# Pembantu penyiapan data uji: 10 kriteria tabel 3.2 dan lima peserta beserta
# matriks keputusan X Bab IV halaman 42.
module SebuseData
  CRITERIA = [
    [ "C1", "Total Poin Cardio", 0.20 ],
    [ "C2", "Total Poin Strength", 0.15 ],
    [ "C3", "Ketuntasan Long Run", 0.15 ],
    [ "C4", "Syarat Mingguan", 0.10 ],
    [ "C5", "Bonus Mingguan", 0.10 ],
    [ "C6", "Aturan Beruntun", 0.10 ],
    [ "C7", "Hasil Pengukuran Akhir", 0.05 ],
    [ "C8", "Poin Fun Sports", 0.05 ],
    [ "C9", "Disiplin Harian", 0.05 ],
    [ "C10", "Kualitas Evidence", 0.05 ]
  ].freeze

  DECISION_MATRIX = {
    "A1" => [ "Budi",  [ 85, 80, 100,  90, 85,  90, 80, 75,  90,  95 ] ],
    "A2" => [ "Andi",  [ 90, 85, 100,  95, 90,  80, 85, 80,  95,  90 ] ],
    "A3" => [ "Citra", [ 70, 75,  80,  70, 65, 100, 75, 60,  80,  85 ] ],
    "A4" => [ "Dedi",  [ 60, 65,  50,  60, 50,  70, 65, 50,  70,  75 ] ],
    "A5" => [ "Eka",   [ 95, 90, 100, 100, 95,  85, 90, 90, 100, 100 ] ]
  }.freeze

  def create_criteria
    CRITERIA.each_with_index.map do |(code, name, weight), index|
      Criterion.create!(code: code, name: name, weight: weight, position: index + 1)
    end
  end

  def create_event(**attributes)
    Event.create!(
      { name: "SEBUSE 2026", start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 29) }
        .merge(attributes)
    )
  end

  # Membuat lima peserta beserta skor kriterianya, siap dihitung TOPSIS.
  def create_scored_participants(event, criteria)
    DECISION_MATRIX.map do |code, (name, values)|
      participant = Participant.create!(
        event: event, alternative_code: code, name: name, nip: "CSU-#{code}"
      )

      criteria.each_with_index do |criterion, index|
        CriterionScore.create!(
          participant: participant, criterion: criterion,
          raw_value: values[index], normalized_value: values[index]
        )
      end

      participant
    end
  end
end

RSpec.configure do |config|
  config.include SebuseData, type: :request
end
