<script setup lang="ts">
  import Authenticator from './components/Authenticator.vue'
  import { ref, onBeforeMount } from 'vue';
  import { API, Auth, graphqlOperation } from 'aws-amplify';
  //import { Authenticator } from '@aws-amplify/ui-vue';
  import { getAllScores } from './graphql/queries/getAllScores';
  import '@aws-amplify/ui-vue/styles.css'

  const isAuthenticated = ref(false)

  onBeforeMount(() => {
    Auth.currentAuthenticatedUser({ bypassCache: true })
      .then(() => {
        isAuthenticated.value = true
        
      })
      .catch(() => {
        isAuthenticated.value = false
      })
  })
  
  const fetchScores = async ()=> {
    Auth.currentAuthenticatedUser({ bypassCache: true })
      .then(async () => {
        try {
          const result = await API.graphql(graphqlOperation(getAllScores));
          if ('data' in result) {
            const fetchedScore = result.data.getAllScores;
            console.log(fetchedScore)
          }
          return 0
        } catch (e) {
          console.error('Error fetching score', e)
          return 0
        }
      })
      .catch((err) => console.log(err));
  }
  
  const signOut = async () => {
    try {
      await Auth.signOut();
      isAuthenticated.value = false
    } catch (e) {
      console.error(e)
    }
  }
  
</script>

<template>
  <div v-if="isAuthenticated">
    <button @click="fetchScores">Get Score</button>
    <button @click="signOut">Sign Out</button>
  </div>
  <Authenticator v-else :onSignIn="()=>{fetchScores();isAuthenticated=true;}">
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
