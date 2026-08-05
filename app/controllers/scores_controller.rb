# UC-09 Lihat Detail Skor Individu.
#
# Peserta hanya boleh membuka rincian skor miliknya sendiri; Admin Panitia dan
# Super Admin boleh membuka rincian siapa pun untuk keperluan verifikasi.
class ScoresController < ApplicationController
  def show
    @participant = Participant.includes(:event, criterion_scores: :criterion).find(params[:id])
    authorize_access!

    @criterion_scores = @participant.criterion_scores.joins(:criterion).merge(Criterion.ordered)
    @ranking_result = @participant.ranking_results
                                  .joins(:topsis_run)
                                  .order("topsis_runs.executed_at DESC")
                                  .first
  end

  private

  def authorize_access!
    return if runs_topsis?
    raise Authorization::Forbidden unless @participant.user_id == current_user&.id
  end
end
