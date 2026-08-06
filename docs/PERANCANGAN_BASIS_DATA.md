# Perancangan Basis Data dan Kelas

## Sistem Pendukung Keputusan Penentuan Peringkat Corporate Wellness Program pada Event SEBUSE PT Cahaya Suara Utama dengan Metode TOPSIS

Dokumen ini memuat rancangan struktur data sistem: Entity Relationship Diagram
(ERD), Class Diagram, dan spesifikasi setiap tabel. Isinya disiapkan untuk
melengkapi Bab IV bagian C.4.

Rancangan ini diturunkan dari sequence diagram pada Bab IV.C.3 dan dari rumus
pre-processing pada Bab IV.B.2, kemudian diwujudkan menjadi sembilan tabel pada
basis data PostgreSQL.

---

## A. Entity Relationship Diagram

![Entity Relationship Diagram](gambar/15-erd.png)

**Gambar 4. 22** Entity Relationship Diagram Sistem Pendukung Keputusan SEBUSE

Diagram menampilkan kunci utama, kunci tamu, dan atribut pembeda setiap entitas.
Daftar kolom selengkapnya beserta tipe dan batasannya dimuat pada bagian C
Spesifikasi Tabel. Kolom `parameter_regulasi` pada entitas `events` mewakili dua
belas kolom parameter aturan penilaian, dan `matriks_perhitungan` pada
`topsis_runs` mewakili enam kolom cuplikan langkah perhitungan.

> **Catatan penempatan.** Diagram ini lebih lebar daripada tinggi. Pada halaman
> tegak dengan lebar cetak 190 mm, tulisan di dalamnya hanya berukuran sekitar
> 5 pt sehingga sukar dibaca. Sisipkan diagram pada halaman **mendatar
> (landscape)**, atau gunakan berkas
> `Diagram_Perancangan_A4_landscape.pdf` yang sudah disiapkan pada ukuran
> tersebut.

### 1. Daftar entitas

| No. | Entitas | Peran dalam sistem |
|---|---|---|
| 1 | `users` | Akun pengguna beserta perannya, yaitu Super Admin, Admin Panitia, dan Peserta |
| 2 | `sessions` | Sesi masuk aktif setiap pengguna (UC-01) |
| 3 | `events` | Periode kompetisi SEBUSE beserta seluruh parameter regulasinya |
| 4 | `criteria` | Sepuluh kriteria penilaian beserta bobotnya (UC-03) |
| 5 | `participants` | Karyawan peserta kompetisi, berperan sebagai alternatif penilaian |
| 6 | `activity_logs` | Log aktivitas fisik harian peserta, baik hasil impor maupun input manual |
| 7 | `criterion_scores` | Matriks keputusan (X) hasil pre-processing pada skala 0–100 |
| 8 | `topsis_runs` | Satu kali eksekusi perhitungan TOPSIS beserta cuplikan seluruh langkahnya |
| 9 | `ranking_results` | Hasil peringkat setiap peserta pada satu kali perhitungan |

### 2. Relasi antar entitas

| Relasi | Kardinalitas | Keterangan |
|---|---|---|
| `users` — `sessions` | satu ke banyak | Satu pengguna dapat memiliki beberapa sesi masuk |
| `users` — `participants` | nol atau satu ke banyak | Akun peserta ditautkan ke data peserta agar dapat membuka rincian skornya (UC-09). Peserta boleh belum memiliki akun |
| `users` — `topsis_runs` | nol atau satu ke banyak | Mencatat siapa yang mengeksekusi perhitungan |
| `events` — `participants` | satu ke banyak | Satu event memiliki banyak peserta sebagai alternatif |
| `events` — `topsis_runs` | satu ke banyak | Satu event dapat dihitung berulang kali |
| `participants` — `activity_logs` | satu ke banyak | Satu peserta mencatat banyak baris log aktivitas |
| `participants` — `criterion_scores` | satu ke banyak | Satu peserta memperoleh sepuluh nilai kriteria |
| `criteria` — `criterion_scores` | satu ke banyak | Satu kriteria menilai seluruh peserta |
| `topsis_runs` — `ranking_results` | satu ke banyak | Satu perhitungan menetapkan peringkat seluruh peserta |
| `participants` — `ranking_results` | satu ke banyak | Satu peserta menerima satu hasil pada setiap perhitungan |

### 3. Pertimbangan perancangan

