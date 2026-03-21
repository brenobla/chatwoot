<template>
  <div class="flex flex-col flex-1 h-full overflow-y-auto p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div class="flex items-center gap-3">
        <button
          class="h-8 w-8 rounded-lg flex items-center justify-center text-n-slate-11 hover:bg-n-slate-3 transition-colors"
          @click="$router.push({ name: 'ai_agent_index' })"
        >
          <span class="i-lucide-arrow-left w-4 h-4" />
        </button>
        <div>
          <h1 class="text-lg font-medium text-n-slate-12">
            {{ agent?.name || 'Agente' }}
          </h1>
          <p class="text-xs text-n-slate-9">Editar configuracoes do agente</p>
        </div>
      </div>
      <button
        v-if="currentTab === 'configuracoes'"
        class="h-9 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 disabled:opacity-50"
        :disabled="!form.name || isSaving"
        @click="saveAgent"
      >
        <span
          v-if="isSaving"
          class="i-lucide-loader-2 w-4 h-4 animate-spin"
        />
        <span v-else>Salvar</span>
      </button>
    </div>

    <!-- Horizontal Tabs -->
    <div class="flex items-center gap-6 mb-6 border-b border-n-slate-4">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        class="pb-3 text-sm font-medium transition-colors cursor-pointer whitespace-nowrap"
        :class="
          currentTab === tab.key
            ? 'text-n-brand border-b-2 border-n-brand'
            : 'text-n-slate-11 border-b-2 border-transparent hover:text-n-slate-12'
        "
        @click="currentTab = tab.key"
      >
        {{ tab.label }}
      </button>
    </div>

    <!-- TAB: Configuracoes -->
    <div v-show="currentTab === 'configuracoes'" class="w-full space-y-5">
      <!-- Identificacao -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <h4
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4"
        >
          Identificacao
        </h4>
        <div class="space-y-4">
          <div>
            <label class="text-sm font-medium text-n-slate-12">Nome</label>
            <input
              v-model="form.name"
              type="text"
              placeholder="Ex: Suporte Curso Beta"
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            />
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12"
              >Descricao</label
            >
            <input
              v-model="form.description"
              type="text"
              placeholder="Breve descricao do agente"
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            />
          </div>
        </div>
      </div>

      <!-- Prompt do Sistema -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <h4
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4"
        >
          Prompt do Sistema
        </h4>
        <textarea
          v-model="form.system_prompt"
          rows="6"
          placeholder="Voce e um atendente de suporte ao cliente..."
          class="block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y font-mono text-xs leading-relaxed"
        />
      </div>

      <!-- Modelo e Parametros -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <h4
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4"
        >
          Modelo e Parametros
        </h4>
        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="text-sm font-medium text-n-slate-12">Modelo</label>
            <select
              v-model="form.openai_model"
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            >
              <option value="gpt-4o">GPT-4o</option>
              <option value="gpt-4o-mini">GPT-4o Mini</option>
              <option value="gpt-4.1">GPT-4.1</option>
              <option value="gpt-4.1-mini">GPT-4.1 Mini</option>
            </select>
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12">Modo</label>
            <select
              v-model="form.mode"
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            >
              <option value="auto">Automatico</option>
              <option value="suggest">Sugestao</option>
            </select>
          </div>
        </div>
        <div class="grid grid-cols-3 gap-4 mt-4">
          <div>
            <label class="text-sm font-medium text-n-slate-12">
              Temperatura
              <span class="text-n-slate-9 font-normal"
                >({{ form.temperature }})</span
              >
            </label>
            <input
              v-model.number="form.temperature"
              type="range"
              min="0"
              max="1"
              step="0.1"
              class="mt-2 w-full accent-n-brand"
            />
            <div class="flex justify-between text-xs text-n-slate-9 mt-0.5">
              <span>Preciso</span>
              <span>Criativo</span>
            </div>
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12"
              >Max. tokens</label
            >
            <input
              v-model.number="form.max_tokens"
              type="number"
              min="100"
              max="4000"
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            />
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12"
              >Msgs de contexto</label
            >
            <input
              v-model.number="form.context_messages"
              type="number"
              min="1"
              max="50"
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            />
          </div>
        </div>
      </div>

      <!-- Idioma -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <h4
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4"
        >
          Idioma
        </h4>
        <select
          v-model="form.language"
          class="block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
        >
          <option value="pt-BR">Portugues (BR)</option>
          <option value="en">English</option>
          <option value="es">Espanol</option>
        </select>
      </div>

      <!-- Mensagens -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <h4
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4"
        >
          Mensagens
        </h4>
        <div class="space-y-4">
          <div>
            <label class="text-sm font-medium text-n-slate-12"
              >Mensagem de boas-vindas</label
            >
            <input
              v-model="form.welcome_message"
              type="text"
              placeholder="Ola! Como posso ajudar?"
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            />
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12"
              >Mensagem de handoff</label
            >
            <input
              v-model="form.handoff_message"
              type="text"
              placeholder="Vou transferir voce para um atendente humano..."
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            />
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12"
              >Mensagem de resolucao</label
            >
            <input
              v-model="form.resolution_message"
              type="text"
              placeholder="Fico feliz em ter ajudado! Ate a proxima."
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            />
          </div>
        </div>
      </div>

      <!-- Base de Conhecimento -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <h4
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4"
        >
          Base de Conhecimento
        </h4>
        <textarea
          v-model="form.knowledge_base"
          rows="4"
          placeholder="Cole aqui FAQs, politicas, informacoes do produto..."
          class="block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y"
        />
      </div>

      <!-- Guardrails -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <h4
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-2"
        >
          Guardrails
        </h4>
        <p class="text-xs text-n-slate-9 mb-3">
          Regras obrigatorias que o agente deve seguir (uma por linha)
        </p>
        <textarea
          v-model="form.guardrails_text"
          rows="3"
          placeholder="Nunca compartilhe dados pessoais de clientes&#10;Sempre confirme o pedido antes de processar"
          class="block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y"
        />
      </div>

      <!-- Diretrizes de Resposta -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <h4
          class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-2"
        >
          Diretrizes de Resposta
        </h4>
        <p class="text-xs text-n-slate-9 mb-3">
          Orientacoes de estilo e formato (uma por linha)
        </p>
        <textarea
          v-model="form.response_guidelines_text"
          rows="3"
          placeholder="Use tom profissional mas amigavel&#10;Respostas curtas e diretas"
          class="block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y"
        />
      </div>

      <!-- Status -->
      <div
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5"
      >
        <div class="flex items-center justify-between">
          <div>
            <div class="text-sm font-medium text-n-slate-12">Agente ativo</div>
            <div class="text-xs text-n-slate-9 mt-1">
              Ativar ou desativar respostas automaticas
            </div>
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

    <!-- TAB: Documentos -->
    <div v-show="currentTab === 'documentos'" class="w-full space-y-5">
      <!-- Upload Zone -->
      <div
        class="border-2 border-dashed border-n-slate-4 rounded-xl p-8 text-center hover:border-n-brand/50 transition-colors"
        :class="{ 'border-n-brand bg-n-brand/5': dragOver }"
        @dragover.prevent="dragOver = true"
        @dragleave.prevent="dragOver = false"
        @drop.prevent="handleFileDrop"
      >
        <span
          class="i-lucide-upload-cloud w-10 h-10 text-n-slate-9 mx-auto mb-3"
        />
        <p class="text-sm text-n-slate-11 mb-1">Arraste arquivos aqui ou</p>
        <label
          class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-n-brand text-white text-sm font-medium cursor-pointer hover:brightness-110"
        >
          <span class="i-lucide-plus w-4 h-4" />
          Selecionar arquivo
          <input
            type="file"
            class="hidden"
            accept=".pdf,.txt,.csv,.docx"
            @change="handleFileSelect"
          />
        </label>
        <p class="text-xs text-n-slate-9 mt-2">PDF, TXT, CSV, DOCX</p>
      </div>

      <!-- Upload Progress -->
      <div
        v-if="isUploading"
        class="flex items-center gap-3 p-4 rounded-lg bg-n-slate-1"
      >
        <span class="i-lucide-loader-2 w-5 h-5 animate-spin text-n-brand" />
        <span class="text-sm text-n-slate-11">Enviando documento...</span>
      </div>

      <!-- Documents List -->
      <div v-if="documents.length" class="space-y-2">
        <div
          v-for="doc in documents"
          :key="doc.id"
          class="flex items-center justify-between p-3 rounded-lg outline outline-1 outline-n-slate-4 bg-white"
        >
          <div class="flex items-center gap-3">
            <span
              class="w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0"
              :class="docIconClass(doc.file_type)"
            >
              <span class="i-lucide-file-text w-4.5 h-4.5" />
            </span>
            <div>
              <p class="text-sm font-medium text-n-slate-12">
                {{ doc.file_name }}
              </p>
              <p class="text-xs text-n-slate-9">
                {{ doc.file_type.toUpperCase() }}
                <span v-if="doc.file_size">
                  &middot; {{ formatFileSize(doc.file_size) }}
                </span>
              </p>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <span
              class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium"
              :class="docStatusClass(doc.status)"
            >
              {{ docStatusLabel(doc.status) }}
            </span>
            <button
              class="p-1.5 rounded-md hover:bg-red-50 text-n-slate-9 hover:text-red-600 transition-colors"
              @click="deleteDocument(doc)"
            >
              <span class="i-lucide-trash-2 w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      <!-- Empty docs -->
      <div v-else-if="!isUploading" class="text-center py-8">
        <span
          class="i-lucide-file-text w-10 h-10 text-n-slate-9 mx-auto mb-3"
        />
        <p class="text-sm text-n-slate-9">Nenhum documento enviado</p>
      </div>
    </div>

    <!-- TAB: Playground -->
    <div
      v-show="currentTab === 'playground'"
      class="w-full flex flex-col"
      style="height: calc(100vh - 200px)"
    >
      <!-- Chat Messages -->
      <div ref="chatContainer" class="flex-1 overflow-y-auto space-y-3 mb-4">
        <div
          v-if="!playgroundMessages.length"
          class="flex flex-col items-center justify-center py-16"
        >
          <span
            class="i-lucide-message-square w-10 h-10 text-n-slate-9 mb-3"
          />
          <p class="text-sm text-n-slate-9">
            Envie uma mensagem para testar o agente
          </p>
        </div>
        <div
          v-for="(msg, idx) in playgroundMessages"
          :key="idx"
          class="flex"
          :class="msg.role === 'user' ? 'justify-end' : 'justify-start'"
        >
          <div
            class="max-w-[80%] px-4 py-2.5 rounded-xl text-sm"
            :class="
              msg.role === 'user'
                ? 'bg-n-brand text-white rounded-br-sm'
                : 'bg-n-slate-2 text-n-slate-12 rounded-bl-sm'
            "
          >
            <p class="whitespace-pre-wrap">{{ msg.content }}</p>
          </div>
        </div>
        <div v-if="playgroundLoading" class="flex justify-start">
          <div
            class="bg-n-slate-2 text-n-slate-12 px-4 py-2.5 rounded-xl rounded-bl-sm"
          >
            <span
              class="i-lucide-loader-2 w-4 h-4 animate-spin inline-block"
            />
          </div>
        </div>
      </div>

      <!-- Chat Input -->
      <div class="flex gap-2 flex-shrink-0">
        <input
          v-model="playgroundInput"
          type="text"
          placeholder="Digite uma mensagem para testar..."
          class="flex-1 rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
          @keydown.enter="sendPlaygroundMessage"
        />
        <button
          class="h-10 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 disabled:opacity-50 flex items-center gap-1.5"
          :disabled="!playgroundInput.trim() || playgroundLoading"
          @click="sendPlaygroundMessage"
        >
          <span class="i-lucide-send w-4 h-4" />
          Enviar
        </button>
      </div>
    </div>

    <!-- TAB: Caixas de Entrada -->
    <div v-show="currentTab === 'caixas'" class="w-full">
      <p class="text-sm text-n-slate-11 mb-4">
        Selecione as caixas de entrada onde este agente deve atuar
      </p>

      <!-- Add inbox -->
      <div class="flex gap-2 mb-5">
        <select
          v-model="selectedInboxId"
          class="flex-1 rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
        >
          <option value="">Selecione uma caixa de entrada...</option>
          <option
            v-for="inbox in availableInboxes"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }} ({{ inbox.channel_type }})
          </option>
        </select>
        <button
          class="h-10 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 disabled:opacity-50"
          :disabled="!selectedInboxId"
          @click="connectInbox"
        >
          Conectar
        </button>
      </div>

      <!-- Connected inboxes -->
      <div v-if="connectedInboxes.length" class="space-y-2">
        <div
          v-for="inbox in connectedInboxes"
          :key="inbox.id"
          class="flex items-center justify-between p-3 rounded-lg outline outline-1 outline-n-slate-4 bg-white"
        >
          <div class="flex items-center gap-3">
            <div
              class="w-9 h-9 rounded-lg bg-n-brand/10 flex items-center justify-center flex-shrink-0"
            >
              <span class="i-lucide-inbox w-4.5 h-4.5 text-n-brand" />
            </div>
            <div>
              <p class="text-sm font-medium text-n-slate-12">
                {{ inbox.inbox_name }}
              </p>
              <p class="text-xs text-n-slate-9">{{ inbox.channel_type }}</p>
            </div>
          </div>
          <button
            class="inline-flex items-center gap-1 px-2.5 py-1 rounded-md text-xs font-medium text-red-600 hover:bg-red-50 transition-colors"
            @click="disconnectInbox(inbox)"
          >
            <span class="i-lucide-unplug w-3.5 h-3.5" />
            Desconectar
          </button>
        </div>
      </div>

      <!-- Empty inboxes -->
      <div v-else class="text-center py-8">
        <span class="i-lucide-inbox w-10 h-10 text-n-slate-9 mx-auto mb-3" />
        <p class="text-sm text-n-slate-9">
          Nenhuma caixa de entrada conectada
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, nextTick, watch } from 'vue';
import { useStore } from 'vuex';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import axios from 'axios';

