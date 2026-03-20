# == Schema Information
#
# Table name: ai_agents
#
#  id          :bigint           not null, primary key
#  name        :string           not null
#  description :string
#  config      :jsonb            not null, default: {}
#  active      :boolean          default(TRUE), not null
#  account_id  :bigint           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class AiAgent < ApplicationRecord
  belongs_to :account
  has_many :ai_agent_inboxes, dependent: :destroy_async
  has_many :inboxes, through: :ai_agent_inboxes
  has_many :messages, as: :sender, dependent: :nullify

  validates :name, presence: true
  validates :account_id, presence: true

  scope :ordered, -> { order(created_at: :desc) }
  scope :active, -> { where(active: true) }

  # Config accessors
  store_accessor :config,
                 :system_prompt,
                 :openai_model,
                 :temperature,
                 :top_p,
                 :frequency_penalty,
                 :presence_penalty,
                 :max_tokens,
                 :context_messages,
                 :mode, # 'auto' or 'suggest'
                 :language,
                 :welcome_message,
                 :handoff_message,
                 :handoff_keywords,
                 :blocked_topics,
                 :max_replies,
                 :knowledge_base,
                 :response_format,
                 :only_business_hours,
                 :add_private_note

  # Defaults
  after_initialize do
    self.config ||= {}
    self.config['openai_model'] ||= 'gpt-4o'
    self.config['temperature'] ||= 0.7
    self.config['max_tokens'] ||= 500
    self.config['context_messages'] ||= 10
    self.config['mode'] ||= 'auto'
    self.config['language'] ||= 'pt-BR'
  end

  # Required interface for polymorphic sender (matches AgentBot/Captain::Assistant)
  def available_name
    name
  end

  def push_event_data
    {
      id: id,
      name: name,
      type: 'ai_agent'
    }
  end

  def webhook_data
    {
      id: id,
      name: name,
      type: 'ai_agent'
    }
  end

  def parsed_handoff_keywords
    keywords = config['handoff_keywords']
    return [] if keywords.blank?
    return keywords if keywords.is_a?(Array)

    keywords.to_s.split(',').map(&:strip).reject(&:blank?)
  end

  def parsed_blocked_topics
    topics = config['blocked_topics']
    return [] if topics.blank?
    return topics if topics.is_a?(Array)

    topics.to_s.split(',').map(&:strip).reject(&:blank?)
  end
end
