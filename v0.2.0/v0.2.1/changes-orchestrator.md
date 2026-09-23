##INfo dla cluade
To jest plik gdzie komunikujemy zmiany, ja podaje swoje ty dopisujesz wątpliwości i rezultaty zmian,
Swoją sekcje oznaczacz Claude
Piszemy zwięźle i bez skrótów, adresujemy dokąłdnie zmiany i pytania czyli np jaki plik nazwa i nazwa sekcji która linia,
Nie uruchamiamy żadnych dodatkowych narzędzi, to jest etap tworzenia harnessa, testy będę przeprowadzał gdzie indziej
Zmiany są dla refactor-legacy-v0.2.0
##

##User - zadania
Orkiestrator stął się za duży 1200 linii i będzie puchnoł czas na odchudzanie.
Kroki odchudzania:
- wprowadzamy katalg orchestrator-exemples w nim będą przechowywane przykłady paylodów, jsonów, jeżele ten plik będzie także za bardzo rosnoł to będziemy go dzielić na pliki z nazwami sekcji,
    w sammy orkiestratorze zamiast przykąłdów użycia będzie ścieżka do pliku z przykładem,
- na pierwszy ogień idzie # Stan sesji harnessu taka sekcja - zróbmy jednak od razu każda sekcja będzie miała osobny plik nawet jeżeli miała by być to jedna linia,
- usuń nawiązania do backloga jeżeli coś jest nie pełne to tylko adnotacja "w budowie"
- jeżeli brakuje czegoś, jakiegoś kroku, zawsze stosuj adnotacje "w budowie", żadnych odwołań do innych plików typu backlog czy changes

**Claude — wprowadzone (2026-09-16):**

**Nowy katalog `refactor-legacy-v0.2.0/orchestrator-examples/`** — jeden plik
na sekcję orkiestratora, każdy z nagłówkiem „# Przykład — …" i linią „Sekcja
orkiestratora: …", żeby dało się wrócić do miejsca pochodzenia:

| Plik | Sekcja orkiestratora | Co zawiera |
|---|---|---|
| `stan-sesji-harnessu.md` | „Plik stanu sesji (`refactor-session.md`)" | szablon pliku stanu |
| `refactor-config.md` | „Plik konfiguracji (`refactor-config.json`)" | komplet pól konfiguracji |
| `koperta-wiadomosci.md` | „Koperta wiadomości" | koperta z kompletem pól |
| `etap2-zleca-zmiane-testu.md` | „Przykład: Etap 2 zleca zmianę testu Etapowi 1" | request `test.update` + dispatch `task.execute` |
| `przekazanie-miedzy-krokami-etapu-1.md` | „Przekazanie między krokami Etapu 1" | trzy wiadomości iteracji |
| `log-orkiestratora.md` | „Log orkiestratora (`orkiestrator-log.md`)" | dwa przykłady wpisów |

**`orkiestrator.md`**
- Z każdej z tych sześciu sekcji wycięty przykład, w jego miejsce jedna linia
  ze ścieżką do pliku. Reguły i listy pól obowiązkowych zostały w orkiestratorze
  — wyniesione są wyłącznie przykłady.
- „Struktura harnessu (pliki)" — dodany wiersz `orchestrator-examples/*.md`
  i akapit z regułą: przykłady są poza plikiem, jeden plik na sekcję, nazwa
  pliku = nazwa sekcji; w treści zostaje reguła i ścieżka, nigdy sam przykład.
- Odwołania do `backlog.md` — usunięte (były dwa: w „Bramy kroków (Etap 1)"
  i w `etap1/step1.md`); zastąpione treścią rozstrzygnięcia z `changes-step.md`.
- Rozmiar: **1270 → 1096 linii** (po doliczeniu zmian z `changes-step.md`,
  które ten plik powiększyły o ~60 linii).

**Co zostało w orkiestratorze jako blok kodu (celowo, to nie są przykłady):**
format znacznika czasu (`yyyy-MM-dd; HH-mm-ss`) oraz dwa wywołania PowerShell
(`00-brama.ps1`, eraser) — to interfejs do uruchomienia, nie ilustracja.

**Wątpliwości:**

1. **Nazwa katalogu** — poprawiona na `orchestrator-examples` (na Twoje
   polecenie). Reszta harnessu jest po polsku (`komunikacja/`,
   `scripts/step1/eraser`) — jeśli ma być spójnie, zostaje wariant
   `orkiestrator-przyklady`.
