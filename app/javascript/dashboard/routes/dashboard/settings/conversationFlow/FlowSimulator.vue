<template>
  <Transition name="simulator-slide">
    <div v-if="visible" class="simulator-panel">
      <div class="simulator-header">
        <span class="simulator-title">Simulador</span>
        <div class="simulator-header-actions">
          <button class="simulator-btn-reset" title="Reiniciar" @click="restart">
            <span class="i-lucide-rotate-ccw w-4 h-4" />
          </button>
          <button class="simulator-btn-close" @click="$emit('close')">
            <span class="i-lucide-x w-4 h-4" />
          </button>
        </div>
      </div>

      <div ref="messagesContainer" class="simulator-messages">
        <div
          v-for="(msg, idx) in messages"
          :key="idx"
          class="simulator-msg"
          :class="msg.sender === 'bot' ? 'simulator-msg--bot' : 'simulator-msg--user'"
        >
          <div class="simulator-msg-bubble" :class="msg.sender === 'bot' ? 'simulator-msg-bubble--bot' : 'simulator-msg-bubble--user'">
            <p v-if="msg.text" class="simulator-msg-text">{{ msg.text }}</p>

            <!-- Buttons -->
            <div v-if="msg.buttons && msg.buttons.length" class="simulator-buttons">
              <button
                v-for="(btn, bi) in msg.buttons"
                :key="bi"
                class="simulator-btn-option"
                :disabled="msg.answered"
                @click="onButtonClick(msg, btn)"
              >
                {{ btn.title }}
              </button>
            </div>

            <!-- Collect data fields -->
            <div v-if="msg.fields && msg.fields.length" class="simulator-fields">
              <div v-for="(field, fi) in msg.fields" :key="fi" class="simulator-field">
                <input
                  v-model="msg.fieldValues[field.name]"
                  :type="field.type === 'email' ? 'email' : field.type === 'phone' ? 'tel' : 'text'"
                  :placeholder="field.label || field.name"
                  class="simulator-field-input"
                  :disabled="msg.answered"
                />
              </div>
              <button
                v-if="!msg.answered"
                class="simulator-btn-submit"
                @click="onSubmitFields(msg)"
              >
                Enviar
              </button>
            </div>

            <!-- Check hours choice -->
            <div v-if="msg.hoursChoice" class="simulator-buttons">
              <button
                class="simulator-btn-option simulator-btn-option--green"
                :disabled="msg.answered"
                @click="onHoursChoice(msg, 'open')"
              >
                Aberto
              </button>
              <button
                class="simulator-btn-option simulator-btn-option--orange"
                :disabled="msg.answered"
                @click="onHoursChoice(msg, 'closed')"
              >
                Fechado
              </button>
            </div>

            <!-- Wait response input -->
            <div v-if="msg.waitInput && !msg.answered" class="simulator-wait-input">
              <input
                v-model="msg.inputValue"
                type="text"
                :placeholder="msg.waitPlaceholder || 'Digite sua resposta...'"
                class="simulator-field-input"
                @keyup.enter="onSubmitWait(msg)"
              />
              <button class="simulator-btn-send" @click="onSubmitWait(msg)">
                <span class="i-lucide-send w-4 h-4" />
              </button>
            </div>

            <!-- Transfer badge -->
            <div v-if="msg.transfer" class="simulator-transfer-badge">
              Transferido para Equipe {{ msg.transfer.team_id }}
            </div>

            <!-- End badge -->
            <div v-if="msg.ended" class="simulator-end-badge">
              Fluxo encerrado
            </div>
          </div>
        </div>

        <!-- Typing indicator -->
        <div v-if="isTyping" class="simulator-msg simulator-msg--bot">
          <div class="simulator-msg-bubble simulator-msg-bubble--bot">
            <div class="simulator-typing">
              <span /><span /><span />
            </div>
          </div>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { ref, reactive, nextTick, watch } from 'vue';

const props = defineProps({
  visible: { type: Boolean, default: false },
  steps: { type: Object, default: () => ({}) },
  teams: { type: Array, default: () => [] },
});

const emit = defineEmits(['close']);

const messages = reactive([]);
const isTyping = ref(false);
const messagesContainer = ref(null);
const currentStepKey = ref('');

const scrollToBottom = async () => {
  await nextTick();
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
};

const addBotMessage = async (content) => {
  isTyping.value = true;
  scrollToBottom();
  await new Promise(r => setTimeout(r, 600));
  isTyping.value = false;
  messages.push({ sender: 'bot', ...content });
  scrollToBottom();
};

