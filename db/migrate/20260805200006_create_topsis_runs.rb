class CreateTopsisRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :topsis_runs do |t|
      t.references :event, null: false, foreign_key: true
      t.references :executed_by, null: true, foreign_key: { to_table: :users }
      t.datetime :executed_at, null: false

      # Snapshot seluruh langkah komputasi. Dua alasan: rincian perhitungan
      # (UC-07 2.3) bisa ditampilkan tanpa hitung ulang, dan hasil lama tetap
      # auditable walaupun bobot kriteria diubah setelahnya.
      t.jsonb :weights_snapshot, null: false, default: {}
      t.jsonb :decision_matrix, null: false, default: {}
      t.jsonb :normalized_matrix, null: false, default: {}
      t.jsonb :weighted_matrix, null: false, default: {}
      t.jsonb :ideal_positive, null: false, default: {}
      t.jsonb :ideal_negative, null: false, default: {}

      t.timestamps
    end

    add_index :topsis_runs, [ :event_id, :executed_at ]
  end
end
