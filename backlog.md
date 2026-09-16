# Backlog — pozycje niezaimplementowane

Stan na 2026-09-15. Źródło: `v0.1.0/v0.1.0/changes.md`, `v0.1.0/v0.1.0/changes_test.md`, `v0.2.0/v0.2.0/changes2.md`
skonfrontowane z plikami harnessu (`refactor-legacy-v0.1.0/` = v1, `refactor-legacy-v0.2.0/` = v2).

Statusy:
- 🔴 **niewprowadzony** — wpis użytkownika bez adnotacji „wprowadzono"
- 🚧 **w budowie** — sekcja istnieje w harnessie, ale jest tylko zaznaczona (zgodnie z poleceniem)
- ⏳ **odłożone** — użytkownik świadomie przesunął na kolejną iterację
- ❓ **do decyzji użytkownika** — pytanie/wątpliwość zgłoszona w adnotacji, bez odpowiedzi
- ✅ **wprowadzone** — pozycja zamknięta w harnessie

---

## A. Orkiestrator (v2)

| # | Pozycja | Status | Źródło | Gdzie w harnessie |
|---|---|---|---|---|
| A1 | **Stan orkiestratora kluczowany własnym task/run ID**, nie `session_id` Claude Code — `/clear` zmienia session ID, więc stan kluczowany nim ginie po wyczyszczeniu kontekstu. Użytkownik: „zastanowić się nad tym". | 🔴 | `changes_test.md`, ostatni wpis; potwierdzone jako niewprowadzone w `changes2.md` (wpis 1) | nigdzie |
| A2 | **Odporność harnessu na częste resetowanie kontekstu przez użytkownika** — harness ma zawsze dawać modelowi i agentom właściwe informacje zgodne z konfiguracją, niezależnie od tego, ile razy użytkownik zrobi `/clear`. | 🔴 | `changes_test.md`, ostatni wpis | nigdzie (częściowo pokrywa się z A1 i z regułą 4 h) |
| A3 | **Brak zachowania, gdy automatyczny `/clear` jest technicznie niemożliwy** — po usunięciu ścieżki ręcznej została jedna droga wyjścia z Etapu 0; jeśli harness nie może sam wywołać `/clear`, orkiestrator idzie dalej z kontekstem pełnym raportu Etapu 0 albo staje bez zdefiniowanego zachowania. Odłożone do iteracji A1. | ❓ | `changes2.md`, adnotacja wpisu 2, pkt 4 | `orkiestrator.md` (v2) — brak wariantu zapasowego |
| A4 | **Konfiguracja bez pytań wstępnych** — gotowy `refactor-config.json` podstawiony z zewnątrz zastępuje Pytanie T i Pytania 0–2. Format już jest, ale orkiestrator nadal pyta. Do rozstrzygnięcia: co wtedy z wymogiem jawnego wyboru użytkownika (`zrodlo` ≠ `domyslne`). | ⏳ | `changes_test.md` (odpowiedzi, „dodatkowy plik json z dedykowaną konfiguracją harnesa") | `orkiestrator.md` (v2) → „Odłożone do kolejnych iteracji" |
| A5 | **Ścieżki inne niż happy path** — nieudany quality gate kroku, powrót iteracji do Step 1, korekta liczby iteracji w dół po rozpoczęciu przebiegu. Użytkownik: „na razie idziemy happy path". | 🚧 | `changes2.md`, wpis 4 | `orkiestrator.md` (v2) → „Status dokumentu", pętla sterowania 4a–4d |
| A6 | **Pliki etapów, do których v2 orkiestrator się odwołuje, nie istnieją w v2**: `etap0.md`, `etap2.md`, `etap3.md` (tabela struktury harnessu, krok 3 pętli sterowania, brama wejściowa). Są tylko w v1. Do decyzji: port do v2 czy wskazanie na v1. | ❓ | pochodna wpisu „został stworzony nowy katalog refactor-legacy-v2" (`changes2.md`) — użytkownik kazał ruszać tylko `etap1` | `refactor-legacy-v0.2.0/orkiestrator.md` linie 46–50, 231, 337–342 |
| A7 | **Los `refactor-legacy-v0.2.0/etap1/etap1.md`** (źródło podziału na step1/step2) — zostawić, usunąć, oznaczyć deprecated? | ❓ | `changes2.md`, adnotacja wpisu 3 („Czego nie zrobiłem") | plik nadal jest, nietknięty |
| A8 | **Wygaszenie v1 (`refactor-legacy-v0.1.0/`)** — w v1 nadal obowiązuje `refactor-decisions.md`, stara reguła buildów i reguła 4 h tylko w orkiestratorze. Dwie równoległe wersje harnessu. | ❓ | `changes2.md`, adnotacja wpisu 4 („Czego nie zmieniałem") | `refactor-legacy-v0.1.0/` |

## B. Etap 1 (v2) — Step 1 / Step 2

| # | Pozycja | Status | Źródło | Gdzie w harnessie |
|---|---|---|---|---|
| B1 | **Quality gate Step 1** — wprowadzone w v0.2.1: sprawdzane pliki / sekcje / struktura JSON / licznik zmian, sprawdza orkiestrator skryptami `scripts/step1/*.ps1`, werdykt w `quality-gate-step1-analize-result/iteracja-N/`, przy `failed` jedno ponowienie Step 1. Otwarta została wyłącznie mechanika ponowienia → B5. | ✅ | `changes2.md`, wpis 3; `v0.2.0/v0.2.1/changes.md` | `etap1/step1.md` → „Quality gate Step 1”; `orkiestrator.md` → „Bramy kroków (Etap 1)” |
| B2 | **Obsługa błędu quality gate Step 2** (nie buduje się / czerwone testy). Do rozstrzygnięcia: samodzielna naprawa i limit prób, powrót do Step 1, rollback, rozdzielenie „błąd kompilacji" od „czerwony test", jaka wiadomość idzie do orkiestratora. Na razie: log + zgłoszenie + stop. | 🚧 | `changes2.md`, wpis 3 („jeżeli pojawi się błąd po kroku drugim… oznacz w budowie") | `etap1/step2.md` → „Obsługa błędu quality gate *(w budowie)*" |
| B3 | **Przydział trybu zadaniowego `task.execute` do bramy Step 2** — tryb zadaniowy trafił do Step 2, ale nie przechodzi przez Step 1 i nie ma pliku wejściowego; czy podlega quality gate Step 2 — nierozstrzygnięte. | 🚧 | `changes2.md`, adnotacja wpisu 3, pkt 4 | `etap1/step2.md` → „Tryb zadaniowy", ramka „Przydział kroku" |
| B5 | **Zachowanie przy ponowieniu Step 1 po negatywnym quality gate** — rozstrzygnięte w v0.2.1: przy `failed` orkiestrator uruchamia `scripts/step1/eraser/00-eraser.ps1` (kasuje komplet plików bramy tej iteracji razem z katalogiem `iteracja-N/`), odnotowuje zużycie ponowienia dla pary (krok, iteracja) w `refactor-session.md` i logu, ponawia Step 1 z tym samym numerem iteracji; drugi `failed` = przerwanie i notyfikacja. Pliki Step 1 nadpisuje ponowiony krok. | ✅ | `v0.2.0/v0.2.1/changes-step.md`, zadania 5 i 4 | `orkiestrator.md` → „Bramy kroków (Etap 1)”, pętla 4b'; `etap1/step1.md` → „Wynik negatywny”; `scripts/step1/eraser/00-eraser.ps1` |
| B4 | **Testy harnessu dla kroków** — użytkownik: „taka budowa pozwoli wprowadzić testy w łatwiejszy sposób, ale testami na razie się nie zajmujemy". Zapisane tylko, że wymiana krok↔krok to pojedynczy JSON, więc da się mockować. | ⏳ | `changes2.md`, wpis 4 | `orkiestrator.md` (v2) → tabela odstępstw trybu `test` (wiersz o mockowaniu kroków) |
| B6 | **Usuwanie plików quality gate po każdej iteracji** — dziś eraser czyści katalog `quality-gate-step1-analize-result/iteracja-N/` tylko przed ponowieniem po `failed`; wyniki iteracji zaliczonych zostają na dysku. Do rozważenia: kasować je również po zamknięciu każdej iteracji (mniej śmieci vs. utrata śladu, po którym orkiestrator poznaje, które iteracje przeszły bramę). | ❓ | `v0.2.0/v0.2.1/changes-step.md`, zadanie 5 | `scripts/step1/eraser/00-eraser.ps1`; `orkiestrator.md` → „Bramy kroków (Etap 1)” |

## C. Etap 2

| # | Pozycja | Status | Źródło | Gdzie w harnessie |
|---|---|---|---|---|
| C1 | **Wariant „Zmiana logiki"** — jest tylko krok wejściowy (użytkownik opisuje zakres, granice, sedno problemu), etap zatrzymuje się po zebraniu opisu. Użytkownik: „tę opcję na razie zostawiamy z dopiskiem w budowie". | 🚧 | `changes.md`, wpis 1 | `refactor-legacy-v0.1.0/etap2.md` (v1) → „Wariant Zmiana logiki *(w budowie)*"; w v2 brak `etap2.md` |
| C2 | **Podstawa metodyczna Etapu 2** — podział użytkownika: refaktor → Fowler + clean architecture Uncle Boba; wprowadzanie zmian → SOLID, KISS, DRY, YAGNI, czysty kod. „Nie ma gdzie trafić" — w v2 nie ma `etap2.md`. Zapisane w adnotacji, do wpisania przy pracy nad Etapem 2. | 🔴 | `changes2.md`, wpis 4 | nigdzie (tylko adnotacja w `changes2.md`) |
| C3 | **Kolejne kroki wariantu „Refaktor" po Kroku 3** (Przerwanie zależności) — placeholder „do zdefiniowania". Użytkownik nie podał jeszcze treści. | 🚧 | `changes.md` (placeholder po wpisie 1, potem kroki 2 i 3) | `refactor-legacy-v0.1.0/etap2.md` (v1) → „Kolejne kroki *(do zdefiniowania)*" |

## D. Etap 3

| # | Pozycja | Status | Źródło | Gdzie w harnessie |
|---|---|---|---|---|
| D1 | **Etap 3 — pusty plik** (nagłówek + warunek uruchomienia). Użytkownik: „etap 3 pusty plik"; w trybie test warunek 5 bramy wejściowej przechodzi dla Etapu 3 zawsze, dopóki plik jest pusty. | 🚧 | `changes.md`, wpis 2; `changes_test.md`, odp9 | `refactor-legacy-v0.1.0/etap3.md` (v1, 21 linii); w v2 brak pliku |

## E. Tryb testowy orkiestratora (piramida testów harnessu)

| # | Pozycja | Status | Źródło | Gdzie w harnessie |
|---|---|---|---|---|
| E1 | **Format i adresowanie mocków + ich katalog** — po czym orkiestrator dobiera mock do dispatchu (`to`+`action` / kolejność w scenariuszu / `corr_id`), gdzie mocki fizycznie leżą (propozycja: stały `mocki/`, kopiowane do katalogu przebiegu po użyciu). Zapisana tylko zasada „brak mocka = twardy błąd". | ⏳ | `changes_test.md`, odp8 / P8 | `orkiestrator.md` (v2) → „Odłożone do kolejnych iteracji" |
| E2 | **Osobny orkiestrator testowy** — dokument bazujący na właściwym, trzymający instrukcje testowe, żeby środowisko testowe nie przenikało do „produkcyjnego". | ⏳ | `changes_test.md`, odp8 | j.w. |
| E3 | **Sterowanie czasem i dane wejściowe test case'ów** — sprawdzenie obu gałęzi reguły 4 h bez czekania (np. podstawiony `refactor-session.md` z zadanym znacznikiem). Powiązana wątpliwość: reguła 4 h w trybie test działa bez zmian i przy ręcznym przebiegu rozłożonym w czasie może uznać przebieg za nową sesję. | ⏳ | `changes_test.md`, odp5 (C5) | j.w. |
| E4 | **Mockowanie interakcji użytkownika** (Pytania 0–2, `user.approval`, `user.input`) — warunek pełnej automatyzacji przebiegu. Na razie obsługuje człowiek. | ⏳ | `changes_test.md`, odp6 (C6) | j.w. + tabela odstępstw trybu `test` |
| E5 | **System ocenny / werdykt** — pojęcie „przebieg oczekiwany vs. faktyczny", plik z werdyktem. Na razie ocenia człowiek na podstawie `orkiestrator-log.md` i `komunikacja/*.json`. | ⏳ | `changes_test.md`, odp10 (C10) | j.w. |
| E6 | **Test `/clear` w trybie test** — pominięcie (wtedy nie testujemy zabezpieczenia przed zapętleniem) czy dwa przebiegi (przed/po `/clear`, drugi startuje z podstawionego `refactor-session.md`). Użytkownik: „do tego wrócimy jeszcze". Na razie `/clear` jest tylko oznaczany jako wykonany. | ⏳ | `changes_test.md`, odp4 (C4) | `orkiestrator.md` (v2) → tabela odstępstw trybu `test` |
| E7 | **Kto tworzy paczkę mocka** — czy komplet plików podkłada scenariusz przed przebiegiem, czy orkiestrator kopiuje je z katalogu mocków w momencie podstawienia. Zależy od E1. | ❓ | `changes_test.md`, adnotacja końcowa („Gdzie widzę wątpliwości") | nigdzie |
| E8 | **Poziom 2 piramidy — testy etapów** (w tym osobny test Etapu 0, rozbity na test samego etapu i test orkiestratora z gotowym JSON-em). Użytkownik: „to jest kolejna część mojej piramidy testów". | ⏳ | `changes_test.md`, odpowiedzi na P7 | nigdzie |

---

## Rozstrzygnięte po drodze (poza backlogiem)

Dla porządku — pozycje, które w adnotacjach były otwarte, a zostały zamknięte
późniejszym wpisem:

- Stary monolit `refactor-legacy.md` → zostaje, przemianowany na `_depracated` (`changes.md`).
- „legacy-skill" = katalog wynikowy harnessu (`changes.md`).
- Sposób przekazania sterowania Step 1 → Step 2 → przez orkiestratora, kroki się nie widzą (`changes2.md`, wpis 4).
- Kolizja „quality gate Step 2 wymaga builda" vs „zakaz buildów" → build/testy domyślnie automatyczne, opcja ręczna (`changes2.md`, wpis 4).
- Ręczny `/clear` przez użytkownika → usunięty; reguła 60 min → 4 h (`changes2.md`, wpis 2).
- Nazwy katalogów (`refactor-resultN` / `refactor-result-testN`), tryb `normalny`/`test`, Pytanie T, Etap 0 mockowany w trybie test (`changes_test.md`).
- Wątpliwość „pierwsza prawdziwa sesja może wylądować w `refactor-result2`" → użytkownik odpowiedział (po Etapie 0 `/clear` + nowa sesja, Etap 0 się nie powtarza) — ale bez zmiany w harnessie; jeśli ma to być zapisane, wraca jako część A1/A2.

## Sugerowana kolejność

1. **A1 + A2 + A3** — jedna iteracja: stabilny run ID, odporność na `/clear`, zachowanie gdy `/clear` niemożliwy. Wszystkie trzy dotyczą tego samego mechanizmu i użytkownik sam je powiązał.
2. **A6** — bez `etap0.md`/`etap2.md`/`etap3.md` w v2 orkiestrator v2 nie da się uruchomić w całości.
3. **B1, B2, B3** — domknięcie Etapu 1 v2 (bramy i ścieżki błędu), potem **A5**.
4. **C2 → C1, C3** — Etap 2 w v2 (najpierw wpisać podstawę metodyczną, którą użytkownik już podał).
5. **E1 → E7 → E2** — tryb testowy: format mocków odblokowuje resztę.
6. **A4, B4, E3–E6, E8, D1, A7, A8** — dalsze.
