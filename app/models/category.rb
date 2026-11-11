class Category < ApplicationRecord
  has_many :products, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, on: :create

  scope :ordered, -> { order(display_order: :asc, name: :asc) }
  scope :for_department, ->(dept) { where(department: dept).ordered }

  DEPARTMENTS = [
    "Stockfeed & Animal Nutrition",
    "Rural Hardware & Farm Supplies"
  ].freeze

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.parameterize if slug.blank? && name.present?
  end
end

