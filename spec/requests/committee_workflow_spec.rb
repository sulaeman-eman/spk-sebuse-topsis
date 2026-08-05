require "rails_helper"

# Menelusuri alur kerja panitia sesuai urutan use case: mendata peserta,
# mencatat log aktivitas, menjalankan pre-processing, menghitung TOPSIS, lalu
# mengumumkan papan peringkat.
RSpec.describe "Alur kerja panitia", type: :request do
  let!(:criteria) { create_criteria }
  let!(:event) { create_event }
  let!(:panitia) { sign_in_as(:admin_panitia) }

  describe "UC-04 mendata peserta" do
    it "menyimpan peserta baru sebagai alternatif penilaian" do
      expect {
        post event_participants_path(event), params: {
          participant: { alternative_code: "A1", nip: "CSU-0001", name: "Budi", department: "Produksi" }
        }
      }.to change(Participant, :count).by(1)

      expect(response).to redirect_to(event_participants_path(event))
      expect(flash[:notice]).to match(/Budi/)
    end

    it "menolak kode alternatif di luar format A1, A2, dan seterusnya" do
      post event_participants_path(event), params: {
        participant: { alternative_code: "Budi", nip: "CSU-0001", name: "Budi" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(Participant.count).to eq(0)
    end

    it "mengusulkan kode alternatif berikutnya pada formulir tambah" do
      Participant.create!(event: event, alternative_code: "A9", nip: "CSU-9", name: "Peserta 9")

      get new_event_participant_path(event)

      expect(response.body).to include('value="A10"')
    end
  end

  describe "pencatatan log aktivitas" do
    let(:participant) do
      Participant.create!(event: event, alternative_code: "A1", nip: "CSU-0001", name: "Budi")
    end

    it "menyimpan log manual beserta penanda sumbernya" do
      expect {
        post participant_activity_logs_path(participant), params: {
          activity_log: {
            activity_date: "2026-03-02", activity_type: "cardio",
            raw_points: 2, evidence_valid: "1"
          }
        }
      }.to change(ActivityLog, :count).by(1)

      log = ActivityLog.last
      expect(log.source).to eq("manual")
      expect(log.activity_type).to eq("cardio")
    end

    it "menandai hari yang melampaui kuota poin harian" do
      2.times do
        participant.activity_logs.create!(
          activity_date: Date.new(2026, 3, 4), activity_type: :cardio, raw_points: 3
        )
      end

      get participant_activity_logs_path(participant)

      expect(response.body).to include("poin/hari")
    end
  end

  describe "UC-06 sampai UC-08 dari log mentah hingga peringkat" do
    # Dua peserta dengan capaian berbeda: yang satu patuh, yang satu tidak.
    let!(:rajin) do
      Participant.create!(event: event, alternative_code: "A1", nip: "CSU-0001", name: "Rajin")
    end

    let!(:santai) do
      Participant.create!(event: event, alternative_code: "A2", nip: "CSU-0002", name: "Santai")
    end

    before do
      # Peserta rajin: cardio dan strength rutin tiap minggu, dua kali long run.
      (0..3).each do |week|
        monday = event.start_date + (week * 7)
        2.times { |i| rajin.activity_logs.create!(activity_date: monday + i, activity_type: :cardio, raw_points: 2, evidence_valid: true) }
        rajin.activity_logs.create!(activity_date: monday + 3, activity_type: :strength, raw_points: 2, evidence_valid: true)
      end
      rajin.activity_logs.create!(activity_date: event.start_date + 5, activity_type: :long_run, raw_points: 3, distance_km: 10.5, evidence_valid: true)
      rajin.activity_logs.create!(activity_date: event.start_date + 19, activity_type: :long_run, raw_points: 3, distance_km: 11, evidence_valid: true)

      # Peserta santai: hanya dua aktivitas, tanpa bukti valid.
      santai.activity_logs.create!(activity_date: event.start_date, activity_type: :cardio, raw_points: 2, evidence_valid: false)
      santai.activity_logs.create!(activity_date: event.start_date + 10, activity_type: :strength, raw_points: 2, evidence_valid: false)
    end

    it "membentuk matriks keputusan lengkap saat pre-processing dijalankan" do
      expect {
        post event_preprocessing_path(event)
      }.to change(CriterionScore, :count).by(20)

      expect(response).to redirect_to(event_preprocessing_path(event))
      expect(flash[:notice]).to match(/2 peserta/)
      expect(rajin.criterion_scores.count).to eq(10)
    end

    it "memberi nilai lebih tinggi pada peserta yang lebih patuh" do
      post event_preprocessing_path(event)

      cardio = Criterion.find_by(code: "C1")
      expect(rajin.criterion_scores.find_by(criterion: cardio).normalized_value)
        .to be > santai.criterion_scores.find_by(criterion: cardio).normalized_value
    end

    it "menghitung TOPSIS dan menempatkan peserta patuh pada peringkat pertama" do
      post event_preprocessing_path(event)

      expect { post event_topsis_runs_path(event) }.to change(TopsisRun, :count).by(1)

      run = TopsisRun.last
      expect(response).to redirect_to(event_topsis_run_path(event, run))
      expect(run.executed_by).to eq(panitia)
      expect(run.winner.participant).to eq(rajin)
    end

    it "menyimpan seluruh langkah komputasi untuk ditampilkan" do
      post event_preprocessing_path(event)
      post event_topsis_runs_path(event)

      get event_topsis_run_path(event, TopsisRun.last)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Matriks keputusan", "Matriks ternormalisasi", "Solusi ideal")
    end

    it "menampilkan hasil pada papan peringkat" do
      post event_preprocessing_path(event)
      post event_topsis_runs_path(event)

      get event_leaderboard_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Juara 1", rajin.name)
    end
  end

  describe "penolakan perhitungan" do
    it "mengarahkan ke pre-processing bila matriks keputusan belum ada" do
      Participant.create!(event: event, alternative_code: "A1", nip: "CSU-0001", name: "Budi")

      post event_topsis_runs_path(event)

      expect(response).to redirect_to(event_preprocessing_path(event))
      expect(flash[:alert]).to match(/pre-processing/i)
      expect(TopsisRun.count).to eq(0)
    end

    it "mengarahkan ke halaman kriteria bila total bobot bukan 100%" do
      participants = create_scored_participants(event, criteria)
      Criterion.find_by(code: "C7").update!(weight: 0.10)

      post event_topsis_runs_path(event)

      expect(response).to redirect_to(criteria_path)
      expect(flash[:alert]).to match(/100%/)
      expect(participants.size).to eq(5)
      expect(TopsisRun.count).to eq(0)
    end
  end
end
