##INfo dla cluade
To jest plik gdzie komunikujemy zmiany, ja podaje swoje ty dopisujesz wątpliwości i rezultaty zmian,
Swoją sekcje oznaczacz Claude
Piszemy zwięźle i bez skrótów, adresujemy dokładnie zmiany i pytania czyli np jaki plik nazwa i nazwa sekcji która linia,
Nie uruchamiamy żadnych dodatkowych narzędzi, to jest etap tworzenia harnessa, testy będę przeprowadzał gdzie indziej
Zmiany są dla refactor-legacy-v0.2.0
##

##User - zadania
Usuwamy tryb test z orkiestratora oraz mocki, jeżeli zmian jest dużo rozbij to na etapy,
Na początek sam orkiestrator, a potem sprawdz odwołania do testowania w poszczególnych etapch i usuń również tam ale jak wspominałem zmiany w etapach później. po zaakcetpowaniu zmian w orkiestratorze

##Claude - analiza i pytania (etap A: sam orkiestrator)

Zrobiłem przegląd `refactor-legacy-v0.2.0/orkiestrator.md` (1072 linie).
Rozdzielam dwa różne znaczenia słowa "test", żeby nic nie wyciąć za dużo:

- **tryb `test` harnessu + mocki etapów** — do usunięcia (to zadanie),
- **testy jednostkowe refaktoryzowanego projektu** (Pytanie 0: build/testy,
  framework testów; akcje `test.update` / `test.add` / `test.remove`;
  `test.mock.enable` / `test.mock.add` — mocki w projekcie testowym, np. Moq)
  — **zostawiam nietknięte**, to merytoryka refaktoru, nie tryb testowy harnessu.

### Co usuwam w etapie A (orkiestrator.md) — o ile potwierdzisz pytania niżej

| Linie | Sekcja | Działanie |
|---|---|---|
| 28–30 | Status dokumentu | zdanie o trybie uruchomienia i trybie testowym — usunąć |
| 170–206 | `## Tryb uruchomienia (normalny / test)` wraz z `### Pytanie T` i `### Tryb jako część konfiguracji` | usunąć całą sekcję |
| 982–1049 | `## Tryb testowy (test)` wraz z podsekcjami "Na czym polega izolacja", "Mock to paczka, nie sam JSON", "Brak mocka to twardy błąd", "Odstępstwa...", "Ocena przebiegu" | usunąć całą sekcję |
| 1050–1072 | `### Odłożone do kolejnych iteracji` | patrz Pytanie 4 |
| 94–98 | Rola orkiestratora, punkt 2 ("Ustala tryb uruchomienia") | usunąć punkt, przenumerować 3–10 |
| 264 | Interpretacja raportu, wiersz "Brak katalogu wynikowego" | usunąć wtrącenie `(w trybie test: refactor-result-test1)` |
| 288 | Plik stanu sesji | usunąć wariant `tak (tryb test — oznaczone, kontekst nieczyszczony)`; zostaje tylko `tak (automatycznie)` |
| 316–318 | Brama wejściowa, wyjątek Etap 0 | usunąć zdanie o mockowaniu Etapu 0 |
| 335–338 | Brama wejściowa, warunek 5 | usunąć "Wyjątek w trybie `test`" dla Etapu 3 — warunek działa bez wyjątków |
| 357–360 | Brama wyjściowa | usunąć akapit "W trybie `test` bramy wyjściowej nie łagodzimy" |
| 506–508 | Izolacja kroków | usunąć punkt "wymianę da się podstawić mockiem..." |
| 680 | Wartości dopuszczalne | patrz Pytanie 1 |
| 693–740 | Katalog wynikowy | usunąć tabelę trybów i zostawić wyłącznie `refactor-resultN`; przepisać zasadę 2 (widzenie katalogów innego trybu), zdanie "Dotyczy to obu trybów..." i wtrącenia `refactor-result-test1` |
| 869–871 | Pętla sterowania, punkt 0 (Pytanie T) | usunąć punkt, przenumerować |
| 873–877 | Pętla sterowania, punkt 1 | usunąć "(w trybie test: podstaw raport z mocka)" i "w trybie test `/clear` jest tylko odnotowywany" |
| 882 | Pętla sterowania, punkt 2 | usunąć "razem z trybem" |
| 888–890 | Pętla sterowania, punkt 4 | usunąć zdania o podstawianiu mocka zamiast wykonania etapu |
| 957–958 | Log orkiestratora | usunąć "W trybie test dodatkowo: który mock został podstawiony pod który dispatch" |
| 973–974 | Log orkiestratora | usunąć "(i czy było automatyczne, czy tylko odnotowane w trybie test)" |
| 83, 667 | Konfiguracja | wzmianki o "przebiegu testowym" jako powodzie formatu JSON / podstawienia pliku z zewnątrz — patrz Pytanie 5 |

