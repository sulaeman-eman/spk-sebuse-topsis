class Criterion < ApplicationRecord
  # Toleransi pembulatan saat menjumlahkan bobot desimal.
  WEIGHT_TOLERANCE = 0.0001

  has_many :criterion_scores, dependent: :destroy

  enum :criterion_type, { benefit: 0, cost: 1 }

  validates :code, presence: true, uniqueness: true, format: { with: /\AC\d+\z/, message: "harus berformat C1, C2, dan seterusnya" }
  validates :name, presence: true
  validates :position, presence: true, uniqueness: true
  validates :weight, numericality: { greater_than: 0, less_than_or_equal_to: 1 }

  scope :ordered, -> { order(:position) }

  class << self
    def total_weight
      sum(:weight)
    end

    # Syarat UC-03 3.1: akumulasi bobot harus tepat 100% (1,0).
    def weights_balanced?
      (total_weight - 1).abs <= WEIGHT_TOLERANCE
    end

    # Pembaruan bobot dilakukan sekaligus (UC-03), karena satu bobot tidak bisa
    # dinilai valid sendirian -- yang harus berjumlah 1,0 adalah keseluruhannya.
    # Mengembalikan true bila tersimpan, false bila total bobot bukan 100%.
    def update_weights(weights_by_code)
      balanced = false

      transaction do
        weights_by_code.each do |code, weight|
          find_by!(code: code.to_s).update!(weight: weight)
        end

        balanced = weights_balanced?
        raise ActiveRecord::Rollback unless balanced
      end

      balanced
    end
  end

  def label
    "#{code} - #{name}"
  end
end
