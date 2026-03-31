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
        <select v-model="inboxId" class="flow-topbar-select">
          <option value="">Todas as caixas</option>
          <option
            v-for="inbox in inboxes"
            :key="inbox.id"
            :value="inbox.id"
          >
            {{ inbox.name }}
          </option>
        </select>
        <select v-model="triggerType" class="flow-topbar-select">
          <option value="conversation_created">Nova conversa</option>
          <option value="message_created">Nova mensagem</option>
          <option value="keyword">Palavra-chave</option>
        </select>
        <button
          class="flow-topbar-btn-icon"
          title="Simular fluxo"
          @click="showSimulator = !showSimulator"
        >
          <span class="i-lucide-play w-4 h-4" />
        </button>
        <button
          class="flow-topbar-btn-icon"
          title="Organizar layout"
          @click="doAutoLayout"
        >
          <span class="i-lucide-layout-grid w-4 h-4" />
        </button>
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

    <!-- Main Area -->
    <div class="flow-main-area">
      <!-- Simulator Panel (positioned relative to main-area) -->
      <FlowSimulator
        :visible="showSimulator"
        :steps="steps"
        :teams="teams"
        @close="showSimulator = false"
      />

      <!-- Vue Flow Canvas -->
      <div class="flow-canvas" :class="{ 'sidebar-open': showSidebar }">
        <VueFlow
          v-model:nodes="vfNodes"
          v-model:edges="vfEdges"
          :default-viewport="{ x: 0, y: 0, zoom: 0.85 }"
          :min-zoom="0.2"
          :max-zoom="2"
          :snap-to-grid="true"
          :snap-grid="[20, 20]"
          fit-view-on-init
          @node-click="onNodeClick"
          @pane-click="onPaneClick"
          @connect="onConnect"
        >
          <Background :gap="24" :size="1" pattern-color="#d1d5db" />
          <Controls position="bottom-left" />
          <MiniMap position="bottom-left" :style="{ marginBottom: '50px' }" />

          <!-- ===== MESSAGE NODE ===== -->
          <template #node-message="{ data, id }">
            <div
              class="vf-node vf-node--message"
              :class="{ 'vf-node--selected': selectedNodeKey === id }"
            >
              <Handle type="target" :position="Position.Top" class="vf-handle vf-handle--target" />
              <div class="vf-node__header">
                <span class="vf-node__icon">&#x1F4AC;</span>
                <span class="vf-node__key">{{ id }}</span>
              </div>
              <p v-if="data.message" class="vf-node__text">{{ truncate(data.message, 80) }}</p>
              <div v-if="data.options && data.options.length" class="vf-node__badge vf-node__badge--message">
                Opcoes ({{ data.options.length }})
              </div>
              <div v-if="data.options && data.options.length" class="vf-node__options">
                <div
                  v-for="(opt, idx) in data.options"
                  :key="idx"
                  class="vf-node__option-pill-row"
                >
                  <span class="vf-node__option-pill">{{ opt.title || opt.value || '...' }}</span>
                  <Handle
                    :id="'opt-' + idx"
                    type="source"
                    :position="Position.Right"
                    class="vf-handle vf-handle--source-pill"
                  />
                </div>
              </div>
              <Handle
                v-if="!data.options || !data.options.length"
                type="source"
                :position="Position.Bottom"
                class="vf-handle vf-handle--source"
              />
              <!-- Inline add button when no outgoing edges -->
              <div
                v-if="nodeHasNoOutgoing(id)"
                class="vf-node__add-btn"
                @click.stop="onAddFromNode(id)"
              >
                <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
                  <path d="M8 3V13M3 8H13" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
              </div>
            </div>
          </template>

          <!-- ===== COLLECT DATA NODE ===== -->
          <template #node-collectData="{ data, id }">
            <div
              class="vf-node vf-node--collectData"
              :class="{ 'vf-node--selected': selectedNodeKey === id }"
            >
              <Handle type="target" :position="Position.Top" class="vf-handle vf-handle--target" />
              <div class="vf-node__header">
                <span class="vf-node__icon">&#x1F4CB;</span>
                <span class="vf-node__key">{{ id }}</span>
              </div>
              <p v-if="data.message" class="vf-node__text">{{ truncate(data.message, 80) }}</p>
              <div v-if="data.fields && data.fields.length" class="vf-node__fields">
                <span v-for="(f, i) in data.fields" :key="i" class="vf-node__field-chip">
                  {{ fieldIcon(f.type) }} {{ f.label || f.name }}
                </span>
              </div>
              <div class="vf-node__badge vf-node__badge--collectData">Peca detalhes</div>
              <Handle type="source" :position="Position.Bottom" class="vf-handle vf-handle--source" />
              <div
                v-if="nodeHasNoOutgoing(id)"
                class="vf-node__add-btn"
                @click.stop="onAddFromNode(id)"
              >
                <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
                  <path d="M8 3V13M3 8H13" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
              </div>
            </div>
          </template>

          <!-- ===== CHECK HOURS NODE ===== -->
          <template #node-checkHours="{ data, id }">
            <div
              class="vf-node-diamond-wrap"
              :class="{ 'vf-node--selected': selectedNodeKey === id }"
            >
              <Handle type="target" :position="Position.Top" class="vf-handle vf-handle--target" />
              <div class="vf-node-diamond">
                <span class="vf-node-diamond__icon">&#x23F0;</span>
              </div>
              <div class="vf-node-diamond__label">{{ id }}</div>
              <Handle
                id="open"
                type="source"
                :position="Position.Left"
                class="vf-handle vf-handle--source-green"
              />
              <Handle
                id="closed"
                type="source"
                :position="Position.Right"
                class="vf-handle vf-handle--source-orange"
              />
            </div>
          </template>

          <!-- ===== TRANSFER NODE ===== -->
          <template #node-transfer="{ data, id }">
            <div
              class="vf-node vf-node--transfer"
              :class="{ 'vf-node--selected': selectedNodeKey === id }"
            >
              <Handle type="target" :position="Position.Top" class="vf-handle vf-handle--target" />
              <div class="vf-node__header">
                <span class="vf-node__icon">&#x1F500;</span>
                <span class="vf-node__key">{{ id }}</span>
              </div>
              <p v-if="data.message" class="vf-node__text">{{ truncate(data.message, 80) }}</p>
              <div class="vf-node__badge vf-node__badge--transfer">
                &#x1F464; Transferir{{ data.team_id ? ' - Equipe ' + data.team_id : '' }}
              </div>
              <!-- No source handles: terminal node -->
            </div>
          </template>

          <!-- ===== WAIT RESPONSE NODE ===== -->
          <template #node-waitResponse="{ data, id }">
            <div
              class="vf-node vf-node--waitResponse"
              :class="{ 'vf-node--selected': selectedNodeKey === id }"
            >
              <Handle type="target" :position="Position.Top" class="vf-handle vf-handle--target" />
              <div class="vf-node__header">
                <span class="vf-node__icon">&#x231B;</span>
                <span class="vf-node__key">{{ id }}</span>
              </div>
              <p v-if="data.message" class="vf-node__text">{{ truncate(data.message, 80) }}</p>
              <div class="vf-node__validation-badge">
                {{ validationIcon(data.validation) }} {{ validationLabel(data.validation) }}
              </div>
              <Handle type="source" :position="Position.Bottom" class="vf-handle vf-handle--source" />
              <div
                v-if="nodeHasNoOutgoing(id)"
                class="vf-node__add-btn"
                @click.stop="onAddFromNode(id)"
              >
                <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
                  <path d="M8 3V13M3 8H13" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
              </div>
            </div>
          </template>

          <!-- Edge labels -->
          <template #edge-label="{ edge }">
            <div v-if="edge.label" class="vf-edge-label" :class="edgeLabelClass(edge)">
              {{ edge.label }}
            </div>
          </template>
        </VueFlow>

        <!-- Floating Add Button -->
        <div class="fab-add" @click="onFabAdd">
          <svg width="20" height="20" viewBox="0 0 16 16" fill="none">
            <path d="M8 3V13M3 8H13" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"/>
          </svg>
        </div>

        <!-- Empty state -->
        <div v-if="Object.keys(steps).length === 0" class="flow-empty-overlay">
          <div class="tree-empty-state">
            <div class="tree-empty-icon">
              <span class="i-lucide-git-branch w-10 h-10 text-slate-300" />
            </div>
            <p class="tree-empty-text">Nenhuma etapa criada ainda</p>
            <button class="tree-empty-btn" @click="createRootNode">
              <span class="i-lucide-plus w-4 h-4" />
              Criar primeira etapa
            </button>
          </div>
        </div>
      </div>

      <!-- Right Sidebar -->
      <Transition name="sidebar-slide">
        <div v-if="showSidebar" class="flow-sidebar">
          <!-- Sidebar: Node Editor -->
          <template v-if="sidebarTab === 'node' && selectedStep">
            <div class="flow-sidebar__header">
              <div class="flow-sidebar__header-left">
                <span
                  class="sidebar-dot"
                  :class="`sidebar-dot--${selectedStep.type}`"
                />
                <span class="flow-sidebar__title">{{ nodeTypeLabel(selectedStep.type) }}</span>
              </div>
              <button class="flow-sidebar__close" @click="closeSidebar">
                <span class="i-lucide-x w-5 h-5" />
              </button>
            </div>

            <div class="flow-sidebar__content">
              <!-- Step key -->
              <div class="flow-sidebar__section">
                <label class="flow-sidebar__label">Chave da Etapa</label>
                <input
                  v-model="editingKey"
                  type="text"
                  placeholder="chave_da_etapa"
                  class="flow-sidebar__input flow-sidebar__input--mono"
                  @blur="renameStepKey"
                />
              </div>

              <!-- ===== MESSAGE NODE ===== -->
              <template v-if="selectedStep.type === 'message'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Mensagem</label>
                  <textarea
                    v-model="selectedStep.message"
                    rows="5"
                    placeholder="Texto da mensagem..."
                    class="flow-sidebar__textarea"
                    @input="syncStepToVueFlow(selectedNodeKey)"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <div class="flow-sidebar__section-header">
                    <label class="flow-sidebar__label">Opcoes / Botoes</label>
                    <button class="flow-sidebar__add-btn" @click="addOption">
                      <span class="i-lucide-plus w-3.5 h-3.5" />
                      Adicionar
                    </button>
                  </div>
                  <div class="flow-sidebar__options-list">
                    <div
                      v-for="(opt, idx) in selectedStep.options"
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
                          @input="syncStepToVueFlow(selectedNodeKey)"
                        />
                        <button
                          class="flow-sidebar__remove-btn"
                          @click="removeOption(idx)"
                        >
                          <span class="i-lucide-trash-2 w-3.5 h-3.5" />
                        </button>
                      </div>
                      <input
                        v-model="opt.value"
                        type="text"
                        placeholder="Valor"
                        class="flow-sidebar__input flow-sidebar__input--sm"
                        @input="syncStepToVueFlow(selectedNodeKey)"
                      />
                      <div class="flow-sidebar__option-row">
                        <label class="flow-sidebar__label-sm">Proximo passo:</label>
                        <select
                          v-model="opt.next_step"
                          class="flow-sidebar__select flow-sidebar__select--sm"
                          @change="rebuildEdges"
                        >
                          <option value="">-- Nenhum --</option>
                          <option
                            v-for="key in otherStepKeys"
                            :key="key"
                            :value="key"
                          >
                            {{ key }}
                          </option>
                        </select>
                      </div>
                    </div>
                  </div>
                </div>
              </template>

              <!-- ===== COLLECT DATA NODE ===== -->
              <template v-if="selectedStep.type === 'collect_data'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Mensagem</label>
                  <textarea
                    v-model="selectedStep.message"
                    rows="4"
                    placeholder="Poderia me informar os seus dados?"
                    class="flow-sidebar__textarea"
                    @input="syncStepToVueFlow(selectedNodeKey)"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <div class="flow-sidebar__section-header">
                    <label class="flow-sidebar__label">Campos para coletar</label>
                    <button class="flow-sidebar__add-btn" @click="addField">
                      <span class="i-lucide-plus w-3.5 h-3.5" />
                      Adicionar
                    </button>
                  </div>
                  <div class="flow-sidebar__options-list">
                    <div
                      v-for="(field, idx) in selectedStep.fields"
                      :key="idx"
                      class="flow-sidebar__option-card"
                    >
                      <div class="flow-sidebar__option-row">
                        <input
                          v-model="field.name"
                          type="text"
                          placeholder="Nome (ex: email)"
                          class="flow-sidebar__input flow-sidebar__input--sm"
                          @input="syncStepToVueFlow(selectedNodeKey)"
                        />
                        <button
                          class="flow-sidebar__remove-btn"
                          @click="selectedStep.fields.splice(idx, 1); syncStepToVueFlow(selectedNodeKey)"
                        >
                          <span class="i-lucide-trash-2 w-3.5 h-3.5" />
                        </button>
                      </div>
                      <input
                        v-model="field.label"
                        type="text"
                        placeholder="Label (ex: E-mail)"
                        class="flow-sidebar__input flow-sidebar__input--sm"
                        @input="syncStepToVueFlow(selectedNodeKey)"
                      />
                      <div class="flow-sidebar__option-row">
                        <select
                          v-model="field.type"
                          class="flow-sidebar__select flow-sidebar__select--sm"
                        >
                          <option value="text">Texto</option>
                          <option value="email">E-mail</option>
                          <option value="phone">Telefone</option>
                          <option value="select">Selecao</option>
                        </select>
                        <label class="flow-sidebar__checkbox-label">
                          <input v-model="field.required" type="checkbox" />
                          Obrigatorio
                        </label>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Proximo passo</label>
                  <select
                    v-model="selectedStep.next_step"
                    class="flow-sidebar__select"
                    @change="rebuildEdges"
                  >
                    <option value="">-- Nenhum --</option>
                    <option
                      v-for="key in otherStepKeys"
                      :key="key"
                      :value="key"
                    >
                      {{ key }}
                    </option>
                  </select>
                </div>
              </template>

              <!-- ===== CHECK HOURS NODE ===== -->
              <template v-if="selectedStep.type === 'check_hours'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Quando em horario de atendimento</label>
                  <select
                    v-model="selectedStep.open_next"
                    class="flow-sidebar__select"
                    @change="rebuildEdges"
                  >
                    <option value="">-- Nenhum --</option>
                    <option
                      v-for="key in otherStepKeys"
                      :key="key"
                      :value="key"
                    >
                      {{ key }}
                    </option>
                  </select>
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Quando fora do horario</label>
                  <select
                    v-model="selectedStep.closed_next"
                    class="flow-sidebar__select"
                    @change="rebuildEdges"
                  >
                    <option value="">-- Nenhum --</option>
                    <option
                      v-for="key in otherStepKeys"
                      :key="key"
                      :value="key"
                    >
                      {{ key }}
                    </option>
                  </select>
                </div>
              </template>

              <!-- ===== TRANSFER NODE ===== -->
              <template v-if="selectedStep.type === 'transfer'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Mensagem antes da transferencia</label>
                  <textarea
                    v-model="selectedStep.message"
                    rows="4"
                    placeholder="So um segundo, vou te encaminhar..."
                    class="flow-sidebar__textarea"
                    @input="syncStepToVueFlow(selectedNodeKey)"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Equipe (team_id)</label>
                  <input
                    v-model="selectedStep.team_id"
                    type="text"
                    placeholder="ID da equipe"
                    class="flow-sidebar__input"
                    @input="syncStepToVueFlow(selectedNodeKey)"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Agente (agent_id) - opcional</label>
                  <input
                    v-model="selectedStep.agent_id"
                    type="text"
                    placeholder="ID do agente (opcional)"
                    class="flow-sidebar__input"
                  />
                </div>
              </template>

              <!-- ===== WAIT RESPONSE NODE ===== -->
              <template v-if="selectedStep.type === 'wait_response'">
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Mensagem / Pergunta</label>
                  <textarea
                    v-model="selectedStep.message"
                    rows="4"
                    placeholder="Peca detalhes sobre seu problema..."
                    class="flow-sidebar__textarea"
                    @input="syncStepToVueFlow(selectedNodeKey)"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Nome da variavel</label>
                  <input
                    v-model="selectedStep.variable"
                    type="text"
                    placeholder="user_issue"
                    class="flow-sidebar__input flow-sidebar__input--mono"
                  />
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Validacao</label>
                  <select
                    v-model="selectedStep.validation"
                    class="flow-sidebar__select"
                  >
                    <option value="">Nenhuma</option>
                    <option value="email">E-mail</option>
                    <option value="phone">Telefone</option>
                  </select>
                </div>
                <div class="flow-sidebar__section">
                  <label class="flow-sidebar__label">Proximo passo</label>
                  <select
                    v-model="selectedStep.next_step"
                    class="flow-sidebar__select"
                    @change="rebuildEdges"
                  >
                    <option value="">-- Nenhum --</option>
                    <option
                      v-for="key in otherStepKeys"
                      :key="key"
                      :value="key"
                    >
                      {{ key }}
                    </option>
                  </select>
                </div>
              </template>

              <!-- Delete Button -->
              <div
                v-if="selectedNodeKey !== 'start'"
                class="flow-sidebar__danger-zone"
              >
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

          <!-- Sidebar: No selection -->
          <template v-if="sidebarTab === 'node' && !selectedStep">
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

    <!-- Add Node Menu (modal overlay) -->
    <Transition name="fade">
      <div
        v-if="addMenuVisible"
        class="add-menu-overlay"
        @click.self="addMenuVisible = false"
      >
        <div class="add-menu-card">
          <div class="add-menu-title">Adicionar etapa</div>
          <button class="add-menu-item" @click="confirmAddNode('message')">
            <span class="add-menu-dot add-menu-dot--message" />
            <div>
              <div class="add-menu-item-title">Mensagem</div>
              <div class="add-menu-item-desc">Enviar mensagem com opcoes de botao</div>
            </div>
          </button>
          <button class="add-menu-item" @click="confirmAddNode('collect_data')">
            <span class="add-menu-dot add-menu-dot--collect_data" />
            <div>
              <div class="add-menu-item-title">Pedir Dados</div>
              <div class="add-menu-item-desc">Coletar nome, email, telefone</div>
            </div>
          </button>
          <button class="add-menu-item" @click="confirmAddNode('check_hours')">
            <span class="add-menu-dot add-menu-dot--check_hours" />
            <div>
              <div class="add-menu-item-title">Verificar Horario</div>
              <div class="add-menu-item-desc">Verificar se esta em horario de atendimento</div>
            </div>
          </button>
          <button class="add-menu-item" @click="confirmAddNode('transfer')">
            <span class="add-menu-dot add-menu-dot--transfer" />
            <div>
              <div class="add-menu-item-title">Transferir</div>
              <div class="add-menu-item-desc">Transferir para equipe ou agente</div>
            </div>
          </button>
          <button class="add-menu-item" @click="confirmAddNode('wait_response')">
            <span class="add-menu-dot add-menu-dot--wait_response" />
            <div>
              <div class="add-menu-item-title">Aguardar Resposta</div>
              <div class="add-menu-item-desc">Esperar o usuario digitar uma resposta</div>
            </div>
          </button>
        </div>
      </div>
    </Transition>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch, nextTick } from 'vue';
