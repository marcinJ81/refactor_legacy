<#
  wersja-harnessu: 0.3.0
  etap0-start.ps1 — hook startu agenta Etapu 0.
  Zarejestrowany w `.claude/settings.json` (zdarzenie SubagentStart, matcher
  `etap0`), więc uruchamia się **wyłącznie przy starcie agenta Etapu 0**,
  nie przy każdym agencie harnessu.

  Woła scripts/etap0/00-rozpoznanie.ps1 i przekazuje jego podsumowanie do
  kontekstu startowego agenta jako JSON `hookSpecificOutput.additionalContext`
  (zwykły stdout SubagentStart nie trafia do kontekstu agenta). Wynik
  rozpoznania jest w ramce communication/<NNN>-etap0-message-frame.json.

  Gdy rozpoznanie się nie wykona, hook sam zapisuje ramkę ze `status: failed`
  i `payload.error`, żeby agent miał co zwrócić orkiestratorowi.

  Hook **nigdy nie kończy się kodem innym niż 0** — błąd rozpoznania nie może
  przerwać startu agenta.
#>

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Continue"

function Save-RamkaFailed {
    <#
      Ramka Etap 0 → orkiestrator ze `status: failed`. Trafia do najnowszego
      katalogu wynikowego; gdy nie ma żadnego — do refactor-result1.
      Zwraca ścieżkę zapisanej ramki. Celowo bez _wspolne.ps1 — ramka ma
      powstać także wtedy, gdy brakuje skryptów Etapu 0.
    #>
    param([string]$KatalogProjektu, [string]$Blad)

    if (-not (Test-Path -LiteralPath $KatalogProjektu -PathType Container)) {
        throw "katalog projektu nie istnieje: $KatalogProjektu"
    }
    $katalogWyniku = $null
    $maxNumer = 0
    foreach ($k in @(Get-ChildItem -LiteralPath $KatalogProjektu -Directory -ErrorAction SilentlyContinue)) {
        $m = [regex]::Match($k.Name, '^refactor-result(\d+)$')
        if ($m.Success -and [int]$m.Groups[1].Value -gt $maxNumer) {
            $maxNumer = [int]$m.Groups[1].Value
            $katalogWyniku = $k.FullName
        }
    }
    if (-not $katalogWyniku) { $katalogWyniku = Join-Path $KatalogProjektu "refactor-result1" }

    $katalogKomunikacji = Join-Path $katalogWyniku "communication"
    if (-not (Test-Path -LiteralPath $katalogKomunikacji)) {
        New-Item -ItemType Directory -Path $katalogKomunikacji -Force | Out-Null
    }

    $maxRamki = 0
    foreach ($plik in @(Get-ChildItem -LiteralPath $katalogKomunikacji -Filter "*.json" -File -ErrorAction SilentlyContinue)) {
        $m = [regex]::Match($plik.Name, '^(\d+)-')
        if ($m.Success -and [int]$m.Groups[1].Value -gt $maxRamki) { $maxRamki = [int]$m.Groups[1].Value }
    }
    $nr = ($maxRamki + 1).ToString("000")

    $ramka = [ordered]@{
        msg_id    = "e0-$nr"
        corr_id   = $null
        from      = "etap0"
        to        = "orkiestrator"
        action    = "stage.done"
        status    = "failed"
        payload   = [ordered]@{ error = $Blad }
        timestamp = (Get-Date).ToString("yyyy-MM-dd; HH-mm-ss")
    }
    $plikRamki = Join-Path $katalogKomunikacji ("{0}-etap0-message-frame.json" -f $nr)
    $tresc = $ramka | ConvertTo-Json -Depth 4
    [System.IO.File]::WriteAllText($plikRamki, $tresc, (New-Object System.Text.UTF8Encoding($false)))
    return $plikRamki
}

$kontekst = New-Object System.Collections.ArrayList
[void]$kontekst.Add("## Etap 0 — rozpoznanie stanu (hook startu agenta)")
$blad = $null
$katalogProjektu = $null

try {
    # Katalog projektu: zmienna środowiskowa, CLAUDE_PROJECT_DIR, pole cwd
    # z wejścia hooka, w ostateczności bieżący katalog.
    $katalogProjektu = $env:REFACTOR_KATALOG_PROJEKTU
    if (-not $katalogProjektu) { $katalogProjektu = $env:CLAUDE_PROJECT_DIR }
    if (-not $katalogProjektu) {
        try {
            $wejscie = [Console]::In.ReadToEnd()
            if ($wejscie) {
                $dane = $wejscie | ConvertFrom-Json
                $pole = $dane.PSObject.Properties["cwd"]
                if ($pole) { $katalogProjektu = $pole.Value }
            }
        } catch { }
    }
    if (-not $katalogProjektu) { $katalogProjektu = (Get-Location).Path }

    # Katalog harnessu: ten plik leży w <projekt>/.claude/hooks/, harness
    # w <projekt>/.claude/refactor-legacy/ (instalacja: agent instalationHarnessRefactor).
    $korzenHarnessu = Join-Path (Split-Path -Parent $PSScriptRoot) "refactor-legacy"
    $skrypt = Join-Path $korzenHarnessu "scripts/etap0/00-rozpoznanie.ps1"

    if (-not (Test-Path -LiteralPath $skrypt)) {
        $blad = "Nie znaleziono skryptu rozpoznania: $skrypt"
    } else {
        # Write-Host skryptu idzie strumieniem 6 — przechwycony razem z resztą.
        $global:LASTEXITCODE = 0
        $wyjscie = @(& $skrypt -KatalogProjektu $katalogProjektu *>&1 | ForEach-Object { "$_" })
        foreach ($linia in $wyjscie) { [void]$kontekst.Add($linia) }
        if ($LASTEXITCODE -ne 0) {
            $blad = "Skrypt rozpoznania zakończył się kodem $LASTEXITCODE"
        } elseif (-not ($wyjscie | Where-Object { $_ -match '^\[etap0\] ramka: (?!niezapisana)' })) {
            $blad = "Skrypt rozpoznania nie zapisał ramki"
        }
    }
} catch {
    $blad = "Rozpoznanie nie wykonało się: {0}" -f $_.Exception.Message
}

if ($blad) {
    [void]$kontekst.Add("[etap0][hook] $blad")
    try {
        if (-not $katalogProjektu) { $katalogProjektu = (Get-Location).Path }
        $plikRamki = Save-RamkaFailed -KatalogProjektu $katalogProjektu -Blad $blad
        [void]$kontekst.Add("[etap0] ramka: $plikRamki")
    } catch {
        [void]$kontekst.Add(("[etap0][hook] Ramka failed nie została zapisana: {0}" -f $_.Exception.Message))
    }
}

[void]$kontekst.Add("Ramka jest danymi dla orkiestratora. Decyzję „nowa sesja czy wznowienie” podejmuje orkiestrator.")

$odpowiedz = [ordered]@{
    hookSpecificOutput = [ordered]@{
        hookEventName     = "SubagentStart"
        additionalContext = ($kontekst -join "`n")
    }
}
Write-Output ($odpowiedz | ConvertTo-Json -Depth 4 -Compress)

exit 0
