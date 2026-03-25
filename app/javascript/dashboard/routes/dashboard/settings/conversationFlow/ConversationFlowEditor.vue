<template>
  <div class="flex flex-col h-full w-full overflow-hidden">
    <!-- Top Toolbar -->
    <div
      class="flex items-center justify-between px-4 py-2 border-b border-n-slate-3 bg-white z-20 flex-shrink-0"
    >
      <div class="flex items-center gap-3 min-w-0 flex-1">
        <button
          class="h-8 w-8 rounded-lg flex items-center justify-center text-n-slate-11 hover:bg-n-slate-3 transition-colors flex-shrink-0"
          @click="$router.push({ name: 'conversation_flow_index' })"
        >
          <span class="i-lucide-arrow-left w-4 h-4" />
        </button>
        <input
          v-model="flowName"
          type="text"
          placeholder="Nome do fluxo"
          class="text-lg font-medium text-n-slate-12 bg-transparent border-none outline-none flex-1 min-w-0"
        />
      </div>
      <div class="flex items-center gap-3 flex-shrink-0">
        <select
          v-model="inboxId"
          class="h-9 rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3"
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
          class="h-9 rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3"
        >
          <option value="conversation_created">Nova conversa</option>
          <option value="message_created">Nova mensagem</option>
          <option value="keyword">Palavra-chave</option>
        </select>
        <button
          class="h-9 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 disabled:opacity-50"
          :disabled="!flowName || isSaving"
          @click="saveFlow"
        >
          <span
            v-if="isSaving"
            class="i-lucide-loader-2 w-4 h-4 animate-spin"
          />
          <span v-else>Salvar</span>
        </button>
      </div>
    </div>

    <!-- Main Area -->
    <div class="flex flex-1 min-h-0 relative">
      <!-- Left Palette -->
      <div
        class="w-[200px] flex-shrink-0 border-r border-n-slate-3 bg-white p-3 space-y-2 z-10 overflow-y-auto"
      >
        <div class="text-xs font-medium text-n-slate-9 uppercase tracking-wide mb-3">
          Arrastar para o canvas
        </div>
        <div
          class="palette-item flex items-center gap-2 px-3 py-2.5 rounded-lg border border-n-slate-3 bg-white cursor-grab hover:border-blue-300 hover:bg-blue-50/50 transition-colors select-none"
          draggable="true"
          @dragstart="onDragStart($event, 'message')"
        >
          <span class="w-3 h-3 rounded-full bg-blue-500 flex-shrink-0" />
          <span class="text-sm text-n-slate-12">Mensagem</span>
        </div>
        <div
          class="palette-item flex items-center gap-2 px-3 py-2.5 rounded-lg border border-n-slate-3 bg-white cursor-grab hover:border-green-300 hover:bg-green-50/50 transition-colors select-none"
          draggable="true"
          @dragstart="onDragStart($event, 'text')"
        >
          <span class="w-3 h-3 rounded-full bg-green-500 flex-shrink-0" />
          <span class="text-sm text-n-slate-12">Texto</span>
        </div>
        <div
          class="palette-item flex items-center gap-2 px-3 py-2.5 rounded-lg border border-n-slate-3 bg-white cursor-grab hover:border-amber-300 hover:bg-amber-50/50 transition-colors select-none"
          draggable="true"
          @dragstart="onDragStart($event, 'action')"
        >
          <span class="w-3 h-3 rounded-full bg-amber-500 flex-shrink-0" />
          <span class="text-sm text-n-slate-12">Acao</span>
        </div>
      </div>

      <!-- Flow Canvas -->
      <div
        ref="flowWrapper"
        class="flex-1 relative"
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
          @connect="onConnect"
          @node-click="onNodeClick"
          @pane-click="onPaneClick"
          @nodes-change="onNodesChange"
        >
          <Background :gap="20" :size="1" pattern-color="#e2e8f0" />
          <Controls position="bottom-left" />
          <MiniMap position="bottom-right" />

          <!-- Custom Node: Start -->
          <template #node-start="nodeProps">
            <div
              class="start-node"
              :class="{ 'ring-2 ring-green-400': selectedNodeId === nodeProps.id }"
            >
              <div class="start-node-header">
                <span class="i-lucide-play w-4 h-4" />
                Inicio
              </div>
              <div class="start-node-body">
                <p class="text-xs text-gray-600 line-clamp-2">
                  {{ nodeProps.data.greeting || 'Saudacao inicial...' }}
                </p>
              </div>
              <Handle type="source" :position="Position.Bottom" class="flow-handle flow-handle-source" />
            </div>
          </template>

          <!-- Custom Node: Message -->
          <template #node-message="nodeProps">
            <div
              class="message-node"
              :class="{ 'ring-2 ring-blue-400': selectedNodeId === nodeProps.id }"
            >
              <Handle type="target" :position="Position.Top" class="flow-handle flow-handle-target" />
              <div class="message-node-header">
                <span class="i-lucide-message-square w-4 h-4" />
                <span class="truncate flex-1">{{ nodeProps.data.label || 'Mensagem' }}</span>
              </div>
              <div class="message-node-body">
                <p class="text-xs text-gray-600 line-clamp-3">
                  {{ nodeProps.data.message || 'Texto da mensagem...' }}
                </p>
                <div
                  v-if="nodeProps.data.options && nodeProps.data.options.length > 0"
                  class="mt-2 space-y-1"
                >
                  <div
                    v-for="(opt, idx) in nodeProps.data.options"
                    :key="idx"
                    class="option-pill"
                  >
                    <span class="truncate flex-1 text-[11px]">{{ opt.title || '...' }}</span>
                    <Handle
                      :id="`option-${idx}`"
                      type="source"
                      :position="Position.Right"
                      class="flow-handle flow-handle-source option-handle"
                      :style="{ top: 'auto', right: '-8px', position: 'absolute' }"
                    />
                  </div>
                </div>
              </div>
              <!-- Fallback source handle when no options -->
              <Handle
                v-if="!nodeProps.data.options || nodeProps.data.options.length === 0"
                type="source"
                :position="Position.Bottom"
                class="flow-handle flow-handle-source"
              />
            </div>
          </template>

          <!-- Custom Node: Text -->
          <template #node-text="nodeProps">
            <div
              class="text-node"
              :class="{ 'ring-2 ring-green-400': selectedNodeId === nodeProps.id }"
            >
              <Handle type="target" :position="Position.Top" class="flow-handle flow-handle-target" />
              <div class="text-node-header">
                <span class="i-lucide-type w-4 h-4" />
                <span class="truncate flex-1">{{ nodeProps.data.label || 'Texto' }}</span>
              </div>
              <div class="text-node-body">
                <p class="text-xs text-gray-600 line-clamp-3">
                  {{ nodeProps.data.message || 'Texto simples...' }}
                </p>
              </div>
              <Handle type="source" :position="Position.Bottom" class="flow-handle flow-handle-source" />
            </div>
          </template>

          <!-- Custom Node: Action -->
          <template #node-action="nodeProps">
            <div
              class="action-node"
              :class="{ 'ring-2 ring-amber-400': selectedNodeId === nodeProps.id }"
            >
              <Handle type="target" :position="Position.Top" class="flow-handle flow-handle-target" />
              <div class="action-node-header">
                <span class="i-lucide-zap w-4 h-4" />
                <span class="truncate flex-1">{{ nodeProps.data.label || 'Acao' }}</span>
              </div>
              <div class="action-node-body">
                <div
                  v-if="nodeProps.data.actions && nodeProps.data.actions.length > 0"
                  class="space-y-1"
                >
                  <div
                    v-for="(act, idx) in nodeProps.data.actions"
                    :key="idx"
                    class="flex items-center gap-1 text-[11px] text-amber-800"
                  >
                    <span class="i-lucide-zap w-3 h-3 flex-shrink-0" />
                    {{ actionTypeLabel(act.type) }}
                  </div>
                </div>
                <p v-else class="text-xs text-gray-500 italic">
                  Nenhuma acao configurada
                </p>
              </div>
            </div>
          </template>
        </VueFlow>
      </div>

      <!-- Right Sidebar -->
      <div
        v-if="showSidebar"
        class="w-[370px] flex-shrink-0 border-l border-n-slate-3 bg-white z-10 flex flex-col overflow-hidden"
      >
        <!-- Sidebar Tabs -->
        <div class="flex items-center border-b border-n-slate-3 flex-shrink-0">
          <button
            class="flex-1 py-2.5 text-sm font-medium text-center transition-colors"
            :class="
              sidebarTab === 'node'
                ? 'text-n-brand border-b-2 border-n-brand'
                : 'text-n-slate-11 border-b-2 border-transparent hover:text-n-slate-12'
            "
            @click="sidebarTab = 'node'"
          >
            {{ selectedNode ? 'Propriedades' : 'Selecione um no' }}
          </button>
          <button
            class="flex-1 py-2.5 text-sm font-medium text-center transition-colors"
            :class="
              sidebarTab === 'config'
                ? 'text-n-brand border-b-2 border-n-brand'
                : 'text-n-slate-11 border-b-2 border-transparent hover:text-n-slate-12'
            "
            @click="sidebarTab = 'config'"
          >
            Config do Bot
          </button>
        </div>

        <!-- Sidebar Content -->
        <div class="flex-1 overflow-y-auto">
          <!-- Node Editor Tab -->
          <div v-if="sidebarTab === 'node'" class="p-4 space-y-4">
            <div v-if="!selectedNode" class="flex flex-col items-center justify-center py-16 text-center">
              <span class="i-lucide-mouse-pointer-click w-8 h-8 text-n-slate-9 mb-3" />
              <p class="text-sm text-n-slate-9">Clique em um no para editar suas propriedades</p>
            </div>

            <!-- Start Node Editor -->
            <template v-if="selectedNode && selectedNode.type === 'start'">
              <div class="flex items-center gap-2 mb-2">
                <span class="w-3 h-3 rounded-full bg-green-500" />
                <h3 class="text-sm font-semibold text-n-slate-12">No de Inicio</h3>
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Saudacao
                </label>
                <textarea
                  v-model="selectedNode.data.greeting"
                  rows="3"
                  placeholder="Ola! Como posso ajudar?"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y"
                  @input="updateNodeData"
                />
              </div>
            </template>

            <!-- Message Node Editor -->
            <template v-if="selectedNode && selectedNode.type === 'message'">
              <div class="flex items-center gap-2 mb-2">
                <span class="w-3 h-3 rounded-full bg-blue-500" />
                <h3 class="text-sm font-semibold text-n-slate-12">No de Mensagem</h3>
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Chave
                </label>
                <input
                  v-model="selectedNode.data.label"
                  type="text"
                  placeholder="chave_da_etapa"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3 font-mono"
                  @input="updateNodeLabel"
                />
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Mensagem
                </label>
                <textarea
                  v-model="selectedNode.data.message"
                  rows="4"
                  placeholder="Texto da mensagem..."
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y"
                  @input="updateNodeData"
                />
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Tipo
                </label>
                <select
                  v-model="selectedNode.data.stepType"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
                  @change="updateNodeData"
                >
                  <option value="input_select">Botoes de opcao</option>
                  <option value="cards">Cards</option>
                </select>
              </div>
              <div>
                <div class="flex items-center justify-between mb-2">
                  <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                    Opcoes / Botoes
                  </label>
                  <button
                    class="inline-flex items-center gap-1 text-xs text-n-brand hover:text-n-brand/80"
                    @click="addOptionToSelected"
                  >
                    <span class="i-lucide-plus w-3 h-3" />
                    Adicionar
                  </button>
                </div>
                <div class="space-y-2">
                  <div
                    v-for="(opt, idx) in selectedNode.data.options"
                    :key="idx"
                    class="p-3 rounded-lg bg-n-slate-1 outline outline-1 outline-n-slate-3 space-y-2"
                  >
                    <div class="flex items-center gap-2">
                      <span class="text-xs text-n-slate-9 font-mono w-5 text-center flex-shrink-0">{{ idx + 1 }}</span>
                      <input
                        v-model="opt.title"
                        type="text"
                        placeholder="Titulo do botao"
                        class="flex-1 rounded-md text-xs bg-white border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-8 px-2"
                        @input="updateNodeData"
                      />
                      <button
                        class="p-1 rounded-md hover:bg-red-50 text-n-slate-9 hover:text-red-600 transition-colors flex-shrink-0"
                        @click="removeOptionFromSelected(idx)"
                      >
                        <span class="i-lucide-x w-3.5 h-3.5" />
                      </button>
                    </div>
                    <input
                      v-model="opt.value"
                      type="text"
                      placeholder="Valor"
                      class="block w-full rounded-md text-xs bg-white border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-8 px-2"
                      @input="updateNodeData"
                    />
                  </div>
                </div>
              </div>
              <div class="pt-2">
                <button
                  class="w-full py-2 rounded-lg text-xs font-medium text-red-600 hover:bg-red-50 transition-colors"
                  @click="deleteSelectedNode"
                >
                  <span class="i-lucide-trash-2 w-3.5 h-3.5 inline-block mr-1" />
                  Excluir no
                </button>
              </div>
            </template>

            <!-- Text Node Editor -->
            <template v-if="selectedNode && selectedNode.type === 'text'">
              <div class="flex items-center gap-2 mb-2">
                <span class="w-3 h-3 rounded-full bg-green-500" />
                <h3 class="text-sm font-semibold text-n-slate-12">No de Texto</h3>
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Chave
                </label>
                <input
                  v-model="selectedNode.data.label"
                  type="text"
                  placeholder="chave_da_etapa"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3 font-mono"
                  @input="updateNodeLabel"
                />
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Mensagem
                </label>
                <textarea
                  v-model="selectedNode.data.message"
                  rows="4"
                  placeholder="Texto simples..."
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y"
                  @input="updateNodeData"
                />
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Proxima etapa (conectar via canvas)
                </label>
                <p class="text-xs text-n-slate-9 mt-1">
                  Arraste uma conexao do handle inferior para o proximo no.
                </p>
              </div>
              <div class="pt-2">
                <button
                  class="w-full py-2 rounded-lg text-xs font-medium text-red-600 hover:bg-red-50 transition-colors"
                  @click="deleteSelectedNode"
                >
                  <span class="i-lucide-trash-2 w-3.5 h-3.5 inline-block mr-1" />
                  Excluir no
                </button>
              </div>
            </template>

            <!-- Action Node Editor -->
            <template v-if="selectedNode && selectedNode.type === 'action'">
              <div class="flex items-center gap-2 mb-2">
                <span class="w-3 h-3 rounded-full bg-amber-500" />
                <h3 class="text-sm font-semibold text-n-slate-12">No de Acao</h3>
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Chave
                </label>
                <input
                  v-model="selectedNode.data.label"
                  type="text"
                  placeholder="chave_da_etapa"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3 font-mono"
                  @input="updateNodeLabel"
                />
              </div>
              <div>
                <div class="flex items-center justify-between mb-2">
                  <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                    Acoes
                  </label>
                  <button
                    class="inline-flex items-center gap-1 text-xs text-n-brand hover:text-n-brand/80"
                    @click="addActionToSelected"
                  >
                    <span class="i-lucide-plus w-3 h-3" />
                    Adicionar
                  </button>
                </div>
                <div class="space-y-2">
                  <div
                    v-for="(action, idx) in selectedNode.data.actions"
                    :key="idx"
                    class="p-3 rounded-lg bg-n-slate-1 outline outline-1 outline-n-slate-3 space-y-2"
                  >
                    <div class="flex items-center gap-2">
                      <select
                        v-model="action.type"
                        class="flex-1 rounded-md text-xs bg-white border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-8 px-2"
                        @change="updateNodeData"
                      >
                        <option value="assign_team">Atribuir a equipe</option>
                        <option value="assign_agent">Atribuir a agente</option>
                        <option value="add_label">Adicionar etiqueta</option>
                        <option value="handoff">Transferir para humano</option>
                        <option value="resolve">Resolver conversa</option>
                      </select>
                      <button
                        class="p-1 rounded-md hover:bg-red-50 text-n-slate-9 hover:text-red-600 transition-colors flex-shrink-0"
                        @click="removeActionFromSelected(idx)"
                      >
                        <span class="i-lucide-x w-3.5 h-3.5" />
                      </button>
                    </div>
                    <input
                      v-if="action.type === 'assign_team'"
                      v-model="action.team_id"
                      type="text"
                      placeholder="ID ou nome da equipe"
                      class="block w-full rounded-md text-xs bg-white border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-8 px-2"
                      @input="updateNodeData"
                    />
                    <input
                      v-if="action.type === 'assign_agent'"
                      v-model="action.agent_id"
                      type="text"
                      placeholder="ID ou nome do agente"
                      class="block w-full rounded-md text-xs bg-white border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-8 px-2"
                      @input="updateNodeData"
                    />
                    <input
                      v-if="action.type === 'add_label'"
                      v-model="action.label"
                      type="text"
                      placeholder="Nome da etiqueta"
                      class="block w-full rounded-md text-xs bg-white border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-8 px-2"
                      @input="updateNodeData"
                    />
                  </div>
                </div>
              </div>
              <div class="pt-2">
                <button
                  class="w-full py-2 rounded-lg text-xs font-medium text-red-600 hover:bg-red-50 transition-colors"
                  @click="deleteSelectedNode"
                >
                  <span class="i-lucide-trash-2 w-3.5 h-3.5 inline-block mr-1" />
                  Excluir no
                </button>
              </div>
            </template>
          </div>

          <!-- Bot Config Tab -->
          <div v-if="sidebarTab === 'config'" class="p-4 space-y-4">
            <div class="rounded-xl outline outline-1 -outline-offset-1 outline-n-slate-4 bg-white px-4 py-4 space-y-4">
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Nome do Bot
                </label>
                <input
                  v-model="botConfig.bot_name"
                  type="text"
                  placeholder="Assistente Virtual"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
                />
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Avatar do Bot
                </label>
                <div class="flex items-center gap-4 mt-2">
                  <div
                    class="relative w-16 h-16 rounded-full bg-n-slate-2 flex-shrink-0 overflow-hidden group cursor-pointer outline outline-2 outline-n-slate-3"
                    @click="avatarInputRef && avatarInputRef.click()"
                  >
                    <img
                      v-if="avatarPreview || botConfig.avatar_url"
                      :src="avatarPreview || botConfig.avatar_url"
                      class="w-full h-full object-cover"
                      @error="$event.target.style.display = 'none'"
                    />
                    <div
                      v-else
                      class="w-full h-full flex items-center justify-center"
                    >
                      <span class="i-lucide-bot w-7 h-7 text-n-slate-9" />
                    </div>
                    <div
                      class="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <span class="i-lucide-camera w-5 h-5 text-white" />
                    </div>
                  </div>
                  <div class="flex-1 space-y-2">
                    <button
                      class="inline-flex items-center gap-1.5 h-8 px-3 rounded-lg text-xs font-medium text-n-brand outline outline-1 outline-n-brand/30 hover:bg-n-brand/5 transition-colors"
                      @click="avatarInputRef && avatarInputRef.click()"
                    >
                      <span class="i-lucide-upload w-3.5 h-3.5" />
                      Fazer upload
                    </button>
                    <button
                      v-if="avatarPreview || botConfig.avatar_url"
                      class="inline-flex items-center gap-1.5 h-8 px-3 rounded-lg text-xs font-medium text-red-600 hover:bg-red-50 transition-colors ml-2"
                      @click="removeAvatar"
                    >
                      <span class="i-lucide-trash-2 w-3.5 h-3.5" />
                      Remover
                    </button>
                    <p class="text-[11px] text-n-slate-9">
                      JPG, PNG ou GIF. Max 2MB.
                    </p>
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
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Saudacao inicial
                </label>
                <textarea
                  v-model="botConfig.greeting"
                  rows="2"
                  placeholder="Ola! Como posso ajudar voce hoje?"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y"
                />
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Delay de digitacao
                  <span class="text-n-slate-9 font-normal">
                    ({{ botConfig.typing_delay }}s)
                  </span>
                </label>
                <input
                  v-model.number="botConfig.typing_delay"
                  type="range"
                  min="0"
                  max="5"
                  step="0.5"
                  class="mt-2 w-full accent-n-brand"
                />
                <div class="flex justify-between text-xs text-n-slate-9 mt-0.5">
                  <span>Sem delay</span>
                  <span>5s</span>
                </div>
              </div>
              <div>
                <label class="text-xs font-medium text-n-slate-9 uppercase tracking-wide">
                  Mensagem fora do horario
                </label>
                <textarea
                  v-model="botConfig.offline_message"
                  rows="2"
                  placeholder="No momento estamos fora do horario de atendimento..."
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-y"
                />
              </div>
              <div class="flex items-center justify-between pt-2">
                <div>
                  <div class="text-sm font-medium text-n-slate-12">Fluxo ativo</div>
                  <div class="text-xs text-n-slate-9 mt-0.5">
                    Ativar ou desativar este fluxo
                  </div>
                </div>
                <button
                  :class="isActive ? 'bg-n-brand' : 'bg-n-slate-6'"
                  class="relative w-11 h-6 rounded-full transition-colors cursor-pointer"
                  @click="isActive = !isActive"
                >
                  <span
                    :class="isActive ? 'translate-x-5' : 'translate-x-0.5'"
                    class="inline-block w-5 h-5 bg-white rounded-full transform transition-transform shadow-sm mt-0.5"
                  />
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Toggle Sidebar -->
        <div class="px-3 py-2 border-t border-n-slate-3 flex-shrink-0">
          <button
            class="w-full py-1.5 rounded-lg text-xs font-medium text-n-slate-9 hover:bg-n-slate-2 transition-colors"
            @click="showSidebar = false"
          >
            <span class="i-lucide-panel-right-close w-3.5 h-3.5 inline-block mr-1" />
            Fechar painel
          </button>
        </div>
      </div>

      <!-- Sidebar Toggle (when hidden) -->
      <button
        v-if="!showSidebar"
        class="absolute top-3 right-3 z-10 h-9 px-3 rounded-lg bg-white shadow-md border border-n-slate-3 text-sm text-n-slate-11 hover:text-n-slate-12 flex items-center gap-1.5"
        @click="showSidebar = true"
      >
        <span class="i-lucide-panel-right-open w-4 h-4" />
        Painel
      </button>
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
const showSidebar = ref(true);
const sidebarTab = ref('config');
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
  style: { stroke: '#6366f1', strokeWidth: 2 },
  markerEnd: { type: 'arrowclosed', color: '#6366f1' },
};

