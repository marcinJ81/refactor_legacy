# Przykład — Koperta wiadomości
<!-- wersja-harnessu: 0.3.0 -->

Sekcja: `.claude/agents/etap0.md` → „Koperta wiadomości". Wspólna dla
wszystkich ramek zapisywanych w `communication/`.

## Koperta — komplet pól

```json
{
  "msg_id": "e0-001",
  "corr_id": null,
  "from": "etap0",
  "to": "orkiestrator",
  "action": "stage.done",
  "status": "in_progress | done | failed | blocked",
  "payload": { },
  "timestamp": "2026-10-20; 10-15-02"
}
```

## Ramka `done` — jest poprzednia sesja
Plik `refactor-result2/communication/032-etap0-message-frame.json`
(komplet pól raportu — `etap0-examples/etap0-raport.md`):
```json
{
  "msg_id": "e0-032",
  "corr_id": null,
  "from": "etap0",
  "to": "orkiestrator",
  "action": "stage.done",
  "status": "done",
  "payload": {
    "report": {
      "schema": "etap0-raport/2",
      "aktywny_katalog": "refactor-result2",
      "konfiguracja": { "plik_istnieje": true, "kompletna": true },
      "etapy": [ { "etap": 2, "status": "in_progress" } ]
    }
  },
  "timestamp": "2026-10-20; 10-11-01"
}
```

## Ramka `done` — brak poprzedniej sesji
Plik `refactor-result1/communication/001-etap0-message-frame.json`:
```json
{
  "msg_id": "e0-001",
  "corr_id": null,
  "from": "etap0",
  "to": "orkiestrator",
  "action": "stage.done",
  "status": "done",
  "payload": { },
  "timestamp": "2026-10-20; 10-11-01"
}
```

## Ramka `failed` — zapisuje hook `.claude/hooks/etap0-start.ps1`

Plik `refactor-result1/communication/001-etap0-message-frame.json`:
```json
{
  "msg_id": "e0-001",
  "corr_id": null,
  "from": "etap0",
  "to": "orkiestrator",
  "action": "stage.done",
  "status": "failed",
  "payload": {
    "error": "Nie znaleziono skryptu rozpoznania: C:/projekty/sklep/.claude/refactor-legacy/scripts/etap0/00-rozpoznanie.ps1"
  },
  "timestamp": "2026-10-20; 10-11-01"
}
```

## Ramka `failed` bez pliku — zwraca agent, gdy hook nie zapisał ramki

```json
{
  "msg_id": "e0-brak-pliku",
  "corr_id": null,
  "from": "etap0",
  "to": "orkiestrator",
  "action": "stage.done",
  "status": "failed",
  "payload": {
    "error": "Hook startu Etapu 0 nie przekazał podsumowania"
  },
  "timestamp": null
}
```
