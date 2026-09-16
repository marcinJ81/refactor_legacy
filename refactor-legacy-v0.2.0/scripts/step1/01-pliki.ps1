<#
  01-pliki.ps1 — brama Step 1, sprawdzenie 1 z 4.
  Czy w katalogu wynikowym przebiegu leżą wszystkie pliki, które Step 1 miał
  wytworzyć dla tej iteracji, i czy żaden nie jest pusty.
  Wynik: quality-gate-step1-analize-result/iteracja-N/01-pliki.json
  Kod wyjścia: 0 = passed, 1 = failed, 2 = błąd wywołania.
#>
param(
    [Parameter(Mandatory = $true)][string]$KatalogWynikowy,
    [Parameter(Mandatory = $true)][int]$Iteracja,
    [string]$PlikAnalizy
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_wspolne.ps1")

if (-not (Test-Path -LiteralPath $KatalogWynikowy)) {
    Write-Host ("Katalog wynikowy nie istnieje: {0}" -f $KatalogWynikowy)
    exit 2
}

$analiza = Get-PlikAnalizy -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -PlikAnalizy $PlikAnalizy

$oczekiwane = @(
    @{ rola = "analiza";   sciezka = $analiza },
    @{ rola = "zmiany";    sciezka = (Join-Path $KatalogWynikowy ("step1-zmiany-{0}.json" -f $Iteracja)) },
    @{ rola = "step.done"; sciezka = (Join-Path $KatalogWynikowy ("step1-step-done-{0}.json" -f $Iteracja)) },
    @{ rola = "log";       sciezka = (Join-Path $KatalogWynikowy "step1-log.md") }
)

$szczegoly = @()
foreach ($p in $oczekiwane) {
    if (-not (Test-Path -LiteralPath $p.sciezka -PathType Leaf)) {
        $szczegoly += New-Szczegol -Pozycja $p.rola -Wynik "brak" -Komunikat ("Nie ma pliku: {0}" -f $p.sciezka)
        continue
    }
    if ((Get-Item -LiteralPath $p.sciezka).Length -eq 0) {
        $szczegoly += New-Szczegol -Pozycja $p.rola -Wynik "pusty" -Komunikat ("Plik jest pusty: {0}" -f $p.sciezka)
        continue
    }
    $szczegoly += New-Szczegol -Pozycja $p.rola -Wynik "ok" -Komunikat $p.sciezka
}

# Log musi zawierać wpis dla tej iteracji — inaczej nie wiadomo, czy jest z tego przebiegu.
$logSciezka = ($oczekiwane | Where-Object { $_.rola -eq "log" }).sciezka
if (Test-Path -LiteralPath $logSciezka -PathType Leaf) {
    $wzorzecIteracji = "^###\s+Iteracja\s+$Iteracja\s*$"
    $maWpis = @(Get-Content -LiteralPath $logSciezka -Encoding UTF8 | Where-Object { $_ -match $wzorzecIteracji }).Count -gt 0
    if ($maWpis) {
        $szczegoly += New-Szczegol -Pozycja "log-iteracja" -Wynik "ok" -Komunikat ("### Iteracja {0}" -f $Iteracja)
    } else {
        $szczegoly += New-Szczegol -Pozycja "log-iteracja" -Wynik "brak" `
            -Komunikat ("Log nie ma nagłówka '### Iteracja {0}'" -f $Iteracja)
    }
}

exit (Save-WynikBramy -Skrypt "01-pliki" -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -Szczegoly $szczegoly)