import { useStore } from 'vuex';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import axios from 'axios';
import { VueFlow, Handle, Position } from '@vue-flow/core';
import { Background } from '@vue-flow/background';
import { Controls } from '@vue-flow/controls';
import { MiniMap } from '@vue-flow/minimap';
import dagre from 'dagre';
import FlowSimulator from './FlowSimulator.vue';

// ============================================================
// Dagre auto-layout
// ============================================================
function layoutNodes(nodes, edges) {
  const g = new dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({ rankdir: 'TB', nodesep: 80, ranksep: 120, marginx: 40, marginy: 40 });

  nodes.forEach(node => {
    const h = node.type === 'checkHours' ? 80 : 180;
    g.setNode(node.id, { width: 300, height: h });
  });
  edges.forEach(edge => {
    g.setEdge(edge.source, edge.target);
  });

  dagre.layout(g);

  return nodes.map(node => {
    const pos = g.node(node.id);
    return {
      ...node,
      position: { x: pos.x - 150, y: pos.y - (node.type === 'checkHours' ? 40 : 90) },
    };
  });
}

// ============================================================
// Type mapping: steps type -> VueFlow node type
// ============================================================
const STEP_TO_VF_TYPE = {
  message: 'message',
  input_select: 'message',
  text: 'message',
  collect_data: 'collectData',
  check_hours: 'checkHours',
  transfer: 'transfer',
  action: 'transfer',
  wait_response: 'waitResponse',
};

