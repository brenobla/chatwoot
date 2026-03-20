import AiAgentAPI from 'dashboard/api/aiAgent';
import { createStore } from './storeFactory';

export default createStore({
  name: 'AiAgent',
  API: AiAgentAPI,
});
