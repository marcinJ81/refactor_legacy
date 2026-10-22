<#
  wersja-harnessu: 0.3.0
  00-rozpoznanie.ps1 — Etap 0: rozpoznanie stanu (wznowienie sesji).
  Przeszukuje katalogi wynikowe projektu, zakłada katalog communication/
  i zapisuje w nim jedną ramkę Etap 0 → orkiestrator (format:
  etap0-examples/message-frame.md). Gdy jest poprzednia sesja (najnowszy
  refactor-resultN z refactor-config.json) — raport w payload.report; gdy nie
  ma — pusty payload. Niczego nie interpretuje — decyzję „nowa sesja czy
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

$WERSJA_SKRYPTU = "etap0-rozpoznanie/1"

# Harness ma jeden tryb pracy; pole `tryb` zostaje w raporcie jako jawne
# oznaczenie przebiegu — patrz „Pozycja `tryb`” w orkiestrator.md.
$TRYB = "normalny"

if (-not (Test-Path -LiteralPath $KatalogProjektu -PathType Container)) {
    Write-Host ("Katalog projektu nie istnieje: {0}" -f $KatalogProjektu)
    exit 2
}
$KatalogProjektu = (Resolve-Path -LiteralPath $KatalogProjektu).Path

$anomalie = New-Object System.Collections.ArrayList
function Add-Anomalia { param([string]$Tresc) [void]$anomalie.Add($Tresc) }

# --- konfiguracja przebiegu -------------------------------------------------

function Get-Konfiguracja {
    param([string]$KatalogWyniku)

    $pusta = [ordered]@{
        plik_istnieje = $false; sciezka = $null; kompletna = $false
        braki = @(); odpowiedzi = [ordered]@{}
    }
    if (-not $KatalogWyniku) { return $pusta }

    $sciezka = Join-Path $KatalogWyniku "refactor-config.json"
    if (-not (Test-Path -LiteralPath $sciezka)) { return $pusta }

    $config = Read-JsonPliku -Sciezka $sciezka
    if ($null -eq $config) {
        Add-Anomalia "refactor-config.json: plik istnieje, ale nie jest poprawnym JSON-em"
        $pusta.plik_istnieje = $true
        $pusta.sciezka = $sciezka
        return $pusta
    }

    # Pola obowiązujące — patrz „Plik konfiguracji (refactor-config.json)”
    # w orkiestrator.md oraz refactor-config.example.json.
    $wymagane = @(
        "tryb.wartosc",
        "pytanie_0.commitowanie.wartosc", "pytanie_0.zgoda_build.wartosc",
        "pytanie_0.zgoda_testy.wartosc", "pytanie_0.wersja_dotnet.wartosc",
        "pytanie_0.solucja.wartosc", "pytanie_0.sekwencja_budowania.wartosc",
        "pytanie_0.projekty_testowe.wartosc",
        "pytanie_0.zmiany_bez_planu.wartosc",
        "pytanie_0.framework_testow.wartosc", "pytanie_0.granulacja.wartosc",
        "pytanie_1.struktura_plikow.wartosc", "pytanie_1.plik_szczegolowy_per_iteracja.wartosc",
        "pytanie_2.zakres_etapow.wartosc"
    )

    $braki = @()
    $odpowiedzi = [ordered]@{}
    foreach ($sciezkaPola in $wymagane) {
        $biezacy = $config
        foreach ($segment in $sciezkaPola.Split(".")) {
            $biezacy = Get-PoleObiektu -Obiekt $biezacy -Nazwa $segment
            if ($null -eq $biezacy) { break }
        }
        if ($null -eq $biezacy -or "$biezacy" -eq "") { $braki += $sciezkaPola }
        else { $odpowiedzi[$sciezkaPola] = $biezacy }
    }

    return [ordered]@{
        plik_istnieje = $true
        sciezka       = $sciezka
        kompletna     = ($braki.Count -eq 0)
        braki         = @($braki)
        odpowiedzi    = $odpowiedzi
    }
}

# --- sesje (uruchomienia harnessu) ------------------------------------------

