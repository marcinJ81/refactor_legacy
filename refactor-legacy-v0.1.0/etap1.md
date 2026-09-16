# Etap 1 — Przygotowanie "placu boju" (Characterization + Seams)

Uruchamiany przez orkiestratora (`orkiestrator.md`) wiadomością `stage.start`.
Konfiguracja wstępna przychodzi w `payload.config` — Etap 1 jej nie zbiera.

Cel etapu: umożliwić bezpieczne wprowadzenie zmiany poprzez objęcie fragmentu
testem charakteryzującym (characterization test — dokumentuje **aktualne**
zachowanie kodu, niezależnie od tego, czy jest ono poprawne) oraz odsprzęgnięcie
(decoupling) zależności blokujących testowalność.

## Tryby pracy Etapu 1

Etap 1 działa w dwóch trybach, zależnie od wiadomości od orkiestratora:

| Wiadomość | Tryb |
|---|---|
| `stage.start` | **Tryb pełny** — cykl Analiza → Implementacja (opis niżej) |
| `task.execute` | **Tryb zadaniowy** — pojedyncze zadanie na testach zlecone przez inny etap (patrz "Tryb zadaniowy") |

## Wejście z orkiestratora

Przed rozpoczęciem **każdej kolejnej iteracji** (Faza Analizy każdej iteracji)
Etap 1 wczytuje na nowo z dysku `refactor-decisions.md` (ustalenia z Pytań 0–2
oraz format znacznika czasu obowiązujący w logach).
Etap nie musi trzymać konfiguracji w pamięci między iteracjami ani między
wywołaniami — plik jest źródłem prawdy i przypominajką. Orkiestrator
niezależnie weryfikuje ten plik względem swojego snapshotu po zakończeniu
etapu (patrz "Kontrola integralności" w `orkiestrator.md`).

## Struktura wewnętrzna: Faza Analizy i Faza Implementacji

Etap 1 — jak każdy kolejny etap tego harnessu — dzieli się na dwie fazy:
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
charakteryzującymi). Etap wysyła wtedy do orkiestratora `stage.done`.

Użytkownik może przerwać iterację w dowolnym momencie, po dowolnej fazie —
przerwanie nie wymaga uzasadnienia. Log Etapu 1 odnotowuje przerwanie jako
ostatni wpis, a do orkiestratora idzie `stage.aborted`.

## Faza Analizy — kroki

1. **Ocena testowalności fragmentu**
   - Czy zmieniany fragment (metoda/funkcja) da się objąć unit testem
     bez modyfikacji kodu? Testujemy **zachowanie**, nie implementację.
   - Jeśli tak → przejdź do Fazy Implementacji, krok 1 (napisz test na obecny
     stan).
   - Jeśli nie → przejdź do kroku 2 poniżej.
   - Jeśli w konfiguracji wstępnej (Pytanie 0) wybrano granulację **dynamiczną**:
     jeśli fragment okaże się zbyt duży/złożony, aby objąć go jedną spójną
     iteracją Fazy Analizy, zatrzymaj się tutaj — wyślij do orkiestratora
     `user.input` z opisem, co dokładnie jest za duże i dlaczego (pod kątem
     wprowadzenia unit testów), i poczekaj na decyzję użytkownika (np. podział
     na mniejsze podfragmenty i przejście na tryb iteracyjny) zamiast
     kontynuować samodzielnie. To jest ten określony krok, w którym dla
     granulacji dynamicznej musi paść pytanie o zakres zmian, zanim powstanie
     jakikolwiek test.

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
     niżej) i czeka na **zatwierdzenie przez użytkownika** (`user.approval`)
     — to jest koniec Fazy Analizy dla danej iteracji. Bez zatwierdzenia Faza
     Implementacji się nie rozpoczyna.

