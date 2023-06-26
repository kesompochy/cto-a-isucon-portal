<template>
	<div class="team-name-display">
		<p class="anataha">あなたは</p>
		<p class="team-name" :style="{color: color}">{{ teamName }}</p>
		<p class="desu">です。</p>
	</div>
</template>

<script setup lang="ts">
defineProps({
	teamName: String,
	color: String
});
</script>

<style scoped lang="scss">
p {
	margin: 0;
}
.team-name-display {
	font-weight: bold;
	text-align: left;
	margin-bottom: 50px;
	.anataha {
		font-size: 2em;
	}
	.team-name {
		font-size: 5em;
	}
	.desu {
		font-size: 1em;
	}
}
</style>