const VF_TO_STEP_TYPE = {};
Object.entries(STEP_TO_VF_TYPE).forEach(([k, v]) => { VF_TO_STEP_TYPE[v] = k; });

// ============================================================
// Store / Route
// ============================================================
const store = useStore();
const route = useRoute();
const router = useRouter();

const flowId = computed(() => route.params.flowId);
const isEditing = computed(() => !!flowId.value);

const flows = useMapGetter('conversationFlows/getRecords');
const inboxes = useMapGetter('inboxes/getInboxes');
const teams = useMapGetter('teams/getTeams');

// ============================================================
// State
// ============================================================
const flowName = ref('');
const inboxId = ref('');
const triggerType = ref('conversation_created');
const isActive = ref(true);
const isSaving = ref(false);
const showSidebar = ref(false);
const sidebarTab = ref('node');
const avatarPreview = ref('');
const avatarFile = ref(null);
const avatarInputRef = ref(null);
const showSimulator = ref(false);

const botConfig = reactive({
  bot_name: '',
  avatar_url: '',
  greeting: '',
  typing_delay: 1,
  offline_message: '',
});

// Steps data model - flat object keyed by step key
const steps = reactive({});

const selectedNodeKey = ref('');
const editingKey = ref('');

// Vue Flow nodes and edges
const vfNodes = ref([]);
const vfEdges = ref([]);

