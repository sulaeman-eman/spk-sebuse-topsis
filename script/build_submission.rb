# Menyusun folder pengumpulan/ berisi paket aplikasi yang siap diserahkan.
#
#   ruby script/build_submission.rb
#
# Aplikasi ini berbentuk aplikasi web, sehingga tidak dapat dijadikan satu
# berkas pemasang tunggal. Paket ini karena itu memuat kode sumber, dump basis
# data, panduan, contoh keluaran, serta slot untuk video peragaan.
#
# Folder hasil selalu disusun ulang dari nol, agar isinya tidak pernah bercampur
# dengan sisa penyusunan sebelumnya.

require "fileutils"
require "zip"

ROOT = File.expand_path("..", __dir__)
PACKAGE = File.join(ROOT, "pengumpulan")

# Kode sumber disaring memakai daftar pengecualian tegas, bukan memakai isi
# .gitignore. Alasannya, docs/ dan app_info/ sengaja diabaikan git, padahal
# keduanya justru sumber berkas PDF panduan yang dibutuhkan paket ini.
EXCLUDED_DIRS = %w[
  .git .github node_modules tmp log storage docs app_info pengumpulan
  public/assets vendor/bundle .bundle coverage
].freeze

# config/master.key adalah kunci pembuka config/credentials.yml.enc, sehingga
# tidak boleh ikut diserahkan.
EXCLUDED_FILES = %w[config/master.key .env].freeze
EXCLUDED_EXTENSIONS = %w[.pdf .docx .doc .mp4 .mkv].freeze

def bytes_to_kb(path) = (File.size(path) / 1024.0).round

def excluded?(relative)
  return true if EXCLUDED_DIRS.any? { |dir| relative == dir || relative.start_with?("#{dir}/") }
  return true if EXCLUDED_FILES.include?(relative)

  # Naskah tugas akhir berformat PDF maupun Word berada di direktori utama, dan
  # tidak termasuk kode sumber.
  EXCLUDED_EXTENSIONS.include?(File.extname(relative).downcase) && !relative.include?("/")
end

def source_entries
  Dir.chdir(ROOT) do
    Dir.glob("**/*", File::FNM_DOTMATCH)
       .reject { |path| [ ".", ".." ].include?(File.basename(path)) }
       .reject { |path| excluded?(path) }
       .select { |path| File.file?(path) }
       .sort
  end
end

# Berkas pada direktori bin/ dan berkas berakhiran .sh wajib dapat dieksekusi.
# Izinnya ditetapkan secara tegas, bukan disalin dari berkas asal, karena
# repositori ini berada pada drive Windows yang melaporkan seluruh berkas
# bermode 777 sehingga mode aslinya tidak dapat dijadikan acuan.
def unix_mode(relative)
  relative.start_with?("bin/") || relative.end_with?(".sh") ? 0o755 : 0o644
end

def build_source_zip(target)
  entries = source_entries

  Zip::File.open(target, Zip::File::CREATE) do |zip|
    entries.each do |relative|
      nama = File.join("spk-sebuse", relative)
      zip.add(nama, File.join(ROOT, relative))

      # Tanpa penetapan ini, bin/rails kehilangan bit dapat-eksekusi saat
      # diekstrak pada Linux maupun macOS, dan perintah bin/rails gagal dengan
      # pesan Permission denied.
      berkas = zip.find_entry(nama)
      berkas.fstype = Zip::FSTYPE_UNIX
      berkas.unix_perms = unix_mode(relative)
    end
  end

  entries.size
end

def run(command)
  system(command, exception: true)
end

# ---------- Menyusun folder ----------

FileUtils.rm_rf(PACKAGE)
%w[01-Aplikasi/basis-data 02-Panduan 03-Contoh-Berkas 04-Video-Demo].each do |dir|
  FileUtils.mkdir_p(File.join(PACKAGE, dir))
end

hasil = []

# 1. Kode sumber.
zip_path = File.join(PACKAGE, "01-Aplikasi", "spk-sebuse-source.zip")
jumlah_berkas = build_source_zip(zip_path)
hasil << [ "01-Aplikasi/spk-sebuse-source.zip", bytes_to_kb(zip_path), "#{jumlah_berkas} berkas" ]

# 2. Dump basis data.
dump_path = File.join(PACKAGE, "01-Aplikasi", "basis-data", "spk_sebuse.sql")
run("pg_dump --no-owner --no-privileges --clean --if-exists " \
    "-d spk_sebuse_development -f #{dump_path.inspect}")
hasil << [ "01-Aplikasi/basis-data/spk_sebuse.sql", bytes_to_kb(dump_path), "dump basis data" ]