2. **Granulacja „jeden plik na sekcję"** — sekcje „Przykład: Etap 2 zleca
   zmianę testu" i „Przekazanie między krokami Etapu 1" mają po 2–3 wiadomości;
   trzymam je w jednym pliku sekcji (rozdzielone nagłówkami `##`). Jeśli
   „osobny plik nawet na jedną linię" ma znaczyć plik na **każdą wiadomość**,
   rozbiję je na 5 plików.
3. **Reszta odchudzania** — po wycięciu przykładów największe sekcje to
   „Konfiguracja wstępna (Pytania 0–2)" (~150 linii), „Tryb testowy" (~110)
   i „Protokół komunikacji" (~90). Jeśli plik ma dalej chudnąć, to one są
   następne w kolejce — czekam na decyzję, czy tniemy je tą samą metodą
   (osobne pliki), czy dopiero gdy urosną.

##User Zadania
przykłąd tekstu z orkiestratora
'Czego orkiestrator **nie** robi: nie analizuje kodu, nie pisze i nie zmienia
testów, nie proponuje seamów ani refaktoryzacji. Cała merytoryka należy do
etapów. Orkiestrator odpowiada wyłącznie za porządek, kompletność i przepływ.'

Dlaczego ten tekst jest przypominany jeżeli orkiestrator nie ma zdefinowanych innych poleceń i właściwości to nie powinien ich robić.
Zmieniłem pole description żeby nie trzeba było powtarzać tego wielokrotnie.

przy okazji redukcji wielkości pliku orkiestratora, przejdziemy do etapu 0.
Ten etap to sprawdzenie czy istnieje poprzednia sesja.
Etap 0 jest uruchamiany przez orkiestratora. Zmienisz teraz sposób uruchamiania i działania etapu 0 na bardziej deterministyczny,
zbuduj skrypt do etapu 0 który wyszukuje poprzednie sesje, robi w skrypcie to co teraz etap 0, zastosujemy hooka który będzie zawsze uruchamiany na początku startu agenta.
Ten hook ma zadanie za pomcą skryptu zbadać czy istnieje poprzednia sesja, ma działać tak jak teraz etap 0.
reszta czyli komunikacja z orkiestratorem pozostaje bez zmian. Skrypt do etapu 0 zapisz w katalogu scripts\etap0

Na podstawie odpowiedzi od agenta etapu 0 orkiestrator będzie reagował.
Zajmiemy się tym jak tylko skończysz zzmiany w pliku etap0

**Claude — wprowadzone (2026-09-18):**