const { screenToFlowCoordinate, addNodes, addEdges, removeNodes, removeEdges, getNode, fitView } = useVueFlow();

// --- Selected node computed ---
const selectedNode = computed(() => {
  if (!selectedNodeId.value) return null;
  return nodes.value.find(n => n.id === selectedNodeId.value) || null;
});

// --- Node click handlers ---
const onNodeClick = ({ node }) => {
  selectedNodeId.value = node.id;
  sidebarTab.value = 'node';
  showSidebar.value = true;
};

const onPaneClick = () => {
  selectedNodeId.value = null;
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
  // Force reactivity update by replacing the node in the array
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
  const node = selectedNode.value;
  // Update the node ID to match the label (the step key)
  // We need to also update edges that reference this node
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
  // Remove related edges for this option handle
  const handleId = `option-${idx}`;
  edges.value = edges.value.filter(
    e => !(e.source === selectedNodeId.value && e.sourceHandle === handleId)
  );
  // Also shift handles for options after this index
  selectedNode.value.data.options.splice(idx, 1);
  // Re-index edges for options after removed index
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
  // Remove all edges connected to this node
  edges.value = edges.value.filter(e => e.source !== id && e.target !== id);
  // Remove the node
  nodes.value = nodes.value.filter(n => n.id !== id);
  selectedNodeId.value = null;
  sidebarTab.value = 'config';
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

  // Create start node
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
    const pos = step.position || { x: xBase + (index % 3) * 300, y: yOffset + Math.floor(index / 3) * ySpacing };
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
      // input_select, cards => message node
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

  // Create edges from options next_step
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
    // For text nodes with next_step
    if (step.next_step && stepKeys.includes(step.next_step)) {
      newEdges.push({
        id: `e-${key}-default-${step.next_step}`,
        source: key,
        target: step.next_step,
        ...defaultEdgeOptions,
      });
    }
  });

  // Connect start node to first step if exists
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
    if (node.type === 'start') return; // Start node is not a step

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
        // Find edge from this option handle
        const edge = edges.value.find(
          e => e.source === node.id && e.sourceHandle === `option-${idx}`
        );
        if (edge) {
          // Use the target node's label as next_step
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
      // Check for edges from text node (next_step)
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
    // New flow: create start node
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

  // Load bot config
  const config = flow.config || {};
  botConfig.bot_name = config.bot_name || '';
  botConfig.avatar_url = config.avatar_url || '';
  botConfig.greeting = config.greeting || '';
  botConfig.typing_delay = config.typing_delay ?? 1;
  botConfig.offline_message = config.offline_message || '';

  // Load steps into nodes/edges
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

    // Update greeting from start node
    const startNode = nodes.value.find(n => n.type === 'start');
    if (startNode && startNode.data.greeting) {
      botConfig.greeting = startNode.data.greeting;
    }

    // Upload avatar if new file selected
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

/* Node base styles */
.start-node,
.message-node,
.text-node,
.action-node {
  min-width: 220px;
  max-width: 280px;
  border-radius: 12px;
  background: white;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06);
  overflow: visible;
  font-family: inherit;
}

