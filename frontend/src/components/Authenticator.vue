<script setup lang="ts">
    import { Auth } from 'aws-amplify';
    import { ref, defineProps } from 'vue';

    const props = defineProps({
        onSignIn: {
            type: Function,
            required: true
        }
    })

    const username = ref('')
    const password = ref('')

    const signIn = async () => {
        try {
            await Auth.signIn(username.value, password.value)
            props.onSignIn()
        } catch (e) {
            console.error(e)
        }
    }
</script>

<template>
    <div>
        <input type="text" v-model="username" placeholder="username">
        <input type="password" v-model="password" placeholder="password">
        <button @click="signIn">Sign In</button>
    </div>
</template>

<style scoped lang="scss">


</style>