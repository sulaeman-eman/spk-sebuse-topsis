# Be sure to restart your server when you modify this file.

# Inflector default Rails memplural-kan "criterion" menjadi "criterions".
# Dokumen tugas akhir memakai model Criterion dengan tabel criteria, jadi
# bentuk Latin yang benar didaftarkan di sini.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "criterion", "criteria"
end
