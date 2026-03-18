# Checklist Operasional Per Run Booking (GUI vs VUI)

Dokumen ini melengkapi skenario pada docs/booking_case_scenarios.md dan dipakai sebagai lembar kontrol eksekusi eksperimen.

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

## 5. Checklist Eksekusi Run GUI

### 5.1 Start
- [ ] Mulai stopwatch/telemetri tepat pada endpoint start mode terpilih.

### 5.2 Eksekusi Langkah
- [ ] Jalankan langkah GUI sesuai skenario tanpa improvisasi.
- [ ] Untuk correction flow: lakukan revisi parameter hanya sesuai skrip skenario.
- [ ] Untuk ambiguous flow: beri jeda antar aksi 3-5 detik sesuai skenario.

### 5.3 End
- [ ] Hentikan stopwatch/telemetri tepat pada endpoint end mode terpilih.
- [ ] Pastikan status run: completed jika endpoint tercapai tanpa crash.

## 6. Checklist Eksekusi Run VUI

### 6.1 Start
- [ ] Aktifkan voice assistant.
- [ ] Mulai stopwatch/telemetri tepat pada endpoint start mode terpilih.
- [ ] Cek mikrofon aktif dan suara tertangkap.

### 6.2 Eksekusi Langkah
- [ ] Ucapkan skrip sesuai skenario (ideal/correction/ambiguous).
- [ ] Jangan ubah wording inti dalam batch yang sama.
- [ ] Pastikan sistem memproses klarifikasi/revisi sesuai alur.
- [ ] Jika terjadi function-call error, catat di notes_error_or_retry.

### 6.3 End
- [ ] Akhiri saat endpoint end mode tercapai.
- [ ] Pastikan sesi voice berhenti normal (auto/manual sesuai skenario).
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

Tandai failed jika salah satu terjadi:
- [ ] Gangguan jaringan yang menghentikan alur.
- [ ] Izin mikrofon/audio bermasalah.
- [ ] Crash, freeze, atau deadlock percakapan.
- [ ] Endpoint tidak tercapai.

Jika failed:
- [ ] Simpan run sebagai failed (jangan ditimpa).
- [ ] Buat run_id baru untuk pengulangan.
- [ ] Catat penyebab ringkas pada notes_error_or_retry.

## 9. Post-Run Checklist

- [ ] Ekspor hasil run (JSON/CSV) bila diperlukan.
- [ ] Verifikasi token dan cost muncul pada output VUI.
- [ ] Verifikasi file ekspor dapat dibuka.
- [ ] Simpan backup data batch setelah setiap 5-10 run.

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
