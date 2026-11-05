---
name: refactor-legacy
description: Harness do bezpiecznej refaktoryzacji i wprowadzania zmian w kodzie legacy. Używać zawsze gdy użytkownik prosi o refaktor, zmianę zachowania istniejącego kodu, wydzielenie metod/klas, dodanie testów do kodu bez pokrycia testami, lub redukcję couplingu. Orkiestrator prowadzi proces etapami, pilnuje poprawnego wykonania każdego etapu i wymaga jawnej akceptacji użytkownika między etapami - nie pomijać etapów, nawet jeśli zadanie wygląda na proste.
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


## Struktura harnessu (pliki)

| Plik | Rola |
|---|---|
| `orkiestrator.md` (ten plik) | Orkiestrator: rozpoznanie stanu, konfiguracja wstępna, protokół, pętla sterowania |
| `etap0.md` | Etap 0 — Rozpoznanie stanu (wznowienie sesji), wykonywany przez agenta |
| `etap1.md` | Etap 1 — Characterization + Seams |
| `references/etap1/feathers-technique-selection.md` | Etap 1 — wybór techniki rozrywania zależności (tabela objaw → technika, poziomy preferencji) |
| `references/etap1/feathers-dependency-breaking-csharp.md` | Etap 1 — katalog 21 technik Feathersa z przykładami w C# |
| `etap2.md` | Etap 2 — Refaktoryzacja wskazanego zakresu technikami z katalogu |
| `references/etap2/*.md` | Etap 2 — katalog technik refaktoryzacji: indeks, pliki autorów, siatka wyboru, przykłady krok po kroku |
| `etap3.md` | Etap 3 — Refaktoryzacja rezultatu Etapu 2 *(pusty, pomijany przez orkiestratora)* |
| `scripts/wspolne/wpis-logu.ps1` | Dopisanie wpisu do logu ze znacznikiem z zegara systemowego oraz znacznik dla pól JSON — jedyna droga zapisu do logów (patrz "Znaczniki czasu w logach") |
| `references/orkiestrator/konfiguracja-wstepna.md` | Orkiestrator — Pytanie 0 i zapis `refactor-decisions.md` |
| `references/orkiestrator/katalog-wynikowy.md` | Orkiestrator — nazwa i numeracja katalogu wynikowego |
| `references/orkiestrator/protokol-komunikacji.md` | Orkiestrator — koperta wiadomości, katalog akcji, zapis wiadomości |
| `references/orkiestrator/petla-sterowania.md` | Orkiestrator — kolejność działań i reakcja na wiadomości od etapów |
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
`-Naglowek sekcja` dopisuje `### <nazwa>` bez znacznika. Numer wpisu podaje
model w `-Tresc`; skrypt dokłada wyłącznie znacznik i separator ` — `.

---

## Etap 0 i wznowienie sesji

Harness może być uruchamiany na tym samym projekcie wielokrotnie. Żeby kolejne
uruchomienie nie zaczynało od zera i nie deptało wyników poprzedniego,
orkiestrator **przed Pytaniem 0** ustala, co już zostało zrobione.

**Każde wejście do harnessu, także wznowienie, przechodzi przez Etap 0.** Etap 0
odczytuje ostatnią ramkę z `komunikacja/` i podaje ją w raporcie. Orkiestrator
nie czyta `komunikacja/` sam.

### Przebieg

1. **Wczytaj `refactor-session.md`** (jeśli istnieje) — to krótki plik stanu
   sesji, opisany niżej. To jedyna rzecz, którą orkiestrator czyta przed
   Etapem 0.
2. - Pole `Stan raportu` ma wartość `do wczytania`: to powrót po wyczyszczeniu
     kontekstu w tym samym wejściu. Etap 0 właśnie się wykonał, więc nie zlecaj
     go ponownie i przejdź do punktu 6. To jedyny przypadek bez zlecenia Etapu 0;
     chroni przed zapętleniem.
   - Pole ma wartość `wczytany` albo pliku nie ma: przejdź do punktu 3.
