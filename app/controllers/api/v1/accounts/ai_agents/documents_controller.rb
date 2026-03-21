class Api::V1::Accounts::AiAgents::DocumentsController < Api::V1::Accounts::BaseController
  before_action :fetch_ai_agent
  before_action :fetch_document, only: [:destroy]

  def index
    documents = @ai_agent.ai_agent_documents.order(created_at: :desc)
    render json: documents.map { |doc| document_json(doc) }
  end

  def create
    unless params[:file].present?
      render json: { error: 'File is required' }, status: :unprocessable_entity
      return
    end

    uploaded_file = params[:file]
    extension = File.extname(uploaded_file.original_filename).delete('.').downcase

    unless AiAgentDocument::ALLOWED_EXTENSIONS.include?(extension)
      render json: { error: "File type '#{extension}' is not supported. Allowed: #{AiAgentDocument::ALLOWED_EXTENSIONS.join(', ')}" },
             status: :unprocessable_entity
      return
    end

    document = @ai_agent.ai_agent_documents.new(
      account: Current.account,
      file_name: uploaded_file.original_filename,
      file_type: extension,
      file_size: uploaded_file.size,
      status: 'processing'
    )

    if document.save
      document.file.attach(uploaded_file)
      extract_content(document)
      render json: document_json(document), status: :created
    else
      render json: { errors: document.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @document.file.purge if @document.file.attached?
    @document.destroy!
    head :no_content
  end

  private

  def fetch_ai_agent
    @ai_agent = Current.account.ai_agents.find(params[:ai_agent_id])
  end

  def fetch_document
    @document = @ai_agent.ai_agent_documents.find(params[:id])
  end

  def extract_content(document)
    content = case document.file_type
              when 'txt'
                extract_txt(document)
              when 'csv'
                extract_csv(document)
              when 'pdf'
                extract_pdf(document)
              when 'docx'
                extract_docx(document)
              end

    if content.present?
      document.update!(content: content, status: 'ready')
    else
      document.update!(status: 'error')
    end
  rescue StandardError => e
    Rails.logger.error("[AiAgentDocument] Extraction error for document #{document.id}: #{e.message}")
    document.update!(status: 'error')
  end

  def extract_txt(document)
    document.file.download.force_encoding('UTF-8')
  end

  def extract_csv(document)
    require 'csv'
    raw = document.file.download.force_encoding('UTF-8')
    csv = CSV.parse(raw, headers: true)
    csv.map { |row| row.to_h.values.compact.join(' | ') }.join("\n")
  end

  def extract_pdf(document)
    if defined?(PDF::Reader)
      io = StringIO.new(document.file.download)
      reader = PDF::Reader.new(io)
      reader.pages.map(&:text).join("\n\n")
    else
      Rails.logger.warn('[AiAgentDocument] pdf-reader gem not available, storing without content extraction')
      nil
    end
  end

  def extract_docx(document)
    # Basic DOCX extraction - DOCX files are ZIP archives containing XML
    require 'zip'
    io = StringIO.new(document.file.download)
    text_parts = []
    Zip::InputStream.open(io) do |zip|
      while (entry = zip.get_next_entry)
        next unless entry.name == 'word/document.xml'

        xml_content = zip.read
        # Strip XML tags to get plain text
        text_parts << xml_content.gsub(/<[^>]+>/, ' ').gsub(/\s+/, ' ').strip
      end
    end
    text_parts.join("\n\n").presence
  rescue LoadError
    Rails.logger.warn('[AiAgentDocument] rubyzip gem not available for DOCX extraction')
    nil
  end

  def document_json(doc)
    {
      id: doc.id,
      ai_agent_id: doc.ai_agent_id,
      file_name: doc.file_name,
      file_type: doc.file_type,
      file_size: doc.file_size,
      status: doc.status,
      content_preview: doc.content&.truncate(200),
      created_at: doc.created_at,
      updated_at: doc.updated_at
    }
  end
end
