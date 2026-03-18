Kerangka Analisis Komparatif Kinerja GUI dan VUI Realtime pada Aplikasi Pemesanan Hotel Qora Berbasis Flutter

Abstrak

Paper ini menyajikan kerangka analisis berbasis repository untuk membandingkan Graphical User Interface (GUI) dan Voice User Interface (VUI) realtime pada aplikasi mobile Qora. Qora adalah prototipe pemesanan hotel berbasis Flutter dengan asisten suara agentic. Berbeda dari tulisan konseptual umum, dokumen ini disusun agar konsisten dengan implementasi yang ada di codebase saat ini. Qora menggunakan manajemen state BLoC, navigasi GoRouter, data pemesanan berbasis mock statik lokal, serta integrasi OpenAI Realtime melalui sesi HTTP dan kanal WebRTC untuk media serta event. Studi komparatif dirancang dengan tujuan pemesanan yang sama pada dua modalitas: interaksi GUI manual dan interaksi suara berbasis function calling. Metrik yang digunakan mencakup CPU, memori, trafik jaringan, latensi tugas, dan estimasi biaya token sesi VUI. Dokumen ini juga mencatat batas validitas eksperimen, termasuk referensi berkas mock `check_availability` yang belum tersedia, penyelarasan route pemesanan yang belum final, dan pembatasan alur voice hingga tahap pembayaran. Kontribusi utama paper ini adalah baseline benchmark yang praktis, transparan, dan dapat direplikasi pada kondisi proyek Qora saat ini.

Kata kunci: Flutter, BLoC, GoRouter, OpenAI Realtime API, WebRTC, Voice User Interface, Graphical User Interface, Profiling Kinerja Mobile, Estimasi Biaya Token, Human-Computer Interaction.

I. Pendahuluan

Perpindahan dari interaksi sentuh ke interaksi percakapan AI membawa perubahan arsitektur aplikasi mobile. Alur GUI cenderung event-driven dan relatif idle di antara aksi pengguna. Sebaliknya, VUI realtime membutuhkan perekaman audio berkelanjutan, transport data dua arah, deteksi giliran bicara, respons suara, serta sinkronisasi status antarkomponen.

Pada Qora, kedua modalitas digunakan untuk tujuan domain yang sama, yaitu pencarian hotel dan progres pemesanan. Tujuan riset ini bukan menyatakan satu modalitas selalu lebih baik, tetapi mengukur trade-off performa dan operasional pada implementasi yang benar-benar ada.

Pertanyaan penelitian:

1. Bagaimana perbedaan konsumsi resource antara alur GUI manual dan alur VUI realtime pada arsitektur Qora saat ini?
2. Komponen pipeline suara mana yang paling berpengaruh terhadap latensi dan overhead?
3. Bagaimana posisi strategis fitur voice dalam desain produk jika mempertimbangkan batasan teknis dan ekonomi yang tampak di codebase?

Dokumen ini merevisi draf sebelumnya agar lebih akurat, terukur, dan sesuai dengan kondisi repository.

II. Sistem yang Diteliti (Selaras dengan Repository Qora)

A. Stack Inti dan Pola Arsitektur

Qora diimplementasikan dengan Flutter (Dart SDK `^3.9.2`) dan saat ini ditargetkan untuk Android. Komponen utama yang digunakan:

- Presentasi dan manajemen state: `flutter_bloc`
- Navigasi: `go_router`
- Transport suara realtime: `flutter_webrtc`
- Izin perangkat: `permission_handler`
- Sumber data domain: berkas JSON statik (mock lokal)
- Konfigurasi environment: `flutter_dotenv`

Pada `main.dart`, runtime memuat environment, memvalidasi API key, menautkan navigation service, lalu menginjeksi `VoiceAssistantBloc` melalui `MultiBlocProvider`.

B. Alur GUI Pemesanan (Modalitas Kontrol)

Alur GUI di Qora bersifat event-driven lintas beberapa layar:

1. Input parameter pencarian dari Home
2. Pengambilan dan filtering daftar hotel
3. Detail hotel dan pemilihan kamar
4. Penyusunan ringkasan pemesanan
5. Pemilihan metode pembayaran
6. Konfirmasi pemesanan

Data domain pada kondisi saat ini bersifat mock-backed dengan simulasi delay (sekitar 500-1200 ms) melalui berkas JSON bundle. Karena itu, benchmark GUI pada repository ini merekam perilaku interaksi dan rendering dengan I/O yang relatif deterministik.

C. Alur VUI Realtime (Modalitas Eksperimental)

Pipeline voice di Qora menggunakan OpenAI Realtime dengan WebRTC:

1. Membuat sesi HTTP ke endpoint OpenAI Realtime (`/v1/realtime/sessions`)
2. Inisialisasi peer connection WebRTC (STUN)
3. Capture mikrofon (echo cancellation, noise suppression, auto gain)
4. Pertukaran SDP offer-answer melalui HTTPS
5. Transport audio melalui media track WebRTC
6. Signaling event dan function call melalui data channel WebRTC (`oai-events`)

