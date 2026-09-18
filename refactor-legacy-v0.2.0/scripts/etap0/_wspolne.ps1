# _wspolne.ps1 — funkcje wspólne skryptu Etapu 0.
# Dot-source'owany przez 00-rozpoznanie.ps1. Sam niczego nie sprawdza i nie zapisuje.

Set-StrictMode -Version 1.0

$script:WzorzecZnacznika = '\d{4}-\d{2}-\d{2}; \d{2}-\d{2}-\d{2}'

function Get-Znacznik {
    # Format obowiązujący w całym harnessie: yyyy-MM-dd; HH-mm-ss
    param([datetime]$Data = (Get-Date))
    $Data.ToString("yyyy-MM-dd; HH-mm-ss")
}

function ConvertFrom-Znacznik {
    # Zwraca [datetime] albo $null, gdy tekst nie jest znacznikiem harnessu.
    param([string]$Tekst)
    if (-not $Tekst) { return $null }
    $kultura = [Globalization.CultureInfo]::InvariantCulture
    $wynik = [datetime]::MinValue
    if ([datetime]::TryParseExact($Tekst.Trim(), "yyyy-MM-dd; HH-mm-ss", $kultura, [Globalization.DateTimeStyles]::None, [ref]$wynik)) {
        return $wynik
    }
    return $null
}

function Get-ZnacznikZLinii {
    # Pierwszy znacznik czasu występujący w linii; $null gdy linia go nie ma.
    param([string]$Linia)
    if (-not $Linia) { return $null }
    $m = [regex]::Match($Linia, $script:WzorzecZnacznika)
    if (-not $m.Success) { return $null }
    return $m.Value
}

function Save-Json {
    # Zapis bez BOM-u — PS 5.1 przez Set-Content -Encoding UTF8 dokłada BOM,
    # na którym potykają się inne parsery JSON.
    param([string]$Sciezka, $Obiekt)
    $tresc = $Obiekt | ConvertTo-Json -Depth 12
    [System.IO.File]::WriteAllText($Sciezka, $tresc, (New-Object System.Text.UTF8Encoding($false)))
}

function Read-JsonPliku {
    # Wczytuje JSON; przy błędzie parsowania zwraca $null (wywołujący dopisuje anomalię).
    param([string]$Sciezka)
    if (-not (Test-Path -LiteralPath $Sciezka)) { return $null }
    try {
        return (Get-Content -LiteralPath $Sciezka -Raw -Encoding UTF8 | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Get-PoleObiektu {
    # Bezpieczny odczyt pola z obiektu z ConvertFrom-Json (StrictMode nie pozwala na wprost).
    param($Obiekt, [string]$Nazwa)
    if ($null -eq $Obiekt) { return $null }
    $wlasciwosc = $Obiekt.PSObject.Properties[$Nazwa]
    if ($null -eq $wlasciwosc) { return $null }
    return $wlasciwosc.Value
}

function Get-WzorzecKatalogow {
    # Liczy się wyłącznie wzorzec refactor-resultN; katalog o innej nazwie
    # (np. pozostały po wcześniejszej wersji harnessu) jest pomijany — patrz
    # „Katalog wynikowy” w orkiestrator.md.
    return '^refactor-result(\d+)$'
}

function Get-OstatniaAktywnosc {
    # Najpóźniejszy czas modyfikacji pliku w katalogu; $null dla katalogu pustego.
    param([string]$Katalog)
    $pliki = @(Get-ChildItem -LiteralPath $Katalog -File -Recurse -ErrorAction SilentlyContinue)
    if ($pliki.Count -eq 0) { return $null }
    $najpozniej = ($pliki | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
    return (Get-Znacznik -Data $najpozniej)
}

function Get-KatalogiWynikowe {
    <#
      Zwraca listę katalogów wynikowych projektu, posortowaną po numerze.
      Każda pozycja: sciezka (nazwa katalogu), numer, ostatnia_aktywnosc.
    #>
    param([string]$KatalogProjektu)

    $wzorzec = Get-WzorzecKatalogow
    $znalezione = @()

    foreach ($katalog in @(Get-ChildItem -LiteralPath $KatalogProjektu -Directory -ErrorAction SilentlyContinue)) {
        $m = [regex]::Match($katalog.Name, $wzorzec)
        if (-not $m.Success) { continue }
        $znalezione += [ordered]@{
            sciezka            = $katalog.Name
            numer              = [int]$m.Groups[1].Value
            ostatnia_aktywnosc = (Get-OstatniaAktywnosc -Katalog $katalog.FullName)
        }
    }

    return @($znalezione | Sort-Object { $_.numer })
}
