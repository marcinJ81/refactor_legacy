# Przykład — Kontrakt dla Step 2 — `step1-zmiany-N.json`

Sekcja: `.claude/agents/etap1/step1.md` → „Wyjście — pliki wytworzone przez Step 1” → „Plik `step1-zmiany-N.json` — kontrakt dla Step 2”.

## Plik — komplet pól

```json
{
  "etap": "etap1",
  "krok": "step1",
  "iteracja": 2,
  "zmiany": [
    {
      "id": "zm-1",
      "kolejnosc": 1,
      "plik": "src/Orders/OrderCalculator.cs",
      "zakres": "CalculateOrderTotal, linie 42-88",
      "typ": "seam",
      "technika": "Replace Function with Function Pointer",
      "opis": "Wstrzyknąć konstruktorem Func<DateTime> domyślnie wskazujący DateTime.Now"
    },
    {
      "id": "zm-2",
      "kolejnosc": 2,
      "plik": "tests/Orders/OrderCalculatorTests.cs",
      "zakres": "nowy plik testowy",
      "typ": "test",
      "technika": "",
      "opis": "Test charakteryzujący CalculateOrderTotal dla 4 przypadków z sekcji 4"
    }
  ],
  "liczba_zmian": 2
}
```
