# changes2.md

Kontynuacja `changes.md` i `changes_test.md`. Zasada ta sama: wpisy użytkownika
zostają nietknięte, adnotacja o wprowadzeniu trafia pod wpis.

---

załaduj sobie plik changes oraz changes_test jako kontest

> ℹ️ Załadowane jako kontekst (`changes.md`, `changes_test.md`) — bez zmian w plikach.
> Odnotowany stan: ostatni wpis w `changes_test.md` (numerowanie katalogów po
> przekroczeniu czasu + **stan orkiestratora kluczowany własnym task/run ID,
> nie `session_id` Claude Code**) pozostaje **bez adnotacji — niewprowadzony**.

---

usuwamy regułę ręcznego wywołania clear przez uzytkownika, dodatkowo była regułą że sesja musi trwać godzinę bo inaczej zaczynamy ją na nowo, terez zmieniamy na cztery godziny, konwersjacje naszą zapisz w pliku changes2.md

> ✅ **Wprowadzono** (2026-09-08) — `refactor-legacy/orkiestrator.md`. Bez commita.
> Pozostałe pliki harnessu (`etap0.md`–`etap3.md`) nie zawierały odwołań do `/clear`
> ani do limitu czasu — nie wymagały zmian.
>
> **1. Ręczne czyszczenie kontekstu — usunięte**
>
> - **Etap 0 i wznowienie sesji, punkt 5** — skasowany akapit „Jeśli automatyczne
>   wywołanie `/clear` nie jest możliwe (…) informuje użytkownika, że kontekst można
>   teraz wyczyścić ręcznie **bez utraty danych** (…) i czeka". W jego miejsce wprost
>   przeciwna reguła: orkiestrator **nie prosi użytkownika o ręczne wyczyszczenie
>   kontekstu i nie czeka na nie** — czyszczenie jest czynnością harnessu, nie
>   użytkownika.
> - **Punkt 6** — „Po odzyskaniu sterowania (po `/clear` albo po ręcznym
>   wyczyszczeniu)" → „Po odzyskaniu sterowania (po `/clear`)".
> - **Pętla sterowania, krok 1** — usunięte „albo poproś użytkownika o ręczne
>   wyczyszczenie"; zostaje samo `/clear`, a w trybie `test` jego odnotowanie.
> - **Plik stanu sesji (`refactor-session.md`)** — pole „Kontekst wyczyszczony"
>   przyjmuje już tylko `tak (automatycznie)` albo
>   `tak (tryb test — oznaczone, kontekst nieczyszczony)`. Skasowane wartości
>   `tak (przez użytkownika)` i `nie — oczekiwanie na użytkownika` — ta druga była
>   jedynym stanem, w którym harness stał i czekał na człowieka.
> - **Log orkiestratora** — z listy obowiązkowych wpisów zniknęło „czy wykonane
>   przez użytkownika"; zostaje rozróżnienie automatyczne / odnotowane w trybie `test`.
>
> **2. Reguła 60 minut → reguła 4 godzin**
>
> Zmiana w komplecie, we wszystkich 12 miejscach: przebieg Etapu 0 (punkty 2 i 6),
> wyjątek bramy wejściowej dla Etapu 0, pętla sterowania (krok 1), sekcja logu
> orkiestratora, przykładowy log (dwa wpisy: `starszy niż 4 h`, `< 4 h`), tabela
> odstępstw trybu `test` i lista odłożonych iteracji (sterowanie czasem).
> Nazwa reguły w całym dokumencie brzmi teraz **„reguła 4 godzin"**.
>
> Uzasadnienie limitu przepisane — dotychczasowe („limit krótszy niż godzina rozbijał
> jeden przebieg na dwie sesje") zastąpione tym, co ustaliłeś w `changes_test.md`:
> resetowanie kontekstu w trakcie jednego przebiegu jest **częste**, a wartość jest
> **tymczasowa** — gdy orkiestrator zacznie działać na większym kontekście, czas
> zostanie wydłużony.
>
> **3. Czego świadomie nie zmieniałem**
>
> - Kolejność „najpierw zapis `refactor-session.md` + log, dopiero potem `/clear`" —
>   nietknięta. To nadal jedyne zabezpieczenie przed zapętleniem Etapu 0.
> - Tryb `test` — `/clear` nadal jest tam tylko **oznaczany** jako wykonany, kontekst
>   nie jest czyszczony.
> - Reguły dotyczące ręcznych czynności użytkownika **w innych obszarach** (commity
>   wykonuje wyłącznie użytkownik ręcznie, ręczne potwierdzenia planów i akceptacje
>   między etapami) — poza zakresem tej zmiany, zostają.
>
> **4. Wątpliwość do rozstrzygnięcia**
>
> Usunięcie ścieżki ręcznej zostawia **jedną** drogę wyjścia z Etapu 0: automatyczne
> `/clear`. Jeśli w praktyce harness nie ma technicznej możliwości wywołania `/clear`
> sam, nie ma już zapasowego wariantu — orkiestrator przejdzie dalej z kontekstem
> pełnym raportu Etapu 0 (czyli dokładnie tym, czemu Etap 0 miał zapobiegać) albo
> stanie bez zdefiniowanego zachowania. To zbiega się z Twoim ostatnim, jeszcze
> niewprowadzonym wpisem z `changes_test.md` o **własnym task/run ID** — jeśli stan
> przestanie zależeć od `session_id`, sposób wykonania `/clear` (kto, kiedy, czym)
> robi się drugorzędny. Do rozstrzygnięcia przy tamtej iteracji.


został stworzony nowy katalo refactor-legacy-v2/etap1/
w tym katalogu będziemy tworzyć nową wersje harnessa,
na początek dzielimy etap 1 na kroki,
step 1 przygotowanie - analiza
    - w tym kroku wydzielimy z z oryginalnego pliku ktry znajduje się w tym katalogu etap analizy,
    - będzie to robił agent któ©y uruchomi się w modelu opus
    - na koniec zostanie wywołane sprawdzenie tego co zostało zrobione taki test akceptacyjny ale na razie nie impelemntuj tego tylko zaznacz sekcje quality gates
step 2 implementacja
    - to będzie wykonywał agent model sonet,
    - z poprzedniego kroku otrzyma instrukcje w formie pliku z konretynymi zmianami do zaimplemntownaia
    - na koniec tego kroku będzie również wywołany quality gate, tym razem będzie sprawdzanie czy środowisko się buduje, czy testy stworzone w implementacji są zielone,

Każdy z tych kroków będzie zapisywał logi, te kroki mogą działać wielokrotnie zależności od rozmiaru, zasięgu zmiany. jeżeli pojawi się błąd po kroku drugim typu że nie można zbudować na tę chwilę tę sekcja oznacz w budowie.
Działasz tylko z tym plikiem etap 1 który jest w katalogu refactor-legacy-v2, wynikiem końcowym będą dwa pliki step1 oraz step2, na razie część sekcji w tych plikach może być oznaczona w budowie , bo to co teraz robisz to na razie wstęp niczego po za tym na tę chwilę nie zmieniaj tylko ten jeden plik, to co zrealizowałem wpissz w tym pliku ponieżej tego tekstu

> ✅ **Wprowadzono** (2026-09-08) — nowe pliki `refactor-legacy-v2/etap1/step1.md`
> i `refactor-legacy-v2/etap1/step2.md`. Bez commita. Poza tymi dwoma plikami
> **nic nie zostało zmienione** — `refactor-legacy-v2/etap1/etap1.md` (źródło)
> i `refactor-legacy-v2/orkiestrator.md` zostają nietknięte, katalog
> `refactor-legacy/` (v1) też.
>
> **Podział**
>
> | | Step 1 | Step 2 |
> |---|---|---|
> | Nazwa | Przygotowanie (Analiza) | Implementacja |
> | Model | **opus** | **sonnet** |
> | Charakter | read-only wobec repozytorium | zapis: seam + testy |
> | Wejście | `payload.config` + `refactor-decisions.md` | `step1-analiza-N.md` |
> | Wyjście | `step1-analiza-N.md` | kod (seam) + testy + `stage.done` |
> | Brama | quality gate *(w budowie)* + `user.approval` | quality gate: build + zielone testy |
> | Log | `step1-log.md` | `step2-log.md` |
>
> **Step 1** — z oryginału przeniesiona cała Faza Analizy: ocena testowalności
> (z zatrzymaniem przy granulacji dynamicznej), identyfikacja zależności
> blokujących + typ seamu wg Feathersa, propozycja minimalnego odsprzęgnięcia,
> Opcje 1–4 na wypadek, gdy odsprzęgnięcie bez zmiany logiki jest niemożliwe.
> Dopisane: **kontrakt przekazania** — plik `step1-analiza-N.md` o 7 sekcjach,
> w tym nowe „Zmiany do zaimplementowania" (konkretne pozycje: co, w którym
> pliku, w jakiej kolejności) i „Poza zakresem" (czego Step 2 nie rusza).
> To jest jedyny wsad merytoryczny Step 2.
>
> **Step 2** — z oryginału przeniesiona Faza Implementacji (test charakteryzujący
> → seam → sprawdzenie przez użytkownika, z pytaniem o strategię seamu po
> pierwszej iteracji), tryb zadaniowy `task.execute`, sekcja „Mocki w testach",
> „Format wyjścia Etapu 1" i „Decyzje (rozstrzygnięte)". Dopisane wprost:
> Step 2 **nie dobiera strategii i nie rozszerza zakresu**; przy niekompletnym
> lub sprzecznym pliku wejściowym nie zgaduje, tylko wystawia `user.input`
> i iteracja wraca do Step 1.
>
> **Iteracyjność** — zachowana i przeniesiona na poziom kroków: cykl
> `Step 1 (N) → zatwierdzenie → Step 2 (N) → quality gate` powtarza się tyle
> razy, ile wymaga rozmiar i zasięg zmiany; dla małego fragmentu raz. Każdy
> krok prowadzi własny log, z nagłówkiem `### Iteracja N` i znacznikami
> `yyyy-MM-dd; HH-mm-ss` wczytywanymi z `refactor-decisions.md`.
>
> **Sekcje oznaczone *w budowie*** (zgodnie z poleceniem — zaznaczone, nie
> implementowane):
>
> 1. **Quality gate Step 1** (test akceptacyjny analizy) — wypisane, co zostaje
>    do rozstrzygnięcia: co jest sprawdzane, kto sprawdza, co przy wyniku
>    negatywnym, gdzie zapisywany werdykt. Do tego czasu bramą Step 1 pozostaje
>    zatwierdzenie użytkownika.
> 2. **Obsługa błędu quality gate Step 2** (nie buduje się / czerwone testy) —
>    do rozstrzygnięcia: samodzielna naprawa i limit prób, powrót do Step 1,
>    rollback, rozdzielenie ścieżki „błąd kompilacji" od „czerwony test", jaka
>    wiadomość idzie do orkiestratora. Na razie: odnotowanie w logu, zgłoszenie
>    użytkownikowi, zatrzymanie iteracji bez prób naprawy.
> 3. **Sposób przekazania sterowania Step 1 → Step 2** — czy Step 2 uruchamia
>    orkiestrator, czy Etap 1 jako sekwencja wewnętrzna. Zależy od tego, czy
>    kroki mają być widoczne dla orkiestratora jako osobne etapy.
> 4. **Przydział trybu zadaniowego** — `task.execute` trafił do Step 2 (to praca
>    na testach, nie analiza), ale nie przechodzi przez Step 1 i nie ma pliku
>    wejściowego; czy podlega quality gate Step 2, nierozstrzygnięte.
>
> **Kolizja wykryta przy okazji (odnotowana w `step2.md`, nierozstrzygnięta):**
> quality gate Step 2 wymaga zbudowania projektu, a wybór obowiązkowy z Pytania 0
> brzmi „brak buildów/kompilacji bez wyraźnej prośby użytkownika". Albo quality
> gate jest wyjątkiem od tej reguły, albo build wymaga zgody przy każdej
> iteracji — do Twojej decyzji.
>
> **Czego nie zrobiłem:** nie usunąłem ani nie zmieniłem `etap1.md` — jest
> źródłem podziału i zostawiam decyzję o jego losie Tobie. Nie ruszałem
> `orkiestrator.md` w v2, mimo że po tym podziale odwołuje się do struktury
> „Faza Analizy / Faza Implementacji", która w v2 nazywa się teraz Step 1 / Step 2.

