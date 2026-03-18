# Dokumentasi Urutan Prompt Acak (Anti Bias Hafalan)

## 1. Tujuan
Dokumen ini memberikan urutan prompt yang sudah diacak untuk:
1. Sesi GUI: ideal 10, correction 10, ambiguous 10.
2. Sesi VUI: ideal 10, correction 10, ambiguous 10.

Urutan dibuat agar operator tidak menjalankan pola berulang yang mudah dihafal.

## 2. Aturan Eksekusi
1. Jalankan Sesi 1 (GUI) sampai 30 run selesai.
2. Uninstall aplikasi.
3. Install dan jalankan ulang untuk Sesi 2 (VUI).
4. Gunakan urutan run persis sesuai tabel.
5. Jangan lompat run, jangan tukar urutan.
6. Jika satu run gagal, tandai failed lalu lanjut run berikutnya. Rerun dilakukan di akhir sesi dengan run_id baru.

## 3. Bank Prompt

### 3.1 Ideal (I01-I10)
Semua prompt ideal wajib berujung parameter inti yang sama:
- Lokasi Jakarta, check-in 2026-04-20, check-out 2026-04-21, 2 tamu, 1 kamar, pilih hotel pertama, pilih kamar premium.

1. I01: Cari hotel di Jakarta untuk 20-21 April 2026, 2 tamu 1 kamar. Pilih hotel pertama lalu kamar premium suite.
2. I02: Tolong booking hotel Jakarta tanggal 20 April masuk, 21 April keluar, 2 orang, 1 kamar. Ambil hotel pertama dan kamar premium.
3. I03: Carikan hotel Jakarta, check-in 20 April 2026, check-out 21 April 2026, tamu 2, kamar 1. Pilih hasil pertama dan kamar premium suite.
4. I04: Saya mau hotel di Jakarta untuk 1 malam, 20 ke 21 April 2026, 2 tamu, 1 kamar. Lanjut pilih hotel pertama dan kamar premium.
5. I05: Booking hotel Jakarta untuk dua orang satu kamar, tanggal 20 sampai 21 April 2026. Pilih hotel teratas dan kamar premium suite.
6. I06: Cari penginapan Jakarta, check-in 20-04-2026 dan check-out 21-04-2026, 2 tamu 1 kamar. Pilih hotel pertama serta kamar premium.
7. I07: Temukan hotel di Jakarta tanggal 20 April sampai 21 April 2026, 2 orang 1 kamar. Ambil hotel pertama lalu kamar premium suite.
8. I08: Bantu saya cari hotel Jakarta untuk 20-21 April 2026, dua tamu satu kamar. Pilih hotel pertama dan kamar premium.
9. I09: Saya ingin pesan hotel Jakarta, masuk 20 April 2026 keluar 21 April 2026, 2 tamu, 1 kamar. Pilih hasil pertama lalu premium suite.
10. I10: Cari hotel Jakarta sesuai tanggal 20 sampai 21 April 2026 untuk 2 tamu 1 kamar. Lanjutkan dengan hotel pertama dan kamar premium.

### 3.2 Correction (C01-C10)
Semua correction dimulai dari 20-21 April lalu dikoreksi check-out menjadi 22 April 2026.

1. C01: Cari hotel Jakarta untuk 20-21 April 2026, 2 tamu. Ubah check-out jadi 22 April 2026. Pilih hotel pertama dan kamar premium suite.
2. C02: Booking hotel Jakarta tanggal 20 sampai 21 April 2026 untuk 2 orang. Koreksi, check-out harus 22 April 2026. Pilih hotel pertama lalu premium.
3. C03: Carikan hotel Jakarta 20 April masuk, 21 April keluar, 2 tamu. Revisi check-out ke 22 April 2026, lalu pilih hotel pertama dan kamar premium.
4. C04: Cari hotel di Jakarta untuk 1 kamar 2 tamu, 20 ke 21 April 2026. Saya koreksi, keluar tanggal 22 April. Pilih hotel pertama dan premium suite.
5. C05: Saya mau booking hotel Jakarta 20-21 April 2026, 2 tamu. Tolong ubah check-out menjadi 22 April 2026, lanjut pilih hotel pertama dan premium.
6. C06: Temukan hotel Jakarta tanggal 20 sampai 21 April 2026 untuk dua orang. Ganti tanggal check-out ke 22 April, lalu pilih hotel pertama dan kamar premium.
7. C07: Cari penginapan Jakarta untuk 20-21 April 2026, tamu 2 kamar 1. Revisi tanggal pulang jadi 22 April 2026, pilih hotel pertama dan premium suite.
8. C08: Booking hotel Jakarta check-in 20 April 2026, check-out 21 April 2026, 2 tamu. Koreksi check-out ke 22 April lalu pilih hotel pertama dan kamar premium.
9. C09: Tolong cari hotel Jakarta 20 ke 21 April 2026 untuk 2 orang. Ubah check-out jadi 22 April 2026. Lanjut pilih hotel pertama dan premium suite.
10. C10: Hotel Jakarta untuk 20-21 April 2026, 2 tamu 1 kamar. Saya revisi check-out ke 22 April 2026, kemudian pilih hotel pertama dan kamar premium.

### 3.3 Ambiguous (A01-A10)
Semua ambiguous diberikan bertahap sampai parameter lengkap.

