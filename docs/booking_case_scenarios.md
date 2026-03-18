# Skenario Case Booking untuk Eksperimen GUI vs VUI (Qora)

## 1. Tujuan Dokumen
Dokumen ini menyediakan skenario pengujian booking yang konsisten dengan paper pada folder docs, terutama untuk tiga kelas skenario:
1. Ideal flow.
2. Correction flow.
3. Ambiguous-input flow.

Dokumen ini dipakai untuk menghasilkan data komparatif GUI vs VUI yang lebih rapi dan dapat direplikasi.

## 1.1 Ringkasan Cepat Jumlah Run
Untuk setup praktis saat ini dengan 3 skenario dan 2 modalitas:
1. Target 10 run per kombinasi skenario x modalitas.
2. Jumlah kombinasi: 3 skenario x 2 modalitas = 6 kombinasi.
3. Total minimal run valid: 10 x 6 = 60 run.

Rekomendasi praktis agar aman terhadap run failed/rerun:
1. Tambah buffer 10%: 60 x 1.10 = 66 run yang dijadwalkan.
2. Target minimal completed tetap 60 run valid.

Catatan untuk paper final:
1. 30 run per kombinasi tetap lebih kuat untuk analisis inferensial.
2. 10 run per kombinasi cocok untuk pilot dan validasi awal.

## 2. Konfigurasi Umum (Wajib Sama di Semua Run)
1. Device: 1 perangkat Android fisik yang sama untuk satu batch.
2. Build: Flutter profile mode.
3. Koneksi internet: stabil dan tidak berpindah jaringan selama batch.
4. Model VUI: tetap (jangan diganti di tengah batch).
5. Data mock: tidak diubah selama batch.
6. Bahasa interaksi: Bahasa Indonesia (konsisten untuk semua run).

## 3. Definisi Start dan End Point
Gunakan dua mode endpoint agar hasil mudah dianalisis:

### Mode A: Sesuai implementasi tracking saat ini
1. GUI start: saat user menekan field lokasi di beranda (tap lokasi pada home search bar).
2. GUI end: saat halaman konfirmasi booking terbuka.
3. VUI start: saat voice assistant diaktifkan.
4. VUI end: saat halaman konfirmasi booking terbuka (finish tracking otomatis ketika halaman konfirmasi terbuka).

### Mode B: Endpoint setara (direkomendasikan untuk paper final)
1. GUI start: saat user menekan aksi mulai pencarian hotel dari beranda.
2. GUI end: saat halaman ringkasan booking terbuka.
3. VUI start: saat voice assistant diaktifkan.
4. VUI end: saat halaman ringkasan booking terbuka.

Catatan: Mode B memberi perbandingan yang lebih adil untuk GUI vs VUI.

### 3.1 Detail Implementasi Endpoint di Project (Branch Saat Ini)
Gunakan catatan ini agar eksekusi run konsisten dengan instrumentation yang aktif:
1. GUI start dipicu ketika user tap field lokasi di beranda, bukan saat halaman pembayaran dibuka.
2. GUI end difinalisasi otomatis saat halaman konfirmasi booking pertama kali terbuka.
3. VUI start dipicu saat event StartVoiceAssistant dikirim (toggle di header beranda atau tombol start pada halaman voice assistant).
4. Pada flow VUI, sesi voice dapat ditutup lebih awal di tahap ringkasan, tetapi tracking eksperimen tetap difinalisasi di halaman konfirmasi booking.
5. Jika run berhenti sebelum halaman konfirmasi booking terbuka, tandai run sebagai failed untuk Mode A.

### 3.2 Catatan Praktis Pemakaian Mode
1. Untuk reproduksi metrik yang sesuai implementasi aplikasi saat ini, gunakan Mode A.
2. Untuk analisis endpoint setara GUI vs VUI di paper final, gunakan Mode B dengan stopwatch/manual marker atau tambahkan instrumentation khusus Mode B.

## 4. Parameter Task Tetap (Task Contract)
Gunakan parameter ini sebagai baseline di semua skenario, kecuali saat memang ada koreksi pada correction flow:
1. Lokasi: Jakarta.
2. Check-in: 2026-04-20.
3. Check-out: 2026-04-21.
4. Tamu: 2.
5. Kamar: 1.
6. Target hotel: hotel pertama dari hasil list.
7. Target kamar: premium suite atau kamar premium teratas yang tersedia.

## 5. Skenario 1: Ideal Flow
## 5.1 Tujuan
Mengukur performa saat user memberikan informasi jelas dan alur berjalan mulus tanpa revisi.

## 5.2 Langkah GUI
1. Dari beranda, isi lokasi Jakarta.
2. Isi check-in 2026-04-20 dan check-out 2026-04-21.
3. Isi tamu 2 dan kamar 1.
4. Buka daftar hotel.
5. Pilih hotel pertama.
6. Pilih kamar premium.
7. Lanjut ke ringkasan booking.
8. Lanjut ke pembayaran atau konfirmasi sesuai mode endpoint.

## 5.3 Skrip VUI (contoh ucapan)
1. Cari hotel di Jakarta untuk check-in 20 April 2026 dan check-out 21 April 2026 untuk 2 tamu 1 kamar.
2. Pilih hotel pertama.
3. Pilih kamar premium suite.
4. Lanjutkan booking.

## 5.4 Ekspektasi
1. Semua parameter dipahami tanpa klarifikasi tambahan panjang.
2. Navigasi ke list, detail, dan ringkasan berhasil.
3. Tidak ada error function call yang menggagalkan alur.

## 5.5 Kriteria sukses
1. Endpoint tercapai sesuai mode yang dipilih.
2. Tidak ada crash.
3. Telemetri tersimpan dan dapat diekspor.