const store = useStore();
const route = useRoute();

const agents = useMapGetter('aiAgents/getRecords');

const agentId = computed(() => route.params.agentId);
const agent = computed(() => agents.value.find(a => a.id == agentId.value));
const accountId = computed(() => route.params.accountId);

const apiHeaders = computed(() => ({
  api_access_token: store.getters['auth/getCurrentUser']?.access_token,
}));
const apiUrl = path => `/api/v1/accounts/${accountId.value}${path}`;

const currentTab = ref('configuracoes');
const isSaving = ref(false);

const tabs = [
  { key: 'configuracoes', label: 'Configuracoes' },
  { key: 'documentos', label: 'Documentos' },
  { key: 'playground', label: 'Playground' },
  { key: 'caixas', label: 'Caixas de Entrada' },
];

const defaultForm = {
  name: '',
  description: '',
  active: true,
  system_prompt:
    'Voce e um atendente de suporte ao cliente profissional e amigavel.',
  openai_model: 'gpt-4o',
  temperature: 0.7,
  mode: 'auto',
  language: 'pt-BR',
  max_tokens: 500,
  context_messages: 10,
  knowledge_base: '',
  welcome_message: '',
  handoff_message: '',
  resolution_message: '',
  guardrails_text: '',
  response_guidelines_text: '',
};

