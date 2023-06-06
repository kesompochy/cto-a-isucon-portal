<script lang="ts" setup>
import { onMounted, ref, nextTick, watch, computed } from 'vue';
import { Score } from '../interfaces';

interface Props {
	scores: Score[];
	colors: string[];
	screenSize: { width: number; height: number };
}

const displayResolution = window.devicePixelRatio || 1;

const padding = {
	top: 20,
	right: 20,
	bottom: 50, // increased for labels
	left: 70, // increased for labels
};

const props = defineProps<Props>();

const canvasRef = ref<HTMLCanvasElement | null>(null);
const ctxRef = ref<CanvasRenderingContext2D | null | undefined>(null);

watch(
	() => props.scores,
	() => {
		if (!ctxRef.value) {
			console.error('canvas要素が存在しません');
			return;
		}
		render(ctxRef.value, props.scores, props.colors);
	},
);

onMounted(async () => {
	await nextTick();
	if (!canvasRef.value) {
		console.error('canvas要素が存在しません');
		return;
	}
	resizeCanvas();
	canvasRef.value.addEventListener('resize', resizeCanvas);
	ctxRef.value = canvasRef?.value?.getContext('2d');
	if (!ctxRef.value) {
		console.error('canvas要素が存在しません');
		return;
	}
	render(ctxRef.value, props.scores, props.colors);
});

const resolution = computed<{ width: number; height: number }>(() => {
	if (!canvasRef.value) {
		return { width: 1, height: 1 };
	}
	const canvas = canvasRef.value;
	const screenSize = props.screenSize;
	const width = screenSize.width / canvas.width;
	const height = screenSize.height / canvas.height;
	return { width: width, height: height };
});

const resizeCanvas = () => {
	if (!canvasRef.value) {
		return;
	}
	const canvas = canvasRef.value;
	canvas.width = canvas.clientWidth * displayResolution;
	canvas.height = canvas.clientHeight * displayResolution;
};

const formatTimeAsHHMM = (timestamp: number) => {
	const date = new Date(timestamp * 1000);
	const hours = String(date.getHours()).padStart(2, '0');
	const minutes = String(date.getMinutes()).padStart(2, '0');

	return `${hours}:${minutes}`;
};

interface GridInfo {
	minScore: number;
	maxScore: number;
	minTimestamp: number;
	maxTimestamp: number;
	scaleX: (timestamp: number) => number;
	scaleY: (score: number) => number;
}

const drawGrids = (ctx: CanvasRenderingContext2D, scores: GridInfo, currentTimestamp: number) => {
	const { maxScore, minTimestamp, maxTimestamp, scaleX, scaleY } = scores;
	const timestampLabelWidth = ctx.measureText(formatTimeAsHHMM(currentTimestamp)).width;
	const screenSize = props.screenSize;

	// Define grid steps for scores and timestamps.
	const scoreStepMajor = maxScore <= 1000 ? 100 : 1000;

	// Calculate the desired timestamp interval.
	const totalHours = (maxTimestamp - minTimestamp) / 3600; // convert to hours
	const timestampInterval = Math.ceil(totalHours / 8) * 3600; // interval in seconds

	ctx.strokeStyle = 'grey';
	ctx.fillStyle = 'black';
	ctx.textBaseline = 'middle';
	ctx.font = `${padding.bottom / 2}px sans-serif`;

	for (let score = 0; score <= maxScore; score += scoreStepMajor) {
		const y = scaleY(score);
		ctx.beginPath();
		ctx.moveTo(padding.left, y);
		ctx.lineTo(screenSize.width - padding.right, y);
		ctx.stroke();

		ctx.fillText(score.toString(), 0, y);
	}

	// Draw grid and labels for timestamps.
	ctx.textAlign = 'center';
	ctx.font = `${padding.bottom / 2}px sans-serif`;

	for (let timestamp = minTimestamp; timestamp <= maxTimestamp; timestamp += timestampInterval) {
		const x = scaleX(timestamp);

		// if x (the label position) is within the visible range
		if (x >= padding.left && x <= screenSize.width - padding.right - timestampLabelWidth / 2) {
			ctx.fillText(formatTimeAsHHMM(timestamp), x, screenSize.height - padding.bottom / 2);
		}
	}
};

