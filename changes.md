 
co do samego tytułu i wstępu to nie będzie to podejście tylko według Feathersa, będziemy się starać wprowadzić to według zasada Fowlera, Uncle Boba, clean code. Oraz jakiś właśnych przemyśleń,
Ale o tym w etapie drugim

Etap drugi, jeżeli zostanie wybrana opcja refaktoryzacja plus zmiana logiki to etap staje się etapem do wprowadzenia, zmiany logiki.

Na początek użytkownik skilla wprowadza opis czego dotyczą zmiany, jakich części systemu-kodu, jakie są przewidziane granice zmian, co jest sednem problemu.

tę opcje na razie zostawiamy z dopiskemi w budowie, bo jeszcze nie wiem jak to będzie wyglądać,

przechodzimy do opcji bez wprowadzenia logiki, czyli opcje refaktoryzacja została wybrana.
W tym momencie etap 2 będzie koncentrował się na zmianach i testach tych zmian,

Etap 2 w tym momencie będzie podzielony na pod etapy kroki do wykonania.
Zgodnie z zasadami Fowlera, Feathersa i innych.
krok pierwszy:
- na początek zadbamy o czytelność czyli poprawiamy nazwy zmiennnych, nazwy metod i klas zgodnie z tym co tak fakytycznie robią, nie zmieniamy zachowania,
- tu piewrsza uwaga taka zmiana może wymuśić zmianę testów jeżeli zmieniła się nazwa metody albo klasy to należy wziąc poduwagę czyli trzeba sięgnąć jakby do Etapu pierwszego i zmienić testy, przekazać info użytkownikówi że po zmianach testy nie przechodzą i trzeba zmienić je, użytkownik musi być o tym poinformaowany i ręcznie to potwierdzić,
- zmiana nazwa pozwoli uzyskać informacje na temat zasięgu zmiany w kolejnych krokach,

dobra na razie tyle implementuj to

---

> ✅ **Wprowadzono w `refactor-legacy.md`** (2026-08-30)
>
> 1. **Tytuł/wstęp** — usunięto "oparty o podejście Michaela Feathersa"; dodano nową sekcję `## Podstawa metodyczna` (linie 10–27) z rozbiciem: Feathers → Etap 1, Fowler + Uncle Bob/clean code → Etap 2, plus "Własne ustalenia i przemyślenia". Zaktualizowano `## Status dokumentu`.
> 2. **Etap 2, reguła rozgałęzienia** — przeformułowana: "Refaktor + zmiana logiki" (lub sama "Zmiana logiki") sprawia, że Etap 2 *staje się etapem wprowadzenia zmiany logiki*.
> 3. **Etap 2, wariant "Zmiana logiki"** — nowa sekcja oznaczona *(w budowie)*. Dodany **krok wejściowy**: użytkownik opisuje czego dotyczą zmiany, jakich części systemu/kodu, jakie są granice zmian, co jest sednem problemu. Skill zatrzymuje się po zebraniu opisu. Poprzednie 5 kroków zostawione jako "wstępny zarys do rewizji" (nie skasowane).
> 4. **Etap 2, wariant "Refaktor"** — przebudowany na podział na **pod-etapy (kroki)**; koncentracja na zmianach i testach tych zmian.
> 5. **Krok 1 — Czytelność (nazewnictwo)** — nowa podsekcja: poprawa nazw zmiennych/metod/klas zgodnie z rzeczywistą odpowiedzialnością, bez zmiany zachowania; obowiązkowe sprzężenie z Etapem 1 (powrót do testów, poinformowanie użytkownika, **ręczne potwierdzenie** aktualizacji testów); zmiana nazwy jako źródło informacji o zasięgu zmiany dla kolejnych kroków.
> 6. **Reguła niezaliczonego testu** — nowa podsekcja rozstrzygająca, kiedy czerwony test to skutek renamu (do aktualizacji po potwierdzeniu), a kiedy regresja (stop + zgłoszenie).
> 7. **Log Etapu 2** — dopisano grupowanie wpisów nagłówkiem `## Krok N` oraz odnotowywanie ręcznych potwierdzeń aktualizacji testów.
>
> Dodano placeholder `#### Kolejne kroki *(do zdefiniowania)*` — czeka na krok 2.

