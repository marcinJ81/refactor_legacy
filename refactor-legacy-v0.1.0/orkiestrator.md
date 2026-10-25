---
name: refactor-legacy
description: Harness do bezpiecznej refaktoryzacji i wprowadzania zmian w kodzie legacy (np. .NET Framework 4.8.1, .NET MVC, jQuery). Używać zawsze gdy użytkownik prosi o refaktor, zmianę zachowania istniejącego kodu, wydzielenie metod/klas, dodanie testów do kodu bez pokrycia testami, lub redukcję couplingu. Orkiestrator prowadzi proces etapami, pilnuje poprawnego wykonania każdego etapu i wymaga jawnej akceptacji użytkownika między etapami - nie pomijać etapów, nawet jeśli zadanie wygląda na proste.
---
<!-- wersja-harnessu: 0.1.1 -->

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

Szkielet w budowie. Konfiguracja wstępna, protokół komunikacji i mechanizm
wznawiania sesji — opisane. Etap 0 — opisany. Etap 1 — opisany. Etap 2: wariant
"Refaktor" kroki 1–3 opisane, kolejne do zdefiniowania; wariant "Zmiana logiki"
— w budowie. Etap 3 — pusty, do zdefiniowania.


## Struktura harnessu (pliki)

| Plik | Rola |
|---|---|
| `orkiestrator.md` (ten plik) | Orkiestrator: rozpoznanie stanu, konfiguracja wstępna, protokół, pętla sterowania |
| `etap0.md` | Etap 0 — Rozpoznanie stanu (wznowienie sesji), wykonywany przez agenta |
| `etap1.md` | Etap 1 — Characterization + Seams |
| `references/etap1/feathers-technique-selection.md` | Etap 1 — wybór techniki rozrywania zależności (tabela objaw → technika, poziomy preferencji) |
| `references/etap1/feathers-dependency-breaking-csharp.md` | Etap 1 — katalog 21 technik Feathersa z przykładami w C# |
| `etap2.md` | Etap 2 — Wprowadzenie zmiany (Refaktor i/lub Zmiana logiki) |
| `etap3.md` | Etap 3 — Refaktoryzacja rezultatu Etapu 2 *(pusty, do zdefiniowania)* |
| `scripts/wspolne/wpis-logu.ps1` | Dopisanie wpisu do logu ze znacznikiem z zegara systemowego oraz znacznik dla pól JSON — jedyna droga zapisu do logów (patrz "Znaczniki czasu w logach") |
| `examples/orchestrator-examples/*.md` | Przykłady wyniesione z orkiestratora (szablony plików, JSON-y, logi) — jeden plik na przykład |
| `examples/etap0-examples/*.md` | Przykłady wyniesione z `etap0.md` |

Orkiestrator wczytuje plik etapu dopiero w momencie jego uruchomienia. Etapy
nie wywołują się nawzajem bezpośrednio — **każde przejście między etapami idzie
przez orkiestratora**.

---

## Rola orkiestratora

1. **Inicjuje cały proces.** Etap wstępny (zebranie wymagań, pytania
   konfiguracyjne) jest częścią orkiestratora, nie Etapu 1.
