# Przykład — Etap 2 pyta użytkownika (`user.input` → `stage.resume`)
<!-- wersja-harnessu: 0.1.1 -->

Sekcja orkiestratora: „Protokół komunikacji orkiestrator ↔ etapy” → „Katalog akcji”.

Request z Etapu 2:

```json
{
  "msg_id": "e2-k2-004",
  "corr_id": null,
  "type": "request",
  "from": "etap2",
  "to": "orkiestrator",
  "action": "user.input",
  "status": "needs_user",
  "user_message": "Nie rozpoznano znaczenia literałów: 7 (OrderService.cs:112), 30 (OrderService.cs:140), \"X1\" (OrderService.cs:155). Podaj, czym są.",
  "payload": {
    "literaly": [
      { "wartosc": "7", "miejsce": "OrderService.cs:112" },
      { "wartosc": "30", "miejsce": "OrderService.cs:140" },
      { "wartosc": "\"X1\"", "miejsce": "OrderService.cs:155" }
    ]
  },
  "timestamp": "<data>"
}
```

Dispatch orkiestratora do Etapu 2 po odpowiedzi użytkownika:

```json
{
  "msg_id": "orc-014",
  "corr_id": "e2-k2-004",
  "type": "dispatch",
  "from": "orkiestrator",
  "to": "etap2",
  "action": "stage.resume",
  "status": "in_progress",
  "user_message": "",
  "payload": {
    "user_answer": "7 = liczba dni zwrotu, 30 = termin płatności w dniach, X1 = kod klienta hurtowego"
  },
  "timestamp": "<data>"
}
```
