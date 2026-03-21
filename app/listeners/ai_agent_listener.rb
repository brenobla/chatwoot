class AiAgentListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless message&.incoming?
    return if message.private?

    conversation = message.conversation
    inbox = conversation.inbox
    ai_agent = inbox.ai_agent

    return unless ai_agent&.active?
    return if conversation.resolved?

    # Don't respond if the message was sent by this AI agent (prevent loops)
    return if message.sender_type == 'AiAgent' && message.sender_id == ai_agent.id

    # Don't respond if conversation was already handed off to a human
    return if conversation.status == 'open' && conversation.assignee_id.present?

    # Check max replies limit
    return if max_replies_reached?(ai_agent, conversation)

    AiAgents::ResponseBuilderJob.perform_later(conversation.id, ai_agent.id)
  end

  # Hook into conversation resolved to generate embeddings for RAG
  def conversation_resolved(event)
    conversation = extract_conversation_and_account(event)[0]
    inbox = conversation.inbox
    ai_agent = inbox.ai_agent

    return unless ai_agent&.active?

    # Only generate embeddings for conversations that had messages
    return if conversation.messages.where(message_type: [:incoming, :outgoing], private: false).count < 2

    AiAgents::EmbeddingJob.perform_later(conversation.id, ai_agent.id)
  end

  private

  def max_replies_reached?(ai_agent, conversation)
    max_replies = ai_agent.max_replies.to_i
    return false if max_replies.zero?

    ai_agent_replies = conversation.messages
                                   .where(sender_type: 'AiAgent', sender_id: ai_agent.id)
                                   .where(private: false)
                                   .count

    ai_agent_replies >= max_replies
  end
end
