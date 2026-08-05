require "rails_helper"

# Spec ini adalah bukti komputasi: seluruh angka acuan diambil dari perhitungan
# manual Bab IV halaman 42-47. Selama spec ini hijau, mesin TOPSIS sistem
# menghasilkan hasil yang sama dengan hitungan tangan di skripsi.
RSpec.describe TopsisEngine do
  # Matriks keputusan X hasil pre-processing, Bab IV halaman 42.
  # Baris berurutan: A1 Budi, A2 Andi, A3 Citra, A4 Dedi, A5 Eka.
  let(:decision_matrix) do
    [
      [ 85, 80, 100,  90, 85,  90, 80, 75,  90,  95 ],
      [ 90, 85, 100,  95, 90,  80, 85, 80,  95,  90 ],
      [ 70, 75,  80,  70, 65, 100, 75, 60,  80,  85 ],
      [ 60, 65,  50,  60, 50,  70, 65, 50,  70,  75 ],
      [ 95, 90, 100, 100, 95,  85, 90, 90, 100, 100 ]
    ]
  end

  # Bobot tabel 3.2 setelah koreksi C7 dari 10% menjadi 5% agar total 100%.
  let(:weights) { [ 0.20, 0.15, 0.15, 0.10, 0.10, 0.10, 0.05, 0.05, 0.05, 0.05 ] }

  subject(:result) { described_class.new(matrix: decision_matrix, weights: weights).call }

  it "bobot yang dipakai berjumlah tepat 1,0 sesuai syarat UC-03" do
    expect(weights.sum).to be_within(0.0001).of(1.0)
  end

  describe "langkah 2: normalisasi matriks keputusan" do
    # Pembagi akar jumlah kuadrat per kolom, Bab IV halaman 43-44.
    it "menghasilkan pembagi yang sama dengan perhitungan manual" do
      expect(result.divisors).to match_bab_iv([
        181.2457, 177.6936, 197.2308, 188.7459, 176.2810,
        191.3766, 177.6936, 161.9413, 196.0230, 199.9375
      ])
    end

    # Matriks R halaman 44, diverifikasi pada baris pertama dan terakhir.
    it "menghasilkan matriks R sesuai halaman 44" do
      expect(result.normalized_matrix.first).to match_bab_iv(
        [ 0.4690, 0.4502, 0.5070, 0.4768, 0.4822, 0.4703, 0.4502, 0.4631, 0.4591, 0.4751 ]
      )
      expect(result.normalized_matrix.last).to match_bab_iv(
        [ 0.5242, 0.5065, 0.5070, 0.5298, 0.5389, 0.4442, 0.5065, 0.5558, 0.5101, 0.5002 ]
      )
    end

    it "seluruh elemen R berada pada rentang 0 sampai 1" do
      expect(result.normalized_matrix.flatten).to all(be_between(0, 1))
    end
  end

  describe "langkah 4: solusi ideal" do
    # Karena 10 kriteria bertipe benefit, A+ adalah maksimum kolom matriks Y
    # dan A- adalah minimumnya.
    it "A+ mengambil nilai terbesar setiap kolom" do
      expected = (0...10).map { |j| result.weighted_matrix.map { |row| row[j] }.max }

      expect(result.ideal_positive).to match_bab_iv(expected)
    end

    it "A- mengambil nilai terkecil setiap kolom" do
      expected = (0...10).map { |j| result.weighted_matrix.map { |row| row[j] }.min }

      expect(result.ideal_negative).to match_bab_iv(expected)
    end
  end

  describe "langkah 5 dan 6: jarak Euclidean dan nilai preferensi" do
    # Tabel Rekapitulasi Pemeringkatan, dengan bobot C7 terkoreksi.
    let(:expected) do
      [
        { name: "A1 Budi",  d_positive: 0.0178, d_negative: 0.0570, preference: 0.7618, rank: 3 },
        { name: "A2 Andi",  d_positive: 0.0139, d_negative: 0.0623, preference: 0.8182, rank: 2 },
        { name: "A3 Citra", d_positive: 0.0429, d_negative: 0.0330, preference: 0.4350, rank: 4 },
        { name: "A4 Dedi",  d_positive: 0.0709, d_negative: 0.0000, preference: 0.0000, rank: 5 },
        { name: "A5 Eka",   d_positive: 0.0078, d_negative: 0.0696, preference: 0.8988, rank: 1 }
      ]
    end

    it "menghasilkan D+, D-, Vi, dan peringkat sesuai perhitungan manual" do
      expected.each_with_index do |row, index|
        aggregate_failures row[:name] do
          expect(result.distances_positive[index]).to be_within(0.0001).of(row[:d_positive])
          expect(result.distances_negative[index]).to be_within(0.0001).of(row[:d_negative])
          expect(result.preferences[index]).to be_within(0.0001).of(row[:preference])
          expect(result.ranks[index]).to eq(row[:rank])
        end
      end
    end

    it "menempatkan Eka sebagai juara pertama dan Dedi pada peringkat terakhir" do
      order = (0...5).sort_by { |i| -result.preferences[i] }

      expect(order).to eq([ 4, 1, 0, 2, 3 ])
    end

    it "nilai preferensi berada pada rentang 0 sampai 1" do
      expect(result.preferences).to all(be_between(0, 1))
    end

    # Dedi bernilai minimum pada seluruh 10 kriteria, sehingga jaraknya ke
    # solusi ideal negatif nol dan nilai preferensinya nol.
    it "memberi Vi nol pada alternatif yang identik dengan solusi ideal negatif" do
      expect(result.distances_negative[3]).to be_within(0.0001).of(0)
      expect(result.preferences[3]).to eq(0)
    end
  end

  describe "penskalaan bobot" do
    # Sifat ini yang membuat koreksi total bobot dari 105% ke 100% tidak
    # mengubah urutan peringkat: V invariant terhadap penskalaan seragam.
    it "tidak mengubah nilai preferensi bila seluruh bobot diskalakan sama" do
      scaled = described_class.new(
        matrix: decision_matrix,
        weights: weights.map { |w| w * 3 }
      ).call

      expect(scaled.preferences).to match_bab_iv(result.preferences)
    end
  end

  describe "kriteria bertipe cost" do
    it "membalik arah solusi ideal" do
      matrix = [ [ 10, 10 ], [ 20, 20 ] ]
      benefit = described_class.new(matrix: matrix, weights: [ 0.5, 0.5 ], types: %i[benefit benefit]).call
      mixed = described_class.new(matrix: matrix, weights: [ 0.5, 0.5 ], types: %i[benefit cost]).call

      expect(benefit.ranks).to eq([ 2, 1 ])
      # Satu kriteria benefit dan satu cost membuat kedua alternatif seimbang.
      expect(mixed.preferences).to all(be_within(0.0001).of(0.5))
    end
  end

  describe "kasus batas" do
    it "memberi Vi nol saat seluruh alternatif identik, bukan NaN" do
      identical = described_class.new(matrix: [ [ 50, 50 ], [ 50, 50 ] ], weights: [ 0.5, 0.5 ]).call

      expect(identical.preferences).to eq([ 0.0, 0.0 ])
      expect(identical.preferences.any?(&:nan?)).to be(false)
    end

    it "menghasilkan kolom nol saat seluruh nilai kriteria nol, bukan pembagian nol" do
      zero_column = described_class.new(matrix: [ [ 0, 80 ], [ 0, 60 ] ], weights: [ 0.5, 0.5 ]).call

      expect(zero_column.normalized_matrix.map(&:first)).to eq([ 0.0, 0.0 ])
    end

    it "memberi peringkat sama pada nilai preferensi yang sama" do
      tied = described_class.new(
        matrix: [ [ 90, 90 ], [ 60, 60 ], [ 90, 90 ] ],
        weights: [ 0.5, 0.5 ]
      ).call

      expect(tied.ranks).to eq([ 1, 2, 1 ])
    end

    it "menolak baris matriks yang jumlah kriterianya tidak konsisten" do
      expect {
        described_class.new(matrix: [ [ 1, 2 ], [ 3 ] ], weights: [ 0.5, 0.5 ])
      }.to raise_error(TopsisEngine::InvalidInput, /2 nilai kriteria/)
    end

    it "menolak matriks kosong" do
      expect {
        described_class.new(matrix: [], weights: [ 0.5 ])
      }.to raise_error(TopsisEngine::InvalidInput, /tidak boleh kosong/)
    end

    it "menolak tipe kriteria yang tidak dikenal" do
      expect {
        described_class.new(matrix: [ [ 1 ] ], weights: [ 1.0 ], types: [ :maximize ])
      }.to raise_error(TopsisEngine::InvalidInput, /tidak dikenal/)
    end
  end

  # Pembanding array angka dengan toleransi 4 desimal, sesuai presisi yang
  # dipakai sepanjang Bab IV.
  matcher :match_bab_iv do |expected|
    match do |actual|
      actual.size == expected.size &&
        actual.each_with_index.all? { |value, i| (value - expected[i]).abs <= 0.0001 }
    end

    failure_message do |actual|
      "diharapkan #{expected.map { |v| v.round(4) }}\n         tetapi #{actual.map { |v| v.round(4) }}"
    end
  end
end
