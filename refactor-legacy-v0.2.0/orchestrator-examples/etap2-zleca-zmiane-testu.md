# Przykład — Etap 2 zleca zmianę testu Etapowi 1

Sekcja orkiestratora: „Protokół komunikacji orkiestrator ↔ etapy i kroki” → „Przykład: Etap 2 zleca zmianę testu Etapowi 1”.

## 1. Request z Etapu 2 (`test.update`)

```json
{
  "msg_id": "e2-k1-007",
  "corr_id": null,
  "type": "request",
  "from": "etap2",
  "to": "orkiestrator",
  "action": "test.update",
  "status": "blocked",
  "requires_user_ack": true,
  "user_message": "Zmiana nazwy metody CalcTot -> CalculateOrderTotal. Testy czerwone: 3. Aktualizuję w nich wyłącznie nazwy.",
  "payload": {
    "cause": {
      "kind": "rename",
      "element": "method",
      "from": "CalcTot",
      "to": "CalculateOrderTotal"
    },
    "failing_tests": [
      { "test_id": "OrderTests.Total_Sums_Lines", "test_file": "...", "failure": "compile", "message": "..." }
    ],
    "allowed_scope": ["rename_only"],
    "forbidden": ["assert_change", "input_data_change", "test_scope_change"],
    "resume_point": "etap2/wariant-refaktor/krok-1"
  },
  "timestamp": "<data>"
}
```

## 2. Dispatch orkiestratora do Etapu 1 (`task.execute`)

```json
{
  "msg_id": "orc-014",
  "corr_id": "e2-k1-007",
  "type": "dispatch",
  "from": "orkiestrator",
  "to": "etap1",
  "action": "task.execute",
  "status": "in_progress",
  "requires_user_ack": false,
  "user_message": "",
  "payload": {
    "config": { "tryb": "normalny", "framework": "NUnit", "granulacja": "...", "pliki_wynikowe": "A" },
    "task": { "...": "kopia payloadu z e2-k1-007" }
  },
  "timestamp": "<data>"
}
```
