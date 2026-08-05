require "rails_helper"

# Menguji jembatan antara database dan TopsisEngine (UC-07): matriks tersusun
# benar dari criterion_scores, dan seluruh langkah komputasi tersimpan.
RSpec.describe TopsisRunCreator do
  let(:event) do
    Event.create!(name: "SEBUSE Uji", start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 29))
  end

  let(:criteria) do
    [
      [ "C1", 0.20 ], [ "C2", 0.15 ], [ "C3", 0.15 ], [ "C4", 0.10 ], [ "C5", 0.10 ],
      [ "C6", 0.10 ], [ "C7", 0.05 ], [ "C8", 0.05 ], [ "C9", 0.05 ], [ "C10", 0.05 ]
    ].each_with_index.map do |(code, weight), index|
      Criterion.create!(code: code, name: "Kriteria #{code}", weight: weight, position: index + 1)
    end
  end

  # Lima peserta dan matriks keputusan X Bab IV halaman 42.
  let(:sample) do
    {
      "A1" => [ 85, 80, 100,  90, 85,  90, 80, 75,  90,  95 ],
      "A2" => [ 90, 85, 100,  95, 90,  80, 85, 80,  95,  90 ],
      "A3" => [ 70, 75,  80,  70, 65, 100, 75, 60,  80,  85 ],
      "A4" => [ 60, 65,  50,  60, 50,  70, 65, 50,  70,  75 ],
      "A5" => [ 95, 90, 100, 100, 95,  85, 90, 90, 100, 100 ]
    }
  end

  def build_participants(rows = sample)
    criteria
    rows.map do |code, values|
      participant = Participant.create!(
        event: event, nip: "CSU-#{code}", name: "Peserta #{code}", alternative_code: code
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

  describe "hasil pemeringkatan" do
    before { build_participants }

    subject(:run) { described_class.new(event).call }

    it "menghasilkan peringkat yang sama dengan tabel Rekapitulasi Pemeringkatan" do
      expected = [
        [ 1, "A5", 0.8988 ],
        [ 2, "A2", 0.8182 ],
        [ 3, "A1", 0.7618 ],
        [ 4, "A3", 0.4350 ],
        [ 5, "A4", 0.0000 ]
      ]

      actual = run.ranking_results.leaderboard.includes(:participant).map do |result|
        [ result.rank, result.participant.alternative_code, result.preference_value.to_f ]
      end

      expected.each_with_index do |(rank, code, preference), index|
        expect(actual[index][0]).to eq(rank)
        expect(actual[index][1]).to eq(code)
        expect(actual[index][2]).to be_within(0.0001).of(preference)
      end
    end

    it "menyimpan satu hasil untuk setiap peserta" do
      expect(run.ranking_results.count).to eq(5)
    end

    it "menyimpan seluruh langkah komputasi berlabel kode alternatif dan kriteria" do
      expect(run.decision_matrix.keys).to eq(%w[A1 A2 A3 A4 A5])
      expect(run.decision_matrix["A1"]).to eq(sample["A1"])
      expect(run.normalized_matrix["A1"].size).to eq(10)
      expect(run.weighted_matrix["A5"].size).to eq(10)
      expect(run.ideal_positive.keys).to eq(%w[C1 C2 C3 C4 C5 C6 C7 C8 C9 C10])
    end

    it "menyimpan snapshot bobot yang dipakai saat eksekusi" do
      expect(run.weights_snapshot["C1"]).to eq(0.20)
      expect(run.weights_snapshot.values.sum).to be_within(0.0001).of(1.0)
    end

    it "membuat snapshot yang tidak berubah walau bobot kriteria diubah setelahnya" do
      run
      Criterion.find_by(code: "C1").update!(weight: 0.30)

      expect(run.reload.weights_snapshot["C1"]).to eq(0.20)
    end

    it "menandai juara pertama pada peserta dengan nilai preferensi tertinggi" do
      expect(run.winner.participant.alternative_code).to eq("A5")
      expect(run.winner.award_label).to eq("Juara 1")
    end
  end

  it "mencatat siapa yang mengeksekusi perhitungan" do
    build_participants
    panitia = User.create!(
      email_address: "panitia@uji.test", name: "Panitia", password: "rahasia123", role: :admin_panitia
    )

    run = described_class.new(event, executed_by: panitia).call

    expect(run.executed_by).to eq(panitia)
    expect(run.executed_at).to be_present
  end

  describe "penolakan" do
    it "menolak dijalankan bila total bobot bukan 100%" do
      build_participants
      Criterion.find_by(code: "C7").update!(weight: 0.10)

      expect { described_class.new(event).call }
        .to raise_error(TopsisRunCreator::UnbalancedWeights)
    end

    it "menolak dijalankan bila belum ada hasil pre-processing" do
      criteria

      expect { described_class.new(event).call }
        .to raise_error(TopsisRunCreator::NoScores)
    end

    # Baris tidak lengkap akan menggeser kolom dan merusak seluruh perhitungan.
    it "melewati peserta yang skornya belum lengkap" do
      build_participants
      Participant.create!(
        event: event, nip: "CSU-A6", name: "Peserta baru", alternative_code: "A6"
      ).criterion_scores.create!(criterion: criteria.first, normalized_value: 90)

      run = described_class.new(event).call

      expect(run.ranking_results.count).to eq(5)
      expect(run.decision_matrix.keys).not_to include("A6")
    end

    it "tidak menyimpan apa pun bila penyimpanan hasil gagal di tengah jalan" do
      build_participants
      # Peringkat 0 ditolak validasi RankingResult, jadi transaksi harus batal
      # utuh: tidak boleh ada topsis_run tanpa hasil peringkat.
      broken = TopsisEngine.new(matrix: sample.values, weights: criteria.map(&:weight)).call
      broken.ranks = Array.new(5, 0)
      allow(TopsisEngine).to receive(:new).and_return(instance_double(TopsisEngine, call: broken))

      expect { described_class.new(event).call }.to raise_error(ActiveRecord::RecordInvalid)
      expect(TopsisRun.count).to eq(0)
      expect(RankingResult.count).to eq(0)
    end
  end
end
