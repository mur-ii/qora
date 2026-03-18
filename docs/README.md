# Dokumentasi Eksperimen GUI vs VUI (Qora)

Folder ini berisi dokumen operasional untuk testing GUI vs VUI pada skenario booking.

## 1) Paket Inti (6 File Saja)
1. [booking_case_scenarios.md](booking_case_scenarios.md)
2. [booking_operational_checklist.md](booking_operational_checklist.md)
3. [booking_operator_sheet_gui.md](booking_operator_sheet_gui.md)
4. [template/booking_gui_30_run_tracking_template.csv](template/booking_gui_30_run_tracking_template.csv)
5. [template/booking_run_log_template.csv](template/booking_run_log_template.csv)
6. [README.md](README.md)

## 2) Jawaban ringkas jumlah tes
- Target praktis (disarankan saat ini): 10 run per kombinasi.
- Komposisi: 3 skenario x 2 modalitas x 10 run = 60 run completed.
- Buffer operasional: jadwalkan 66 run (tambah 10%) untuk antisipasi failed/rerun.

Catatan:
1. Target 30 run per kombinasi tetap lebih kuat untuk analisis inferensial paper final.
2. Target 10 run per kombinasi cocok untuk fase pilot/skripsi awal agar eksekusi realistis.

## 3) Alur pakai cepat
1. Baca skenario di [booking_case_scenarios.md](booking_case_scenarios.md).
2. Jalankan run pakai checklist di [booking_operational_checklist.md](booking_operational_checklist.md).
3. Untuk sesi GUI 30 run, pakai [template/booking_gui_30_run_tracking_template.csv](template/booking_gui_30_run_tracking_template.csv).
4. Untuk logging metrik lengkap lintas modalitas, pakai [template/booking_run_log_template.csv](template/booking_run_log_template.csv).
5. Pastikan tiap kombinasi mencapai 10 completed run.

## 3.1) Ringkasan Endpoint Implementasi Aktual (Branch Saat Ini)
1. Mode A (sesuai instrumentation default app):
	- GUI start: tap field lokasi di beranda.
	- GUI end: halaman konfirmasi booking terbuka.
	- VUI start: voice assistant diaktifkan.
	- VUI end telemetry: halaman konfirmasi booking terbuka.
2. Catatan penting VUI:
	- Sesi voice dapat ditutup di ringkasan, namun run Mode A dianggap selesai saat konfirmasi booking terbuka.
3. Catatan Mode B:
	- Endpoint setara Mode B belum menjadi instrumentation default, sehingga perlu marker manual (stopwatch/manual event marker) atau perubahan instrumentation khusus.
4. Untuk detail operasional, ikuti:
	- [booking_case_scenarios.md](booking_case_scenarios.md)
	- [booking_operational_checklist.md](booking_operational_checklist.md)

## 4) Dokumen paper
Dokumen naskah tetap tersedia untuk kebutuhan penulisan:
- [paper/paper.md](paper/paper.md)
- [paper/paper_ieee_draft.md](paper/paper_ieee_draft.md)
- [paper/paper_ready_submit_id.md](paper/paper_ready_submit_id.md)
- [paper/paper_ready_submit_en.md](paper/paper_ready_submit_en.md)
- [paper/ISITIA IEEE Template.pdf](paper/ISITIA%20IEEE%20Template.pdf)

## 5) Praktik terbaik eksekusi
1. Kunci mode endpoint (A atau B) per batch, jangan campur dalam satu batch.
2. Kunci model VUI, bahasa, data mock, dan device selama batch.
3. Simpan run gagal sebagai failed, lalu rerun dengan run_id baru.
4. Backup data setiap 5-10 run.
5. Evaluasi progres harian: completed, failed, rerun queue, sisa menuju 60 valid.
6. Untuk hasil paling konsisten dengan aplikasi saat ini, jalankan batch utama menggunakan Mode A.
