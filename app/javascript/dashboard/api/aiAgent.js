import ApiClient from './ApiClient';

class AiAgentAPI extends ApiClient {
  constructor() {
    super('ai_agents', { accountScoped: true });
  }

  playground({ agentId, messageContent, messageHistory }) {
    return axios.post(`${this.url}/${agentId}/playground`, {
      message_content: messageContent,
      message_history: messageHistory,
    });
  }

  getInboxes(agentId) {
    return axios.get(`${this.url}/${agentId}/inboxes`);
  }

  connectInbox(agentId, inboxId) {
    return axios.post(`${this.url}/${agentId}/inboxes`, { inbox_id: inboxId });
  }

  disconnectInbox(agentId, inboxId) {
    return axios.delete(`${this.url}/${agentId}/inboxes/${inboxId}`);
  }
}

export default new AiAgentAPI();