const render = (ctx: CanvasRenderingContext2D, scores: Score[], colors: string[]) => {
	console.log('start rendering');
	const minScore = Math.min(...scores.map((score) => score.score));
	const maxScore = Math.max(...scores.map((score) => score.score));
	const minTimestamp = scores[0].timestamp;
	const currentTimestamp = Math.floor(Date.now() / 1000); // Current timestamp in seconds
	const screenSize = props.screenSize;

	ctx.scale(1 / resolution.value.width, 1 / resolution.value.height);

	// Clear canvas.
	ctx.clearRect(0, 0, screenSize.width, screenSize.height);
	ctx.fillStyle = 'rgba(230, 230, 230, 0.5)';
	ctx.fillRect(0, 0, screenSize.width, screenSize.height);

	scores.sort((a, b) => a.timestamp - b.timestamp);

	const timestampLabelWidth = ctx.measureText(formatTimeAsHHMM(currentTimestamp)).width;

	const scaleX = (timestamp: number) =>
		padding.left +
		((timestamp - minTimestamp) / (currentTimestamp - minTimestamp)) *
			(screenSize.width - padding.left - (padding.right + timestampLabelWidth / 2));
	const scaleY = (score: number) =>
		padding.top +
		(screenSize.height - padding.top - padding.bottom) -
		((score - minScore) / (maxScore - minScore)) *
			(screenSize.height - padding.top - padding.bottom);
	drawGrids(
		ctx,
		{
			minScore: minScore,
			maxScore: maxScore,
			minTimestamp: minTimestamp,
			maxTimestamp: currentTimestamp,
			scaleX: scaleX,
			scaleY: scaleY,
		},
		currentTimestamp,
	);

	// Group scores by team.
	const scoresByTeam = scores.reduce((acc, score) => {
		acc[score.team_id] = acc[score.team_id] || [];
		acc[score.team_id].push(score);
		return acc;
	}, {} as Record<number, Score[]>);

	Object.keys(scoresByTeam).forEach((teamIdStr) => {
		const teamId = Number(teamIdStr);
		// Find the latest score for the team.
		const latestScore = scoresByTeam[teamId].reduce((latest, current) => {
			return current.timestamp > latest.timestamp ? current : latest;
		});
		// Create a new score with the current timestamp and the latest score.
		const currentScore = {
			team_id: teamId,
			score: latestScore.score,
			timestamp: currentTimestamp,
		};
		scoresByTeam[teamId].push(currentScore);
	});
	// Draw lines for each team.
	Object.keys(scoresByTeam).forEach((teamIdStr) => {
		const teamId = Number(teamIdStr);
		const teamScores = scoresByTeam[teamId];
		ctx.strokeStyle = colors[teamId];
		ctx.beginPath();
		ctx.moveTo(scaleX(teamScores[0].timestamp), scaleY(teamScores[0].score));
		teamScores.slice(1).forEach((score) => {
			ctx.lineTo(scaleX(score.timestamp), scaleY(score.score));
		});
		ctx.stroke();
	});
};
</script>

<template>
	<legend>スコア経過</legend>
	<canvas ref="canvasRef"></canvas>
	<div class="legend">
		<div v-for="(color, index) in colors" :key="index" class="legend-item">
			<span class="legend-color" :style="{ background: color }"></span>
			<span class="legend-label">チーム {{ index }}</span>
		</div>
	</div>
</template>

<style lang="scss" scoped>
canvas {
	//border: 1px solid #000;
	width: 600px;
	height: 450px;
}
.legend {
	display: flex;
	flex-wrap: wrap;
	margin-top: 10px;
}

.legend-item {
	display: flex;
	align-items: center;
	margin-right: 10px;
	margin-bottom: 10px;
}

.legend-color {
	width: 15px;
	height: 15px;
	margin-right: 5px;
}
</style>
