```
name: etap2
description: etap 2 polega na refakryzacji wybranej części kodu. Refaktryzacji za pomocą dołączonych technik
```

<!-- wersja-harnessu: 0.1.1 -->

Uruchamiany przez orkiestratora (`orkiestrator.md`) wiadomością `stage.start`.
Konfiguracja wstępna przychodzi w `payload.config` — Etap 2 jej nie zbiera.

## Brama wejściowa (warunek uruchomienia)

Etap 2 uruchamia się dopiero po zakończeniu Etapu 1 **i** po jawnej akceptacji
przez użytkownika wyniku Etapu 1 (utworzone unit testy do istniejącego kodu
i/lub zmiany umożliwiające testowanie — seamy, extract method/interface).
Brak akceptacji = brak startu Etapu 2. Bramy pilnuje orkiestrator.

Testy z Etapu 1 to testy napisane w Etapie 1 oraz istniejące testy, które Etap 1
rozpoznał jako pełne albo uzupełnił (patrz "Rozpoznanie istniejących testów"
w `etap1.md`).

Etap 2 to już konkretne zmiany w kodzie. Zmiana jest bezpieczna, ponieważ
istnieje siatka testów z Etapu 1, względem której można weryfikować skutki.

## Zmiany w testach z Etapu 1

Etap 2 sam aktualizuje testy z Etapu 1, wyłącznie gdy technika zmienia sposób
odwołania do kodu, a nie jego zachowanie: zmiana nazwy, zmiana sygnatury,
przeniesienie metody lub klasy, przeniesienie zależności do konstruktora.
- Zmiany w testach są zapowiedziane w planie iteracji (sekcja "Wpływ na testy
  z Etapu 1") i akceptowane razem z nim, przed zmianą kodu.
- Asercje, dane wejściowe i zakres testu pozostają nietknięte.
- Mock lub stub odtwarza dotychczasowe zachowanie zależności. Użyj tego, co jest
  w projekcie; jeśli nie ma, utwórz własny. **Nie używaj frameworka Moq.**
- Każda zmiana w testach jest odnotowana w logu Etapu 2.

## Pytanie startowe Etapu 2

Zakres refaktoryzacji użytkowink określa jak jest zakres refaktoryzacji, a etap2 sam określa dynamicznie ile iteracji potrzebuje na wprowadzenie tych zmian.

## uruchomienie refaktryzacji

Po zebraniu inforamcji od użytkownika uruchamiany jest etap analizy, na podstawie danych podanych przez użytkowinka można określić zakres zmian. Na podstawie tego można określić ilość iteracji potrzebnych do wprowadzenia zmian.

## iteracja - analiza

krok pierwszy sprawdza kod i na podstawie tego wybiera odpowiednią technike z katalogu technik, zapisuje informacje do loga, żeby każda kolejna iteracja wiedziała co zostało zrobione oraz żeby można w dowolnym momencie przewrwać działanie LLM i wrócić bez utraty danych z kontekstu.

Przed każdą iteracją wczytaj z dysku `refactor-decisions.md` i
`etap2-decisions-log.md`.

Analiza zakresu kończy się podziałem zakresu na iteracje. Podział trafia do
`payload.stan_iteracji.zakres_pozostaly`. Liczbę iteracji można zmienić w planie
kolejnej iteracji.

## Stan iteracji i wznowienie

Każda wiadomość Etapu 2 niesie `payload.stan_iteracji`. Wznowienie zaczyna od
ostatniej ramki. Zasady i pola: `references/orkiestrator/protokol-komunikacji.md`,
sekcja "Stan iteracji".

## iteracja - plan i akceptacja

1. Dopisz plan iteracji do pliku planu (patrz "Format wyjścia Etapu 2").
2. Wyślij `user.approval` z `payload.rodzaj` = `plan`. Bez akceptacji planu kod
   się nie zmienia. Gdy użytkownik odrzuci plan, popraw go i wyślij ponownie.

## iteracja - wykonanie

1. Uruchom testy z Etapu 1. Testy muszą być zielone przed pierwszym krokiem.
   Gdy są czerwone, zatrzymaj się i wyślij `user.input` z opisem.
2. Wykonuj zaplanowane techniki po jednej, według zasady pracy z `00-README.md`.
3. Po każdym kroku uruchom testy. Czerwony test obsłuż według "Reguły
   niezaliczonego testu".
4. Zapisz w logu wykonane techniki i wynik testów.
5. Wyślij `user.approval` z `payload.rodzaj` = `wynik`. W `user_message`
   przypomnij o commicie użytkownika. Gdy użytkownik odrzuci wynik, zatrzymaj się
   i wyślij `user.input` z pytaniem, co dalej.

## Koniec iteracji i etapu

- Iteracja kończy się, gdy testy są zielone, a użytkownik potwierdził wynik.
  Kolejna iteracja startuje dopiero wtedy.
- Etap wysyła `stage.done`, gdy zakres jest wyczerpany albo zachodzi warunek
  z sekcji 5 siatki (`references/etap2/06-siatka-globalna.md`).
- Gdy użytkownik przerwie pracę, zapisz to w logu i wyślij `stage.aborted`.

## Reguła niezaliczonego testu

1. Test przestał przechodzić z powodu zmiany zapowiedzianej w planie bieżącej
   iteracji → zaktualizuj test według sekcji "Zmiany w testach z Etapu 1".
2. Test przestał przechodzić z innego powodu → to regresja. Zatrzymaj się
   i wyślij `user.input` z opisem. Nie zmieniaj testu pod nowy wynik.

## Zakaz zgadywania

Gdy z kodu nie da się ustalić znaczenia literału, odpowiedzialności elementu
albo zachowania zależności, wyślij `user.input` z listą pozycji i miejscami
wystąpienia. Nie nadawaj nazw "na oko" ani nazw zastępczych typu `MAGIC_1`.
Pozycje bez odpowiedzi użytkownika zostają w kodzie nietknięte i trafiają do
pozycji otwartych planu.

## Katalog technik

Wybór i wykonanie techniki refaktoryzacji w iteracji opiera się na plikach
z katalogu `references/etap2/`:

| Plik | Do czego |
|---|---|
| `references/etap2/00-README.md` | Indeks katalogu: identyfikatory technik, konwencje kodu C#, zasada pracy w każdym kroku, odpowiedniki technik u różnych autorów |
| `references/etap2/06-siatka-globalna.md` | Wybór techniki: poziomy ryzyka, zapach → sekwencja kroków, wybór między technikami konkurencyjnymi, warunki wstępne, kiedy przestać |
| `references/etap2/01-fowler.md` | Wykonanie techniki: F01–F22, katalog podstawowy |
| `references/etap2/02-feathers.md` | Wykonanie techniki: W01–W08, duże metody i duże klasy |
| `references/etap2/03-kerievsky.md` | Wykonanie techniki: K01–K07, refaktoryzacja do wzorców |
| `references/etap2/04-beck.md` | Wykonanie techniki: B01–B06, drobne porządki |
| `references/etap2/05-czysty-kod.md` | Wykonanie techniki: P01–P16, dobre praktyki czystego kodu |
| `references/etap2/07-przyklady-krok-po-kroku.md` | Scenariusze S1–S4: całe sekwencje kroków na przykładach |

Wczytaj `00-README.md` i `06-siatka-globalna.md` na początku każdej iteracji.
Pliki autorów wczytuj tylko w sekcjach wybranych technik,
a plik `07-przyklady-krok-po-kroku.md` tylko w scenariuszu podobnym do
refaktoryzowanego kodu.

Wybór techniki w iteracji:

1. Rozpoznaj zapach w kodzie i odczytaj sekwencję kroków (siatka, sekcja 2).
2. Gdy pasuje kilka technik, rozstrzygnij wybór według sekcji 3 siatki.
3. Sprawdź warunki wstępne wybranej techniki (siatka, sekcja 4.2).
4. Zacznij od najniższego poziomu ryzyka (siatka, sekcja 1).
5. Zakończ refaktoryzację, gdy zachodzi warunek z sekcji 5 siatki. Niewykonane
   kroki wypisz w pliku wynikowym jako pozycje otwarte.

Identyfikator wybranej techniki (np. `F18`) zapisz w logu. Gdy żadna technika
z katalogu nie pasuje, wystaw `user.input` zamiast stosować technikę spoza
katalogu.

Zasada pracy z `00-README.md` obowiązuje w każdym kroku z jednym wyjątkiem:
punkt „Commit” i słowo „commit” w plikach katalogu oznaczają miejsce na commit
użytkownika. Etap 2 nie commituje (Pytanie 0, „Commitowanie”).

## Log Etapu 2 (`etap2-decisions-log.md`)

Osobny plik logu, analogicznie do Etapu 1 — nie mieszać z logiem konfiguracji
wstępnej, logiem Etapu 1 ani logiem orkiestratora. Te same zasady prowadzenia:
wyłącznie decyzje i wybory, żadnego kodu ani diffów, wpisy numerowane
chronologicznie, w miarę jak są podejmowane, **każdy wpis poprzedzony
znacznikiem daty i godziny** w formacie `yyyy-MM-dd; HH-mm-ss`. Wpisy
i nagłówki dopisuje wyłącznie skrypt `scripts/wspolne/wpis-logu.ps1` (patrz
"Znaczniki czasu w logach" w `orkiestrator.md`). Pierwszym wpisem każdego uruchomienia Etapu 2 jest
nagłówek `## Uruchomienie <znacznik>` z datą i godziną startu etapu.

Na starcie log odnotowuje zakres refaktoryzacji i planowaną liczbę iteracji.

Wpisy każdej iteracji grupuje nagłówek `### Iteracja N`
(`-Naglowek iteracja -Iteracja <N>`). **Każda zmiana jest odnotowana w logu tak
czy inaczej** — w szczególności każda zmiana w testach z Etapu 1 (które testy,
przez jaką zmianę w kodzie).

## Format wyjścia Etapu 2

Analogiczny do Etapu 1. Lokalizacja: katalog wynikowy (patrz "Katalog
wynikowy" w `orkiestrator.md`).

Plan zapisywany jest w `etap2-plan.md`. Każda iteracja dopisuje do niego sekcję
`## Iteracja N`.

Struktura sekcji iteracji, w kolejności:

1. **Zakres iteracji** — numer iteracji, objęte pliki/klasy/metody.
2. **Stan wyjściowy** — rozpoznane zapachy z miejscami wystąpienia.
3. **Planowane zmiany** — identyfikatory technik w kolejności wykonania i opis
   zmian, bez treści kodu.
4. **Wpływ na testy z Etapu 1** — które testy prawdopodobnie zaświecą się na
   czerwono i z jakiego powodu; jakie zmiany zostaną w nich wprowadzone.
5. **Pozycje otwarte** — to, czego LLM nie rozstrzygnął sam (np. literały
   o nieustalonym znaczeniu czekające na wkład użytkownika, niewykonane kroki).
6. **Do akceptacji** — jawne pytanie do użytkownika kończące fazę planowania
   tej iteracji.

Zgodnie z wyborem obowiązkowym z Pytania 0 (brak zmian bez pliku `.md`), plan
iteracji powstaje i jest akceptowany **przed** wprowadzeniem zmian w kodzie —
tak samo jak w Etapie 1.
