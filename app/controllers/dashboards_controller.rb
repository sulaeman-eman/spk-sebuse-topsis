class DashboardsController < ApplicationController
  def show
    @event = Event.order(:start_date).last
    @criteria_balanced = Criterion.weights_balanced?
    @total_weight = Criterion.total_weight

    return unless @event

    @participant_count = @event.participants.count
    @scored_count = @event.participants.joins(:criterion_scores).distinct.count
    @activity_log_count = @event.activity_logs.count
    @latest_run = @event.latest_topsis_run
    @my_participant = @event.participants.find_by(user: current_user)
  end
end
