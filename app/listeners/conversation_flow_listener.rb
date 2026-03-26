class ConversationFlowListener < BaseListener
  def conversation_created(event)
    conversation = event.data[:conversation]
    return unless conversation
    # Skip if already triggered manually (e.g. test_flow action)
    return if conversation.additional_attributes&.dig('skip_flow_trigger')

    # Check if any flow should be triggered for this new conversation
    ConversationFlows::TriggerService.new(conversation).perform
  rescue StandardError => e
    Rails.logger.error "ConversationFlowListener#conversation_created error: #{e.message}"
  end

  def message_created(event)
    message = event.data[:message]
    return unless message
    return unless message.incoming?

    conversation = message.conversation
    flow_state = conversation.conversation_flow_state

    if flow_state&.active?
      # Process message through the active flow engine
      ConversationFlows::EngineService.new(conversation).process_message(message)
    elsif flow_state.nil?
      # No active flow - check if a keyword trigger matches
      ConversationFlows::TriggerService.new(conversation, message: message).perform
    end
  rescue StandardError => e
    Rails.logger.error "ConversationFlowListener#message_created error: #{e.message}"
  end
end
