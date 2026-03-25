<template>
  <div class="flow-editor-fullscreen">
    <!-- Top Bar -->
    <div class="flow-topbar">
      <div class="flow-topbar-left">
        <button
          class="flow-topbar-btn"
          @click="$router.push({ name: 'conversation_flow_index' })"
        >
          <span class="i-lucide-arrow-left w-5 h-5" />
        </button>
        <div class="flow-topbar-divider" />
        <input
          v-model="flowName"
          type="text"
          placeholder="Nome do fluxo"
          class="flow-topbar-name"
        />
      </div>
      <div class="flow-topbar-right">
        <select
          v-model="inboxId"
          class="flow-topbar-select"
        >
          <option value="">Todas as caixas</option>
          <option
            v-for="inbox in inboxes"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }}
          </option>
        </select>
        <select
          v-model="triggerType"
          class="flow-topbar-select"
        >
          <option value="conversation_created">Nova conversa</option>
          <option value="message_created">Nova mensagem</option>
          <option value="keyword">Palavra-chave</option>
        </select>
        <button
          class="flow-topbar-btn-icon"
          title="Configuracoes do Bot"
          @click="openConfigPanel"
        >
          <span class="i-lucide-settings w-4 h-4" />
        </button>
        <button
          class="flow-topbar-save"
          :disabled="!flowName || isSaving"
          @click="saveFlow"
        >
          <span
            v-if="isSaving"
            class="i-lucide-loader-2 w-4 h-4 animate-spin"
          />
          <template v-else>
            <span class="i-lucide-check w-4 h-4" />
            Salvar
          </template>
        </button>
      </div>
    </div>

    <!-- Canvas Area -->
    <div class="flow-canvas-area">
      <div
        ref="flowWrapper"
        class="flow-canvas-wrapper"
        :class="{ 'sidebar-open': showSidebar }"
        @drop="onDrop"
        @dragover.prevent
        @dragenter.prevent
      >
        <VueFlow
          v-model:nodes="nodes"
          v-model:edges="edges"
          :node-types="nodeTypes"
          :default-edge-options="defaultEdgeOptions"
          :fit-view-on-init="true"
          :snap-to-grid="true"
          :snap-grid="[20, 20]"
          :connection-mode="ConnectionMode.Loose"
          class="flow-canvas"
          @connect="onConnect"
          @node-click="onNodeClick"
          @pane-click="onPaneClick"
          @nodes-change="onNodesChange"
        >
          <Background :gap="24" :size="1.5" pattern-color="#d1d5db" />
          <Controls position="bottom-left" />
          <MiniMap position="bottom-right" />

          <!-- Custom Node: Start -->
          <template #node-start="nodeProps">
            <div
              class="mc-node mc-node--start"
              :class="{ 'mc-node--selected': selectedNodeId === nodeProps.id }"
            >
              <div class="mc-node__header">
                <span class="mc-node__dot mc-node__dot--green" />
                <span class="mc-node__key">start</span>
              </div>
              <div class="mc-node__divider" />
              <div class="mc-node__body">
                <p class="mc-node__preview">
                  {{ nodeProps.data.greeting || 'Saudacao inicial...' }}
                </p>
              </div>
              <Handle
                type="source"
                :position="Position.Bottom"
                class="mc-handle mc-handle--source"
              />
            </div>
          </template>

          <!-- Custom Node: Message -->
          <template #node-message="nodeProps">
            <div
              class="mc-node mc-node--message"
              :class="{ 'mc-node--selected': selectedNodeId === nodeProps.id }"
            >
              <Handle
                type="target"
                :position="Position.Top"
                class="mc-handle mc-handle--target"
              />
              <div class="mc-node__header">
                <span class="mc-node__dot mc-node__dot--blue" />
                <span class="mc-node__key">{{ nodeProps.data.label || 'mensagem' }}</span>
              </div>
              <div class="mc-node__divider" />
              <div class="mc-node__body">
                <p class="mc-node__preview">
                  {{ nodeProps.data.message || 'Texto da mensagem...' }}
                </p>
                <div
                  v-if="nodeProps.data.options && nodeProps.data.options.length > 0"
                  class="mc-node__options"
                >
                  <div
                    v-for="(opt, idx) in nodeProps.data.options"
                    :key="idx"
                    class="mc-option"
                  >
                    <span class="mc-option__label">{{ opt.title || '...' }}</span>
                    <span class="mc-option__arrow">
                      <svg width="8" height="8" viewBox="0 0 8 8" fill="none">
                        <path d="M1 4H7M7 4L4 1M7 4L4 7" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                      </svg>
                    </span>
                    <Handle
                      :id="`option-${idx}`"
                      type="source"
                      :position="Position.Right"
                      class="mc-handle mc-handle--option"
                    />
                  </div>
                </div>
              </div>
              <!-- Fallback source when no options -->
              <Handle
                v-if="!nodeProps.data.options || nodeProps.data.options.length === 0"
                type="source"
                :position="Position.Bottom"
                class="mc-handle mc-handle--source"
              />
            </div>
          </template>

          <!-- Custom Node: Text -->
          <template #node-text="nodeProps">
            <div
              class="mc-node mc-node--text"
              :class="{ 'mc-node--selected': selectedNodeId === nodeProps.id }"
            >
              <Handle
                type="target"
                :position="Position.Top"
                class="mc-handle mc-handle--target"
              />
              <div class="mc-node__header">
                <span class="mc-node__dot mc-node__dot--purple" />
                <span class="mc-node__key">{{ nodeProps.data.label || 'texto' }}</span>
              </div>
              <div class="mc-node__divider" />
              <div class="mc-node__body">
                <p class="mc-node__preview">
                  {{ nodeProps.data.message || 'Texto simples...' }}
                </p>
              </div>
              <Handle
                type="source"
                :position="Position.Bottom"
                class="mc-handle mc-handle--source"
              />
            </div>
          </template>

          <!-- Custom Node: Action -->
          <template #node-action="nodeProps">
            <div
              class="mc-node mc-node--action"
              :class="{ 'mc-node--selected': selectedNodeId === nodeProps.id }"
            >
              <Handle
                type="target"
                :position="Position.Top"
                class="mc-handle mc-handle--target"
              />
              <div class="mc-node__header">
                <span class="mc-node__dot mc-node__dot--amber" />
                <span class="mc-node__key">{{ nodeProps.data.label || 'acao' }}</span>
              </div>
              <div class="mc-node__divider" />
              <div class="mc-node__body">
                <p
                  v-if="nodeProps.data.message"
                  class="mc-node__preview"
                >
                  {{ nodeProps.data.message }}
                </p>
                <div
                  v-if="nodeProps.data.actions && nodeProps.data.actions.length > 0"
                  class="mc-node__actions"
                >
                  <div
                    v-for="(act, idx) in nodeProps.data.actions"
                    :key="idx"
                    class="mc-action-item"
                  >
                    <span class="mc-action-item__icon">{{ actionIcon(act.type) }}</span>
                    <span class="mc-action-item__text">{{ actionTypeLabel(act.type) }}{{ actionDetail(act) }}</span>
                  </div>
                </div>
                <p
                  v-if="!nodeProps.data.actions || nodeProps.data.actions.length === 0"
                  class="mc-node__empty"
                >
                  Nenhuma acao configurada
                </p>
              </div>
            </div>
          </template>
        </VueFlow>
      </div>

      <!-- Floating Add Button -->
      <div class="flow-fab-container" :class="{ 'sidebar-open': showSidebar }">
        <Transition name="fab-menu">
          <div v-if="showAddMenu" class="flow-fab-menu">
            <button class="flow-fab-menu-item" @click="addNodeToCenter('message')">
              <span class="flow-fab-menu-dot flow-fab-menu-dot--blue" />
              <span>Mensagem</span>
            </button>
            <button class="flow-fab-menu-item" @click="addNodeToCenter('text')">
              <span class="flow-fab-menu-dot flow-fab-menu-dot--purple" />
              <span>Texto</span>
            </button>
            <button class="flow-fab-menu-item" @click="addNodeToCenter('action')">
              <span class="flow-fab-menu-dot flow-fab-menu-dot--amber" />
              <span>Acao</span>
            </button>
          </div>
        </Transition>
        <button
          class="flow-fab"
          :class="{ 'flow-fab--active': showAddMenu }"
          @click="showAddMenu = !showAddMenu"
        >
          <svg
            width="24"
            height="24"
            viewBox="0 0 24 24"
            fill="none"
            class="flow-fab__icon"
          >
            <path
              d="M12 5V19M5 12H19"
              stroke="currentColor"
              stroke-width="2.5"
              stroke-linecap="round"
              stroke-linejoin="round"
            />
          </svg>
        </button>
      </div>

      <!-- Right Sidebar -->
      <Transition name="sidebar-slide">
        <div v-if="showSidebar" class="flow-sidebar">
          <!-- Sidebar: Node Editor -->
          <template v-if="sidebarTab === 'node' && selectedNode">
            <div class="flow-sidebar__header">
              <div class="flow-sidebar__header-left">
                <span
                  class="mc-node__dot"
                  :class="nodeTypeColor(selectedNode.type)"
                />
                <span class="flow-sidebar__title">Editar Etapa</span>
              </div>
              <button class="flow-sidebar__close" @click="closeSidebar">
                <span class="i-lucide-x w-5 h-5" />
              </button>
            </div>

            <div class="flow-sidebar__content">
              <!-- Start Node -->
              <template v-if="selectedNode.type === 'start'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Saudacao</label>
                  <textarea
                    v-model="selectedNode.data.greeting"
                    rows="4"
                    placeholder="Ola! Como posso ajudar?"
                    class="flow-sidebar__textarea"
                    @input="updateNodeData"
                  />
                </div>
              </template>

              <!-- Message Node -->
              <template v-if="selectedNode.type === 'message'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Chave da Etapa</label>
                  <input
                    v-model="selectedNode.data.label"
                    type="text"
                    placeholder="chave_da_etapa"
                    class="flow-sidebar__input flow-sidebar__input--mono"
                    @input="updateNodeLabel"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Mensagem</label>
                  <textarea
                    v-model="selectedNode.data.message"
                    rows="5"
                    placeholder="Texto da mensagem..."
                    class="flow-sidebar__textarea"
                    @input="updateNodeData"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Tipo</label>
                  <select
                    v-model="selectedNode.data.stepType"
                    class="flow-sidebar__select"
                    @change="updateNodeData"
                  >
                    <option value="input_select">Botoes de opcao</option>
                    <option value="cards">Cards</option>
                  </select>
                </div>
                <div class="flow-sidebar__section">
                  <div class="flow-sidebar__section-header">
                    <label class="flow-sidebar__label">Opcoes / Botoes</label>
                    <button
                      class="flow-sidebar__add-btn"
                      @click="addOptionToSelected"
                    >
                      <span class="i-lucide-plus w-3.5 h-3.5" />
                      Adicionar
                    </button>
                  </div>
                  <div class="flow-sidebar__options-list">
                    <div
                      v-for="(opt, idx) in selectedNode.data.options"
                      :key="idx"
                      class="flow-sidebar__option-card"
                    >
                      <div class="flow-sidebar__option-row">
                        <span class="flow-sidebar__option-num">{{ idx + 1 }}</span>
                        <input
                          v-model="opt.title"
                          type="text"
                          placeholder="Titulo do botao"
                          class="flow-sidebar__input flow-sidebar__input--sm"
                          @input="updateNodeData"
                        />
                        <button
                          class="flow-sidebar__remove-btn"
                          @click="removeOptionFromSelected(idx)"
                        >
                          <span class="i-lucide-trash-2 w-3.5 h-3.5" />
                        </button>
                      </div>
                      <input
                        v-model="opt.value"
                        type="text"
                        placeholder="Valor"
                        class="flow-sidebar__input flow-sidebar__input--sm"
                        @input="updateNodeData"
                      />
                    </div>
                  </div>
                </div>
              </template>

              <!-- Text Node -->
              <template v-if="selectedNode.type === 'text'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Chave da Etapa</label>
                  <input
                    v-model="selectedNode.data.label"
                    type="text"
                    placeholder="chave_da_etapa"
                    class="flow-sidebar__input flow-sidebar__input--mono"
                    @input="updateNodeLabel"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Mensagem</label>
                  <textarea
                    v-model="selectedNode.data.message"
                    rows="5"
                    placeholder="Texto simples..."
                    class="flow-sidebar__textarea"
                    @input="updateNodeData"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <p class="flow-sidebar__hint">
                    Conecte ao proximo passo arrastando uma conexao do handle inferior do no.
                  </p>
                </div>
              </template>

              <!-- Action Node -->
              <template v-if="selectedNode.type === 'action'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Chave da Etapa</label>
                  <input
                    v-model="selectedNode.data.label"
                    type="text"
                    placeholder="chave_da_etapa"
                    class="flow-sidebar__input flow-sidebar__input--mono"
                    @input="updateNodeLabel"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <div class="flow-sidebar__section-header">
                    <label class="flow-sidebar__label">Acoes</label>
                    <button
                      class="flow-sidebar__add-btn"
                      @click="addActionToSelected"
                    >
                      <span class="i-lucide-plus w-3.5 h-3.5" />
                      Adicionar
                    </button>
                  </div>
                  <div class="flow-sidebar__options-list">
                    <div
                      v-for="(action, idx) in selectedNode.data.actions"
                      :key="idx"
                      class="flow-sidebar__option-card"
                    >
                      <div class="flow-sidebar__option-row">
                        <select
                          v-model="action.type"
                          class="flow-sidebar__select flow-sidebar__select--sm"
                          @change="updateNodeData"
                        >
                          <option value="assign_team">Atribuir a equipe</option>
                          <option value="assign_agent">Atribuir a agente</option>
                          <option value="add_label">Adicionar etiqueta</option>
                          <option value="handoff">Transferir para humano</option>
                          <option value="resolve">Resolver conversa</option>
                        </select>
                        <button
                          class="flow-sidebar__remove-btn"
                          @click="removeActionFromSelected(idx)"
                        >
                          <span class="i-lucide-trash-2 w-3.5 h-3.5" />
                        </button>
                      </div>
                      <input
                        v-if="action.type === 'assign_team'"
                        v-model="action.team_id"
                        type="text"
                        placeholder="ID ou nome da equipe"
                        class="flow-sidebar__input flow-sidebar__input--sm"
                        @input="updateNodeData"
                      />
                      <input
                        v-if="action.type === 'assign_agent'"
                        v-model="action.agent_id"
                        type="text"
                        placeholder="ID ou nome do agente"
                        class="flow-sidebar__input flow-sidebar__input--sm"
                        @input="updateNodeData"
                      />
                      <input
                        v-if="action.type === 'add_label'"
                        v-model="action.label"
                        type="text"
                        placeholder="Nome da etiqueta"
                        class="flow-sidebar__input flow-sidebar__input--sm"
                        @input="updateNodeData"
                      />
                    </div>
                  </div>
                </div>
              </template>

              <!-- Delete Button -->
              <div v-if="selectedNode.type !== 'start'" class="flow-sidebar__danger-zone">
                <button
                  class="flow-sidebar__delete-btn"
                  @click="deleteSelectedNode"
                >
                  <span class="i-lucide-trash-2 w-4 h-4" />
                  Excluir etapa
                </button>
              </div>
            </div>
          </template>

          <!-- Sidebar: Config Panel -->
          <template v-if="sidebarTab === 'config'">
            <div class="flow-sidebar__header">
              <div class="flow-sidebar__header-left">
                <span class="i-lucide-settings w-5 h-5 text-slate-500" />
                <span class="flow-sidebar__title">Configuracoes do Bot</span>
              </div>
              <button class="flow-sidebar__close" @click="closeSidebar">
                <span class="i-lucide-x w-5 h-5" />
              </button>
            </div>

            <div class="flow-sidebar__content">
              <div class="flow-sidebar__section">
                <label class="flow-sidebar__label">Nome do Bot</label>
                <input
                  v-model="botConfig.bot_name"
                  type="text"
                  placeholder="Assistente Virtual"
                  class="flow-sidebar__input"
                />
              </div>

              <div class="flow-sidebar__section">
                <label class="flow-sidebar__label">Avatar do Bot</label>
                <div class="flow-sidebar__avatar-row">
                  <div
                    class="flow-sidebar__avatar"
                    @click="avatarInputRef && avatarInputRef.click()"
                  >
                    <img
                      v-if="avatarPreview || botConfig.avatar_url"
                      :src="avatarPreview || botConfig.avatar_url"
                      class="flow-sidebar__avatar-img"
                      @error="$event.target.style.display = 'none'"
                    />
                    <div v-else class="flow-sidebar__avatar-placeholder">
                      <span class="i-lucide-bot w-6 h-6 text-slate-400" />
                    </div>
                    <div class="flow-sidebar__avatar-overlay">
                      <span class="i-lucide-camera w-4 h-4 text-white" />
                    </div>
                  </div>
                  <div class="flow-sidebar__avatar-actions">
                    <button
                      class="flow-sidebar__avatar-btn"
                      @click="avatarInputRef && avatarInputRef.click()"
                    >
                      <span class="i-lucide-upload w-3.5 h-3.5" />
                      Upload
                    </button>
                    <button
                      v-if="avatarPreview || botConfig.avatar_url"
                      class="flow-sidebar__avatar-btn flow-sidebar__avatar-btn--danger"
                      @click="removeAvatar"
                    >
                      <span class="i-lucide-trash-2 w-3.5 h-3.5" />
                      Remover
                    </button>
                    <span class="flow-sidebar__hint">JPG, PNG ou GIF. Max 2MB.</span>
                  </div>
                  <input
                    ref="avatarInputRef"
                    type="file"
                    class="hidden"
                    accept="image/jpeg,image/png,image/gif,image/webp"
                    @change="handleAvatarUpload"
                  />
                </div>
              </div>

              <div class="flow-sidebar__section">
                <label class="flow-sidebar__label">Saudacao inicial</label>
                <textarea
                  v-model="botConfig.greeting"
                  rows="3"
                  placeholder="Ola! Como posso ajudar voce hoje?"
                  class="flow-sidebar__textarea"
                />
              </div>

              <div class="flow-sidebar__section">
                <label class="flow-sidebar__label">
                  Delay de digitacao
                  <span class="flow-sidebar__label-detail">({{ botConfig.typing_delay }}s)</span>
                </label>
                <input
                  v-model.number="botConfig.typing_delay"
                  type="range"
                  min="0"
                  max="5"
                  step="0.5"
                  class="flow-sidebar__range"
                />
                <div class="flow-sidebar__range-labels">
                  <span>Sem delay</span>
                  <span>5s</span>
                </div>
              </div>

              <div class="flow-sidebar__section">
                <label class="flow-sidebar__label">Mensagem fora do horario</label>
                <textarea
                  v-model="botConfig.offline_message"
                  rows="3"
                  placeholder="No momento estamos fora do horario de atendimento..."
                  class="flow-sidebar__textarea"
                />
              </div>

              <div class="flow-sidebar__section">
                <div class="flow-sidebar__toggle-row">
                  <div>
                    <div class="flow-sidebar__toggle-title">Fluxo ativo</div>
                    <div class="flow-sidebar__toggle-desc">Ativar ou desativar este fluxo</div>
                  </div>
                  <button
                    class="flow-sidebar__toggle"
                    :class="{ 'flow-sidebar__toggle--on': isActive }"
                    @click="isActive = !isActive"
                  >
                    <span class="flow-sidebar__toggle-knob" />
                  </button>
                </div>
              </div>
            </div>
          </template>

          <!-- Sidebar: No selection placeholder -->
          <template v-if="sidebarTab === 'node' && !selectedNode">
            <div class="flow-sidebar__header">
              <div class="flow-sidebar__header-left">
                <span class="flow-sidebar__title">Propriedades</span>
              </div>
              <button class="flow-sidebar__close" @click="closeSidebar">
                <span class="i-lucide-x w-5 h-5" />
              </button>
            </div>
            <div class="flow-sidebar__empty">
              <span class="i-lucide-mouse-pointer-click w-10 h-10 text-slate-300" />
              <p>Clique em um no para editar suas propriedades</p>
            </div>
          </template>
        </div>
      </Transition>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch, nextTick, markRaw } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import axios from 'axios';
