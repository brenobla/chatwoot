class CreateAiAgents < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_agents do |t|
      t.string :name, null: false
      t.string :description
      t.jsonb :config, null: false, default: {}
      t.boolean :active, null: false, default: true
      t.references :account, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
