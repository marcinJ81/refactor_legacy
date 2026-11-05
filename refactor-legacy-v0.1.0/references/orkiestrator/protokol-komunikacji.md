# Orkiestrator — Protokół komunikacji orkiestrator ↔ etapy
<!-- wersja-harnessu: 0.1.1 -->

Sekcja wyniesiona z `orkiestrator.md` („Protokół komunikacji orkiestrator ↔ etapy”).

Etapy nie zwracają już samego "sukces / porażka". Każde zakończenie etapu,
każde przerwanie i każda potrzeba decyzji lub informacji od użytkownika jest
**wiadomością w formacie JSON**, niosącą komplet informacji potrzebny
odbiorcy bez dopytywania. Orkiestrator nie przekazuje etapom zadań zleconych
przez inne etapy.

## Koperta wiadomości (wspólna dla wszystkich typów)

Wzór koperty: `examples/orchestrator-examples/koperta-wiadomosci.md`.

- `msg_id` — unikalny identyfikator wiadomości.
- `corr_id` — `msg_id` wiadomości, na którą ta odpowiada (`null` dla nowej).
- `user_message` — dokładna treść do pokazania użytkownikowi; nie może być
  pusta dla `user.input`, `user.approval` i `stage.aborted`.

## Katalog akcji

**Etap → orkiestrator (`type: "request"` / `"event"`):**

| `action` | Znaczenie |
|---|---|
| `user.input` | Potrzebna informacja od użytkownika (np. znaczenie literału, technika spoza tabeli Feathersa) |
| `user.approval` | Plan lub wynik iteracji czeka na akceptację; `payload.rodzaj` = `plan` albo `wynik` |
| `stage.done` | Etap zakończony |
| `stage.aborted` | Użytkownik przerwał iterację/etap |
| `error.critical` | Sytuacja blokująca dalsze działanie |

**Orkiestrator → etap (`type: "dispatch"`):**

| `action` | Znaczenie |
|---|---|
| `stage.start` | Uruchom etap; `payload.config` = konfiguracja wstępna; przy wznowieniu także `payload.stan_iteracji` z pola `wznowienie.stan_iteracji` raportu Etapu 0 |
| `stage.resume` | Wznów etap po requeście `corr_id`; `payload.user_answer` = odpowiedź użytkownika; `payload.stan_iteracji` = pole z requestu, bez zmian |
| `stage.abort` | Zakończ etap (decyzja użytkownika lub critical error) |

Przykład `user.input` → `stage.resume`: `examples/orchestrator-examples/etap2-pyta-uzytkownika.md`.

## Stan iteracji (`payload.stan_iteracji`)

Koperta jest też zapisem ostatniego stanu etapu. Ramka to ostatnia wiadomość
etapu z polem `payload.stan_iteracji`. Wznowienie zaczyna od ramki: w najgorszym
przypadku powtarzana jest jedna iteracja, a nie cały etap.

Przykład pola: `examples/orchestrator-examples/stan-iteracji.md`.

- **Etap** dołącza pole do każdej wiadomości (`user.input`, `user.approval`,
  `stage.done`, `stage.aborted`), od chwili ustalenia podziału zakresu na
  iteracje.
- **Orkiestrator** odsyła pole bez zmian w `stage.resume` i nie interpretuje go.
- **Przy wznowieniu** Etap 0 odczytuje ramkę z `komunikacja/` i podaje ją w polu
  `wznowienie` raportu (patrz "Ostatnia ramka" w `etap0.md`). Orkiestrator nie
  czyta `komunikacja/`, tylko przekazuje `wznowienie.stan_iteracji` w
  `stage.start`. Wartość `null` oznacza start etapu od początku.
- **Etap po `stage.start` z polem** nie powtarza iteracji z `wykonane`. Iterację
  z pola `iteracja` wykonuje od analizy, a najpierw sprawdza kod i testy, bo
  zmiany z przerwanej iteracji mogą już być w kodzie.

Pola:

| Pole | Znaczenie |
|---|---|
| `iteracja` | Numer bieżącej iteracji |
| `iteracje_planowane` | Aktualna planowana liczba iteracji |
| `zakres_pozostaly` | Części zakresu jeszcze nieobjęte, łącznie z bieżącą iteracją |
| `wykonane` | Iteracje potwierdzone przez użytkownika: numer, techniki, pliki |
| `sekwencja_pozostala` | Techniki rozpoczętej sekwencji do wykonania; pusta lista, gdy nie ma takich |
| `pozycje_otwarte` | Pozycje czekające na rozstrzygnięcie |

Pliki konfiguracji i logów etap czyta z dysku. `refactor-decisions.md` wczytuje
przed każdą iteracją, a numer następnego wpisu logu odczytuje z logu.

## Zapis wiadomości

Każda wiadomość zapisywana jest jako osobny plik w podkatalogu `komunikacja/`
katalogu wynikowego, w formacie
`<NNN>-<from>-<action>.json` (numeracja chronologiczna). Daje to pełny audyt
przepływu, niezależny od logów decyzji.
