<script lang="ts" setup>
import { computed } from 'vue';
import { Score } from '../interfaces';

interface Props {
  scores: Score[];
}

const props = defineProps<Props>();

// UNIXタイムスタンプを人間が読める形式に変換します。
const formattedTimestamp = computed(() => {
  const date = new Date(props.timestamp * 1000);
  console.log(props.messages)
  return date.toLocaleString();
});

const sortedScores = computed(() => {
  return [...props.scores].sort((a, b) => b.timestamp - a.timestamp);
});

const formatDate = (timestamp: number) => {
  return new Date(timestamp * 1000).toLocaleString();
};

const getScoreDifference = (currentScore: number, previousScore: number) => {
  const diff = currentScore - previousScore;
  return diff > 0 ? `+${diff}` : diff.toString();
};
</script>

<template>
  <div class="message-history">
    <h2 class="message-description">ベンチマーカーからのメッセージ</h2>
    <div v-for="(score, index) in sortedScores" :key="score.timestamp" class="message-item">
      <div class="message-header">
        <span class="timestamp">{{ formatDate(score.timestamp) }}</span>
        <span class="score">スコア: {{ score.score }}</span>
        <span v-if="index < sortedScores.length - 1" class="score-diff" 
              :class="{ positive: score.score > sortedScores[index + 1].score, 
                        negative: score.score < sortedScores[index + 1].score }">
          ({{ getScoreDifference(score.score, sortedScores[index + 1].score) }})
        </span>
      </div>
      <div v-for="(message, msgIndex) in score.messages" :key="msgIndex" class="message-content">
        {{ message }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.message-history {
  max-height: 400px;
  overflow-y: auto;
  padding: 10px;
  background-color: #f5f5f5;
  border-radius: 5px;
}

.message-description {
  font-weight: bold;
  font-size: 1.5em;
  margin-bottom: 10px;
}

.message-item {
  margin-bottom: 15px;
  padding: 10px;
  background-color: white;
  border-radius: 5px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}
