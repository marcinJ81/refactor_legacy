<#
  wersja-harnessu: 0.1.1
  wpis-logu.ps1 — jedyna droga dopisania wpisu do logu harnessu
  (orkiestrator-log.md, etap1-decisions-log.md, etap2-decisions-log.md)
  i źródło znacznika czasu dla pól JSON (`timestamp` w kopercie,
  `generated_at` w raporcie Etapu 0).

  Znacznik bierze z zegara systemowego (Get-Date) w chwili wywołania. Model
  nie zna bieżącej godziny — nie wpisuje znacznika sam, tylko woła ten skrypt.

  Wywołania:
    wpis-logu.ps1 -Plik <log> -Tresc "<nr>. <treść>"
        → dopisuje linię "<znacznik> — <nr>. <treść>"
    wpis-logu.ps1 -Plik <log> -Naglowek uruchomienie
        → dopisuje "## Uruchomienie <znacznik>"
    wpis-logu.ps1 -Plik <log> -Naglowek iteracja -Iteracja <N>
        → dopisuje "### Iteracja <N>" (bez znacznika)
    wpis-logu.ps1 -Plik <log> -Naglowek sekcja -Nazwa "<nazwa>"
        → dopisuje "### <nazwa>" (bez znacznika), np. "Krok 3 — iteracja 2"
    wpis-logu.ps1 -TylkoZnacznik
        → wypisuje sam znacznik na standardowe wyjście, nic nie zapisuje

  -Tytul: gdy pliku logu jeszcze nie ma, tworzy go z pierwszą linią "# <Tytul>".
  Format znacznika: yyyy-MM-dd; HH-mm-ss (stała harnessu).

  Wypisuje dopisaną linię (albo sam znacznik). Kod wyjścia: 0 = zapisano,
  2 = błąd wywołania.
#>
param(
    [string]$Plik,
    [string]$Tresc,
    [ValidateSet("uruchomienie", "iteracja", "sekcja")][string]$Naglowek,
    [int]$Iteracja,
    [string]$Nazwa,
    [string]$Tytul,
    [switch]$TylkoZnacznik
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"

$format = "yyyy-MM-dd; HH-mm-ss"
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
    "sekcja" {
        if (-not $Nazwa) { Write-Host "Brak -Nazwa dla nagłówka sekcji."; exit 2 }
        $linia = "### {0}" -f $Nazwa.Trim()
    }
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
