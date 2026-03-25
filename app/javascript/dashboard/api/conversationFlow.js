import ApiClient from './ApiClient';

class ConversationFlowAPI extends ApiClient {
  constructor() {
    super('conversation_flows', { accountScoped: true });
  }
}

export default new ConversationFlowAPI();
