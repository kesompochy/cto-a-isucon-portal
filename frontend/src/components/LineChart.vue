<script lang="ts" setup>
import { nextTick, onMounted, ref } from 'vue'

interface Score {
    timestamp: number
    teamId: number
    score: number
}
interface Props {
    scores: Score[]
}

const props = defineProps<Props>()

const canvas = ref<HTMLCanvasElement | null>(null)

onMounted(async ()=>{
    await nextTick()
    const ctx = canvas?.value?.getContext('2d')
    if (!ctx) {
        console.error('canvas要素が存在しません')
        return
    } 
    props.scores.map(score => {
        console.log(score.score)
    })

    ctx.fillRect(0, 0, 10,10)
})
</script>

<template>
    <canvas ref="canvas"></canvas>
</template>

<style lang="sass" scoped>
</style>
