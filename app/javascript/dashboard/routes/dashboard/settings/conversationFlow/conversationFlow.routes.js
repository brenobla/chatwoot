import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import ConversationFlowPage from './ConversationFlowPage.vue';
import ConversationFlowEditor from './ConversationFlowEditor.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/conversation-flows'),
      component: SettingsWrapper,
      props: { keepAlive: false },
      children: [
        {
          path: '',
          name: 'conversation_flow_index',
          component: ConversationFlowPage,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'new',
          name: 'conversation_flow_new',
          component: ConversationFlowEditor,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: ':flowId/edit',
          name: 'conversation_flow_edit',
          component: ConversationFlowEditor,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
