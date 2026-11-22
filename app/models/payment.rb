# frozen_string_literal: true

class Payment < ApplicationRecord
  belongs_to :order

  validates :amount_cents, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  STATUSES = %w[pending succeeded failed refunded].freeze

  scope :recent, -> { order(created_at: :desc) }
  scope :succeeded, -> { where(status: "succeeded") }
  scope :failed, -> { where(status: "failed") }

  def amount_dollars
    amount_cents / 100.0
  end

  def formatted_amount
    "AU$ #{format('%.2f', amount_dollars)}"
  end

  def succeeded?
    status == "succeeded"
  end

  def failed?
    status == "failed"
  end
end
