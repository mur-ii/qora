param(
  [int]$LoopCount = 10,
  [string]$OutputDirectory = "performance_reports",
  [string]$DriverFile = "test_driver/integration_test.dart",
  [string]$TestFile = "integration_test/app_login_booking_logout_flow_test.dart"
)

$ErrorActionPreference = "Stop"

$delegateScript = Join-Path $PSScriptRoot "run_performance_loop.ps1"

if (-not (Test-Path $delegateScript)) {
  throw "Delegate script not found: $delegateScript"
}

& $delegateScript `
  -LoopCount $LoopCount `
  -OutputDirectory $OutputDirectory `
  -DriverFile $DriverFile `
  -TestFile $TestFile
