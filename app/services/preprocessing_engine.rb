# Mengubah log aktivitas mentah menjadi matriks keputusan X berskala 0-100,
# sesuai aturan pre-processing pada Bab III.C dan Bab IV.B.2.
#
# Urutan kerja per peserta:
#   1. Kuota poin harian dipangkas ke batas regulasi (maksimal 4 poin/hari)
#   2. Tiap kriteria C1..C10 dikonversi dengan rumusnya masing-masing
#   3. Hasilnya ditulis ke criterion_scores beserta catatan evaluasi (UC-09)
#
#   PreprocessingEngine.new(event).call
class PreprocessingEngine
  SCALE_MAX = 100.0

  # C7 (Hasil Pengukuran Akhir) adalah skor progres berat badan/BMI yang
  # dinilai panitia di akhir periode, bukan turunan log olahraga. Nilainya
  # diisi manual dan sengaja tidak ditimpa oleh pre-processing.
  MANUAL_CODES = %w[C7].freeze

  attr_reader :event

  def initialize(event)
    @event = event
  end

  # Mengembalikan jumlah peserta yang diproses.
  def call
    criteria = Criterion.ordered.to_a
    participants = event.participants.includes(:activity_logs).ordered.to_a

    ActiveRecord::Base.transaction do
      participants.each { |participant| process(participant, criteria) }
    end

    participants.size
  end

  private

  def process(participant, criteria)
    logs = capped_logs(participant)

    criteria.each do |criterion|
      score = CriterionScore.find_or_initialize_by(participant: participant, criterion: criterion)

      if MANUAL_CODES.include?(criterion.code)
        next if score.persisted?

        score.raw_value = nil
        score.normalized_value = 0
        score.notes = "Menunggu input manual panitia"
        score.save!
        next
      end

      raw, value, notes = evaluate(criterion.code, logs)

      score.raw_value = raw
      score.normalized_value = clamp(value)
      score.notes = notes
      score.save!
    end
  end

  def evaluate(code, logs)
    case code
    when "C1"  then cardio(logs)
    when "C2"  then strength(logs)
    when "C3"  then long_run(logs)
    when "C4"  then weekly_requirement(logs)
    when "C5"  then weekly_bonus(logs)
    when "C6"  then streak_rule(logs)
    when "C8"  then fun_sports(logs)
    when "C9"  then daily_discipline(logs)
    when "C10" then evidence_quality(logs)
    else raise ArgumentError, "kriteria #{code} belum memiliki rumus pre-processing"
    end
  end

  # Langkah 1: pemangkasan kuota poin harian.
  #
  # Total poin dalam satu hari dibatasi event.daily_point_cap (4). Bila terlampaui,
  # kelebihannya dipotong proporsional dari poin log hari itu sehingga komposisi
  # cardio/strength peserta tetap terjaga, hanya totalnya yang dipangkas.
  # Mengembalikan array struct log yang poinnya sudah bersih.
  def capped_logs(participant)
    cap = event.daily_point_cap

    participant.activity_logs.group_by(&:activity_date).flat_map do |_date, day_logs|
      total = day_logs.sum { |log| log.raw_points.to_f }
      factor = total > cap ? cap / total : 1.0

      day_logs.map do |log|
        CappedLog.new(
          activity_date: log.activity_date,
          activity_type: log.activity_type,
          points: log.raw_points.to_f * factor,
          raw_points: log.raw_points.to_f,
          distance_km: log.distance_km.to_f,
          evidence_valid: log.evidence_valid,
          trimmed: factor < 1.0
        )
      end
    end
  end

  CappedLog = Struct.new(
    :activity_date, :activity_type, :points, :raw_points,
    :distance_km, :evidence_valid, :trimmed,
    keyword_init: true
  )

  # C1 dan C2: persentase pencapaian terhadap target bulanan.
  # Nilai = (poin didapat / target bulanan) x 100
  def cardio(logs)
    points_over_target(logs, "cardio", event.target_cardio, "Cardio")
  end

  def strength(logs)
    points_over_target(logs, "strength", event.target_strength, "Strength")
  end

  def points_over_target(logs, type, target, label)
    points = logs.select { |log| log.activity_type == type }.sum(&:points)
    value = target.to_i.zero? ? 0.0 : (points / target) * SCALE_MAX
    trimmed = logs.count { |log| log.activity_type == type && log.trimmed }

    notes = "#{label}: #{round2(points)} dari target #{target} poin"
    notes += ", #{trimmed} log dipangkas kuota harian" if trimmed.positive?

    [ round2(points), value, notes ]
  end

  # C3: skala biner diskrit. 2x tuntas = 100, 1x = 50, 0x = 0.
  def long_run(logs)
    completed = logs.count do |log|
      log.activity_type == "long_run" && log.distance_km >= event.long_run_target_km
    end

    value = case completed
    when 0 then 0.0
    when 1 then 50.0
    else 100.0
    end

    [ completed, value, "Long Run >= #{round2(event.long_run_target_km)} KM tuntas #{completed}x" ]
  end

  # C4: syarat mingguan, minimal 3x olahraga per minggu dengan komposisi
  # 2 cardio + 1 strength. Nilai = (minggu patuh / total minggu) x 100
  def weekly_requirement(logs)
    target = { "cardio" => event.weekly_cardio_target, "strength" => event.weekly_strength_target }
    successful = weeks_meeting(logs, target)

    [ successful, weekly_ratio(successful),
      "Syarat mingguan terpenuhi #{successful} dari #{event.total_weeks} minggu" ]
  end

  # C5: bonus mingguan, diraih bila satu minggu mencapai 3 aerobik + 2 strength.
  def weekly_bonus(logs)
    target = { "cardio" => event.bonus_cardio_target, "strength" => event.bonus_strength_target }
    successful = weeks_meeting(logs, target)

    [ successful, weekly_ratio(successful),
      "Bonus mingguan diraih #{successful} dari #{event.total_weeks} minggu" ]
  end

  # Menghitung berapa minggu program yang komposisi sesinya memenuhi target.
  # Satu log sama dengan satu sesi.
  def weeks_meeting(logs, target_sessions)
    sessions_per_week(logs).count do |_week, counts|
      target_sessions.all? { |type, minimum| counts.fetch(type, 0) >= minimum }
    end
  end

  def sessions_per_week(logs)
    logs.group_by { |log| week_index(log.activity_date) }
        .select { |week, _| week.between?(1, event.total_weeks) }
        .transform_values { |week_logs| week_logs.group_by(&:activity_type).transform_values(&:size) }
  end

  # Minggu ke-1 dimulai pada event.start_date.
  def week_index(date)
    ((date - event.start_date).to_i / 7) + 1
  end

  def weekly_ratio(successful_weeks)
    return 0.0 if event.total_weeks.to_i.zero?

    (successful_weeks.to_f / event.total_weeks) * SCALE_MAX
  end

  # C6: proteksi overtraining. Regulasi membatasi cardio maksimal 3 hari
  # berturut-turut. Nilai = 100 - (jumlah rentetan pelanggaran x penalti).
  #
  # Yang dihitung adalah rentetannya, bukan tiap harinya: cardio 4 hari
  # berturut-turut sekali saja berarti satu pelanggaran, bukan empat.
  def streak_rule(logs)
    violations = cardio_streak_violations(logs)
    value = SCALE_MAX - (violations * event.streak_penalty_per_violation)

    [ violations, value,
      "#{violations} rentetan cardio melebihi #{event.max_consecutive_cardio_days} hari berturut-turut" ]
  end

  def cardio_streak_violations(logs)
    dates = logs.select { |log| log.activity_type == "cardio" }
                .map(&:activity_date).uniq.sort

    consecutive_runs(dates).count { |run| run.size > event.max_consecutive_cardio_days }
  end

  # Memecah daftar tanggal menjadi kelompok hari yang berurutan.
  def consecutive_runs(dates)
    dates.slice_when { |previous, current| (current - previous).to_i != 1 }.to_a
  end

  # C8: aktivitas opsional. 1 sesi = 1 poin, dibandingkan kuota santai sebulan.
  def fun_sports(logs)
    points = logs.select { |log| log.activity_type == "fun_sport" }.sum(&:points)
    target = event.fun_sport_point_target
    value = target.to_i.zero? ? 0.0 : (points / target) * SCALE_MAX

    [ round2(points), value, "Fun sports #{round2(points)} dari kuota #{target} poin" ]
  end

  # C9: kepatuhan kuota poin harian. Rasio hari aktif yang tidak melampaui
  # batas 4 poin terhadap seluruh hari aktif.
  def daily_discipline(logs)
    days = logs.group_by(&:activity_date)
    return [ 0, SCALE_MAX, "Belum ada hari aktif tercatat" ] if days.empty?

    over_quota = days.count { |_date, day_logs| day_logs.sum(&:raw_points) > event.daily_point_cap }
    compliant = days.size - over_quota
    value = (compliant.to_f / days.size) * SCALE_MAX

    [ compliant, value, "#{compliant} dari #{days.size} hari aktif patuh kuota #{event.daily_point_cap} poin" ]
  end

  # C10: validitas link dan foto bukti.
  def evidence_quality(logs)
    return [ 0, 0.0, "Belum ada bukti aktivitas diunggah" ] if logs.empty?

    valid = logs.count(&:evidence_valid)
    value = (valid.to_f / logs.size) * SCALE_MAX

    [ valid, value, "#{valid} dari #{logs.size} bukti dinyatakan valid" ]
  end

  # Bab III.C menyebut skala standar 0 sampai 100, jadi capaian melebihi target
  # tetap bernilai 100 dan penalti berlebih berhenti di 0.
  def clamp(value)
    value.clamp(0.0, SCALE_MAX).round(4)
  end

  def round2(value)
    value.to_f.round(2)
  end
end
