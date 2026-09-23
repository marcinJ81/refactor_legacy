---
name: etap0
description: Etap 0 — rozpoznanie stanu przed konfiguracją wstępną. Ustala, czy to nowe uruchomienie harnessu, czy kontynuacja przerwanego przebiegu. Uruchamiany wyłącznie przez orkiestratora; rozpoznanie wykonuje skrypt, agent zwraca jego raport JSON.
---

# Etap 0 — Rozpoznanie stanu (wznowienie sesji)

Etap 0 odpowiada na pytanie **„czy to nowe uruchomienie, czy kontynuacja
czegoś, co już się działo"** i dostarcza orkiestratorowi komplet danych
potrzebnych do podjęcia tej decyzji — bez wciągania do kontekstu treści kodu
i treści logów.

Rozpoznanie jest **deterministyczne**: wykonuje je skrypt
`scripts/etap0/00-rozpoznanie.ps1`, a nie agent czytający pliki. Ten sam stan
katalogów zawsze daje ten sam raport. Agent Etapu 0 nie przeszukuje niczego —
uruchamia skrypt i oddaje orkiestratorowi jego raport.

## Kto wykonuje

| Element | Rola |
|---|---|
| hook `SubagentStart`, matcher `etap0` (`.claude/settings.json`) | Uruchamia rozpoznanie przy starcie agenta Etapu 0 — **tylko tego agenta**, nigdzie indziej w harnessie |
| `.claude/hooks/etap0-start.ps1` | Opakowanie hooka: ustala katalog projektu, woła skrypt rozpoznania, wypisuje podsumowanie. Nigdy nie kończy się kodem innym niż 0 |
| `scripts/etap0/00-rozpoznanie.ps1` | Właściwe rozpoznanie: przeszukanie katalogów, odtworzenie historii, zapis `etap0-raport.json` |
| `scripts/etap0/_wspolne.ps1` | Funkcje wspólne skryptu (znaczniki czasu, zapis JSON bez BOM, wyszukanie katalogów wynikowych) |
| agent Etapu 0 | Startuje na zlecenie orkiestratora (`stage.start` → `etap0`), odbiera raport wytworzony przez hooka i zwraca go jako `payload.report`. Nic poza tym — nie przeszukuje katalogów, nie interpretuje wyniku |

Agent pozostaje w przepływie z jednego powodu: raport nie może osiąść
w kontekście orkiestratora w całości. Orkiestrator dostaje **wyłącznie raport
JSON**, a nie zawartość przeszukanych plików.

**Interpretacja raportu należy do orkiestratora** — patrz „Etap 0 i wznowienie
sesji" w `orkiestrator.md`. Skrypt nie rozstrzyga, czy zaczynamy nową sesję,
czy wznawiamy przerwaną.

## Przebieg

1. **Hook odpala się na starcie tego agenta** (`SubagentStart`, matcher
   `etap0`) i uruchamia `00-rozpoznanie.ps1`. Podsumowanie (4 linie + ścieżka)
   trafia do kontekstu agenta, pełny raport do pliku.
2. **Agent zwraca raport** orkiestratorowi jako `payload.report`.

Katalog projektu dociera do hooka zmienną środowiskową
`REFACTOR_KATALOG_PROJEKTU`; przy jej braku hook bierze pole `cwd` z wejścia
JSON zdarzenia, a w ostateczności katalog bieżący. Sposób ustawiania tej
zmiennej przez orkiestratora — *w budowie*.

Harness ma jeden tryb pracy (`normalny` — patrz „Pozycja `tryb`"
w `orkiestrator.md`), więc agent nie porównuje trybu z `payload.config.tryb`
i nie uruchamia skryptu ponownie.


## Wywołanie skryptu

```
scripts/etap0/00-rozpoznanie.ps1 -KatalogProjektu <sciezka>
                                 [-Wyjscie <plik>] [-BezTworzenia] [-Cicho]
```

