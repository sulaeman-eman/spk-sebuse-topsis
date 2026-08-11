# Draf Bab IV Bagian D

## Kelebihan dan Kelemahan Penelitian

Dokumen ini merupakan draf untuk mengisi Bab IV bagian D yang masih kosong.
Seluruh pernyataan di dalamnya diturunkan dari keadaan purwarupa yang benar-benar
dibangun, bukan dari perkiraan. Penulis tetap perlu menyesuaikan susunan kalimat
dengan gaya penulisan bab-bab sebelumnya, dan memeriksa kembali butir-butir yang
ditandai sebagai perlu konfirmasi.

---

## D. Kelebihan dan Kelemahan Penelitian

Bagian ini menguraikan keunggulan yang dicapai serta keterbatasan yang masih
melekat pada purwarupa Sistem Pendukung Keputusan yang dibangun. Uraian
keterbatasan disajikan secara terbuka agar penelitian lanjutan memiliki pijakan
yang jelas.

### 1. Kelebihan Penelitian

**a. Kebenaran komputasi terverifikasi terhadap perhitungan manual**

Mesin perhitungan sistem diuji secara otomatis terhadap hasil perhitungan manual
yang tertera pada Bab IV bagian B. Pengujian membandingkan sepuluh pembagi
normalisasi, matriks ternormalisasi (R), solusi ideal positif dan negatif
(A⁺ dan A⁻), jarak Euclidean (D⁺ dan D⁻), serta nilai preferensi (Vᵢ) hingga
empat angka desimal. Dengan demikian kesesuaian hasil sistem terhadap perhitungan
manual bukan berupa pernyataan, melainkan keadaan yang diperiksa ulang setiap
kali program dijalankan.

**b. Transparansi seluruh tahapan perhitungan**

Sistem tidak hanya menampilkan peringkat akhir, tetapi juga keenam tahapan
perhitungan TOPSIS secara berurutan, mulai dari matriks keputusan sampai nilai
preferensi. Setiap peserta pun dapat membuka rincian capaian sepuluh kriteria
miliknya beserta catatan evaluasi tiap kriteria. Keterbukaan ini menjawab
permasalahan rasa ketidakadilan peserta yang diuraikan pada Bab I, karena dasar
penilaian dapat diperiksa sendiri oleh yang dinilai.

**c. Konsistensi penerapan regulasi**

Seluruh aturan penilaian, meliputi pembatasan kuota empat poin per hari,
ketuntasan Long Run, syarat dan bonus mingguan, serta penalti aturan beruntun,
diterjemahkan menjadi satu rangkaian program yang sama bagi setiap peserta.
Perbedaan penafsiran aturan antar anggota panitia, yang mungkin terjadi pada
rekapitulasi semi-manual, tidak lagi memengaruhi hasil penilaian.

**d. Hasil perhitungan tetap dapat diaudit**

Setiap eksekusi perhitungan menyimpan cuplikan lengkap bobot kriteria beserta
seluruh matriks yang terbentuk. Apabila bobot kriteria diubah pada kemudian hari,
hasil perhitungan sebelumnya tetap mencerminkan konfigurasi yang benar-benar
dipakai saat itu. Kemampuan ini tidak dimiliki oleh rekapitulasi berbasis
spreadsheet, yang nilainya berubah seketika ketika rumus atau bobotnya disunting.

**e. Keterpisahan data mentah dari hasil olahan**

Log aktivitas disimpan sebagai baris harian, bukan sebagai nilai agregat.
Akibatnya, pre-processing dapat dijalankan berulang kali tanpa kehilangan data
sumber, dan penyesuaian aturan penilaian dapat langsung dihitung ulang atas data
yang sama. Setiap unggahan berkas juga ditandai secara tersendiri sehingga satu
unggahan yang keliru dapat dibatalkan utuh tanpa mengganggu data lainnya.

**f. Keluwesan terhadap perubahan regulasi**

