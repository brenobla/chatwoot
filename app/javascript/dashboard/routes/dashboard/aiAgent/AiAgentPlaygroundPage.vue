<template>
  <div class="flex flex-col flex-1 h-full overflow-y-auto p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">Playground</h1>
        <p class="text-sm text-n-slate-10 mt-1">
          Teste seus agentes de IA em tempo real
        </p>
      </div>
    </div>

    <!-- Agent Selector -->
    <div class="mb-6">
      <label class="text-sm font-medium text-n-slate-12">Agente</label>
      <select
        v-model="selectedAgentId"
        class="mt-1.5 block w-full max-w-xs rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
      >
        <option value="">Selecione um agente...</option>
        <option v-for="agent in agents" :key="agent.id" :value="agent.id">
          {{ agent.name }}
        </option>
      </select>
    </div>

    <!-- Chat Area -->
    <div v-if="selectedAgentId" class="w-full flex-1 flex flex-col rounded-xl outline outline-1 outline-n-slate-4 bg-white overflow-hidden">
      <!-- Chat Header -->
      <div class="px-5 py-4 border-b border-n-slate-3 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-lg bg-n-brand/10 flex items-center justify-center">
            <span class="i-lucide-bot w-4.5 h-4.5 text-n-brand" />
          </div>
          <div>
            <p class="text-sm font-medium text-n-slate-12">{{ selectedAgent?.name }}</p>
            <p class="text-xs text-n-slate-9">{{ selectedAgent?.config?.openai_model || 'gpt-4o' }}</p>
          </div>
        </div>
        <button
          class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium text-n-slate-11 hover:bg-n-slate-2 transition-colors"
          @click="clearChat"
        >
          <span class="i-lucide-trash-2 w-3.5 h-3.5" />
          Limpar
        </button>
      </div>

      <!-- Messages -->
      <div ref="chatContainer" class="flex-1 overflow-y-auto p-5 space-y-3 min-h-[400px]">
        <div v-if="!messages.length" class="flex flex-col items-center justify-center h-full text-center">
          <span class="i-lucide-message-square w-10 h-10 text-n-slate-9 mb-3" />
          <p class="text-sm text-n-slate-9">Envie uma mensagem para testar o agente</p>
        </div>
        <div
          v-for="(msg, idx) in messages"
          :key="idx"
          class="flex"
          :class="msg.role === 'user' ? 'justify-end' : 'justify-start'"
        >
          <div
            class="max-w-[80%] px-4 py-2.5 rounded-xl text-sm"
            :class="msg.role === 'user'
              ? 'bg-n-brand text-white rounded-br-sm'
              : 'bg-n-slate-2 text-n-slate-12 rounded-bl-sm'"
          >
            <p class="whitespace-pre-wrap">{{ msg.content }}</p>
          </div>
        </div>
        <div v-if="isLoading" class="flex justify-start">
          <div class="bg-n-slate-2 text-n-slate-12 px-4 py-2.5 rounded-xl rounded-bl-sm">
            <span class="i-lucide-loader-2 w-4 h-4 animate-spin inline-block" />
          </div>
        </div>
      </div>

      <!-- Input -->
      <div class="px-5 py-4 border-t border-n-slate-3 flex gap-2">
        <input
          v-model="inputText"
          type="text"
          placeholder="Digite uma mensagem para testar..."
          class="flex-1 rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
          @keydown.enter="sendMessage"
        />
        <button
          class="h-10 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 disabled:opacity-50 flex items-center gap-1.5"
          :disabled="!inputText.trim() || isLoading"
          @click="sendMessage"
        >
          <span class="i-lucide-send w-4 h-4" />
          Enviar
        </button>
      </div>
    </div>

    <!-- Empty state -->
    <div v-else class="w-full flex items-center justify-center py-24 rounded-xl outline outline-1 outline-n-slate-3 bg-n-slate-1">
      <div class="text-center">
        <span class="i-lucide-message-square w-12 h-12 text-n-slate-9 mx-auto mb-4" />
        <p class="text-base font-medium text-n-slate-12">Selecione um agente</p>
        <p class="text-sm text-n-slate-9 mt-1">Escolha um agente acima para iniciar o teste</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import axios from 'axios';

const store = useStore();
const route = useRoute();

const agents = useMapGetter('aiAgents/getRecords');

const accountId = computed(() => route.params.accountId);
const apiHeaders = computed(() => ({
  api_access_token: store.getters['auth/getCurrentUser']?.access_token,
}));
const apiUrl = path => `/api/v1/accounts/${accountId.value}${path}`;

const selectedAgentId = ref('');
const selectedAgent = computed(() => agents.value.find(a => a.id == selectedAgentId.value));
const messages = ref([]);
const inputText = ref('');
const isLoading = ref(false);
const chatContainer = ref(null);

onMounted(() => {
  store.dispatch('aiAgents/get');
});

watch(selectedAgentId, () => {
  messages.value = [];
  inputText.value = '';
});

const sendMessage = async () => {
  const text = inputText.value.trim();
  if (!text || isLoading.value || !selectedAgentId.value) return;

  messages.value.push({ role: 'user', content: text });
  inputText.value = '';
  isLoading.value = true;

  await nextTick();
  scrollToBottom();

  try {
    const history = messages.value
      .filter(m => m.role !== 'system')
      .slice(0, -1)
      .map(m => ({ role: m.role, content: m.content }));

    const { data } = await axios.post(
      apiUrl(`/ai_agents/${selectedAgentId.value}/playground`),
      { message_content: text, message_history: history },
      { headers: apiHeaders.value }
    );

    const response = data.response || data.error || 'Sem resposta';
    messages.value.push({ role: 'assistant', content: response });
  } catch (e) {
    messages.value.push({
      role: 'assistant',
      content: 'Erro ao gerar resposta. Verifique a configuração da API.',
    });
  } finally {
    isLoading.value = false;
    await nextTick();
    scrollToBottom();
  }
};

const scrollToBottom = () => {
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

const clearChat = () => {
  messages.value = [];
};
</script>
