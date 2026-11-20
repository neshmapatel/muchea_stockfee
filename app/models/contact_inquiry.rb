class ContactInquiry < ApplicationRecord
  STATUSES = %w[new in_progress resolved archived].freeze

  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :phone, presence: true
  validates :message, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent_first, -> { order(created_at: :desc) }
  scope :unresolved, -> { where(status: %w[new in_progress]) }
  scope :new_inquiries, -> { where(status: "new") }

  def new?
    status == "new"
  end

  def resolved?
    status == "resolved"
  end

  def mark_resolved!
    update!(status: "resolved")
  end

  def mark_in_progress!
    update!(status: "in_progress")
  end
end