### Pytania (nie zgaduję, czekam na odpowiedź)

**Pytanie 1 — pole `tryb` w konfiguracji.**
Czy pole `tryb` znika **całkowicie** z `refactor-config.json` i z
`payload.config`, czy zostaje z jedyną dopuszczalną wartością `normalny`?
Dotyczy: `orkiestrator.md` linia 680 (wartości dopuszczalne),
`refactor-config.example.json` linie 17–21, `orchestrator-examples/refactor-config.md`
linia 24, `orchestrator-examples/etap2-zleca-zmiane-testu.md` linia 50.
Moja rekomendacja: usunąć całkowicie — jeśli jest jedna wartość, pole niczego
nie rozstrzyga, a zostawione kusi do przywrócenia trybu.

**Pytanie 2 — pole `tryb` w raporcie Etapu 0 i pole "Tryb uruchomienia" w stanie sesji.**
Raport Etapu 0 ma pole `tryb` i `katalogi_innego_trybu`
(`orchestrator-examples/etap0-raport.md` linie 13, 21, 29, 104, 128),
`refactor-session.md` ma wiersz "Tryb uruchomienia"
(`orchestrator-examples/stan-sesji-harnessu.md` linia 10),
log orkiestratora ma wpis "Ustalono tryb uruchomienia"
(`orchestrator-examples/log-orkiestratora.md` linia 12).
Czy te pola usuwam teraz razem z orkiestratorem, czy dopiero przy etapach,
skoro raport wytwarza skrypt Etapu 0?

**Pytanie 3 — zakres etapu A.**
Czy `orchestrator-examples/*.md` i `refactor-config.example.json` traktujemy
jako część orkiestratora (poprawiam w tym etapie), czy osobno? To pliki
orkiestratora, nie etapów, więc domyślnie wziąłbym je teraz — ale wynik zależy
od odpowiedzi na Pytania 1 i 2.

**Pytanie 4 — sekcja "Odłożone do kolejnych iteracji" (linie 1050–1072).**
Jest podsekcją "Trybu testowego", ale dwa jej punkty nie dotyczą trybu test:
- "Konfiguracja bez pytań" (czy gotowy `refactor-config.json` z zewnątrz może
  zastąpić Pytania 0–2),
- "Ścieżki inne niż happy path" (nieudany quality gate Step 2, powrót iteracji,
  korekta liczby iteracji).

Czy usuwam całą sekcję razem z tymi dwoma punktami, czy przenoszę te dwa punkty
do nowej sekcji na końcu dokumentu (np. `## Odłożone do kolejnych iteracji`
poza kontekstem testowym)?

