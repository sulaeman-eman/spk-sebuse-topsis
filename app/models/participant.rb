class Participant < ApplicationRecord
  belongs_to :event
  belongs_to :user, optional: true
  has_many :activity_logs, dependent: :destroy
  has_many :criterion_scores, dependent: :destroy
  has_many :ranking_results, dependent: :destroy

  validates :nip, presence: true, uniqueness: { scope: :event_id }
  validates :name, presence: true
  validates :alternative_code, presence: true,
            uniqueness: { scope: :event_id },
            format: { with: /\AA\d+\z/, message: "harus berformat A1, A2, dan seterusnya" }

  # Diurutkan panjang kode dulu agar A10 jatuh setelah A9, bukan setelah A1.
  scope :ordered, -> { order(Arel.sql("LENGTH(alternative_code), alternative_code")) }

  # Baris matriks keputusan X untuk peserta ini, terurut C1..C10.
  def decision_row
    criterion_scores.joins(:criterion).merge(Criterion.ordered).pluck(:normalized_value)
  end
end
