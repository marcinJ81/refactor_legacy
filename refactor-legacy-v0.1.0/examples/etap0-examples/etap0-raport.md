# Przykład — Raport Etapu 0 — `etap0-raport.json`
<!-- wersja-harnessu: 0.1.1 -->

Sekcja `etap0.md`: „Wyjście — raport JSON”.

```json
{
  "schema": "etap0-raport/1",
  "generated_at": "2026-08-30; 19-07-12",

  "katalogi_wynikowe": [
    { "sciezka": "refactor-result1", "numer": 1, "ostatnia_aktywnosc": "2026-08-29; 14-02-55" },
    { "sciezka": "refactor-result2", "numer": 2, "ostatnia_aktywnosc": "2026-08-30; 18-41-03" }
  ],
  "aktywny_katalog": "refactor-result2",

  "konfiguracja": {
    "plik_istnieje": true,
    "sciezka": "refactor-result2/refactor-decisions.md",
    "kompletna": true,
    "braki": [],
    "odpowiedzi": {
      "pytanie_0": { "commity": "...", "buildy": "...", "zmiany_bez_planu": "...", "framework_testow": "NUnit", "granulacja": "dynamiczna" },
      "pytanie_1": { "struktura": "A", "plik_szczegolowy": false },
      "pytanie_2": { "zakres": "A", "pominiete": [] }
    }
  },

  "sesje": [
    { "nr": 1, "start": "2026-08-29; 11-30-00", "koniec": "2026-08-29; 14-02-55", "zrodlo": "orkiestrator-log.md" },
    { "nr": 2, "start": "2026-08-30; 17-05-12", "koniec": null, "zrodlo": "orkiestrator-log.md" }
  ],

  "etapy": [
    {
      "etap": 1,
      "status": "done",
      "iteracje": 3,
      "ostatni_wpis_logu": "2026-08-30; 17-58-40",
      "log": "etap1-decisions-log.md",
      "plik_wynikowy": "etap1-plan.md",
      "zaakceptowany_przez_uzytkownika": true
    },
    {
      "etap": 2,
      "status": "in_progress",
      "wariant": "refaktor",
      "ostatni_krok": 2,
      "ostatni_wpis_logu": "2026-08-30; 18-41-03",
      "log": "etap2-decisions-log.md",
      "plik_wynikowy": "etap2-plan.md",
      "zaakceptowany_przez_uzytkownika": false
    },
    { "etap": 3, "status": "not_started" }
  ],

  "requesty_otwarte": [
    { "msg_id": "e2-k2-004", "from": "etap2", "action": "user.input", "wystawiony": "2026-08-30; 18-40-11", "opis": "3 nierozpoznane magic numbers" }
  ],

  "pozycje_otwarte": [
    "etap2-plan.md, sekcja Pozycje otwarte: 3 literały bez ustalonego znaczenia"
  ],

  "sesja_poprzednia": {
    "plik_istnieje": true,
    "etap0_wykonany": "2026-08-30; 18-52-30",
    "kontekst_wyczyszczony": true,
    "kto_wyczyscil": "uzytkownik"
  },

  "anomalie": [
    "etap1-decisions-log.md: wpisy 1-9 bez znaczników czasu (uruchomienie sprzed reguły)"
  ]
}
```