// Add menu state
const addMenuVisible = ref(false);
const addMenuParentKey = ref('');
const addMenuContext = ref('');

// ============================================================
// Computed
// ============================================================
const allStepKeys = computed(() => Object.keys(steps));

const selectedStep = computed(() => {
  if (!selectedNodeKey.value || !steps[selectedNodeKey.value]) return null;
  return steps[selectedNodeKey.value];
});

const otherStepKeys = computed(() => {
  return allStepKeys.value.filter(k => k !== selectedNodeKey.value);
});

// ============================================================
// Helpers
// ============================================================
const truncate = (text, max) => {
  if (!text) return '';
  return text.length > max ? text.substring(0, max) + '...' : text;
};

const fieldIcon = (type) => {
  const icons = { email: '\u{1F4E7}', phone: '\u{1F4F1}', text: '\u{1F4DD}', select: '\u{1F4CB}' };
  return icons[type] || '\u{1F4DD}';
};

const validationIcon = (v) => {
  if (v === 'email') return '\u{1F4E7}';
  if (v === 'phone') return '\u{1F4F1}';
  return '\u{1F4AC}';
};

const validationLabel = (v) => {
  if (v === 'email') return 'email';
  if (v === 'phone') return 'telefone';
  return 'texto livre';
};

const nodeTypeLabel = (type) => {
  const labels = {
    message: 'Mensagem',
    collect_data: 'Pedir Dados',
    check_hours: 'Verificar Horario',
    transfer: 'Transferir',
    wait_response: 'Aguardar Resposta',
  };
  return labels[type] || type;
};

const edgeLabelClass = (edge) => {
  if (edge.data?.branch === 'open') return 'vf-edge-label--green';
  if (edge.data?.branch === 'closed') return 'vf-edge-label--orange';
  if (edge.data?.branch === 'option') return 'vf-edge-label--blue';
  return '';
};

const nodeHasNoOutgoing = (id) => {
  return !vfEdges.value.some(e => e.source === id);
};

