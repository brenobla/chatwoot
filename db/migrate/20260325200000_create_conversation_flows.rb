class CreateConversationFlows < ActiveRecord::Migration[7.0]
  def change
    create_table :conversation_flows do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, null: true, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :trigger_type, default: 0, null: false
      t.jsonb :trigger_config, default: {}
      t.jsonb :steps, default: {}, null: false
      t.jsonb :config, default: {}
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
