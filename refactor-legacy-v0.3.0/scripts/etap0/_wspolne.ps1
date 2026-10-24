# _wspolne.ps1 — funkcje wspólne skryptu Etapu 0.
# wersja-harnessu: 0.3.0
# Dot-source'owany przez 00-rozpoznanie.ps1. Sam niczego nie sprawdza i nie zapisuje.

Set-StrictMode -Version 1.0

function Get-Znacznik {
    # Format obowiązujący w całym harnessie (ramki i logi): ISO 8601 z offsetem
    # — references/frame-model.md, I8.
    param([datetime]$Data = (Get-Date))
    $Data.ToString("yyyy-MM-ddTHH:mm:sszzz")
}

function Save-Json {
    # Zapis bez BOM-u — PS 5.1 przez Set-Content -Encoding UTF8 dokłada BOM,
    # na którym potykają się inne parsery JSON.
    param([string]$Sciezka, $Obiekt)
    $tresc = $Obiekt | ConvertTo-Json -Depth 12
    [System.IO.File]::WriteAllText($Sciezka, $tresc, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-WzorzecKatalogow {
    # Liczy się wyłącznie wzorzec refactor-resultN; katalog o innej nazwie
    # (np. pozostały po wcześniejszej wersji harnessu) jest pomijany.
    return '^refactor-result(\d+)$'
}

function Get-KatalogiWynikowe {
    <#
      Zwraca listę katalogów wynikowych projektu, posortowaną po numerze.
      Każda pozycja: sciezka (nazwa katalogu), numer.
    #>
    param([string]$KatalogProjektu)

    $wzorzec = Get-WzorzecKatalogow
    $znalezione = @()

    foreach ($katalog in @(Get-ChildItem -LiteralPath $KatalogProjektu -Directory -ErrorAction SilentlyContinue)) {
        $m = [regex]::Match($katalog.Name, $wzorzec)
        if (-not $m.Success) { continue }
        $znalezione += [ordered]@{
            sciezka = $katalog.Name
            numer   = [int]$m.Groups[1].Value
        }
    }

    return @($znalezione | Sort-Object { $_.numer })
}

function Get-NastepnyNumerRamki {
    # Numer kolejnej ramki w communication/: największy prefiks NNN + 1,
    # najmniej 2 — numer 001 ma ramka startowa orkiestratora (references/frame-model.md, isInitial).
    param([string]$KatalogKomunikacji)
    $max = 0
    foreach ($plik in @(Get-ChildItem -LiteralPath $KatalogKomunikacji -Filter "*.json" -File -ErrorAction SilentlyContinue)) {
        $m = [regex]::Match($plik.Name, '^(\d+)-')
        if ($m.Success -and [int]$m.Groups[1].Value -gt $max) { $max = [int]$m.Groups[1].Value }
    }
    $nastepny = [Math]::Max($max + 1, 2)
    if ($nastepny -gt 999) { throw "communication/: przekroczony limit numerów ramek (999)" }
    return $nastepny
}
