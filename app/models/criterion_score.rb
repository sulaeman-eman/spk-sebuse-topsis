class CriterionScore < ApplicationRecord
  belongs_to :participant
  belongs_to :criterion

  validates :normalized_value,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :criterion_id, uniqueness: { scope: :participant_id }
end
