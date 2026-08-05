require "rails_helper"

RSpec.describe Criterion do
  # Bobot tabel 3.2 setelah koreksi C7 dari 10% menjadi 5%.
  WEIGHTS = {
    "C1" => 0.20, "C2" => 0.15, "C3" => 0.15, "C4" => 0.10, "C5" => 0.10,
    "C6" => 0.10, "C7" => 0.05, "C8" => 0.05, "C9" => 0.05, "C10" => 0.05
  }.freeze

  def seed_criteria
    WEIGHTS.each_with_index do |(code, weight), index|
      described_class.create!(code: code, name: "Kriteria #{code}", weight: weight, position: index + 1)
    end
  end

  describe "validasi per kriteria" do
    it "menolak kode di luar format C1, C2, dan seterusnya" do
      criterion = described_class.new(code: "Cardio", name: "Cardio", weight: 0.2, position: 1)

      expect(criterion).not_to be_valid
      expect(criterion.errors[:code]).to be_present
    end

    it "menolak bobot nol atau lebih dari 1" do
      expect(described_class.new(code: "C1", name: "x", weight: 0, position: 1)).not_to be_valid
      expect(described_class.new(code: "C1", name: "x", weight: 1.5, position: 1)).not_to be_valid
    end

    it "menolak kode ganda" do
      seed_criteria
      duplicate = described_class.new(code: "C1", name: "Duplikat", weight: 0.1, position: 99)

      expect(duplicate).not_to be_valid
    end

    it "menetapkan seluruh kriteria SEBUSE bertipe benefit" do
      seed_criteria

      expect(described_class.all).to all(be_benefit)
    end
  end

  # Syarat UC-03: akumulasi bobot harus tepat 100%. Karena satu bobot tidak
  # bisa dinilai valid sendirian, pemeriksaannya dilakukan atas keseluruhan.
  describe "akumulasi bobot" do
    before { seed_criteria }

    it "berjumlah tepat 1,0 pada konfigurasi tabel 3.2 terkoreksi" do
      expect(described_class.total_weight).to eq(1)
      expect(described_class).to be_weights_balanced
    end

    it "tidak seimbang bila satu bobot diubah sepihak" do
      described_class.find_by(code: "C7").update!(weight: 0.10)

      expect(described_class.total_weight).to eq(1.05)
      expect(described_class).not_to be_weights_balanced
    end

    describe ".update_weights" do
      it "menyimpan perubahan bila totalnya tetap 100%" do
        result = described_class.update_weights("C1" => 0.25, "C2" => 0.10)

        expect(result).to be(true)
        expect(described_class.find_by(code: "C1").weight).to eq(0.25)
        expect(described_class).to be_weights_balanced
      end

      it "menolak dan membatalkan perubahan bila total bukan 100%" do
        result = described_class.update_weights("C1" => 0.30)

        expect(result).to be(false)
        expect(described_class.find_by(code: "C1").reload.weight).to eq(0.20)
        expect(described_class.total_weight).to eq(1)
      end
    end
  end

  describe "#label" do
    it "menggabungkan kode dan nama kriteria" do
      criterion = described_class.new(code: "C1", name: "Total Poin Cardio")

      expect(criterion.label).to eq("C1 - Total Poin Cardio")
    end
  end

  describe ".ordered" do
    it "mengurutkan C1 sampai C10 sesuai posisi, bukan urutan alfabet" do
      seed_criteria

      expect(described_class.ordered.pluck(:code)).to eq(WEIGHTS.keys)
    end
  end
end
