# Mengubah dokumen Markdown di docs/ menjadi HTML yang siap dicetak ke PDF.
# Penerjemahnya sengaja hanya menangani penulisan Markdown yang dipakai pada
# berkas tersebut: judul, paragraf, daftar, tabel, gambar, blok kode, garis
# pemisah, tebal, miring, kode sebaris, dan kutipan.
#
#   ruby script/build_manual.rb                    # manual pengguna
#   ruby script/build_manual.rb REVISI_USE_CASE.md # dokumen lain
#
# Berkas sumber dicari ke seluruh subdirektori docs/, dan hasilnya diletakkan
# pada direktori yang sama dengan sumbernya. Dengan begitu penataan docs/ boleh
# diubah tanpa menyunting berkas ini.

DOCS_ROOT = File.expand_path("../docs", __dir__)

DOCUMENTS = {
  "MANUAL_PENGGUNA.md" => "manual.html",
  "PERANCANGAN_BASIS_DATA.md" => "perancangan.html",
  "DRAFT_BAB4_D.md" => "draft-bab4-d.html",
  "DRAFT_BAB5.md" => "draft-bab5.html",
  "REVISI_USE_CASE.md" => "revisi-use-case.html",
  "DESKRIPSI_USE_CASE.md" => "revisi-deskripsi-use-case.html"
}.freeze

source_name = ARGV[0] ? File.basename(ARGV[0]) : "MANUAL_PENGGUNA.md"
target_name = DOCUMENTS.fetch(source_name) do
  abort "Dokumen #{source_name} belum terdaftar. Pilihan: #{DOCUMENTS.keys.join(', ')}"
end

SOURCE = Dir.glob(File.join(DOCS_ROOT, "**", source_name)).first
abort "Berkas #{source_name} tidak ditemukan di dalam #{DOCS_ROOT}" if SOURCE.nil?

TARGET = File.join(File.dirname(SOURCE), target_name)

# Gambar dirujuk sebagai gambar/nama.png pada berkas sumber. Awalan disesuaikan
# dengan kedalaman berkas hasil terhadap docs/, sehingga rujukannya tetap sah
# walau dokumen dipindahkan ke subdirektori.
depth = File.dirname(SOURCE).delete_prefix("#{DOCS_ROOT}/").split("/").reject(&:empty?).size
IMAGE_PREFIX = "../" * depth

