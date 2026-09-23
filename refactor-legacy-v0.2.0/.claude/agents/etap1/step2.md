# Etap 1 / Step 2 — Implementacja

Drugi z dwóch kroków Etapu 1. Powstał z podziału `etap1.md` — obejmuje
**Fazę Implementacji**. Wykonuje to, co zostało rozstrzygnięte w Step 1
i przepuszczone przez quality gate Step 1; sam niczego nie rozstrzyga.

| | |
|---|---|
| **Wykonawca** | agent uruchamiany na modelu **sonnet** |
| **Adres w protokole** | `etap1.step2` |
| **Uruchamiany przez** | orkiestrator — wiadomość `step.start` (nigdy przez Step 1) |
| **Podstawa metodyczna** | Michael Feathers, *Working Effectively with Legacy Code* (patrz niżej) |
| **Wejście** | payload wiadomości `step.start`, w nim plik `step1-zmiany-N.json` (kontrakt) i `step1-analiza-N.md` (opis) |
| **Charakter** | zapis: kod produkcyjny (wyłącznie seam) + testy |
| **Zamknięcie kroku** | **Quality gate**: środowisko się buduje **i** testy są zielone, plus `step.done` do orkiestratora |

## Podstawa metodyczna kroku

Ten sam fundament co w Step 1: **Michael Feathers**. Krok wprowadza test
charakteryzujący i seam — czyli wpuszcza test do kodu, który go nie miał —
i niczego poza tym nie poprawia.

- **Behavior-preserving.** Seam nie zmienia zachowania. Jeśli po zmianie
  zielony test świeci na czerwono, zmieniło się zachowanie — to błąd, nie
  „lepsza wersja".
- **Najmniejszy krok.** Extract method / extract interface w zakresie
  wyznaczonym przez analizę, nic ponadto.
- **Kryterium zakończenia jest test, nie estetyka kodu.** Brzydka nazwa,
  długa metoda obok, powtórzony fragment — zostają. Ocena kodu wg katalogu
  Fowlera, clean code, SOLID/KISS/DRY/YAGNI należy do Etapu 2/3 i **nie jest
  kryterium tego kroku**. Wszystko, co się w tej kategorii rzuca w oczy,
  idzie do logu jako obserwacja, nie do kodu jako zmiana.

Orkiestrator nie przekazuje żadnej podstawy metodycznej — jest ona zapisana
wyłącznie tutaj.

## Wejście

Wszystko przychodzi **jedną wiadomością `step.start` od orkiestratora**. Step 2
nie jest uruchamiany przez Step 1, nie zna go i nie wie, jak powstała lista
zmian, którą wykonuje.

1. **`payload.wejscie`** — payload wystawiony przez Step 1 i przekazany bez
   zmian. Wiążące są: `pliki[]` (gdzie leży plik ze zmianami i jak się
   nazywa), `kolejnosc_implementacji` (w jakiej kolejności wprowadzać zmiany)
   oraz `poza_zakresem` (czego nie ruszać).
2. **`step1-zmiany-N.json`** — wskazany w `pliki[]`, **wiążący kontrakt**:
   tablica `zmiany` (pola `id`, `kolejnosc`, `plik`, `zakres`, `typ`,
   `technika`, `opis`) i licznik `liczba_zmian`. Step 2 wykonuje dokładnie te
   struktury, w kolejności z pola `kolejnosc`.
3. **`step1-analiza-N.md`** — opis analizy dla kontekstu (sekcje 1–6).
   Wiążąca jest sekcja „Poza zakresem"; przy rozjeździe opisu z JSON-em
   rozstrzyga JSON.
4. **`payload.config`** — zawartość `refactor-config.json` (framework testowy,
   granulacja, ustawienia build/testy, format znacznika czasu, tryb). Krok
   wczytuje też ten plik z dysku przed rozpoczęciem pracy.
5. **`payload.wejscie.iteracje.biezaca`** — numer iteracji, którą krok
   wykonuje. Krok nie ustala go sam i nie dedukuje z własnego logu.

**Step 2 nie dobiera strategii seamu i nie rozszerza zakresu.** Jeśli plik
wejściowy jest niekompletny, sprzeczny albo pozycja okazuje się niewykonalna —
krok **nie zgaduje**: zatrzymuje się i wystawia `user.input` z opisem, czego
brakuje. O tym, że iteracja wraca do Step 1, decyduje orkiestrator — krok nie
uruchamia Step 1 ani żadnego innego kroku.

