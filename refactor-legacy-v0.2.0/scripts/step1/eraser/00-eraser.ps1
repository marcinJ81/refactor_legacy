<#
  00-eraser.ps1 — czyści wynik quality gate Step 1 dla jednej iteracji.
  Uruchamia go orkiestrator po wyniku `failed`, ZANIM ponowi Step 1, żeby
  brama próby 2 nie widziała artefaktów próby 1.
  Zakres czyszczenia: wyłącznie
  <katalog wynikowy>/quality-gate-step1-analize-result/iteracja-N/
  (pliki 01-04, podsumowanie.json i sam katalog). Plików Step 1
  (step1-analiza-N.md, step1-zmiany-N.json, step1-step-done-N.json, log)
  skrypt NIE rusza — nadpisuje je ponowiony krok.
  Kod wyjścia: 0 = wyczyszczone (albo nie było czego czyścić),
               1 = czyszczenie nieudane (coś zostało),
               2 = błąd wywołania (brak katalogu wynikowego).
#>
param(
    [Parameter(Mandatory = $true)][string]$KatalogWynikowy,
    [Parameter(Mandatory = $true)][int]$Iteracja,
    [string]$Powod = ""
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"
. (Join-Path (Split-Path -Parent $PSScriptRoot) "_wspolne.ps1")

if (-not (Test-Path -LiteralPath $KatalogWynikowy)) {
    Write-Host ("Katalog wynikowy nie istnieje: {0}" -f $KatalogWynikowy)
    exit 2
}

$katalog = Get-KatalogWynikuBramy -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja

if (-not (Test-Path -LiteralPath $katalog)) {
    Write-Host ("[eraser step1] {0} — iteracja {1}: brak katalogu wyniku bramy, nic do czyszczenia ({2})" -f (Get-Znacznik), $Iteracja, $katalog)
    exit 0
}

$pliki = @(Get-ChildItem -LiteralPath $katalog -Recurse -File | ForEach-Object { $_.FullName })

Remove-Item -LiteralPath $katalog -Recurse -Force

if (Test-Path -LiteralPath $katalog) {
    Write-Host ("[eraser step1] iteracja {0}: NIE UDAŁO SIĘ wyczyścić {1}" -f $Iteracja, $katalog)
    exit 1
}

Write-Host ("[eraser step1] {0} — iteracja {1}: usunięto {2} plik(ów) i katalog {3}{4}" -f (Get-Znacznik), $Iteracja, $pliki.Count, $katalog, $(if ($Powod) { " (powód: $Powod)" } else { "" }))
foreach ($p in $pliki) { Write-Host ("  - {0}" -f $p) }

exit 0
