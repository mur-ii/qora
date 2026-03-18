# Lembar Operator GUI (Siap Eksekusi)

Dokumen ini adalah lembar kerja praktis untuk menjalankan Sesi GUI (30 run) secara konsisten, sesuai implementasi aplikasi Qora saat ini.

## 1) Scope dan Aturan Kunci

1. Dipakai untuk Sesi 1 (GUI) saja.
2. Gunakan urutan run GUI dari docs/booking_prompt_randomized_order.md.
3. Jangan lompat urutan run, jangan tukar prompt_id.
4. Dalam satu waktu operator hanya fokus pada 1 run aktif.
5. Jika run gagal, tandai failed lalu lanjut run berikutnya. Rerun dikerjakan di akhir sesi dengan run_id baru.

## 2) Endpoint Mode (Default Operasional)

Gunakan Mode A agar konsisten dengan instrumentation aplikasi saat ini:

1. Start GUI: saat field lokasi di beranda ditap.
2. End GUI: saat halaman konfirmasi booking pertama kali terbuka.

## 3) Task Contract Baseline (Wajib Sama)

Pastikan parameter inti berikut dipenuhi (kecuali revisi pada correction):

1. Lokasi: Jakarta.
2. Check-in: 2026-04-20.
3. Check-out: 2026-04-21.
4. Tamu: 2.
5. Kamar: 1.
6. Pilih hotel pertama pada hasil list.
7. Pilih kamar premium suite atau premium teratas tersedia.

## 4) Pre-Run Checklist (Centang Tiap Run)

- [ ] Device, jaringan, dan build mode tetap (profile).
- [ ] App dalam kondisi fresh start (tutup lalu buka ulang).
- [ ] run_id sudah dibuat dan unik.
- [ ] run_no aktif sudah sesuai urutan tabel GUI.
- [ ] Stopwatch/telemetri siap dimulai.
- [ ] scenario_type run aktif sudah dipahami (ideal/correction/ambiguous).

## 5) SOP Eksekusi GUI per Tipe Skenario

### 5.1 Ideal

1. Tap field lokasi (ini titik start timing).
2. Isi lokasi Jakarta.
3. Isi check-in 2026-04-20 dan check-out 2026-04-21.
4. Isi tamu 2 dan kamar 1.
5. Buka list hotel.
6. Pilih hotel pertama.
7. Pilih kamar premium.
8. Lanjutkan sampai halaman konfirmasi booking terbuka (ini titik end timing).

### 5.2 Correction

1. Jalankan baseline: Jakarta, 20-21 April 2026, 2 tamu, 1 kamar.
2. Setelah masuk list hotel, kembali ke filter.
3. Ubah check-out menjadi 2026-04-22.
4. Terapkan filter ulang.
5. Pilih hotel pertama.
6. Pilih kamar premium.
7. Lanjutkan sampai halaman konfirmasi booking terbuka.

### 5.3 Ambiguous

1. Tap field lokasi (start timing), isi lokasi Jakarta saja terlebih dahulu.
2. Beri jeda 3-5 detik.
3. Isi check-out 2026-04-21.
4. Beri jeda 3-5 detik.
5. Isi check-in 2026-04-20.
6. Isi tamu 2 dan kamar 1.
7. Buka list hotel, pilih hotel pertama, lalu kamar premium.
8. Lanjutkan sampai halaman konfirmasi booking terbuka.

## 6) Kriteria Status Run

Tandai completed jika:

1. Endpoint start dan end tercapai sesuai Mode A.
2. Tidak ada crash/freeze yang memutus alur.
3. Data log run terisi lengkap.

Tandai failed jika salah satu terjadi:

1. Endpoint end tidak tercapai.
2. Aplikasi crash/freeze/deadlock.
3. Gangguan jaringan atau error yang menghentikan alur.

## 7) Tabel Urutan Run GUI (30 Run)

Gunakan tabel ini persis sesuai urutan.

| Run | Prompt ID | Tipe | Status | Notes |
|---|---|---|---|---|
| 1 | A03 | ambiguous |  |  |
| 2 | I07 | ideal |  |  |
| 3 | C02 | correction |  |  |
| 4 | I01 | ideal |  |  |
| 5 | C09 | correction |  |  |
| 6 | A10 | ambiguous |  |  |
| 7 | I04 | ideal |  |  |
| 8 | C05 | correction |  |  |
| 9 | A01 | ambiguous |  |  |
| 10 | I10 | ideal |  |  |
| 11 | C03 | correction |  |  |
| 12 | A06 | ambiguous |  |  |
| 13 | I02 | ideal |  |  |
| 14 | C08 | correction |  |  |
| 15 | A04 | ambiguous |  |  |
| 16 | I05 | ideal |  |  |
| 17 | C01 | correction |  |  |
| 18 | A08 | ambiguous |  |  |
| 19 | I09 | ideal |  |  |
| 20 | C10 | correction |  |  |
| 21 | A02 | ambiguous |  |  |
| 22 | I03 | ideal |  |  |
| 23 | C06 | correction |  |  |
| 24 | A05 | ambiguous |  |  |
| 25 | I08 | ideal |  |  |
| 26 | C04 | correction |  |  |
| 27 | A07 | ambiguous |  |  |
| 28 | I06 | ideal |  |  |
| 29 | C07 | correction |  |  |
| 30 | A09 | ambiguous |  |  |

## 8) Format Pencatatan Log Minimum

Isi minimal field berikut untuk tiap run:

run_id,session,run_no,prompt_id,scenario_type,status,notes

Template siap isi untuk 30 run GUI tersedia di:

docs/template/booking_gui_30_run_tracking_template.csv

Contoh:

1. GUI-001,GUI,1,A03,ambiguous,completed,-
2. GUI-002,GUI,2,I07,ideal,failed,network_drop

## 9) Penanganan Failed dan Rerun

1. Jangan hapus data failed.
2. Lanjut ke run urutan berikutnya.
3. Rerun failed dilakukan setelah run 30 selesai.
4. Saat rerun, gunakan run_id baru.
5. Tautkan run_id lama di notes untuk audit.

## 10) Closing Sesi GUI

Setelah 30 run GUI selesai:

1. Rekap jumlah completed, failed, dan rerun queue.
2. Backup file log.
3. Uninstall aplikasi.
4. Install ulang untuk memulai Sesi VUI.