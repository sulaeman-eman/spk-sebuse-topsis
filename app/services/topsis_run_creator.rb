# Menjembatani database dengan TopsisEngine (UC-07).
#
# Menyusun matriks keputusan dari criterion_scores, menjalankan kalkulasi, lalu
# menyimpan seluruh langkah perhitungan ke topsis_runs beserta peringkat akhir
# ke ranking_results.
#
#   run = TopsisRunCreator.new(event, executed_by: current_user).call
#   run.ranking_results.leaderboard
class TopsisRunCreator
  class NoScores < StandardError; end
  class UnbalancedWeights < StandardError; end

  attr_reader :event, :executed_by

  def initialize(event, executed_by: nil)
    @event = event
    @executed_by = executed_by
  end

  def call
    criteria = Criterion.ordered.to_a
    raise UnbalancedWeights, "total bobot kriteria harus 100%" unless Criterion.weights_balanced?

    participants = scored_participants(criteria)
    raise NoScores, "belum ada hasil pre-processing untuk event ini" if participants.empty?

    matrix = participants.map { |participant| row_for(participant, criteria) }
    result = TopsisEngine.new(
      matrix: matrix,
      weights: criteria.map(&:weight),
      types: criteria.map { |criterion| criterion.criterion_type.to_sym }
    ).call

    persist(result, participants, criteria)
  end

  private

  # Hanya peserta yang skornya lengkap untuk seluruh kriteria yang boleh masuk
  # matriks. Baris tidak lengkap akan menggeser kolom dan merusak perhitungan.
  def scored_participants(criteria)
    event.participants.ordered.includes(:criterion_scores).select do |participant|
      participant.criterion_scores.size == criteria.size
    end
  end

  def row_for(participant, criteria)
    scores = participant.criterion_scores.index_by(&:criterion_id)

    criteria.map { |criterion| scores.fetch(criterion.id).normalized_value.to_f }
  end

  def persist(result, participants, criteria)
    TopsisRun.transaction do
      run = TopsisRun.create!(
        event: event,
        executed_by: executed_by,
        executed_at: Time.current,
        weights_snapshot: criteria.to_h { |criterion| [ criterion.code, criterion.weight.to_f ] },
        decision_matrix: labelled(result.decision_matrix, participants),
        normalized_matrix: labelled(result.normalized_matrix, participants),
        weighted_matrix: labelled(result.weighted_matrix, participants),
        ideal_positive: labelled_row(result.ideal_positive, criteria),
        ideal_negative: labelled_row(result.ideal_negative, criteria)
      )

      participants.each_with_index do |participant, index|
        run.ranking_results.create!(
          participant: participant,
          d_positive: result.distances_positive[index],
          d_negative: result.distances_negative[index],
          preference_value: result.preferences[index],
          rank: result.ranks[index]
        )
      end

      run
    end
  end

  # Matriks disimpan berlabel kode alternatif supaya rincian komputasi tetap
  # terbaca walau daftar peserta berubah setelah eksekusi.
  def labelled(matrix, participants)
    participants.each_with_index.to_h do |participant, index|
      [ participant.alternative_code, matrix[index] ]
    end
  end

  def labelled_row(row, criteria)
    criteria.each_with_index.to_h { |criterion, index| [ criterion.code, row[index] ] }
  end
end
