# UC-08 Lihat Papan Peringkat. Terbuka untuk seluruh aktor, termasuk Peserta,
# sebagai wujud transparansi hasil kompetisi.
class LeaderboardsController < ApplicationController
  def show
    @event = Event.find(params[:event_id])
    @topsis_run = @event.latest_topsis_run
    @ranking_results =
      if @topsis_run
        @topsis_run.ranking_results.leaderboard.includes(participant: :user)
      else
        RankingResult.none
      end
    @my_result = @ranking_results.find { |result| result.participant.user_id == current_user&.id }
  end
end
