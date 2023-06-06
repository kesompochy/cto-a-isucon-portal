<script setup lang="ts">
import { ref, watch, onBeforeMount } from 'vue';
import { Score } from '../interfaces';

interface Props {
	scores: Score[];
	colors: string[];
}

const props = defineProps<Props>();

const maxScores = ref<number[]>([]);

const sortedScores = ref<{ score: number; team_id: number }[]>([]);

watch(
	() => props.scores,
	() => {
		sortedScores.value = sortScores(calcTeamMaxScore(props.scores));
	},
);

onBeforeMount(() => {
	maxScores.value = calcTeamMaxScore(props.scores);
	sortedScores.value = sortScores(calcTeamMaxScore(props.scores));
});

const calcTeamMaxScore = (scores: Score[]): number[] => {
	const teamMaxScore = scores.reduce(
		(acc, cur) => {
			if (acc[cur.team_id] < cur.score) {
				acc[cur.team_id] = cur.score;
			}
			return acc;
		},
		[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
	);
	return teamMaxScore;
};

const sortScores = (teamMaxScore: number[]) => {
	const scores = [];
	for (let team_id = 0; team_id < teamMaxScore.length; team_id++) {
		const score = teamMaxScore[team_id];
		scores.push({
			team_id,
			score,
		});
	}
	return scores.sort((a, b) => b.score - a.score);
};

const generateBarWidth = (score: number) => {
	const maxScore = Math.max(...maxScores.value);
	const barWidth = (score / maxScore) * 100;
	return `${barWidth}%`;
};
</script>

<template>
	<legend>現在スコア</legend>
	<div class="scoreboard">
		<div class="bar" v-for="(score, index) in sortedScores" :key="index">
			<div class="bar-wrapper">
				<div
					class="bar-fill"
					:style="{
						width: generateBarWidth(score.score),
						backgroundColor: colors[score.team_id],
					}"
				></div>
			</div>
			<div class="bar-info">
				<div class="score">{{ score.score }}</div>
				<div class="team-id">チーム{{ score.team_id }}</div>
			</div>
		</div>
	</div>
</template>

<style scoped lang="scss">
.scoreboard {
	display: flex;
	flex-direction: column;
}

.bar {
	display: flex;
	align-items: center;
	margin-bottom: 8px;
}

.bar-wrapper {
	width: 100%;
	height: 20px;
	background-color: rgba(0, 0, 0, 0);
	border-radius: 4px;
	overflow: hidden;
}

.bar-fill {
	height: 100%;
}

.bar-info {
	margin-left: 8px;
	white-space: nowrap;
}

.score {
	font-weight: bold;
}

.team-id {
	color: gray;
}
</style>
