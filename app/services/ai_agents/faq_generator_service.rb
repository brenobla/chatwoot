module AiAgents
  class FaqGeneratorService
    def initialize(ai_agent_document:)
      @document = ai_agent_document
      @ai_agent = ai_agent_document.ai_agent
    end

    def generate
      return [] if @document.content.blank?

      prompt = build_prompt
      messages = [
        { role: 'system', content: 'You are a helpful assistant that generates FAQ question-answer pairs from documents. Always respond in valid JSON format.' },
        { role: 'user', content: prompt }
      ]

      client = openai_client
      response = client.chat(parameters: {
        model: 'gpt-4o-mini',
        messages: messages,
        temperature: 0.3,
        max_tokens: 4000,
        response_format: { type: 'json_object' }
      })

      raw = response.dig('choices', 0, 'message', 'content')&.strip || '{}'
      parsed = JSON.parse(raw)
      pairs = parsed['faq'] || parsed['pairs'] || parsed['questions'] || []

      pairs.map do |pair|
        {
          question: pair['question'] || pair['q'],
          answer: pair['answer'] || pair['a']
        }
      end.select { |p| p[:question].present? && p[:answer].present? }
    rescue JSON::ParserError => e
      Rails.logger.error("[AiAgent::FaqGenerator] JSON parse error: #{e.message}")
      []
    rescue StandardError => e
      Rails.logger.error("[AiAgent::FaqGenerator] Error: #{e.message}")
      []
    end

    private

    def build_prompt
      content = @document.content.truncate(12_000)
      <<~PROMPT
        Analise o seguinte documento e gere pares de pergunta e resposta (FAQ) baseados no conteúdo.
        Gere o máximo de perguntas relevantes possível.

        Responda em JSON com o formato:
        {"faq": [{"question": "...", "answer": "..."}]}

        Documento (#{@document.file_name}):
        ---
        #{content}
        ---
      PROMPT
    end

    def openai_client
      api_key = InstallationConfig.find_by(name: 'CAPTAIN_OPEN_AI_API_KEY')&.value ||
                ENV.fetch('OPENAI_API_KEY', nil)
      raise 'OpenAI API key não configurada' if api_key.blank?

      OpenAI::Client.new(access_token: api_key)
    end
  end
end
