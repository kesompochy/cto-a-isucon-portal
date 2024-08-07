<script setup lang="ts">
import Authenticator from './components/Authenticator.vue';
import LineChart from './components/LineChart.vue';
import BarChart from './components/BarChart.vue';
import YourTeamNameIs from './components/YourTeamNameIs.vue';
import MessageFromBench from './components/MessageFromBench.vue';
import { ref, onBeforeMount, onBeforeUnmount, watch} from 'vue';
import { API, Auth, graphqlOperation } from 'aws-amplify';
import { getAllScores } from './graphql/queries/getAllScores';
import { onNewScore } from './graphql/queries/onNewScore';
import { Score } from './interfaces';
import mockScore from './mocks/scores.json';
import Observable from 'zen-observable-ts';

const sheetAPIEndpoint = import.meta.env.VITE_SHEET_API_ENDPOINT || '';

const isDevelopment = ref(process.env.NODE_ENV === 'development');
const isAuthenticated = ref(false);

const scores = ref<Score[]>([]);
const teamNum = ref<number>(0);
const colors = ref<string[]>([]);
const teamStates = ref<boolean[]>(Array(teamNum.value).fill(true));
const teamNames = ref<string[]>([]);
const teamName = ref<string>('');
const username = ref<string>('');
const messageFromBench = ref<{message: string[], timestamp: number}>({message: [], timestamp: 0});
const teamScores = ref<Score[]>([]);
const teamId = ref<number>(0);
const leftPanelIsHidden = ref<boolean>(false);
const isAuthChecking = ref(true);

const TEAM_COUNT = import.meta.env.VITE_TEAM_COUNT || 40;