// ============================================================
// Steps <-> VueFlow conversion
// ============================================================
function stepsToNodesAndEdges(stepsObj) {
  const nodes = [];
  const edges = [];

  Object.entries(stepsObj).forEach(([key, step]) => {
    const vfType = STEP_TO_VF_TYPE[step.type] || 'message';
    nodes.push({
      id: key,
      type: vfType,
      position: { x: 0, y: 0 },
      data: { ...step },
    });

    const isMessageType = ['message', 'input_select', 'text'].includes(step.type);
    if (isMessageType && step.options && step.options.length > 0) {
      step.options.forEach((opt, idx) => {
        if (opt.next_step && stepsObj[opt.next_step]) {
          edges.push({
            id: `${key}-opt${idx}-${opt.next_step}`,
            source: key,
            target: opt.next_step,
            sourceHandle: `opt-${idx}`,
            type: 'smoothstep',
            animated: true,
            style: { stroke: '#94a3b8', strokeWidth: 2 },
            label: opt.title || opt.value || '',
            data: { branch: 'option' },
          });
        }
      });
    } else if (step.type === 'check_hours') {
      if (step.open_next && stepsObj[step.open_next]) {
        edges.push({
          id: `${key}-open-${step.open_next}`,
          source: key,
          target: step.open_next,
          sourceHandle: 'open',
          type: 'smoothstep',
          animated: true,
          style: { stroke: '#22c55e', strokeWidth: 2 },
          label: 'Quando em aberto',
          data: { branch: 'open' },
        });
      }
      if (step.closed_next && stepsObj[step.closed_next]) {
        edges.push({
          id: `${key}-closed-${step.closed_next}`,
          source: key,
          target: step.closed_next,
          sourceHandle: 'closed',
          type: 'smoothstep',
          animated: true,
          style: { stroke: '#f97316', strokeWidth: 2 },
          label: 'Quando fechado',
          data: { branch: 'closed' },
        });
      }
    } else if (step.next_step && stepsObj[step.next_step]) {
      edges.push({
        id: `${key}-next-${step.next_step}`,
        source: key,
        target: step.next_step,
        type: 'smoothstep',
        animated: true,
        style: { stroke: '#94a3b8', strokeWidth: 2 },
      });
    }
  });

  const laid = layoutNodes(nodes, edges);
  return { nodes: laid, edges };
}

function rebuildAll() {
  const { nodes, edges } = stepsToNodesAndEdges(steps);
  vfNodes.value = nodes;
  vfEdges.value = edges;
}

function rebuildEdges() {
  // Keep existing node positions, only rebuild edges
  const { edges } = stepsToNodesAndEdges(steps);
  vfEdges.value = edges;
}

function syncStepToVueFlow(key) {
  if (!key || !steps[key]) return;
  const idx = vfNodes.value.findIndex(n => n.id === key);
  if (idx >= 0) {
    vfNodes.value[idx] = {
      ...vfNodes.value[idx],
      data: { ...steps[key] },
    };
  }
}

function doAutoLayout() {
  const edges = vfEdges.value;
  const nodes = vfNodes.value.map(n => ({ ...n }));
  const laid = layoutNodes(nodes, edges);
  vfNodes.value = laid;
}

// ============================================================
// Vue Flow event handlers
// ============================================================
function onNodeClick({ node }) {
  selectedNodeKey.value = node.id;
  editingKey.value = node.id;
  sidebarTab.value = 'node';
  showSidebar.value = true;
}

function onPaneClick() {
  selectedNodeKey.value = '';
  if (sidebarTab.value === 'node') {
    showSidebar.value = false;
  }
}

function onConnect(params) {
  const sourceNode = steps[params.source];
  if (!sourceNode) return;

  const targetKey = params.target;
  const sourceHandle = params.sourceHandle;

  if (sourceNode.type === 'message' && sourceHandle && sourceHandle.startsWith('opt-')) {
    const idx = parseInt(sourceHandle.replace('opt-', ''), 10);
    if (sourceNode.options && sourceNode.options[idx]) {
      sourceNode.options[idx].next_step = targetKey;
    }
  } else if (sourceNode.type === 'check_hours') {
    if (sourceHandle === 'open') {
      sourceNode.open_next = targetKey;
    } else if (sourceHandle === 'closed') {
      sourceNode.closed_next = targetKey;
    }
  } else {
    sourceNode.next_step = targetKey;
  }

  rebuildEdges();
}

// ============================================================
// Sidebar / Node operations
// ============================================================
const closeSidebar = () => {
  showSidebar.value = false;
  selectedNodeKey.value = '';
};

const openConfigPanel = () => {
  sidebarTab.value = 'config';
  showSidebar.value = true;
};

// --- Rename step key ---
const renameStepKey = () => {
  const oldKey = selectedNodeKey.value;
  const newKey = editingKey.value.trim().replace(/\s+/g, '_').toLowerCase();
  if (!newKey || newKey === oldKey || steps[newKey]) {
    editingKey.value = oldKey;
    return;
  }

  const stepData = { ...steps[oldKey] };
  steps[newKey] = stepData;
  delete steps[oldKey];

  Object.keys(steps).forEach(k => {
    const s = steps[k];
    if (s.options) {
      s.options.forEach(opt => {
        if (opt.next_step === oldKey) opt.next_step = newKey;
      });
    }
    if (s.next_step === oldKey) s.next_step = newKey;
    if (s.open_next === oldKey) s.open_next = newKey;
    if (s.closed_next === oldKey) s.closed_next = newKey;
  });

  selectedNodeKey.value = newKey;
  rebuildAll();
};

// --- Add/remove options ---
const addOption = () => {
  if (!selectedStep.value) return;
  if (!selectedStep.value.options) selectedStep.value.options = [];
  selectedStep.value.options.push({ title: '', value: '', next_step: '' });
  syncStepToVueFlow(selectedNodeKey.value);
};

const removeOption = (idx) => {
  if (!selectedStep.value || !selectedStep.value.options) return;
  selectedStep.value.options.splice(idx, 1);
  syncStepToVueFlow(selectedNodeKey.value);
  rebuildEdges();
};

// --- Add/remove fields (collect_data) ---
const addField = () => {
  if (!selectedStep.value) return;
  if (!selectedStep.value.fields) selectedStep.value.fields = [];
  selectedStep.value.fields.push({ name: '', label: '', type: 'text', required: false });
  syncStepToVueFlow(selectedNodeKey.value);
};

