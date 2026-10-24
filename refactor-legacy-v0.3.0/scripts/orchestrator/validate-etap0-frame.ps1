<#
  wersja-harnessu: 0.3.0
  validate-etap0-frame.ps1 — walidacja ramki Etap 0 → orkiestrator.
  Uruchamia orkiestrator dla ramki zwróconej przez agenta etap0
  (kontrakt ValidateEtap0Frame, references/contracts.md).

  Sprawdza:
  1. każde pole ramki według references/frame-model.md (enumy Participant,
     Action, FrameStatus czytane z tego pliku; invarianty I1–I8),
  2. strukturę payload Etapu 0 — tylko gdy status == done i payload nie jest pusty:
     - directories: wymagane, tablica napisów,
     - files: opcjonalne (jest tylko przy poprzedniej sesji), tablica niepustych napisów,
     - inne pola niedozwolone.

  Wejście: -SciezkaRamki (plik JSON) albo -Tresc (JSON ramki jako tekst).
  Wyjście: JSON { "valid": bool, "errors": [ ... ] } na stdout.
  Kod wyjścia: 0 = ramka poprawna, 1 = ramka niepoprawna, 2 = błąd wywołania.
#>
param(
    [string]$SciezkaRamki,
    [string]$Tresc
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"

$bledy = New-Object System.Collections.ArrayList
function Add-Blad { param([string]$Tekst) [void]$bledy.Add($Tekst) }

function Write-Wynik {
    $wynik = [ordered]@{ valid = ($bledy.Count -eq 0); errors = @($bledy) }
    Write-Output ($wynik | ConvertTo-Json -Depth 4 -Compress)
    if ($bledy.Count -eq 0) { exit 0 } else { exit 1 }
}

function Get-Enumy {
    # Enumy z frame-model.md: blok „enum Nazwa { a, b, -- komentarz ... }”.
    param([string]$SciezkaModelu)
    $enumy = @{}
    $tekst = Get-Content -LiteralPath $SciezkaModelu -Raw -Encoding UTF8
    foreach ($m in [regex]::Matches($tekst, '(?s)enum\s+(\w+)\s*\{(.*?)\}')) {
        $wartosci = @()
        foreach ($linia in ($m.Groups[2].Value -split "`n")) {
            $bezKomentarza = ($linia -replace '--.*$', '')
            foreach ($w in ($bezKomentarza -split ',')) {
                $w = $w.Trim()
                if ($w) { $wartosci += $w }
            }
        }
        $enumy[$m.Groups[1].Value] = $wartosci
    }
    return $enumy
}

function Get-Napis {
    # Wartość pola jako string; $null gdy pole nie jest napisem.
    param([System.Text.Json.JsonElement]$Element)
    if ($Element.ValueKind -eq [System.Text.Json.JsonValueKind]::String) { return $Element.GetString() }
    return $null
}

function Test-TablicaNapisow {
    param([System.Text.Json.JsonElement]$Element, [string]$Nazwa, [switch]$Niepuste)
    if ($Element.ValueKind -ne [System.Text.Json.JsonValueKind]::Array) {
        Add-Blad "payload.${Nazwa}: musi być tablicą"
        return
    }
    $i = 0
    foreach ($e in $Element.EnumerateArray()) {
        if ($e.ValueKind -ne [System.Text.Json.JsonValueKind]::String) {
            Add-Blad "payload.${Nazwa}[$i]: musi być napisem"
        } elseif ($Niepuste -and -not $e.GetString().Trim()) {
            Add-Blad "payload.${Nazwa}[$i]: pusty napis"
        }
        $i++
    }
}

# --- wejście ----------------------------------------------------------------

if ([bool]$SciezkaRamki -eq [bool]$Tresc) {
    Write-Host "Podaj dokładnie jeden parametr: -SciezkaRamki albo -Tresc"
    exit 2
}
if ($SciezkaRamki) {
    if (-not (Test-Path -LiteralPath $SciezkaRamki -PathType Leaf)) {
        Write-Host ("Plik ramki nie istnieje: {0}" -f $SciezkaRamki)
        exit 2
    }
    $Tresc = Get-Content -LiteralPath $SciezkaRamki -Raw -Encoding UTF8
}

# Skrypt leży w <harness>/scripts/orchestrator/, model w <harness>/references/.
$sciezkaModelu = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "references/frame-model.md"
if (-not (Test-Path -LiteralPath $sciezkaModelu)) {
    Write-Host ("Nie znaleziono modelu ramki: {0}" -f $sciezkaModelu)
    exit 2
}
$enumy = Get-Enumy -SciezkaModelu $sciezkaModelu
foreach ($nazwa in @("Participant", "Action", "FrameStatus")) {
    if (-not $enumy.ContainsKey($nazwa)) {
        Write-Host ("frame-model.md: brak enum {0}" -f $nazwa)
        exit 2
    }
}

# System.Text.Json zamiast ConvertFrom-Json — ConvertFrom-Json w PS 7 zamienia
# napisy ISO 8601 na [datetime] i nie odróżnia typów wartości.
try {
    $dokument = [System.Text.Json.JsonDocument]::Parse($Tresc)
} catch {
    Add-Blad ("ramka nie jest poprawnym JSON-em: {0}" -f $_.Exception.Message)
    Write-Wynik
}
$ramka = $dokument.RootElement
if ($ramka.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
    Add-Blad "ramka musi być obiektem JSON"
    Write-Wynik
}

# --- pola ramki (model Frame) -----------------------------------------------

$pola = @("msg_id", "corr_id", "from", "to", "action", "status", "payload", "timestamp")
$wartosc = @{}
foreach ($p in $ramka.EnumerateObject()) {
    if ($pola -notcontains $p.Name) { Add-Blad ("pole spoza modelu Frame: {0}" -f $p.Name) }
    else { $wartosc[$p.Name] = $p.Value }
}
foreach ($p in $pola) {
    if (-not $wartosc.ContainsKey($p)) { Add-Blad ("brak pola: {0}" -f $p) }
}
if ($bledy.Count -gt 0) { Write-Wynik }

$wzorzecId = '^(?:00[1-9]|0[1-9][0-9]|[1-9][0-9]{2})$'

# I1: msg_id
$msgId = Get-Napis $wartosc["msg_id"]
if ($null -eq $msgId) { Add-Blad "msg_id: musi być napisem" }
elseif ($msgId -notmatch $wzorzecId) { Add-Blad ("msg_id: '{0}' nie pasuje do formatu 001–999 (I1)" -f $msgId) }

# I2, I3: corr_id
$corrElement = $wartosc["corr_id"]
$czyPoczatkowa = ($msgId -eq "001")
if ($czyPoczatkowa) {
    if ($corrElement.ValueKind -ne [System.Text.Json.JsonValueKind]::Null) { Add-Blad "corr_id: ramka początkowa (msg_id 001) musi mieć corr_id null (I2)" }
} else {
    $corrId = Get-Napis $corrElement
    if ($null -eq $corrId) { Add-Blad "corr_id: wymagany napis przy ramce nie-początkowej (I3)" }
    elseif ($corrId -notmatch $wzorzecId) { Add-Blad ("corr_id: '{0}' nie pasuje do formatu 001–999 (I3)" -f $corrId) }
    elseif ($msgId -match $wzorzecId -and [int]$corrId -ge [int]$msgId) { Add-Blad ("corr_id: {0} musi być mniejszy niż msg_id {1} (I3)" -f $corrId, $msgId) }
}

# from, to: Participant; I4, I5
$from = Get-Napis $wartosc["from"]
$to   = Get-Napis $wartosc["to"]
foreach ($para in @(@("from", $from), @("to", $to))) {
    if ($null -eq $para[1]) { Add-Blad ("{0}: musi być napisem" -f $para[0]) }
    elseif ($enumy["Participant"] -cnotcontains $para[1]) { Add-Blad ("{0}: '{1}' spoza enum Participant" -f $para[0], $para[1]) }
}
if ($from -and $from -ceq $to) { Add-Blad "from i to muszą być różne (I4)" }
if ($from -cne "orchestrator" -and $to -cne "orchestrator") { Add-Blad "from albo to musi być orchestrator (I5)" }

# action: Action
$action = Get-Napis $wartosc["action"]
if ($null -eq $action) { Add-Blad "action: musi być napisem" }
elseif ($enumy["Action"] -cnotcontains $action) { Add-Blad ("action: '{0}' spoza enum Action" -f $action) }

# status: FrameStatus
$status = Get-Napis $wartosc["status"]
if ($null -eq $status) { Add-Blad "status: musi być napisem" }
elseif ($enumy["FrameStatus"] -cnotcontains $status) { Add-Blad ("status: '{0}' spoza enum FrameStatus" -f $status) }

# payload: obiekt; I6, I7
$payload = $wartosc["payload"]
$polaPayload = @{}
if ($payload.ValueKind -ne [System.Text.Json.JsonValueKind]::Object) {
    Add-Blad "payload: musi być obiektem"
} else {
    foreach ($p in $payload.EnumerateObject()) { $polaPayload[$p.Name] = $p.Value }
    if ($status -ceq "failed") {
        $e = if ($polaPayload.ContainsKey("error")) { Get-Napis $polaPayload["error"] } else { $null }
        if (-not $e -or -not $e.Trim()) { Add-Blad "payload.error: wymagany niepusty napis przy status failed (I6)" }
    }
    if ($status -ceq "blocked") {
        $r = if ($polaPayload.ContainsKey("reason")) { Get-Napis $polaPayload["reason"] } else { $null }
        if (-not $r -or -not $r.Trim()) { Add-Blad "payload.reason: wymagany niepusty napis przy status blocked (I7)" }
    }
}

# I8: timestamp ISO 8601 z offsetem
$timestamp = Get-Napis $wartosc["timestamp"]
$czas = [DateTimeOffset]::MinValue
if ($null -eq $timestamp) { Add-Blad "timestamp: musi być napisem (I8)" }
elseif ($timestamp -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})$' -or
        -not [DateTimeOffset]::TryParse($timestamp, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$czas)) {
    Add-Blad ("timestamp: '{0}' nie jest ISO 8601 z offsetem (I8)" -f $timestamp)
}

# --- payload Etapu 0: tylko status done i niepusty payload --------------------

if ($status -ceq "done" -and $polaPayload.Count -gt 0) {
    foreach ($nazwa in $polaPayload.Keys) {
        if (@("files", "directories") -notcontains $nazwa) { Add-Blad ("payload.{0}: pole spoza struktury payload Etapu 0" -f $nazwa) }
    }
    if (-not $polaPayload.ContainsKey("directories")) { Add-Blad "payload.directories: brak pola" }
    else { Test-TablicaNapisow -Element $polaPayload["directories"] -Nazwa "directories" -Niepuste }
    if ($polaPayload.ContainsKey("files")) {
        Test-TablicaNapisow -Element $polaPayload["files"] -Nazwa "files" -Niepuste
    }
}

Write-Wynik
