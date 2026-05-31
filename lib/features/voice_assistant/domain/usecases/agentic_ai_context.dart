import 'dart:convert';

import '../../../booking/domain/entities/booking_entity.dart';
import '../entities/agent_state_entity.dart';

/// Holds mutable conversational and booking state for agentic voice flow.
class AgenticAiContext {
  AgentStateEntity _agentState = const AgentStateEntity();
  Map<String, dynamic> hotelSearchResults = {};
  Map<String, dynamic> selectedHotel = {};
  Map<String, dynamic> bookingData = {};

  AgentStateEntity get agentState => _agentState;

  void reset() {
    _agentState = const AgentStateEntity();
    hotelSearchResults = {};
    selectedHotel = {};
    bookingData = {};
  }

  void previewUserConstraints(Map<String, dynamic> args) {
    final normalized = Map<String, dynamic>.from(applyDefaultScenario(args));
    final constraints = _agentState.userConstraints;

    normalized['rooms'] = args['rooms'] ?? constraints['rooms'] ?? 1;
    normalized['guests'] = args['guests'] ?? constraints['guests'] ?? 2;

    updateAgentState(userConstraints: normalized);
  }

  void updateAgentState({
    BookingStep? currentStep,
    Map<String, dynamic>? userConstraints,
    Map<String, dynamic>? appState,
    String? currentScreen,
  }) {
    _agentState = _agentState.copyWith(
      currentStep: currentStep,
      userConstraints: userConstraints ?? _agentState.userConstraints,
      appState: appState ?? _agentState.appState,
      currentScreen: currentScreen,
    );
  }

  Map<String, dynamic> applyDefaultScenario(Map<String, dynamic> args) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    final updated = Map<String, dynamic>.from(args);

    updated['location'] = (updated['location'] ?? 'Jakarta').toString();
    updated['check_in'] = (updated['check_in'] ?? _formatDate(today))
        .toString();
    updated['check_out'] = (updated['check_out'] ?? _formatDate(tomorrow))
        .toString();

    if (updated['amenities'] is String) {
      updated['amenities'] = [(updated['amenities'] as String).trim()];
    }

