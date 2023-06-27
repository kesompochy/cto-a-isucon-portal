<script lang="ts" setup>
import { onMounted, ref, nextTick, watch, computed } from 'vue';
import { Score } from '../interfaces';

const unFocusedOpacity: string = '10%';
const lineThickness = 3;
const gridThickness = 1;

interface Props {
	scores: Score[];
	colors: string[];
	screenSize: { width: number; height: number };
	teamStates: boolean[];
	clickTeamLegend: Function;
	teamNames: string[];
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
	{ deep: true },
);
watch(
	() => props.teamStates,
	() => {
		if (!ctxRef.value) {
			console.error('canvas要素が存在しません');
			return;
		}
		render(ctxRef.value, props.scores, props.colors);
	},
	{ deep: true },
);
watch(
	() => props.colors,
	() => {
		if (!ctxRef.value) {
			console.error('canvas要素が存在しません');
			return;
		}
		props.colors;
		render(ctxRef.value, props.scores, props.colors);
	},
	{ deep: true },
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
	ctxRef.value.scale(1 / resolution.value.width, 1 / resolution.value.height);
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
	const { maxScore, minTimestamp, scaleX, scaleY } = scores;
	const timestampLabelWidth = ctx.measureText(formatTimeAsHHMM(currentTimestamp)).width;
	const screenSize = props.screenSize;

	// Determine the optimal step size for the scores
	let scoreStepMajor = 1;

	if (maxScore > 0) {
		const maxNumberOfSteps = 10;
		let exponent = Math.floor(Math.log10(maxScore / maxNumberOfSteps));
		let magnitude = Math.pow(10, exponent);
		let baseStep = maxScore / (maxNumberOfSteps * magnitude);

		if (baseStep <= 2) {
			scoreStepMajor = 2 * magnitude;
		} else if (baseStep <= 5) {
			scoreStepMajor = 5 * magnitude;
		} else {
			scoreStepMajor = 10 * magnitude;
		}
	}

	ctx.lineWidth = gridThickness;
	ctx.strokeStyle = 'grey';
	ctx.fillStyle = 'black';
	ctx.textBaseline = 'middle';
	ctx.font = `${padding.bottom / 2}px sans-serif`;

	// Draw grid and labels for scores
	ctx.textAlign = 'left';
	for (let score = 0; score <= maxScore; score += scoreStepMajor) {
		const y = scaleY(score);
		ctx.beginPath();
		ctx.moveTo(padding.left, y);
		ctx.lineTo(screenSize.width - padding.right, y);
		ctx.stroke();

		const scoreLabel = Math.round(score).toString(); // convert score to integer
		ctx.fillText(scoreLabel, 0, y);
	}

	// Calculate the desired timestamp interval
	const desiredNumberOfLabels = 7;
	const totalSeconds = currentTimestamp - minTimestamp;
	const approximateIntervalInSeconds = totalSeconds / desiredNumberOfLabels;

	let timestampInterval;

	if (approximateIntervalInSeconds <= 15 * 60) {
		timestampInterval = 15 * 60; // 15 minutes
	} else if (approximateIntervalInSeconds <= 30 * 60) {
		timestampInterval = 30 * 60; // 30 minutes
	} else if (approximateIntervalInSeconds <= 60 * 60) {
		timestampInterval = 60 * 60; // 1 hour
	} else if (approximateIntervalInSeconds <= 2 * 60 * 60) {
		timestampInterval = 2 * 60 * 60; // 2 hours
	} else if (approximateIntervalInSeconds <= 3 * 60 * 60) {
		timestampInterval = 3 * 60 * 60; // 3 hours
	} else {
		timestampInterval = Math.ceil(approximateIntervalInSeconds / (60 * 60)) * 60 * 60; // round up to nearest hour
	}

	// Find the nearest rounded timestamp for minTimestamp
	let startTimestamp = Math.ceil(minTimestamp / timestampInterval) * timestampInterval;

	// Draw grid and labels for timestamps
	ctx.textAlign = 'center';
	ctx.font = `${padding.bottom / 2}px sans-serif`;

	// Draw minTimestamp label at the left edge
	const minLabel = formatTimeAsHHMM(minTimestamp);
	ctx.fillText(minLabel, padding.left, screenSize.height - padding.bottom / 2);

	// Draw grid and labels for timestamps between minTimestamp and currentTimestamp
	let lastLabelPosition = scaleX(minTimestamp);
	for (
		let timestamp = startTimestamp;
		timestamp <= currentTimestamp;
		timestamp += timestampInterval
	) {
		const x = scaleX(timestamp);
		const label = formatTimeAsHHMM(timestamp);

		// Check if there's enough space between the labels
		if (
			x >= padding.left + timestampLabelWidth &&
			x <= screenSize.width - padding.right - timestampLabelWidth
		) {
			lastLabelPosition = x;
			ctx.fillText(label, x, screenSize.height - padding.bottom / 2);
		}
	}

	// Draw the current timestamp label at the right edge,
	// but only if it doesn't overlap with the previous label
	const currentLabelPosition = screenSize.width - padding.right - timestampLabelWidth / 2;
	if (currentLabelPosition - lastLabelPosition >= timestampLabelWidth) {
		const currentLabel = formatTimeAsHHMM(currentTimestamp);
		ctx.fillText(currentLabel, currentLabelPosition, screenSize.height - padding.bottom / 2);
	}
};

