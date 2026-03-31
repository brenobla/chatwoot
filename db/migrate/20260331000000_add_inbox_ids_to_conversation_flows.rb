class AddInboxIdsToConversationFlows < ActiveRecord::Migration[7.0]
  def up
    add_column :conversation_flows, :inbox_ids, :jsonb, default: []

    # Migrate existing inbox_id to inbox_ids array
    ConversationFlow.reset_column_information
    ConversationFlow.where.not(inbox_id: nil).find_each do |flow|
      flow.update_column(:inbox_ids, [flow.inbox_id])
    end
  end

  def down
    remove_column :conversation_flows, :inbox_ids
  end
end
