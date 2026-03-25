import ConversationFlowAPI from 'dashboard/api/conversationFlow';
import { createStore } from './storeFactory';

export default createStore({
  name: 'ConversationFlow',
  API: ConversationFlowAPI,
});
