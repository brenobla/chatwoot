class CreateAiAgentDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agent_documents do |t|
      t.references :ai_agent, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :file_name, null: false
      t.string :file_type, null: false
      t.text :content
      t.integer :file_size
      t.string :status, null: false, default: 'processing'

      t.timestamps
    end

    add_index :ai_agent_documents, [:ai_agent_id, :status]
  end
end