import { VueFlow, useVueFlow, Position, Handle, ConnectionMode } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import { MiniMap } from '@vue-flow/minimap';

const store = useStore();
const route = useRoute();
const router = useRouter();

const flowId = computed(() => route.params.flowId);
const isEditing = computed(() => !!flowId.value);

const flows = useMapGetter('conversationFlows/getRecords');
const inboxes = useMapGetter('inboxes/getInboxes');

const flowName = ref('');
const inboxId = ref('');
const triggerType = ref('conversation_created');
const isActive = ref(true);
const isSaving = ref(false);
const showSidebar = ref(false);
const sidebarTab = ref('node');
const showAddMenu = ref(false);
const avatarPreview = ref('');
const avatarFile = ref(null);
const avatarInputRef = ref(null);
const flowWrapper = ref(null);

const botConfig = reactive({
  bot_name: '',
  avatar_url: '',
  greeting: '',
  typing_delay: 1,
  offline_message: '',
});

// Vue Flow state
const nodes = ref([]);
const edges = ref([]);
const selectedNodeId = ref(null);
const draggedType = ref(null);

const nodeTypes = {};

const defaultEdgeOptions = {
  type: 'smoothstep',
  animated: true,
  style: { stroke: '#94a3b8', strokeWidth: 2 },
  markerEnd: { type: 'arrowclosed', color: '#94a3b8' },
};

