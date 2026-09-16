<#
  00-brama.ps1 — uruchamia komplet sprawdzeń bramy Step 1 (01-04) i zapisuje
  podsumowanie. Wywołuje go orkiestrator; skrypty 01-04 da się też uruchomić
  pojedynczo. Brama nie ocenia treści analizy — wyłącznie strukturę wyniku.
  Wynik: quality-gate-step1-analize-result/iteracja-N/podsumowanie.json
  Kod wyjścia: 0 = passed, 1 = failed, 2 = błąd wywołania.
#>
param(
    [Parameter(Mandatory = $true)][string]$KatalogWynikowy,
    [Parameter(Mandatory = $true)][int]$Iteracja,
    [string]$PlikAnalizy,
    [ValidateSet(1, 2)][int]$Proba = 1
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_wspolne.ps1")

if (-not (Test-Path -LiteralPath $KatalogWynikowy)) {
    Write-Host ("Katalog wynikowy nie istnieje: {0}" -f $KatalogWynikowy)
    exit 2
}

$wspolne = @{ KatalogWynikowy = $KatalogWynikowy; Iteracja = $Iteracja }
$skrypty = @(
    @{ nazwa = "01-pliki";   parametry = $wspolne + @{ PlikAnalizy = $PlikAnalizy } },
    @{ nazwa = "02-sekcje";  parametry = $wspolne + @{ PlikAnalizy = $PlikAnalizy } },
    @{ nazwa = "03-json";    parametry = $wspolne },
    @{ nazwa = "04-licznik"; parametry = $wspolne + @{ PlikAnalizy = $PlikAnalizy } }
)

$wyniki = @()
foreach ($s in $skrypty) {
    $parametry = @{} + $s.parametry
    if ($parametry.ContainsKey("PlikAnalizy") -and -not $parametry.PlikAnalizy) { $parametry.Remove("PlikAnalizy") }

    & (Join-Path $PSScriptRoot ("{0}.ps1" -f $s.nazwa)) @parametry
    $kod = $LASTEXITCODE

    $wyniki += [ordered]@{
        skrypt      = $s.nazwa
        kod_wyjscia = $kod
        wynik       = switch ($kod) { 0 { "passed" } 1 { "failed" } default { "blad" } }
    }
}

$niezaliczone = @($wyniki | Where-Object { $_.wynik -ne "passed" })
$status = if ($niezaliczone.Count -eq 0) { "passed" } else { "failed" }

$podsumowanie = [ordered]@{
    etap         = "etap1"
    krok         = "step1"
    iteracja     = $Iteracja
    proba        = $Proba
    status       = $status
    sprawdzenia  = $wyniki
    niezaliczone = @($niezaliczone | ForEach-Object { $_.skrypt })
    timestamp    = Get-Znacznik
}

$katalog = Get-KatalogWynikuBramy -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja
if (-not (Test-Path -LiteralPath $katalog)) { New-Item -ItemType Directory -Path $katalog -Force | Out-Null }
$plik = Join-Path $katalog "podsumowanie.json"
Save-Json -Sciezka $plik -Obiekt $podsumowanie

Write-Host ("[brama step1] iteracja {0}, próba {1}: {2} -> {3}" -f $Iteracja, $Proba, $status, $plik)

if ($status -eq "passed") { exit 0 } else { exit 1 }