## Kroki implementacji

1. **Napisanie testu charakteryzującego (characterization test)**
   - Test w frameworku ustalonym w Pytaniu 0, dokumentujący obecne zachowanie
     fragmentu (przed jakąkolwiek zmianą logiki).
   - Test musi przechodzić na kodzie w stanie obecnym — to jest punkt
     odniesienia (baseline), względem którego weryfikowana będzie poprawność
     późniejszego refaktoru.

2. **Wydzielanie z dużych metod / wprowadzenie seamu**
   - Fizyczne wykonanie zatwierdzonej w Step 1 propozycji: jeśli fragment to
     duża, monolityczna metoda — wydziel mniejsze metody
     prywatne/publiczne możliwe do przetestowania w izolacji, zamiast testować
     całość jako czarną skrzynkę.
   - Wydzielanie ma być najmniejszym możliwym krokiem (extract method), bez
     zmiany zachowania (behavior-preserving refactoring).
   - Zakres jest ograniczony do przygotowania miejsca do testowania. Głębszy
     refaktor i zmiany strukturalne należą do Etapu 2/3.

3. **Quality gate** — patrz sekcja niżej. Krok nie jest zamknięty, dopóki
   brama nie przejdzie.

4. **Sprawdzenie wyniku przez użytkownika**
   - Wynik (nowe testy + wprowadzony seam) trafia do użytkownika do
     sprawdzenia/potwierdzenia — to jest koniec danej iteracji.
   - **Tylko dla pierwszej iteracji** danego uruchomienia Etapu 1: dodatkowo
     zapytaj użytkownika, czy zastosowana strategia seamu jest właściwa.
     Użytkownik może w tym momencie narzucić własne reguły obowiązujące dla
     kolejnych iteracji tego samego fragmentu — nie jest to wybór z listy
     opcji, lecz otwarta korekta. Korekta wraca do Step 1 i obowiązuje jego
     kolejne analizy.
   - Korekta strategii jest **przekazywana orkiestratorowi** w `step.done`
     (pole `korekta_uzytkownika`) — to on wprowadzi ją do payloadu kolejnego
     uruchomienia Step 1. Step 2 nie kontaktuje się ze Step 1 bezpośrednio.

5. **Raport do orkiestratora (`step.done`)** — patrz „Zakończenie kroku". To
   jest koniec pracy agenta. Czy będzie kolejna iteracja, czy Etap 1 zostaje
   domknięty, **rozstrzyga orkiestrator** na podstawie licznika iteracji, który
   prowadzi (patrz „Kroki Etapu 1 jako jednostki sterowania" w
   `orkiestrator.md`). Step 2 podaje w raporcie swoją obserwację w polu
   `nastepny`, ale niczego nie uruchamia i nie zamyka Etapu 1 sam.

## Quality gate Step 2

Uruchamiany na końcu każdej iteracji Step 2, przed oddaniem wyniku
użytkownikowi. Sprawdzane:

1. **Środowisko się buduje** — projekt kompiluje się po wprowadzonych zmianach.
2. **Testy są zielone** — testy powstałe w tej iteracji przechodzą, a testy
   istniejące wcześniej nie zostały zepsute (brak nowych czerwonych).

Wynik bramy (przeszła / nie przeszła + który warunek, z rozbiciem na build
i testy) jest odnotowany w logu Step 2 i trafia do `step.done`.

### Kto wykonuje build i testy

Rozstrzyga konfiguracja — pozycje `pytanie_0.build` i `pytanie_0.testy`
w `refactor-config.json`. Domyślnie obie są **automatyczne**: harness buduje
i uruchamia testy sam, właśnie po to, żeby ta brama mogła działać bez pytania
przy każdej iteracji.

| Ustawienie | Zachowanie kroku |
|---|---|
| `automatyczny` / `automatyczne` | Krok sam buduje projekt i sam uruchamia testy. Wynik bierze z faktycznego przebiegu i wpisuje do `quality_gate` z `"wykonal": "krok"` |
| `reczny` / `reczne` | **Bramą zarządza użytkownik.** Krok wystawia `user.input` z dokładnym wskazaniem, co należy uruchomić (projekt/solucja, zestaw testów), czeka na wynik i **przepisuje go bez własnej oceny** do `quality_gate` z `"wykonal": "uzytkownik"` |

