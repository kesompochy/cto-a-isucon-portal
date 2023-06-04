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

const isAuthenticated = ref(false);

const scores = ref<Score[]>([]);
const colors = ref<string[]>([]);

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

const generateRandomColor = () => {
	const letters = '0123456789ABCDEF';
	let color = '#';
	for (let i = 0; i < 6; i++) {
		color += letters[Math.floor(Math.random() * 16)];
	}
	return color;
};

const generateTeamColors = (numTeams: number) => {
	const colors = [];
	for (let i = 0; i < numTeams; i++) {
		colors.push(generateRandomColor());
	}
	return colors;
};

colors.value = generateTeamColors(10); // numTeamsはチームの数
</script>

<template>
	<div v-if="isAuthenticated">
		<LineChart :scores="scores" :colors="colors" />
		<BarChart />
		<button @click="fetchScores">Get Score</button>
		<button @click="signOut">Sign Out</button>
	</div>
	<Authenticator
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
.logo {
	height: 6em;
	padding: 1.5em;
	will-change: filter;
	transition: filter 300ms;
}
.logo:hover {
	filter: drop-shadow(0 0 2em #646cffaa);
}
.logo.vue:hover {
	filter: drop-shadow(0 0 2em #42b883aa);
}
</style>
