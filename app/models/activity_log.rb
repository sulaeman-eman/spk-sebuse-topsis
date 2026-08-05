class ActivityLog < ApplicationRecord
  belongs_to :participant

  enum :activity_type, { cardio: 0, strength: 1, long_run: 2, fun_sport: 3 }
  enum :source, { manual: 0, import: 1 }

  validates :activity_date, presence: true
  validates :raw_points, numericality: { greater_than_or_equal_to: 0 }
  validates :distance_km, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :on_date, ->(date) { where(activity_date: date) }
  scope :chronological, -> { order(:activity_date) }
end
