# UC-07 Hitung Metode TOPSIS beserta rincian komputasinya.
class TopsisRunsController < ApplicationController
  before_action :require_committee, except: :show
  before_action :set_event

  def index
    @topsis_runs = @event.topsis_runs.recent_first
  end

  # Rincian seluruh langkah perhitungan dari snapshot yang tersimpan.
  def show
    @topsis_run = @event.topsis_runs.find(params[:id])
    @criteria = Criterion.ordered
    @ranking_results = @topsis_run.ranking_results.leaderboard.includes(:participant)
  end

  def create
    run = TopsisRunCreator.new(@event, executed_by: current_user).call

    redirect_to event_topsis_run_path(@event, run),
                notice: "Perhitungan TOPSIS selesai. #{run.ranking_results.count} peserta diperingkatkan."
  rescue TopsisRunCreator::UnbalancedWeights
    redirect_to criteria_path,
                alert: "Total bobot kriteria belum 100%. Sesuaikan bobot sebelum menghitung TOPSIS."
  rescue TopsisRunCreator::NoScores
    redirect_to event_preprocessing_path(@event),
                alert: "Belum ada matriks keputusan. Jalankan pre-processing terlebih dahulu."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
