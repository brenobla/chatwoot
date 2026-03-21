import { frontendURL } from 'dashboard/helper/URLHelper.js';

const AiAgentPage = () => import('./AiAgentPage.vue');
const AiAgentEditPage = () => import('./AiAgentEditPage.vue');
const AiAgentPlaygroundPage = () => import('./AiAgentPlaygroundPage.vue');
const AiAgentGlobalSettingsPage = () =>
  import('./AiAgentGlobalSettingsPage.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/ai-agent'),
    name: 'ai_agent_index',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: AiAgentPage,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agent/playground'),
    name: 'ai_agent_playground',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: AiAgentPlaygroundPage,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agent/settings'),
    name: 'ai_agent_global_settings',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: AiAgentGlobalSettingsPage,
  },
  {
    path: frontendURL('accounts/:accountId/ai-agent/:agentId/edit'),
    name: 'ai_agent_edit',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: AiAgentEditPage,
  },
];
