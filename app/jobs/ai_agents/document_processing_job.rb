module AiAgents
  class DocumentProcessingJob < ApplicationJob
    queue_as :low
    retry_on StandardError, wait: 30.seconds, attempts: 3

    def perform(document_id)
      document = AiAgentDocument.find_by(id: document_id)
      return unless document
      return unless document.content.present?

      ai_agent = document.ai_agent

      # Generate FAQ pairs from the document
      faq_service = AiAgents::FaqGeneratorService.new(ai_agent_document: document)
      pairs = faq_service.generate

      if pairs.present?
        rag_service = AiAgents::RagService.new(ai_agent: ai_agent)

        pairs.each do |pair|
          text = "Q: #{pair[:question]}\nA: #{pair[:answer]}"
          embedding = rag_service.generate_embedding(text)
          next if embedding.blank?

          AiAgentEmbedding.create!(
            ai_agent_id: ai_agent.id,
            account_id: ai_agent.account_id,
            content: text,
            summary: pair[:question],
            embedding: embedding,
            status: 'active',
            document_id: document.id
          )
        end

        Rails.logger.info("[AiAgent::DocumentProcessing] Generated #{pairs.size} FAQ embeddings for document #{document.id}")
      end

      document.update!(status: 'ready')
    rescue StandardError => e
      Rails.logger.error("[AiAgent::DocumentProcessing] Error for document #{document_id}: #{e.message}")
      document&.update!(status: 'error') if document&.persisted?
      raise
    end
  end
end
