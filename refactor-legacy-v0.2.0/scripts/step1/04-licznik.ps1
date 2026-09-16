<#
  04-licznik.ps1 — brama Step 1, sprawdzenie 4 z 4.
  Czy liczba struktur w step1-zmiany-N.json zgadza się z licznikiem
  zadeklarowanym na końcu tego pliku (liczba_zmian) i z linią
  "Liczba zmian: K" w pliku analizy.
  Wynik: quality-gate-step1-analize-result/iteracja-N/04-licznik.json
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

$plikZmian = Join-Path $KatalogWynikowy ("step1-zmiany-{0}.json" -f $Iteracja)
$analiza = Get-PlikAnalizy -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -PlikAnalizy $PlikAnalizy
$szczegoly = @()

if (-not (Test-Path -LiteralPath $plikZmian -PathType Leaf)) {
    Write-Host ("Nie ma pliku ze zmianami: {0}" -f $plikZmian)
    exit 2
}

try {
    $json = (Get-Content -LiteralPath $plikZmian -Raw -Encoding UTF8) | ConvertFrom-Json
} catch {
    Write-Host ("Plik ze zmianami nie jest poprawnym JSON-em: {0}" -f $_.Exception.Message)
    exit 2
}

$faktyczna = @($json.zmiany).Count
$szczegoly += New-Szczegol -Pozycja "struktury-w-json" -Wynik "ok" -Komunikat ("{0}" -f $faktyczna)

# 1. Licznik zadeklarowany w JSON-ie.
if ($json.PSObject.Properties.Name -contains "liczba_zmian") {
    $zadeklarowana = [int]$json.liczba_zmian
    if ($zadeklarowana -eq $faktyczna) {
        $szczegoly += New-Szczegol -Pozycja "liczba_zmian-json" -Wynik "ok" -Komunikat ("{0}" -f $zadeklarowana)
    } else {
        $szczegoly += New-Szczegol -Pozycja "liczba_zmian-json" -Wynik "rozjazd" `
            -Komunikat ("Zadeklarowano {0}, struktur jest {1}" -f $zadeklarowana, $faktyczna)
    }
} else {
    $szczegoly += New-Szczegol -Pozycja "liczba_zmian-json" -Wynik "brak" `
        -Komunikat "Brak pola 'liczba_zmian' na końcu pliku ze zmianami"
}

# 2. Ta sama liczba w pliku opisowym.
if (-not (Test-Path -LiteralPath $analiza -PathType Leaf)) {
    $szczegoly += New-Szczegol -Pozycja "liczba-zmian-md" -Wynik "brak" `
        -Komunikat ("Nie ma pliku analizy: {0}" -f $analiza)
} else {
    $linie = @(Get-Content -LiteralPath $analiza -Encoding UTF8)
    $blok = @(Get-BlokIteracji -Linie $linie -Iteracja $Iteracja)
    $trafienia = @($blok | Where-Object { $_ -match "Liczba\s+zmian:\s*(\d+)" })

    if ($trafienia.Count -eq 0) {
        $szczegoly += New-Szczegol -Pozycja "liczba-zmian-md" -Wynik "brak" `
            -Komunikat "Plik analizy nie ma linii 'Liczba zmian: K'"
    } else {
        $null = $trafienia[-1] -match "Liczba\s+zmian:\s*(\d+)"
        $zMd = [int]$Matches[1]
        if ($zMd -eq $faktyczna) {
            $szczegoly += New-Szczegol -Pozycja "liczba-zmian-md" -Wynik "ok" -Komunikat ("{0}" -f $zMd)
        } else {
            $szczegoly += New-Szczegol -Pozycja "liczba-zmian-md" -Wynik "rozjazd" `
                -Komunikat ("Plik analizy podaje {0}, struktur w JSON-ie jest {1}" -f $zMd, $faktyczna)
        }
    }
}

exit (Save-WynikBramy -Skrypt "04-licznik" -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -Szczegoly $szczegoly)
