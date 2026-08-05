# Manual Pengguna

## Sistem Pendukung Keputusan Penentuan Peringkat Corporate Wellness Program pada Event SEBUSE PT Cahaya Suara Utama dengan Metode TOPSIS

Dokumen ini menjelaskan cara menjalankan dan menggunakan purwarupa aplikasi
Sistem Pendukung Keputusan (SPK) yang dibangun pada penelitian tugas akhir.
Seluruh tangkapan layar diambil dari aplikasi yang berjalan dengan data simulasi
lima peserta sebagaimana tercantum pada Bab IV.

---

## A. Ruang Lingkup Dokumen

Dokumen ini mencakup:

1. Kebutuhan perangkat lunak dan cara pemasangan.
2. Pembagian hak akses tiga aktor sistem.
3. Panduan penggunaan setiap use case (UC-01 sampai UC-10).
4. Rujukan aturan penilaian sepuluh kriteria beserta rumus konversinya.
5. Penanganan masalah yang umum ditemui.

Seluruh use case UC-01 sampai UC-10 telah tersedia pada purwarupa ini.

---

## B. Kebutuhan Sistem

### 1. Perangkat lunak

| Komponen | Versi | Keterangan |
|---|---|---|
| Ruby | 3.3.12 | Dikelola melalui `mise` |
| Ruby on Rails | 8.1.3 | Kerangka kerja aplikasi |
| PostgreSQL | 16 | Basis data |
| Peramban | Chrome, Edge, atau Firefox versi terkini | Antarmuka pengguna |

### 2. Perangkat keras minimum

| Komponen | Spesifikasi |
|---|---|
| Prosesor | Dual core 2 GHz |
| Memori | 4 GB RAM |
| Penyimpanan | 2 GB ruang bebas |

---

## C. Pemasangan dan Menjalankan Aplikasi

Seluruh perintah dijalankan dari direktori utama aplikasi.

### 1. Menyiapkan lingkungan Ruby

```bash
mise install
```

### 2. Memasang pustaka yang dibutuhkan

```bash
bundle install
```

### 3. Menyiapkan basis data beserta data awal

```bash
bin/rails db:create db:migrate db:seed
```

Perintah `db:seed` memuat sepuluh kriteria penilaian beserta bobotnya, satu
event SEBUSE 2026, tiga akun pengguna, dan lima peserta beserta matriks
keputusan sebagaimana Bab IV.

### 4. Menjalankan aplikasi

```bash
bin/rails server
```

Aplikasi dapat diakses melalui peramban pada alamat `http://localhost:3000`.

### 5. Memverifikasi kebenaran perhitungan

```bash
bundle exec rspec
```

Perintah ini menjalankan seluruh pengujian otomatis. Berkas
`spec/services/topsis_engine_spec.rb` secara khusus membandingkan hasil
komputasi sistem dengan perhitungan manual pada Bab IV, meliputi pembagi
normalisasi, matriks R, solusi ideal, jarak Euclidean, dan nilai preferensi.

---

## D. Akun dan Hak Akses

Tiga aktor sistem sesuai use case diagram, dengan kata sandi awal
`sebuse2026` untuk seluruh akun contoh:

| Aktor | Alamat email | Kewenangan |
|---|---|---|
| Super Admin | `superadmin@cahayasuarautama.co.id` | Mengelola akun pengguna (UC-02) dan bobot kriteria (UC-03), serta seluruh kewenangan Admin Panitia |
| Admin Panitia | `panitia@cahayasuarautama.co.id` | Mengelola peserta (UC-04), mengimpor dan mencatat log aktivitas (UC-05), menjalankan pre-processing (UC-06) dan perhitungan TOPSIS (UC-07), mencetak laporan (UC-10) |
| Peserta | `peserta@cahayasuarautama.co.id` | Melihat papan peringkat (UC-08) dan rincian skor pribadi (UC-09) |

Pembatasan hak akses diterapkan pada tingkat pengendali (controller). Pengguna
yang membuka halaman di luar kewenangannya akan dialihkan ke dasbor beserta
pesan peringatan.

---

## E. Alur Kerja Sistem

Urutan penggunaan sistem oleh panitia mengikuti alur berikut:

1. **Kelola Kriteria dan Bobot** (UC-03) — memastikan akumulasi bobot tepat 100%.
2. **Kelola Data Peserta** (UC-04) — mendaftarkan karyawan sebagai alternatif penilaian.
3. **Memasukkan log aktivitas** — melalui unggahan berkas rekap (UC-05) untuk data
   banyak peserta sekaligus, atau pencatatan manual per baris untuk penyesuaian.
