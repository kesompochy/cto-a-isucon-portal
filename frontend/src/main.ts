import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import { Amplify } from 'aws-amplify'

Amplify.configure({
    Auth: {
        region: 'ap-northeast-1',
        userPoolId: 'ap-northeast-1_owwW23cX9',
        userPoolWebClientId: '28pbs1v5v549utukg74m89o2q3',
    },
    aws_appsync_graphqlEndpoint: 'https://6bqrafkynnbbzgkticdkxuawki.appsync-api.ap-northeast-1.amazonaws.com/graphql',
    aws_appsync_region: 'ap-northeast-1',
    aws_appsync_authenticationType: 'AMAZON_COGNITO_USER_POOLS',
})

createApp(App).mount('#app')