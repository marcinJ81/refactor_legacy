<#
  02-cel.ps1 — sprawdzenie miejsca docelowego (katalog `.claude` projektu).
  wersja-instalatora: 0.2.2

  Porównuje to, co leży w miejscu docelowym, z wersją wybraną w źródle.
  Pliki rozpoznawane według manifestów wszystkich wersji ze źródła, wersja
  pliku — ze znacznika `wersja-harnessu`.

  Status:
    brak        — w miejscu docelowym nie ma harnessu → instalacja
    starsza     — wgrana wersja niższa (albo pliki bez znacznika) → instalacja
    taka_sama   — ta sama wersja, komplet plików i wpisów hooków → bez instalacji
    nowsza      — wgrana wersja wyższa niż źródło → bez instalacji
    niekompletna — ta sama wersja, ale brakuje plików lub wpisów hooków
                   → pytanie o wgranie wszystkiego

  Wynik: JSON na stdout. Z -Log: krok dopisany do logu instalacji.
#>
param(
    [Parameter(Mandatory)][string] $KatalogZrodlowy,
    [Parameter(Mandatory)][string] $Wersja,
    [Parameter(Mandatory)][string] $KatalogClaude,
    [ValidateSet("settings.json", "settings.local.json")][string] $PlikSettings = "settings.json",
    [string] $Log
)
. (Join-Path $PSScriptRoot "_wspolne.ps1")

$manifesty = Get-Manifesty $KatalogZrodlowy
$wybrany = $manifesty | Where-Object { $_.wersja -eq $Wersja } | Select-Object -First 1
if (-not $wybrany) {
    Write-Json ([pscustomobject]@{ status = "blad"; komunikat = "brak wersji $Wersja w źródle $KatalogZrodlowy" })
    exit 0
}

# Co leży w miejscu docelowym — według manifestów wszystkich wersji.
$znalezione = @{}
foreach ($m in $manifesty) {
    foreach ($poz in (Get-MapaPlikow -Wpis $m -KatalogClaude $KatalogClaude)) {
        if ($znalezione.ContainsKey($poz.cel)) { continue }
        if (Test-Path -LiteralPath $poz.cel -PathType Leaf) {
            $znalezione[$poz.cel] = [pscustomobject]@{ plik = $poz.cel; wersja = (Get-WersjaPliku $poz.cel) }
        }
    }
}
$wersjeWCelu = @($znalezione.Values | ForEach-Object { if ($_.wersja) { $_.wersja } else { "bez_wersji" } } | Sort-Object -Unique)
$wyzsze = @($znalezione.Values | Where-Object { $_.wersja -and (Compare-Wersja $_.wersja $Wersja) -gt 0 })

# Pliki wybranej wersji.
$brakujace = @()
$innaWersja = @()
foreach ($poz in (Get-MapaPlikow -Wpis $wybrany -KatalogClaude $KatalogClaude)) {
    if (-not (Test-Path -LiteralPath $poz.cel -PathType Leaf)) { $brakujace += $poz.plik; continue }
    $w = Get-WersjaPliku $poz.cel
    if ($w -ne $Wersja) { $innaWersja += [pscustomobject]@{ plik = $poz.plik; wersja = $w } }
}
$obecneWybranej = @(Get-MapaPlikow -Wpis $wybrany -KatalogClaude $KatalogClaude).Count - $brakujace.Count

$settings = $null
if ($wybrany.manifest.settings) {
    try {
        $settings = Merge-Settings -SettingsHarnessu (Join-Path $wybrany.katalog $wybrany.manifest.settings) `
            -SettingsProjektu (Join-Path $KatalogClaude $PlikSettings) -TylkoSprawdz
    } catch {
        if ($Log) { Add-KrokLogu -Log $Log -Tresc "Cel: nie da się odczytać $PlikSettings — $($_.Exception.Message)" }
        Write-Json ([pscustomobject]@{ status = "blad"; komunikat = "nie da się odczytać $(Join-Path $KatalogClaude $PlikSettings) (niepoprawny JSON?): $($_.Exception.Message)" })
        exit 0
    }
}
$settingsOk = (-not $settings) -or $settings.aktualny

if ($wyzsze.Count -gt 0) {
    $status = "nowsza"
} elseif ($brakujace.Count -eq 0 -and $innaWersja.Count -eq 0 -and $settingsOk) {
    $status = "taka_sama"
} elseif ($innaWersja.Count -gt 0 -or ($obecneWybranej -eq 0 -and $znalezione.Count -gt 0)) {
    $status = "starsza"
} elseif ($znalezione.Count -eq 0) {
    $status = "brak"
} else {
    $status = "niekompletna"
}

if ($Log) {
    $opis = switch ($status) {
        "brak"         { "brak harnessu" }
        "starsza"      { "wgrana starsza wersja ($($wersjeWCelu -join ', '))" }
        "taka_sama"    { "wgrana ta sama wersja $Wersja, komplet" }
        "nowsza"       { "wgrana nowsza wersja ($($wersjeWCelu -join ', '))" }
        "niekompletna" { "wersja $Wersja niekompletna: brak $($brakujace.Count) plików" + $(if (-not $settingsOk) { ", brak wpisów hooków w $PlikSettings" } else { "" }) }
    }
    Add-KrokLogu -Log $Log -Tresc "Cel: $KatalogClaude — $opis."
}

Write-Json ([pscustomobject]@{
    status          = $status
    wersja_zrodla   = $Wersja
    wersje_w_celu   = $wersjeWCelu
    katalog_claude  = $KatalogClaude
    brakujace       = $brakujace
    inna_wersja     = $innaWersja
    settings        = $settings
})
