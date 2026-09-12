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
| **Wyjście** | plik z konkretnymi zmianami do zaimplementowania + wiadomość `step.done` do orkiestratora |
| **Zamknięcie kroku** | zatwierdzenie użytkownika + **Quality gate** *(w budowie)* |

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
   musi trzymać konfiguracji w pamięci między iteracjami. Orkiestrator
   niezależnie weryfikuje ten plik względem swojego snapshotu.

Step 1 **nie wie nic o Step 2** — ani czy istnieje, ani kto go wykona. Jego
zadanie kończy się wystawieniem wiadomości do orkiestratora.

## Iteracyjność

Step 1 i Step 2 tworzą jeden cykl, który dla dużego fragmentu (moduł, klasa,
kontroler — rzędu np. 10 tys. linii) przechodzi się **wielokrotnie**, dla
kolejnych podfragmentów:

```
Step 1 (1) → zatwierdzenie użytkownika → Step 2 (1) → quality gate
→ Step 1 (2) → zatwierdzenie użytkownika → Step 2 (2) → quality gate
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
     `.md`): propozycja trafia najpierw do pliku wyjściowego (patrz "Wyjście")
     i czeka na **zatwierdzenie przez użytkownika** (`user.approval`) — to jest
     koniec Step 1 dla danej iteracji. Bez zatwierdzenia Step 2 się nie
     rozpoczyna.

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

## Wyjście — plik z konkretnymi zmianami dla Step 2

Step 2 dostaje **wyłącznie ten plik** — nie powtarza analizy i nie dobiera
strategii samodzielnie. Plik musi więc być na tyle konkretny, żeby dało się go
wykonać bez wracania do rozpoznania.

Lokalizacja: katalog wynikowy przebiegu (patrz "Katalog wynikowy"
w `orkiestrator.md`). Nazwa: `step1-analiza-N.md`, gdzie `N` to numer iteracji.

Struktura pliku (sekcje w kolejności):

1. **Fragment** — wskazanie metody/klasy/modułu objętego iteracją (plik + zakres).
2. **Zależności blokujące** — lista zidentyfikowanych zależności blokujących
   testowalność, wraz z typem seamu proponowanym dla każdej z nich.
3. **Proponowany seam** — opis najmniejszej możliwej zmiany umożliwiającej test,
   bez ruszania logiki biznesowej.
4. **Test charakteryzujący** — opis zakresu i przypadków, jakie ma pokryć test
   (bez treści kodu — kod powstaje w Step 2, w pliku testowym).
5. **Zmiany do zaimplementowania** — lista konkretnych, wykonalnych pozycji dla
   Step 2: co, w którym pliku, w jakiej kolejności. To jest właściwy kontrakt
   przekazania między krokami.
6. **Poza zakresem** — czego Step 2 **nie** ma ruszać w tej iteracji.
7. **Do akceptacji** — jawne pytanie do użytkownika kończące Step 1 tej iteracji.

Wybór z Pytania 1 (Opcja A — osobny plik na etap / Opcja B — jeden zbiorczy
plik) obowiązuje bez zmian: przy Opcji B powyższa struktura jest sekcją
`## Etap 1 / Step 1 — iteracja N` w pliku zbiorczym.

## Zakończenie kroku — wiadomość do orkiestratora

Step 1 kończy pracę **jedną wiadomością `step.done` wysłaną do orkiestratora**.
Wysłanie tej wiadomości jest końcem pracy agenta: krok nie czeka, nie uruchamia
Step 2 i nie robi nic więcej.

Wiadomość niesie komplet informacji potrzebnych orkiestratorowi do podjęcia
decyzji o uruchomieniu następnego kroku:

