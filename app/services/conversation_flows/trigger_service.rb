module ConversationFlows
  class TriggerService
    attr_reader :conversation, :message

    def initialize(conversation, message: nil)
      @conversation = conversation
      @message = message
    end

    def perform
      # Don't start a new flow if conversation already has an active flow state
      return if conversation.conversation_flow_state.present?

      flow = find_matching_flow
      return unless flow

      ConversationFlows::EngineService.new(conversation).start_flow(flow)
    end

    private

    def find_matching_flow
      flows = ConversationFlow.active.for_inbox(conversation.inbox_id)

      # Priority: keyword match first, then conversation_created
      keyword_flow = find_keyword_flow(flows)
      return keyword_flow if keyword_flow

      find_conversation_created_flow(flows)
    end

    def find_keyword_flow(flows)
      return nil unless message&.content.present?

      keyword_flows = flows.keyword
      keyword_flows.find do |flow|
        keywords = flow.trigger_config['keywords'] || []
        keywords.any? do |keyword|
          message.content.downcase.include?(keyword.downcase)
        end
      end
    end

    def find_conversation_created_flow(flows)
      flows.conversation_created.first
    end
  end
end