File.write(File.join(PACKAGE, "01-Aplikasi", "basis-data", "CARA_RESTORE.txt"), <<~TEKS)
  CARA MEMULIHKAN DUMP BASIS DATA

  Dump ini bersifat pilihan. Data yang sama dapat dimuat memakai perintah
  bin/rails db:seed, sebagaimana bagian C berkas CARA_MENJALANKAN.pdf.

  Pulihkan dump dengan dua perintah berikut, dijalankan dari direktori kode
  sumber yang sudah diekstrak.

    bin/rails db:create db:migrate
    psql -d spk_sebuse_development -f basis-data/spk_sebuse.sql

  Dump dibuat tanpa keterangan pemilik dan tanpa hak akses, sehingga dapat
  dipulihkan memakai peran basis data mana pun yang berwenang membuat tabel.

  Periksa hasilnya melalui perintah berikut. Keluarannya adalah 10, 6, dan 60.

    psql -d spk_sebuse_development -c "SELECT COUNT(*) FROM criteria;"
    psql -d spk_sebuse_development -c "SELECT COUNT(*) FROM participants;"
    psql -d spk_sebuse_development -c "SELECT COUNT(*) FROM criterion_scores;"
TEKS

# 3. Panduan yang sudah ada.
PANDUAN = {
  "docs/Pengumpulan/CARA_MENJALANKAN.pdf" => "01-Aplikasi/CARA_MENJALANKAN.pdf",
  "docs/Pengumpulan/BACA_INI_DULU.pdf" => "00-BACA-INI-DULU.pdf",
  "docs/Pengumpulan/CARA_MEREKAM.pdf" => "04-Video-Demo/CARA_MEREKAM.pdf",
  "docs/PanduanPenggunaan/Tata_Cara_Penggunaan.pdf" => "02-Panduan/Tata_Cara_Penggunaan.pdf",
  "app_info/Manual_Book_SPK_SEBUSE.pdf" => "02-Panduan/Manual_Book_SPK_SEBUSE.pdf",
  "app_info/Kredensial_SPK_SEBUSE.pdf" => "02-Panduan/Kredensial_SPK_SEBUSE.pdf"
}.freeze

PANDUAN.each do |sumber, tujuan|
  asal = File.join(ROOT, sumber)
  unless File.exist?(asal)
    abort "Berkas panduan #{sumber} belum ada. Bangun lebih dahulu melalui script/build_manual.rb " \
          "dan script/build_manual_pdf.sh."
  end

  akhir = File.join(PACKAGE, tujuan)
  FileUtils.cp(asal, akhir)
  hasil << [ tujuan, bytes_to_kb(akhir), "panduan" ]
end

# 4. Contoh berkas impor.
csv_asal = File.join(ROOT, "docs/contoh/contoh-impor-log-aktivitas.csv")
csv_tujuan = File.join(PACKAGE, "03-Contoh-Berkas", "contoh-impor-log-aktivitas.csv")
FileUtils.cp(csv_asal, csv_tujuan)
hasil << [ "03-Contoh-Berkas/contoh-impor-log-aktivitas.csv", bytes_to_kb(csv_tujuan), "contoh unggahan" ]

# 5. Contoh keluaran laporan, dihasilkan oleh aplikasi sendiri.
run("bin/rails runner #{File.join(__dir__, 'generate_report_samples_for_package.rb').inspect}")
[ "contoh-laporan-peringkat.pdf", "contoh-laporan-peringkat.xlsx" ].each do |nama|
  berkas = File.join(PACKAGE, "03-Contoh-Berkas", nama)
  abort "Contoh laporan #{nama} gagal dibuat" unless File.exist?(berkas)
  hasil << [ "03-Contoh-Berkas/#{nama}", bytes_to_kb(berkas), "keluaran aplikasi" ]
end

# 6. Penanda folder video.
File.write(File.join(PACKAGE, "04-Video-Demo", "LETAKKAN_VIDEO_DI_SINI.txt"), <<~TEKS)
  Letakkan rekaman peragaan aplikasi pada folder ini, dengan nama
  demo-spk-sebuse.mp4

  Susunan adegan yang perlu direkam terdapat pada berkas CARA_MEREKAM.pdf di
  folder yang sama.
TEKS

# ---------- Ringkasan ----------

puts "\nPaket tersusun pada #{PACKAGE}\n\n"
puts format("%-52s %8s  %s", "BERKAS", "UKURAN", "KETERANGAN")
hasil.each { |nama, kb, catatan| puts format("%-52s %6d KB  %s", nama, kb, catatan) }

total = Dir.glob(File.join(PACKAGE, "**", "*")).select { |f| File.file?(f) }.sum { |f| File.size(f) }
puts format("\nTotal %d berkas, %.1f MB", Dir.glob(File.join(PACKAGE, "**", "*")).count { |f| File.file?(f) },
            total / 1_048_576.0)