Turn detection menggunakan server-side VAD saat setup sesi. Event yang diterima dipakai untuk memperbarui transkrip, state agent, dan siklus function calling.

D. Function Calling Agentic pada Implementasi Saat Ini

Qora mengekspos sembilan fungsi tool ke model realtime:

1. `search_hotels`
2. `get_hotel_details`
3. `select_room`
4. `check_availability`
5. `get_pricing`
6. `create_booking`
7. `confirm_booking`
8. `navigate_to_screen`
9. `update_booking_step`

Fungsi-fungsi ini berjalan di atas konteks internal (`AgenticAiContext`) dan mendorong transisi state serta navigasi melalui `NavigationService`.

E. Akuntansi Biaya Token

Setiap turn VUI menghasilkan informasi token (input, cached input, output) dan estimasi biaya. Nilai biaya sesi dihitung sebagai penjumlahan biaya seluruh turn dalam satu sesi percakapan.

III. Metodologi Komparatif untuk Qora

A. Desain Eksperimen

Variabel independen:

- Modalitas interaksi: GUI vs VUI

Faktor terkontrol:

- Tujuan pemesanan dan entitas domain yang sama
- Build aplikasi yang sama (Flutter profile mode)
- Perangkat Android dan kondisi jaringan yang sama pada setiap batch
- Dataset mock hotel dan pemesanan yang sama

Variabel dependen:

- Rata-rata utilisasi CPU
- Puncak penggunaan memori
- Trafik jaringan TX/RX
- Latensi end-to-end tugas
- Estimasi biaya token per sesi VUI

B. Skenario Tugas yang Selaras dengan Alur Aplikasi

Skenario 1 (jalur ideal deterministik)

- GUI: pengguna menyelesaikan alur dari Home ke Payment dengan koreksi minimal.
- VUI: pengguna memberi perintah ringkas; model mengeksekusi `search_hotels -> get_hotel_details -> select_room -> create_booking` lalu menavigasi ke arah pembayaran.

Skenario 2 (self-correction)

- GUI: pengguna mengubah pencarian atau pilihan kamar sebelum konfirmasi.
- VUI: pengguna merevisi lokasi, tanggal, atau tipe kamar di tengah percakapan; model memperbarui argumen fungsi dan mengulang langkah relevan.

Skenario 3 (multi-turn bertahap)

- GUI: pengguna bernavigasi dan memfilter lebih lambat serta tidak kontinu.
- VUI: model membutuhkan beberapa turn untuk melengkapi parameter sebelum handoff.

Catatan implementasi: sesi voice saat ini sengaja ditutup di batas halaman pembayaran (closing instruction), karena aksi payment gateway berada di luar ruang otomasi.

C. Persamaan Metrik

Overhead relatif:

$$Overhead(\%) = \frac{M_{VUI} - M_{GUI}}{M_{GUI}} \times 100$$

dengan $M$ sebagai metrik seperti CPU, memori, jaringan, atau latensi.

Biaya token per turn:

$$Cost_{USD} = \frac{0.60 \cdot T_{in} + 0.06 \cdot T_{cached} + 2.40 \cdot T_{out}}{10^6}$$

dengan:

- $T_{in}$ = input tokens
- $T_{cached}$ = cached input tokens
- $T_{out}$ = output tokens

Biaya sesi dihitung sebagai penjumlahan biaya seluruh turn dalam session id yang sama.

D. Pemetaan Instrumentasi

Agar hasil dapat direplikasi, instrumentasi yang direkomendasikan:

1. Flutter DevTools CPU Profiler (hotspot thread Dart dan beban async)
2. DevTools Memory (pertumbuhan heap dan perilaku GC saat sesi voice)
3. DevTools Network (setup HTTP session dan dampak trafik kanal realtime)
4. Timeline atau Frame Chart (dampak pada budget frame UI dan raster)
5. Rekap token dan biaya sesi dari log runtime aplikasi

IV. Temuan Analitis Berbasis Kode (Kondisi Saat Ini)

Bagian ini tidak menyajikan angka kuantitatif buatan. Temuan diturunkan dari implementasi yang terverifikasi di repository.

A. Perbedaan Pola Komputasi

GUI cenderung bursty dan event-driven. Beban utama muncul pada aksi pengguna dan parsing JSON mock dengan delay terbatas.

VUI membawa aktivitas latar yang lebih kontinu:

- stream mikrofon aktif selama sesi
- parsing event realtime pada data channel
- orkestrasi function call dan mutasi state
- update navigasi dan transkrip secara paralel

Implikasinya, occupancy CPU lebih berkelanjutan dan churn memori cenderung lebih tinggi dibanding alur GUI murni.

B. Perbedaan Profil Jaringan

Pada repository ini, alur GUI sebagian besar menggunakan data mock lokal, sehingga beban jaringan relatif rendah.

