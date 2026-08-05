# UC-10 Cetak Laporan Peringkat.
#
# Menyusun laporan resmi hasil pemeringkatan ke dalam berkas PDF atau Excel.
#
#   generator = ReportGenerator.new(topsis_run)
#   generator.to_pdf     # => String biner PDF
#   generator.to_xlsx    # => String biner XLSX
#   generator.filename("pdf")
class ReportGenerator
  ORGANIZATION = "PT CAHAYA SUARA UTAMA".freeze
  ORGANIZATION_SIGNATURE = "PT Cahaya Suara Utama".freeze
  TITLE = "LAPORAN HASIL PEMERINGKATAN".freeze
  SUBTITLE = "Corporate Wellness Program - Event SEBUSE".freeze
  METHOD_NAME = "Metode Technique for Order of Preference by Similarity to Ideal Solution (TOPSIS)".freeze

  attr_reader :topsis_run, :event

  def initialize(topsis_run)
    @topsis_run = topsis_run
    @event = topsis_run.event
  end

  def filename(format)
    slug = event.name.parameterize
    stamp = topsis_run.executed_at.strftime("%Y%m%d-%H%M")

    "laporan-peringkat-#{slug}-#{stamp}.#{format}"
  end

  def to_pdf
    document = Prawn::Document.new(page_size: "A4", page_layout: :portrait, margin: 40)

    pdf_heading(document)
    pdf_meta(document)
    pdf_ranking_table(document)
    pdf_criteria_table(document)
    pdf_signature(document)

    document.render
  end

  def to_xlsx
    package = Axlsx::Package.new
    workbook = package.workbook
    styles = xlsx_styles(workbook)

    xlsx_ranking_sheet(workbook, styles)
    xlsx_decision_matrix_sheet(workbook, styles)
    xlsx_criteria_sheet(workbook, styles)

    package.to_stream.read
  end

  private

  def results
    @results ||= topsis_run.ranking_results.leaderboard.includes(:participant).to_a
  end

  def criteria
    @criteria ||= Criterion.ordered.to_a
  end

  # ---------- PDF ----------

  def pdf_heading(document)
    document.text ORGANIZATION, size: 11, align: :center, style: :bold
    document.text TITLE, size: 14, align: :center, style: :bold
    document.text SUBTITLE, size: 11, align: :center
    document.text METHOD_NAME, size: 8, align: :center, style: :italic
    document.stroke_horizontal_rule
    document.move_down 16
  end

  def pdf_meta(document)
    rows = [
      [ "Nama event", event.name ],
      [ "Periode", "#{format_date(event.start_date)} sampai #{format_date(event.end_date)}" ],
      [ "Jumlah peserta", "#{results.size} orang" ],
      [ "Waktu perhitungan", format_time(topsis_run.executed_at) ],
      [ "Dihitung oleh", topsis_run.executed_by&.name || "-" ]
    ]

    document.table(rows, cell_style: { size: 9, borders: [], padding: [ 2, 4 ] }, column_widths: [ 110, 400 ])
    document.move_down 14
  end

  def pdf_ranking_table(document)
    document.text "A. Hasil Pemeringkatan", size: 10, style: :bold
    document.move_down 6

    header = [ "Peringkat", "Kode", "Nama Peserta", "Departemen", "D+", "D-", "Nilai Vi" ]
    rows = results.map do |result|
      [
        result.award_label,
        result.participant.alternative_code,
        result.participant.name,
        result.participant.department.presence || "-",
        decimal(result.d_positive),
        decimal(result.d_negative),
        decimal(result.preference_value)
      ]
    end

    document.table([ header ] + rows, header: true, width: document.bounds.width) do
      cells.style(size: 8, padding: [ 4, 5 ])
      row(0).style(background_color: "E8F1F8", font_style: :bold)
      columns(4..6).style(align: :right)
    end

    document.move_down 6
    document.text "Nilai Vi merupakan kedekatan relatif terhadap solusi ideal pada rentang 0 sampai 1. " \
                  "Semakin mendekati 1, semakin baik capaian peserta.",
                  size: 7.5, style: :italic
    document.move_down 14
  end

  def pdf_criteria_table(document)
    document.text "B. Kriteria dan Bobot Penilaian", size: 10, style: :bold
    document.move_down 6

    weights = topsis_run.weights_snapshot
    header = [ "Kode", "Nama Kriteria", "Jenis", "Bobot" ]
    rows = criteria.map do |criterion|
      weight = weights[criterion.code] || criterion.weight
      [ criterion.code, criterion.name, criterion.criterion_type.capitalize, percent(weight) ]
    end
    rows << [ "", "Akumulasi seluruh bobot", "", percent(weights.values.sum) ]

    document.table([ header ] + rows, header: true, width: document.bounds.width) do
      cells.style(size: 8, padding: [ 4, 5 ])
      row(0).style(background_color: "E8F1F8", font_style: :bold)
      row(-1).style(font_style: :bold)
      column(3).style(align: :right)
    end

    document.move_down 6
    document.text "Bobot di atas adalah bobot yang tercatat pada saat perhitungan dijalankan.",
                  size: 7.5, style: :italic
    document.move_down 24
  end

  def pdf_signature(document)
    document.text "Jakarta, #{format_date(Date.current)}", size: 9, align: :right
    document.move_down 48
    document.text "Ketua Panitia Event SEBUSE", size: 9, align: :right
    document.text ORGANIZATION_SIGNATURE, size: 9, align: :right
  end

  # ---------- Excel ----------

  def xlsx_styles(workbook)
    {
      title: workbook.styles.add_style(sz: 13, b: true, alignment: { horizontal: :center }),
      subtitle: workbook.styles.add_style(sz: 10, alignment: { horizontal: :center }),
      header: workbook.styles.add_style(
        b: true, bg_color: "E8F1F8", border: { style: :thin, color: "C9D2DC" },
        alignment: { horizontal: :center, wrap_text: true }
      ),
      cell: workbook.styles.add_style(border: { style: :thin, color: "C9D2DC" }),
      number: workbook.styles.add_style(
        border: { style: :thin, color: "C9D2DC" }, format_code: "0.0000", alignment: { horizontal: :right }
      ),
      label: workbook.styles.add_style(b: true)
    }
  end

  def xlsx_ranking_sheet(workbook, styles)
    workbook.add_worksheet(name: "Peringkat") do |sheet|
      sheet.add_row [ "#{TITLE} - #{event.name}" ], style: styles[:title]
      sheet.add_row [ METHOD_NAME ], style: styles[:subtitle]
      sheet.add_row []
      sheet.add_row [ "Periode", "#{format_date(event.start_date)} sampai #{format_date(event.end_date)}" ]
      sheet.add_row [ "Waktu perhitungan", format_time(topsis_run.executed_at) ]
      sheet.add_row [ "Dihitung oleh", topsis_run.executed_by&.name || "-" ]
      sheet.add_row []

      sheet.add_row [ "Peringkat", "Kode", "Nama Peserta", "Departemen", "D+", "D-", "Nilai Vi" ],
                    style: styles[:header]

      results.each do |result|
        sheet.add_row [
          result.award_label,
          result.participant.alternative_code,
          result.participant.name,
          result.participant.department.presence || "-",
          result.d_positive.to_f,
          result.d_negative.to_f,
          result.preference_value.to_f
        ], style: [ styles[:cell] ] * 4 + [ styles[:number] ] * 3
      end

      sheet.merge_cells("A1:G1")
      sheet.merge_cells("A2:G2")
      sheet.column_widths 12, 8, 24, 18, 12, 12, 12
    end
  end

  # Matriks keputusan disertakan agar laporan dapat diperiksa ulang secara manual.
  def xlsx_decision_matrix_sheet(workbook, styles)
    workbook.add_worksheet(name: "Matriks Keputusan") do |sheet|
      sheet.add_row [ "Matriks keputusan (X) hasil pre-processing, skala 0 sampai 100" ], style: styles[:label]
      sheet.add_row []
      sheet.add_row [ "Alternatif" ] + criteria.map(&:code), style: styles[:header]

      topsis_run.decision_matrix.each do |code, values|
        sheet.add_row [ code ] + values.map(&:to_f), style: [ styles[:cell] ] + [ styles[:number] ] * values.size
      end

      sheet.add_row []
      sheet.add_row [ "Solusi ideal positif dan negatif dari matriks terbobot (Y)" ], style: styles[:label]
      sheet.add_row [ "Solusi" ] + criteria.map(&:code), style: styles[:header]
      sheet.add_row [ "A+" ] + criteria.map { |c| topsis_run.ideal_positive[c.code].to_f },
                    style: [ styles[:cell] ] + [ styles[:number] ] * criteria.size
      sheet.add_row [ "A-" ] + criteria.map { |c| topsis_run.ideal_negative[c.code].to_f },
                    style: [ styles[:cell] ] + [ styles[:number] ] * criteria.size

      sheet.column_widths(*([ 14 ] + Array.new(criteria.size, 10)))
    end
  end

  def xlsx_criteria_sheet(workbook, styles)
    weights = topsis_run.weights_snapshot

    workbook.add_worksheet(name: "Kriteria") do |sheet|
      sheet.add_row [ "Kode", "Nama Kriteria", "Jenis", "Bobot" ], style: styles[:header]

      criteria.each do |criterion|
        sheet.add_row [
          criterion.code,
          criterion.name,
          criterion.criterion_type.capitalize,
          (weights[criterion.code] || criterion.weight).to_f
        ], style: [ styles[:cell] ] * 3 + [ styles[:cell] ]
      end

      sheet.add_row [ "", "Akumulasi seluruh bobot", "", weights.values.sum.to_f ], style: styles[:label]
      sheet.column_widths 8, 42, 12, 10
    end
  end

  # ---------- Pembantu ----------

  def decimal(value) = format("%.4f", value.to_f)
  def percent(value) = "#{(value.to_f * 100).round(2)}%"
  def format_date(date) = I18n.l(date, format: :long)
  def format_time(time) = I18n.l(time, format: :long)
end
