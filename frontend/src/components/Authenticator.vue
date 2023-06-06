<script setup lang="ts">
import { Auth } from 'aws-amplify';
import { ref } from 'vue';

const props = defineProps({
	onSignIn: {
		type: Function,
		required: true,
	},
});

const username = ref('');
const password = ref('');

const signIn = async () => {
	try {
		await Auth.signIn(username.value, password.value);
		props.onSignIn();
	} catch (e) {
		console.error(e);
	}
};
</script>

<template>
	<div class="auth-container">
		<input class="auth-input" type="text" v-model="username" placeholder="username" />
		<input class="auth-input" type="password" v-model="password" placeholder="password" />
		<button class="auth-button" @click="signIn">Sign In</button>
	</div>
</template>

<style scoped lang="scss">
.auth-container {
	display: flex;
	flex-direction: column;
	align-items: center;
	padding: 20px;
	border-radius: 10px;
	box-shadow: 0 2px 4px 0 rgba(0, 0, 0, 0.2);
}

.auth-input {
	margin-bottom: 10px;
	padding: 10px;
	border-radius: 5px;
	border: 1px solid #ccc;
	width: 200px;
}

.auth-button {
	padding: 10px 20px;
	border-radius: 5px;
	border: none;
	color: white;
	background-color: #007bff;
	cursor: pointer;

	&:hover {
		background-color: #0056b3;
	}
}
</style>