1. **Parameter regulasi disimpan pada tabel `events`, bukan ditulis di dalam
   kode.** Target poin, kuota harian, batas hari beruntun, dan sebelas parameter
   lainnya menjadi kolom tersendiri sehingga panitia dapat menyesuaikan aturan
   melalui antarmuka tanpa mengubah program.

2. **Tabel `activity_logs` menyimpan baris log harian, bukan nilai agregat.**
   Dengan demikian pre-processing dapat dijalankan berulang tanpa kehilangan
   data mentah, dan aturan penilaian dapat diubah lalu dihitung ulang dari data
   yang sama.

3. **Kolom `import_batch_id` menandai setiap unggahan berkas (UC-05).** Satu
   batch impor yang keliru dapat dibatalkan utuh tanpa mengganggu data dari
   unggahan lain.

4. **Tabel `topsis_runs` menyimpan cuplikan seluruh langkah perhitungan dalam
   kolom bertipe `jsonb`.** Dua alasannya: rincian komputasi (UC-07) dapat
   ditampilkan tanpa menghitung ulang, dan hasil perhitungan lama tetap dapat
   diaudit walaupun bobot kriteria diubah setelahnya.

5. **Pemisahan `criterion_scores` dari `activity_logs`** memisahkan data mentah
   dari hasil olahan, sehingga matriks keputusan dapat diperiksa terpisah dari
   sumber datanya.

### 4. Bentuk normalisasi

Seluruh tabel telah memenuhi bentuk normal ketiga (3NF):

| Bentuk | Pemenuhan |
|---|---|
| 1NF | Setiap kolom bernilai atomik dan tidak ada kelompok berulang. Data aktivitas yang jumlahnya tidak tetap dipisah ke tabel `activity_logs`, bukan disimpan sebagai kolom berulang pada tabel peserta |
| 2NF | Setiap kolom bukan kunci bergantung penuh pada kunci utama. Tabel penghubung `criterion_scores` memakai kunci utama tunggal dengan indeks unik gabungan `participant_id` dan `criterion_id` |
| 3NF | Tidak ada ketergantungan transitif. Nama dan bobot kriteria disimpan sekali di tabel `criteria`, tidak diulang pada `criterion_scores`. Nama peserta tidak diulang pada `ranking_results` |

Kolom bertipe `jsonb` pada `topsis_runs` sengaja tidak dinormalisasi menjadi
tabel tersendiri, karena isinya merupakan cuplikan tidak berubah untuk keperluan
audit, bukan data operasional yang akan disunting maupun ditelusuri per elemen.

---

## B. Class Diagram

![Class Diagram](gambar/16-class-diagram.png)

**Gambar 4. 23** Class Diagram Sistem Pendukung Keputusan SEBUSE

Diagram ini pun disarankan disisipkan pada halaman mendatar dengan alasan yang
sama seperti ERD.

Diagram memuat sembilan kelas model yang mewakili tabel basis data, serta lima
kelas layanan (*service object*) yang menampung logika perhitungan sebagaimana
tergambar pada sequence diagram Bab IV.C.3.

### 1. Kelas model

| Kelas | Tabel | Tanggung jawab utama |
|---|---|---|
| `User` | `users` | Autentikasi dan penentuan hak akses melalui `manages_users`, `manages_criteria`, dan `runs_topsis` |
| `Session` | `sessions` | Menyimpan sesi masuk pengguna |
| `Event` | `events` | Menyimpan periode dan parameter regulasi kompetisi |
| `Criterion` | `criteria` | Memvalidasi akumulasi bobot melalui `weights_balanced` dan `update_weights` |
| `Participant` | `participants` | Menyediakan baris matriks keputusan melalui `decision_row` |
| `ActivityLog` | `activity_logs` | Menyimpan log aktivitas mentah |
| `CriterionScore` | `criterion_scores` | Menyimpan elemen matriks keputusan beserta catatan evaluasinya |
| `TopsisRun` | `topsis_runs` | Menyimpan cuplikan perhitungan dan menyediakan `winner` |
| `RankingResult` | `ranking_results` | Menyimpan hasil peringkat dan sebutan juara melalui `award_label` |

### 2. Kelas layanan

| Kelas | Tanggung jawab utama |
|---|---|
| `ActivityLogImport` | Membaca berkas rekap CSV, XLSX, dan XLS, memvalidasi setiap baris, lalu menyimpannya sebagai satu batch (UC-05) |
| `PreprocessingEngine` | Mengubah log mentah menjadi matriks keputusan berskala 0–100, meliputi pemangkasan kuota harian dan penalti aturan beruntun (UC-06) |
| `TopsisEngine` | Melaksanakan keenam tahapan TOPSIS secara murni matematis, tanpa menyentuh basis data (UC-07) |
| `TopsisRunCreator` | Menjembatani basis data dengan `TopsisEngine`, lalu menyimpan hasilnya (UC-07) |
| `ReportGenerator` | Menyusun laporan pemeringkatan berformat PDF dan Excel (UC-10) |