Jeżeli trzeba zmienić testy z powodu zmiany nazwy to LLM robi to automatycznie ale wcześniej niż to zrobi zgłasza użytkownikowi że testy świecą na czerwowno, chodzi o transparentność tego co robi LLM żeby uzytkownik na każdym etapie był świadomy zmian i tego co się dzieje,
Każda zmiana będzie odnotowana w logu tak czy inaczej, plik wynikowy będzie analogiczny do etapu 1,

Krok 2
- usunięcie magic numberów - to robi LLM ale jeżeli nie potrafi z kodu wywnioskować, znaleźć co kryje się pod danymi liczbami to informuje o tym użytkonwika, nic nie wymyśla sam. Użytkownik musi znaleźć czym są te magic numbery i przedstawić je LLM-owi albo w formie wpisu w odpowiednim pliku, albo po prostu wrzuceniu do kodu enuma bądz klasy statycznje ze stałymi albo jakaś inna forma która umożliwia ich wykorzystanie w kodzie,
oczywiście testy po tym kroku aczkolwiek wątpliwe by świecily na czerwono ale trzeba po każdym kroku sprawdzać,

Teraz inna sprawa, ten skill rozrasta się bardzo szybko to jest teraz druga część zadania,
- trzeba rozbić skilla na pliki która będą operować na poszczególnych etapach,
- głównym kierownikiem będzie orkiestratorm on będzie uruchamiany na początek i do nie go i z nie go będą wychodzić informacje w czasie trwania etapów, czyli np jeżeli w etpaie drugim jest hasło trzeba zmienić testty, to orkiestrator dostaje takie info i odpala etap 1 ktory zmienia odpowiedni test który zaświecił się na czerwono z powodu zmiany nazwy czy też odpowiedzialności, czy też innego który zmusza do zmiany testa, może też zaistnieć sytuacja że trzeba dopisać nowy test albo usunąć niepotrzebny wtedy orkiestrator dostaje odpowiedniego requesta który będzie miał w sobie odpowiednie informacje które umożliwią wykonaie poszczególnych zadań,
- w tym momencie etapy nie są już tylko częściami które zwracają czy coś się wykonało poprawnie albo nie ale musza zwrócić requesta najlepiej w formie jasona który będzie zawierał znacznie więcej informacji, teraz będze potrzebna wymiana informacji duwkierunkowa a praca asynchroniczna, gdyż jak będzie się wykonywał etap pierwszy czy drugi orkiestrator musi czuwac i oczekiwać- reagować na zmiany,
- orkiestrator inicjuje wszystkie etapy więc etap wstępny jest w nim czyli zebranie wymagań co do procesu, czyli konfiguracja wstępna, pytania konfiguracyjne, wynik tych pytań teraz będzie przekazywany do etapu piewrszego jako wsad początkowy i przypominający bo jest tam jeden z warunków który mówi że po każdej iteracji będą wczytywane ustalenia konfiguracyjne, wiec ten plik który będzie stworzony będzie miał te odpowiedzi i to on będzie ładowany po każdej iteracji w etapie pierszym jako przypominajka, nie będzie musiał być trzymany w pamięci między wywoływaniami etapów albo między iteracjami, jednak dla bezpieczeństwa orkiestrator będzie go trzymał w pamięci u po zakończeniu etapu pierwszego jak i kolejnego będzie sprawdzał czy plik zapisany ma te same warunki które on trzyma w pamięci, to takie zabezpieczenie na wypadek przypadkowej zmiany, jeżeli ona zajdzie to orkiestrator przerywa działanie skilla z informacją że główne ząłożenia zostały zmienione w trakcie działania (to jest critical error)
- nazwy poszczegółnych etapów to na razie daj etap 1, etap 2 i etap 3 z tym że etap 3 pusty plik,

działaj

---

