class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      # 0 = super_admin, 1 = admin_panitia, 2 = peserta (tiga aktor pada use case diagram)
      t.integer :role, null: false, default: 2

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
