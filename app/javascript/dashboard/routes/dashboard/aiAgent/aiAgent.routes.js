import { frontendURL } from 'dashboard/helper/URLHelper.js';
import AiAgentPage from './AiAgentPage.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/ai-agent'),
    name: 'ai_agent_index',
    meta: {
      permissions: ['administrator', 'agent', 'custom_role'],
    },
    component: AiAgentPage,
  },
];
