class Event < ApplicationRecord
  has_many :participants, dependent: :destroy
  has_many :activity_logs, through: :participants
  has_many :topsis_runs, dependent: :destroy

  validates :name, presence: true
  validates :start_date, :end_date, presence: true
  validates :target_cardio, :target_strength, :total_weeks, :daily_point_cap,
            :weekly_cardio_target, :weekly_strength_target,
            :bonus_cardio_target, :bonus_strength_target,
            :max_consecutive_cardio_days, :fun_sport_point_target,
            numericality: { greater_than: 0 }
  validates :streak_penalty_per_violation, numericality: { greater_than_or_equal_to: 0 }
  validates :long_run_target_km, numericality: { greater_than: 0 }
  validate :end_date_after_start_date

  def latest_topsis_run
    topsis_runs.order(executed_at: :desc).first
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    return if end_date >= start_date

    errors.add(:end_date, "harus setelah atau sama dengan tanggal mulai")
  end
end
