<template>
  <div class="flex flex-col h-full overflow-y-auto p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-3">
        <button
          class="h-8 w-8 rounded-lg flex items-center justify-center text-n-slate-11 hover:bg-n-slate-3"
          @click="$router.push({ name: 'ai_agent_index' })"
        >
          <span class="i-lucide-arrow-left w-4 h-4" />
        </button>
        <div>
          <h1 class="text-lg font-medium text-n-slate-12">
            {{ agent?.name || 'Agente' }}
          </h1>
          <p class="text-xs text-n-slate-9">Configurações do agente</p>
        </div>
      </div>
      <button
        class="h-10 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110"
        @click="saveAgent"
      >
        Salvar
      </button>
    </div>

    <!-- Sub-tabs -->
    <div class="flex items-center gap-6 mb-6 border-b border-n-slate-4">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        class="pb-3 text-sm font-medium transition-colors cursor-pointer whitespace-nowrap"
        :class="
          currentTab === tab.id
            ? 'text-n-brand border-b-2 border-n-brand'
            : 'text-n-slate-11 border-b-2 border-transparent hover:text-n-slate-12'
        "
        @click="currentTab = tab.id"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- Settings Tab -->
    <div v-show="currentTab === 'settings'" class="max-w-2xl space-y-5">
      <!-- Identificação -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <h4 class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4">Identificação</h4>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-n-slate-12">Nome</label>
            <input v-model="form.name" type="text" class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3" />
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12">Modelo</label>
            <select v-model="form.config.openai_model" class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3">
              <option value="gpt-4o">GPT-4o</option>
              <option value="gpt-4o-mini">GPT-4o Mini</option>
              <option value="gpt-4-turbo">GPT-4 Turbo</option>
              <option value="gpt-3.5-turbo">GPT-3.5 Turbo</option>
            </select>
          </div>
        </div>
        <div class="mt-4">
          <label class="text-sm font-medium text-n-slate-12">Descrição</label>
          <input v-model="form.description" type="text" class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3" />
        </div>
      </div>

      <!-- Prompt -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <h4 class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4">Prompt do Sistema</h4>
        <textarea v-model="form.config.system_prompt" rows="10" placeholder="Instruções do agente..."
          class="block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 p-3 resize-y font-mono text-xs leading-relaxed" />
      </div>

      <!-- Parâmetros -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <h4 class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4">Parâmetros</h4>
        <div class="grid grid-cols-3 gap-4">
          <div>
            <label class="text-sm font-medium text-n-slate-12">Temperatura: {{ form.config.temperature }}</label>
            <input v-model="form.config.temperature" type="range" min="0" max="2" step="0.1" class="mt-2 w-full accent-[#2781F6]" />
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12">Max Tokens</label>
            <input v-model="form.config.max_tokens" type="number" min="50" max="4096" class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3" />
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12">Modo</label>
            <select v-model="form.config.mode" class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3">
              <option value="auto">Automático</option>
              <option value="suggest">Sugestão</option>
            </select>
          </div>
        </div>
      </div>

      <!-- Handoff -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <h4 class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4">Handoff</h4>
        <div>
          <label class="text-sm font-medium text-n-slate-12">Palavras-chave</label>
          <input v-model="form.config.handoff_keywords" type="text" placeholder="falar com humano, atendente"
            class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3" />
        </div>
        <div class="mt-4">
          <label class="text-sm font-medium text-n-slate-12">Mensagem de handoff</label>
          <textarea v-model="form.config.handoff_message" rows="2"
            class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 p-3 resize-none" />
        </div>
      </div>

      <!-- Knowledge Base -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <h4 class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4">Base de Conhecimento</h4>
        <textarea v-model="form.config.knowledge_base" rows="6" placeholder="FAQs, políticas, regras..."
          class="block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 p-3 resize-y font-mono text-xs leading-relaxed" />
      </div>

      <!-- Status -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <div class="flex items-center justify-between">
          <div>
            <div class="text-sm font-medium text-n-slate-12">Agente ativo</div>
            <div class="text-xs text-n-slate-9 mt-1">Ativar ou desativar respostas automáticas</div>
          </div>
          <button
            :class="form.active ? 'bg-n-brand' : 'bg-n-slate-6'"
            class="relative w-11 h-6 rounded-full transition-colors cursor-pointer"
            @click="form.active = !form.active"
          >
            <span
              :class="form.active ? 'translate-x-5' : 'translate-x-0.5'"
              class="inline-block w-5 h-5 bg-white rounded-full transform transition-transform shadow-sm mt-0.5"
            />
          </button>
        </div>
      </div>
    </div>

    <!-- Inboxes Tab -->
    <div v-show="currentTab === 'inboxes'" class="max-w-2xl">
      <p class="text-sm text-n-slate-11 mb-4">Selecione as caixas de entrada onde este agente deve atuar</p>
      <div class="space-y-2">
        <div
          v-for="inbox in accountInboxes"
          :key="inbox.id"
          class="flex items-center justify-between py-3 px-4 rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white"
        >
          <div class="flex items-center gap-3">
            <span class="i-lucide-inbox w-4 h-4 text-n-slate-9" />
            <div>
              <div class="text-sm font-medium text-n-slate-12">{{ inbox.name }}</div>
              <div class="text-xs text-n-slate-9">{{ inbox.channel_type }}</div>
            </div>
          </div>
          <button
            :class="isInboxConnected(inbox.id) ? 'bg-n-brand' : 'bg-n-slate-6'"
            class="relative w-11 h-6 rounded-full transition-colors cursor-pointer"
            @click="toggleInbox(inbox.id)"
          >
            <span
              :class="isInboxConnected(inbox.id) ? 'translate-x-5' : 'translate-x-0.5'"
              class="inline-block w-5 h-5 bg-white rounded-full transform transition-transform shadow-sm mt-0.5"
            />
          </button>
        </div>
      </div>
    </div>

    <!-- Playground Tab -->
    <div v-show="currentTab === 'playground'" class="max-w-4xl">
      <div class="grid grid-cols-2 gap-6">
        <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white">
          <div class="px-5 py-4 border-b border-n-slate-4">
            <div class="text-sm font-medium text-n-slate-12">Mensagem de teste</div>
          </div>
          <div class="p-5">
            <textarea v-model="playgroundMessage" rows="6" placeholder="Digite a mensagem do cliente..."
              class="block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 p-3 resize-none" />
            <button
              class="mt-4 h-10 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 disabled:opacity-50"
              :disabled="!playgroundMessage || playgroundLoading"
              @click="testPlayground"
            >
              {{ playgroundLoading ? 'Gerando...' : 'Enviar' }}
            </button>
          </div>
        </div>
        <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white">
          <div class="px-5 py-4 border-b border-n-slate-4">
            <div class="text-sm font-medium text-n-slate-12">Resposta do Agente</div>
          </div>
          <div class="p-5">
            <div v-if="!playgroundResponse" class="text-sm text-n-slate-9 italic">A resposta aparecerá aqui...</div>
            <div v-else class="text-sm text-n-slate-12 whitespace-pre-wrap leading-relaxed">{{ playgroundResponse }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import AiAgentAPI from 'dashboard/api/aiAgent';

const store = useStore();
const route = useRoute();

const agents = useMapGetter('aiAgents/getRecords');
const agentId = computed(() => route.params.agentId);
const agent = computed(() => agents.value.find(a => a.id == agentId.value));

const accountInboxes = useMapGetter('inboxes/getInboxes');

const currentTab = ref('settings');
const tabs = [
  { id: 'settings', label: 'Configurações' },
  { id: 'inboxes', label: 'Caixas de Entrada' },
  { id: 'playground', label: 'Playground' },
];

const form = reactive({
  name: '',
  description: '',
  active: true,
  config: {
    system_prompt: '',
    openai_model: 'gpt-4o',
    temperature: 0.7,
    max_tokens: 500,
    mode: 'auto',
    handoff_keywords: '',
    handoff_message: '',
    knowledge_base: '',
  },
});

const connectedInboxIds = ref([]);
const playgroundMessage = ref('');
const playgroundResponse = ref('');
const playgroundLoading = ref(false);

onMounted(async () => {
  await store.dispatch('aiAgents/get');
  await store.dispatch('inboxes/get');
  loadAgentData();
  loadConnectedInboxes();
});

watch(agent, () => loadAgentData());

const loadAgentData = () => {
  if (!agent.value) return;
  form.name = agent.value.name;
  form.description = agent.value.description;
  form.active = agent.value.active;
  form.config = { ...form.config, ...agent.value.config };
};

const loadConnectedInboxes = async () => {
  if (!agentId.value) return;
  try {
    const { data } = await AiAgentAPI.getInboxes(agentId.value);
    connectedInboxIds.value = data.map(i => i.inbox_id);
  } catch (e) {
    // handle
  }
};

const isInboxConnected = id => connectedInboxIds.value.includes(id);

const toggleInbox = async inboxId => {
  try {
    if (isInboxConnected(inboxId)) {
      await AiAgentAPI.disconnectInbox(agentId.value, inboxId);
      connectedInboxIds.value = connectedInboxIds.value.filter(
        id => id !== inboxId
      );
    } else {
      await AiAgentAPI.connectInbox(agentId.value, inboxId);
      connectedInboxIds.value.push(inboxId);
    }
  } catch (e) {
    // handle
  }
};

const saveAgent = async () => {
  try {
    await store.dispatch('aiAgents/update', {
      id: agentId.value,
      ...form,
    });
  } catch (e) {
    // handle
  }
};

const testPlayground = async () => {
  playgroundLoading.value = true;
  playgroundResponse.value = '';
  try {
    const { data } = await AiAgentAPI.playground({
      agentId: agentId.value,
      messageContent: playgroundMessage.value,
      messageHistory: [],
    });
    playgroundResponse.value = data.response || data.error || 'Sem resposta';
  } catch (e) {
    playgroundResponse.value = 'Erro: ' + e.message;
  }
  playgroundLoading.value = false;
};
</script>
