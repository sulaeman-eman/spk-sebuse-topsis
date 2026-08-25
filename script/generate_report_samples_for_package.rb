# Menghasilkan sepasang contoh keluaran laporan untuk paket pengumpulan.
#
#   bin/rails runner script/generate_report_samples_for_package.rb
#
# Berkas dihasilkan oleh ReportGenerator yang dipakai fitur UC-10, sehingga
# contohnya benar-benar keluaran aplikasi, bukan berkas yang disusun manual.
# Skrip ini dipanggil oleh script/build_submission.rb.

TUJUAN = Rails.root.join("pengumpulan/03-Contoh-Berkas")

event = Event.order(:start_date).last
abort "Belum ada event. Jalankan bin/rails db:seed lebih dahulu." if event.nil?

run = event.latest_topsis_run || TopsisRunCreator.new(
  event, executed_by: User.find_by(role: :admin_panitia)
).call

generator = ReportGenerator.new(run)

FileUtils.mkdir_p(TUJUAN)
File.binwrite(TUJUAN.join("contoh-laporan-peringkat.pdf"), generator.to_pdf)
File.binwrite(TUJUAN.join("contoh-laporan-peringkat.xlsx"), generator.to_xlsx)

juara = run.winner
puts "Contoh laporan dibuat dari perhitungan #{run.executed_at.strftime('%d-%m-%Y %H:%M')}, " \
     "juara 1 #{juara.participant.name} dengan nilai #{format('%.4f', juara.preference_value)}"
