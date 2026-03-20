class Api::V1::Accounts::AiAgents::InboxesController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent

  def index
    render json: @ai_agent.ai_agent_inboxes.includes(:inbox).map { |aai|
      {
        id: aai.id,
        inbox_id: aai.inbox.id,
        inbox_name: aai.inbox.name,
        channel_type: aai.inbox.channel_type
      }
    }
  end

  def create
    inbox = Current.account.inboxes.find(params[:inbox_id])
    ai_agent_inbox = @ai_agent.ai_agent_inboxes.new(inbox: inbox)

    if ai_agent_inbox.save
      render json: {
        id: ai_agent_inbox.id,
        inbox_id: inbox.id,
        inbox_name: inbox.name,
        channel_type: inbox.channel_type
      }, status: :created
    else
      render json: { errors: ai_agent_inbox.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    ai_agent_inbox = @ai_agent.ai_agent_inboxes.find_by!(inbox_id: params[:inbox_id])
    ai_agent_inbox.destroy!
    head :no_content
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end
end