## 6. Skenario 2: Correction Flow
## 6.1 Tujuan
Mengukur overhead saat user melakukan revisi parameter di tengah alur.

## 6.2 Langkah GUI
1. Mulai dengan lokasi Jakarta, check-in 2026-04-20, check-out 2026-04-21.
2. Setelah masuk list hotel, kembali ke filter.
3. Ubah check-out menjadi 2026-04-22.
4. Pilih ulang hotel dan kamar.
5. Lanjut ke ringkasan booking.
6. Lanjut ke pembayaran atau konfirmasi sesuai mode endpoint.

## 6.3 Skrip VUI (contoh ucapan)
1. Cari hotel di Jakarta untuk 20 sampai 21 April 2026, 2 tamu.
2. Ubah check-out jadi 22 April 2026.
3. Pilih hotel pertama.
4. Pilih kamar premium suite.
5. Lanjutkan booking.

## 6.4 Ekspektasi
1. Sistem memproses revisi parameter tanpa restart sesi.
2. Hasil pencarian/ringkasan menyesuaikan tanggal baru.
3. Jumlah turn VUI dan latency meningkat dibanding ideal flow.

## 6.5 Kriteria sukses
1. Revisi parameter berhasil diterapkan.
2. Endpoint tercapai.
3. Telemetri menyimpan run sebagai completed.

## 7. Skenario 3: Ambiguous-Input Flow
## 7.1 Tujuan
Mengukur biaya performa saat input awal tidak lengkap dan sistem harus klarifikasi.

## 7.2 Langkah GUI
1. Dari beranda, isi hanya lokasi Jakarta dulu.
2. Isi tanggal dan jumlah tamu secara bertahap (berhenti 3-5 detik antar aksi).
3. Buka list hotel, pilih hotel dan kamar.
4. Lanjut ke ringkasan booking.
5. Lanjut ke pembayaran atau konfirmasi sesuai mode endpoint.

## 7.3 Skrip VUI (contoh ucapan)
1. Carikan hotel di Jakarta.
2. Check-out tanggal 21 April 2026.
3. Check-in tanggal 20 April 2026, tamu 2 orang.
4. Pilih hotel pertama.
5. Pilih kamar premium suite.
6. Lanjutkan booking.

## 7.4 Ekspektasi
1. Sistem mengajukan pertanyaan klarifikasi.
2. User menjawab bertahap sampai parameter lengkap.
3. Turn count, token, dan biaya VUI meningkat dibanding ideal flow.

## 7.5 Kriteria sukses
1. Semua parameter inti akhirnya lengkap.
2. Endpoint tercapai.
3. Tidak ada deadlock percakapan.

## 8. Matriks Run yang Direkomendasikan
Untuk eksekusi praktis saat ini, gunakan 10 run per modalitas per skenario:
1. GUI ideal: 10 run.
2. VUI ideal: 10 run.
3. GUI correction: 10 run.
4. VUI correction: 10 run.
5. GUI ambiguous: 10 run.
6. VUI ambiguous: 10 run.

Total minimum run: 60.

### 8.1 Formula cepat
1. Total run minimum = jumlah_skenario x jumlah_modalitas x run_per_kombinasi.
2. Pada desain ini: 3 x 2 x 10 = 60.

### 8.2 Target operasional yang disarankan
1. Target scheduled run: 66 (buffer 10%).
2. Target completed run: minimal 60.
3. Jika completed belum 60, lanjutkan run sampai kuota valid terpenuhi.

### 8.3 Contoh pembagian batch
Contoh pembagian agar rapi:
1. Batch 1: ideal (GUI 10, VUI 10) = 20.
2. Batch 2: correction (GUI 10, VUI 10) = 20.
3. Batch 3: ambiguous (GUI 10, VUI 10) = 20.
4. Tambahan buffer rerun lintas batch: 6 run.

Total scheduled: 66 run, dengan target valid akhir minimal 60 run.

## 9. Template Log per Run
Catat data berikut untuk setiap run:
1. run_id.
2. tanggal_waktu.
3. mode_endpoint (A atau B).
4. modality (GUI atau VUI).
5. scenario_type (ideal/correction/ambiguous).
6. status (completed/failed).
7. latency_ms.
8. avg_cpu_percent.
9. peak_memory_mb.
10. network_tx_kb.
11. network_rx_kb.
12. total_tokens.
13. session_cost_usd.
14. total_turns.
15. notes_error_or_retry.

Contoh header CSV:
run_id,tanggal_waktu,mode_endpoint,modality,scenario_type,status,latency_ms,avg_cpu_percent,peak_memory_mb,network_tx_kb,network_rx_kb,total_tokens,session_cost_usd,total_turns,notes_error_or_retry

## 10. Aturan Eksekusi Supaya Data Bersih
1. Tutup aplikasi lain di perangkat sebelum run.
2. Jalankan tiap run sampai endpoint, jangan berhenti di tengah.
3. Jika gagal karena jaringan/izin, tandai failed dan ulang run baru.
4. Jangan mengganti script ucapan VUI di dalam batch yang sama.
5. Jangan mengganti urutan langkah GUI di dalam batch yang sama.
6. Simpan run failed sebagai data audit, jangan dihapus.
7. Gunakan run_id baru saat rerun, jangan menimpa run_id lama.

## 11. Keluaran yang Ditargetkan
Setelah menjalankan skenario ini, Anda akan punya dataset terstruktur yang siap untuk:
1. Statistik deskriptif (mean, median, std, p95).
2. Uji inferensial GUI vs VUI per skenario.
3. Visualisasi boxplot per metrik.
4. Penguatan klaim empiris pada paper final.
