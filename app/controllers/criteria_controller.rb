# UC-03 Kelola Kriteria dan Bobot. Hanya Super Admin.
#
# Bobot diperbarui sekaligus, bukan satu per satu, karena syarat 3.1 menuntut
# akumulasi seluruh bobot bernilai tepat 100%.
class CriteriaController < ApplicationController
  before_action :require_super_admin, except: :index

  def index
    @criteria = Criterion.ordered
    @total_weight = Criterion.total_weight
    @balanced = Criterion.weights_balanced?
  end

  def update_weights
    if Criterion.update_weights(weight_params)
      redirect_to criteria_path, notice: "Bobot kriteria berhasil disimpan."
    else
      redirect_to criteria_path,
                  alert: "Total bobot harus tepat 100%. Perubahan dibatalkan, silakan sesuaikan kembali."
    end
  end

  private

  # Dikirim sebagai persen agar sesuai tampilan tabel 3.2, lalu diubah ke desimal.
  def weight_params
    params.require(:weights).permit(Criterion.pluck(:code)).to_h.transform_values do |percent|
      percent.to_f / 100
    end
  end
end
