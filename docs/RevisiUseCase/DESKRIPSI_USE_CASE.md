# Deskripsi Use Case

## Bab IV Bagian C.1, Butir a sampai m

Berkas ini memuat seluruh deskripsi use case setelah use case diagram direvisi.
Penulis menyusun ketiga belas deskripsi di dalam satu berkas agar dapat disalin
sekaligus ke dalam laporan tugas akhir.

Naskah sebelumnya memuat sepuluh deskripsi pada butir a sampai j. Naskah ini
memuat tiga belas deskripsi pada butir a sampai m. Penulis mempertahankan
urutan nomor use case, sehingga butir a sampai j tetap menunjuk UC-01 sampai
UC-10, sedangkan butir k, l, dan m menunjuk ketiga use case tambahan.

Ringkasan seluruh perubahan terhadap naskah sebelumnya terdapat pada bagian
akhir berkas ini.

---

### a. Use Case Description Form Login (UC-01)

| | |
|---|---|
| **Use case name** | Login |
| **Scenario** | Memasukkan email dan kata sandi ke sistem untuk otentikasi hak akses |
| **Triggering Event** | Menekan tombol Login |
| **Brief Description** | Suatu use case yang berfungsi untuk memverifikasi otentikasi pengguna, yaitu Super Admin, Admin Panitia, atau Peserta, agar dapat mengakses sistem sesuai peran dan hak aksesnya. |
| **Actors** | Super Admin, Admin Panitia, Peserta |
| **Stake Holders** | Super Admin, Admin Panitia, Peserta |
| **Precondition** | Aktor belum masuk ke sistem dan berada di halaman login |
| **Post Condition** | Aktor berhasil terautentikasi, kemudian sistem mengarahkannya ke halaman dasbor utama aplikasi |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Membuka halaman login | 1.1 Menampilkan halaman formulir login |
| 2. Memasukkan email dan kata sandi | |
| 3. Menekan tombol Login | 3.1 Memvalidasi data kredensial dengan basis data<br>3.2 Jika data valid, sistem membuat sesi pengguna dan mengarahkan ke dasbor utama<br>3.3 Jika data tidak valid, sistem menampilkan pesan kesalahan dan kembali ke halaman login |

---

### b. Use Case Description Form Data Pengguna (UC-02)

| | |
|---|---|
| **Use case name** | Kelola Data Pengguna |
| **Scenario** | Melakukan tambah, ubah, dan hapus data akun pengguna sistem, yaitu Admin Panitia dan Peserta |
| **Triggering Event** | Menekan tombol Simpan, Ubah, atau Hapus data pengguna |
| **Brief Description** | Suatu use case yang berfungsi untuk mengelola master akun pengguna yang berhak mengakses aplikasi. |
| **Actors** | Super Admin |
| **Stake Holders** | Super Admin, Admin Panitia, Peserta |
| **Precondition** | Super Admin telah berhasil login dan memilih menu Data Pengguna |
| **Post Condition** | Data akun pengguna berhasil tersimpan, diperbarui, atau dihapus di dalam basis data |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih menu Data Pengguna | 1.1 Menampilkan daftar akun pengguna dan formulir kelola pengguna |
| 2. Memasukkan data pengguna, yaitu Nama, Email, Kata Sandi, dan Peran | |
| 3. Menekan tombol Simpan | 3.1 Memvalidasi kelengkapan data serta keunikan alamat email<br>3.2 Jika data valid, sistem menyimpan data ke basis data dan memperbarui daftar pengguna<br>3.3 Jika data tidak valid, sistem menampilkan notifikasi kesalahan isian<br>3.4 Jika akun yang dihapus sedang digunakan, sistem menolak penghapusan tersebut |

---

### c. Use Case Description Form Kriteria dan Bobot (UC-03)

