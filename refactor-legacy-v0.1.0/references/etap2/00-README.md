# Katalog refaktoryzacji C# — indeks
<!-- wersja-harnessu: 0.1.1 -->

## Cel

- Katalog technik refaktoryzacji dla kodu **już pokrytego testami**.
- Pominięte: techniki łamania zależności i wprowadzania szwów (seams) z Feathersa (rozdz. 25 WELC) — z Feathersa wzięte tylko techniki refaktoryzacji z rozdz. 20–22.
- Zasady SOLID celowo pominięte — wynikają z zastosowania technik (np. F13, K03, K04).

## Pliki

| Plik | Zawartość | Identyfikatory |
|---|---|---|
| `01-fowler.md` | Martin Fowler — katalog podstawowy | F01–F22 |
| `02-feathers.md` | Michael Feathers — praca z dużymi metodami i klasami | W01–W08 |
| `03-kerievsky.md` | Joshua Kerievsky — refaktoryzacja do wzorców | K01–K07 |
| `04-beck.md` | Kent Beck — drobne porządki (tidyings) | B01–B06 |
| `05-czysty-kod.md` | Robert C. Martin — dobre praktyki czystego kodu | P01–P16 |
| `06-siatka-globalna.md` | Zapach → sekwencja kroków, poziomy ryzyka, wybór między technikami | — |
| `07-przyklady-krok-po-kroku.md` | 4 scenariusze refaktoryzacji krok po kroku | S1–S4 |

Każdy plik autora kończy się sekcją **Siatka zastosowania** (sygnał w kodzie → technika → łączenie → kiedy nie stosować).

## Format wpisu

- **Opis** — jedno zdanie.
- **Przykład** — C#, stan *przed* i *po*.
- **Kiedy** — jedno zdanie.

## Konwencje kodu

- C# 7.3 / .NET Framework 4.8.1 — bez rekordów, switch expressions, `??=`, nullable reference types.
- Klamry zawsze, także dla jednoliniowych `if`/`else`/`for`/`foreach`.
- Identyfikatory po angielsku, komentarze po polsku.
- Nazwy technik: oryginał angielski + tłumaczenie (polskie) w nawiasie.

## Zasada pracy (każdy krok)

1. Testy zielone przed krokiem.
2. Jeden mały krok (jedna technika).
3. Testy.
4. Commit — osobno od zmian funkcjonalnych (Beck, *Tidy First?*: oddzielaj porządki od zmian zachowania).

## Polityka unikania powtórzeń

Technika opisana u kilku autorów występuje **raz** — u autora, który skatalogował ją najpełniej. Odpowiedniki:

| Opisane jako | Odpowiednik u innych autorów (pominięty) |
|---|---|
| F01 Extract Function | Beck: Extract Helper |
| F03 Extract Variable | Beck: Explaining Variables |
| F08 Slide Statements | Beck: Move Declaration and Initialization Together |
| F12 Replace Function with Command | Feathers: Break Out Method Object; Beck: Method Object |
| F18 Guard Clauses | Beck: Guard Clauses |
| F20 Introduce Special Case | Kerievsky: Introduce Null Object |
| B01 Dead Code | Fowler: Remove Dead Code |
| P12 Named Constants | Fowler: Replace Magic Literal; Beck: Explaining Constants |
| P11 Comments | Beck: Delete Redundant Comments |
| — (pominięte) | Fowler: Replace Constructor with Factory Function ≈ Kerievsky: Replace Constructors with Creation Methods |

## Źródła

- M. Fowler, *Refactoring: Improving the Design of Existing Code*, 2nd ed., Addison-Wesley 2018; katalog online: https://refactoring.com/catalog/
- M. Feathers, *Working Effectively with Legacy Code*, Prentice Hall 2004 — rozdz. 20 (duża klasa), 21 (ta sama zmiana w wielu miejscach), 22 (metoda-potwór).
- J. Kerievsky, *Refactoring to Patterns*, Addison-Wesley 2004.
- K. Beck, *Tidy First? A Personal Exercise in Empirical Software Design*, O'Reilly 2023.
- R. C. Martin, *Clean Code*, Prentice Hall 2008 — rozdz. 2, 3, 4, 7, 17 (oznaczenia zapachów G/N/F).
- A. Hunt, D. Thomas, *The Pragmatic Programmer*, 1999 — zasada DRY.
