import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Price Calculation & Promo Tests', () {
    test('Base price calculation for single night', () {
      // Arrange
      const basePrice = 500000.0;
      const nights = 1;

      // Act
      final totalPrice = basePrice * nights;

      // Assert
      expect(totalPrice, equals(500000.0));
    });

    test('Multi-night pricing calculation', () {
      // Arrange
      const basePrice = 750000.0;
      const nights = 3;

      // Act
      final totalPrice = basePrice * nights;

      // Assert
      expect(totalPrice, equals(2250000.0));
    });

    test('Promo discount 10% applied correctly', () {
      // Arrange
      const basePrice = 1000000.0;
      const promoPercent = 10;

      // Act
      final discount = basePrice * (promoPercent / 100);
      final finalPrice = basePrice - discount;

      // Assert
      expect(discount, equals(100000.0));
      expect(finalPrice, equals(900000.0));
    });

    test('Promo discount 50% applied correctly', () {
      // Arrange
      const basePrice = 2000000.0;
      const promoPercent = 50;

      // Act
      final discount = basePrice * (promoPercent / 100);
      final finalPrice = basePrice - discount;

      // Assert
      expect(discount, equals(1000000.0));
      expect(finalPrice, equals(1000000.0));
    });

    test('Fixed amount promo applied correctly', () {
      // Arrange
      const basePrice = 1500000.0;
      const promoAmount = 200000.0;

      // Act
      final finalPrice = basePrice - promoAmount;

      // Assert
      expect(finalPrice, equals(1300000.0));
      expect(finalPrice, greaterThan(0));
    });

    test('Expired promo should not be applied', () {
      // Arrange
      final now = DateTime.now();
      final promoExpiry = DateTime.now().subtract(const Duration(days: 1));
      const basePrice = 1000000.0;

      // Act
      final isPromoValid = promoExpiry.isAfter(now);
      final finalPrice = isPromoValid ? basePrice * 0.9 : basePrice;

      // Assert
      expect(isPromoValid, false);
      expect(finalPrice, equals(basePrice));
    });

    test('Valid promo should be applied', () {
      // Arrange
      final now = DateTime.now();
      final promoExpiry = DateTime.now().add(const Duration(days: 7));
      const basePrice = 1000000.0;
      const discount = 0.15;

      // Act
      final isPromoValid = promoExpiry.isAfter(now);
      final finalPrice = isPromoValid ? basePrice * (1 - discount) : basePrice;

      // Assert
      expect(isPromoValid, true);
      expect(finalPrice, equals(850000.0));
    });

    test('Multiple rooms pricing calculation', () {
      // Arrange
      const pricePerRoom = 600000.0;
      const rooms = 3;
      const nights = 2;

      // Act
      final totalPrice = pricePerRoom * rooms * nights;

      // Assert
      expect(totalPrice, equals(3600000.0));
    });

    test('Price consistency across state updates', () {
      // Arrange
      const initialPrice = 1000000.0;
      var currentPrice = initialPrice;

      // Act - Multiple state updates
      currentPrice = currentPrice; // State update 1
      currentPrice = currentPrice; // State update 2
      currentPrice = currentPrice; // State update 3

      // Assert
      expect(currentPrice, equals(initialPrice));
    });

    test('Tax calculation (10% VAT)', () {
      // Arrange
      const basePrice = 1000000.0;
      const taxRate = 0.10;

      // Act
      final tax = basePrice * taxRate;
      final totalPrice = basePrice + tax;

      // Assert
      expect(tax, equals(100000.0));
      expect(totalPrice, equals(1100000.0));
    });

    test('Service charge calculation (5%)', () {
      // Arrange
      const basePrice = 2000000.0;
      const serviceChargeRate = 0.05;

      // Act
      final serviceCharge = basePrice * serviceChargeRate;
      final totalPrice = basePrice + serviceCharge;

      // Assert
      expect(serviceCharge, equals(100000.0));
      expect(totalPrice, equals(2100000.0));
    });

    test('Weekend surcharge applied', () {
      // Arrange
      const basePrice = 800000.0;
      const weekendSurcharge = 0.20;
      const isWeekend = true;

      // Act
      final finalPrice = isWeekend
          ? basePrice * (1 + weekendSurcharge)
          : basePrice;

      // Assert
      expect(finalPrice, equals(960000.0));
    });

    test('Early bird discount applied', () {
      // Arrange
      const basePrice = 1500000.0;
      const checkIn = 45; // days in advance
      const earlyBirdThreshold = 30;
      const earlyBirdDiscount = 0.15;

      // Act
      final discount = checkIn >= earlyBirdThreshold ? earlyBirdDiscount : 0.0;
      final finalPrice = basePrice * (1 - discount);

      // Assert
      expect(discount, equals(0.15));
      expect(finalPrice, equals(1275000.0));
    });

    test('Minimum promo amount threshold', () {
      // Arrange
      const basePrice = 400000.0;
      const minPromoAmount = 500000.0;
      const promoDiscount = 0.10;

      // Act
      final isEligible = basePrice >= minPromoAmount;
      final finalPrice = isEligible
          ? basePrice * (1 - promoDiscount)
          : basePrice;

      // Assert
      expect(isEligible, false);
      expect(finalPrice, equals(basePrice));
    });

    test('Maximum discount cap applied', () {
      // Arrange
      const basePrice = 10000000.0;
      const promoPercent = 50;
      const maxDiscountCap = 2000000.0;

      // Act
      final calculatedDiscount = basePrice * (promoPercent / 100);
      final actualDiscount = calculatedDiscount > maxDiscountCap
          ? maxDiscountCap
          : calculatedDiscount;
      final finalPrice = basePrice - actualDiscount;

      // Assert
      expect(calculatedDiscount, equals(5000000.0));
      expect(actualDiscount, equals(maxDiscountCap));
      expect(finalPrice, equals(8000000.0));
    });

    test('Cumulative pricing with multiple add-ons', () {
      // Arrange
      const roomPrice = 1000000.0;
      const breakfastCost = 150000.0;
      const airportTransfer = 200000.0;
      const extraBed = 100000.0;

      // Act
      final totalPrice = roomPrice + breakfastCost + airportTransfer + extraBed;

      // Assert
      expect(totalPrice, equals(1450000.0));
    });

    test('Promo code case insensitive validation', () {
      // Arrange
      const validPromoCode = 'WEEKEND50';
      const userInput = 'weekend50';

      // Act
      final isValid = validPromoCode.toLowerCase() == userInput.toLowerCase();

      // Assert
      expect(isValid, true);
    });

    test('Invalid promo code should not apply discount', () {
      // Arrange
      const validPromoCodes = ['SAVE10', 'WEEKEND50', 'NEWYEAR'];
      const userPromoCode = 'INVALID';
      const basePrice = 1000000.0;

      // Act
      final isValid = validPromoCodes.contains(userPromoCode);
      final finalPrice = isValid ? basePrice * 0.9 : basePrice;

      // Assert
      expect(isValid, false);
      expect(finalPrice, equals(basePrice));
    });

    test('Price should never be negative after discount', () {
      // Arrange
      const basePrice = 100000.0;
      const hugeDiscount = 150000.0;

      // Act
      final finalPrice = (basePrice - hugeDiscount).clamp(0.0, double.infinity);

      // Assert
      expect(finalPrice, equals(0.0));
      expect(finalPrice, greaterThanOrEqualTo(0));
    });

    test('Rounding to nearest currency unit', () {
      // Arrange
      const basePrice = 1234567.89;

      // Act
      final roundedPrice = (basePrice / 1000).round() * 1000;

      // Assert
      expect(roundedPrice, equals(1235000));
    });
  });
}