Bierzemy się za orkiestratora,
Z powodu zmiany podejścia że nie będzie ręcznego clear-a wołanego przez usera i quality gate step2 to budowanie i uruchamianie testów to musimy zmienić konfiguracje która jest na początku, domyślne ustawienia dla konfiguracji będą zmienione na automatyczne budowanie i urchamianie testów, ale opcj może zostać zamieniona na ręczne wtedy quality gate będzie kroku drugiego będzie zarządzana przez usera,
Dodatkowo sam plik konfiguracji powinien być bardziej czytelny i ustrukturyzowany wydaje mi się że jsno był by lepszy jako konfiguracja, dzięki temu będziemy mieli standard zapisu kolejnych informacji, będzie mógł być ten plik rozbudowywany z zewnątrz oraz czytany przez wszystkie etapy tak samo.

Likwidujemy sekcje podstawa metodyczna z orkiestratora, ten atrybuty wskazujące agentowi jakimi zasadami ma się kierować, jaki kontekst autora ma wybierać, będzie przeniesiony do ospowiednie go etapu i kroku I tak etap 1 krok pierwszy to przygotowanie testów i kodu według zasad Feathersa,
Etap drugi to pewno Fowler ale tu zależy czy to będzie refaktor czy wprowadzanie zmian, bo refaktor to bym poszedł w strone Fowlera i Uncle Boba zasad clean archtecture, a wprowadzanie zmian to zasady solid, kiss, dry, yagni oraz zasady czystego kodu. Na razie tak bym to podzielił aczkolwiek na tę chwilę pracujemy nad etapem numer 1.

