# Etap 1 / Step 1 — Przygotowanie (Analiza)

Pierwszy z dwóch kroków Etapu 1. Powstał z podziału `etap1.md` — obejmuje
**wyłącznie Fazę Analizy**. Nic tu nie dotyka kodu produkcyjnego ani testów.

| | |
|---|---|
| **Wykonawca** | agent uruchamiany na modelu **opus** |
| **Adres w protokole** | `etap1.step1` |
| **Uruchamiany przez** | orkiestrator — wiadomość `step.start` |
| **Podstawa metodyczna** | Michael Feathers, *Working Effectively with Legacy Code* (patrz niżej) |
| **Charakter** | read-only wobec repozytorium — analiza, żadnej zmiany w plikach projektu |
| **Wyjście** | plik opisowy z analizą + JSON ze zmianami dla Step 2 + request `step.done` — wszystko zapisane na dysku |
| **Zamknięcie kroku** | **Quality gate** uruchamiany przez orkiestratora (skrypty z `scripts/step1/`) — nie akceptacja użytkownika |

Cel Etapu 1 pozostaje bez zmian: umożliwić bezpieczne wprowadzenie zmiany przez
objęcie fragmentu testem charakteryzującym (dokumentuje **aktualne** zachowanie
kodu, niezależnie od tego, czy jest poprawne) oraz odsprzęgnięcie zależności
blokujących testowalność. Step 1 odpowiada za **rozpoznanie i decyzję**,
Step 2 za **wykonanie**.

## Podstawa metodyczna kroku

Krok pracuje **według zasad Michaela Feathersa** (*Working Effectively with
Legacy Code*) i tylko według nich. To jest kryterium, którym ocenia własne
propozycje:

- **Seam** — miejsce, w którym da się zmienić zachowanie programu bez edycji
  w tym miejscu. Rozpoznanie seamów jest właściwą treścią analizy; katalog
  technik (Extract Interface + DI, Extract and Override Call, Adapter,
  Parameterize Method) pochodzi stąd.
- **Test charakteryzujący** — dokumentuje zachowanie **aktualne**, nie
  poprawne. Analiza nie rozstrzyga, czy kod robi to, co powinien.
- **Najmniejsza możliwa zmiana umożliwiająca test** — logika biznesowa zostaje
  nietknięta. Wszystko, co wykracza poza wpuszczenie testu do kodu, należy do
  Etapu 2/3 i trafia do sekcji „Poza zakresem".

Czego ten krok **nie** stosuje: katalogu refaktoryzacji Fowlera, zasad clean
code/clean architecture, SOLID/KISS/DRY/YAGNI. To są podstawy metodyczne
kolejnych etapów i nie są kryterium oceny w Etapie 1. Orkiestrator nie
przekazuje żadnej podstawy metodycznej — jest ona zapisana wyłącznie tutaj.

## Wejście

1. `payload.config` z wiadomości `step.start` — zawartość `refactor-config.json`
   zebrana przez orkiestratora. Step 1 konfiguracji nie zbiera.
2. `payload.iteracja` — numer iteracji, którą krok ma wykonać. **Krok nie
   ustala go sam i nie odtwarza z własnego logu** — dostaje go od
   orkiestratora, który jest właścicielem licznika.
3. **Przed każdą kolejną iteracją** Step 1 wczytuje na nowo z dysku
   `refactor-config.json` (ustalenia z Pytań 0–2 oraz format znacznika czasu
   obowiązujący w logach). Plik jest źródłem prawdy i przypominajką — krok nie
   musi trzymać konfiguracji w pamięci między iteracjami. Orkiestrator czyta
   ten sam plik przy każdej wiadomości do kroku.

Step 1 **nie wie nic o Step 2** — ani czy istnieje, ani kto go wykona. Jego
zadanie kończy się wystawieniem wiadomości do orkiestratora.

## Iteracyjność

Step 1 i Step 2 tworzą jeden cykl, który dla dużego fragmentu (moduł, klasa,
kontroler — rzędu np. 10 tys. linii) przechodzi się **wielokrotnie**, dla
kolejnych podfragmentów:

