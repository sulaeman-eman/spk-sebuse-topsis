class CreateRankingResults < ActiveRecord::Migration[8.1]
  def change
    create_table :ranking_results do |t|
      t.references :topsis_run, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      # Jarak Euclidean terhadap solusi ideal positif dan negatif.
      t.decimal :d_positive, null: false, precision: 12, scale: 8
      t.decimal :d_negative, null: false, precision: 12, scale: 8
      # Nilai preferensi Vi pada rentang 0-1.
      t.decimal :preference_value, null: false, precision: 8, scale: 4
      t.integer :rank, null: false

      t.timestamps
    end

    add_index :ranking_results, [ :topsis_run_id, :rank ]
    add_index :ranking_results, [ :topsis_run_id, :participant_id ], unique: true
  end
end
