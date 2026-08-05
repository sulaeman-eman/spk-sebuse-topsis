class CreateCriteria < ActiveRecord::Migration[8.1]
  def change
    create_table :criteria do |t|
      t.string :code, null: false
      t.string :name, null: false
      t.decimal :weight, null: false, precision: 5, scale: 4
      # 0 = benefit, 1 = cost. Seluruh 10 kriteria SEBUSE bertipe benefit.
      t.integer :criterion_type, null: false, default: 0
      t.integer :position, null: false

      t.timestamps
    end

    add_index :criteria, :code, unique: true
    add_index :criteria, :position, unique: true
  end
end