3. **Zleć Etap 0 agentowi** (`stage.start` do `etap0`, patrz `etap0.md`).
   Orkiestrator nie przeszukuje katalogów sam.
4. **Odbierz raport JSON.** Zapisz go w katalogu wynikowym jako
   `etap0-raport.json`. Nowy raport zastępuje poprzedni.
5. **Zapisz stan sesji, potem wyczyść kontekst.** Kolejność jest krytyczna:
   - **najpierw** orkiestrator zapisuje `refactor-session.md` z `Stan raportu:
     do wczytania` oraz wpis w `orkiestrator-log.md`;
   - **potem** czyści kontekst (`/clear`).
6. **Po odzyskaniu sterowania:** wczytaj `etap0-raport.json`, ustaw w
   `refactor-session.md` `Stan raportu: wczytany` i zinterpretuj raport (patrz
   "Interpretacja raportu"). Ustal z użytkownikiem: wznowienie czy nowa sesja.
   Potem przejdź do Pytania 0.

Jeśli Etap 0 **nie wykrył żadnej poprzedniej sesji**, postępowanie jest
**identyczne** — raport z pustymi tablicami przechodzi tę samą ścieżkę, łącznie
z zapisem stanu sesji i czyszczeniem kontekstu. Brak historii nie jest
przypadkiem szczególnym.

### Interpretacja raportu

Na podstawie `etap0-raport.json` orkiestrator rozstrzyga:

| Sytuacja w raporcie | Decyzja orkiestratora |
|---|---|
| Brak katalogu wynikowego | Nowa sesja: katalog `refactor-result1`, pełne Pytanie 0 |
| Katalog jest, `konfiguracja.plik_istnieje: false` | Nowa sesja w katalogu o kolejnym numerze, pełne Pytanie 0 |
| Konfiguracja jest i kompletna, `wznowienie: null` (wszystkie etapy `done`) | Poprzedni refaktor domknięty → nowa sesja, katalog o kolejnym numerze |
| Konfiguracja jest, `wznowienie` różne od `null` | Zaproponuj użytkownikowi **wznowienie** od etapu `wznowienie.etap`; pokaż, co zostało zrobione, jakie requesty wiszą otwarte i jakie pozycje są nierozstrzygnięte |
| `requesty_otwarte` niepuste | Wypisz je użytkownikowi przed jakąkolwiek decyzją — to niedokończona wymiana z poprzedniej sesji |
| `anomalie` niepuste | Pokaż użytkownikowi; anomalie nie blokują startu, ale nie są przemilczane |

**Wznowienie nie jest automatyczne.** Orkiestrator przedstawia stan i pyta
użytkownika, czy wznawiamy przerwany przebieg, czy zaczynamy nowy. Przy
wznowieniu konfiguracja jest wczytywana z `refactor-decisions.md` (Pytanie 0 nie jest zadawane od nowa, ale jego odpowiedzi są **pokazane
użytkownikowi do potwierdzenia**).

**Wznowienie nie tworzy nowego katalogu.** Przebieg kontynuuje w katalogu
wznawianej sesji; numer katalogu rośnie wyłącznie przy nowej sesji (patrz
`references/orkiestrator/katalog-wynikowy.md`). Dzięki temu stan jednej sesji zostaje w jednym miejscu.

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
brama wejściowa go nie dotyczy. O jego uruchomieniu decyduje sekcja "Etap 0
i wznowienie sesji", punkt 2.

Sprawdzane dla każdego pozostałego etapu:

0. Etap 0 został wykonany w bieżącym przebiegu (istnieje `refactor-session.md`
   z aktualnym wpisem i `etap0-raport.json`). Bez rozpoznania stanu żaden etap
   nie startuje — inaczej harness mógłby nadpisać wynik poprzedniej sesji.
