---
name: refactor-legacy
description: Harness do bezpiecznej refaktoryzacji i wprowadzania zmian w kodzie legacy  Używać zawsze gdy użytkownik prosi o refaktor, zmianę zachowania istniejącego kodu, wydzielenie metod/klas, dodanie testów do kodu bez pokrycia testami, lub redukcję couplingu. Orkiestrator prowadzi proces etapami, pilnuje poprawnego wykonania każdego etapu i wymaga jawnej akceptacji użytkownika między etapami - nie pomijać etapów, nawet jeśli zadanie wygląda na proste. Orkiestrator podejmuje decyzje na temat procesu na podstawie wyników zwracanych przez agentów oraz tego co jest zapisane w piku orkiestratora. Sam nie tworzy refaktoryzacji oraz testów nie analizuje, jest zarządcą, rozdysponowuje zadania, wywołuje quality gates jeżeli dostanie potwierdzenie od agentów. Komunikacja z agentami odbywa się za pomocą plików json.
---

# Refactor Legacy — Orkiestrator

Ten plik jest **punktem wejścia** i pełni rolę **orkiestratora**.

To nie jest typowy skill — to **harness**: warstwa nadrzędna, która sama nie
wykonuje refaktoryzacji, tylko **pilnuje, żeby poszczególne etapy zostały
wykonane poprawnie i w ustalonym porządku**. Merytoryka refaktoru siedzi
w plikach etapów; orkiestrator zbiera konfigurację, uruchamia etapy, waliduje
ich wejście i wyjście, przyjmuje od nich requesty i kieruje sterowanie do
właściwego etapu.

Praktyczna konsekwencja: **żaden etap nie jest uruchamiany bezpośrednio**.
Wejściem zawsze jest orkiestrator — tylko on zna konfigurację, kolejność
etapów i stan procesu.

## Status dokumentu

Szkielet w budowie. Konfiguracja wstępna (plik JSON), protokół komunikacji
i mechanizm wznawiania sesji — opisane. Etap 0 — opisany. Etap 1 — podzielony
na dwa kroki (`.claude/agents/etap1/step1.md`, `.claude/agents/etap1/step2.md`), oba uruchamiane przez
orkiestratora. Etap 2: wariant "Refaktor" kroki 1–3 opisane, kolejne do
zdefiniowania; wariant "Zmiana logiki" — w budowie. Etap 3 — pusty, do
zdefiniowania.

Obowiązuje **happy path**: opisany jest przebieg, w którym kroki kończą się
powodzeniem, a bramy przechodzą. Wyjątek: ścieżka nieudanej bramy Step 1 jest
opisana w całości (jedno ponowienie z erasrem, potem przerwanie — patrz „Bramy
kroków (Etap 1)"). Pozostałe ścieżki błędu (nieudany quality gate Step 2,
powrót iteracji do wcześniejszego kroku) są *w budowie* i nie są tu
rozwijane.


## Struktura harnessu (pliki)