| | |
|---|---|
| **Use case name** | Kelola Kriteria dan Bobot |
| **Scenario** | Memasukkan dan memperbarui persentase bobot untuk sepuluh kriteria penilaian, yaitu C1 sampai C10 |
| **Triggering Event** | Menekan tombol Simpan Kriteria dan Bobot |
| **Brief Description** | Suatu use case yang berfungsi mengonfigurasi sepuluh kriteria penilaian beserta nilai persentase bobot yang digunakan pada perhitungan algoritma TOPSIS. |
| **Actors** | Super Admin |
| **Stake Holders** | Super Admin, Admin Panitia, Peserta |
| **Precondition** | Super Admin telah login dan mengakses halaman Kelola Kriteria dan Bobot |
| **Post Condition** | Data persentase bobot kriteria tersimpan dan siap digunakan untuk kalkulasi TOPSIS |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih menu Kriteria dan Bobot | 1.1 Menampilkan daftar sepuluh kriteria beserta jenis dan bobot yang berlaku |
| 2. Mengisi atau mengubah nilai persentase bobot kriteria | |
| 3. Menekan tombol Simpan | 3.1 Memvalidasi total akumulasi bobot, yang harus bernilai 100% atau 1,0<br>3.2 Jika total bobot valid, sistem menyimpan data ke basis data<br>3.3 Jika total bobot tidak bernilai 100%, sistem membatalkan seluruh perubahan dan menampilkan pesan peringatan agar bobot disesuaikan kembali |

---

### d. Use Case Description Form Data Peserta (UC-04)

| | |
|---|---|
| **Use case name** | Kelola Data Peserta |
| **Scenario** | Melakukan tambah, ubah, dan hapus data profil peserta yang menjadi alternatif penilaian |
| **Triggering Event** | Menekan tombol Tambah atau Simpan Peserta |
| **Brief Description** | Suatu use case yang berfungsi mengelola data master profil peserta karyawan yang menjadi alternatif pada kompetisi. |
| **Actors** | Admin Panitia |
| **Stake Holders** | Admin Panitia, Peserta |
| **Precondition** | Admin Panitia telah login dan memilih menu Kelola Data Peserta |
| **Post Condition** | Data alternatif peserta berhasil tersimpan di dalam basis data |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih menu Data Peserta | 1.1 Menampilkan daftar peserta dan formulir input data peserta<br>1.2 Mengusulkan kode alternatif berikutnya secara otomatis |
| 2. Memasukkan data profil peserta, yaitu Kode Alternatif, NIP, Nama, Departemen, dan Akun Peserta | |
| 3. Menekan tombol Simpan | 3.1 Memvalidasi format dan kelengkapan data peserta<br>3.2 Jika data valid, sistem menyimpan profil peserta ke basis data<br>3.3 Jika data tidak valid, sistem meminta pengguna melengkapi isian formulir |

---

### e. Use Case Description Form Impor Log Aktivitas (UC-05)

| | |
|---|---|
| **Use case name** | Impor Log Aktivitas |
| **Scenario** | Mengunggah berkas rekap log aktivitas fisik peserta dari medicalrjbb.com, Strava, atau Timestamp |
| **Triggering Event** | Menekan tombol Import Data |
| **Brief Description** | Suatu use case yang berfungsi memuat data mentah pencapaian olahraga harian seluruh peserta melalui satu berkas rekap berformat CSV, XLSX, atau XLS. Sistem mencocokkan setiap baris dengan peserta melalui kolom NIP. |
| **Actors** | Admin Panitia |
| **Stake Holders** | Admin Panitia, Peserta |
| **Precondition** | Admin Panitia telah login dan membuka menu Impor Log Aktivitas |
| **Post Condition** | Data mentah log aktivitas tersimpan di basis data sebagai satu batch dan siap di-*pre-processing* |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih menu Impor Log Aktivitas | 1.1 Menampilkan formulir unggah berkas beserta ketentuan kolom dan riwayat impor |
| 2. Memilih berkas rekap log aktivitas fisik peserta | |
| 3. Menekan tombol Import Data | 3.1 Memeriksa format berkas serta kelengkapan nama kolom wajib<br>3.2 Memvalidasi setiap baris, meliputi kesesuaian NIP, format tanggal, jenis aktivitas, dan nilai poin<br>3.3 Jika seluruh baris valid, sistem menyimpan data mentah ke basis data beserta penanda batch<br>3.4 Jika terdapat satu baris yang tidak valid, sistem membatalkan seluruh berkas dan menampilkan nomor baris beserta alasan penolakannya |
| 4. Menekan tombol Batalkan Batch apabila berkas yang diunggah keliru | 4.1 Menghapus seluruh baris dari batch tersebut tanpa mengganggu data dari unggahan lain |

