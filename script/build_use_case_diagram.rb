# Menghasilkan docs/diagram/use-case.svg, yaitu use case diagram hasil revisi
# yang disesuaikan dengan sistem yang benar-benar dibangun.
#
# Diagram digambar langsung sebagai SVG karena lingkungan pengembangan tidak
# memuat PlantUML maupun Graphviz. Seluruh titik koordinat dihitung oleh berkas
# ini, sehingga tata letaknya dapat disesuaikan dengan mengubah tetapan di bawah.
#
#   ruby script/build_use_case_diagram.rb

TARGET = File.expand_path("../docs/diagram/use-case.svg", __dir__)

WIDTH = 1060
HEIGHT = 1130

# Batas sistem (system boundary).
BOUNDARY = { x: 555, y: 40, width: 455, height: 1050 }

# Elips use case.
UC_CX = 782
UC_RX = 185
UC_RY = 26

# Aktor digambar pada satu lajur di sebelah kiri batas sistem.
ACTOR_X = 110

USE_CASES = [
  { code: "UC-02", name: "Kelola Data Pengguna",        cy: 82 },
  { code: "UC-03", name: "Kelola Kriteria dan Bobot",   cy: 154 },
  { code: "UC-11", name: "Kelola Aturan Event",         cy: 226 },
  { code: "UC-04", name: "Kelola Data Peserta",         cy: 298 },
  { code: "UC-05", name: "Impor Log Aktivitas",         cy: 370 },
  { code: "UC-12", name: "Catat Log Aktivitas Manual",  cy: 442 },
  { code: "UC-06", name: "Pre-processing Data",         cy: 514 },
  { code: "UC-07", name: "Hitung Metode TOPSIS",        cy: 586 },
  { code: "UC-13", name: "Lihat Rincian Komputasi",     cy: 686 },
  { code: "UC-10", name: "Cetak Laporan Peringkat",     cy: 786 },
  { code: "UC-08", name: "Lihat Papan Peringkat",       cy: 886 },
  { code: "UC-09", name: "Lihat Detail Skor Individu",  cy: 958 },
  { code: "UC-01", name: "Login",                       cy: 1030 }
].freeze

ACTORS = [
  { name: "Super Admin",       cy: 140 },
  { name: "Admin Panitia",     cy: 520 },
  { name: "Peserta (Karyawan)", cy: 960 }
].freeze

# Asosiasi hanya dituliskan untuk kemampuan yang khas setiap aktor. Kemampuan
# Admin Panitia tidak diulang pada Super Admin karena keduanya sudah dihubungkan
# oleh relasi generalisasi.
ASSOCIATIONS = {
  "Super Admin" => %w[UC-02 UC-03],
  "Admin Panitia" => %w[UC-11 UC-04 UC-05 UC-12 UC-06 UC-07 UC-10 UC-08 UC-09 UC-01],
  "Peserta (Karyawan)" => %w[UC-08 UC-09 UC-01]
}.freeze

def use_case(code)
  USE_CASES.find { |item| item[:code] == code } or raise ArgumentError, "#{code} tidak ada"
end

def actor(name)
  ACTORS.find { |item| item[:name] == name } or raise ArgumentError, "#{name} tidak ada"
end

svg = []

svg << %(<svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}" viewBox="0 0 #{WIDTH} #{HEIGHT}" font-family="Arial, Helvetica, sans-serif">)
svg << <<~DEFS
  <defs>
    <marker id="panah-terbuka" viewBox="0 0 12 12" refX="11" refY="6"
            markerWidth="12" markerHeight="12" orient="auto-start-reverse">
      <path d="M 1 1 L 11 6 L 1 11" fill="none" stroke="#1a1a1a" stroke-width="1.4"/>
    </marker>
    <marker id="segitiga-generalisasi" viewBox="0 0 14 14" refX="13" refY="7"
            markerWidth="14" markerHeight="14" orient="auto-start-reverse">
      <path d="M 1 1 L 13 7 L 1 13 z" fill="#ffffff" stroke="#1a1a1a" stroke-width="1.4"/>
    </marker>
  </defs>
DEFS

svg << %(<rect width="#{WIDTH}" height="#{HEIGHT}" fill="#ffffff"/>)

# Batas sistem beserta namanya.
svg << %(<rect x="#{BOUNDARY[:x]}" y="#{BOUNDARY[:y]}" width="#{BOUNDARY[:width]}" ) +
       %(height="#{BOUNDARY[:height]}" fill="none" stroke="#1a1a1a" stroke-width="1.6"/>)
svg << %(<text x="#{BOUNDARY[:x] + BOUNDARY[:width] / 2}" y="#{BOUNDARY[:y] - 12}" ) +
       %(text-anchor="middle" font-size="17" font-weight="bold">Sistem Pendukung Keputusan SEBUSE (TOPSIS)</text>)

