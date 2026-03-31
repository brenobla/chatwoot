<template>
  <div class="flex flex-col flex-1 w-full">
    <!-- Header -->
    <div class="flex items-center justify-between mb-8">
      <div>
        <h1 class="text-xl font-semibold text-n-slate-12">
          Fluxos de Conversa
        </h1>
        <p class="text-sm text-n-slate-10 mt-1">
          Crie e gerencie fluxos interativos de chatbot com botoes clicaveis
        </p>
      </div>
      <button
        class="inline-flex items-center gap-2 h-9 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 transition-all"
        @click="createFlow"
      >
        <span class="i-lucide-plus w-4 h-4" />
        Novo Fluxo
      </button>
    </div>

    <!-- Loading -->
    <div v-if="isFetching" class="flex items-center justify-center py-20">
      <span class="i-lucide-loader-2 w-6 h-6 animate-spin text-n-slate-9" />
    </div>

    <!-- Empty State -->
    <div
      v-else-if="!flows.length"
      class="flex flex-col items-center justify-center py-24 rounded-xl outline outline-1 outline-n-slate-3 bg-n-slate-1"
    >
      <div
        class="w-14 h-14 rounded-full bg-n-brand/8 flex items-center justify-center mb-5"
      >
        <span class="i-lucide-git-branch-plus w-7 h-7 text-n-brand" />
      </div>
      <p class="text-base font-medium text-n-slate-12">
        Nenhum fluxo configurado
      </p>
      <p class="text-sm text-n-slate-9 mt-1 mb-5">
        Crie seu primeiro fluxo de conversa para automatizar o atendimento
      </p>
      <button
        class="inline-flex items-center gap-2 h-9 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110"
        @click="createFlow"
      >
        <span class="i-lucide-plus w-4 h-4" />
        Criar primeiro fluxo
      </button>
    </div>

    <!-- Flow Cards (full width) -->
    <div v-else class="flex flex-col gap-4">
      <div
        v-for="flow in flows"
        :key="flow.id"
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white p-5 hover:shadow-md transition-shadow"
      >
        <div class="flex items-center gap-5">
          <!-- Icon -->
          <div
            class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
            :class="flow.active ? 'bg-n-brand/10' : 'bg-n-slate-2'"
          >
            <span
              class="i-lucide-git-branch-plus w-5 h-5"
              :class="flow.active ? 'text-n-brand' : 'text-n-slate-9'"
            />
          </div>

          <!-- Name + Description -->
          <div class="min-w-0 w-48 flex-shrink-0">
            <p class="text-sm font-medium text-n-slate-12 truncate">
              {{ flow.name }}
            </p>
            <p
              v-if="flow.description"
              class="text-xs text-n-slate-9 mt-0.5 truncate"
            >
              {{ flow.description }}
            </p>
          </div>

          <!-- Status Badge -->
          <span
            v-if="flow.active"
            class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md text-xs font-medium bg-emerald-50 text-emerald-700 flex-shrink-0"
          >
            <span class="w-1.5 h-1.5 rounded-full bg-emerald-500" />
            Ativo
          </span>
          <span
            v-else
            class="inline-flex items-center px-2 py-0.5 rounded-md text-xs font-medium bg-n-slate-3 text-n-slate-11 flex-shrink-0"
          >
            Inativo
          </span>

          <!-- Trigger -->
          <div
            v-if="flow.trigger_type"
            class="flex items-center gap-1 text-xs text-n-slate-9 flex-shrink-0"
          >
            <span class="i-lucide-zap w-3.5 h-3.5" />
            {{ triggerLabel(flow.trigger_type) }}
          </div>

          <!-- Steps -->
          <div
            v-if="flow.steps"
            class="flex items-center gap-1 text-xs text-n-slate-9 flex-shrink-0"
          >
            <span class="i-lucide-layers w-3.5 h-3.5" />
            {{ Object.keys(flow.steps || {}).length }} etapas
          </div>

          <!-- Inbox Multiselect -->
          <div class="flex-1 min-w-0 relative">
            <div
              class="flex items-center gap-1.5 flex-wrap cursor-pointer rounded-lg border border-n-slate-3 px-2.5 py-1.5 min-h-[34px] hover:border-n-slate-5 transition-colors"
              @click="toggleInboxDropdown(flow.id)"
            >
              <span class="i-lucide-inbox w-3.5 h-3.5 text-n-slate-9 flex-shrink-0" />
              <span
                v-if="!getFlowInboxIds(flow).length"
                class="text-xs text-n-slate-9"
              >
                Todas as caixas
              </span>
              <span
                v-for="inboxId in getFlowInboxIds(flow)"
                :key="inboxId"
                class="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-xs font-medium bg-n-brand/10 text-n-brand"
              >
                {{ getInboxName(inboxId) }}
                <button
                  class="hover:text-red-500 transition-colors"
                  @click.stop="removeInbox(flow, inboxId)"
                >
                  <span class="i-lucide-x w-3 h-3" />
                </button>
              </span>
            </div>
            <!-- Dropdown -->
            <div
              v-if="openDropdownId === flow.id"
              class="absolute z-50 top-full left-0 mt-1 w-64 bg-white rounded-lg shadow-lg border border-n-slate-3 py-1 max-h-48 overflow-y-auto"
            >
              <label
                v-for="inbox in inboxes"
                :key="inbox.id"
                class="flex items-center gap-2.5 px-3 py-2 hover:bg-n-slate-2 cursor-pointer text-sm text-n-slate-12"
              >
                <input
                  type="checkbox"
                  class="rounded border-n-slate-4 text-n-brand focus:ring-n-brand"
                  :checked="getFlowInboxIds(flow).includes(inbox.id)"
                  @change="toggleInbox(flow, inbox.id)"
                />
                {{ inbox.name }}
              </label>
              <div
                v-if="!inboxes.length"
                class="px-3 py-2 text-xs text-n-slate-9"
              >
                Nenhuma caixa disponível
              </div>
            </div>
          </div>

          <!-- Actions -->
          <div class="flex items-center gap-1 flex-shrink-0">
            <button
              class="relative w-10 h-5 rounded-full transition-colors cursor-pointer"
              :class="flow.active ? 'bg-n-brand' : 'bg-n-slate-6'"
              @click="toggleActive(flow)"
            >
              <span
                class="inline-block w-4 h-4 bg-white rounded-full transform transition-transform shadow-sm mt-0.5"
                :class="flow.active ? 'translate-x-5' : 'translate-x-0.5'"
              />
            </button>
            <button
              class="p-1.5 rounded-md hover:bg-n-slate-3 text-n-slate-9 hover:text-n-slate-12 transition-colors"
              title="Editar"
              @click="editFlow(flow)"
            >
              <span class="i-lucide-pencil w-4 h-4" />
            </button>
            <button
              class="p-1.5 rounded-md hover:bg-red-50 text-n-slate-9 hover:text-red-600 transition-colors"
              title="Excluir"
              @click="deleteFlow(flow)"
            >
              <span class="i-lucide-trash-2 w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';

