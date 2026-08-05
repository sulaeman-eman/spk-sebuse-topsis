# Pembatasan hak akses per use case, mengikuti pembagian aktor pada use case
# diagram Bab IV.C.1:
#
#   Super Admin    : UC-02 Kelola Pengguna, UC-03 Kelola Kriteria & Bobot
#   Admin Panitia  : UC-04 Kelola Peserta, UC-05 Import Log, UC-06 Pre-processing,
#                    UC-07 Hitung TOPSIS, UC-10 Cetak Laporan
#   Peserta        : UC-08 Papan Peringkat, UC-09 Detail Skor Individu
module Authorization
  extend ActiveSupport::Concern

  class Forbidden < StandardError; end

  included do
    helper_method :current_user, :manages_users?, :manages_criteria?, :runs_topsis?

    rescue_from Forbidden do
      redirect_to root_path, alert: "Anda tidak memiliki hak akses untuk halaman tersebut."
    end
  end

  private

  def current_user
    Current.session&.user
  end

  def manages_users?    = current_user&.manages_users?
  def manages_criteria? = current_user&.manages_criteria?
  def runs_topsis?      = current_user&.runs_topsis?

  def require_super_admin
    raise Forbidden unless current_user&.super_admin?
  end

  # Super Admin tetap diizinkan agar bisa menyiapkan data tanpa berganti akun.
  def require_committee
    raise Forbidden unless current_user&.runs_topsis?
  end
end
