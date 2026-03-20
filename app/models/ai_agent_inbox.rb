# == Schema Information
#
# Table name: ai_agent_inboxes
#
#  id          :bigint           not null, primary key
#  ai_agent_id :bigint           not null
#  inbox_id    :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class AiAgentInbox < ApplicationRecord
  belongs_to :ai_agent
  belongs_to :inbox

  validates :inbox_id, uniqueness: { scope: :ai_agent_id, message: 'já está vinculada a este agente' }

  before_validation :ensure_account_id

  private

  def ensure_account_id
    self.ai_agent&.account_id
  end
end
