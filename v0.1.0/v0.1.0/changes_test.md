 
rozbudowujemy opcje test dla orkiestratora, będzie to piewrszy poziom z mojej piramidy testów harnesa czyli test orkiestratora w izolacji. Izolacja będzie polegać na wykonywaniu poszczególnych etapów poprzez wstawienie mocków czyli wcześniej przygotowanych json-owych odpowiedzi z procesu,

zabadaj orkiestraota pod kątem możliwości uruchomiania go w trybie test,

---

> 🔍 **Badanie: orkiestrator w trybie `test` (izolacja przez mocki)** (2026-08-31)
> — analiza, **żaden plik harnessu nie został zmieniony**.
>
> **A. Co już jest i nadaje się na seam**
>
> 1. **Protokół JSON jest jedynym stykiem orkiestrator ↔ etapy** (`orkiestrator.md`, sekcja "Protokół komunikacji", linie 436–558). Orkiestrator wysyła wyłącznie 4 akcje (`stage.start`, `task.execute`, `stage.resume`, `stage.abort`) i przyjmuje wyłącznie wiadomości z katalogu akcji etapów. To jest gotowy, wąski szew: **mock = plik JSON podstawiony w miejsce odpowiedzi etapu**, bez dotykania logiki orkiestratora.
> 2. **Etap 0 też idzie protokołem** (`stage.start` → `payload.report`, `etap0.md` sekcja "Wyjście — raport JSON"). Nie jest przypadkiem szczególnym — mockuje się tak samo jak etapy 1–3, a jego raport to najbogatszy wsad testowy (6 wierszy tabeli "Interpretacja raportu" = 6 gotowych przypadków testowych).
> 3. **Zapis wiadomości do `komunikacja/<NNN>-<from>-<action>.json`** (linia 553) + **log orkiestratora z wynikiem każdej bramy** (linia 606) dają **gotowy ślad wykonania (trace)**. To jest materiał, na którym system ocenny może asertować, bez dokładania nowego mechanizmu logowania. Praktycznie: oczekiwany przebieg = oczekiwana sekwencja wiadomości + oczekiwane werdykty bram.
> 4. **Etapy nie wołają się nawzajem** (linia 57–59) — całe sterowanie przechodzi przez orkiestratora, więc podstawienie mocków na styku etapów odcina *całą* merytorykę. Izolacja jest osiągalna bez przebudowy architektury.
>
> **B. Co zostaje przedmiotem testu (tego nie wolno mockować)**
>
> Wszystko, co orkiestrator robi sam, bez wysyłania wiadomości: reguła 10 minut, interpretacja raportu Etapu 0, Pytania 0–2 i zapis `refactor-decisions.md`, snapshot w pamięci, ustalenie kolejki etapów z Pytania 2, **brama wejściowa (6 warunków, 0–5)**, routing przychodzących requestów (pkt 4 pętli sterowania), **brama wyjściowa (5 warunków)**, kontrola integralności, wpisy do `orkiestrator-log.md`.
>
> **C. Przeszkody wykryte w obecnym opisie (rzeczy do rozstrzygnięcia przed implementacją)**
>
> 1. **Istniejąca sekcja "Flaga trybu testowego (`test`)" (linie 635–648) jest nie tylko szkicem — jest sprzeczna z izolacją.** Mówi: „Wyjście z Etapu 1 domyślnie przyjmuje wynik »sukces«". To zakłada, że etap **faktycznie się wykonuje**, a tylko jego werdykt jest podmieniany. Przy izolacji przez mocki etap **w ogóle nie startuje**, a wynik (sukces / `failed` / `needs_user` / `error.critical`) bierze się z pliku mocka — i to jest istotne, bo **testy negatywne bram wymagają umiejętności podania porażki**. Ten punkt trzeba zastąpić, nie rozbudować.
> 2. **Flaga nie ma zdefiniowanego wejścia ani miejsca w konfiguracji.** Nie wynika z Pytań 0–2, nie ma jej w `refactor-decisions.md`, więc nie trafia do etapów w `payload.config` i **nie podlega kontroli integralności**. Do ustalenia: jak jest podawana (argument wywołania skilla? osobne pytanie przed Pytaniem 0?) i czy ląduje w logu decyzji.
> 3. **Brama wyjściowa wymaga artefaktów, których mock nie wytwarza.** Warunki 1–2 („powstał plik wynikowy", „log etapu istnieje, jest niepusty i chronologiczny") czytają realne pliki na dysku. Zmockowany etap nie napisze `etap1-plan.md` ani `etap1-decisions-log.md` → **każda brama wyjściowa poleci na false**, i to nie dlatego, że orkiestrator ma błąd. To jest **centralny problem konstrukcyjny** trybu test. Dwie drogi:
>    - **(a) mock = paczka**: odpowiedź JSON **plus** komplet plików, które etap by wytworzył. Brama działa nietknięta i jest **naprawdę testowana** (możemy podać paczkę celowo niekompletną i sprawdzić, czy brama to złapie). Droższe w przygotowaniu.
>    - **(b) mock = sama odpowiedź**, a brama w trybie test sprawdza deklarację z payloadu zamiast dysku. Tańsze, ale **brama przestaje być testowana** — testujemy atrapę bramy.
>    Rekomendacja: **(a)**. Cel pierwszego poziomu piramidy to sprawdzenie, czy orkiestrator pilnuje — a pilnowanie to głównie bramy.
> 4. **`/clear` w kroku 0 pętli sterowania przecina test na pół.** Automatyczny przebieg testowy nie przeżyje wyczyszczenia kontekstu, a wariant ręczny wymaga człowieka w środku. Do rozstrzygnięcia: czy w trybie test `/clear` jest pomijany (wtedy **nie testujemy** zabezpieczenia przed zapętleniem — a to jedno z ważniejszych miejsc), czy scenariusz dzieli się na dwa przebiegi (przed i po `/clear`), gdzie drugi startuje z podstawionego `refactor-session.md`. Skłaniam się do **dwóch przebiegów** — reguła 10 minut daje się wtedy przetestować w obie strony.
> 5. **Zegar jest niesterowalny.** Reguła 10 minut i znaczniki czasu biorą się z realnego czasu. Żeby przetestować obie gałęzie (`< 10 min` i `≥ 10 min`) bez czekania, potrzebny jest albo czas wstrzykiwany w trybie test, albo `refactor-session.md` przygotowany z zadanym znacznikiem (to drugie wystarcza i nic nie kosztuje).
> 6. **Interakcje z użytkownikiem nie są zmockowane.** Pytania 0–2, potwierdzenie wznowienia, akceptacje między etapami, obsługa `user.approval` / `user.input` — bez podstawienia odpowiedzi użytkownika przebieg testowy nie jest automatyczny. Twój opis mówi o mockach „odpowiedzi z procesu"; **do potwierdzenia, czy mockujemy też ścieżkę użytkownika** (moim zdaniem tak — inaczej każdy przebieg wymaga ręcznego klikania i przestaje być powtarzalny).
> 7. **Przebieg testowy zabrudzi katalog wynikowy.** Orkiestrator pisze do `refactor-legacy` / `refactor-legacy-verN` w katalogu projektu i **nigdy nie nadpisuje** istniejącego (linie 382–401). Skutek uboczny: każdy przebieg testowy tworzy kolejną wersję katalogu, a **Etap 0 w kolejnym prawdziwym uruchomieniu wykryje sesje testowe jako prawdziwe**. Potrzebny osobny katalog dla trybu test (np. `refactor-legacy-test-<znacznik>`) i zasada, że Etap 0 go pomija.
> 8. **Brak zdefiniowanego adresowania mocków.** Trzeba ustalić klucz: po czym orkiestrator wybiera, którym plikiem odpowiedzieć na dany `dispatch` (para `to` + `action`? kolejność w scenariuszu? `corr_id`?). Oraz — **co się dzieje przy braku mocka**: musi to być twardy błąd scenariusza, nigdy ciche zejście do prawdziwego etapu, bo wtedy test przestaje być testem w izolacji.
> 9. **Warunek 5 bramy wejściowej dotyka pliku etapu** („plik etapu istnieje i nie jest pusty" — dziś dotyczy pustego `etap3.md`). W trybie test plik etapu nie jest wczytywany, ale warunek nadal go czyta. Do rozstrzygnięcia: czy sprawdzamy realny plik (wtedy pusty Etap 3 daje darmowy przypadek testowy na `error.critical`), czy scenariusz może go podmienić.
> 10. **Brak pojęcia werdyktu.** Orkiestrator nie zna dziś niczego w rodzaju „przebieg oczekiwany vs. faktyczny" ani pliku z wynikiem oceny. To jest do dopisania jako element systemu ocennego — ale dopiero po rozstrzygnięciu punktów wyżej.
>
> **D. Wniosek**
>
> Orkiestrator **nadaje się** do uruchamiania w izolacji — protokół JSON i zapis `komunikacja/` to szew wystarczająco czysty, żeby podstawić mocki bez przebudowy. Realna praca leży nie w „podłączeniu mocków", tylko w trzech miejscach: **artefakty dla bramy wyjściowej (pkt C3)**, **`/clear` (pkt C4)** i **izolacja katalogu wynikowego (pkt C7)**. Obecna sekcja o fladze `test` jest do napisania od nowa.
>
> **Do Twojej decyzji przed implementacją:** C3 (a czy b), C4 (pominięcie `/clear` czy dwa przebiegi), C6 (mockujemy odpowiedzi użytkownika czy nie), C7 (nazwa i zasada osobnego katalogu testowego).

To żeby to miało ręcę i nogi to przebudujemy trochę orkiestratora po pierwsze wyniki w normalnym trybie będą zapisywane w katalogu refactor-resultN gdzie N będzie kolejną liczbą zaczynamy od 1 czyli dla każdego kolejnego uruchomienia wartość będzie inkrementowana dzięki temu będziemy widzieć że wcześniej były już jakies próby uruchomienia orkiestratora,
Dla trybu testowewgo będzie katalog nazywał się inaczej result-testN i analogicznie N będzie kolejna wersją uruchomienia testu.
Czyli na początku po sprawdzeniu czy etap 0 był uruchomiony będzie weryfikacja wersji resultatu, czyli np jeżeli etap 0 znajdzie już dwie wersje 1 i 2 to orkiestrator kolejną nazwie refactor-result3, będzie szukał tylko takich katalogów, jeżeli będzie tryb testowy to tryb testowy będzie szukał katalogów z dopiskeim test i każde kolejne uruchomienie będzie inkrementować rezultaty.

odp1. To trzeba zmienić flaga testowa ma zadanie przełączyć orkiestrator w tryb testu czyli działa on normalnie ale etapy nie są wykonywane w normalny sposób tylko podstawiane pliki json z przygotowanymi wcześniej wynikami, to będą nasze mocki,

odp2. Trzeba dodać do orkiestratora pytanie o tryb testowy albo normalny, na razie nie przychodzi mi nic dogłowy mówiąc o nazwie trybu nietestowego, może coś się wymyśli ale ogólnie trzeba to określić jako część konfiguracji co jest istotne bo etapy działają w izolacji i konfiguracja zawsze jest im podawana przez plik.

odp3.Tu również myśle że twoja odpowiedz a jest słusznym podejście te testowanie ma być zbliżone do realnego działania więc wszystkie pliki będą musiały powstać, wymagane pliki, a jedynie ich zawartość będzie świadczyć że to test, będzie w jakiś sposób sztucznie przygotoana aczkolwiek na tym etapie nie jest to właściwe żeby rozstrzygać takie rzeczy na razie przygotujemy środowiko do testów,

odp4. Do tego wrócimy jeszcze, muszę sie zastanowić jak ten test będzie wyglądać, na razie bym w teście oznaczył że /clear został wykonany, i nie trzeba sprawdzać etapu 0,

odp5. Sądze że testy które będą sprawdzać dane które pojawiają się z zewnątrz tak będą wygladać czyli jak przejdzeiemy do test casów to wtedy będziemy doszczegółowiać co będzie wpisywane i gdzie, ten puntk również oznacz że zajmiemy się w przyszłości,

odp6. Na razie nie będzie interakcja użytkownika mockowana, nie w tym etapie, w póżniejszych zapewne ale nie teraz,

odp7. Na to odpowiedziałem na wstępie wieć z tym nie będzie problemu,

odp8.Nie moze braknąć mocka sądzę że będziemy musieli napisć orkiestratora do testów, czyli takiego który będzie bazował na właściwym ale ze względu na nie zaśmiecanie tego właściwego będzie trzymał instrukcje dotyczące testów, nie wiem czy to właściwe podejście ale w tym przypadki wydaje mi się sensowne pod kątem utrzymania porządku i nie przenikania środowiska testowego z "produkcyjnym", ale to zostawiamy na kolejną iteracje, nie teraz, oznacz to do przyszłej iteracji,

odp9.Etap 3 na razie pomijamy, on nie jest gotowy, w testach zawsze może być na true, na razie póki go nie zrobimy,

odp10.tego też jeszcze nie wiem, wieć zostawmy to do przyszłej iteracji, na razie badanie rezultatu będzie należało do człowieka i to on decyduje o tym czy się powiodło czy nie

---

> ❓ **Pytania uzupełniające przed implementacją** (2026-08-31)
> — nadal **żaden plik harnessu nie zmieniony**. Najpierw domykam wątpliwości, tak jak prosiłeś.
>
> **Co przyjmuję za ustalone** (poprawi mnie, jeśli źle czytam):
> U1. Katalogi wynikowe: tryb normalny `refactor-resultN`, tryb testowy z dopiskiem `test`; `N` inkrementowane, każde uruchomienie widoczne jako osobna wersja; orkiestrator szuka **wyłącznie** katalogów pasujących do bieżącego trybu. `N` liczę jako **największy znaleziony + 1** (nie „liczba katalogów") — usunięcie `...2` nie powoduje ponownego użycia numeru.
> U2. Flaga `test` nie podmienia werdyktu etapu — **przełącza sposób wykonania etapu**: orkiestrator działa normalnie, ale zamiast uruchomić etap, podstawia przygotowany wcześniej JSON.
> U3. Tryb jest **częścią konfiguracji** zapisywanej w `refactor-decisions.md` (etapy dostają go z pliku, jak resztę). Zmiana trybu w trakcie przebiegu = rozjazd ze snapshotem = CRITICAL ERROR, jak każda inna pozycja konfiguracji.
> U4. Mock = wariant **(a)**: powstają wszystkie wymagane pliki, sztuczna jest tylko ich treść. Bramy działają nietknięte.
> U5. W trybie test `/clear` jest **oznaczany jako wykonany**, a Etap 0 nie jest weryfikowany (wracamy do tego przy projektowaniu test case'ów).
> U6. Interakcja z użytkownikiem **nie jest mockowana** w tej iteracji.
> U7. Tryb test prowadzi te same logi i ten sam zapis `komunikacja/*.json` co tryb normalny — to jest ślad, który człowiek ocenia (C10).
> U8. Odłożone do przyszłych iteracji: **C5** (sterowanie czasem / dane wejściowe test case'ów), **C8** (osobny orkiestrator testowy), **C10** (werdykt — na razie ocenia człowiek).
>
> **Pytania:**
>
> **P1. Dokładna nazwa katalogu testowego.** Napisałeś raz `result-testN`, a katalog normalny to `refactor-resultN`. Czy testowy to `refactor-result-test1` (spójny przedrostek, jedna reguła wyszukiwania: `refactor-result` + opcjonalne `-test` + numer) — **rekomendacja** — czy dosłownie `result-test1` bez przedrostka?
>
> **P2. Los starego nazewnictwa.** Dziś w dokumentach jest `refactor-legacy` / `refactor-legacy-verN` (m.in. w zakresie przeszukania Etapu 0). Kasuję to całkowicie na rzecz nowego schematu — **rekomendacja**, harness nie jest jeszcze używany na produkcji — czy Etap 0 ma nadal **rozpoznawać** stare katalogi (kompatybilność wsteczna)?
>
> **P3. Wznowienie a inkrementacja — to jest realny konflikt.** „Każde kolejne uruchomienie inkrementuje" kłóci się z wznowieniem przerwanej sesji: jeśli wznawiam Etap 2 z `refactor-result2`, to gdzie piszę?
>    - (a) **Wznowienie kontynuuje w katalogu wznawianej sesji** (bez inkrementacji); numer rośnie tylko przy nowej sesji. Stan sesji zostaje w jednym miejscu — **rekomendacja**.
>    - (b) Zawsze nowy katalog `N+1`, a stan wznawianej sesji jest do niego **kopiowany** na start. Każde uruchomienie widoczne osobno, ale historia jednej sesji rozjeżdża się po katalogach.
>
> **P4. Skąd bierze się tryb i kiedy — to jest kolejność, która się dziś nie spina.** Etap 0 szuka katalogów zależnych od trybu (`...` vs `...-test`), więc tryb **musi być znany przed Etapem 0**. Ale pytania konfiguracyjne padają **po** Etapie 0. Propozycja: tryb rozstrzygany **jako pierwsza czynność, przed Etapem 0** — jeśli podano flagę `test`, to ona decyduje; jeśli nie podano nic, orkiestrator **pyta**; wynik trafia potem do `refactor-decisions.md` razem z resztą konfiguracji. **Rekomendacja.** Akceptujesz, czy tryb ma być wyłącznie flagą (bez pytania), albo wyłącznie pytaniem (bez flagi)?
>
> **P5. Gdzie w konfiguracji ląduje pytanie o tryb.** Renumerowanie Pytań 0–2 na 0–3 pociąga zmiany w schemacie raportu Etapu 0 (`pytanie_0/1/2`) i w `refactor-decisions.md`. Proponuję **osobne „Pytanie T — Tryb uruchomienia"** zadawane przed Pytaniem 0, numeracja 0–2 bez zmian, raport Etapu 0 dostaje pole `tryb`. **Rekomendacja.** Czy wolisz jednak pełne przenumerowanie?
>
> **P6. Nazwa trybu nietestowego.** Propozycje: `normalny` / `roboczy` / `produkcyjny` / `praca`. **Rekomendacja: `normalny`** (wartości w konfiguracji: `normalny` | `test`) — najbliżej tego, jak sam o tym piszesz.
>
> **P7. Etap 0 w trybie testowym.** „Nie trzeba sprawdzać etapu 0" rozumiem dwojako i muszę wiedzieć, jak:
>    - Etap 0 **też jest mockowany** (podstawiony `etap0-raport.json`, jak każdy inny etap), a warunek 0 bramy wejściowej („Etap 0 wykonany w bieżącym przebiegu") przechodzi automatycznie — **rekomendacja**, spójne z U2;
>    - czy Etap 0 **wykonuje się naprawdę** (jako jedyny), a pomijane jest tylko sprawdzanie warunku 0?
>
> **P8. Gdzie fizycznie żyją mocki i gdzie powstaje katalog testowy.** Skoro każdy przebieg tworzy nowy `...-testN`, mocki **nie mogą** mieszkać w katalogu przebiegu (trzeba by je kopiować przed każdym uruchomieniem). Propozycja: mocki w osobnym, stałym katalogu (np. `mocki/`, wskazywanym na starcie), kopiowane do katalogu przebiegu **po użyciu**, jako ślad audytowy. Druga część pytania: tryb testowy nie ma realnego projektu do refaktoryzacji — katalog `...-testN` powstaje w katalogu roboczym harnessu, czy we wskazanym projekcie-atrapie? **Rekomendacja:** mocki w stałym `mocki/`, katalog przebiegu w katalogu roboczym harnessu.
>
> **P9. Zakres tej iteracji.** Czytam „na razie przygotujemy środowisko do testów" jako: **przebudowa orkiestratora** (katalogi `refactor-resultN` / `...-testN`, pytanie o tryb, nowa semantyka flagi `test`, pominięcia z odp4/odp9, oznaczenie punktów odłożonych), **bez** definiowania formatu i katalogu mocków oraz **bez** osobnego orkiestratora testowego (odp8). Potwierdzasz ten zakres?
>
> **P10. „Etap 3 zawsze na true".** Rozumiem to jako: **tylko w trybie test** warunek 5 bramy wejściowej (plik etapu istnieje i nie jest pusty) przechodzi dla Etapu 3; w trybie normalnym zostaje `error.critical`, jak dziś. **Rekomendacja.** Czy raczej Etap 3 ma być w trybie test **w ogóle wyłączony z kolejki**?

odpowiedzi

- tryb będzie wybierany jako pierwszy przed etapem 0, to ma większy sens,
- test etapu 0 będzie musiał być osobnym testem, będzie raczej rozbity na dwa, czyli test samego etapu oraz test orkiestratora który dostanie tylko jsona z przygotowanym wynikiem, pytanie czy w tym momencie musimy testować etapy? nie to jest kolejna część mojej piramidy testów czyli testowanie etapów, na razie orkiestrator czyli etap 0 jest uruchamiany jako mock a orkiestrator oczekuje przygotowanego jsona,
-tu masz racje z tym wznowieniem i numerowaniem ale numerowanie będzie dostpne jeżlie etap 0 nie znajdzie poprzedniej sesji czyli zaczyna nową, jeżeli znajdzie to kontynuuje starą ale tu misimy powiększyć limit czasowy do conajmniej godziny, bo z piewrszych testów wynikło że przejście przez całość trwa długo, sądze że docelowo powstanie dodatkowy plik json z dedykowaną konfiguracją harnesa, co w przyszłości będzie mogło zastąpić pytania wstępne, ale to zapisz to do przysżłej implemnetacji na razie orkiestrator się pyta a my podnosimy czas do 60 minut,
- tak jak pisałem etap 0 nie wykonuje się naprawde na razie nie,
- dokładna nazwa to dla testu refactor-result-testN idziemy w twoim torem wydaje się lepszy, dla normalnego wykonaia nie będzie dopisku -test


---

> ✅ **Zmiany wprowadzone** (2026-08-31) — `orkiestrator.md`, `etap0.md`, `etap3.md`. Bez commita.
>
> **Doprecyzowane przed implementacją** (trzy pytania bez odpowiedzi w Twoich wpisach, potwierdzone w rozmowie): stare nazewnictwo `refactor-legacy` / `-verN` **usunięte całkowicie**, bez kompatybilności wstecznej; tryb nietestowy nazywa się **`normalny`**; katalog przebiegu testowego powstaje **w katalogu projektu**, tak jak normalny — różni się tylko nazwą.
>
> **Co zostało zmienione**
>
> 1. **Katalogi wynikowe — nowy schemat** (`orkiestrator.md`, sekcja "Katalog wynikowy", przepisana w całości). `refactor-resultN` dla trybu `normalny`, `refactor-result-testN` dla trybu `test`. Numer = **największy znaleziony + 1** (nie liczba katalogów). Orkiestrator widzi **wyłącznie katalogi bieżącego trybu** — rozdział szczelny w obie strony, więc przebieg testowy nigdy nie zostanie wzięty za prawdziwą sesję. Zapisana kolejność: tryb → Etap 0 → decyzja nowa sesja / wznowienie → dopiero wtedy numer katalogu.
> 2. **Wznowienie nie inkrementuje numeru** (P3, Twoja odpowiedź). Wznowienie kontynuuje w katalogu wznawianej sesji; numer rośnie tylko przy nowej sesji. Dopisane w "Interpretacja raportu" i w "Katalog wynikowy".
> 3. **Reguła 10 minut → reguła 60 minut**, w komplecie (przebieg Etapu 0, wyjątek bramy wejściowej, pętla sterowania, log orkiestratora, przykład logu) wraz z uzasadnieniem, że przejście przez cały harness trwa długo.
> 4. **Nowa sekcja "Tryb uruchomienia (`normalny` / `test`)"**, umieszczona **przed** "Etap 0 i wznowienie sesji" — bo tryb jest ustalany najwcześniej. Zawiera **Pytanie T**: flaga `test` rozstrzyga bez pytania, brak flagi → orkiestrator pyta, trybu domyślnego po cichu nie ma. Numeracja Pytań 0–2 **bez zmian** — Pytanie T stoi poza nią.
> 5. **Tryb jest pozycją konfiguracji, nie przełącznikiem lokalnym**: trafia do `refactor-decisions.md` (nowa sekcja w przykładzie), do snapshotu w pamięci, do `payload.config` (`"tryb"`, dopisany w przykładzie dispatchu i w katalogu akcji) i do raportu Etapu 0 (pole `tryb`). **Podlega kontroli integralności** — zmiana trybu w trakcie = CRITICAL ERROR.
> 6. **Sekcja "Flaga trybu testowego" napisana od nowa** jako "Tryb testowy (`test`)". Usunięte zdanie o domyślnym „sukcesie" z Etapu 1 — werdykt bierze się z treści mocka (`done` / `failed` / `needs_user` / `error.critical`), inaczej nie da się testować negatywnych ścieżek bram. Opisane: izolacja (podmieniony jest **tylko sposób wykonania etapu**), **mock = paczka** (JSON + komplet plików, które etap by wytworzył — bramy działają nietknięte), **brak mocka = twardy błąd** bez cichego zejścia do prawdziwego etapu, tabela odstępstw obowiązujących wyłącznie w trybie test, ocena przez człowieka.
> 7. **Etap 0 mockowany w trybie test** — nie wykonuje się naprawdę, orkiestrator dostaje przygotowany `etap0-raport.json`. Odnotowane w `orkiestrator.md` i w `etap0.md` ("Kto wykonuje"), z zastrzeżeniem, że test samego Etapu 0 to kolejny poziom piramidy.
> 8. **`/clear` w trybie test** — oznaczany jako wykonany w `refactor-session.md` i w logu, kontekst nieczyszczony. Plik stanu sesji dostał wartość `tak (tryb test — oznaczone, kontekst nieczyszczony)` oraz pola `Tryb uruchomienia` i `Katalog wynikowy`.
> 9. **Etap 3 w trybie test** — warunek 5 bramy wejściowej przechodzi zawsze, dopóki `etap3.md` jest pusty (w trybie `normalny` bez zmian: `error.critical`). Zapisane w bramie wejściowej i w `etap3.md`.
> 10. **Zakres przeszukania Etapu 0** przepisany na tabelę zależną od trybu; przykład raportu JSON zaktualizowany (`refactor-result1/2`, pole `numer` zamiast `wersja`, pole `tryb`), z zastrzeżeniem, że Etap 0 sam niczego nie numeruje ani nie tworzy.
> 11. **Pętla sterowania** — nowy krok 0 (ustalenie trybu), renumeracja kroków 1–7, odwołania wewnętrzne poprawione. **Log orkiestratora** odnotowuje wybór trybu, katalog wynikowy, a w trybie test także **który mock trafił pod który dispatch**.
>
> **Czego świadomie nie zrobiłem** (Twoje „to na później"):
>
> - **Format i adresowanie mocków** oraz ich katalog (odp8 / P8) — wypisane w sekcji "Odłożone do kolejnych iteracji". Zapisana jest tylko zasada „brak mocka = twardy błąd".
> - **Osobny orkiestrator testowy** (odp8) — odłożony, ten plik pozostaje jeden.
> - **Sterowanie czasem i dane wejściowe test case'ów** (odp5) — odłożone.
> - **Mockowanie interakcji użytkownika** (odp6) — odłożone; w tabeli odstępstw stoi wprost, że obsługuje ją człowiek.
> - **System ocenny / werdykt** (odp10) — odłożony; zapisane, że przebieg ocenia człowiek na podstawie logu i `komunikacja/*.json`.
> - **Plik JSON z konfiguracją harnessu** zastępujący pytania wstępne — dopisany do listy odłożonych, zgodnie z Twoją uwagą.
> - **Etapy 1 i 2 nietknięte** — nic w nich nie wymagało zmiany (odwołują się do "Katalogu wynikowego" przez nazwę sekcji, nie przez nazwę katalogu).
>
> **Gdzie widzę wątpliwości do rozstrzygnięcia później**
>
> - **Tryb w `refactor-decisions.md` a wznowienie.** Przy wznowieniu konfiguracja z pliku staje się snapshotem — jeśli ktoś wznowi sesję testową w trybie normalnym (albo odwrotnie), dostanie CRITICAL ERROR z kontroli integralności. To zachowanie **zamierzone**, ale w praktyce Etap 0 i tak nie znajdzie tej sesji, bo szuka tylko katalogów swojego trybu. Czyli realnie ten konflikt jest nieosiągalny — zostawiam obie bariery, ale warto o tym pamiętać przy pisaniu test case'ów.
> - **Kto tworzy paczkę mocka.** Zapisałem, że mock zawiera pliki, które etap by wytworzył, ale nie rozstrzygnąłem, czy podkłada je scenariusz przed przebiegiem, czy orkiestrator kopiuje je z katalogu mocków w momencie podstawienia. To zależy od formatu mocków (odłożonego), więc celowo nie przesądzam.
> - **Reguła 60 minut w trybie test.** Zostawiłem ją działającą bez zmian (jest przedmiotem testu), ale przy przebiegu ręcznym rozłożonym w czasie może niechcący uznać przebieg za nową sesję. To wróci przy C5 (sterowanie czasem).
> - **Numer katalogu przy pierwszym uruchomieniu Etapu 0.** Gdy nie ma żadnego katalogu, orkiestrator tworzy `refactor-result1` tylko po to, żeby zapisać `etap0-raport.json` — a potem może się okazać, że użytkownik zaczyna nową sesję. Wtedy `1` jest już zajęte przez katalog powstały „na potrzebę Etapu 0". Zapisałem to zgodnie z dotychczasową logiką (pliki Etapu 0 są kopiowane do katalogu nowej sesji), ale efekt uboczny jest taki, że **pierwsza prawdziwa sesja może wylądować w `refactor-result2`**. Do przemyślenia, czy to przeszkadza.

co do tej wątpliwości to po stwrzeniu etapu 0 uzytkownik zrobi clear i będzie nowa sesja ale etap 0 z powodu tego co jest w nim zapisane nie powtórzy się,

ale moze stać się coś innego użytkownik przekroczy czas i wtedy orkiestrator stworzy nowy numer a potem kolejny jeżeli użytkownik świadomie albo nie będzie pracował na danej wersji, ten czas 60 minut jest na razie w ramach testów, jeżeli dojdziemy do momentu że orkiestrator będzie działał na większym kontekście ten czas się wydłuży, po za tym ja zakładam ze resetowanie kontekstu będzie częste,
będzie to wykonywał użytkownik ale harnes będzie musiał być na to odpoporny i dawać modelowi i agentom zawsze właściwe infroamcje zgodne z konfiguracją użytkownika,

Stan orkiestratora w JSON kluczowany własnym task ID, nie session_id Claude Code, zastanowić się nadym

przykład ściągnięty z claude
"2. Krytyczna luka: /clear zmienia session ID

/clear tworzy nowy identyfikator sesji i nowy plik transkryptu. Jeśli Twoje "state w plikach JSON kluczowanych sesją" (session-keyed) jest kluczowane właśnie tym ID Claude Code — po /clear orkiestrator traci dostęp do własnego stanu, bo klucz się zmienił.
Konsekwencja: potrzebujesz własnego, stabilnego identyfikatora zadania/przebiegu (task/run ID nadawany przez Twój skill, niezależny od session_id Claude Code), pod którym trzymasz stan. Session_id od Claude Code używaj co najwyżej do debugowania, nie jako klucz trwałości."

