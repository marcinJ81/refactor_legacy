---
name: refactor-legacy
description: Harness do bezpiecznej refaktoryzacji i wprowadzania zmian w kodzie legacy (np. .NET Framework 4.8.1, .NET MVC, jQuery). Używać zawsze gdy użytkownik prosi o refaktor, zmianę zachowania istniejącego kodu, wydzielenie metod/klas, dodanie testów do kodu bez pokrycia testami, lub redukcję couplingu. Orkiestrator prowadzi proces etapami, pilnuje poprawnego wykonania każdego etapu i wymaga jawnej akceptacji użytkownika między etapami - nie pomijać etapów, nawet jeśli zadanie wygląda na proste.
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

Szkielet w budowie. Konfiguracja wstępna, protokół komunikacji i mechanizm
wznawiania sesji — opisane. Etap 0 — opisany. Etap 1 — opisany. Etap 2: wariant
"Refaktor" kroki 1–3 opisane, kolejne do zdefiniowania; wariant "Zmiana logiki"
— w budowie. Etap 3 — pusty, do zdefiniowania.

## Podstawa metodyczna

Harness nie opiera się na jednym autorze ani jednej szkole — łączy kilka źródeł,
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

## Struktura harnessu (pliki)

| Plik | Rola |
|---|---|
| `orkiestrator.md` (ten plik) | Orkiestrator: rozpoznanie stanu, konfiguracja wstępna, protokół, pętla sterowania |
| `etap0.md` | Etap 0 — Rozpoznanie stanu (wznowienie sesji), wykonywany przez agenta |
| `etap1.md` | Etap 1 — Characterization + Seams |
| `etap2.md` | Etap 2 — Wprowadzenie zmiany (Refaktor i/lub Zmiana logiki) |
| `etap3.md` | Etap 3 — Refaktoryzacja rezultatu Etapu 2 *(pusty, do zdefiniowania)* |

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
5. **Routuje requesty między etapami.** Przykład: Etap 2 w trakcie zmiany nazw
   stwierdza, że trzeba zmienić test → wystawia request do orkiestratora →
   orkiestrator uruchamia Etap 1 w trybie zadaniowym z tym requestem → po
   wykonaniu wraca sterowanie do Etapu 2 w miejsce, w którym zostało przerwane.