const store = useStore();
const router = useRouter();

const flows = useMapGetter('conversationFlows/getRecords');
const inboxes = useMapGetter('inboxes/getInboxes');
const uiFlags = useMapGetter('conversationFlows/getUIFlags');
const isFetching = computed(() => uiFlags.value?.fetchingList);

const openDropdownId = ref(null);

onMounted(() => {
  store.dispatch('conversationFlows/get');
  store.dispatch('inboxes/get');
  document.addEventListener('click', closeDropdown);
});

onBeforeUnmount(() => {
  document.removeEventListener('click', closeDropdown);
});

const closeDropdown = e => {
  if (!e.target.closest('.relative')) {
    openDropdownId.value = null;
  }
};

const toggleInboxDropdown = flowId => {
  openDropdownId.value = openDropdownId.value === flowId ? null : flowId;
};

const getFlowInboxIds = flow => {
  return flow.inbox_ids || (flow.inbox_id ? [flow.inbox_id] : []);
};

const getInboxName = inboxId => {
  const inbox = (inboxes.value || []).find(i => i.id === inboxId);
  return inbox ? inbox.name : `#${inboxId}`;
};

const updateFlowInboxIds = async (flow, inboxIds) => {
  try {
    const accountId = store.getters['getCurrentAccountId'];
    await window.axios.patch(
      `/api/v1/accounts/${accountId}/conversation_flows/${flow.id}`,
      { inbox_ids: inboxIds }
    );
    store.dispatch('conversationFlows/get');
  } catch (e) {
    console.error('Erro ao atualizar caixas:', e);
  }
};

const toggleInbox = (flow, inboxId) => {
  const current = getFlowInboxIds(flow);
  const updated = current.includes(inboxId)
    ? current.filter(id => id !== inboxId)
    : [...current, inboxId];
  updateFlowInboxIds(flow, updated);
};

const removeInbox = (flow, inboxId) => {
  const updated = getFlowInboxIds(flow).filter(id => id !== inboxId);
  updateFlowInboxIds(flow, updated);
};

const triggerLabel = type => {
  const labels = {
    message_created: 'Nova mensagem',
    conversation_created: 'Nova conversa',
    keyword: 'Palavra-chave',
  };
  return labels[type] || type;
};

const createFlow = () => {
  router.push({ name: 'conversation_flow_new' });
};

const editFlow = flow => {
  router.push({
    name: 'conversation_flow_edit',
    params: { flowId: flow.id },
  });
};

const toggleActive = async flow => {
  try {
    await store.dispatch('conversationFlows/update', {
      id: flow.id,
      active: !flow.active,
    });
    store.dispatch('conversationFlows/get');
  } catch (e) {
    // handle error
  }
};

const deleteFlow = async flow => {
  if (!confirm(`Excluir o fluxo "${flow.name}"?`)) return;
  try {
    await store.dispatch('conversationFlows/delete', flow.id);
    store.dispatch('conversationFlows/get');
  } catch (e) {
    // handle error
  }
};
</script>
