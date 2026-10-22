# Installs pcbmate-worker on Windows (PowerShell):
#   irm https://raw.githubusercontent.com/pcbmate/worker-cli/main/install.ps1 | iex
# The latest version is in latest.json; the executable comes from its release, checked against the
# release's SHA256SUMS, and goes to %LOCALAPPDATA%\pcbmate-worker\bin (added to the user's PATH).
# Then `setup` downloads the tools.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$repo = 'https://github.com/pcbmate/worker-cli'
$raw = 'https://raw.githubusercontent.com/pcbmate/worker-cli/main'
if ($env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw "pcbmate-worker: no build for $env:PROCESSOR_ARCHITECTURE" }

$version = (Invoke-RestMethod "$raw/latest.json").version
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw 'pcbmate-worker: cannot read the latest version' }
$name = "pcbmate-worker-$version-win32-x64.exe"
Write-Host "Installing pcbmate-worker $version for win32-x64"

$tmp = Join-Path ([IO.Path]::GetTempPath()) ([Guid]::NewGuid())
New-Item -ItemType Directory $tmp | Out-Null
try {
  Invoke-WebRequest "$repo/releases/download/worker-$version/$name" -OutFile "$tmp\$name" -UseBasicParsing
  # Release files come as application/octet-stream: the content is bytes, decoded here.
  $content = (Invoke-WebRequest "$repo/releases/download/worker-$version/SHA256SUMS" -UseBasicParsing).Content
  $sums = if ($content -is [byte[]]) { [Text.Encoding]::UTF8.GetString($content) } else { $content }
  $expected = ($sums -split "`n" | ForEach-Object { ,($_.Trim() -split '\s+') } |
    Where-Object { $_[1] -eq $name } | Select-Object -First 1)
  $actual = (Get-FileHash "$tmp\$name" -Algorithm SHA256).Hash.ToLower()
  if (-not $expected -or $expected[0] -ne $actual) { throw 'pcbmate-worker: the download does not match its checksum' }

  $bin = Join-Path $env:LOCALAPPDATA 'pcbmate-worker\bin'
  New-Item -ItemType Directory -Force $bin | Out-Null
  $exe = Join-Path $bin 'pcbmate-worker.exe'
  Move-Item -Force "$tmp\$name" $exe
} finally {
  Remove-Item -Recurse -Force $tmp
}

& $exe setup
if ($LASTEXITCODE -ne 0) { throw 'pcbmate-worker: setup failed' }

$path = [Environment]::GetEnvironmentVariable('Path', 'User')
if (($path -split ';') -notcontains $bin) {
  [Environment]::SetEnvironmentVariable('Path', (@($path, $bin) | Where-Object { $_ }) -join ';', 'User')
}
Write-Host ''
Write-Host "Done. Open a new terminal and connect this computer with a token from pcbmate's Workers page:"
Write-Host '  pcbmate-worker login <token> --api <https://your-pcbmate>'
Write-Host '  pcbmate-worker run'
