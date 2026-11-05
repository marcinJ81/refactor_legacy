# Przykład — Stan iteracji (`payload.stan_iteracji`)
<!-- wersja-harnessu: 0.1.1 -->

Plik: `references/orkiestrator/protokol-komunikacji.md`, sekcja „Stan iteracji”.

Etap 2 wysyła plan drugiej iteracji:

```json
{
  "msg_id": "e2-i2-001",
  "corr_id": null,
  "type": "request",
  "from": "etap2",
  "to": "orkiestrator",
  "action": "user.approval",
  "status": "needs_user",
  "user_message": "Plan iteracji 2 jest w etap2-plan.md. Czy akceptujesz?",
  "payload": {
    "rodzaj": "plan",
    "stan_iteracji": {
      "iteracja": 2,
      "iteracje_planowane": 3,
      "zakres_pozostaly": ["OrderService.Calculate", "OrderService.Save"],
      "wykonane": [
        { "iteracja": 1, "techniki": ["F16", "F01"], "pliki": ["OrderService.cs"] }
      ],
      "sekwencja_pozostala": ["F13", "F14"],
      "pozycje_otwarte": []
    }
  },
  "timestamp": "<data>"
}
```