4. **Pre-processing Data** (UC-06) — mengonversi log mentah menjadi matriks keputusan (X) berskala 0–100.
5. **Hitung Metode TOPSIS** (UC-07) — menghasilkan nilai preferensi dan peringkat.
6. **Papan Peringkat** (UC-08) — mengumumkan hasil kepada seluruh peserta.
7. **Cetak Laporan** (UC-10) — mengunduh rekapitulasi resmi berformat PDF atau Excel.

Langkah 4 wajib mendahului langkah 5. Apabila perhitungan TOPSIS dijalankan
tanpa matriks keputusan, sistem menolak dan mengarahkan pengguna kembali ke
halaman pre-processing.

---

## F. Panduan Penggunaan

### 1. UC-01 Login

**Aktor:** Super Admin, Admin Panitia, Peserta

**Langkah:**

1. Buka alamat `http://localhost:3000`. Sistem menampilkan halaman login.
2. Masukkan alamat email dan kata sandi.
3. Tekan tombol **Masuk**.

**Hasil:** Sistem memverifikasi kredensial ke basis data, membuat sesi
pengguna, lalu mengarahkan ke dasbor sesuai peran. Apabila kredensial tidak
valid, sistem menampilkan pesan kesalahan dan pengguna tetap di halaman login.

![Halaman login](gambar/01-login.png)

**Gambar 4. 24** Tampilan Halaman Login (UC-01)

---

### 2. Dasbor

**Aktor:** seluruh peran

Dasbor menampilkan ringkasan keadaan event: jumlah peserta, jumlah peserta yang
matriks keputusannya sudah terbentuk, jumlah baris log aktivitas, serta total
bobot kriteria beserta penanda kesiapan perhitungan. Panel kanan menampilkan
lima peringkat teratas hasil perhitungan terakhir dan tautan langkah berikutnya.

Isi dasbor menyesuaikan peran pengguna. Peserta hanya memperoleh tautan menuju
papan peringkat dan rincian skor pribadinya.

![Dasbor Admin Panitia](gambar/02-dasbor-panitia.png)

**Gambar 4. 25** Tampilan Dasbor Admin Panitia

---

### 3. UC-02 Kelola Data Pengguna

**Aktor:** Super Admin

**Langkah:**

1. Pilih menu **Pengguna**.
2. Tekan **Tambah pengguna** untuk membuat akun baru, atau **Ubah** pada baris akun yang akan disunting.
3. Isi nama lengkap, alamat email, peran, dan kata sandi.
4. Tekan **Simpan pengguna**.

**Hasil:** Sistem memvalidasi kelengkapan data serta keunikan alamat email,
lalu menyimpannya ke tabel `users`. Pada penyuntingan, kolom kata sandi yang
dibiarkan kosong tidak mengubah kata sandi lama. Akun yang sedang digunakan
tidak dapat dihapus.

![Kelola data pengguna](gambar/04-data-pengguna.png)

**Gambar 4. 26** Tampilan Kelola Data Pengguna (UC-02)

---

### 4. UC-03 Kelola Kriteria dan Bobot

**Aktor:** Super Admin

**Langkah:**

1. Pilih menu **Kriteria**.
2. Sunting nilai persentase bobot pada kolom **Bobot (%)**.
3. Tekan **Simpan kriteria & bobot**.

**Hasil:** Sistem memeriksa akumulasi seluruh bobot. Apabila totalnya tepat
100%, perubahan disimpan. Apabila tidak, seluruh perubahan dibatalkan dan
sistem menampilkan peringatan agar bobot disesuaikan kembali.

Pemeriksaan dilakukan atas keseluruhan bobot, bukan satu per satu, karena satu
bobot tidak dapat dinilai sahih secara sendirian. Penanda di kanan atas halaman
menunjukkan status kesiapan perhitungan.

![Kelola kriteria dan bobot](gambar/03-kriteria-bobot.png)

**Gambar 4. 27** Tampilan Kelola Kriteria dan Bobot (UC-03)

---

### 5. UC-04 Kelola Data Peserta

**Aktor:** Admin Panitia

**Langkah:**

