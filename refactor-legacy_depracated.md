---
name: refactor-legacy
description: Skill do bezpiecznej refaktoryzacji i wprowadzania zmian w kodzie legacy (np. .NET Framework 4.8.1, .NET MVC, jQuery). Używać zawsze gdy użytkownik prosi o refaktor, zmianę zachowania istniejącego kodu, wydzielenie metod/klas, dodanie testów do kodu bez pokrycia testami, lub redukcję couplingu. Proces jest etapowy i wymaga jawnej akceptacji użytkownika między etapami - nie pomijać etapów, nawet jeśli zadanie wygląda na proste.
---

# Refactor Legacy

Skill do prowadzenia refaktoryzacji kodu legacy w sposób kontrolowany, etapowy.

## Podstawa metodyczna

Skill nie opiera się na jednym autorze ani jednej szkole — łączy kilka źródeł,
każde tam, gdzie jest najbardziej użyteczne:

- **Michael Feathers** (*Working Effectively with Legacy Code*) — Etap 1:
  seamy, testy charakteryzujące, bezpieczne wejście w kod bez pokrycia testami.
- **Martin Fowler** (*Refactoring*) — Etap 2: katalog refaktoryzacji i zasada
  małych kroków zachowujących zachowanie.
- **Robert C. Martin (Uncle Bob) / clean code** — Etap 2: nazewnictwo
  odpowiadające rzeczywistej odpowiedzialności, rozmiar i odpowiedzialność
  metod i klas, czytelność jako pierwszy cel.
- **Własne ustalenia i przemyślenia** — reguły wypracowane w trakcie pracy nad
  konkretnym projektem; zapisywane w logach decyzji i respektowane w kolejnych
  iteracjach.

Rozkład jest celowy: Etap 1 to Feathers (jak w ogóle dostać się do kodu
testem), Etap 2 to Fowler i clean code (jak ten kod poprawić).

## Status dokumentu

Szkielet w budowie. Etap 1 opisany. Etap 2: wariant "Refaktor" — krok 1
opisany, kolejne kroki do zdefiniowania; wariant "Zmiana logiki" — w budowie.
Etap 3 — do zdefiniowania. Kolejne części dodawane iteracyjnie.

---

## Konfiguracja wstępna (wymagana przed uruchomieniem skilla)

Skill nie może rozpocząć pracy nad kodem, dopóki ta konfiguracja nie zostanie
przeprowadzona z użytkownikiem. Konfiguracja to jeden przepływ pytań. Żadne
pytanie nie jest pomijane milcząco — każde wymaga jawnego wyboru użytkownika,
nawet jeśli dla części z nich dopuszczalna jest w praktyce tylko jedna
sensowna odpowiedź.

### Pytania konfiguracyjne (pytać zawsze na starcie, przed Etapem 1)

**Pytanie 0 — Wybory obowiązkowe + granulacja fragmentu**

Poniższe wybory użytkownik musi podjąć zawsze, na starcie każdego uruchomienia
skilla:

- Commitowanie: (musi wybrać) — brak commitów automatycznych, commit wykonuje
  wyłącznie użytkownik, ręcznie.
- Build: (musi wybrać) — brak buildów/kompilacji bez wyraźnej prośby
  użytkownika.
- Zmiany bez planu: (musi wybrać) — brak zmian w kodzie produkcyjnym, dopóki
  nie istnieje plik `.md` opisujący planowane zmiany, chyba że użytkownik
  jawnie powie inaczej w danej sesji.
- Framework unit testów: (musi wybrać) — NUnit / xUnit / MSTest / inny.
  Logika ustalenia:
  1. Sprawdź solucję — jeśli w projekcie(-ach) testowym(-ych) już jest
     zainstalowany i używany któryś z frameworków (referencje w `.csproj`,
     istniejące pliki testów), zaproponuj go jako **domyślny wybór** i poproś
     użytkownika o potwierdzenie.
  2. Jeśli w solucji nie ma żadnego frameworka testowego (brak projektu
     testowego lub brak referencji), zapytaj użytkownika wprost, którego
     frameworka użyć — nie zakładaj domyślnie.
  3. Jeśli w solucji istnieje więcej niż jeden framework jednocześnie
     (mieszane projekty testowe), przedstaw wszystkie znalezione i zapytaj,
     którego użyć dla nowych testów w ramach tego refaktoru.