### 3. Pemisahan mesin perhitungan

`TopsisEngine` sengaja tidak memiliki keterkaitan dengan kelas model mana pun.
Masukannya berupa larik angka biasa dan keluarannya berupa objek hasil, sehingga
kebenaran matematikanya dapat diuji langsung terhadap matriks keputusan yang
tertulis pada Bab IV tanpa membuat satu pun data pada basis data.

Hubungan `TopsisRunCreator` dengan `TopsisEngine` digambarkan sebagai
ketergantungan (*dependency*), bukan asosiasi, karena `TopsisRunCreator` hanya
memakai `TopsisEngine` sesaat pada saat perhitungan dijalankan.

Hubungan `TopsisRun` dengan `RankingResult` digambarkan sebagai agregasi
komposisi, karena hasil peringkat tidak bermakna tanpa perhitungan yang
menghasilkannya dan akan terhapus bersama perhitungan tersebut.

---

## C. Spesifikasi Tabel

Tipe data mengikuti PostgreSQL. Kolom `id` pada seluruh tabel merupakan kunci
utama bertipe `bigint` yang bertambah otomatis. Kolom `created_at` dan
`updated_at` bertipe `timestamp` dan tercatat otomatis oleh kerangka kerja,
sehingga tidak diulang pada setiap tabel di bawah.

### Tabel 1. `users`

Nama tabel: `users` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan akun pengguna sistem

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik pengguna |
| 2 | `email_address` | varchar | NOT NULL, unik | Alamat email untuk masuk sistem |
| 3 | `password_digest` | varchar | NOT NULL | Kata sandi tersimpan dalam bentuk sidik (*hash*) bcrypt |
| 4 | `name` | varchar | NOT NULL | Nama lengkap pengguna |
| 5 | `role` | integer | NOT NULL, default 2 | 0 Super Admin, 1 Admin Panitia, 2 Peserta |

### Tabel 2. `sessions`

Nama tabel: `sessions` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan sesi masuk pengguna

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik sesi |
| 2 | `user_id` | bigint | FK ke `users`, NOT NULL | Pemilik sesi |
| 3 | `ip_address` | varchar | boleh kosong | Alamat IP saat masuk |
| 4 | `user_agent` | varchar | boleh kosong | Keterangan peramban yang dipakai |

### Tabel 3. `events`

Nama tabel: `events` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan periode dan parameter regulasi kompetisi

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik event |
| 2 | `name` | varchar | NOT NULL | Nama event, misalnya SEBUSE 2026 |
| 3 | `start_date` | date | NOT NULL | Tanggal mulai, menjadi acuan minggu ke-1 |
| 4 | `end_date` | date | NOT NULL | Tanggal berakhir |
| 5 | `target_cardio` | integer | NOT NULL, default 24 | Target poin cardio sebulan (C1) |
| 6 | `target_strength` | integer | NOT NULL, default 16 | Target poin strength sebulan (C2) |
| 7 | `total_weeks` | integer | NOT NULL, default 4 | Jumlah minggu program (C4 dan C5) |
| 8 | `daily_point_cap` | integer | NOT NULL, default 4 | Kuota poin maksimal per hari (C9) |
| 9 | `streak_penalty_per_violation` | integer | NOT NULL, default 25 | Penalti per rentetan pelanggaran (C6) |
| 10 | `long_run_target_km` | decimal(6,2) | NOT NULL, default 10 | Jarak wajib Long Run (C3) |
| 11 | `weekly_cardio_target` | integer | NOT NULL, default 2 | Syarat cardio per minggu (C4) |
| 12 | `weekly_strength_target` | integer | NOT NULL, default 1 | Syarat strength per minggu (C4) |
| 13 | `bonus_cardio_target` | integer | NOT NULL, default 3 | Syarat cardio untuk bonus (C5) |
| 14 | `bonus_strength_target` | integer | NOT NULL, default 2 | Syarat strength untuk bonus (C5) |
| 15 | `max_consecutive_cardio_days` | integer | NOT NULL, default 3 | Batas hari cardio berturut-turut (C6) |
| 16 | `fun_sport_point_target` | integer | NOT NULL, default 4 | Kuota poin fun sports sebulan (C8) |

