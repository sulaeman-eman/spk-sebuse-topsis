class CreateCriterionScores < ActiveRecord::Migration[8.1]
  def change
    create_table :criterion_scores do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :criterion, null: false, foreign_key: true
      # Nilai mentah sebelum konversi (mis. 18 poin cardio, 3 minggu sukses).
      t.decimal :raw_value, precision: 10, scale: 2
      # Hasil pre-processing pada skala 0-100, inilah elemen matriks keputusan X.
      t.decimal :normalized_value, null: false, precision: 8, scale: 4
      # Catatan evaluasi yang ditampilkan pada Detail Skor Individu (UC-09).
      t.string :notes

      t.timestamps
    end

    add_index :criterion_scores, [ :participant_id, :criterion_id ], unique: true
  end
end