const { screenToFlowCoordinate, addNodes, addEdges, removeNodes, removeEdges, getNode, fitView, getViewport } = useVueFlow();

// --- Selected node computed ---
const selectedNode = computed(() => {
  if (!selectedNodeId.value) return null;
  return nodes.value.find(n => n.id === selectedNodeId.value) || null;
});

// --- Helpers ---
const nodeTypeColor = (type) => {
  const map = {
    start: 'mc-node__dot--green',
    message: 'mc-node__dot--blue',
    text: 'mc-node__dot--purple',
    action: 'mc-node__dot--amber',
  };
  return map[type] || 'mc-node__dot--blue';
};

const actionIcon = (type) => {
  const icons = {
    assign_team: '\u{1F465}',
    assign_agent: '\u{1F464}',
    add_label: '\u{1F3F7}\uFE0F',
    handoff: '\u{1F44B}',
    resolve: '\u{2705}',
  };
  return icons[type] || '\u{26A1}';
};

const actionDetail = (act) => {
  if (act.type === 'add_label' && act.label) return `: ${act.label}`;
  if (act.type === 'assign_team' && act.team_id) return `: ${act.team_id}`;
  if (act.type === 'assign_agent' && act.agent_id) return `: ${act.agent_id}`;
  return '';
};

const closeSidebar = () => {
  showSidebar.value = false;
  selectedNodeId.value = null;
};

