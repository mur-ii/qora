# Qora Smart

Qora Smart adalah aplikasi Flutter untuk skenario pemesanan hotel berbasis dua mode interaksi:

- Graphical User Interface (GUI) untuk alur pemesanan manual
- Voice User Interface (VUI) realtime untuk asistensi berbasis suara

README ini disusun agar sesuai sebagai artefak pendukung project paper conference, dengan fokus pada deskripsi sistem, struktur implementasi, dan langkah reproduksibilitas.

## Kontribusi Sistem

- Integrasi alur booking hotel end-to-end pada aplikasi mobile Flutter
- Dukungan navigasi dan bantuan booking melalui voice assistant realtime
- Arsitektur modular per fitur untuk memudahkan evaluasi, pengembangan, dan pemeliharaan

## Cakupan Fitur

- Menampilkan daftar hotel dan detail hotel
- Menjalankan proses booking dari pemilihan hingga konfirmasi
- Menyediakan alur GUI dan VUI dalam satu aplikasi

## Struktur Proyek

```text
lib/
	core/
		config/, di/, router/, services/, theme/, utils/, widgets/
	features/
		booking/
		home/
		hotel_detail/
		hotel_list/
		voice_assistant/
```

## Reproduksibilitas

1. Pastikan Flutter SDK sudah terpasang dan terkonfigurasi.
2. Instal dependensi proyek:

	```bash
	flutter pub get
	```

3. Jalankan aplikasi pada mode debug (pengembangan):

	```bash
	flutter run --debug
	```

4. Jalankan aplikasi pada mode profile (evaluasi performa):

	```bash
	flutter run --profile
	```

## Demo Aplikasi

[Demo Aplikasi Qora Smart](https://telkomuniversityofficial-my.sharepoint.com/:v:/g/personal/muhammadsadrims_student_telkomuniversity_ac_id/IQCpEXBzMunfSaXaDOY2Lr6FAQ0UnG5rMQRn5weWdfqQa_Q?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=piu6PB)

## Catatan Implementasi

- Konfigurasi environment: `lib/core/config/env_config.dart`
- Dependency injection: `lib/core/di/`