> ✅ **Wprowadzono** (2026-08-30) — nowa struktura w katalogu `refactor-legacy/`
>
> **Część 1 — zmiany merytoryczne (Etap 2):**
> 1. **Aktualizacja testów po renamie** — poprawione względem poprzedniej iteracji: LLM robi to **automatycznie**, ale **najpierw** wystawia request z `requires_user_ack: true` i pokazuje użytkownikowi, które testy świecą na czerwono i przez którą zmianę nazwy. Wykonanie bez zatwierdzania linia po linii. (`etap2.md`, Krok 1 pkt 3)
> 2. **Każda zmiana w logu** — log Etapu 2 odnotowuje każdy wystawiony request na testy (`msg_id`, moment zgłoszenia, wynik z Etapu 1), niezależnie od tego, czy użytkownik go komentował.
> 3. **Format wyjścia Etapu 2** — placeholder zastąpiony pełną strukturą, analogiczną do Etapu 1: Opcja A/B, plik per krok, 6 sekcji planu (Zakres kroku / Stan wyjściowy / Planowane zmiany / Wpływ na testy z Etapu 1 / Pozycje otwarte / Do akceptacji) + akceptacja planu przed zmianą kodu.
> 4. **Krok 2 — Usunięcie magic numbers** — nowa podsekcja: LLM podstawia stałe tam, gdzie znaczenie da się wywieść z kodu; **zakaz zgadywania** — nierozpoznane literały idą do użytkownika jako `user.input`, nic nie jest wymyślane ani pomijane po cichu; użytkownik dostarcza znaczenie w dowolnej formie (wpis w pliku / enum / klasa statyczna ze stałymi / inna); testy uruchamiane po kroku bez wyjątku, czerwony test = regresja (brak wymówki w postaci renamu).
> 5. **Sekcja "Otwarte pytania (Etap 2)" usunięta** — oba pytania rozstrzygnięte przez powyższe (pkt 1 i pkt 3).
>
> **Część 2 — rozbicie na pliki + orkiestrator:**
>
> | Plik | Zawartość |
> |---|---|
> | `refactor-legacy/SKILL.md` | **Orkiestrator** — punkt wejścia, podstawa metodyczna, konfiguracja wstępna (Pytania 0–2), log decyzji, katalog wynikowy, snapshot + kontrola integralności, protokół komunikacji, pętla sterowania, log orkiestratora, flaga `test` |
> | `refactor-legacy/etap1.md` | Etap 1 + nowy **tryb zadaniowy** (`task.execute`) |
> | `refactor-legacy/etap2.md` | Etap 2, oba warianty, kroki 1–2 |
> | `refactor-legacy/etap3.md` | Pusty (nagłówek + warunek uruchomienia) |
>
> 6. **Orkiestrator inicjuje wszystko** — konfiguracja wstępna przeniesiona z Etapu 1 do orkiestratora; wynik idzie do etapów jako `payload.config` w `stage.start`.
> 7. **Snapshot + kontrola integralności** — orkiestrator trzyma odpowiedzi z Pytań 0–2 w pamięci; etapy wczytują `refactor-decisions.md` z dysku przed każdą iteracją (przypominajka, bez trzymania w pamięci); po zakończeniu **każdego** etapu orkiestrator porównuje plik ze snapshotem → rozjazd = **CRITICAL ERROR** i przerwanie całego skilla ze wskazaniem różnic, bez próby scalania.
> 8. **Protokół komunikacji JSON** — koperta (`msg_id`, `corr_id`, `type`, `from`, `to`, `action`, `status`, `requires_user_ack`, `user_message`, `payload`, `timestamp`); katalog akcji w obie strony (`test.update` / `test.add` / `test.remove` / `user.input` / `user.approval` / `stage.done` / `stage.aborted` / `error.critical` ↔ `stage.start` / `task.execute` / `stage.resume` / `stage.abort`); pełny przykład routingu Etap 2 → orkiestrator → Etap 1 → `stage.resume`; wiadomości zapisywane jako pliki w `komunikacja/`.
> 9. **Praca dwukierunkowa i asynchroniczna** — orkiestrator nie kończy po odpaleniu etapu, tylko czuwa i reaguje na przychodzące requesty; `resume_point` pozwala wrócić do przerwanego miejsca.
> 10. **Zasada własności testów** — Etap 1 jest jedynym miejscem, gdzie testy powstają, zmieniają się i są usuwane; Etap 2 nigdy nie rusza testów sam, tylko wystawia request przez orkiestratora.
>
> ⚠️ **Do Twojej decyzji:** stary monolit `refactor-legacy.md` (565 linii) **zostawiłem nietknięty** w katalogu głównym. Jego treść jest w całości przeniesiona do `refactor-legacy/`, ale zawiera nieaktualną wersję punktu o testach ("ręczne potwierdzenie"). Powiedz, czy go usunąć — nie kasowałem go sam.
>
> ↳ **Rozstrzygnięte:** stary `refactor-legacy.md` zostaje w katalogu głównym (decyzja użytkownika — git rozwiąże sprawę wersjonowania).

