# Przykład — Etap 1: plan z rozkazem → `impl.start` → wynik
<!-- wersja-harnessu: 0.1.2 -->

Pliki: `references/orkiestrator/przebieg-etapu1.md`, „Przebieg etapu”, punkty 3–6;
`references/orkiestrator/protokol-komunikacji.md`, „Adresat `stage.resume` w Etapie 1”.

## 1. `etap1-analiza` → orkiestrator: plan iteracji 1 (`007-etap1-analiza-user.approval.json`)

```json
{
  "msg_id": "e1a-i1-002",
  "corr_id": null,
  "type": "request",
  "from": "etap1-analiza",
  "to": "orkiestrator",
  "action": "user.approval",
  "status": "needs_user",
  "user_message": "Iteracja 1: OrderService.Calculate. Zależność od DateTime.Now → Replace Function with Function Pointer [17]. Test: 3 przypadki rabatu. Czy techniki są właściwe? Czy akceptujesz plan?",
  "payload": {
    "rodzaj": "plan",
    "rozkaz": {
      "iteracja": 1,
      "fragment": { "plik": "src/Orders/OrderService.cs", "nazwa": "OrderService.Calculate" },
      "zaleznosci": [
        {
          "opis": "Bezpośrednie wywołanie DateTime.Now w Calculate",
          "objaw": "G",
          "technika": "[17]",
          "poziom": 1,
          "uzasadnienie": null
        }
      ],
      "seamy": [
        {
          "kolejnosc": 1,
          "technika": "[17]",
          "miejsce": "src/Orders/OrderService.cs, OrderService.Calculate, linia z DateTime.Now",
          "opis": "Dodaj do OrderService pole Func<DateTime> now przekazywane nowym konstruktorem, domyślnie () => DateTime.Now; Calculate wywołuje now(). Stary konstruktor zostaje i deleguje do nowego."
        }
      ],
      "testy": {
        "plik": "tests/Orders.Tests/OrderServiceCalculateTests.cs",
        "klasa": "OrderServiceCalculateTests",
        "przypadki": [
          { "wejscie": "zamówienie 100, dzień roboczy", "oczekiwane": "100" },
          { "wejscie": "zamówienie 100, sobota", "oczekiwane": "90" },
          { "wejscie": "zamówienie 0, sobota", "oczekiwane": "0" }
        ]
      },
      "mocki": [
        { "nazwa": "Func<DateTime> ze stałą datą", "stan": "do utworzenia", "opis": "Lambda w teście, bez osobnej klasy" }
      ],
      "reguly_uzytkownika": []
    },
    "stan_iteracji": {
      "iteracja": 1,
      "iteracje_planowane": 2,
      "zakres_pozostaly": ["OrderService.Calculate", "OrderService.Save"],
      "wykonane": [],
      "sekwencja_pozostala": [],
      "pozycje_otwarte": []
    }
  },
  "timestamp": "<data>"
}
```

## 2. Orkiestrator → `etap1-implementacja` po akceptacji (`008-orkiestrator-impl.start.json`)

```json
{
  "msg_id": "o-015",
  "corr_id": "e1a-i1-002",
  "type": "dispatch",
  "from": "orkiestrator",
  "to": "etap1-implementacja",
  "action": "impl.start",
  "status": "in_progress",
  "user_message": "",
  "payload": {
    "user_answer": "Akceptuję.",
    "rozkaz": { "...": "pole rozkaz z wiadomości e1a-i1-002, bez zmian" },
    "stan_iteracji": { "...": "pole stan_iteracji z wiadomości e1a-i1-002, bez zmian" }
  },
  "timestamp": "<data>"
}
```

## 3. `etap1-implementacja` → orkiestrator: wynik (`009-etap1-implementacja-user.approval.json`)

```json
{
  "msg_id": "e1i-i1-001",
  "corr_id": null,
  "type": "request",
  "from": "etap1-implementacja",
  "to": "orkiestrator",
  "action": "user.approval",
  "status": "needs_user",
  "user_message": "Iteracja 1 wykonana. Testy: OrderServiceCalculateTests, 3 przypadki, zielone. Seam: [17] w OrderService.cs (Func<DateTime> now). Czy akceptujesz wynik?",
  "payload": {
    "rodzaj": "wynik",
    "wynik": {
      "techniki": ["[17]"],
      "pliki": [
        "src/Orders/OrderService.cs",
        "tests/Orders.Tests/OrderServiceCalculateTests.cs"
      ]
    },
    "stan_iteracji": { "...": "bez zmian względem impl.start" }
  },
  "timestamp": "<data>"
}
```

Akceptacja → `stage.resume` do `etap1-analiza` z `payload.wynik`; analiza dopisuje
iterację 1 do `wykonane` i przygotowuje plan iteracji 2.