### Tabel 4. `criteria`

Nama tabel: `criteria` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan sepuluh kriteria penilaian beserta bobotnya

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik kriteria |
| 2 | `code` | varchar | NOT NULL, unik | Kode kriteria C1 sampai C10 |
| 3 | `name` | varchar | NOT NULL | Nama kriteria penilaian |
| 4 | `weight` | decimal(5,4) | NOT NULL | Bobot desimal, akumulasi seluruhnya harus 1,0 |
| 5 | `criterion_type` | integer | NOT NULL, default 0 | 0 benefit, 1 cost. Seluruh kriteria SEBUSE bertipe benefit |
| 6 | `position` | integer | NOT NULL, unik | Urutan tampil C1 sampai C10 |

### Tabel 5. `participants`

Nama tabel: `participants` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan data peserta sebagai alternatif penilaian

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik peserta |
| 2 | `event_id` | bigint | FK ke `events`, NOT NULL | Event yang diikuti |
| 3 | `user_id` | bigint | FK ke `users`, boleh kosong | Akun peserta, diperlukan untuk membuka rincian skor sendiri |
| 4 | `nip` | varchar | NOT NULL, unik per event | Nomor induk pegawai, dipakai sebagai kunci pencocokan saat impor |
| 5 | `name` | varchar | NOT NULL | Nama peserta |
| 6 | `department` | varchar | boleh kosong | Departemen tempat peserta bekerja |
| 7 | `alternative_code` | varchar | NOT NULL, unik per event | Kode alternatif TOPSIS A1 sampai An |

### Tabel 6. `activity_logs`

Nama tabel: `activity_logs` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan log aktivitas fisik harian peserta

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik log |
| 2 | `participant_id` | bigint | FK ke `participants`, NOT NULL | Peserta pemilik log |
| 3 | `activity_date` | date | NOT NULL | Tanggal pelaksanaan aktivitas |
| 4 | `activity_type` | integer | NOT NULL | 0 cardio, 1 strength, 2 long run, 3 fun sport |
| 5 | `raw_points` | decimal(6,2) | NOT NULL, default 0 | Poin sebelum pemangkasan kuota harian |
| 6 | `distance_km` | decimal(6,2) | boleh kosong | Jarak tempuh, wajib untuk Long Run |
| 7 | `evidence_url` | varchar | boleh kosong | Tautan bukti Strava atau foto Timestamp |
| 8 | `evidence_valid` | boolean | NOT NULL, default false | Penilaian panitia atas keabsahan bukti (C10) |
| 9 | `source` | integer | NOT NULL, default 0 | 0 input manual, 1 hasil impor berkas |
| 10 | `import_batch_id` | uuid | boleh kosong | Penanda batch unggahan agar dapat dibatalkan utuh |

### Tabel 7. `criterion_scores`

Nama tabel: `criterion_scores` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan matriks keputusan (X) hasil pre-processing

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik skor |
| 2 | `participant_id` | bigint | FK ke `participants`, NOT NULL | Peserta yang dinilai |
| 3 | `criterion_id` | bigint | FK ke `criteria`, NOT NULL | Kriteria penilaian |
| 4 | `raw_value` | decimal(10,2) | boleh kosong | Nilai mentah sebelum konversi, misalnya jumlah poin atau jumlah minggu |
| 5 | `normalized_value` | decimal(8,4) | NOT NULL | Nilai hasil konversi pada skala 0 sampai 100 |
| 6 | `notes` | varchar | boleh kosong | Catatan evaluasi yang ditampilkan pada UC-09 |

Indeks unik gabungan `participant_id` dan `criterion_id` mencegah satu peserta
memiliki dua nilai untuk kriteria yang sama.

### Tabel 8. `topsis_runs`

Nama tabel: `topsis_runs` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan satu kali eksekusi perhitungan TOPSIS

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik perhitungan |
| 2 | `event_id` | bigint | FK ke `events`, NOT NULL | Event yang dihitung |
| 3 | `executed_by_id` | bigint | FK ke `users`, boleh kosong | Pengguna yang mengeksekusi perhitungan |
| 4 | `executed_at` | timestamp | NOT NULL | Waktu eksekusi perhitungan |
| 5 | `weights_snapshot` | jsonb | NOT NULL | Bobot kriteria yang dipakai saat eksekusi |
| 6 | `decision_matrix` | jsonb | NOT NULL | Matriks keputusan X |
| 7 | `normalized_matrix` | jsonb | NOT NULL | Matriks ternormalisasi R |
| 8 | `weighted_matrix` | jsonb | NOT NULL | Matriks ternormalisasi terbobot Y |
| 9 | `ideal_positive` | jsonb | NOT NULL | Solusi ideal positif A⁺ |
| 10 | `ideal_negative` | jsonb | NOT NULL | Solusi ideal negatif A⁻ |