6. **Pilnuje integralności konfiguracji** (patrz "Kontrola integralności").
7. **Pilnuje poprawnego wykonania etapów** — sprawdza bramę wejściową przed
   startem i bramę wyjściową po zakończeniu każdego etapu (patrz "Bramy
   etapów"). To główna funkcja harnessu: etap nie decyduje sam o tym, czy
   wolno mu wystartować i czy zrobił, co miał zrobić.
8. **Prowadzi log orkiestratora** — kto, kiedy, jaki request, do kogo
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
   i wczytywany przez etapy razem z resztą konfiguracji. Podlega kontroli
   integralności jak każda inna pozycja konfiguracji.
2. **Każdy etap na starcie zapisuje w swoim logu datę i godzinę uruchomienia**
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
2. **Sprawdź regułę 10 minut** (zabezpieczenie przed zapętleniem):
   - Plik istnieje, odnotowuje wyczyszczenie kontekstu, a od znacznika czasu
     tego wpisu minęło **mniej niż 10 minut** → to jest środowisko przygotowane
     do pracy w tym samym przebiegu. Etap 0 **nie jest uruchamiany ponownie**;
     orkiestrator korzysta z zapisanego `etap0-raport.json` i przechodzi
     do punktu 6.
   - Plik nie istnieje albo od wpisu minęło **10 minut lub więcej** → to nowe
     uruchomienie. Przejdź do punktu 3.
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

   **Jeśli automatyczne wywołanie `/clear` nie jest możliwe** (harness nie ma
   takiej możliwości technicznej), orkiestrator **nie udaje, że je wykonał**:
   informuje użytkownika, że kontekst można teraz wyczyścić ręcznie **bez
   utraty danych** — wszystko, co znalazł Etap 0, jest już zapisane
   w `etap0-raport.json` i `refactor-session.md` — i czeka. Zapis stanu sesji
   następuje tak samo, przed prośbą.
6. **Po odzyskaniu sterowania** (po `/clear` albo po ręcznym wyczyszczeniu):
   wczytaj `refactor-session.md` i `etap0-raport.json`, porównaj znaczniki
   czasu (reguła 10 minut z punktu 2) i dopiero wtedy przejdź do Pytań 0–2.

Jeśli Etap 0 **nie wykrył żadnej poprzedniej sesji**, postępowanie jest
**identyczne** — raport z pustymi tablicami przechodzi tę samą ścieżkę, łącznie
z zapisem stanu sesji i czyszczeniem kontekstu. Brak historii nie jest
przypadkiem szczególnym.

### Interpretacja raportu

Na podstawie `etap0-raport.json` orkiestrator rozstrzyga:

| Sytuacja w raporcie | Decyzja orkiestratora |
|---|---|
| Brak katalogu wynikowego | Nowa sesja: nowy katalog `refactor-legacy`, pełne Pytania 0–2 |
| Katalog jest, `konfiguracja.plik_istnieje: false` | Nowa sesja w kolejnej wersji katalogu, pełne Pytania 0–2 |
| Konfiguracja jest i kompletna, wszystkie etapy `done` | Poprzedni refaktor domknięty → nowa sesja, nowa wersja katalogu |
| Konfiguracja jest, któryś etap `in_progress` / `aborted` | Zaproponuj użytkownikowi **wznowienie** od tego etapu; pokaż, co zostało zrobione, jakie requesty wiszą otwarte i jakie pozycje są nierozstrzygnięte |
| `requesty_otwarte` niepuste | Wypisz je użytkownikowi przed jakąkolwiek decyzją — to niedokończona wymiana z poprzedniej sesji |
| `anomalie` niepuste | Pokaż użytkownikowi; anomalie nie blokują startu, ale nie są przemilczane |

**Wznowienie nie jest automatyczne.** Orkiestrator przedstawia stan i pyta
użytkownika, czy wznawiamy przerwany przebieg, czy zaczynamy nowy. Przy
wznowieniu konfiguracja z `refactor-decisions.md` staje się snapshotem
referencyjnym (Pytania 0–2 nie są zadawane od nowa, ale są **pokazane
użytkownikowi do potwierdzenia**).

### Plik stanu sesji (`refactor-session.md`)

Celowo bardzo krótki — jest czytany przed Etapem 0, więc nie może być kosztowny
w kontekście. Zapisuje go wyłącznie orkiestrator.

```markdown
# Stan sesji harnessu

- Etap 0 wykonany: 2026-08-30; 18-52-30
- Raport: etap0-raport.json
- Wykryte poprzednie sesje: 2
- Kontekst wyczyszczony: tak (automatycznie) — 2026-08-30; 18-52-41
- Tryb po wznowieniu: kontynuacja Etapu 2 / nowa sesja
```

Pole "Kontekst wyczyszczony" przyjmuje: `tak (automatycznie)`,
`tak (przez użytkownika)`, `nie — oczekiwanie na użytkownika`.

---

## Bramy etapów (kontrola wykonania)

Orkiestrator otwiera i zamyka każdy etap. Etap nie startuje z własnej inicjatywy
i nie ogłasza sam, że skończył — deklaruje `stage.done`, a orkiestrator to
weryfikuje.

### Brama wejściowa — przed `stage.start`

**Wyjątek — Etap 0.** Etap 0 wykonuje się przed konfiguracją wstępną, więc
brama wejściowa go nie dotyczy. Jego jedynym warunkiem uruchomienia jest reguła
10 minut z sekcji "Etap 0 i wznowienie sesji".

Sprawdzane dla każdego pozostałego etapu:

0. Etap 0 został wykonany w bieżącym przebiegu (istnieje `refactor-session.md`
   z aktualnym wpisem i `etap0-raport.json`). Bez rozpoznania stanu żaden etap
   nie startuje — inaczej harness mógłby nadpisać wynik poprzedniej sesji.
1. Konfiguracja wstępna jest kompletna — wszystkie pozycje Pytań 0–2 mają
   jawny wybór użytkownika, żadna nie jest pusta ani domyślna po cichu.
2. `refactor-decisions.md` istnieje i zgadza się ze snapshotem w pamięci.
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
   żaden nie wisi bez `response`.
4. Nie ma nierozstrzygniętych pozycji oznaczonych jako blokujące (np.
   nierozpoznane magic numbers, na które etap czekał — patrz `etap2.md`,
   Krok 2). Pozycje otwarte niewymagające rozstrzygnięcia są dopuszczalne, ale
   muszą być wypisane w pliku wynikowym.
5. Kontrola integralności konfiguracji wypada zgodnie.

Niespełniony warunek → orkiestrator **nie zamyka etapu**: odsyła
`stage.resume` z listą braków albo, jeśli braku nie da się uzupełnić bez
decyzji użytkownika, zgłasza to użytkownikowi. Etap nie zostaje uznany za
zakończony, dopóki brama wyjściowa nie przejdzie.

### Zasada nieprzeskakiwania

Kolejność etapów wynika z kolejki ustalonej w Pytaniu 2 i nie podlega
samodzielnej zmianie przez etap ani przez orkiestratora. Jedyny dopuszczalny
"skok" to routing zadaniowy: chwilowe wywołanie Etapu 1 w trybie
`task.execute` na zlecenie innego etapu, po którym sterowanie **zawsze** wraca
do etapu-zleceniodawcy w punkcie `resume_point`. Nie jest to przejście etapu
i nie zamyka etapu zleceniodawcy.

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

## Format znacznika czasu (stała harnessu, nie pytanie)
- Format: `yyyy-MM-dd; HH-mm-ss`  (np. 2026-08-30; 19-07-12)
- Obowiązuje: log orkiestratora i logi wszystkich etapów, każdy wpis
```

Pozycja "Format znacznika czasu" nie jest pytaniem do użytkownika — to stała
harnessu zapisywana w pliku konfiguracyjnym po to, żeby etapy wczytywały ją
razem z resztą konfiguracji i stosowały bez wyjątku (patrz "Znaczniki czasu
w logach").

### Katalog wynikowy

Wszystkie pliki powstałe w trakcie działania harnessu (plan/plany, logi
decyzji, opcjonalne pliki szczegółowe per iteracja, komunikaty protokołu)
zapisywane są w katalogu `refactor-legacy`, utworzonym wewnątrz katalogu
**projektu będącego przedmiotem refaktoryzacji** (nie w katalogu samego
harnessu).

Jeśli katalog o tej nazwie już istnieje (np. z poprzedniego uruchomienia
harnessu na tym samym projekcie), nowy katalog otrzymuje kolejny numer wersji:
`refactor-legacy-ver2`, `refactor-legacy-ver3`, itd. Istniejący katalog nigdy
nie jest nadpisywany.

**Wyjątek — pliki Etapu 0.** Etap 0 wykonuje się, zanim wiadomo, czy powstanie
nowa wersja katalogu. Dlatego `etap0-raport.json` i `refactor-session.md`
zapisywane są zawsze w **najnowszym istniejącym** katalogu wynikowym; jeśli nie
istnieje żaden, orkiestrator tworzy `refactor-legacy` na tę potrzebę. Gdy
interpretacja raportu prowadzi do decyzji o nowej wersji katalogu, oba pliki
są do niej kopiowane jako punkt startowy nowej sesji — oryginały zostają
nietknięte.

---

## Snapshot konfiguracji i kontrola integralności

**Snapshot.** Po zapisaniu `refactor-decisions.md` orkiestrator zachowuje
odpowiedzi z Pytań 0–2 **w pamięci** jako snapshot referencyjny na czas całego
uruchomienia harnessu.

**Przekazanie do etapów.** Konfiguracja jest przekazywana do Etapu 1 (i do
kolejnych etapów) jako wsad początkowy w polu `config` wiadomości `stage.start`.

**Przypominajka.** Etapy nie muszą trzymać konfiguracji w pamięci między
wywołaniami ani między iteracjami — przed każdą iteracją wczytują na nowo
`refactor-decisions.md` z dysku. To realizuje zasadę stałego odświeżania
kontekstu: zapobiega odejściu od reguł ustalonych na starcie (granulacja,
framework testowy, zasada braku zmian bez planu, struktura plików wynikowych)
w miarę postępu pracy, niezależnie od długości sesji.

**Kontrola integralności (zabezpieczenie).** Po zakończeniu **każdego** etapu
orkiestrator porównuje zawartość `refactor-decisions.md` ze swoim snapshotem
w pamięci.

- Zgodne → proces idzie dalej.
- **Rozjazd → CRITICAL ERROR.** Orkiestrator **przerywa działanie całego
  harnessu** z komunikatem, że główne założenia zostały zmienione w trakcie
  działania. Wskazuje, które konkretnie pozycje się różnią (wartość
  ze snapshotu vs. wartość w pliku). Nie próbuje samodzielnie scalać,
  nadpisywać ani "naprawiać" pliku. Wznowienie wymaga decyzji użytkownika.

Cel: wychwycenie przypadkowej zmiany pliku konfiguracyjnego w trakcie pracy.

---

## Protokół komunikacji orkiestrator ↔ etapy

Etapy nie zwracają już samego "sukces / porażka". Każde zakończenie etapu,
każde przerwanie i każda potrzeba działania po stronie innego etapu jest
**wiadomością w formacie JSON**, niosącą komplet informacji potrzebny
odbiorcy do wykonania zadania bez dopytywania.

### Koperta wiadomości (wspólna dla wszystkich typów)

```json
{
  "msg_id": "e2-k1-003",
  "corr_id": "e2-k1-002",
  "type": "request | dispatch | response | event",
  "from": "etap2",
  "to": "orkiestrator",
  "action": "test.update",
  "status": "blocked | in_progress | done | failed | needs_user",
  "requires_user_ack": true,
  "user_message": "Po zmianie nazwy metody 3 testy świecą na czerwono. Aktualizuję je teraz — wyłącznie nazwy.",
  "payload": { },
  "timestamp": "<data i godzina>"
}
```

- `msg_id` — unikalny identyfikator wiadomości.
- `corr_id` — `msg_id` wiadomości, na którą ta odpowiada (`null` dla nowej).
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
| `stage.aborted` | Użytkownik przerwał iterację/etap |
| `error.critical` | Sytuacja blokująca dalsze działanie |

**Orkiestrator → etap (`type: "dispatch"`):**

| `action` | Znaczenie |
|---|---|
| `stage.start` | Uruchom etap; `payload.config` = konfiguracja wstępna |
| `task.execute` | Wykonaj pojedyncze zadanie zlecone przez inny etap |
| `stage.resume` | Wznów przerwany etap w punkcie `corr_id` |
| `stage.abort` | Zakończ etap (decyzja użytkownika lub critical error) |

**Etap → orkiestrator (`type: "response"`):** `status` = `done` / `failed` /
`needs_user`, w `payload.result` — co faktycznie zrobiono.

### Przykład: Etap 2 zleca zmianę testu Etapowi 1

Request z Etapu 2:

```json
{
  "msg_id": "e2-k1-007",
  "corr_id": null,
  "type": "request",
  "from": "etap2",
  "to": "orkiestrator",
  "action": "test.update",
  "status": "blocked",
  "requires_user_ack": true,
  "user_message": "Zmiana nazwy metody CalcTot -> CalculateOrderTotal. Testy czerwone: 3. Aktualizuję w nich wyłącznie nazwy.",
  "payload": {
    "cause": {
      "kind": "rename",
      "element": "method",
      "from": "CalcTot",
      "to": "CalculateOrderTotal"
    },
    "failing_tests": [
      { "test_id": "OrderTests.Total_Sums_Lines", "test_file": "...", "failure": "compile", "message": "..." }
    ],
    "allowed_scope": ["rename_only"],
    "forbidden": ["assert_change", "input_data_change", "test_scope_change"],
    "resume_point": "etap2/wariant-refaktor/krok-1"
  },
  "timestamp": "<data>"
}
```

Dispatch orkiestratora do Etapu 1:

```json
{
  "msg_id": "orc-014",
  "corr_id": "e2-k1-007",
  "type": "dispatch",
  "from": "orkiestrator",
  "to": "etap1",
  "action": "task.execute",
  "status": "in_progress",
  "requires_user_ack": false,
  "user_message": "",
  "payload": {
    "config": { "framework": "NUnit", "granulacja": "...", "pliki_wynikowe": "A" },
    "task": { "...": "kopia payloadu z e2-k1-007" }
  },
  "timestamp": "<data>"
}
```

Po `response` ze statusem `done` orkiestrator wysyła do Etapu 2
`stage.resume` z `corr_id: "e2-k1-007"` i wskazaniem `resume_point`.

### Zapis wiadomości

Każda wiadomość zapisywana jest jako osobny plik w podkatalogu `komunikacja/`
katalogu wynikowego, w formacie
`<NNN>-<from>-<action>.json` (numeracja chronologiczna). Daje to pełny audyt
przepływu, niezależny od logów decyzji.

---

## Pętla sterowania orkiestratora

0. **Rozpoznanie stanu.** Wczytaj `refactor-session.md`; jeśli reguła 10 minut
   nie zwalnia z Etapu 0 — zleć Etap 0 agentowi, odbierz raport JSON, zapisz
   `etap0-raport.json` i `refactor-session.md`, odnotuj to w logu i dopiero
   **potem** wyczyść kontekst (`/clear`) albo poproś użytkownika o ręczne
   wyczyszczenie. Po odzyskaniu sterowania zinterpretuj raport i ustal
   z użytkownikiem: nowa sesja czy wznowienie (patrz "Etap 0 i wznowienie
   sesji").
1. Przeprowadź konfigurację wstępną (Pytania 0–2), zapisz
   `refactor-decisions.md` (razem z formatem znacznika czasu), zrób snapshot
   w pamięci. Przy wznowieniu: pokaż istniejącą konfigurację do potwierdzenia
   zamiast pytać od nowa.
2. Ustal kolejkę etapów na podstawie Pytania 2 (z pominięciami). Przy
   wznowieniu kolejka zaczyna się od etapu wskazanego w raporcie Etapu 0.
3. Dla kolejnego etapu z kolejki: sprawdź **bramę wejściową**. Gdy przechodzi —
   wczytaj plik etapu (`etap1.md` / `etap2.md` / `etap3.md`) i wyślij
   `stage.start` z `payload.config`. Gdy nie przechodzi — zgłoś użytkownikowi
   niespełniony warunek i czekaj.
4. **Czuwaj.** W trakcie działania etapu przyjmuj przychodzące wiadomości:
   - `user.approval` / `user.input` → przekaż `user_message` użytkownikowi,
     poczekaj na odpowiedź, odeślij ją do etapu.
   - `test.update` / `test.add` / `test.remove` / `test.mock.enable` /
     `test.mock.add` → jeśli `requires_user_ack: true`, najpierw pokaż
     `user_message` użytkownikowi (transparentność), potem wyślij
     `task.execute` do Etapu 1; po jego `response` wyślij `stage.resume` do
     etapu-zleceniodawcy. Wszystkie te akcje trafiają wyłącznie do Etapu 1 —
     to jedyny właściciel testów i ich obudowy (mocków).
   - `stage.aborted` → odnotuj w logu, zatrzymaj kolejkę, oddaj sterowanie
     użytkownikowi.
   - `error.critical` → przerwij działanie harnessu z komunikatem.
5. Po `stage.done`: sprawdź **bramę wyjściową** (obejmuje kontrolę
   integralności konfiguracji). Przechodzi → wróć do punktu 3 dla następnego
   etapu. Braki → `stage.resume` z listą braków lub zgłoszenie użytkownikowi.
   Rozjazd konfiguracji → CRITICAL ERROR i przerwanie.
6. Po wyczerpaniu kolejki: podsumuj przebieg i zakończ.

### Log orkiestratora (`orkiestrator-log.md`)

Osobny plik, niezależny od logów etapów. Te same zasady co w logach etapów:
wyłącznie decyzje i zdarzenia sterujące, żadnego kodu ani diffów, wpisy
numerowane chronologicznie, **każdy wpis poprzedzony znacznikiem czasu**
w formacie `yyyy-MM-dd; HH-mm-ss` (patrz "Znaczniki czasu w logach").

Odnotowuje: start/koniec każdego etapu, każdy routing requestu (kto → co → do
kogo → z jakim wynikiem), **wynik każdej bramy wejściowej i wyjściowej**
(przeszła / nie przeszła + który warunek), wynik każdej kontroli integralności,
przerwania i critical errory.

Osobno, z racji roli w zabezpieczeniu przed zapętleniem, log **musi** zawierać:
zlecenie Etapu 0 i moment odebrania raportu, moment zapisu
`refactor-session.md`, moment wyczyszczenia kontekstu (i czy było automatyczne,
czy wykonane przez użytkownika), oraz wynik reguły 10 minut przy kolejnym
wejściu.

Przykład:

```markdown
# Log orkiestratora

## Uruchomienie 2026-08-30; 18-51-02

2026-08-30; 18-51-02 — 1. Wczytano refactor-session.md; ostatni wpis starszy niż 10 min → nowa sesja.
2026-08-30; 18-51-05 — 2. Zlecono Etap 0 agentowi.
2026-08-30; 18-52-28 — 3. Odebrano raport Etapu 0: 2 poprzednie sesje, Etap 2 in_progress, 1 request otwarty.
2026-08-30; 18-52-30 — 4. Zapisano etap0-raport.json i refactor-session.md.
2026-08-30; 18-52-41 — 5. Wyczyszczono kontekst (automatycznie).
2026-08-30; 18-53-10 — 6. Po odzyskaniu sterowania: różnica 29 s < 10 min → środowisko przygotowane, Etap 0 pominięty.
2026-08-30; 18-54-00 — 7. Użytkownik wybrał wznowienie Etapu 2 od kroku 2.
```

---

## Flaga trybu testowego (`test`)

Flaga włącza tryb sprawdzania wykonalności kroków harnessu — weryfikowany jest
przebieg działania narzędzia (czy dany punkt da się wykonać), nie
merytoryczna poprawność wyniku.

- Konfiguracja podstawowa (Pytania 0–2) ustawiana jest normalnie, bez zmian.
- Wyjście z Etapu 1 domyślnie przyjmuje wynik "sukces", niezależnie od
  faktycznego rezultatu weryfikacji.
- To wstęp do systemu ocennego oceniającego działanie narzędzia (poprawność
  przepływu), a nie konkretne wyniki refaktoryzacji.

Zastosowanie flagi w kolejnych etapach oraz jej wpływ na protokół komunikacji
— do zdefiniowania w kolejnej iteracji.