---

### f. Use Case Description Form Pre-processing Data (UC-06)

| | |
|---|---|
| **Use case name** | Pre-processing Data |
| **Scenario** | Mengonversi data mentah ke skala 0 sampai 100, memotong kuota poin harian yang melebihi empat poin, dan menghitung penalti *overtraining* |
| **Triggering Event** | Menekan tombol Jalankan Pre-processing |
| **Brief Description** | Suatu use case yang berfungsi mengubah data mentah menjadi Matriks Keputusan (X) berskala 0 sampai 100 sesuai aturan bisnis SEBUSE. |
| **Actors** | Admin Panitia |
| **Stake Holders** | Admin Panitia, Peserta |
| **Precondition** | Data log aktivitas mentah telah berhasil diimpor atau dicatat ke dalam sistem |
| **Post Condition** | Terbentuk Matriks Keputusan (X) bernilai skala 0 sampai 100 yang siap diproses oleh algoritma TOPSIS |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih menu Pre-processing Data | 1.1 Menampilkan aturan penilaian yang berlaku beserta ringkasan log data mentah |
| 2. Menekan tombol Jalankan Pre-processing | 2.1 Memangkas kuota poin harian yang melebihi empat poin secara proporsional<br>2.2 Memproses konversi rumus matematika sepuluh kriteria ke skala 0 sampai 100, termasuk fungsi penalti kriteria C6<br>2.3 Melewati peserta yang belum memiliki log aktivitas namun skornya sudah terisi, agar nilai yang dimasukkan langsung tidak tertimpa<br>2.4 Menyimpan hasil konversi ke Matriks Keputusan (X)<br>2.5 Menampilkan tabel pratinjau Matriks Keputusan (X) beserta catatan evaluasi setiap nilai |

---

### g. Use Case Description Form Topsis (UC-07)

| | |
|---|---|
| **Use case name** | Hitung Metode TOPSIS |
| **Scenario** | Mengeksekusi kalkulasi normalisasi (R), matriks terbobot (Y), solusi ideal (A⁺ dan A⁻), jarak Euclidean (D⁺ dan D⁻), serta nilai preferensi (Vᵢ) |
| **Triggering Event** | Menekan tombol Hitung TOPSIS |
| **Brief Description** | Suatu use case yang berfungsi melakukan komputasi algoritma TOPSIS secara otomatis untuk menentukan nilai preferensi kedekatan relatif setiap peserta. |
| **Actors** | Admin Panitia |
| **Stake Holders** | Admin Panitia, Peserta |
| **Precondition** | Matriks Keputusan (X) hasil pre-processing telah terbentuk, dan akumulasi bobot kriteria bernilai tepat 100% |
| **Post Condition** | Nilai preferensi kedekatan (Vᵢ) terhitung, urutan peringkat peserta tersimpan, dan sistem menampilkan rincian komputasinya |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih menu Perhitungan TOPSIS | 1.1 Menampilkan riwayat perhitungan beserta tombol Hitung TOPSIS |
| 2. Menekan tombol Hitung TOPSIS | 2.1 Memeriksa kesiapan Matriks Keputusan dan akumulasi bobot kriteria<br>2.2 Menghitung Matriks Ternormalisasi (R), Matriks Terbobot (Y), Solusi Ideal (A⁺ dan A⁻), serta Jarak Euclidean (D⁺ dan D⁻)<br>2.3 Menghitung Nilai Preferensi (Vᵢ) dan mengurutkan peringkat<br>2.4 Menyimpan hasil beserta cuplikan seluruh matriks ke basis data<br>2.5 Menampilkan rincian komputasi sebagaimana UC-13<br>2.6 Jika prasyarat belum terpenuhi, sistem menolak perhitungan dan mengarahkan pengguna ke halaman pre-processing atau halaman kriteria |

---

### h. Use Case Description Form Leaderboard (UC-08)

