class ConversationFlow < ApplicationRecord
  belongs_to :account
  belongs_to :inbox, optional: true
  has_many :conversation_flow_states, dependent: :destroy

  enum :trigger_type, { conversation_created: 0, keyword: 1, manual: 2 }

  validates :name, presence: true
  validates :steps, presence: true

  store_accessor :config, :bot_name, :bot_avatar_url, :greeting_message, :greeting_delay_seconds,
                 :offline_message, :business_hours, :typing_indicator, :typing_delay_ms, :theme_color,
                 :collect_contact_info

  scope :active, -> { where(active: true) }
  scope :for_inbox, ->(inbox_id) { where(inbox_id: [inbox_id, nil]) }
end