### Tabel 9. `ranking_results`

Nama tabel: `ranking_results` &middot; Kunci utama: `id` &middot; Fungsi: menyimpan hasil peringkat setiap peserta

| No. | Nama kolom | Tipe | Batasan | Keterangan |
|---|---|---|---|---|
| 1 | `id` | bigint | PK, auto increment | Pengenal unik hasil |
| 2 | `topsis_run_id` | bigint | FK ke `topsis_runs`, NOT NULL | Perhitungan yang menghasilkan peringkat ini |
| 3 | `participant_id` | bigint | FK ke `participants`, NOT NULL | Peserta yang diperingkatkan |
| 4 | `d_positive` | decimal(12,8) | NOT NULL | Jarak Euclidean terhadap solusi ideal positif (D⁺) |
| 5 | `d_negative` | decimal(12,8) | NOT NULL | Jarak Euclidean terhadap solusi ideal negatif (D⁻) |
| 6 | `preference_value` | decimal(8,4) | NOT NULL | Nilai preferensi Vᵢ pada rentang 0 sampai 1 |
| 7 | `rank` | integer | NOT NULL | Peringkat akhir, 1 untuk nilai preferensi tertinggi |

Indeks unik gabungan `topsis_run_id` dan `participant_id` mencegah satu peserta
memperoleh dua hasil pada perhitungan yang sama.

---

## D. Bahan Siap Tempel untuk Laporan

### 1. Usulan penempatan

Kedua diagram beserta spesifikasi tabel ditempatkan pada **Bab IV bagian C.4
Diagram**, yang saat ini masih kosong. Urutan penyajian yang disarankan:

1. Entity Relationship Diagram beserta penjelasan entitas dan relasinya
2. Spesifikasi tabel, sembilan tabel berurutan
3. Class Diagram beserta penjelasan kelas model dan kelas layanan

### 2. Entri Daftar Gambar

```
Gambar 4. 22 Entity Relationship Diagram Sistem Pendukung Keputusan SEBUSE
Gambar 4. 23 Class Diagram Sistem Pendukung Keputusan SEBUSE
```

### 3. Entri Daftar Tabel

```
Tabel 4. 1 Spesifikasi Tabel users
Tabel 4. 2 Spesifikasi Tabel sessions
Tabel 4. 3 Spesifikasi Tabel events
Tabel 4. 4 Spesifikasi Tabel criteria
Tabel 4. 5 Spesifikasi Tabel participants
Tabel 4. 6 Spesifikasi Tabel activity_logs
Tabel 4. 7 Spesifikasi Tabel criterion_scores
Tabel 4. 8 Spesifikasi Tabel topsis_runs
Tabel 4. 9 Spesifikasi Tabel ranking_results
```

Penomoran tabel di atas mengasumsikan Bab IV belum memuat tabel bernomor
sebelumnya. Apabila tabel rekapitulasi pemeringkatan pada Bab IV.B sudah
diberi nomor, penomoran di atas perlu digeser.

### 4. Berkas gambar

| Berkas | Gambar | Keterangan |
|---|---|---|
| `docs/gambar/15-erd.png` | Gambar 4. 22 | ERD, memuat kunci dan atribut pembeda |
| `docs/gambar/16-class-diagram.png` | Gambar 4. 23 | Class Diagram |
| `docs/gambar/17-erd-lengkap.png` | lampiran, bila diperlukan | ERD dengan seluruh atribut setiap tabel |
| `docs/Diagram_Perancangan_A4_landscape.pdf` | dua halaman | Kedua diagram pada A4 mendatar beserta captionnya, siap disisipkan |

Ketiga gambar dihasilkan dari berkas sumber `docs/diagram/erd.html`,
`docs/diagram/class.html`, dan `docs/diagram/cetak.html`. Berkas tersebut dapat
dibuka langsung di peramban, sehingga diagram dapat disunting bila struktur data
berubah, tanpa perlu menggambar ulang dari nol.

Diagram ditulis memakai notasi Mermaid, sehingga perubahan struktur cukup
dilakukan dengan menyunting teks pada berkas HTML tersebut, lalu memuat ulang
halamannya di peramban.