const form = reactive({ ...defaultForm });

// --- Load agent data ---
const loadAgentData = () => {
  if (!agent.value) return;

  const guardrailsArr = agent.value.config?.guardrails || [];
  const guidelinesArr = agent.value.config?.response_guidelines || [];

  Object.assign(form, {
    name: agent.value.name || '',
    description: agent.value.description || '',
    active: agent.value.active ?? true,
    system_prompt:
      agent.value.config?.system_prompt || defaultForm.system_prompt,
    openai_model: agent.value.config?.openai_model || 'gpt-4o',
    temperature: Number(agent.value.config?.temperature) || 0.7,
    mode: agent.value.config?.mode || 'auto',
    language: agent.value.config?.language || 'pt-BR',
    max_tokens: Number(agent.value.config?.max_tokens) || 500,
    context_messages: Number(agent.value.config?.context_messages) || 10,
    knowledge_base: agent.value.config?.knowledge_base || '',
    welcome_message: agent.value.config?.welcome_message || '',
    handoff_message: agent.value.config?.handoff_message || '',
    resolution_message: agent.value.config?.resolution_message || '',
    guardrails_text: Array.isArray(guardrailsArr)
      ? guardrailsArr.join('\n')
      : '',
    response_guidelines_text: Array.isArray(guidelinesArr)
      ? guidelinesArr.join('\n')
      : '',
  });
};