1. A01: Carikan hotel di Jakarta. Lalu set check-out 21 April 2026. Kemudian set check-in 20 April 2026, tamu 2 orang, 1 kamar. Pilih hotel pertama dan premium suite.
2. A02: Saya mau hotel Jakarta. Tanggal keluarnya 21 April 2026. Tanggal masuk 20 April 2026, tamu 2, kamar 1. Pilih hotel pertama lalu kamar premium.
3. A03: Cari hotel Jakarta dulu. Check-out 21 April 2026. Check-in 20 April 2026 untuk 2 tamu satu kamar. Ambil hotel pertama dan premium suite.
4. A04: Tolong carikan hotel di Jakarta. Keluar 21 April 2026. Masuk 20 April 2026, dua tamu, satu kamar. Pilih hotel pertama serta kamar premium.
5. A05: Hotel di Jakarta. Saya ingin check-out 21 April 2026. Check-in 20 April 2026, 2 orang, 1 kamar. Pilih hasil pertama dan kamar premium suite.
6. A06: Cari penginapan Jakarta. Tanggal selesai 21 April 2026. Tanggal mulai 20 April 2026, tamu dua, kamar satu. Lanjut hotel pertama dan premium.
7. A07: Temukan hotel Jakarta. Check-out 21-04-2026. Check-in 20-04-2026 untuk 2 tamu 1 kamar. Pilih hotel pertama lalu premium suite.
8. A08: Cari hotel Jakarta. Keluar tanggal 21 April 2026. Masuk 20 April 2026, 2 tamu, 1 kamar. Ambil hotel pertama dan kamar premium.
9. A09: Carikan hotel di Jakarta dulu. Check-out saya 21 April 2026. Check-in 20 April 2026, tamu 2 orang kamar 1. Pilih hotel pertama dan premium suite.
10. A10: Saya butuh hotel Jakarta. Tanggal check-out 21 April 2026. Tanggal check-in 20 April 2026 dengan 2 tamu 1 kamar. Pilih hotel pertama dan kamar premium.

## 4. Urutan Acak Sesi 1 (GUI)
Gunakan 30 run berikut sebelum uninstall aplikasi.

| Run | Prompt ID | Tipe |
|---|---|---|
| 1 | A03 | ambiguous |
| 2 | I07 | ideal |
| 3 | C02 | correction |
| 4 | I01 | ideal |
| 5 | C09 | correction |
| 6 | A10 | ambiguous |
| 7 | I04 | ideal |
| 8 | C05 | correction |
| 9 | A01 | ambiguous |
| 10 | I10 | ideal |
| 11 | C03 | correction |
| 12 | A06 | ambiguous |
| 13 | I02 | ideal |
| 14 | C08 | correction |
| 15 | A04 | ambiguous |
| 16 | I05 | ideal |
| 17 | C01 | correction |
| 18 | A08 | ambiguous |
| 19 | I09 | ideal |
| 20 | C10 | correction |
| 21 | A02 | ambiguous |
| 22 | I03 | ideal |
| 23 | C06 | correction |
| 24 | A05 | ambiguous |
| 25 | I08 | ideal |
| 26 | C04 | correction |
| 27 | A07 | ambiguous |
| 28 | I06 | ideal |
| 29 | C07 | correction |
| 30 | A09 | ambiguous |

## 5. Urutan Acak Sesi 2 (VUI)
Setelah uninstall dan install ulang aplikasi, gunakan urutan ini.

| Run | Prompt ID | Tipe |
|---|---|---|
| 1 | C04 | correction |
| 2 | A01 | ambiguous |
| 3 | I09 | ideal |
| 4 | C10 | correction |
| 5 | I02 | ideal |
| 6 | A07 | ambiguous |
| 7 | C01 | correction |
| 8 | I05 | ideal |
| 9 | A03 | ambiguous |
| 10 | C06 | correction |
| 11 | I01 | ideal |
| 12 | A10 | ambiguous |
| 13 | C08 | correction |
| 14 | I07 | ideal |
| 15 | A05 | ambiguous |
| 16 | C03 | correction |
| 17 | I10 | ideal |
| 18 | A08 | ambiguous |
| 19 | C05 | correction |
| 20 | I04 | ideal |
| 21 | A02 | ambiguous |
| 22 | C09 | correction |
| 23 | I06 | ideal |
| 24 | A04 | ambiguous |
| 25 | C02 | correction |
| 26 | I03 | ideal |
| 27 | A06 | ambiguous |
| 28 | C07 | correction |
| 29 | I08 | ideal |
| 30 | A09 | ambiguous |

## 6. Checklist Validasi Sebelum Mulai
1. Jumlah per sesi tepat 30 run (I=10, C=10, A=10).
2. Prompt ID tidak diulang dalam sesi yang sama.
3. Operator hanya melihat 1 baris run aktif saat eksekusi.
4. Catat status completed atau failed di setiap run.

## 7. Format Log Ringkas (Opsional)
Gunakan format berikut untuk memudahkan audit:

run_id,session,run_no,prompt_id,scenario_type,status,notes

Contoh:
- GUI-001,GUI,1,A03,ambiguous,completed,-
- GUI-002,GUI,2,I07,ideal,failed,network_drop
