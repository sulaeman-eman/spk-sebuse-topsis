# UC-06 Pre-processing Data. Mengubah log mentah menjadi matriks keputusan X.
class PreprocessingsController < ApplicationController
  before_action :require_committee
  before_action :set_event

  # Ringkasan log mentah dan pratinjau matriks keputusan hasil pre-processing.
  def show
    @criteria = Criterion.ordered
    @participants = @event.participants.ordered.includes(:activity_logs, :criterion_scores)
  end

  def create
    processed = PreprocessingEngine.new(@event).call

    redirect_to event_preprocessing_path(@event),
                notice: "Pre-processing selesai untuk #{processed} peserta. Matriks keputusan siap dihitung."
  rescue ArgumentError => error
    redirect_to event_preprocessing_path(@event), alert: error.message
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