| Plik | Rola |
|---|---|
| `orkiestrator.md` (ten plik) | Orkiestrator: rozpoznanie stanu, konfiguracja wstępna, protokół, pętla sterowania |
| `.claude/settings.json` | Hooki harnessu — obecnie `SubagentStart` z matcherem `etap0` |
| `.claude/hooks/etap0-start.ps1` | Opakowanie hooka Etapu 0 — woła skrypt rozpoznania i wypisuje podsumowanie do kontekstu agenta |
| `.claude/agents/etap0.md` | Etap 0 — Rozpoznanie stanu (wznowienie sesji) |
| `.claude/agents/etap1/step1.md` | Etap 1 / Step 1 — Przygotowanie (Analiza), agent na modelu **opus** |
| `.claude/agents/etap1/step2.md` | Etap 1 / Step 2 — Implementacja, agent na modelu **sonnet** |
| `.claude/agents/etap2.md` | Etap 2 — Wprowadzenie zmiany (Refaktor i/lub Zmiana logiki) |
| `.claude/agents/etap3.md` | Etap 3 — Refaktoryzacja rezultatu Etapu 2 *(pusty, do zdefiniowania)* |
| `scripts/etap0/00-rozpoznanie.ps1` | Skrypt rozpoznania stanu — przeszukuje katalogi wynikowe i wytwarza `etap0-raport.json` (patrz `.claude/agents/etap0.md`) |
| `scripts/step1/*.ps1` | Skrypty quality gate Step 1 — uruchamiane przez orkiestratora, nie przez krok (patrz „Bramy kroków (Etap 1)") |
| `scripts/step1/eraser/00-eraser.ps1` | Skrypt czyszczący wynik bramy Step 1 dla jednej iteracji — orkiestrator uruchamia go przed ponowieniem kroku |
| `etap1-step1-examples/*.md` | Przykłady wyniesione z `.claude/agents/etap1/step1.md` — jeden plik na sekcję kroku |
| `orchestrator-examples/*.md` | Przykłady (payloady, JSON-y, szablony plików) wyniesione z tego pliku — jeden plik na sekcję orkiestratora |

**Przykłady są poza tym plikiem.** Payloady, JSON-y i szablony plików leżą
w `orchestrator-examples/`, **jeden plik na sekcję orkiestratora** (nazwa pliku
= nazwa sekcji). W treści orkiestratora zostaje reguła i ścieżka do przykładu,
nigdy sam przykład.

Orkiestrator wczytuje plik etapu (albo kroku) dopiero w momencie jego
uruchomienia. Etapy nie wywołują się nawzajem bezpośrednio — **każde przejście
między etapami idzie przez orkiestratora**.

**To samo dotyczy kroków wewnątrz etapu.** Etap 1 składa się z dwóch kroków,
które **nie uruchamiają się nawzajem i nic o sobie nie wiedzą**: Step 1 kończy
pracę wiadomością do orkiestratora, orkiestrator decyduje o uruchomieniu
Step 2 i przekazuje mu tę samą wiadomość jako wsad. Krok zna wyłącznie wynik
własnego zadania i to, co dostał w payloadzie — dzięki temu kroki są od siebie
odizolowane i każdy może skupić się na swojej robocie (patrz "Kroki Etapu 1
jako jednostki sterowania").

### Pliki konfiguracji

| Plik | Rola |
|---|---|
| `refactor-config.json` | **Jedyny** plik konfiguracji przebiegu: tryb, odpowiedzi na Pytania 0–2, stałe harnessu. Powstaje w katalogu wynikowym; zapisuje go orkiestrator, czytają wszystkie etapy i kroki |
| `refactor-config.example.json` | Szablon powyższego, w katalogu harnessu: komplet pól z wartościami dopuszczalnymi (`_dozwolone`) i domyślnymi (`_domyslne`). Pola z podkreśleniem są dokumentacją szablonu i nie są czytane przez harness |

Konfiguracja jest w **JSON**, nie w markdownie. Powód: jeden ustrukturyzowany
format, który tak samo czyta każdy etap i każdy krok i który da się rozbudować
o kolejne pozycje bez zmiany sposobu odczytu. Plik `refactor-decisions.md` z poprzedniej wersji harnessu
**przestaje istnieć** — jego rolę (log decyzji użytkownika) przejmują pola
`zrodlo` przy każdej pozycji konfiguracji. Zawartość i zasady — patrz „Plik
konfiguracji (`refactor-config.json`)" w sekcji „Konfiguracja wstępna".

---

## Rola orkiestratora

1. **Inicjuje cały proces.** Etap wstępny (zebranie wymagań, pytania
   konfiguracyjne) jest częścią orkiestratora, nie Etapu 1.
2. **Ustala stan wyjściowy przed konfiguracją.** Zanim padnie pierwsze pytanie
   konfiguracyjne, orkiestrator zleca **Etap 0** i na podstawie jego raportu
   rozstrzyga, czy to nowe uruchomienie, czy kontynuacja (patrz "Etap 0
   i wznowienie sesji").
3. **Dostarcza konfigurację.** Przy **każdej** wiadomości do etapu i do kroku
   wczytuje `refactor-config.json` z dysku i wkłada jego zawartość
   w `payload.config`. Konfiguracji nie trzyma w pamięci — plik na dysku jest
   jedynym źródłem prawdy (patrz "Konfiguracja w trakcie przebiegu").
4. **Czuwa w trakcie działania etapu.** Nie kończy pracy po odpaleniu etapu —
   pozostaje aktywny i reaguje na requesty przychodzące z etapu w dowolnym
   momencie jego trwania (praca asynchroniczna, wymiana dwukierunkowa).
5. **Routuje requesty między etapami.** Przykład: Etap 2 w trakcie zmiany nazw
   stwierdza, że trzeba zmienić test → wystawia request do orkiestratora →
   orkiestrator uruchamia Etap 1 w trybie zadaniowym z tym requestem → po
   wykonaniu wraca sterowanie do Etapu 2 w miejsce, w którym zostało przerwane.
6. **Pilnuje poprawnego wykonania etapów** — sprawdza bramę wejściową przed
   startem i bramę wyjściową po zakończeniu każdego etapu (patrz "Bramy
   etapów"). To główna funkcja harnessu: etap nie decyduje sam o tym, czy
   wolno mu wystartować i czy zrobił, co miał zrobić.
7. **Prowadzi log orkiestratora** — kto, kiedy, jaki request, do kogo
   skierowany, z jakim wynikiem. Każdy wpis poprzedzony znacznikiem czasu
   (patrz "Znaczniki czasu w logach").
8. **Uruchamia kroki etapu i przekazuje między nimi wynik.** Kroki Etapu 1 nie
   komunikują się bezpośrednio — cała wymiana idzie przez orkiestratora
   (patrz "Kroki Etapu 1 jako jednostki sterowania").
9. **Zna licznik iteracji.** Ile iteracji jest przewidzianych i która jest
   aktualnie prowadzona — orkiestrator wie to z wiadomości Step 1 i trzyma
   w `refactor-session.md`. **Wznawianie przerwanego przebiegu jest wyłącznie
   jego zadaniem** — ani etap, ani krok nie jest od tego (patrz
   "Iteracje i wznawianie").

Orkiestrator **nie niesie podstawy metodycznej**. Zasady, którymi kieruje
się agent — czyj katalog technik stosuje, jakim kryterium ocenia rezultat —
należą do etapu i kroku, który je stosuje, i są zapisane w jego pliku (dla
Etapu 1: Feathers, w `.claude/agents/etap1/step1.md` i `.claude/agents/etap1/step2.md`). Orkiestrator ich nie
zna, nie przekazuje i nie egzekwuje.

---

## Znaczniki czasu w logach

Każdy wpis w każdym logu harnessu (log orkiestratora, logi etapów) jest
**poprzedzony znacznikiem daty i godziny**. Nie jest to ozdobnik — to jedyny
mechanizm, po którym Etap 0 rozpoznaje, czy ma do czynienia z nowym
uruchomieniem harnessu, czy z kontynuacją istniejącego.

**Format (obowiązkowy, bez odstępstw):**

```
yyyy-MM-dd; HH-mm-ss
```

gdzie `yyyy-MM-dd` to rok-miesiąc-dzień, a `HH-mm-ss` to godzina-minuta-sekunda
(doba 24-godzinna, człony rozdzielone myślnikami). Przykład: `2026-08-30; 19-07-12`.

**Zasady:**

1. Format jest zapisany w pliku konfiguracyjnym `refactor-config.json`
   (pole `harness.znacznik_czasu`) i wczytywany przez etapy i kroki razem
   z resztą konfiguracji.
2. **Każdy etap i każdy krok na starcie zapisuje w swoim logu datę i godzinę
   uruchomienia**
   jako pierwszy wpis (`## Uruchomienie <yyyy-MM-dd; HH-mm-ss>`).
3. Każdy kolejny wpis logu zaczyna się od znacznika czasu, przed numerem
   i treścią wpisu:
   `2026-08-30; 19-07-12 — 4. Wypisano zależności blokujące testowalność.`
4. Znacznik odnotowuje moment **podjęcia decyzji / wykonania działania**, nie
   moment zapisu pliku.

---

## Etap 0 i wznowienie sesji

Harness może być uruchamiany na tym samym projekcie wielokrotnie. Żeby kolejne
uruchomienie nie zaczynało od zera i nie deptało wyników poprzedniego,
orkiestrator **przed Pytaniami 0–2** ustala, co już zostało zrobione.

### Przebieg

1. **Wczytaj `refactor-session.md`** (jeśli istnieje) — to krótki plik stanu
   sesji, opisany niżej. To jedyna rzecz, którą orkiestrator czyta przed
   Etapem 0.
2. **Sprawdź regułę 4 godzin** (zabezpieczenie przed zapętleniem):
   - Plik istnieje, odnotowuje wyczyszczenie kontekstu, a od znacznika czasu
     tego wpisu minęło **mniej niż 4 godziny** → to jest środowisko przygotowane
     do pracy w tym samym przebiegu. Etap 0 **nie jest uruchamiany ponownie**;
     orkiestrator korzysta z zapisanego `etap0-raport.json` i przechodzi
     do punktu 6.
   - Plik nie istnieje albo od wpisu minęło **4 godziny lub więcej** → to nowe
     uruchomienie. Przejdź do punktu 3.

   Limit wynika z obserwacji: przejście przez cały harness trwa długo,
   a resetowanie kontekstu w trakcie jednego przebiegu jest częste — limit
   krótszy niż 4 godziny rozbijał jeden przebieg na kilka sesji. Wartość jest
   tymczasowa: gdy orkiestrator zacznie działać na większym kontekście, czas
   zostanie wydłużony.
3. **Zleć Etap 0 agentowi** (`stage.start` do `etap0`, patrz `.claude/agents/etap0.md`).
   Orkiestrator nie przeszukuje katalogów sam.
4. **Odbierz raport JSON** i zinterpretuj go (patrz "Interpretacja raportu").
   Zapisz raport w katalogu wynikowym jako `etap0-raport.json`.
5. **Zapisz stan sesji, potem wyczyść kontekst.** Kolejność jest krytyczna:
   - **najpierw** orkiestrator zapisuje `refactor-session.md` oraz wpis
     w `orkiestrator-log.md` — że raport Etapu 0 został wczytany i że kontekst
     jest czyszczony, wraz ze znacznikiem czasu;
   - **dopiero potem** następuje wyczyszczenie kontekstu (`/clear`).

   Zapis przed czyszczeniem jest jedynym zabezpieczeniem przed zapętleniem:
   po `/clear` orkiestrator nie pamięta, że Etap 0 już był — dowiaduje się tego
   wyłącznie z tego pliku.

   Orkiestrator **nie prosi użytkownika o ręczne wyczyszczenie kontekstu**
   i nie czeka na nie — czyszczenie jest czynnością harnessu, nie użytkownika.
6. **Po odzyskaniu sterowania** (po `/clear`):
   wczytaj `refactor-session.md` i `etap0-raport.json`, porównaj znaczniki
   czasu (reguła 4 godzin z punktu 2) i dopiero wtedy przejdź do Pytań 0–2.

Jeśli Etap 0 **nie wykrył żadnej poprzedniej sesji**, postępowanie jest
**identyczne** — raport z pustymi tablicami przechodzi tę samą ścieżkę, łącznie
z zapisem stanu sesji i czyszczeniem kontekstu. Brak historii nie jest
przypadkiem szczególnym.

### Interpretacja raportu

Na podstawie `etap0-raport.json` orkiestrator rozstrzyga:

| Sytuacja w raporcie | Decyzja orkiestratora |
|---|---|
| Brak katalogu wynikowego | Nowa sesja: katalog `refactor-result1`, pełne Pytania 0–2 |
| Katalog jest, `konfiguracja.plik_istnieje: false` | Nowa sesja w katalogu o kolejnym numerze, pełne Pytania 0–2 |
| Konfiguracja jest i kompletna, wszystkie etapy `done` | Poprzedni refaktor domknięty → nowa sesja, katalog o kolejnym numerze |
| Konfiguracja jest, któryś etap `in_progress` / `aborted` | Zaproponuj użytkownikowi **wznowienie** od tego etapu; pokaż, co zostało zrobione, jakie requesty wiszą otwarte i jakie pozycje są nierozstrzygnięte |
| `requesty_otwarte` niepuste | Wypisz je użytkownikowi przed jakąkolwiek decyzją — to niedokończona wymiana z poprzedniej sesji |
| `anomalie` niepuste | Pokaż użytkownikowi; anomalie nie blokują startu, ale nie są przemilczane |

**Wznowienie nie jest automatyczne.** Orkiestrator przedstawia stan i pyta
użytkownika, czy wznawiamy przerwany przebieg, czy zaczynamy nowy. Przy
wznowieniu obowiązuje konfiguracja z `refactor-config.json` (Pytania 0–2 nie
są zadawane od nowa, ale są **pokazane użytkownikowi do potwierdzenia**).

**Wznowienie nie tworzy nowego katalogu.** Przebieg kontynuuje w katalogu
wznawianej sesji; numer katalogu rośnie wyłącznie przy nowej sesji (patrz
"Katalog wynikowy"). Dzięki temu stan jednej sesji zostaje w jednym miejscu.

### Plik stanu sesji (`refactor-session.md`)

Celowo bardzo krótki — jest czytany przed Etapem 0, więc nie może być kosztowny
w kontekście. Zapisuje go wyłącznie orkiestrator.

Szablon pliku — `orchestrator-examples/stan-sesji-harnessu.md`.

Pole "Kontekst wyczyszczony" przyjmuje wyłącznie `tak (automatycznie)`.

Pole "Quality gate Step 1" ma postać `<passed|failed> (iteracja N, próba K)`
i dotyczy ostatniego uruchomienia bramy. Pole "Ponowienia kroku" jest
**licznikiem per para (krok, iteracja)** — `<krok> / iteracja N — zużyte (1 z 1)`
albo `<krok> / iteracja N — dostępne (0 z 1)`; orkiestrator czyta je przed
decyzją o ponowieniu (patrz "Bramy kroków (Etap 1)"). Gdy iteracja zamyka się
`passed`, wiersz ponowienia zostaje — jest dowodem, że limit dla tej pary już
się wyczerpał. Dopóki żaden krok nie wystartował, oba pola mają wartość `—`.

Cztery ostatnie pola są **punktem wznowienia** i aktualizuje je wyłącznie
orkiestrator, po każdej zamkniętej jednostce sterowania (krok albo etap) —
patrz "Iteracje i wznawianie". Pole "Iteracja" ma postać
`<biezaca> z <zaplanowanych>`; liczba zaplanowanych pochodzi z wiadomości
Step 1. Dopóki żaden krok nie wystartował, pola mają wartość `—`.

---

## Bramy etapów (kontrola wykonania)

Orkiestrator otwiera i zamyka każdy etap. Etap nie startuje z własnej inicjatywy
i nie ogłasza sam, że skończył — deklaruje `stage.done`, a orkiestrator to
weryfikuje.

### Brama wejściowa — przed `stage.start`

**Wyjątek — Etap 0.** Etap 0 wykonuje się przed konfiguracją wstępną, więc
brama wejściowa go nie dotyczy. Jego jedynym warunkiem uruchomienia jest reguła
4 godzin z sekcji "Etap 0 i wznowienie sesji".

Sprawdzane dla każdego pozostałego etapu:

0. Etap 0 został wykonany w bieżącym przebiegu (istnieje `refactor-session.md`
   z aktualnym wpisem i `etap0-raport.json`). Bez rozpoznania stanu żaden etap
   nie startuje — inaczej harness mógłby nadpisać wynik poprzedniej sesji.
1. Konfiguracja wstępna jest kompletna — wszystkie pozycje Pytań 0–2 mają
   jawny wybór użytkownika, żadna nie jest pusta ani domyślna po cichu.
2. `refactor-config.json` istnieje i jest poprawnym JSON-em.
3. Etap nie jest pominięty decyzją z Pytania 2.
4. Poprzedni etap w kolejce zakończył się `stage.done` **i** jego wynik został
   jawnie zaakceptowany przez użytkownika (dla Etapu 2 to opisana w `.claude/agents/etap2.md`
   brama wejściowa; Etap 1 nie ma poprzednika).
5. Plik etapu istnieje i nie jest pusty (dotyczy m.in. Etapu 3, który jest na
   razie pusty — próba jego uruchomienia kończy się `error.critical`, nie cichym
   pominięciem).

Niespełniony którykolwiek warunek → etap **nie startuje**. Orkiestrator zgłasza
użytkownikowi, który warunek jest niespełniony, i czeka.

### Brama wyjściowa — po `stage.done`

Sprawdzane po deklaracji zakończenia etapu:

1. Powstał plik wynikowy w formacie wymaganym przez ten etap i zgodnym
   z wyborem z Pytania 1 (Opcja A / Opcja B).
2. Log etapu istnieje, jest niepusty i chronologiczny.
3. Wszystkie requesty wystawione przez ten etap mają domkniętą odpowiedź —
   żaden nie wisi bez `response`.
4. Nie ma nierozstrzygniętych pozycji oznaczonych jako blokujące (np.
   nierozpoznane magic numbers, na które etap czekał — patrz `.claude/agents/etap2.md`,
   Krok 2). Pozycje otwarte niewymagające rozstrzygnięcia są dopuszczalne, ale
   muszą być wypisane w pliku wynikowym.

Niespełniony warunek → orkiestrator **nie zamyka etapu**: odsyła
`stage.resume` z listą braków albo, jeśli braku nie da się uzupełnić bez
decyzji użytkownika, zgłasza to użytkownikowi. Etap nie zostaje uznany za
zakończony, dopóki brama wyjściowa nie przejdzie.

### Bramy kroków (Etap 1)

Kroki Etapu 1 przechodzą przez ten sam mechanizm co etapy, w wersji skróconej.
Orkiestrator sprawdza je sam, na podstawie wiadomości i plików na dysku — krok
nigdy nie ocenia sam siebie.

**Brama wejściowa kroku — przed `step.start`:**

1. Brama wejściowa Etapu 1 przeszła (warunki 0–5 wyżej).
2. Plik kroku istnieje i nie jest pusty (`.claude/agents/etap1/step1.md`, `.claude/agents/etap1/step2.md`).
3. Dla Step 2 dodatkowo: istnieje wiadomość `step.done` od Step 1 dla **tej
   samej iteracji**, ma `status: "done"`, a wszystkie pliki wymienione
   w `payload.pliki` istnieją na dysku pod podanymi ścieżkami.
4. Dla Step 2 dodatkowo: quality gate Step 1 dla **tej samej iteracji**
   zakończył się wynikiem `passed` — plik
   `<katalog wynikowy>/quality-gate-step1-analize-result/iteracja-N/podsumowanie.json`
   istnieje i ma `status: "passed"`. Akceptacja analizy przez użytkownika nie
   jest już warunkiem — zastąpiła ją brama.

**Brama wyjściowa kroku — po `step.done`:**

1. Wiadomość ma komplet pól wymaganych dla danego kroku (patrz "Kroki Etapu 1
   jako jednostki sterowania").
2. Log kroku (`step1-log.md` / `step2-log.md`) istnieje, jest niepusty
   i zawiera wpis dla bieżącej iteracji.
3. Zadeklarowany wynik quality gate kroku jest w wiadomości obecny — z wartością
   `passed`, `failed` albo `nie_wykonany` (ta ostatnia dopuszczalna tylko tam,
   gdzie brama kroku jest oznaczona *w budowie*). Dla Step 1 wartością
   deklarowaną przez krok jest **zawsze** `nie_wykonany` — o wyniku rozstrzyga
   punkt 5, nie krok.
4. Licznik iteracji w wiadomości zgadza się z tym, co orkiestrator trzyma
   w `refactor-session.md`.
5. **Dla Step 1: quality gate przeszedł** — patrz niżej.

**Quality gate Step 1 — skrypty uruchamiane przez orkiestratora**

Po odebraniu `step.done` od `etap1.step1` orkiestrator uruchamia skrypty
z `scripts/step1/` (PowerShell). Krok nie uruchamia ich sam i nie zna ich
wyniku — brama jest po stronie orkiestratora, żeby krok nie oceniał sam siebie.
Co sprawdzają — patrz „Quality gate Step 1" w `.claude/agents/etap1/step1.md`.

```powershell
.\scripts\step1\00-brama.ps1 -KatalogWynikowy <katalog wynikowy> -Iteracja <N> -Proba <1|2>
```

Skrypty zapisują wyniki w
`<katalog wynikowy>/quality-gate-step1-analize-result/iteracja-N/` (plik na
sprawdzenie + `podsumowanie.json`). Katalog jest numerowany per iteracja —
po jego zawartości orkiestrator poznaje, które iteracje przeszły bramę.
Wynik bramy i numer próby orkiestrator odnotowuje w swoim logu
i w `refactor-session.md`; do wiadomości `step.start` dla Step 2 wchodzi jako
`payload.quality_gate_step1`.

**Ścieżka błędu — jedno ponowienie na parę (krok, iteracja):**

1. `podsumowanie.json` ma `status: "passed"` → orkiestrator może uruchomić
   Step 2.
2. `failed` → orkiestrator sprawdza najpierw w `refactor-session.md` polu
   „Ponowienia kroku", czy ponowienie dla **tej pary (krok, iteracja)** jest
   już zużyte.
   - **Nie jest zużyte (próba 1):**
     a. uruchamia skrypt czyszczący (eraser) dla tej iteracji — patrz niżej;
     b. odnotowuje w logu i w `refactor-session.md`, że ponowienie dla pary
        (`etap1.step1`, iteracja N) zostało zużyte;
     c. wysyła `step.start` do `etap1.step1` z **tym samym** numerem iteracji,
        a po odebraniu `step.done` uruchamia bramę z `-Proba 2`. Step 2 nie
        startuje.
   - **Jest już zużyte (próba 2):** → punkt 3.
3. `failed` przy zużytym ponowieniu → **przerwanie procesu** i notyfikacja
   użytkownika (`requires_user_ack: true`) z listą niezaliczonych sprawdzeń
   z `podsumowanie.json`. Orkiestrator nie ponawia po raz trzeci i nie
   naprawia plików samodzielnie.

**Licznik ponowień jest per krok i iteracja, nie per przebieg.** Zużyte
ponowienie iteracji 2 nie odbiera ponowienia iteracji 3 ani ponowienia Step 2.
Jedynym źródłem prawdy jest zapis w `refactor-session.md` (pole „Ponowienia
kroku") — `podsumowanie.json` zostaje wyczyszczone przez eraser, więc nie
nadaje się na licznik.

**Skrypt czyszczący (eraser).** Przed każdym ponowieniem Step 1 orkiestrator
kasuje wynik bramy z nieudanej próby, żeby próba 2 nie oceniała artefaktów
próby 1:

```powershell
.\scripts\step1\eraser\00-eraser.ps1 -KatalogWynikowy <katalog wynikowy> -Iteracja <N> -Powod "quality gate failed, proba 1"
```

Skrypt usuwa komplet plików bramy tej iteracji (`01`–`04`,
`podsumowanie.json`) razem z katalogiem
`quality-gate-step1-analize-result/iteracja-N/`. Plików Step 1
(`step1-analiza-N.md`, `step1-zmiany-N.json`, `step1-step-done-N.json`, wpis
w logu kroku) **nie rusza** — nadpisuje je ponowiony krok.

Kody wyjścia erasera: `0` = wyczyszczone (albo nie było czego czyścić),
`1` = czyszczenie nieudane, `2` = błąd wywołania (brak katalogu wynikowego).
Kod `1` albo `2` = **brak ponowienia**: orkiestrator przerywa przebieg
i powiadamia użytkownika, bo nie ma pewności, na czyich plikach orzekłaby
brama.

Brama kroku, która nie przechodzi, **nie zamyka kroku** — obowiązuje ta sama
zasada co przy etapie. Ścieżka błędu bramy Step 2 jest nadal *w budowie*
(patrz `.claude/agents/etap1/step2.md`).

### Zasada nieprzeskakiwania

Kolejność etapów wynika z kolejki ustalonej w Pytaniu 2 i nie podlega
samodzielnej zmianie przez etap ani przez orkiestratora. Jedyny dopuszczalny
"skok" to routing zadaniowy: chwilowe wywołanie Etapu 1 w trybie
`task.execute` na zlecenie innego etapu, po którym sterowanie **zawsze** wraca
do etapu-zleceniodawcy w punkcie `resume_point`. Nie jest to przejście etapu
i nie zamyka etapu zleceniodawcy.

---

## Kroki Etapu 1 jako jednostki sterowania

Etap 1 jest podzielony na dwa kroki wykonywane przez **osobnych agentów, na
różnych modelach**:

| | Step 1 | Step 2 |
|---|---|---|
| Adres w protokole | `etap1.step1` | `etap1.step2` |
| Model | opus | sonnet |
| Zadanie | analiza, przygotowanie listy zmian | implementacja tych zmian |
| Plik | `.claude/agents/etap1/step1.md` | `.claude/agents/etap1/step2.md` |

### Izolacja

Kroki **nie uruchamiają się nawzajem i nie wiedzą o sobie nic** poza wynikiem
pracy tego drugiego, przekazanym przez orkiestratora. Step 1 nie wie, kto
wykona jego listę zmian; Step 2 nie wie, jak ta lista powstała. Każdy zna
swoje zadanie, swój payload i swój log.

Konsekwencje, które są tu celem, a nie efektem ubocznym:

- decyzję o uruchomieniu kolejnego kroku podejmuje **wyłącznie orkiestrator** —
  krok może ją co najwyżej zaproponować w polu `nastepny`;
- krok nie musi znać przebiegu jako całości, więc może zajmować się wyłącznie
  swoją robotą.

### Przekazanie Step 1 → Step 2

1. Step 1 kończy analizę i **wysyła do orkiestratora `step.done`**. Wiadomość
   niesie: że faza analizy się zakończyła, jaki jest wynik quality gate kroku,
   **gdzie leżą pliki ze zmianami, jak się nazywają i w jakiej kolejności mają
   być implementowane**, oraz licznik iteracji. Wysłanie tej wiadomości jest
   **końcem pracy agenta Step 1** — agent nie czeka i nie robi nic więcej.
2. Orkiestrator sprawdza bramę wyjściową kroku, **uruchamia skrypty quality
   gate Step 1** (`scripts/step1/`), odnotowuje wszystko w logu
   i w `refactor-session.md`, po czym **decyduje**, czy uruchomić Step 2.
   Wynik `failed` → eraser + jedno ponowienie Step 1 tej samej iteracji; drugi
   `failed` → przerwanie i notyfikacja użytkownika (patrz „Bramy kroków
   (Etap 1)").
3. Jeśli tak — wysyła `step.start` do `etap1.step2` z **tym samym payloadem**,
   uzupełnionym o `config`. To rozpoczyna pracę agenta kodującego.
4. Step 2 wykonuje zmiany i odsyła własne `step.done`: czy skończył i czy
   przeszedł quality gate (build + testy).
5. Orkiestrator sprawdza bramę wyjściową kroku i rozstrzyga, co dalej: kolejna
   iteracja (`step.start` do `etap1.step1`) albo zamknięcie Etapu 1
   (`stage.done`).

Payload nie jest przez orkiestratora przepisywany ani interpretowany
merytorycznie — jest przekazywany dalej w całości. Orkiestrator czyta z niego
tylko to, czego potrzebuje do sterowania: licznik iteracji, listę plików
i wynik bramy.

### Iteracje i wznawianie

**Step 1 deklaruje liczbę iteracji.** W wiadomości `step.done` podaje pole
`iteracje` z liczbą przewidzianych przebiegów cyklu Step 1 → Step 2 dla
wskazanego zakresu oraz numerem iteracji bieżącej. Deklaracja jest szacunkiem —
przy kolejnej iteracji Step 1 może ją skorygować, podając nową wartość
`zaplanowane`; orkiestrator przyjmuje wartość z najnowszej wiadomości
i odnotowuje korektę w logu.

**Licznik iteracji jest własnością orkiestratora.** Krok prowadzi własny log
i zapisuje w nim wszystko, co robi, ale to nie jest źródło stanu procesu:

- orkiestrator trzyma `iteracja biezaca / zaplanowane` oraz `etap w toku` i
  `krok w toku` w `refactor-session.md` i aktualizuje je po **każdej** zamkniętej
  jednostce sterowania;
- po przerwaniu przebiegu (utrata kontekstu, zamknięta sesja, przerwanie przez
  użytkownika) **wznawia wyłącznie orkiestrator** — z `refactor-session.md`
  i z ostatnich wiadomości w `komunikacja/`;
- **ani etap, ani krok nie wznawia się sam** i nie jest od tego. Agent kroku
  uruchomiony ponownie dostaje z payloadu numer iteracji, którą ma wykonać, i
  nie dedukuje go z własnego logu.

Happy path: iteracje idą po kolei, `1 → zaplanowane`. Powrót iteracji do Step 1
po nieudanym quality gate Step 2 jest *w budowie* (patrz `.claude/agents/etap1/step2.md`).

---

## Konfiguracja wstępna (wymagana przed uruchomieniem jakiegokolwiek etapu)

Konfigurację poprzedza **Etap 0** (rozpoznanie stanu) — dopiero jego raport
mówi, czy pytania zadajemy od nowa, czy wznawiamy przebieg z istniejącą
konfiguracją (patrz "Etap 0 i wznowienie sesji").

Orkiestrator nie może uruchomić żadnego etapu, dopóki ta konfiguracja nie
zostanie przeprowadzona z użytkownikiem. Konfiguracja to jeden przepływ pytań.
Żadne pytanie nie jest pomijane milcząco — każde wymaga jawnego wyboru
użytkownika, nawet jeśli dla części z nich dopuszczalna jest w praktyce tylko
jedna sensowna odpowiedź.

### Pytanie 0 — Wybory obowiązkowe + granulacja fragmentu

Poniższe wybory użytkownik musi podjąć zawsze, na starcie każdego uruchomienia
harnessu:

- Commitowanie: (musi wybrać) — brak commitów automatycznych, commit wykonuje
  wyłącznie użytkownik, ręcznie.
- **Build: (musi wybrać) — `automatyczny` (domyślny) / `reczny`.**
- **Uruchamianie testów: (musi wybrać) — `automatyczne` (domyślne) /
  `reczne`.**
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

**Build i testy — dlaczego domyślnie automatycznie.** Quality gate Step 2
Etapu 1 polega na zbudowaniu projektu i uruchomieniu testów (patrz
`.claude/agents/etap1/step2.md`). Poprzednia reguła — „brak buildów/kompilacji bez wyraźnej
prośby użytkownika" — czyniła tę bramę niewykonalną bez pytania przy każdej
iteracji, więc domyślne ustawienie zostaje odwrócone: harness buduje i
uruchamia testy sam, w zakresie potrzebnym bramom jakości.

Reguła obowiązująca w obu ustawieniach:

| Ustawienie | Kto wykonuje build / testy | Kto rozstrzyga quality gate |
|---|---|---|
| `automatyczny` / `automatyczne` (domyślnie) | krok wykonuje sam | krok — na podstawie faktycznego wyniku, wynik trafia do logu i do wiadomości |
| `reczny` / `reczne` | **użytkownik** | **użytkownik** — krok wystawia `user.input` z tym, co należy uruchomić, czeka na wynik i przepisuje go do wiadomości bez własnej oceny |

Obie pozycje są niezależne: build może być automatyczny, a testy ręczne.
Ustawienie `reczny` nie zwalnia z bramy — zmienia wyłącznie to, kto ją
wykonuje. Poza bramami jakości build i testy nadal nie są uruchamiane bez
potrzeby.

Oraz wybór granulacji fragmentu podlegającego jednej iteracji Etapu 1:
- Automatyczna — LLM sam ustala zakres fragmentu na podstawie analizy kodu.
- Tylko metoda.
- Klasa.
- Kontroler / moduł.
- Dynamiczna — zakres nie jest ustalany z góry; pytanie o zakres zmian musi
  paść w jednym określonym kroku/części Etapu 1, przed napisaniem testów
  (patrz krok 1 Fazy Analizy w `.claude/agents/etap1/step1.md`), na podstawie tego, co pokaże
  analiza.

### Pytanie 1 — Struktura plików wynikowych
- Opcja A: Osobny plik `.md` dla każdego etapu.
- Opcja B: Jeden zbiorczy plik `.md` na wszystkie etapy (rozbudowywany
  sekcjami w miarę postępu).
- Dodatkowo, niezależnie od wyboru A/B: czy oprócz logu decyzji ma powstawać
  osobny plik ze szczegółowym opisem zmian po każdej iteracji (Tak/Nie)?
  Domyślnie Nie — decyzja należy do użytkownika.

### Pytanie 2 — Zakres etapów
- Opcja A: Wykonujemy wszystkie etapy po kolei.
- Opcja B: Użytkownik pomija wybrane etapy (np. Etap 1 zbędny, bo fragment
  jest już pokryty unit testami) — użytkownik wskazuje, które etapy
  pomijamy i orkiestrator to respektuje (nie dispatchuje pominiętych etapów).

Pytanie dotyczy wyłącznie Etapów 1–3. **Etap 0 nie podlega pominięciu** — jest
wykonywany przed tym pytaniem i warunkuje samo jego zadanie.

### Plik konfiguracji (`refactor-config.json`)

Po przejściu Pytań 0–2 orkiestrator zapisuje wynik konfiguracji do **jednego
pliku JSON**, tworzonego w katalogu wynikowym obok plików etapów. Plik jest
jednocześnie zapisem decyzji użytkownika (każda pozycja ma `zrodlo`) i punktem
odniesienia przy każdej kolejnej iteracji, kroku i etapie tego samego
refaktoru.

Zasady:

1. **Jeden format dla wszystkich.** Każdy etap i każdy krok czyta ten sam plik
   tak samo. Nie ma drugiego miejsca, z którego wolno brać konfigurację.
2. **Rozszerzalność.** Kolejne ustalenia dokładane są jako nowe pola/obiekty;
   nieznane pole nie jest błędem — czytający ignoruje to, czego nie zna.
   `schema_version` rośnie przy zmianie znaczenia istniejących pól.
3. **`zrodlo` przy pozycji** mówi, skąd wzięła się wartość: `uzytkownik`,
   `flaga`, `wykryte+potwierdzone`, `domyslne`. Pozycja z Pytań 0–2 nie może
   mieć `zrodlo: "domyslne"` — każda wymaga jawnego wyboru użytkownika,
   nawet gdy wartość domyślna jest oczywista.
4. **Stałe harnessu** (format znacznika czasu, katalog wynikowy) siedzą
   w `harness` — nie są pytaniem do użytkownika, ale są czytane razem z resztą.

Przykładowa zawartość (komplet pól z wartościami dopuszczalnymi) —
`orchestrator-examples/refactor-config.md`; ten sam komplet leży
w `refactor-config.example.json`.

Wartości dopuszczalne: `tryb.wartosc` — `normalny` (jedyna wartość);
`pytanie_0.build.wartosc` — `automatyczny` / `reczny`;
`pytanie_0.testy.wartosc` — `automatyczne` / `reczne`;
`pytanie_0.granulacja.wartosc` — `automatyczna` / `metoda` / `klasa` /
`kontroler-modul` / `dynamiczna`; `pytanie_1.struktura_plikow.wartosc` —
`A` / `B`; `pytanie_2.zakres_etapow.wartosc` — `A` / `B` (przy `B` lista
`pominiete`, np. `["etap1"]`).

Obiekt `harness` nie jest pytaniem do użytkownika — to stałe przebiegu
zapisywane w pliku po to, żeby etapy i kroki wczytywały je razem z resztą
konfiguracji i stosowały bez wyjątku (patrz "Znaczniki czasu w logach"
i "Katalog wynikowy").

**Pozycja `tryb`.** Harness ma jeden tryb pracy — `normalny` — i taka wartość
jest zapisywana w `tryb.wartosc` (`zrodlo: "domyslne"`). Użytkownik nie jest
o tryb pytany. Pole zostaje mimo jednej dopuszczalnej wartości z dwóch powodów:
jest jawnym oznaczeniem, w jakim trybie powstał przebieg (bez niego nie da się
odróżnić przebiegu od przebiegu z wcześniejszej wersji harnessu), i jest
miejscem na kolejne tryby pracy, gdyby się pojawiły. Tryb trafia do
`payload.config` jako `"tryb": "normalny"` i do raportu Etapu 0 jako pole
`tryb`.

### Katalog wynikowy

Wszystkie pliki powstałe w trakcie działania harnessu (plan/plany, logi
decyzji, opcjonalne pliki szczegółowe per iteracja, komunikaty protokołu,
wyniki bram w `quality-gate-step1-analize-result/iteracja-N/`)
zapisywane są w katalogu wynikowym utworzonym wewnątrz katalogu **projektu
będącego przedmiotem refaktoryzacji** (nie w katalogu samego harnessu).

**Nazwa katalogu:** `refactor-resultN` — np. `refactor-result1`,
`refactor-result2`.

`N` to numer kolejnego uruchomienia, liczony od 1. Zasady:

1. **Numer to największy znaleziony + 1**, a nie liczba katalogów. Usunięcie
   `refactor-result2` nie powoduje ponownego użycia numeru 2.
2. **Liczy się wyłącznie wzorzec `refactor-resultN`.** Katalog o innej nazwie
   (np. pozostały po wcześniejszej wersji harnessu) jest pomijany i nigdy nie
   zostanie rozpoznany jako sesja tego przebiegu.
3. **Istniejący katalog nigdy nie jest nadpisywany.**
4. **Nowy numer powstaje tylko przy nowej sesji.** Jeśli Etap 0 wykrył
   poprzednią sesję i użytkownik wybrał wznowienie, przebieg **kontynuuje
   w katalogu wznawianej sesji**, bez inkrementacji. Numer rośnie wyłącznie
   wtedy, gdy zaczynamy nową sesję — Etap 0 nie znalazł poprzedniej albo
   użytkownik świadomie zaczyna od nowa.

Kolejność jest zatem taka: **Etap 0 (rozpoznanie katalogów) → decyzja "nowa
sesja czy wznowienie" → dopiero wtedy ustalenie numeru katalogu**. Zestaw istniejących numerów jest jednocześnie historią prób
uruchomienia harnessu na tym projekcie.

**Wyjątek — pliki Etapu 0.** Etap 0 wykonuje się, zanim wiadomo, czy powstanie
katalog o nowym numerze. Dlatego `etap0-raport.json` i `refactor-session.md`
zapisywane są zawsze w **najnowszym istniejącym** katalogu; jeśli nie istnieje
żaden, orkiestrator tworzy `refactor-result1` na tę potrzebę. Gdy interpretacja raportu prowadzi do
decyzji o nowej sesji w katalogu o kolejnym numerze, oba pliki są do niego
kopiowane jako punkt startowy — oryginały zostają nietknięte.

---

## Konfiguracja w trakcie przebiegu

**Konfiguracja żyje wyłącznie na dysku.** Orkiestrator nie trzyma jej
w pamięci i nie porównuje niczego z zapamiętanym stanem — obowiązuje to, co
w danym momencie stoi w `refactor-config.json`.

**Odczyt przy każdej wiadomości.** Przed wysłaniem `stage.start`, `step.start`,
`task.execute` i `stage.resume` orkiestrator wczytuje `refactor-config.json`
z dysku i wkłada jego zawartość w `payload.config`. Forma przekazania nie
zmienia się — zmienia się to, że zawartość pochodzi z każdorazowego odczytu,
a nie z pamięci.

**Przypominajka.** Etapy i kroki też nie muszą trzymać konfiguracji w pamięci
między wywołaniami ani między iteracjami — przed każdą iteracją wczytują
`refactor-config.json` na nowo z dysku. To realizuje zasadę stałego odświeżania
kontekstu: zapobiega odejściu od reguł ustalonych na starcie (granulacja,
framework testowy, zasada braku zmian bez planu, struktura plików wynikowych)
w miarę postępu pracy, niezależnie od długości sesji.

**Zmiana pliku w trakcie przebiegu** obowiązuje od najbliższego odczytu — czyli
od następnej wiadomości do etapu albo kroku. Wykrywanie zmian konfiguracji
w trakcie przebiegu — *w budowie*.

---

## Protokół komunikacji orkiestrator ↔ etapy i kroki

Etapy nie zwracają już samego "sukces / porażka". Każde zakończenie etapu,
każde przerwanie i każda potrzeba działania po stronie innego etapu jest
**wiadomością w formacie JSON**, niosącą komplet informacji potrzebny
odbiorcy do wykonania zadania bez dopytywania.

### Koperta wiadomości (wspólna dla wszystkich typów)

Komplet pól koperty — `orchestrator-examples/koperta-wiadomosci.md`.

- `msg_id` — unikalny identyfikator wiadomości.
- `corr_id` — `msg_id` wiadomości, na którą ta odpowiada (`null` dla nowej).
- `from` / `to` — adresem jest `orkiestrator`, `etap0`–`etap3` albo **krok**:
  `etap1.step1`, `etap1.step2`. Krok nigdy nie adresuje drugiego kroku —
  w polu `to` kroku zawsze stoi `orkiestrator`.
- `requires_user_ack` — czy przed wykonaniem trzeba pokazać coś użytkownikowi.
- `user_message` — dokładna treść do pokazania użytkownikowi; nie może być
  pusta, gdy `requires_user_ack` jest `true`.

### Katalog akcji

**Etap → orkiestrator (`type: "request"` / `"event"`):**

| `action` | Znaczenie |
|---|---|
| `test.update` | Istniejący test wymaga aktualizacji (np. po zmianie nazwy) |
| `test.add` | Trzeba dopisać nowy test |
| `test.remove` | Test stał się zbędny |
| `test.mock.enable` | W projekcie testowym trzeba włączyć obsługę mocków (nie była wcześniej włączona) |
| `test.mock.add` | Dla przeniesionej zależności trzeba dodać mock/stub w testach |
| `user.input` | Potrzebna informacja od użytkownika (np. znaczenie magic numbera, wybór frameworka mocków) |
| `user.approval` | Plan gotowy, czeka na akceptację |
| `stage.done` | Etap zakończony |
| `step.done` | **Krok zakończony** — jedyny sposób, w jaki krok kończy pracę (patrz niżej) |
| `stage.aborted` | Użytkownik przerwał iterację/etap |
| `error.critical` | Sytuacja blokująca dalsze działanie |

**Orkiestrator → etap (`type: "dispatch"`):**

| `action` | Znaczenie |
|---|---|
| `stage.start` | Uruchom etap; `payload.config` = konfiguracja wstępna (razem z `tryb`) |
| `step.start` | **Uruchom krok**; `payload` = payload z `step.done` poprzedniego kroku + `config` |
| `task.execute` | Wykonaj pojedyncze zadanie zlecone przez inny etap |
| `stage.resume` | Wznów przerwany etap w punkcie `corr_id` |
| `stage.abort` | Zakończ etap (decyzja użytkownika lub critical error) |

**Etap → orkiestrator (`type: "response"`):** `status` = `done` / `failed` /
`needs_user`, w `payload.result` — co faktycznie zrobiono.

### Przykład: Etap 2 zleca zmianę testu Etapowi 1

Request z Etapu 2 (`test.update`) i dispatch orkiestratora do Etapu 1
(`task.execute`) — `orchestrator-examples/etap2-zleca-zmiane-testu.md`.

Po `response` ze statusem `done` orkiestrator wysyła do Etapu 2
`stage.resume` z `corr_id: "e2-k1-007"` i wskazaniem `resume_point`.

### Przekazanie między krokami Etapu 1

Trzy wiadomości domykają jedną iterację. Wszystkie idą przez orkiestratora —
Step 1 i Step 2 nie wymieniają się niczym bezpośrednio.

**1. Step 1 → orkiestrator (`step.done`)** — koniec pracy agenta analizującego.
Request jest zapisywany jako `step1-step-done-N.json` w katalogu wynikowym,
obok pozostałych plików Step 1 (kopia idzie do `komunikacja/` jak każda inna
wiadomość).

Pola obowiązkowe dla `step.done` ze Step 1: `iteracje.biezaca`,
`iteracje.zaplanowane`, `quality_gate.status`, `liczba_zmian`,
`pliki[]` (z `nazwa` i `sciezka`) oraz `kolejnosc_implementacji`. Bez nich
brama wyjściowa kroku nie przechodzi. Pole `nastepny` jest **propozycją** —
uruchomienie i tak rozstrzyga orkiestrator.

**2. Orkiestrator → Step 2 (`step.start`)** — ten sam payload, uzupełniony
o konfigurację (`payload.config` + `payload.wejscie`).

**3. Step 2 → orkiestrator (`step.done`)** — raport agenta kodującego.

Przykłady wszystkich trzech wiadomości —
`orchestrator-examples/przekazanie-miedzy-krokami-etapu-1.md`.

Pola obowiązkowe dla `step.done` ze Step 2: `ukonczono`, `iteracje`,
`quality_gate.status` oraz — dla każdej pozycji bramy — `wynik` i `wykonal`
(`krok` przy ustawieniu automatycznym, `uzytkownik` przy ręcznym, patrz
Pytanie 0). Po tej wiadomości orkiestrator albo startuje kolejną iterację
(`step.start` do `etap1.step1` z `iteracje.biezaca: 3`), albo — gdy
`biezaca == zaplanowane` — domyka Etap 1.

### Zapis wiadomości

Każda wiadomość zapisywana jest jako osobny plik w podkatalogu `komunikacja/`
katalogu wynikowego, w formacie
`<NNN>-<from>-<action>.json` (numeracja chronologiczna; dla kroków `from` to
`etap1.step1` / `etap1.step2`, np. `014-etap1.step1-step.done.json`). Daje to
pełny audyt przepływu, niezależny od logów decyzji — i jest to zapis, z którego
orkiestrator odtwarza stan przy wznowieniu.

---

## Pętla sterowania orkiestratora

1. **Rozpoznanie stanu.** Wczytaj `refactor-session.md`; jeśli reguła 4 godzin
   nie zwalnia z Etapu 0 — zleć Etap 0 agentowi, odbierz raport JSON, zapisz
   `etap0-raport.json` i `refactor-session.md`, odnotuj to w logu i dopiero
   **potem** wyczyść kontekst (`/clear`). Po
   odzyskaniu sterowania zinterpretuj raport i ustal z użytkownikiem: nowa
   sesja czy wznowienie (patrz "Etap 0 i wznowienie sesji"). Ustal katalog
   wynikowy przebiegu (patrz "Katalog wynikowy").
2. Przeprowadź konfigurację wstępną (Pytania 0–2), zapisz
   `refactor-config.json` (razem z pozycją `tryb`, ustawieniami build/testy
   i formatem znacznika czasu). Przy wznowieniu: pokaż istniejącą konfigurację do
   potwierdzenia zamiast pytać od nowa.
3. Ustal kolejkę etapów na podstawie Pytania 2 (z pominięciami). Przy
   wznowieniu kolejka zaczyna się od etapu wskazanego w raporcie Etapu 0.
4. Dla kolejnego etapu z kolejki: sprawdź **bramę wejściową**. Gdy przechodzi —
   wczytaj plik etapu i wyślij `stage.start` z `payload.config`.
   Gdy brama nie przechodzi — zgłoś użytkownikowi niespełniony warunek i czekaj.

   **Dla Etapu 1 etap nie jest jedną jednostką — prowadź pętlę kroków (4a–4d):**

   4a. Sprawdź bramę wejściową kroku i wyślij `step.start` do `etap1.step1`
       (`.claude/agents/etap1/step1.md`), z `payload.config` i numerem iteracji do wykonania.
       Dla iteracji 1 numer to 1; dla kolejnych — `biezaca + 1` z ostatniej
       wiadomości. **Wyjątek:** wejście z 4b' (ponowienie po `failed`) idzie
       z **tym samym** numerem iteracji, bez inkrementacji.
   4b. Odbierz `step.done` od `etap1.step1`. Sprawdź bramę wyjściową kroku
       i **uruchom quality gate Step 1** — skrypty z `scripts/step1/` dla tej
       iteracji (`00-brama.ps1 -KatalogWynikowy … -Iteracja N -Proba 1`).
       Zapisz w `refactor-session.md` licznik iteracji (`biezaca`,
       `zaplanowane`), krok w toku, wynik bramy i numer próby; odnotuj w logu,
       gdzie leżą pliki ze zmianami i jaka jest kolejność implementacji.
   4b'. Gdy brama zwróciła `failed`: sprawdź w `refactor-session.md` polu
       „Ponowienia kroku", czy ponowienie dla pary (`etap1.step1`, iteracja N)
       jest zużyte.
       - **Dostępne** → uruchom eraser
         (`scripts\step1\eraser\00-eraser.ps1 -KatalogWynikowy … -Iteracja N`),
         zapisz w logu i w `refactor-session.md`, że ponowienie tej pary jest
         zużyte, i wróć do 4a z **tym samym** numerem iteracji (`-Proba 2`
         przy kolejnym sprawdzeniu). Eraser zakończony kodem `1` lub `2` →
         bez ponowienia, przerwij przebieg i powiadom użytkownika.
       - **Zużyte** → przerwij przebieg i powiadom użytkownika
         (`requires_user_ack: true`) listą niezaliczonych sprawdzeń
         z `podsumowanie.json`.
   4c. Gdy brama zwróciła `passed` — zdecyduj o uruchomieniu Step 2, sprawdź
       bramę wejściową kroku i wyślij `step.start` do `etap1.step2`
       (`.claude/agents/etap1/step2.md`) z **tym samym payloadem** + `config`
       + `quality_gate_step1`.
   4d. Odbierz `step.done` od `etap1.step2`, sprawdź bramę wyjściową kroku,
       zaktualizuj `refactor-session.md`. Jeśli `biezaca < zaplanowane` → wróć
       do 4a z kolejnym numerem iteracji. Jeśli `biezaca == zaplanowane` →
       przejdź do punktu 6 (brama wyjściowa Etapu 1). Ścieżka nieudanego
       quality gate Step 2 — *w budowie*, patrz `.claude/agents/etap1/step2.md`.
5. **Czuwaj.** W trakcie działania etapu przyjmuj przychodzące wiadomości:
   - `user.approval` / `user.input` → przekaż `user_message` użytkownikowi,
     poczekaj na odpowiedź, odeślij ją do etapu.
   - `test.update` / `test.add` / `test.remove` / `test.mock.enable` /
     `test.mock.add` → jeśli `requires_user_ack: true`, najpierw pokaż
     `user_message` użytkownikowi (transparentność), potem wyślij
     `task.execute` do Etapu 1; po jego `response` wyślij `stage.resume` do
     etapu-zleceniodawcy. Wszystkie te akcje trafiają wyłącznie do Etapu 1 —
     to jedyny właściciel testów i ich obudowy (mocków).
   - `user.input` z kroku przy ustawieniu `reczny` (build/testy) → przekaż
     użytkownikowi, co ma uruchomić, odbierz wynik i odeślij go do kroku bez
     własnej oceny (patrz Pytanie 0).
   - `stage.aborted` → odnotuj w logu, zatrzymaj kolejkę, oddaj sterowanie
     użytkownikowi.
   - `error.critical` → przerwij działanie harnessu z komunikatem.
6. Po `stage.done`: sprawdź **bramę wyjściową**. Przechodzi → wróć do punktu 4
   dla następnego etapu. Braki → `stage.resume` z listą braków lub zgłoszenie
   użytkownikowi.
7. Po wyczerpaniu kolejki: podsumuj przebieg i zakończ.

### Log orkiestratora (`orkiestrator-log.md`)

Osobny plik, niezależny od logów etapów. Te same zasady co w logach etapów:
wyłącznie decyzje i zdarzenia sterujące, żadnego kodu ani diffów, wpisy
numerowane chronologicznie, **każdy wpis poprzedzony znacznikiem czasu**
w formacie `yyyy-MM-dd; HH-mm-ss` (patrz "Znaczniki czasu w logach").

Odnotowuje: **ustalony katalog wynikowy**,
start/koniec każdego etapu **i każdego kroku**, każdy routing requestu (kto →
co → do kogo → z jakim wynikiem), **wynik każdej bramy wejściowej i wyjściowej**
(przeszła / nie przeszła + który warunek), przerwania i critical errory.

Dla Etapu 1 log **musi** zawierać ponadto: numer iteracji przy każdym
uruchomieniu i zamknięciu kroku, **zadeklarowaną przez Step 1 liczbę iteracji**
(oraz każdą jej korektę), listę plików ze zmianami przekazanych do Step 2 wraz
z kolejnością implementacji, oraz wynik quality gate każdego kroku
z rozbiciem na build i testy i z informacją, kto je wykonał (krok czy
użytkownik). Dla bramy Step 1 (skrypty, bez builda i testów): wynik bramy,
**numer próby**, listę niezaliczonych sprawdzeń, każde uruchomienie erasera
(iteracja + jego kod wyjścia) oraz jawny wpis, **dla której pary (krok,
iteracja) ponowienie zostało zużyte** — ponowienia liczą się osobno dla każdej
pary, nie dla przebiegu.

Osobno, z racji roli w zabezpieczeniu przed zapętleniem, log **musi** zawierać:
zlecenie Etapu 0 i moment odebrania raportu, moment zapisu
`refactor-session.md`, moment wyczyszczenia kontekstu oraz wynik reguły
4 godzin przy kolejnym wejściu.

Przykłady wpisów (uruchomienie harnessu i Etap 0 oraz pętla kroków Etapu 1
z nieudaną bramą i ponowieniem) — `orchestrator-examples/log-orkiestratora.md`.

---

## Odłożone do kolejnych iteracji

- **Ścieżki inne niż happy path** — nieudany quality gate Step 2, powrót
  iteracji do Step 1, korekta liczby iteracji w dół po rozpoczęciu przebiegu.
  (Nieudana brama Step 1 jest już opisana: eraser + jedno ponowienie na parę
  krok/iteracja.)
