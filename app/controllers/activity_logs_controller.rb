# Pencatatan log aktivitas fisik peserta. Input manual per baris; unggah berkas
# rekap (UC-05) menyusul.
class ActivityLogsController < ApplicationController
  before_action :require_committee
  before_action :set_participant

  def index
    @activity_logs = @participant.activity_logs.chronological
    @points_per_day = @activity_logs.group_by(&:activity_date)
                                    .transform_values { |logs| logs.sum { |log| log.raw_points.to_f } }
  end

  def new
    @activity_log = @participant.activity_logs.new(
      activity_date: Date.current, activity_type: :cardio, raw_points: 2
    )
  end

  def create
    @activity_log = @participant.activity_logs.new(activity_log_params.merge(source: :manual))

    if @activity_log.save
      redirect_to participant_activity_logs_path(@participant),
                  notice: "Log aktivitas berhasil dicatat."
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @participant.activity_logs.find(params[:id]).destroy
    redirect_to participant_activity_logs_path(@participant), notice: "Log aktivitas dihapus."
  end

  private

  def set_participant
    @participant = Participant.find(params[:participant_id])
  end

  def activity_log_params
    params.require(:activity_log).permit(
      :activity_date, :activity_type, :raw_points, :distance_km, :evidence_url, :evidence_valid
    )
  end
end
