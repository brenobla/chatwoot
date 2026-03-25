class Api::V1::Accounts::ConversationFlowsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :fetch_conversation_flow, only: [:show, :update, :destroy]

  def index
    @conversation_flows = Current.account.conversation_flows
    render json: {
      payload: @conversation_flows,
      meta: { total_count: @conversation_flows.count }
    }
  end

  def show
    render json: @conversation_flow
  end

  def create
    @conversation_flow = Current.account.conversation_flows.new(conversation_flow_params)

    if @conversation_flow.save
      render json: @conversation_flow, status: :ok
    else
      render json: { errors: @conversation_flow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @conversation_flow.update(conversation_flow_params)
      render json: @conversation_flow, status: :ok
    else
      render json: { errors: @conversation_flow.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @conversation_flow.destroy!
    head :ok
  end

  def upload_avatar
    file = params[:avatar]
    return render json: { error: 'No file provided' }, status: :unprocessable_entity unless file

    # Store in public/uploads/flow-avatars/
    upload_dir = Rails.root.join('public', 'uploads', 'flow-avatars')
    FileUtils.mkdir_p(upload_dir)

    filename = "#{SecureRandom.hex(8)}#{File.extname(file.original_filename)}"
    filepath = upload_dir.join(filename)
    File.open(filepath, 'wb') { |f| f.write(file.read) }

    avatar_url = "#{ENV.fetch('FRONTEND_URL', '')}/uploads/flow-avatars/#{filename}"
    render json: { avatar_url: avatar_url }, status: :ok
  end

  private

  def fetch_conversation_flow
    @conversation_flow = Current.account.conversation_flows.find(params[:id])
  end

  def conversation_flow_params
    params.permit(:name, :description, :inbox_id, :trigger_type, :active,
                  trigger_config: {}, steps: {}, config: {})
  end
end
