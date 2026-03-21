class CreateAiAgentEmbeddings < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_embeddings do |t|
      t.bigint :account_id, null: false
      t.bigint :ai_agent_id, null: false
      t.bigint :conversation_id, null: false
      t.text :content, null: false
      t.text :summary
      t.vector :embedding, limit: 1536
      t.string :status, default: 'active', null: false

      t.timestamps
    end

    add_index :ai_agent_embeddings, :account_id
    add_index :ai_agent_embeddings, :ai_agent_id
    add_index :ai_agent_embeddings, :conversation_id
    add_index :ai_agent_embeddings, [:ai_agent_id, :conversation_id], unique: true, name: 'idx_ai_agent_embeddings_agent_conversation'
    add_index :ai_agent_embeddings, :embedding, using: :ivfflat, name: 'idx_ai_agent_embeddings_vector', opclass: :vector_l2_ops
  end
end
