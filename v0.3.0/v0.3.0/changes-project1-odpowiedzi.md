# Odpowiedzi Claude do `changes-project1.md`

## Claude — sprawdzenie skryptów Etapu 0 (2026-10-29)

Sprawdzone: `scripts/etap0/00-rozpoznanie.ps1`, `scripts/etap0/_wspolne.ps1`, `.claude/hooks/etap0-start.ps1`, `.claude/settings.json`. Skryptów nie zmieniałem — poniżej błędy i propozycje poprawek.

### Błędy

1. **Krytyczny — jeden katalog wynikowy wywraca rozpoznanie.** `00-rozpoznanie.ps1`, linia 359: `$katalogi = Get-KatalogiWynikowe ...`. Funkcja kończy się `return @(...)`, ale PowerShell rozwija tablicę na wyjściu funkcji — przy jednym `refactor-resultN` `$katalogi` jest pojedynczym `OrderedDictionary`, nie tablicą. Skutek:
   - linia 363: `$katalogi.Count` = 3 (liczba kluczy słownika), nie 1,
   - linia 364: `$katalogi[-1]` — indeks `-1` na `OrderedDictionary` rzuca wyjątek; przy `$ErrorActionPreference = "Stop"` skrypt się przerywa, hook zapisuje ramkę `failed`.

   To najczęstszy przypadek: pierwsze uruchomienie zakłada `refactor-result1`, więc **każde kolejne uruchomienie Etapu 0 kończy się ramką `failed`**. Ten sam błąd jest w `refactor-legacy-v0.2.0/scripts/etap0/00-rozpoznanie.ps1`, linia 363.
   Poprawka: `$katalogi = @(Get-KatalogiWynikowe -KatalogProjektu $KatalogProjektu)`.

2. **Ten sam mechanizm, mniejszy skutek** — linie 373–377: `$sesje`, `$komunikaty`, `$etapy`, `$requesty`, `$pozycje` bez `@(...)`. Przy jednym elemencie podsumowanie podaje złą liczbę (linia 437 `$sesje.Count` = 5, linia 440 `$requesty.Count` = 5 — liczba kluczy). W raporcie JSON wartości są poprawne, bo w `$raport` są opakowane w `@(...)`.
   Poprawka: opakować wszystkie pięć wywołań w `@(...)`.

3. **Prawdopodobny — polskie znaki w kontekście agenta.** `etap0-start.ps1`, linia 137: JSON idzie na stdout w kodowaniu konsoli. Na Windows `pwsh` z przekierowanym wyjściem używa strony kodowej konsoli (np. 852), więc „ę”, „ł” w `additionalContext` mogą dotrzeć jako `?`. JSON zostaje poprawny, psuje się tylko tekst.
   Poprawka: na początku hooka `[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)`.

### Drobne

4. `00-rozpoznanie.ps1`, parametr `-Cicho` (linia 18) — przy nim skrypt nie wypisuje linii `[etap0] ramka:`, a hook (linia 110) uzna to za błąd i zapisze drugą ramkę `failed`. Hook go nie przekazuje, więc dziś bez skutku. Propozycja: usunąć `-Cicho` i `-BezTworzenia` (ten drugi też nieużywany przez hook) albo opisać w nagłówku, że są tylko do ręcznego uruchomienia.
5. `00-rozpoznanie.ps1`, linia 399: `refactor-config.json`, który nie jest poprawnym JSON-em, liczy się jako poprzednia sesja (`plik_istnieje = true`). Zgodne z definicją „katalog zawiera plik”, ale warto potwierdzić.

### Bez zastrzeżeń
- `etap0-start.ps1`: `additionalContext` w `hookSpecificOutput` zgodnie z `instructions/hooks.md` (tabela „Context only” dla `SubagentStart`); kontekst daleko poniżej limitu 10 000 znaków; zawsze `exit 0`; przechwytywanie `Write-Host` przez `*>&1`; ramka `failed` w `Save-RamkaFailed` zgodna z `etap0-examples/message-frame.md`.
- `.claude/settings.json`: matcher `etap0`, ścieżka `${CLAUDE_PROJECT_DIR}/.claude/hooks/etap0-start.ps1` zgodna z miejscem instalacji.
- `.claude/agents/etap0.md`: `permissionMode: manual` jest poprawny (alias `default`, `instructions/sub-agents.md`, linia 308).
- Zapis ramki (`Get-NastepnyNumerRamki`, nazwa `<NNN>-etap0-message-frame.json`, pusty `payload` bez sesji) — zgodny z `.claude/agents/etap0.md`.

Otwarte pozycje z sekcji „braki” w `changes-project1.md` (pkt 1–6: `$wymagane`, `tryb`, zakres raportu, akcje w `Get-Etapy`, `status` ramki `failed`, odwołania do nieistniejących sekcji) — nadal aktualne.

## Claude — instalator dla 0.3.0 (2026-10-29)

