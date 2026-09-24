# Przykład — Request `step.done` — `step1-step-done-N.json`

Sekcja: `.claude/agents/etap1/step1.md` → „Zakończenie kroku — request `step.done`”.

## Request — komplet pól payloadu

Ta sama wiadomość co w `orchestrator-examples/przekazanie-miedzy-krokami-etapu-1.md`, sekcja 1. Zmiana jednego przykładu wymaga zmiany drugiego.

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
