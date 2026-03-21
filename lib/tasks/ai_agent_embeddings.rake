namespace :ai_agents do
  desc 'Generate embeddings from existing resolved conversations for all active AI agents'
  task generate_embeddings: :environment do
    batch_size = ENV.fetch('BATCH_SIZE', 50).to_i
    agent_id = ENV['AI_AGENT_ID']
    account_id = ENV['ACCOUNT_ID']
    limit = ENV.fetch('LIMIT', 1000).to_i

    agents = AiAgent.active
    agents = agents.where(id: agent_id) if agent_id.present?
    agents = agents.where(account_id: account_id) if account_id.present?

    if agents.empty?
      puts 'No active AI agents found.'
      exit 0
    end

    total_processed = 0
    total_stored = 0

    agents.find_each do |ai_agent|
      puts "\nProcessing AI Agent: #{ai_agent.name} (ID: #{ai_agent.id}, Account: #{ai_agent.account_id})"

      rag_service = AiAgents::RagService.new(ai_agent: ai_agent)

      # Get all inboxes linked to this AI agent
      inbox_ids = ai_agent.inbox_ids
      if inbox_ids.empty?
        puts "  No inboxes linked. Skipping."
        next
      end

      # Find resolved conversations in those inboxes that don't have embeddings yet
      existing_conversation_ids = AiAgentEmbedding.where(ai_agent_id: ai_agent.id).pluck(:conversation_id)

      conversations = Conversation
                      .where(inbox_id: inbox_ids, status: :resolved)
                      .where.not(id: existing_conversation_ids)
                      .order(created_at: :desc)
                      .limit(limit)

      puts "  Found #{conversations.count} conversations to process."

      conversations.find_each(batch_size: batch_size).with_index do |conversation, idx|
        # Only process conversations with at least 2 messages (some interaction)
        message_count = conversation.messages
                                    .where(message_type: [:incoming, :outgoing], private: false)
                                    .where.not(content: [nil, ''])
                                    .count

        if message_count < 2
          puts "  [#{idx + 1}] Conversation ##{conversation.display_id} - skipped (only #{message_count} messages)"
          next
        end

        result = rag_service.store_conversation_embedding(conversation)

        if result
          total_stored += 1
          puts "  [#{idx + 1}] Conversation ##{conversation.display_id} - embedded (#{message_count} messages)"
        else
          puts "  [#{idx + 1}] Conversation ##{conversation.display_id} - failed"
        end

        total_processed += 1

        # Rate limiting: avoid hitting OpenAI too fast
        sleep(0.2)
      end
    end

    puts "\nDone! Processed: #{total_processed}, Stored: #{total_stored}"
  end

  desc 'Clear all embeddings for an AI agent'
  task clear_embeddings: :environment do
    agent_id = ENV['AI_AGENT_ID']

    unless agent_id.present?
      puts 'Please provide AI_AGENT_ID environment variable'
      puts 'Usage: rake ai_agents:clear_embeddings AI_AGENT_ID=123'
      exit 1
    end

    ai_agent = AiAgent.find_by(id: agent_id)
    unless ai_agent
      puts "AI Agent with ID #{agent_id} not found"
      exit 1
    end

    count = ai_agent.ai_agent_embeddings.count
    ai_agent.ai_agent_embeddings.delete_all

    puts "Cleared #{count} embeddings for AI Agent '#{ai_agent.name}' (ID: #{ai_agent.id})"
  end

  desc 'Show embedding stats for all AI agents'
  task embedding_stats: :environment do
    AiAgent.includes(:account).find_each do |ai_agent|
      count = ai_agent.ai_agent_embeddings.count
      next if count.zero?

      puts "AI Agent: #{ai_agent.name} (ID: #{ai_agent.id}, Account: #{ai_agent.account.name})"
      puts "  Embeddings: #{count}"
      puts "  Oldest: #{ai_agent.ai_agent_embeddings.minimum(:created_at)}"
      puts "  Newest: #{ai_agent.ai_agent_embeddings.maximum(:created_at)}"
      puts ""
    end
  end
end
