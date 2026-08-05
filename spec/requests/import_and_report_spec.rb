require "rails_helper"

RSpec.describe "Import log dan cetak laporan", type: :request do
  let!(:criteria) { create_criteria }
  let!(:event) { create_event }

  describe "UC-05 Import Log Activities" do
    let!(:panitia) { sign_in_as(:admin_panitia) }
    let!(:participants) { create_scored_participants(event, criteria) }

    def upload(content, filename: "rekap.csv", type: "text/csv")
      path = Rails.root.join("tmp", "req-#{SecureRandom.hex(4)}-#{filename}")
      File.write(path, content)

      Rack::Test::UploadedFile.new(path, type, original_filename: filename)
    end

    it "menampilkan formulir unggahan beserta ketentuan kolomnya" do
      get new_event_activity_log_import_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Import Log Aktivitas", "nip", "tanggal", "jenis", "poin")
    end

    it "menyediakan template CSV untuk diunduh" do
      get template_event_activity_log_imports_path(event)

      expect(response).to have_http_status(:ok)
      expect(response.header["Content-Type"]).to include("text/csv")
      expect(response.body).to include("nip,tanggal,jenis,poin")
    end

    it "menyimpan seluruh baris berkas yang sah" do
      file = upload(<<~CSV)
        nip,tanggal,jenis,poin,jarak_km,bukti_valid
        CSU-A1,2026-03-02,cardio,2,,ya
        CSU-A1,2026-03-08,long_run,3,10.5,ya
        CSU-A2,2026-03-03,strength,2,,tidak
      CSV

      expect { post event_activity_log_imports_path(event), params: { file: file } }
        .to change(ActivityLog, :count).by(3)

      expect(response).to redirect_to(new_event_activity_log_import_path(event))
      expect(flash[:notice]).to match(/3 baris/)
    end

    it "membatalkan seluruh berkas bila ada baris yang tidak sah" do
      file = upload(<<~CSV)
        nip,tanggal,jenis,poin
        CSU-A1,2026-03-02,cardio,2
        CSU-9999,2026-03-03,cardio,2
      CSV

      expect { post event_activity_log_imports_path(event), params: { file: file } }
        .not_to change(ActivityLog, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("CSU-9999 tidak terdaftar")
    end

    it "menampilkan pesan galat bila format berkas tidak didukung" do
      post event_activity_log_imports_path(event),
           params: { file: upload("apa saja", filename: "rekap.txt", type: "text/plain") }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("tidak didukung")
    end

    it "menampilkan riwayat batch impor" do
      post event_activity_log_imports_path(event), params: {
        file: upload("nip,tanggal,jenis,poin\nCSU-A1,2026-03-02,cardio,2\n")
      }

      get new_event_activity_log_import_path(event)

      expect(response.body).to include("Riwayat impor", "1 batch")
    end

    it "membatalkan satu batch beserta seluruh barisnya" do
      post event_activity_log_imports_path(event), params: {
        file: upload("nip,tanggal,jenis,poin\nCSU-A1,2026-03-02,cardio,2\nCSU-A2,2026-03-03,cardio,2\n")
      }
      batch_id = ActivityLog.first.import_batch_id

      expect { delete event_activity_log_import_path(event, batch_id) }
        .to change(ActivityLog, :count).by(-2)

      expect(flash[:notice]).to match(/2 baris/)
    end

    it "tidak menyentuh batch lain saat satu batch dibatalkan" do
      post event_activity_log_imports_path(event), params: {
        file: upload("nip,tanggal,jenis,poin\nCSU-A1,2026-03-02,cardio,2\n")
      }
      batch_pertama = ActivityLog.first.import_batch_id

      post event_activity_log_imports_path(event), params: {
        file: upload("nip,tanggal,jenis,poin\nCSU-A2,2026-03-05,cardio,2\n")
      }

      delete event_activity_log_import_path(event, batch_pertama)

      expect(ActivityLog.count).to eq(1)
      expect(ActivityLog.first.import_batch_id).not_to eq(batch_pertama)
    end

    it "ditolak untuk Peserta" do
      sign_in_as(:peserta)

      get new_event_activity_log_import_path(event)

      expect(response).to redirect_to(root_path)
    end
  end

  describe "UC-10 Cetak Laporan Peringkat" do
    let!(:participants) { create_scored_participants(event, criteria) }
    let!(:run) { TopsisRunCreator.new(event).call }

    context "sebagai Admin Panitia" do
      before { sign_in_as(:admin_panitia) }

      it "mengunduh laporan berformat PDF" do
        get event_report_path(event, run, format: :pdf)

        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("application/pdf")
        expect(response.header["Content-Disposition"]).to include("laporan-peringkat", ".pdf")
        expect(response.body).to start_with("%PDF")
      end

      it "mengunduh laporan berformat Excel" do
        get event_report_path(event, run, format: :xlsx)

        expect(response).to have_http_status(:ok)
        expect(response.header["Content-Type"]).to include("spreadsheetml")
        expect(response.header["Content-Disposition"]).to include(".xlsx")
        expect(response.body[0, 2]).to eq("PK")
      end

      it "menampilkan tombol cetak pada papan peringkat" do
        get event_leaderboard_path(event)

        expect(response.body).to include("Cetak PDF", "Export Excel")
      end
    end

    it "ditolak untuk Peserta" do
      sign_in_as(:peserta)

      get event_report_path(event, run, format: :pdf)

      expect(response).to redirect_to(root_path)
    end

    it "tidak menampilkan tombol cetak pada akun Peserta" do
      sign_in_as(:peserta)

      get event_leaderboard_path(event)

      expect(response.body).not_to include("Cetak PDF")
    end
  end
end