watch(agent, () => loadAgentData());

onMounted(async () => {
  await store.dispatch('aiAgents/get');
  loadAgentData();
  fetchDocuments();
  fetchInboxes();
});

// --- Save ---
const saveAgent = async () => {
  isSaving.value = true;
  try {
    const guardrailsArray = form.guardrails_text
      .split('\n')
      .map(l => l.trim())
      .filter(Boolean);
    const guidelinesArray = form.response_guidelines_text
      .split('\n')
      .map(l => l.trim())
      .filter(Boolean);

    const payload = {
      name: form.name,
      description: form.description,
      active: form.active,
      config: {
        system_prompt: form.system_prompt,
        openai_model: form.openai_model,
        temperature: form.temperature,
        mode: form.mode,
        language: form.language,
        max_tokens: form.max_tokens,
        context_messages: form.context_messages,
        knowledge_base: form.knowledge_base,
        welcome_message: form.welcome_message,
        handoff_message: form.handoff_message,
        resolution_message: form.resolution_message,
        guardrails: guardrailsArray,
        response_guidelines: guidelinesArray,
      },
    };

    await store.dispatch('aiAgents/update', {
      id: agentId.value,
      ...payload,
    });
    store.dispatch('aiAgents/get');
  } catch (e) {
    // handle error
  } finally {
    isSaving.value = false;
  }
};

