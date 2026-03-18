# Checklist Operasional Per Run Booking (GUI vs VUI)

Dokumen ini melengkapi skenario pada docs/booking_case_scenarios.md dan dipakai sebagai lembar kontrol eksekusi eksperimen.

## Ringkasan Kuota Eksperimen
- [ ] Total minimal run valid (completed): 60.
- [ ] Total run terjadwal yang disarankan (dengan buffer 10%): 66.
- [ ] Komposisi target valid per kombinasi: 10 run untuk setiap skenario x modalitas.

## 1. Tujuan Checklist

Checklist ini dipakai untuk:
- Menjaga konsistensi prosedur antar run.
- Mengurangi bias operator.
- Menentukan run valid, failed, dan rerun secara objektif.
- Menjaga dataset bersih untuk analisis statistik dan pelaporan paper.

## 2. Aturan Utama Sebelum Batch

Gunakan aturan berikut untuk seluruh batch:
- [ ] Endpoint mode dipilih dan dikunci untuk batch: Mode A atau Mode B.
- [ ] Build mode untuk eksperimen utama dikunci: GUI profile, VUI profile.
- [ ] Jika butuh debug log detail VUI, jalankan batch terpisah bertanda validation_only.
- [ ] Device fisik tetap sama untuk satu batch.
- [ ] Jaringan stabil dan tidak pindah Wi-Fi/provider selama batch.
- [ ] Model OpenAI tidak diganti selama batch.
- [ ] Data mock tidak diubah selama batch.
- [ ] Bahasa interaksi dikunci: Bahasa Indonesia.

Sebelum batch dimulai, tetapkan juga:
- [ ] Kuota run per batch (misal 20 run untuk 1 skenario).
- [ ] Operator yang menjalankan run dan format penamaan run_id.
- [ ] Lokasi penyimpanan file log utama (CSV/JSON) untuk batch ini.

## 2.1 Mapping Endpoint Operasional (Sesuai Implementasi App Saat Ini)

Jika batch menggunakan Mode A, gunakan patokan berikut:
- [ ] GUI start = saat field lokasi di beranda ditap.
- [ ] GUI end = saat halaman konfirmasi booking pertama kali terbuka.
- [ ] VUI start = saat voice assistant diaktifkan.
- [ ] VUI end telemetry = saat halaman konfirmasi booking pertama kali terbuka.
- [ ] Catatan: sesi voice VUI bisa selesai di ringkasan, tetapi endpoint tracking Mode A tetap di konfirmasi booking.

Jika batch menggunakan Mode B:
- [ ] Pastikan tim sepakat marker manual start/end karena endpoint setara Mode B belum menjadi instrumentation default pada aplikasi saat ini.

## 3. Task Contract Baseline (Wajib Sama)

Centang sebelum mulai setiap run:
- [ ] Lokasi: Jakarta.
- [ ] Check-in: 2026-04-20.
- [ ] Check-out: 2026-04-21.
- [ ] Tamu: 2.
- [ ] Kamar: 1.
- [ ] Target hotel: hotel pertama di list.
- [ ] Target kamar: premium suite atau premium teratas tersedia.

## 4. Pre-Run Checklist (Diulang Setiap Run)

- [ ] Tutup aplikasi lain di perangkat.
- [ ] Pastikan baterai > 40% atau sambung daya.
- [ ] Pastikan thermal perangkat normal (tidak overheat).
- [ ] Tutup aplikasi Qora lalu buka ulang (fresh start).
- [ ] Verifikasi parameter skenario: ideal, correction, atau ambiguous.
- [ ] Verifikasi modality run: GUI atau VUI.
- [ ] Verifikasi run_id dibuat dan unik.
- [ ] Verifikasi pencatatan waktu start siap.
- [ ] Verifikasi mode endpoint untuk run ini sama dengan mode batch (A atau B).

## 5. Checklist Eksekusi Run GUI

### 5.1 Start
- [ ] Mulai stopwatch/telemetri tepat pada endpoint start mode terpilih.
- [ ] Untuk Mode A: pastikan run dimulai tepat saat tap field lokasi di beranda.

### 5.2 Eksekusi Langkah
- [ ] Jalankan langkah GUI sesuai skenario tanpa improvisasi.
- [ ] Untuk correction flow: lakukan revisi parameter hanya sesuai skrip skenario.
- [ ] Untuk ambiguous flow: beri jeda antar aksi 3-5 detik sesuai skenario.

### 5.3 End
- [ ] Hentikan stopwatch/telemetri tepat pada endpoint end mode terpilih.
- [ ] Untuk Mode A: akhiri saat halaman konfirmasi booking sudah terbuka (tidak menunggu tombol Back to Home).
- [ ] Pastikan status run: completed jika endpoint tercapai tanpa crash.

## 6. Checklist Eksekusi Run VUI

