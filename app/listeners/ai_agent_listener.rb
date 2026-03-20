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

    AiAgents::ResponseBuilderJob.perform_later(conversation.id, ai_agent.id)
  end
end
