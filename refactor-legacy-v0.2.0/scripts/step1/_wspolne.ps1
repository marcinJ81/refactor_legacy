# _wspolne.ps1 — funkcje wspólne dla skryptów bramy Step 1.
# Dot-source'owany przez skrypty 01–04 i 00-brama.ps1. Sam nic nie sprawdza.

Set-StrictMode -Version 1.0

function Get-Znacznik {
    # Format obowiązujący w całym harnessie: yyyy-MM-dd; HH-mm-ss
    (Get-Date).ToString("yyyy-MM-dd; HH-mm-ss")
}

function Get-KatalogWynikuBramy {
    param([string]$KatalogWynikowy, [int]$Iteracja)
    Join-Path (Join-Path $KatalogWynikowy "quality-gate-step1-analize-result") ("iteracja-{0}" -f $Iteracja)
}

function Save-Json {
    # Zapis bez BOM-u — PS 5.1 przez Set-Content -Encoding UTF8 dokłada BOM,
    # na którym potykają się inne parsery JSON.
    param([string]$Sciezka, $Obiekt)
    $tresc = $Obiekt | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($Sciezka, $tresc, (New-Object System.Text.UTF8Encoding($false)))
}

function New-Szczegol {
    param([string]$Pozycja, [string]$Wynik, [string]$Komunikat = "")
    [ordered]@{ pozycja = $Pozycja; wynik = $Wynik; komunikat = $Komunikat }
}

function Save-WynikBramy {
    <#
      Zapisuje wynik pojedynczego sprawdzenia i zwraca kod wyjścia:
      0 = passed, 1 = failed. Plik: <katalog iteracji>/<Skrypt>.json
    #>
    param(
        [string]$Skrypt,
        [string]$KatalogWynikowy,
        [int]$Iteracja,
        [array]$Szczegoly
    )

    $katalog = Get-KatalogWynikuBramy -KatalogWynikowy $KatalogWynikowy -Iteracja $Iteracja
    if (-not (Test-Path -LiteralPath $katalog)) {
        New-Item -ItemType Directory -Path $katalog -Force | Out-Null
    }

    $failed = @($Szczegoly | Where-Object { $_.wynik -ne "ok" })
    $wynik = if ($failed.Count -eq 0) { "passed" } else { "failed" }

    $obiekt = [ordered]@{
        skrypt    = $Skrypt
        etap      = "etap1"
        krok      = "step1"
        iteracja  = $Iteracja
        wynik     = $wynik
        szczegoly = $Szczegoly
        timestamp = Get-Znacznik
    }

    $plik = Join-Path $katalog ("{0}.json" -f $Skrypt)
    Save-Json -Sciezka $plik -Obiekt $obiekt

    Write-Host ("[{0}] {1} -> {2}" -f $Skrypt, $wynik, $plik)
    foreach ($s in $failed) { Write-Host ("  - {0}: {1}" -f $s.pozycja, $s.komunikat) }

    if ($wynik -eq "passed") { return 0 } else { return 1 }
}

function Get-PlikAnalizy {
    param([string]$KatalogWynikowy, [int]$Iteracja, [string]$PlikAnalizy)
    if ($PlikAnalizy) { return $PlikAnalizy }
    Join-Path $KatalogWynikowy ("step1-analiza-{0}.md" -f $Iteracja)
}

function Get-BlokIteracji {
    <#
      Opcja A (osobny plik na iterację): zwraca całą treść.
      Opcja B (plik zbiorczy): wycina blok "## Etap 1 / Step 1 — iteracja N"
      do następnego nagłówka poziomu 2.
    #>
    param([string[]]$Linie, [int]$Iteracja)

    $wzorzec = "^##\s+Etap\s+1\s*/\s*Step\s+1\s*[-—–]\s*iteracja\s+$Iteracja\s*$"
    $start = -1
    for ($i = 0; $i -lt $Linie.Count; $i++) {
        if ($Linie[$i] -match $wzorzec) { $start = $i; break }
    }
    if ($start -lt 0) { return $Linie }

    $koniec = $Linie.Count
    for ($i = $start + 1; $i -lt $Linie.Count; $i++) {
        if ($Linie[$i] -match "^##\s+(?!#)" ) { $koniec = $i; break }
    }
    return $Linie[$start..($koniec - 1)]
}
