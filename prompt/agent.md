# Task: Implement Conversation Log & Token Usage Tracking for Realtime Voice Assistant (WebRTC)

Saya memiliki aplikasi booking hotel berbasis Flutter yang menggunakan OpenAI Realtime Voice API melalui WebRTC untuk interaksi voice assistant (VUI).

Saya ingin menambahkan fitur berikut:

## 🎯 Tujuan Fitur

1. Menampilkan log percakapan antara user dan assistant
2. Menampilkan jumlah token yang digunakan pada setiap conversation
3. Menyimpan data conversation secara lokal
4. Bisa digunakan untuk kebutuhan penelitian (analisis penggunaan VUI vs GUI)
5. Menggunakan state management BLoC (WAJIB mengikuti arsitektur BLoC yang sudah ada)

---

# 🧠 Scope Implementasi

## 1. Conversation Log Data Structure

Buat model data conversation seperti berikut:

- id session
- timestamp
- role (user / assistant)
- text transcript
- audio duration (optional jika tersedia)
- input tokens
- output tokens
- total tokens
- latency response (optional)
- error flag (optional)

Contoh field:

```dart
class ConversationMessage {
  final String id;
  final String role;
  final String text;
  final DateTime timestamp;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
}
````

---

## 2. Token Usage Tracking (Realtime API)

Ambil token usage dari response OpenAI realtime.

Pastikan mengambil data:

* input_audio_tokens
* input_text_tokens
* output_text_tokens
* total_tokens

Jika token tidak langsung tersedia dari event realtime:

* lakukan estimasi token menggunakan tokenizer library
* atau hitung dari jumlah karakter sebagai fallback

---

## 3. Conversation Session Concept

Setiap user berbicara dihitung sebagai:

> 1 Conversation Turn

Struktur:

User Speech → Assistant Response = 1 Conversation Log

---

## 4. BLoC Architecture

Buat BLoC baru:

ConversationBloc

Event:

* StartConversationSession
* AddUserMessage
* AddAssistantMessage
* UpdateTokenUsage
* EndConversationSession
* LoadConversationHistory

State:

* ConversationInitial
* ConversationActive
* ConversationUpdated
* ConversationSaved
* ConversationError

Pastikan clean architecture dan scalable.

---

## 5. Local Storage

Simpan conversation ke local storage.

Boleh pilih:

* Hive (recommended)
* Isar
* Sqflite

Struktur penyimpanan:

ConversationSession

* sessionId
* startTime
* endTime
* messages[]
* totalTokens
* totalTurns

---

## 6. UI Conversation Log Screen

Buat halaman baru:

Conversation Log Screen

Tampilkan:

* daftar session
* jumlah turns
* total token
* waktu session
* detail percakapan

Detail percakapan:

User Bubble (kanan)
Assistant Bubble (kiri)

Tambahkan info kecil:

Token: 120
Latency: 1.2s

UI harus:

* minimalis
* profesional
* cocok untuk aplikasi booking hotel
* responsive

---

## 7. Realtime Integration Flow

Saat event voice terjadi:

### User Speak Detected

Trigger:

AddUserMessage

### Assistant Response Received

Trigger:

AddAssistantMessage
UpdateTokenUsage

---

## 8. Performance Consideration

Pastikan:

* tidak mengganggu realtime audio streaming
* logging berjalan async
* tidak blocking UI thread

Gunakan isolate jika perlu.

---

## 9. Summary Analytics (Optional tapi direkomendasikan)

Hitung:

* total conversations
* total tokens digunakan
* rata-rata token per turn
* rata-rata latency
* durasi session

---

## 10. Research Friendly Mode

Tambahkan flag:

researchMode = true

Jika aktif:

* simpan data lebih detail
* export ke JSON / CSV

---

# 🚀 Output yang Saya Harapkan

Tolong buatkan:

1. Arsitektur folder lengkap
2. Model data
3. BLoC implementation
4. Local storage setup
5. Realtime integration example
6. UI halaman log conversation
7. Contoh data JSON hasil penyimpanan
8. Best practice token tracking realtime OpenAI
9. Cara menghubungkan dengan WebRTC event
10. Tips optimasi performa Flutter realtime voice

Gunakan best practice Flutter production level code.

State management harus BLoC.

Kode harus clean, scalable, dan siap penelitian akademik.

---
