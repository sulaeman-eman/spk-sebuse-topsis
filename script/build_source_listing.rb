# Menyusun satu berkas teks berisi seluruh kode sumber aplikasi, siap disalin
# ke naskah Word sebagai lampiran "Listing Program".
#
#   ruby script/build_source_listing.rb
#
# Tata letaknya mengikuti lampiran listing program pada naskah acuan: setiap
# berkas menjadi satu butir berhuruf, dan setiap baris kode diberi nomor yang
# dimulai kembali dari satu pada tiap berkas. Keluaran berupa teks biasa tanpa
# hiasan, agar gaya huruf tetap ditentukan oleh Word.

ROOT = File.expand_path("..", __dir__)
OUTPUT = File.join(ROOT, "pengumpulan", "05-Kode-Sumber", "Lampiran_Listing_Program.txt")

# Berkas diurutkan menurut lapisan aplikasi, bukan menurut abjad, agar lampiran
# terbaca mengikuti alur bab perancangan: konfigurasi, basis data, model,
# logika bisnis, pengendali, tampilan, lalu pengujian.
ORDER = %w[
  Gemfile
  config/routes.rb
  config/application.rb
  config/database.yml
  config/importmap.rb
  config/locales/id.yml
  db/schema.rb
  db/migrate
  db/seeds.rb
  app/models
  app/services
  app/controllers
  app/helpers
  app/mailers
  app/views
  app/assets/stylesheets/application.css
  app/javascript
  spec
].freeze

EXCLUDED_EXTENSIONS = %w[.png .jpg .jpeg .gif .ico .svg .pdf .docx .xlsx .zip .enc].freeze

# Keterangan berkas dituliskan tegas untuk berkas inti, karena nama berkas saja
# belum menjelaskan perannya kepada pembaca naskah.
DESCRIPTIONS = {
  "Gemfile" => "Daftar Pustaka dan Ketergantungan Aplikasi",
  "config/routes.rb" => "Peta Rute Aplikasi",
  "config/application.rb" => "Konfigurasi Utama Aplikasi",
  "config/database.yml" => "Konfigurasi Sambungan Basis Data",
  "config/importmap.rb" => "Pemetaan Modul JavaScript",
  "config/locales/id.yml" => "Berkas Terjemahan Bahasa Indonesia",
  "db/schema.rb" => "Skema Basis Data",
  "db/seeds.rb" => "Data Awal Basis Data",
  "app/models/activity_log.rb" => "Model Log Aktivitas",
  "app/models/criterion.rb" => "Model Kriteria Penilaian",
  "app/models/criterion_score.rb" => "Model Nilai Kriteria Peserta",
  "app/models/current.rb" => "Model Konteks Permintaan Berjalan",
  "app/models/event.rb" => "Model Kegiatan",
  "app/models/participant.rb" => "Model Peserta",
  "app/models/ranking_result.rb" => "Model Hasil Peringkat",
  "app/models/session.rb" => "Model Sesi Masuk",
  "app/models/topsis_run.rb" => "Model Penghitungan TOPSIS",
  "app/models/user.rb" => "Model Pengguna",
  "app/models/application_record.rb" => "Kelas Induk Seluruh Model",
  "app/services/activity_log_import.rb" => "Layanan Impor Log Aktivitas dari CSV",
  "app/services/preprocessing_engine.rb" => "Mesin Praolah Data Aktivitas",
  "app/services/report_generator.rb" => "Pembangkit Laporan Peringkat",
  "app/services/topsis_engine.rb" => "Mesin Perhitungan Metode TOPSIS",
  "app/services/topsis_run_creator.rb" => "Layanan Pembuatan Penghitungan TOPSIS",
  "app/controllers/application_controller.rb" => "Kelas Induk Seluruh Pengendali",
  "app/controllers/concerns/authentication.rb" => "Modul Autentikasi Pengguna",
  "app/controllers/concerns/authorization.rb" => "Modul Hak Akses Pengguna",
  "app/controllers/sessions_controller.rb" => "Pengendali Masuk dan Keluar",
  "app/controllers/passwords_controller.rb" => "Pengendali Lupa Kata Sandi",
  "app/controllers/users_controller.rb" => "Pengendali Manajemen Pengguna",
  "app/controllers/dashboards_controller.rb" => "Pengendali Dasbor",
  "app/controllers/events_controller.rb" => "Pengendali Kegiatan",
  "app/controllers/criteria_controller.rb" => "Pengendali Kriteria Penilaian",
  "app/controllers/participants_controller.rb" => "Pengendali Peserta",
  "app/controllers/activity_logs_controller.rb" => "Pengendali Log Aktivitas",
  "app/controllers/activity_log_imports_controller.rb" => "Pengendali Impor Log Aktivitas",
  "app/controllers/preprocessings_controller.rb" => "Pengendali Praolah Data",
  "app/controllers/scores_controller.rb" => "Pengendali Nilai Kriteria",
  "app/controllers/topsis_runs_controller.rb" => "Pengendali Perhitungan TOPSIS",
  "app/controllers/leaderboards_controller.rb" => "Pengendali Papan Peringkat",
  "app/controllers/reports_controller.rb" => "Pengendali Unduhan Laporan"
}.freeze

