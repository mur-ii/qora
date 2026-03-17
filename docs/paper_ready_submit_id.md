# Naskah Final Siap Submit (Bahasa Indonesia)

## Judul
Analisis Komparatif Kinerja GUI dan VUI pada Aplikasi Pemesanan Hotel Berbasis Flutter: Studi Pilot pada Qora

## Penulis
Nama Penulis 1, Nama Penulis 2, Nama Penulis 3
Afiliasi, Kota, Negara
Email

## Abstrak
Penelitian ini menyajikan studi komparatif kinerja antara Graphical User Interface (GUI) dan Voice User Interface (VUI) pada Qora, aplikasi pemesanan hotel berbasis Flutter dengan asisten suara realtime berbasis agentic function calling. Tujuan penelitian adalah mengevaluasi trade-off performa operasional antara interaksi sentuh manual dan interaksi percakapan suara untuk tujuan tugas yang sama. Sistem diimplementasikan menggunakan Flutter, BLoC, dan GoRouter pada sisi aplikasi, serta OpenAI Realtime API melalui HTTP dan WebRTC pada sisi VUI. Metrik yang dianalisis meliputi rata-rata CPU, puncak memori, trafik jaringan, latensi end-to-end, jumlah token, dan biaya sesi.

Hasil pilot dari satu run GUI dan satu run VUI menunjukkan bahwa VUI memiliki latensi jauh lebih tinggi (87.550 ms vs 3.126 ms), trafik jaringan lebih besar, serta biaya sesi tidak nol (USD 0,0103512 dengan 14.753 token). Sementara itu, nilai CPU rata-rata dan puncak memori pada run pilot VUI lebih rendah daripada GUI. Temuan ini mengindikasikan bahwa penalti utama VUI pada implementasi saat ini berada pada latensi dan biaya model, bukan pada saturasi resource lokal. Penelitian ini berkontribusi dengan kerangka evaluasi yang selaras kode, dapat direplikasi, serta roadmap peningkatan agar Qora layak untuk studi empiris berskala publikasi.

## Kata Kunci
Flutter, Voice User Interface, Graphical User Interface, Realtime AI, WebRTC, Kinerja Aplikasi Mobile, Human-Computer Interaction, Pemesanan Hotel

## I. Pendahuluan
Interaksi manusia-komputer pada aplikasi mobile bergerak dari paradigma sentuh murni menuju paradigma percakapan multimodal. Pada aplikasi transaksional seperti pemesanan hotel, GUI lazim dipandang lebih deterministik dan mudah dikendalikan, sedangkan VUI menawarkan pengalaman hands-free dan potensi otomatisasi alur.

Namun, VUI membawa kompleksitas tambahan berupa streaming audio kontinu, inferensi model jarak jauh, mekanisme turn-taking, dan biaya token berbasis penggunaan. Oleh karena itu, evaluasi performa GUI versus VUI perlu dilakukan pada implementasi nyata, bukan hanya konseptual.

Qora dipilih sebagai objek studi karena menyediakan dua modalitas interaksi dalam satu codebase. GUI berjalan dengan navigasi layar dan data mock lokal, sedangkan VUI memanfaatkan OpenAI Realtime API dengan WebRTC dan function calling.

Pertanyaan penelitian:
1. Bagaimana perbedaan CPU, memori, jaringan, latensi, dan biaya antara GUI dan VUI pada tujuan booking yang setara?
2. Komponen apa yang paling berkontribusi terhadap overhead VUI pada implementasi saat ini?
3. Perbaikan teknis apa yang diperlukan agar studi ini memenuhi kualitas publikasi ilmiah?

## II. Arsitektur Sistem dan Instrumentasi
### A. Arsitektur Aplikasi
Qora dikembangkan dengan Flutter dan menerapkan BLoC untuk state management serta GoRouter untuk navigasi. Modul voice assistant terdiri dari lapisan data, domain, dan presentasi. Eksekusi fungsi agentic dikoordinasikan oleh use case yang memetakan tool call model ke aksi pemesanan.