**Pytanie 5 — uzasadnienia powołujące się na "przebieg testowy".**
Linia 83 (dlaczego konfiguracja jest w JSON: "może zostać podstawiona z zewnątrz —
skrypt, przygotowany przebieg testowy") i linia 667 (zasada 3: "plik może zostać
przygotowany poza harnessem — skrypt, przebieg testowy").
Zostawiam samo "skrypt" i wykreślam "przebieg testowy", czy całą możliwość
podstawienia konfiguracji z zewnątrz też wycinamy?

**Pytanie 6 — potwierdzenie, że to zostaje.**
Potwierdź, że **nie ruszam**: Pytania 0 (build/testy, framework testów),
katalogu akcji `test.update` / `test.add` / `test.remove` /
`test.mock.enable` / `test.mock.add` (linie 792–797), punktu 5 pętli sterowania
w części o tych akcjach (linie 930–935) i quality gate Step 2 (build + testy).
To testy refaktoryzowanego projektu, nie tryb testowy harnessu.

**Pytanie 7 — frontmatter `description` (linia 3).**
Nie zawiera trybu testowego, ale mówi o "dodaniu testów do kodu bez pokrycia".
Zakładam, że zostaje bez zmian — potwierdź.

### Etap B (po akceptacji etapu A) — tylko rozpoznanie, nic nie zmieniam

Odwołania do trybu `test` / mocków poza orkiestratorem, do zrobienia później:

- `etap0.md` — 16 trafień,
- `etap1/step1.md` — 31 trafień, `etap1/step2.md` — 76 trafień (większość to
  testy jednostkowe projektu, do rozdzielenia jak wyżej),
- `scripts/etap0/00-rozpoznanie.ps1` — 18 trafień (parametr trybu, katalogi
  `-test`), `scripts/etap0/hook-start.ps1`, `scripts/etap0/_wspolne.ps1`,
- `scripts/step1/*.ps1` — trafienia do przejrzenia pod kątem tego samego podziału.

Czekam na odpowiedzi — nic w `refactor-legacy-v0.2.0/` jeszcze nie zmieniłem.

##User - odpowiedzi
1 - Tryb zostaje - jeden wybór, normalny - poprzednie wersje miały wyznacznik czy normalna czy test a teraz usunięcie tej informacji niesie ze sobą ryzyko braku rozpoznania czy to test czy normalny tryb po za tym taka pozycja może być użyta później jako różne tryby pracy, więc pole powinno zostać
2 - zmień razem ze zmianami orkiestratora
3 - to jest traktowane razem,
4 - przenieś do nowej sekcji odłożone ....
5 - tak wycinamy wszystko, bo nie będzie już testowania, więc nie wrzucanie czegoś z zewnątrz nie ma sensu,
6 - tak potwierdzam to zostaje,
7 - tak zostaje bez zmian, description sam poprawie


##Claude - wykonane (etap A)

Zmienione pliki w `refactor-legacy-v0.2.0/`: `orkiestrator.md`,
`refactor-config.example.json`, `orchestrator-examples/refactor-config.md`,
`orchestrator-examples/etap0-raport.md`,
`orchestrator-examples/log-orkiestratora.md`.
Nic w `etap0.md`, `etap1/`, `scripts/` nie ruszone.

### `orkiestrator.md`

Usunięte całe sekcje:
- `## Tryb uruchomienia (normalny / test)` razem z `### Pytanie T`
  i `### Tryb jako część konfiguracji`,
- `## Tryb testowy (test)` razem z podsekcjami "Na czym polega izolacja",
  "Mock to paczka, nie sam JSON", "Brak mocka to twardy błąd",
  "Odstępstwa obowiązujące wyłącznie w trybie test", "Ocena przebiegu".

Usunięte pojedyncze miejsca:
- Status dokumentu — zdanie o trybie uruchomienia, mockach i systemie ocennym,
- Rola orkiestratora — punkt 2 ("Ustala tryb uruchomienia"); lista
  przenumerowana, ma teraz 9 punktów,
- Brama wejściowa — zdanie o mockowanym Etapie 0; z warunku 1 wykreślone
  "Pytanie T (tryb)"; z warunku 5 wyjątek dla Etapu 3 w trybie `test`,
- Brama wyjściowa — akapit "W trybie test bramy wyjściowej nie łagodzimy",
- Izolacja kroków — punkt "wymianę da się podstawić mockiem",
- Konfiguracja wstępna — akapit o Pytaniu T,
- Plik konfiguracji — zasada 3 "Możliwość podstawienia z zewnątrz"
  (odpowiedź 5); zasady przenumerowane, są teraz 4,
- Uzasadnienie formatu JSON (sekcja "Pliki konfiguracji") — wykreślone
  "może zostać podstawiony albo zmodyfikowany z zewnątrz (skrypt, przygotowany
  przebieg testowy)" (odpowiedź 5),
- Katalog wynikowy — tabela dwóch trybów, wzorzec `refactor-result-testN`,
  zdanie "Dotyczy to obu trybów", wtrącenie `refactor-result-test1`
  w wyjątku Etapu 0,
- Pętla sterowania — punkt 0 (Pytanie T); z punktu 1 podstawianie raportu
  z mocka i "`/clear` tylko odnotowywany"; z punktu 4 podstawianie mocka
  zamiast wykonania etapu,
- Log orkiestratora — "wybór trybu uruchomienia" z listy odnotowywanych rzeczy,
  "W trybie test dodatkowo: który mock został podstawiony pod który dispatch",
  "(i czy było automatyczne, czy tylko odnotowane w trybie test)",
- Plik stanu sesji — wariant `tak (tryb test — oznaczone, kontekst
  nieczyszczony)`; zostaje wyłącznie `tak (automatycznie)`,
- Interpretacja raportu — wtrącenie `(w trybie test: refactor-result-test1)`.