### 6.1 Start
- [ ] Aktifkan voice assistant.
- [ ] Mulai stopwatch/telemetri tepat pada endpoint start mode terpilih.
- [ ] Cek mikrofon aktif dan suara tertangkap.
- [ ] Untuk Mode A: start dihitung saat aksi aktivasi voice dilakukan.

### 6.2 Eksekusi Langkah
- [ ] Ucapkan skrip sesuai skenario (ideal/correction/ambiguous).
- [ ] Jangan ubah wording inti dalam batch yang sama.
- [ ] Pastikan sistem memproses klarifikasi/revisi sesuai alur.
- [ ] Jika terjadi function-call error, catat di notes_error_or_retry.

### 6.3 End
- [ ] Akhiri saat endpoint end mode tercapai.
- [ ] Untuk Mode A: endpoint tracking selesai saat halaman konfirmasi booking terbuka.
- [ ] Pastikan sesi voice berhenti normal; pada implementasi saat ini sesi voice bisa selesai di ringkasan sebelum endpoint tracking konfirmasi.
- [ ] Pastikan status run: completed jika endpoint tercapai tanpa deadlock/crash.

## 7. Data Capture Checklist (Setiap Run)

Pastikan field berikut terisi:
- [ ] run_id
- [ ] tanggal_waktu
- [ ] mode_endpoint
- [ ] modality
- [ ] scenario_type
- [ ] status
- [ ] latency_ms
- [ ] avg_cpu_percent
- [ ] peak_memory_mb
- [ ] network_tx_kb
- [ ] network_rx_kb
- [ ] total_tokens
- [ ] session_cost_usd
- [ ] total_turns
- [ ] notes_error_or_retry

## 8. Aturan Validasi Run

Tandai completed jika:
- [ ] Endpoint tercapai sesuai mode.
- [ ] Tidak ada crash aplikasi.
- [ ] Telemetri tersimpan lengkap.
- [ ] Untuk Mode A VUI: walau sesi voice sudah tertutup di ringkasan, run tetap harus mencapai konfirmasi booking agar endpoint end valid.

Tandai failed jika salah satu terjadi:
- [ ] Gangguan jaringan yang menghentikan alur.
- [ ] Izin mikrofon/audio bermasalah.
- [ ] Crash, freeze, atau deadlock percakapan.
- [ ] Endpoint tidak tercapai.

Jika failed:
- [ ] Simpan run sebagai failed (jangan ditimpa).
- [ ] Buat run_id baru untuk pengulangan.
- [ ] Catat penyebab ringkas pada notes_error_or_retry.
- [ ] Masukkan failed run ke daftar rerun queue.

Jika rerun:
- [ ] Pastikan parameter task contract identik dengan run yang gagal.
- [ ] Eksekusi ulang sebagai run baru, bukan overwrite data lama.
- [ ] Tautkan run_id lama pada notes_error_or_retry untuk jejak audit.

## 9. Post-Run Checklist

- [ ] Ekspor hasil run (JSON/CSV) bila diperlukan.
- [ ] Verifikasi token dan cost muncul pada output VUI.
- [ ] Verifikasi file ekspor dapat dibuka.
- [ ] Simpan backup data batch setelah setiap 5-10 run.
- [ ] Update progres kuota completed vs failed vs pending rerun.

Ringkasan progres yang disarankan per akhir sesi:
- [ ] Total completed valid saat ini.
- [ ] Total failed saat ini.
- [ ] Total rerun queue saat ini.
- [ ] Sisa run untuk mencapai minimal 60 completed.

## 10. Label Batch yang Direkomendasikan

Agar analisis valid, gunakan label batch:
- main_profile: GUI profile vs VUI profile (dipakai untuk analisis utama paper).
- validation_debug: VUI debug untuk inspeksi logging detail (bukan perbandingan utama performa).

## 11. Template Ringkas Per Run (Siap Copy)

Run Metadata:
- [ ] run_id:
- [ ] batch_label: main_profile / validation_debug
- [ ] mode_endpoint: A / B
- [ ] modality: GUI / VUI
- [ ] scenario_type: ideal / correction / ambiguous

Execution:
- [ ] Start timestamp dicatat
- [ ] End timestamp dicatat
- [ ] Endpoint tercapai
- [ ] Status: completed / failed

Metrics:
- [ ] latency_ms
- [ ] avg_cpu_percent
- [ ] peak_memory_mb
- [ ] network_tx_kb
- [ ] network_rx_kb
- [ ] total_tokens
- [ ] session_cost_usd
- [ ] total_turns

Notes:
- [ ] notes_error_or_retry

## 12. Gate Kualitas Akhir Batch

Batch dianggap siap masuk analisis jika:
- [ ] Kuota completed per kombinasi mencapai 10 run.
- [ ] Total completed global mencapai minimal 60 run.
- [ ] Tidak ada missing field pada kolom metrik wajib.
- [ ] Semua failed run terdokumentasi penyebabnya.
- [ ] Seluruh file data batch sudah dibackup.
