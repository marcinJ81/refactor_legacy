# Przykład — Przekazanie między krokami Etapu 1

Sekcja orkiestratora: „Protokół komunikacji orkiestrator ↔ etapy i kroki” → „Przekazanie między krokami Etapu 1”.

## 1. Step 1 → orkiestrator (`step.done`)

```json
{
  "msg_id": "e1s1-i2-done",
  "corr_id": "orc-021",
  "type": "response",
  "from": "etap1.step1",
  "to": "orkiestrator",
  "action": "step.done",
  "status": "done",
  "requires_user_ack": false,
  "user_message": "",
  "payload": {
    "etap": "etap1",
    "krok": "step1",
    "faza": "analiza",
    "faza_zakonczona": true,
    "iteracje": {
      "biezaca": 2,
      "zaplanowane": 4,
      "podstawa_szacunku": "4 podfragmenty wskazane w analizie zakresu"
    },
    "quality_gate": {
      "status": "nie_wykonany",
      "powod": "brama po stronie orkiestratora — krok nie ocenia sam siebie"
    },
    "pliki": [
      {
        "kolejnosc": 1,
        "nazwa": "step1-zmiany-2.json",
        "sciezka": "refactor-result3/step1-zmiany-2.json",
        "rola": "zmiany do zaimplementowania"
      },
      {
        "kolejnosc": 2,
        "nazwa": "step1-analiza-2.md",
        "sciezka": "refactor-result3/step1-analiza-2.md",
        "rola": "opis analizy"
      }
    ],
    "liczba_zmian": 3,
    "kolejnosc_implementacji": ["zm-1", "zm-2", "zm-3"],
    "poza_zakresem": ["logika rabatów", "warstwa widoku"],
    "nastepny": "etap1.step2"
  },
  "timestamp": "2026-09-09; 11-04-22"
}
```

## 2. Orkiestrator → Step 2 (`step.start`)

```json
{
  "msg_id": "orc-022",
  "corr_id": "e1s1-i2-done",
  "type": "dispatch",
  "from": "orkiestrator",
  "to": "etap1.step2",
  "action": "step.start",
  "status": "in_progress",
  "requires_user_ack": false,
  "user_message": "",
  "payload": {
    "config": { "...": "zawartość refactor-config.json" },
    "wejscie": { "...": "payload z e1s1-i2-done, bez zmian" }
  },
  "timestamp": "2026-09-09; 11-04-40"
}
```

## 3. Step 2 → orkiestrator (`step.done`)

```json
{
  "msg_id": "e1s2-i2-done",
  "corr_id": "orc-022",
  "type": "response",
  "from": "etap1.step2",
  "to": "orkiestrator",
  "action": "step.done",
  "status": "done",
  "requires_user_ack": true,
  "user_message": "Iteracja 2 zamknięta: seam IClock + 4 testy charakteryzujące. Build OK, testy 16/16.",
  "payload": {
    "etap": "etap1",
    "krok": "step2",
    "ukonczono": true,
    "iteracje": { "biezaca": 2, "zaplanowane": 4 },
    "wejscie_wykonane": "step1-analiza-2.md",
    "quality_gate": {
      "status": "passed",
      "build":  { "wynik": "ok", "wykonal": "krok" },
      "testy":  { "wynik": "ok", "przeszlo": 16, "wszystkich": 16, "nowe": 4, "wykonal": "krok" }
    },
    "zmienione_pliki": ["OrderCalculator.cs", "IClock.cs", "OrderCalculatorTests.cs"],
    "nastepny": "etap1.step1"
  },
  "timestamp": "2026-09-09; 11-31-05"
}
```