    return updated;
  }

  Map<String, dynamic> normalizeBookingArgs(Map<String, dynamic> args) {
    final normalized = Map<String, dynamic>.from(applyDefaultScenario(args));
    final constraints = _agentState.userConstraints;

    normalized['check_in'] =
        (args['check_in'] ?? constraints['check_in'] ?? normalized['check_in'])
            .toString();
    normalized['check_out'] =
        (args['check_out'] ??
                constraints['check_out'] ??
                normalized['check_out'])
            .toString();

    normalized['guests'] = args['guests'] ?? constraints['guests'] ?? 2;
    normalized['rooms'] = args['rooms'] ?? constraints['rooms'] ?? 1;

    final hotelId =
        args['hotel_id'] ?? selectedHotel['id'] ?? normalized['hotel_id'];
    if (hotelId != null) {
      normalized['hotel_id'] = hotelId.toString();
    }

    final roomId = resolveRoomId(args) ?? normalized['room_id'];
    if (roomId != null) {
      normalized['room_id'] = roomId.toString();
    }

    return normalized;
  }

  String buildHotelListSpeech(List<Map<String, dynamic>> hotels, String city) {
    if (hotels.isEmpty) {
      final checkIn = _agentState.userConstraints['check_in']?.toString();
      final checkOut = _agentState.userConstraints['check_out']?.toString();
      final guests = (_agentState.userConstraints['guests'] ?? 2).toString();
      final rooms = (_agentState.userConstraints['rooms'] ?? 1).toString();
      final scheduleText = (checkIn != null && checkOut != null)
          ? 'check-in $checkIn dan check-out $checkOut'
          : 'tanggal sebelumnya';

      return 'Belum ada hotel yang cocok di $city. '
          'Mau ganti lokasi? Saya tetap pakai $scheduleText, $guests tamu, $rooms kamar.';
    }

    final shownHotels = hotels.take(4).toList(growable: false);
    final buffer = StringBuffer(
      'Berikut hotel yang tersedia di $city, ada ${hotels.length} cabang yang kami miliki. ',
    );

    for (var i = 0; i < shownHotels.length; i++) {
      final hotel = shownHotels[i];
      final name = hotel['name'] ?? 'Hotel';
      buffer.write('${i + 1}) $name. ');
    }

    if (hotels.length > shownHotels.length) {
      buffer.write('Masih ada opsi lain. ');
    }

    buffer.write('Hotel mana yang ingin Anda pilih?');
    return buffer.toString();
  }

  String buildHotelDetailPrompt() {
    if (selectedHotel.isEmpty) {
      return 'Silakan pilih tipe kamar.';
    }

    final name = selectedHotel['name']?.toString() ?? 'Hotel ini';
    final facilities = (selectedHotel['amenities'] as List<dynamic>? ?? [])
        .map((item) => item.toString())
        .take(3)
        .toList(growable: false);
    final roomTypes = selectedHotel['roomTypes'] as List<dynamic>? ?? [];
    final roomNames = roomTypes
        .map((room) => (room as Map<String, dynamic>)['name']?.toString())
        .whereType<String>()
        .take(3)
        .toList();

    final facilitiesText = facilities.isNotEmpty
        ? '$name memiliki ${facilities.join(', ')}.'
        : '$name siap Anda pilih.';

    final roomsText = roomNames.isNotEmpty
        ? 'Pilihan kamar: ${roomNames.join(', ')}.'
        : 'Silakan pilih tipe kamar.';

    return '$facilitiesText $roomsText Tipe kamar apa yang ingin kamu pilih?';
  }

  BookingEntity? buildBookingEntityFromCache() {
    if (bookingData.isEmpty) return null;

    final hotel = bookingData['hotel'] as Map<String, dynamic>?;
    final room = bookingData['room'] as Map<String, dynamic>?;
    final bookingDetails =
        bookingData['booking_details'] as Map<String, dynamic>?;
    final guestInfo = bookingData['guest_info'] as Map<String, dynamic>?;
    final pricing = bookingData['pricing'] as Map<String, dynamic>?;
    final cancellationPolicy =
        bookingData['cancellation_policy'] as Map<String, dynamic>?;

    if (hotel == null ||
        room == null ||
        bookingDetails == null ||
        guestInfo == null ||
        pricing == null) {
      return null;
    }

    final primaryGuest =
        guestInfo['primaryGuest'] as Map<String, dynamic>? ?? {};

    return BookingEntity(
      bookingId:
          bookingData['booking_id']?.toString() ??
          bookingData['bookingId']?.toString() ??
          'temp-booking',
      confirmationNumber: bookingData['confirmation_number']?.toString(),
      bookingStatus: bookingData['status']?.toString() ?? 'pending',
      hotel: HotelInfoEntity(
        id: hotel['id'].toString(),
        name: hotel['name'].toString(),
        address: hotel['address'].toString(),
        rating: (hotel['rating'] as num).toDouble(),
        phone: hotel['phone']?.toString() ?? '',
        email: hotel['email']?.toString() ?? '',
      ),
      room: RoomInfoEntity(
        id: room['id'].toString(),
        name: room['name'].toString(),
        bedType: room['bedType']?.toString() ?? 'Double',
        maxGuests: (room['maxGuests'] as num).toInt(),
      ),
      bookingDetails: BookingDetailsEntity(
        checkIn: bookingDetails['checkIn'].toString(),
        checkOut: bookingDetails['checkOut'].toString(),
        checkInTime: bookingDetails['checkInTime'].toString(),
        checkOutTime: bookingDetails['checkOutTime'].toString(),
        nights: (bookingDetails['nights'] as num).toInt(),
        guests: (bookingDetails['guests'] as num).toInt(),
        rooms: (bookingDetails['rooms'] as num).toInt(),
      ),
      guestInfo: GuestInfoEntity(
        primaryGuest: PrimaryGuestEntity(
          title: primaryGuest['title'].toString(),
          fullName: primaryGuest['fullName'].toString(),
          email: primaryGuest['email'].toString(),
          phone: primaryGuest['phone'].toString(),
        ),
        specialRequests: guestInfo['specialRequests']?.toString(),
      ),
      pricing: PricingEntity(
        subtotal: (pricing['subtotal'] as num).toDouble(),
        taxes: (pricing['taxes'] as num).toDouble(),
        fees: (pricing['fees'] as num).toDouble(),
        discount: (pricing['discount'] as num).toDouble(),
        grandTotal: (pricing['grandTotal'] as num).toDouble(),
        currency: pricing['currency'].toString(),
        dueNow: pricing['dueNow'] == null
            ? null
            : (pricing['dueNow'] as num).toDouble(),
        dueAtProperty: pricing['dueAtProperty'] == null
            ? null
            : (pricing['dueAtProperty'] as num).toDouble(),
      ),
      cancellationPolicy: cancellationPolicy == null
          ? null
          : CancellationPolicyEntity(
              type: cancellationPolicy['type'].toString(),
              description: cancellationPolicy['description'].toString(),
              refundable: cancellationPolicy['refundable'] as bool,
              deadline: cancellationPolicy['deadline'] == null
                  ? null
                  : DateTime.tryParse(
                      cancellationPolicy['deadline'].toString(),
                    ),
            ),
    );
  }

  String getSystemInstructions() {
    return '''
Kamu adalah voice assistant khusus pemesanan hotel di aplikasi Qora.

Konteks:
- Tahap: ${_agentState.currentStep.name}
- Layar: ${_agentState.currentScreen ?? 'tidak diketahui'}
- Data: ${jsonEncode(_agentState.userConstraints)}

Aturan WAJIB:
1) Jawaban sangat ringkas: maksimal 2 kalimat dan maksimal 30 kata.
2) Maksimal 1 pertanyaan per respons.
3) Jangan jelaskan panjang, jangan daftar detail berlebihan, jangan mengulang info.
4) Fokus hanya booking hotel dalam aplikasi ini.
5) Jika user di luar konteks booking hotel (contoh: coding, matematika, politik, cuaca, trivia), jawab PERSIS:
   "Maaf, saya hanya bisa membantu pemesanan hotel di aplikasi ini."
6) Saat user minta cari hotel, panggil search_hotels.
7) Saat user pilih hotel, panggil get_hotel_details.
8) Saat user pilih kamar, panggil select_room lalu jawab singkat: "Kamar dipilih. Lanjutkan pemesanan?"
9) Jika user setuju lanjut, panggil create_booking.
10) Di ringkasan, jelaskan total lalu tanyakan apakah user ingin lanjut ke pembayaran.
11) Jika user setuju lanjut pembayaran, panggil navigate_to_screen ke booking_payment.
12) Saat sudah di halaman pembayaran, sampaikan: "Saya hanya bisa bantu sampai disini karena saya tidak ada akses ke fitur selanjutnya".
13) Jangan minta data tamu lagi.

Gunakan fungsi ini saat relevan:
search_hotels, get_hotel_details, select_room, create_booking, confirm_booking, navigate_to_screen, update_booking_step.
''';
  }

  String? resolveRoomId(Map<String, dynamic> args) {
    final roomId = args['room_id'] as String?;
    if (roomId != null && roomId.isNotEmpty) {
      return roomId;
    }

    final roomType = args['room_type']?.toString();
    final hotelRooms = selectedHotel['roomTypes'] as List?;
    if (roomType != null && hotelRooms != null) {
      for (final room in hotelRooms) {
        final roomMap = room as Map<String, dynamic>;
        final name = (roomMap['name'] ?? '').toString().toLowerCase();
        if (name.contains(roomType.toLowerCase())) {
          return roomMap['id']?.toString();
        }
      }
    }

    if (hotelRooms != null && hotelRooms.isNotEmpty) {
      final firstRoom = hotelRooms.first as Map<String, dynamic>;
      return firstRoom['id']?.toString();
    }

    return null;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
