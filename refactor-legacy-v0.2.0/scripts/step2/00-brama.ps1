<#
  wersja-harnessu: 0.2.2
  00-brama.ps1 — quality gate Step 2: build wybranych projektów + unit testy.
  Wywołuje go hook `.claude/hooks/step2-stop.ps1` (SubagentStop, matcher step2).
  Wynik: quality-gate-step2-result/iteracja-N/podsumowanie.json
  Logi poleceń: quality-gate-step2-result/iteracja-N/restore-<nr>.log, build-<nr>.log, testy-<nr>.log, testy-<nr>.trx
  Kod wyjścia: 0 = passed, 1 = failed, 2 = błąd wywołania.

  Zgoda: pytanie_0.zgoda_build / pytanie_0.zgoda_testy z refactor-config.json
  — jedyna akceptacja uruchomienia; `false` → pozycja `nie_wykonano`.

  Co budować (z refactor-config.json, ścieżki względem katalogu projektu):
  - pytanie_0.solucja             — ścieżka do .sln; nie jest budowana, służy
                                    jako SolutionDir (pakiety NuGet, ścieżki
                                    $(SolutionDir) w .csproj),
  - pytanie_0.sekwencja_budowania — lista .csproj budowanych po kolei; pierwszy
                                    błąd przerywa sekwencję,
  - pytanie_0.projekty_testowe    — lista .csproj, z których uruchamiane są
                                    testy; projekt spoza sekwencji jest
                                    budowany po niej.
  Cała solucja nie jest budowana.

  Wersja .NET (pytanie_0.wersja_dotnet) wybiera polecenia:
  - framework        — prewencyjnie nuget.exe restore (projekt
                       z packages.config, nuget.exe w PATH; brak →
                       pominięte), MSBuild.exe (vswhere) /restore +
                       vstest.console.exe na DLL projektu testowego,
  - core / net5plus  — dotnet build + dotnet test --no-build.
  Liczby testów z pliku .trx (ResultSummary/Counters).
#>
param(
    [Parameter(Mandatory = $true)][string]$KatalogWynikowy,
    [Parameter(Mandatory = $true)][int]$Iteracja,
    [Parameter(Mandatory = $true)][string]$KatalogProjektu
)

Set-StrictMode -Version 1.0
$ErrorActionPreference = "Stop"

$KonfiguracjaBuild = "Debug"

function Get-Znacznik {
    # Format obowiązujący w całym harnessie: yyyy-MM-dd; HH-mm-ss
    (Get-Date).ToString("yyyy-MM-dd; HH-mm-ss")
}

function Save-Json {
    # Zapis bez BOM-u — PS 5.1 przez Set-Content -Encoding UTF8 dokłada BOM.
    param([string]$Sciezka, $Obiekt)
    $tresc = $Obiekt | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($Sciezka, $tresc, (New-Object System.Text.UTF8Encoding($false)))
}

function Get-Wartosc {
    # Odczyt pytanie_0.<pole>.wartosc; brak pola → $null.
    param($Konfiguracja, [string]$Pole)
    $p0 = $Konfiguracja.PSObject.Properties["pytanie_0"]
    if (-not $p0) { return $null }
    $pozycja = $p0.Value.PSObject.Properties[$Pole]
    if (-not $pozycja) { return $null }
    $wartosc = $pozycja.Value.PSObject.Properties["wartosc"]
    if ($wartosc) { $wartosc.Value } else { $null }
}

function Resolve-Sciezka {
    # Ścieżka z konfiguracji → bezwzględna (względna liczona od katalogu projektu).
    param([string]$Sciezka)
    if ([System.IO.Path]::IsPathRooted($Sciezka)) { return $Sciezka }
    [System.IO.Path]::GetFullPath((Join-Path $KatalogProjektu $Sciezka))
}

function Find-Vswhere {
    $sciezka = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path -LiteralPath $sciezka) { $sciezka } else { $null }
}

function Find-MSBuild {
    $vswhere = Find-Vswhere
    if ($vswhere) {
        $wynik = & $vswhere -latest -products * -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1
        if ($wynik) { return $wynik }
    }
    $polecenie = Get-Command "msbuild" -ErrorAction SilentlyContinue
    if ($polecenie) { $polecenie.Source } else { $null }
}

function Find-NuGet {
    $polecenie = Get-Command "nuget.exe" -ErrorAction SilentlyContinue
    if (-not $polecenie) { $polecenie = Get-Command "nuget" -ErrorAction SilentlyContinue }
    if ($polecenie) { $polecenie.Source } else { $null }
}

