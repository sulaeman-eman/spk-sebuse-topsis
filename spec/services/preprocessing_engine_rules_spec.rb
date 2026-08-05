require "rails_helper"

# Menguji kebenaran rumus C1-C10 terhadap contoh perhitungan aturan penilaian
# event SEBUSE, dengan menurunkannya dari log aktivitas mentah.
#
# Angka pada spec ini BUKAN data Bab IV. Matriks keputusan X halaman 42 adalah
# data simulasi dan tetap dipakai apa adanya pada db/seeds.rb. Spec ini hanya
# membuktikan mesin pre-processing menerapkan rumusnya dengan benar.
#
# Aktivitas peserta contoh:
#   10 sesi cardio (20 poin), 8 sesi strength (16 poin), 1x Long Run 10 KM,
#   patuh syarat mingguan di keempat minggu, meraih bonus di minggu 1 dan 3,
#   sekali cardio 4 hari berturut-turut, 2x fun sports, 2 bukti ditolak panitia.
RSpec.describe PreprocessingEngine, "contoh perhitungan aturan C1-C10" do
  let(:event) do
    Event.create!(
      name: "SEBUSE Uji Aturan",
      start_date: Date.new(2026, 3, 2),   # Senin
      end_date: Date.new(2026, 3, 29)
    )
  end

  let(:participant) do
    Participant.create!(event: event, nip: "CSU-9101", name: "Peserta Contoh", alternative_code: "A1")
  end

  before do
    [
      [ "C1", 0.20 ], [ "C2", 0.15 ], [ "C3", 0.15 ], [ "C4", 0.10 ], [ "C5", 0.10 ],
      [ "C6", 0.10 ], [ "C7", 0.05 ], [ "C8", 0.05 ], [ "C9", 0.05 ], [ "C10", 0.05 ]
    ].each_with_index do |(code, weight), index|
      Criterion.create!(code: code, name: "Kriteria #{code}", weight: weight, position: index + 1)
    end

    activity_log_rows.each do |date, type, points, distance, evidence_valid|
      participant.activity_logs.create!(
        activity_date: Date.parse(date),
        activity_type: type,
        raw_points: points,
        distance_km: distance,
        evidence_valid: evidence_valid
      )
    end

    described_class.new(event).call
  end

  # Minggu 1: 2-8 Maret, minggu 2: 9-15, minggu 3: 16-22, minggu 4: 23-29.
  #
  # Rentetan cardio 7-10 Maret memotong batas minggu, sehingga Budi tetap
  # memenuhi syarat mingguan di seluruh minggu sekaligus punya tepat satu
  # rentetan pelanggaran.
  def activity_log_rows
    [
      # minggu 1: 3 cardio + 2 strength -> syarat dan bonus terpenuhi
      [ "2026-03-02", :cardio,   2, nil,  true  ],
      [ "2026-03-03", :strength, 2, nil,  true  ],
      [ "2026-03-05", :strength, 2, nil,  true  ],
      [ "2026-03-07", :cardio,   2, nil,  true  ],
      [ "2026-03-08", :cardio,   2, nil,  true  ],

      # minggu 2: 2 cardio + 2 strength -> syarat saja, tanpa bonus.
      # 7-10 Maret cardio empat hari berturut-turut, satu pelanggaran.
      [ "2026-03-09", :cardio,   2, nil,  true  ],
      [ "2026-03-10", :cardio,   2, nil,  false ],
      [ "2026-03-12", :strength, 2, nil,  true  ],
      [ "2026-03-14", :strength, 2, nil,  true  ],
      [ "2026-03-15", :fun_sport, 1, nil, true  ],

      # minggu 3: 3 cardio + 2 strength -> syarat dan bonus terpenuhi
      [ "2026-03-16", :cardio,   2, nil,  true  ],
      [ "2026-03-17", :strength, 2, nil,  true  ],
      [ "2026-03-18", :cardio,   2, nil,  true  ],
      [ "2026-03-19", :strength, 2, nil,  true  ],
      [ "2026-03-20", :cardio,   2, nil,  false ],
      [ "2026-03-22", :long_run, 3, 10.2, true  ],

      # minggu 4: 2 cardio + 2 strength -> syarat saja
      [ "2026-03-24", :cardio,   2, nil,  true  ],
      [ "2026-03-25", :strength, 2, nil,  true  ],
      [ "2026-03-26", :cardio,   2, nil,  true  ],
      [ "2026-03-27", :strength, 2, nil,  true  ],
      [ "2026-03-29", :fun_sport, 1, nil, true  ]
    ]
  end

  def value(code)
    participant.criterion_scores.joins(:criterion).find_by(criteria: { code: code })
               .normalized_value.to_f
  end

  it "menghitung 10 sesi cardio sebagai 83,33 dari target 24 poin" do
    expect(value("C1")).to be_within(0.01).of(83.33)
  end

  it "menghitung 8 sesi strength sebagai 100, tepat target 16 poin" do
    expect(value("C2")).to eq(100)
  end

  it "memberi 50 untuk satu kali Long Run tuntas" do
    expect(value("C3")).to eq(50)
  end

  it "memberi 100 karena syarat mingguan terpenuhi keempat minggu" do
    expect(value("C4")).to eq(100)
  end

  it "memberi 50 karena bonus mingguan hanya diraih di minggu 1 dan 3" do
    expect(value("C5")).to eq(50)
  end

  it "memberi 75 karena sekali cardio empat hari berturut-turut" do
    expect(value("C6")).to eq(75)
  end

  it "memberi 50 untuk 2 poin fun sports dari kuota 4" do
    expect(value("C8")).to eq(50)
  end

  it "memberi 100 karena tidak pernah melampaui kuota 4 poin sehari" do
    expect(value("C9")).to eq(100)
  end

  it "menghitung rasio bukti valid untuk C10" do
    # 21 log dengan 2 bukti ditolak. Contoh pada dokumen menyebut 20 upload
    # dengan hasil 90; selisih satu upload ini berasal dari dokumen, bukan
    # dari rumusnya.
    expect(value("C10")).to be_within(0.01).of(19.0 / 21 * 100)
  end

  it "menyisakan C7 untuk dinilai panitia, tidak diturunkan dari log olahraga" do
    score = participant.criterion_scores.joins(:criterion).find_by(criteria: { code: "C7" })

    expect(score.normalized_value).to eq(0)
    expect(score.notes).to match(/manual/i)
  end

  it "menghasilkan baris matriks keputusan yang lengkap untuk 10 kriteria" do
    expect(participant.decision_row.size).to eq(10)
  end
end
