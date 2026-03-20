<template>
  <div class="flex flex-col h-full overflow-y-auto p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-6">
      <div>
        <h1 class="text-lg font-medium text-n-slate-12">Agentes de IA</h1>
        <p class="text-sm text-n-slate-11 mt-1">
          Configure agentes de IA que respondem automaticamente às conversas
        </p>
      </div>
      <button
        class="inline-flex items-center gap-2 h-10 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 transition-all"
        @click="showCreateDialog = true"
      >
        <span class="i-lucide-plus w-4 h-4" />
        Novo Agente
      </button>
    </div>

    <!-- Loading -->
    <div v-if="isFetching" class="flex items-center justify-center py-20">
      <span class="i-lucide-loader-2 w-6 h-6 animate-spin text-n-slate-9" />
    </div>

    <!-- Empty State -->
    <div
      v-else-if="!agents.length"
      class="flex flex-col items-center justify-center py-20"
    >
      <div
        class="w-12 h-12 rounded-full bg-n-slate-3 flex items-center justify-center mb-4"
      >
        <span class="i-lucide-bot w-6 h-6 text-n-slate-9" />
      </div>
      <p class="text-sm text-n-slate-11">Nenhum agente configurado</p>
      <p class="text-xs text-n-slate-9 mt-1">
        Crie um agente para começar a responder automaticamente
      </p>
    </div>

    <!-- Agent Cards -->
    <div v-else class="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
      <div
        v-for="agent in agents"
        :key="agent.id"
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-n-solid-2 p-5 hover:outline-n-slate-6 transition-colors cursor-pointer"
        @click="navigateToAgent(agent)"
      >
        <div class="flex items-start justify-between">
          <div class="flex items-center gap-3">
            <div
              class="w-10 h-10 rounded-lg bg-n-brand/10 flex items-center justify-center"
            >
              <span class="i-lucide-bot w-5 h-5 text-n-brand" />
            </div>
            <div>
              <h3 class="text-sm font-medium text-n-slate-12">
                {{ agent.name }}
              </h3>
              <p class="text-xs text-n-slate-9 mt-0.5">
                {{ agent.config?.openai_model || 'gpt-4o' }}
              </p>
            </div>
          </div>
          <span
            v-if="agent.active"
            class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md text-xs font-medium bg-emerald-50 text-emerald-700 outline outline-1 outline-emerald-200"
          >
            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500" />
            Ativo
          </span>
          <span
            v-else
            class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-n-slate-3 text-n-slate-11 outline outline-1 outline-n-slate-5"
          >
            Inativo
          </span>
        </div>
        <p
          v-if="agent.description"
          class="text-xs text-n-slate-9 mt-3 line-clamp-2"
        >
          {{ agent.description }}
        </p>
        <div class="flex items-center gap-4 mt-4 text-xs text-n-slate-9">
          <span class="flex items-center gap-1">
            <span class="i-lucide-inbox w-3.5 h-3.5" />
            {{ agent.inboxes?.length || 0 }} caixas
          </span>
          <span class="flex items-center gap-1">
            <span class="i-lucide-zap w-3.5 h-3.5" />
            {{ agent.config?.mode === 'suggest' ? 'Sugestão' : 'Automático' }}
          </span>
        </div>
      </div>
    </div>

    <!-- Create Dialog -->
    <div
      v-if="showCreateDialog"
      class="fixed inset-0 z-50 flex items-center justify-center"
    >
      <div
        class="absolute inset-0 bg-black/12"
        @click="showCreateDialog = false"
      />
      <div
        class="relative bg-white rounded-xl outline outline-1 outline-n-slate-4 shadow-lg w-full max-w-md mx-4"
      >
        <div class="px-6 py-5 border-b border-n-slate-4">
          <h3 class="text-base font-medium text-n-slate-12">Novo Agente</h3>
        </div>
        <div class="px-6 py-5 space-y-4">
          <div>
            <label class="text-sm font-medium text-n-slate-12">Nome</label>
            <input
              v-model="newAgentName"
              type="text"
              placeholder="Ex: Suporte Curso Beta"
              class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3"
            />
          </div>
          <div>
            <label class="text-sm font-medium text-n-slate-12"
              >Descrição</label
            >
            <input
              v-model="newAgentDescription"
              type="text"
              placeholder="Breve descrição"
              class="mt-2 block w-full rounded-lg text-sm bg-n-slate-2 border-none outline outline-1 outline-n-slate-5 h-10 px-3"
            />
          </div>
        </div>
        <div
          class="px-6 py-4 border-t border-n-slate-4 flex items-center justify-end gap-3"
        >
          <button
            class="h-10 px-4 rounded-lg text-sm font-medium text-n-slate-12 outline outline-1 outline-n-slate-5 hover:bg-n-slate-2"
            @click="showCreateDialog = false"
          >
            Cancelar
          </button>
          <button
            class="h-10 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110"
            :disabled="!newAgentName"
            @click="createAgent"
          >
            Criar Agente
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';

const store = useStore();
const router = useRouter();

const agents = useMapGetter('aiAgents/getRecords');
const uiFlags = useMapGetter('aiAgents/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingList);

const showCreateDialog = ref(false);
const newAgentName = ref('');
const newAgentDescription = ref('');

onMounted(() => {
  store.dispatch('aiAgents/get');
});

const navigateToAgent = agent => {
  router.push({
    name: 'ai_agent_settings',
    params: { agentId: agent.id },
  });
};

const createAgent = async () => {
  try {
    const agent = await store.dispatch('aiAgents/create', {
      name: newAgentName.value,
      description: newAgentDescription.value,
      config: {
        system_prompt:
          'Você é um atendente de suporte ao cliente profissional e amigável.',
        openai_model: 'gpt-4o',
        temperature: 0.7,
        mode: 'auto',
        language: 'pt-BR',
      },
    });
    showCreateDialog.value = false;
    newAgentName.value = '';
    newAgentDescription.value = '';
    if (agent?.id) {
      navigateToAgent(agent);
    }
  } catch (e) {
    // handle error
  }
};
</script>