1. Pilih menu **Peserta**.
2. Tekan **Tambah peserta**.
3. Isi kode alternatif, NIP, nama, dan departemen. Kode alternatif berikutnya diusulkan otomatis oleh sistem.
4. Pilih akun peserta pada kolom **Akun peserta** agar karyawan tersebut dapat membuka rincian skornya sendiri.
5. Tekan **Simpan peserta**.

**Hasil:** Data peserta tersimpan sebagai alternatif penilaian. Kolom **Skor
terisi** menunjukkan kelengkapan matriks keputusan peserta tersebut.

![Kelola data peserta](gambar/05-data-peserta.png)

**Gambar 4. 28** Tampilan Kelola Data Peserta (UC-04)

---

### 6. UC-05 Import Log Activities

**Aktor:** Admin Panitia

**Langkah:**

1. Pilih menu **Impor Log**.
2. Tekan **Unduh template CSV** untuk memperoleh contoh berkas beserta nama kolomnya.
3. Isi berkas mengikuti ketentuan kolom, lalu simpan sebagai CSV, XLSX, atau XLS.
4. Tekan **Choose File** dan pilih berkas yang telah disiapkan.
5. Tekan **Import Data**.

**Hasil:** Sistem memeriksa kelengkapan nama kolom, lalu memvalidasi setiap
baris. Bila seluruh baris memenuhi ketentuan, data disimpan sekaligus dan
tercatat sebagai satu batch. Bila ada satu baris yang tidak memenuhi ketentuan,
seluruh berkas dibatalkan dan sistem menampilkan nomor baris beserta alasan
penolakannya.

Pembatalan menyeluruh ini disengaja: panitia tidak perlu menebak sebagian data
mana yang sudah masuk sebelum memperbaiki berkasnya.

**Ketentuan kolom.** Baris pertama berkas wajib memuat nama kolom. Peserta
dicocokkan melalui kolom NIP, sehingga satu berkas dapat memuat data seluruh
peserta sekaligus. Batas satu unggahan adalah 5.000 baris.

| Kolom | Sifat | Keterangan | Contoh |
|---|---|---|---|
| `nip` | wajib | NIP peserta, harus sudah terdaftar pada event | `CSU-0001` |
| `tanggal` | wajib | Tanggal aktivitas, format YYYY-MM-DD | `2026-03-02` |
| `jenis` | wajib | `cardio`, `strength`, `long_run`, atau `fun_sport` | `cardio` |
| `poin` | wajib | Poin aktivitas | `2` |
| `jarak_km` | opsional | Wajib untuk Long Run agar ketuntasannya terhitung | `10.5` |
| `tautan_bukti` | opsional | Tautan Strava atau foto Timestamp | `https://...` |
| `bukti_valid` | opsional | Penilaian panitia atas bukti, diisi `ya` atau `tidak` | `ya` |

Penulisan jenis aktivitas tidak membedakan huruf besar dan kecil, serta
menerima beberapa bentuk umum seperti `Kardio`, `Long Run`, dan `Fun Sports`.

**Pembatalan batch.** Setiap unggahan tercatat pada panel **Riwayat impor**
beserta jumlah baris dan rentang tanggalnya. Tombol **Batalkan batch** menghapus
seluruh baris dari satu unggahan tanpa mengganggu data dari unggahan lain.

![Import log aktivitas](gambar/13-impor-log.png)

**Gambar 4. 29** Tampilan Import Log Activities (UC-05)

---

### 7. Pencatatan Log Aktivitas secara Manual

**Aktor:** Admin Panitia

**Langkah:**

1. Pada daftar peserta, tekan **Log aktivitas** pada baris peserta yang dimaksud.
2. Tekan **Catat aktivitas**.
3. Isi tanggal, jenis aktivitas, poin, jarak (untuk Long Run), dan tautan bukti.
4. Tandai **Bukti dinyatakan valid oleh panitia** apabila bukti memenuhi syarat.
5. Tekan **Simpan log**.

**Hasil:** Baris log tersimpan sebagai data mentah. Hari yang total poinnya
melampaui kuota harian ditandai pada daftar, dan kelebihannya akan dipangkas
otomatis saat pre-processing dijalankan.

![Log aktivitas peserta](gambar/12-log-aktivitas.png)

**Gambar 4. 30** Tampilan Pencatatan Log Aktivitas Peserta

---

### 8. UC-06 Pre-processing Data

**Aktor:** Admin Panitia

**Langkah:**