// --- Documents ---
const documents = ref([]);
const isUploading = ref(false);
const dragOver = ref(false);

const fetchDocuments = async () => {
  if (!agentId.value) return;
  try {
    const { data } = await axios.get(
      apiUrl(`/ai_agents/${agentId.value}/documents`),
      { headers: apiHeaders.value }
    );
    documents.value = data;
  } catch (e) {
    documents.value = [];
  }
};

const handleFileSelect = event => {
  const file = event.target.files?.[0];
  if (file) uploadDocument(file);
  event.target.value = '';
};

const handleFileDrop = event => {
  dragOver.value = false;
  const file = event.dataTransfer.files?.[0];
  if (file) uploadDocument(file);
};

const uploadDocument = async file => {
  if (!agentId.value) return;
  isUploading.value = true;
  try {
    const formData = new FormData();
    formData.append('file', file);
    await axios.post(
      apiUrl(`/ai_agents/${agentId.value}/documents`),
      formData,
      {
        headers: {
          ...apiHeaders.value,
          'Content-Type': 'multipart/form-data',
        },
      }
    );
    await fetchDocuments();
  } catch (e) {
    // handle error
  } finally {
    isUploading.value = false;
  }
};

const deleteDocument = async doc => {
  if (!confirm(`Excluir o documento "${doc.file_name}"?`)) return;
  try {
    await axios.delete(
      apiUrl(`/ai_agents/${agentId.value}/documents/${doc.id}`),
      { headers: apiHeaders.value }
    );
    await fetchDocuments();
  } catch (e) {
    // handle error
  }
};