```
Step 1 (1) → quality gate Step 1 → Step 2 (1) → quality gate Step 2
→ Step 1 (2) → quality gate Step 1 → Step 2 (2) → quality gate Step 2
→ ... → finałowe zamknięcie Etapu 1
```

Dla małego fragmentu (np. pojedyncza metoda) cykl przechodzi się raz. Liczba
iteracji wynika z rozmiaru i zasięgu zmiany.

**Step 1 deklaruje liczbę iteracji.** W wiadomości `step.done` podaje pole
`iteracje` z liczbą przewidzianych przebiegów cyklu dla wskazanego zakresu
(`zaplanowane`), numerem iteracji bieżącej (`biezaca`) i krótkim uzasadnieniem
szacunku. Deklaracja jest szacunkiem: przy kolejnej iteracji krok może ją
skorygować, podając nową wartość — korektę odnotowuje w swoim logu, a wiążący
zapis prowadzi orkiestrator.

**Licznik iteracji nie jest własnością kroku.** Log Step 1 zapisuje wszystko,
co krok robi, ale stanem procesu zarządza orkiestrator: to on wie, ile iteracji
jest przewidzianych i która trwa, i **to on wznawia przebieg po przerwaniu**.
Krok nie wznawia się sam, nie sprawdza, czy poprzednia iteracja się odbyła, i
nie dedukuje numeru iteracji z logu — bierze go z payloadu.

Użytkownik może przerwać iterację w dowolnym momencie, po dowolnym kroku —
przerwanie nie wymaga uzasadnienia. Log odnotowuje je jako ostatni wpis,
a do orkiestratora idzie `stage.aborted`.

## Kroki analizy

1. **Ocena testowalności fragmentu**
   - Czy zmieniany fragment (metoda/funkcja) da się objąć unit testem
     bez modyfikacji kodu? Testujemy **zachowanie**, nie implementację.
   - Jeśli tak → analiza jest zamknięta: przygotuj wyjście dla Step 2
     (samo napisanie testu charakteryzującego, bez seamu).
   - Jeśli nie → przejdź do kroku 2.
   - Jeśli w konfiguracji wstępnej (Pytanie 0) wybrano granulację
     **dynamiczną**: jeśli fragment okaże się zbyt duży/złożony, aby objąć go
     jedną spójną iteracją, zatrzymaj się tutaj — wyślij do orkiestratora
     `user.input` z opisem, co dokładnie jest za duże i dlaczego (pod kątem
     wprowadzenia unit testów), i poczekaj na decyzję użytkownika (np. podział
     na mniejsze podfragmenty) zamiast kontynuować samodzielnie. To jest ten
     określony moment, w którym dla granulacji dynamicznej musi paść pytanie
     o zakres, zanim powstanie jakikolwiek test.

2. **Identyfikacja zależności blokujących testowalność**
   - Wypisz wszystkie zależności uniemożliwiające izolację fragmentu w teście,
     np.: statyczne wywołania, `HttpContext`, bezpośrednie odwołania do bazy
     danych, `DateTime.Now`, singletony, `new` wewnątrz metody zamiast
     wstrzykniętej zależności (brak Dependency Injection).
   - Dla każdej zależności określ typ szwu (seam) możliwy do zastosowania:
     Extract Interface + DI, Extract and Override Call, Adapter, Parameterize
     Method — zgodnie z katalogiem technik Feathersa.

3. **Propozycja minimalnego odsprzęgnięcia**
   - Zaproponuj **najmniejszą możliwą** zmianę, która umożliwi test, bez
     ruszania logiki biznesowej.
   - Zgodnie z wyborem obowiązkowym z Pytania 0 (brak zmian w kodzie bez pliku
     `.md`): propozycja trafia do plików wyjściowych (patrz "Wyjście"). Krok
     kończy się wysłaniem `step.done` — **bramę uruchamia orkiestrator**, nie
     krok, i to jej wynik decyduje, czy Step 2 wystartuje. Step 1 nie pyta
     użytkownika o akceptację analizy.

