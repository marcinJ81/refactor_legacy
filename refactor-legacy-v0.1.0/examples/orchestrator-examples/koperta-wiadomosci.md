# Przykład — Koperta wiadomości
<!-- wersja-harnessu: 0.1.1 -->

Sekcja orkiestratora: „Protokół komunikacji orkiestrator ↔ etapy” → „Koperta wiadomości”.

```json
{
  "msg_id": "e2-k2-004",
  "corr_id": null,
  "type": "request | dispatch | event",
  "from": "etap2",
  "to": "orkiestrator",
  "action": "user.input",
  "status": "blocked | in_progress | done | failed | needs_user",
  "user_message": "Nie rozpoznano znaczenia 3 literałów. Podaj, czym są.",
  "payload": { },
  "timestamp": "<data i godzina>"
}
```