| | |
|---|---|
| **Use case name** | Lihat Papan Peringkat (*Leaderboard*) |
| **Scenario** | Menampilkan urutan pemenang event SEBUSE dari nilai preferensi kedekatan Vᵢ tertinggi ke terendah |
| **Triggering Event** | Menekan menu Papan Peringkat |
| **Brief Description** | Suatu use case yang menyajikan tabel papan peringkat hasil kompetisi secara transparan. |
| **Actors** | Admin Panitia, Peserta |
| **Stake Holders** | Admin Panitia, Peserta, Manajemen Perusahaan |
| **Precondition** | Perhitungan TOPSIS telah selesai dieksekusi oleh Admin Panitia |
| **Post Condition** | Pengguna dapat melihat daftar urutan juara beserta skor preferensi Vᵢ |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih menu Papan Peringkat | 1.1 Mengambil data hasil pemeringkatan terakhir dari basis data<br>1.2 Menampilkan tabel *leaderboard* terurut beserta jarak solusi ideal dan nilai preferensi Vᵢ<br>1.3 Jika pengguna berperan sebagai Peserta, sistem menyorot baris peserta tersebut dan menampilkan ringkasan peringkat pribadinya<br>1.4 Jika perhitungan belum pernah dijalankan, sistem menampilkan pemberitahuan bahwa hasil belum tersedia |

---

### i. Use Case Description Form Detail Skor (UC-09)

| | |
|---|---|
| **Use case name** | Lihat Detail Skor Individu |
| **Scenario** | Menampilkan rincian pencapaian skor sepuluh kriteria, yaitu C1 sampai C10, milik seorang peserta |
| **Triggering Event** | Menekan tombol Detail Skor |
| **Brief Description** | Suatu use case yang menyajikan *breakdown* skor per kriteria. Peserta hanya dapat membuka rincian skor miliknya sendiri, sedangkan Admin Panitia dapat membuka rincian skor peserta mana pun untuk keperluan verifikasi. |
| **Actors** | Peserta, Admin Panitia |
| **Stake Holders** | Peserta, Admin Panitia |
| **Precondition** | Peserta telah login dan membuka halaman Papan Peringkat atau Dasbor |
| **Post Condition** | Sistem menampilkan halaman rincian skor per kriteria milik peserta yang bersangkutan |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Menekan tombol Lihat Detail Skor | 1.1 Memeriksa hak akses pengguna atas data peserta yang diminta<br>1.2 Mengambil data pencapaian sepuluh kriteria milik peserta<br>1.3 Menampilkan *breakdown* skor C1 sampai C10 beserta bobot dan catatan evaluasi<br>1.4 Menampilkan peringkat, nilai preferensi, dan jarak terhadap kedua solusi ideal<br>1.5 Jika Peserta membuka rincian skor peserta lain, sistem menolak permintaan tersebut |

---

### j. Use Case Description Form Cetak Laporan (UC-10)

| | |
|---|---|
| **Use case name** | Cetak Laporan Peringkat |
| **Scenario** | Mencetak atau mengunduh dokumen laporan resmi hasil pemeringkatan ke format PDF atau Excel |
| **Triggering Event** | Menekan tombol Cetak PDF atau Export Excel |
| **Brief Description** | Suatu use case yang berfungsi merekap hasil akhir pemeringkatan SEBUSE ke dalam berkas cetak atau unduhan resmi. |
| **Actors** | Admin Panitia |
| **Stake Holders** | Admin Panitia, Manajemen Perusahaan |
| **Precondition** | Admin Panitia berada pada halaman Papan Peringkat yang memiliki data hasil TOPSIS |
| **Post Condition** | Berkas laporan resmi pemeringkatan terunduh dalam format PDF atau Excel |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih tombol Cetak Laporan | 1.1 Menyiapkan format tata letak dokumen laporan |
| 2. Memilih format unduhan, yaitu PDF atau Excel | 2.1 Mengambil data pemeringkatan beserta cuplikan bobot yang dipakai saat perhitungan<br>2.2 Mengonversi data pemeringkatan ke dalam berkas dokumen<br>2.3 Mengunduh berkas laporan secara otomatis ke perangkat pengguna |

---

### k. Use Case Description Form Aturan Event (UC-11)

