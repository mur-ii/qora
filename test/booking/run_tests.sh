#!/bin/bash
# Qora Booking Unit Test Runner

echo "🧪 Running Qora Booking Unit Tests..."
echo "======================================"
echo ""

echo "📋 Test Categories:"
echo "  1. Input Validation (15 tests)"
echo "  2. Room Selection (15 tests)"
echo "  3. Pricing Logic (20 tests)"
echo "  4. Confirmation Flow (20 tests)"
echo "  5. Error Handling (21 tests)"
echo "  6. Performance & Stability (15 tests)"
echo ""
echo "Total: 106 tests"
echo "======================================"
echo ""

# Run all tests
flutter test test/booking/ --reporter expanded

# Check exit code
if [ $? -eq 0 ]; then
    echo ""
    echo "✅ All tests passed successfully!"
else
    echo ""
    echo "❌ Some tests failed. Review output above."
    exit 1
fi
