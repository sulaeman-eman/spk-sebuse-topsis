# UC-04 Kelola Data Peserta. Admin Panitia dan Super Admin.
class ParticipantsController < ApplicationController
  before_action :require_committee
  before_action :set_event
  before_action :set_participant, only: %i[edit update destroy]

  def index
    @participants = @event.participants.ordered.includes(:user, :criterion_scores)
  end

  def new
    @participant = @event.participants.new(alternative_code: next_alternative_code)
  end

  def create
    @participant = @event.participants.new(participant_params)

    if @participant.save
      redirect_to event_participants_path(@event),
                  notice: "Peserta #{@participant.name} berhasil ditambahkan."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @participant.update(participant_params)
      redirect_to event_participants_path(@event),
                  notice: "Data #{@participant.name} berhasil diperbarui."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @participant.destroy
    redirect_to event_participants_path(@event),
                notice: "Peserta #{@participant.name} berhasil dihapus."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def set_participant
    @participant = @event.participants.find(params[:id])
  end

  # Kode alternatif berikutnya, mengikuti penomoran A1, A2, dan seterusnya.
  def next_alternative_code
    used = @event.participants.pluck(:alternative_code).filter_map { |code| code[/\d+/]&.to_i }

    "A#{(used.max || 0) + 1}"
  end

  def participant_params
    params.require(:participant).permit(:nip, :name, :department, :alternative_code, :user_id)
  end
end