const addUserMessage = (text) => {
  messages.push({ sender: 'user', text });
  scrollToBottom();
};

const getTeamName = (teamId) => {
  const team = props.teams.find(t => String(t.id) === String(teamId));
  return team ? team.name : `#${teamId}`;
};

const processStep = async (stepKey) => {
  const step = props.steps[stepKey];
  if (!step) {
    await addBotMessage({ text: `[Etapa "${stepKey}" nao encontrada]`, ended: true });
    return;
  }

  currentStepKey.value = stepKey;
  const type = step.type || 'message';

  if (type === 'message' || type === 'input_select' || type === 'text') {
    const hasOptions = step.options && step.options.length > 0;
    await addBotMessage({
      text: step.message || '',
      buttons: hasOptions ? step.options.map(o => ({
        title: o.title || o.value,
        value: o.value || o.title,
        next_step: o.next_step,
      })) : null,
      answered: false,
      stepKey,
    });
    // If no options, auto-advance to next_step
    if (!hasOptions && step.next_step) {
      await processStep(step.next_step);
    } else if (!hasOptions && !step.next_step) {
      await addBotMessage({ ended: true });
    }
  } else if (type === 'collect_data') {
    const fieldValues = {};
    (step.fields || []).forEach(f => { fieldValues[f.name] = ''; });
    await addBotMessage({
      text: step.message || 'Poderia me informar seus dados?',
      fields: step.fields || [],
      fieldValues,
      answered: false,
      stepKey,
    });
  } else if (type === 'check_hours') {
    await addBotMessage({
      text: `[Verificando horario de atendimento]`,
      hoursChoice: true,
      answered: false,
      stepKey,
    });
  } else if (type === 'transfer' || type === 'action') {
    if (step.message) {
      await addBotMessage({ text: step.message });
    }
    await addBotMessage({
      transfer: { team_id: step.team_id, team_name: getTeamName(step.team_id) },
    });
  } else if (type === 'wait_response') {
    await addBotMessage({
      text: step.message || 'Aguardando resposta...',
      waitInput: true,
      waitPlaceholder: step.validation === 'email' ? 'Digite um e-mail...' : step.validation === 'phone' ? 'Digite um telefone...' : 'Digite sua resposta...',
      inputValue: '',
      answered: false,
      stepKey,
    });
  } else {
    await addBotMessage({ text: `[Tipo desconhecido: ${type}]`, ended: true });
  }
};

const onButtonClick = async (msg, btn) => {
  msg.answered = true;
  addUserMessage(btn.title);
  if (btn.next_step) {
    await processStep(btn.next_step);
  } else {
    await addBotMessage({ ended: true });
  }
};

const onSubmitFields = async (msg) => {
  msg.answered = true;
  const values = Object.entries(msg.fieldValues)
    .map(([k, v]) => `${k}: ${v}`)
    .join(', ');
  addUserMessage(values || '(dados enviados)');
  const step = props.steps[msg.stepKey];
  if (step?.next_step) {
    await processStep(step.next_step);
  } else {
    await addBotMessage({ ended: true });
  }
};

const onHoursChoice = async (msg, choice) => {
  msg.answered = true;
  addUserMessage(choice === 'open' ? 'Aberto' : 'Fechado');
  const step = props.steps[msg.stepKey];
  const nextKey = choice === 'open' ? step?.open_next : step?.closed_next;
  if (nextKey) {
    await processStep(nextKey);
  } else {
    await addBotMessage({ ended: true });
  }
};

const onSubmitWait = async (msg) => {
  if (!msg.inputValue?.trim()) return;
  msg.answered = true;
  addUserMessage(msg.inputValue);
  const step = props.steps[msg.stepKey];
  if (step?.next_step) {
    await processStep(step.next_step);
  } else {
    await addBotMessage({ ended: true });
  }
};

const restart = () => {
  messages.splice(0, messages.length);
  currentStepKey.value = '';
  startSimulation();
};

const startSimulation = async () => {
  // Find the start step
  const startKey = props.steps.start ? 'start' : Object.keys(props.steps)[0];
  if (!startKey) {
    messages.push({ sender: 'bot', text: 'Nenhuma etapa encontrada no fluxo.' });
    return;
  }
  await processStep(startKey);
};

watch(() => props.visible, (val) => {
  if (val) {
    messages.splice(0, messages.length);
    nextTick(() => startSimulation());
  }
});
</script>

<style scoped>
.simulator-panel {
  position: fixed;
  right: 16px;
  top: 60px;
  bottom: 16px;
  width: 380px;
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 8px 32px rgba(0,0,0,0.12), 0 0 0 1px rgba(0,0,0,0.06);
  display: flex;
  flex-direction: column;
  z-index: 50;
  overflow: hidden;
}

