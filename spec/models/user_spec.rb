require "rails_helper"

RSpec.describe User, type: :model do
  def build_user(role:)
    described_class.new(
      email_address: "orang@cahayasuarautama.co.id",
      name: "Orang",
      password: "sebuse2026",
      role: role
    )
  end

  it "mengenali tiga aktor pada use case diagram" do
    expect(described_class.roles.keys).to eq(%w[super_admin admin_panitia peserta])
  end

  it "mewajibkan nama pengguna" do
    user = build_user(role: :peserta)
    user.name = nil

    expect(user).not_to be_valid
  end

  it "menormalkan alamat email" do
    user = build_user(role: :peserta)
    user.email_address = "  Orang@Cahayasuarautama.co.id "

    expect(user.email_address).to eq("orang@cahayasuarautama.co.id")
  end

  describe "hak akses per use case" do
    # UC-02 dan UC-03 hanya untuk Super Admin, UC-07 untuk Super Admin dan
    # Admin Panitia.
    it "membatasi kelola pengguna dan kriteria pada Super Admin" do
      expect(build_user(role: :super_admin)).to be_manages_users
      expect(build_user(role: :super_admin)).to be_manages_criteria
      expect(build_user(role: :admin_panitia)).not_to be_manages_users
      expect(build_user(role: :peserta)).not_to be_manages_criteria
    end

    it "mengizinkan eksekusi TOPSIS oleh Super Admin dan Admin Panitia" do
      expect(build_user(role: :super_admin)).to be_runs_topsis
      expect(build_user(role: :admin_panitia)).to be_runs_topsis
      expect(build_user(role: :peserta)).not_to be_runs_topsis
    end
  end
end
