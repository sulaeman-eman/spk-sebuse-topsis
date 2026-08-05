require "rails_helper"

# Memastikan pembatasan hak akses sesuai pembagian aktor pada use case diagram:
# Super Admin mengelola pengguna dan bobot, Admin Panitia mengelola data dan
# menjalankan perhitungan, Peserta hanya melihat peringkat dan skornya sendiri.
RSpec.describe "Hak akses per use case", type: :request do
  let!(:criteria) { create_criteria }
  let!(:event) { create_event }
  let!(:participants) { create_scored_participants(event, criteria) }

  describe "tanpa login" do
    it "mengarahkan seluruh halaman ke formulir masuk" do
      [
        root_path, users_path, criteria_path, events_path,
        event_participants_path(event), event_preprocessing_path(event),
        event_topsis_runs_path(event), event_leaderboard_path(event),
        score_path(participants.first)
      ].each do |path|
        get path

        expect(response).to redirect_to(new_session_path), "#{path} seharusnya menuntut login"
      end
    end
  end

  describe "UC-02 Kelola Data Pengguna" do
    it "dibuka Super Admin" do
      sign_in_as(:super_admin)
      get users_path

      expect(response).to have_http_status(:ok)
    end

    it "ditolak untuk Admin Panitia dan Peserta" do
      %i[admin_panitia peserta].each do |role|
        sign_in_as(role)
        get users_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/hak akses/i)
      end
    end
  end

  describe "UC-03 Kelola Kriteria dan Bobot" do
    it "dapat dilihat semua peran sebagai informasi" do
      %i[super_admin admin_panitia peserta].each do |role|
        sign_in_as(role)
        get criteria_path

        expect(response).to have_http_status(:ok)
      end
    end

    it "hanya Super Admin yang boleh menyimpan bobot" do
      sign_in_as(:admin_panitia)
      patch update_weights_criteria_path, params: { weights: { "C1" => 25, "C2" => 10 } }

      expect(response).to redirect_to(root_path)
      expect(Criterion.find_by(code: "C1").weight).to eq(0.20)
    end
  end

  describe "UC-04 Kelola Data Peserta" do
    it "dibuka Admin Panitia" do
      sign_in_as(:admin_panitia)
      get event_participants_path(event)

      expect(response).to have_http_status(:ok)
    end

    it "ditolak untuk Peserta" do
      sign_in_as(:peserta)
      get event_participants_path(event)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "UC-06 dan UC-07 Pre-processing dan Hitung TOPSIS" do
    it "ditolak untuk Peserta" do
      sign_in_as(:peserta)

      post event_preprocessing_path(event)
      expect(response).to redirect_to(root_path)

      post event_topsis_runs_path(event)
      expect(response).to redirect_to(root_path)
      expect(TopsisRun.count).to eq(0)
    end
  end

  describe "UC-08 Papan Peringkat" do
    it "terbuka untuk seluruh peran demi transparansi" do
      %i[super_admin admin_panitia peserta].each do |role|
        sign_in_as(role)
        get event_leaderboard_path(event)

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "UC-09 Detail Skor Individu" do
    let(:participant) { participants.first }

    it "mengizinkan Peserta membuka rincian skor miliknya" do
      user = sign_in_as(:peserta)
      participant.update!(user: user)

      get score_path(participant)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(participant.name)
    end

    it "menolak Peserta membuka rincian skor peserta lain" do
      sign_in_as(:peserta)

      get score_path(participant)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to match(/hak akses/i)
    end

    it "mengizinkan panitia membuka rincian skor siapa pun untuk verifikasi" do
      sign_in_as(:admin_panitia)

      get score_path(participant)

      expect(response).to have_http_status(:ok)
    end
  end
end
