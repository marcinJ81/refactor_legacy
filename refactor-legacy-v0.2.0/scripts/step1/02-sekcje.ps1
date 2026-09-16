<#
  02-sekcje.ps1 — brama Step 1, sprawdzenie 2 z 4.
  Czy plik analizy ma komplet sekcji 1–6 wymaganych w "Wyjście" (step1.md)
  i czy stoją w wymaganej kolejności.
  Wynik: quality-gate-step1-analize-result/iteracja-N/02-sekcje.json
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

$analiza = Get-PlikAnalizy -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -PlikAnalizy $PlikAnalizy
if (-not (Test-Path -LiteralPath $analiza -PathType Leaf)) {
    Write-Host ("Nie ma pliku analizy: {0}" -f $analiza)
    exit 2
}

# Nagłówek sekcji: "## N. Nazwa" (Opcja A) albo "### N. Nazwa" (Opcja B, plik zbiorczy).
$sekcje = @(
    @{ nr = 1; nazwa = "Fragment" },
    @{ nr = 2; nazwa = "Zależności blokujące" },
    @{ nr = 3; nazwa = "Proponowany seam" },
    @{ nr = 4; nazwa = "Test charakteryzujący" },
    @{ nr = 5; nazwa = "Zmiany do zaimplementowania" },
    @{ nr = 6; nazwa = "Poza zakresem" }
)

$linie = @(Get-Content -LiteralPath $analiza -Encoding UTF8)
$blok = @(Get-BlokIteracji -Linie $linie -Iteracja $Iteracja)

$szczegoly = @()
$pozycje = @()
foreach ($s in $sekcje) {
    $wzorzec = "^#{2,3}\s+$($s.nr)\.\s+$([regex]::Escape($s.nazwa))\s*$"
    $idx = -1
    for ($i = 0; $i -lt $blok.Count; $i++) {
        if ($blok[$i] -match $wzorzec) { $idx = $i; break }
    }
    if ($idx -lt 0) {
        $szczegoly += New-Szczegol -Pozycja ("sekcja-{0}" -f $s.nr) -Wynik "brak" `
            -Komunikat ("Brak nagłówka '## {0}. {1}'" -f $s.nr, $s.nazwa)
    } else {
        $pozycje += [ordered]@{ nr = $s.nr; linia = $idx }
        $szczegoly += New-Szczegol -Pozycja ("sekcja-{0}" -f $s.nr) -Wynik "ok" -Komunikat $s.nazwa
    }
}

if ($pozycje.Count -eq $sekcje.Count) {
    $poKolei = $true
    for ($i = 1; $i -lt $pozycje.Count; $i++) {
        if ($pozycje[$i].linia -lt $pozycje[$i - 1].linia) { $poKolei = $false; break }
    }
    if ($poKolei) {
        $szczegoly += New-Szczegol -Pozycja "kolejnosc-sekcji" -Wynik "ok" -Komunikat "1-6 w kolejności"
    } else {
        $szczegoly += New-Szczegol -Pozycja "kolejnosc-sekcji" -Wynik "zla-kolejnosc" `
            -Komunikat "Sekcje 1-6 nie stoją w wymaganej kolejności"
    }
}

# Sekcja "Do akceptacji" została usunięta ze struktury — jej obecność to rozjazd z step1.md.
$maDoAkceptacji = @($blok | Where-Object { $_ -match "^#{2,3}\s+.*Do\s+akceptacji" }).Count -gt 0
if ($maDoAkceptacji) {
    $szczegoly += New-Szczegol -Pozycja "do-akceptacji" -Wynik "nadmiarowa" `
        -Komunikat "Plik ma sekcję 'Do akceptacji' — usunięta ze struktury, bramą jest quality gate"
} else {
    $szczegoly += New-Szczegol -Pozycja "do-akceptacji" -Wynik "ok" -Komunikat "brak, zgodnie ze strukturą"
}

exit (Save-WynikBramy -Skrypt "02-sekcje" -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -Szczegoly $szczegoly)
