module AiAgents
  class PlaygroundService
    def initialize(ai_agent:, message_content:, message_history: [])
      @ai_agent = ai_agent
      @message_content = message_content
      @message_history = message_history || []
    end

    def generate
      system_message = build_system_prompt

      messages = [{ role: 'system', content: system_message }]
      messages += @message_history.map { |m| { role: m['role'], content: m['content'] } }
      messages << { role: 'user', content: @message_content }

      api_key = openai_api_key
      raise 'OpenAI API key não configurada' if api_key.blank?

      client = OpenAI::Client.new(access_token: api_key)

      start_time = Time.current
      response = client.chat(parameters: {
        model: @ai_agent.openai_model || 'gpt-4o',
        messages: messages,
        temperature: (@ai_agent.temperature || 0.7).to_f,
        max_tokens: (@ai_agent.max_tokens || 500).to_i
      })

      content = response.dig('choices', 0, 'message', 'content')&.strip || ''
      tokens = response.dig('usage', 'total_tokens') || 0
      elapsed = ((Time.current - start_time) * 1000).to_i

      {
        response: content,
        tokens_used: tokens,
        elapsed_ms: elapsed
      }
    rescue StandardError => e
      { response: nil, error: e.message }
    end

    private

    def build_system_prompt
      prompt = @ai_agent.system_prompt || 'Você é um assistente de suporte ao cliente.'

      if @ai_agent.knowledge_base.present?
        prompt += "\n\n## Base de Conhecimento\n#{@ai_agent.knowledge_base}"
      end

      # Add document context
      documents = @ai_agent.ai_agent_documents.where(status: 'ready')
      if documents.any?
        prompt += "\n\n## Documentos de Referência\n"
        documents.each { |doc| prompt += "### #{doc.file_name}\n#{doc.content}\n\n" }
      end

      # Add guardrails
      guardrails = @ai_agent.parsed_guardrails
      if guardrails.present?
        prompt += "\n\n## Guardrails (Regras obrigatórias)\n"
        guardrails.each { |g| prompt += "- #{g}\n" }
      end

      # Add response guidelines
      guidelines = @ai_agent.parsed_response_guidelines
      if guidelines.present?
        prompt += "\n\n## Diretrizes de Resposta\n"
        guidelines.each { |g| prompt += "- #{g}\n" }
      end

      prompt
    end

    def openai_api_key
      # 1. Account's OpenAI integration (Settings > Integrations > OpenAI)
      account = @ai_agent.account
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
