module AiAgents
  class RagService
    EMBEDDING_MODEL = 'text-embedding-3-small'.freeze
    MAX_CONTENT_LENGTH = 8000 # Max characters per conversation content for embedding
    SIMILARITY_THRESHOLD = 0.4 # Max cosine distance to consider relevant

    attr_reader :ai_agent, :account

    def initialize(ai_agent:)
      @ai_agent = ai_agent
      @account = ai_agent.account
    end

    # Generate an embedding for a given text using OpenAI's text-embedding-3-small
    def generate_embedding(text)
      return [] if text.blank?

      client = openai_client
      response = client.embeddings(
        parameters: {
          model: EMBEDDING_MODEL,
          input: text.truncate(MAX_CONTENT_LENGTH)
        }
      )

      response.dig('data', 0, 'embedding') || []
    rescue StandardError => e
      Rails.logger.error("[AiAgent::RagService] Embedding error: #{e.message}")
      []
    end

    # Store an embedding for a resolved conversation
    def store_conversation_embedding(conversation)
      content = build_conversation_content(conversation)
      return if content.blank?

      summary = build_conversation_summary(conversation)
      embedding = generate_embedding(content)
      return if embedding.blank?

      record = AiAgentEmbedding.find_or_initialize_by(
        ai_agent_id: ai_agent.id,
        conversation_id: conversation.id
      )

      record.assign_attributes(
        account_id: account.id,
        content: content,
        summary: summary,
        embedding: embedding,
        status: 'active'
      )

      record.save!
      record
    rescue StandardError => e
      Rails.logger.error("[AiAgent::RagService] Store embedding error for conversation #{conversation.id}: #{e.message}")
      nil
    end

    # Search for similar past conversations given a query text
    # Returns an array of hashes with conversation context
    def search(query, limit: 5)
      query_embedding = generate_embedding(query)
      return [] if query_embedding.blank?

      results = AiAgentEmbedding.search(query_embedding, ai_agent_id: ai_agent.id, limit: limit)

      results.filter_map do |record|
        next if record.neighbor_distance > SIMILARITY_THRESHOLD

        {
          conversation_id: record.conversation_id,
          content: record.content,
          summary: record.summary,
          distance: record.neighbor_distance
        }
      end
    end

    # Build a RAG context string from search results for injection into system prompt
    def build_rag_context(query, limit: 5)
      results = search(query, limit: limit)
      return nil if results.blank?

      context_parts = results.map.with_index(1) do |result, idx|
        summary = result[:summary].present? ? result[:summary] : result[:content].truncate(500)
        "### Conversa similar #{idx} (relevancia: #{format('%.2f', 1 - result[:distance])})\n#{summary}"
      end

      "## Conversas anteriores relevantes\n" \
      "Use as seguintes conversas passadas como referencia para responder de forma consistente:\n\n" \
      "#{context_parts.join("\n\n")}"
    end

    private

    def openai_client
      api_key = openai_api_key
      raise 'OpenAI API key nao configurada' if api_key.blank?

      OpenAI::Client.new(access_token: api_key)
    end

    def openai_api_key
      InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value ||
        ENV.fetch('OPENAI_API_KEY', nil)
    end

    # Build full conversation text for embedding
    def build_conversation_content(conversation)
      messages = conversation.messages
                             .where(private: false)
                             .where(message_type: [:incoming, :outgoing])
                             .where.not(content: [nil, ''])
                             .order(created_at: :asc)
                             .limit(50)

      return nil if messages.empty?

      lines = messages.map do |msg|
        role = msg.incoming? ? 'Cliente' : 'Agente'
        "#{role}: #{msg.content.to_s.strip}"
      end

      lines.join("\n").truncate(MAX_CONTENT_LENGTH)
    end

    # Build a short summary of the conversation for display in RAG context
    def build_conversation_summary(conversation)
      messages = conversation.messages
                             .where(private: false)
                             .where(message_type: [:incoming, :outgoing])
                             .where.not(content: [nil, ''])
                             .order(created_at: :asc)
                             .limit(20)

      return nil if messages.empty?

      lines = messages.map do |msg|
        role = msg.incoming? ? 'Cliente' : 'Agente'
        "#{role}: #{msg.content.to_s.strip}"
      end

      lines.join("\n").truncate(2000)
    end
  end
end