Przepisane:
- Katalog wynikowy, zasada 2 — było "Orkiestrator widzi wyłącznie katalogi
  bieżącego trybu", jest "Liczy się wyłącznie wzorzec `refactor-resultN`.
  Katalog o innej nazwie (np. pozostały po wcześniejszej wersji harnessu) jest
  pomijany". Zostawiłem tę zasadę celowo: w projektach mogą leżeć katalogi
  `refactor-result-testN` z poprzednich przebiegów i nie wolno ich rozpoznać
  jako sesji,
- Kolejność ustalania katalogu — było "tryb → Etap 0 → decyzja → numer", jest
  "Etap 0 → decyzja → numer",
- Pętla sterowania, punkt 2 — zapis konfiguracji "razem z pozycją `tryb`,
  ustawieniami build/testy i formatem znacznika czasu".

Dodane (odpowiedź 1) — nowy akapit **"Pozycja `tryb`"** w sekcji
"Plik konfiguracji (`refactor-config.json`)": jeden tryb pracy `normalny`,
`zrodlo: "domyslne"`, użytkownik nie jest o tryb pytany, pole zostaje jako
jawne oznaczenie przebiegu i miejsce na przyszłe tryby pracy; trafia do
`payload.config` i do raportu Etapu 0.

### Pozostałe pliki

- `refactor-config.example.json` — `tryb._dozwolone` z `["normalny", "test"]`
  na `["normalny"]`, `tryb.zrodlo` z `uzytkownik` na `domyslne`. JSON się
  parsuje.
- `orchestrator-examples/refactor-config.md` — `tryb.zrodlo` na `domyslne`.
- `orchestrator-examples/etap0-raport.md` — usunięte pole
  `"katalogi_innego_trybu": ["refactor-result-test1"]`. Pola `tryb` w raporcie
  i w `sesja_poprzednia` zostają (odpowiedź 1).
- `orchestrator-examples/log-orkiestratora.md` — wpis 1 z "Ustalono tryb
  uruchomienia: normalny (Pytanie T, wybór użytkownika)" na "(stała harnessu,
  bez pytania)". Numeracja wpisów nietknięta.
- `orchestrator-examples/stan-sesji-harnessu.md` — bez zmian, wiersz "Tryb
  uruchomienia: normalny" zostaje.
- `orchestrator-examples/etap2-zleca-zmiane-testu.md`,
  `koperta-wiadomosci.md`, `przekazanie-miedzy-krokami-etapu-1.md` — bez zmian
  (dotyczą testów projektu, nie trybu testowego harnessu).

### Do rozstrzygnięcia — dwie rzeczy, których sam nie przesądziłem

**A. Konflikt odpowiedzi 4 i 5.** Miałem przenieść do nowej sekcji "Odłożone do
kolejnych iteracji" dwa punkty: "Ścieżki inne niż happy path" i "Konfiguracja
bez pytań". Ale "Konfiguracja bez pytań" to dokładnie pytanie, czy gotowy
`refactor-config.json` podstawiony z zewnątrz może zastąpić Pytania 0–2 —
czyli to, co odpowiedź 5 kazała wyciąć. Przeniosłem więc **tylko "Ścieżki inne
niż happy path"**. Sekcja `## Odłożone do kolejnych iteracji` jest teraz
ostatnią sekcją dokumentu i ma jeden punkt. Potwierdź albo powiedz, żeby
"Konfigurację bez pytań" jednak przywrócić.

**B. Wartość `flaga` w polu `zrodlo`.** W sekcji "Plik konfiguracji", zasada 3
(dawna 4), dopuszczalne wartości `zrodlo` to `uzytkownik`, `flaga`,
`wykryte+potwierdzone`, `domyslne`. `flaga` była tam dla flagi `test` przy
wywołaniu — innych flag harness nie ma. **Zostawiłem ją**, bo nie było o nią
pytania. Czy usunąć?

**C. Etap B — co zostało do zrobienia poza orkiestratorem.** Raport Etapu 0
nadal jest wytwarzany przez `scripts/etap0/00-rozpoznanie.ps1`, który ma
parametr trybu i szuka katalogów `-test`. Dopóki tego nie zmienimy, skrypt
będzie produkował pole `katalogi_innego_trybu`, którego już nie ma w przykładzie
raportu. To jest w etapie B, ale odnotowuję jako niespójność istniejącą
**od teraz do końca etapu B**.

##User -odpowiedzi
 A - konflikty - sekcji nie przywracaj wrzuć w backloga ten info o tym konflikcie żeby potem na to zajrzeć, a na teraz nieprzywracamy,
 B - na razie zostaw,
 C - usuń z nie go wyszukiwanie katalogów z paramtrem test

