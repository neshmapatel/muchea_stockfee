class AdminUser < ApplicationRecord
  belongs_to :role
  belongs_to :created_by, class_name: "AdminUser", optional: true
  has_many :created_users, class_name: "AdminUser", foreign_key: :created_by_id, dependent: :nullify
  has_many :inventory_logs, dependent: :nullify

  has_secure_password

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || password.present? }
  validate :preserve_at_least_one_active_super_admin, on: :update

  before_validation :normalize_email

  scope :active, -> { where(active: true) }
  scope :ordered, -> { joins(:role).order("roles.is_super_admin DESC, roles.display_order ASC, admin_users.name ASC") }
  scope :super_admins, -> { joins(:role).where(roles: { is_super_admin: true }) }

  def super_admin?
    active? && role&.is_super_admin? == true
  end

  def can?(permission)
    return false unless active? && role.present?
    role.allows?(permission)
  end

  def can_any?(*permissions)
    return false unless active? && role.present?
    return true if role.is_super_admin?
    permissions.flatten.any? { |perm| role.allows?(perm) }
  end

  def manageable_by?(actor)
    return false unless actor&.active?
    return true if actor.super_admin?

    !role&.is_super_admin? && actor.can?(:manage_admin_users)
  end

  def role_name
    role&.name || "Unassigned"
  end

  def role_slug
    role&.slug
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def preserve_at_least_one_active_super_admin
    was_active = active_in_database
    previous_role = role_id_changed? ? Role.find_by(id: role_id_in_database) : role
    was_super = previous_role&.is_super_admin? && was_active

    return unless was_super
    return if active? && role&.is_super_admin?

    unless AdminUser.active.super_admins.where.not(id: id).exists?
      errors.add(:base, "Cannot deactivate or demote the last remaining active Super Admin.")
    end
  end
end
