<template>
  <div class="ai-agent-iframe-wrapper">
    <iframe
      :src="iframeSrc"
      class="ai-agent-iframe"
      frameborder="0"
      allow="clipboard-read; clipboard-write"
    />
  </div>
</template>

<script setup>
const iframeSrc =
  'https://chatwoot-ai-bot-production-15bc.up.railway.app/admin?token=admin123';
</script>

<style scoped>
.ai-agent-iframe-wrapper {
  display: flex;
  flex: 1;
  height: 100%;
  width: 100%;
  overflow: hidden;
}

.ai-agent-iframe {
  flex: 1;
  width: 100%;
  height: 100%;
  border: none;
}
</style>
