module AiAgents
  class ResponseService
    attr_reader :ai_agent, :conversation

    def initialize(ai_agent:, conversation:)
      @ai_agent = ai_agent
      @conversation = conversation
    end

    def generate_response
      history = MessageCollectorService.new(conversation: conversation, ai_agent: ai_agent).collect
      last_message = history.last&.dig(:content) || ''

      # Check handoff keywords
      if should_handoff?(last_message)
        return { action: 'handoff', response: ai_agent.handoff_message || 'Transferindo para um atendente humano.' }
      end

      # Build system message
      system_message = build_system_prompt

      # Build messages array for OpenAI
      messages = [{ role: 'system', content: system_message }] + history

      # Call OpenAI
      response = call_openai(messages)

      { action: 'respond', response: response }
    rescue StandardError => e
      Rails.logger.error("[AiAgent] Error generating response: #{e.message}")
      { action: 'error', response: nil, error: e.message }
    end

    def call_openai(messages)
      api_key = openai_api_key
      raise 'OpenAI API key não configurada' if api_key.blank?

      client = OpenAI::Client.new(access_token: api_key)

      params = {
        model: ai_agent.openai_model || 'gpt-4o',
        messages: messages,
        temperature: (ai_agent.temperature || 0.7).to_f,
        max_tokens: (ai_agent.max_tokens || 500).to_i
      }

      # Optional parameters
      top_p = ai_agent.top_p
      params[:top_p] = top_p.to_f if top_p.present? && top_p.to_f != 1.0

      freq_penalty = ai_agent.frequency_penalty
      params[:frequency_penalty] = freq_penalty.to_f if freq_penalty.present? && freq_penalty.to_f != 0

      pres_penalty = ai_agent.presence_penalty
      params[:presence_penalty] = pres_penalty.to_f if pres_penalty.present? && pres_penalty.to_f != 0

      response = client.chat(parameters: params)

      response.dig('choices', 0, 'message', 'content')&.strip || ''
    end

    private

    def should_handoff?(message)
      keywords = ai_agent.parsed_handoff_keywords
      return false if keywords.blank?

      message_lower = message.downcase
      keywords.any? { |kw| message_lower.include?(kw.downcase) }
    end

    def build_system_prompt
      prompt = ai_agent.system_prompt || 'Você é um assistente de suporte ao cliente.'

      # Add knowledge base if present
      if ai_agent.knowledge_base.present?
        prompt += "\n\n## Base de Conhecimento\n#{ai_agent.knowledge_base}"
      end

      # Add document context from uploaded files
      document_context = fetch_document_context
      prompt += "\n\n## Documentos de Referência\n#{document_context}" if document_context.present?

      # Add RAG context from similar past conversations
      rag_context = fetch_rag_context
      prompt += "\n\n#{rag_context}" if rag_context.present?

      # Add language instruction
      if ai_agent.language.present? && ai_agent.language != 'auto'
        lang_map = { 'pt-BR' => 'português do Brasil', 'en' => 'inglês', 'es' => 'espanhol' }
        lang = lang_map[ai_agent.language] || ai_agent.language
        prompt += "\n\nResponda sempre em #{lang}."
      end

      # Add guardrails
      guardrails = ai_agent.parsed_guardrails
      if guardrails.present?
        prompt += "\n\n## Guardrails (Regras obrigatórias)\n"
        guardrails.each { |g| prompt += "- #{g}\n" }
      end

      # Add response guidelines
      guidelines = ai_agent.parsed_response_guidelines
      if guidelines.present?
        prompt += "\n\n## Diretrizes de Resposta\n"
        guidelines.each { |g| prompt += "- #{g}\n" }
      end

      # Add blocked topics
      blocked = ai_agent.parsed_blocked_topics
      if blocked.present?
        prompt += "\n\nNUNCA responda sobre os seguintes assuntos: #{blocked.join(', ')}. Se perguntado, diga educadamente que não pode ajudar com esse tema."
      end

      prompt
    end

    def fetch_document_context
      documents = ai_agent.ai_agent_documents.ready
      return nil if documents.empty?

      documents.map { |doc|
        "### #{doc.file_name}\n#{doc.content}"
      }.join("\n\n")
    rescue StandardError => e
      Rails.logger.error("[AiAgent] Document context error: #{e.message}")
      nil
    end

    def fetch_rag_context
      # Get the last incoming message content to use as RAG query
      last_incoming = conversation.messages
                                  .where(message_type: :incoming, private: false)
                                  .where.not(content: [nil, ''])
                                  .order(created_at: :desc)
                                  .first

      return nil if last_incoming.blank?

      rag_service = AiAgents::RagService.new(ai_agent: ai_agent)
      rag_service.build_rag_context(last_incoming.content, limit: 5)
    rescue StandardError => e
      Rails.logger.error("[AiAgent] RAG context error: #{e.message}")
      nil
    end

    def openai_api_key
      # 1. Account's OpenAI integration (Settings > Integrations > OpenAI)
      account = conversation.account
      hook = account.hooks.find_by(app_id: 'openai', status: 'enabled')
      return hook.settings['api_key'] if hook&.settings&.dig('api_key').present?

      # 2. System-wide installation config
      config_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value
      return config_key if config_key.present?

      # 3. Environment variable
      ENV.fetch('OPENAI_API_KEY', nil)
    end
  end
end