---

**(wpis z rozmowy, nie z pliku)** Zmiana nazwy `SKILL.md` → `orkiestrator.md`. To już nie typowy skill, tylko harness pilnujący odpowiedniego wykonania poszczególnych etapów.

> ✅ **Wprowadzono** (2026-08-30)
>
> 1. **Odwołania międzyplikowe** — 6 wystąpień `SKILL.md` → `orkiestrator.md` w `etap1.md` i `etap2.md`.
> 2. **Framing skill → harness** — frontmatter (`description`), wstęp, „Struktura harnessu (pliki)", „Katalog wynikowy", kontrola integralności, flaga `test`. W `etap1.md`/`etap2.md` słowo „skill" zastąpione przez „etap" lub „harness" zależnie od kontekstu (np. „Opcja 1 — Zakończenie działania harnessu", „Strategia seamu: Etap wybiera…").
> 3. **Wstęp przepisany** — wprost: „To nie jest typowy skill — to **harness**: warstwa nadrzędna, która sama nie wykonuje refaktoryzacji, tylko pilnuje, żeby poszczególne etapy zostały wykonane poprawnie i w ustalonym porządku." Plus zasada: żaden etap nie jest uruchamiany bezpośrednio.
> 4. **Rola orkiestratora** — dopisany punkt 6 (pilnowanie poprawnego wykonania etapów) oraz akapit negatywny: orkiestrator **nie** analizuje kodu, **nie** pisze i **nie** zmienia testów, **nie** proponuje seamów. Wyłącznie porządek, kompletność, przepływ.
> 5. **Nowa sekcja „Bramy etapów (kontrola wykonania)"** — to jest właściwa realizacja „pilnowania":
>    - **Brama wejściowa** (5 warunków przed `stage.start`): kompletna konfiguracja, zgodność ze snapshotem, etap nie pominięty, poprzedni etap zamknięty i zaakceptowany, plik etapu istnieje i nie jest pusty (próba uruchomienia pustego Etapu 3 → `error.critical`, nie ciche pominięcie).
>    - **Brama wyjściowa** (5 warunków po `stage.done`): plik wynikowy w wymaganym formacie, log niepusty i chronologiczny, żaden request nie wisi bez odpowiedzi, brak nierozstrzygniętych pozycji blokujących, integralność konfiguracji. Braki → `stage.resume` z listą braków; etap nie jest zamknięty, dopóki brama nie przejdzie.
>    - **Zasada nieprzeskakiwania** — kolejność etapów nie podlega samodzielnej zmianie; jedyny dopuszczalny „skok" to routing zadaniowy do Etapu 1, po którym sterowanie zawsze wraca do zleceniodawcy.
> 6. **Pętla sterowania i log orkiestratora** — wpięte bramy; log odnotowuje wynik każdej bramy (przeszła / nie przeszła + który warunek).

zmiana nazwy poprzedniej wesrji pliku na depracated,

kolejne zmiany do etapu drugiego
korok kolejny to :
Przerwanie zależności:
- wykrycie zależeności od systemów zewnętrznych, pod tym czaji się trochę więcej, chodzi o zewnętrzne klasy, baza danych, api, czy inne wywołania,
- trzeba jest znaleźć i przesuwać w forme zależności przychodzacych od góry czyli przez konstruktor, ilośc na razie nie ma znaczenie jeżeli będzie znaczna to nie istotne bo ten krok ma je uanocznić i przesunąć zależność do konstruktora w taki sposób żeby można było je zamockować albo stubować,
- tu będzie zapewne zmiana testów i trzeb będzie komunikować okiestratora poprzez odpowiednie zdarzenie,

