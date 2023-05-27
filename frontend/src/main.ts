import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import { Amplify } from 'aws-amplify'

Amplify.configure({
    Auth: {
        region: 'ap-northeast-1',
        userPoolId: 'ap-northeast-1_owwW23cX9',
        userPoolWebClientId: '28pbs1v5v549utukg74m89o2q3',
        identityPoolId: 'ap-northeast-1:46a21551-aaae-4caf-8b0b-d4b8301554e4',
    },
    aws_appsync_graphqlEndpoint: 'https://6bqrafkynnbbzgkticdkxuawki.appsync-api.ap-northeast-1.amazonaws.com/graphql',
    aws_appsync_region: 'ap-northeast-1',
    aws_appsync_authenticationType: 'AMAZON_COGNITO_USER_POOLS',
})


/*const checkUserLoggedIn = async () => {
    try {
        const user = await Auth.currentAuthenticatedUser()
        console.log('user is signed in:', user)
    } catch (e) {
        const user = await Auth.signIn('team0', 'Ilovecookingcurry1!')
        console.log(user)
    }
}

checkUserLoggedIn()*/


createApp(App).mount('#app')
