# Przykład — Log decyzji — `refactor-decisions.md`
<!-- wersja-harnessu: 0.1.1 -->

Sekcja orkiestratora: „Konfiguracja wstępna” → „Log decyzji”.

```markdown
# Log decyzji — konfiguracja refaktoru

Data: <data>
Fragment/moduł: <opis>

## Katalog wynikowy
- Katalog wynikowy tego przebiegu: refactor-resultN

## Pytanie 0 — Wybory obowiązkowe + granulacja fragmentu

### Wybór użytkownika
- [x] Brak commitów automatycznych
- [x] Brak buildów bez prośby
- [x] Brak zmian bez pliku .md z planem
- [ ] Framework unit testów: (NUnit / xUnit / MSTest / inny)
      -> wykryty w solucji: ... / potwierdzony przez użytkownika: ...
- [ ] Granulacja fragmentu: (automatyczna / tylko metoda / klasa /
      kontroler-moduł / dynamiczna)
      -> szczegóły: ...

## Pytanie 1 — Pliki wynikowe
- [ ] (A: osobny plik na etap / B: jeden zbiorczy plik)

## Pytanie 2 — Zakres etapów
- [ ] (A: wszystkie / B: pominięte: ...)

## Format znacznika czasu (stała harnessu, nie pytanie)
- Format: `yyyy-MM-dd; HH-mm-ss`  (np. 2026-08-30; 19-07-12)
- Obowiązuje: log orkiestratora i logi wszystkich etapów, każdy wpis
```