const openConfigPanel = () => {
  sidebarTab.value = 'config';
  showSidebar.value = true;
};

// --- Node click handlers ---
const onNodeClick = ({ node }) => {
  selectedNodeId.value = node.id;
  sidebarTab.value = 'node';
  showSidebar.value = true;
  showAddMenu.value = false;
};

const onPaneClick = () => {
  selectedNodeId.value = null;
  if (sidebarTab.value === 'node') {
    showSidebar.value = false;
  }
  showAddMenu.value = false;
};

const onNodesChange = (changes) => {
  // Vue Flow handles this automatically via v-model
};

// --- Connection handler ---
const onConnect = (params) => {
  const edgeId = `e-${params.source}-${params.sourceHandle || 'default'}-${params.target}`;
  // Remove existing edge from same source handle
  edges.value = edges.value.filter(
    e => !(e.source === params.source && e.sourceHandle === params.sourceHandle)
  );

  // Determine label from option title
  let label = '';
  const sourceNode = nodes.value.find(n => n.id === params.source);
  if (sourceNode && params.sourceHandle && params.sourceHandle.startsWith('option-')) {
    const optIdx = parseInt(params.sourceHandle.replace('option-', ''), 10);
    if (sourceNode.data.options && sourceNode.data.options[optIdx]) {
      label = sourceNode.data.options[optIdx].title || '';
    }
  }

  edges.value.push({
    id: edgeId,
    source: params.source,
    sourceHandle: params.sourceHandle || null,
    target: params.target,
    targetHandle: params.targetHandle || null,
    label,
    ...defaultEdgeOptions,
  });
};

// --- Drag & Drop ---
const onDragStart = (event, type) => {
  draggedType.value = type;
  event.dataTransfer.setData('application/vueflow', type);
  event.dataTransfer.effectAllowed = 'move';
};

const onDrop = (event) => {
  const type = event.dataTransfer.getData('application/vueflow');
  if (!type) return;

  const position = screenToFlowCoordinate({
    x: event.clientX,
    y: event.clientY,
  });

  createNodeAtPosition(type, position);
};

// --- Add node to center of viewport ---
const addNodeToCenter = (type) => {
  showAddMenu.value = false;

  const viewport = getViewport();
  const wrapperEl = flowWrapper.value;
  let centerX = 400;
  let centerY = 300;

  if (wrapperEl) {
    const rect = wrapperEl.getBoundingClientRect();
    const center = screenToFlowCoordinate({
      x: rect.left + rect.width / 2,
      y: rect.top + rect.height / 2,
    });
    centerX = center.x;
    centerY = center.y;
  }

  // Offset slightly randomly so nodes don't stack
  centerX += (Math.random() - 0.5) * 60;
  centerY += (Math.random() - 0.5) * 60;

  createNodeAtPosition(type, { x: centerX, y: centerY });
};

const createNodeAtPosition = (type, position) => {
  const nodeId = `step_${Date.now()}`;
  let newNode;

  if (type === 'message') {
    newNode = {
      id: nodeId,
      type: 'message',
      position,
      data: {
        label: nodeId,
        message: '',
        stepType: 'input_select',
        options: [],
      },
    };
  } else if (type === 'text') {
    newNode = {
      id: nodeId,
      type: 'text',
      position,
      data: {
        label: nodeId,
        message: '',
        stepType: 'text',
      },
    };
  } else if (type === 'action') {
    newNode = {
      id: nodeId,
      type: 'action',
      position,
      data: {
        label: nodeId,
        stepType: 'action',
        actions: [],
      },
    };
  }

  if (newNode) {
    nodes.value.push(newNode);
    nextTick(() => {
      selectedNodeId.value = nodeId;
      sidebarTab.value = 'node';
      showSidebar.value = true;
    });
  }
};

// --- Node editing helpers ---
const updateNodeData = () => {
  if (!selectedNode.value) return;
  const idx = nodes.value.findIndex(n => n.id === selectedNodeId.value);
  if (idx >= 0) {
    nodes.value[idx] = {
      ...nodes.value[idx],
      data: { ...nodes.value[idx].data },
    };
  }
};

const updateNodeLabel = () => {
  if (!selectedNode.value) return;
  updateNodeData();
};