2. **Ustala stan wyjściowy przed konfiguracją.** Zanim padnie pierwsze pytanie
   konfiguracyjne, orkiestrator zleca **Etap 0** i na podstawie jego raportu
   rozstrzyga, czy to nowe uruchomienie, czy kontynuacja (patrz "Etap 0
   i wznowienie sesji").
3. **Przekazuje wynik konfiguracji do etapów** jako wsad początkowy.
4. **Czuwa w trakcie działania etapu.** Nie kończy pracy po odpaleniu etapu —
   pozostaje aktywny i reaguje na requesty przychodzące z etapu w dowolnym
   momencie jego trwania (praca asynchroniczna, wymiana dwukierunkowa).
5. **Pilnuje poprawnego wykonania etapów** — sprawdza bramę wejściową przed
   startem i bramę wyjściową po zakończeniu każdego etapu (patrz "Bramy
   etapów"). To główna funkcja harnessu: etap nie decyduje sam o tym, czy
   wolno mu wystartować i czy zrobił, co miał zrobić.
6. **Prowadzi log orkiestratora** — kto, kiedy, jaki request, do kogo
   skierowany, z jakim wynikiem. Każdy wpis poprzedzony znacznikiem czasu
   (patrz "Znaczniki czasu w logach").

Czego orkiestrator **nie** robi: nie analizuje kodu, nie pisze i nie zmienia
testów, nie proponuje seamów ani refaktoryzacji. Cała merytoryka należy do
etapów. Orkiestrator odpowiada wyłącznie za porządek, kompletność i przepływ.

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

1. Format jest zapisany w pliku konfiguracyjnym `refactor-decisions.md`
   i wczytywany przez etapy razem z resztą konfiguracji.
2. **Każdy etap na starcie zapisuje w swoim logu datę i godzinę uruchomienia**
   jako pierwszy wpis (`## Uruchomienie <yyyy-MM-dd; HH-mm-ss>`).
3. Każdy kolejny wpis logu zaczyna się od znacznika czasu, przed numerem
   i treścią wpisu:
   `2026-08-30; 19-07-12 — 4. Wypisano zależności blokujące testowalność.`
4. **Znacznik nadaje skrypt, nie model.** Model nie zna bieżącej godziny —
   znacznik wpisany z pamięci jest wymyślony i powielany. Każdy wpis do logu
   (nagłówek uruchomienia, nagłówek sekcji, wpis) dopisuje skrypt
   `scripts/wspolne/wpis-logu.ps1`, który bierze czas z zegara systemowego
   w chwili wywołania. Zapis do logu narzędziem Write/Edit jest zabroniony.
   Wpis dopisujesz od razu po decyzji / działaniu — znacznik = moment
   wywołania skryptu.
5. **Pola czasu w JSON** (`timestamp` w kopercie wiadomości, `generated_at`
   w raporcie Etapu 0) wypełniasz wartością z
   `scripts/wspolne/wpis-logu.ps1 -TylkoZnacznik`, wywołanego tuż przed
   zapisem pliku. Nie wpisujesz czasu sam.

Wywołania skryptu (ścieżki względem katalogu harnessu, log w katalogu
wynikowym):

```
pwsh -NoProfile -File scripts/wspolne/wpis-logu.ps1 -Plik <log> -Tytul "<tytuł logu>" -Naglowek uruchomienie
pwsh -NoProfile -File scripts/wspolne/wpis-logu.ps1 -Plik <log> -Naglowek iteracja -Iteracja <N>
pwsh -NoProfile -File scripts/wspolne/wpis-logu.ps1 -Plik <log> -Naglowek sekcja -Nazwa "<nazwa>"
pwsh -NoProfile -File scripts/wspolne/wpis-logu.ps1 -Plik <log> -Tresc "<nr>. <treść wpisu>"
pwsh -NoProfile -File scripts/wspolne/wpis-logu.ps1 -TylkoZnacznik
```

`-Tytul` działa tylko przy tworzeniu pliku (pierwsza linia `# <tytuł>`).
`-Naglowek sekcja` dopisuje `### <nazwa>` bez znacznika (np. `Krok 3 —
iteracja 2` w logu Etapu 2). Numer wpisu podaje model w `-Tresc`; skrypt
dokłada wyłącznie znacznik i separator ` — `.

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
3. **Zleć Etap 0 agentowi** (`stage.start` do `etap0`, patrz `etap0.md`).
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
wznowieniu konfiguracja jest wczytywana z `refactor-decisions.md` (Pytania 0–2 nie są zadawane od nowa, ale są **pokazane
użytkownikowi do potwierdzenia**).

**Wznowienie nie tworzy nowego katalogu.** Przebieg kontynuuje w katalogu
wznawianej sesji; numer katalogu rośnie wyłącznie przy nowej sesji (patrz
"Katalog wynikowy"). Dzięki temu stan jednej sesji zostaje w jednym miejscu.

### Plik stanu sesji (`refactor-session.md`)

Celowo bardzo krótki — jest czytany przed Etapem 0, więc nie może być kosztowny
w kontekście. Zapisuje go wyłącznie orkiestrator.

Przykład: `examples/orchestrator-examples/stan-sesji-harnessu.md`.

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
1. Konfiguracja wstępna jest kompletna — wszystkie pozycje Pytań 0–2 mają jawny wybór użytkownika, żadna nie jest pusta ani
   domyślna po cichu.
2. `refactor-decisions.md` istnieje.
3. Etap nie jest pominięty decyzją z Pytania 2.
4. Poprzedni etap w kolejce zakończył się `stage.done` **i** jego wynik został
   jawnie zaakceptowany przez użytkownika (dla Etapu 2 to opisana w `etap2.md`
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
   na każdy poszedł `stage.resume` z jego `msg_id` w `corr_id`.
4. Nie ma nierozstrzygniętych pozycji oznaczonych jako blokujące (np.
   nierozpoznane magic numbers, na które etap czekał — patrz `etap2.md`,
   Krok 2). Pozycje otwarte niewymagające rozstrzygnięcia są dopuszczalne, ale
   muszą być wypisane w pliku wynikowym.

Niespełniony warunek → orkiestrator **nie zamyka etapu**: odsyła
`stage.resume` z listą braków albo, jeśli braku nie da się uzupełnić bez
decyzji użytkownika, zgłasza to użytkownikowi. Etap nie zostaje uznany za
zakończony, dopóki brama wyjściowa nie przejdzie.

### Zasada nieprzeskakiwania

Kolejność etapów wynika z kolejki ustalonej w Pytaniu 2 i nie podlega
samodzielnej zmianie przez etap ani przez orkiestratora. Etapy nie zlecają
sobie nawzajem zadań.

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
  (patrz krok 1 Fazy Analizy w `etap1.md`), na podstawie tego, co pokaże
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

### Log decyzji

Po przejściu Pytań 0–2 orkiestrator zapisuje wynik konfiguracji jako
checklistę do osobnego pliku, tworzonego obok plików dotyczących etapów, np.
`refactor-decisions.md`. Plik ten pełni rolę logu decyzji użytkownika i jest
punktem odniesienia przy każdej kolejnej iteracji/etapie tego samego
refaktoru.

Przykład: `examples/orchestrator-examples/log-decyzji.md`.

Pozycja "Format znacznika czasu" nie jest pytaniem do użytkownika — to stała
harnessu zapisywana w pliku konfiguracyjnym po to, żeby etapy wczytywały ją
razem z resztą konfiguracji i stosowały bez wyjątku (patrz "Znaczniki czasu
w logach").

### Katalog wynikowy

Wszystkie pliki powstałe w trakcie działania harnessu (plan/plany, logi
decyzji, opcjonalne pliki szczegółowe per iteracja, komunikaty protokołu)
zapisywane są w katalogu wynikowym utworzonym wewnątrz katalogu **projektu
będącego przedmiotem refaktoryzacji** (nie w katalogu samego harnessu).

Nazwa katalogu: `refactor-resultN` (np. `refactor-result1`, `refactor-result2`).
`N` to numer kolejnego uruchomienia, liczony od 1. Zasady:

1. **Numer to największy znaleziony + 1**, a nie liczba katalogów. Usunięcie
   `refactor-result2` nie powoduje ponownego użycia numeru 2.
2. **Istniejący katalog nigdy nie jest nadpisywany.**
3. **Nowy numer powstaje tylko przy nowej sesji.** Jeśli Etap 0 wykrył
   poprzednią sesję i użytkownik wybrał wznowienie, przebieg **kontynuuje
   w katalogu wznawianej sesji**, bez inkrementacji. Numer rośnie wyłącznie
   wtedy, gdy zaczynamy nową sesję — Etap 0 nie znalazł poprzedniej albo
   użytkownik świadomie zaczyna od nowa.

Kolejność jest zatem taka: **Etap 0 (rozpoznanie katalogów) →
decyzja "nowa sesja czy wznowienie" → dopiero wtedy ustalenie numeru
katalogu**. Zestaw istniejących numerów jest jednocześnie historią prób
uruchomienia harnessu na tym projekcie.

**Wyjątek — pliki Etapu 0.** Etap 0 wykonuje się, zanim wiadomo, czy powstanie
katalog o nowym numerze. Dlatego `etap0-raport.json` i `refactor-session.md`
zapisywane są zawsze w **najnowszym istniejącym** katalogu wynikowym;
jeśli nie istnieje żaden, orkiestrator tworzy `refactor-result1` na tę potrzebę. Gdy interpretacja raportu prowadzi do
decyzji o nowej sesji w katalogu o kolejnym numerze, oba pliki są do niego
kopiowane jako punkt startowy — oryginały zostają nietknięte.


## Protokół komunikacji orkiestrator ↔ etapy

Etapy nie zwracają już samego "sukces / porażka". Każde zakończenie etapu,
każde przerwanie i każda potrzeba decyzji lub informacji od użytkownika jest
**wiadomością w formacie JSON**, niosącą komplet informacji potrzebny
odbiorcy bez dopytywania. Orkiestrator nie przekazuje etapom zadań zleconych
przez inne etapy.

### Koperta wiadomości (wspólna dla wszystkich typów)

Wzór koperty: `examples/orchestrator-examples/koperta-wiadomosci.md`.

- `msg_id` — unikalny identyfikator wiadomości.
- `corr_id` — `msg_id` wiadomości, na którą ta odpowiada (`null` dla nowej).
- `user_message` — dokładna treść do pokazania użytkownikowi; nie może być
  pusta dla `user.input`, `user.approval` i `stage.aborted`.

### Katalog akcji

**Etap → orkiestrator (`type: "request"` / `"event"`):**

| `action` | Znaczenie |
|---|---|
| `user.input` | Potrzebna informacja od użytkownika (np. znaczenie magic numbera, technika spoza tabeli Feathersa) |
| `user.approval` | Plan gotowy, czeka na akceptację |
| `stage.done` | Etap zakończony |
| `stage.aborted` | Użytkownik przerwał iterację/etap |
| `error.critical` | Sytuacja blokująca dalsze działanie |

**Orkiestrator → etap (`type: "dispatch"`):**

| `action` | Znaczenie |
|---|---|
| `stage.start` | Uruchom etap; `payload.config` = konfiguracja wstępna |
| `stage.resume` | Wznów etap po requeście `corr_id`; `payload.user_answer` = odpowiedź użytkownika |
| `stage.abort` | Zakończ etap (decyzja użytkownika lub critical error) |

Przykład `user.input` → `stage.resume`: `examples/orchestrator-examples/etap2-pyta-uzytkownika.md`.

### Zapis wiadomości

Każda wiadomość zapisywana jest jako osobny plik w podkatalogu `komunikacja/`
katalogu wynikowego, w formacie
`<NNN>-<from>-<action>.json` (numeracja chronologiczna). Daje to pełny audyt
przepływu, niezależny od logów decyzji.

---

## Pętla sterowania orkiestratora

1. **Rozpoznanie stanu.** Wczytaj `refactor-session.md`; jeśli reguła 4 godzin
   nie zwalnia z Etapu 0 — zleć Etap 0 agentowi, odbierz raport JSON, zapisz `etap0-raport.json`
   i `refactor-session.md`, odnotuj to w logu i dopiero **potem** wyczyść
   kontekst (`/clear`). Po odzyskaniu sterowania zinterpretuj raport i ustal z użytkownikiem: nowa
   sesja czy wznowienie (patrz "Etap 0 i wznowienie sesji"). Ustal katalog
   wynikowy przebiegu (patrz "Katalog wynikowy").
2. Przeprowadź konfigurację wstępną (Pytania 0–2), zapisz
   `refactor-decisions.md` (razem z formatem znacznika czasu), przy
   wznowieniu: pokaż istniejącą konfigurację do
   potwierdzenia zamiast pytać od nowa.
3. Ustal kolejkę etapów na podstawie Pytania 2 (z pominięciami). Przy
   wznowieniu kolejka zaczyna się od etapu wskazanego w raporcie Etapu 0.
4. Dla kolejnego etapu z kolejki: sprawdź **bramę wejściową**. Gdy przechodzi —
   wczytaj plik etapu (`etap1.md` / `etap2.md` / `etap3.md`) i wyślij
   `stage.start` z `payload.config`. Gdy brama nie
   przechodzi — zgłoś użytkownikowi niespełniony warunek i czekaj.
5. **Czuwaj.** W trakcie działania etapu przyjmuj przychodzące wiadomości:
   - `user.approval` / `user.input` → przekaż `user_message` użytkownikowi,
     poczekaj na odpowiedź, odeślij ją do etapu w `stage.resume`
     (`corr_id` = `msg_id` requestu).
   - `stage.aborted` → odnotuj w logu, zatrzymaj kolejkę, oddaj sterowanie
     użytkownikowi.
   - `error.critical` → przerwij działanie harnessu z komunikatem.
6. Po `stage.done`: sprawdź **bramę wyjściową**. Przechodzi → wróć do punktu 4 dla następnego
   etapu. Braki → `stage.resume` z listą braków lub zgłoszenie użytkownikowi.
7. Po wyczerpaniu kolejki: podsumuj przebieg i zakończ.

### Log orkiestratora (`orkiestrator-log.md`)

Osobny plik, niezależny od logów etapów. Te same zasady co w logach etapów:
wyłącznie decyzje i zdarzenia sterujące, żadnego kodu ani diffów, wpisy
numerowane chronologicznie, **każdy wpis poprzedzony znacznikiem czasu**
w formacie `yyyy-MM-dd; HH-mm-ss` (patrz "Znaczniki czasu w logach").

Odnotowuje: **ustalony katalog wynikowy**,
start/koniec każdego etapu, każdy routing requestu (kto → co → do kogo →
z jakim wynikiem), **wynik każdej bramy wejściowej i wyjściowej** (przeszła /
nie przeszła + który warunek), przerwania
i critical errory.

Osobno, z racji roli w zabezpieczeniu przed zapętleniem, log **musi** zawierać:
zlecenie Etapu 0 i moment odebrania raportu, moment zapisu
`refactor-session.md`, moment wyczyszczenia kontekstu oraz
wynik reguły 4 godzin przy kolejnym wejściu.

Przykład: `examples/orchestrator-examples/log-orkiestratora.md`.