1. Pilih menu **Pre-processing**.
2. Periksa panel **Aturan yang diterapkan** untuk memastikan parameter regulasi sudah sesuai.
3. Tekan **Jalankan pre-processing**.

**Hasil:** Sistem memangkas kuota poin harian yang melampaui batas, mengonversi
setiap kriteria ke skala 0–100 menggunakan rumusnya masing-masing, menghitung
penalti pelanggaran aturan beruntun, lalu menyimpan hasilnya sebagai matriks
keputusan (X). Panel bawah halaman menampilkan pratinjau matriks tersebut.

Nilai kriteria C7 tidak ditimpa oleh proses ini karena bersumber dari
pengukuran fisik oleh panitia, bukan dari log olahraga.

![Pre-processing data](gambar/06-preprocessing.png)

**Gambar 4. 31** Tampilan Pre-processing Data dan Matriks Keputusan (UC-06)

---

### 9. UC-07 Hitung Metode TOPSIS

**Aktor:** Admin Panitia

**Langkah:**

1. Pilih menu **TOPSIS**.
2. Tekan **Hitung TOPSIS**.

**Hasil:** Sistem menyusun matriks keputusan dari basis data, menjalankan
seluruh tahapan TOPSIS, lalu menyimpan hasilnya ke tabel `topsis_runs` dan
`ranking_results`. Pengguna langsung diarahkan ke halaman rincian komputasi.

Setiap eksekusi tercatat beserta waktu dan pelaksananya, sehingga riwayat
perhitungan dapat ditelusuri.

![Riwayat perhitungan TOPSIS](gambar/07-riwayat-topsis.png)

**Gambar 4. 32** Tampilan Riwayat Perhitungan TOPSIS (UC-07)

---

### 10. Rincian Komputasi TOPSIS

**Aktor:** Admin Panitia

Halaman ini menampilkan keenam tahapan perhitungan secara berurutan beserta
rumus yang digunakan:

| Langkah | Keluaran | Rumus |
|---|---|---|
| 1 | Matriks keputusan (X) | hasil pre-processing skala 0–100 |
| 2 | Matriks ternormalisasi (R) | rᵢⱼ = xᵢⱼ / √(Σ xᵢⱼ²) |
| 3 | Matriks ternormalisasi terbobot (Y) | yᵢⱼ = wⱼ × rᵢⱼ |
| 4 | Solusi ideal positif dan negatif | A⁺ = maks kolom Y, A⁻ = min kolom Y |
| 5 | Jarak Euclidean | D⁺ᵢ = √(Σ (yᵢⱼ − y⁺ⱼ)²), D⁻ᵢ = √(Σ (yᵢⱼ − y⁻ⱼ)²) |
| 6 | Nilai preferensi | Vᵢ = D⁻ᵢ / (D⁺ᵢ + D⁻ᵢ) |

Seluruh langkah disimpan sebagai cuplikan (*snapshot*) pada saat eksekusi.
Dengan demikian rincian perhitungan dapat ditampilkan tanpa menghitung ulang,
dan hasil perhitungan lama tetap dapat diaudit walaupun bobot kriteria diubah
setelahnya. Bobot yang dipakai saat eksekusi ditampilkan sebagai penanda pada
langkah ketiga.

![Rincian komputasi TOPSIS](gambar/08-rincian-komputasi.png)

**Gambar 4. 33** Tampilan Rincian Komputasi Metode TOPSIS (UC-07)

---

### 11. UC-08 Lihat Papan Peringkat

**Aktor:** Admin Panitia, Peserta

**Langkah:**

1. Pilih menu **Peringkat**.

**Hasil:** Sistem mengambil hasil perhitungan terakhir dan menampilkan seluruh
peserta terurut dari nilai preferensi tertinggi ke terendah, lengkap dengan
jarak solusi ideal positif dan negatif sebagai bentuk transparansi.

Halaman ini terbuka bagi seluruh peran, sesuai tujuan penelitian dalam
menegakkan transparansi hasil kompetisi.

![Papan peringkat](gambar/09-papan-peringkat.png)

**Gambar 4. 34** Tampilan Papan Peringkat (UC-08)

Bagi pengguna dengan peran Peserta, sistem menambahkan panel ringkasan
peringkat pribadi di bagian atas halaman dan menyorot baris peserta yang
bersangkutan pada tabel.

![Papan peringkat dari sudut pandang peserta](gambar/10-peringkat-peserta.png)

**Gambar 4. 35** Tampilan Papan Peringkat pada Akun Peserta (UC-08)