const render = (ctx: CanvasRenderingContext2D, scores: Score[], colors: string[]) => {
	console.log(`start rendering line chart with ${scores.length} scores`, scores);
	const minScore = Math.min(...scores.map((score) => score.score));
	const maxScore = Math.max(...scores.map((score) => score.score));
	const minTimestamp = scores[0]?.timestamp || 0;
	const currentTimestamp = Math.floor(Date.now() / 1000); // Current timestamp in seconds
	const screenSize = props.screenSize;

	// Clear canvas.
	ctx.clearRect(0, 0, screenSize.width, screenSize.height);
	ctx.fillStyle = 'rgba(250, 250, 250, 1)';
	ctx.fillRect(0, 0, screenSize.width, screenSize.height);

	scores.sort((a, b) => a.timestamp - b.timestamp);

	const timestampLabelWidth = ctx.measureText(formatTimeAsHHMM(currentTimestamp)).width;

	const scaleGraphX = (timestamp: number) =>
		padding.left +
		((timestamp - minTimestamp) / (currentTimestamp - minTimestamp)) *
			(screenSize.width - padding.left - padding.right);
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
			messages: []
		};
		scoresByTeam[teamId].push(currentScore);
	});

	// Draw lines for each team.
	ctx.lineWidth = lineThickness;
	Object.keys(scoresByTeam).forEach((teamIdStr) => {
		const teamId = Number(teamIdStr);
		const teamScores = scoresByTeam[teamId];

		let alpha = props.teamStates[teamId] ? '100%' : unFocusedOpacity; // 100% for focused and 10% for unfocused

		let hslColor = colors[teamId] || 'hsl(0, 0%, 0%)';
		// Convert the color to HSLA
		let hslaColor = hslColor.slice(0, -1) + `, ${alpha})`.replace('hsl', 'hsla');

		ctx.strokeStyle = hslaColor;
		ctx.beginPath();
		ctx.moveTo(scaleX(teamScores[0]?.timestamp || 1), scaleY(teamScores[0]?.score || 1));
		teamScores.slice(1).forEach((score) => {
			ctx.lineTo(scaleGraphX(score.timestamp), scaleY(score.score));
		});
		ctx.stroke();
	});
};
</script>

<template>
	<div class="container">
		<legend>スコア経過</legend>
		<canvas ref="canvasRef"></canvas>
		<div class="legend">
			<div
				v-for="(color, index) in colors"
				:key="index"
				class="legend-item"
				:class="teamStates[index] ? 'focused' : 'unfocused'"
				@click="clickTeamLegend(index)"
			>
				<span class="legend-color" :style="{ background: color }"></span>
				<span class="legend-label">{{ teamNames[index] || `チーム${index}` }}</span>
			</div>
		</div>
	</div>

</template>

<style lang="scss" scoped>
canvas {
	width: 600px;
	height: 450px;
}
.container {
	margin-bottom: 80px;
	width: 600px;
}
.legend {
	display: flex;
	flex-wrap: wrap;
	margin-top: 10px;
}

.legend-item {
	display: flex;
	align-items: center;
	padding: 5px;
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

	//テキストを選択されないようにしたい
	-webkit-touch-callout: none; /* iOS Safari */
	-webkit-user-select: none; /* Safari */
	user-select: none;
}

.legend-color {
	width: 15px;
	height: 15px;
	margin-right: 5px;
}
</style>
