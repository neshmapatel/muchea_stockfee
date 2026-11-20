class Customer < ApplicationRecord
  has_secure_password

  belongs_to :approved_by, class_name: "AdminUser", optional: true

  STATUSES = %w[pending approved rejected].freeze

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phone, presence: true
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }

  before_validation :normalize_attributes

  scope :pending, -> { where(status: "pending") }
  scope :approved, -> { where(status: "approved") }
  scope :rejected, -> { where(status: "rejected") }
  scope :recent, -> { order(created_at: :desc) }

  def name
    [first_name, last_name].compact.join(" ")
  end

  def pending?
    status == "pending"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def can_view_prices?
    approved?
  end

  def approve!(admin_user)
    update!(
      status: "approved",
      approved_at: Time.current,
      approved_by: admin_user,
      rejection_reason: nil
    )
  end

  def reject!(admin_user, reason: nil)
    update!(
      status: "rejected",
      rejection_reason: reason,
      approved_by: admin_user
    )
  end

  def status_badge_color
    case status
    when "approved" then "bg-emerald-100 text-emerald-800 border-emerald-300"
    when "rejected" then "bg-rose-100 text-rose-800 border-rose-300"
    else "bg-amber-100 text-amber-900 border-amber-300"
    end
  end

  private

  def normalize_attributes
    self.email = email.to_s.strip.downcase
    self.phone = phone.to_s.strip
    self.first_name = first_name.to_s.strip
    self.last_name = last_name.to_s.strip
    self.business_name = business_name.to_s.strip.presence
    self.abn = abn.to_s.strip.presence
  end
end
