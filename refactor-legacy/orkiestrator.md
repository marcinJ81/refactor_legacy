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
— w budowie. Etap 3 — pusty, do zdefiniowania. Tryb uruchomienia
(`normalny` / `test`) i tryb testowy — opisane; format i katalog mocków oraz
system ocenny — do zdefiniowania (patrz "Tryb testowy").

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
2. **Ustala tryb uruchomienia.** Jako **pierwszą czynność**, jeszcze przed
   Etapem 0, orkiestrator rozstrzyga tryb (`normalny` / `test`) — z flagi
   wywołania albo pytając użytkownika. Od trybu zależy m.in. to, których
   katalogów wynikowych szuka Etap 0 (patrz "Tryb uruchomienia").
3. **Ustala stan wyjściowy przed konfiguracją.** Zanim padnie pierwsze pytanie
   konfiguracyjne, orkiestrator zleca **Etap 0** i na podstawie jego raportu
   rozstrzyga, czy to nowe uruchomienie, czy kontynuacja (patrz "Etap 0
   i wznowienie sesji").
4. **Przekazuje wynik konfiguracji do etapów** jako wsad początkowy.
5. **Czuwa w trakcie działania etapu.** Nie kończy pracy po odpaleniu etapu —
   pozostaje aktywny i reaguje na requesty przychodzące z etapu w dowolnym
   momencie jego trwania (praca asynchroniczna, wymiana dwukierunkowa).
6. **Routuje requesty między etapami.** Przykład: Etap 2 w trakcie zmiany nazw
   stwierdza, że trzeba zmienić test → wystawia request do orkiestratora →
   orkiestrator uruchamia Etap 1 w trybie zadaniowym z tym requestem → po
   wykonaniu wraca sterowanie do Etapu 2 w miejsce, w którym zostało przerwane.
7. **Pilnuje integralności konfiguracji** (patrz "Kontrola integralności").
8. **Pilnuje poprawnego wykonania etapów** — sprawdza bramę wejściową przed
   startem i bramę wyjściową po zakończeniu każdego etapu (patrz "Bramy
   etapów"). To główna funkcja harnessu: etap nie decyduje sam o tym, czy
   wolno mu wystartować i czy zrobił, co miał zrobić.
9. **Prowadzi log orkiestratora** — kto, kiedy, jaki request, do kogo
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

## Tryb uruchomienia (`normalny` / `test`)

Harness działa w jednym z dwóch trybów. Tryb jest **pierwszą rzeczą, jaką
orkiestrator ustala** — wcześniej niż Etap 0, bo od trybu zależy, których
katalogów wynikowych Etap 0 w ogóle szuka.

| Tryb | Znaczenie |
|---|---|
| `normalny` | Praca na realnym kodzie. Etapy wykonują się naprawdę. |
| `test` | Test orkiestratora w izolacji. Orkiestrator działa normalnie, ale etapy nie są wykonywane — ich odpowiedzi są podstawiane z przygotowanych wcześniej mocków (patrz "Tryb testowy") |

### Pytanie T — Tryb uruchomienia

Zadawane **jako pierwsza czynność uruchomienia harnessu, przed Etapem 0**
i przed Pytaniami 0–2.

- Jeśli harness został wywołany z flagą `test`, flaga rozstrzyga i pytanie nie
  jest zadawane — orkiestrator informuje użytkownika, w jakim trybie startuje.
- Jeśli flagi nie podano, orkiestrator **pyta**. Nie ma trybu przyjmowanego
  domyślnie po cichu — obowiązuje ten sam rygor co przy Pytaniach 0–2.

Numeracja Pytań 0–2 pozostaje bez zmian. Pytanie T stoi poza nią, bo pada przed
Etapem 0, a nie w bloku konfiguracji wstępnej.

### Tryb jako część konfiguracji

Tryb nie jest lokalnym przełącznikiem orkiestratora — jest pełnoprawną pozycją
konfiguracji:

1. Trafia do `refactor-decisions.md` (sekcja "Tryb uruchomienia").
2. Wchodzi do snapshotu w pamięci razem z odpowiedziami na Pytania 0–2.
3. Jest przekazywany etapom w `payload.config` jako
   `"tryb": "normalny" | "test"`. Etapy działają w izolacji i całą konfigurację
   dostają plikiem, więc muszą wiedzieć, w jakim trybie działa harness.
4. **Podlega kontroli integralności.** Zmiana trybu w trakcie przebiegu =
   rozjazd ze snapshotem = CRITICAL ERROR, tak samo jak każda inna pozycja
   konfiguracji.
5. Trafia do raportu Etapu 0 jako pole `tryb` — raport jest dzięki temu
   samoopisujący się co do tego, którego zbioru katalogów dotyczy.

---

## Etap 0 i wznowienie sesji

Harness może być uruchamiany na tym samym projekcie wielokrotnie. Żeby kolejne
uruchomienie nie zaczynało od zera i nie deptało wyników poprzedniego,
orkiestrator **przed Pytaniami 0–2** ustala, co już zostało zrobione.

### Przebieg

1. **Wczytaj `refactor-session.md`** (jeśli istnieje) — to krótki plik stanu
   sesji, opisany niżej. To jedyna rzecz, którą orkiestrator czyta przed
   Etapem 0.
2. **Sprawdź regułę 60 minut** (zabezpieczenie przed zapętleniem):
   - Plik istnieje, odnotowuje wyczyszczenie kontekstu, a od znacznika czasu
     tego wpisu minęło **mniej niż 60 minut** → to jest środowisko przygotowane
     do pracy w tym samym przebiegu. Etap 0 **nie jest uruchamiany ponownie**;
     orkiestrator korzysta z zapisanego `etap0-raport.json` i przechodzi
     do punktu 6.
   - Plik nie istnieje albo od wpisu minęło **60 minut lub więcej** → to nowe
     uruchomienie. Przejdź do punktu 3.

   Limit wynika z obserwacji: przejście przez cały harness trwa długo, więc
   limit krótszy niż godzina rozbijał jeden przebieg na dwie sesje.
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
   czasu (reguła 60 minut z punktu 2) i dopiero wtedy przejdź do Pytań 0–2.

Jeśli Etap 0 **nie wykrył żadnej poprzedniej sesji**, postępowanie jest
**identyczne** — raport z pustymi tablicami przechodzi tę samą ścieżkę, łącznie
z zapisem stanu sesji i czyszczeniem kontekstu. Brak historii nie jest
przypadkiem szczególnym.

### Interpretacja raportu

Na podstawie `etap0-raport.json` orkiestrator rozstrzyga:

| Sytuacja w raporcie | Decyzja orkiestratora |
|---|---|
| Brak katalogu wynikowego | Nowa sesja: katalog `refactor-result1` (w trybie `test`: `refactor-result-test1`), pełne Pytania 0–2 |
| Katalog jest, `konfiguracja.plik_istnieje: false` | Nowa sesja w katalogu o kolejnym numerze, pełne Pytania 0–2 |
| Konfiguracja jest i kompletna, wszystkie etapy `done` | Poprzedni refaktor domknięty → nowa sesja, katalog o kolejnym numerze |
| Konfiguracja jest, któryś etap `in_progress` / `aborted` | Zaproponuj użytkownikowi **wznowienie** od tego etapu; pokaż, co zostało zrobione, jakie requesty wiszą otwarte i jakie pozycje są nierozstrzygnięte |
| `requesty_otwarte` niepuste | Wypisz je użytkownikowi przed jakąkolwiek decyzją — to niedokończona wymiana z poprzedniej sesji |
| `anomalie` niepuste | Pokaż użytkownikowi; anomalie nie blokują startu, ale nie są przemilczane |

**Wznowienie nie jest automatyczne.** Orkiestrator przedstawia stan i pyta
użytkownika, czy wznawiamy przerwany przebieg, czy zaczynamy nowy. Przy
wznowieniu konfiguracja z `refactor-decisions.md` staje się snapshotem
referencyjnym (Pytania 0–2 nie są zadawane od nowa, ale są **pokazane
użytkownikowi do potwierdzenia**).

**Wznowienie nie tworzy nowego katalogu.** Przebieg kontynuuje w katalogu
wznawianej sesji; numer katalogu rośnie wyłącznie przy nowej sesji (patrz
"Katalog wynikowy"). Dzięki temu stan jednej sesji zostaje w jednym miejscu.

### Plik stanu sesji (`refactor-session.md`)

Celowo bardzo krótki — jest czytany przed Etapem 0, więc nie może być kosztowny
w kontekście. Zapisuje go wyłącznie orkiestrator.

```markdown
# Stan sesji harnessu

- Tryb uruchomienia: normalny
- Katalog wynikowy: refactor-result3
- Etap 0 wykonany: 2026-08-30; 18-52-30
- Raport: etap0-raport.json
- Wykryte poprzednie sesje: 2
- Kontekst wyczyszczony: tak (automatycznie) — 2026-08-30; 18-52-41
- Kontynuacja: kontynuacja Etapu 2 / nowa sesja
```

Pole "Kontekst wyczyszczony" przyjmuje: `tak (automatycznie)`,
`tak (przez użytkownika)`, `nie — oczekiwanie na użytkownika`,
`tak (tryb test — oznaczone, kontekst nieczyszczony)`.

---

## Bramy etapów (kontrola wykonania)

Orkiestrator otwiera i zamyka każdy etap. Etap nie startuje z własnej inicjatywy
i nie ogłasza sam, że skończył — deklaruje `stage.done`, a orkiestrator to
weryfikuje.

### Brama wejściowa — przed `stage.start`

**Wyjątek — Etap 0.** Etap 0 wykonuje się przed konfiguracją wstępną, więc
brama wejściowa go nie dotyczy. Jego jedynym warunkiem uruchomienia jest reguła
60 minut z sekcji "Etap 0 i wznowienie sesji". W trybie `test` Etap 0 nie jest
uruchamiany w ogóle — jego raport jest podstawiany z mocka (patrz "Tryb
testowy").

Sprawdzane dla każdego pozostałego etapu:

0. Etap 0 został wykonany w bieżącym przebiegu (istnieje `refactor-session.md`
   z aktualnym wpisem i `etap0-raport.json`). Bez rozpoznania stanu żaden etap
   nie startuje — inaczej harness mógłby nadpisać wynik poprzedniej sesji.
1. Konfiguracja wstępna jest kompletna — Pytanie T (tryb) oraz wszystkie
   pozycje Pytań 0–2 mają jawny wybór użytkownika, żadna nie jest pusta ani
   domyślna po cichu.
2. `refactor-decisions.md` istnieje i zgadza się ze snapshotem w pamięci.
3. Etap nie jest pominięty decyzją z Pytania 2.
4. Poprzedni etap w kolejce zakończył się `stage.done` **i** jego wynik został
   jawnie zaakceptowany przez użytkownika (dla Etapu 2 to opisana w `etap2.md`
   brama wejściowa; Etap 1 nie ma poprzednika).
5. Plik etapu istnieje i nie jest pusty (dotyczy m.in. Etapu 3, który jest na
   razie pusty — próba jego uruchomienia kończy się `error.critical`, nie cichym
   pominięciem). **Wyjątek w trybie `test`:** dla Etapu 3 ten warunek przechodzi
   zawsze, dopóki `etap3.md` nie zostanie napisany — inaczej żaden przebieg
   testowy nie doszedłby do końca kolejki. W trybie `normalny` warunek działa
   bez zmian.

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

W trybie `test` bramy wyjściowej **nie łagodzimy**: warunki 1–2 nadal czytają
realne pliki z dysku, a wytwarza je paczka mocka (patrz "Tryb testowy"). To
celowe — pilnowanie bram jest głównym przedmiotem testu, więc muszą działać
nietknięte.

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

Konfigurację poprzedza także **Pytanie T** (tryb uruchomienia), zadawane
jeszcze przed Etapem 0 — patrz "Tryb uruchomienia". Jego wynik jest częścią tej
samej konfiguracji i trafia do tego samego pliku decyzji.

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

## Tryb uruchomienia (Pytanie T)
- [ ] Tryb: (normalny / test)
      -> źródło: flaga wywołania / wybór użytkownika
- [ ] Katalog wynikowy tego przebiegu: refactor-resultN / refactor-result-testN

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
zapisywane są w katalogu wynikowym utworzonym wewnątrz katalogu **projektu
będącego przedmiotem refaktoryzacji** (nie w katalogu samego harnessu). Dotyczy
to obu trybów — przebieg testowy powstaje w tym samym miejscu, różni się
wyłącznie nazwą katalogu.

**Nazwa katalogu zależy od trybu:**

| Tryb | Wzorzec nazwy | Przykłady |
|---|---|---|
| `normalny` | `refactor-resultN` | `refactor-result1`, `refactor-result2` |
| `test` | `refactor-result-testN` | `refactor-result-test1`, `refactor-result-test2` |

`N` to numer kolejnego uruchomienia, liczony od 1. Zasady:

1. **Numer to największy znaleziony + 1**, a nie liczba katalogów. Usunięcie
   `refactor-result2` nie powoduje ponownego użycia numeru 2.
2. **Orkiestrator widzi wyłącznie katalogi bieżącego trybu.** W trybie
   `normalny` brane są pod uwagę tylko `refactor-resultN` (katalogi z dopiskiem
   `-test` są pomijane), w trybie `test` — tylko `refactor-result-testN`.
   Dzięki temu przebieg testowy nigdy nie zostanie rozpoznany jako prawdziwa
   sesja ani odwrotnie.
3. **Istniejący katalog nigdy nie jest nadpisywany.**
4. **Nowy numer powstaje tylko przy nowej sesji.** Jeśli Etap 0 wykrył
   poprzednią sesję i użytkownik wybrał wznowienie, przebieg **kontynuuje
   w katalogu wznawianej sesji**, bez inkrementacji. Numer rośnie wyłącznie
   wtedy, gdy zaczynamy nową sesję — Etap 0 nie znalazł poprzedniej albo
   użytkownik świadomie zaczyna od nowa.

Kolejność jest zatem taka: **tryb → Etap 0 (rozpoznanie katalogów tego trybu) →
decyzja "nowa sesja czy wznowienie" → dopiero wtedy ustalenie numeru
katalogu**. Zestaw istniejących numerów jest jednocześnie historią prób
uruchomienia harnessu na tym projekcie.

**Wyjątek — pliki Etapu 0.** Etap 0 wykonuje się, zanim wiadomo, czy powstanie
katalog o nowym numerze. Dlatego `etap0-raport.json` i `refactor-session.md`
zapisywane są zawsze w **najnowszym istniejącym** katalogu bieżącego trybu;
jeśli nie istnieje żaden, orkiestrator tworzy `refactor-result1` (odpowiednio
`refactor-result-test1`) na tę potrzebę. Gdy interpretacja raportu prowadzi do
decyzji o nowej sesji w katalogu o kolejnym numerze, oba pliki są do niego
kopiowane jako punkt startowy — oryginały zostają nietknięte.

---

## Snapshot konfiguracji i kontrola integralności

**Snapshot.** Po zapisaniu `refactor-decisions.md` orkiestrator zachowuje
tryb uruchomienia (Pytanie T) i odpowiedzi z Pytań 0–2 **w pamięci** jako
snapshot referencyjny na czas całego uruchomienia harnessu.

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
| `stage.start` | Uruchom etap; `payload.config` = konfiguracja wstępna (razem z `tryb`) |
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
    "config": { "tryb": "normalny", "framework": "NUnit", "granulacja": "...", "pliki_wynikowe": "A" },
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

0. **Ustal tryb uruchomienia (Pytanie T).** Flaga `test` przy wywołaniu →
   tryb `test`; brak flagi → zapytaj użytkownika. Odnotuj tryb w logu. To
   pierwsza czynność, przed czymkolwiek innym (patrz "Tryb uruchomienia").
1. **Rozpoznanie stanu.** Wczytaj `refactor-session.md`; jeśli reguła 60 minut
   nie zwalnia z Etapu 0 — zleć Etap 0 agentowi (w trybie `test`: podstaw
   raport z mocka), odbierz raport JSON, zapisz `etap0-raport.json`
   i `refactor-session.md`, odnotuj to w logu i dopiero **potem** wyczyść
   kontekst (`/clear`) albo poproś użytkownika o ręczne wyczyszczenie —
   w trybie `test` `/clear` jest tylko odnotowywany jako wykonany. Po
   odzyskaniu sterowania zinterpretuj raport i ustal z użytkownikiem: nowa
   sesja czy wznowienie (patrz "Etap 0 i wznowienie sesji"). Ustal katalog
   wynikowy przebiegu (patrz "Katalog wynikowy").
2. Przeprowadź konfigurację wstępną (Pytania 0–2), zapisz
   `refactor-decisions.md` (razem z trybem i formatem znacznika czasu), zrób
   snapshot w pamięci. Przy wznowieniu: pokaż istniejącą konfigurację do
   potwierdzenia zamiast pytać od nowa.
3. Ustal kolejkę etapów na podstawie Pytania 2 (z pominięciami). Przy
   wznowieniu kolejka zaczyna się od etapu wskazanego w raporcie Etapu 0.
4. Dla kolejnego etapu z kolejki: sprawdź **bramę wejściową**. Gdy przechodzi —
   wczytaj plik etapu (`etap1.md` / `etap2.md` / `etap3.md`) i wyślij
   `stage.start` z `payload.config`. W trybie `test` plik etapu nie jest
   wykonywany — orkiestrator podstawia mock odpowiadający temu dispatchowi
   (brak mocka → twardy błąd przebiegu, patrz "Tryb testowy"). Gdy brama nie
   przechodzi — zgłoś użytkownikowi niespełniony warunek i czekaj.
5. **Czuwaj.** W trakcie działania etapu przyjmuj przychodzące wiadomości:
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
6. Po `stage.done`: sprawdź **bramę wyjściową** (obejmuje kontrolę
   integralności konfiguracji). Przechodzi → wróć do punktu 4 dla następnego
   etapu. Braki → `stage.resume` z listą braków lub zgłoszenie użytkownikowi.
   Rozjazd konfiguracji → CRITICAL ERROR i przerwanie.
7. Po wyczerpaniu kolejki: podsumuj przebieg i zakończ.

### Log orkiestratora (`orkiestrator-log.md`)

Osobny plik, niezależny od logów etapów. Te same zasady co w logach etapów:
wyłącznie decyzje i zdarzenia sterujące, żadnego kodu ani diffów, wpisy
numerowane chronologicznie, **każdy wpis poprzedzony znacznikiem czasu**
w formacie `yyyy-MM-dd; HH-mm-ss` (patrz "Znaczniki czasu w logach").

Odnotowuje: **wybór trybu uruchomienia i ustalony katalog wynikowy**,
start/koniec każdego etapu, każdy routing requestu (kto → co → do kogo →
z jakim wynikiem), **wynik każdej bramy wejściowej i wyjściowej** (przeszła /
nie przeszła + który warunek), wynik każdej kontroli integralności, przerwania
i critical errory. W trybie `test` dodatkowo: który mock został podstawiony pod
który dispatch.

Osobno, z racji roli w zabezpieczeniu przed zapętleniem, log **musi** zawierać:
zlecenie Etapu 0 i moment odebrania raportu, moment zapisu
`refactor-session.md`, moment wyczyszczenia kontekstu (i czy było automatyczne,
czy wykonane przez użytkownika, czy tylko odnotowane w trybie `test`), oraz
wynik reguły 60 minut przy kolejnym wejściu.

Przykład:

```markdown
# Log orkiestratora

## Uruchomienie 2026-08-30; 18-51-00

2026-08-30; 18-51-00 — 1. Ustalono tryb uruchomienia: normalny (Pytanie T, wybór użytkownika).
2026-08-30; 18-51-02 — 2. Wczytano refactor-session.md; ostatni wpis starszy niż 60 min → nowa sesja.
2026-08-30; 18-51-05 — 3. Zlecono Etap 0 agentowi.
2026-08-30; 18-52-28 — 4. Odebrano raport Etapu 0: 2 poprzednie sesje (refactor-result1, refactor-result2), Etap 2 in_progress, 1 request otwarty.
2026-08-30; 18-52-30 — 5. Zapisano etap0-raport.json i refactor-session.md.
2026-08-30; 18-52-41 — 6. Wyczyszczono kontekst (automatycznie).
2026-08-30; 18-53-10 — 7. Po odzyskaniu sterowania: różnica 29 s < 60 min → środowisko przygotowane, Etap 0 pominięty.
2026-08-30; 18-54-00 — 8. Użytkownik wybrał wznowienie Etapu 2 od kroku 2 → kontynuacja w refactor-result2, bez nowego katalogu.
```

---

## Tryb testowy (`test`)

Pierwszy poziom piramidy testów harnessu: **test orkiestratora w izolacji**.
Sprawdzamy, czy orkiestrator pilnuje — czy poprawnie prowadzi przepływ, bramy,
routing i logi — a nie czy refaktoryzacja jest merytorycznie dobra. Testowanie
samych etapów to kolejny poziom piramidy i osobne testy.

### Na czym polega izolacja

Orkiestrator działa **normalnie**: ustala tryb, zadaje pytania, ustala kolejkę,
sprawdza bramy, routuje requesty, prowadzi logi i zapisuje `komunikacja/*.json`.
Podmieniony jest **wyłącznie sposób wykonania etapu**: zamiast uruchomić etap,
orkiestrator podstawia w miejsce jego odpowiedzi **przygotowany wcześniej plik
JSON** (mock), zgodny z protokołem komunikacji jak każda prawdziwa odpowiedź
etapu.

Flaga `test` **nie podmienia werdyktu etapu.** Wynik (`done` / `failed` /
`needs_user` / `error.critical`) bierze się z treści mocka — inaczej nie dałoby
się przetestować negatywnych ścieżek bram.

**Etap 0 też jest mockowany.** W trybie `test` Etap 0 nie wykonuje się
naprawdę — orkiestrator dostaje przygotowany `etap0-raport.json` i traktuje go
jak raport z prawdziwego przebiegu; warunek 0 bramy wejściowej przechodzi na tej
podstawie.

### Mock to paczka, nie sam JSON

Mock etapu składa się z dwóch części:

1. **Odpowiedź JSON** zgodna z protokołem komunikacji.
2. **Komplet plików, które etap by wytworzył** — plik wynikowy etapu, log
   etapu, ewentualne pliki szczegółowe. Sztuczna jest wyłącznie ich treść, nie
   ich obecność.

Powód: brama wyjściowa czyta realne pliki z dysku (warunki 1–2). Gdyby mock był
samym JSON-em, każda brama wyjściowa leciałaby na `false` niezależnie od tego,
czy orkiestrator działa poprawnie. Przy mocku-paczce **bramy działają nietknięte
i są naprawdę testowane** — można świadomie podać paczkę niekompletną
i sprawdzić, czy brama to złapie.

### Brak mocka to twardy błąd

Jeśli dla danego dispatchu nie ma przygotowanego mocka, orkiestrator
**przerywa przebieg testowy** z komunikatem, którego dispatchu zabrakło.
**Nigdy** nie schodzi po cichu do prawdziwego wykonania etapu — to
unieważniłoby izolację i test przestałby być testem.

### Odstępstwa obowiązujące wyłącznie w trybie `test`

| Miejsce | Zachowanie w trybie `test` |
|---|---|
| Wykonanie etapów 0–3 | Etap się nie uruchamia; odpowiedź i pliki pochodzą z mocka |
| `/clear` (krok 1 pętli sterowania) | Oznaczany w `refactor-session.md` i w logu jako wykonany; kontekst nie jest czyszczony |
| Warunek 5 bramy wejściowej (plik etapu niepusty) | Dla **Etapu 3** przechodzi zawsze, dopóki `etap3.md` jest pusty. Pozostałe etapy sprawdzane normalnie |
| Katalog wynikowy | `refactor-result-testN`, w tym samym miejscu co katalog trybu normalnego |
| Interakcja z użytkownikiem | **Nie jest mockowana** — Pytanie T, Pytania 0–2, akceptacje między etapami i odpowiedzi na `user.input` / `user.approval` obsługuje człowiek |

Poza tą tabelą orkiestrator w trybie `test` nie robi niczego inaczej.
W szczególności brama wejściowa i wyjściowa, kontrola integralności, routing
requestów, reguła 60 minut, logi i zapis `komunikacja/*.json` działają bez
zmian — bo to właśnie one są przedmiotem testu.

### Ocena przebiegu

W tej iteracji przebieg **ocenia człowiek**, na podstawie `orkiestrator-log.md`
i zapisu `komunikacja/*.json`. Orkiestrator nie zna pojęcia "przebieg oczekiwany
vs. faktyczny" i nie wystawia werdyktu.

### Odłożone do kolejnych iteracji

- **Format i katalog mocków** — po czym orkiestrator dobiera mock do dispatchu
  (para `to` + `action`, kolejność w scenariuszu, `corr_id`) i gdzie mocki
  fizycznie leżą.
- **Osobny orkiestrator testowy** — dokument bazujący na tym, ale trzymający
  instrukcje testowe, żeby środowisko testowe nie przenikało do
  "produkcyjnego".
- **Sterowanie czasem i dane wejściowe test case'ów** — sprawdzenie obu gałęzi
  reguły 60 minut bez czekania (np. `refactor-session.md` przygotowany
  z zadanym znacznikiem czasu).
- **Mockowanie interakcji użytkownika** — warunek pełnej automatyzacji
  przebiegu.
- **System ocenny** — pojęcie przebiegu oczekiwanego i pliku z werdyktem.
- **Plik JSON z konfiguracją harnessu** — docelowo może zastąpić pytania
  wstępne (Pytanie T i Pytania 0–2); na razie orkiestrator pyta.
