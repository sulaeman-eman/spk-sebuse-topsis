# Draf Bab V

## Penutup

Dokumen ini merupakan draf untuk mengisi Bab V yang masih kosong. Butir simpulan
disusun agar menjawab ketiga tujuan penelitian pada Bab I secara berurutan,
sedangkan butir saran dipasangkan dengan kelemahan penelitian pada Bab IV
bagian D. Penulis tetap perlu menyesuaikan susunan kalimat dengan gaya penulisan
bab sebelumnya.

---

## BAB V

## PENUTUP

### A. Simpulan

Berdasarkan hasil perancangan, pembangunan, dan pengujian Sistem Pendukung
Keputusan penentuan peringkat Corporate Wellness Program pada event SEBUSE di
PT Cahaya Suara Utama dengan metode TOPSIS, diperoleh simpulan sebagai berikut:

**1. Identifikasi kriteria dan pra-pemrosesan data telah menghasilkan matriks
keputusan yang terukur.** Sepuluh kriteria penilaian aktivitas fisik pada
regulasi laman medicalrjbb.com berhasil diidentifikasi, seluruhnya bertipe
*benefit*, dan masing-masing memperoleh rumus konversi tersendiri menuju skala
seragam 0 sampai 100. Tahap pra-pemrosesan mencakup pemangkasan kuota poin
harian sebesar empat poin, konversi ketuntasan Long Run ke skala biner
diskrit, perhitungan proporsi ketercapaian mingguan, serta penerapan fungsi
penalti terhadap pelanggaran aturan olahraga beruntun. Pada tahap ini
ditemukan pula bahwa akumulasi bobot kriteria semula berjumlah 105%, sehingga
dilakukan koreksi menjadi tepat 100% agar memenuhi syarat pembobotan metode
TOPSIS. Koreksi tersebut tidak mengubah urutan peringkat yang dihasilkan.

**2. Arsitektur perangkat lunak dan pemodelan sistem telah dirancang secara
terstruktur menggunakan UML.** Perancangan mencakup use case diagram dengan
sepuluh use case dan tiga aktor, activity diagram, sequence diagram, class
diagram, serta Entity Relationship Diagram yang diwujudkan menjadi sembilan
tabel basis data. Rancangan memisahkan mesin perhitungan TOPSIS dari lapisan
penyimpanan data, sehingga kebenaran perhitungannya dapat diuji secara mandiri
terhadap perhitungan manual tanpa bergantung pada basis data.

**3. Purwarupa Sistem Pendukung Keputusan berbasis web telah berhasil dibangun
dan menghasilkan pemeringkatan yang objektif serta konsisten.** Sistem
dibangun menggunakan kerangka kerja Ruby on Rails dengan basis data
PostgreSQL, dan telah mewujudkan seluruh sepuluh use case yang dirancang.
Pengujian atas data lima peserta menghasilkan nilai preferensi sebagaimana
tercantum pada tabel berikut, dan nilainya identik dengan perhitungan manual
hingga empat angka desimal:

| Kode | Nama peserta | D⁺ | D⁻ | Nilai Vᵢ | Peringkat |
|---|---|---|---|---|---|
| A5 | Eka | 0,0078 | 0,0696 | 0,8988 | Juara 1 |
| A2 | Andi | 0,0139 | 0,0623 | 0,8182 | Juara 2 |
| A1 | Budi | 0,0178 | 0,0570 | 0,7618 | Juara 3 |
| A3 | Citra | 0,0429 | 0,0330 | 0,4350 | Peringkat 4 |
| A4 | Dedi | 0,0709 | 0,0000 | 0,0000 | Peringkat 5 |

Objektivitas hasil dicapai karena seluruh peserta dinilai oleh satu rangkaian
aturan yang sama, sehingga perbedaan penafsiran regulasi antar anggota panitia
tidak lagi memengaruhi peringkat. Kesesuaian perhitungan sistem terhadap
perhitungan manual dijaga oleh pengujian otomatis yang membandingkan pembagi
normalisasi, matriks ternormalisasi, solusi ideal positif dan negatif, jarak
Euclidean, serta nilai preferensi.

**4. Transparansi penilaian telah terwujud melalui penyajian seluruh tahapan
perhitungan.** Sistem menampilkan keenam tahapan metode TOPSIS beserta
rumusnya, dan setiap peserta dapat membuka rincian capaian sepuluh kriteria
miliknya beserta catatan evaluasinya. Keterbukaan ini menjawab permasalahan
rasa ketidakadilan peserta yang menjadi salah satu latar belakang penelitian.
Selain itu, setiap eksekusi perhitungan menyimpan cuplikan bobot dan seluruh
matriks yang terbentuk, sehingga hasil pemeringkatan pada suatu periode tetap
dapat diperiksa kembali walaupun bobot kriteria disesuaikan pada periode
berikutnya.

### B. Saran

Berdasarkan keterbatasan yang diuraikan pada Bab IV bagian D, diajukan
saran-saran sebagai berikut:

#### 1. Bagi PT Cahaya Suara Utama

a. Menerapkan sistem pada periode SEBUSE berikutnya dengan data seluruh peserta,
agar perilaku sistem pada jumlah alternatif yang sebenarnya dapat diamati.