const addOptionToSelected = () => {
  if (!selectedNode.value) return;
  if (!selectedNode.value.data.options) {
    selectedNode.value.data.options = [];
  }
  selectedNode.value.data.options.push({ title: '', value: '', next_step: '' });
  updateNodeData();
};

const removeOptionFromSelected = (idx) => {
  if (!selectedNode.value || !selectedNode.value.data.options) return;
  const handleId = `option-${idx}`;
  edges.value = edges.value.filter(
    e => !(e.source === selectedNodeId.value && e.sourceHandle === handleId)
  );
  selectedNode.value.data.options.splice(idx, 1);
  edges.value = edges.value.map(e => {
    if (e.source === selectedNodeId.value && e.sourceHandle) {
      const match = e.sourceHandle.match(/^option-(\d+)$/);
      if (match) {
        const eIdx = parseInt(match[1], 10);
        if (eIdx > idx) {
          return { ...e, sourceHandle: `option-${eIdx - 1}`, id: `e-${e.source}-option-${eIdx - 1}-${e.target}` };
        }
      }
    }
    return e;
  });
  updateNodeData();
};

const addActionToSelected = () => {
  if (!selectedNode.value) return;
  if (!selectedNode.value.data.actions) {
    selectedNode.value.data.actions = [];
  }
  selectedNode.value.data.actions.push({ type: 'assign_team' });
  updateNodeData();
};

const removeActionFromSelected = (idx) => {
  if (!selectedNode.value || !selectedNode.value.data.actions) return;
  selectedNode.value.data.actions.splice(idx, 1);
  updateNodeData();
};

const deleteSelectedNode = () => {
  if (!selectedNodeId.value) return;
  const id = selectedNodeId.value;
  edges.value = edges.value.filter(e => e.source !== id && e.target !== id);
  nodes.value = nodes.value.filter(n => n.id !== id);
  selectedNodeId.value = null;
  showSidebar.value = false;
};

// --- Avatar upload ---
const handleAvatarUpload = (event) => {
  const file = event.target.files[0];
  if (!file) return;

  if (file.size > 2 * 1024 * 1024) {
    alert('Arquivo muito grande. Maximo 2MB.');
    return;
  }

  if (!file.type.startsWith('image/')) {
    alert('Selecione uma imagem (JPG, PNG ou GIF).');
    return;
  }

  avatarFile.value = file;
  const reader = new FileReader();
  reader.onload = (e) => {
    avatarPreview.value = e.target.result;
  };
  reader.readAsDataURL(file);
};

const removeAvatar = () => {
  avatarPreview.value = '';
  avatarFile.value = null;
  botConfig.avatar_url = '';
};

const uploadAvatar = async () => {
  if (!avatarFile.value) return botConfig.avatar_url;

  const formData = new FormData();
  formData.append('avatar', avatarFile.value);

  try {
    const accountId = store.getters['getCurrentAccountId'];
    const response = await axios.post(
      `/api/v1/accounts/${accountId}/conversation_flows/upload_avatar`,
      formData,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    );
    return response.data.avatar_url;
  } catch {
    return avatarPreview.value || botConfig.avatar_url;
  }
};

// --- Convert steps object to nodes + edges ---
const stepsToNodesAndEdges = (stepsObj, config) => {
  const newNodes = [];
  const newEdges = [];
  let yOffset = 0;
  const xBase = 300;
  const ySpacing = 200;

  const startNode = {
    id: 'start',
    type: 'start',
    position: { x: xBase, y: 0 },
    data: {
      greeting: config?.greeting || botConfig.greeting || '',
    },
  };
  newNodes.push(startNode);
  yOffset += ySpacing;

  const stepKeys = Object.keys(stepsObj);
  const stepPositions = {};

  stepKeys.forEach((key, index) => {
    const step = stepsObj[key];
    const pos = step.position || { x: xBase + (index % 3) * 350, y: yOffset + Math.floor(index / 3) * ySpacing };
    stepPositions[key] = pos;

    if (step.type === 'action') {
      newNodes.push({
        id: key,
        type: 'action',
        position: pos,
        data: {
          label: key,
          stepType: 'action',
          actions: (step.actions || []).map(a => ({ ...a })),
        },
      });
    } else if (step.type === 'text') {
      newNodes.push({
        id: key,
        type: 'text',
        position: pos,
        data: {
          label: key,
          message: step.message || '',
          stepType: 'text',
        },
      });
    } else {
      newNodes.push({
        id: key,
        type: 'message',
        position: pos,
        data: {
          label: key,
          message: step.message || '',
          stepType: step.type || 'input_select',
          options: (step.options || []).map(o => ({ ...o })),
        },
      });
    }
  });

  stepKeys.forEach((key) => {
    const step = stepsObj[key];
    if (step.options && step.options.length) {
      step.options.forEach((opt, idx) => {
        if (opt.next_step && stepKeys.includes(opt.next_step)) {
          newEdges.push({
            id: `e-${key}-option-${idx}-${opt.next_step}`,
            source: key,
            sourceHandle: `option-${idx}`,
            target: opt.next_step,
            label: opt.title || '',
            ...defaultEdgeOptions,
          });
        }
      });
    }
    if (step.next_step && stepKeys.includes(step.next_step)) {
      newEdges.push({
        id: `e-${key}-default-${step.next_step}`,
        source: key,
        target: step.next_step,
        ...defaultEdgeOptions,
      });
    }
  });

  if (stepKeys.length > 0) {
    const firstKey = stepKeys[0];
    newEdges.push({
      id: `e-start-${firstKey}`,
      source: 'start',
      target: firstKey,
      label: 'inicio',
      ...defaultEdgeOptions,
    });
  }

  return { nodes: newNodes, edges: newEdges };
};

// --- Convert nodes + edges back to steps object ---
const nodesToSteps = () => {
  const stepsObj = {};

  nodes.value.forEach((node) => {
    if (node.type === 'start') return;

    const key = node.data.label || node.id;
    const stepData = {
      message: node.data.message || '',
      type: node.data.stepType || 'text',
      position: { x: node.position.x, y: node.position.y },
    };

    if (node.type === 'message') {
      const options = (node.data.options || []).map((opt, idx) => {
        const optData = {
          title: opt.title || '',
          value: opt.value || '',
          next_step: '',
        };
        const edge = edges.value.find(
          e => e.source === node.id && e.sourceHandle === `option-${idx}`
        );
        if (edge) {
          const targetNode = nodes.value.find(n => n.id === edge.target);
          optData.next_step = targetNode ? (targetNode.data.label || targetNode.id) : edge.target;
        }
        return optData;
      });
      stepData.options = options;
    } else if (node.type === 'action') {
      stepData.actions = (node.data.actions || []).map((act) => {
        const actionObj = { type: act.type };
        if (act.type === 'assign_team') actionObj.team_id = act.team_id;
        if (act.type === 'assign_agent') actionObj.agent_id = act.agent_id;
        if (act.type === 'add_label') actionObj.label = act.label;
        return actionObj;
      });
    } else if (node.type === 'text') {
      const edge = edges.value.find(e => e.source === node.id && !e.sourceHandle);
      if (edge) {
        const targetNode = nodes.value.find(n => n.id === edge.target);
        stepData.next_step = targetNode ? (targetNode.data.label || targetNode.id) : edge.target;
      }
    }

    stepsObj[key] = stepData;
  });

  return stepsObj;
};