watch(
	() => scores.value,
	(newScores: Score[]) => {
		teamNum.value = calcTeamNumFromScores(newScores);
		
		extractMessage(newScores);
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
watch(
	() => isAuthenticated.value,
	async (newIsAuthenticated: boolean) => {
		if (newIsAuthenticated && !isDevelopment.value) {
			await fetchScores();
			const user = await Auth.currentAuthenticatedUser();
			username.value = user.username;
			if (username.value == 'admin') {
				teamName.value = 'admin';
			} else {
				teamId.value = parseInt(username.value.replace('team', ''), 10);
				teamName.value = teamNames.value[teamId.value];
			}
		}
	},
	{ deep: true },
)

onBeforeMount(async () => {
	await fetchTeamNames();
	if (process.env.NODE_ENV == 'development') {
		scores.value = mockScore;
		scores.value = scores.value.filter((score: Score) => score.team_id >= 0 && score.team_id <= TEAM_COUNT);
		isAuthenticated.value = true;
		teamName.value = 'ふわふわ';
		username.value = 'team1';
		isAuthChecking.value = false;
	} else {
		Auth.currentAuthenticatedUser({ bypassCache: true })
			.then(async () => {
				isAuthenticated.value = true;
				const subscription = subscribeToNewScores();
				await fetchScores();
				
				// コンポーネントがアンマウントされるときにサブスクリプションを解除する
				onBeforeUnmount(() => {
					unsubscribeFromNewScores(subscription);
				});
			})
			.catch(() => {
				isAuthenticated.value = false;
			})
			.finally(() => {
				isAuthChecking.value = false;
			});
	}
	extractMessage(scores.value)
});

const extractMessage = (scores: Score[]) => {
	if (username.value !== 'admin') {
		console.log(`username is ${username.value}`)
		teamId.value = parseInt(username.value.replace('team', ''));
		teamScores.value = scores.filter(score => score.team_id === teamId.value);

		// find the message with the latest timestamp
		const latestMessage = teamScores.value.reduce((prev, current) => {
			return (prev.timestamp > current.timestamp) ? prev : current;
		}, {timestamp: 0, messages: ['']});
		
		// get the last message from the latestMessage
		const lastMessage = latestMessage.messages;

		// set the messageFromBench
		messageFromBench.value = {
			message: lastMessage,
			timestamp: latestMessage.timestamp
		};
	}	else {
		teamScores.value = scores;
	}
}

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

const fetchTeamNames = async () => {
	try {
		const response = await fetch(sheetAPIEndpoint);
		const data = await response.json();
		const rowData = data.sheets[0].data[0].rowData.slice(1);

		teamNames.value = rowData.map((row: any, index: number) => {
			return row.values[1]?.formattedValue || `チーム${index}`;
		});
	} catch (error) {
		console.error('Failed to fetch team names:', error);
	}
};

const fetchScores = async () => {
	await Auth.currentAuthenticatedUser({ bypassCache: true });

  let allScores: Score[] = [];
  let nextToken: string | null = null;

  do {
    try {
      const result: any = await API.graphql(graphqlOperation(getAllScores, { 
        limit: 200, // 一度に取得するスコアの数を指定
        nextToken: nextToken 
      }));

      if ('data' in result && result.data.getAllScores) {
        const fetchedData = result.data.getAllScores;
				console.log('fetchedData', fetchedData);
        allScores = [...allScores, ...fetchedData.scores];
				console.log('allScores', allScores);
        nextToken = fetchedData.nextToken;
      }
		} catch (e) {
			console.error('Error fetching scores', e);
			isAuthenticated.value = false;
			return;
		}
	} while (nextToken);

  scores.value = allScores.filter((score: Score) => score.team_id >= 0 && score.team_id <= TEAM_COUNT);
  if (username.value === "debug") {
    scores.value = allScores;
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
				if (username.value == "debug" || (newScore.team_id >= 0 && newScore.team_id <= TEAM_COUNT)) {
					scores.value.push({
						team_id: newScore.team_id,
						score: newScore.score,
						timestamp: newScore.timestamp,
						messages: newScore.messages,
					});
				}
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
	<div v-if="!isAuthChecking">
		<div class="app-container" v-if="isAuthenticated">
			<div class="left-panel" @click="()=>{leftPanelIsHidden = !leftPanelIsHidden}"
				:class="leftPanelIsHidden ? 'hidden' : ''"
				>
				<YourTeamNameIs :team-name="teamName" :color="colors[teamId]"/>
			</div>
			<div class="chart-container">
				<LineChart
					:scores="scores"
					:colors="colors"
					:screenSize="{ width: 800, height: 600 }"
					:team-states="teamStates"
					:click-team-legend="onClickTeamLegend"
					:team-names="teamNames"
				/>
				<BarChart
					:scores="scores"
					:colors="colors"
					:team-states="teamStates"
					:click-team-score="onClickTeamLegend"
					:team-names="teamNames"
				/>
			</div>
			<MessageFromBench :scores="teamScores" :teamName="username"/>
			<div class="button-container">
				<button v-if="isDevelopment" @click="fetchScores">Get Score</button>
				<button @click="signOut">Sign Out</button>
			</div>
		</div>
		<Authenticator
			class="authenticator"
			v-else
			:onSignIn="
				() => {
					isAuthenticated = true;
					isAuthChecking = false;
					fetchScores();
				}
			"
		>
		</Authenticator>
	</div>
</template>

<style scoped lang="scss">
.app-container {
    width: 100%; /* Adjust as needed */
    display: flex; /* Added */
    flex-direction: column; /* Added */
    justify-content: space-between; /* Added */
}

.chart-container {
    display: flex; /* Added */
    width: 1200px;
}

.button-container {
    display: flex; /* Added */
    flex-direction: column; /* Added */
    align-items: flex-start; /* Added */
}

.left-panel {
	position: fixed;
	top: 100px;
	left: 0;
	background-color: rgba(250, 250, 255, 0.4);
	&.hidden {
		opacity: 0.2;
	}
	&:hover {
		background-color: rgba(250, 250, 255, 0.9);
		cursor: pointer;
	}
}
</style>