Co do uruchamiania każdy step czyli 1 i 2 na tę chwilę tylko te nie uruchamiają się nawzajem, komunikacja odbywa się za pomocą orkiestratora. Krok pierwszy wysyła jsona do orkiestratora w którym jest zawarta informacja że faza analziy się skończyła i quality gates przeszły pozytywnie, można uruchomić step2, ale orkiestrator dostaje tę inforacje od kroku 1, co stanowi zakończenie pracy agenta. W tym momencie orkiestrator wysyła tego samego jsona do kroku drugiego rozpoczynając tym samym pracę agenta kodujacego.
Dzięki temu izolujemy kroki od siebie, nie wiedzią o sobie nic, tylko o wynikach swoich zadań.
Orkiestrator decyduje czy uruchomić czy nie, etap i kroki etapu mogą się skupić tylko na swoich zadaniach.
Dodatkowo orkiestrator dostaje informacje od kroku pierwszego gdzie są pliki ze zmianami jak się nazywają i jak jest kolejnośc implementacji. To jest przekazywane do kroku drugiegi. Krok drugi raportuje co w jsonie czy zakończył i udało się przejść quality gate.

Na razie idziemy happy path.
Dodatkowo taka budowa pozwoli wprowadzić testy w łątwiejszy sposób ale testami na razie się nie zajmujemy.