// --- Load existing flow ---
const loadFlow = () => {
  if (!isEditing.value) {
    if (nodes.value.length === 0) {
      nodes.value = [
        {
          id: 'start',
          type: 'start',
          position: { x: 300, y: 50 },
          data: { greeting: '' },
        },
      ];
      edges.value = [];
    }
    return;
  }

  const flow = flows.value.find(f => f.id == flowId.value);
  if (!flow) return;

  flowName.value = flow.name || '';
  inboxId.value = flow.inbox_id || '';
  triggerType.value = flow.trigger_type || 'conversation_created';
  isActive.value = flow.active ?? true;

  const config = flow.config || {};
  botConfig.bot_name = config.bot_name || '';
  botConfig.avatar_url = config.avatar_url || '';
  botConfig.greeting = config.greeting || '';
  botConfig.typing_delay = config.typing_delay ?? 1;
  botConfig.offline_message = config.offline_message || '';

  if (flow.steps && typeof flow.steps === 'object' && Object.keys(flow.steps).length > 0) {
    const result = stepsToNodesAndEdges(flow.steps, config);
    nodes.value = result.nodes;
    edges.value = result.edges;
  } else {
    nodes.value = [
      {
        id: 'start',
        type: 'start',
        position: { x: 300, y: 50 },
        data: { greeting: config.greeting || '' },
      },
    ];
    edges.value = [];
  }

  nextTick(() => {
    fitView({ padding: 0.2 });
  });
};

watch(flows, () => loadFlow());

onMounted(async () => {
  await store.dispatch('conversationFlows/get');
  store.dispatch('inboxes/get');
  loadFlow();
});

// --- Save ---
const saveFlow = async () => {
  isSaving.value = true;
  try {
    const stepsObj = nodesToSteps();

    const startNode = nodes.value.find(n => n.type === 'start');
    if (startNode && startNode.data.greeting) {
      botConfig.greeting = startNode.data.greeting;
    }

    if (avatarFile.value) {
      botConfig.avatar_url = await uploadAvatar();
      avatarFile.value = null;
    }

    const payload = {
      name: flowName.value,
      description: '',
      inbox_id: inboxId.value || null,
      trigger_type: triggerType.value,
      active: isActive.value,
      steps: stepsObj,
      config: { ...botConfig },
    };

    if (isEditing.value) {
      await store.dispatch('conversationFlows/update', {
        id: flowId.value,
        ...payload,
      });
    } else {
      const result = await store.dispatch('conversationFlows/create', payload);
      if (result?.data?.id) {
        router.replace({
          name: 'conversation_flow_edit',
          params: { flowId: result.data.id },
        });
      }
    }
    await store.dispatch('conversationFlows/get');
  } catch (e) {
    // handle error
  } finally {
    isSaving.value = false;
  }
};

// --- Helper labels ---
const actionTypeLabel = (type) => {
  const labels = {
    assign_team: 'Atribuir a equipe',
    assign_agent: 'Atribuir a agente',
    add_label: 'Adicionar etiqueta',
    handoff: 'Transferir para humano',
    resolve: 'Resolver conversa',
  };
  return labels[type] || type;
};
</script>

<style>
/* Vue Flow required styles */
@import '@vue-flow/core/dist/style.css';
@import '@vue-flow/core/dist/theme-default.css';
@import '@vue-flow/controls/dist/style.css';
@import '@vue-flow/minimap/dist/style.css';
</style>

<style scoped>
/* ============================================================
   FULLSCREEN LAYOUT
   ============================================================ */
.flow-editor-fullscreen {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 100;
  display: flex;
  flex-direction: column;
  background: #f1f5f9;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', sans-serif;
}

/* ============================================================
   TOP BAR
   ============================================================ */
.flow-topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 52px;
  padding: 0 16px;
  background: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  flex-shrink: 0;
  z-index: 50;
}

.flow-topbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
  min-width: 0;
}

.flow-topbar-right {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
}

.flow-topbar-btn {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748b;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: all 0.15s;
}

.flow-topbar-btn:hover {
  background: #f1f5f9;
  color: #1e293b;
}

.flow-topbar-btn-icon {
  width: 36px;
  height: 36px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748b;
  background: transparent;
  border: 1px solid #e2e8f0;
  cursor: pointer;
  transition: all 0.15s;
}

.flow-topbar-btn-icon:hover {
  background: #f1f5f9;
  color: #1e293b;
  border-color: #cbd5e1;
}

.flow-topbar-divider {
  width: 1px;
  height: 24px;
  background: #e2e8f0;
}

.flow-topbar-name {
  font-size: 16px;
  font-weight: 600;
  color: #1e293b;
  background: transparent;
  border: none;
  outline: none;
  flex: 1;
  min-width: 0;
}

.flow-topbar-name::placeholder {
  color: #94a3b8;
}

.flow-topbar-select {
  height: 36px;
  border-radius: 8px;
  font-size: 13px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  outline: none;
  padding: 0 12px;
  color: #475569;
  cursor: pointer;
  transition: border-color 0.15s;
}

.flow-topbar-select:focus {
  border-color: #3b82f6;
}

.flow-topbar-save {
  height: 36px;
  padding: 0 20px;
  border-radius: 8px;
  background: #3b82f6;
  color: white;
  font-size: 13px;
  font-weight: 600;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 6px;
  transition: all 0.15s;
}

.flow-topbar-save:hover:not(:disabled) {
  background: #2563eb;
}

.flow-topbar-save:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* ============================================================
   CANVAS AREA
   ============================================================ */
.flow-canvas-area {
  flex: 1;
  position: relative;
  overflow: hidden;
  display: flex;
}

.flow-canvas-wrapper {
  flex: 1;
  position: relative;
  transition: margin-right 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.flow-canvas-wrapper.sidebar-open {
  margin-right: 400px;
}

.flow-canvas {
  width: 100%;
  height: 100%;
  background: #f1f5f9;
}

/* ============================================================
   NODE CARDS (ManyChat Style)
   ============================================================ */
.mc-node {
  width: 300px;
  background: #ffffff;
  border-radius: 12px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08), 0 4px 12px rgba(0, 0, 0, 0.04);
  overflow: visible;
  border-left: 4px solid transparent;
  transition: box-shadow 0.2s, transform 0.15s;
  cursor: pointer;
}

.mc-node:hover {
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1), 0 8px 24px rgba(0, 0, 0, 0.06);
}

