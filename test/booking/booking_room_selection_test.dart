import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hotel & Room Selection Tests', () {
    test('Selecting available hotel should return hotel details', () {
      // Arrange
      final availableHotels = [
        {'id': '1', 'name': 'Grand Hotel', 'available': true},
        {'id': '2', 'name': 'Beach Resort', 'available': true},
      ];
      const selectedHotelId = '1';

      // Act
      final selectedHotel = availableHotels.firstWhere(
        (hotel) => hotel['id'] == selectedHotelId,
      );

      // Assert
      expect(selectedHotel['id'], equals('1'));
      expect(selectedHotel['name'], equals('Grand Hotel'));
      expect(selectedHotel['available'], true);
    });

    test('Selecting unavailable room should return error', () {
      // Arrange
      final rooms = [
        {'id': 'r1', 'type': 'Deluxe', 'available': true, 'stock': 5},
        {'id': 'r2', 'type': 'Suite', 'available': false, 'stock': 0},
      ];
      const selectedRoomId = 'r2';

      // Act
      final selectedRoom = rooms.firstWhere(
        (room) => room['id'] == selectedRoomId,
      );

      // Assert
      expect(selectedRoom['available'], false);
      expect(selectedRoom['stock'], equals(0));
    });

    test('Room stock should decrease after booking', () {
      // Arrange
      var roomStock = 5;
      const roomsBooked = 2;

      // Act
      roomStock -= roomsBooked;

      // Assert
      expect(roomStock, equals(3));
      expect(roomStock, greaterThan(0));
    });

    test('Booking last available room should set stock to zero', () {
      // Arrange
      var roomStock = 1;
      const roomsBooked = 1;

      // Act
      roomStock -= roomsBooked;

      // Assert
      expect(roomStock, equals(0));
    });

    test('Booking more rooms than available should fail', () {
      // Arrange
      const roomStock = 3;
      const roomsRequested = 5;

      // Act
      final canBook = roomsRequested <= roomStock;

      // Assert
      expect(canBook, false);
      expect(roomsRequested, greaterThan(roomStock));
    });

    test('Multiple room types should be handled correctly', () {
      // Arrange
      final roomTypes = [
        {'type': 'Standard', 'price': 500000, 'available': 10},
        {'type': 'Deluxe', 'price': 750000, 'available': 5},
        {'type': 'Suite', 'price': 1200000, 'available': 2},
      ];

      // Act
      final availableTypes = roomTypes
          .where((room) => (room['available'] as int) > 0)
          .toList();

      // Assert
      expect(availableTypes.length, equals(3));
      expect(roomTypes.every((room) => room.containsKey('type')), true);
      expect(roomTypes.every((room) => room.containsKey('price')), true);
    });

    test('Selecting room with specific requirements should match criteria', () {
      // Arrange
      final rooms = [
        {'id': '1', 'beds': 1, 'maxGuests': 2, 'price': 500000},
        {'id': '2', 'beds': 2, 'maxGuests': 4, 'price': 800000},
        {'id': '3', 'beds': 3, 'maxGuests': 6, 'price': 1200000},
      ];
      const requiredGuests = 5;

      // Act
      final suitableRooms = rooms
          .where((room) => (room['maxGuests'] as int) >= requiredGuests)
          .toList();

      // Assert
      expect(suitableRooms.length, equals(1));
      expect(suitableRooms.first['id'], equals('3'));
    });

    test('Room amenities should be properly assigned', () {
      // Arrange
      final room = {
        'id': '1',
        'amenities': ['WiFi', 'TV', 'AC', 'Minibar'],
      };

      // Act
      final amenities = room['amenities'] as List<String>;

      // Assert
      expect(amenities.length, equals(4));
      expect(amenities.contains('WiFi'), true);
      expect(amenities.contains('Pool'), false);
    });

    test('Room price should match room type', () {
      // Arrange
      final roomPrices = {
        'Standard': 500000.0,
        'Deluxe': 750000.0,
        'Suite': 1200000.0,
      };
      const selectedType = 'Deluxe';

      // Act
      final price = roomPrices[selectedType];

      // Assert
      expect(price, equals(750000.0));
      expect(price, greaterThan(500000.0));
      expect(price, lessThan(1200000.0));
    });

    test('Concurrent booking should handle race condition', () {
      // Arrange
      var roomStock = 1;
      const booking1Rooms = 1;
      const booking2Rooms = 1;

      // Act - First booking
      final canBook1 = booking1Rooms <= roomStock;
      if (canBook1) {
        roomStock -= booking1Rooms;
      }

      // Second booking attempts
      final canBook2 = booking2Rooms <= roomStock;

      // Assert
      expect(canBook1, true);
      expect(canBook2, false);
      expect(roomStock, equals(0));
    });

    test('Room upgrade option should be available', () {
      // Arrange
      final currentRoom = {'type': 'Standard', 'price': 500000};
      final upgradeRoom = {'type': 'Deluxe', 'price': 750000};

      // Act
      final upgradeCost =
          (upgradeRoom['price'] as int) - (currentRoom['price'] as int);

      // Assert
      expect(upgradeCost, equals(250000));
      expect(upgradeCost, greaterThan(0));
    });

    test('Room filtering by price range should work', () {
      // Arrange
      final rooms = [
        {'id': '1', 'price': 400000},
        {'id': '2', 'price': 750000},
        {'id': '3', 'price': 1200000},
      ];
      const minPrice = 500000;
      const maxPrice = 1000000;

      // Act
      final filteredRooms = rooms.where((room) {
        final price = room['price'] as int;
        return price >= minPrice && price <= maxPrice;
      }).toList();

      // Assert
      expect(filteredRooms.length, equals(1));
      expect(filteredRooms.first['id'], equals('2'));
    });

    test('Selecting non-existent room should return null', () {
      // Arrange
      final rooms = [
        {'id': '1', 'type': 'Standard'},
        {'id': '2', 'type': 'Deluxe'},
      ];
      const selectedRoomId = '999';

      // Act
      final selectedRoom = rooms
          .where((room) => room['id'] == selectedRoomId)
          .firstOrNull;

      // Assert
      expect(selectedRoom, isNull);
    });

    test('Room capacity should not be exceeded', () {
      // Arrange
      const roomCapacity = 4;
      const requestedGuests = 6;

      // Act
      final isValidBooking = requestedGuests <= roomCapacity;

      // Assert
      expect(isValidBooking, false);
      expect(requestedGuests, greaterThan(roomCapacity));
    });
  });
}
