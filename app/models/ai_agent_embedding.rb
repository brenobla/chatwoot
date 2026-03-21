# == Schema Information
#
# Table name: ai_agent_embeddings
#
#  id              :bigint           not null, primary key
#  account_id      :bigint           not null
#  ai_agent_id     :bigint           not null
#  conversation_id :bigint           not null
#  content         :text             not null
#  summary         :text
#  embedding       :vector(1536)
#  status          :string           default("active"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class AiAgentEmbedding < ApplicationRecord
  belongs_to :account
  belongs_to :ai_agent
  belongs_to :conversation

  has_neighbors :embedding, normalize: true

  validates :content, presence: true

  scope :active, -> { where(status: 'active') }
  scope :by_agent, ->(ai_agent_id) { where(ai_agent_id: ai_agent_id) }
  scope :by_account, ->(account_id) { where(account_id: account_id) }

  # Search for similar conversation embeddings using cosine distance
  # Returns top N nearest neighbors for the given query embedding
  def self.search(query_embedding, ai_agent_id:, limit: 5)
    active
      .by_agent(ai_agent_id)
      .nearest_neighbors(:embedding, query_embedding, distance: 'cosine')
      .limit(limit)
  end
end
