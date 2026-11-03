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

Etap 2 to już konkretne zmiany w kodzie. Zmiana jest bezpieczna, ponieważ
istnieje siatka testów z Etapu 1, względem której można weryfikować skutki.

## Zmiany w testach z Etapu 1

Etap 2 sam aktualizuje testy z Etapu 1, wyłącznie w dwóch przypadkach:
zmiana nazwy i przeniesienie zależności do konstruktora.
- Zmiany w testach są zapowiedziane w planie kroku (sekcja "Wpływ na testy
  z Etapu 1") i akceptowane razem z nim, przed zmianą kodu.
- Asercje, dane wejściowe i zakres testu pozostają nietknięte.
- Każda zmiana w testach jest odnotowana w logu Etapu 2.

## Pytanie startowe Etapu 2

Zakres refaktoryzacji użytkowink określa jak jest zakres refaktoryzacji, a etap2 sam określa dynamicznie ile iteracji potrzebuje na wprowadzenie tych zmian.

## uruchomienie refaktryzacji

Po zebraniu inforamcji od użytkownika uruchamiany jest etap analizy, na podstawie danych podanych przez użytkowinka można określić zakres zmian. Na podstawie tego można określić ilość iteracji potrzebnych do wprowadzenia zmian.

## iteracja - analiza

krok pierwszy sprawdza kod i na podstawie tego wybiera odpowiednią technike z katalogu technik, zapisuje informacje do loga, żeby każda kolejna iteracja wiedziała co zostało zrobione oraz żeby można w dowolnym momencie przewrwać działanie LLM i wrócić bez utraty danych z kontekstu.




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

Wczytaj `00-README.md` i `06-siatka-globalna.md` przed wyborem techniki
w pierwszej iteracji. Pliki autorów wczytuj tylko w sekcjach wybranych technik,
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

Log musi jednoznacznie odnotować na starcie, który wariant został wybrany
(Refaktor / Zmiana logiki / Oba → zawężone do Zmiana logiki), ponieważ od
tego zależy, czy Etap 3 zostanie uruchomiony jako refaktoryzacja rezultatu.

Dodatkowo, dla wariantu "Refaktor": wpisy grupowane są nagłówkiem
`### Krok N` (pod-etap), a w krokach iteracyjnych (krok 3) —
`### Krok N — iteracja M`. **Każda zmiana jest odnotowana w logu tak czy
inaczej** — w szczególności każda zmiana w testach z Etapu 1 (które testy,
przez jaką zmianę w kodzie).

## Format wyjścia Etapu 2

Analogiczny do Etapu 1. Lokalizacja: katalog wynikowy (patrz "Katalog
wynikowy" w `orkiestrator.md`).

Struktura pliku/sekcji zależy od wyboru dokonanego w Pytaniu 1:

- **Opcja A (osobny plik na etap):** plan zapisywany w `etap2-plan.md`.
- **Opcja B (jeden zbiorczy plik):** plan to sekcja `## Etap 2` w pliku
  zbiorczym `refactor-plan.md`, dopisywana/rozbudowywana w miarę postępu
  kroków.
- **Dodatkowy plik szczegółowy per krok** (tylko jeśli użytkownik wybrał tę
  opcję w Pytaniu 1): po zakończeniu każdego kroku powstaje plik
  `etap2-krok-N-zmiany.md` ze szczegółowym opisem zmian tego kroku. Dla kroków
  iteracyjnych (krok 3) plik powstaje po każdej iteracji jako
  `etap2-krok-N-iteracja-M-zmiany.md`. Log pozostaje przy tym wyłącznie listą
  decyzji.

Struktura planu (niezależna od wyboru A/B), sekcje w kolejności:

1. **Zakres kroku** — wariant (Refaktor / Zmiana logiki), numer i nazwa kroku
   (dla kroków iteracyjnych także numer iteracji i porcja zależności objęta tą
   iteracją), objęte pliki/klasy/metody.
2. **Stan wyjściowy** — co konkretnie jest do poprawy w tym kroku (np. lista
   nazw do zmiany, lista magic numbers z miejscami wystąpienia).
3. **Planowane zmiany** — opis zmian, bez treści kodu.
4. **Wpływ na testy z Etapu 1** — które testy prawdopodobnie zaświecą się na
   czerwono i z jakiego powodu; jakie zmiany zostaną w nich wprowadzone.
5. **Pozycje otwarte** — to, czego LLM nie rozstrzygnął sam (np.
   nierozpoznane magic numbers czekające na wkład użytkownika).
6. **Do akceptacji** — jawne pytanie do użytkownika kończące fazę planowania
   tego kroku.

Zgodnie z wyborem obowiązkowym z Pytania 0 (brak zmian bez pliku `.md`), plan
kroku powstaje i jest akceptowany **przed** wprowadzeniem zmian w kodzie —
tak samo jak w Etapie 1.
