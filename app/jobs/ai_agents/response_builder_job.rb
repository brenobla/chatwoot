module AiAgents
  class ResponseBuilderJob < ApplicationJob
    queue_as :default
    retry_on StandardError, wait: 5.seconds, attempts: 2

    def perform(conversation_id, ai_agent_id)
      @conversation = Conversation.find_by(id: conversation_id)
      @ai_agent = AiAgent.find_by(id: ai_agent_id)

      return unless @conversation && @ai_agent&.active?
      return if @conversation.resolved?

      # Set current executor for tracking
      Current.executed_by = @ai_agent

      result = AiAgents::ResponseService.new(
        ai_agent: @ai_agent,
        conversation: @conversation
      ).generate_response

      case result[:action]
      when 'handoff'
        handle_handoff(result[:response])
      when 'respond'
        handle_response(result[:response])
      when 'error'
        Rails.logger.error("[AiAgent] Failed for conversation #{@conversation.id}: #{result[:error]}")
        # On error, silently fail - let human handle it
      end
    ensure
      Current.executed_by = nil
    end

    private

    def handle_response(content)
      return if content.blank?

      mode = @ai_agent.mode || 'auto'

      if mode == 'auto'
        # Send directly as outgoing message
        @conversation.messages.create!(
          message_type: :outgoing,
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          sender: @ai_agent,
          content: content
        )
      else
        # Suggest mode: create as private note for human review
        @conversation.messages.create!(
          message_type: :outgoing,
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          sender: @ai_agent,
          content: "💡 **Sugestão do Agente de IA:**\n\n#{content}",
          private: true
        )
      end

      # Add private note with analysis if configured
      if @ai_agent.add_private_note.to_s == 'true' && mode == 'auto'
        @conversation.messages.create!(
          message_type: :outgoing,
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          sender: @ai_agent,
          content: "🤖 Resposta gerada automaticamente pelo Agente de IA \"#{@ai_agent.name}\"",
          private: true,
          content_type: :text
        )
      end
    end

    def handle_handoff(message)
      # Send handoff message to customer
      if message.present?
        @conversation.messages.create!(
          message_type: :outgoing,
          account_id: @conversation.account_id,
          inbox_id: @conversation.inbox_id,
          sender: @ai_agent,
          content: message
        )
      end

      # Change conversation status to open (triggers human assignment)
      @conversation.update!(status: :open) if @conversation.pending?

      # Add private note for the team
      @conversation.messages.create!(
        message_type: :outgoing,
        account_id: @conversation.account_id,
        inbox_id: @conversation.inbox_id,
        sender: @ai_agent,
        content: '🔄 Conversa transferida para atendimento humano pelo Agente de IA.',
        private: true
      )
    end
  end
end