function Invoke-RestoreNuGet {
    # Tylko framework, prewencyjnie: nuget.exe restore dla projektu z packages.config
    # (pakiety do <katalog .sln>/packages). Zwraca @{ wynik; komunikat; log }.
    param([string]$Projekt, [int]$Nr)
    if (-not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $Projekt) "packages.config"))) {
        return @{ wynik = "pominieto"; komunikat = "brak packages.config"; log = "" }
    }
    $nuget = Find-NuGet
    if (-not $nuget) {
        return @{ wynik = "pominieto"; komunikat = "nie znaleziono nuget.exe w PATH — restore tylko przez MSBuild /restore"; log = "" }
    }
    $plikLogu = Join-Path $katalog ("restore-{0}.log" -f $Nr)
    $kod = Invoke-Polecenie -Program $nuget -Argumenty @("restore", $Projekt, "-SolutionDirectory", $katalogSolucji, "-NonInteractive") -PlikLogu $plikLogu
    $wynik = if ($kod -eq 0) { "ok" } else { "blad" }
    @{ wynik = $wynik; komunikat = ""; log = (Split-Path -Leaf $plikLogu) }
}

function Find-VsTest {
    $vswhere = Find-Vswhere
    if ($vswhere) {
        $wynik = & $vswhere -latest -products * -find "**\vstest.console.exe" | Select-Object -First 1
        if ($wynik) { return $wynik }
    }
    $polecenie = Get-Command "vstest.console.exe" -ErrorAction SilentlyContinue
    if ($polecenie) { $polecenie.Source } else { $null }
}

function Invoke-Polecenie {
    # Uruchamia program, zapisuje wyjście do pliku logu, zwraca kod wyjścia.
    param([string]$Program, [string[]]$Argumenty, [string]$PlikLogu)
    $wyjscie = & $Program @Argumenty 2>&1
    $kod = $LASTEXITCODE
    [System.IO.File]::WriteAllLines($PlikLogu, [string[]]@($wyjscie | ForEach-Object { "$_" }), (New-Object System.Text.UTF8Encoding($false)))
    $kod
}

function Get-PolecenieBuild {
    # Zwraca @{ program; argumenty } dla jednego projektu albo $null + komunikat.
    param([string]$Projekt, [string]$KatalogSolucji)
    $solutionDir = $KatalogSolucji.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    switch ($wersjaDotnet) {
        "framework" {
            $msbuild = Find-MSBuild
            if (-not $msbuild) { return @{ blad = "nie znaleziono MSBuild.exe (vswhere ani PATH)" } }
            return @{ program = $msbuild; argumenty = @(
                $Projekt, "/restore", "/t:Build", "/nologo", "/v:minimal",
                "/p:Configuration=$KonfiguracjaBuild", "/p:RestorePackagesConfig=true",
                "/p:SolutionDir=$solutionDir") }
        }
        { $_ -in @("core", "net5plus") } {
            return @{ program = "dotnet"; argumenty = @(
                "build", $Projekt, "--nologo", "-c", $KonfiguracjaBuild,
                "/p:SolutionDir=$solutionDir") }
        }
        default { return @{ blad = ("nieznana wersja .NET: {0}" -f $wersjaDotnet) } }
    }
}

function Get-PolecenieTestow {
    param([string]$Projekt, [string]$PlikTrx)
    switch ($wersjaDotnet) {
        "framework" {
            $vstest = Find-VsTest
            if (-not $vstest) { return @{ blad = "nie znaleziono vstest.console.exe (vswhere ani PATH)" } }
            $msbuild = Find-MSBuild
            # TargetPath = ścieżka DLL projektu testowego (MSBuild 17.8+: -getProperty).
            $dll = (& $msbuild $Projekt "-getProperty:TargetPath" "/p:Configuration=$KonfiguracjaBuild" "/nologo" 2>$null | Select-Object -Last 1)
            if (-not $dll -or -not (Test-Path -LiteralPath $dll)) {
                return @{ blad = ("nie ustalono DLL projektu testowego: {0}" -f $Projekt) }
            }
            return @{ program = $vstest; argumenty = @(
                $dll, ("/logger:trx;LogFileName={0}" -f (Split-Path -Leaf $PlikTrx)),
                ("/ResultsDirectory:{0}" -f (Split-Path -Parent $PlikTrx))) }
        }
        { $_ -in @("core", "net5plus") } {
            return @{ program = "dotnet"; argumenty = @(
                "test", $Projekt, "--no-build", "--nologo", "-c", $KonfiguracjaBuild,
                "--logger", ("trx;LogFileName={0}" -f (Split-Path -Leaf $PlikTrx)),
                "--results-directory", (Split-Path -Parent $PlikTrx)) }
        }
        default { return @{ blad = ("nieznana wersja .NET: {0}" -f $wersjaDotnet) } }
    }
}

