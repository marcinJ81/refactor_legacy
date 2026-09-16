<#
  03-json.ps1 — brama Step 1, sprawdzenie 3 z 4.
  Czy step1-zmiany-N.json istnieje, parsuje się i ma strukturę opisaną
  w "Wyjście" (step1.md): nagłówek przebiegu + tablica zmian z kompletem pól.
  Licznik sprawdza 04-licznik.ps1 — tu tylko obecność pola.
  Wynik: quality-gate-step1-analize-result/iteracja-N/03-json.json
  Kod wyjścia: 0 = passed, 1 = failed, 2 = błąd wywołania.
#>
param(
    [Parameter(Mandatory = $true)][string]$KatalogWynikowy,
    [Parameter(Mandatory = $true)][int]$Iteracja
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_wspolne.ps1")

$plik = Join-Path $KatalogWynikowy ("step1-zmiany-{0}.json" -f $Iteracja)
$szczegoly = @()

if (-not (Test-Path -LiteralPath $plik -PathType Leaf)) {
    $szczegoly += New-Szczegol -Pozycja "plik" -Wynik "brak" -Komunikat ("Nie ma pliku: {0}" -f $plik)
    exit (Save-WynikBramy -Skrypt "03-json" -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -Szczegoly $szczegoly)
}

try {
    $json = (Get-Content -LiteralPath $plik -Raw -Encoding UTF8) | ConvertFrom-Json
    $szczegoly += New-Szczegol -Pozycja "parsowanie" -Wynik "ok" -Komunikat $plik
} catch {
    $szczegoly += New-Szczegol -Pozycja "parsowanie" -Wynik "niepoprawny-json" -Komunikat $_.Exception.Message
    exit (Save-WynikBramy -Skrypt "03-json" -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -Szczegoly $szczegoly)
}

function Test-Pole {
    param($Obiekt, [string]$Nazwa)
    if (-not ($Obiekt.PSObject.Properties.Name -contains $Nazwa)) { return $false }
    $w = $Obiekt.$Nazwa
    return -not ($null -eq $w -or ($w -is [string] -and $w.Trim() -eq ""))
}

foreach ($pole in @("etap", "krok", "iteracja", "zmiany", "liczba_zmian")) {
    if (Test-Pole -Obiekt $json -Nazwa $pole) {
        $szczegoly += New-Szczegol -Pozycja ("pole-{0}" -f $pole) -Wynik "ok"
    } else {
        $szczegoly += New-Szczegol -Pozycja ("pole-{0}" -f $pole) -Wynik "brak" `
            -Komunikat ("Brak albo puste pole '{0}' w nagłówku pliku" -f $pole)
    }
}

if ((Test-Pole -Obiekt $json -Nazwa "iteracja") -and ([int]$json.iteracja -ne $Iteracja)) {
    $szczegoly += New-Szczegol -Pozycja "iteracja" -Wynik "rozjazd" `
        -Komunikat ("Plik deklaruje iterację {0}, brama uruchomiona dla {1}" -f $json.iteracja, $Iteracja)
}

$zmiany = @()
if (Test-Pole -Obiekt $json -Nazwa "zmiany") { $zmiany = @($json.zmiany) }

if ($zmiany.Count -lt 1) {
    $szczegoly += New-Szczegol -Pozycja "zmiany" -Wynik "pusta-tablica" `
        -Komunikat "JSON musi zawierać co najmniej jedną strukturę zmiany"
} else {
    $szczegoly += New-Szczegol -Pozycja "zmiany" -Wynik "ok" -Komunikat ("{0} struktur" -f $zmiany.Count)
}

$wymagane = @("id", "kolejnosc", "plik", "zakres", "typ", "opis")
$idki = @()
$kolejnosci = @()

for ($i = 0; $i -lt $zmiany.Count; $i++) {
    $z = $zmiany[$i]
    $etykieta = "zmiana-{0}" -f ($i + 1)
    $braki = @()

    foreach ($pole in $wymagane) {
        if (-not (Test-Pole -Obiekt $z -Nazwa $pole)) { $braki += $pole }
    }

    $typ = if (Test-Pole -Obiekt $z -Nazwa "typ") { [string]$z.typ } else { "" }
    if ($typ -and @("seam", "test") -notcontains $typ) {
        $braki += ("typ='{0}' (dozwolone: seam, test)" -f $typ)
    }
    if ($typ -eq "seam" -and -not (Test-Pole -Obiekt $z -Nazwa "technika")) {
        $braki += "technika (obowiązkowa dla typ=seam)"
    }

    if (Test-Pole -Obiekt $z -Nazwa "id") { $idki += [string]$z.id }
    if (Test-Pole -Obiekt $z -Nazwa "kolejnosc") { $kolejnosci += [int]$z.kolejnosc }

    if ($braki.Count -eq 0) {
        $szczegoly += New-Szczegol -Pozycja $etykieta -Wynik "ok" -Komunikat $(if (Test-Pole -Obiekt $z -Nazwa "id") { [string]$z.id } else { "" })
    } else {
        $szczegoly += New-Szczegol -Pozycja $etykieta -Wynik "niekompletna" `
            -Komunikat ("Brakuje / niepoprawne: {0}" -f ($braki -join ", "))
    }
}

if ($idki.Count -gt 0) {
    $duble = @($idki | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name })
    if ($duble.Count -gt 0) {
        $szczegoly += New-Szczegol -Pozycja "id-unikalne" -Wynik "duplikat" -Komunikat ($duble -join ", ")
    } else {
        $szczegoly += New-Szczegol -Pozycja "id-unikalne" -Wynik "ok"
    }
}

if ($kolejnosci.Count -eq $zmiany.Count -and $zmiany.Count -gt 0) {
    $oczekiwana = 1..$zmiany.Count
    $posortowane = @($kolejnosci | Sort-Object)
    if (@(Compare-Object $oczekiwana $posortowane -SyncWindow 0).Count -eq 0) {
        $szczegoly += New-Szczegol -Pozycja "kolejnosc-ciagla" -Wynik "ok" -Komunikat ("1-{0}" -f $zmiany.Count)
    } else {
        $szczegoly += New-Szczegol -Pozycja "kolejnosc-ciagla" -Wynik "rozjazd" `
            -Komunikat ("Pola 'kolejnosc' mają być ciągiem 1-{0} bez powtórzeń; jest: {1}" -f $zmiany.Count, ($kolejnosci -join ", "))
    }
}

exit (Save-WynikBramy -Skrypt "03-json" -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja -Szczegoly $szczegoly)
