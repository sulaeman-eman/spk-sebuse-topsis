# Pengaturan periode event beserta parameter regulasi SEBUSE yang dipakai
# mesin pre-processing.
class EventsController < ApplicationController
  before_action :require_committee, except: %i[index show]
  before_action :set_event, only: %i[show edit update]

  def index
    @events = Event.order(start_date: :desc)
  end

  def show
    @participant_count = @event.participants.count
    @latest_run = @event.latest_topsis_run
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to event_path(@event), notice: "Parameter regulasi event berhasil diperbarui."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :name, :start_date, :end_date,
      :target_cardio, :target_strength, :total_weeks, :daily_point_cap,
      :streak_penalty_per_violation, :long_run_target_km,
      :weekly_cardio_target, :weekly_strength_target,
      :bonus_cardio_target, :bonus_strength_target,
      :max_consecutive_cardio_days, :fun_sport_point_target
    )
  end
end
