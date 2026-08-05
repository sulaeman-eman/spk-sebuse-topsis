require "rails_helper"

RSpec.describe ActivityLogImport do
  let(:event) do
    Event.create!(name: "SEBUSE Uji", start_date: Date.new(2026, 3, 2), end_date: Date.new(2026, 3, 29))
  end

  let!(:budi) do
    Participant.create!(event: event, alternative_code: "A1", nip: "CSU-0001", name: "Budi")
  end

  let!(:andi) do
    Participant.create!(event: event, alternative_code: "A2", nip: "CSU-0002", name: "Andi")
  end

  # Berkas unggahan diwakili struct sederhana; yang dibutuhkan hanya jalur
  # berkas dan nama aslinya untuk menentukan format.
  Upload = Struct.new(:path, :original_filename)

  def csv_upload(content, filename: "rekap.csv")
    path = Rails.root.join("tmp", "spec-#{SecureRandom.hex(4)}-#{filename}")
    File.write(path, content)

    Upload.new(path.to_s, filename)
  end

  def import(content, **options)
    described_class.new(event, file: csv_upload(content, **options)).call
  end

  describe "berkas yang sah" do
    let(:content) do
      <<~CSV
        nip,tanggal,jenis,poin,jarak_km,tautan_bukti,bukti_valid
        CSU-0001,2026-03-02,cardio,2,,https://medicalrjbb.com/1,ya
        CSU-0001,2026-03-08,long_run,3,10.5,https://medicalrjbb.com/2,ya
        CSU-0002,2026-03-03,strength,2,,,tidak
      CSV
    end

    it "menyimpan seluruh baris beserta penanda batch yang sama" do
      result = import(content)

      expect(result).to be_success
      expect(result.imported).to eq(3)
      expect(ActivityLog.where(import_batch_id: result.batch_id).count).to eq(3)
    end

    it "menandai sumber datanya sebagai impor" do
      import(content)

      expect(ActivityLog.pluck(:source).uniq).to eq([ "import" ])
    end

    it "mencocokkan peserta melalui kolom NIP" do
      import(content)

      expect(budi.activity_logs.count).to eq(2)
      expect(andi.activity_logs.count).to eq(1)
    end

    it "memetakan kolom opsional dengan benar" do
      import(content)

      long_run = budi.activity_logs.find_by(activity_type: :long_run)
      expect(long_run.distance_km.to_f).to eq(10.5)
      expect(long_run.evidence_url).to eq("https://medicalrjbb.com/2")
      expect(long_run.evidence_valid).to be(true)

      expect(andi.activity_logs.first.evidence_valid).to be(false)
    end

    it "menerima penulisan jenis aktivitas dalam berbagai bentuk" do
      import(<<~CSV)
        nip,tanggal,jenis,poin
        CSU-0001,2026-03-02,Cardio,2
        CSU-0001,2026-03-03,KARDIO,2
        CSU-0001,2026-03-04,Long Run,3
        CSU-0001,2026-03-05,Fun Sports,1
        CSU-0001,2026-03-06,beban,2
      CSV

      expect(budi.activity_logs.pluck(:activity_type))
        .to eq(%w[cardio cardio long_run fun_sport strength])
    end

    it "menerima nama kolom yang memakai huruf besar dan spasi" do
      result = import(<<~CSV)
        NIP,Tanggal,Jenis,Poin,Jarak KM
        CSU-0001,2026-03-02,cardio,2,
      CSV

      expect(result.imported).to eq(1)
    end

    it "melewati baris kosong di tengah berkas" do
      result = import(<<~CSV)
        nip,tanggal,jenis,poin
        CSU-0001,2026-03-02,cardio,2

        CSU-0002,2026-03-03,cardio,2
      CSV

      expect(result.imported).to eq(2)
    end

    it "menerima koma sebagai pemisah desimal pada kolom jarak" do
      import(<<~CSV)
        nip,tanggal,jenis,poin,jarak_km
        CSU-0001,2026-03-08,long_run,3,"10,5"
      CSV

      expect(budi.activity_logs.first.distance_km.to_f).to eq(10.5)
    end

    # Pemisah kolom yang dipakai adalah koma, sebagaimana template unduhan.
    it "menolak berkas yang memakai titik koma sebagai pemisah kolom" do
      expect {
        import(<<~CSV)
          nip;tanggal;jenis;poin
          CSU-0001;2026-03-02;cardio;2
        CSV
      }.to raise_error(described_class::InvalidFile, /Kolom wajib belum lengkap/)
    end
  end

  describe "penolakan baris" do
    # Satu baris tidak sah membatalkan seluruh berkas, sehingga panitia tidak
    # perlu menebak sebagian data mana yang sudah masuk.
    it "tidak menyimpan apa pun bila ada satu baris yang tidak sah" do
      result = import(<<~CSV)
        nip,tanggal,jenis,poin
        CSU-0001,2026-03-02,cardio,2
        CSU-9999,2026-03-03,cardio,2
      CSV

      expect(result).not_to be_success
      expect(result.imported).to eq(0)
      expect(ActivityLog.count).to eq(0)
    end

    it "menyebut nomor baris dan alasan penolakannya" do
      result = import(<<~CSV)
        nip,tanggal,jenis,poin
        CSU-9999,2026-03-02,cardio,2
        CSU-0001,32 Maret,cardio,2
        CSU-0001,2026-03-02,yoga,2
        CSU-0001,2026-03-02,cardio,dua
      CSV

      expect(result.errors).to contain_exactly(
        "Baris 2: NIP CSU-9999 tidak terdaftar pada event ini",
        'Baris 3: tanggal "32 Maret" tidak dikenali, gunakan format YYYY-MM-DD',
        'Baris 4: jenis aktivitas "yoga" tidak dikenali',
        'Baris 5: poin "dua" bukan angka'
      )
    end

    it "menolak NIP peserta dari event lain" do
      lain = Event.create!(name: "Event Lain", start_date: Date.new(2025, 3, 3), end_date: Date.new(2025, 3, 30))
      Participant.create!(event: lain, alternative_code: "A1", nip: "CSU-8888", name: "Peserta Lain")

      result = import("nip,tanggal,jenis,poin\nCSU-8888,2026-03-02,cardio,2\n")

      expect(result.errors.first).to match(/CSU-8888 tidak terdaftar/)
    end
  end

  describe "penolakan berkas" do
    it "menolak berkas tanpa kolom wajib" do
      expect { import("nip,tanggal\nCSU-0001,2026-03-02\n") }
        .to raise_error(described_class::InvalidFile, /Kolom wajib belum lengkap: jenis, poin/)
    end

    it "menolak format berkas yang tidak didukung" do
      expect { import("nip,tanggal,jenis,poin\n", filename: "rekap.txt") }
        .to raise_error(described_class::InvalidFile, /tidak didukung/)
    end

    it "menolak berkas tanpa baris data" do
      expect { import("nip,tanggal,jenis,poin\n") }
        .to raise_error(described_class::InvalidFile, /tidak memuat satu pun baris data/)
    end

    it "menolak bila berkas belum dipilih" do
      expect { described_class.new(event, file: nil).call }
        .to raise_error(described_class::InvalidFile, /Belum ada berkas/)
    end
  end

  describe "berkas Excel" do
    it "membaca XLSX beserta nilai tanggal aslinya" do
      path = Rails.root.join("tmp", "spec-#{SecureRandom.hex(4)}.xlsx")
      package = Axlsx::Package.new
      package.workbook.add_worksheet(name: "Log") do |sheet|
        sheet.add_row %w[nip tanggal jenis poin jarak_km]
        sheet.add_row [ "CSU-0001", Date.new(2026, 3, 20), "cardio", 2, nil ]
        sheet.add_row [ "CSU-0002", Date.new(2026, 3, 21), "long_run", 3, 11.0 ]
      end
      package.serialize(path)

      result = described_class.new(event, file: Upload.new(path.to_s, "log.xlsx")).call

      expect(result.imported).to eq(2)
      expect(budi.activity_logs.first.activity_date).to eq(Date.new(2026, 3, 20))
      expect(andi.activity_logs.first.distance_km.to_f).to eq(11.0)
    end
  end

  describe ".template_csv" do
    it "memuat seluruh nama kolom beserta contoh baris" do
      lines = described_class.template_csv.lines

      expect(lines.first).to include("nip", "tanggal", "jenis", "poin", "bukti_valid")
      expect(lines.size).to be > 1
    end
  end
end