Dua belas parameter aturan penilaian, antara lain target poin bulanan, kuota
harian, batas hari olahraga beruntun, dan besar penalti, disimpan sebagai data
pada tingkat event. Panitia dapat menyesuaikan aturan melalui antarmuka aplikasi
tanpa perlu mengubah kode program. Sistem karenanya tetap dapat dipakai pada
periode SEBUSE berikutnya walaupun regulasinya diperbarui.

**g. Pembagian hak akses sesuai peran**

Pembatasan kewenangan Super Admin, Admin Panitia, dan Peserta diterapkan pada
tingkat pengendali aplikasi, bukan sekadar disembunyikan pada tampilan menu.
Peserta hanya dapat membuka rincian skor miliknya sendiri, sehingga kerahasiaan
data antar karyawan tetap terjaga.

**h. Implementasi berfungsi sebagai alat verifikasi rancangan**

Proses penerjemahan rancangan menjadi program mengungkap dua ketidakkonsistenan
pada dokumen perancangan yang sebelumnya tidak terdeteksi, yaitu akumulasi bobot
Tabel 3.2 yang berjumlah 105% sementara syarat sistem menuntut tepat 100%, serta
penafsiran penghitungan pelanggaran aturan beruntun. Temuan tersebut muncul
justru karena sistem memvalidasi aturannya sendiri. Hal ini menunjukkan bahwa
tahap implementasi tidak hanya mewujudkan rancangan, tetapi juga menguji
ketepatannya.

### 2. Kelemahan Penelitian

**a. Kriteria C7 belum dapat dihitung otomatis**

Kriteria Hasil Pengukuran Akhir bersumber dari pengukuran berat badan atau BMI
oleh panitia, bukan dari log aktivitas olahraga. Nilainya karena itu masih
dimasukkan secara manual dan bersifat penilaian, sehingga celah subjektivitas
pada kriteria ini belum sepenuhnya tertutup. Bobot kriteria tersebut sebesar 5%,
sehingga pengaruhnya terhadap peringkat akhir relatif kecil, namun tetap ada.

**b. Pengujian baru memakai data simulasi berskala kecil**

Validasi perhitungan dilakukan atas lima peserta sebagai data simulasi,
sedangkan event SEBUSE yang sebenarnya melibatkan lebih dari seratus peserta.
Perilaku sistem pada jumlah alternatif yang sebenarnya, termasuk keterbacaan
tampilan matriks dan waktu pemrosesan, belum diuji.

**c. Belum ada pengukuran empiris atas efisiensi waktu**

Penelitian ini merancang sistem yang ditujukan memangkas waktu rekapitulasi,
tetapi belum melakukan pengukuran pembanding antara waktu rekapitulasi
semi-manual dan waktu pemrosesan melalui sistem. Klaim efisiensi karena itu masih
bersifat rancangan dan belum didukung data pengukuran.

**d. Belum dilakukan pengujian penerimaan pengguna**

Purwarupa belum diujicobakan kepada panitia dan peserta sebagai pengguna
sebenarnya, sehingga aspek kemudahan penggunaan serta kesesuaian alur kerja
dengan kebiasaan panitia belum terukur.

**e. Pembobotan kriteria belum melalui uji konsistensi**

Bobot sepuluh kriteria diperoleh melalui wawancara dengan panitia, tanpa
penerapan metode pembobotan objektif seperti Analytical Hierarchy Process atau
metode entropi. Konsistensi penilaian antar narasumber karena itu belum dapat
diukur, dan bobot yang dipakai masih bergantung pada penilaian pemangku
kepentingan.

**f. Belum ada analisis sensitivitas**

Metode TOPSIS peka terhadap perubahan bobot maupun perubahan susunan alternatif,
yang dalam kepustakaan dikenal sebagai gejala pembalikan peringkat (*rank
reversal*). Penelitian ini belum menguji seberapa besar perubahan bobot yang
mampu mengubah urutan peringkat, sehingga ketahanan hasil terhadap penyesuaian
bobot belum diketahui.

**g. Belum terhubung langsung dengan sumber data aktivitas**

