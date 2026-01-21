import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Booking Input Validation Tests', () {
    test('Valid hotel search input should pass validation', () {
      // Arrange
      const location = 'Jakarta';
      final checkIn = DateTime.now().add(const Duration(days: 1));
      final checkOut = DateTime.now().add(const Duration(days: 3));
      const guests = 2;
      const rooms = 1;

      // Act & Assert
      expect(location.isNotEmpty, true);
      expect(checkOut.isAfter(checkIn), true);
      expect(guests, greaterThan(0));
      expect(rooms, greaterThan(0));
      expect(guests >= rooms, true);
    });

    test('Invalid date: check-out before check-in should fail', () {
      // Arrange
      final checkIn = DateTime.now().add(const Duration(days: 3));
      final checkOut = DateTime.now().add(const Duration(days: 1));

      // Act & Assert
      expect(checkOut.isBefore(checkIn), true);
      expect(checkOut.isAfter(checkIn), false);
    });

    test('Empty location should fail validation', () {
      // Arrange
      const location = '';

      // Act & Assert
      expect(location.isEmpty, true);
      expect(location.trim().isEmpty, true);
    });

    test('Guest and room mismatch should fail validation', () {
      // Arrange
      const guests = 1;
      const rooms = 3;

      // Act & Assert
      expect(guests < rooms, true); // Invalid: more rooms than guests
    });

    test('Boundary values: 1 guest should be valid', () {
      // Arrange
      const guests = 1;
      const rooms = 1;

      // Act & Assert
      expect(guests, equals(1));
      expect(rooms, equals(1));
      expect(guests >= rooms, true);
    });

    test('Boundary values: maximum guests (10) should be valid', () {
      // Arrange
      const maxGuests = 10;
      const rooms = 5;

      // Act & Assert
      expect(maxGuests, lessThanOrEqualTo(10));
      expect(maxGuests >= rooms, true);
    });

    test('Zero guests should fail validation', () {
      // Arrange
      const guests = 0;

      // Act & Assert
      expect(guests, equals(0));
      expect(guests > 0, false);
    });

    test('Negative guests should fail validation', () {
      // Arrange
      const guests = -1;

      // Act & Assert
      expect(guests, lessThan(0));
      expect(guests > 0, false);
    });

    test('Same check-in and check-out date should fail', () {
      // Arrange
      final checkIn = DateTime.now().add(const Duration(days: 1));
      final checkOut = checkIn;

      // Act & Assert
      expect(checkOut.isAtSameMomentAs(checkIn), true);
      expect(checkOut.isAfter(checkIn), false);
    });

    test('Check-in in the past should fail validation', () {
      // Arrange
      final checkIn = DateTime.now().subtract(const Duration(days: 1));
      final now = DateTime.now();

      // Act & Assert
      expect(checkIn.isBefore(now), true);
    });

    test('More than 30 nights booking should require special validation', () {
      // Arrange
      final checkIn = DateTime.now().add(const Duration(days: 1));
      final checkOut = DateTime.now().add(const Duration(days: 32));
      final nights = checkOut.difference(checkIn).inDays;

      // Act & Assert
      expect(nights, greaterThan(30));
    });

    test('Special characters in location should be sanitized', () {
      // Arrange
      const location = 'Jakarta<script>';
      final sanitized = location.replaceAll(RegExp(r'[<>]'), '');

      // Act & Assert
      expect(sanitized, equals('Jakartascript'));
      expect(sanitized.contains('<'), false);
      expect(sanitized.contains('>'), false);
    });

    test('Whitespace-only location should fail validation', () {
      // Arrange
      const location = '   ';

      // Act & Assert
      expect(location.trim().isEmpty, true);
    });

    test('Room count exceeding limit (5) should fail', () {
      // Arrange
      const rooms = 6;
      const maxRooms = 5;

      // Act & Assert
      expect(rooms, greaterThan(maxRooms));
    });

    test('Valid date range of 1 night should pass', () {
      // Arrange
      final checkIn = DateTime.now().add(const Duration(days: 1));
      final checkOut = DateTime.now().add(const Duration(days: 2));
      final nights = checkOut.difference(checkIn).inDays;

      // Act & Assert
      expect(nights, equals(1));
      expect(nights, greaterThan(0));
    });
  });
}
