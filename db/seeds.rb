# Data awal SPK SEBUSE. Idempoten, aman dijalankan berulang.
#
# Dua kelompok data yang sengaja dipisah:
#   1. Lima peserta Bab IV beserta matriks keputusan X halaman 42, dipakai untuk
#      membuktikan output sistem sama dengan hitungan manual di skripsi.
#   2. Satu peserta demo beserta log aktivitas mentah, dipakai untuk
#      mendemokan PreprocessingEngine (pemangkasan kuota dan penalti beruntun).

# --- 10 kriteria beserta bobot tabel 3.2 (revisi) ---------------------------
#
# Tabel 3.2 versi awal menjumlah 105%, sedangkan baris Total menyatakan 100%
# dan UC-03 mewajibkan akumulasi bobot tepat 100%. Bobot C7 diturunkan dari
# 10% ke 5% agar totalnya benar-benar 1,00. Urutan peringkat Bab IV tidak
# berubah oleh koreksi ini.

CRITERIA = [
  { code: "C1",  name: "Total Poin Cardio",                              weight: 0.20 },
  { code: "C2",  name: "Total Poin Strength",                            weight: 0.15 },
  { code: "C3",  name: "Ketuntasan Long Run (Wajib 10 KM)",              weight: 0.15 },
  { code: "C4",  name: "Syarat Mingguan (Kepatuhan minimal sesi)",       weight: 0.10 },
  { code: "C5",  name: "Bonus Mingguan (Apresiasi performa lebih)",      weight: 0.10 },
  { code: "C6",  name: "Aturan Beruntun (Pencegahan overtraining)",      weight: 0.10 },
  { code: "C7",  name: "Hasil Pengukuran Akhir (Progres Fisik/BMI)",     weight: 0.05 },
  { code: "C8",  name: "Poin Fun Sports (Aktivitas Opsional)",           weight: 0.05 },
  { code: "C9",  name: "Disiplin Harian (Kepatuhan kuota poin harian)",  weight: 0.05 },
  { code: "C10", name: "Kualitas Evidence (Validitas link & foto)",      weight: 0.05 }
].freeze

CRITERIA.each_with_index do |attributes, index|
  Criterion.find_or_initialize_by(code: attributes[:code]).update!(
    name: attributes[:name],
    weight: attributes[:weight],
    criterion_type: :benefit,
    position: index + 1
  )
end

raise "total bobot kriteria bukan 100%" unless Criterion.weights_balanced?

# --- Event ------------------------------------------------------------------

event = Event.find_or_initialize_by(name: "SEBUSE 2026")
event.update!(
  start_date: Date.new(2026, 3, 2),
  end_date: Date.new(2026, 3, 29),
  target_cardio: 24,
  target_strength: 16,
  total_weeks: 4,
  daily_point_cap: 4,
  streak_penalty_per_violation: 25,
  long_run_target_km: 10
)

# --- Akun tiga aktor --------------------------------------------------------

[
  { email_address: "superadmin@cahayasuarautama.co.id", name: "Super Admin",  role: :super_admin },
  { email_address: "panitia@cahayasuarautama.co.id",    name: "Admin Panitia", role: :admin_panitia },
  { email_address: "peserta@cahayasuarautama.co.id",    name: "Peserta Demo",  role: :peserta }
].each do |attributes|
  user = User.find_or_initialize_by(email_address: attributes[:email_address])
  user.name = attributes[:name]
  user.role = attributes[:role]
  user.password = "sebuse2026" if user.new_record?
  user.save!
end

# --- Lima peserta Bab IV dan matriks keputusan X halaman 42 -----------------

DECISION_MATRIX = {
  "A1" => { name: "Budi",  nip: "CSU-0001", department: "Produksi",
            values: [ 85, 80, 100,  90, 85,  90, 80, 75,  90,  95 ] },
  "A2" => { name: "Andi",  nip: "CSU-0002", department: "Teknik",
            values: [ 90, 85, 100,  95, 90,  80, 85, 80,  95,  90 ] },
  "A3" => { name: "Citra", nip: "CSU-0003", department: "Keuangan",
            values: [ 70, 75,  80,  70, 65, 100, 75, 60,  80,  85 ] },
  "A4" => { name: "Dedi",  nip: "CSU-0004", department: "Umum",
            values: [ 60, 65,  50,  60, 50,  70, 65, 50,  70,  75 ] },
  "A5" => { name: "Eka",   nip: "CSU-0005", department: "Pemasaran",
            values: [ 95, 90, 100, 100, 95,  85, 90, 90, 100, 100 ] }
}.freeze