Data aktivitas masuk melalui unggahan berkas rekap atau pencatatan manual, belum
melalui antarmuka pemrograman aplikasi (API) laman medicalrjbb.com maupun Strava.
Masih terdapat langkah penyalinan data di antaranya, yang tetap menyisakan
kemungkinan salah ketik walaupun sistem sudah memvalidasi setiap baris yang
diunggah.

**h. Sebagian rumus konversi merupakan penurunan**

Rumus untuk kriteria C4, C5, C8, C9, dan C10 diturunkan dari pernyataan umum
regulasi, karena dokumen aturan tidak mencantumkan rumus persisnya. Angka
pembanding pada rumus tersebut diletakkan sebagai parameter yang dapat diubah,
namun penetapannya masih perlu dikonfirmasi kepada panitia penyelenggara.

**i. Purwarupa belum dijalankan pada lingkungan produksi**

Sistem baru dijalankan pada lingkungan pengembangan lokal. Aspek yang menyertai
penggunaan sebenarnya, seperti pengamanan sambungan, pencadangan berkala, dan
penanganan akses serentak oleh banyak pengguna, belum diuji.

**j. Cakupan fungsi masih terbatas pada satu event berjalan**

Sistem belum menyediakan perbandingan antar periode SEBUSE, misalnya
perkembangan capaian seorang peserta dari satu periode ke periode berikutnya.
Fungsi tersebut berada di luar batasan masalah penelitian, namun berpotensi
bermanfaat bagi manajemen perusahaan.

---

## Catatan bagi Penulis

### 1. Butir yang perlu dikonfirmasi sebelum dipakai

| Butir | Yang perlu dipastikan |
|---|---|
| Kelemahan (b) | Jumlah peserta SEBUSE yang sebenarnya. Bab III menyebut lebih dari seratus peserta; sesuaikan bila angkanya berbeda |
| Kelemahan (c) dan (d) | Pastikan pengukuran waktu dan pengujian kepada pengguna memang belum dilakukan. Bila sudah, butir ini dipindahkan menjadi kelebihan beserta datanya |
| Kelemahan (h) | Konfirmasi rumus C4, C5, C8, C9, dan C10 kepada panitia. Bila sudah dikonfirmasi, butir ini dapat dihapus |
| Kelebihan (h) | Pastikan koreksi bobot Tabel 3.2 dari 105% menjadi 100% sudah diterapkan pada Bab III sebelum butir ini dipakai |

### 2. Keterkaitan dengan Bab V

Setiap butir kelemahan pada bagian D sebaiknya memiliki pasangan saran pada
Bab V bagian B, sehingga kedua bab saling menyambung. Pemetaan yang disarankan:

| Kelemahan | Saran yang dapat ditulis pada Bab V.B |
|---|---|
| (a) C7 manual | Menambahkan pencatatan hasil pengukuran fisik berkala agar C7 terhitung otomatis |
| (b) data simulasi | Menguji sistem memakai data seluruh peserta pada periode SEBUSE berikutnya |
| (c) efisiensi belum terukur | Mengukur waktu rekapitulasi sebelum dan sesudah penerapan sistem |
| (d) belum ada uji pengguna | Melakukan pengujian penerimaan pengguna kepada panitia dan peserta |
| (e) pembobotan | Menggabungkan TOPSIS dengan AHP agar konsistensi bobot dapat diukur |
| (f) sensitivitas | Melakukan analisis sensitivitas terhadap perubahan bobot kriteria |
| (g) sumber data | Menghubungkan sistem dengan API medicalrjbb.com atau Strava |
| (i) lingkungan produksi | Menempatkan sistem pada server perusahaan beserta pencadangan berkala |
| (j) satu event | Menambahkan laporan perbandingan capaian antar periode |

### 3. Saran penyajian

Bagian D umumnya cukup disajikan dalam dua sampai tiga halaman. Apabila draf ini
terasa terlalu panjang, butir kelebihan (e) dan (g) serta kelemahan (j) dapat
dihilangkan lebih dahulu karena keduanya bersifat pelengkap, sedangkan butir
kelebihan (a), (b), dan (d) sebaiknya dipertahankan karena ketiganya yang paling
langsung menjawab rumusan masalah penelitian.