4. **Gdy odsprzęgnięcie bez zmiany logiki nie jest możliwe**
   - Jeśli żadna propozycja seamu z kroku 3 nie pozwala objąć fragmentu testem
     bez ingerencji w logikę biznesową, przedstaw użytkownikowi do wyboru
     poniższe kierunki. Wybór jest obowiązkowy i odnotowywany w logu Step 1.

   - **Opcja 1 — Zakończenie działania harnessu.** Praca nad fragmentem zostaje
     zakończona z adnotacją: sensowne napisanie testów nie jest możliwe,
     złożoność kodu wymusza zmianę logiki.

   - **Opcja 2 — Zakończenie z decyzją użytkownika.** Ta sama adnotacja co
     w Opcji 1, ale krok nie kończy pracy samodzielnie — przedstawia sytuację
     i czeka na decyzję użytkownika co do dalszego kierunku.

   - **Opcja 3 — Opakowanie w dodatkową abstrakcję.** Stosowana, gdy problem
     dotyczy całego modułu, dużej klasy lub metody. Problematyczny kod zostaje
     opakowany w dodatkową abstrakcję, co pozwala wprowadzić przełącznik
     kierujący sterowanie do nowej implementacji — stara struktura pozostaje
     nietknięta. Nowa implementacja powstaje w podejściu TDD. Po wyborze tej
     opcji i wskazaniu frameworka do mocków krok zatrzymuje się z adnotacją
     *w budowie* — dalsze rozwinięcie (przebieg TDD, dobór mocków) zamknięte
     do kolejnej iteracji.

   - **Opcja 4 — Jak Opcja 3, z pytaniem o kierunek zmian.** Ta sama technika
     (abstrakcja + przełącznik), ale przed jej zastosowaniem krok pyta
     użytkownika, czy celem jest: (a) refaktor przez przepisanie starego
     rozwiązania na nowe, zachowanie bez zmian, czy (b) zmiana
     logiki/funkcjonalności realizowana równolegle z refaktorem. Kierunek
     wybiera użytkownik.

## Wyjście — pliki wytworzone przez Step 1

Step 1 wytwarza w **katalogu wynikowym przebiegu** (patrz „Katalog wynikowy"
w `orkiestrator.md`) komplet czterech plików dla iteracji `N`. Ten komplet jest
przedmiotem quality gate — brak któregokolwiek pliku zatrzymuje krok.

