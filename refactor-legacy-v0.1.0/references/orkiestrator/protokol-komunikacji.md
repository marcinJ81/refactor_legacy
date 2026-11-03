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
| `user.input` | Potrzebna informacja od użytkownika (np. znaczenie magic numbera, technika spoza tabeli Feathersa) |
| `user.approval` | Plan gotowy, czeka na akceptację |
| `stage.done` | Etap zakończony |
| `stage.aborted` | Użytkownik przerwał iterację/etap |
| `error.critical` | Sytuacja blokująca dalsze działanie |

**Orkiestrator → etap (`type: "dispatch"`):**

| `action` | Znaczenie |
|---|---|
| `stage.start` | Uruchom etap; `payload.config` = konfiguracja wstępna |
| `stage.resume` | Wznów etap po requeście `corr_id`; `payload.user_answer` = odpowiedź użytkownika |
| `stage.abort` | Zakończ etap (decyzja użytkownika lub critical error) |

Przykład `user.input` → `stage.resume`: `examples/orchestrator-examples/etap2-pyta-uzytkownika.md`.

## Zapis wiadomości

Każda wiadomość zapisywana jest jako osobny plik w podkatalogu `komunikacja/`
katalogu wynikowego, w formacie
`<NNN>-<from>-<action>.json` (numeracja chronologiczna). Daje to pełny audyt
przepływu, niezależny od logów decyzji.
