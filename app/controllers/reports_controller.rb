# UC-10 Cetak Laporan Peringkat.
#
# Mengambil hasil pemeringkatan, menyerahkannya ke ReportGenerator untuk
# diformat, lalu mengunduhkan berkasnya ke perangkat pengguna.
class ReportsController < ApplicationController
  before_action :require_committee
  before_action :set_event

  def show
    run = @event.topsis_runs.find(params[:id])
    generator = ReportGenerator.new(run)

    # Format ditentukan melalui akhiran berkas pada alamat, misalnya
    # /events/1/laporan/2.xlsx
    case params[:format]
    when "xlsx"
      send_data generator.to_xlsx,
                filename: generator.filename("xlsx"),
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    else
      send_data generator.to_pdf, filename: generator.filename("pdf"), type: "application/pdf"
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end
end