// --- Delete node ---
const deleteSelectedNode = () => {
  const key = selectedNodeKey.value;
  if (!key || key === 'start') return;

  Object.keys(steps).forEach(k => {
    const s = steps[k];
    if (s.options) {
      s.options.forEach(opt => {
        if (opt.next_step === key) opt.next_step = '';
      });
    }
    if (s.next_step === key) s.next_step = '';
    if (s.open_next === key) s.open_next = '';
    if (s.closed_next === key) s.closed_next = '';
  });

  delete steps[key];
  selectedNodeKey.value = '';
  showSidebar.value = false;
  rebuildAll();
};

// --- Add node (from inline "+" button on a node) ---
const onAddFromNode = (parentKey) => {
  addMenuParentKey.value = parentKey;
  addMenuContext.value = 'next';
  addMenuVisible.value = true;
};

// --- Add node (FAB button, no parent) ---
const onFabAdd = () => {
  addMenuParentKey.value = '';
  addMenuContext.value = '';
  addMenuVisible.value = true;
};

const confirmAddNode = (type) => {
  addMenuVisible.value = false;
  const parentKey = addMenuParentKey.value;
  const context = addMenuContext.value;

  let baseKey = type + '_' + Date.now().toString(36);
  while (steps[baseKey]) {
    baseKey = type + '_' + Math.random().toString(36).substring(2, 8);
  }

  const newStep = { type };
  if (type === 'message') {
    newStep.message = '';
    newStep.options = [];
  } else if (type === 'collect_data') {
    newStep.message = 'Poderia me informar os seus dados?';
    newStep.fields = [
      { name: 'email', label: 'E-mail', type: 'email', required: true },
    ];
    newStep.next_step = '';
  } else if (type === 'check_hours') {
    newStep.open_next = '';
    newStep.closed_next = '';
  } else if (type === 'transfer') {
    newStep.message = '';
    newStep.team_id = null;
    newStep.agent_id = null;
  } else if (type === 'wait_response') {
    newStep.message = '';
    newStep.variable = '';
    newStep.validation = '';
    newStep.next_step = '';
  }

  steps[baseKey] = newStep;

  // Wire up parent -> new node
  if (parentKey && steps[parentKey]) {
    const parent = steps[parentKey];
    if (parent.type === 'message' && context === 'next') {
      if (!parent.options || parent.options.length === 0) {
        if (!parent.next_step) parent.next_step = baseKey;
      }
    } else if (parent.type === 'collect_data' || parent.type === 'wait_response') {
      if (!parent.next_step) parent.next_step = baseKey;
    } else if (parent.type === 'check_hours') {
      if (!parent.open_next) parent.open_next = baseKey;
      else if (!parent.closed_next) parent.closed_next = baseKey;
    } else {
      if (!parent.next_step) parent.next_step = baseKey;
    }
  }

  rebuildAll();

  nextTick(() => {
    selectedNodeKey.value = baseKey;
    editingKey.value = baseKey;
    sidebarTab.value = 'node';
    showSidebar.value = true;
  });
};

const createRootNode = () => {
  steps.start = {
    type: 'message',
    message: '',
    options: [],
  };
  rebuildAll();
  nextTick(() => {
    selectedNodeKey.value = 'start';
    editingKey.value = 'start';
    sidebarTab.value = 'node';
    showSidebar.value = true;
  });
};

// ============================================================
// Avatar upload
// ============================================================
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

// ============================================================
// Load existing flow
// ============================================================
const loadFlow = () => {
  if (!isEditing.value) {
    if (Object.keys(steps).length === 0) {
      steps.start = {
        type: 'message',
        message: '',
        options: [],
      };
    }
    rebuildAll();
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
    Object.keys(steps).forEach(k => delete steps[k]);
    Object.keys(flow.steps).forEach(k => {
      steps[k] = JSON.parse(JSON.stringify(flow.steps[k]));
    });
  } else {
    Object.keys(steps).forEach(k => delete steps[k]);
    steps.start = {
      type: 'message',
      message: config.greeting || '',
      options: [],
    };
  }

  rebuildAll();
};

watch(flows, () => loadFlow());

onMounted(async () => {
  await store.dispatch('conversationFlows/get');
  store.dispatch('inboxes/get');
  store.dispatch('teams/get');
  loadFlow();
});

// ============================================================
// Save
// ============================================================
const saveFlow = async () => {
  isSaving.value = true;
  try {
    const stepsObj = {};
    Object.keys(steps).forEach(k => {
      stepsObj[k] = JSON.parse(JSON.stringify(steps[k]));
    });

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
</script>

<style>
/* Vue Flow base styles - must be unscoped */
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
  background: #f8fafc;
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
   MAIN AREA
   ============================================================ */
.flow-main-area {
  flex: 1;
  position: relative;
  overflow: hidden;
  display: flex;
}

/* ============================================================
   VUE FLOW CANVAS
   ============================================================ */
.flow-canvas {
  flex: 1;
  transition: margin-right 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
}

.flow-canvas.sidebar-open {
  margin-right: 400px;
}

.flow-canvas :deep(.vue-flow) {
  width: 100%;
  height: 100%;
  background: #f8fafc;
}

.flow-empty-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
  z-index: 5;
}

.flow-empty-overlay > * {
  pointer-events: auto;
}

/* ============================================================
   CUSTOM VUE FLOW NODES
   ============================================================ */
.vf-node {
  width: 300px;
  background: white;
  border-radius: 10px;
  border: 1px solid #e2e8f0;
  border-left: 4px solid;
  padding: 14px 16px;
  cursor: pointer;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06), 0 1px 2px rgba(0, 0, 0, 0.04);
  transition: all 0.2s;
  user-select: none;
  position: relative;
}

.vf-node:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.vf-node--selected {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
}

