class TopsisRun < ApplicationRecord
  belongs_to :event
  belongs_to :executed_by, class_name: "User", optional: true
  has_many :ranking_results, dependent: :destroy

  validates :executed_at, presence: true

  scope :recent_first, -> { order(executed_at: :desc) }

  def winner
    ranking_results.order(:rank).first
  end
end