| Pole payloadu | Znaczenie |
|---|---|
| `faza_zakonczona` | Faza analizy zakończona (`true`) |
| `quality_gate.status` | Wynik bramy kroku: `passed` / `failed` / `nie_wykonany` |
| `zatwierdzenie_uzytkownika` | Czy użytkownik zatwierdził propozycję z sekcji „Do akceptacji" |
| `iteracje.biezaca` / `iteracje.zaplanowane` | Licznik iteracji (patrz „Iteracyjność") |
| `pliki[]` | **Gdzie leżą pliki ze zmianami i jak się nazywają** — `nazwa`, `sciezka`, `rola`, `kolejnosc` |
| `kolejnosc_implementacji` | **W jakiej kolejności zmiany mają być wprowadzone** — pozycje z sekcji 5 pliku wyjściowego, w kolejności wykonania |
| `poza_zakresem` | Czego następny krok nie rusza (sekcja 6) |
| `nastepny` | Propozycja: `etap1.step2`. Decyzję i tak podejmuje orkiestrator |

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
    "quality_gate": { "status": "nie_wykonany", "powod": "brama w budowie" },
    "zatwierdzenie_uzytkownika": true,
    "pliki": [
      { "kolejnosc": 1, "nazwa": "step1-analiza-2.md",
        "sciezka": "refactor-result3/step1-analiza-2.md",
        "rola": "zmiany do zaimplementowania" }
    ],
    "kolejnosc_implementacji": [
      "1. Extract interface IClock dla DateTime.Now w OrderCalculator",
      "2. Wstrzyknięcie IClock przez konstruktor",
      "3. Test charakteryzujący dla CalculateOrderTotal"
    ],
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
- Wynik quality gate jest odnotowany jako ostatni wpis iteracji, przed wpisem
  o wysłaniu `step.done`.
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
2026-09-08; 17-21-49 — 6. Zapisano step1-analiza-1.md, zatwierdzone przez użytkownika.
2026-09-08; 17-21-55 — 7. Zadeklarowano 4 iteracje dla wskazanego zakresu (bieżąca: 1).
2026-09-08; 17-22-05 — 8. Quality gate Step 1: (w budowie — nie wykonywany).
2026-09-08; 17-22-10 — 9. Wysłano step.done do orkiestratora; koniec pracy kroku.
```

## Quality gate Step 1 *(w budowie)*

Po zakończeniu analizy, **przed przekazaniem sterowania do Step 2**, uruchamiane
jest sprawdzenie tego, co krok wytworzył — test akceptacyjny kroku analizy.

**Na tę chwilę sekcja jest wyłącznie zaznaczona — nic z niej nie jest
implementowane ani wykonywane.** Do rozstrzygnięcia w kolejnej iteracji:

- co dokładnie jest sprawdzane (kompletność sekcji 1–7 pliku wyjściowego?
  wykonalność pozycji z sekcji „Zmiany do zaimplementowania"? zgodność
  z granulacją z Pytania 0?),
- kto sprawdza (osobny agent oceniający, ten sam agent, orkiestrator, człowiek),
- co się dzieje przy wyniku negatywnym (powtórzenie analizy, `user.input`,
  przerwanie iteracji),
- jak wynik jest zapisywany i gdzie (log Step 1, osobny plik werdyktu).

Do czasu rozstrzygnięcia bramą Step 1 pozostaje **zatwierdzenie przez
użytkownika** (`user.approval`) z sekcji „Do akceptacji". W wiadomości
`step.done` pole `quality_gate.status` ma wtedy wartość `nie_wykonany`
z podanym powodem — pole jest obecne zawsze, żeby orkiestrator nie musiał
rozróżniać „brak bramy" od „brak informacji".

## Przekazanie do Step 2

Step 1 kończy się, gdy: plik `step1-analiza-N.md` istnieje i jest kompletny,
użytkownik go zatwierdził, wynik quality gate jest odnotowany w logu,
a wiadomość `step.done` poszła do orkiestratora.

**Sposób przekazania sterowania — rozstrzygnięty: przez orkiestratora.**
Step 1 **nie uruchamia Step 2** i nie ma takiej możliwości. Przebieg wygląda
tak:

1. Step 1 wysyła `step.done` → koniec pracy agenta analizującego.
2. Orkiestrator sprawdza bramę wyjściową kroku, zapisuje licznik iteracji
   i lokalizację plików, i **decyduje**, czy uruchomić Step 2.
3. Jeśli tak — wysyła `step.start` do `etap1.step2` z **tym samym payloadem**,
   uzupełnionym o `config`. To rozpoczyna pracę agenta kodującego.

Kroki są dzięki temu od siebie odizolowane: Step 1 nie wie, kto ani kiedy
wykona jego listę zmian, a jedynym kanałem między nimi jest wiadomość JSON
przechodząca przez orkiestratora (patrz „Kroki Etapu 1 jako jednostki
sterowania" w `orkiestrator.md`).