1. Konfiguracja wstępna jest kompletna — wszystkie pozycje Pytania 0 mają jawny wybór użytkownika, żadna nie jest pusta ani
   domyślna po cichu.
2. `refactor-decisions.md` istnieje.
3. Poprzedni etap w kolejce zakończył się `stage.done` **i** jego wynik został
   jawnie zaakceptowany przez użytkownika (dla Etapu 2 to opisana w `etap2.md`
   brama wejściowa; Etap 1 nie ma poprzednika).

Niespełniony którykolwiek warunek → etap **nie startuje**. Orkiestrator zgłasza
użytkownikowi, który warunek jest niespełniony, i czeka.

### Brama wyjściowa — po `stage.done`

Sprawdzane po deklaracji zakończenia etapu:

1. Powstał plik wynikowy `etapN-plan.md` w formacie wymaganym przez ten etap.
2. Log etapu istnieje, jest niepusty i chronologiczny.
3. Wszystkie requesty wystawione przez ten etap mają domkniętą odpowiedź —
   na każdy poszedł `stage.resume` z jego `msg_id` w `corr_id`.
4. Nie ma nierozstrzygniętych pozycji oznaczonych jako blokujące (np.
   literały o nieustalonym znaczeniu, na które etap czekał — patrz `etap2.md`,
   "Zakaz zgadywania"). Pozycje otwarte niewymagające rozstrzygnięcia są dopuszczalne, ale
   muszą być wypisane w pliku wynikowym.

Niespełniony warunek → orkiestrator **nie zamyka etapu**: odsyła
`stage.resume` z listą braków albo, jeśli braku nie da się uzupełnić bez
decyzji użytkownika, zgłasza to użytkownikowi. Etap nie zostaje uznany za
zakończony, dopóki brama wyjściowa nie przejdzie.

### Zasada nieprzeskakiwania

Kolejka etapów jest stała: Etap 1, potem Etap 2. Użytkownik jej nie wybiera,
a etap ani orkiestrator nie mogą jej zmienić. Etapy nie zlecają sobie nawzajem
zadań.

---

## Konfiguracja wstępna (wymagana przed uruchomieniem jakiegokolwiek etapu)

**Przed zadaniem pierwszego pytania konfiguracyjnego wczytaj
`references/orkiestrator/konfiguracja-wstepna.md` i przeprowadź konfigurację
dokładnie według tego pliku.** Tam jest Pytanie 0 i zapis wyniku do
`refactor-decisions.md` (log decyzji). Nie zadajesz pytań z pamięci i nie
pomijasz żadnego. Bez tego pliku żaden etap nie startuje (patrz "Brama
wejściowa", warunki 1–2).

---

## Katalog wynikowy

Nazwa, numeracja i lokalizacja katalogu wynikowego (`refactor-resultN`) oraz
wyjątek dla plików Etapu 0: `references/orkiestrator/katalog-wynikowy.md`.

---

## Protokół komunikacji orkiestrator ↔ etapy

**Przed wysłaniem lub odebraniem jakiejkolwiek wiadomości od etapu wczytaj
`references/orkiestrator/protokol-komunikacji.md`.** Tam są koperta
wiadomości, katalog akcji i zasady zapisu wiadomości. Nie wysyłaj wiadomości
z pamięci — format i akcje bierzesz wyłącznie z tego pliku.

---

## Pętla sterowania orkiestratora

Kolejność działań orkiestratora od rozpoznania stanu do zakończenia kolejki
oraz reakcja na każdą wiadomość od etapu: `references/orkiestrator/petla-sterowania.md`.
Jest to ważny punkt musi być bezwzględnie wczytany.

---

## Log orkiestratora (`orkiestrator-log.md`)

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
decyzję użytkownika przy kolejnym wejściu: wznowienie czy nowa sesja.

Przykład: `examples/orchestrator-examples/log-orkiestratora.md`.

