<script lang="ts" setup>
import { computed } from 'vue';

interface Props {
  message: string;
  timestamp: number;
}

const props = defineProps<Props>();

// UNIXタイムスタンプを人間が読める形式に変換します。
const formattedTimestamp = computed(() => {
  const date = new Date(props.timestamp * 1000);
  console.log(props.message)
  return date.toLocaleString();
});
</script>

<template>
<div class="message-item">
    <div class="message-content">
    {{ message }}
    </div>
    <div class="timestamp">
    {{ formattedTimestamp }}
    </div>
</div>
</template>

<style scoped>
.message-item {
  /* ここにスタイルを追加します */
}

.message-content {
  /* メッセージのスタイルを追加します */
}

.timestamp {
  /* タイムスタンプのスタイルを追加します */
}
</style>