Oraz wybór granulacji fragmentu podlegającego jednej iteracji Etapu 1:
- Automatyczna — LLM sam ustala zakres fragmentu na podstawie analizy kodu.
- Tylko metoda.
- Klasa.
- Kontroler / moduł.
- Dynamiczna — zakres nie jest ustalany z góry; pytanie o zakres zmian musi
  paść w jednym określonym kroku/części Etapu 1, przed napisaniem testów
  (patrz krok 1 Etapu 1 niżej), na podstawie tego, co pokaże analiza.

**Pytanie 1 — Struktura plików wynikowych**
- Opcja A: Osobny plik `.md` dla każdego etapu.
- Opcja B: Jeden zbiorczy plik `.md` na wszystkie etapy (rozbudowywany
  sekcjami w miarę postępu).
- Dodatkowo, niezależnie od wyboru A/B: czy oprócz logu decyzji ma powstawać
  osobny plik ze szczegółowym opisem zmian po każdej iteracji (Tak/Nie)?
  Domyślnie Nie — decyzja należy do użytkownika.

**Pytanie 2 — Zakres etapów**
- Opcja A: Wykonujemy wszystkie etapy po kolei.
- Opcja B: Użytkownik pomija wybrane etapy (np. Etap 1 zbędny, bo fragment
  jest już pokryty unit testami) — użytkownik wskazuje, które etapy
  pomijamy i skill to respektuje.

### Log decyzji

Po przejściu Pytań 0–2 skill zapisuje wynik konfiguracji jako checklistę do
osobnego pliku, tworzonego obok plików dotyczących etapów, np.
`refactor-decisions.md`. Plik ten pełni rolę logu decyzji użytkownika i jest
punktem odniesienia przy każdej kolejnej iteracji/etapie tego samego
refaktoru.

Przykładowa zawartość pliku logu:

```markdown
# Log decyzji — konfiguracja refaktoru

Data: <data>
Fragment/moduł: <opis>

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
```

### Katalog wynikowy skilla

Wszystkie pliki powstałe w trakcie działania skilla (plan/plany, logi decyzji,
opcjonalne pliki szczegółowe per iteracja) zapisywane są w katalogu o nazwie
skilla (`refactor-legacy`), utworzonym wewnątrz katalogu projektu będącego
przedmiotem refaktoryzacji.

Jeśli katalog o tej nazwie już istnieje (np. z poprzedniego uruchomienia
skilla na tym samym projekcie), nowy katalog otrzymuje kolejny numer wersji:
`refactor-legacy-ver2`, `refactor-legacy-ver3`, itd. Istniejący katalog nigdy
nie jest nadpisywany.

### Zasada stałego odświeżania kontekstu

Przed rozpoczęciem **każdej kolejnej iteracji** (Faza Analizy każdej iteracji
w Etapie 1, analogicznie w Etapie 2 i Etapie 3) skill wczytuje na nowo log
konfiguracji wstępnej (`refactor-decisions.md` z ustaleniami z Pytań 0–2).
Zasada obowiązuje niezależnie od długości sesji — celem jest zapobieganie
odejściu od reguł ustalonych na starcie (granulacja, framework testowy,
zasada braku zmian bez planu, struktura plików wynikowych) w miarę postępu
pracy.

---

## Etap 1 — Przygotowanie "placu boju" (Characterization + Seams)

Cel etapu: umożliwić bezpieczne wprowadzenie zmiany poprzez objęcie fragmentu
testem charakteryzującym (characterization test — dokumentuje **aktualne**
zachowanie kodu, niezależnie od tego, czy jest ono poprawne) oraz odsprzęgnięcie
(decoupling) zależności blokujących testowalność.

### Struktura wewnętrzna: Faza Analizy i Faza Implementacji

Etap 1 — jak każdy kolejny etap tego skilla — dzieli się na dwie fazy:
**Analizę** i **Implementację**. Faza Analizy kończy się zatwierdzeniem
wyniku przez użytkownika, dopiero po nim może ruszyć Faza Implementacji;
Faza Implementacji kończy się sprawdzeniem/potwierdzeniem wyniku przez
użytkownika.

