class Api::V1::Accounts::AiAgentsController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent, only: [:show, :update, :destroy, :playground]

  def index
    @ai_agents = Current.account.ai_agents.ordered.includes(:inboxes)
    render json: @ai_agents.map { |a| ai_agent_json(a) }
  end

  def show
    render json: ai_agent_json(@ai_agent)
  end

  def create
    @ai_agent = Current.account.ai_agents.new(ai_agent_params)
    if @ai_agent.save
      render json: ai_agent_json(@ai_agent), status: :created
    else
      render json: { errors: @ai_agent.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @ai_agent.update(ai_agent_params)
      render json: ai_agent_json(@ai_agent)
    else
      render json: { errors: @ai_agent.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @ai_agent.destroy!
    head :no_content
  end

  def playground
    result = AiAgents::PlaygroundService.new(
      ai_agent: @ai_agent,
      message_content: params[:message_content],
      message_history: params[:message_history]
    ).generate

    render json: result
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:id])
  end

  def ai_agent_params
    params.permit(
      :name, :description, :active,
      config: [
        :system_prompt, :openai_model, :temperature, :top_p,
        :frequency_penalty, :presence_penalty, :max_tokens, :context_messages,
        :mode, :language, :welcome_message, :handoff_message,
        :handoff_keywords, :blocked_topics, :max_replies,
        :knowledge_base, :response_format, :only_business_hours,
        :add_private_note
      ]
    )
  end

  def ai_agent_json(agent)
    {
      id: agent.id,
      name: agent.name,
      description: agent.description,
      active: agent.active,
      config: agent.config,
      inbox_ids: agent.inbox_ids,
      inboxes: agent.inboxes.map { |i| { id: i.id, name: i.name, channel_type: i.channel_type } },
      created_at: agent.created_at,
      updated_at: agent.updated_at
    }
  end
end
