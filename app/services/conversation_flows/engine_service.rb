module ConversationFlows
  class EngineService
    attr_reader :conversation, :flow_state

    def initialize(conversation)
      @conversation = conversation
      @flow_state = conversation.conversation_flow_state
    end

    def start_flow(flow)
      return if conversation.conversation_flow_state.present?

      @flow_state = ConversationFlowState.create!(
        conversation: conversation,
        conversation_flow: flow,
        current_step: 'start',
        status: :active
      )

      execute_step('start')
    end

    def process_message(message)
      return unless flow_state&.active?

      current_step_data = fetch_step(flow_state.current_step)
      return complete_flow unless current_step_data

      selected_option = match_user_response(message, current_step_data)

      if selected_option.present?
        # Store the user's choice in context
        update_context(flow_state.current_step, selected_option)

        # Execute any actions defined on the selected option
        execute_actions(selected_option['actions']) if selected_option['actions'].present?

        # Advance to next step
        next_step = selected_option['next_step']
        if next_step.present?
          flow_state.update!(current_step: next_step)
          execute_step(next_step)
        else
          complete_flow
        end
      else
        # No match found - re-send the current step or send a fallback message
        fallback = current_step_data['fallback_message'] || 'Desculpe, nao entendi. Por favor, selecione uma das opcoes.'
        send_bot_message(fallback)
        execute_step(flow_state.current_step)
      end
    end

    private

    def execute_step(step_key)
      step_data = fetch_step(step_key)

      unless step_data
        complete_flow
        return
      end

      # Execute pre-actions if defined
      execute_actions(step_data['actions']) if step_data['actions'].present?

      # Check if this is a terminal step (no options, just message + actions)
      if step_data['options'].blank?
        send_bot_message(step_data['message']) if step_data['message'].present?
        complete_flow
        return
      end

      # Build and send the message with buttons
      send_step_message(step_data)
    end

    def send_step_message(step_data)
      message_text = step_data['message'] || ''
      options = step_data['options'] || []

      items = options.each_with_index.map do |option, index|
        {
          title: option['title'],
          value: option['value'] || option['title']
        }
      end

      content_attributes = {
        items: items
      }

      send_bot_message(message_text, 'input_select', content_attributes)
    end

    def match_user_response(message, step_data)
      options = step_data['options'] || []
      return nil if options.blank?

      # First check submitted_values from button clicks
      submitted_values = message.content_attributes&.dig('submitted_values')
      if submitted_values.present?
        # submitted_values is typically an array like [{"title" => "...", "value" => "..."}]
        submitted = submitted_values.is_a?(Array) ? submitted_values.first : submitted_values
        submitted_value = submitted&.dig('value') || submitted&.dig('title')

        if submitted_value.present?
          match = options.find do |opt|
            (opt['value'] || opt['title']).to_s.downcase == submitted_value.to_s.downcase ||
              opt['title'].to_s.downcase == submitted_value.to_s.downcase
          end
          return match if match
        end
      end

      # Fallback: match by text content
      user_text = message.content.to_s.strip.downcase
      return nil if user_text.blank?

      # Try exact match on value or title
      options.find do |opt|
        opt_value = (opt['value'] || opt['title']).to_s.downcase
        opt_title = opt['title'].to_s.downcase
        user_text == opt_value || user_text == opt_title
      end || match_by_index(user_text, options)
    end

    def match_by_index(user_text, options)
      # Allow user to type a number (1, 2, 3...) to select an option
      index = user_text.to_i
      return nil unless index.positive? && index <= options.length

      options[index - 1]
    end

    def execute_actions(actions)
      return if actions.blank?

      actions.each do |action|
        case action['type']
        when 'assign_team'
          assign_team(action['team_id'])
        when 'assign_agent'
          assign_agent(action['agent_id'])
        when 'add_label'
          add_label(action['label'])
        when 'remove_label'
          remove_label(action['label'])
        when 'send_message'
          send_bot_message(action['message'])
        when 'handoff'
          handoff_to_agent(action)
        when 'resolve'
          conversation.resolved!
          flow_state.update!(status: :completed)
        when 'set_context'
          update_context(action['key'], action['value'])
        end
      end
    end

    def assign_team(team_id)
      return unless team_id

      team = conversation.account.teams.find_by(id: team_id)
      conversation.update!(team: team) if team
    end

    def assign_agent(agent_id)
      return unless agent_id

      agent = conversation.account.users.find_by(id: agent_id)
      conversation.update!(assignee: agent) if agent
    end

    def add_label(label)
      return unless label

      conversation.add_labels([label])
    end

    def remove_label(label)
      return unless label

      conversation.remove_labels([label])
    end

    def handoff_to_agent(action)
      flow_state.update!(status: :handoff)

      if action['team_id']
        assign_team(action['team_id'])
      end

      if action['message']
        send_bot_message(action['message'])
      end
    end

    def update_context(key, value)
      context = flow_state.context || {}
      context[key.to_s] = value
      flow_state.update!(context: context)
    end

    def complete_flow
      flow_state&.update!(status: :completed)
    end

    def fetch_step(step_key)
      flow = flow_state.conversation_flow
      steps = flow.steps
      steps[step_key.to_s]
    end

    def send_bot_message(text, content_type = 'text', content_attributes = {})
      conversation.messages.create!(
        message_type: :outgoing,
        content: text,
        content_type: content_type,
        content_attributes: content_attributes,
        account_id: conversation.account_id,
        inbox_id: conversation.inbox_id,
        sender_type: nil,
        sender_id: nil
      )
    end
  end
end