function Read-Trx {
    # Liczniki z .trx: ResultSummary/Counters (total, passed). Brak pliku → $null.
    param([string]$PlikTrx)
    if (-not (Test-Path -LiteralPath $PlikTrx)) { return $null }
    [xml]$trx = Get-Content -LiteralPath $PlikTrx -Raw -Encoding UTF8
    $liczniki = $trx.TestRun.ResultSummary.Counters
    @{ wszystkich = [int]$liczniki.total; przeszlo = [int]$liczniki.passed }
}

function Invoke-Build {
    # Build projektów po kolei: sekwencja_budowania, potem projekty testowe spoza niej.
    $projekty = @()
    $doZbudowania = @($sekwencja) + @($projektyTestowe | Where-Object { $sekwencja -notcontains $_ })
    $nr = 0
    foreach ($projekt in $doZbudowania) {
        $nr++
        $sciezka = Resolve-Sciezka $projekt
        if (-not (Test-Path -LiteralPath $sciezka)) {
            $projekty += [ordered]@{ projekt = $projekt; wynik = "blad"; komunikat = "plik projektu nie istnieje"; log = "" }
            return [ordered]@{ wynik = "blad"; komunikat = ("brak projektu: {0}" -f $projekt); projekty = $projekty; wykonal = "hook" }
        }
        $restore = $null
        if ($wersjaDotnet -eq "framework") {
            $restore = Invoke-RestoreNuGet -Projekt $sciezka -Nr $nr
            if ($restore.wynik -eq "blad") {
                $projekty += [ordered]@{ projekt = $projekt; wynik = "blad"; komunikat = "nuget restore nie przeszedł"; restore = $restore; log = $restore.log }
                return [ordered]@{ wynik = "blad"; komunikat = ("nuget restore nie przeszedł: {0}" -f $projekt); projekty = $projekty; wykonal = "hook" }
            }
        }
        $polecenie = Get-PolecenieBuild -Projekt $sciezka -KatalogSolucji $katalogSolucji
        if ($polecenie.blad) {
            return [ordered]@{ wynik = "nie_wykonano"; komunikat = $polecenie.blad; projekty = $projekty; wykonal = "hook" }
        }
        $plikLogu = Join-Path $katalog ("build-{0}.log" -f $nr)
        $kod = Invoke-Polecenie -Program $polecenie.program -Argumenty $polecenie.argumenty -PlikLogu $plikLogu
        $wynik = if ($kod -eq 0) { "ok" } else { "blad" }
        $projekty += [ordered]@{
            projekt   = $projekt
            wynik     = $wynik
            polecenie = ("{0} {1}" -f $polecenie.program, ($polecenie.argumenty -join " "))
            restore   = $restore
            log       = (Split-Path -Leaf $plikLogu)
        }
        if ($wynik -eq "blad") {
            return [ordered]@{ wynik = "blad"; komunikat = ("build nie przeszedł: {0}" -f $projekt); projekty = $projekty; wykonal = "hook" }
        }
    }
    [ordered]@{ wynik = "ok"; komunikat = ""; projekty = $projekty; wykonal = "hook" }
}

function Invoke-Testy {
    # Testy z każdego projektu testowego; suma liczników z plików .trx.
    $projekty = @()
    $przeszlo = 0
    $wszystkich = 0
    $wynikZbiorczy = "ok"
    $nr = 0
    foreach ($projekt in $projektyTestowe) {
        $nr++
        $plikTrx = Join-Path $katalog ("testy-{0}.trx" -f $nr)
        $polecenie = Get-PolecenieTestow -Projekt (Resolve-Sciezka $projekt) -PlikTrx $plikTrx
        if ($polecenie.blad) {
            $projekty += [ordered]@{ projekt = $projekt; wynik = "nie_wykonano"; komunikat = $polecenie.blad }
            $wynikZbiorczy = "blad"
            continue
        }
        $plikLogu = Join-Path $katalog ("testy-{0}.log" -f $nr)
        $kod = Invoke-Polecenie -Program $polecenie.program -Argumenty $polecenie.argumenty -PlikLogu $plikLogu
        $liczniki = Read-Trx -PlikTrx $plikTrx
        $wynik = if ($kod -eq 0 -and $liczniki) { "ok" } else { "blad" }
        if ($wynik -eq "blad") { $wynikZbiorczy = "blad" }
        $pozycja = [ordered]@{
            projekt   = $projekt
            wynik     = $wynik
            przeszlo  = if ($liczniki) { $liczniki.przeszlo } else { 0 }
            wszystkich = if ($liczniki) { $liczniki.wszystkich } else { 0 }
            polecenie = ("{0} {1}" -f $polecenie.program, ($polecenie.argumenty -join " "))
            log       = (Split-Path -Leaf $plikLogu)
        }
        $przeszlo += $pozycja.przeszlo
        $wszystkich += $pozycja.wszystkich
        $projekty += $pozycja
    }
    [ordered]@{ wynik = $wynikZbiorczy; przeszlo = $przeszlo; wszystkich = $wszystkich; komunikat = ""; projekty = $projekty; wykonal = "hook" }
}

