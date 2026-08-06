require "rails_helper"

# Menguji tiap rumus konversi pada Bab IV.B.2 secara terpisah, memakai log
# aktivitas seminimal mungkin agar satu spec hanya menguji satu rumus.
RSpec.describe PreprocessingEngine do
  let(:event) do
    Event.create!(
      name: "SEBUSE Uji",
      start_date: Date.new(2026, 3, 2),   # Senin, awal minggu ke-1
      end_date: Date.new(2026, 3, 29),
      target_cardio: 24,
      target_strength: 16,
      total_weeks: 4,
      daily_point_cap: 4,
      streak_penalty_per_violation: 25,
      long_run_target_km: 10
    )
  end

  let(:participant) do
    Participant.create!(
      event: event, nip: "CSU-9001", name: "Uji", alternative_code: "A1"
    )
  end

  # Sepuluh kriteria dengan bobot tabel 3.2 terkoreksi.
  before do
    [
      [ "C1", 0.20 ], [ "C2", 0.15 ], [ "C3", 0.15 ], [ "C4", 0.10 ], [ "C5", 0.10 ],
      [ "C6", 0.10 ], [ "C7", 0.05 ], [ "C8", 0.05 ], [ "C9", 0.05 ], [ "C10", 0.05 ]
    ].each_with_index do |(code, weight), index|
      Criterion.create!(code: code, name: "Kriteria #{code}", weight: weight, position: index + 1)
    end
  end

  def log(date:, type:, points: 2, distance: nil, evidence_valid: true)
    participant.activity_logs.create!(
      activity_date: Date.parse(date),
      activity_type: type,
      raw_points: points,
      distance_km: distance,
      evidence_valid: evidence_valid
    )
  end

  def score(code)
    participant   # dipastikan ada walau spec ini tidak membuat log apa pun
    described_class.new(event.reload).call
    participant.criterion_scores.joins(:criterion).find_by(criteria: { code: code })
  end

  def value(code) = score(code).normalized_value.to_f

  describe "pemangkasan kuota poin harian" do
    # Regulasi membatasi 4 poin per hari. Kelebihan dipotong proporsional agar
    # komposisi cardio dan strength peserta tetap terjaga.
    it "memangkas total poin satu hari yang melebihi batas 4" do
      log(date: "2026-03-04", type: :cardio, points: 4)
      log(date: "2026-03-04", type: :strength, points: 2)

      # 6 poin dipangkas ke 4, proporsional: cardio 2,67 dan strength 1,33.
      expect(value("C1")).to be_within(0.01).of(2.6667 / 24 * 100)
      expect(value("C2")).to be_within(0.01).of(1.3333 / 16 * 100)
    end

    it "membiarkan hari yang tepat pada batas kuota" do
      log(date: "2026-03-04", type: :cardio, points: 4)

      expect(value("C1")).to be_within(0.01).of(4.0 / 24 * 100)
    end
  end

  describe "C1 dan C2: persentase pencapaian target bulanan" do
    it "bernilai 100 saat target cardio tepat terpenuhi" do
      12.times { |i| log(date: (event.start_date + (i * 2)).to_s, type: :cardio, points: 2) }

      expect(value("C1")).to eq(100)
    end

    it "tetap 100 saat capaian melampaui target" do
      # 15 hari x 2 poin = 30 poin, melebihi target 24.
      15.times { |i| log(date: (event.start_date + (i * 2)).to_s, type: :cardio, points: 2) }

      expect(value("C1")).to eq(100)
    end

    it "bernilai 50 saat capaian setengah target strength" do
      4.times { |i| log(date: (event.start_date + (i * 2)).to_s, type: :strength, points: 2) }

      expect(value("C2")).to eq(50)
    end

    it "bernilai 0 saat tidak ada aktivitas" do
      expect(value("C1")).to eq(0)
    end
  end

  describe "C3: ketuntasan Long Run wajib 10 KM" do
    it "bernilai 100 untuk dua kali tuntas" do
      log(date: "2026-03-08", type: :long_run, points: 3, distance: 10.5)
      log(date: "2026-03-22", type: :long_run, points: 3, distance: 12)

      expect(value("C3")).to eq(100)
    end

    it "bernilai 50 untuk satu kali tuntas" do
      log(date: "2026-03-08", type: :long_run, points: 3, distance: 10)

      expect(value("C3")).to eq(50)
    end

    it "bernilai 0 tanpa long run sama sekali" do
      expect(value("C3")).to eq(0)
    end

    it "tidak menghitung long run yang jaraknya kurang dari 10 KM" do
      log(date: "2026-03-08", type: :long_run, points: 3, distance: 9.9)

      expect(value("C3")).to eq(0)
    end
  end

  describe "C4 dan C5: proporsi ketercapaian target mingguan" do
    # Syarat C4: minimal 2 cardio + 1 strength per minggu.
    # Bonus C5: 3 aerobik + 2 strength dalam satu minggu.
    def fill_week(week_index, cardio:, strength:)
      first_day = event.start_date + ((week_index - 1) * 7)
      offset = 0

      cardio.times do
        log(date: (first_day + offset).to_s, type: :cardio, points: 2)
        offset += 1
      end

      strength.times do
        log(date: (first_day + offset).to_s, type: :strength, points: 2)
        offset += 1
      end
    end

    it "bernilai 75 saat 3 dari 4 minggu memenuhi syarat" do
      [ 1, 2, 3 ].each { |week| fill_week(week, cardio: 2, strength: 1) }

      expect(value("C4")).to eq(75)
    end

    it "bernilai 100 saat seluruh minggu memenuhi syarat" do
      (1..4).each { |week| fill_week(week, cardio: 2, strength: 1) }

      expect(value("C4")).to eq(100)
    end

    it "tidak menghitung minggu yang komposisinya tidak lengkap" do
      fill_week(1, cardio: 5, strength: 0)   # cardio banyak tapi strength nol

      expect(value("C4")).to eq(0)
    end

    it "hanya memberi bonus pada minggu yang mencapai 3 cardio dan 2 strength" do
      fill_week(1, cardio: 3, strength: 2)   # syarat sekaligus bonus
      fill_week(2, cardio: 2, strength: 1)   # syarat saja

      expect(value("C4")).to eq(50)
      expect(value("C5")).to eq(25)
    end

    it "tidak memberi bonus bila strength kurang walau cardio melimpah" do
      fill_week(1, cardio: 4, strength: 1)

      expect(value("C4")).to eq(25)
      expect(value("C5")).to eq(0)
    end
  end

  describe "C6: aturan beruntun sebagai proteksi overtraining" do
    # Regulasi mengizinkan cardio maksimal 3 hari berturut-turut.
    it "bernilai 100 saat cardio tiga hari berturut-turut, masih dalam batas" do
      %w[2026-03-02 2026-03-03 2026-03-04].each { |date| log(date: date, type: :cardio) }

      expect(value("C6")).to eq(100)
    end

    it "bernilai 75 untuk satu rentetan cardio empat hari berturut-turut" do
      %w[2026-03-09 2026-03-10 2026-03-11 2026-03-12].each { |date| log(date: date, type: :cardio) }

      expect(value("C6")).to eq(75)
      expect(score("C6").raw_value.to_i).to eq(1)
    end

    it "menghitung satu pelanggaran per rentetan, bukan per hari" do
      # Tujuh hari berturut-turut tetap satu rentetan.
      (2..8).each { |day| log(date: "2026-03-#{format('%02d', day)}", type: :cardio) }

      expect(score("C6").raw_value.to_i).to eq(1)
      expect(value("C6")).to eq(75)
    end

    it "bernilai 50 untuk dua rentetan pelanggaran terpisah" do
      %w[2026-03-02 2026-03-03 2026-03-04 2026-03-05].each { |date| log(date: date, type: :cardio) }
      %w[2026-03-16 2026-03-17 2026-03-18 2026-03-19].each { |date| log(date: date, type: :cardio) }

      expect(value("C6")).to eq(50)
    end

    it "berhenti di 0 dan tidak negatif walau rentetan pelanggaran lebih dari empat" do
      [ 1, 8, 15, 22, 29 ].each do |start|
        4.times { |offset| log(date: (Date.new(2026, 3, 1) + start + offset - 1).to_s, type: :cardio) }
      end

      expect(score("C6").raw_value.to_i).to eq(5)
      expect(value("C6")).to eq(0)
    end

    it "hanya menghitung cardio, bukan strength yang berdempet" do
      %w[2026-03-02 2026-03-03 2026-03-04 2026-03-05].each { |date| log(date: date, type: :strength) }

      expect(value("C6")).to eq(100)
    end

    it "tidak menghitung dua log pada hari yang sama sebagai hari beruntun" do
      log(date: "2026-03-04", type: :cardio, points: 2)
      log(date: "2026-03-04", type: :cardio, points: 2)

      expect(value("C6")).to eq(100)
    end
  end

  describe "C7: hasil pengukuran akhir" do
    # Progres fisik/BMI tidak bisa diturunkan dari log olahraga, sumbernya
    # pengukuran badan oleh panitia.
    it "menyiapkan nilai nol dengan catatan menunggu input manual" do
      log(date: "2026-03-04", type: :cardio)

      expect(value("C7")).to eq(0)
      expect(score("C7").notes).to match(/manual/i)
    end

    it "tidak menimpa nilai yang sudah diisi panitia" do
      criterion = Criterion.find_by(code: "C7")
      CriterionScore.create!(
        participant: participant, criterion: criterion,
        raw_value: 1, normalized_value: 80, notes: "Pengukuran akhir oleh panitia"
      )
      log(date: "2026-03-04", type: :cardio)

      expect(value("C7")).to eq(80)
      expect(score("C7").notes).to eq("Pengukuran akhir oleh panitia")
    end
  end

  describe "C8: poin fun sports" do
    # 1 sesi = 1 poin, kuota santai 4 poin sebulan.
    it "menghitung rasio terhadap kuota regulasi" do
      log(date: "2026-03-14", type: :fun_sport, points: 1)
      log(date: "2026-03-21", type: :fun_sport, points: 1)

      expect(value("C8")).to eq(50)
    end

    it "tetap 100 saat kuota fun sports terlampaui" do
      6.times { |i| log(date: (event.start_date + (i * 3)).to_s, type: :fun_sport, points: 1) }

      expect(value("C8")).to eq(100)
    end
  end

  describe "C9: disiplin kepatuhan kuota harian" do
    it "menurunkan nilai untuk hari yang melampaui kuota" do
      log(date: "2026-03-02", type: :cardio, points: 2)
      log(date: "2026-03-04", type: :cardio, points: 4)
      log(date: "2026-03-04", type: :strength, points: 2)   # hari ini melebihi kuota

      expect(value("C9")).to eq(50)
    end

    it "bernilai 100 bila seluruh hari patuh" do
      log(date: "2026-03-02", type: :cardio, points: 2)
      log(date: "2026-03-04", type: :cardio, points: 4)

      expect(value("C9")).to eq(100)
    end
  end

  describe "C10: kualitas evidence" do
    it "menghitung rasio bukti valid terhadap seluruh log" do
      log(date: "2026-03-02", type: :cardio, evidence_valid: true)
      log(date: "2026-03-04", type: :cardio, evidence_valid: true)
      log(date: "2026-03-06", type: :cardio, evidence_valid: true)
      log(date: "2026-03-08", type: :cardio, evidence_valid: false)

      expect(value("C10")).to eq(75)
    end

    it "bernilai 0 tanpa bukti apa pun" do
      expect(value("C10")).to eq(0)
    end
  end

  describe "hasil keseluruhan" do
    it "menulis satu skor untuk setiap kriteria dan mengembalikan jumlah peserta" do
      log(date: "2026-03-04", type: :cardio)

      expect(described_class.new(event).call).to eq(1)
      expect(participant.criterion_scores.count).to eq(10)
      expect(participant.criterion_scores.pluck(:normalized_value)).to all(be_between(0, 100))
    end

    it "dapat dijalankan ulang tanpa menduplikasi skor" do
      log(date: "2026-03-04", type: :cardio)

      2.times { described_class.new(event).call }

      expect(participant.criterion_scores.count).to eq(10)
    end
  end

  # Skor peserta dapat berasal dari pemasukan langsung, misalnya data simulasi
  # Bab IV yang tidak memiliki log aktivitas. Menjalankan pre-processing tidak
  # boleh menghapus nilai tersebut menjadi nol.
  describe "peserta tanpa log aktivitas" do
    it "tidak menimpa skor yang sudah ada" do
      criteria = Criterion.ordered.to_a
      nilai = [ 85, 80, 100, 90, 85, 90, 80, 75, 90, 95 ]
      criteria.each_with_index do |criterion, index|
        CriterionScore.create!(
          participant: participant, criterion: criterion, normalized_value: nilai[index]
        )
      end

      described_class.new(event).call

      expect(participant.reload.decision_row.map(&:to_i)).to eq(nilai)
    end

    it "mengisi nol beserta catatan bila skornya memang belum ada" do
      described_class.new(event.tap { participant }).call

      expect(participant.criterion_scores.count).to eq(10)
      expect(value("C1")).to eq(0)
      expect(score("C1").notes).to eq("Belum ada log aktivitas")
    end

    it "tetap menghitung ulang peserta lain yang memiliki log" do
      criteria = Criterion.ordered.to_a
      criteria.each do |criterion|
        CriterionScore.create!(participant: participant, criterion: criterion, normalized_value: 90)
      end

      aktif = Participant.create!(
        event: event, nip: "CSU-9002", name: "Aktif", alternative_code: "A2"
      )
      12.times do |i|
        aktif.activity_logs.create!(
          activity_date: event.start_date + (i * 2), activity_type: :cardio, raw_points: 2
        )
      end

      described_class.new(event).call

      cardio = Criterion.find_by(code: "C1")
      expect(participant.criterion_scores.find_by(criterion: cardio).normalized_value).to eq(90)
      expect(aktif.criterion_scores.find_by(criterion: cardio).normalized_value).to eq(100)
    end
  end
end
