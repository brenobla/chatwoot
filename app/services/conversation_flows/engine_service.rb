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

      # Check if there's a greeting message we can convert to buttons
      # instead of sending a duplicate message
      start_step = flow.steps['start']
      greeting_msg = conversation.messages.outgoing.where(content_type: 'text').order(:created_at).first

      if greeting_msg && start_step && start_step['options'].present?
        # Convert the existing greeting message to input_select with buttons
        items = (start_step['options'] || []).map do |opt|
          { title: opt['title'], value: opt['value'] || opt['title'] }
        end
        greeting_msg.update!(
          content: start_step['message'],
          content_type: 'input_select',
          content_attributes: { items: items }
        )
      else
        execute_step('start')
      end
    end

    def process_message(message)
      return unless flow_state&.active?

      current_step_data = fetch_step(flow_state.current_step)
      return complete_flow unless current_step_data

      step_type = current_step_data['type'] || 'message'

      case step_type
      when 'message'
        process_message_response(message, current_step_data)
      when 'collect_data'
        process_collect_data_response(message, current_step_data)
      when 'wait_response'
        process_wait_response(message, current_step_data)
      else
        # For other types, try matching as message
        process_message_response(message, current_step_data)
      end
    end

    def process_message_response(message, step_data)
      selected_option = match_user_response(message, step_data)

      if selected_option.present?
        update_context(flow_state.current_step, selected_option)
        execute_actions(selected_option['actions']) if selected_option['actions'].present?

        next_step = selected_option['next_step']
        if next_step.present?
          flow_state.update!(current_step: next_step)
          execute_step(next_step)
        else
          complete_flow
        end
      else
        fallback = step_data['fallback_message'] || 'Desculpe, nao entendi. Por favor, selecione uma das opcoes.'
        send_bot_message(fallback)
        execute_step(flow_state.current_step)
      end
    end

    def process_collect_data_response(message, step_data)
      # Store form submitted values or text response
      submitted = message.content_attributes&.dig('submitted_values')
      if submitted.present?
        submitted.each do |field|
          update_context(field['name'], field['value']) if field['name']
        end
      else
        # Store raw text as the first field's value
        first_field = (step_data['fields'] || []).first
        update_context(first_field['name'], message.content) if first_field
      end

      next_step = step_data['next_step']
      if next_step.present?
        flow_state.update!(current_step: next_step)
        execute_step(next_step)
      else
        complete_flow
      end
    end

    def process_wait_response(message, step_data)
      variable = step_data['variable'] || 'user_response'
      validation = step_data['validation'] || 'none'

      # Validate response
      if validation == 'email' && !message.content.to_s.match?(/\A[^@\s]+@[^@\s]+\z/)
        send_bot_message('Por favor, informe um e-mail válido.')
        return
      end

      if validation == 'phone' && !message.content.to_s.match?(/[\d\s\-\+\(\)]{8,}/)
        send_bot_message('Por favor, informe um número de telefone válido.')
        return
      end

      # Store response in context
      update_context(variable, message.content)

      next_step = step_data['next_step']
      if next_step.present?
        flow_state.update!(current_step: next_step)
        execute_step(next_step)
      else
        complete_flow
      end
    end

    private

    def execute_step(step_key)
      step_data = fetch_step(step_key)

      unless step_data
        complete_flow
        return
      end

      step_type = step_data['type'] || 'message'

      case step_type
      when 'message'
        execute_message_step(step_key, step_data)
      when 'collect_data'
        execute_collect_data_step(step_key, step_data)
      when 'check_hours'
        execute_check_hours_step(step_key, step_data)
      when 'transfer'
        execute_transfer_step(step_data)
      when 'wait_response'
        execute_wait_response_step(step_key, step_data)
      when 'action'
        # Legacy action type
        execute_actions(step_data['actions']) if step_data['actions'].present?
        send_bot_message(step_data['message']) if step_data['message'].present?
        complete_flow
      else
        # Fallback: treat as message
        execute_message_step(step_key, step_data)
      end
    end

    def execute_message_step(_step_key, step_data)
      if step_data['options'].present?
        send_step_message(step_data)
      else
        send_bot_message(step_data['message']) if step_data['message'].present?
        if step_data['next_step'].present?
          flow_state.update!(current_step: step_data['next_step'])
          execute_step(step_data['next_step'])
        else
          complete_flow
        end
      end
    end

    def execute_collect_data_step(_step_key, step_data)
      # Send form message to collect data
      fields = step_data['fields'] || []
      items = fields.map do |field|
        {
          type: field['type'] || 'text',
          name: field['name'],
          label: field['label'],
          placeholder: field['placeholder'] || field['label'],
          required: field['required'] || false
        }
      end

      send_bot_message(
        step_data['message'] || 'Por favor, preencha os dados abaixo:',
        'form',
        { items: items, button_label: 'Enviar' }
      )
      # Flow stays on this step waiting for form submission
    end

    def execute_check_hours_step(_step_key, step_data)
      # Check if current time is within business hours
      account = conversation.account
      inbox = conversation.inbox

      is_open = if inbox&.working_hours_enabled?
                  inbox.working_hours.today&.open_all_day? ||
                    (inbox.working_hours.today && !inbox.working_hours.today.closed_all_day? &&
                     Time.current.between?(
                       Time.current.change(hour: inbox.working_hours.today.open_hour, min: inbox.working_hours.today.open_minutes),
                       Time.current.change(hour: inbox.working_hours.today.close_hour, min: inbox.working_hours.today.close_minutes)
                     ))
                else
                  true # If no business hours configured, consider always open
                end

      next_step = is_open ? step_data['open_next'] : step_data['closed_next']

      if next_step.present?
        flow_state.update!(current_step: next_step)
        execute_step(next_step)
      else
        complete_flow
      end
    end

    def execute_transfer_step(step_data)
      send_bot_message(step_data['message']) if step_data['message'].present?

      assign_team(step_data['team_id']) if step_data['team_id'].present?
      assign_agent(step_data['agent_id']) if step_data['agent_id'].present?

      flow_state.update!(status: :handoff)
    end

    def execute_wait_response_step(_step_key, step_data)
      # Send prompt and wait for user response
      send_bot_message(step_data['message']) if step_data['message'].present?
      # Flow stays on this step, process_message will handle the next response
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
      user_text = normalize_text(message.content.to_s)
      return nil if user_text.blank?

      # Try exact match on value or title (normalized - no emojis, trimmed)
      options.find do |opt|
        opt_value = normalize_text(opt['value'] || opt['title'])
        opt_title = normalize_text(opt['title'])
        user_text == opt_value || user_text == opt_title
      end || match_by_contains(user_text, options) || match_by_index(user_text, options)
    end

    def normalize_text(text)
      # Remove emojis, extra spaces, downcase
      text.to_s.gsub(/[\u{1F000}-\u{1FFFF}]|[\u{2600}-\u{27BF}]|[\u{FE00}-\u{FEFF}]|[\u{1F900}-\u{1F9FF}]|[✅🆕🔑💰📚❓💡💳🎁🔧📋💰🚀🎉👋🏷️⚡]/, '')
              .strip.squeeze(' ').downcase
    end

    def match_by_contains(user_text, options)
      # Partial match - user text is contained in option title/value or vice versa
      options.find do |opt|
        opt_value = normalize_text(opt['value'] || opt['title'])
        opt_title = normalize_text(opt['title'])
        opt_title.include?(user_text) || user_text.include?(opt_title) ||
          opt_value.include?(user_text) || user_text.include?(opt_value)
      end
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