function New-NieWykonano {
    param([string]$Komunikat, [switch]$Testy)
    if ($Testy) {
        [ordered]@{ wynik = "nie_wykonano"; przeszlo = 0; wszystkich = 0; komunikat = $Komunikat; projekty = @(); wykonal = "hook" }
    } else {
        [ordered]@{ wynik = "nie_wykonano"; komunikat = $Komunikat; projekty = @(); wykonal = "hook" }
    }
}

if (-not (Test-Path -LiteralPath $KatalogWynikowy)) {
    Write-Host ("Katalog wynikowy nie istnieje: {0}" -f $KatalogWynikowy)
    exit 2
}

$plikKonfiguracji = Join-Path $KatalogWynikowy "refactor-config.json"
if (-not (Test-Path -LiteralPath $plikKonfiguracji)) {
    Write-Host ("Brak refactor-config.json: {0}" -f $plikKonfiguracji)
    exit 2
}
$konfiguracja = Get-Content -LiteralPath $plikKonfiguracji -Raw -Encoding UTF8 | ConvertFrom-Json

$wersjaDotnet    = [string](Get-Wartosc -Konfiguracja $konfiguracja -Pole "wersja_dotnet")
$zgodaBuild      = (Get-Wartosc -Konfiguracja $konfiguracja -Pole "zgoda_build") -eq $true
$zgodaTesty      = (Get-Wartosc -Konfiguracja $konfiguracja -Pole "zgoda_testy") -eq $true
$solucja         = [string](Get-Wartosc -Konfiguracja $konfiguracja -Pole "solucja")
$sekwencja       = @(Get-Wartosc -Konfiguracja $konfiguracja -Pole "sekwencja_budowania" | Where-Object { $_ })
$projektyTestowe = @(Get-Wartosc -Konfiguracja $konfiguracja -Pole "projekty_testowe" | Where-Object { $_ })

$katalog = Join-Path (Join-Path $KatalogWynikowy "quality-gate-step2-result") ("iteracja-{0}" -f $Iteracja)
if (-not (Test-Path -LiteralPath $katalog)) { New-Item -ItemType Directory -Path $katalog -Force | Out-Null }

# Braki w konfiguracji budowania → nie_wykonano z komunikatem (nie błąd wywołania).
$brakKonfiguracji = @()
if (-not $solucja -or -not (Test-Path -LiteralPath (Resolve-Sciezka $solucja))) { $brakKonfiguracji += "pytanie_0.solucja (brak pola albo pliku .sln)" }
if ($sekwencja.Count -eq 0) { $brakKonfiguracji += "pytanie_0.sekwencja_budowania (pusta lista)" }
if ($projektyTestowe.Count -eq 0) { $brakKonfiguracji += "pytanie_0.projekty_testowe (pusta lista)" }
$katalogSolucji = if ($solucja) { Split-Path -Parent (Resolve-Sciezka $solucja) } else { "" }

$build = if (-not $zgodaBuild) {
    New-NieWykonano -Komunikat "brak zgody na build (pytanie_0.zgoda_build)"
} elseif ($brakKonfiguracji.Count -gt 0) {
    New-NieWykonano -Komunikat ("niekompletna konfiguracja budowania: {0}" -f ($brakKonfiguracji -join "; "))
} else {
    Invoke-Build
}
$testy = if (-not $zgodaTesty) {
    New-NieWykonano -Testy -Komunikat "brak zgody na unit testy (pytanie_0.zgoda_testy)"
} elseif ($build.wynik -eq "ok") {
    Invoke-Testy
} else {
    New-NieWykonano -Testy -Komunikat "build nie przeszedł"
}

$status = if ($build.wynik -eq "ok" -and $testy.wynik -eq "ok") { "passed" } else { "failed" }

$podsumowanie = [ordered]@{
    etap          = "etap1"
    krok          = "step2"
    iteracja      = $Iteracja
    wersja_dotnet = $wersjaDotnet
    solucja       = $solucja
    status        = $status
    build         = $build
    testy         = $testy
    timestamp     = Get-Znacznik
}

$plik = Join-Path $katalog "podsumowanie.json"
Save-Json -Sciezka $plik -Obiekt $podsumowanie

Write-Host ("[brama step2] iteracja {0}: {1} -> {2}" -f $Iteracja, $status, $plik)

if ($status -eq "passed") { exit 0 } else { exit 1 }
