

### A. Indikator Kuantitatif (Data Objektif)

Data ini direkam secara otomatis di latar belakang oleh aplikasi Flutter Anda selama pengujian berlangsung.

* **Waktu Input Pengguna (*User Input Time*)**
    * *GUI:* Waktu yang dihitung dari saat layar pemesanan terbuka hingga pengguna selesai mengetik dan menekan tombol konfirmasi.
    * *VUI:* Waktu yang dihitung dari saat mikrofon aktif hingga pengguna selesai mengucapkan satu kalimat perintah utuh.
    * *Catatan:* Ingat, waktu *loading* atau pemrosesan sistem tidak dihitung di sini agar perbandingan tetap adil.


* **Tingkat Koreksi (*Correction Rate*)**
    * *GUI:* Berapa kali pengguna menekan tombol *backspace* saat mengetik nama kota/hotel, atau menghapus centang filter yang salah.
    * *VUI:* Berapa kali pengguna meralat ucapannya sendiri di tengah jalan (misalnya: *"Cari hotel di Bandung... eh maksud saya Jakarta"*).


* **Beban Interaksi (*Interaction Effort*)**
    * *GUI:* Total ketukan (*tap*) layar dan guliran (*scroll*) yang dilakukan untuk menyelesaikan satu pesanan.
    * *VUI:* Total "giliran bicara" (*voice turns*) atau berapa kali pengguna harus merespons pertanyaan dari *Voice Assistant* OpenAI.


* **Tingkat Keberhasilan Tugas (*Task Completion Rate*)**
    * Apakah partisipan berhasil mencapai layar "Booking Sukses" tanpa menyerah dan tanpa intervensi/bantuan dari Anda.
