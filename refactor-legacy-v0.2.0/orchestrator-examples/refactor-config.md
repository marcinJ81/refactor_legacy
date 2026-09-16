# Przykład — Konfiguracja przebiegu — `refactor-config.json`

Sekcja orkiestratora: „Konfiguracja wstępna” → „Plik konfiguracji (`refactor-config.json`)”.

## Komplet pól z wartościami dopuszczalnymi (to samo co `refactor-config.example.json`)

```json
{
  "schema": "refactor-legacy/config",
  "schema_version": 1,
  "utworzono": "2026-09-09; 10-12-00",
  "zaktualizowano": "2026-09-09; 10-12-00",

  "projekt": {
    "fragment": "OrderController.ProcessOrder",
    "opis": "wydzielenie kalkulacji zamówienia spod HttpContext"
  },

  "harness": {
    "znacznik_czasu": "yyyy-MM-dd; HH-mm-ss",
    "katalog_wynikowy": "refactor-result3"
  },

  "tryb": { "wartosc": "normalny", "zrodlo": "uzytkownik" },

  "pytanie_0": {
    "commitowanie":     { "wartosc": "reczne",       "zrodlo": "uzytkownik" },
    "build":            { "wartosc": "automatyczny", "zrodlo": "uzytkownik" },
    "testy":            { "wartosc": "automatyczne", "zrodlo": "uzytkownik" },
    "zmiany_bez_planu": { "wartosc": "zabronione",   "zrodlo": "uzytkownik" },
    "framework_testow": { "wartosc": "NUnit",        "zrodlo": "wykryte+potwierdzone" },
    "granulacja":       { "wartosc": "dynamiczna",   "zrodlo": "uzytkownik" }
  },

  "pytanie_1": {
    "struktura_plikow":              { "wartosc": "A",   "zrodlo": "uzytkownik" },
    "plik_szczegolowy_per_iteracja": { "wartosc": false, "zrodlo": "uzytkownik" }
  },

  "pytanie_2": {
    "zakres_etapow": { "wartosc": "A", "zrodlo": "uzytkownik" },
    "pominiete":     []
  }
}
```
