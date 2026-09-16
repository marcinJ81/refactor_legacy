# Przykład — Koperta wiadomości

Sekcja orkiestratora: „Protokół komunikacji orkiestrator ↔ etapy i kroki” → „Koperta wiadomości (wspólna dla wszystkich typów)”.

## Koperta — komplet pól

```json
{
  "msg_id": "e2-k1-003",
  "corr_id": "e2-k1-002",
  "type": "request | dispatch | response | event",
  "from": "etap2",
  "to": "orkiestrator",
  "action": "test.update",
  "status": "blocked | in_progress | done | failed | needs_user",
  "requires_user_ack": true,
  "user_message": "Po zmianie nazwy metody 3 testy świecą na czerwono. Aktualizuję je teraz — wyłącznie nazwy.",
  "payload": { },
  "timestamp": "<data i godzina>"
}
```