| Parametr | Znaczenie |
|---|---|
| `-KatalogProjektu` | Katalog projektu objętego refaktorem (obowiązkowy) |
| `-Wyjscie` | Ścieżka pliku raportu; domyślnie `<najnowszy katalog wynikowy>/etap0-raport.json` |
| `-BezTworzenia` | Nie twórz katalogu wynikowego, gdy żaden nie istnieje — raport wtedy nie powstaje, zostaje samo podsumowanie |
| `-Cicho` | Bez podsumowania na stdout |

Kod wyjścia: `0` = raport powstał (albo świadomie nie powstał przy
`-BezTworzenia`), `2` = błąd wywołania (np. nie ma katalogu projektu).

**Jedyne zapisy Etapu 0** to plik raportu oraz — gdy skrypt biegnie bez
`-BezTworzenia`, a nie ma ani jednego katalogu wynikowego — pusty katalog
`refactor-result1`, żeby raport miał gdzie leżeć.
Niczego innego Etap 0 nie tworzy, nie nadpisuje i nie kasuje; w szczególności
nie dotyka `refactor-session.md` (ten zapisuje orkiestrator).

## Zakres przeszukania

Przeszukiwane są **katalogi wynikowe** w projekcie objętym refaktorem (patrz
„Katalog wynikowy" w `orkiestrator.md`): `refactor-result1`,
`refactor-result2`, ... Liczy się wyłącznie ten wzorzec — katalog o innej
nazwie nie jest katalogiem wynikowym i nie trafia do raportu.

Analiza zawartości dotyczy **najnowszego katalogu wynikowego**
(`aktywny_katalog`). Szukane pozycje:

| Pozycja | Czego dostarcza |
|---|---|
| `refactor-config.json` | Konfiguracja przebiegu: czy istnieje, czy kompletna, jakie ma wartości |
| `refactor-session.md` | Punkt wznowienia i ślad po czyszczeniu kontekstu |
| `orkiestrator-log.md` | Podział na sesje (uruchomienia harnessu) |
| `etapN-decisions-log.md` | Znacznik ostatniego wpisu etapu |
| `refactor-plan.md` / `etapN-plan.md` | Istnienie pliku wynikowego etapu; sekcja „Pozycje otwarte" |
| `komunikacja/*.json` | Statusy etapów i requesty bez odpowiedzi |

## Reguły rozpoznania

Reguły są w skrypcie, nie w ocenie agenta:

1. **Sesje.** Granicą sesji jest nagłówek `## Uruchomienie <znacznik>`
   w `orkiestrator-log.md`. Gdy logu nie ma albo nie ma w nim takich nagłówków,
   sesje są odtwarzane z przerw między znacznikami (próg 4 godzin — ten sam,
   co reguła 4 godzin orkiestratora), a fakt użycia reguły zapasowej trafia do
   `anomalie[]`.
2. **Wpisy bez znacznika czasu** (sprzed wprowadzenia reguły znaczników) są
   liczone i raportowane w `anomalie[]`; nie są przypisywane do żadnej sesji.
3. **Status etapu** wynika przede wszystkim z `komunikacja/*.json`:
   `stage.aborted` → `aborted`, `stage.done` od etapu → `done`,
   jakikolwiek `stage.start` / `step.start` / `stage.resume` → `in_progress`,
   brak wiadomości → `not_started`. Gdy dla etapu nie ma żadnej wiadomości,
   a istnieje jego log albo plik wynikowy, status to `in_progress` z adnotacją
   `zrodlo_statusu: "pliki"`.
4. **Request otwarty** = wiadomość typu `request` / `event` spoza
   orkiestratora, do której `msg_id` nie odwołuje się żadne `corr_id`
   (z pominięciem `stage.done` i `step.done`, które zamykają, a nie pytają).
5. **Pozycje otwarte** to punkty listy z sekcji „Pozycje otwarte" plików
   planów; wpis `brak` / `—` jest pomijany.
6. **Brak pliku to `false`, nie domysł.** Niejednoznaczność trafia do
   `anomalie[]`, nie do wniosku.

Etap 0 **nie wchodzi do plików źródłowych projektu** — nie analizuje kodu ani
testów, nie ocenia pokrycia testami, nie sprawdza, czy testy przechodzą, i nie
ocenia merytorycznie tego, co zrobiły poprzednie sesje.

## Wyjście — raport JSON

Raport jest zapisywany jako `etap0-raport.json` i wraca do orkiestratora jako
`payload.report` w odpowiedzi agenta Etapu 0.

Przykład kompletnego raportu — `orchestrator-examples/etap0-raport.md`.

Pola raportu (`schema: "etap0-raport/2"`):

| Pole | Zawartość |
|---|---|
| `zrodlo`, `generated_at` | Wersja skryptu rozpoznania i znacznik wygenerowania |
| `tryb`, `katalog_projektu` | Tryb, w którym powstał przebieg (zawsze `normalny`), i przeszukany katalog |
| `katalogi_wynikowe[]` | `sciezka`, `numer`, `ostatnia_aktywnosc` — posortowane po numerze |
| `aktywny_katalog` | Katalog o największym numerze; `null`, gdy nie ma żadnego |
| `konfiguracja` | `plik_istnieje`, `sciezka`, `kompletna`, `braki[]`, `odpowiedzi` |
| `sesje[]` | `nr`, `start`, `ostatni_wpis`, `liczba_wpisow`, `zrodlo` |
| `etapy[]` | `etap`, `status`, `zrodlo_statusu`, `log`, `ostatni_wpis_logu`, `plik_wynikowy`, `liczba_wiadomosci`; dla Etapu 1 dodatkowo `iteracje` |
| `requesty_otwarte[]` | `msg_id`, `from`, `action`, `wystawiony`, `opis`, `plik` |
| `pozycje_otwarte[]` | Nierozstrzygnięte punkty z planów |
| `sesja_poprzednia` | Odczyt `refactor-session.md` razem z `punkt_wznowienia` |
| `anomalie[]` | Wszystko, czego nie dało się rozstrzygnąć jednoznacznie |

Dopuszczalne wartości `etapy[].status`: `not_started`, `in_progress`, `done`,
`aborted`, `skipped`.

`katalogi_wynikowe[].numer` to `N` z nazwy katalogu. Orkiestrator wylicza z
niego numer kolejnego katalogu jako **największy znaleziony + 1** (patrz
„Katalog wynikowy" w `orkiestrator.md`) — Etap 0 sam niczego nie numeruje.

Gdy nie znaleziono **żadnego** katalogu wynikowego, raport ma tę samą
strukturę, z pustymi tablicami i `konfiguracja.plik_istnieje: false`. Brak
poprzednich sesji nie jest błędem.

## Hook

Hook jest zadeklarowany w `.claude/settings.json` jako zdarzenie
`SubagentStart` z matcherem `etap0`. Dzięki matcherowi uruchamia się wyłącznie
razem z agentem Etapu 0, a nie przy starcie każdego subagenta harnessu.

Frontmatter subagenta przyjmuje tylko `PreToolUse`, `PostToolUse` i `Stop`
(`Stop` zamieniany w czasie pracy na `SubagentStop`), więc startu agenta nie da
się obsłużyć stamtąd — stąd wpis w `settings.json`.

Komenda wskazuje `${CLAUDE_PROJECT_DIR}/.claude/hooks/etap0-start.ps1`;
`${CLAUDE_PROJECT_DIR}` to korzeń projektu, w którym wystartowała sesja.
Skrypt sam odtwarza korzeń harnessu ze swojego położenia i woła
`scripts/etap0/00-rozpoznanie.ps1`.

Hook **nigdy nie kończy się kodem innym niż 0** — błąd rozpoznania nie może
przerwać startu agenta; komunikat o błędzie idzie na stdout i jest widoczny
dla agenta, który przekazuje go orkiestratorowi.

## Log Etapu 0

Etap 0 nie prowadzi własnego pliku logu — jego przebieg odnotowuje orkiestrator
w `orkiestrator-log.md` (zlecenie, czas wykonania, ścieżka raportu, liczba
wykrytych sesji). Raport JSON jest kompletnym śladem tego, co Etap 0 znalazł.
