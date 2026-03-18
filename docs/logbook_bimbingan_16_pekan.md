# Logbook Bimbingan Penelitian 16 Pekan

## Identitas Penelitian

- Nama Mahasiswa: [Isi Nama]
- NIM: [Isi NIM]
- Program Studi: [Isi Prodi]
- Judul Penelitian: Analisis Komparatif Kinerja GUI dan VUI pada Aplikasi Pemesanan Hotel Berbasis Flutter (Qora)
- Dosen Pembimbing: [Isi Nama Dosen]
- Periode: 16 Pekan

## Tujuan Umum

Menyusun, mengembangkan, dan mengevaluasi sistem Qora untuk membandingkan performa Graphical User Interface (GUI) dan Voice User Interface (VUI) berdasarkan metrik CPU, memori, jaringan, latensi, token, dan biaya sesi.

## Logbook Mingguan

| Pekan | Fokus Kegiatan | Aktivitas Bimbingan dan Teknis | Luaran / Hasil | Kendala | Rencana Pekan Berikutnya |
|---|---|---|---|---|---|
| 1 | Inisiasi topik | Konsultasi awal topik, penetapan ruang lingkup GUI vs VUI, penyusunan timeline kerja 16 pekan. | Topik disetujui, ruang lingkup penelitian terdefinisi. | Ruang lingkup awal terlalu luas. | Finalisasi rumusan masalah dan tujuan penelitian. |
| 2 | Studi literatur | Kajian jurnal terkait HCI mobile, VUI, WebRTC, dan evaluasi performa aplikasi. Bimbingan validasi daftar referensi utama. | Ringkasan literatur dan gap penelitian tersusun. | Beberapa referensi kurang relevan dengan konteks mobile. | Perbaiki matriks literatur dan turunan variabel penelitian. |
| 3 | Perumusan metodologi | Menyusun pertanyaan penelitian, variabel, metrik, dan desain eksperimen. Review metodologi bersama pembimbing. | Kerangka metodologi awal (pilot) disepakati. | Definisi kesetaraan skenario GUI-VUI belum rinci. | Detailkan skenario uji agar setara tujuan tugas. |
| 4 | Analisis sistem Qora | Audit struktur proyek Flutter (Clean Architecture, BLoC, GoRouter), pemetaan alur booking GUI dan VUI. | Diagram alur proses dan komponen sistem tersedia. | Alur VUI memiliki dependency eksternal API real-time. | Siapkan strategi instrumentasi dan logging metrik. |
| 5 | Implementasi instrumentasi dasar | Menambahkan/menyesuaikan pencatatan CPU, memori, latensi, network usage, token, dan biaya sesi. Bimbingan validasi metrik. | Mekanisme telemetry awal berjalan. | Sinkronisasi timestamp antar komponen belum konsisten. | Standarisasi format output telemetry dan timestamp. |
| 6 | Skenario uji GUI | Menentukan skenario booking GUI (awal-akhir), menjalankan uji coba awal, mengumpulkan data baseline. | Data pilot GUI pertama terkumpul. | Jalur GUI sebagian masih mock sehingga trafik jaringan minim. | Dokumentasikan keterbatasan baseline GUI secara eksplisit. |
| 7 | Skenario uji VUI | Menjalankan skenario VUI dengan OpenAI Realtime API dan WebRTC, observasi kualitas interaksi serta stabilitas sesi. | Data pilot VUI pertama terkumpul. | Latensi tinggi dan variasi respons dipengaruhi kondisi jaringan. | Tuning skenario dan batasan akhir sesi uji. |
| 8 | Evaluasi tengah semester | Bimbingan evaluasi progres, komparasi awal GUI vs VUI, identifikasi kelemahan desain eksperimen. | Temuan awal: latensi dan biaya VUI dominan lebih tinggi. | Jumlah sampel uji masih sangat kecil (n pilot). | Susun rencana repetisi eksperimen dan kontrol variabel. |
| 9 | Perbaikan protokol eksperimen | Menyusun protokol final: perangkat, mode build, kondisi jaringan, kriteria sukses/gagal, format batch data. | Protokol uji lebih terstandar dan dapat direplikasi. | Belum semua tahap memiliki marker waktu per langkah. | Tambah timestamp per-stage untuk GUI dan VUI. |
| 10 | Refinement implementasi | Penyesuaian route/alur booking agar definisi tahap lebih jelas (guest info, payment, confirmation) dan valid untuk analisis. | Konsistensi tahap eksperimen meningkat. | Perubahan alur memerlukan regression check antarf fitur. | Lakukan uji fungsional regresi pada flow booking. |
| 11 | Pengambilan data batch 1 | Eksekusi pengujian berulang skenario ideal flow untuk GUI dan VUI sesuai protokol. | Dataset batch 1 terbentuk. | Sebagian run gagal karena timeout/ketidakstabilan sesi. | Tambahkan log kegagalan, retry, dan klasifikasi error. |
| 12 | Pengambilan data batch 2 | Melanjutkan eksperimen pada skenario correction flow dan ambiguous input flow. Bimbingan monitoring kualitas data. | Dataset lebih beragam dan representatif. | Distribusi data belum merata per skenario. | Lengkapi run yang kurang dan normalisasi format data. |
| 13 | Analisis statistik deskriptif | Menghitung mean, median, standar deviasi, p95, serta visualisasi tabel/plot komparatif GUI-VUI. | Ringkasan statistik utama tersusun. | Outlier memengaruhi interpretasi metrik tertentu. | Lakukan analisis outlier dan validasi data mentah. |
| 14 | Analisis inferensial dan pembahasan | Menjalankan uji statistik yang relevan, menghitung effect size, dan menyusun interpretasi teknis hasil. | Draf pembahasan hasil penelitian tersedia. | Asumsi uji statistik harus disesuaikan dengan distribusi data. | Revisi pendekatan analisis berdasarkan hasil uji asumsi. |
| 15 | Penyusunan naskah akhir | Menulis bab hasil, pembahasan, ancaman validitas, dan rekomendasi pengembangan sistem. Bimbingan final konten ilmiah. | Draf paper siap pra-submit. | Perlu penyelarasan gaya sitasi/template. | Finalisasi format IEEE dan pemeriksaan plagiarisme. |
| 16 | Final review dan submit | Bimbingan akhir, perbaikan minor, validasi lampiran data, persiapan presentasi/ujian. | Naskah final dan berkas pendukung siap dikumpulkan. | Keterbatasan waktu untuk polishing visualisasi. | Submit akhir dan siapkan materi presentasi penelitian. |

## Rekap Kemajuan

- Status saat ini: [Belum Mulai / Berjalan / Selesai]
- Persentase progres: [Isi %]
- Catatan umum pembimbing: [Isi catatan]

## Catatan Penggunaan

- Dokumen ini dapat digunakan sebagai logbook formal mingguan.
- Setiap pekan disarankan menambahkan tanggal bimbingan, paraf pembimbing, dan bukti aktivitas (screenshot commit, hasil uji, atau revisi naskah).
- Jika jadwal akademik berubah, sesuaikan urutan pekan tanpa mengubah struktur luaran.