4. **Gdy odsprzęgnięcie bez zmiany logiki nie jest możliwe**
   - Jeśli żadna propozycja seamu z kroku 3 nie pozwala objąć fragmentu
     testem bez ingerencji w logikę biznesową, przedstaw użytkownikowi do
     wyboru poniższe kierunki. Wybór jest obowiązkowy i odnotowywany w logu
     Etapu 1.

   - **Opcja 1 — Zakończenie działania harnessu.** Praca nad fragmentem zostaje
     zakończona z adnotacją: sensowne napisanie testów nie jest możliwe,
     złożoność kodu wymusza zmianę logiki.

   - **Opcja 2 — Zakończenie z decyzją użytkownika.** Ta sama adnotacja co
     w Opcji 1, ale etap nie kończy pracy samodzielnie — przedstawia
     sytuację i czeka na decyzję użytkownika co do dalszego kierunku.

   - **Opcja 3 — Opakowanie w dodatkową abstrakcję.** Stosowana, gdy problem
     dotyczy całego modułu, dużej klasy lub metody. Problematyczny kod
     zostaje opakowany w dodatkową abstrakcję, co pozwala wprowadzić
     przełącznik kierujący sterowanie do nowej implementacji — stara
     struktura pozostaje nietknięta. Nowa implementacja powstaje w podejściu
     TDD. Po wyborze tej opcji i wskazaniu frameworka do mocków etap
     zatrzymuje się z adnotacją "w budowie" — dalsze rozwinięcie (przebieg
     TDD, dobór mocków) zamknięte do kolejnej iteracji.

   - **Opcja 4 — Jak Opcja 3, z pytaniem o kierunek zmian.** Ta sama
     technika (abstrakcja + przełącznik), ale przed jej zastosowaniem etap
     pyta użytkownika, czy celem jest: (a) refaktor przez przepisanie
     starego rozwiązania na nowe, zachowanie bez zmian, czy (b) zmiana
     logiki/funkcjonalności realizowana równolegle z refaktorem. Kierunek
     wybiera użytkownik.

## Faza Implementacji — kroki

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
     zamknięcie Etapu 1 (kompletne środowisko testowe dla całego zakresu)
     i `stage.done` do orkiestratora.

## Tryb zadaniowy (`task.execute`)

Uruchamiany, gdy orkiestrator przekazuje zadanie zlecone przez inny etap
(najczęściej Etap 2 w trakcie kroków refaktoru). Etap 1 jest **jedynym
miejscem**, w którym powstają i zmieniają się testy — inne etapy nie ruszają
testów samodzielnie, tylko wystawiają request.

Obsługiwane zadania:

| `action` | Co robi Etap 1 |
|---|---|
| `test.update` | Aktualizuje istniejące testy w zakresie wskazanym w `payload.allowed_scope` |
| `test.add` | Dopisuje nowy test charakteryzujący dla wskazanego zakresu |
| `test.remove` | Usuwa test, który stał się zbędny, po uzasadnieniu w payloadzie |
| `test.mock.enable` | Włącza obsługę mocków w projekcie testowym, jeśli nie była jeszcze włączona (patrz "Mocki w testach") |
| `test.mock.add` | Dodaje mock/stub dla wskazanej zależności w istniejących lub nowych testach |

Zasady trybu zadaniowego:

1. **Zakres wykonania jest ograniczony payloadem.** Wykonuj wyłącznie to, co
   dopuszcza `payload.allowed_scope`; nie ruszaj tego, co wymienia
   `payload.forbidden`. Przykład dla `rename_only`: zmieniasz w teście nazwy
   metod/klas, **nie** asercje, **nie** dane wejściowe, **nie** zakres testu.
2. **Transparentność przed wykonaniem.** Jeśli wiadomość ma
   `requires_user_ack: true`, użytkownik musi zobaczyć `user_message`
   (co jest czerwone i dlaczego) **zanim** cokolwiek zostanie zmienione.
   Za pokazanie odpowiada orkiestrator; Etap 1 nie startuje przed jego
   zgodą na kontynuację.
3. **Wykonanie jest automatyczne.** Po pokazaniu informacji Etap 1 wykonuje
   zadanie sam — nie prosi o zatwierdzenie linia po linii.
4. **Uruchom testy po zmianie** i zaraportuj wynik w `payload.result`.
5. **Odpowiedź** to `type: "response"` ze statusem `done` / `failed` /
   `needs_user`, z opisem, co konkretnie zmieniono (pliki, testy, rodzaj
   zmiany) — bez treści kodu.