##Claude - wykonane (A, B, C)

**A — konflikt "Konfiguracja bez pytań".** Sekcji nie przywracam. Okazało się,
że backlog ma już pozycję **A4 "Konfiguracja bez pytań wstępnych"** o dokładnie
tej treści, więc nie zakładałem nowej pozycji, tylko dopisałem do A4 adnotację
o konflikcie (data, co konkretnie zostało wycięte z `orkiestrator.md`, że przy
powrocie do tematu zasadę trzeba napisać od nowa bez kontekstu testowego i że
Pytanie T już nie istnieje). Kolumna "Gdzie w harnessie" w A4 zmieniona
z `orkiestrator.md (v2) → "Odłożone do kolejnych iteracji"` na `nigdzie —
usunięte z orkiestrator.md`. Plik: `backlog.md`, linia 22.

**B — `flaga` w polu `zrodlo`.** Zostawiona bez zmian.

**C — wyszukiwanie katalogów `-test` w skryptach Etapu 0.** Usunięte.
Zmienione trzy pliki, bo parametr trybu przechodził przez wszystkie:

- `scripts/etap0/_wspolne.ps1`
  - `Get-WzorzecKatalogow` — usunięty parametr `-Tryb` i gałąź
    `^refactor-result-test(\d+)$`; zostaje jeden wzorzec `^refactor-result(\d+)$`.
    Komentarz przepisany na regułę z orkiestratora ("katalog o innej nazwie jest
    pomijany").
  - `Get-KatalogiTrybu` → **przemianowana na `Get-KatalogiWynikowe`**, bez
    parametru `-Tryb`. Nazwa z "Trybu" nie miała już sensu. Funkcja nie jest
    używana nigdzie indziej — `scripts/step1/` ma własny `_wspolne.ps1`.
- `scripts/etap0/00-rozpoznanie.ps1`
  - usunięty parametr `-Tryb` z `param(...)`,
  - dodana stała `$TRYB = "normalny"` z komentarzem odsyłającym do "Pozycja
    `tryb`" w orkiestratorze — pole `tryb` zostaje w raporcie (odpowiedź 1),
  - usunięte `$trybDrugi`, `$katalogiDrugiegoTrybu` i pole raportu
    `katalogi_innego_trybu`,
  - usunięta gałąź rozpoznająca `tryb test` w polu "Kontekst wyczyszczony"
    (`Get-SesjaPoprzednia`),
  - katalog zastępczy: było `if ($Tryb -eq "test") { "refactor-result-test1" }
    else { "refactor-result1" }`, jest na sztywno `refactor-result1`,
  - nagłówek pliku: usunięte zdanie o uruchamianiu skryptu ponownie, gdy raport
    dotyczy innego trybu niż `payload.config.tryb`,
  - `Write-Host` podsumowania nadal wypisuje `tryb: normalny` — zgodnie
    z przykładem w `orchestrator-examples/etap0-raport.md`.
- `scripts/etap0/hook-start.ps1`
  - usunięty odczyt `REFACTOR_TRYB` i przekazywanie `-Tryb` do skryptu
    (inaczej wywołanie wywaliłoby się na nieznanym parametrze),
  - usunięty akapit nagłówka o ustalaniu trybu przed Etapem 0.

Skryptów nie uruchamiałem — to środowisko tworzenia harnessu.

### Dwie niespójności, które zostają do etapu B

1. **`etap0.md` nadal dokumentuje parametr `-Tryb`** — linie 53, 58, 70, 77
   i 185 (tabela parametrów skryptu, zmienna `REFACTOR_TRYB`, sekcja o trybie
   testowym). Parametru już nie ma, więc dokumentacja Etapu 0 jest teraz
   nieaktualna. To jest w etapie B, ale od teraz jest rozjazd między plikiem
   a skryptem.
2. **Backlog, sekcja E "Tryb testowy orkiestratora"** (pozycje E1–E9) opisuje
   mechanizm, którego już nie ma w harnessie. Nie ruszałem jej — daj znać, czy
   ma zostać jako historia, czy oznaczyć ją jako nieaktualną.

##User - odpowiedź
tak zostaw

##Claude
Sekcja E backlogu (`backlog.md`, pozycje E1–E9, „Tryb testowy orkiestratora")
zostaje nietknięta jako historia. Etap A zamknięty — nic więcej nie zmieniam.
Niespójność `etap0.md` ↔ skrypty Etapu 0 (parametr `-Tryb`) do zrobienia
w etapie B.