const formatFileSize = bytes => {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

const docIconClass = type => {
  const map = {
    pdf: 'bg-red-50 text-red-600',
    txt: 'bg-blue-50 text-blue-600',
    csv: 'bg-green-50 text-green-600',
    docx: 'bg-indigo-50 text-indigo-600',
  };
  return map[type] || 'bg-n-slate-2 text-n-slate-11';
};

const docStatusClass = status => {
  const map = {
    ready: 'bg-emerald-50 text-emerald-700',
    processing: 'bg-amber-50 text-amber-700',
    error: 'bg-red-50 text-red-700',
  };
  return map[status] || 'bg-n-slate-3 text-n-slate-11';
};

const docStatusLabel = status => {
  const map = {
    ready: 'Pronto',
    processing: 'Processando',
    error: 'Erro',
  };
  return map[status] || status;
};

// --- Playground ---
const playgroundMessages = ref([]);
const playgroundInput = ref('');
const playgroundLoading = ref(false);
const chatContainer = ref(null);

const sendPlaygroundMessage = async () => {
  const text = playgroundInput.value.trim();
  if (!text || playgroundLoading.value) return;

  playgroundMessages.value.push({ role: 'user', content: text });
  playgroundInput.value = '';
  playgroundLoading.value = true;

  await nextTick();
  scrollChatToBottom();

  try {
    const history = playgroundMessages.value
      .filter(m => m.role !== 'system')
      .slice(0, -1)
      .map(m => ({ role: m.role, content: m.content }));

    const { data } = await axios.post(
      apiUrl(`/ai_agents/${agentId.value}/playground`),
      { message_content: text, message_history: history },
      { headers: apiHeaders.value }
    );

    const response = data.response || data.error || 'Sem resposta';
    playgroundMessages.value.push({ role: 'assistant', content: response });
  } catch (e) {
    playgroundMessages.value.push({
      role: 'assistant',
      content: 'Erro ao gerar resposta. Verifique a configuracao da API.',
    });
  } finally {
    playgroundLoading.value = false;
    await nextTick();
    scrollChatToBottom();
  }
};

const scrollChatToBottom = () => {
  if (chatContainer.value) {
    chatContainer.value.scrollTop = chatContainer.value.scrollHeight;
  }
};

// --- Inboxes ---
const connectedInboxes = ref([]);
const availableInboxes = ref([]);
const selectedInboxId = ref('');

const fetchInboxes = async () => {
  if (!agentId.value) return;
  try {
    const [connected, available] = await Promise.all([
      axios.get(apiUrl(`/ai_agents/${agentId.value}/inboxes`), {
        headers: apiHeaders.value,
      }),
      axios.get(apiUrl(`/ai_agents/${agentId.value}/inboxes?available=true`), {
        headers: apiHeaders.value,
      }),
    ]);
    connectedInboxes.value = connected.data;
    availableInboxes.value = available.data;
  } catch (e) {
    connectedInboxes.value = [];
    availableInboxes.value = [];
  }
};

const connectInbox = async () => {
  if (!selectedInboxId.value) return;
  try {
    await axios.post(
      apiUrl(`/ai_agents/${agentId.value}/inboxes`),
      { inbox_id: selectedInboxId.value },
      { headers: apiHeaders.value }
    );
    selectedInboxId.value = '';
    await fetchInboxes();
    store.dispatch('aiAgents/get');
  } catch (e) {
    // handle error
  }
};

const disconnectInbox = async inbox => {
  if (!confirm(`Desconectar "${inbox.inbox_name}" deste agente?`)) return;
  try {
    await axios.delete(
      apiUrl(`/ai_agents/${agentId.value}/inboxes/${inbox.inbox_id}`),
      { headers: apiHeaders.value }
    );
    await fetchInboxes();
    store.dispatch('aiAgents/get');
  } catch (e) {
    // handle error
  }
};
</script>
