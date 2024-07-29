import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import { Amplify } from 'aws-amplify'

const AUTH_REGION = import.meta.env.VITE_AUTH_REGION || 'ap-northeast-1'
const AUTH_USER_POOL_ID = import.meta.env.VITE_USER_POOL_ID || 'ap-northeast-1_owwW23cX9'
const AUTH_USER_POOL_WEB_CLIENT_ID = import.meta.env.VITE_USER_POOL_WEB_CLIENT_ID || '28pbs1v5v549utukg74m89o2q3'
const APPSYNC_GRAPHQL_ENDPOINT = import.meta.env.VITE_APPSYNC_GRAPHQL_ENDPOINT || 'https://6bqrafkynnbbzgkticdkxuawki.appsync-api.ap-northeast-1.amazonaws.com/graphql'
const APPSYNC_REGION = import.meta.env.VITE_APPSYNC_REGION || 'ap-northeast-1'

Amplify.configure({
    Auth: {
        region: AUTH_REGION,
        userPoolId: AUTH_USER_POOL_ID,
        userPoolWebClientId: AUTH_USER_POOL_WEB_CLIENT_ID,
    },
    aws_appsync_graphqlEndpoint: APPSYNC_GRAPHQL_ENDPOINT,
    aws_appsync_region: APPSYNC_REGION,
    aws_appsync_authenticationType: 'AMAZON_COGNITO_USER_POOLS',
})

createApp(App).mount('#app')
