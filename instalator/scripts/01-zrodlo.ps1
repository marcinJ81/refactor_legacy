<#
  01-zrodlo.ps1 — sprawdzenie katalogu źródłowego harnessu.
  wersja-instalatora: 0.2.2

  Bez -Wersja: lista wersji znalezionych w źródle (manifesty).
  Z -Wersja: czy źródło ma wszystkie pliki z manifestu tej wersji i czy każdy
  plik ma znacznik tej wersji. Braki → status "braki", instalacja niemożliwa.

  Wynik: JSON na stdout. Z -Log: kroki dopisane do logu instalacji.
#>
param(
    [Parameter(Mandatory)][string] $KatalogZrodlowy,
    [string] $Wersja,
    [string] $Log
)
. (Join-Path $PSScriptRoot "_wspolne.ps1")

function Write-Krok([string] $Tresc) { if ($Log) { Add-KrokLogu -Log $Log -Tresc $Tresc } }

if (-not (Test-Path -LiteralPath $KatalogZrodlowy -PathType Container)) {
    Write-Krok "Źródło: katalog $KatalogZrodlowy nie istnieje."
    Write-Json ([pscustomobject]@{ status = "brak_katalogu"; katalog = $KatalogZrodlowy })
    exit 0
}

$manifesty = Get-Manifesty $KatalogZrodlowy
$dostepne = @($manifesty | ForEach-Object { [pscustomobject]@{ wersja = $_.wersja; katalog = $_.katalog } })

if (-not $Wersja) {
    $status = if ($dostepne.Count -gt 0) { "ok" } else { "brak_manifestu" }
    Write-Krok "Źródło: $KatalogZrodlowy — wersje: $(if ($dostepne.Count) { ($dostepne.wersja -join ', ') } else { 'brak manifestu' })."
    Write-Json ([pscustomobject]@{ status = $status; katalog = $KatalogZrodlowy; wersje = $dostepne })
    exit 0
}

$wpis = $manifesty | Where-Object { $_.wersja -eq $Wersja } | Select-Object -First 1
if (-not $wpis) {
    Write-Krok "Źródło: brak wersji $Wersja w $KatalogZrodlowy."
    Write-Json ([pscustomobject]@{ status = "brak_wersji"; wersja = $Wersja; wersje = $dostepne })
    exit 0
}

$brakujace = @()
$zlaWersja = @()
foreach ($poz in (Get-MapaPlikow -Wpis $wpis -KatalogClaude "_")) {
    if (-not (Test-Path -LiteralPath $poz.zrodlo -PathType Leaf)) { $brakujace += $poz.plik; continue }
    $w = Get-WersjaPliku $poz.zrodlo
    if ($w -ne $Wersja) { $zlaWersja += [pscustomobject]@{ plik = $poz.plik; wersja = $w } }
}
if ($wpis.manifest.settings) {
    $s = Join-Path $wpis.katalog $wpis.manifest.settings
    if (-not (Test-Path -LiteralPath $s -PathType Leaf)) { $brakujace += $wpis.manifest.settings }
    else {
        try { $null = Read-JsonHashtable $s } catch { $zlaWersja += [pscustomobject]@{ plik = $wpis.manifest.settings; wersja = "niepoprawny JSON" } }
    }
}

$status = if ($brakujace.Count -eq 0 -and $zlaWersja.Count -eq 0) { "ok" } else { "braki" }
Write-Krok ("Źródło: wersja $Wersja ($($wpis.katalog)) — " + $(if ($status -eq "ok") { "komplet plików." } else { "braki: $($brakujace.Count) brakujących, $($zlaWersja.Count) z inną wersją." }))
Write-Json ([pscustomobject]@{
    status            = $status
    wersja            = $Wersja
    katalog           = $wpis.katalog
    plik_startowy     = $wpis.manifest.plik_startowy
    katalog_harnessu  = $wpis.manifest.katalog_harnessu
    ma_settings       = [bool]$wpis.manifest.settings
    brakujace         = $brakujace
    inna_wersja       = $zlaWersja
})
