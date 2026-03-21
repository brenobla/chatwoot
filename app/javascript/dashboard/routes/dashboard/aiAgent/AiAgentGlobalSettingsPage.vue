<template>
  <div class="flex flex-col flex-1 h-full overflow-y-auto p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">Configurações Globais</h1>
        <p class="text-sm text-n-slate-10 mt-1">
          Configurações gerais dos agentes de IA
        </p>
      </div>
    </div>

    <div class="w-full space-y-6">
      <!-- OpenAI Integration Status -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <h4 class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4">Integração OpenAI</h4>
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-emerald-50 flex items-center justify-center">
              <span class="i-lucide-key w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <p class="text-sm font-medium text-n-slate-12">API Key OpenAI</p>
              <p class="text-xs text-n-slate-9 mt-0.5">
                Configurada em Settings → Integrations → OpenAI
              </p>
            </div>
          </div>
          <div>
            <span
              v-if="openaiStatus === 'checking'"
              class="inline-flex items-center gap-1.5 px-3 py-1 rounded-md text-xs font-medium bg-n-slate-2 text-n-slate-11"
            >
              <span class="i-lucide-loader-2 w-3.5 h-3.5 animate-spin" />
              Verificando...
            </span>
            <span
              v-else-if="openaiStatus === 'connected'"
              class="inline-flex items-center gap-1.5 px-3 py-1 rounded-md text-xs font-medium bg-emerald-50 text-emerald-700"
            >
              <span class="w-1.5 h-1.5 rounded-full bg-emerald-500" />
              Conectada
            </span>
            <span
              v-else
              class="inline-flex items-center gap-1.5 px-3 py-1 rounded-md text-xs font-medium bg-amber-50 text-amber-700"
            >
              <span class="w-1.5 h-1.5 rounded-full bg-amber-500" />
              Não configurada
            </span>
          </div>
        </div>
        <p class="text-xs text-n-slate-9 mt-4 p-3 rounded-lg bg-n-slate-1">
          O AI Agent busca a chave OpenAI da integração configurada em
          <strong>Settings → Integrations → OpenAI</strong>.
          Se não encontrada, usa a variável de ambiente OPENAI_API_KEY como fallback.
        </p>
      </div>

      <!-- Default Settings -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <h4 class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4">Padrões para Novos Agentes</h4>
        <div class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-n-slate-12">Modelo padrão</label>
              <select
                v-model="defaults.model"
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3"
              >
                <option value="gpt-4o">GPT-4o</option>
                <option value="gpt-4o-mini">GPT-4o Mini</option>
                <option value="gpt-4.1">GPT-4.1</option>
                <option value="gpt-4.1-mini">GPT-4.1 Mini</option>
              </select>
            </div>
            <div>
              <label class="text-sm font-medium text-n-slate-12">Modo padrão</label>
              <select
                v-model="defaults.mode"
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3"
              >
                <option value="auto">Automático</option>
                <option value="suggest">Sugestão</option>
              </select>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-n-slate-12">Temperatura: {{ defaults.temperature }}</label>
              <input v-model.number="defaults.temperature" type="range" min="0" max="2" step="0.1" class="mt-2 w-full accent-[#2781F6]" />
            </div>
            <div>
              <label class="text-sm font-medium text-n-slate-12">Max Tokens</label>
              <input v-model.number="defaults.maxTokens" type="number" min="50" max="4096"
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3" />
            </div>
          </div>
        </div>
        <p class="text-xs text-n-slate-9 mt-4 p-3 rounded-lg bg-n-slate-1">
          Estes são valores padrão sugeridos. Cada agente pode ter suas próprias configurações individuais.
        </p>
      </div>

      <!-- Stats -->
      <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-6 py-5">
        <h4 class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-4">Resumo</h4>
        <div class="grid grid-cols-3 gap-4">
          <div class="p-4 rounded-lg bg-n-slate-1 text-center">
            <p class="text-2xl font-semibold text-n-slate-12">{{ agents.length }}</p>
            <p class="text-xs text-n-slate-9 mt-1">Agentes criados</p>
          </div>
          <div class="p-4 rounded-lg bg-n-slate-1 text-center">
            <p class="text-2xl font-semibold text-emerald-600">{{ activeAgents }}</p>
            <p class="text-xs text-n-slate-9 mt-1">Agentes ativos</p>
          </div>
          <div class="p-4 rounded-lg bg-n-slate-1 text-center">
            <p class="text-2xl font-semibold text-n-brand">{{ totalInboxes }}</p>
            <p class="text-xs text-n-slate-9 mt-1">Caixas conectadas</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
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

const openaiStatus = ref('checking');

const defaults = reactive({
  model: 'gpt-4o',
  mode: 'auto',
  temperature: 0.7,
  maxTokens: 500,
});

const activeAgents = computed(() => agents.value.filter(a => a.active).length);
const totalInboxes = computed(() =>
  agents.value.reduce((sum, a) => sum + (a.inboxes?.length || 0), 0)
);

onMounted(async () => {
  await store.dispatch('aiAgents/get');
  checkOpenAIStatus();
});

const checkOpenAIStatus = async () => {
  openaiStatus.value = 'checking';
  try {
    const { data } = await axios.get(
      `/api/v1/accounts/${accountId.value}/integrations/hooks`,
      { headers: apiHeaders.value }
    );
    const hooks = data?.payload || data || [];
    const openaiHook = (Array.isArray(hooks) ? hooks : []).find(
      h => h.app_id === 'openai' && h.status === 'enabled'
    );
    openaiStatus.value = openaiHook ? 'connected' : 'not_configured';
  } catch (e) {
    openaiStatus.value = 'not_configured';
  }
};
</script>