| Plik | Rola |
|---|---|
| `step1-analiza-N.md` | opis analizy dla człowieka — sekcje 1–6 + licznik zmian |
| `step1-zmiany-N.json` | **kontrakt dla Step 2** — struktury zmian do zaimplementowania |
| `step1-step-done-N.json` | request `step.done` do orkiestratora (patrz „Zakończenie kroku") |
| `step1-log.md` | log decyzji kroku, wspólny dla wszystkich iteracji |

### Plik opisowy `step1-analiza-N.md`

Struktura pliku — sekcje w tej kolejności, nagłówkami `## N. Nazwa`
(brzmienie nagłówków jest wiążące: sprawdza je skrypt bramy):

1. **Fragment** — wskazanie metody/klasy/modułu objętego iteracją (plik + zakres).
2. **Zależności blokujące** — lista zidentyfikowanych zależności blokujących
   testowalność, wraz z typem seamu proponowanym dla każdej z nich.
3. **Proponowany seam** — opis najmniejszej możliwej zmiany umożliwiającej test,
   bez ruszania logiki biznesowej.
4. **Test charakteryzujący** — opis zakresu i przypadków, jakie ma pokryć test
   (bez treści kodu — kod powstaje w Step 2, w pliku testowym).
5. **Zmiany do zaimplementowania** — lista konkretnych, wykonalnych pozycji dla
   Step 2: co, w którym pliku, w jakiej kolejności. Odpowiada strukturom
   z `step1-zmiany-N.json` — ten sam zestaw zmian, tu opisany po ludzku.
6. **Poza zakresem** — czego Step 2 **nie** ma ruszać w tej iteracji.

Sekcji „Do akceptacji" **nie ma** — Step 1 nie kończy się pytaniem do
użytkownika, tylko bramą uruchamianą przez orkiestratora.

Na końcu pliku (za sekcją 6) stoi linia z licznikiem:

```
Liczba zmian: 3
```

Liczba musi być **identyczna** z `liczba_zmian` w `step1-zmiany-N.json` —
zgodność sprawdza skrypt `04-licznik.ps1`.

Wybór z Pytania 1 (Opcja A — osobny plik na etap / Opcja B — jeden zbiorczy
plik) obowiązuje bez zmian: przy Opcji B powyższa struktura jest sekcją
`## Etap 1 / Step 1 — iteracja N` w pliku zbiorczym, a sekcje 1–6 schodzą
o poziom niżej (`### N. Nazwa`). Ścieżkę pliku zbiorczego orkiestrator podaje
skryptom bramy parametrem `-PlikAnalizy`.

### Plik `step1-zmiany-N.json` — kontrakt dla Step 2

Step 2 dostaje **wyłącznie ten plik** (wskazany w `pliki[]` wiadomości
`step.done`) — nie powtarza analizy i nie dobiera strategii samodzielnie. Plik
musi więc być na tyle konkretny, żeby dało się go wykonać bez wracania do
rozpoznania.

```json
{
  "etap": "etap1",
  "krok": "step1",
  "iteracja": 2,
  "zmiany": [
    {
      "id": "zm-1",
      "kolejnosc": 1,
      "plik": "src/Orders/OrderCalculator.cs",
      "zakres": "CalculateOrderTotal, linie 42-88",
      "typ": "seam",
      "technika": "Extract Interface + DI",
      "opis": "Wydzielić IClock dla DateTime.Now, wstrzyknąć przez konstruktor"
    },
    {
      "id": "zm-2",
      "kolejnosc": 2,
      "plik": "tests/Orders/OrderCalculatorTests.cs",
      "zakres": "nowy plik testowy",
      "typ": "test",
      "technika": "",
      "opis": "Test charakteryzujący CalculateOrderTotal dla 4 przypadków z sekcji 4"
    }
  ],
  "liczba_zmian": 2
}
```

Pola struktury zmiany:

| Pole | Znaczenie |
|---|---|
| `id` | identyfikator w obrębie iteracji, unikalny (`zm-1`, `zm-2`, …) |
| `kolejnosc` | pozycja w kolejności wykonania; ciąg `1..K` bez luk i powtórzeń |
| `plik` | plik projektu, którego zmiana dotyczy (ścieżka względem katalogu projektu) |
| `zakres` | co dokładnie w tym pliku — metoda, klasa, zakres linii, „nowy plik" |
| `typ` | `seam` (zmiana w kodzie produkcyjnym) albo `test` (test charakteryzujący) |
| `technika` | technika z katalogu Feathersa — **obowiązkowa dla `typ: "seam"`**, pusta dla `typ: "test"` |
| `opis` | jedno zdanie: co ma zrobić Step 2 |

**Licznik.** Tablica `zmiany` ma **co najmniej jedną** strukturę. Step 1 zlicza
je i wpisuje wynik w `liczba_zmian` — **ostatnie pole pliku** — oraz w linię
`Liczba zmian: K` pliku opisowego. Trzy liczby (struktury w tablicy, pole
w JSON-ie, linia w `.md`) muszą się zgadzać; rozjazd zatrzymuje bramę.

## Zakończenie kroku — request `step.done`

Step 1 kończy pracę **jednym requestem `step.done` skierowanym do
orkiestratora**. Request jest **zapisywany jako plik na dysku**, w katalogu
wynikowym przebiegu, razem z pozostałymi plikami iteracji:
`step1-step-done-N.json`. Zapisanie tego pliku jest końcem pracy agenta: krok
nie czeka, nie uruchamia Step 2, nie uruchamia bramy i nie robi nic więcej.

(Kopia wiadomości trafia dodatkowo do `komunikacja/` — patrz „Zapis
wiadomości" w `orkiestrator.md`. Plik `step1-step-done-N.json` jest wersją,
której szuka brama, bo ma stać tam, gdzie reszta plików Step 1.)

Request niesie komplet informacji potrzebnych orkiestratorowi do podjęcia
decyzji o uruchomieniu następnego kroku:

| Pole payloadu | Znaczenie |
|---|---|
| `faza_zakonczona` | Faza analizy zakończona (`true`) |
| `quality_gate.status` | Zawsze `nie_wykonany` z powodem „brama po stronie orkiestratora" — **krok nie ocenia sam siebie** i nie uruchamia skryptów bramy |
| `iteracje.biezaca` / `iteracje.zaplanowane` | Licznik iteracji (patrz „Iteracyjność") |
| `pliki[]` | **Gdzie leżą pliki i jak się nazywają** — `nazwa`, `sciezka`, `rola`, `kolejnosc` |
| `liczba_zmian` | Liczba struktur w `step1-zmiany-N.json` — ta sama, co w pliku JSON i w pliku opisowym |
| `kolejnosc_implementacji` | **W jakiej kolejności zmiany mają być wprowadzone** — `id` struktur z `step1-zmiany-N.json` w kolejności wykonania |
| `poza_zakresem` | Czego następny krok nie rusza (sekcja 6) |
| `nastepny` | Propozycja: `etap1.step2`. Decyzję i tak podejmuje orkiestrator |

Pola `zatwierdzenie_uzytkownika` **nie ma** — akceptacja analizy przez
użytkownika została zastąpiona bramą orkiestratora.

```json
{
  "type": "response",
  "from": "etap1.step1",
  "to": "orkiestrator",
  "action": "step.done",
  "status": "done",
  "payload": {
    "etap": "etap1",
    "krok": "step1",
    "faza": "analiza",
    "faza_zakonczona": true,
    "iteracje": { "biezaca": 2, "zaplanowane": 4, "podstawa_szacunku": "4 podfragmenty" },
    "quality_gate": { "status": "nie_wykonany", "powod": "brama po stronie orkiestratora" },
    "pliki": [
      { "kolejnosc": 1, "nazwa": "step1-zmiany-2.json",
        "sciezka": "refactor-result3/step1-zmiany-2.json",
        "rola": "zmiany do zaimplementowania" },
      { "kolejnosc": 2, "nazwa": "step1-analiza-2.md",
        "sciezka": "refactor-result3/step1-analiza-2.md",
        "rola": "opis analizy" }
    ],
    "liczba_zmian": 2,
    "kolejnosc_implementacji": ["zm-1", "zm-2"],
    "poza_zakresem": ["logika rabatów"],
    "nastepny": "etap1.step2"
  },
  "timestamp": "2026-09-09; 11-04-22"
}
```

Pełna koperta wiadomości i sposób jej zapisu — patrz „Protokół komunikacji"
w `orkiestrator.md`. Brak któregokolwiek z pól obowiązkowych oznacza, że brama
wyjściowa kroku nie przechodzi i krok nie zostaje zamknięty.

## Log Step 1 (`step1-log.md`)

Osobny plik logu, oddzielny od pliku konfiguracji (`refactor-config.json`), od
logu orkiestratora i od logu Step 2. Nie mieszać zawartości tych plików.

- Log zawiera **wyłącznie decyzje i wybory** — żadnego kodu, diffów, treści
  testów ani zawartości plików. Sam fakt, że coś zostało zrobione, nie jak.
- Wpisy są numerowane i dopisywane **chronologicznie**, w miarę jak zapadają.
- **Każdy wpis jest poprzedzony znacznikiem daty i godziny** w formacie
  `yyyy-MM-dd; HH-mm-ss` wczytanym z `refactor-config.json` (patrz "Znaczniki
  czasu w logach" w `orkiestrator.md`). Pierwszym wpisem każdego uruchomienia
  jest nagłówek `## Uruchomienie <znacznik>`. Bez znaczników Etap 0 nie
  rozpozna, do której sesji należą wpisy.
- Każdy wpis to jedno zdanie, bez uzasadnień technicznych (te trafiają do pliku
  wyjściowego).
- Każda iteracja jest oznaczona nagłówkiem `### Iteracja N` (wewnątrz nagłówka
  uruchomienia), wpisy numerowane od nowa w ramach iteracji.
- **Zadeklarowana liczba iteracji** (i każda jej korekta) jest wpisem
  obowiązkowym — log kroku odnotowuje deklarację, ale wiążący stan procesu
  prowadzi orkiestrator.
- **Zapisanie każdego z plików wyjściowych** jest wpisem obowiązkowym, razem
  z liczbą zmian wpisaną do `step1-zmiany-N.json`.
- **Wyniku quality gate w logu Step 1 nie ma** — bramę uruchamia orkiestrator
  po zakończeniu pracy kroku i odnotowuje ją w swoim logu. Krok nie zna wyniku
  własnej bramy.
- Przerwanie przez użytkownika odnotowane jako ostatni wpis, bez domysłów co do
  przyczyny.

Przykład:

```markdown
# Log Step 1 — <fragment/moduł>

## Uruchomienie 2026-09-08; 17-05-12

### Iteracja 1

2026-09-08; 17-05-30 — 1. Sprawdzenie fragmentu pod kątem możliwości napisania testu.
2026-09-08; 17-06-02 — 2. Fragment za duży — konieczna większa granulacja.
2026-09-08; 17-06-40 — 3. Pytanie do użytkownika o wybór granulacji (opcja dynamiczna).
2026-09-08; 17-12-18 — 4. Wypisano zależności blokujące testowalność dla podfragmentu 1.
2026-09-08; 17-15-03 — 5. Zaproponowano najmniejszą możliwą zmianę (seam) dla podfragmentu 1.
2026-09-08; 17-21-49 — 6. Zapisano step1-analiza-1.md (sekcje 1-6, liczba zmian: 3).
2026-09-08; 17-21-52 — 7. Zapisano step1-zmiany-1.json — 3 struktury zmian.
2026-09-08; 17-21-55 — 8. Zadeklarowano 4 iteracje dla wskazanego zakresu (bieżąca: 1).
2026-09-08; 17-22-10 — 9. Zapisano step1-step-done-1.json; koniec pracy kroku.
```

## Quality gate Step 1

Brama sprawdza **to, co krok wytworzył**, a nie to, co napisał w logu. Zasady:

- **Uruchamia ją orkiestrator, nie krok.** Step 1 kończy pracę zapisaniem
  requestu; bramę odpala orkiestrator po odebraniu `step.done`. Krok nigdy nie
  ocenia sam siebie.
- **Brama to skrypty**, nie ocena agenta — zestaw w `scripts/step1/`
  (PowerShell, uruchamialny na Windowsie bez doinstalowywania czegokolwiek).
- **Sprawdzana jest struktura, nie merytoryka.** Brama nie ocenia trafności
  seamu ani jakości analizy — tylko to, czy komplet plików istnieje i czy mają
  wymaganą strukturę.

| Skrypt | Co sprawdza |
|---|---|
| `01-pliki.ps1` | czy w katalogu wynikowym są wszystkie cztery pliki iteracji, niepuste, i czy log ma nagłówek `### Iteracja N` |
| `02-sekcje.ps1` | czy `step1-analiza-N.md` ma sekcje 1–6 w wymaganej kolejności i nie ma usuniętej sekcji „Do akceptacji" |
| `03-json.ps1` | czy `step1-zmiany-N.json` parsuje się i czy każda struktura ma komplet pól (`id`, `kolejnosc`, `plik`, `zakres`, `typ`, `opis`, `technika` dla `seam`) |
| `04-licznik.ps1` | czy liczba struktur == `liczba_zmian` == `Liczba zmian: K` w pliku opisowym |

`00-brama.ps1` uruchamia komplet i zapisuje podsumowanie. Wywołanie:

```powershell
.\scripts\step1\00-brama.ps1 -KatalogWynikowy <ścieżka> -Iteracja <N> [-PlikAnalizy <plik zbiorczy>] [-Proba 1|2]
```

Kod wyjścia każdego skryptu: `0` = passed, `1` = failed, `2` = błąd wywołania
(np. nie ma katalogu wynikowego).

**Gdzie ląduje wynik.** Każdy skrypt zapisuje własny plik wyniku w katalogu
`<katalog wynikowy>/quality-gate-step1-analize-result/iteracja-N/`:

```
quality-gate-step1-analize-result/
  iteracja-1/
    01-pliki.json
    02-sekcje.json
    03-json.json
    04-licznik.json
    podsumowanie.json
  iteracja-2/
    ...
```

Katalog jest numerowany per iteracja, bo pętli analiza → implementacja bywa
wiele: po zawartości tego katalogu orkiestrator widzi, które iteracje już
przeszły bramę, a które nie.

Pojedynczy plik wyniku:

```json
{
  "skrypt": "03-json",
  "etap": "etap1", "krok": "step1", "iteracja": 2,
  "wynik": "failed",
  "szczegoly": [
    { "pozycja": "zmiana-2", "wynik": "niekompletna",
      "komunikat": "Brakuje / niepoprawne: technika (obowiązkowa dla typ=seam)" }
  ],
  "timestamp": "2026-09-09; 11-05-02"
}
```

**Wynik negatywny — jedno ponowienie.** `failed` w pierwszej próbie →
orkiestrator uruchamia skrypt czyszczący
(`scripts/step1/eraser/00-eraser.ps1 -KatalogWynikowy <ścieżka> -Iteracja N`),
który kasuje komplet plików bramy tej iteracji razem z katalogiem
`quality-gate-step1-analize-result/iteracja-N/`, odnotowuje zużycie ponowienia
dla pary (`etap1.step1`, iteracja N) i **uruchamia Step 1 tej samej iteracji
jeszcze raz**. `failed` w drugiej próbie → przerwanie procesu i notyfikacja
użytkownika.

Ponowiony krok dostaje ten sam numer iteracji i **nadpisuje własne pliki**
(`step1-analiza-N.md`, `step1-zmiany-N.json`, `step1-step-done-N.json`) —
eraser ich nie usuwa. Licznik ponowień prowadzi orkiestrator, osobno dla
każdej pary (krok, iteracja); krok go nie zna i nie dedukuje z własnego logu.

## Przekazanie do Step 2

Step 1 kończy się, gdy komplet plików iteracji leży w katalogu wynikowym
(`step1-analiza-N.md`, `step1-zmiany-N.json`, `step1-step-done-N.json`, wpis
w `step1-log.md`). Co dalej — rozstrzyga quality gate uruchamiany przez
orkiestratora; krok nie czeka na jego wynik.

**Sposób przekazania sterowania — rozstrzygnięty: przez orkiestratora.**
Step 1 **nie uruchamia Step 2** i nie ma takiej możliwości. Przebieg wygląda
tak:

1. Step 1 zapisuje `step1-step-done-N.json` → koniec pracy agenta analizującego.
2. Orkiestrator uruchamia skrypty bramy z `scripts/step1/`, sprawdza bramę
   wyjściową kroku, zapisuje licznik iteracji i lokalizację plików,
   i **decyduje**, czy uruchomić Step 2. `failed` → jedno ponowienie Step 1
   tej samej iteracji; drugi `failed` → przerwanie i notyfikacja użytkownika.
3. Jeśli tak — wysyła `step.start` do `etap1.step2` z **tym samym payloadem**,
   uzupełnionym o `config`. To rozpoczyna pracę agenta kodującego.

Kroki są dzięki temu od siebie odizolowane: Step 1 nie wie, kto ani kiedy
wykona jego listę zmian, a jedynym kanałem między nimi jest wiadomość JSON
przechodząca przez orkiestratora (patrz „Kroki Etapu 1 jako jednostki
sterowania" w `orkiestrator.md`).
