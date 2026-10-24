<#
  wersja-harnessu: 0.3.0
  00-rozpoznanie.ps1 — Etap 0: rozpoznanie stanu (wznowienie sesji).
  Szuka najnowszego katalogu wynikowego projektu, zakłada katalog communication/
  i zapisuje w nim jedną ramkę Etap 0 → orkiestrator (model:
  references/frame-model.md, przykłady: etap0-examples/message-frame.md).
  Gdy jest poprzednia sesja (najnowszy refactor-resultN z refactor-config.json)
  — payload.files: pliki wygenerowane w poprzedniej sesji; zawsze —
  payload.directories. Niczego nie interpretuje — decyzję „nowa sesja czy
  wznowienie” podejmuje orkiestrator.
  Uruchamiany przez hooka startu agenta Etapu 0 (.claude/hooks/etap0-start.ps1,
  zadeklarowanego w .claude/settings.json jako SubagentStart z matcherem etap0).
  Kod wyjścia: 0 = ramka powstała (albo świadomie nie powstała przy
  -BezTworzenia), 2 = błąd wywołania.
#>
param(
    [Parameter(Mandatory = $true)][string]$KatalogProjektu,
    [switch]$BezTworzenia,
    [switch]$Cicho
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "_wspolne.ps1")

if (-not (Test-Path -LiteralPath $KatalogProjektu -PathType Container)) {
    Write-Host ("Katalog projektu nie istnieje: {0}" -f $KatalogProjektu)
    exit 2
}
$KatalogProjektu = (Resolve-Path -LiteralPath $KatalogProjektu).Path

function Get-PlikiSesji {
    # Ścieżki wszystkich plików w katalogu wynikowym, względne, z separatorem „/”.
    param([string]$KatalogWyniku)
    $prefiks = $KatalogWyniku.TrimEnd('\', '/').Length + 1
    return @(Get-ChildItem -LiteralPath $KatalogWyniku -File -Recurse -ErrorAction SilentlyContinue |
             ForEach-Object { $_.FullName.Substring($prefiks).Replace('\', '/') } |
             Sort-Object)
}

# --- przebieg ---------------------------------------------------------------

$katalogi = Get-KatalogiWynikowe -KatalogProjektu $KatalogProjektu

$aktywny = $null
$aktywnyPelny = $null
if ($katalogi.Count -gt 0) {
    $aktywny = $katalogi[-1].sciezka
    $aktywnyPelny = Join-Path $KatalogProjektu $aktywny
}

# Poprzednia sesja = najnowszy katalog wynikowy z refactor-config.json.
# Bez niej ramka nie ma payload.files — to nie jest błąd.
$sesjaZnaleziona = [bool]($aktywnyPelny -and (Test-Path -LiteralPath (Join-Path $aktywnyPelny "refactor-config.json")))

# Lista plików powstaje przed założeniem communication/ i zapisem ramki,
# więc obejmuje wyłącznie pliki poprzedniej sesji.
$plikiSesji = @()
if ($sesjaZnaleziona) { $plikiSesji = @(Get-PlikiSesji -KatalogWyniku $aktywnyPelny) }

# Ramka trafia do communication/ najnowszego katalogu wynikowego; gdy nie ma
# żadnego, powstaje refactor-result1 wyłącznie po to, żeby ramka miała gdzie
# leżeć. Przy -BezTworzenia w takim przypadku ramka nie powstaje.
if (-not $aktywnyPelny -and -not $BezTworzenia) {
    $aktywny = "refactor-result1"
    $aktywnyPelny = Join-Path $KatalogProjektu $aktywny
    New-Item -ItemType Directory -Path $aktywnyPelny -Force | Out-Null
}

# Katalog communication/ zakłada Etap 0 — przez niego idą wszystkie ramki
# wchodzące do orkiestratora i z niego wychodzące.
$plikRamki = $null
if ($aktywnyPelny) {
    $katalogKomunikacji = Join-Path $aktywnyPelny "communication"
    if (-not (Test-Path -LiteralPath $katalogKomunikacji)) {
        New-Item -ItemType Directory -Path $katalogKomunikacji -Force | Out-Null
    }
    $nr = (Get-NastepnyNumerRamki -KatalogKomunikacji $katalogKomunikacji).ToString("000")
    $payload = [ordered]@{}
    if ($sesjaZnaleziona) { $payload["files"] = $plikiSesji }
    # Lista katalogów w aktywnym katalogu wynikowym — zawsze, także bez poprzedniej sesji.
    $payload["directories"] = @(Get-ChildItem -LiteralPath $aktywnyPelny -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
    $ramka = [ordered]@{
        msg_id    = $nr
        corr_id   = "001"      # odpowiedź na ramkę startową orkiestratora (Orkiestrator.SendStartEtap0, isInitial)
        from      = "stage0"
        to        = "orchestrator"
        action    = "stageDone"
        status    = "done"
        payload   = $payload
        timestamp = (Get-Znacznik)
    }
    $plikRamki = Join-Path $katalogKomunikacji ("{0}-etap0-message-frame.json" -f $nr)
    Save-Json -Sciezka $plikRamki -Obiekt $ramka
}

if (-not $Cicho) {
    Write-Host ("[etap0] poprzednia sesja: {0}; katalogi wynikowe: {1}; aktywny: {2}" -f $(if ($sesjaZnaleziona) { "tak" } else { "nie" }), $katalogi.Count, $(if ($aktywny) { $aktywny } else { "brak" }))
    if ($sesjaZnaleziona) {
        Write-Host ("[etap0] pliki poprzedniej sesji: {0}" -f $plikiSesji.Count)
    }
    Write-Host ("[etap0] ramka: {0}" -f $(if ($plikRamki) { $plikRamki } else { "niezapisana (brak katalogu wynikowego, -BezTworzenia)" }))
}

exit 0