### B. Pipeline GUI
Pada implementasi saat ini, tracking performa GUI dimulai dari halaman pembayaran dan berakhir di halaman konfirmasi booking. Alur GUI bersifat event-driven dan sangat dipengaruhi data mock lokal.

### C. Pipeline VUI
Alur VUI meliputi pembuatan sesi Realtime via HTTP, negosiasi SDP, streaming audio mikrofon via WebRTC, penerimaan event data channel, serta eksekusi function call seperti pencarian hotel, pemilihan kamar, dan pembuatan booking.

### D. Telemetri yang Direkam
Telemetri yang diekspor mencakup:
1. CPU rata-rata.
2. Memori puncak.
3. Trafik HTTP dan WebRTC.
4. Latensi skenario.
5. Jumlah token serta biaya sesi.

## III. Metodologi
### A. Desain Eksperimen
Variabel independen:
- Modalitas interaksi: GUI dan VUI.

Variabel dependen:
- Rata-rata CPU (%).
- Puncak memori (MB).
- Trafik jaringan TX/RX (KB).
- Latensi end-to-end (ms).
- Token dan biaya sesi (USD).

Faktor kontrol target:
1. Perangkat Android yang sama.
2. Build aplikasi yang sama (profile mode).
3. Tujuan tugas pemesanan yang sama.
4. Kondisi jaringan stabil per batch.
5. Dataset dan model yang konsisten.

### B. Sumber Data
Analisis ini menggunakan dua berkas hasil ekspor telemetri:
1. Skenario GUI booking flow.
2. Skenario VUI booking flow.

### C. Persamaan
Overhead relatif metrik M:

$$
Overhead(M) = \frac{M_{VUI} - M_{GUI}}{M_{GUI}} \times 100\%
$$

Rasio latensi:

$$
Rasio\ Latensi = \frac{Latensi_{VUI}}{Latensi_{GUI}}
$$

## IV. Hasil dan Pembahasan
### A. Hasil Numerik Pilot
| Metrik | GUI | VUI |
|---|---:|---:|
| Latensi (ms) | 3.126 | 87.550 |
| CPU rata-rata (%) | 6,5878 | 4,9979 |
| Memori puncak (MB) | 392,0166 | 313,7334 |
| Network TX (KB) | 0,0000 | 778,3682 |
| Network RX (KB) | 0,0000 | 1.515,4902 |
| Biaya sesi (USD) | 0,0000000 | 0,0103512 |
| Total token | 0 | 14.753 |
| Total turn | 0 | 12 |

### B. Perbandingan Turunan
1. Rasio latensi VUI terhadap GUI: 28,01x.
2. Overhead latensi VUI terhadap GUI: 2700,70%.
3. Selisih CPU VUI terhadap GUI: -24,13%.
4. Selisih memori puncak VUI terhadap GUI: -19,97%.

### C. Interpretasi
1. VUI pada implementasi saat ini memiliki penalti utama pada latensi end-to-end dan biaya sesi model.
2. Nilai jaringan dan token GUI yang nol menunjukkan jalur GUI saat ini masih dominan lokal/mock, sehingga perbandingan belum sepenuhnya setara dengan kompleksitas cloud-assisted VUI.
3. Nilai CPU dan memori pilot yang lebih rendah pada VUI tidak dapat langsung ditafsirkan sebagai keunggulan, karena ukuran sampel masih sangat kecil dan simetri skenario belum ketat.

## V. Ancaman terhadap Validitas
### A. Validitas Internal
1. Ukuran sampel baru n=1 per modalitas sehingga belum memungkinkan analisis varians dan signifikansi statistik.
2. Skenario GUI dan VUI belum sepenuhnya simetris dalam jumlah langkah dan kompleksitas interaksi.

