require "rails_helper"

RSpec.describe ReportGenerator do
  let(:criteria) do
    [
      [ "C1", "Total Poin Cardio", 0.20 ], [ "C2", "Total Poin Strength", 0.15 ],
      [ "C3", "Ketuntasan Long Run", 0.15 ], [ "C4", "Syarat Mingguan", 0.10 ],
      [ "C5", "Bonus Mingguan", 0.10 ], [ "C6", "Aturan Beruntun", 0.10 ],
      [ "C7", "Hasil Pengukuran Akhir", 0.05 ], [ "C8", "Poin Fun Sports", 0.05 ],
      [ "C9", "Disiplin Harian", 0.05 ], [ "C10", "Kualitas Evidence", 0.05 ]
    ].each_with_index.map do |(code, name, weight), index|
      Criterion.create!(code: code, name: name, weight: weight, position: index + 1)
    end
  end

  let(:event) do
    Event.create!(name: "SEBUSE 2026", start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 29))
  end

  let(:panitia) do
    User.create!(name: "Panitia Uji", email_address: "panitia@uji.test", password: "sebuse2026", role: :admin_panitia)
  end

  # Lima peserta beserta matriks keputusan Bab IV.
  let(:matrix) do
    {
      "A1" => [ "Budi",  "Produksi",  [ 85, 80, 100,  90, 85,  90, 80, 75,  90,  95 ] ],
      "A2" => [ "Andi",  "Teknik",    [ 90, 85, 100,  95, 90,  80, 85, 80,  95,  90 ] ],
      "A3" => [ "Citra", "Keuangan",  [ 70, 75,  80,  70, 65, 100, 75, 60,  80,  85 ] ],
      "A4" => [ "Dedi",  "Umum",      [ 60, 65,  50,  60, 50,  70, 65, 50,  70,  75 ] ],
      "A5" => [ "Eka",   "Pemasaran", [ 95, 90, 100, 100, 95,  85, 90, 90, 100, 100 ] ]
    }
  end

  let(:topsis_run) do
    matrix.each do |code, (name, department, values)|
      participant = Participant.create!(
        event: event, alternative_code: code, name: name, department: department, nip: "CSU-#{code}"
      )

      criteria.each_with_index do |criterion, index|
        CriterionScore.create!(participant: participant, criterion: criterion, normalized_value: values[index])
      end
    end

    TopsisRunCreator.new(event, executed_by: panitia).call
  end

  subject(:generator) { described_class.new(topsis_run) }

  describe "#filename" do
    it "memuat nama event dan waktu perhitungan" do
      expect(generator.filename("pdf")).to match(/\Alaporan-peringkat-sebuse-2026-\d{8}-\d{4}\.pdf\z/)
      expect(generator.filename("xlsx")).to end_with(".xlsx")
    end
  end

  describe "#to_pdf" do
    let(:pdf) { generator.to_pdf }

    it "menghasilkan berkas PDF yang sah" do
      expect(pdf).to start_with("%PDF")
      expect(pdf.bytesize).to be > 1_000
    end

    it "memuat nama perusahaan dan judul laporan" do
      text = pdf_text(pdf)

      expect(text).to include("PT CAHAYA SUARA UTAMA", "LAPORAN HASIL PEMERINGKATAN", "TOPSIS")
    end

    it "memuat seluruh peserta beserta nilai preferensinya" do
      text = pdf_text(pdf)

      expect(text).to include("Eka", "Andi", "Budi", "Citra", "Dedi")
      expect(text).to include("0.8988", "0.8182", "0.7618", "0.4350", "0.0000")
    end

    it "memuat sebutan juara sesuai peringkat" do
      text = pdf_text(pdf)

      expect(text).to include("Juara 1", "Juara 2", "Juara 3", "Peringkat 4", "Peringkat 5")
    end

    it "memuat sepuluh kriteria beserta akumulasi bobotnya" do
      text = pdf_text(pdf)

      criteria.each { |criterion| expect(text).to include(criterion.code) }
      expect(text).to include("Akumulasi seluruh bobot", "100.0%")
    end

    it "mencantumkan pelaksana perhitungan" do
      expect(pdf_text(pdf)).to include("Panitia Uji")
    end
  end

  describe "#to_xlsx" do
    let(:xlsx) { generator.to_xlsx }

    it "menghasilkan berkas XLSX yang sah" do
      # Berkas XLSX adalah arsip zip, sehingga diawali tanda PK.
      expect(xlsx[0, 2]).to eq("PK")
      expect(xlsx.bytesize).to be > 1_000
    end

    it "memuat tiga lembar kerja" do
      expect(xlsx_sheet_names(xlsx)).to eq([ "Peringkat", "Matriks Keputusan", "Kriteria" ])
    end

    it "memuat nilai preferensi pada lembar peringkat" do
      rows = xlsx_rows(xlsx, "Peringkat")
      ranking = rows.find { |row| row.include?("Eka") }

      expect(ranking).to include("Juara 1", "A5", "Pemasaran")
      expect(ranking.last.to_f).to be_within(0.0001).of(0.8988)
    end

    it "memuat matriks keputusan Bab IV pada lembar tersendiri" do
      rows = xlsx_rows(xlsx, "Matriks Keputusan")
      a1 = rows.find { |row| row.first == "A1" }

      expect(a1[1..10].map(&:to_f)).to eq([ 85, 80, 100, 90, 85, 90, 80, 75, 90, 95 ])
    end

    it "memuat solusi ideal positif dan negatif" do
      rows = xlsx_rows(xlsx, "Matriks Keputusan")

      expect(rows.map(&:first)).to include("A+", "A-")
    end

    it "memuat bobot kriteria pada lembar kriteria" do
      rows = xlsx_rows(xlsx, "Kriteria")
      c1 = rows.find { |row| row.first == "C1" }

      expect(c1[1]).to eq("Total Poin Cardio")
      expect(c1.last.to_f).to be_within(0.0001).of(0.20)
    end
  end

  # Membaca kembali berkas hasil generator melalui pustaka pembaca, agar yang
  # diuji benar-benar isi berkasnya, bukan sekadar keluaran pemanggilan metode.
  def pdf_text(binary)
    path = Rails.root.join("tmp", "spec-#{SecureRandom.hex(4)}.pdf")
    File.binwrite(path, binary)
    text = `pdftotext -layout #{path} - 2>/dev/null`
    File.delete(path)

    text
  end

  def spreadsheet(binary)
    path = Rails.root.join("tmp", "spec-#{SecureRandom.hex(4)}.xlsx")
    File.binwrite(path, binary)
    sheet = Roo::Spreadsheet.open(path.to_s, extension: ".xlsx")
    yield sheet
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  def xlsx_sheet_names(binary)
    spreadsheet(binary, &:sheets)
  end

  def xlsx_rows(binary, sheet_name)
    spreadsheet(binary) do |book|
      book.sheet(sheet_name).to_a.map { |row| row.map { |cell| cell.is_a?(String) ? cell : cell } }
    end
  end
end