**1. Powtórzenie w `orkiestrator.md`** — masz rację, to była duplikacja
`description`. Akapit „Czego orkiestrator **nie** robi: nie analizuje kodu…"
(sekcja „Rola orkiestratora", linie 126–128) — usunięty. Został następny akapit,
bo mówi co innego (podstawa metodyczna należy do etapu i orkiestrator jej nie
przekazuje) i tego w `description` nie ma; zaczyna się teraz od „Orkiestrator
**nie niesie podstawy metodycznej**". Plik: 1093 → 1092 linie.

**2. Etap 0 — rozpoznanie deterministyczne.** Nowe pliki:

| Plik | Rola |
|---|---|
| `scripts/etap0/00-rozpoznanie.ps1` | Całe rozpoznanie: katalogi wynikowe trybu, konfiguracja, sesje, statusy etapów, requesty otwarte, pozycje otwarte, stan sesji, anomalie → `etap0-raport.json` |
| `scripts/etap0/_wspolne.ps1` | Znaczniki czasu, zapis JSON bez BOM, wyszukanie katalogów trybu |
| `hooks/etap0-session-start.ps1` | Hook `SessionStart` — uruchamia skrypt przy każdym starcie agenta, wypisuje 4 linie podsumowania + ścieżkę raportu |
| `hooks/settings.hook.example.json` | Fragment `.claude/settings.json` rejestrujący hooka |
| `orchestrator-examples/etap0-raport.md` | Przykład raportu (wycięty z `etap0.md`) |

Wywołanie: `00-rozpoznanie.ps1 -KatalogProjektu <ścieżka> [-Tryb normalny|test]
[-Wyjscie <plik>] [-BezTworzenia] [-Cicho]`; kod wyjścia 0 = raport powstał,
2 = błąd wywołania. Hook woła go z `-BezTworzenia`, żeby w projekcie bez
historii harnessu nie powstawał żaden katalog ani plik.

Reguły, które w skrypcie musiały zostać rozstrzygnięte jednoznacznie (były
opisowe): granica sesji = nagłówek `## Uruchomienie <znacznik>`
w `orkiestrator-log.md`, zapasowo przerwa ≥ 4 h + anomalia; status etapu przede
wszystkim z `komunikacja/*.json`, dopiero zapasowo z obecności logu/pliku
wynikowego (pole `zrodlo_statusu`); request otwarty = `msg_id`, do którego nie
odwołuje się żadne `corr_id`.

**`etap0.md`** — przepisany: kto wykonuje (hook / skrypt / agent), przebieg,
wywołanie skryptu, zakres przeszukania, reguły rozpoznania, opis pól raportu
(przykład wyniesiony do `orchestrator-examples/`). Usunięte odwołanie do
`refactor-decisions.md` — konfiguracją jest `refactor-config.json`; obecność
starego pliku skrypt zgłasza jako anomalię. Adnotacje „w budowie": test samego
skryptu rozpoznania, instalacja hooka w projekcie. Plik: 187 linii.

**`orkiestrator.md`** — wyłącznie „Struktura harnessu (pliki)": trzy nowe
wiersze i zmieniony opis wiersza `etap0.md`. Reszty sekcji Etapu 0 nie ruszam —
zgodnie z Twoim „zajmiemy się tym, jak skończysz zmiany w `etap0`".

**Wątpliwości:**

1. **Hook nie zna trybu.** Pytanie T pada po starcie agenta, więc hook biegnie
   z `-Tryb normalny`. Jeśli orkiestrator ustali `test`, raport z hooka dotyczy
   złego zbioru katalogów i skrypt trzeba uruchomić ponownie z `-Tryb test` —
   tak to teraz opisałem. Alternatywa: hook skanuje oba tryby i wytwarza dwa
   raporty. Nazwy katalogów drugiego trybu są w raporcie (`katalogi_innego_trybu`),
   więc informacja nie ginie.
2. **Schemat raportu podbity na `etap0-raport/2`.** Zmiany: `sesje[].koniec` →
   `ostatni_wpis` + `liczba_wpisow` (koniec sesji nie dawał się wyznaczyć
   deterministycznie), usunięte `zaakceptowany_przez_uzytkownika` (to samo),
   doszły `zrodlo`, `katalog_projektu`, `katalogi_innego_trybu`,
   `etapy[].zrodlo_statusu`, `etapy[].liczba_wiadomosci`,
   `sesja_poprzednia.punkt_wznowienia`. Gotowe mocki w schemacie `/1` przestaną
   pasować.
3. **`etapy[]` obejmuje teraz Etap 0** (0–3, wcześniej 1–3) — status Etapu 0
   wynika z jego własnych wiadomości. Mogę zawęzić z powrotem do 1–3.
4. **Czy agent Etapu 0 jest jeszcze potrzebny?** Hook wytwarza raport przed
   uruchomieniem orkiestratora; agent w tej wersji wyłącznie uruchamia skrypt
   ponownie (tryb `test`) i zwraca raport. Do rozważenia przy zmianach
   w orkiestratorze: czy zostaje jako opakowanie protokołu, czy orkiestrator
   czyta raport po ścieżce.
5. **Kto instaluje hooka** w `.claude/settings.json` projektu objętego
   refaktorem — na razie „w budowie", fragment leży w
   `hooks/settings.hook.example.json`.
6. **Skrypty nie były uruchomione** — w tym środowisku nie ma `pwsh`, zgodnie
   z zasadą, że to etap tworzenia harnessu.

##user - zadania i uwagi do poprzednich

Hook jest odpalany na etapie 0, testami na razie się nie przejmujemy, nie wiadomo czy finalnie nie będą musiały być usunięte z tej wersji,
dopisz do backloga że jest taka niezgodność z testami, do obsłużenia na później,

Po za tym w sekcji ## Rola orkiestratora jest zapis
**Ustala tryb uruchomienia.** Jako **pierwszą czynność**, jeszcze przed
   Etapem 0, orkiestrator rozstrzyga tryb (`normalny` / `test`)
Czyli wyznaczenie trybu jest przed etapem 0

Wyrzucamy ten punkt:
7. **Pilnuje integralności konfiguracji** (patrz "Kontrola integralności").
czyli rezygnujemy ze snapshota w pamięci, mamy plik od tego który jest na dysku zapisany, orkiestrator nie będzie trzymał go w pamięcie ale przy każdym requeście do agenta będzie odczytywał ten plik i pchał zawartość do agenta w takiej formie jak to teraz robi.

odpowiedz na punkt 4 - tak agent zostastaje,

5 - czy nie wytstarczyt że hook jest zdefiniowany w etap 0? tam powinien być wprowadzony tak jak się wrzuca hooka do pliku md, poprzedzonego frontmaterem, ten hook będzie uruchamiany w agentcie i tylko tam, wynik i tak będzie lądował w pliku a sam agent przepcha jsona do orkiestratora


**Claude — wprowadzone (2026-09-18, druga tura):**

**1. Hook należy do Etapu 0.** Katalog `hooks/` usunięty w całości
(`etap0-session-start.ps1`, `settings.hook.example.json`). Hook jest teraz
zadeklarowany we **frontmatterze `etap0.md`** (zdarzenie `SessionStart`),
a opakowanie leży w `scripts/etap0/hook-start.ps1`. Uruchamia się wyłącznie
z agentem Etapu 0; wynik ląduje w pliku, agent przepycha JSON orkiestratorowi.
Komenda hooka wskazuje `${CLAUDE_PLUGIN_ROOT}/scripts/etap0/hook-start.ps1` —
gdy harness nie jest uruchamiany jako plugin, w tym miejscu stoi ścieżka
bezwzględna (adnotacja w `etap0.md`, sekcja „Hook").

**2. Tryb jest znany przed Etapem 0** — masz rację, „Rola orkiestratora"
punkt 2 to rozstrzyga. Moja wątpliwość 1 z poprzedniej tury odpada. Przebieg
w `etap0.md` przepisany na 6 punktów: tryb → start agenta → hook → sprawdzenie
zgodności trybu → zwrot raportu → interpretacja. Tryb dociera do hooka zmienną
`REFACTOR_TRYB` (katalog projektu — `REFACTOR_KATALOG_PROJEKTU`); przy braku
zmiennych hook bierze `normalny` i katalog bieżący, a agent porównuje pole
`tryb` raportu z `payload.config.tryb` i przy rozjeździe uruchamia skrypt
ponownie. Sposób ustawiania tych zmiennych przez orkiestratora — *w budowie*.
Hook nie używa już `-BezTworzenia` (sam przełącznik w skrypcie zostaje).

**3. Snapshot w pamięci — usunięty.** `orkiestrator.md`:
- „Rola orkiestratora": punkt 7 („Pilnuje integralności konfiguracji")
  usunięty, punkty 8–11 przenumerowane na 7–10. Punkt 4 mówi teraz, że przy
  **każdej** wiadomości do etapu i kroku orkiestrator wczytuje
  `refactor-config.json` z dysku i wkłada zawartość w `payload.config`.
- Sekcja „Snapshot konfiguracji i kontrola integralności" → **„Konfiguracja
  w trakcie przebiegu"**: konfiguracja żyje tylko na dysku, odczyt przed
  `stage.start` / `step.start` / `task.execute` / `stage.resume`, forma
  przekazania bez zmian. Zmiana pliku obowiązuje od najbliższego odczytu.
- Usunięte wszystkie pozostałe odwołania: „Tryb jako część konfiguracji"
  (punkty 2 i 4), brama wejściowa warunek 2 (zostaje „istnieje i jest poprawnym
  JSON-em"), brama wyjściowa warunek 5 (skreślony), „Znaczniki czasu" zasada 1,
  „Plik konfiguracji" zasada 3, pętla sterowania punkty 2 i 6, zakres logu
  orkiestratora, tabela odstępstw trybu `test`.
- `etap1/step1.md` punkt 3: „Orkiestrator niezależnie weryfikuje ten plik
  względem swojego snapshotu" → „Orkiestrator czyta ten sam plik przy każdej
  wiadomości do kroku".
- Rozmiar: 1092 → 1072 linie.

**4. Agent Etapu 0 zostaje** — zgodnie z Twoją odpowiedzią. W `etap0.md` jego
rola to: odebrać raport wytworzony przez hooka, sprawdzić zgodność trybu,
zwrócić `payload.report`.

**5. Backlog** — dopisana pozycja **E9** (`backlog.md`, sekcja „E. Tryb testowy
orkiestratora"): hook uruchamia się także w trybie `test`, więc rozpoznanie
wykonuje się naprawdę, a tabela odstępstw mówi, że Etap 0 jest mockowany. Do
rozstrzygnięcia później. W samym harnessie stoi adnotacja „w budowie"
(`etap0.md`, sekcja „Tryb testowy") — bez odwołania do backloga.

**Wątpliwości:**

1. **Po usunięciu kontroli integralności nie ma żadnego wykrywania zmian
   `refactor-config.json` w trakcie przebiegu.** Zostawiłem w tym miejscu
   adnotację „w budowie". Jeśli to ma zostać bez wykrywania na stałe, adnotację
   usunę.
2. **`orkiestrator.md` nadal mówi „Etap 0 też jest mockowany"** (sekcja „Tryb
   testowy"). Nie ruszam, bo to część E9 — ale to zdanie i hook wykluczają się
   wzajemnie już teraz.


