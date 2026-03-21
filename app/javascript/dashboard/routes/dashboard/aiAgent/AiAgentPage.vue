<template>
  <div class="flex flex-col h-full overflow-y-auto p-6">
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

    <!-- Create/Edit Dialog -->
    <div
      v-if="showDialog"
      class="fixed inset-0 z-50 flex items-start justify-center pt-[5vh]"
    >
      <div class="absolute inset-0 bg-black/20" @click="closeDialog" />
      <div
        class="relative bg-white rounded-xl outline outline-1 outline-n-slate-4 shadow-xl w-full max-w-3xl mx-4 max-h-[90vh] flex flex-col"
      >
        <!-- Dialog Header -->
        <div class="px-6 py-5 border-b border-n-slate-3 flex-shrink-0">
          <h3 class="text-base font-semibold text-n-slate-12">
            {{ isEditing ? 'Editar Agente' : 'Novo Agente' }}
          </h3>
          <p class="text-xs text-n-slate-9 mt-0.5">
            {{ isEditing ? 'Atualize as configurações do agente' : 'Configure um novo agente de IA' }}
          </p>
        </div>

        <!-- Tabs -->
        <div v-if="isEditing" class="px-6 pt-4 pb-0 flex-shrink-0">
          <div class="flex gap-2">
            <button
              v-for="tab in tabs"
              :key="tab.key"
              class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-sm font-medium transition-colors"
              :class="activeTab === tab.key ? 'bg-n-brand text-white' : 'bg-n-slate-2 text-n-slate-11 hover:bg-n-slate-3'"
              @click="activeTab = tab.key"
            >
              <span :class="tab.icon" class="w-4 h-4" />
              {{ tab.label }}
            </button>
          </div>
        </div>

        <!-- Dialog Body -->
        <div class="flex-1 overflow-y-auto px-6 py-5">
          <!-- TAB: Configurações -->
          <div v-show="activeTab === 'configuracoes'" class="space-y-5">
            <!-- Nome -->
            <div>
              <label class="text-sm font-medium text-n-slate-12">Nome</label>
              <input
                v-model="form.name"
                type="text"
                placeholder="Ex: Suporte Curso Beta"
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
              />
            </div>

            <!-- Descrição -->
            <div>
              <label class="text-sm font-medium text-n-slate-12">Descrição</label>
              <input
                v-model="form.description"
                type="text"
                placeholder="Breve descrição do agente"
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
              />
            </div>

            <!-- System Prompt -->
            <div>
              <label class="text-sm font-medium text-n-slate-12">
                Prompt do sistema
              </label>
              <p class="text-xs text-n-slate-9 mt-0.5">
                Instruções que definem o comportamento do agente
              </p>
              <textarea
                v-model="form.system_prompt"
                rows="4"
                placeholder="Você é um atendente de suporte ao cliente..."
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-none"
              />
            </div>

            <!-- Modelo + Modo -->
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

            <!-- Temperatura + Max Tokens -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="text-sm font-medium text-n-slate-12">
                  Temperatura
                  <span class="text-n-slate-9 font-normal">({{ form.temperature }})</span>
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
                <label class="text-sm font-medium text-n-slate-12">
                  Máx. tokens
                </label>
                <input
                  v-model.number="form.max_tokens"
                  type="number"
                  min="100"
                  max="4000"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
                />
              </div>
            </div>

            <!-- Idioma + Contexto -->
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="text-sm font-medium text-n-slate-12">Idioma</label>
                <select
                  v-model="form.language"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
                >
                  <option value="pt-BR">Português (BR)</option>
                  <option value="en">English</option>
                  <option value="es">Español</option>
                </select>
              </div>
              <div>
                <label class="text-sm font-medium text-n-slate-12">
                  Mensagens de contexto
                </label>
                <input
                  v-model.number="form.context_messages"
                  type="number"
                  min="1"
                  max="50"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
                />
              </div>
            </div>

            <!-- Welcome / Handoff / Resolution Messages -->
            <div class="space-y-4">
              <div>
                <label class="text-sm font-medium text-n-slate-12">Mensagem de boas-vindas</label>
                <input
                  v-model="form.welcome_message"
                  type="text"
                  placeholder="Olá! Como posso ajudar?"
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
                />
              </div>
              <div>
                <label class="text-sm font-medium text-n-slate-12">Mensagem de handoff</label>
                <input
                  v-model="form.handoff_message"
                  type="text"
                  placeholder="Vou transferir você para um atendente humano..."
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
                />
              </div>
              <div>
                <label class="text-sm font-medium text-n-slate-12">Mensagem de resolução</label>
                <input
                  v-model="form.resolution_message"
                  type="text"
                  placeholder="Fico feliz em ter ajudado! Até a próxima."
                  class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand h-10 px-3"
                />
              </div>
            </div>

            <!-- Base de Conhecimento -->
            <div>
              <label class="text-sm font-medium text-n-slate-12">
                Base de conhecimento
              </label>
              <p class="text-xs text-n-slate-9 mt-0.5">
                Informações adicionais que o agente pode consultar
              </p>
              <textarea
                v-model="form.knowledge_base"
                rows="3"
                placeholder="Cole aqui FAQs, políticas, informações do produto..."
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-none"
              />
            </div>

            <!-- Guardrails -->
            <div>
              <label class="text-sm font-medium text-n-slate-12">
                Guardrails
              </label>
              <p class="text-xs text-n-slate-9 mt-0.5">
                Regras obrigatórias que o agente deve seguir (uma por linha)
              </p>
              <textarea
                v-model="form.guardrails_text"
                rows="3"
                placeholder="Nunca compartilhe dados pessoais de clientes&#10;Sempre confirme o pedido antes de processar&#10;Não ofereça descontos sem autorização"
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-none"
              />
            </div>

            <!-- Response Guidelines -->
            <div>
              <label class="text-sm font-medium text-n-slate-12">
                Diretrizes de resposta
              </label>
              <p class="text-xs text-n-slate-9 mt-0.5">
                Orientações de estilo e formato para as respostas (uma por linha)
              </p>
              <textarea
                v-model="form.response_guidelines_text"
                rows="3"
                placeholder="Use tom profissional mas amigável&#10;Respostas curtas e diretas&#10;Sempre ofereça ajuda adicional ao final"
                class="mt-1.5 block w-full rounded-lg text-sm bg-n-slate-1 border-none outline outline-1 outline-n-slate-4 focus:outline-n-brand px-3 py-2.5 resize-none"
              />
            </div>

            <!-- Ativo toggle -->
            <div
              v-if="isEditing"
              class="flex items-center justify-between py-3 px-4 rounded-lg bg-n-slate-1"
            >
              <div>
                <p class="text-sm font-medium text-n-slate-12">Agente ativo</p>
                <p class="text-xs text-n-slate-9">
                  Quando ativo, o agente responde automaticamente
                </p>
              </div>
              <button
                class="relative w-11 h-6 rounded-full transition-colors"
                :class="form.active ? 'bg-n-brand' : 'bg-n-slate-4'"
                @click="form.active = !form.active"
              >
                <span
                  class="absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform"
                  :class="form.active ? 'left-[22px]' : 'left-0.5'"
                />
              </button>
            </div>
          </div>

          <!-- TAB: Documentos -->
          <div v-show="activeTab === 'documentos'" class="space-y-5">
            <!-- Upload Zone -->
            <div
              class="border-2 border-dashed border-n-slate-4 rounded-xl p-8 text-center hover:border-n-brand/50 transition-colors"
              @dragover.prevent="dragOver = true"
              @dragleave.prevent="dragOver = false"
              @drop.prevent="handleFileDrop"
              :class="{ 'border-n-brand bg-n-brand/5': dragOver }"
            >
              <span class="i-lucide-upload-cloud w-10 h-10 text-n-slate-9 mx-auto mb-3" />
              <p class="text-sm text-n-slate-11 mb-1">
                Arraste arquivos aqui ou
              </p>
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
              <p class="text-xs text-n-slate-9 mt-2">
                PDF, TXT, CSV, DOCX
              </p>
            </div>

            <!-- Upload Progress -->
            <div v-if="isUploading" class="flex items-center gap-3 p-4 rounded-lg bg-n-slate-1">
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
                    <p class="text-sm font-medium text-n-slate-12">{{ doc.file_name }}</p>
                    <p class="text-xs text-n-slate-9">
                      {{ doc.file_type.toUpperCase() }}
                      <span v-if="doc.file_size"> · {{ formatFileSize(doc.file_size) }}</span>
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
              <span class="i-lucide-file-text w-10 h-10 text-n-slate-9 mx-auto mb-3" />
              <p class="text-sm text-n-slate-9">Nenhum documento enviado</p>
            </div>
          </div>

          <!-- TAB: Playground -->
          <div v-show="activeTab === 'playground'" class="flex flex-col h-[500px]">
            <!-- Chat Messages -->
            <div ref="chatContainer" class="flex-1 overflow-y-auto space-y-3 mb-4">
              <div
                v-for="(msg, idx) in playgroundMessages"
                :key="idx"
                class="flex"
                :class="msg.role === 'user' ? 'justify-end' : 'justify-start'"
              >
                <div
                  class="max-w-[80%] px-4 py-2.5 rounded-xl text-sm"
                  :class="msg.role === 'user'
                    ? 'bg-n-brand text-white rounded-br-sm'
                    : 'bg-n-slate-2 text-n-slate-12 rounded-bl-sm'"
                >
                  <p class="whitespace-pre-wrap">{{ msg.content }}</p>
                </div>
              </div>
              <div v-if="playgroundLoading" class="flex justify-start">
                <div class="bg-n-slate-2 text-n-slate-12 px-4 py-2.5 rounded-xl rounded-bl-sm">
                  <span class="i-lucide-loader-2 w-4 h-4 animate-spin inline-block" />
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
          <div v-show="activeTab === 'caixas'" class="space-y-5">
            <!-- Add inbox -->
            <div class="flex gap-2">
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
                  <div class="w-9 h-9 rounded-lg bg-n-brand/10 flex items-center justify-center flex-shrink-0">
                    <span class="i-lucide-inbox w-4.5 h-4.5 text-n-brand" />
                  </div>
                  <div>
                    <p class="text-sm font-medium text-n-slate-12">{{ inbox.inbox_name }}</p>
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
              <p class="text-sm text-n-slate-9">Nenhuma caixa de entrada conectada</p>
            </div>
          </div>
        </div>

        <!-- Dialog Footer -->
        <div
          class="px-6 py-4 border-t border-n-slate-3 flex items-center justify-end gap-3 flex-shrink-0"
        >
          <button
            class="h-9 px-4 rounded-lg text-sm font-medium text-n-slate-12 outline outline-1 outline-n-slate-4 hover:bg-n-slate-2"
            @click="closeDialog"
          >
            Cancelar
          </button>
          <button
            v-if="activeTab === 'configuracoes'"
            class="h-9 px-4 rounded-lg bg-n-brand text-white text-sm font-medium hover:brightness-110 disabled:opacity-50"
            :disabled="!form.name || isSaving"
            @click="saveAgent"
          >
            <span
              v-if="isSaving"
              class="i-lucide-loader-2 w-4 h-4 animate-spin"
            />
            <span v-else>{{ isEditing ? 'Salvar' : 'Criar Agente' }}</span>
          </button>
        </div>
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
const uiFlags = useMapGetter('aiAgents/getUIFlags');
const isFetching = computed(() => uiFlags.value?.fetchingList);

