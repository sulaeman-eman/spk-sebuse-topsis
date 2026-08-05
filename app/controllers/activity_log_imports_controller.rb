# UC-05 Import Log Activities.
class ActivityLogImportsController < ApplicationController
  before_action :require_committee
  before_action :set_event

  def new
    @batches = recent_batches
  end

  def create
    result = ActivityLogImport.new(@event, file: params[:file]).call

    if result.success?
      redirect_to new_event_activity_log_import_path(@event),
                  notice: "#{result.imported} baris log aktivitas berhasil diimpor."
    else
      # Seluruh berkas ditolak agar tidak ada data setengah masuk.
      @batches = recent_batches
      @errors = result.errors
      flash.now[:alert] = "Impor dibatalkan. #{result.errors.size} baris tidak memenuhi ketentuan."
      render :new, status: :unprocessable_content
    end
  rescue ActivityLogImport::InvalidFile => error
    @batches = recent_batches
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_content
  end

  # Membatalkan satu batch unggahan beserta seluruh barisnya.
  def destroy
    logs = ActivityLog.where(import_batch_id: params[:id], participant: @event.participants)
    count = logs.count
    logs.destroy_all

    redirect_to new_event_activity_log_import_path(@event),
                notice: "#{count} baris dari satu batch impor berhasil dibatalkan."
  end

  # Contoh berkas acuan penulisan kolom.
  def template
    send_data ActivityLogImport.template_csv,
              filename: "template-log-aktivitas-sebuse.csv",
              type: "text/csv"
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  # Ringkasan tiap batch impor: jumlah baris, waktu, dan rentang tanggal.
  def recent_batches
    ActivityLog.where(participant: @event.participants)
               .where.not(import_batch_id: nil)
               .group(:import_batch_id)
               .pluck(
                 :import_batch_id,
                 Arel.sql("COUNT(*)"),
                 Arel.sql("MIN(created_at)"),
                 Arel.sql("MIN(activity_date)"),
                 Arel.sql("MAX(activity_date)")
               )
               .map { |row| { id: row[0], rows: row[1], at: row[2], from: row[3], to: row[4] } }
               .sort_by { |batch| batch[:at] }
               .reverse
  end
end
