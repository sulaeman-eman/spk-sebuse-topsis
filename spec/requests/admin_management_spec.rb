require "rails_helper"

RSpec.describe "Pengelolaan oleh Super Admin", type: :request do
  describe "UC-01 Login" do
    let!(:user) { create_user(role: :super_admin, email_address: "admin@uji.test") }

    it "membuat sesi dan mengarahkan ke dasbor saat kredensial benar" do
      post session_path, params: { email_address: "admin@uji.test", password: "sebuse2026" }

      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Dasbor")
    end

    it "menolak dan menampilkan pesan kesalahan saat kredensial salah" do
      post session_path, params: { email_address: "admin@uji.test", password: "salah" }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to be_present
      expect(user.sessions.count).to eq(0)
    end

    it "mengakhiri sesi saat pengguna keluar" do
      sign_in(user)
      expect(user.sessions.count).to eq(1)

      delete session_path

      expect(response).to redirect_to(new_session_path)
      expect(user.sessions.count).to eq(0)
    end
  end

  describe "UC-02 Kelola Data Pengguna" do
    before { sign_in_as(:super_admin) }

    it "menyimpan pengguna baru beserta perannya" do
      expect {
        post users_path, params: {
          user: {
            name: "Panitia Baru", email_address: "panitia.baru@uji.test",
            role: "admin_panitia", password: "sebuse2026"
          }
        }
      }.to change(User, :count).by(1)

      expect(User.find_by(email_address: "panitia.baru@uji.test")).to be_admin_panitia
    end

    it "menolak email yang sudah terpakai" do
      create_user(role: :peserta, email_address: "kembar@uji.test")

      post users_path, params: {
        user: { name: "Kembar", email_address: "kembar@uji.test", role: "peserta", password: "sebuse2026" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(User.where(email_address: "kembar@uji.test").count).to eq(1)
    end

    it "mempertahankan kata sandi lama bila kolomnya dibiarkan kosong" do
      target = create_user(role: :peserta, email_address: "peserta@uji.test")
      digest_awal = target.password_digest

      patch user_path(target), params: {
        user: { name: "Nama Baru", email_address: "peserta@uji.test", role: "peserta", password: "" }
      }

      expect(target.reload.name).to eq("Nama Baru")
      expect(target.password_digest).to eq(digest_awal)
    end

    it "menolak menghapus akun yang sedang digunakan" do
      expect { delete user_path(current_admin) }.not_to change(User, :count)
      expect(flash[:alert]).to match(/sedang digunakan/i)
    end

    def current_admin
      User.super_admin.first
    end
  end

  describe "UC-03 Kelola Kriteria dan Bobot" do
    let!(:criteria) { create_criteria }

    before { sign_in_as(:super_admin) }

    it "menyimpan bobot baru bila totalnya tetap 100%" do
      patch update_weights_criteria_path, params: { weights: { "C1" => 25, "C2" => 10 } }

      expect(response).to redirect_to(criteria_path)
      expect(flash[:notice]).to match(/berhasil/i)
      expect(Criterion.find_by(code: "C1").weight).to eq(0.25)
      expect(Criterion.total_weight).to eq(1)
    end

    it "membatalkan perubahan dan memperingatkan bila total bukan 100%" do
      patch update_weights_criteria_path, params: { weights: { "C1" => 30 } }

      expect(flash[:alert]).to match(/100%/)
      expect(Criterion.find_by(code: "C1").weight).to eq(0.20)
      expect(Criterion.total_weight).to eq(1)
    end

    it "menampilkan sepuluh kriteria beserta jenis dan bobotnya" do
      get criteria_path

      expect(response).to have_http_status(:ok)
      Criterion.pluck(:code).each { |code| expect(response.body).to include(code) }
      expect(response.body).to include("Benefit")
    end
  end
end