criteria = Criterion.ordered.to_a

DECISION_MATRIX.each do |code, attributes|
  participant = Participant.find_or_initialize_by(event: event, alternative_code: code)
  participant.update!(
    nip: attributes[:nip],
    name: attributes[:name],
    department: attributes[:department]
  )

  criteria.each_with_index do |criterion, index|
    score = CriterionScore.find_or_initialize_by(participant: participant, criterion: criterion)
    score.update!(
      raw_value: attributes[:values][index],
      normalized_value: attributes[:values][index],
      notes: "Nilai simulasi Bab IV halaman 42"
    )
  end
end

# Akun peserta contoh ditautkan ke salah satu alternatif agar UC-09 Detail Skor
# Individu langsung dapat dicoba tanpa penyiapan tambahan.
if (peserta = User.find_by(role: :peserta))
  Participant.find_by(event: event, alternative_code: "A1")&.update!(user: peserta)
end

# --- Peserta demo pre-processing --------------------------------------------
#
# Ditaruh pada event terpisah supaya event SEBUSE 2026 tetap berisi tepat lima
# alternatif seperti Bab IV, sehingga peringkatnya bisa dibandingkan angka per
# angka dengan tabel halaman 47.
#
# Log dirancang mengandung dua kondisi yang disebut di regulasi:
#   - 4 Maret total 6 poin, melampaui kuota harian sehingga dipangkas ke 4
#   - 16-19 Maret cardio empat hari berturut-turut, satu rentetan pelanggaran

demo_event = Event.find_or_initialize_by(name: "SEBUSE 2026 (demo pre-processing)")
demo_event.update!(
  start_date: Date.new(2026, 3, 2),
  end_date: Date.new(2026, 3, 29)
)

demo = Participant.find_or_initialize_by(event: demo_event, alternative_code: "A1")
demo.update!(nip: "CSU-0006", name: "Fajar", department: "Operasional")
demo.activity_logs.destroy_all

DEMO_LOGS = [
  # tanggal,    tipe,        poin, km,   bukti valid
  [ "2026-03-02", :cardio,    2, nil,  true  ],
  [ "2026-03-04", :cardio,    4, nil,  true  ],   # bersama baris berikut = 6 poin
  [ "2026-03-04", :strength,  2, nil,  true  ],   # sehari, dipangkas jadi 4
  [ "2026-03-06", :strength,  2, nil,  true  ],
  [ "2026-03-08", :long_run,  3, 10.5, true  ],
  [ "2026-03-10", :cardio,    2, nil,  false ],
  [ "2026-03-12", :strength,  2, nil,  true  ],
  [ "2026-03-14", :fun_sport, 1, nil,  true  ],
  [ "2026-03-16", :cardio,    2, nil,  true  ],   # cardio empat hari
  [ "2026-03-17", :cardio,    2, nil,  true  ],   # berturut-turut, melebihi
  [ "2026-03-18", :cardio,    2, nil,  false ],   # batas 3 hari sehingga
  [ "2026-03-19", :cardio,    2, nil,  true  ],   # dihitung 1 pelanggaran
  [ "2026-03-22", :long_run,  3, 11.2, true  ],
  [ "2026-03-24", :cardio,    2, nil,  true  ],
  [ "2026-03-26", :strength,  2, nil,  true  ]
].freeze

DEMO_LOGS.each do |date, type, points, distance, evidence_valid|
  demo.activity_logs.create!(
    activity_date: Date.parse(date),
    activity_type: type,
    raw_points: points,
    distance_km: distance,
    evidence_url: "https://medicalrjbb.com/logs/#{date}",
    evidence_valid: evidence_valid,
    source: :manual
  )
end

PreprocessingEngine.new(demo_event.reload).call

puts "Seed selesai:"
puts "  kriteria             : #{Criterion.count} (total bobot #{Criterion.total_weight})"
puts "  peserta SEBUSE 2026  : #{event.participants.count}"
puts "  peserta demo         : #{demo_event.participants.count}"
puts "  log aktivitas        : #{ActivityLog.count}"
puts "  skor kriteria        : #{CriterionScore.count}"
