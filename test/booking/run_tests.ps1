# Qora Booking Unit Test Runner (PowerShell)

Write-Host "🧪 Running Qora Booking Unit Tests..." -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Test Categories:" -ForegroundColor Yellow
Write-Host "  1. Input Validation (15 tests)"
Write-Host "  2. Room Selection (15 tests)"
Write-Host "  3. Pricing Logic (20 tests)"
Write-Host "  4. Confirmation Flow (20 tests)"
Write-Host "  5. Error Handling (21 tests)"
Write-Host "  6. Performance & Stability (15 tests)"
Write-Host ""
Write-Host "Total: 106 tests" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Run all tests
flutter test test/booking/ --reporter expanded

# Check exit code
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ All tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Some tests failed. Review output above." -ForegroundColor Red
    exit 1
}
