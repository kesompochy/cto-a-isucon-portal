<script setup lang="ts">
import { ref, watch, onBeforeMount } from 'vue';
import { Score } from '../interfaces';

interface Props {
	scores: Score[];
	colors: string[];
	teamStates: boolean[];
	teamNames: string[];
	clickTeamScore: (team_id: number) => void;
}

const props = defineProps<Props>();

const maxScores = ref<number[]>([]);

const sortedScores = ref<{ score: number; team_id: number }[]>([]);

watch(
	() => props.scores,
	() => {
		maxScores.value = calcTeamMaxScore(props.scores);
		sortedScores.value = sortScores(calcTeamMaxScore(props.scores));
		console.log('sorted value', sortedScores.value);
	},
	{ deep: true },
);

onBeforeMount(() => {
	maxScores.value = calcTeamMaxScore(props.scores);
	sortedScores.value = sortScores(calcTeamMaxScore(props.scores));
});

/*
const calcTeamMaxScore = (scores: Score[]): number[] => {
	const teamMaxScore: number[] = [];
	scores.forEach((cur) => {
		if (!teamMaxScore[cur.team_id] || teamMaxScore[cur.team_id] < cur.score) {
			teamMaxScore[cur.team_id] = cur.score;
		}
	});
	return teamMaxScore;
};*/

const calcTeamMaxScore = (scores: Score[]): number[] => {
	const teamLatestScore: { [id: number]: Score } = {};
	scores.forEach((cur) => {
		// If this team hasn't been seen before, or if this score is more recent
		if (!teamLatestScore[cur.team_id] || teamLatestScore[cur.team_id].timestamp < cur.timestamp) {
			teamLatestScore[cur.team_id] = cur;
		}
	});
	
	// Convert the mapping to an array with just the scores.
	const latestScores: number[] = [];
	for (let team in teamLatestScore) {
		latestScores[+team] = teamLatestScore[team].score;
	}
	return latestScores;
}

const sortScores = (teamMaxScore: number[]) => {
	return teamMaxScore
		.map((score, team_id) => ({ team_id, score }))
		.filter((scoreObj) => scoreObj.score !== undefined)
		.sort((a, b) => b.score - a.score);
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
		<transition-group name="bar-animation" tag="div">
			<div
				class="bar"
				v-for="(score, index) in sortedScores"
				:key="score.team_id"
				:class="teamStates[score.team_id] ? 'focused' : 'unfocused'"
				@click="clickTeamScore(score.team_id)"
			>
				<div
					class="rank"
					:class="{
						first: index === 0,
						'second-to-fifth': index > 0 && index < 5,
						other: index >= 5,
					}"
				>
					{{ index + 1 }}
				</div>
				<div class="bar-wrapper">
					<div
						class="bar-fill"
						:style="{
							width: generateBarWidth(score.score),
							backgroundColor: colors[score.team_id],
							transition: 'width 0.5s ease-out',
						}"
					></div>
				</div>
				<div class="bar-info">
					<div class="score">{{ score.score }}</div>
					<div class="team-id">
						{{ teamNames[score.team_id] || `チーム${score.team_id}` }}
					</div>
				</div>
			</div>
		</transition-group>
	</div>
</template>

<style scoped>
.bar-animation-move {
	transition: transform 0.5s;
}
</style>

<style scoped lang="scss">
.scoreboard {
	display: flex;
	flex-direction: column;
}

.bar {
	display: flex;
	align-items: center;
	margin-bottom: 8px;
	cursor: pointer;
	&.focused {
		opacity: 1;
	}
	&.unfocused {
		opacity: 0.2;
	}
	&:hover {
		background-color: azure;
	}

	.rank {
		margin-right: 16px;
		width: 50px;
		font-size: 1em;
		font-weight: bold;

		&.first {
			font-size: 2em;
		}

		&.second-to-fifth {
			font-size: 1.5em;
		}

		&.other {
			/* それ以外の順位 */
			color: #333;
		}
	}
}

.bar-wrapper {
	height: 20px;
	width: 100%;
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
	width: 100px; // 幅を固定にする
	overflow: hidden; // 超えたテキストを隠す
	text-overflow: ellipsis; // 省略記号を表示
	.score {
		font-weight: bold;
	}
	.team-id {
		color: gray;
		overflow: hidden;
		text-overflow: ellipsis;
		font-size: 0.8em;
	}
}

</style>
