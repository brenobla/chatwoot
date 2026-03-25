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
              class="p-1.5 rounded-md hover:bg-emerald-50 text-n-slate-9 hover:text-emerald-600 transition-colors"
              title="Testar fluxo"
              @click="testFlow(flow)"
            >
              <span class="i-lucide-play w-4 h-4" />
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

    <!-- Test Flow Modal -->
    <teleport to="body">
      <div
        v-if="showTestModal"
        class="fixed inset-0 z-[9999] flex items-center justify-center"
      >
        <!-- Backdrop -->
        <div
          class="absolute inset-0 bg-black/50 backdrop-blur-sm"
          @click="closeTestModal"
        />

        <!-- Modal Content -->
        <div class="relative flex gap-6 z-10">
          <!-- Phone Mockup -->
          <div class="relative">
            <!-- Phone Frame -->
            <div
              class="relative bg-black rounded-[3rem] p-3 shadow-2xl"
              style="width: 390px; height: 780px;"
            >
              <!-- Screen -->
              <div class="relative w-full h-full bg-white rounded-[2.4rem] overflow-hidden">
                <!-- Notch -->
                <div class="absolute top-0 left-1/2 -translate-x-1/2 w-32 h-7 bg-black rounded-b-2xl z-10" />

                <!-- Widget iframe -->
                <iframe
                  v-if="testWidgetUrl"
                  ref="testIframe"
                  :src="testWidgetUrl"
                  class="w-full h-full border-none"
                  allow="microphone; camera"
                />
                <div v-else class="flex items-center justify-center h-full">
                  <span class="i-lucide-loader-2 w-8 h-8 animate-spin text-n-slate-9" />
                </div>
              </div>
            </div>

            <!-- Home indicator -->
            <div class="absolute bottom-6 left-1/2 -translate-x-1/2 w-32 h-1 bg-gray-400 rounded-full" />
          </div>

          <!-- Info Panel -->
          <div class="flex flex-col gap-4 w-72">
            <div class="bg-white rounded-2xl p-5 shadow-xl">
              <h3 class="text-base font-semibold text-n-slate-12 mb-1">
                {{ testingFlow?.name }}
              </h3>
              <p class="text-xs text-n-slate-9 mb-4">
                Teste o fluxo como se fosse um visitante do seu site.
              </p>

              <div class="space-y-3 text-sm">
                <div class="flex items-center gap-2 text-n-slate-11">
                  <span class="i-lucide-message-circle w-4 h-4 text-n-brand" />
                  Envie uma mensagem para iniciar
                </div>
                <div class="flex items-center gap-2 text-n-slate-11">
                  <span class="i-lucide-mouse-pointer-click w-4 h-4 text-blue-500" />
                  Clique nos botoes para navegar
                </div>
                <div class="flex items-center gap-2 text-n-slate-11">
                  <span class="i-lucide-users w-4 h-4 text-amber-500" />
                  Verifique o roteamento no dashboard
                </div>
              </div>
            </div>

            <button
              class="h-10 rounded-xl bg-white text-sm font-medium text-n-slate-11 hover:bg-n-slate-2 shadow-xl transition-colors"
              @click="closeTestModal"
            >
              Fechar teste
            </button>
          </div>
        </div>
      </div>
    </teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import axios from 'axios';

const store = useStore();
const router = useRouter();

const flows = useMapGetter('conversationFlows/getRecords');
const inboxes = useMapGetter('inboxes/getInboxes');
const uiFlags = useMapGetter('conversationFlows/getUIFlags');
const isFetching = computed(() => uiFlags.value?.fetchingList);

const showTestModal = ref(false);
const testingFlow = ref(null);
const testWidgetUrl = ref('');

onMounted(() => {
  store.dispatch('conversationFlows/get');
  store.dispatch('inboxes/get');
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

const testFlow = async flow => {
  testingFlow.value = flow;

  // Find the inbox's website_token
  const allInboxes = inboxes.value || [];
  let targetInbox = null;

  if (flow.inbox_id) {
    targetInbox = allInboxes.find(i => i.id === flow.inbox_id);
  } else {
    targetInbox = allInboxes.find(
      i => i.channel_type === 'Channel::WebWidget'
    );
  }

  if (!targetInbox?.website_token) {
    alert('Nenhuma caixa de entrada do tipo Website encontrada.');
    return;
  }

  const baseUrl = window.location.origin;
  testWidgetUrl.value = `${baseUrl}/widget?website_token=${targetInbox.website_token}`;

  // Create a test contact + conversation via API to trigger the flow
  try {
    const accountId = store.getters['getCurrentAccountId'];
    const token = store.getters['auth/getCurrentUser']?.access_token;

    // Create test contact
    const contactRes = await axios.post(
      `${baseUrl}/api/v1/accounts/${accountId}/contacts`,
      { name: `Teste ${Date.now()}`, phone_number: `+5511${Math.floor(Math.random() * 900000000 + 100000000)}` },
      { headers: { api_access_token: token } }
    );
    const contactId = contactRes.data?.payload?.contact?.id;

    if (contactId) {
      // Create conversation which triggers the flow
      await axios.post(
        `${baseUrl}/api/v1/accounts/${accountId}/conversations`,
        {
          source_id: `test_preview_${Date.now()}`,
          inbox_id: targetInbox.id,
          contact_id: contactId,
          message: { content: 'Oi' },
        },
        { headers: { api_access_token: token } }
      );
    }
  } catch (e) {
    // Conversation creation may fail but widget still works
  }

  showTestModal.value = true;
};

const testWidgetHtml = computed(() => {
  if (!testWidgetUrl.value) return '';
  const baseUrl = window.location.origin;
  const token = testWidgetUrl.value.split('website_token=')[1]?.split('&')[0] || '';

  return `<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #fff; }
</style>
</head><body>
<script>
  (function(d,t) {
    var BASE_URL="${baseUrl}";
    var g=d.createElement(t),s=d.getElementsByTagName(t)[0];
    g.src=BASE_URL+"/packs/js/sdk.js";
    g.async=true;
    s.parentNode.insertBefore(g,s);
    g.onload=function(){
      window.chatwootSDK.run({
        websiteToken: '${token}',
        baseUrl: BASE_URL
      });
      // Wait for widget to load then auto-open
      window.addEventListener('chatwoot:ready', function() {
        // Open widget - campaign will auto-send the greeting with buttons
        window.$chatwoot.toggle('open');
      });
    }
  })(document,"script");
</script>
</body></html>`;
});

const closeTestModal = () => {
  showTestModal.value = false;
  testingFlow.value = null;
  testWidgetUrl.value = '';
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