.vf-node--message { border-left-color: #0ea5e9; }
.vf-node--collectData { border-left-color: #10b981; }
.vf-node--transfer { border-left-color: #f97316; }
.vf-node--waitResponse { border-left-color: #8b5cf6; }

.vf-node__header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 6px;
}

.vf-node__icon {
  font-size: 16px;
  line-height: 1;
}

.vf-node__key {
  font-size: 13px;
  font-weight: 600;
  color: #334155;
  font-family: 'SF Mono', 'Fira Code', monospace;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.vf-node__text {
  font-size: 12px;
  color: #64748b;
  line-height: 1.5;
  margin: 0 0 8px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.vf-node__badge {
  display: inline-flex;
  align-items: center;
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  margin-bottom: 8px;
}

.vf-node__badge--message { background: #e0f2fe; color: #0369a1; }
.vf-node__badge--collectData { background: #d1fae5; color: #065f46; }
.vf-node__badge--transfer { background: #ffedd5; color: #9a3412; }
.vf-node__badge--waitResponse { background: #ede9fe; color: #5b21b6; }

.vf-node__options {
  display: flex;
  flex-direction: column;
  gap: 0;
  margin-top: 8px;
}

.vf-node__option-pill {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 6px 12px;
  border-radius: 8px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  color: #1d4ed8;
  font-size: 12px;
  font-weight: 500;
  white-space: nowrap;
  flex: 1;
}

.vf-node__option-pill::after {
  content: '→';
  margin-left: 8px;
  opacity: 0.5;
}

.vf-node__fields {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-bottom: 8px;
}

.vf-node__field-chip {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 6px;
  background: #f1f5f9;
  color: #475569;
  font-size: 11px;
  gap: 2px;
}

.vf-node__validation-badge {
  display: inline-flex;
  align-items: center;
  padding: 3px 10px;
  border-radius: 12px;
  background: #ede9fe;
  color: #5b21b6;
  font-size: 11px;
  font-weight: 600;
  gap: 4px;
}

.vf-node__add-btn {
  position: absolute;
  bottom: -32px;
  left: 50%;
  transform: translateX(-50%);
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: white;
  border: 2px dashed #cbd5e1;
  color: #94a3b8;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s;
  z-index: 10;
}

.vf-node__add-btn:hover {
  border-color: #3b82f6;
  color: #3b82f6;
  background: #eff6ff;
  transform: translateX(-50%) scale(1.15);
}

/* ============================================================
   DIAMOND NODE (Check Hours)
   ============================================================ */
.vf-node-diamond-wrap {
  display: flex;
  flex-direction: column;
  align-items: center;
  cursor: pointer;
  position: relative;
  width: 80px;
  padding: 10px 0;
}

.vf-node-diamond-wrap.vf-node--selected .vf-node-diamond {
  outline: 2px solid #1d4ed8;
  outline-offset: 3px;
}

.vf-node-diamond {
  width: 56px;
  height: 56px;
  background: #3b82f6;
  border-radius: 10px;
  transform: rotate(45deg);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.3);
  transition: all 0.2s;
}

.vf-node-diamond:hover {
  box-shadow: 0 4px 16px rgba(59, 130, 246, 0.4);
}

.vf-node-diamond__icon {
  transform: rotate(-45deg);
  font-size: 20px;
  line-height: 1;
}

.vf-node-diamond__label {
  margin-top: 8px;
  font-size: 12px;
  font-weight: 600;
  color: #475569;
  font-family: 'SF Mono', 'Fira Code', monospace;
  white-space: nowrap;
}

/* ============================================================
   VUE FLOW HANDLES
   ============================================================ */
.vf-handle {
  width: 10px !important;
  height: 10px !important;
  border-radius: 50% !important;
  border: 2px solid #94a3b8 !important;
  background: white !important;
}

.vf-handle--target {
  top: -5px !important;
}

.vf-handle--source {
  bottom: -5px !important;
}

.vf-handle--source-pill {
  width: 10px !important;
  height: 10px !important;
  border: 2px solid #3b82f6 !important;
  background: white !important;
  right: -5px !important;
  top: 50% !important;
  transform: translateY(-50%) !important;
}

.vf-node__option-pill-row {
  position: relative;
  display: flex;
  align-items: center;
  margin-bottom: 4px;
}

.vf-node__option-pill-row:last-child {
  margin-bottom: 0;
}

.vf-handle--source-green {
  border-color: #22c55e !important;
  left: -5px !important;
}

.vf-handle--source-orange {
  border-color: #f97316 !important;
  right: -5px !important;
}

/* ============================================================
   EDGE LABELS
   ============================================================ */
.vf-edge-label {
  padding: 3px 10px;
  border-radius: 12px;
  font-size: 11px;
  font-weight: 600;
  background: #f1f5f9;
  color: #475569;
  white-space: nowrap;
  pointer-events: none;
}

.vf-edge-label--green { background: #d1fae5; color: #065f46; }
.vf-edge-label--orange { background: #ffedd5; color: #9a3412; }
.vf-edge-label--blue { background: #dbeafe; color: #1d4ed8; }

/* ============================================================
   FLOATING ADD BUTTON
   ============================================================ */
.fab-add {
  position: absolute;
  bottom: 24px;
  right: 24px;
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: #3b82f6;
  color: white;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  box-shadow: 0 4px 16px rgba(59, 130, 246, 0.4);
  transition: all 0.2s;
  z-index: 10;
}

.fab-add:hover {
  background: #2563eb;
  transform: scale(1.1);
  box-shadow: 0 6px 24px rgba(59, 130, 246, 0.5);
}

/* ============================================================
   EMPTY STATE
   ============================================================ */
.tree-empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 16px;
}

.tree-empty-icon {
  width: 64px;
  height: 64px;
  border-radius: 16px;
  background: #f1f5f9;
  display: flex;
  align-items: center;
  justify-content: center;
}

.tree-empty-text {
  font-size: 15px;
  color: #94a3b8;
  margin: 0;
}

.tree-empty-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 24px;
  border-radius: 8px;
  background: #3b82f6;
  color: white;
  font-size: 14px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}

.tree-empty-btn:hover {
  background: #2563eb;
}

/* ============================================================
   ADD MENU OVERLAY
   ============================================================ */
.add-menu-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 200;
}

.add-menu-card {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.15);
  padding: 8px;
  min-width: 320px;
  max-width: 400px;
}

.add-menu-title {
  font-size: 14px;
  font-weight: 600;
  color: #475569;
  padding: 12px 16px 8px;
}

.add-menu-item {
  display: flex;
  align-items: center;
  gap: 14px;
  width: 100%;
  padding: 12px 16px;
  border: none;
  background: transparent;
  border-radius: 10px;
  cursor: pointer;
  text-align: left;
  transition: background 0.15s;
}

.add-menu-item:hover {
  background: #f8fafc;
}

.add-menu-dot {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
}

.add-menu-dot--message { background: #e0f2fe; }
.add-menu-dot--message::after { content: '\1F4AC'; }
.add-menu-dot--collect_data { background: #d1fae5; }
.add-menu-dot--collect_data::after { content: '\1F4CB'; }
.add-menu-dot--check_hours { background: #dbeafe; }
.add-menu-dot--check_hours::after { content: '\23F0'; }
.add-menu-dot--transfer { background: #ffedd5; }
.add-menu-dot--transfer::after { content: '\1F500'; }
.add-menu-dot--wait_response { background: #ede9fe; }
.add-menu-dot--wait_response::after { content: '\231B'; }

.add-menu-item-title {
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
}

.add-menu-item-desc {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

/* ============================================================
   RIGHT SIDEBAR
   ============================================================ */
.flow-sidebar {
  position: absolute;
  top: 0;
  right: 0;
  width: 400px;
  height: 100%;
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

.sidebar-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  flex-shrink: 0;
}

.sidebar-dot--message { background: #0ea5e9; }
.sidebar-dot--collect_data { background: #10b981; }
.sidebar-dot--check_hours { background: #3b82f6; }
.sidebar-dot--transfer { background: #f97316; }
.sidebar-dot--wait_response { background: #8b5cf6; }

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
  font-size: 13px;
  font-weight: 600;
  color: #475569;
  margin-bottom: 6px;
}

.flow-sidebar__label-sm {
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
  white-space: nowrap;
}

.flow-sidebar__label-detail {
  font-weight: 400;
  color: #94a3b8;
}

.flow-sidebar__input {
  width: 100%;
  height: 38px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  padding: 0 12px;
  font-size: 13px;
  color: #1e293b;
  outline: none;
  transition: border-color 0.15s;
  background: #fafbfc;
  box-sizing: border-box;
}

.flow-sidebar__input:focus {
  border-color: #3b82f6;
  background: white;
}

.flow-sidebar__input--mono {
  font-family: 'SF Mono', 'Fira Code', monospace;
}

.flow-sidebar__input--sm {
  height: 34px;
  font-size: 12px;
}

.flow-sidebar__textarea {
  width: 100%;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  padding: 10px 12px;
  font-size: 13px;
  color: #1e293b;
  outline: none;
  resize: vertical;
  min-height: 60px;
  transition: border-color 0.15s;
  background: #fafbfc;
  font-family: inherit;
  box-sizing: border-box;
}

.flow-sidebar__textarea:focus {
  border-color: #3b82f6;
  background: white;
}

.flow-sidebar__select {
  width: 100%;
  height: 38px;
  border-radius: 8px;
  border: 1px solid #e2e8f0;
  padding: 0 12px;
  font-size: 13px;
  color: #1e293b;
  outline: none;
  background: #fafbfc;
  cursor: pointer;
  transition: border-color 0.15s;
}

.flow-sidebar__select:focus {
  border-color: #3b82f6;
}

.flow-sidebar__select--sm {
  height: 34px;
  font-size: 12px;
  flex: 1;
}

.flow-sidebar__checkbox-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: #475569;
  white-space: nowrap;
  cursor: pointer;
}

.flow-sidebar__add-btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 12px;
  border-radius: 6px;
  background: #eff6ff;
  color: #3b82f6;
  font-size: 12px;
  font-weight: 600;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}

.flow-sidebar__add-btn:hover {
  background: #dbeafe;
}

.flow-sidebar__options-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.flow-sidebar__option-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
  padding: 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.flow-sidebar__option-row {
  display: flex;
  align-items: center;
  gap: 8px;
}

.flow-sidebar__option-num {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  background: #e2e8f0;
  color: #475569;
  font-size: 11px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.flow-sidebar__remove-btn {
  width: 28px;
  height: 28px;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #ef4444;
  background: transparent;
  border: none;
  cursor: pointer;
  flex-shrink: 0;
  transition: background 0.15s;
}

.flow-sidebar__remove-btn:hover {
  background: #fef2f2;
}

.flow-sidebar__hint {
  font-size: 11px;
  color: #94a3b8;
}

.flow-sidebar__range {
  width: 100%;
  margin: 4px 0;
}

.flow-sidebar__range-labels {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: #94a3b8;
}

/* Avatar */
.flow-sidebar__avatar-row {
  display: flex;
  align-items: flex-start;
  gap: 16px;
}

.flow-sidebar__avatar {
  width: 64px;
  height: 64px;
  border-radius: 12px;
  background: #f1f5f9;
  overflow: hidden;
  cursor: pointer;
  position: relative;
  flex-shrink: 0;
  border: 1px solid #e2e8f0;
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
  gap: 8px;
}

.flow-sidebar__avatar-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  border-radius: 6px;
  background: #f1f5f9;
  color: #475569;
  font-size: 12px;
  font-weight: 500;
  border: none;
  cursor: pointer;
  transition: background 0.15s;
}

.flow-sidebar__avatar-btn:hover {
  background: #e2e8f0;
}

.flow-sidebar__avatar-btn--danger {
  color: #ef4444;
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
  font-weight: 600;
  color: #1e293b;
}

.flow-sidebar__toggle-desc {
  font-size: 12px;
  color: #94a3b8;
  margin-top: 2px;
}

.flow-sidebar__toggle {
  width: 44px;
  height: 24px;
  border-radius: 12px;
  background: #e2e8f0;
  border: none;
  cursor: pointer;
  position: relative;
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
  border-top: 1px solid #fecaca;
}

.flow-sidebar__delete-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 10px 16px;
  border-radius: 8px;
  background: #fef2f2;
  color: #dc2626;
  font-size: 13px;
  font-weight: 600;
  border: 1px solid #fecaca;
  cursor: pointer;
  transition: background 0.15s;
}

.flow-sidebar__delete-btn:hover {
  background: #fee2e2;
}

/* Empty sidebar */
.flow-sidebar__empty {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: #94a3b8;
  font-size: 14px;
  text-align: center;
  padding: 40px;
}

/* ============================================================
   TRANSITIONS
   ============================================================ */
.sidebar-slide-enter-active,
.sidebar-slide-leave-active {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.sidebar-slide-enter-from,
.sidebar-slide-leave-to {
  transform: translateX(100%);
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}

/* ============================================================
   UTILITY
   ============================================================ */
.hidden {
  display: none;
}
</style>
