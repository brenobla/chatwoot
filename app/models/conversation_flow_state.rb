class ConversationFlowState < ApplicationRecord
  belongs_to :conversation
  belongs_to :conversation_flow

  enum :status, { active: 0, completed: 1, handoff: 2 }

  validates :conversation_id, uniqueness: true
end