| | |
|---|---|
| **Use case name** | Kelola Aturan Event |
| **Scenario** | Mengubah parameter regulasi penilaian yang digunakan oleh mesin pre-processing |
| **Triggering Event** | Menekan tombol Simpan Aturan |
| **Brief Description** | Suatu use case yang berfungsi menyesuaikan dua belas parameter regulasi event, meliputi target poin bulanan, kuota poin harian, syarat mingguan, batas hari olahraga beruntun, dan besar penalti, tanpa mengubah kode program. |
| **Actors** | Admin Panitia |
| **Stake Holders** | Admin Panitia, Peserta, Manajemen Perusahaan |
| **Precondition** | Admin Panitia telah login dan membuka halaman Event |
| **Post Condition** | Parameter regulasi tersimpan dan langsung digunakan pada pre-processing berikutnya |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Memilih menu Event, kemudian menekan tombol Ubah Aturan | 1.1 Menampilkan formulir parameter regulasi beserta nilai yang berlaku |
| 2. Mengubah nilai parameter yang diperlukan | |
| 3. Menekan tombol Simpan Aturan | 3.1 Memvalidasi setiap parameter agar bernilai lebih besar dari nol<br>3.2 Jika data valid, sistem menyimpan parameter dan menampilkan halaman event<br>3.3 Jika data tidak valid, sistem menampilkan pesan kesalahan pada formulir |

---

### l. Use Case Description Form Catat Log Manual (UC-12)

| | |
|---|---|
| **Use case name** | Catat Log Aktivitas Manual |
| **Scenario** | Mencatat satu baris log aktivitas fisik peserta melalui formulir |
| **Triggering Event** | Menekan tombol Simpan Log |
| **Brief Description** | Suatu use case yang berfungsi mencatat log aktivitas satu per satu. Use case ini digunakan untuk penyesuaian data atau untuk peserta yang datanya tidak tercakup pada berkas rekap. |
| **Actors** | Admin Panitia |
| **Stake Holders** | Admin Panitia, Peserta |
| **Precondition** | Admin Panitia telah login dan membuka daftar log aktivitas seorang peserta |
| **Post Condition** | Satu baris log aktivitas tersimpan beserta penanda sumber manual |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Menekan tombol Catat Aktivitas | 1.1 Menampilkan formulir log aktivitas |
| 2. Mengisi tanggal, jenis aktivitas, poin, jarak, dan tautan bukti | |
| 3. Menekan tombol Simpan Log | 3.1 Memvalidasi kelengkapan dan kewajaran nilai yang diisikan<br>3.2 Jika data valid, sistem menyimpan log beserta penanda sumber manual<br>3.3 Jika data tidak valid, sistem menampilkan pesan kesalahan<br>3.4 Menandai hari yang total poinnya melampaui kuota empat poin pada daftar log |

---

### m. Use Case Description Form Rincian Komputasi (UC-13)

| | |
|---|---|
| **Use case name** | Lihat Rincian Komputasi |
| **Scenario** | Menampilkan keenam tahapan perhitungan TOPSIS beserta rumus yang digunakan |
| **Triggering Event** | Selesainya perhitungan TOPSIS, atau menekan tautan Rincian Komputasi pada riwayat perhitungan |
| **Brief Description** | Suatu use case yang berfungsi menyajikan Matriks Keputusan (X), Matriks Ternormalisasi (R), Matriks Terbobot (Y), Solusi Ideal (A⁺ dan A⁻), Jarak Euclidean (D⁺ dan D⁻), serta Nilai Preferensi (Vᵢ) dari cuplikan yang tersimpan pada saat perhitungan dijalankan. |
| **Actors** | Admin Panitia |
| **Stake Holders** | Admin Panitia, Peserta, Manajemen Perusahaan |
| **Precondition** | Perhitungan TOPSIS telah dijalankan sekurang-kurangnya satu kali |
| **Post Condition** | Seluruh tahapan perhitungan tersaji beserta bobot yang digunakan saat eksekusi |

**Flows Of Activity**

| Actors | System |
|---|---|
| 1. Menyelesaikan UC-07, atau memilih satu baris pada riwayat perhitungan | 1.1 Mengambil cuplikan perhitungan dari tabel `topsis_runs`<br>1.2 Menampilkan Matriks Keputusan (X), Matriks Ternormalisasi (R), dan Matriks Terbobot (Y) secara berurutan<br>1.3 Menampilkan Solusi Ideal Positif dan Negatif<br>1.4 Menampilkan Jarak Euclidean, Nilai Preferensi, dan peringkat setiap peserta<br>1.5 Menampilkan bobot kriteria yang digunakan pada saat perhitungan dijalankan |