VUI memerlukan komunikasi live dengan OpenAI Realtime (session creation, SDP exchange, dan transport media/event kontinu), sehingga lebih sensitif terhadap kualitas jaringan.

C. Perbedaan Profil Ekonomi

GUI tidak menimbulkan biaya token model.

VUI menimbulkan biaya variabel per turn sesuai jumlah token input, cached input, dan output.

D. Perbedaan Pengalaman Produk

GUI lebih deterministik, mudah ditinjau, dan mudah diulang.

VUI memberi pengalaman hands-free dan interaksi yang lebih natural, tetapi menambah tantangan pada ambiguitas bahasa, sensitivitas latensi turn-taking, dan kebutuhan guardrail yang tegas pada tahap kritis.

V. Celah Implementasi dan Ancaman Validitas

Fakta berikut perlu dicatat sebagai batas validitas eksperimen:

1. `check_availability` merujuk ke `lib/features/room/mock/room_list_response.json`, tetapi berkas JSON tersebut belum tersedia. Jika fungsi dipanggil, runtime dapat gagal saat memuat asset.
2. Route `booking_guest_info` saat ini mengarah ke `PaymentPage`, sehingga batas guest-info vs payment belum sepenuhnya tegas.
3. `VoiceAssistantPage` tersedia di layer presentasi, tetapi aktivasi utama saat ini menggunakan voice toggle dari Home.
4. Data domain hotel dan pemesanan masih mock-driven, sehingga variabilitas backend eksternal belum tercakup.

Batasan ini tidak membatalkan komparasi, tetapi wajib dilaporkan agar generalisasi tetap proporsional.

VI. Protokol Eksperimen Reproducible untuk Proyek Ini

Protokol yang disarankan:

1. Build aplikasi pada Flutter profile mode di perangkat fisik Android.
2. Pastikan `.env` berisi `OPENAI_API_KEY` valid dan opsional `OPENAI_MODEL`.
3. Stabilkan kondisi jaringan selama satu batch pengujian.
4. Jalankan tiap skenario GUI dan VUI dengan repetisi seimbang (misalnya $N=10$).
5. Catat per-run CPU, puncak memori, bytes jaringan, dan latensi dari DevTools.
6. Catat token serta biaya sesi dari log runtime aplikasi.
7. Hitung mean, deviasi standar, dan persentase overhead.
8. Laporkan run gagal secara terpisah (izin perangkat, error pemanggilan tool, atau gangguan konektivitas).

Format tabel hasil yang disarankan:

| Skenario | Metrik | Mean GUI | Mean VUI | Overhead (%) | Catatan |
|---|---|---:|---:|---:|---|
| Ideal | CPU (%) | - | - | - | |
| Ideal | Peak Memory (MB) | - | - | - | |
| Ideal | Network (KB/MB) | - | - | - | |
| Ideal | Latency (s) | - | - | - | |
| Ideal | Session Cost (USD) | 0.00 | - | N/A | |
| Self-correction | CPU (%) | - | - | - | |
| Self-correction | Peak Memory (MB) | - | - | - | |
| Self-correction | Network (KB/MB) | - | - | - | |
| Self-correction | Latency (s) | - | - | - | |
| Self-correction | Session Cost (USD) | 0.00 | - | N/A | |
| Multi-turn | CPU (%) | - | - | - | |
| Multi-turn | Peak Memory (MB) | - | - | - | |
| Multi-turn | Network (KB/MB) | - | - | - | |
| Multi-turn | Latency (s) | - | - | - | |
| Multi-turn | Session Cost (USD) | 0.00 | - | N/A | |

VII. Kesimpulan

Pada kondisi codebase Qora saat ini, GUI dan VUI lebih tepat diposisikan sebagai modalitas yang saling melengkapi, bukan pengganti langsung. GUI tetap lebih deterministik dan relatif ringan dalam prototipe ini. VUI realtime memberi manfaat pada naturalness interaksi dan potensi otomasi melalui function calling, tetapi menambah beban komputasi kontinu, ketergantungan jaringan, dan biaya token.

Kontribusi utama revisi ini adalah menyelaraskan klaim analisis dengan kondisi repository dan menyediakan metodologi pengukuran yang dapat direplikasi.

VIII. Pekerjaan Lanjutan

1. Menutup celah implementasi sebelum benchmark final (ketersediaan berkas mock `check_availability` dan penyelarasan route).
2. Menambahkan pipeline ekspor telemetri (CSV/JSON) untuk memudahkan analisis statistik lintas run.
3. Memperluas evaluasi ke metrik battery drain dan thermal behavior untuk sesi VUI panjang.
4. Membandingkan pendekatan cloud realtime saat ini dengan alternatif on-device speech/SLM untuk melihat trade-off biaya dan latensi.
5. Menambahkan metrik studi pengguna (task success, beban koreksi, persepsi delay, trust) sebagai pelengkap profiling sistem.