function Get-Sesje {
    <#
      Granicą sesji jest nagłówek „## Uruchomienie <znacznik>” w logu
      orkiestratora. Brak nagłówków w logu to błąd formatu logu — trafia do
      anomalii, sesje nie są odtwarzane.
    #>
    param([string]$KatalogWyniku)

    if (-not $KatalogWyniku) { return @() }
    $plikLogu = Join-Path $KatalogWyniku "orkiestrator-log.md"
    if (-not (Test-Path -LiteralPath $plikLogu)) { return @() }

    $linie = @(Get-Content -LiteralPath $plikLogu -Encoding UTF8)
    $bezZnacznika = 0
    $wpisy = @()
    $granice = @()

    for ($i = 0; $i -lt $linie.Count; $i++) {
        $linia = $linie[$i]
        if ($linia -match '^\s*$') { continue }
        $znacznik = Get-ZnacznikZLinii -Linia $linia
        if ($linia -match '^##\s+Uruchomienie') {
            if ($znacznik) { $granice += $znacznik }
            continue
        }
        if ($linia -match '^#') { continue }
        if (-not $znacznik) { $bezZnacznika++; continue }
        $wpisy += [ordered]@{ znacznik = $znacznik; czas = (ConvertFrom-Znacznik -Tekst $znacznik) }
    }

    if ($bezZnacznika -gt 0) {
        Add-Anomalia ("orkiestrator-log.md: {0} wpisów bez znacznika czasu (błąd formatu logu) — nieprzypisane do żadnej sesji" -f $bezZnacznika)
    }
    if ($wpisy.Count -eq 0) { return @() }

    $wpisy = @($wpisy | Sort-Object { $_.czas })

    if ($granice.Count -eq 0) {
        Add-Anomalia "orkiestrator-log.md: brak nagłówków „## Uruchomienie” (błąd formatu logu) — sesje nieodtworzone"
        return @()
    }

    $czasyGranic = @($granice | ForEach-Object { ConvertFrom-Znacznik -Tekst $_ } | Sort-Object)
    $sesje = @()
    for ($n = 0; $n -lt $czasyGranic.Count; $n++) {
        $od = $czasyGranic[$n]
        $doCzasu = if ($n + 1 -lt $czasyGranic.Count) { $czasyGranic[$n + 1] } else { [datetime]::MaxValue }
        $wSesji = @($wpisy | Where-Object { $_.czas -ge $od -and $_.czas -lt $doCzasu })
        $ostatni = if ($wSesji.Count -gt 0) { $wSesji[-1].znacznik } else { (Get-Znacznik -Data $od) }
        $sesje += [ordered]@{
            nr            = $n + 1
            start         = (Get-Znacznik -Data $od)
            ostatni_wpis  = $ostatni
            liczba_wpisow = $wSesji.Count
            zrodlo        = "orkiestrator-log.md"
        }
    }
    return @($sesje)
}

# --- communication ----------------------------------------------------------

function Get-Komunikaty {
    param([string]$KatalogWyniku)

    if (-not $KatalogWyniku) { return @() }
    $katalog = Join-Path $KatalogWyniku "communication"
    if (-not (Test-Path -LiteralPath $katalog)) { return @() }

    $komunikaty = @()
    foreach ($plik in @(Get-ChildItem -LiteralPath $katalog -Filter "*.json" -File | Sort-Object Name)) {
        $tresc = Read-JsonPliku -Sciezka $plik.FullName
        if ($null -eq $tresc) {
            Add-Anomalia ("communication/{0}: nie jest poprawnym JSON-em — pominięty" -f $plik.Name)
            continue
        }
        $komunikaty += [ordered]@{
            plik              = $plik.Name
            msg_id            = (Get-PoleObiektu -Obiekt $tresc -Nazwa "msg_id")
            corr_id           = (Get-PoleObiektu -Obiekt $tresc -Nazwa "corr_id")
            from              = (Get-PoleObiektu -Obiekt $tresc -Nazwa "from")
            to                = (Get-PoleObiektu -Obiekt $tresc -Nazwa "to")
            action            = (Get-PoleObiektu -Obiekt $tresc -Nazwa "action")
            status            = (Get-PoleObiektu -Obiekt $tresc -Nazwa "status")
            timestamp         = (Get-PoleObiektu -Obiekt $tresc -Nazwa "timestamp")
            payload_iteracje  = $null
        }
        $payload = Get-PoleObiektu -Obiekt $tresc -Nazwa "payload"
        $iteracje = Get-PoleObiektu -Obiekt $payload -Nazwa "iteracje"
        if ($null -ne $iteracje) { $komunikaty[-1].payload_iteracje = $iteracje }
    }
    return @($komunikaty)
}