tu też uwaga do etapu pierwszego, w tym momncie trzeba będzie włączyć mocki w testach jeżeli wcześniej nie były one włączone, to też należy rozszerzyć typ zdarzeń do orkiestratora i etapu drugiego o dodanie mocków,

wracając do tego etapu
- ten etap może mieć sam w sobie kilka iteracji więc gdyż ilość tych zależności może być duża,

teraz kolejna uwaga do orkiestratora
- trzeba będzie zrobić mechanizm wznawiania sesji, ale być może to będzie łatwiejsze gdyż mamy logi, po prstu orkiestrator przed pytaniami wstępnymi musi uruchomić etap 0, ten etap będzie miał za zadanie przeszukać aktualną strukturę kryjącą się pod nazwą legacy-skill to nasz zbiór na wszelkie logi i informacje gromadzone przez harnessa,
- będzie to etap wykonywany przez agenta zlecony przez orkiestrator, po tym etapie wynikiem będzie json któ©y orkiestrator będzie interpretował w tym jsonie, będzie zawarte które etapy zostały zrobione, czy jest plik z odpowiedziami na pytania wstepne?, jakie są logi? może być tak że harness byl uruchamiany wielokrotnie wtedy trzeba i tu uwaga jedna do orkiestratora i etapów trzeba w logi wrzucać daty i czas,
- czyli log na początek każdego etapy wpisuje datę uruchomienia i godzine, w formacie
yyyy-MM-dd (rok-miesiąć-dzień); HH-mm-ss (godzina - minuta-sekunda) każdy w logu ma vbyć poprzedzony tymi informacjami, to ma być zapisane w pliku konfiguracyjnym, będzie to również wczytywane do etapów, to jest bardzo istotne w kwesti sprawdzania czy mamy doczynienia z nowym wywołaniem czy isteniejącym,
- jeżeli etap 0 zwróci te dane orkiestrato będzie miał pełne info na temat tego co zostało zrobione i będzie mógł utowrzyć nową sesje, tu uwaga wążna po pozykaniu danych z etapu 0  musi wystąpić wywołanie /clear czyli wyczyszczenie kontekstu ale nim to nastąpi orkiestrator zapiszę dane że wczytał i wyczyścił kontekst to będzie zapobiegało zapętleniu tego,
- ta inforamcja będzie wtedy w logach samego orkiestratora i będzie wczytywana przed etapem 0 czyli dodatkowy plik który będzie bradzo krótki i będzie miał info że zostały wczytane poprzednie sesje i tu ważne będzie data i godzina dzięki temu po wyczyszczeniu kontekstu orkistrator będzie miał szanse porównać kiedy to zostało zrobione, jeżeli czas jest krótrzy i zakładamy na razie 10 minut to znaczy że mamy doczynienia z przygotowanym środowiskiem do pracy,
jezeli etap 0 nie wykrył poprzednich sesji to postępowane jest takie samo jak przy ich wykryciu, analogiczne, ten etap jest newralgiczny bo nie wiem czy możliwy, więc jeżeli nie jest to możliwe zamiast automatycznego wywołania /clear użytkownik musi to zrobić, czyli LLM informuje użykownika że może to zrobić bez utraty danych odnośnie tego co znalazł etap 0



---