b. Melakukan pengukuran waktu rekapitulasi sebelum dan sesudah penerapan sistem,
sehingga besaran penghematan waktu dapat dinyatakan berdasarkan data
pengukuran, bukan berdasarkan perkiraan.

c. Melakukan pengujian penerimaan pengguna kepada panitia dan peserta, agar
kesesuaian alur kerja sistem dengan kebiasaan kerja panitia dapat dinilai.

d. Menetapkan secara tertulis rumus perhitungan untuk kriteria C4, C5, C8, C9,
dan C10, karena rumus yang dipakai pada purwarupa masih merupakan penurunan
dari pernyataan umum regulasi.

e. Menambahkan pencatatan hasil pengukuran fisik peserta secara berkala, agar
kriteria C7 dapat dihitung otomatis dan tidak lagi bergantung pada penilaian
manual panitia.

f. Menempatkan sistem pada server perusahaan beserta pengamanan sambungan dan
pencadangan berkala sebelum dipakai pada kegiatan yang sebenarnya.

#### 2. Bagi penelitian selanjutnya

a. Menggabungkan metode TOPSIS dengan metode pembobotan objektif seperti
Analytical Hierarchy Process atau metode entropi, sehingga konsistensi bobot
antar narasumber dapat diukur dan tidak sepenuhnya bergantung pada penilaian
pemangku kepentingan.

b. Melakukan analisis sensitivitas terhadap perubahan bobot kriteria, guna
mengetahui seberapa besar perubahan bobot yang mampu membalikkan urutan
peringkat (*rank reversal*).

c. Menghubungkan sistem secara langsung dengan antarmuka pemrograman aplikasi
laman medicalrjbb.com atau Strava, sehingga tahap penyalinan data dapat
dihilangkan beserta kemungkinan kesalahan yang menyertainya.

d. Membandingkan hasil pemeringkatan metode TOPSIS dengan metode pengambilan
keputusan multikriteria lain, misalnya Simple Additive Weighting, Weighted
Product, atau MOORA, atas data yang sama.

e. Mengembangkan fungsi perbandingan capaian antar periode SEBUSE, agar
perkembangan kebugaran karyawan dari satu periode ke periode berikutnya dapat
diamati oleh manajemen perusahaan.

---

## Catatan bagi Penulis

### 1. Keterkaitan simpulan dengan tujuan penelitian

Ketiga butir pertama simpulan disusun agar berpasangan satu-satu dengan tujuan
penelitian pada Bab I bagian E:

| Tujuan penelitian (Bab I.E) | Simpulan |
|---|---|
| Mengidentifikasi kriteria dan melakukan pra-pemrosesan menjadi matriks keputusan | Butir 1 |
| Merancang arsitektur perangkat lunak dan pemodelan UML | Butir 2 |
| Mengimplementasikan dan menguji purwarupa berbasis web | Butir 3 |

Butir 4 bersifat tambahan dan menjawab latar belakang mengenai transparansi.
Butir tersebut dapat dihapus apabila penulis menghendaki simpulan yang persis
sejumlah tujuan penelitian.

### 2. Hal yang perlu diperiksa demi keselarasan antar bab

| Yang perlu diperiksa | Alasan |
|---|---|
| Nilai Vᵢ pada simpulan butir 3 | Angka pada tabel di atas memakai bobot C7 sebesar 5%. Pastikan Bab III Tabel 3.2 dan Bab IV halaman 42 sampai 47 sudah memakai bobot yang sama, agar tidak ada dua versi angka pada satu skripsi |
| Kalimat pada ABSTRAK | Abstrak saat ini menyatakan sistem "terbukti efektif memangkas waktu rekapitulasi data panitia". Pengukuran waktu belum dilakukan, sedangkan Bab IV.D dan Bab V.B menyatakan hal tersebut sebagai keterbatasan. Sebaiknya kalimat abstrak disesuaikan, misalnya menjadi "dirancang untuk memangkas waktu rekapitulasi", agar tidak bertentangan dengan isi Bab IV dan Bab V |
| Klaim efisiensi pada Bab I | Bab I mengutip temuan penelitian lain mengenai pemotongan waktu hingga 85%. Pastikan penulisannya jelas sebagai temuan penelitian terdahulu, bukan sebagai hasil penelitian ini |
| Jumlah use case yang disebut | Simpulan butir 2 dan 3 menyebut sepuluh use case. Pastikan angkanya sama dengan Bab IV bagian C |
| Jumlah tabel basis data | Simpulan butir 2 menyebut sembilan tabel. Pastikan sama dengan Bab IV bagian C.4 |

### 3. Ketentuan penulisan simpulan

Simpulan tidak boleh memuat informasi yang belum pernah dibahas pada bab
sebelumnya. Seluruh angka pada draf ini sudah muncul pada Bab IV, sehingga aman
dipakai. Apabila penulis menambahkan pernyataan baru, pastikan dasarnya ada pada
bab sebelumnya.

Bagian simpulan dan saran umumnya cukup disajikan dalam dua sampai tiga halaman.
Apabila draf ini terasa terlalu panjang, saran bagi perusahaan butir (f) dan
saran bagi penelitian selanjutnya butir (e) dapat dihilangkan lebih dahulu.
