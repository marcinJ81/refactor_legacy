# _wspolne.ps1 — funkcje wspólne skryptów instalatora harnessu.
# wersja-instalatora: 0.2.2
# Dot-source'owany przez 01-zrodlo.ps1, 02-cel.ps1, 03-instaluj.ps1,
# log-instalacji.ps1. Sam nic nie robi.

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"

$script:WzorzecWersji = 'wersja[-_]harnessu"?\s*:\s*"?(\d+\.\d+\.\d+)'
$script:WzorzecSkryptuHooka = '[\\/]\.claude[\\/]hooks[\\/]([^"''\\/\s]+\.ps1)'

function Write-Json {
    param([Parameter(Mandatory)] $Obiekt)
    $Obiekt | ConvertTo-Json -Depth 32
}

function Write-PlikUtf8 {
    param([Parameter(Mandatory)][string] $Sciezka, [Parameter(Mandatory)][AllowEmptyString()][string] $Tresc)
    $katalog = Split-Path -Parent $Sciezka
    if ($katalog -and -not (Test-Path -LiteralPath $katalog)) {
        New-Item -ItemType Directory -Path $katalog -Force | Out-Null
    }
    [System.IO.File]::WriteAllText($Sciezka, $Tresc, [System.Text.UTF8Encoding]::new($false))
}

# Numer wersji z pliku harnessu (znacznik `wersja-harnessu: X.Y.Z`
# w komentarzu albo `"wersja_harnessu": "X.Y.Z"` w JSON). Brak → $null.
function Get-WersjaPliku {
    param([Parameter(Mandatory)][string] $Sciezka)
    if (-not (Test-Path -LiteralPath $Sciezka -PathType Leaf)) { return $null }
    $linie = Get-Content -LiteralPath $Sciezka -TotalCount 30 -Encoding UTF8
    foreach ($linia in $linie) {
        if ($linia -match $script:WzorzecWersji) { return $Matches[1] }
    }
    return $null
}

# -1 gdy A < B, 0 gdy równe, 1 gdy A > B.
function Compare-Wersja {
    param([Parameter(Mandatory)][string] $A, [Parameter(Mandatory)][string] $B)
    return ([version]$A).CompareTo([version]$B)
}