> ✅ **Wprowadzono** (2026-08-30)
>
> **Część 1 — Etap 2, Krok 3: Przerwanie zależności** (`etap2.md`)
> 1. **Wykrycie zależności zewnętrznych** — rozpisane szerzej niż "baza danych": zewnętrzne klasy (`new` wewnątrz metody), baza danych/ORM/repozytoria, API i usługi zdalne (HTTP, kolejki), oraz inne wywołania wychodzące — statyka, singletony, `DateTime.Now`, system plików, konfiguracja, kontekst HTTP. Zaznaczone, że lista z Etapu 1 jest punktem wyjścia, ale Krok 3 idzie szerzej (Etap 1 = tylko to, co blokowało test; Krok 3 = wszystkie zależności zewnętrzne w zakresie).
> 2. **Przesunięcie do konstruktora** — zależność przychodząca "od góry": interfejs → parametr konstruktora → pole → miejsca użycia wołają pole. Wprost zapisane, że **liczba zależności nie ma znaczenia** i rozdęty konstruktor to zamierzony efekt kroku (uwidocznienie), a nie problem; zakaz "chowania" ich w fabryki czy serwis-agregat, żeby lista wyglądała krócej. Kryterium akceptacji per zależność: da się ją w teście podmienić na mock/stub bez dotykania kodu produkcyjnego.
> 3. **Sprzężenie z Etapem 1** — zmiana sygnatury konstruktora ⇒ czerwone testy, jak przy renamie: najpierw zgłoszenie (`requires_user_ack: true`), potem automatyczne wykonanie przez Etap 1. `allowed_scope: ["constructor_injection", "mock_setup"]`, `forbidden: ["assert_change", "input_data_change", "test_scope_change"]` — mock odtwarza dotychczasowe zachowanie zależności, asercje nietknięte.
> 4. **Iteracyjność kroku** — Krok 3 dzieli się na porcje (klasa / grupa powiązanych zależności na iterację); każda iteracja to pełny cykl plan → akceptacja → przeniesienie → request na testy → **zielone testy** → potwierdzenie. Kolejna iteracja startuje dopiero na zielonym; zakaz kumulowania czerwonych testów między iteracjami. Log grupuje `### Krok 3 — iteracja N`.
> 5. **Reguła niezaliczonego testu** — dopisany przypadek dla Kroku 3 (przeniesienie zależności = skutek zamierzony, nie regresja), ale wyłącznie dla zależności wymienionych w planie bieżącej iteracji; zależność nieplanowana nie jest wymówką. Lista przenumerowana (1–5), odwołania w Kroku 2 i 3 poprawione.
>
> **Część 2 — Mocki w Etapie 1** (`etap1.md`, `orkiestrator.md`)
> 6. **Nowe typy zdarzeń** — `test.mock.enable` (włączenie obsługi mocków w projekcie testowym) i `test.mock.add` (dodanie mocka/stuba dla konkretnej zależności). Dopisane do katalogu akcji w `orkiestrator.md`, do tabeli zadań trybu zadaniowego Etapu 1 i do "Zasady własności testów" w Etapie 2. Routing w pętli sterowania obejmuje je tak samo jak `test.update` — trafiają wyłącznie do Etapu 1.
> 7. **Nowa sekcja "Mocki w testach"** w `etap1.md` — wprost zapisane, że do Kroku 2 testy mogły obejść się bez mocków, a od Kroku 3 już nie. Wybór frameworka mockującego działa analogicznie do wyboru frameworka testowego z Pytania 0: jest w projekcie → używamy; nie ma → **Etap 1 nie wybiera sam**, tylko wystawia `user.input`; jest kilka → pytanie, którego użyć. Wybór zapada raz i jest odnotowany w logu. Przy `test.mock.add` obowiązuje zakaz zgadywania zachowania zależności, której nie da się odtworzyć z kodu.
>
> **Część 3 — Etap 0 i wznawianie sesji** (nowy `etap0.md` + `orkiestrator.md`)
> 8. **Nowy plik `etap0.md`** — Etap 0 "Rozpoznanie stanu (wznowienie sesji)", wykonywany przez **agenta zleconego przez orkiestratora** w osobnym kontekście. Powód zapisany wprost: treść kilkunastu logów nie może osiąść w kontekście orkiestratora — orkiestrator dostaje **wyłącznie raport JSON**. Etap 0 jest read-only, nie analizuje kodu ani testów, nie zgaduje (brak pliku = `false`, niejednoznaczność → `anomalie[]`).
> 9. **Zakres przeszukania** — katalog wynikowy harnessu wraz ze wszystkimi wersjami (`refactor-legacy`, `refactor-legacy-verN`): plik stanu sesji, `refactor-decisions.md`, logi orkiestratora i etapów, pliki wynikowe, `komunikacja/*.json` (wykrycie requestów bez odpowiedzi).
>    ⚠️ **Interpretacja:** nazwę "legacy-skill" z Twojego wpisu przyjąłem jako katalog wynikowy harnessu (`refactor-legacy` + wersje) — to jedyny zbiór logów i informacji, jaki harness gromadzi. Jeśli miałeś na myśli inny katalog, powiedz, poprawię nazwę w jednym miejscu.
> 10. **Raport JSON** — pełny schemat: `katalogi_wynikowe`, `aktywny_katalog`, `konfiguracja` (czy jest plik z odpowiedziami na pytania wstępne, czy kompletny, jakie odpowiedzi), `sesje[]` (wielokrotne uruchomienia rozpoznane po znacznikach czasu), `etapy[]` (status `not_started`/`in_progress`/`done`/`aborted`/`skipped`, iteracje, ostatni wpis, akceptacja), `requesty_otwarte`, `pozycje_otwarte`, `sesja_poprzednia`, `anomalie`.
> 11. **Znaczniki czasu — nowa sekcja w `orkiestrator.md`** — format `yyyy-MM-dd; HH-mm-ss` (np. `2026-08-30; 19-07-12`), **zapisany w pliku konfiguracyjnym** i wczytywany przez etapy razem z resztą konfiguracji (podlega kontroli integralności). Każdy etap na starcie wpisuje do logu datę i godzinę uruchomienia (`## Uruchomienie <znacznik>`), każdy kolejny wpis jest poprzedzony znacznikiem. Zaktualizowane logi Etapu 1 (wraz z przykładem), Etapu 2 i orkiestratora; nagłówki iteracji zeszły na `###` pod nagłówek uruchomienia. Wpisy bez znacznika (sprzed reguły) Etap 0 raportuje jako anomalię, a nie przypisuje do sesji na siłę.
> 12. **Zabezpieczenie przed zapętleniem `/clear`** — kolejność krytyczna: **najpierw** zapis `refactor-session.md` + wpis w logu orkiestratora (raport wczytany, kontekst czyszczony, ze znacznikiem czasu), **dopiero potem** `/clear`. Po odzyskaniu sterowania orkiestrator czyta ten plik i porównuje czas: **< 10 minut** → środowisko przygotowane, Etap 0 pominięty; **≥ 10 minut** → nowe uruchomienie.
> 13. **Gdy `/clear` nie jest możliwy automatycznie** — orkiestrator **nie udaje, że go wykonał**: informuje użytkownika, że może wyczyścić kontekst ręcznie **bez utraty danych** (wszystko jest już w `etap0-raport.json` i `refactor-session.md`), i czeka. Zapis stanu sesji następuje tak samo, przed prośbą.
> 14. **Brak poprzednich sesji = ta sama ścieżka** — raport z pustymi tablicami przechodzi identycznie, łącznie z zapisem stanu i czyszczeniem kontekstu. Zapisane wprost, że to nie jest przypadek szczególny.
> 15. **Wznowienie nie jest automatyczne** — tabela interpretacji raportu (6 sytuacji → decyzja); przy wznowieniu Pytania 0–2 nie są zadawane od nowa, ale konfiguracja jest **pokazana użytkownikowi do potwierdzenia** i staje się snapshotem referencyjnym.
> 16. **Wpięcie w resztę orkiestratora** — Etap 0 w tabeli struktury harnessu i w Roli orkiestratora (nowy pkt 2, reszta przenumerowana); nowy **warunek 0 bramy wejściowej** (bez rozpoznania stanu żaden etap nie startuje — inaczej harness mógłby nadpisać wynik poprzedniej sesji) plus jawny wyjątek, że sam Etap 0 bramie nie podlega; **krok 0 pętli sterowania**; Etap 0 wyłączony z pomijania w Pytaniu 2; przykładowy log orkiestratora ze śladem `/clear`; reguła, gdzie lądują pliki Etapu 0, zanim wiadomo, czy powstanie nowa wersja katalogu (najnowszy istniejący katalog, kopiowane do nowej wersji przy decyzji o nowej sesji).
>
> ↳ **Rozstrzygnięte (2026-08-30):** "legacy-skill" = katalog wynikowy harnessu (`refactor-legacy` + wersje) — interpretacja potwierdzona przez użytkownika, `etap0.md` zostaje bez zmian.