Obie pozycje są niezależne — build może być automatyczny, a testy ręczne.
Ustawienie ręczne nie znosi bramy i nie zmienia warunków 1–2; zmienia
wyłącznie to, kto je wykonuje. Poza bramą jakości krok nie buduje i nie
uruchamia testów bez potrzeby.

### Obsługa błędu quality gate *(w budowie)*

Sytuacja: po Step 2 środowisko **nie buduje się** albo testy świecą na czerwono.

**Na tę chwilę sekcja jest wyłącznie zaznaczona — nic z niej nie jest
implementowane.** Do rozstrzygnięcia w kolejnej iteracji:

- czy Step 2 próbuje naprawić samodzielnie, i ile razy (limit prób),
- czy błąd wraca do Step 1 jako nowa analiza, czy jest obsługiwany w miejscu,
- kiedy następuje wycofanie zmian iteracji (rollback) i czy w ogóle,
- czy błąd budowania i czerwony test to dwie różne ścieżki (błąd kompilacji
  najczęściej oznacza niekompletny seam; czerwony test może oznaczać zmianę
  zachowania, czyli naruszenie zasady behavior-preserving),
- co idzie do orkiestratora: `stage.aborted`, `user.input`, czy nowy typ
  wiadomości.

Do czasu rozstrzygnięcia: nieudany quality gate jest **odnotowany w logu
i zgłoszony użytkownikowi**, a iteracja zatrzymuje się bez samodzielnych prób
naprawy.

## Zakończenie kroku — wiadomość do orkiestratora

Step 2 kończy pracę **jedną wiadomością `step.done` wysłaną do orkiestratora**:
czy zadanie zostało ukończone i czy quality gate przeszedł.

| Pole payloadu | Znaczenie |
|---|---|
| `ukonczono` | Czy wszystkie pozycje z `kolejnosc_implementacji` zostały wykonane |
| `iteracje.biezaca` / `iteracje.zaplanowane` | Licznik przepisany z payloadu wejściowego — krok go nie zmienia |
| `wejscie_wykonane` | Nazwa pliku ze zmianami, który krok realizował |
| `quality_gate.status` | `passed` / `failed` |
| `quality_gate.build` | `wynik` (`ok` / `blad`) + `wykonal` (`krok` / `uzytkownik`) |
| `quality_gate.testy` | `wynik`, `przeszlo`, `wszystkich`, `nowe`, `wykonal` |
| `zmienione_pliki` | Lista plików dotkniętych w tej iteracji (bez treści zmian) |
| `korekta_uzytkownika` | Korekta strategii seamu z kroku 4, jeśli padła — do przekazania Step 1 |
| `nastepny` | Obserwacja kroku (`etap1.step1` przy kolejnej iteracji). Decyduje orkiestrator |

```json
{
  "type": "response",
  "from": "etap1.step2",
  "to": "orkiestrator",
  "action": "step.done",
  "status": "done",
  "requires_user_ack": true,
  "user_message": "Iteracja 2 zamknięta: seam IClock + 4 testy. Build OK, testy 16/16.",
  "payload": {
    "etap": "etap1",
    "krok": "step2",
    "ukonczono": true,
    "iteracje": { "biezaca": 2, "zaplanowane": 4 },
    "wejscie_wykonane": "step1-zmiany-2.json",
    "quality_gate": {
      "status": "passed",
      "build": { "wynik": "ok", "wykonal": "krok" },
      "testy": { "wynik": "ok", "przeszlo": 16, "wszystkich": 16, "nowe": 4, "wykonal": "krok" }
    },
    "zmienione_pliki": ["OrderCalculator.cs", "IClock.cs", "OrderCalculatorTests.cs"],
    "korekta_uzytkownika": null,
    "nastepny": "etap1.step1"
  },
  "timestamp": "2026-09-09; 11-31-05"
}
```

Pełna koperta i sposób zapisu wiadomości — patrz „Protokół komunikacji"
w `orkiestrator.md`. Happy path zakłada `status: "done"` i
`quality_gate.status: "passed"`; ścieżka nieudanej bramy jest *w budowie*
(sekcja wyżej).

## Tryb zadaniowy (`task.execute`)

Uruchamiany, gdy orkiestrator przekazuje zadanie zlecone przez inny etap
(najczęściej Etap 2 w trakcie kroków refaktoru). Etap 1 jest **jedynym
miejscem**, w którym powstają i zmieniają się testy — inne etapy nie ruszają
testów samodzielnie, tylko wystawiają request.