# Garis asosiasi digambar lebih dahulu agar tertutup oleh elips dan aktor.
ASSOCIATIONS.each do |actor_name, codes|
  source = actor(actor_name)

  codes.each do |code|
    target = use_case(code)
    svg << %(<line x1="#{ACTOR_X + 34}" y1="#{source[:cy]}" x2="#{UC_CX - UC_RX}" ) +
           %(y2="#{target[:cy]}" stroke="#55677d" stroke-width="1.2"/>)
  end
end

# Relasi generalisasi antar aktor: Super Admin mewarisi seluruh kemampuan
# Admin Panitia.
atas = actor("Super Admin")
bawah = actor("Admin Panitia")
svg << %(<line x1="#{ACTOR_X}" y1="#{atas[:cy] + 62}" x2="#{ACTOR_X}" y2="#{bawah[:cy] - 46}" ) +
       %(stroke="#1a1a1a" stroke-width="1.4" marker-end="url(#segitiga-generalisasi)"/>)
svg << %(<text x="#{ACTOR_X + 10}" y="#{(atas[:cy] + bawah[:cy]) / 2}" font-size="14" ) +
       %(font-style="italic" fill="#55677d">generalization</text>)

# Elips use case.
USE_CASES.each do |item|
  svg << %(<ellipse cx="#{UC_CX}" cy="#{item[:cy]}" rx="#{UC_RX}" ry="#{UC_RY}" ) +
         %(fill="#eef3f8" stroke="#1a1a1a" stroke-width="1.4"/>)
  svg << %(<text x="#{UC_CX}" y="#{item[:cy] + 5}" text-anchor="middle" font-size="15">) +
         %(#{item[:code]}: #{item[:name]}</text>)
end

# Relasi include: UC-07 selalu menampilkan rincian komputasi (UC-13).
sumber = use_case("UC-07")
tujuan = use_case("UC-13")
svg << %(<line x1="#{UC_CX}" y1="#{sumber[:cy] + UC_RY}" x2="#{UC_CX}" y2="#{tujuan[:cy] - UC_RY}" ) +
       %(stroke="#1a1a1a" stroke-width="1.3" stroke-dasharray="7 5" marker-end="url(#panah-terbuka)"/>)
svg << %(<text x="#{UC_CX + 12}" y="#{(sumber[:cy] + tujuan[:cy]) / 2 + 5}" font-size="15" ) +
       %(font-style="italic">&#171;include&#187;</text>)

# Relasi extend: UC-10 merupakan perluasan pilihan dari UC-08.
sumber = use_case("UC-10")
tujuan = use_case("UC-08")
svg << %(<line x1="#{UC_CX}" y1="#{sumber[:cy] + UC_RY}" x2="#{UC_CX}" y2="#{tujuan[:cy] - UC_RY}" ) +
       %(stroke="#1a1a1a" stroke-width="1.3" stroke-dasharray="7 5" marker-end="url(#panah-terbuka)"/>)
svg << %(<text x="#{UC_CX + 12}" y="#{(sumber[:cy] + tujuan[:cy]) / 2 + 5}" font-size="15" ) +
       %(font-style="italic">&#171;extend&#187;</text>)

# Gambar aktor berupa tokoh garis.
ACTORS.each do |item|
  cy = item[:cy]
  svg << %(<g stroke="#1a1a1a" stroke-width="1.6" fill="none">)
  svg << %(<circle cx="#{ACTOR_X}" cy="#{cy - 34}" r="13" fill="#ffffff"/>)
  svg << %(<line x1="#{ACTOR_X}" y1="#{cy - 21}" x2="#{ACTOR_X}" y2="#{cy + 14}"/>)
  svg << %(<line x1="#{ACTOR_X - 22}" y1="#{cy - 6}" x2="#{ACTOR_X + 22}" y2="#{cy - 6}"/>)
  svg << %(<line x1="#{ACTOR_X}" y1="#{cy + 14}" x2="#{ACTOR_X - 18}" y2="#{cy + 42}"/>)
  svg << %(<line x1="#{ACTOR_X}" y1="#{cy + 14}" x2="#{ACTOR_X + 18}" y2="#{cy + 42}"/>)
  svg << %(</g>)
  svg << %(<text x="#{ACTOR_X}" y="#{cy + 60}" text-anchor="middle" font-size="15" ) +
         %(font-weight="bold">#{item[:name]}</text>)
end

svg << "</svg>"

File.write(TARGET, "#{svg.join("\n")}\n")

puts "#{TARGET} (#{USE_CASES.size} use case, #{ACTORS.size} aktor, " \
     "#{ASSOCIATIONS.values.sum(&:size)} asosiasi)"
