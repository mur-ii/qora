import '../../domain/entities/notification_entity.dart';

class NotificationLocalDataSource {
  Future<List<NotificationEntity>> fetchNotifications() async {
    final now = DateTime.now();
    return [
      NotificationEntity(
        id: 'notif_1',
        type: NotificationType.booking,
        title: 'Booking Berhasil!',
        message:
            'Reservasi Anda di Grand Luxury Hotel telah dikonfirmasi untuk tanggal 22-25 Januari 2026.',
        time: now.subtract(const Duration(hours: 2)),
        isUnread: true,
      ),
      NotificationEntity(
        id: 'notif_2',
        type: NotificationType.promo,
        title: 'Promo Spesial Weekend! 🎉',
        message:
            'Dapatkan diskon hingga 50% untuk booking hotel di akhir pekan. Buruan pesan sekarang!',
        time: now.subtract(const Duration(hours: 5)),
        isUnread: true,
      ),
      NotificationEntity(
        id: 'notif_3',
        type: NotificationType.payment,
        title: 'Pembayaran Berhasil',
        message:
            'Pembayaran sebesar Rp 2.500.000 untuk Sunset Beach Resort telah diterima.',
        time: now.subtract(const Duration(days: 1, hours: 10)),
        isUnread: false,
      ),
      NotificationEntity(
        id: 'notif_4',
        type: NotificationType.reminder,
        title: 'Pengingat Check-in',
        message:
            'Jangan lupa! Check-in Anda di Mountain View Lodge besok pukul 14:00.',
        time: now.subtract(const Duration(days: 1, hours: 14)),
        isUnread: false,
      ),
      NotificationEntity(
        id: 'notif_5',
        type: NotificationType.review,
        title: 'Bagikan Pengalaman Anda',
        message:
            'Terima kasih telah menginap di Royal Palace Hotel. Berikan review Anda!',
        time: now.subtract(const Duration(days: 5)),
        isUnread: false,
      ),
      NotificationEntity(
        id: 'notif_6',
        type: NotificationType.promo,
        title: 'Cashback 100rb',
        message:
            'Dapatkan cashback Rp 100.000 untuk transaksi minimal Rp 500.000. Berlaku hingga akhir bulan!',
        time: now.subtract(const Duration(days: 6)),
        isUnread: false,
      ),
      NotificationEntity(
        id: 'notif_7',
        type: NotificationType.booking,
        title: 'Konfirmasi Pembatalan',
        message:
            'Pembatalan booking Anda di Beachfront Paradise telah diproses. Dana akan dikembalikan dalam 3-5 hari kerja.',
        time: now.subtract(const Duration(days: 7)),
        isUnread: false,
      ),
    ];
  }
}
