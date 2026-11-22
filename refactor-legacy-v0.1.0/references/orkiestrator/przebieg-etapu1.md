# Orkiestrator — Przebieg Etapu 1 (Characterization + Seams)
<!-- wersja-harnessu: 0.1.2 -->

Wczytaj przed `stage.start` Etapu 1. Orkiestrator prowadzi Etap 1 według tego
pliku. Konfiguracja wstępna przychodzi do agentów w `payload.config` — Etap 1
jej nie zbiera.

Cel etapu: umożliwić bezpieczne wprowadzenie zmiany poprzez objęcie fragmentu
testem charakteryzującym (characterization test — dokumentuje **aktualne**
zachowanie kodu, niezależnie od tego, czy jest ono poprawne) oraz odsprzęgnięcie
(decoupling) zależności blokujących testowalność.

## Agenci etapu

| Agent | Plik | Rola |
|---|---|---|
| `etap1-analiza` | `.claude/agents/etap1-analiza.md` | Rozpoznanie testów, podział na iteracje, analiza iteracji, rozkaz dla implementacji, decyzja o końcu etapu |
| `etap1-implementacja` | `.claude/agents/etap1-implementacja.md` | Wykonanie rozkazu jednej iteracji: test charakteryzujący i seam |

Agenci nie wywołują się nawzajem. Między nimi stoi orkiestrator, który steruje
przepływem, i użytkownik, który akceptuje każdy krok (quality gate).

Każde wywołanie agenta kończy się **jedną** wiadomością do orkiestratora,
zapisaną w `komunikacja/`. Agent nie czeka na odpowiedź użytkownika — odpowiedź
przychodzi w kolejnym wywołaniu.

## Przebieg etapu

1. Orkiestrator → `etap1-analiza`: `stage.start`.
   Agent rozpoznaje istniejące testy, dzieli zakres na iteracje, zapisuje
   `etap1-plan.md` i zwraca `user.approval` z `payload.rodzaj` = `podzial`:
   liczba iteracji i gotowość do iteracji 1.
2. Orkiestrator pokazuje podział użytkownikowi. Akceptacja → `stage.resume` do
   `etap1-analiza`. Uwagi → `stage.resume` z uwagami; agent poprawia podział
   i wraca do punktu 1.
3. `etap1-analiza` analizuje iterację N i zwraca `user.approval` z
   `payload.rodzaj` = `plan` i `payload.rozkaz` (dokładne polecenia dla
   implementacji).
4. Orkiestrator pokazuje plan iteracji użytkownikowi. Akceptacja →
   `impl.start` do `etap1-implementacja` z `payload.rozkaz` bez zmian. Uwagi →
   `stage.resume` z uwagami do `etap1-analiza`; agent poprawia rozkaz.
5. `etap1-implementacja` wykonuje rozkaz i zwraca `user.approval` z
   `payload.rodzaj` = `wynik`.
6. Orkiestrator pokazuje wynik użytkownikowi. Akceptacja → `stage.resume` do
   `etap1-analiza`; agent dopisuje iterację do `wykonane` i przechodzi do
   iteracji N+1 (punkt 3) albo, po ostatniej iteracji, zwraca `stage.done`.
   Uwagi → `stage.resume` z uwagami do `etap1-implementacja`; agent poprawia
   wynik i wraca do punktu 5.

Request `user.input` od któregokolwiek agenta: orkiestrator odsyła odpowiedź
użytkownika `stage.resume` do agenta, który wysłał request (`from` requestu).
Adresaci i pola: `references/orkiestrator/protokol-komunikacji.md`, sekcja
"Adresat `stage.resume` w Etapie 1".

Gdy rozpoznanie wykaże pełne testy, podział ma 0 iteracji. Po akceptacji
podziału `etap1-analiza` zwraca `stage.done`.

Użytkownik może przerwać w dowolnym momencie, bez uzasadnienia → orkiestrator
odnotowuje to w logu orkiestratora, wysyła `stage.abort` do `etap1-analiza`
i zatrzymuje kolejkę.

## Plik planu a ramka

- `etap1-plan.md` zawiera **tylko ogólny opis** planowanych kroków: rozpoznanie
  testów, lista iteracji z fragmentem i krótkim celem, status iteracji.
- Dokładne polecenia dla implementacji idą **ramką**: `payload.rozkaz`
  w wiadomości `etap1-analiza`. Pola rozkazu: `.claude/agents/etap1-analiza.md`,
  sekcja "Rozkaz dla implementacji".

Przykład: `examples/orchestrator-examples/etap1-rozkaz.md`.
