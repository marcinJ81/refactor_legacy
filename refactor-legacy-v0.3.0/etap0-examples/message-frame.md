# Przykład — Ramka wiadomości
<!-- wersja-harnessu: 0.3.0 -->

Model ramki: `references/frame-model.md` — jedna ramka dla wszystkich
wiadomości, także dla ramki startowej orkiestratora i odpowiedzi Etapu 0.
Ramki Etapu 0 leżą w `communication/`.

## Ramka startowa — orkiestrator → Etap 0
Kontrakt `Orkiestrator.SendStartEtap0` (`orkiestrator.md`):
```json
{
  "msg_id": "001",
  "corr_id": null,
  "from": "orchestrator",
  "to": "stage0",
  "action": "stageStart",
  "status": "done",
  "payload": { },
  "timestamp": "2026-10-20T10:11:00+02:00"
}
```

## Ramka `done` — jest poprzednia sesja
Plik `refactor-result2/communication/032-etap0-message-frame.json`.
`files` — pliki wygenerowane w poprzedniej sesji (ścieżki względne do `refactor-resultN`):
```json
{
  "msg_id": "032",
  "corr_id": "001",
  "from": "stage0",
  "to": "orchestrator",
  "action": "stageDone",
  "status": "done",
  "payload": {
    "files": [
      "communication/002-etap0-message-frame.json",
      "communication/003-stage1part1-stageStart.json",
      "orkiestrator-log.md",
      "refactor-config.json"
    ],
    "directories": [ "communication" ]
  },
  "timestamp": "2026-10-20T10:11:01+02:00"
}
```

## Ramka `done` — brak poprzedniej sesji
Plik `refactor-result1/communication/002-etap0-message-frame.json`
(numer 001 ma ramka startowa orkiestratora):
```json
{
  "msg_id": "002",
  "corr_id": "001",
  "from": "stage0",
  "to": "orchestrator",
  "action": "stageDone",
  "status": "done",
  "payload": { "directories": [ "communication" ] },
  "timestamp": "2026-10-20T10:11:01+02:00"
}
```

## Ramka `failed` — zapisuje hook `.claude/hooks/etap0-start.ps1`
Plik `refactor-result1/communication/002-etap0-message-frame.json`:
```json
{
  "msg_id": "002",
  "corr_id": "001",
  "from": "stage0",
  "to": "orchestrator",
  "action": "stageDone",
  "status": "failed",
  "payload": {
    "error": "Nie znaleziono skryptu rozpoznania: C:/projekty/sklep/.claude/refactor-legacy/scripts/etap0/00-rozpoznanie.ps1"
  },
  "timestamp": "2026-10-20T10:11:01+02:00"
}
```

## Ramka `failed` bez pliku — zwraca agent, gdy hook nie zapisał ramki
Kontrakt `FailedFrame` (`references/contracts.md`):
```json
{
  "msg_id": "002",
  "corr_id": "001",
  "from": "stage0",
  "to": "orchestrator",
  "action": "stageDone",
  "status": "failed",
  "payload": {
    "error": "Hook startu Etapu 0 nie przekazał podsumowania"
  },
  "timestamp": "2026-10-20T10:11:01+02:00"
}
```
