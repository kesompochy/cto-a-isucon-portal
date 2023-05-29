<script setup lang="ts">
  import { ref } from 'vue';
  import { API, Auth, graphqlOperation } from 'aws-amplify';
  import { Authenticator } from '@aws-amplify/ui-vue';
  import { getAllScores } from './graphql/queries/getAllScores';
  import '@aws-amplify/ui-vue/styles.css'

  const fetchScores = async ()=> {
    Auth.currentAuthenticatedUser({ bypassCache: true })
      .then(async () => {
        try {
          const result = await API.graphql(graphqlOperation(getAllScores));
          if ('data' in result) {
            const fetchedScore = result.data.getAllScores;
            console.log(fetchedScore)
            return score
          }
          return 0
        } catch (e) {
          console.error('Error fetching score', e)
          return 0
        }
      })
      .catch((err) => console.log(err));

  }
  let score = ref(0)

  const isAuthenticated = ref(false)
</script>

<template>
    <div v-if="isAuthenticated">
      <button @click="fetchScores">Get Score</button>
    </div>
    <div v-else>
      <authenticator>
        <template v-slot="{ user, signOut }">
          <h1>Hello {{ user.username }}!</h1>
          <button @click="signOut">Sign Out</button>
          <h1>{{ score }}</h1>
        </template>
      </authenticator>
    </div>

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
