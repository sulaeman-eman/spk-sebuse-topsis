class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.references :event, null: false, foreign_key: true
      # Nullable: panitia bisa mendata peserta sebelum akun login dibuatkan.
      t.references :user, null: true, foreign_key: true
      t.string :nip, null: false
      t.string :name, null: false
      t.string :department
      # Kode alternatif TOPSIS (A1, A2, ...) seperti pada Bab IV.
      t.string :alternative_code, null: false

      t.timestamps
    end

    add_index :participants, [ :event_id, :nip ], unique: true
    add_index :participants, [ :event_id, :alternative_code ], unique: true
  end
end
