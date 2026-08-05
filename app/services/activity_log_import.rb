# UC-05 Import Log Activities.
#
# Memuat berkas rekap aktivitas fisik peserta berformat CSV, XLSX, atau XLS ke
# dalam tabel activity_logs. Peserta dicocokkan melalui kolom NIP.
#
# Seluruh baris diperiksa lebih dahulu, baru disimpan sekaligus. Bila ada satu
# baris yang tidak sah, tidak ada baris yang tersimpan, sehingga panitia tidak
# perlu menebak sebagian data mana yang sudah masuk.
#
#   result = ActivityLogImport.new(event, file: params[:file]).call
#   result.imported   # => 42
#   result.errors     # => ["Baris 5: NIP CSU-9999 tidak terdaftar", ...]
class ActivityLogImport
  # Nama kolom yang wajib ada pada baris pertama berkas.
  HEADERS = %w[nip tanggal jenis poin].freeze
  OPTIONAL_HEADERS = %w[jarak_km tautan_bukti bukti_valid].freeze

  # Penulisan jenis aktivitas yang diterima, dipetakan ke nilai enum.
  ACTIVITY_TYPES = {
    "cardio" => :cardio,
    "kardio" => :cardio,
    "strength" => :strength,
    "beban" => :strength,
    "long_run" => :long_run,
    "long run" => :long_run,
    "longrun" => :long_run,
    "fun_sport" => :fun_sport,
    "fun sport" => :fun_sport,
    "fun sports" => :fun_sport,
    "fun_sports" => :fun_sport
  }.freeze

  TRUTHY = %w[1 true ya y yes valid benar sah].freeze
  EXTENSIONS = %w[.csv .xlsx .xls].freeze
  MAX_ROWS = 5_000

  Result = Struct.new(:imported, :batch_id, :errors, :skipped, keyword_init: true) do
    def success? = errors.empty? && imported.positive?
  end

  class InvalidFile < StandardError; end

  attr_reader :event, :file

  def initialize(event, file:)
    @event = event
    @file = file
  end

  def call
    rows = read_rows
    participants = event.participants.index_by { |participant| participant.nip.to_s.strip.downcase }

    errors = []
    attributes = []
    batch_id = SecureRandom.uuid

    rows.each do |number, row|
      built = build_attributes(row, participants, batch_id)

      if built.is_a?(String)
        errors << "Baris #{number}: #{built}"
      else
        attributes << built
      end
    end

    return Result.new(imported: 0, batch_id: nil, errors: errors, skipped: rows.size) if errors.any?

    ActivityLog.insert_all!(attributes) if attributes.any?

    Result.new(imported: attributes.size, batch_id: batch_id, errors: [], skipped: 0)
  end

  # Contoh berkas yang dapat diunduh panitia sebagai acuan penulisan kolom.
  def self.template_csv
    CSV.generate do |csv|
      csv << (HEADERS + OPTIONAL_HEADERS)
      csv << [ "CSU-0001", "2026-03-02", "cardio", 2, "", "https://medicalrjbb.com/logs/1", "ya" ]
      csv << [ "CSU-0001", "2026-03-08", "long_run", 3, 10.5, "https://medicalrjbb.com/logs/2", "ya" ]
      csv << [ "CSU-0002", "2026-03-03", "strength", 2, "", "https://medicalrjbb.com/logs/3", "tidak" ]
      csv << [ "CSU-0002", "2026-03-14", "fun_sport", 1, "", "", "ya" ]
    end
  end

  private

  # Mengembalikan pasangan [nomor baris pada berkas, hash kolom].
  def read_rows
    validate_file!

    sheet = Roo::Spreadsheet.open(file.path, extension: extension)
    header = normalize_header(sheet.row(1))
    missing = HEADERS - header

    if missing.any?
      raise InvalidFile,
            "Kolom wajib belum lengkap: #{missing.join(', ')}. " \
            "Baris pertama harus memuat #{HEADERS.join(', ')}."
    end

    rows = []
    (2..sheet.last_row.to_i).each do |number|
      values = sheet.row(number)
      next if values.compact.all? { |value| value.to_s.strip.empty? }

      rows << [ number, header.zip(values).to_h ]
    end

    raise InvalidFile, "Berkas tidak memuat satu pun baris data." if rows.empty?

    if rows.size > MAX_ROWS
      raise InvalidFile, "Berkas memuat #{rows.size} baris, melebihi batas #{MAX_ROWS} baris per unggahan."
    end

    rows
  rescue Roo::Error, CSV::MalformedCSVError => error
    raise InvalidFile, "Berkas tidak dapat dibaca: #{error.message}"
  end

  def validate_file!
    raise InvalidFile, "Belum ada berkas yang dipilih." if file.blank?

    unless EXTENSIONS.include?(extension)
      raise InvalidFile, "Format berkas #{extension.presence || 'tidak dikenal'} tidak didukung. " \
                         "Gunakan CSV, XLSX, atau XLS."
    end
  end

  def extension
    @extension ||= File.extname(file.original_filename.to_s).downcase
  end

  def normalize_header(values)
    values.map { |value| value.to_s.strip.downcase.tr(" ", "_") }
  end

  # Mengembalikan hash atribut bila sah, atau String berisi alasan penolakan.
  def build_attributes(row, participants, batch_id)
    participant = participants[row["nip"].to_s.strip.downcase]
    return "NIP #{row['nip'].presence || '(kosong)'} tidak terdaftar pada event ini" if participant.nil?

    date = parse_date(row["tanggal"])
    return "tanggal #{row['tanggal'].inspect} tidak dikenali, gunakan format YYYY-MM-DD" if date.nil?

    type = ACTIVITY_TYPES[row["jenis"].to_s.strip.downcase]
    return "jenis aktivitas #{row['jenis'].inspect} tidak dikenali" if type.nil?

    points = row["poin"].to_s.strip.tr(",", ".")
    return "poin #{row['poin'].inspect} bukan angka" unless points.match?(/\A\d+(\.\d+)?\z/)

    {
      participant_id: participant.id,
      activity_date: date,
      activity_type: ActivityLog.activity_types.fetch(type.to_s),
      raw_points: points.to_f,
      distance_km: parse_decimal(row["jarak_km"]),
      evidence_url: row["tautan_bukti"].presence&.to_s&.strip,
      evidence_valid: TRUTHY.include?(row["bukti_valid"].to_s.strip.downcase),
      source: ActivityLog.sources.fetch("import"),
      import_batch_id: batch_id,
      created_at: Time.current,
      updated_at: Time.current
    }
  end

  def parse_date(value)
    return value.to_date if value.respond_to?(:to_date) && !value.is_a?(String)

    Date.parse(value.to_s)
  rescue Date::Error, TypeError
    nil
  end

  def parse_decimal(value)
    text = value.to_s.strip.tr(",", ".")
    return nil if text.empty?

    Float(text)
  rescue ArgumentError
    nil
  end
end
