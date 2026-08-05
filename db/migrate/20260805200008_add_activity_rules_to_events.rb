class AddActivityRulesToEvents < ActiveRecord::Migration[8.1]
  def change
    change_table :events, bulk: true do |t|
      # Syarat mingguan C4: minimal 2 cardio + 1 strength per minggu.
      t.integer :weekly_cardio_target, null: false, default: 2
      t.integer :weekly_strength_target, null: false, default: 1

      # Bonus mingguan C5: 3 aerobik + 2 strength dalam satu minggu.
      t.integer :bonus_cardio_target, null: false, default: 3
      t.integer :bonus_strength_target, null: false, default: 2

      # Aturan beruntun C6: maksimal 3 hari cardio berturut-turut.
      t.integer :max_consecutive_cardio_days, null: false, default: 3

      # Kuota fun sports C8: 1 sesi = 1 poin, target santai 4 poin sebulan.
      t.integer :fun_sport_point_target, null: false, default: 4
    end
  end
end
