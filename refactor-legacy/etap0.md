# Etap 0 — Rozpoznanie stanu (wznowienie sesji)

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
czyli katalog wynikowy w projekcie będącym przedmiotem refaktoryzacji (patrz
"Katalog wynikowy" w `orkiestrator.md`), wraz ze wszystkimi jego wersjami:
`refactor-legacy`, `refactor-legacy-ver2`, `refactor-legacy-ver3`, ...

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

```json
{
  "schema": "etap0-raport/1",
  "generated_at": "2026-08-30; 19-07-12",

  "katalogi_wynikowe": [
    { "sciezka": "refactor-legacy", "wersja": 1, "ostatnia_aktywnosc": "2026-08-29; 14-02-55" },
    { "sciezka": "refactor-legacy-ver2", "wersja": 2, "ostatnia_aktywnosc": "2026-08-30; 18-41-03" }
  ],
  "aktywny_katalog": "refactor-legacy-ver2",

  "konfiguracja": {
    "plik_istnieje": true,
    "sciezka": "refactor-legacy-ver2/refactor-decisions.md",
    "kompletna": true,
    "braki": [],
    "odpowiedzi": {
      "pytanie_0": { "commity": "...", "buildy": "...", "zmiany_bez_planu": "...", "framework_testow": "NUnit", "granulacja": "dynamiczna" },
      "pytanie_1": { "struktura": "A", "plik_szczegolowy": false },
      "pytanie_2": { "zakres": "A", "pominiete": [] }
    }
  },

  "sesje": [
    { "nr": 1, "start": "2026-08-29; 11-30-00", "koniec": "2026-08-29; 14-02-55", "zrodlo": "orkiestrator-log.md" },
    { "nr": 2, "start": "2026-08-30; 17-05-12", "koniec": null, "zrodlo": "orkiestrator-log.md" }
  ],

  "etapy": [
    {
      "etap": 1,
      "status": "done",
      "iteracje": 3,
      "ostatni_wpis_logu": "2026-08-30; 17-58-40",
      "log": "etap1-decisions-log.md",
      "plik_wynikowy": "etap1-plan.md",
      "zaakceptowany_przez_uzytkownika": true
    },
    {
      "etap": 2,
      "status": "in_progress",
      "wariant": "refaktor",
      "ostatni_krok": 2,
      "ostatni_wpis_logu": "2026-08-30; 18-41-03",
      "log": "etap2-decisions-log.md",
      "plik_wynikowy": "etap2-plan.md",
      "zaakceptowany_przez_uzytkownika": false
    },
    { "etap": 3, "status": "not_started" }
  ],

  "requesty_otwarte": [
    { "msg_id": "e2-k2-004", "from": "etap2", "action": "user.input", "wystawiony": "2026-08-30; 18-40-11", "opis": "3 nierozpoznane magic numbers" }
  ],

  "pozycje_otwarte": [
    "etap2-plan.md, sekcja Pozycje otwarte: 3 literały bez ustalonego znaczenia"
  ],

  "sesja_poprzednia": {
    "plik_istnieje": true,
    "etap0_wykonany": "2026-08-30; 18-52-30",
    "kontekst_wyczyszczony": true,
    "kto_wyczyscil": "uzytkownik"
  },

  "anomalie": [
    "etap1-decisions-log.md: wpisy 1-9 bez znaczników czasu (uruchomienie sprzed reguły)"
  ]
}
```

Dopuszczalne wartości `etapy[].status`: `not_started`, `in_progress`, `done`,
`aborted`, `skipped`.

Jeśli nie znaleziono **żadnego** katalogu wynikowego, raport ma tę samą
strukturę, z pustymi tablicami i `konfiguracja.plik_istnieje: false`. Brak
poprzednich sesji nie jest błędem i nie zmienia dalszego przebiegu — patrz
"Etap 0 i wznowienie sesji" w `orkiestrator.md`.

## Log Etapu 0

Etap 0 nie prowadzi własnego pliku logu — jego przebieg odnotowuje orkiestrator
w `orkiestrator-log.md` (zlecenie, czas wykonania, ścieżka raportu, liczba
wykrytych sesji). Powód: Etap 0 wykonuje agent w osobnym kontekście, a raport
JSON jest kompletnym śladem tego, co znalazł.
