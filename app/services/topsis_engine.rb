# Kalkulasi metode TOPSIS (Technique for Order of Preference by Similarity to
# Ideal Solution) sesuai langkah a-f pada Bab IV.B.3.
#
# Kelas ini sengaja tidak menyentuh ActiveRecord: masukannya array biasa, jadi
# kebenaran matematikanya bisa diuji langsung terhadap matriks keputusan yang
# tertulis di skripsi tanpa membuat satu pun record database.
#
#   result = TopsisEngine.new(matrix: x, weights: w).call
#   result.preferences  # => [0.7567, 0.8177, ...]
class TopsisEngine
  Result = Struct.new(
    :decision_matrix,      # X  - matriks keputusan
    :divisors,             # akar dari jumlah kuadrat tiap kolom
    :normalized_matrix,    # R  - matriks ternormalisasi
    :weighted_matrix,      # Y  - matriks ternormalisasi terbobot
    :ideal_positive,       # A+ - solusi ideal positif
    :ideal_negative,       # A- - solusi ideal negatif
    :distances_positive,   # D+ - jarak Euclidean ke A+
    :distances_negative,   # D- - jarak Euclidean ke A-
    :preferences,          # V  - nilai preferensi, rentang 0..1
    :ranks,                # peringkat 1..m, sejajar indeks alternatif
    keyword_init: true
  )

  class InvalidInput < ArgumentError; end

  attr_reader :matrix, :weights, :types

  # matrix  : array m x n berisi nilai alternatif per kriteria (skala 0-100)
  # weights : array n bobot desimal, idealnya berjumlah 1,0
  # types   : array n simbol :benefit atau :cost. Default seluruhnya :benefit,
  #           sesuai tabel 3.2 di mana 10 kriteria SEBUSE bertipe benefit.
  def initialize(matrix:, weights:, types: nil)
    @matrix = matrix.map { |row| row.map { |value| value.to_f } }
    @weights = weights.map(&:to_f)
    @types = (types || Array.new(@weights.size, :benefit)).map(&:to_sym)

    validate!
  end

  def call
    normalized = normalize
    weighted = apply_weights(normalized)
    positive = ideal_solution(weighted, :positive)
    negative = ideal_solution(weighted, :negative)
    d_positive = distances(weighted, positive)
    d_negative = distances(weighted, negative)
    preferences = preference_values(d_positive, d_negative)

    Result.new(
      decision_matrix: matrix,
      divisors: divisors,
      normalized_matrix: normalized,
      weighted_matrix: weighted,
      ideal_positive: positive,
      ideal_negative: negative,
      distances_positive: d_positive,
      distances_negative: d_negative,
      preferences: preferences,
      ranks: ranks_for(preferences)
    )
  end

  private

  def alternative_count = matrix.size
  def criterion_count   = weights.size

  def validate!
    raise InvalidInput, "matriks keputusan tidak boleh kosong" if matrix.empty?
    raise InvalidInput, "bobot kriteria tidak boleh kosong" if weights.empty?

    unless matrix.all? { |row| row.size == criterion_count }
      raise InvalidInput, "setiap baris matriks harus berisi #{criterion_count} nilai kriteria"
    end

    unless types.size == criterion_count
      raise InvalidInput, "jumlah tipe kriteria harus #{criterion_count}"
    end

    unknown = types.uniq - %i[benefit cost]
    raise InvalidInput, "tipe kriteria tidak dikenal: #{unknown.join(', ')}" if unknown.any?
  end

  def column(index)
    matrix.map { |row| row[index] }
  end

  # Langkah 2: pembagi normalisasi, yaitu akar dari jumlah kuadrat tiap kolom.
  def divisors
    @divisors ||= Array.new(criterion_count) do |j|
      Math.sqrt(column(j).sum { |value| value**2 })
    end
  end

  # Langkah 2: r_ij = x_ij / sqrt(sum x_ij^2)
  # Pembagi nol berarti seluruh alternatif bernilai 0 pada kriteria itu, jadi
  # kolomnya memang 0 -- bukan pembagian nol.
  def normalize
    matrix.map do |row|
      row.each_with_index.map do |value, j|
        divisors[j].zero? ? 0.0 : value / divisors[j]
      end
    end
  end

  # Langkah 3: y_ij = w_j * r_ij
  def apply_weights(normalized)
    normalized.map do |row|
      row.each_with_index.map { |value, j| weights[j] * value }
    end
  end

  # Langkah 4: A+ mengambil nilai terbaik per kriteria, A- nilai terburuk.
  # Untuk kriteria benefit "terbaik" berarti maksimum; untuk cost dibalik.
  def ideal_solution(weighted, direction)
    Array.new(criterion_count) do |j|
      values = weighted.map { |row| row[j] }
      wants_max = (types[j] == :benefit) == (direction == :positive)
      wants_max ? values.max : values.min
    end
  end

  # Langkah 5: jarak Euclidean tiap alternatif terhadap satu titik acuan ideal.
  def distances(weighted, ideal)
    weighted.map do |row|
      Math.sqrt(row.each_with_index.sum { |value, j| (value - ideal[j])**2 })
    end
  end

  # Langkah 6: V_i = D- / (D+ + D-)
  # Penyebut nol hanya terjadi bila seluruh alternatif identik, sehingga tidak
  # ada yang lebih unggul. Nilainya 0, bukan NaN.
  def preference_values(d_positive, d_negative)
    d_positive.each_with_index.map do |dp, i|
      denominator = dp + d_negative[i]
      denominator.zero? ? 0.0 : d_negative[i] / denominator
    end
  end

  # Peringkat 1 untuk nilai preferensi tertinggi. Nilai yang sama persis
  # mendapat peringkat yang sama.
  def ranks_for(preferences)
    sorted = preferences.uniq.sort.reverse
    preferences.map { |value| sorted.index(value) + 1 }
  end
end