---

### 12. UC-09 Lihat Detail Skor Individu

**Aktor:** Peserta

**Langkah:**

1. Pada papan peringkat atau dasbor, tekan **Detail skor**.

**Hasil:** Sistem menampilkan rincian capaian sepuluh kriteria milik peserta
beserta bobot, batang capaian, dan catatan evaluasi setiap kriteria. Panel atas
menampilkan peringkat, nilai preferensi, serta jarak terhadap kedua solusi
ideal.

Peserta hanya dapat membuka rincian skor miliknya sendiri. Admin Panitia dan
Super Admin dapat membuka rincian skor peserta mana pun untuk keperluan
verifikasi.

![Detail skor individu](gambar/11-detail-skor.png)

**Gambar 4. 36** Tampilan Detail Skor Individu (UC-09)

---

### 13. UC-10 Cetak Laporan Peringkat

**Aktor:** Admin Panitia

**Langkah:**

1. Buka **Papan Peringkat** atau halaman **Rincian Komputasi**.
2. Tekan **Cetak PDF** untuk dokumen resmi, atau **Export Excel** untuk berkas
   yang dapat diolah lebih lanjut.

**Hasil:** Sistem menyusun laporan dari hasil perhitungan yang tersimpan, lalu
mengunduhkan berkasnya ke perangkat pengguna. Nama berkas memuat nama event dan
waktu perhitungan, misalnya
`laporan-peringkat-sebuse-2026-20260806-0403.pdf`, sehingga laporan dari
perhitungan berbeda tidak saling menimpa.

**Isi laporan PDF.** Satu halaman A4 memuat kop nama perusahaan, judul laporan,
keterangan event, tabel hasil pemeringkatan beserta jarak solusi ideal, tabel
kriteria beserta bobot yang tercatat saat perhitungan, serta ruang tanda tangan
ketua panitia.

**Isi laporan Excel.** Berkas memuat tiga lembar kerja:

| Lembar | Isi |
|---|---|
| Peringkat | Keterangan event dan tabel hasil pemeringkatan |
| Matriks Keputusan | Matriks keputusan (X) serta solusi ideal positif dan negatif |
| Kriteria | Sepuluh kriteria beserta jenis dan bobotnya |

Lembar Matriks Keputusan disertakan agar hasil laporan dapat diperiksa ulang
secara manual, tidak hanya dipercaya apa adanya.

![Laporan peringkat berformat PDF](gambar/14-laporan-pdf.png)

**Gambar 4. 37** Keluaran Laporan Pemeringkatan Berformat PDF (UC-10)

---

## G. Rujukan Aturan Penilaian

Sepuluh kriteria penilaian beserta rumus konversinya ke skala 0–100. Seluruh
kriteria bertipe *benefit*, yaitu semakin tinggi nilainya semakin baik.

| Kode | Kriteria | Bobot | Aturan | Rumus konversi |
|---|---|---|---|---|
| C1 | Total Poin Cardio | 20% | 1 sesi = 2 poin, target 3× seminggu, maksimum 24 poin sebulan | (poin didapat / 24) × 100 |
| C2 | Total Poin Strength | 15% | 1 sesi = 2 poin, target 2× seminggu, maksimum 16 poin sebulan | (poin didapat / 16) × 100 |
| C3 | Ketuntasan Long Run | 15% | wajib 10 KM per dua minggu, dua kali sebulan | 2× tuntas = 100, 1× = 50, 0× = 0 |
| C4 | Syarat Mingguan | 10% | minimal 2 cardio + 1 strength per minggu | (minggu patuh / 4) × 100 |
| C5 | Bonus Mingguan | 10% | 3 cardio + 2 strength dalam satu minggu | (minggu bonus / 4) × 100 |
| C6 | Aturan Beruntun | 10% | maksimal 3 hari cardio berturut-turut | 100 − (jumlah rentetan pelanggaran × 25) |
| C7 | Hasil Pengukuran Akhir | 5% | progres berat badan atau BMI pada akhir periode | skor penilaian panitia, skala 0–100 |
| C8 | Poin Fun Sports | 5% | 1 sesi = 1 poin, kuota 4 poin sebulan | (poin didapat / 4) × 100 |
| C9 | Disiplin Harian | 5% | maksimal 4 poin sehari | (hari patuh kuota / hari aktif) × 100 |
| C10 | Kualitas Evidence | 5% | tautan aktif dan foto bukti jelas | (bukti valid / total unggahan) × 100 |