# Wszystkie manifesty w katalogu źródłowym. Katalog źródłowy to katalog
# wersji (leży w nim manifest.json) albo katalog nadrzędny z katalogami
# refactor-legacy-v*/.
function Get-Manifesty {
    param([Parameter(Mandatory)][string] $KatalogZrodlowy)
    $pliki = @()
    $wprost = Join-Path $KatalogZrodlowy "manifest.json"
    if (Test-Path -LiteralPath $wprost) {
        $pliki += Get-Item -LiteralPath $wprost
    } else {
        $pliki += Get-ChildItem -LiteralPath $KatalogZrodlowy -Directory |
            ForEach-Object { Join-Path $_.FullName "manifest.json" } |
            Where-Object { Test-Path -LiteralPath $_ } |
            ForEach-Object { Get-Item -LiteralPath $_ }
    }
    $wynik = @()
    foreach ($plik in $pliki) {
        try {
            $m = Get-Content -LiteralPath $plik.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch { continue }
        if (-not $m.PSObject.Properties["wersja_harnessu"]) { continue }
        $wynik += [pscustomobject]@{
            wersja   = [string]$m.wersja_harnessu
            katalog  = $plik.Directory.FullName
            manifest = $m
        }
    }
    return @($wynik | Sort-Object { [version]$_.wersja } -Descending)
}

# Pary źródło → cel dla wszystkich plików manifestu (bez settings).
function Get-MapaPlikow {
    param([Parameter(Mandatory)] $Wpis, [Parameter(Mandatory)][string] $KatalogClaude)
    $m = $Wpis.manifest
    $celHarnessu = if ($m.katalog_harnessu) { Join-Path $KatalogClaude $m.katalog_harnessu } else { $KatalogClaude }
    $mapa = @()
    foreach ($p in @($m.pliki_harnessu)) {
        $mapa += [pscustomobject]@{
            plik   = $p
            zrodlo = Join-Path $Wpis.katalog $p
            cel    = Join-Path $celHarnessu $p
        }
    }
    foreach ($p in @($m.pliki_claude)) {
        $wzgledna = $p -replace '^\.claude[\\/]', ''
        $mapa += [pscustomobject]@{
            plik   = $p
            zrodlo = Join-Path $Wpis.katalog $p
            cel    = Join-Path $KatalogClaude $wzgledna
        }
    }
    return $mapa
}

function Read-JsonHashtable {
    param([Parameter(Mandatory)][string] $Sciezka)
    $tresc = Get-Content -LiteralPath $Sciezka -Raw -Encoding UTF8
    if (-not $tresc -or -not $tresc.Trim()) { return [ordered]@{} }
    return ($tresc | ConvertFrom-Json -AsHashtable)
}

function Get-SkryptyHookow {
    param($Grupa)
    $nazwy = @()
    foreach ($h in @($Grupa["hooks"])) {
        if ($h -and $h["command"] -and ([string]$h["command"] -match $script:WzorzecSkryptuHooka)) {
            $nazwy += $Matches[1]
        }
    }
    return $nazwy
}

# Rozszerza sekcję `hooks` pliku ustawień projektu o wpisy z settings.json
# harnessu. Inne klucze i inne hooki zostają nietknięte. Wpis harnessu
# rozpoznawany po nazwie skryptu w `.claude/hooks/` w komendzie.
# -TylkoSprawdz: nic nie zapisuje, zwraca, co by się zmieniło.
function Merge-Settings {
    param(
        [Parameter(Mandatory)][string] $SettingsHarnessu,
        [Parameter(Mandatory)][string] $SettingsProjektu,
        [switch] $TylkoSprawdz
    )
    $zrodlo = Read-JsonHashtable $SettingsHarnessu
    $istnial = Test-Path -LiteralPath $SettingsProjektu
    $cel = if ($istnial) { Read-JsonHashtable $SettingsProjektu } else { [ordered]@{} }
    if (-not $cel.Contains("hooks") -or -not $cel["hooks"]) { $cel["hooks"] = [ordered]@{} }

    $zmiany = @()
    foreach ($zdarzenie in @($zrodlo["hooks"].Keys)) {
        $grupyCel = [System.Collections.ArrayList]@()
        if ($cel["hooks"].Contains($zdarzenie) -and $cel["hooks"][$zdarzenie]) {
            foreach ($g in @($cel["hooks"][$zdarzenie])) { [void]$grupyCel.Add($g) }
        }
        foreach ($grupa in @($zrodlo["hooks"][$zdarzenie])) {
            $skrypty = Get-SkryptyHookow $grupa
            $jsonGrupy = $grupa | ConvertTo-Json -Depth 32 -Compress
            $indeks = -1
            for ($i = 0; $i -lt $grupyCel.Count; $i++) {
                $wspolne = @(Get-SkryptyHookow $grupyCel[$i] | Where-Object { $skrypty -contains $_ })
                if ($wspolne.Count -gt 0) { $indeks = $i; break }
            }
            $opis = "$zdarzenie / matcher '$($grupa["matcher"])' / $($skrypty -join ', ')"
            if ($indeks -lt 0) {
                [void]$grupyCel.Add($grupa)
                $zmiany += [pscustomobject]@{ wpis = $opis; akcja = "dodano" }
            } elseif (($grupyCel[$indeks] | ConvertTo-Json -Depth 32 -Compress) -eq $jsonGrupy) {
                $zmiany += [pscustomobject]@{ wpis = $opis; akcja = "bez_zmian" }
            } else {
                $grupyCel[$indeks] = $grupa
                $zmiany += [pscustomobject]@{ wpis = $opis; akcja = "zaktualizowano" }
            }
        }
        $cel["hooks"][$zdarzenie] = @($grupyCel)
    }

    $doZapisu = @($zmiany | Where-Object { $_.akcja -ne "bez_zmian" }).Count -gt 0
    $kopia = $null
    if (-not $TylkoSprawdz -and $doZapisu) {
        if ($istnial) {
            $kopia = "$SettingsProjektu.przed-instalacja.bak"
            Copy-Item -LiteralPath $SettingsProjektu -Destination $kopia -Force
        }
        Write-PlikUtf8 -Sciezka $SettingsProjektu -Tresc (($cel | ConvertTo-Json -Depth 32) + "`n")
    }
    return [pscustomobject]@{
        plik         = $SettingsProjektu
        plik_istnial = $istnial
        aktualny     = -not $doZapisu
        zapisano     = (-not $TylkoSprawdz -and $doZapisu)
        kopia        = $kopia
        wpisy        = $zmiany
    }
}

# Dopisuje krok do logu instalacji. Numer kroku = liczba dotychczasowych
# kroków w bieżącym uruchomieniu + 1. Bez znaczników czasu.
function Add-KrokLogu {
    param([Parameter(Mandatory)][string] $Log, [Parameter(Mandatory)][string] $Tresc)
    $linie = @()
    if (Test-Path -LiteralPath $Log) { $linie = @(Get-Content -LiteralPath $Log -Encoding UTF8) }
    $ostatniNaglowek = -1
    for ($i = 0; $i -lt $linie.Count; $i++) { if ($linie[$i] -match '^## ') { $ostatniNaglowek = $i } }
    $nr = 1
    if ($ostatniNaglowek -ge 0 -and $ostatniNaglowek -lt ($linie.Count - 1)) {
        $nr = @($linie[($ostatniNaglowek + 1)..($linie.Count - 1)] | Where-Object { $_ -match '^\d+\. ' }).Count + 1
    }
    $katalog = Split-Path -Parent $Log
    if ($katalog -and -not (Test-Path -LiteralPath $katalog)) { New-Item -ItemType Directory -Path $katalog -Force | Out-Null }
    [System.IO.File]::AppendAllText($Log, "$nr. $Tresc`n", [System.Text.UTF8Encoding]::new($false))
}
