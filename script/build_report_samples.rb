# Menghasilkan empat berkas laporan PDF contoh untuk dokumentasi (UC-10).
#
#   bin/rails runner script/build_report_samples.rb
#
# Keempat laporan berasal dari empat perhitungan TOPSIS pada event yang sama,
# dengan daftar peserta yang sama namun capaian yang berbeda, sehingga urutan
# peringkatnya berbeda pula. Susunan tersebut memperlihatkan bahwa peringkat
# ditentukan oleh angka capaian, bukan oleh urutan pendaftaran peserta.
#
# Seluruh pekerjaan dijalankan di dalam satu transaksi yang selalu dibatalkan,
# sehingga basis data tidak berubah sedikit pun. Berkas PDF sudah tertulis ke
# disk sebelum pembatalan terjadi, karena penulisan berkas berada di luar
# jangkauan transaksi.

OUTPUT_DIR = Rails.root.join("tmp/laporan-contoh")

EVENT_NAME = "SEBUSE 2026".freeze

# Nama peserta sengaja sama pada keempat perhitungan. Yang berubah hanya nilai
# capaiannya, sehingga peringkatnya ikut berubah.
VARIANTS = [
  {
    label: "1",
    executed_at: Time.zone.local(2026, 8, 6, 4, 3),
    note: "Perhitungan pertama, angkanya sama dengan contoh perhitungan manual Bab IV",
    scores: {
      "A1" => [ 85, 80, 100,  90, 85,  90, 80, 75,  90,  95 ],
      "A2" => [ 90, 85, 100,  95, 90,  80, 85, 80,  95,  90 ],
      "A3" => [ 70, 75,  80,  70, 65, 100, 75, 60,  80,  85 ],
      "A4" => [ 60, 65,  50,  60, 50,  70, 65, 50,  70,  75 ],
      "A5" => [ 95, 90, 100, 100, 95,  85, 90, 90, 100, 100 ]
    }
  },
  {
    label: "2",
    executed_at: Time.zone.local(2026, 8, 6, 9, 15),
    note: "Budi naik ke peringkat pertama, Andi turun ke peringkat keempat",
    scores: {
      "A1" => [ 100, 95, 100, 100, 95,  90, 90, 90, 100, 100 ],
      "A2" => [  75, 75,  50,  80, 75,  80, 75, 70,  80,  85 ],
      "A3" => [  85, 80, 100,  85, 80, 100, 80, 75,  85,  90 ],
      "A4" => [  65, 60,  50,  65, 60,  70, 65, 75,  70,  75 ],
      "A5" => [  90, 90, 100,  95, 90,  85, 85, 85,  95,  95 ]
    }
  },
  {
    label: "3",
    executed_at: Time.zone.local(2026, 8, 7, 10, 40),
    note: "Citra naik ke peringkat pertama, Dedi menyusul di peringkat kedua",
    scores: {
      "A1" => [ 70, 70,  50,  75, 70,  80, 70, 65,  75,  80 ],
      "A2" => [ 60, 65,  50,  65, 55,  70, 60, 55,  65,  85 ],
      "A3" => [ 95, 90, 100, 100, 95,  95, 90, 85, 100,  80 ],
      "A4" => [ 90, 85, 100,  95, 85,  90, 85, 80,  90,  75 ],
      "A5" => [ 80, 80, 100,  85, 75, 100, 80, 75,  85,  70 ]
    }
  },
  {
    label: "4",
    executed_at: Time.zone.local(2026, 8, 10, 8, 5),
    note: "Andi naik ke peringkat pertama, Citra turun ke peringkat kelima",
    scores: {
      "A1" => [  85, 80, 100,  85, 80,  85, 75, 75,  85,  85 ],
      "A2" => [ 100, 95, 100, 100, 95,  90, 90, 90, 100,  95 ],
      "A3" => [  65, 60,  50,  60, 55,  70, 60, 55,  65,  90 ],
      "A4" => [  90, 90, 100,  90, 85, 100, 85, 80,  90,  85 ],
      "A5" => [  75, 70,  50,  75, 70,  80, 70, 65,  75,  80 ]
    }
  }
].freeze

event = Event.find_by!(name: EVENT_NAME)
criteria = Criterion.ordered.to_a
committee = User.find_by(role: :admin_panitia) or abort "akun panitia belum ada, jalankan bin/rails db:seed"

FileUtils.mkdir_p(OUTPUT_DIR)

ActiveRecord::Base.transaction do
  # Nama akun disesuaikan dengan penamaan aktor hasil revisi, agar baris
  # "Dihitung oleh" pada laporan contoh terbaca Panitia. Perubahan ini ikut
  # dibatalkan bersama transaksi, sehingga data akun yang tersimpan tetap utuh.
  committee.update!(name: "Panitia")

  VARIANTS.each do |variant|
    variant[:scores].each do |code, values|
      participant = event.participants.find_by!(alternative_code: code)

      criteria.each_with_index do |criterion, index|
        score = CriterionScore.find_or_initialize_by(participant: participant, criterion: criterion)
        score.update!(
          raw_value: values[index],
          normalized_value: values[index],
          notes: "Nilai contoh laporan perhitungan ke-#{variant[:label]}"
        )
      end
    end

    run = TopsisRunCreator.new(event.reload, executed_by: committee).call
    run.update!(executed_at: variant[:executed_at])

    generator = ReportGenerator.new(run.reload)
    path = OUTPUT_DIR.join("laporan-#{variant[:label]}.pdf")
    File.binwrite(path, generator.to_pdf)

    urutan = run.ranking_results.leaderboard.includes(:participant).map do |result|
      "#{result.rank}. #{result.participant.name}"
    end

    puts "#{path.basename} #{urutan.join('  ')}"
  end

  raise ActiveRecord::Rollback
end

puts "Basis data tidak berubah, seluruh perubahan dibatalkan setelah berkas tertulis."
puts "Berkas tersimpan pada #{OUTPUT_DIR}"