/* Start Node */
.start-node-header {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: #16a34a;
  color: white;
  font-size: 13px;
  font-weight: 600;
  border-radius: 12px 12px 0 0;
}

.start-node-body {
  padding: 10px 14px;
}

/* Message Node */
.message-node-header {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: #3b82f6;
  color: white;
  font-size: 13px;
  font-weight: 600;
  border-radius: 12px 12px 0 0;
}

.message-node-body {
  padding: 10px 14px;
}

/* Text Node */
.text-node-header {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: #22c55e;
  color: white;
  font-size: 13px;
  font-weight: 600;
  border-radius: 12px 12px 0 0;
}

.text-node-body {
  padding: 10px 14px;
}

/* Action Node */
.action-node-header {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: #f59e0b;
  color: white;
  font-size: 13px;
  font-weight: 600;
  border-radius: 12px 12px 0 0;
}

.action-node-body {
  padding: 10px 14px;
}

/* Option pills inside message nodes */
.option-pill {
  position: relative;
  display: flex;
  align-items: center;
  padding: 4px 24px 4px 8px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 6px;
  color: #1e40af;
  font-size: 11px;
}

/* Flow handles */
.flow-handle {
  width: 12px !important;
  height: 12px !important;
  border: 2px solid white !important;
  box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.15);
}

.flow-handle-source {
  background: #6366f1 !important;
}

.flow-handle-target {
  background: #a855f7 !important;
}

.option-handle {
  width: 10px !important;
  height: 10px !important;
}

/* Vue Flow overrides */
.vue-flow {
  background: #f8fafc;
}

.vue-flow__edge-path {
  stroke-width: 2;
}

.vue-flow__edge-textbg {
  fill: white;
}

.vue-flow__edge-text {
  font-size: 11px;
  fill: #6366f1;
  font-weight: 500;
}

.vue-flow__minimap {
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.vue-flow__controls {
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

/* Selection highlight */
.start-node.ring-2,
.message-node.ring-2,
.text-node.ring-2,
.action-node.ring-2 {
  box-shadow: 0 0 0 2px currentColor, 0 1px 3px rgba(0, 0, 0, 0.1);
}

/* Line clamp utility */
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.line-clamp-3 {
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* Palette drag styling */
.palette-item:active {
  cursor: grabbing;
  opacity: 0.7;
}
</style>