Jeszcze jedna sprawa, iteracyjnośc, krok 1 oznacza w jsonie wysłanym do orkiestratora ile będzie iteracji, sam krok pierwszy ma swojego loga więc tam zapisuje wszystko co robi ale to orkiestrator musi wiedzieć ile jest przewidzianych eteracji oraz która jest aktualnie prowadzona. To na wypadek przerwania procesu, orkiestrator będzie go wznawiał nie etap czy tym bardziej krok który nie jest od tego.
implementuj

> ✅ **Wprowadzono** (2026-09-09) — `refactor-legacy-v2/orkiestrator.md`,
> `refactor-legacy-v2/etap1/step1.md`, `refactor-legacy-v2/etap1/step2.md`
> + nowy plik `refactor-legacy-v2/refactor-config.example.json`. Bez commita.
> Katalog `refactor-legacy/` (v1) i `refactor-legacy-v2/etap1/etap1.md`
> (źródło podziału) — nietknięte.
>
> **1. Konfiguracja: build i testy domyślnie automatyczne**
>
> Pytanie 0 miało dotąd jeden wybór „Build: brak buildów/kompilacji bez
> wyraźnej prośby użytkownika". Zastąpiony dwiema niezależnymi pozycjami:
> **`build`** (`automatyczny` domyślnie / `reczny`) i **`testy`**
> (`automatyczne` domyślnie / `reczne`). Reguła w obu ustawieniach:
>
> | Ustawienie | Kto wykonuje | Kto rozstrzyga quality gate Step 2 |
> |---|---|---|
> | automatyczny/-e | krok | krok, na podstawie faktycznego wyniku |
> | ręczny/-e | **użytkownik** | **użytkownik** — krok wystawia `user.input` z tym, co uruchomić, i przepisuje wynik bez własnej oceny |
>
> Ustawienie ręczne **nie znosi bramy** — zmienia tylko to, kto ją wykonuje.
> W wiadomości `step.done` każda pozycja bramy niesie `wykonal`:
> `krok` albo `uzytkownik`. Tym samym **zniknęła kolizja** odnotowana
> poprzednio w `step2.md` (build wymagany przez bramę vs. zakaz buildów) —
> ostrzeżenie usunięte, w jego miejsce sekcja „Kto wykonuje build i testy".
>
> **2. Konfiguracja w JSON zamiast markdown**
>
> `refactor-decisions.md` **przestaje istnieć**; zastępuje go
> **`refactor-config.json`** w katalogu wynikowym. Zaktualizowane wszystkie 18
> odwołań w v2 (orkiestrator, step1, step2). Struktura: `schema` +
> `schema_version`, `projekt`, `harness` (znacznik czasu, katalog wynikowy),
> `tryb`, `pytanie_0`, `pytanie_1`, `pytanie_2`; każda pozycja to obiekt
> `{ wartosc, zrodlo }`.
>
> - `zrodlo` (`uzytkownik` / `flaga` / `wykryte+potwierdzone` / `domyslne`)
>   przejmuje rolę dotychczasowego logu decyzji — pozycja z Pytań 0–2 nie może
>   mieć `domyslne`, wymóg jawnego wyboru zostaje.
> - Nieznane pole nie jest błędem (rozszerzalność z zewnątrz);
>   `schema_version` rośnie tylko przy zmianie znaczenia istniejących pól.
> - Kontrola integralności porównuje teraz **strukturalnie, pole po polu** —
>   samo przeformatowanie pliku nie jest już rozjazdem.
> - Powstał szablon `refactor-config.example.json` z kompletem pól i
>   wartościami dopuszczalnymi (`_dozwolone`, `_domyslne` — pola z
>   podkreśleniem są dokumentacją szablonu, harness ich nie czyta).
>
> **3. Podstawa metodyczna — usunięta z orkiestratora**
>
> Sekcja „Podstawa metodyczna" skasowana w całości. W jej miejsce w
> orkiestratorze zostaje jedno zdanie: orkiestrator **nie zna, nie przekazuje
> i nie egzekwuje** żadnej podstawy metodycznej. Treść przeniesiona do kroków:
>
> - `step1.md` → „Podstawa metodyczna kroku": **Feathers** — seam, test
>   charakteryzujący (zachowanie aktualne, nie poprawne), najmniejsza możliwa
>   zmiana. Wprost wypisane, czego krok **nie** stosuje (Fowler, clean
>   code/architecture, SOLID/KISS/DRY/YAGNI).
> - `step2.md` → ten sam fundament w wersji wykonawczej: behavior-preserving,
>   najmniejszy krok, **kryterium zakończenia to test, nie estetyka kodu** —
>   brzydka nazwa czy długa metoda obok zostają, obserwacja idzie do logu,
>   nie do kodu.
>
> Twój podział dla dalszych etapów (Etap 2: refaktor → Fowler + clean
> architecture Uncle Boba; wprowadzanie zmian → SOLID, KISS, DRY, YAGNI,
> czysty kod) **nie ma gdzie trafić** — w v2 nie istnieje jeszcze plik Etapu 2.
> Zostaje zapisany tutaj i wpiszę go do `etap2.md` przy pracy nad tamtym
> etapem.
>
> **4. Kroki jako jednostki sterowania — komunikacja tylko przez orkiestratora**
>
> Nowa sekcja w orkiestratorze: „Kroki Etapu 1 jako jednostki sterowania".
> Kroki dostały **adresy w protokole** (`etap1.step1`, `etap1.step2`) i dwie
> nowe akcje: `step.start` (orkiestrator → krok) i `step.done` (krok →
> orkiestrator). Krok **nigdy** nie adresuje drugiego kroku — w polu `to`
> zawsze stoi `orkiestrator`.
>
> Przebieg jednej iteracji:
>
> 1. Step 1 kończy analizę → wysyła `step.done`. **To jest koniec pracy
>    agenta** — nie czeka, nie uruchamia Step 2.
> 2. Orkiestrator sprawdza bramę, zapisuje stan, **decyduje** o uruchomieniu.
> 3. `step.start` → `etap1.step2` z **tym samym payloadem** + `config`.
>    To rozpoczyna pracę agenta kodującego.
> 4. Step 2 raportuje `step.done`: `ukonczono` + wynik quality gate.
> 5. Orkiestrator rozstrzyga: kolejna iteracja albo zamknięcie Etapu 1.
>
> Payload Step 1 niesie to, o co prosiłeś: `pliki[]` (**gdzie leżą pliki ze
> zmianami i jak się nazywają** — `nazwa`, `sciezka`, `kolejnosc`) oraz
> `kolejnosc_implementacji`. Orkiestrator nie interpretuje go merytorycznie —
> przekazuje w całości, czyta tylko licznik iteracji, listę plików i wynik
> bramy. Komplet trzech wiadomości JSON opisany w orkiestratorze („Przekazanie
> między krokami Etapu 1") i powtórzony po stronie każdego kroku w sekcji
> „Zakończenie kroku".
>
> Dodane też **bramy kroków** (wejściowa i wyjściowa) — m.in. Step 2 nie
> wystartuje, dopóki pliki wymienione w `payload.pliki` nie istnieją na dysku
> i nie ma zatwierdzenia użytkownika.
>
> Tym samym **rozstrzygnięta została jedna z sekcji *w budowie*** ze
> `step1.md`: „sposób przekazania sterowania Step 1 → Step 2" — przez
> orkiestratora, kroki nie widzą się nawzajem.
>
> **5. Iteracyjność i wznawianie**
>
> - Step 1 deklaruje w `step.done` pole `iteracje`: `zaplanowane`, `biezaca`,
>   `podstawa_szacunku`. Deklaracja jest szacunkiem i może być skorygowana
>   w kolejnej iteracji — orkiestrator bierze wartość z najnowszej wiadomości
>   i odnotowuje korektę w logu.
> - **Licznik jest własnością orkiestratora**, nie kroku. `refactor-session.md`
>   dostał cztery nowe pola: `Etap w toku`, `Krok w toku`,
>   `Iteracja: <biezaca> z <zaplanowanych>`, `Ostatnia zamknięta jednostka`.
>   Aktualizowane po każdej zamkniętej jednostce sterowania.
> - **Wznawia wyłącznie orkiestrator** — z `refactor-session.md` i wiadomości
>   w `komunikacja/`. Ani etap, ani krok nie wznawia się sam; agent kroku
>   dostaje numer iteracji w payloadzie i **nie dedukuje go z własnego logu**
>   (log kroku zostaje pełnym zapisem tego, co krok robił, ale nie jest
>   źródłem stanu procesu).
> - Pętla sterowania orkiestratora dostała podpunkty 4a–4d: pętla kroków
>   Etapu 1 z licznikiem iteracji. Log orkiestratora ma teraz obowiązkowo
>   odnotowywać numer iteracji, zadeklarowaną liczbę iteracji i jej korekty,
>   listę plików przekazanych do Step 2 i wynik quality gate każdego kroku
>   z rozbiciem build/testy + kto wykonał.
>
> **6. Happy path — zaznaczony wprost**
>
> W „Statusie dokumentu" dopisane, że opisany jest wyłącznie przebieg udany.
> Ścieżki błędu zostają *w budowie*: obsługa nieudanego quality gate Step 2,
> powrót iteracji do Step 1, korekta liczby iteracji w dół. Testy harnessu —
> poza zakresem tej iteracji; odnotowane tylko tyle, że wymiana krok↔krok jest
> pojedynczym plikiem JSON, więc daje się podstawić mockiem (tryb `test`
> dostał wiersz o mockowaniu kroków).
>
> **Nadal *w budowie* po tej zmianie:** quality gate Step 1 (bramą pozostaje
> zatwierdzenie użytkownika; w `step.done` pole ma wtedy wartość
> `nie_wykonany` z powodem — pole jest obecne zawsze), obsługa błędu quality
> gate Step 2, przydział trybu `task.execute` do bramy Step 2.
>
> **Czego nie zmieniałem:** `etap1.md` w v2 (źródło podziału), `refactor-legacy/`
> (v1) — tam nadal obowiązuje `refactor-decisions.md` i stara reguła buildów.
> Jeśli v1 ma zostać wygaszony, to osobna decyzja.