Catatan penting:

1. **Pemangkasan kuota harian.** Total poin dalam satu hari yang melampaui 4
   poin dipangkas secara proporsional, sehingga komposisi cardio dan strength
   peserta tetap terjaga dan hanya totalnya yang berkurang.
2. **Penghitungan pelanggaran C6.** Yang dihitung adalah rentetannya, bukan
   setiap harinya. Cardio empat hari berturut-turut satu kali berarti satu
   pelanggaran, sehingga nilainya 75, bukan 25.
3. **Pembatasan skala.** Nilai dibatasi pada rentang 0 sampai 100. Capaian yang
   melampaui target tetap bernilai 100, dan penalti yang berlebih berhenti di 0.
4. **Kriteria C7.** Tidak diturunkan dari log olahraga karena bersumber dari
   pengukuran badan. Nilainya diisi manual dan tidak ditimpa oleh
   pre-processing.

Seluruh parameter di atas tersimpan pada tingkat event dan dapat diubah melalui
halaman **Event › Ubah aturan** tanpa mengubah kode program.

---

## H. Penanganan Masalah

| Gejala | Penyebab | Penyelesaian |
|---|---|---|
| Peringatan "Total bobot kriteria belum 100%" saat menghitung TOPSIS | Akumulasi bobot kriteria tidak tepat 1,00 | Buka menu **Kriteria**, sesuaikan bobot hingga totalnya 100%, lalu simpan |
| Peringatan "Belum ada matriks keputusan" | Pre-processing belum dijalankan | Buka menu **Pre-processing** dan tekan **Jalankan pre-processing** |
| Peserta tidak muncul pada hasil perhitungan | Skor kriteria peserta belum lengkap | Jalankan pre-processing kembali; peserta dengan baris tidak lengkap sengaja dilewati agar tidak merusak matriks |
| Peserta tidak dapat membuka rincian skornya | Akun pengguna belum ditautkan ke data peserta | Buka **Peserta › Ubah**, pilih akun pada kolom **Akun peserta** |
| Pesan "Anda tidak memiliki hak akses" | Halaman berada di luar kewenangan peran | Masuk menggunakan akun dengan peran yang sesuai |
| Nilai C7 seluruh peserta bernilai 0 | Nilai C7 belum diisi panitia | Isi nilai C7 secara manual; nilai ini memang tidak dihasilkan oleh pre-processing |
| Galat `PG::ConnectionBad` saat menjalankan aplikasi | Layanan PostgreSQL belum berjalan | Jalankan layanan PostgreSQL, lalu ulangi perintah |
| Impor ditolak dengan pesan "Kolom wajib belum lengkap" | Baris pertama berkas tidak memuat keempat nama kolom wajib | Unduh template CSV dan salin baris pertamanya |
| Impor ditolak dengan pesan "NIP ... tidak terdaftar" | NIP pada berkas belum didaftarkan sebagai peserta event ini | Daftarkan peserta melalui UC-04, atau perbaiki penulisan NIP pada berkas |
| Impor ditolak dengan pesan "tanggal ... tidak dikenali" | Kolom tanggal tidak berformat YYYY-MM-DD | Perbaiki format tanggal. Pada Excel, pastikan kolom bertipe Date atau Text yang benar |
| Impor ditolak dengan pesan "Format berkas ... tidak didukung" | Berkas bukan CSV, XLSX, atau XLS | Simpan ulang berkas ke salah satu format tersebut |
| Sebagian data terimpor ganda | Berkas yang sama diunggah dua kali | Batalkan salah satu batch melalui panel Riwayat impor |
| Tombol Cetak PDF tidak muncul | Perhitungan TOPSIS belum pernah dijalankan, atau akun berperan Peserta | Jalankan UC-07 lebih dahulu, dan gunakan akun Admin Panitia |

---

## I. Bahan Siap Tempel untuk Laporan

### 1. Usulan penempatan pada Bab IV

Tangkapan layar pada dokumen ini disarankan ditempatkan sebagai subbab baru
**C.5 Implementasi Antarmuka**, yaitu setelah C.4 Diagram dan sebelum
D. Kelebihan dan Kelemahan Penelitian.

### 2. Penomoran gambar

Penomoran `Gambar 4. 24` sampai `Gambar 4. 37` pada dokumen ini disusun dengan
asumsi urutan gambar Bab IV sebagai berikut:

