# SPK SEBUSE — Pemeringkatan Corporate Wellness Program dengan Metode TOPSIS

Purwarupa Sistem Pendukung Keputusan berbasis web untuk menentukan peringkat
peserta event SEBUSE (Sehat, Bugar, Senang) di PT Cahaya Suara Utama,
menggunakan metode *Technique for Order of Preference by Similarity to Ideal
Solution* (TOPSIS).

Dibangun sebagai tugas akhir Program Studi Teknik Informatika, Universitas
Indraprasta PGRI.

## Latar belakang singkat

Penilaian event SEBUSE sebelumnya dilakukan semi-manual dengan spreadsheet
untuk sepuluh kriteria aktivitas fisik, mencakup kuota poin harian, ketuntasan
Long Run, target mingguan, dan proteksi *overtraining*. Proses tersebut lambat,
rawan salah rekap, dan kurang transparan bagi peserta. Sistem ini
mengotomatiskan seluruh perhitungan tersebut dan menampilkan setiap langkahnya.

## Teknologi

| Komponen | Versi |
|---|---|
| Ruby | 3.3.12 (dikelola `mise`) |
| Ruby on Rails | 8.1 |
| PostgreSQL | 16 |
| Pengujian | RSpec |

Antarmuka memakai CSS yang ditulis langsung tanpa kerangka kerja, sehingga
tidak ada tahap *build* aset tambahan.

## Menjalankan

```bash
mise install
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server
```

Aplikasi berjalan di `http://localhost:3000`. Akun contoh dimuat oleh
`db:seed`, kata sandi `sebuse2026` untuk seluruhnya:

| Peran | Email |
|---|---|
| Super Admin | `superadmin@cahayasuarautama.co.id` |
| Admin Panitia | `panitia@cahayasuarautama.co.id` |
| Peserta | `peserta@cahayasuarautama.co.id` |

## Pengujian

```bash
bundle exec rspec
```

`spec/services/topsis_engine_spec.rb` adalah pengujian terpenting: ia
membandingkan keluaran mesin perhitungan dengan hasil hitungan manual pada
Bab IV hingga empat angka desimal, meliputi pembagi normalisasi, matriks R,
solusi ideal, jarak Euclidean, dan nilai preferensi.

## Struktur inti

```
app/services/topsis_engine.rb          kalkulasi TOPSIS, murni matematis
app/services/preprocessing_engine.rb   konversi log mentah ke matriks keputusan
app/services/topsis_run_creator.rb     jembatan basis data dengan mesin hitung
app/services/activity_log_import.rb    pembacaan berkas rekap CSV dan Excel
app/services/report_generator.rb       penyusun laporan PDF dan Excel
docs/MANUAL_PENGGUNA.md                manual pengguna beserta tangkapan layar
docs/Manual_Pengguna_SPK_SEBUSE.pdf    manual siap cetak
```

`TopsisEngine` sengaja tidak menyentuh ActiveRecord agar kebenaran
matematikanya dapat diuji langsung terhadap matriks keputusan pada skripsi
tanpa membuat satu pun record basis data.

## Use case yang sudah tersedia

| Kode | Use case | Status |
|---|---|---|
| UC-01 | Login | selesai |
| UC-02 | Kelola Data Pengguna | selesai |
| UC-03 | Kelola Kriteria dan Bobot | selesai |
| UC-04 | Kelola Data Peserta | selesai |
| UC-05 | Import Log Aktivitas | selesai (CSV, XLSX, XLS, dan input manual) |
| UC-06 | Pre-processing Data | selesai |
| UC-07 | Hitung Metode TOPSIS | selesai |
| UC-08 | Lihat Papan Peringkat | selesai |
| UC-09 | Lihat Detail Skor Individu | selesai |
| UC-10 | Cetak Laporan Peringkat | selesai (PDF dan Excel) |

## Sepuluh kriteria penilaian

Seluruh kriteria bertipe *benefit*. Rumus konversi lengkap beserta contoh
perhitungannya ada pada [manual pengguna](docs/MANUAL_PENGGUNA.md#g-rujukan-aturan-penilaian).

| Kode | Kriteria | Bobot |
|---|---|---|
| C1 | Total Poin Cardio | 20% |
| C2 | Total Poin Strength | 15% |
| C3 | Ketuntasan Long Run | 15% |
| C4 | Syarat Mingguan | 10% |
| C5 | Bonus Mingguan | 10% |
| C6 | Aturan Beruntun | 10% |
| C7 | Hasil Pengukuran Akhir | 5% |
| C8 | Poin Fun Sports | 5% |
| C9 | Disiplin Harian | 5% |
| C10 | Kualitas Evidence | 5% |

Seluruh parameter regulasi (target poin, kuota harian, batas hari beruntun,
dan lainnya) tersimpan pada tingkat event dan dapat diubah melalui antarmuka
tanpa mengubah kode.

## Dokumentasi

- [Manual Pengguna](docs/MANUAL_PENGGUNA.md) — panduan setiap use case beserta tangkapan layar
- [Manual Pengguna (PDF)](docs/Manual_Pengguna_SPK_SEBUSE.pdf) — versi siap cetak, 18 halaman A4