const accountId = computed(() => route.params.accountId);
const apiHeaders = computed(() => ({
  api_access_token: store.getters['auth/getCurrentUser']?.access_token,
}));
const apiUrl = path => `/api/v1/accounts/${accountId.value}${path}`;

const showDialog = ref(false);
const isEditing = ref(false);
const isSaving = ref(false);
const editingAgentId = ref(null);
const activeTab = ref('configuracoes');

const tabs = [
  { key: 'configuracoes', label: 'Configurações', icon: 'i-lucide-settings' },
  { key: 'documentos', label: 'Documentos', icon: 'i-lucide-file-text' },
  { key: 'playground', label: 'Playground', icon: 'i-lucide-message-square' },
  { key: 'caixas', label: 'Caixas de Entrada', icon: 'i-lucide-inbox' },
];

const defaultForm = {
  name: '',
  description: '',
  active: true,
  system_prompt: 'Você é um atendente de suporte ao cliente profissional e amigável.',
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

// --- Documents ---
const documents = ref([]);
const isUploading = ref(false);
const dragOver = ref(false);

const fetchDocuments = async () => {
  if (!editingAgentId.value) return;
  try {
    const { data } = await axios.get(
      apiUrl(`/ai_agents/${editingAgentId.value}/documents`),
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
  if (!editingAgentId.value) return;
  isUploading.value = true;
  try {
    const formData = new FormData();
    formData.append('file', file);
    await axios.post(
      apiUrl(`/ai_agents/${editingAgentId.value}/documents`),
      formData,
      { headers: { ...apiHeaders.value, 'Content-Type': 'multipart/form-data' } }
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
      apiUrl(`/ai_agents/${editingAgentId.value}/documents/${doc.id}`),
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
      apiUrl(`/ai_agents/${editingAgentId.value}/playground`),
      { message_content: text, message_history: history },
      { headers: apiHeaders.value }
    );

    const response = data.response || data.error || 'Sem resposta';
    playgroundMessages.value.push({ role: 'assistant', content: response });
  } catch (e) {
    playgroundMessages.value.push({
      role: 'assistant',
      content: 'Erro ao gerar resposta. Verifique a configuração da API.',
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
  if (!editingAgentId.value) return;
  try {
    const [connected, available] = await Promise.all([
      axios.get(
        apiUrl(`/ai_agents/${editingAgentId.value}/inboxes`),
        { headers: apiHeaders.value }
      ),
      axios.get(
        apiUrl(`/ai_agents/${editingAgentId.value}/inboxes?available=true`),
        { headers: apiHeaders.value }
      ),
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
      apiUrl(`/ai_agents/${editingAgentId.value}/inboxes`),
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
      apiUrl(`/ai_agents/${editingAgentId.value}/inboxes/${inbox.inbox_id}`),
      { headers: apiHeaders.value }
    );
    await fetchInboxes();
    store.dispatch('aiAgents/get');
  } catch (e) {
    // handle error
  }
};

// --- Dialog lifecycle ---
onMounted(() => {
  store.dispatch('aiAgents/get');
});

const openCreateDialog = () => {
  Object.assign(form, { ...defaultForm });
  isEditing.value = false;
  editingAgentId.value = null;
  activeTab.value = 'configuracoes';
  playgroundMessages.value = [];
  documents.value = [];
  connectedInboxes.value = [];
  availableInboxes.value = [];
  showDialog.value = true;
};

const openEditDialog = agent => {
  isEditing.value = true;
  editingAgentId.value = agent.id;
  activeTab.value = 'configuracoes';

  const guardrailsArr = agent.config?.guardrails || [];
  const guidelinesArr = agent.config?.response_guidelines || [];

  Object.assign(form, {
    name: agent.name || '',
    description: agent.description || '',
    active: agent.active ?? true,
    system_prompt: agent.config?.system_prompt || defaultForm.system_prompt,
    openai_model: agent.config?.openai_model || 'gpt-4o',
    temperature: Number(agent.config?.temperature) || 0.7,
    mode: agent.config?.mode || 'auto',
    language: agent.config?.language || 'pt-BR',
    max_tokens: Number(agent.config?.max_tokens) || 500,
    context_messages: Number(agent.config?.context_messages) || 10,
    knowledge_base: agent.config?.knowledge_base || '',
    welcome_message: agent.config?.welcome_message || '',
    handoff_message: agent.config?.handoff_message || '',
    resolution_message: agent.config?.resolution_message || '',
    guardrails_text: Array.isArray(guardrailsArr) ? guardrailsArr.join('\n') : '',
    response_guidelines_text: Array.isArray(guidelinesArr) ? guidelinesArr.join('\n') : '',
  });

  playgroundMessages.value = [];
  showDialog.value = true;

  // Fetch related data
  fetchDocuments();
  fetchInboxes();
};

const closeDialog = () => {
  showDialog.value = false;
};

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

    if (isEditing.value) {
      await store.dispatch('aiAgents/update', {
        id: editingAgentId.value,
        ...payload,
      });
    } else {
      await store.dispatch('aiAgents/create', payload);
    }
    closeDialog();
    store.dispatch('aiAgents/get');
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
