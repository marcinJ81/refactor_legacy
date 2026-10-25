# Etap 0 — Rozpoznanie stanu (wznowienie sesji)
<!-- wersja-harnessu: 0.1.1 -->

Uruchamiany przez orkiestratora jako **pierwsza czynność każdego uruchomienia
harnessu — jeszcze przed Pytaniami 0–2**. Konfiguracji wstępnej w tym momencie
może w ogóle nie być; Etap 0 właśnie po to istnieje, żeby ustalić, czy już
istnieje i co poza nią zostało zrobione wcześniej.

Cel etapu: odpowiedzieć orkiestratorowi na pytanie **"czy to nowe uruchomienie,
czy kontynuacja czegoś, co już się działo"**, i dostarczyć komplet danych
potrzebnych do podjęcia tej decyzji — bez wciągania do kontekstu treści kodu
i treści logów.

## Kto wykonuje

Etap 0 wykonuje **agent zlecony przez orkiestratora**, w osobnym kontekście.
Orkiestrator nie przeszukuje katalogów samodzielnie.

Powód jest praktyczny: przeszukanie katalogu wynikowego po wielu wcześniejszych
uruchomieniach oznacza przeczytanie kilkunastu plików logów i planów. Ta treść
nie może osiąść w kontekście orkiestratora — orkiestrator ma dostać
**wyłącznie raport JSON**, a nie zawartość plików.

## Zakres przeszukania

Etap 0 przeszukuje **zbiór logów i informacji gromadzonych przez harness** —
czyli katalogi wynikowe w projekcie będącym przedmiotem refaktoryzacji (patrz
"Katalog wynikowy" w `orkiestrator.md`), wszystkie kolejne numery:
`refactor-result1`, `refactor-result2`, ...

Szukane pozycje:

| Pozycja | Czego dotyczy |
|---|---|
| `refactor-session.md` | Krótki plik stanu sesji — czy Etap 0 był już wykonany i kiedy, czy kontekst był czyszczony |
| `refactor-decisions.md` | Plik z odpowiedziami na pytania wstępne (Pytania 0–2) |
| `orkiestrator-log.md` | Log orkiestratora — starty/końce etapów, routing, bramy |
| `etap1-decisions-log.md`, `etap2-decisions-log.md`, ... | Logi etapów |
| `refactor-plan.md` / `etapN-plan.md` | Pliki wynikowe etapów (Opcja B / Opcja A) |
| `etapN-iteracja-M-zmiany.md`, `etap2-krok-N-zmiany.md` | Opcjonalne pliki szczegółowe |
| `komunikacja/*.json` | Wiadomości protokołu — do wykrycia requestów bez odpowiedzi |

## Czego Etap 0 nie robi

- **Nie analizuje kodu produkcyjnego ani testów.** Nie wchodzi do plików
  źródłowych projektu, nie ocenia pokrycia testami, nie sprawdza, czy testy
  przechodzą.
- **Nie ocenia merytorycznie** tego, co zrobiły poprzednie sesje.
- **Niczego nie zmienia** — Etap 0 jest read-only. Nie tworzy, nie nadpisuje
  i nie kasuje żadnego pliku, w tym `refactor-session.md` (ten zapisuje
  orkiestrator).
- **Nie zgaduje.** Brak pliku to `false`, a nie domysł. Niejednoznaczność
  trafia do `anomalie[]`, nie do wniosku.

## Wykrywanie sesji — rola znaczników czasu

Rozdzielenie kolejnych uruchomień harnessu opiera się wyłącznie na
**znacznikach czasu wpisów w logach** (format i obowiązek — patrz "Znaczniki
czasu w logach" w `orkiestrator.md`). Etap 0 grupuje wpisy w sesje po
znaczniku startu etapu (`start etapu` w logu orkiestratora / pierwszy wpis
logu etapu).

Wpisy bez znacznika czasu (pochodzące z uruchomienia sprzed wprowadzenia tej
reguły) są raportowane w `anomalie[]` i **nie** są przypisywane do żadnej
sesji na siłę.

## Wyjście — raport JSON

Etap 0 zwraca raport jako `payload.report` w odpowiedzi do orkiestratora oraz
zapisuje go do katalogu wynikowego jako `etap0-raport.json`.

Przykład raportu: `examples/etap0-examples/etap0-raport.md`.

Dopuszczalne wartości `etapy[].status`: `not_started`, `in_progress`, `done`,
`aborted`, `skipped`.

Pole `katalogi_wynikowe[].numer` to `N` z nazwy katalogu. Orkiestrator wylicza
z niego numer kolejnego katalogu jako **największy znaleziony + 1** (patrz
"Katalog wynikowy" w `orkiestrator.md`) — Etap 0 sam niczego nie numeruje
i niczego nie tworzy.

Jeśli nie znaleziono **żadnego** katalogu wynikowego, raport ma tę samą
strukturę, z pustymi tablicami i `konfiguracja.plik_istnieje: false`. Brak
poprzednich sesji nie jest błędem i nie zmienia dalszego przebiegu — patrz
"Etap 0 i wznowienie sesji" w `orkiestrator.md`.

## Log Etapu 0

Etap 0 nie prowadzi własnego pliku logu — jego przebieg odnotowuje orkiestrator
w `orkiestrator-log.md` (zlecenie, czas wykonania, ścieżka raportu, liczba
wykrytych sesji). Powód: Etap 0 wykonuje agent w osobnym kontekście, a raport
JSON jest kompletnym śladem tego, co znalazł.