function Get-RequestyOtwarte {
    # Request otwarty = żadna wiadomość nie odwołuje się do niego w corr_id.
    param([array]$Komunikaty)

    $odpowiedziane = @($Komunikaty | ForEach-Object { $_.corr_id } | Where-Object { $_ })
    $otwarte = @()
    foreach ($k in $Komunikaty) {
        if ($k.from -eq "orkiestrator") { continue }
        if (-not $k.msg_id) { continue }
        if ($odpowiedziane -contains $k.msg_id) { continue }
        if ($k.action -in @("stage.done", "step.done")) { continue }
        $otwarte += [ordered]@{
            msg_id    = $k.msg_id
            from      = $k.from
            action    = $k.action
            wystawiony = $k.timestamp
            plik      = "communication/" + $k.plik
        }
    }
    return @($otwarte)
}

# --- etapy ------------------------------------------------------------------

function Get-OstatniZnacznikPliku {
    param([string]$Sciezka)
    if (-not (Test-Path -LiteralPath $Sciezka)) { return $null }
    $ostatni = $null
    foreach ($linia in @(Get-Content -LiteralPath $Sciezka -Encoding UTF8)) {
        $z = Get-ZnacznikZLinii -Linia $linia
        if ($z) { $ostatni = $z }
    }
    return $ostatni
}

