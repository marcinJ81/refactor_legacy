# Przykład — Raport Etapu 0 — `payload.report`
<!-- wersja-harnessu: 0.3.0 -->

Sekcja: `.claude/agents/etap0.md` → „Koperta wiadomości". Raport wytwarza
`scripts/etap0/00-rozpoznanie.ps1` i wpisuje go do `payload.report` ramki
(`etap0-examples/message-frame.md`) — tylko gdy jest poprzednia sesja.
Osobny plik raportu nie powstaje.

## Raport — komplet pól

```json
{
  "schema": "etap0-raport/2",
  "zrodlo": "etap0-rozpoznanie/1",
  "generated_at": "2026-08-30; 19-07-12",
  "tryb": "normalny",
  "katalog_projektu": "C:/projekty/sklep",

  "katalogi_wynikowe": [
    { "sciezka": "refactor-result1", "numer": 1, "ostatnia_aktywnosc": "2026-08-29; 14-02-55" },
    { "sciezka": "refactor-result2", "numer": 2, "ostatnia_aktywnosc": "2026-08-30; 18-41-03" }
  ],
  "aktywny_katalog": "refactor-result2",

  "konfiguracja": {
    "plik_istnieje": true,
    "sciezka": "C:/projekty/sklep/refactor-result2/refactor-config.json",
    "kompletna": false,
    "braki": ["pytanie_2.zakres_etapow.wartosc"],
    "odpowiedzi": {
      "tryb.wartosc": "normalny",
      "pytanie_0.commitowanie.wartosc": "reczne",
      "pytanie_0.zgoda_build.wartosc": true,
      "pytanie_0.zgoda_testy.wartosc": true,
      "pytanie_0.wersja_dotnet.wartosc": "framework",
      "pytanie_0.solucja.wartosc": "src/Sklep.sln",
      "pytanie_0.sekwencja_budowania.wartosc": ["src/Sklep.Domena/Sklep.Domena.csproj", "src/Sklep.Web/Sklep.Web.csproj"],
      "pytanie_0.projekty_testowe.wartosc": ["tests/Sklep.Domena.Tests/Sklep.Domena.Tests.csproj"],
      "pytanie_0.zmiany_bez_planu.wartosc": "zabronione",
      "pytanie_0.framework_testow.wartosc": "NUnit",
      "pytanie_0.granulacja.wartosc": "dynamiczna",
      "pytanie_1.struktura_plikow.wartosc": "A",
      "pytanie_1.plik_szczegolowy_per_iteracja.wartosc": false
    }
  },

  "sesje": [
    { "nr": 1, "start": "2026-08-29; 11-30-00", "ostatni_wpis": "2026-08-29; 14-02-55", "liczba_wpisow": 31, "zrodlo": "orkiestrator-log.md" },
    { "nr": 2, "start": "2026-08-30; 17-05-12", "ostatni_wpis": "2026-08-30; 18-41-03", "liczba_wpisow": 18, "zrodlo": "orkiestrator-log.md" }
  ],

  "etapy": [
    {
      "etap": 0,
      "status": "done",
      "zrodlo_statusu": "communication",
      "log": null,
      "ostatni_wpis_logu": null,
      "plik_wynikowy": null,
      "liczba_wiadomosci": 2
    },
    {
      "etap": 1,
      "status": "done",
      "zrodlo_statusu": "communication",
      "log": "etap1-decisions-log.md",
      "ostatni_wpis_logu": "2026-08-30; 17-58-40",
      "plik_wynikowy": "etap1-plan.md",
      "liczba_wiadomosci": 14,
      "iteracje": { "biezaca": 3, "zaplanowane": 3 }
    },
    {
      "etap": 2,
      "status": "in_progress",
      "zrodlo_statusu": "communication",
      "log": "etap2-decisions-log.md",
      "ostatni_wpis_logu": "2026-08-30; 18-41-03",
      "plik_wynikowy": "etap2-plan.md",
      "liczba_wiadomosci": 6
    },
    {
      "etap": 3,
      "status": "not_started",
      "zrodlo_statusu": "communication",
      "log": null,
      "ostatni_wpis_logu": null,
      "plik_wynikowy": null,
      "liczba_wiadomosci": 0
    }
  ],

  "requesty_otwarte": [
    {
      "msg_id": "e2-k2-004",
      "from": "etap2",
      "action": "user.input",
      "wystawiony": "2026-08-30; 18-40-11",
      "plik": "communication/031-etap2-user.input.json"
    }
  ],

  "pozycje_otwarte": [
    "etap2-plan.md, sekcja Pozycje otwarte: 3 literały bez ustalonego znaczenia"
  ],

  "sesja_poprzednia": {
    "plik_istnieje": true,
    "sciezka": "C:/projekty/sklep/refactor-result2/refactor-session.md",
    "tryb": "normalny",
    "katalog_wynikowy": "refactor-result2",
    "etap0_wykonany": "2026-08-30; 18-52-30",
    "punkt_wznowienia": {
      "etap_w_toku": "etap2",
      "krok_w_toku": "—",
      "iteracja": "3 z 3",
      "ostatnia_zamknieta_jednostka": "etap1.step2 / iteracja 3 — 2026-08-30; 17-58-40"
    }
  },

  "anomalie": [
    "orkiestrator-log.md: 9 wpisów bez znacznika czasu (błąd formatu logu) — nieprzypisane do żadnej sesji"
  ]
}
```

## Podsumowanie hooka (`additionalContext`, trafia do kontekstu startowego)

```
## Etap 0 — rozpoznanie stanu (hook startu agenta)
[etap0] poprzednia sesja: tak; katalogi wynikowe: 2; aktywny: refactor-result2
[etap0] sesje: 2; konfiguracja: niekompletna; etapy w toku: etap2=in_progress
[etap0] requesty otwarte: 1; pozycje otwarte: 1; anomalie: 1
[etap0] ramka: C:/projekty/sklep/refactor-result2/communication/032-etap0-message-frame.json
```
