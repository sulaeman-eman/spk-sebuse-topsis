require "rails_helper"

# Sudut pandang peserta: transparansi hasil (UC-08) dan evaluasi mandiri (UC-09).
RSpec.describe "Tampilan peserta", type: :request do
  let!(:criteria) { create_criteria }
  let!(:event) { create_event }
  let!(:participants) { create_scored_participants(event, criteria) }
  let(:budi) { participants.find { |p| p.name == "Budi" } }
  let!(:peserta) { create_user(role: :peserta, name: "Budi") }

  before do
    budi.update!(user: peserta)
    TopsisRunCreator.new(event).call
    sign_in(peserta)
  end

  describe "UC-08 Papan Peringkat" do
    it "menampilkan seluruh peserta terurut dari nilai preferensi tertinggi" do
      get event_leaderboard_path(event)

      expect(response).to have_http_status(:ok)
      body = response.body
      # Eka juara 1, Dedi peringkat terakhir sesuai tabel Bab IV.
      expect(body.index("Eka")).to be < body.index("Dedi")
      expect(body).to include("Juara 1", "Peringkat 5")
    end

    it "menyoroti peringkat peserta yang sedang masuk" do
      get event_leaderboard_path(event)

      expect(response.body).to include("Peringkat Anda", "row--highlight")
    end

    it "menampilkan pemberitahuan bila perhitungan belum dijalankan" do
      TopsisRun.destroy_all

      get event_leaderboard_path(event)

      expect(response.body).to include("belum tersedia")
    end
  end

  describe "UC-09 Detail Skor Individu" do
    it "menampilkan rincian sepuluh kriteria beserta catatan evaluasi" do
      get score_path(budi)

      expect(response).to have_http_status(:ok)
      criteria.each { |criterion| expect(response.body).to include(criterion.code) }
      expect(response.body).to include("Detail Skor Individu")
    end

    it "menampilkan jarak solusi ideal dan nilai preferensi peserta" do
      get score_path(budi)

      expect(response.body).to include("Nilai preferensi", "Jarak ideal positif", "Jarak ideal negatif")
    end
  end

  describe "menu yang tersedia" do
    it "tidak menampilkan tautan pengelolaan pada navigasi peserta" do
      get root_path

      expect(response.body).not_to include(users_path)
      expect(response.body).not_to include(event_preprocessing_path(event))
      expect(response.body).to include(event_leaderboard_path(event))
    end

    it "menautkan rincian skor peserta dari dasbor" do
      get root_path

      expect(response.body).to include(score_path(budi))
    end
  end
end
