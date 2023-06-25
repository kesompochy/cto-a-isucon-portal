<script setup lang="ts">
import Authenticator from './components/Authenticator.vue';
import LineChart from './components/LineChart.vue';
import BarChart from './components/BarChart.vue';
import { ref, onBeforeMount, onBeforeUnmount, watch } from 'vue';
import { API, Auth, graphqlOperation } from 'aws-amplify';
import { getAllScores } from './graphql/queries/getAllScores';
import { onNewScore } from './graphql/queries/onNewScore';
import { Score } from './interfaces';
import mockScore from './mocks/scores.json';
import Observable from 'zen-observable-ts';

const isDevelopment = ref(process.env.NODE_ENV === 'development');
const isAuthenticated = ref(false);

const scores = ref<Score[]>([]);
const teamNum = ref<number>(0);
const colors = ref<string[]>([]);
const teamStates = ref<boolean[]>(Array(teamNum.value).fill(true));

watch(
	() => scores.value,
	(newScores: Score[]) => {
		teamNum.value = calcTeamNumFromScores(newScores);
	},
	{ deep: true },
);
watch(
	() => teamNum.value,
	(newTeamNum: number) => {
		teamStates.value = Array(newTeamNum).fill(true);
		colors.value = generateColors(teamNum.value);
	},
	{ deep: true },
);

onBeforeMount(() => {
	if (process.env.NODE_ENV == 'development') {
		scores.value = mockScore;
		isAuthenticated.value = true;
	} else {
		Auth.currentAuthenticatedUser({ bypassCache: true })
			.then(async () => {
				isAuthenticated.value = true;
				await fetchScores();

				const subscription = subscribeToNewScores();
				// コンポーネントがアンマウントされるときにサブスクリプションを解除する
				onBeforeUnmount(() => {
					unsubscribeFromNewScores(subscription);
				});
			})
			.catch(() => {
				isAuthenticated.value = false;
			});
	}
});

const calcTeamNumFromScores = (scores: Score[]): number => {
	// 異なるteam_idを追跡するためのSetを作成
	const teamIds = new Set();

	// 各スコアをループし、team_idをSetに追加
	scores.forEach((score: Score) => {
		teamIds.add(score.team_id);
	});

	console.log(`calculated teamId size is ${teamIds.size}, yo`);

	// teamNumにSetのサイズ（異なるteam_idの数）を設定
	return teamIds.size;
};

const fetchScores = async () => {
	await Auth.currentAuthenticatedUser({ bypassCache: true });
	try {
		const result = await API.graphql(graphqlOperation(getAllScores));
		if ('data' in result) {
			const fetchedScores = result.data.getAllScores;
			scores.value = fetchedScores;
		}
		return 0;
	} catch (e) {
		console.error('Error fetching score', e);
		isAuthenticated.value = false;
		return 0;
	}
};

const subscribeToNewScores = () => {
	const observable = API.graphql(graphqlOperation(onNewScore)) as Observable<any>;
	const subscription = observable.subscribe({
		next: (scoreData) => {
			// 新しいスコアデータを処理します
			if (
				scoreData &&
				scoreData.value &&
				scoreData.value.data &&
				scoreData.value.data.onNewScore
			) {
				const newScore = scoreData.value.data.onNewScore;
				scores.value.push({
					team_id: newScore.team_id,
					score: newScore.score,
					timestamp: newScore.timestamp,
				});
			}
		},
		error: (error) => {
			console.error(error);
		},
	});
	console.log('subscribe');
	return subscription;
};

const unsubscribeFromNewScores = (subscription: any) => {
	if (subscription) {
		subscription.unsubscribe();
	}
};

const signOut = async () => {
	try {
		await Auth.signOut();
		isAuthenticated.value = false;
	} catch (e) {
		console.error(e);
	}
};

const generateColors = (numTeams: number) => {
	console.log(`generate colors from teamNum ${numTeams}`);
	const colors = [];
	for (let i = 0; i < numTeams; i++) {
		// 色相 (Hue) を 0 から 360 で変化させる
		const hue = Math.round((i / numTeams) * 360);
		const saturation = 80; // 80%
		const lightness = 60; // 60%
		colors.push(`hsl(${hue}, ${saturation}%, ${lightness}%)`);
	}
	return colors;
};

const onClickTeamLegend = (index: number) => {
	// すべてのチームがtrueなら、クリックされたチームのみをtrueにする
	if (teamStates.value.every((teamState) => teamState)) {
		teamStates.value = Array(teamNum.value).fill(false);
		teamStates.value[index] = true;
		return;
	} else {
		teamStates.value = Array(teamNum.value).fill(true);
	}
};
</script>

<template>
	<div class="app-container" v-if="isAuthenticated">
		<LineChart
			:scores="scores"
			:colors="colors"
			:screenSize="{ width: 800, height: 600 }"
			:team-states="teamStates"
			:click-team-legend="onClickTeamLegend"
		/>
		<BarChart :scores="scores" :colors="colors" />
		<button v-if="isDevelopment" @click="fetchScores">Get Score</button>
		<button @click="signOut">Sign Out</button>
	</div>
	<Authenticator
		class="authenticator"
		v-else
		:onSignIn="
			() => {
				fetchScores();
				isAuthenticated = true;
			}
		"
	>
	</Authenticator>
</template>

<style scoped>
.app-container {
	width: 600px;
}
</style>
