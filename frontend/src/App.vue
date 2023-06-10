<script setup lang="ts">
import Authenticator from './components/Authenticator.vue';
import LineChart from './components/LineChart.vue';
import BarChart from './components/BarChart.vue';
import { ref, onBeforeMount, onMounted } from 'vue';
import { API, Auth, graphqlOperation } from 'aws-amplify';
import { getAllScores } from './graphql/queries/getAllScores';
import { Score } from './interfaces';
//import '@aws-amplify/ui-vue/styles.css'
import mockScore from './mocks/scores.json';

const isDevelopment = ref(process.env.NODE_ENV === 'development');
const isAuthenticated = ref(false);

const scores = ref<Score[]>([]);
const colors = ref<string[]>([]);
const teamStates = ref<boolean[]>(Array(10).fill(true));

if (process.env.NODE_ENV === 'development') {
	scores.value = mockScore;
}

onBeforeMount(() => {
	Auth.currentAuthenticatedUser({ bypassCache: true })
		.then(() => {
			isAuthenticated.value = true;
		})
		.catch(() => {
			isAuthenticated.value = false;
		});
});

onMounted(() => {
	if (process.env.NODE_ENV !== 'development') {
		if (isAuthenticated.value) {
			fetchScores();
		}
	}
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
		/*
		// クリックされたチーム以外すべてfalseなら、すべてのチームをtrueにする
		if (teamStates.value.every((teamState) => !teamState)) {
			teamStates.value = Array(10).fill(true);
			return;
		} else if (teamStates.value[index]) {
			teamStates.value[index] = false;
			return;
		} else {
			teamStates.value[index] = true;
			return;
		}*/
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
		<button v-if="!isDevelopment" @click="fetchScores">Get Score</button>
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
