<#
  03-instaluj.ps1 — instalacja harnessu w katalogu `.claude` projektu.
  wersja-instalatora: 0.2.2

  Kopiuje wszystkie pliki z manifestu wybranej wersji (nadpisuje istniejące),
  tworzy brakujące katalogi (także sam `.claude`), rozszerza plik ustawień
  o wpisy hooków harnessu (nie nadpisuje go; kopia zapasowa
  `<plik>.przed-instalacja.bak` przed zapisem).
  Pliki spoza manifestu zostają nietknięte.

  Uruchamiać dopiero po 01-zrodlo.ps1 ze statusem "ok".
  Wynik: JSON na stdout. Z -Log: kroki dopisane do logu instalacji.
#>
param(
    [Parameter(Mandatory)][string] $KatalogZrodlowy,
    [Parameter(Mandatory)][string] $Wersja,
    [Parameter(Mandatory)][string] $KatalogClaude,
    [ValidateSet("settings.json", "settings.local.json")][string] $PlikSettings = "settings.json",
    [string] $Log
)
. (Join-Path $PSScriptRoot "_wspolne.ps1")

function Write-Krok([string] $Tresc) { if ($Log) { Add-KrokLogu -Log $Log -Tresc $Tresc } }

$wpis = Get-Manifesty $KatalogZrodlowy | Where-Object { $_.wersja -eq $Wersja } | Select-Object -First 1
if (-not $wpis) {
    Write-Krok "Instalacja: brak wersji $Wersja w źródle — przerwano."
    Write-Json ([pscustomobject]@{ status = "blad"; komunikat = "brak wersji $Wersja w źródle $KatalogZrodlowy" })
    exit 0
}

if (-not (Test-Path -LiteralPath $KatalogClaude)) {
    New-Item -ItemType Directory -Path $KatalogClaude -Force | Out-Null
    Write-Krok "Utworzono katalog $KatalogClaude."
}

$skopiowane = @()
$bledy = @()
foreach ($poz in (Get-MapaPlikow -Wpis $wpis -KatalogClaude $KatalogClaude)) {
    try {
        $katalog = Split-Path -Parent $poz.cel
        if (-not (Test-Path -LiteralPath $katalog)) { New-Item -ItemType Directory -Path $katalog -Force | Out-Null }
        $nadpisany = Test-Path -LiteralPath $poz.cel
        Copy-Item -LiteralPath $poz.zrodlo -Destination $poz.cel -Force
        $skopiowane += [pscustomobject]@{ plik = $poz.plik; cel = $poz.cel; nadpisano = $nadpisany }
        Write-Krok "Skopiowano $($poz.plik) → $($poz.cel)$(if ($nadpisany) { ' (nadpisano)' })."
    } catch {
        $bledy += [pscustomobject]@{ plik = $poz.plik; komunikat = $_.Exception.Message }
        Write-Krok "Błąd kopiowania $($poz.plik): $($_.Exception.Message)"
    }
}

$settings = $null
if ($wpis.manifest.settings) {
    try {
        $settings = Merge-Settings -SettingsHarnessu (Join-Path $wpis.katalog $wpis.manifest.settings) `
            -SettingsProjektu (Join-Path $KatalogClaude $PlikSettings)
        if (-not $settings.plik_istnial) { Write-Krok "Utworzono $($settings.plik)." }
        if ($settings.kopia) { Write-Krok "Kopia zapasowa ustawień: $($settings.kopia)." }
        foreach ($z in $settings.wpisy) { Write-Krok "Hook $($z.wpis): $($z.akcja)." }
    } catch {
        $bledy += [pscustomobject]@{ plik = $PlikSettings; komunikat = $_.Exception.Message }
        Write-Krok "Błąd rozszerzania $PlikSettings`: $($_.Exception.Message)"
    }
}

$status = if ($bledy.Count -eq 0) { "ok" } else { "blad" }
Write-Krok "Instalacja wersji $Wersja zakończona: $status (pliki: $($skopiowane.Count), błędy: $($bledy.Count))."
Write-Json ([pscustomobject]@{
    status           = $status
    wersja           = $Wersja
    katalog_claude   = $KatalogClaude
    katalog_harnessu = $(if ($wpis.manifest.katalog_harnessu) { Join-Path $KatalogClaude $wpis.manifest.katalog_harnessu } else { $KatalogClaude })
    plik_startowy    = $wpis.manifest.plik_startowy
    skopiowane       = $skopiowane
    settings         = $settings
    bledy            = $bledy
})
