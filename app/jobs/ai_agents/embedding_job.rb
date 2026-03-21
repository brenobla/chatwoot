module AiAgents
  class EmbeddingJob < ApplicationJob
    queue_as :low
    retry_on StandardError, wait: 10.seconds, attempts: 3

    def perform(conversation_id, ai_agent_id)
      conversation = Conversation.find_by(id: conversation_id)
      ai_agent = AiAgent.find_by(id: ai_agent_id)

      return unless conversation && ai_agent

      rag_service = AiAgents::RagService.new(ai_agent: ai_agent)
      rag_service.store_conversation_embedding(conversation)

      Rails.logger.info("[AiAgent::EmbeddingJob] Stored embedding for conversation #{conversation_id}, agent #{ai_agent_id}")
    end
  end
end
