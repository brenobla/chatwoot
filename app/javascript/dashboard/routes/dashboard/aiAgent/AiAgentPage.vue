<template>
  <div class="flex flex-col flex-1 h-full overflow-y-auto p-6">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">Agentes de IA</h1>
        <p class="text-sm text-n-slate-10 mt-1">
          Configure agentes inteligentes que respondem automaticamente às conversas
        </p>
      </div>
      <button
        class="inline-flex items-center gap-2 h-9 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 transition-all"
        @click="openCreateDialog"
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
      class="flex flex-col items-center justify-center py-24 rounded-xl outline outline-1 outline-n-slate-3 bg-n-slate-1"
    >
      <div
        class="w-14 h-14 rounded-full bg-n-brand/8 flex items-center justify-center mb-5"
      >
        <span class="i-lucide-bot w-7 h-7 text-n-brand" />
      </div>
      <p class="text-base font-medium text-n-slate-12">
        Nenhum agente configurado
      </p>
      <p class="text-sm text-n-slate-9 mt-1 mb-5">
        Crie seu primeiro agente de IA para automatizar o atendimento
      </p>
      <button
        class="inline-flex items-center gap-2 h-9 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110"
        @click="openCreateDialog"
      >
        <span class="i-lucide-plus w-4 h-4" />
        Criar primeiro agente
      </button>
    </div>

    <!-- Agent Table -->
    <div
      v-else
      class="rounded-xl outline outline-1 outline-n-slate-4 overflow-hidden"
    >
      <table class="w-full">
        <thead>
          <tr class="bg-n-slate-2 text-left text-xs font-medium text-n-slate-10 uppercase tracking-wider">
            <th class="px-5 py-3">Agente</th>
            <th class="px-5 py-3">Modelo</th>
            <th class="px-5 py-3">Modo</th>
            <th class="px-5 py-3">Caixas</th>
            <th class="px-5 py-3">Status</th>
            <th class="px-5 py-3 text-right">Ações</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-slate-3">
          <tr
            v-for="agent in agents"
            :key="agent.id"
            class="hover:bg-n-slate-1 cursor-pointer transition-colors"
            @click="openEditDialog(agent)"
          >
            <td class="px-5 py-4">
              <div class="flex items-center gap-3">
                <div
                  class="w-9 h-9 rounded-lg bg-n-brand/10 flex items-center justify-center flex-shrink-0"
                >
                  <span class="i-lucide-bot w-4.5 h-4.5 text-n-brand" />
                </div>
                <div>
                  <p class="text-sm font-medium text-n-slate-12">
                    {{ agent.name }}
                  </p>
                  <p
                    v-if="agent.description"
                    class="text-xs text-n-slate-9 mt-0.5 line-clamp-1 max-w-xs"
                  >
                    {{ agent.description }}
                  </p>
                </div>
              </div>
            </td>
            <td class="px-5 py-4">
              <span
                class="inline-flex px-2 py-0.5 rounded text-xs font-mono text-n-slate-11 bg-n-slate-2"
              >
                {{ agent.config?.openai_model || 'gpt-4o' }}
              </span>
            </td>
            <td class="px-5 py-4">
              <span class="text-sm text-n-slate-11">
                {{
                  agent.config?.mode === 'suggest'
                    ? 'Sugestão'
                    : 'Automático'
                }}
              </span>
            </td>
            <td class="px-5 py-4">
              <span class="text-sm text-n-slate-11">
                {{ agent.inboxes?.length || 0 }}
              </span>
            </td>
            <td class="px-5 py-4">
              <span
                v-if="agent.active"
                class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md text-xs font-medium bg-emerald-50 text-emerald-700"
              >
                <span class="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                Ativo
              </span>
              <span
                v-else
                class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-n-slate-3 text-n-slate-11"
              >
                Inativo
              </span>
            </td>
            <td class="px-5 py-4 text-right">
              <button
                class="p-1.5 rounded-md hover:bg-n-slate-3 text-n-slate-9 hover:text-n-slate-12 transition-colors"
                @click.stop="openEditDialog(agent)"
              >
                <span class="i-lucide-settings w-4 h-4" />
              </button>
              <button
                class="p-1.5 rounded-md hover:bg-red-50 text-n-slate-9 hover:text-red-600 transition-colors ml-1"
                @click.stop="deleteAgent(agent)"
              >
                <span class="i-lucide-trash-2 w-4 h-4" />
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Create Dialog (simplified) -->
    <div
      v-if="showDialog"
      class="fixed inset-0 z-50 flex items-start justify-center pt-[10vh]"
    >
      <div class="absolute inset-0 bg-black/20" @click="closeDialog" />
      <div
        class="relative bg-white rounded-xl outline outline-1 outline-n-slate-4 shadow-xl w-full max-w-lg mx-4 flex flex-col"
      >
        <!-- Dialog Header -->
        <div class="px-6 py-5 border-b border-n-slate-3">
          <h3 class="text-base font-semibold text-n-slate-12">Novo Agente</h3>
          <p class="text-xs text-n-slate-9 mt-0.5">Configure um novo agente de IA</p>
        </div>

        <!-- Dialog Body -->
        <div class="px-6 py-5 space-y-5">
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
            <label class="text-sm font-medium text-n-slate-12">Descrição</label>
            <input
              v-model="form.description"
              type="text"
              placeholder="Breve descrição do agente"
              class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
            />
          </div>
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
                <option value="auto">Automático</option>
                <option value="suggest">Sugestão</option>
              </select>
            </div>
          </div>
        </div>

        <!-- Dialog Footer -->
        <div class="px-6 py-4 border-t border-n-slate-3 flex items-center justify-end gap-3">
          <button
            class="h-9 px-4 rounded-lg text-sm font-medium text-n-slate-12 outline outline-1 outline-n-slate-4 hover:bg-n-slate-2"
            @click="closeDialog"
          >
            Cancelar
          </button>
          <button
            class="h-9 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 disabled:opacity-50"
            :disabled="!form.name || isSaving"
            @click="saveAgent"
          >
            <span v-if="isSaving" class="i-lucide-loader-2 w-4 h-4 animate-spin" />
            <span v-else>Criar Agente</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';