def escape(text)
  # Entitas HTML yang sudah ditulis pada sumber, misalnya &middot;, dibiarkan
  # utuh. Tanpa penjagaan ini tandanya tampil sebagai teks apa adanya.
  text.gsub(/&(?!#?\w+;)/, "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
end

# Rujukan gambar dinormalkan lebih dahulu, agar penulisan gambar/nama.png dan
# ../gambar/nama.png sama-sama menunjuk ke docs/gambar/nama.png.
def image_src(path)
  bersih = path.sub(%r{\A(\.\./)+}, "")

  bersih.start_with?("gambar/") ? "#{IMAGE_PREFIX}#{bersih}" : path
end

# Penulisan sebaris: gambar, tebal, miring, lalu kode sebaris.
def inline(text)
  escape(text)
    # Pindah baris di dalam sel tabel ditulis sebagai <br> pada berkas sumber,
    # sehingga tandanya perlu dipulihkan setelah proses penyandian.
    .gsub("&lt;br&gt;", "<br>")
    .gsub(/!\[([^\]]*)\]\(([^)]+)\)/) { %(<img src="#{image_src($2)}" alt="#{$1}">) }
    .gsub(/\*\*([^*]+)\*\*/) { "<strong>#{$1}</strong>" }
    .gsub(/(?<!\*)\*([^*\n]+)\*(?!\*)/) { "<em>#{$1}</em>" }
    .gsub(/`([^`]+)`/) { "<code>#{$1}</code>" }
end

def table_row(line, cell_tag)
  cells = line.strip.delete_prefix("|").delete_suffix("|").split("|")

  "<tr>#{cells.map { |cell| "<#{cell_tag}>#{inline(cell.strip)}</#{cell_tag}>" }.join}</tr>"
end

def separator_row?(line)
  line.match?(/^\|[\s:|-]+\|$/)
end

lines = File.readlines(SOURCE, chomp: true)
html = []
index = 0

while index < lines.size
  line = lines[index]

  case line
  when /^```/
    index += 1
    code = []
    code << lines[index] and index += 1 while index < lines.size && !lines[index].start_with?("```")
    html << "<pre><code>#{escape(code.join("\n"))}</code></pre>"

  when /^(#{'#'}{1,4})\s+(.*)$/
    level = Regexp.last_match(1).length
    html << "<h#{level}>#{inline(Regexp.last_match(2))}</h#{level}>"

  when /^---+$/
    html << "<hr>"

  when /^\s*\|/
    rows = []
    while index < lines.size && lines[index].match?(/^\s*\|/)
      rows << lines[index].strip
      index += 1
    end
    index -= 1

    head = rows.shift
    rows.shift if rows.first && separator_row?(rows.first)
    body = rows.reject { |row| separator_row?(row) }

    # Tabel dua lajur bergaya daftar keterangan ditulis dengan baris judul
    # kosong. Baris tersebut tidak perlu dikeluarkan agar tidak menyisakan
    # bidang kosong di atas tabel.
    header_kosong = head.delete("|").strip.empty?

    thead = header_kosong ? "" : "<thead>#{table_row(head, 'th')}</thead>"
    html << "<table>#{thead}<tbody>#{body.map { |row| table_row(row, 'td') }.join}</tbody></table>"

  when /^>\s?/
    quote = []
    while index < lines.size && lines[index].start_with?(">")
      quote << lines[index].sub(/^>\s?/, "")
      index += 1
    end
    index -= 1
    html << "<blockquote>#{inline(quote.reject(&:empty?).join(' '))}</blockquote>"

  when /^\s*[-*]\s+/
    items = []
    while index < lines.size && lines[index].match?(/^\s*[-*]\s+/)
      items << lines[index].sub(/^\s*[-*]\s+/, "")
      index += 1
    end
    index -= 1
    html << "<ul>#{items.map { |item| "<li>#{inline(item)}</li>" }.join}</ul>"

  when /^\s*\d+\.\s+/
    items = []

    loop do
      current = lines[index]

      if current.nil?
        break
      elsif current.match?(/^\s*\d+\.\s+/)
        items << current.sub(/^\s*\d+\.\s+/, "")
      elsif current.empty?
        # Baris kosong antar item tidak boleh memutus daftar menjadi dua,
        # karena penomorannya akan dimulai ulang dari satu.
        break unless lines[index + 1]&.match?(/^\s*\d+\.\s+/)
      elsif current.match?(/^\s{3,}\S/) && !current.match?(/^\s*(\||[-*]\s|```|>)/)
        # Baris menjorok merupakan lanjutan item sebelumnya, kecuali bila baris
        # itu justru membuka blok lain seperti tabel atau blok kode.
        items[-1] = "#{items[-1]} #{current.strip}"
      else
        break
      end

      index += 1
    end

    index -= 1
    html << "<ol>#{items.map { |item| "<li>#{inline(item)}</li>" }.join}</ol>"

  when ""
    # Baris kosong tidak menghasilkan keluaran.

  else
    paragraph = []
    while index < lines.size && !lines[index].empty? &&
          !lines[index].match?(%r{^(\s*\||\#|>|---+$|```|\s*[-*]\s|\s*\d+\.\s)})
      paragraph << lines[index]
      index += 1
    end
    index -= 1
    text = paragraph.join(" ")
    # Gambar berdiri sendiri dibungkus figure agar tidak terpotong antar halaman.
    html << if text.match?(/^!\[/)
              "<figure>#{inline(text)}</figure>"
    else
              "<p>#{inline(text)}</p>"
    end
  end

  index += 1
end

STYLE = <<~CSS
  @page { size: A4; margin: 20mm 18mm; }
  * { box-sizing: border-box; }
  body {
    font: 11pt/1.6 "Times New Roman", Georgia, serif;
    color: #1a1a1a; max-width: 190mm; margin: 0 auto; padding: 12mm 0;
  }
  h1 { font-size: 20pt; text-align: center; margin: 0 0 4pt; }
  h2 { font-size: 13pt; margin: 20pt 0 8pt; page-break-after: avoid; }
  h3 { font-size: 12pt; margin: 16pt 0 6pt; page-break-after: avoid; }
  h1 + h2 { text-align: center; font-weight: normal; font-size: 12pt; margin-top: 0; }
  p { margin: 0 0 8pt; text-align: justify; }
  hr { border: 0; border-top: 1px solid #ccc; margin: 16pt 0; }
  ul, ol { margin: 0 0 10pt; padding-left: 22pt; }
  li { margin-bottom: 4pt; }
  code {
    font-family: Consolas, "Courier New", monospace; font-size: 9.5pt;
    background: #f2f4f7; padding: 1pt 3pt; border-radius: 3px;
  }
  pre {
    background: #f7f9fb; border: 1px solid #dde3ea; border-radius: 4px;
    padding: 8pt 10pt; overflow-x: auto; page-break-inside: avoid;
  }
  pre code { background: none; padding: 0; font-size: 9.5pt; }
  table {
    width: 100%; border-collapse: collapse; font-size: 9.5pt;
    margin: 0 0 12pt; page-break-inside: avoid;
  }
  th, td { border: 1px solid #c9d2dc; padding: 4pt 6pt; text-align: left; vertical-align: top; }
  th { background: #eef3f8; font-weight: bold; }
  em { font-style: italic; }
  blockquote {
    margin: 0 0 12pt; padding: 8pt 12pt;
    background: #f7f9fb; border-left: 3pt solid #1b5e8c;
    page-break-inside: avoid; text-align: justify;
  }
  figure { margin: 10pt 0 4pt; page-break-inside: avoid; text-align: center; }
  img { max-width: 100%; border: 1px solid #ccd4de; }
  figure + p { text-align: center; font-size: 10pt; margin-bottom: 14pt; }
CSS

# Judul halaman diambil dari judul pertama dokumen sumber.
document_title = lines.find { |line| line.start_with?("# ") }&.delete_prefix("# ") || source_name

File.write(TARGET, <<~HTML)
  <!DOCTYPE html>
  <html lang="id">
  <head>
  <meta charset="utf-8">
  <title>#{document_title} - SPK SEBUSE</title>
  <style>#{STYLE}</style>
  </head>
  <body>
  #{html.join("\n")}
  </body>
  </html>
HTML

puts "#{TARGET} (#{(File.size(TARGET) / 1024.0).round(1)} KB, #{html.size} blok)"