.mc-node--selected {
  box-shadow: 0 0 0 2px #3b82f6, 0 2px 8px rgba(59, 130, 246, 0.2);
}

.mc-node--start {
  border-left-color: #10b981;
}

.mc-node--start.mc-node--selected {
  box-shadow: 0 0 0 2px #10b981, 0 2px 8px rgba(16, 185, 129, 0.2);
}

.mc-node--message {
  border-left-color: #3b82f6;
}

.mc-node--text {
  border-left-color: #8b5cf6;
}

.mc-node--text.mc-node--selected {
  box-shadow: 0 0 0 2px #8b5cf6, 0 2px 8px rgba(139, 92, 246, 0.2);
}

.mc-node--action {
  border-left-color: #f59e0b;
}

.mc-node--action.mc-node--selected {
  box-shadow: 0 0 0 2px #f59e0b, 0 2px 8px rgba(245, 158, 11, 0.2);
}

.mc-node__header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 16px 8px;
}

.mc-node__dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.mc-node__dot--green { background: #10b981; }
.mc-node__dot--blue { background: #3b82f6; }
.mc-node__dot--purple { background: #8b5cf6; }
.mc-node__dot--amber { background: #f59e0b; }

.mc-node__key {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mc-node__divider {
  height: 1px;
  background: #f1f5f9;
  margin: 0 16px;
}

.mc-node__body {
  padding: 10px 16px 14px;
}

.mc-node__preview {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin: 0;
}

.mc-node__empty {
  font-size: 12px;
  color: #94a3b8;
  font-style: italic;
  margin: 0;
}

/* Options inside message nodes */
.mc-node__options {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 10px;
}

.mc-option {
  position: relative;
  display: flex;
  align-items: center;
  padding: 8px 30px 8px 12px;
  background: #f0f9ff;
  border: 1px solid #bae6fd;
  border-radius: 8px;
  color: #0369a1;
  font-size: 12px;
  font-weight: 500;
  transition: background 0.15s;
}

.mc-option__label {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mc-option__arrow {
  color: #0369a1;
  opacity: 0.5;
  margin-left: 4px;
}

/* Action items inside action nodes */
.mc-node__actions {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-top: 8px;
}

.mc-action-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  background: #fffbeb;
  border-radius: 6px;
  font-size: 11px;
  color: #92400e;
}

.mc-action-item__icon {
  font-size: 12px;
  flex-shrink: 0;
}

.mc-action-item__text {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

/* ============================================================
   HANDLES
   ============================================================ */
.mc-handle {
  width: 12px !important;
  height: 12px !important;
  border-radius: 50% !important;
  border: 2px solid white !important;
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.12), 0 2px 4px rgba(0, 0, 0, 0.06) !important;
  transition: transform 0.15s !important;
}

.mc-handle:hover {
  transform: scale(1.3) !important;
}

.mc-handle--source {
  background: #3b82f6 !important;
}

.mc-handle--target {
  background: #94a3b8 !important;
}

.mc-handle--option {
  position: absolute !important;
  right: -8px !important;
  top: 50% !important;
  transform: translateY(-50%) !important;
  width: 10px !important;
  height: 10px !important;
  background: #0ea5e9 !important;
}

.mc-handle--option:hover {
  transform: translateY(-50%) scale(1.3) !important;
}

/* ============================================================
   FLOATING ADD BUTTON (FAB)
   ============================================================ */
.flow-fab-container {
  position: absolute;
  bottom: 24px;
  right: 24px;
  z-index: 30;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
  transition: right 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.flow-fab-container.sidebar-open {
  right: 424px;
}

.flow-fab {
  width: 56px;
  height: 56px;
  border-radius: 16px;
  background: #3b82f6;
  color: white;
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.4), 0 1px 3px rgba(0, 0, 0, 0.1);
  transition: all 0.2s;
}

.flow-fab:hover {
  background: #2563eb;
  box-shadow: 0 6px 20px rgba(59, 130, 246, 0.5), 0 2px 6px rgba(0, 0, 0, 0.1);
  transform: scale(1.05);
}

.flow-fab--active {
  background: #1e293b;
  border-radius: 16px;
}

.flow-fab--active:hover {
  background: #0f172a;
  box-shadow: 0 6px 20px rgba(30, 41, 59, 0.5), 0 2px 6px rgba(0, 0, 0, 0.1);
}

.flow-fab__icon {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.flow-fab--active .flow-fab__icon {
  transform: rotate(45deg);
}

.flow-fab-menu {
  display: flex;
  flex-direction: column;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 24px rgba(0, 0, 0, 0.12), 0 1px 4px rgba(0, 0, 0, 0.06);
  overflow: hidden;
  min-width: 180px;
}

.flow-fab-menu-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 16px;
  font-size: 14px;
  color: #334155;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
  text-align: left;
}

.flow-fab-menu-item:hover {
  background: #f8fafc;
}

.flow-fab-menu-item:not(:last-child) {
  border-bottom: 1px solid #f1f5f9;
}

.flow-fab-menu-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.flow-fab-menu-dot--blue { background: #3b82f6; }
.flow-fab-menu-dot--purple { background: #8b5cf6; }
.flow-fab-menu-dot--amber { background: #f59e0b; }

/* FAB menu transitions */
.fab-menu-enter-active {
  transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
}

.fab-menu-leave-active {
  transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
}

.fab-menu-enter-from,
.fab-menu-leave-to {
  opacity: 0;
  transform: translateY(8px) scale(0.95);
}

/* ============================================================
   RIGHT SIDEBAR (400px)
   ============================================================ */
.flow-sidebar {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  width: 400px;
  background: #ffffff;
  border-left: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  z-index: 40;
  box-shadow: -4px 0 24px rgba(0, 0, 0, 0.06);
}

.flow-sidebar__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid #f1f5f9;
  flex-shrink: 0;
}

.flow-sidebar__header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.flow-sidebar__title {
  font-size: 15px;
  font-weight: 600;
  color: #1e293b;
}

.flow-sidebar__close {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #94a3b8;
  background: transparent;
  border: none;
  cursor: pointer;
  transition: all 0.15s;
}

.flow-sidebar__close:hover {
  background: #f1f5f9;
  color: #475569;
}

.flow-sidebar__content {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
}

.flow-sidebar__empty {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: #94a3b8;
  font-size: 14px;
  padding: 40px;
  text-align: center;
}

.flow-sidebar__section {
  margin-bottom: 20px;
}

.flow-sidebar__section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}

.flow-sidebar__label {
  display: block;
  font-size: 11px;
  font-weight: 600;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 8px;
}

.flow-sidebar__section-header .flow-sidebar__label {
  margin-bottom: 0;
}

.flow-sidebar__label-detail {
  font-weight: 400;
  color: #94a3b8;
}

.flow-sidebar__input {
  display: block;
  width: 100%;
  height: 40px;
  padding: 0 12px;
  border-radius: 8px;
  font-size: 14px;
  color: #1e293b;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  outline: none;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.flow-sidebar__input:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.flow-sidebar__input--mono {
  font-family: 'SF Mono', 'Fira Code', 'Cascadia Code', monospace;
  font-size: 13px;
}

.flow-sidebar__input--sm {
  height: 34px;
  font-size: 13px;
}

.flow-sidebar__textarea {
  display: block;
  width: 100%;
  padding: 10px 12px;
  border-radius: 8px;
  font-size: 14px;
  color: #1e293b;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  outline: none;
  resize: vertical;
  line-height: 1.5;
  transition: border-color 0.15s, box-shadow 0.15s;
}

.flow-sidebar__textarea:focus {
  border-color: #3b82f6;
  box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
}

.flow-sidebar__select {
  display: block;
  width: 100%;
  height: 40px;
  padding: 0 12px;
  border-radius: 8px;
  font-size: 14px;
  color: #1e293b;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  outline: none;
  cursor: pointer;
  transition: border-color 0.15s;
}

.flow-sidebar__select:focus {
  border-color: #3b82f6;
}

.flow-sidebar__select--sm {
  height: 34px;
  font-size: 13px;
  flex: 1;
}

.flow-sidebar__add-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 500;
  color: #3b82f6;
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 6px;
  transition: background 0.15s;
}

.flow-sidebar__add-btn:hover {
  background: #eff6ff;
}

.flow-sidebar__options-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.flow-sidebar__option-card {
  padding: 12px;
  border-radius: 10px;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.flow-sidebar__option-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.flow-sidebar__option-num {
  font-size: 11px;
  font-weight: 600;
  color: #94a3b8;
  font-family: monospace;
  width: 18px;
  text-align: center;
  flex-shrink: 0;
}

.flow-sidebar__remove-btn {
  width: 30px;
  height: 30px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #94a3b8;
  background: transparent;
  border: none;
  cursor: pointer;
  flex-shrink: 0;
  transition: all 0.15s;
}

.flow-sidebar__remove-btn:hover {
  background: #fef2f2;
  color: #dc2626;
}

.flow-sidebar__hint {
  font-size: 12px;
  color: #94a3b8;
  line-height: 1.5;
  margin: 0;
}

.flow-sidebar__range {
  width: 100%;
  accent-color: #3b82f6;
  margin-top: 4px;
}

.flow-sidebar__range-labels {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: #94a3b8;
  margin-top: 2px;
}

/* Avatar */
.flow-sidebar__avatar-row {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-top: 8px;
}

.flow-sidebar__avatar {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: #f1f5f9;
  flex-shrink: 0;
  overflow: hidden;
  position: relative;
  cursor: pointer;
  border: 2px solid #e2e8f0;
}

.flow-sidebar__avatar-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.flow-sidebar__avatar-placeholder {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.flow-sidebar__avatar-overlay {
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.15s;
}

.flow-sidebar__avatar:hover .flow-sidebar__avatar-overlay {
  opacity: 1;
}

.flow-sidebar__avatar-actions {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.flow-sidebar__avatar-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  height: 30px;
  padding: 0 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #3b82f6;
  background: transparent;
  border: 1px solid #bfdbfe;
  cursor: pointer;
  transition: all 0.15s;
}

.flow-sidebar__avatar-btn:hover {
  background: #eff6ff;
}

.flow-sidebar__avatar-btn--danger {
  color: #dc2626;
  border-color: #fecaca;
}

.flow-sidebar__avatar-btn--danger:hover {
  background: #fef2f2;
}

/* Toggle */
.flow-sidebar__toggle-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.flow-sidebar__toggle-title {
  font-size: 14px;
  font-weight: 500;
  color: #1e293b;
}

.flow-sidebar__toggle-desc {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

.flow-sidebar__toggle {
  position: relative;
  width: 44px;
  height: 24px;
  border-radius: 12px;
  background: #cbd5e1;
  border: none;
  cursor: pointer;
  transition: background 0.2s;
  flex-shrink: 0;
}

.flow-sidebar__toggle--on {
  background: #3b82f6;
}

.flow-sidebar__toggle-knob {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: white;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
  transition: transform 0.2s;
}

.flow-sidebar__toggle--on .flow-sidebar__toggle-knob {
  transform: translateX(20px);
}

/* Danger zone */
.flow-sidebar__danger-zone {
  margin-top: 24px;
  padding-top: 20px;
  border-top: 1px solid #f1f5f9;
}

.flow-sidebar__delete-btn {
  width: 100%;
  height: 40px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-size: 13px;
  font-weight: 500;
  color: #dc2626;
  background: transparent;
  border: 1px solid #fecaca;
  cursor: pointer;
  transition: all 0.15s;
}

.flow-sidebar__delete-btn:hover {
  background: #fef2f2;
  border-color: #fca5a5;
}

/* Sidebar slide transition */
.sidebar-slide-enter-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.sidebar-slide-leave-active {
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

.sidebar-slide-enter-from {
  transform: translateX(100%);
  opacity: 0;
}

.sidebar-slide-leave-to {
  transform: translateX(100%);
  opacity: 0;
}

/* ============================================================
   VUE FLOW OVERRIDES (unscoped needed for deep selectors)
   ============================================================ */
</style>

<style>
/* Vue Flow global overrides */
.flow-canvas .vue-flow__background {
  background: #f1f5f9;
}

.flow-canvas .vue-flow__edge-path {
  stroke: #94a3b8;
  stroke-width: 2;
}

.flow-canvas .vue-flow__edge.animated .vue-flow__edge-path {
  stroke-dasharray: 5;
  animation: flow-dash 0.5s linear infinite;
}

@keyframes flow-dash {
  to {
    stroke-dashoffset: -10;
  }
}

.flow-canvas .vue-flow__edge-textbg {
  fill: white;
  rx: 4;
}

.flow-canvas .vue-flow__edge-text {
  font-size: 11px;
  fill: #64748b;
  font-weight: 500;
}

.flow-canvas .vue-flow__minimap {
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  border: 1px solid #e2e8f0;
}

.flow-canvas .vue-flow__controls {
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  border: 1px solid #e2e8f0;
}

.flow-canvas .vue-flow__controls-button {
  background: white;
  border-bottom: 1px solid #f1f5f9;
  color: #475569;
}

.flow-canvas .vue-flow__controls-button:hover {
  background: #f8fafc;
}

.flow-canvas .vue-flow__connection-line {
  stroke: #3b82f6;
  stroke-width: 2;
}

/* Node wrapper - remove default borders */
.flow-canvas .vue-flow__node {
  border: none !important;
  border-radius: 12px;
  box-shadow: none !important;
  padding: 0 !important;
  background: transparent !important;
}

.flow-canvas .vue-flow__node.selected {
  box-shadow: none !important;
}
</style>
