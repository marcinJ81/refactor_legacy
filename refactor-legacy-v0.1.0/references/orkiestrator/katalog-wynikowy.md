# Orkiestrator — Katalog wynikowy
<!-- wersja-harnessu: 0.1.1 -->

Sekcja wyniesiona z `orkiestrator.md` („Katalog wynikowy”).

Wszystkie pliki powstałe w trakcie działania harnessu (plan/plany, logi
decyzji, komunikaty protokołu)
zapisywane są w katalogu wynikowym utworzonym wewnątrz katalogu **projektu
będącego przedmiotem refaktoryzacji** (nie w katalogu samego harnessu).

Nazwa katalogu: `refactor-resultN` (np. `refactor-result1`, `refactor-result2`).
`N` to numer kolejnego uruchomienia, liczony od 1. Zasady:

1. **Numer to największy znaleziony + 1**, a nie liczba katalogów. Usunięcie
   `refactor-result2` nie powoduje ponownego użycia numeru 2.
2. **Istniejący katalog nigdy nie jest nadpisywany.**
3. **Nowy numer powstaje tylko przy nowej sesji.** Jeśli Etap 0 wykrył
   poprzednią sesję i użytkownik wybrał wznowienie, przebieg **kontynuuje
   w katalogu wznawianej sesji**, bez inkrementacji. Numer rośnie wyłącznie
   wtedy, gdy zaczynamy nową sesję — Etap 0 nie znalazł poprzedniej albo
   użytkownik świadomie zaczyna od nowa.

Kolejność jest zatem taka: **Etap 0 (rozpoznanie katalogów) →
decyzja "nowa sesja czy wznowienie" → dopiero wtedy ustalenie numeru
katalogu**. Zestaw istniejących numerów jest jednocześnie historią prób
uruchomienia harnessu na tym projekcie.

**Wyjątek — pliki Etapu 0.** Etap 0 wykonuje się, zanim wiadomo, czy powstanie
katalog o nowym numerze. Dlatego `etap0-raport.json` i `refactor-session.md`
zapisywane są zawsze w **najnowszym istniejącym** katalogu wynikowym;
jeśli nie istnieje żaden, orkiestrator tworzy `refactor-result1` na tę potrzebę. Gdy interpretacja raportu prowadzi do
decyzji o nowej sesji w katalogu o kolejnym numerze, oba pliki są do niego
kopiowane jako punkt startowy — oryginały zostają nietknięte.
