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

    <!-- Flow Cards -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
      <div
        v-for="flow in flows"
        :key="flow.id"
        class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white p-5 hover:shadow-md transition-shadow"
      >
        <!-- Card Header -->
        <div class="flex items-start justify-between mb-3">
          <div class="flex items-center gap-3 min-w-0">
            <div
              class="w-10 h-10 rounded-lg flex items-center justify-center flex-shrink-0"
              :class="flow.active ? 'bg-n-brand/10' : 'bg-n-slate-2'"
            >
              <span
                class="i-lucide-git-branch-plus w-5 h-5"
                :class="flow.active ? 'text-n-brand' : 'text-n-slate-9'"
              />
            </div>
            <div class="min-w-0">
              <p class="text-sm font-medium text-n-slate-12 truncate">
                {{ flow.name }}
              </p>
              <p
                v-if="flow.description"
                class="text-xs text-n-slate-9 mt-0.5 line-clamp-1"
              >
                {{ flow.description }}
              </p>
            </div>
          </div>
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
        </div>

        <!-- Card Info -->
        <div class="flex items-center gap-4 mb-4 text-xs text-n-slate-9">
          <div class="flex items-center gap-1">
            <span class="i-lucide-inbox w-3.5 h-3.5" />
            {{ flow.inbox_name || 'Todos' }}
          </div>
          <div v-if="flow.trigger_type" class="flex items-center gap-1">
            <span class="i-lucide-zap w-3.5 h-3.5" />
            {{ triggerLabel(flow.trigger_type) }}
          </div>
          <div v-if="flow.steps" class="flex items-center gap-1">
            <span class="i-lucide-layers w-3.5 h-3.5" />
            {{ Object.keys(flow.steps || {}).length }} etapas
          </div>
        </div>

        <!-- Card Actions -->
        <div class="flex items-center justify-between pt-3 border-t border-n-slate-3">
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
          <div class="flex items-center gap-1">
            <button
              class="p-1.5 rounded-md hover:bg-n-slate-3 text-n-slate-9 hover:text-n-slate-12 transition-colors"
              @click="editFlow(flow)"
            >
              <span class="i-lucide-pencil w-4 h-4" />
            </button>
            <button
              class="p-1.5 rounded-md hover:bg-red-50 text-n-slate-9 hover:text-red-600 transition-colors"
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
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';

const store = useStore();
const router = useRouter();

const flows = useMapGetter('conversationFlows/getRecords');
const uiFlags = useMapGetter('conversationFlows/getUIFlags');
const isFetching = computed(() => uiFlags.value?.fetchingList);

onMounted(() => {
  store.dispatch('conversationFlows/get');
});

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
