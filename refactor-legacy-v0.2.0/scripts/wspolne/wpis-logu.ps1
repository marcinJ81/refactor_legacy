<#
  wersja-harnessu: 0.2.2
  wpis-logu.ps1 — jedyna droga dopisania wpisu do logu harnessu
  (orkiestrator-log.md, step1-log.md, step2-log.md) i źródło znacznika czasu
  dla pól JSON (`timestamp` w kopercie i `step.done`, `utworzono` /
  `zaktualizowano` w refactor-config.json).

  Znacznik bierze z zegara systemowego (Get-Date) w chwili wywołania. Model
  nie zna bieżącej godziny — nie wpisuje znacznika sam, tylko woła ten skrypt.

  Wywołania:
    wpis-logu.ps1 -Plik <log> -Tresc "<nr>. <treść>"
        → dopisuje linię "<znacznik> — <nr>. <treść>"
    wpis-logu.ps1 -Plik <log> -Naglowek uruchomienie
        → dopisuje "## Uruchomienie <znacznik>"
    wpis-logu.ps1 -Plik <log> -Naglowek iteracja -Iteracja <N>
        → dopisuje "### Iteracja <N>" (bez znacznika)
    wpis-logu.ps1 -Plik <log> -Naglowek zadania
        → dopisuje "### Zadania zlecone" (bez znacznika)
    wpis-logu.ps1 -TylkoZnacznik
        → wypisuje sam znacznik na standardowe wyjście, nic nie zapisuje

  -Tytul: gdy pliku logu jeszcze nie ma, tworzy go z pierwszą linią "# <Tytul>".
  -Konfiguracja: ścieżka do refactor-config.json; format znacznika z pola
  `harness.znacznik_czasu`. Bez niej (albo bez pola) — format harnessu
  yyyy-MM-dd; HH-mm-ss.

  Wypisuje dopisaną linię (albo sam znacznik). Kod wyjścia: 0 = zapisano,
  2 = błąd wywołania.
#>
param(
    [string]$Plik,
    [string]$Tresc,
    [ValidateSet("uruchomienie", "iteracja", "zadania")][string]$Naglowek,
    [int]$Iteracja,
    [string]$Tytul,
    [string]$Konfiguracja,
    [switch]$TylkoZnacznik
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"

$format = "yyyy-MM-dd; HH-mm-ss"
if ($Konfiguracja -and (Test-Path -LiteralPath $Konfiguracja -PathType Leaf)) {
    $config = Get-Content -LiteralPath $Konfiguracja -Raw -Encoding UTF8 | ConvertFrom-Json
    $harness = $config.PSObject.Properties["harness"]
    if ($harness -and $harness.Value.PSObject.Properties["znacznik_czasu"]) {
        $format = [string]$harness.Value.znacznik_czasu
    }
}
$znacznik = (Get-Date).ToString($format, [Globalization.CultureInfo]::InvariantCulture)

if ($TylkoZnacznik) {
    Write-Output $znacznik
    exit 0
}

if (-not $Plik) {
    Write-Host "Brak -Plik (ścieżka logu)."
    exit 2
}
if ($Naglowek -and $Tresc) {
    Write-Host "Podaj -Naglowek albo -Tresc, nie oba naraz."
    exit 2
}

switch ($Naglowek) {
    "uruchomienie" { $linia = "## Uruchomienie {0}" -f $znacznik }
    "iteracja" {
        if ($Iteracja -lt 1) { Write-Host "Brak -Iteracja dla nagłówka iteracji."; exit 2 }
        $linia = "### Iteracja {0}" -f $Iteracja
    }
    "zadania" { $linia = "### Zadania zlecone" }
    default {
        if (-not $Tresc) { Write-Host "Brak -Tresc (treść wpisu)."; exit 2 }
        $linia = "{0} — {1}" -f $znacznik, $Tresc.Trim()
    }
}

$kodowanie = New-Object System.Text.UTF8Encoding($false)
$doDopisania = ""
if (-not (Test-Path -LiteralPath $Plik -PathType Leaf)) {
    $katalog = Split-Path -Parent $Plik
    if ($katalog -and -not (Test-Path -LiteralPath $katalog)) {
        New-Item -ItemType Directory -Path $katalog -Force | Out-Null
    }
    if ($Tytul) { $doDopisania = "# {0}{1}" -f $Tytul, [Environment]::NewLine }
}
elseif ((Get-Item -LiteralPath $Plik).Length -gt 0) {
    # Plik nie kończy się nową linią → wpis nie może skleić się z poprzednim.
    $tresc = [System.IO.File]::ReadAllText($Plik, $kodowanie)
    if (-not $tresc.EndsWith("`n")) { $doDopisania = [Environment]::NewLine }
}

# Nagłówki oddzielone pustą linią od poprzedniej treści (czytelność markdownu).
if ($Naglowek -and ((Test-Path -LiteralPath $Plik -PathType Leaf) -or $doDopisania)) {
    $doDopisania += [Environment]::NewLine
}
$doDopisania += $linia + [Environment]::NewLine
if ($Naglowek) { $doDopisania += [Environment]::NewLine }

[System.IO.File]::AppendAllText($Plik, $doDopisania, $kodowanie)
Write-Output $linia
exit 0
