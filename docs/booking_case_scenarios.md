# Skenario Case Booking untuk Eksperimen GUI vs VUI (Qora)

## 1. Tujuan Dokumen
Dokumen ini menyediakan skenario pengujian booking yang konsisten dengan paper pada folder docs, terutama untuk tiga kelas skenario:
1. Ideal flow.
2. Correction flow.
3. Ambiguous-input flow.

Dokumen ini dipakai untuk menghasilkan data komparatif GUI vs VUI yang lebih rapi dan dapat direplikasi.

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
1. GUI start: saat halaman pembayaran terbuka.
2. GUI end: saat halaman konfirmasi booking terbuka.
3. VUI start: saat voice assistant diaktifkan.
4. VUI end: saat sesi voice ditutup otomatis/manual di tahap ringkasan.

### Mode B: Endpoint setara (direkomendasikan untuk paper final)
1. GUI start: saat user menekan aksi mulai pencarian hotel dari beranda.
2. GUI end: saat halaman ringkasan booking terbuka.
3. VUI start: saat voice assistant diaktifkan.
4. VUI end: saat halaman ringkasan booking terbuka.

Catatan: Mode B memberi perbandingan yang lebih adil untuk GUI vs VUI.

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
Untuk paper final, gunakan minimal 30 run per modalitas per skenario:
1. GUI ideal: 30 run.
2. VUI ideal: 30 run.
3. GUI correction: 30 run.
4. VUI correction: 30 run.
5. GUI ambiguous: 30 run.
6. VUI ambiguous: 30 run.

Total minimum run: 180.

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

## 11. Keluaran yang Ditargetkan
Setelah menjalankan skenario ini, Anda akan punya dataset terstruktur yang siap untuk:
1. Statistik deskriptif (mean, median, std, p95).
2. Uji inferensial GUI vs VUI per skenario.
3. Visualisasi boxplot per metrik.
4. Penguatan klaim empiris pada paper final.
