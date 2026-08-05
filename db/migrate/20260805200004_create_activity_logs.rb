class CreateActivityLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :activity_logs do |t|
      t.references :participant, null: false, foreign_key: true
      t.date :activity_date, null: false
      # 0 = cardio, 1 = strength, 2 = long_run, 3 = fun_sport
      t.integer :activity_type, null: false
      t.decimal :raw_points, null: false, default: 0, precision: 6, scale: 2
      t.decimal :distance_km, precision: 6, scale: 2
      t.string :evidence_url
      t.boolean :evidence_valid, null: false, default: false
      # 0 = manual (form panitia), 1 = import (unggah CSV/Excel)
      t.integer :source, null: false, default: 0
      # Menandai satu batch unggahan supaya import salah bisa dirollback utuh.
      t.uuid :import_batch_id

      t.timestamps
    end

    add_index :activity_logs, [ :participant_id, :activity_date ]
    add_index :activity_logs, :import_batch_id
  end
end
