param(
  [int]$LoopCount = 10,
  [string]$OutputDirectory = "performance_reports",
  [string]$TestFile = "integration_test/app_login_booking_logout_flow_test.dart"
)

$ErrorActionPreference = "Stop"

if ($LoopCount -le 0) {
  throw "LoopCount must be greater than 0."
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (-not (Test-Path $OutputDirectory)) {
  New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$outputPath = Join-Path $OutputDirectory "gui_performance_loop_${LoopCount}_${timestamp}.csv"

Write-Host "Running performance loop test ($LoopCount iterations)..."
Write-Host "Command: flutter test $TestFile --dart-define=PERF_LOOP_COUNT=$LoopCount"

$rawOutput = & flutter test $TestFile "--dart-define=PERF_LOOP_COUNT=$LoopCount" 2>&1 |
  Tee-Object -Variable capturedOutput

$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
  throw "Flutter test failed with exit code $exitCode"
}

$lines = @($capturedOutput | ForEach-Object { $_.ToString() })

$startIndex = -1
$endIndex = -1

for ($i = 0; $i -lt $lines.Count; $i++) {
  if ($startIndex -lt 0 -and $lines[$i].Contains("PERFORMANCE_CSV_START")) {
    $startIndex = $i
    continue
  }

  if ($startIndex -ge 0 -and $lines[$i].Contains("PERFORMANCE_CSV_END")) {
    $endIndex = $i
    break
  }
}

if ($startIndex -lt 0 -or $endIndex -lt 0 -or $endIndex -le $startIndex + 1) {
  throw "CSV markers not found in test output."
}

$csvLines = $lines[($startIndex + 1)..($endIndex - 1)]

Set-Content -Path $outputPath -Value $csvLines -Encoding UTF8

Write-Host ""
Write-Host "CSV exported to: $outputPath"
Write-Host "Done."