### B. Validitas Konstrak
1. Tracking GUI saat ini dimulai dari tahap pembayaran sehingga belum merekam beban penuh dari awal alur booking.
2. Sesi VUI dapat diakhiri pada tahap ringkasan tertentu sesuai desain, sehingga titik akhir belum setara penuh dengan GUI.

### C. Validitas Implementasi
1. Route booking guest info saat ini masih terhubung ke halaman pembayaran, berpotensi mengaburkan analisis berbasis langkah.
2. Salah satu tool voice mereferensikan aset mock availability yang belum tersedia.

## VI. Rencana Peningkatan agar Layak Publikasi
### A. Peningkatan Metodologi
1. Menjalankan minimal 30 repetisi per modalitas dan per jenis skenario.
2. Melaporkan mean, median, standar deviasi, p95, dan confidence interval 95%.
3. Menambahkan uji statistik inferensial dan effect size.
4. Menambahkan metrik keberhasilan tugas dan jumlah koreksi pengguna.

### B. Peningkatan Instrumentasi
1. Menggeser titik mulai tracking GUI ke titik awal booking yang sebenarnya.
2. Menambahkan timestamp per tahap untuk kedua modalitas.
3. Menyediakan ekspor data batch dalam format seragam untuk analisis statistik.
4. Memisahkan tabel analisis trafik HTTP signaling dan WebRTC media/event.

### C. Peningkatan Produk
1. Memisahkan route guest info dan payment agar definisi tahap eksperimen konsisten.
2. Melengkapi aset mock untuk semua tool yang didaftarkan.
3. Menstandarkan skrip skenario GUI dan VUI agar tujuan dan kondisi akhir benar-benar setara.
4. Menambahkan pencatatan retry, timeout, dan failure rate fungsi.

## VII. Protokol Eksperimen Final yang Direkomendasikan
1. Gunakan satu perangkat fisik Android untuk satu batch pengujian.
2. Gunakan build profile mode yang sama sepanjang batch.
3. Jalankan tiga kelas skenario: ideal flow, correction flow, dan ambiguous-input flow.
4. Rekam semua metrik per run dan tandai run gagal secara eksplisit.
5. Lakukan agregasi statistik deskriptif dan inferensial.
6. Sajikan hasil dalam tabel komparatif dan boxplot per metrik.

## VIII. Kesimpulan
Qora sudah memiliki fondasi telemetri yang memadai untuk studi komparatif GUI versus VUI. Hasil pilot menunjukkan bahwa VUI memberikan overhead latensi dan biaya yang signifikan pada konfigurasi saat ini, sedangkan perbedaan CPU dan memori belum konklusif. Dengan penyetaraan skenario, perluasan cakupan tracking, dan repetisi eksperimen yang cukup, proyek ini sangat potensial untuk menjadi paper empiris yang kuat mengenai kinerja modalitas interaksi pada aplikasi booking hotel.

## Ucapan Terima Kasih (Opsional)
Penelitian ini didukung oleh institusi/laboratorium terkait dan dikembangkan menggunakan prototipe Qora.

## Referensi (Isi sesuai kebutuhan template)
[1] Flutter Documentation. https://docs.flutter.dev
[2] BLoC Library Documentation. https://bloclibrary.dev
[3] GoRouter Documentation. https://pub.dev/packages/go_router
[4] WebRTC for the Curious. https://webrtcforthecurious.com
[5] OpenAI Realtime API Documentation. https://platform.openai.com/docs
[6] IEEE Editorial Style Manual.

## Catatan Copy-Paste ke Template IEEE
1. Tempelkan bagian Abstract dan Kata Kunci pada blok yang disediakan template.
2. Gunakan heading section dengan format Romawi seperti pada naskah ini.
3. Ganti identitas penulis dan afiliasi sebelum submit.
4. Sesuaikan gaya referensi mengikuti format IEEE conference pada template ISITIA.
