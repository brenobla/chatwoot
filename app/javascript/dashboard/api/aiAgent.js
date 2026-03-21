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

  getDocuments(agentId) {
    return axios.get(`${this.url}/${agentId}/documents`);
  }

  uploadDocument(agentId, formData) {
    return axios.post(`${this.url}/${agentId}/documents`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  deleteDocument(agentId, documentId) {
    return axios.delete(`${this.url}/${agentId}/documents/${documentId}`);
  }
}

export default new AiAgentAPI();