Dla małego fragmentu (np. pojedyncza metoda) ten cykl przechodzi się raz.
Dla dużego fragmentu (moduł, klasa, kontroler — rzędu np. 10 tys. linii) cykl
wykonuje się **iteracyjnie, wielokrotnie**, dla kolejnych podfragmentów:

```
Analiza (1) → zatwierdzenie użytkownika → Implementacja (1) → sprawdzenie użytkownika
→ Analiza (2) → zatwierdzenie użytkownika → Implementacja (2) → sprawdzenie użytkownika
→ ... → finałowe zamknięcie Etapu 1
```

Finałowe zamknięcie Etapu 1 dla danego fragmentu następuje, gdy powstanie
kompletne środowisko testowe dla całego pierwotnie wskazanego zakresu
(wszystkie niezbędne seamy wprowadzone, wszystkie podfragmenty objęte testami
charakteryzującymi).

Użytkownik może przerwać iterację w dowolnym momencie, po dowolnej fazie —
przerwanie nie wymaga uzasadnienia. Log Etapu 1 odnotowuje przerwanie jako
ostatni wpis.

### Faza Analizy — kroki

1. **Ocena testowalności fragmentu**
   - Czy zmieniany fragment (metoda/funkcja) da się objąć unit testem
     bez modyfikacji kodu? Testujemy **zachowanie**, nie implementację.
   - Jeśli tak → przejdź do Fazy Implementacji, krok 1 (napisz test na obecny
     stan).
   - Jeśli nie → przejdź do kroku 2 poniżej.
   - Jeśli w konfiguracji wstępnej (Pytanie 0) wybrano granulację **dynamiczną**:
     jeśli fragment okaże się zbyt duży/złożony, aby objąć go jedną spójną
     iteracją Fazy Analizy, zatrzymaj się tutaj — przedstaw użytkownikowi co
     dokładnie jest za duże i dlaczego (pod kątem wprowadzenia unit testów),
     i zapytaj o decyzję (np. podział na mniejsze podfragmenty i przejście na
     tryb iteracyjny) zamiast kontynuować samodzielnie. To jest ten określony
     krok, w którym dla granulacji dynamicznej musi paść pytanie o zakres
     zmian, zanim powstanie jakikolwiek test.

2. **Identyfikacja zależności blokujących testowalność**
   - Wypisz wszystkie zależności uniemożliwiające izolację fragmentu w teście,
     np.: statyczne wywołania, `HttpContext`, bezpośrednie odwołania do bazy danych,
     `DateTime.Now`, singletony, `new` wewnątrz metody zamiast wstrzykniętej
     zależności (brak Dependency Injection).
   - Dla każdej zależności określ typ szwu (seam) możliwy do zastosowania:
     Extract Interface + DI, Extract and Override Call, Adapter, Parameterize
     Method — zgodnie z katalogiem technik Feathersa.

3. **Propozycja minimalnego odsprzęgnięcia**
   - Zaproponuj **najmniejszą możliwą** zmianę, która umożliwi test, bez
     ruszania logiki biznesowej.
   - Zgodnie z wyborem obowiązkowym z Pytania 0 (brak zmian bez pliku `.md`):
     propozycja trafia najpierw do pliku `.md` (patrz sekcja "Format wyjścia"
     niżej) i czeka na **zatwierdzenie przez użytkownika** — to jest koniec
     Fazy Analizy dla danej iteracji. Bez zatwierdzenia Faza Implementacji
     się nie rozpoczyna.

