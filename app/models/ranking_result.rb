class RankingResult < ApplicationRecord
  belongs_to :topsis_run
  belongs_to :participant

  validates :preference_value,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :rank, numericality: { greater_than: 0 }

  scope :leaderboard, -> { order(:rank) }

  # Sebutan juara sesuai tabel Rekapitulasi Pemeringkatan Bab IV.
  def award_label
    rank <= 3 ? "Juara #{rank}" : "Peringkat #{rank}"
  end
end
