module AiAgents
  class MessageCollectorService
    def initialize(conversation:, ai_agent:)
      @conversation = conversation
      @ai_agent = ai_agent
    end

    def collect
      max_messages = (@ai_agent.context_messages || 10).to_i
      messages = @conversation.messages
                              .where(private: false)
                              .where(message_type: [:incoming, :outgoing])
                              .where.not(content: [nil, ''])
                              .order(created_at: :desc)
                              .limit(max_messages)
                              .reverse

      messages.map do |msg|
        {
          role: msg.incoming? ? 'user' : 'assistant',
          content: msg.content.to_s.strip
        }
      end
    end
  end
end