6. **Każde zadanie jest odnotowane w logu Etapu 1** jako osobny wpis, z
   oznaczeniem, który etap je zlecił i pod jakim `corr_id`.

## Mocki w testach

Do końca Kroku 2 Etapu 2 testy z Etapu 1 mogą działać bez żadnego frameworka
mockującego. Zmienia się to w **Kroku 3 Etapu 2** (przerwanie zależności): gdy
zależności od systemów zewnętrznych trafiają do konstruktora, testy muszą móc
podstawić w ich miejsce mock albo stub. Jeśli projekt testowy nie miał wcześniej
włączonej obsługi mocków, trzeba ją włączyć — i to należy do Etapu 1, bo Etap 1
jest jedynym właścicielem testów i ich obudowy.

**Zadanie `test.mock.enable`:**

1. Sprawdź, czy w projekcie testowym jest już używany framework mockujący
   (referencje w `.csproj`, istniejące użycia w testach). Analogicznie do
   logiki ustalania frameworka testowego z Pytania 0.
2. Jeśli **jest** — używaj go, nie wprowadzaj drugiego.
3. Jeśli **nie ma** — nie wybieraj samodzielnie. Wystaw `user.input`
   z pytaniem, którego frameworka użyć, i z informacją, co wymusiło ten wybór
   (która zależność, w którym kroku Etapu 2). Czekaj na decyzję użytkownika.
4. Jeśli w projekcie jest **więcej niż jeden** framework mockujący — przedstaw
   znalezione i zapytaj, którego użyć dla testów objętych tym refaktorem.
5. Wybór (wraz z uzasadnieniem, kto go podjął) trafia do logu Etapu 1 i do
   pliku wynikowego Etapu 1. Kolejne zadania `test.mock.*` już nie pytają —
   korzystają z ustalonego wyboru.
6. Włączenie obsługi mocków samo w sobie nie zmienia zachowania testów.
   Po jego wprowadzeniu uruchom testy i zaraportuj wynik.

**Zadanie `test.mock.add`:**

1. Zakres wyznacza `payload` — konkretna zależność (typ/interfejs) przeniesiona
   do konstruktora oraz testy, które przez to przestały się kompilować lub
   przechodzić.
2. Podstaw mock/stub tak, żeby test **zachował dotychczasowe zachowanie
   sprawdzane asercjami**. Mock ma odtwarzać to, co dotąd robiła prawdziwa
   zależność w tym teście — nie jest okazją do zmiany oczekiwań.
3. `allowed_scope` typowo obejmuje `constructor_injection` i `mock_setup`;
   `forbidden` typowo obejmuje `assert_change` i `test_scope_change`. Zakres
   z payloadu jest wiążący.
4. Jeśli odtworzenie dotychczasowego zachowania zależności nie jest możliwe bez
   wiedzy, której nie ma w kodzie (np. co dokładnie zwracało zewnętrzne API
   w danym scenariuszu) — **nie zgaduj**. Wystaw `user.input` z opisem, czego
   brakuje.
5. Jeśli obsługa mocków nie jest jeszcze włączona, `test.mock.add` najpierw
   wywołuje ścieżkę `test.mock.enable`.

## Log Etapu 1 (`etap1-decisions-log.md`)

Każde uruchomienie Etapu 1 (dla danego fragmentu) prowadzi własny, osobny plik
logu, oddzielny od logu konfiguracji wstępnej (`refactor-decisions.md`) i od
logu orkiestratora. Nie mieszać zawartości tych plików.

Zasady prowadzenia logu:
- Log zawiera **wyłącznie decyzje i wybory** — żadnego kodu, diffów, treści
  testów ani zawartości plików. Sam fakt, że coś zostało zrobione, nie jak to
  zostało zrobione.
- Wpisy są numerowane i dopisywane **w kolejności chronologicznej**, w miarę
  jak są podejmowane w trakcie wykonywania kroków Etapu 1.