Skrypty instalatora (`instalator/scripts/`) działają według `manifest.json` wersji — nie mają wersji zaszytej w kodzie, więc obsługują 0.3.0 bez zmian. Potrzebne były tylko poprawki w źródle i w agencie.

### Zmienione
- `refactor-legacy-v0.3.0/references/etap1-step1/feathers-dependency-breaking-csharp.md`, `feathers-technique-selection.md`, linia 2 — znacznik `wersja-harnessu` 0.2.2 → 0.3.0.
- `refactor-legacy-v0.3.0/references/orchestrator/Configuration.md` — dopisany znacznik `<!-- wersja-harnessu: 0.3.0 -->` pod frontmatterem (brak znacznika).
  Bez tych trzech zmian `01-zrodlo.ps1 -Wersja 0.3.0` zwracał `braki` (`inna_wersja`) i instalacja była niemożliwa.
- `.claude/agents/instalationHarnessRefactor.md`:
  - tabela „Wersje harnessu” — wiersz `0.3.0`,
  - „3. Wersja i źródło”, punkt 2 — pytanie o plik ustawień także dla `0.3.0`,
  - „5. Instalacja” — przy aktualizacji z `0.2.2` do `0.3.0` informacja, co zostaje po 0.2.2 (`agents/etap1/`, `hooks/step2-stop.ps1`, `refactor-legacy/orchestrator-examples/`, `refactor-legacy/scripts/step1/`, wpis `SubagentStop` / `step2`),
  - „6. Podsumowanie”, punkt 2 — zaufanie katalogu także dla `0.3.0`.
- `instalationInfo.md` — `refactor-legacy-v0.3.0/` na liście katalogów wersji.

### Do decyzji
1. Znacznik `wersja-instalatora: 0.2.2` w agencie, `instalationInfo.md` i skryptach — zostawiony, bo skrypty się nie zmieniły. Podnieść do 0.3.0?
2. `README.md`, „Bieżąca wersja: 0.2.2” (linie 11 i 71) i tabela katalogów — nie zmieniane. Aktualizować teraz, czy po przyłączeniu orkiestratora?
3. Po instalacji 0.3.0 harness nie przejdzie całego przebiegu — `orkiestrator.md` 0.3.0 nie jest jeszcze połączony z Etapem 0. Instalacja nadaje się do testu samego Etapu 0 (uruchomienie agenta `etap0`).

## Claude — poprawki skryptów Etapu 0 (2026-10-29)

Poprawki naniesione na aktualną wersję skryptu (przepisaną przez usera: `payload.files` / `payload.directories`, ramka `stage0` → `orchestrator`).

### `scripts/etap0/00-rozpoznanie.ps1`
- Błąd 1 (krytyczny): `$katalogi = @(Get-KatalogiWynikowe ...)` — przy jednym `refactor-resultN` `$katalogi` jest tablicą, `$katalogi[-1]` działa.
- Drobne 4: usunięte parametry `-BezTworzenia` i `-Cicho`. Skrypt zawsze zakłada katalog wynikowy (gdy brak — `refactor-result1`), zawsze zapisuje ramkę i zawsze wypisuje podsumowanie. Nagłówek: kod wyjścia „0 = ramka powstała, 2 = błąd wywołania”.

### `.claude/hooks/etap0-start.ps1`
- Błąd 3: `[Console]::OutputEncoding = UTF-8` na początku hooka.
- Warunek „brak linii `[etap0] ramka:`” bez wyjątku `niezapisana` — skrypt już takiej linii nie wypisuje.

### Nieaktualne po przepisaniu skryptu
- Błąd 2 (`$sesje`, `$komunikaty`, `$etapy`, `$requesty`, `$pozycje` bez `@(...)`) — tych funkcji już nie ma.
- Drobne 5 (niepoprawny `refactor-config.json`) — skrypt sprawdza tylko istnienie pliku, zgodnie z definicją poprzedniej sesji.

### Przy okazji
`.claude/agents/instalationHarnessRefactor.md`, sekcja „5. Instalacja” — konflikt po `git stash pop` (Updated upstream / Stashed changes). Połączone: przykład `0.1.0` z Twojej wersji + akapit o pozostałościach 0.2.2 przy instalacji 0.3.0. Plik nadal ma w gicie status `UU` — trzeba zrobić `git add`; wpis w `git stash list` też został.

## Claude — wersja instalatora 0.3.0 (2026-10-29)

Znacznik `wersja-instalatora` 0.2.2 → 0.3.0 w: `.claude/agents/instalationHarnessRefactor.md`, `instalationInfo.md`, `instalator/scripts/_wspolne.ps1`, `01-zrodlo.ps1`, `02-cel.ps1`, `03-instaluj.ps1`, `log-instalacji.ps1`. Logika skryptów bez zmian. `v0.2.0/v0.2.2/changes-project3.md` (historia) nie zmieniany.
