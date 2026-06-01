# Verify that git submodules are properly populated
# Usage: .github\scripts\verify_submodules.ps1 <path1> [path2] ...

param(
    [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
    [string[]]$Paths
)

$failed = $false

foreach ($path in $Paths) {
  if (-not (Test-Path $path) -or (Get-ChildItem $path).Count -eq 0) {
    Write-Error "ERROR: submodule '$path' is missing or empty."
    $failed = $true
  } else {
    Write-Host "OK: $path"
  }
}

if ($failed) { exit 1 }