.simulator-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
}

.simulator-title {
  font-size: 14px;
  font-weight: 600;
  color: #1e293b;
}

.simulator-header-actions {
  display: flex;
  gap: 4px;
}

.simulator-btn-reset,
.simulator-btn-close {
  padding: 6px;
  border-radius: 8px;
  color: #64748b;
  cursor: pointer;
  background: none;
  border: none;
  transition: all 0.15s;
}
.simulator-btn-reset:hover { background: #e5e7eb; color: #1e293b; }
.simulator-btn-close:hover { background: #fee2e2; color: #ef4444; }

.simulator-messages {
  flex: 1;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  background: #f1f5f9;
}

.simulator-msg {
  display: flex;
}
.simulator-msg--bot { justify-content: flex-start; }
.simulator-msg--user { justify-content: flex-end; }

.simulator-msg-bubble {
  max-width: 85%;
  padding: 10px 14px;
  border-radius: 12px;
  font-size: 13px;
  line-height: 1.5;
}
.simulator-msg-bubble--bot {
  background: #fff;
  color: #1e293b;
  border: 1px solid #e2e8f0;
  border-bottom-left-radius: 4px;
}
.simulator-msg-bubble--user {
  background: #3b82f6;
  color: #fff;
  border-bottom-right-radius: 4px;
}

.simulator-msg-text {
  margin: 0;
  white-space: pre-wrap;
}

.simulator-buttons {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 8px;
}

.simulator-btn-option {
  padding: 8px 12px;
  border: 1px solid #3b82f6;
  border-radius: 8px;
  background: #eff6ff;
  color: #3b82f6;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  text-align: left;
  transition: all 0.15s;
}
.simulator-btn-option:hover:not(:disabled) {
  background: #3b82f6;
  color: #fff;
}
.simulator-btn-option:disabled {
  opacity: 0.5;
  cursor: default;
}
.simulator-btn-option--green {
  border-color: #22c55e;
  background: #f0fdf4;
  color: #22c55e;
}
.simulator-btn-option--green:hover:not(:disabled) {
  background: #22c55e;
  color: #fff;
}
.simulator-btn-option--orange {
  border-color: #f97316;
  background: #fff7ed;
  color: #f97316;
}
.simulator-btn-option--orange:hover:not(:disabled) {
  background: #f97316;
  color: #fff;
}

.simulator-fields {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 8px;
}

.simulator-field-input {
  width: 100%;
  padding: 8px 10px;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  font-size: 13px;
  outline: none;
  transition: border-color 0.15s;
}
.simulator-field-input:focus { border-color: #3b82f6; }
.simulator-field-input:disabled { background: #f3f4f6; }

.simulator-btn-submit {
  padding: 8px 16px;
  border: none;
  border-radius: 8px;
  background: #3b82f6;
  color: #fff;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background 0.15s;
}
.simulator-btn-submit:hover { background: #2563eb; }

.simulator-wait-input {
  display: flex;
  gap: 6px;
  margin-top: 8px;
}

.simulator-btn-send {
  padding: 8px;
  border: none;
  border-radius: 8px;
  background: #3b82f6;
  color: #fff;
  cursor: pointer;
  display: flex;
  align-items: center;
  flex-shrink: 0;
}
.simulator-btn-send:hover { background: #2563eb; }

.simulator-transfer-badge {
  margin-top: 8px;
  padding: 6px 10px;
  background: #fef3c7;
  border: 1px solid #fbbf24;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #92400e;
}

.simulator-end-badge {
  margin-top: 8px;
  padding: 6px 10px;
  background: #f1f5f9;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 500;
  color: #64748b;
  text-align: center;
}

.simulator-typing {
  display: flex;
  gap: 4px;
  padding: 4px 0;
}
.simulator-typing span {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #94a3b8;
  animation: typing-dot 1.4s infinite;
}
.simulator-typing span:nth-child(2) { animation-delay: 0.2s; }
.simulator-typing span:nth-child(3) { animation-delay: 0.4s; }

@keyframes typing-dot {
  0%, 60%, 100% { opacity: 0.3; transform: scale(0.8); }
  30% { opacity: 1; transform: scale(1); }
}

/* Slide transition */
.simulator-slide-enter-active,
.simulator-slide-leave-active {
  transition: transform 0.3s ease, opacity 0.3s ease;
}
.simulator-slide-enter-from,
.simulator-slide-leave-to {
  transform: translateX(400px);
  opacity: 0;
}
</style>