function Get-Etapy {
    <#
      Status etapu wynika przede wszystkim z communication/*.json (zapis
      strukturalny). Gdy dla etapu nie ma żadnej wiadomości, brany jest pod
      uwagę sam fakt istnienia logu i pliku wynikowego — z adnotacją w polu
      zrodlo_statusu.
    #>
    param([string]$KatalogWyniku, [array]$Komunikaty)

    if (-not $KatalogWyniku) { return @() }
    $etapy = @()

    foreach ($nr in 0..3) {
        $adres = "etap$nr"
        $wlasne = @($Komunikaty | Where-Object { $_.from -eq $adres -or $_.to -eq $adres -or ("$($_.from)").StartsWith("$adres.") })

        $log = Join-Path $KatalogWyniku ("etap{0}-decisions-log.md" -f $nr)
        $planEtapu = Join-Path $KatalogWyniku ("etap{0}-plan.md" -f $nr)
        $planWspolny = Join-Path $KatalogWyniku "refactor-plan.md"
        $plikWynikowy = if (Test-Path -LiteralPath $planEtapu) { "etap$nr-plan.md" }
                        elseif (Test-Path -LiteralPath $planWspolny) { "refactor-plan.md" }
                        else { $null }

        $status = "not_started"
        $zrodlo = "communication"
        if (@($wlasne | Where-Object { $_.action -eq "stage.aborted" }).Count -gt 0) { $status = "aborted" }
        elseif (@($wlasne | Where-Object { $_.action -eq "stage.done" -and $_.from -eq $adres }).Count -gt 0) { $status = "done" }
        elseif (@($wlasne | Where-Object { $_.action -in @("stage.start", "step.start", "stage.resume") }).Count -gt 0) { $status = "in_progress" }
        elseif ($wlasne.Count -gt 0) { $status = "in_progress" }
        else {
            $zrodlo = "pliki"
            if ((Test-Path -LiteralPath $log) -or $plikWynikowy) { $status = "in_progress" }
        }

        $nazwaLogu = $null
        if (Test-Path -LiteralPath $log) { $nazwaLogu = "etap$nr-decisions-log.md" }

        $pozycja = [ordered]@{
            etap              = $nr
            status            = $status
            zrodlo_statusu    = $zrodlo
            log               = $nazwaLogu
            ostatni_wpis_logu = (Get-OstatniZnacznikPliku -Sciezka $log)
            plik_wynikowy     = $plikWynikowy
            liczba_wiadomosci = $wlasne.Count
        }

        if ($nr -eq 1) {
            $biezaca = $null; $zaplanowane = $null
            foreach ($k in $wlasne) {
                $it = $k.payload_iteracje
                if ($null -eq $it) { continue }
                $b = Get-PoleObiektu -Obiekt $it -Nazwa "biezaca"
                $z = Get-PoleObiektu -Obiekt $it -Nazwa "zaplanowane"
                if ($null -ne $b) { $biezaca = [int]$b }
                if ($null -ne $z) { $zaplanowane = [int]$z }
            }
            $pozycja.iteracje = [ordered]@{ biezaca = $biezaca; zaplanowane = $zaplanowane }
        }

        $etapy += $pozycja
    }
    return @($etapy)
}

# --- pozycje otwarte w planach ----------------------------------------------

function Get-PozycjeOtwarte {
    param([string]$KatalogWyniku)

    if (-not $KatalogWyniku) { return @() }
    $pozycje = @()
    $plany = @(Get-ChildItem -LiteralPath $KatalogWyniku -File -Filter "*.md" -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -match '^(refactor-plan|etap\d+-plan)\.md$' })

    foreach ($plan in $plany) {
        $linie = @(Get-Content -LiteralPath $plan.FullName -Encoding UTF8)
        $wSekcji = $false
        foreach ($linia in $linie) {
            if ($linia -match '^#{1,6}\s') {
                $wSekcji = ($linia -match 'Pozycje\s+otwarte')
                continue
            }
            if (-not $wSekcji) { continue }
            if ($linia -match '^\s*[-*]\s+(.+)$') {
                $tresc = $Matches[1].Trim()
                if ($tresc -and $tresc -notmatch '^(brak|—|-)$') {
                    $pozycje += ("{0}, sekcja Pozycje otwarte: {1}" -f $plan.Name, $tresc)
                }
            }
        }
    }
    return @($pozycje)
}

# --- plik stanu sesji -------------------------------------------------------

function Get-SesjaPoprzednia {
    param([string]$KatalogWyniku)

    $pusta = [ordered]@{ plik_istnieje = $false; sciezka = $null }
    if (-not $KatalogWyniku) { return $pusta }

    $sciezka = Join-Path $KatalogWyniku "refactor-session.md"
    if (-not (Test-Path -LiteralPath $sciezka)) { return $pusta }

    $pola = @{}
    foreach ($linia in @(Get-Content -LiteralPath $sciezka -Encoding UTF8)) {
        if ($linia -match '^\s*[-*]\s*([^:]+):\s*(.*)$') {
            $pola[$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    function Pole { param([string]$Nazwa) if ($pola.ContainsKey($Nazwa)) { $pola[$Nazwa] } else { $null } }

    return [ordered]@{
        plik_istnieje         = $true
        sciezka               = $sciezka
        tryb                  = (Pole "Tryb uruchomienia")
        katalog_wynikowy      = (Pole "Katalog wynikowy")
        etap0_wykonany        = (Get-ZnacznikZLinii -Linia (Pole "Etap 0 wykonany"))
        punkt_wznowienia      = [ordered]@{
            etap_w_toku                 = (Pole "Etap w toku")
            krok_w_toku                 = (Pole "Krok w toku")
            iteracja                    = (Pole "Iteracja")
            ostatnia_zamknieta_jednostka = (Pole "Ostatnia zamknięta jednostka")
        }
    }
}

# --- przebieg ---------------------------------------------------------------

$katalogi = Get-KatalogiWynikowe -KatalogProjektu $KatalogProjektu

$aktywny = $null
$aktywnyPelny = $null
if ($katalogi.Count -gt 0) {
    $aktywny = $katalogi[-1].sciezka
    $aktywnyPelny = Join-Path $KatalogProjektu $aktywny
}

if (Test-Path -LiteralPath (Join-Path $KatalogProjektu "refactor-decisions.md")) {
    Add-Anomalia "refactor-decisions.md: plik z poprzedniej wersji harnessu — konfiguracją jest refactor-config.json"
}

$konfiguracja  = Get-Konfiguracja -KatalogWyniku $aktywnyPelny
$sesje         = Get-Sesje -KatalogWyniku $aktywnyPelny
$komunikaty    = Get-Komunikaty -KatalogWyniku $aktywnyPelny
$etapy         = Get-Etapy -KatalogWyniku $aktywnyPelny -Komunikaty $komunikaty
$requesty      = Get-RequestyOtwarte -Komunikaty $komunikaty
$pozycje       = Get-PozycjeOtwarte -KatalogWyniku $aktywnyPelny
$sesjaPoprzednia = Get-SesjaPoprzednia -KatalogWyniku $aktywnyPelny

$raport = [ordered]@{
    schema                 = "etap0-raport/2"
    zrodlo                 = $WERSJA_SKRYPTU
    generated_at           = (Get-Znacznik)
    tryb                   = $TRYB
    katalog_projektu       = $KatalogProjektu
    katalogi_wynikowe      = @($katalogi)
    aktywny_katalog        = $aktywny
    konfiguracja           = $konfiguracja
    sesje                  = @($sesje)
    etapy                  = @($etapy)
    requesty_otwarte       = @($requesty)
    pozycje_otwarte        = @($pozycje)
    sesja_poprzednia       = $sesjaPoprzednia
    anomalie               = @($anomalie)
}

# Poprzednia sesja = najnowszy katalog wynikowy z refactor-config.json
# (jak w 0.2.2). Bez niej ramka ma pusty payload — to nie jest błąd.
$sesjaZnaleziona = [bool]($aktywnyPelny -and $konfiguracja.plik_istnieje)

# Ramka trafia do communication/ najnowszego katalogu wynikowego; gdy nie ma
# żadnego, powstaje refactor-result1 wyłącznie po to, żeby ramka miała gdzie
# leżeć. Przy -BezTworzenia w takim przypadku ramka nie powstaje.
if (-not $aktywnyPelny -and -not $BezTworzenia) {
    $aktywnyPelny = Join-Path $KatalogProjektu "refactor-result1"
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
    $payload = if ($sesjaZnaleziona) { [ordered]@{ report = $raport } } else { [ordered]@{} }
    # Lista katalogów w aktywnym katalogu wynikowym — zawsze, także bez poprzedniej sesji.
    $payload["directories"] = @(Get-ChildItem -LiteralPath $aktywnyPelny -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
    $ramka = [ordered]@{
        msg_id    = "e0-$nr"
        corr_id   = $null
        from      = "etap0"
        to        = "orkiestrator"
        action    = "stage.done"
        status    = "done"
        payload   = $payload
        timestamp = (Get-Znacznik)
    }
    $plikRamki = Join-Path $katalogKomunikacji ("{0}-etap0-message-frame.json" -f $nr)
    Save-Json -Sciezka $plikRamki -Obiekt $ramka
}

if (-not $Cicho) {
    $wToku = @($etapy | Where-Object { $_.status -eq "in_progress" -or $_.status -eq "aborted" })
    Write-Host ("[etap0] poprzednia sesja: {0}; katalogi wynikowe: {1}; aktywny: {2}" -f $(if ($sesjaZnaleziona) { "tak" } else { "nie" }), $katalogi.Count, $(if ($aktywny) { $aktywny } else { "brak" }))
    if ($sesjaZnaleziona) {
        Write-Host ("[etap0] sesje: {0}; konfiguracja: {1}; etapy w toku: {2}" -f $sesje.Count,
            $(if ($konfiguracja.kompletna) { "kompletna" } else { "niekompletna" }),
            $(if ($wToku.Count -gt 0) { ($wToku | ForEach-Object { "etap$($_.etap)=$($_.status)" }) -join ", " } else { "brak" }))
        Write-Host ("[etap0] requesty otwarte: {0}; pozycje otwarte: {1}; anomalie: {2}" -f $requesty.Count, $pozycje.Count, $anomalie.Count)
    }
    Write-Host ("[etap0] ramka: {0}" -f $(if ($plikRamki) { $plikRamki } else { "niezapisana (brak katalogu wynikowego, -BezTworzenia)" }))
}

exit 0