4. **Gdy odsprzęgnięcie bez zmiany logiki nie jest możliwe**
   - Jeśli żadna propozycja seamu z kroku 3 nie pozwala objąć fragmentu
     testem bez ingerencji w logikę biznesową, przedstaw użytkownikowi do
     wyboru poniższe kierunki. Wybór jest obowiązkowy i odnotowywany w logu
     Etapu 1.

   - **Opcja 1 — Zakończenie działania skilla.** Praca nad fragmentem zostaje
     zakończona z adnotacją: sensowne napisanie testów nie jest możliwe,
     złożoność kodu wymusza zmianę logiki.

   - **Opcja 2 — Zakończenie z decyzją użytkownika.** Ta sama adnotacja co
     w Opcji 1, ale skill nie kończy pracy samodzielnie — przedstawia
     sytuację i czeka na decyzję użytkownika co do dalszego kierunku.

   - **Opcja 3 — Opakowanie w dodatkową abstrakcję.** Stosowana, gdy problem
     dotyczy całego modułu, dużej klasy lub metody. Problematyczny kod
     zostaje opakowany w dodatkową abstrakcję, co pozwala wprowadzić
     przełącznik kierujący sterowanie do nowej implementacji — stara
     struktura pozostaje nietknięta. Nowa implementacja powstaje w podejściu
     TDD. Po wyborze tej opcji i wskazaniu frameworka do mocków skill
     zatrzymuje się z adnotacją "w budowie" — dalsze rozwinięcie (przebieg
     TDD, dobór mocków) zamknięte do kolejnej iteracji.

   - **Opcja 4 — Jak Opcja 3, z pytaniem o kierunek zmian.** Ta sama
     technika (abstrakcja + przełącznik), ale przed jej zastosowaniem skill
     pyta użytkownika, czy celem jest: (a) refaktor przez przepisanie
     starego rozwiązania na nowe, zachowanie bez zmian, czy (b) zmiana
     logiki/funkcjonalności realizowana równolegle z refaktorem. Kierunek
     wybiera użytkownik.

### Faza Implementacji — kroki

1. **Napisanie testu charakteryzującego (characterization test)**
   - Test w frameworku ustalonym w Pytaniu 0, dokumentujący obecne zachowanie
     fragmentu (przed jakąkolwiek zmianą logiki).
   - Test musi przechodzić na kodzie w stanie obecnym — to jest punkt odniesienia
     (baseline), względem którego będzie weryfikowana poprawność późniejszego
     refaktoru.

2. **Wydzielanie z dużych metod / wprowadzenie seamu**
   - Fizyczne wykonanie zatwierdzonej w Fazie Analizy propozycji: jeśli
     fragment to duża, monolityczna metoda — wydziel mniejsze metody
     prywatne/publiczne możliwe do przetestowania w izolacji, zamiast testować
     całość jako czarną skrzynkę.
   - Wydzielanie ma być najmniejszym możliwym krokiem (extract method), bez
     zmiany zachowania (behavior-preserving refactoring).

3. **Sprawdzenie wyniku przez użytkownika**
   - Wynik Fazy Implementacji (nowe testy + wprowadzony seam) trafia do
     użytkownika do sprawdzenia/potwierdzenia — to jest koniec danej iteracji.
   - **Tylko dla pierwszej iteracji** danego uruchomienia Etapu 1: dodatkowo
     zapytaj użytkownika, czy zastosowana strategia seamu (sposób
     rozwiązania) jest właściwa. Użytkownik może w tym momencie narzucić
     własne reguły obowiązujące dla kolejnych iteracji tego samego fragmentu
     — nie jest to wybór z listy opcji, lecz otwarta korekta.
   - Jeśli fragment wymaga kolejnej iteracji (duży fragment, granulacja
     dynamiczna z podziałem) → wróć do Fazy Analizy, krok 1, dla kolejnego
     podfragmentu.
   - Jeśli to była ostatnia iteracja dla całego wskazanego zakresu → finałowe
     zamknięcie Etapu 1 (kompletne środowisko testowe dla całego zakresu).

### Log Etapu 1 (`etap1-decisions-log.md`)

Etap 1 wykonuje LLM. Każde uruchomienie Etapu 1 (dla danego fragmentu) prowadzi
własny, osobny plik logu, oddzielny od logu konfiguracji wstępnej
(`refactor-decisions.md`, Pytanie 0). Nie mieszać zawartości tych dwóch plików.

Zasady prowadzenia logu:
- Log zawiera **wyłącznie decyzje i wybory** — żadnego kodu, diffów, treści
  testów ani zawartości plików. Sam fakt, że coś zostało zrobione, nie jak to
  zostało zrobione.
- Wpisy są numerowane i dopisywane **w kolejności chronologicznej**, w miarę
  jak są podejmowane w trakcie wykonywania kroków Etapu 1.
