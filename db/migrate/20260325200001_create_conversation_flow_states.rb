class CreateConversationFlowStates < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_flow_states do |t|
      t.references :conversation, null: false, foreign_key: true, index: false
      t.references :conversation_flow, null: false, foreign_key: true
      t.string :current_step, default: 'start'
      t.jsonb :context, default: {}
      t.integer :status, default: 0, null: false
      t.timestamps
    end
    add_index :conversation_flow_states, :conversation_id, unique: true
  end
end