- **Każdy wpis jest poprzedzony znacznikiem daty i godziny** w formacie
  `yyyy-MM-dd; HH-mm-ss` wczytanym z `refactor-decisions.md` (patrz "Znaczniki
  czasu w logach" w `orkiestrator.md`). Pierwszym wpisem każdego uruchomienia
  Etapu 1 jest nagłówek `## Uruchomienie <znacznik>` z datą i godziną startu
  etapu. Bez tych znaczników Etap 0 nie rozpozna, do której sesji należą wpisy.
- Każdy wpis to jedno zdanie — krótki opis decyzji/działania, bez uzasadnień
  technicznych (te trafiają do pliku wynikowego Etapu 1, patrz "Format
  wyjścia Etapu 1").
- Dla dużych fragmentów wykonywanych iteracyjnie: każda iteracja (Analiza →
  Implementacja) jest oznaczona w logu nagłówkiem `### Iteracja N` (wewnątrz
  nagłówka uruchomienia), a wpisy numerowane są od nowa w ramach iteracji.
- Zadania z trybu zadaniowego trafiają pod nagłówek `### Zadania zlecone`,
  z podaniem etapu zlecającego i `corr_id`.
- Jeśli użytkownik przerwie iterację, przerwanie jest odnotowane jako
  ostatni wpis w bieżącej iteracji, bez domysłów co do przyczyny.

Przykład (fragment za duży, granulacja dynamiczna, dwie iteracje, druga
przerwana przez użytkownika):

```markdown
# Log Etapu 1 — <fragment/moduł>

## Uruchomienie 2026-08-30; 17-05-12

### Iteracja 1

2026-08-30; 17-05-30 — 1. Sprawdzenie fragmentu kodu pod kątem możliwości napisania testu.
2026-08-30; 17-06-02 — 2. Fragment za duży — konieczna większa granulacja.
2026-08-30; 17-06-40 — 3. Pytanie do użytkownika o wybór granulacji (opcja dynamiczna była zaznaczona).
2026-08-30; 17-12-18 — 4. Wypisano zależności blokujące testowalność dla podfragmentu 1.
2026-08-30; 17-15-03 — 5. Zaproponowano najmniejszą możliwą zmianę (seam) dla podfragmentu 1.
2026-08-30; 17-21-49 — 6. Propozycja zapisana do pliku wynikowego, zatwierdzona przez użytkownika.
2026-08-30; 17-28-11 — 7. Napisano test charakteryzujący dla podfragmentu 1.
2026-08-30; 17-33-27 — 8. Wprowadzono seam (extract method) dla podfragmentu 1.
2026-08-30; 17-40-05 — 9. Wynik iteracji sprawdzony i potwierdzony przez użytkownika.

### Iteracja 2

2026-08-30; 17-41-00 — 1. Wypisano zależności blokujące testowalność dla podfragmentu 2.
2026-08-30; 17-45-22 — 2. Zaproponowano najmniejszą możliwą zmianę (seam) dla podfragmentu 2.
2026-08-30; 17-58-40 — 3. Użytkownik przerwał iterację przed zatwierdzeniem propozycji.

### Zadania zlecone

2026-08-30; 18-20-14 — 1. Etap 2 (corr_id e2-k1-007) — zaktualizowano nazwy w 3 testach po zmianie nazwy metody.
2026-08-30; 18-49-51 — 2. Etap 2 (corr_id e2-k3-002) — włączono obsługę mocków w projekcie testowym (framework wskazany przez użytkownika).
2026-08-30; 18-55-30 — 3. Etap 2 (corr_id e2-k3-005) — dodano stub IOrderRepository w 4 testach po przeniesieniu zależności do konstruktora.
```

## Format wyjścia Etapu 1

Lokalizacja: katalog wynikowy (patrz "Katalog wynikowy"
w `orkiestrator.md`).

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

## Decyzje (rozstrzygnięte)

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
- **Strategia seamu:** Etap wybiera strategię samodzielnie (na podstawie
  katalogu technik Feathersa), ale użytkownik może ją zakwestionować. Po
  zakończeniu pierwszej iteracji danego fragmentu etap pyta wprost, czy
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
- **Własność testów:** Etap 1 jest jedynym miejscem, w którym powstają,
  zmieniają się i są usuwane testy. Inne etapy zlecają to przez orkiestratora.
