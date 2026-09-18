<#
  hook-start.ps1 — hook startu agenta Etapu 0.
  Zarejestrowany we frontmatterze `etap0.md` (zdarzenie SessionStart), więc
  uruchamia się **wyłącznie przy starcie agenta Etapu 0**, nie przy każdym
  agencie harnessu.

  Woła scripts/etap0/00-rozpoznanie.ps1 i wypisuje jego podsumowanie na stdout,
  skąd trafia do kontekstu startowego agenta. Pełny raport zostaje w pliku —
  agent przepycha go orkiestratorowi jako payload.report.

  Tryb jest ustalany przed Etapem 0 (Pytanie T), więc hook go zna: bierze go
  ze zmiennej środowiskowej REFACTOR_TRYB, a gdy jej nie ma — z wartości
  domyślnej `normalny`. Agent po odczytaniu raportu porównuje pole `tryb`
  z `payload.config.tryb` i przy rozjeździe uruchamia skrypt ponownie
  z właściwym `-Tryb`.

  Hook **nigdy nie kończy się kodem innym niż 0** — błąd rozpoznania nie może
  przerwać startu agenta.
#>

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Continue"

try {
    # Katalog projektu: zmienna środowiskowa, pole cwd z wejścia hooka,
    # w ostateczności bieżący katalog.
    $katalogProjektu = $env:REFACTOR_KATALOG_PROJEKTU
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

    $tryb = $env:REFACTOR_TRYB
    if ($tryb -notin @("normalny", "test")) { $tryb = "normalny" }

    $skrypt = Join-Path $PSScriptRoot "00-rozpoznanie.ps1"
    if (-not (Test-Path -LiteralPath $skrypt)) {
        Write-Output "[etap0][hook] Nie znaleziono skryptu rozpoznania: $skrypt"
        exit 0
    }

    Write-Output "## Etap 0 — rozpoznanie stanu (hook startu agenta)"
    & $skrypt -KatalogProjektu $katalogProjektu -Tryb $tryb
    Write-Output "Raport jest danymi dla orkiestratora. Decyzję „nowa sesja czy wznowienie” podejmuje orkiestrator — patrz „Etap 0 i wznowienie sesji” w orkiestrator.md."
} catch {
    Write-Output ("[etap0][hook] Rozpoznanie nie wykonało się: {0}" -f $_.Exception.Message)
}

exit 0
