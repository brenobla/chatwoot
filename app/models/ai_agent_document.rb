# == Schema Information
#
# Table name: ai_agent_documents
#
#  id          :bigint           not null, primary key
#  ai_agent_id :bigint           not null
#  account_id  :bigint           not null
#  file_name   :string           not null
#  file_type   :string           not null
#  content     :text
#  file_size   :integer
#  status      :string           default("processing"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class AiAgentDocument < ApplicationRecord
  belongs_to :ai_agent
  belongs_to :account

  has_one_attached :file

  ALLOWED_CONTENT_TYPES = %w[
    application/pdf
    text/plain
    text/csv
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
  ].freeze

  ALLOWED_EXTENSIONS = %w[pdf txt csv docx].freeze

  MAX_FILE_SIZE = 10.megabytes

  validates :file_name, presence: true
  validates :file_type, presence: true, inclusion: { in: ALLOWED_EXTENSIONS }
  validates :status, presence: true, inclusion: { in: %w[processing ready error] }
  validate :validate_file_size

  scope :ready, -> { where(status: 'ready') }
  scope :by_agent, ->(ai_agent_id) { where(ai_agent_id: ai_agent_id) }

  private

  def validate_file_size
    return if file_size.blank?

    errors.add(:file_size, "must be less than #{MAX_FILE_SIZE / 1.megabyte}MB") if file_size > MAX_FILE_SIZE
  end
end