const store = useStore();
const route = useRoute();
const router = useRouter();

const agents = useMapGetter('aiAgents/getRecords');
const uiFlags = useMapGetter('aiAgents/getUIFlags');
const isFetching = computed(() => uiFlags.value?.fetchingList);

const showDialog = ref(false);
const isSaving = ref(false);

const defaultForm = {
  name: '',
  description: '',
  openai_model: 'gpt-4o',
  mode: 'auto',
};

const form = reactive({ ...defaultForm });

onMounted(() => {
  store.dispatch('aiAgents/get');
});

const openCreateDialog = () => {
  Object.assign(form, { ...defaultForm });
  showDialog.value = true;
};

const openEditDialog = agent => {
  router.push({ name: 'ai_agent_edit', params: { agentId: agent.id } });
};

const closeDialog = () => {
  showDialog.value = false;
};

const saveAgent = async () => {
  isSaving.value = true;
  try {
    const payload = {
      name: form.name,
      description: form.description,
      active: true,
      config: {
        openai_model: form.openai_model,
        mode: form.mode,
        temperature: 0.7,
        max_tokens: 500,
        system_prompt: 'Você é um atendente de suporte ao cliente profissional e amigável.',
      },
    };
    const result = await store.dispatch('aiAgents/create', payload);
    closeDialog();
    await store.dispatch('aiAgents/get');
    // Navigate to edit page of the newly created agent
    if (result?.data?.id) {
      router.push({ name: 'ai_agent_edit', params: { agentId: result.data.id } });
    }
  } catch (e) {
    // handle error
  } finally {
    isSaving.value = false;
  }
};

const deleteAgent = async agent => {
  if (!confirm(`Excluir o agente "${agent.name}"?`)) return;
  try {
    await store.dispatch('aiAgents/delete', agent.id);
    store.dispatch('aiAgents/get');
  } catch (e) {
    // handle error
  }
};
</script>
