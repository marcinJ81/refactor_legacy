<#
  step2-stop.ps1 — hook zakończenia agenta Step 2 (quality gate Step 2, Opcja A).
  Zarejestrowany w `.claude/settings.json` (zdarzenie SubagentStop, matcher
  `step2`), więc uruchamia się **wyłącznie przy zakończeniu agenta Step 2**.

  Przebieg:
  1. Pierwsze zakończenie agenta (`stop_hook_active: false`), ostatnia
     odpowiedź agenta zawiera znacznik
       QUALITY_GATE_STEP2: katalog_wynikowy=<ścieżka>; iteracja=<N>
     → hook woła scripts/step2/00-brama.ps1 (build + unit testy) i zwraca
     wynik agentowi przez hookSpecificOutput.additionalContext. Agent nie
     kończy pracy — dostaje wynik jako kolejną instrukcję i zapisuje step.done.
  2. Drugie zakończenie (`stop_hook_active: true`) albo odpowiedź bez
     znacznika → hook nic nie robi, agent się zamyka.

  Hook **nigdy nie kończy się kodem innym niż 0** — błąd bramy trafia do
  agenta jako treść wyniku, nie jako błąd hooka.
#>

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Continue"

function Write-WynikHooka {
    param([string]$Tresc)
    $wyjscie = [ordered]@{
        hookSpecificOutput = [ordered]@{
            hookEventName     = "SubagentStop"
            additionalContext = $Tresc
        }
    }
    Write-Output ($wyjscie | ConvertTo-Json -Depth 4 -Compress)
}

try {
    $wejscie = [Console]::In.ReadToEnd()
    if (-not $wejscie) { exit 0 }
    $dane = $wejscie | ConvertFrom-Json

    # Drugie zakończenie — agent już zapisał step.done po wyniku bramy.
    $pole = $dane.PSObject.Properties["stop_hook_active"]
    if ($pole -and $pole.Value -eq $true) { exit 0 }

    $pole = $dane.PSObject.Properties["last_assistant_message"]
    $odpowiedz = if ($pole) { [string]$pole.Value } else { "" }

    $wzorzec = 'QUALITY_GATE_STEP2:\s*katalog_wynikowy=(?<katalog>[^;\r\n]+);\s*iteracja=(?<iteracja>\d+)'
    $dopasowanie = [regex]::Match($odpowiedz, $wzorzec)
    if (-not $dopasowanie.Success) { exit 0 }

    $katalogWynikowy = $dopasowanie.Groups["katalog"].Value.Trim()
    $iteracja = [int]$dopasowanie.Groups["iteracja"].Value

    # Ścieżka względna liczona od katalogu projektu (CLAUDE_PROJECT_DIR,
    # pole cwd z wejścia hooka, w ostateczności bieżący katalog).
    if (-not [System.IO.Path]::IsPathRooted($katalogWynikowy)) {
        $katalogProjektu = $env:CLAUDE_PROJECT_DIR
        if (-not $katalogProjektu) {
            $pole = $dane.PSObject.Properties["cwd"]
            $katalogProjektu = if ($pole) { $pole.Value } else { (Get-Location).Path }
        }
        $katalogWynikowy = Join-Path $katalogProjektu $katalogWynikowy
    }

    # Katalog harnessu: ten plik leży w <projekt>/.claude/hooks/, harness
    # w <projekt>/.claude/refactor-legacy/ (patrz INSTALACJA.md).
    $korzenHarnessu = Join-Path (Split-Path -Parent $PSScriptRoot) "refactor-legacy"
    $skrypt = Join-Path $korzenHarnessu "scripts/step2/00-brama.ps1"
    if (-not (Test-Path -LiteralPath $skrypt)) {
        Write-WynikHooka ("Quality gate Step 2 nie wykonany: brak skryptu bramy {0}." -f $skrypt)
        exit 0
    }

    & $skrypt -KatalogWynikowy $katalogWynikowy -Iteracja $iteracja | Out-Null
    $plikWyniku = Join-Path $katalogWynikowy ("quality-gate-step2-result/iteracja-{0}/podsumowanie.json" -f $iteracja)
    if (-not (Test-Path -LiteralPath $plikWyniku)) {
        Write-WynikHooka ("Quality gate Step 2 nie zapisał wyniku: {0}." -f $plikWyniku)
        exit 0
    }

    $wynik = Get-Content -LiteralPath $plikWyniku -Raw -Encoding UTF8
    $tresc = @(
        "## Quality gate Step 2 — wynik (hook SubagentStop)"
        ""
        ("Plik wyniku: {0}" -f $plikWyniku)
        ""
        '```json'
        $wynik.Trim()
        '```'
        ""
        "Przepisz wynik bez własnej oceny do payload.quality_gate wiadomości step.done (wykonal: hook),"
        "zapisz step.done w komunikacja/, dopisz wpisy do step2-log.md i zakończ pracę."
    ) -join "`n"
    Write-WynikHooka $tresc
} catch {
    Write-WynikHooka ("Quality gate Step 2 nie wykonał się: {0}" -f $_.Exception.Message)
}

exit 0
