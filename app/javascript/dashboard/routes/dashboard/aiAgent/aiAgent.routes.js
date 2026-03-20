import { frontendURL } from 'dashboard/helper/URLHelper.js';

const AiAgentPage = () => import('./AiAgentPage.vue');
const AiAgentSettingsPage = () => import('./AiAgentSettingsPage.vue');

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
    path: frontendURL('accounts/:accountId/ai-agent/:agentId/settings'),
    name: 'ai_agent_settings',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: AiAgentSettingsPage,
  },
];
