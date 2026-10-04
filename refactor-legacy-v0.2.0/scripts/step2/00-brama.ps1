<#
  00-brama.ps1 — quality gate Step 2: build projektu + unit testy.
  Wywołuje go hook `.claude/hooks/step2-stop.ps1` (SubagentStop, matcher step2).
  Wynik: quality-gate-step2-result/iteracja-N/podsumowanie.json
  Kod wyjścia: 0 = passed, 1 = failed, 2 = błąd wywołania.

  Zgoda: pytanie_0.zgoda_build / pytanie_0.zgoda_testy z refactor-config.json
  — jedyna akceptacja uruchomienia; `false` → pozycja `nie_wykonano`.
  Wersja .NET: pytanie_0.wersja_dotnet (framework / core / net5plus) wybiera
  polecenia. *(w budowie)* Same polecenia build / testy dla każdej wersji —
  do tego czasu zwracają `nie_wykonano`.
#>
param(
    [Parameter(Mandatory = $true)][string]$KatalogWynikowy,
    [Parameter(Mandatory = $true)][int]$Iteracja
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"

function Get-Znacznik {
    # Format obowiązujący w całym harnessie: yyyy-MM-dd; HH-mm-ss
    (Get-Date).ToString("yyyy-MM-dd; HH-mm-ss")
}

function Save-Json {
    # Zapis bez BOM-u — PS 5.1 przez Set-Content -Encoding UTF8 dokłada BOM.
    param([string]$Sciezka, $Obiekt)
    $tresc = $Obiekt | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($Sciezka, $tresc, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-Wartosc {
    # Odczyt pytanie_0.<pole>.wartosc; brak pola → $null.
    param($Konfiguracja, [string]$Pole)
    $p0 = $Konfiguracja.PSObject.Properties["pytanie_0"]
    if (-not $p0) { return $null }
    $pozycja = $p0.Value.PSObject.Properties[$Pole]
    if (-not $pozycja) { return $null }
    $wartosc = $pozycja.Value.PSObject.Properties["wartosc"]
    if ($wartosc) { $wartosc.Value } else { $null }
}

function Invoke-Build {
    # *(w budowie)* — polecenie dla danej wersji .NET.
    param([string]$WersjaDotnet)
    switch ($WersjaDotnet) {
        "framework" { $komunikat = "build .NET Framework w budowie" }
        "core"      { $komunikat = "build .NET Core w budowie" }
        "net5plus"  { $komunikat = "build .NET 5+ w budowie" }
        default     { $komunikat = ("nieznana wersja .NET: {0}" -f $WersjaDotnet) }
    }
    [ordered]@{ wynik = "nie_wykonano"; polecenie = ""; komunikat = $komunikat; wykonal = "hook" }
}

function Invoke-Testy {
    # *(w budowie)* — polecenie dla danej wersji .NET i framework_testow.
    param([string]$WersjaDotnet, [string]$FrameworkTestow)
    switch ($WersjaDotnet) {
        "framework" { $komunikat = ("testy .NET Framework ({0}) w budowie" -f $FrameworkTestow) }
        "core"      { $komunikat = ("testy .NET Core ({0}) w budowie" -f $FrameworkTestow) }
        "net5plus"  { $komunikat = ("testy .NET 5+ ({0}) w budowie" -f $FrameworkTestow) }
        default     { $komunikat = ("nieznana wersja .NET: {0}" -f $WersjaDotnet) }
    }
    [ordered]@{ wynik = "nie_wykonano"; przeszlo = 0; wszystkich = 0; polecenie = ""; komunikat = $komunikat; wykonal = "hook" }
}

function New-NieWykonano {
    param([string]$Komunikat, [switch]$Testy)
    if ($Testy) {
        [ordered]@{ wynik = "nie_wykonano"; przeszlo = 0; wszystkich = 0; polecenie = ""; komunikat = $Komunikat; wykonal = "hook" }
    } else {
        [ordered]@{ wynik = "nie_wykonano"; polecenie = ""; komunikat = $Komunikat; wykonal = "hook" }
    }
}

if (-not (Test-Path -LiteralPath $KatalogWynikowy)) {
    Write-Host ("Katalog wynikowy nie istnieje: {0}" -f $KatalogWynikowy)
    exit 2
}

$plikKonfiguracji = Join-Path $KatalogWynikowy "refactor-config.json"
if (-not (Test-Path -LiteralPath $plikKonfiguracji)) {
    Write-Host ("Brak refactor-config.json: {0}" -f $plikKonfiguracji)
    exit 2
}
$konfiguracja = Get-Content -LiteralPath $plikKonfiguracji -Raw -Encoding UTF8 | ConvertFrom-Json

$wersjaDotnet    = [string](Get-Wartosc -Konfiguracja $konfiguracja -Pole "wersja_dotnet")
$frameworkTestow = [string](Get-Wartosc -Konfiguracja $konfiguracja -Pole "framework_testow")
$zgodaBuild      = (Get-Wartosc -Konfiguracja $konfiguracja -Pole "zgoda_build") -eq $true
$zgodaTesty      = (Get-Wartosc -Konfiguracja $konfiguracja -Pole "zgoda_testy") -eq $true

$build = if ($zgodaBuild) {
    Invoke-Build -WersjaDotnet $wersjaDotnet
} else {
    New-NieWykonano -Komunikat "brak zgody na build (pytanie_0.zgoda_build)"
}
$testy = if (-not $zgodaTesty) {
    New-NieWykonano -Testy -Komunikat "brak zgody na unit testy (pytanie_0.zgoda_testy)"
} elseif ($build.wynik -eq "ok") {
    Invoke-Testy -WersjaDotnet $wersjaDotnet -FrameworkTestow $frameworkTestow
} else {
    New-NieWykonano -Testy -Komunikat "build nie przeszedł"
}

$status = if ($build.wynik -eq "ok" -and $testy.wynik -eq "ok") { "passed" } else { "failed" }

$podsumowanie = [ordered]@{
    etap      = "etap1"
    krok      = "step2"
    iteracja  = $Iteracja
    wersja_dotnet = $wersjaDotnet
    status    = $status
    build     = $build
    testy     = $testy
    timestamp = Get-Znacznik
}

$katalog = Join-Path (Join-Path $KatalogWynikowy "quality-gate-step2-result") ("iteracja-{0}" -f $Iteracja)
if (-not (Test-Path -LiteralPath $katalog)) { New-Item -ItemType Directory -Path $katalog -Force | Out-Null }
$plik = Join-Path $katalog "podsumowanie.json"
Save-Json -Sciezka $plik -Obiekt $podsumowanie

Write-Host ("[brama step2] iteracja {0}: {1} -> {2}" -f $Iteracja, $status, $plik)

if ($status -eq "passed") { exit 0 } else { exit 1 }
