<script setup lang="ts">
import Authenticator from './components/Authenticator.vue';
import LineChart from './components/LineChart.vue';
import BarChart from './components/BarChart.vue';
import { ref, onBeforeMount, onBeforeUnmount } from 'vue';
import { API, Auth, graphqlOperation } from 'aws-amplify';
import { getAllScores } from './graphql/queries/getAllScores';
import { onNewScore } from './graphql/queries/onNewScore';
import { Score } from './interfaces';
//import '@aws-amplify/ui-vue/styles.css'
import mockScore from './mocks/scores.json';
import Observable from 'zen-observable-ts';

const isDevelopment = ref(process.env.NODE_ENV === 'development');
const isAuthenticated = ref(false);

const scores = ref<Score[]>([]);
const colors = ref<string[]>([]);
const teamStates = ref<boolean[]>(Array(10).fill(true));

onBeforeMount(() => {
	Auth.currentAuthenticatedUser({ bypassCache: true })
		.then(() => {
			isAuthenticated.value = true;
			if (process.env.NODE_ENV !== 'development') {
				fetchScores();

				const subscription = subscribeToNewScores();
				// コンポーネントがアンマウントされるときにサブスクリプションを解除する
				onBeforeUnmount(() => {
					unsubscribeFromNewScores(subscription);
				});
			} else {
				scores.value = mockScore;
			}
		})
		.catch(() => {
			isAuthenticated.value = false;
		});
});

const fetchScores = async () => {
	Auth.currentAuthenticatedUser({ bypassCache: true })
		.then(async () => {
			try {
				const result = await API.graphql(graphqlOperation(getAllScores));
				if ('data' in result) {
					const fetchedScore = result.data.getAllScores;
					console.log(fetchedScore);
					scores.value = fetchedScore;
				}
				return 0;
			} catch (e) {
				console.error('Error fetching score', e);
				isAuthenticated.value = false;
				return 0;
			}
		})
		.catch((err) => console.log(err));
};

const subscribeToNewScores = () => {
	const observable = API.graphql(graphqlOperation(onNewScore)) as Observable<any>;
	const subscription = observable.subscribe({
		next: (scoreData) => {
			// 新しいスコアデータを処理します
			console.log(scoreData);
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

const generateTeamColors = (numTeams: number) => {
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

colors.value = generateTeamColors(10); // numTeamsはチームの数

const onClickTeamLegend = (index: number) => {
	console.log(teamStates.value);
	// すべてのチームがtrueなら、クリックされたチームのみをtrueにする
	if (teamStates.value.every((teamState) => teamState)) {
		teamStates.value = Array(10).fill(false);
		teamStates.value[index] = true;
		return;
	} else {
		teamStates.value = Array(10).fill(true);
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