---

## Ringkasan Perubahan terhadap Naskah Sebelumnya

Penulis mencatat seluruh perubahan pada tabel berikut agar dapat diperiksa
kembali oleh dosen pembimbing.

### 1. Penambahan use case

| Butir | Use case | Alasan penambahan |
|---|---|---|
| k | UC-11 Kelola Aturan Event | Sistem menyediakan halaman pengubahan dua belas parameter regulasi, namun fungsi tersebut belum dimodelkan |
| l | UC-12 Catat Log Aktivitas Manual | Sistem menyediakan formulir pencatatan log per baris, sedangkan UC-05 hanya menangani pengunggahan berkas |
| m | UC-13 Lihat Rincian Komputasi | Sistem selalu menampilkan keenam tahapan perhitungan setelah UC-07 selesai, dan halaman tersebut dapat dibuka kembali melalui riwayat |

### 2. Pembetulan kekeliruan salin pada naskah sebelumnya

| Butir | Bagian | Isi sebelumnya | Isi setelah pembetulan |
|---|---|---|---|
| c (UC-03) | Flows Of Activity, langkah 1.1 | Menampilkan daftar akun pengguna dan form kelola pengguna | Menampilkan daftar sepuluh kriteria beserta jenis dan bobot yang berlaku |
| d (UC-04) | Scenario | Memasukkan dan memperbarui persentase bobot untuk 10 kriteria penilaian | Melakukan tambah, ubah, dan hapus data profil peserta yang menjadi alternatif penilaian |
| g (UC-07) | Flows Of Activity, langkah 1.1 | Menampilkan daftar akun pengguna dan form kelola pengguna | Menampilkan riwayat perhitungan beserta tombol Hitung TOPSIS |

Ketiga isi sebelumnya merupakan kalimat yang tersalin dari deskripsi UC-02 dan
UC-03, sehingga tidak sesuai dengan use case yang bersangkutan.

### 3. Penyesuaian isi agar sesuai sistem

| Butir | Bagian | Penyesuaian |
|---|---|---|
| e (UC-05) | Use case name | Import Log Activities menjadi Impor Log Aktivitas |
| e (UC-05) | Brief Description | Ditambahi keterangan format berkas CSV, XLSX, dan XLS, serta pencocokan peserta melalui kolom NIP |
| e (UC-05) | Flows Of Activity | Ditambahi langkah pembatalan seluruh berkas bila ada baris tidak valid, dan langkah pembatalan batch |
| f (UC-06) | Actors | System (di-trigger oleh Admin Panitia) menjadi Admin Panitia, karena kaidah UML menempatkan sistem sebagai pelaksana, bukan aktor |
| f (UC-06) | Flows Of Activity | Ditambahi langkah pelewatan peserta yang belum memiliki log namun skornya sudah terisi |
| g (UC-07) | Precondition | Ditambahi syarat akumulasi bobot kriteria bernilai tepat 100% |
| g (UC-07) | Flows Of Activity | Ditambahi langkah penolakan bila prasyarat belum terpenuhi, dan langkah penampilan rincian komputasi |
| i (UC-09) | Actors | Peserta menjadi Peserta dan Admin Panitia |
| i (UC-09) | Brief Description | Ditambahi keterangan pembatasan akses, yaitu Peserta hanya dapat membuka rincian miliknya sendiri |
| a sampai m | Nama kolom | Trigering Event menjadi Triggering Event, karena penulisan sebelumnya kurang satu huruf g |

---

## Catatan Penyalinan

Penulis menyarankan langkah penyalinan berikut agar bentuk tabel tetap terjaga
saat dipindahkan ke pengolah kata.

1. Buka berkas `revisi-deskripsi-use-case.html` pada peramban.
2. Pilih seluruh isi halaman, kemudian salin.
3. Tempelkan ke dokumen pengolah kata memakai pilihan *Keep Source Formatting*.
4. Sesuaikan jenis dan ukuran huruf tabel dengan ketentuan penulisan tugas akhir.

Tanda `<br>` pada berkas Markdown menyatakan pindah baris di dalam satu sel
tabel. Tanda tersebut tidak akan tampil pada berkas HTML maupun PDF.
