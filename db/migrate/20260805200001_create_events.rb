class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false

      # Parameter regulasi SEBUSE (medicalrjbb.com) disimpan per event, bukan
      # dihardcode di engine, supaya panitia bisa mengubah aturan tanpa deploy.
      t.integer :target_cardio, null: false, default: 24
      t.integer :target_strength, null: false, default: 16
      t.integer :total_weeks, null: false, default: 4
      t.integer :daily_point_cap, null: false, default: 4
      t.integer :streak_penalty_per_violation, null: false, default: 25
      t.decimal :long_run_target_km, null: false, default: 10, precision: 6, scale: 2

      t.timestamps
    end
  end
end