- Każdy wpis to jedno zdanie — krótki opis decyzji/działania, bez uzasadnień
  technicznych (te trafiają do pliku wynikowego Etapu 1, patrz "Format
  wyjścia Etapu 1").
- Dla dużych fragmentów wykonywanych iteracyjnie: każda iteracja (Analiza →
  Implementacja) jest oznaczona w logu nagłówkiem `## Iteracja N`, a wpisy
  numerowane są od nowa w ramach iteracji.
- Jeśli użytkownik przerwie iterację, przerwanie jest odnotowane jako
  ostatni wpis w bieżącej iteracji, bez domysłów co do przyczyny.

Przykład (fragment za duży, granulacja dynamiczna, dwie iteracje, druga
przerwana przez użytkownika):

```markdown
# Log Etapu 1 — <fragment/moduł>

## Iteracja 1

1. Sprawdzenie fragmentu kodu pod kątem możliwości napisania testu.
2. Fragment za duży — konieczna większa granulacja.
3. Pytanie do użytkownika o wybór granulacji (opcja dynamiczna była zaznaczona).
4. Wypisano zależności blokujące testowalność dla podfragmentu 1.
5. Zaproponowano najmniejszą możliwą zmianę (seam) dla podfragmentu 1.
6. Propozycja zapisana do pliku wynikowego, zatwierdzona przez użytkownika.
7. Napisano test charakteryzujący dla podfragmentu 1.
8. Wprowadzono seam (extract method) dla podfragmentu 1.
9. Wynik iteracji sprawdzony i potwierdzony przez użytkownika.

## Iteracja 2

1. Wypisano zależności blokujące testowalność dla podfragmentu 2.
2. Zaproponowano najmniejszą możliwą zmianę (seam) dla podfragmentu 2.
3. Użytkownik przerwał iterację przed zatwierdzeniem propozycji.
```

### Format wyjścia Etapu 1

Lokalizacja: katalog wynikowy skilla (patrz "Katalog wynikowy skilla" w
konfiguracji wstępnej).

Struktura pliku/sekcji zależy od wyboru dokonanego w Pytaniu 1:

- **Opcja A (osobny plik na etap):** plan zapisywany w `etap1-plan.md`.
- **Opcja B (jeden zbiorczy plik):** plan to sekcja `## Etap 1` w pliku
  zbiorczym `refactor-plan.md`, dopisywana/rozbudowywana w miarę postępu
  iteracji.
- **Dodatkowy plik szczegółowy per iteracja** (tylko jeśli użytkownik wybrał
  tę opcję w Pytaniu 1): po zakończeniu każdej iteracji, niezależnie od logu
  (`etap1-decisions-log.md`), powstaje plik `etap1-iteracja-N-zmiany.md` ze
  szczegółowym opisem zmian tej iteracji. Log pozostaje przy tym wyłącznie
  listą decyzji — bez treści merytorycznej.

Struktura planu (niezależna od wyboru A/B), sekcje w kolejności:

1. **Fragment** — wskazanie metody/klasy/modułu objętego iteracją.
2. **Zależności blokujące** — lista zidentyfikowanych zależności blokujących
   testowalność, wraz z typem seamu proponowanym dla każdej z nich.
3. **Proponowany seam** — opis najmniejszej możliwej zmiany umożliwiającej
   test, bez ruszania logiki biznesowej.
4. **Test charakteryzujący** — opis zakresu/przypadków, jakie ma pokryć test
   (bez treści kodu — kod trafia bezpośrednio do pliku testowego, nie do
   planu).
5. **Do akceptacji** — jawne pytanie do użytkownika kończące Fazę Analizy tej
   iteracji.

### Decyzje (rozstrzygnięte)

- **Fizyczne wykonanie zmian w Etapie 1:** Tak — po zatwierdzeniu propozycji
  przez użytkownika Etap 1 fizycznie wprowadza seam (extract method / extract
  interface + DI), ale wyłącznie w zakresie umożliwiającym testowanie
  (behavior-preserving). Etap 1 nie jest miejscem na głębokie zmiany
  strukturalne ani zmianę logiki biznesowej — jego jedynym celem jest
  przygotowanie bezpiecznego miejsca do testowania. Głębszy refaktor należy
  do Etapu 2/3.
- **Jednostka Etapu 1:** Zależna od granulacji ustalonej w Pytaniu 0
  konfiguracji wstępnej (metoda / klasa / kontroler-moduł / automatyczna /
  dynamiczna) — nie jest sztywno ograniczona do pojedynczej metody.
- **Strategia seamu:** Skill wybiera strategię samodzielnie (na podstawie
  katalogu technik Feathersa), ale użytkownik może ją zakwestionować. Po
  zakończeniu pierwszej iteracji danego fragmentu skill pyta wprost, czy
  zastosowany sposób rozwiązania jest właściwy — użytkownik może wtedy
  narzucić własne reguły na potrzeby kolejnych iteracji (patrz krok 3 Fazy
  Implementacji).
- **Framework testowy i izolacja zależności statycznych:** Framework
  testowy ustalany w Pytaniu 0 (dla tego projektu: NUnit). Domyślne
  podejście do seamów: interfejs + Dependency Injection. Jeśli w projekcie
  nie ma kontenera DI — używamy fabryk (Factory), żeby nie wprowadzać
  dodatkowej zależności i nie komplikować rozwiązania. Microsoft Fakes/Shims
  nie jest strategią domyślną — rozważane wyłącznie w ostateczności, gdy
  klasyczne DI/interfejs/fabryka nie dają się zastosować bez naruszenia
  zasady najmniejszej możliwej zmiany.

### Flaga trybu testowego (`test`)

Flaga włącza tryb sprawdzania wykonalności kroków skilla — weryfikowany jest
przebieg działania narzędzia (czy dany punkt da się wykonać), nie
merytoryczna poprawność wyniku.

- Konfiguracja podstawowa (Pytania 0–2) ustawiana jest normalnie, bez zmian.
- Wyjście z Etapu 1 domyślnie przyjmuje wynik "sukces", niezależnie od
  faktycznego rezultatu weryfikacji.
- To wstęp do systemu ocennego oceniającego działanie narzędzia (poprawność
  przepływu), a nie konkretne wyniki refaktoryzacji.

Zastosowanie flagi w kolejnych etapach oraz pełna integracja z Konfiguracją
wstępną — do zdefiniowania w kolejnej iteracji.

---

## Etap 2 — Wprowadzenie zmiany (Refaktor i/lub Zmiana logiki)

### Brama wejściowa (warunek uruchomienia)

Etap 2 uruchamia się dopiero po zakończeniu Etapu 1 **i** po jawnej akceptacji
przez użytkownika wyniku Etapu 1 (utworzone unit testy do istniejącego kodu
i/lub zmiany umożliwiające testowanie — seamy, extract method/interface).
Brak akceptacji = brak startu Etapu 2.

Etap 2 to już konkretne zmiany w kodzie. Zmiana jest bezpieczna, ponieważ
istnieje siatka testów z Etapu 1, względem której można weryfikować skutki.

### Pytanie startowe Etapu 2 — Rodzaj zmiany

Zanim ruszy jakakolwiek zmiana kodu, użytkownik wybiera jedną z opcji:
- **Refaktor** — wyłącznie zmiana struktury kodu, zachowanie bez zmian
  (behavior-preserving).
- **Zmiana logiki** — zmiana zachowania biznesowego.
- **Oba** — refaktor i zmiana logiki razem.

**Reguła rozgałęzienia:** jeśli wybór zawiera zmianę logiki (opcja "Zmiana
logiki" lub "Oba"), Etap 2 **staje się etapem wprowadzenia zmiany logiki** i
zawęża się wyłącznie do niej. Refaktoryzacja nie jest wtedy wykonywana
w Etapie 2 — zostaje odroczona i przechodzi do Etapu 3, który staje się
dedykowanym etapem refaktoryzacji rezultatu Etapu 2. Jeśli wybrano samą opcję
"Refaktor" (bez zmiany logiki), ta reguła się nie stosuje i Etap 2 pozostaje
czystym refaktorem — przebiega wtedy według sekcji "Wariant Refaktor" niżej.

### Wariant "Zmiana logiki" *(w budowie)*

Ścieżka uruchamiana, gdy w pytaniu startowym wybrano "Zmiana logiki" lub "Oba".

**Krok wejściowy — opis zmiany od użytkownika.** Zanim ruszy cokolwiek innego,
użytkownik skilla wprowadza opis zmiany, obejmujący:
- czego dotyczą zmiany (opis merytoryczny),
- jakich części systemu / kodu dotykają,
- jakie są przewidziane granice zmian (co jest poza zakresem),
- co jest sednem problemu, który zmiana ma rozwiązać.

Opis jest wejściem dla wszystkich dalszych kroków tego wariantu i trafia do
pliku wynikowego Etapu 2.

**Status: w budowie.** Dalszy przebieg wariantu (kroki po opisie wejściowym,
sposób weryfikacji względem testów z Etapu 1, tryb aktualizacji testów) nie
jest jeszcze ustalony — do zdefiniowania w kolejnej iteracji. Do tego czasu
skill po zebraniu opisu wejściowego zatrzymuje się z adnotacją "w budowie"
i czeka na decyzję użytkownika.

Poniższa lista to **wstępny zarys do rewizji**, nie zatwierdzony przebieg:

1. Zakres Etapu 2 zawężony wyłącznie do zmiany logiki biznesowej — bez
   refaktoryzacji struktury.
2. Wprowadź zmianę logiki zgodnie z ustaleniami z użytkownikiem.
3. Uruchom testy z Etapu 1 (testy charakteryzujące zachowanie sprzed zmiany).
4. Dla każdego testu, który przestał przechodzić w wyniku zmiany logiki:
   odnotuj to jawnie i zweryfikuj z użytkownikiem, czy to zamierzona zmiana
   zachowania (wtedy test wymaga aktualizacji) czy niezamierzony efekt uboczny
   (wtedy to błąd do poprawy, nie do zaakceptowania jako nowy stan).
5. Nie wykonuj żadnej zmiany strukturalnej/refaktoryzacyjnej w tym kroku —
   nawet jeśli przy okazji widać oczywisty refaktor. Odnotuj taką obserwację
   do rozważenia w Etapie 3, ale nie realizuj jej teraz.

### Wariant "Refaktor" (bez zmiany logiki)

Ścieżka uruchamiana, gdy w pytaniu startowym wybrano wyłącznie "Refaktor".
Etap 2 koncentruje się wtedy na dwóch rzeczach naraz: na **zmianach w kodzie**
i na **testach tych zmian** — każda zmiana jest natychmiast weryfikowana
siatką testów z Etapu 1.

Wariant dzieli się na **pod-etapy (kroki)** wykonywane po kolei, zgodnie
z zasadami Fowlera, Feathersa i clean code (patrz "Podstawa metodyczna").
Każdy krok kończy się sprawdzeniem/potwierdzeniem przez użytkownika, zanim
ruszy następny.

#### Krok 1 — Czytelność (nazewnictwo)

Cel: doprowadzić nazwy do zgodności z tym, co kod **faktycznie** robi. Bez
zmiany zachowania.

1. Popraw nazwy zmiennych, nazwy metod i nazwy klas tak, aby odpowiadały ich
   rzeczywistej odpowiedzialności — nie temu, co sugeruje nazwa historyczna.
2. Nie zmieniaj zachowania. Ten krok to wyłącznie rename
   (behavior-preserving), żadnych zmian struktury ani logiki.
3. **Sprzężenie z Etapem 1 (obowiązkowe).** Zmiana nazwy metody lub klasy
   objętej testami z Etapu 1 spowoduje, że te testy przestaną się
   kompilować/przechodzić. To skutek zamierzony, nie regresja. Postępowanie:
   - poinformuj użytkownika wprost, które testy przestały przechodzić i przez
     którą zmianę nazwy — użytkownik **musi** zostać o tym poinformowany,
   - wróć do zakresu Etapu 1 i zaktualizuj te testy: wyłącznie nazwy, bez
     zmiany asercji, danych wejściowych ani zakresu testu,
   - aktualizacja testów wymaga **ręcznego potwierdzenia użytkownika**; bez
     niego skill nie modyfikuje testów z Etapu 1.

   To jedyny przypadek w wariancie "Refaktor", w którym niezaliczony test nie
   jest sygnałem regresji — rozstrzygnięcie w "Regule niezaliczonego testu".
4. **Efekt uboczny wykorzystywany w dalszych krokach:** zmiana nazwy ujawnia
   zasięg zmiany — pokazuje wszystkie miejsca w kodzie odwołujące się do
   zmienianego elementu. Ta lista miejsc jest wejściem dla kolejnych kroków
   (ocena rzeczywistego zakresu refaktoru) i trafia do pliku wynikowego
   Etapu 2.

#### Kolejne kroki *(do zdefiniowania)*

Podział wariantu "Refaktor" na dalsze pod-etapy (po kroku 1) — do ustalenia
w kolejnej iteracji.

#### Reguła niezaliczonego testu (obowiązuje we wszystkich krokach)

1. Uruchom testy z Etapu 1 po każdej wprowadzonej zmianie cząstkowej.
2. Test przestał przechodzić **z powodu zmiany nazwy** (krok 1) → aktualizacja
   nazw w teście po ręcznym potwierdzeniu użytkownika (patrz krok 1, punkt 3).
3. Test przestał przechodzić **z jakiegokolwiek innego powodu** → to sygnał
   regresji (zmiana zachowania tam, gdzie miało go nie być), nieakceptowalny
   wynik refaktoru. Zatrzymaj się i zgłoś to użytkownikowi zamiast kontynuować
   lub modyfikować test pod nowy wynik.
4. Kontynuuj małymi krokami (behavior-preserving), aż do zakończenia
   zaplanowanego kroku.

### Log Etapu 2 (`etap2-decisions-log.md`)

Osobny plik logu, analogicznie do Etapu 1 — nie mieszać z logiem konfiguracji
wstępnej ani z logiem Etapu 1. Te same zasady prowadzenia: wyłącznie decyzje
i wybory, żadnego kodu ani diffów, wpisy numerowane chronologicznie, w miarę
jak są podejmowane.

Log musi jednoznacznie odnotować na starcie, który wariant został wybrany
(Refaktor / Zmiana logiki / Oba → zawężone do Zmiana logiki), ponieważ od
tego zależy, czy Etap 3 zostanie uruchomiony jako refaktoryzacja rezultatu.

Dodatkowo, dla wariantu "Refaktor": wpisy grupowane są nagłówkiem
`## Krok N` (pod-etap), a każde ręczne potwierdzenie aktualizacji testów
z Etapu 1 (po zmianie nazw) jest odnotowane jako osobny wpis.

### Format wyjścia Etapu 2

*(do ustalenia — placeholder, uzupełnić, analogicznie do Etapu 1)*

### Otwarte pytania (Etap 2)

- [ ] Czy przy wariancie "Zmiana logiki" testy z Etapu 1, które trzeba
      zaktualizować, aktualizuje LLM automatycznie po potwierdzeniu przez
      użytkownika, czy to zawsze osobny krok wymagający akceptacji per test?
- [ ] Czy plik wynikowy Etapu 2 (analogiczny do planu z Etapu 1) też wymaga
      akceptacji przed wprowadzeniem zmiany, zgodnie z zasadą "brak zmian bez
      pliku .md" z Pytania 0, czy dla Etapu 2 obowiązuje inny tryb?

---

## Etap 3 — Refaktoryzacja rezultatu Etapu 2 *(do zdefiniowania)*

Uruchamiany warunkowo: tylko wtedy, gdy w Etapie 2 wybrano wariant zawierający
zmianę logiki ("Zmiana logiki" lub "Oba"), przez co refaktoryzacja została
tam odroczona. Etap 3 przejmuje wtedy refaktoryzację kodu w stanie **po**
zmianie logiki z Etapu 2, wykorzystując zaktualizowaną siatkę testów jako
podstawę bezpieczeństwa zmian.

Jeśli w Etapie 2 wybrano wyłącznie wariant "Refaktor", ten warunek nie
zachodzi — zasady uruchomienia Etapu 3 w takim przypadku do zdefiniowania
osobno, później.

Szczegóły kroków, logu i formatu wyjścia — do zdefiniowania w kolejnej
iteracji.