| Rentang | Isi |
|---|---|
| Gambar 4. 1 | Use Case Diagram (C.1) |
| Gambar 4. 2 – 4. 11 | Activity Diagram UC-01 sampai UC-10 (C.2) |
| Gambar 4. 12 – 4. 21 | Sequence Diagram UC-01 sampai UC-10 (C.3) |
| Gambar 4. 22 – 4. 23 | Class Diagram dan ERD (C.4) |
| Gambar 4. 24 – 4. 37 | Implementasi antarmuka (C.5, dokumen ini) |

Apabila jumlah gambar pada C.4 berbeda, penomoran pada dokumen ini perlu
digeser sesuai keadaan sebenarnya.

### 3. Entri Daftar Gambar

```
Gambar 4. 24 Tampilan Halaman Login (UC-01)
Gambar 4. 25 Tampilan Dasbor Admin Panitia
Gambar 4. 26 Tampilan Kelola Data Pengguna (UC-02)
Gambar 4. 27 Tampilan Kelola Kriteria dan Bobot (UC-03)
Gambar 4. 28 Tampilan Kelola Data Peserta (UC-04)
Gambar 4. 29 Tampilan Import Log Activities (UC-05)
Gambar 4. 30 Tampilan Pencatatan Log Aktivitas Peserta
Gambar 4. 31 Tampilan Pre-processing Data dan Matriks Keputusan (UC-06)
Gambar 4. 32 Tampilan Riwayat Perhitungan TOPSIS (UC-07)
Gambar 4. 33 Tampilan Rincian Komputasi Metode TOPSIS (UC-07)
Gambar 4. 34 Tampilan Papan Peringkat (UC-08)
Gambar 4. 35 Tampilan Papan Peringkat pada Akun Peserta (UC-08)
Gambar 4. 36 Tampilan Detail Skor Individu (UC-09)
Gambar 4. 37 Keluaran Laporan Pemeringkatan Berformat PDF (UC-10)
```

### 4. Berkas gambar

Seluruh berkas tangkapan layar tersimpan pada `docs/gambar/` dengan penamaan
berurutan sesuai pembahasan pada dokumen ini:

| Berkas | Gambar |
|---|---|
| `01-login.png` | Gambar 4. 24 |
| `02-dasbor-panitia.png` | Gambar 4. 25 |
| `04-data-pengguna.png` | Gambar 4. 26 |
| `03-kriteria-bobot.png` | Gambar 4. 27 |
| `05-data-peserta.png` | Gambar 4. 28 |
| `13-impor-log.png` | Gambar 4. 29 |
| `12-log-aktivitas.png` | Gambar 4. 30 |
| `06-preprocessing.png` | Gambar 4. 31 |
| `07-riwayat-topsis.png` | Gambar 4. 32 |
| `08-rincian-komputasi.png` | Gambar 4. 33 |
| `09-papan-peringkat.png` | Gambar 4. 34 |
| `10-peringkat-peserta.png` | Gambar 4. 35 |
| `11-detail-skor.png` | Gambar 4. 36 |
| `14-laporan-pdf.png` | Gambar 4. 37 |

### 5. Bukti kesesuaian perhitungan

Hasil perhitungan sistem pada Gambar 4. 33, Gambar 4. 34, dan Gambar 4. 37
sesuai dengan perhitungan manual pada Bab IV:

| Kode | Peserta | D⁺ | D⁻ | Vᵢ | Peringkat |
|---|---|---|---|---|---|
| A5 | Eka | 0,0078 | 0,0696 | 0,8988 | Juara 1 |
| A2 | Andi | 0,0139 | 0,0623 | 0,8182 | Juara 2 |
| A1 | Budi | 0,0178 | 0,0570 | 0,7618 | Juara 3 |
| A3 | Citra | 0,0429 | 0,0330 | 0,4350 | Peringkat 4 |
| A4 | Dedi | 0,0709 | 0,0000 | 0,0000 | Peringkat 5 |

Nilai di atas berlaku untuk konfigurasi bobot dengan C7 sebesar 5%, sehingga
akumulasi seluruh bobot tepat 100% sesuai syarat UC-03.

Kebenaran angka tersebut dikunci oleh pengujian otomatis pada
`spec/services/topsis_engine_spec.rb`, yang membandingkan keluaran mesin
perhitungan dengan angka perhitungan manual hingga empat angka desimal.