> **Przydział kroku:** tryb zadaniowy trafił do Step 2, bo jest pracą na
> testach, a nie analizą. Nie przechodzi jednak przez Step 1 i nie ma pliku
> wejściowego z analizą — czy ma podlegać quality gate Step 2, jest *w budowie*.

Obsługiwane zadania:

| `action` | Co robi Step 2 |
|---|---|
| `test.update` | Aktualizuje istniejące testy w zakresie wskazanym w `payload.allowed_scope` |
| `test.add` | Dopisuje nowy test charakteryzujący dla wskazanego zakresu |
| `test.remove` | Usuwa test, który stał się zbędny, po uzasadnieniu w payloadzie |
| `test.mock.enable` | Włącza obsługę mocków w projekcie testowym, jeśli nie była włączona (patrz „Mocki w testach") |
| `test.mock.add` | Dodaje mock/stub dla wskazanej zależności w istniejących lub nowych testach |

Zasady trybu zadaniowego:

1. **Zakres wykonania jest ograniczony payloadem.** Wykonuj wyłącznie to, co
   dopuszcza `payload.allowed_scope`; nie ruszaj tego, co wymienia
   `payload.forbidden`. Przykład dla `rename_only`: zmieniasz w teście nazwy
   metod/klas, **nie** asercje, **nie** dane wejściowe, **nie** zakres testu.
2. **Transparentność przed wykonaniem.** Jeśli wiadomość ma
   `requires_user_ack: true`, użytkownik musi zobaczyć `user_message` (co jest
   czerwone i dlaczego) **zanim** cokolwiek zostanie zmienione. Za pokazanie
   odpowiada orkiestrator; krok nie startuje przed jego zgodą na kontynuację.
3. **Wykonanie jest automatyczne.** Po pokazaniu informacji krok wykonuje
   zadanie sam — nie prosi o zatwierdzenie linia po linii.
4. **Uruchom testy po zmianie** i zaraportuj wynik w `payload.result`.
5. **Odpowiedź** to `type: "response"` ze statusem `done` / `failed` /
   `needs_user`, z opisem, co konkretnie zmieniono (pliki, testy, rodzaj
   zmiany) — bez treści kodu.
6. **Każde zadanie jest odnotowane w logu** jako osobny wpis, z oznaczeniem,
   który etap je zlecił i pod jakim `corr_id`.

## Mocki w testach

Do końca Kroku 2 Etapu 2 testy z Etapu 1 mogą działać bez żadnego frameworka
mockującego. Zmienia się to w **Kroku 3 Etapu 2** (przerwanie zależności): gdy
zależności od systemów zewnętrznych trafiają do konstruktora, testy muszą móc
podstawić w ich miejsce mock albo stub. Jeśli projekt testowy nie miał wcześniej
włączonej obsługi mocków, trzeba ją włączyć — i należy to do Etapu 1, bo Etap 1
jest jedynym właścicielem testów i ich obudowy.

**Zadanie `test.mock.enable`:**

1. Sprawdź, czy w projekcie testowym jest już używany framework mockujący
   (referencje w `.csproj`, istniejące użycia w testach). Analogicznie do
   logiki ustalania frameworka testowego z Pytania 0.
2. Jeśli **jest** — używaj go, nie wprowadzaj drugiego.
3. Jeśli **nie ma** — nie wybieraj samodzielnie. Wystaw `user.input` z pytaniem,
   którego frameworka użyć, i z informacją, co wymusiło ten wybór (która
   zależność, w którym kroku Etapu 2). Czekaj na decyzję użytkownika.
4. Jeśli w projekcie jest **więcej niż jeden** framework mockujący — przedstaw
   znalezione i zapytaj, którego użyć dla testów objętych tym refaktorem.
5. Wybór (wraz z uzasadnieniem, kto go podjął) trafia do logu i do pliku
   wynikowego Etapu 1. Kolejne zadania `test.mock.*` już nie pytają.
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

## Log Step 2 (`step2-log.md`)

Osobny plik logu, oddzielny od logu Step 1, logu orkiestratora
i `refactor-config.json`. Zasady prowadzenia identyczne jak w Step 1:

- wyłącznie decyzje i działania — żadnego kodu, diffów ani treści testów;
- wpisy numerowane, chronologiczne, **każdy poprzedzony znacznikiem
  `yyyy-MM-dd; HH-mm-ss`** wczytanym z `refactor-config.json`; pierwszym
  wpisem uruchomienia jest nagłówek `## Uruchomienie <znacznik>`;
- każda iteracja pod nagłówkiem `### Iteracja N`, numeracja od nowa;
- **wynik quality gate jest wpisem obowiązkowym** — z rozbiciem na build
  i testy oraz z informacją, kto je wykonał (krok czy użytkownik);
- wysłanie `step.done` jest ostatnim wpisem iteracji;
- zadania z trybu zadaniowego pod nagłówkiem `### Zadania zlecone`, z etapem
  zlecającym i `corr_id`;
- przerwanie przez użytkownika jako ostatni wpis, bez domysłów co do przyczyny.

Przykład:

```markdown
# Log Step 2 — <fragment/moduł>

## Uruchomienie 2026-09-08; 17-25-00

### Iteracja 1

2026-09-08; 17-25-10 — 1. Wczytano step1-zmiany-1.json (5 struktur do zaimplementowania).
2026-09-08; 17-28-11 — 2. Napisano test charakteryzujący dla podfragmentu 1.
2026-09-08; 17-33-27 — 3. Wprowadzono seam (extract method) dla podfragmentu 1.
2026-09-08; 17-36-40 — 4. Quality gate: build OK, testy zielone (12/12) → brama przeszła.
2026-09-08; 17-40-05 — 5. Wynik iteracji sprawdzony i potwierdzony przez użytkownika.
2026-09-08; 17-40-12 — 6. Wysłano step.done do orkiestratora (iteracja 1 z 4); koniec pracy kroku.

### Zadania zlecone

2026-09-08; 18-20-14 — 1. Etap 2 (corr_id e2-k1-007) — zaktualizowano nazwy w 3 testach po zmianie nazwy metody.
2026-09-08; 18-49-51 — 2. Etap 2 (corr_id e2-k3-002) — włączono obsługę mocków w projekcie testowym.
```

## Format wyjścia Etapu 1

Lokalizacja: katalog wynikowy (patrz „Katalog wynikowy" w `orkiestrator.md`).
Wybór z Pytania 1 obowiązuje bez zmian:

- **Opcja A (osobny plik na etap):** wynik zapisywany w `etap1-plan.md`.
- **Opcja B (jeden zbiorczy plik):** wynik to sekcja `## Etap 1` w pliku
  zbiorczym `refactor-plan.md`, rozbudowywana w miarę postępu iteracji.
- **Dodatkowy plik szczegółowy per iteracja** (tylko jeśli użytkownik wybrał tę
  opcję w Pytaniu 1): po zakończeniu każdej iteracji powstaje
  `etap1-iteracja-N-zmiany.md` ze szczegółowym opisem zmian tej iteracji. Logi
  pozostają przy tym wyłącznie listami decyzji.

## Decyzje (rozstrzygnięte)

- **Fizyczne wykonanie zmian:** Tak — po zatwierdzeniu propozycji ze Step 1
  Step 2 fizycznie wprowadza seam (extract method / extract interface + DI),
  ale wyłącznie w zakresie umożliwiającym testowanie (behavior-preserving).
  Etap 1 nie jest miejscem na głębokie zmiany strukturalne ani zmianę logiki
  biznesowej. Głębszy refaktor należy do Etapu 2/3.
- **Jednostka Etapu 1:** Zależna od granulacji ustalonej w Pytaniu 0 (metoda /
  klasa / kontroler-moduł / automatyczna / dynamiczna) — nie jest sztywno
  ograniczona do pojedynczej metody.
- **Strategia seamu:** Wybiera ją Step 1; Step 2 jej nie zmienia. Użytkownik
  może ją zakwestionować po pierwszej iteracji (krok 4 wyżej) — korekta
  obowiązuje kolejne analizy Step 1.
- **Framework testowy i izolacja zależności statycznych:** Framework testowy
  ustalany w Pytaniu 0 (dla tego projektu: NUnit). Domyślne podejście do
  seamów: interfejs + Dependency Injection. Jeśli w projekcie nie ma kontenera
  DI — używamy fabryk (Factory), żeby nie wprowadzać dodatkowej zależności.
  Microsoft Fakes/Shims nie jest strategią domyślną — rozważane wyłącznie
  w ostateczności.
- **Własność testów:** Etap 1 jest jedynym miejscem, w którym powstają,
  zmieniają się i są usuwane testy. Inne etapy zlecają to przez orkiestratora.