def tracked_files
  @tracked_files ||= Dir.chdir(ROOT) { `git ls-files`.lines.map(&:chomp) }
end

def files_for(entry)
  matches = tracked_files.select { |path| path == entry || path.start_with?("#{entry}/") }
  matches.reject { |path| EXCLUDED_EXTENSIONS.include?(File.extname(path).downcase) }.sort
end

# Huruf butir mengikuti pola a, b, ... z, lalu aa, ab, dan seterusnya, karena
# jumlah berkas aplikasi ini melampaui dua puluh enam.
def bullet(index)
  letters = ("a".."z").to_a
  base = letters.size
  label = +""
  number = index
  loop do
    label.prepend(letters[number % base])
    number = number / base - 1
    break if number < 0
  end
  label
end

# Keterangan berkas yang tidak tercantum tegas diturunkan dari jalurnya, agar
# berkas baru tetap memperoleh judul yang masuk akal tanpa menyunting daftar.
def description(path)
  return DESCRIPTIONS[path] if DESCRIPTIONS.key?(path)

  name = File.basename(path).sub(/\..*\z/, "")
  human = name.delete_prefix("_").tr("_", " ").split.map(&:capitalize).join(" ")

  case path
  when %r{\Adb/migrate/}
    # Nama berkas migrasi selalu diawali cap waktu, yang tidak perlu ikut
    # tampil pada judul butir lampiran.
    "Migrasi Basis Data: #{human.sub(/\A\d+ /, '').sub(/\ACreate /, 'Tabel ').sub(/\AAdd /, 'Penambahan Kolom ')}"
  when %r{\Aapp/views/}
    folder = File.dirname(path).split("/").last.tr("_", " ").split.map(&:capitalize).join(" ")
    "Tampilan #{folder}: #{human}"
  when %r{\Aspec/} then "Pengujian #{human.sub(/ Spec\z/, '')}"
  when %r{\Aapp/javascript/} then "Berkas JavaScript: #{human}"
  when %r{\Aapp/assets/} then "Berkas Gaya Tampilan"
  when %r{\Aapp/mailers/} then "Pengirim Surel: #{human}"
  when %r{\Aapp/helpers/} then "Pembantu Tampilan: #{human}"
  else human
  end
end

# Jalur ditulis dengan huruf awal kapital, mengikuti gaya penulisan judul butir
# pada lampiran naskah acuan.
def titled_path(path) = path.sub(/\A([a-z])/) { $1.upcase }

files = ORDER.flat_map { |entry| files_for(entry) }.uniq

out = +""
out << "LAMPIRAN\n\n"
out << "Listing Program\n\n"
out << "Aplikasi Sistem Pendukung Keputusan Pemilihan Peserta Terbaik (SPK SEBUSE)\n"
out << "dibangun memakai kerangka kerja Ruby on Rails. Seluruh #{files.size} berkas kode\n"
out << "sumbernya dilampirkan berikut ini, berurutan dari lapisan konfigurasi hingga\n"
out << "lapisan pengujian.\n\n"

files.each_with_index do |path, index|
  out << "\n#{bullet(index)}. #{titled_path(path)} (#{description(path)})\n\n"

  # Spasi di ujung baris dibuang karena Word menampilkannya sebagai lebar
  # kolom yang tidak rata ketika teks ditempel ke dalam kotak kode.
  lines = File.read(File.join(ROOT, path)).gsub(/[ \t]+$/, "").split("\n", -1)
  lines.pop while lines.last == ""

  lines.each_with_index do |line, number|
    out << format("%5d)  %s\n", number + 1, line).gsub(/\s+\z/, "\n")
  end
end

Dir.mkdir(File.dirname(OUTPUT)) unless Dir.exist?(File.dirname(OUTPUT))
File.write(OUTPUT, out)

puts "#{OUTPUT} tersusun (#{files.size} berkas, #{(File.size(OUTPUT) / 1024.0).round} KB)."
