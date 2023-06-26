<script lang="ts" setup>
import { computed } from 'vue';

interface Props {
  messages: string[];
  timestamp: number;
}

const props = defineProps<Props>();

// UNIXタイムスタンプを人間が読める形式に変換します。
const formattedTimestamp = computed(() => {
  const date = new Date(props.timestamp * 1000);
  console.log(props.messages)
  return date.toLocaleString();
});
</script>

<template>
<div class="message-item" v-if="messages">
    <div class="message-description">
      ベンチマーカーからのメッセージ
    </div>
    <div class="message-content" v-for="(message, index) in messages" :key="index">
      <span class="timestamp">{{ formattedTimestamp }}</span>
      <span class="message">{{ message }}</span>
    </div>
</div>
</template>

<style scoped>
.message-item {
  text-align: left;
}

.message-description {
  font-weight: bold;
  font-size: 1.5em;
}

.timestamp {
  font-size: 0.8em;
  color: #999;
  margin-right: 10px;
}
</style>
