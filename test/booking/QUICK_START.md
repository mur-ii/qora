# 🚀 Quick Start Guide - Qora Booking Tests

## Installation

```bash
# Install dependencies
flutter pub get
```

## Running Tests

### Quick Run (Recommended)

```bash
flutter test test/booking/
```

### Detailed Output

```bash
flutter test test/booking/ --reporter expanded
```

### Individual Test Files

```bash
flutter test test/booking/booking_input_validation_test.dart
flutter test test/booking/booking_pricing_test.dart
flutter test test/booking/booking_performance_test.dart
```

### Integration Test Only

```bash
flutter test test/booking/booking_flow_integration_test.dart
```

## Expected Output

```
00:02 +108: All tests passed!
```

**108 tests** covering:

- Input validation (15)
- Room selection (15)
- Pricing logic (20)
- Confirmation flow (20)
- Error handling (21)
- Performance (15)
- Integration (4)

## Performance Targets

| Operation       | Target  | Actual   |
| --------------- | ------- | -------- |
| Booking flow    | < 500ms | 0-5ms ✅ |
| Search          | < 200ms | 0ms ✅   |
| Price calc (1k) | < 100ms | 0ms ✅   |
| Stress (100)    | < 5s    | 0ms ✅   |

## Common Commands

```bash
# Run all tests
flutter test test/booking/

# Run with coverage
flutter test test/booking/ --coverage

# Watch mode (re-run on changes)
flutter test test/booking/ --watch

# Specific test pattern
flutter test test/booking/ --name "pricing"
```

## Troubleshooting

### Test Fails

1. Run specific file: `flutter test test/booking/booking_confirmation_test.dart`
2. Check error message
3. Review test code and assertions

### Import Errors

```bash
flutter clean
flutter pub get
```

### Performance Issues

- Tests should complete in < 2 seconds total
- Individual tests < 500ms
- Check system resources if slower

## Files Overview

```
test/booking/
├── booking_input_validation_test.dart    ← Input checks
├── booking_room_selection_test.dart      ← Room logic
├── booking_pricing_test.dart             ← Price calculations
├── booking_confirmation_test.dart        ← Booking flow
├── booking_error_handling_test.dart      ← Error scenarios
├── booking_performance_test.dart         ← Speed & stability
└── booking_flow_integration_test.dart    ← End-to-end
```

## Success Criteria

✅ All 108 tests passing  
✅ 100% success rate  
✅ < 2 second total execution  
✅ Zero compilation errors  
✅ Clean test output

---

**Status:** ✅ Ready to use  
**Last Updated:** January 21, 2026
