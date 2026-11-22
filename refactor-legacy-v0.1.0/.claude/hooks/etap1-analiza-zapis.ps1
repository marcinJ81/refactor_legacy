<#
  wersja-harnessu: 0.1.2
  etap1-analiza-zapis.ps1 — hook PreToolUse agenta etap1-analiza.
  Zarejestrowany we frontmatterze `.claude/agents/etap1-analiza.md` (matcher
  `Write|Edit`), więc działa wyłącznie, gdy aktywny jest agent analizy.

  Przepuszcza zapis tylko do:
    refactor-resultN/etap1-plan.md
    refactor-resultN/komunikacja/<plik>.json
  Każdą inną ścieżkę odrzuca (permissionDecision = deny) z powodem, który
  trafia do agenta. Błąd odczytu wejścia też kończy się odrzuceniem.

  Log Etapu 1 dopisuje skrypt wpis-logu.ps1 przez Bash, więc ten hook go nie
  dotyczy.
#>

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"

function Write-Odmowa {
    param([string]$Powod)
    $wyjscie = [ordered]@{
        hookSpecificOutput = [ordered]@{
            hookEventName            = "PreToolUse"
            permissionDecision       = "deny"
            permissionDecisionReason = $Powod
        }
    }
    Write-Output ($wyjscie | ConvertTo-Json -Depth 4 -Compress)
    exit 0
}

try {
    $dane = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $sciezka = [string]$dane.tool_input.file_path
} catch {
    Write-Odmowa "etap1-analiza: nie udało się odczytać ścieżki zapisu. Zapis zablokowany."
}

if (-not $sciezka) {
    Write-Odmowa "etap1-analiza: brak ścieżki zapisu. Zapis zablokowany."
}

$dozwolone = @(
    '(^|[\\/])refactor-result\d+[\\/]etap1-plan\.md$',
    '(^|[\\/])refactor-result\d+[\\/]komunikacja[\\/][^\\/]+\.json$'
)

foreach ($wzorzec in $dozwolone) {
    if ($sciezka -match $wzorzec) { exit 0 }
}

Write-Odmowa ("etap1-analiza nie zmienia kodu ani innych plików. Dozwolony zapis: " +
    "refactor-resultN/etap1-plan.md i refactor-resultN/komunikacja/*.json. " +
    "Odrzucona ścieżka: $sciezka. Zmiany w kodzie opisz w payload.rozkaz.")
