require "rails_helper"

# UC-01 Login dan UC-14 Logout. Keduanya dijalankan oleh ketiga aktor, sehingga
# pengujian menelusuri seluruh peran, bukan satu peran saja.
RSpec.describe "UC-01 Login dan UC-14 Logout", type: :request do
  describe "UC-01 Login" do
    it "membuat sesi lalu mengarahkan ke dasbor bagi ketiga aktor" do
      %i[super_admin admin_panitia peserta].each do |role|
        user = create_user(role: role)
        sign_in(user)

        expect(response).to redirect_to(root_path)
        expect(user.sessions.count).to eq(1)
      end
    end

    it "menolak kredensial yang tidak sah tanpa membuat sesi" do
      user = create_user(role: :admin_panitia)

      post session_path, params: { email_address: user.email_address, password: "salah" }

      expect(response).to redirect_to(new_session_path)
      expect(user.sessions.count).to eq(0)
    end
  end

  describe "UC-14 Logout" do
    it "mengakhiri sesi dan mengarahkan ke halaman login bagi ketiga aktor" do
      %i[super_admin admin_panitia peserta].each do |role|
        user = create_user(role: role)
        sign_in(user)

        delete session_path

        expect(response).to redirect_to(new_session_path)
        expect(response).to have_http_status(:see_other)
        expect(user.sessions.reload.count).to eq(0)
      end
    end

    it "menuntut login kembali untuk membuka halaman yang dilindungi" do
      sign_in_as(:admin_panitia)
      delete session_path

      get root_path

      expect(response).to redirect_to(new_session_path)
    end

    it "mengakhiri hanya sesi peramban yang menekan tombol keluar" do
      user = create_user(role: :admin_panitia)
      sesi_lain = user.sessions.create!(user_agent: "peramban lain", ip_address: "10.0.0.9")
      sign_in(user)

      delete session_path

      expect(user.sessions.reload.pluck(:id)).to eq([ sesi_lain.id ])
    end
  end
end
