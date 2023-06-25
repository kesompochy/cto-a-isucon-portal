<template>
	<div class="team-name-display">
		<p class="anataha">あなたは</p>
		<p class="team-name">{{ teamName }}</p>
		<p class="desu">です。</p>
	</div>
</template>

<script setup lang="ts">
defineProps({
	teamName: String,
});
</script>

<style scoped lang="scss">
p {
	margin: 0;
}
.team-name-display {
	position: fixed;
	left: 0px;
	top: 100px;
	font-weight: bold;
	text-align: left;
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
