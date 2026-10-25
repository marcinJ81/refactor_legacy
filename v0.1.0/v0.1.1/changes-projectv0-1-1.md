 ## INfo dla cluade
To jest plik gdzie komunikujemy zmiany, ja podaje swoje ty dopisujesz wątpliwości i rezultaty zmian,
Swoją sekcje oznaczacz Claude
Piszemy zwięźle i bez skrótów, adresujemy dokładnie zmiany i pytania czyli np jaki plik nazwa i nazwa sekcji która linia,
Nie uruchamiamy żadnych dodatkowych narzędzi, to jest etap tworzenia harnessa, testy będę przeprowadzał gdzie indziej
Zmiany są dla refactor-legacy-v0.1.0
Wersje: każdy nowy numer wersji trzeba uwzględnić przy instalacji (`manifest.json` wersji — pole `wersja_harnessu` i lista plików; tabela „Wersje harnessu" w `.claude/agents/instalationHarnessRefactor.md`) oraz w każdym pliku harnessu, w którym jest o nim mowa (znacznik `wersja-harnessu` w każdym pliku, pole `wersja_harnessu` w `refactor-config.example.json` i `orchestrator-examples/refactor-config.md`).
korzystasz z dokumentacji:
Hooki

[instructions/hooks.md](../../instructions/hooks.md) — zdarzenia (SessionStart, SubagentStart/SubagentStop, PreToolUse, PostToolUse, Stop itd.), schemat matcherów, ${CLAUDE_PROJECT_DIR}/${CLAUDE_PLUGIN_ROOT}, lokalizacje konfiguracji (settings.json / settings.local.json / plugin hooks.json), debugowanie hooków.

Subagenty

[instructions/sub-agents.md](../../instructions/sub-agents.md) — pełna lista pól frontmattera, lokalizacje (.claude/agents/, ~/.claude/agents/, plugin agents/), priorytety, wywoływanie przez Agent tool (subagent_type), hooki we frontmatterze subagenta (PreToolUse/PostToolUse/Stop).

Skille

[instructions/skills.md](../../instructions/skills.md) — frontmatter skilla, progressive disclosure (SKILL.md + pliki referencyjne), limit ~500 linii, zasada „state what to do rather than narrating how or why", hooki we frontmatterze skilla i ich zasięg („rest of session once invoked").

Pluginy (na wypadek gdybyś jednak wrócił do tej opcji przy dystrybucji harnessu)

[instructions/plugins.md](../../instructions/plugins.md) — tworzenie pluginu, manifest .claude-plugin/plugin.json, struktura katalogów (agents/, hooks/hooks.json, skills/), namespacing (plugin-name:agent-name).
https://code.claude.com/docs/en/plugins-reference.md — pełna specyfikacja techniczna (nie sprawdzałem jej dziś wprost, ale to źródło, do którego odsyłają powyższe strony po szczegóły schematu manifestu i katalogów).

Ustawienia / precedencja

[instructions/settings.md](../../instructions/settings.md) — kolejność rozstrzygania settings.json vs settings.local.json vs managed policy, co dokładnie idzie do którego pliku.

struktura (repozytorium):
<orkiestartor-refaktor-skill>/
├── instalationInfo.md                ← co skopiować ręcznie przed instalacją
├── docs/
│   └── communication-protocol.md
├── instructions/                     ← lokalne kopie dokumentacji Claude Code (w .gitignore)
│   ├── hooks.md
│   ├── instructions-references.md
│   ├── plugins.md
│   ├── settings.md
│   ├── skills.md
│   └── sub-agents.md
├── .claude/
│   └── agents/
│       └── instalationHarnessRefactor.md   ← agent instalacyjny (claude --agent …)
├── instalator/
│   └── scripts/
│       ├── _wspolne.ps1
│       ├── 01-zrodlo.ps1
│       ├── 02-cel.ps1
│       ├── 03-instaluj.ps1
│       └── log-instalacji.ps1
├── refactor-legacy-v0.1.0/           ← wersja 0.1.0 (nierozwijana)
│   ├── manifest.json
│   ├── orkiestrator.md
│   └── etap0.md … etap3.md
└── refactor-legacy-v0.2.0/           ← wersja 0.2.2 (bieżąca)
    ├── manifest.json                 ← wersja + lista plików dla instalatora
    ├── orkiestrator.md
    ├── refactor-config.example.json
    ├── .claude/
    │   ├── settings.json             ← hooki: SubagentStart (etap0), SubagentStop (step2)
    │   ├── hooks/
    │   │   ├── etap0-start.ps1
    │   │   └── step2-stop.ps1
    │   └── agents/
    │       ├── etap0.md
    │       └── etap1/
    │           ├── step1.md
    │           └── step2.md
    ├── scripts/
    │   ├── etap0/
    │   │   ├── 00-rozpoznanie.ps1
    │   │   └── _wspolne.ps1
    │   ├── step1/
    │   │   ├── 00-brama.ps1
    │   │   ├── 01-pliki.ps1
    │   │   ├── 02-sekcje.ps1
    │   │   ├── 03-json.ps1
    │   │   ├── 04-licznik.ps1
    │   │   ├── _wspolne.ps1
    │   │   └── eraser/
    │   │       └── 00-eraser.ps1
    │   ├── step2/
    │   │   └── 00-brama.ps1
    │   └── wspolne/
    │       └── wpis-logu.ps1
    ├── orchestrator-examples/
    ├── etap1-step1-examples/
    └── references/
        └── etap1-step1/
            ├── feathers-technique-selection.md
            └── feathers-dependency-breaking-csharp.md
struktura będzie dostosowywana
##

##User - zadania

działamy na wersji 0.1.0
Do etapu1 dodasz z wersji 0.2.0 katalog technik feathers-a, będzie on umieszczony w katalogu references/etap1/ będzie to kopia dwóch plików feathers-technique-selection.md oraz feathers-dependency-breaking-csharp.md
dorzucisz odwołanie do tego w etapie1, dzięki temu będzie można usunąć sporo rzeczy z etapu1


## Claude

### Rezultat zmian

1. Nowy katalog `refactor-legacy-v0.1.0/references/etap1/` — kopie plików z `refactor-legacy-v0.2.0/references/etap1-step1/`:
   - `feathers-technique-selection.md`
   - `feathers-dependency-breaking-csharp.md`
   Treść bez zmian, zmieniony tylko znacznik `wersja-harnessu` (z 0.2.2 na 0.1.1).
2. `refactor-legacy-v0.1.0/etap1.md`:
   - nowa sekcja `## Katalog technik Feathersa` (linia 16) — tabela dwóch plików i kiedy je wczytać;
   - sekcja `## Faza Analizy — kroki`, krok 2 „Identyfikacja zależności blokujących testowalność” (linia 93) — usunięta lista przykładowych zależności i lista czterech technik, w ich miejscu odwołania do tabeli objaw → technika, kolejności preferencji, warunków wstępnych, reguł wyboru i do sekcji `[n]` w pliku z technikami;
   - sekcja `## Decyzje (rozstrzygnięte)`, punkt „Strategia seamu” (linia 359) — „katalog technik Feathersa” zamienione na ścieżkę `references/etap1/feathers-technique-selection.md`.
3. `refactor-legacy-v0.1.0/orkiestrator.md`, sekcja `## Struktura harnessu (pliki)` — dwa nowe wiersze dla plików z `references/etap1/`.
4. Wersja 0.1.1:
   - znacznik `wersja-harnessu: 0.1.1` w `orkiestrator.md`, `etap0.md`–`etap3.md` i w obu plikach `references/etap1/`;
   - `refactor-legacy-v0.1.0/manifest.json` — `wersja_harnessu: "0.1.1"`, lista `pliki_harnessu` uzupełniona o dwa pliki z `references/etap1/`;
   - `.claude/agents/instalationHarnessRefactor.md`, sekcja `## Wersje harnessu` (linia 40) — wiersz `0.1.0` zamieniony na `0.1.1`, dodane `references/etap1/`; także linie 86, 112, 132 (`0.1.0` → `0.1.1`).
   - Nazwa katalogu `refactor-legacy-v0.1.0/` bez zmian. Wersja 0.1.1 nie ma `refactor-config.example.json` ani `orchestrator-examples/`, więc tam nic nie zmieniałem.

### Wątpliwości

1. `etap1.md`, sekcja `## Decyzje (rozstrzygnięte)`, punkt „Framework testowy i izolacja zależności statycznych” (linia 365): domyślne podejście to „interfejs + Dependency Injection, przy braku kontenera DI fabryka”. Plik `feathers-technique-selection.md`, sekcja `## 2. Kolejność preferencji`, stawia na poziomie 1 Parameterize Constructor, Parameterize Method, Extract Interface, Adapt Parameter, Replace Function with Function Pointer — fabryka (Extract and Override Factory Method) jest dopiero na poziomie 2. Nie usuwałem tego punktu. Pytanie: co ma pierwszeństwo — punkt w `etap1.md` czy kolejność z pliku wyboru?
2. Kandydaci do usunięcia z `etap1.md`, których nie ruszałem bez Twojej decyzji:
   - sekcja `## Faza Implementacji — kroki`, krok 2 „Wydzielanie z dużych metod / wprowadzenie seamu” (linia 152) — częściowo pokrywa wiersz N tabeli (Parameterize Method / Break Out Method Object) i regułę „technika nie może zmieniać zachowania” z `## 4. Reguły wyboru`;
   - sekcja `## Faza Analizy — kroki`, krok 3 „Propozycja minimalnego odsprzęgnięcia” (linia 104), pierwszy punkt „najmniejsza możliwa zmiana” — pokrywa reguła „wybierać najniższy możliwy poziom preferencji”;
   - sekcja `## Format wyjścia Etapu 1`, punkt 2 „Zależności blokujące” (linia 337) — można dopisać, że typ seamu podaje się nazwą i numerem `[n]` z pliku wyboru, oraz uzasadnienie przy poziomie 2 i 3.
3. Pliki Feathersa w wersji 0.2.2 są pisane pod agenta kroku 1 (`step1`). W wersji 0.1.1 czyta je etap1 jako całość — treść tego nie zakłada, więc nie zmieniałem, ale reguła z `## 4. Reguły wyboru` „nie zgadywać techniki, zwrócić pytanie” w 0.1.1 oznacza `user.input` do orkiestratora. Czy dopisać to wprost w kroku 2 Fazy Analizy?

## user zadanie

teraz najważniejsze to odchudzić ten etap1, to co jest w katalogu technik jest najważniejsze, to co zostało w etapie1 a tczy się wprowadzania zmian można usunąć, trzeba usunąć.

Kilka rzeczy pousuwałem już np tryb zadaniowy oraz zminimalizowałem loga


## Claude

### Rezultat zmian (`refactor-legacy-v0.1.0/etap1.md`, 359 → 198 linii)

1. `## Faza Analizy — kroki`, krok 2 (linia 89) — zamieniony na „Wybór techniki dla każdej zależności blokującej testowalność”: rozpoznanie i wybór wyłącznie według `references/etap1/feathers-technique-selection.md`; objaw spoza tabeli → `user.input` do orkiestratora (to odpowiedź na wątpliwość 3).
2. `## Faza Analizy — kroki`, krok 3 (linia 94) — Twój wpis „jest katalog technik…” zastąpiony krokiem „Propozycja do zatwierdzenia”: propozycja do pliku planu i `user.approval` przed Fazą Implementacji. Wcześniej ten warunek był w kroku 3; po Twoim skróceniu zniknął, a sekcja `## Struktura wewnętrzna` dalej go wymaga.
3. `## Faza Analizy — kroki`, krok 4: „propozycja seamu z kroku 3” → „technika z kroku 2”; „Opcja 2 — Jak Opcja 3” → „Jak Opcja 1” (po usunięciu dawnych opcji 1 i 2).
4. `## Faza Implementacji — kroki`, krok 2 (linia 130) — usunięty opis wydzielania metod; zostało tylko odwołanie do sekcji `[n]` w `feathers-dependency-breaking-csharp.md`.
5. `## Faza Implementacji — kroki`, krok 3 (linia 134) — skrócony, treść bez zmian.
6. `## Log Etapu 1` — przykład: usunięty opis „dwie iteracje, druga przerwana” (nie pasował do nowego logu), domknięty blok ```` ```markdown ```` (brakowało zamknięcia, przez co `## Format wyjścia Etapu 1` był wewnątrz bloku kodu).
7. `## Format wyjścia Etapu 1`, punkty 2 i 3 (linia 189) — technika podawana jako litera objawu, numer `[n]` i poziom; uzasadnienie przy poziomie 2 i 3 (to odpowiedź na wątpliwość 2, punkt trzeci).
8. Wątpliwość 1 (DI + fabryka kontra kolejność z pliku wyboru) — rozstrzygnięta przez usunięcie sekcji `## Decyzje (rozstrzygnięte)`: obowiązuje plik wyboru.

### Wątpliwości

1. Kolizja z usuniętym trybem zadaniowym: `etap2.md` (linie 21–22, 109, 209–217, 292) wystawia `test.update` / `test.add` / `test.remove` / `test.mock.enable` / `test.mock.add`, a `orkiestrator.md` (linie 338, 576–580, 592, 641, 694–697) przekazuje je Etapowi 1 jako `task.execute`. Etap 1 tego już nie obsługuje. `etap2.md` linia 217 odsyła też do „Mocki w testach” w `etap1.md` po wybór frameworka mocków, a ta sekcja już tego nie opisuje. Nie zmieniałem — co robimy: usuwamy te zlecenia z Etapu 2 i orkiestratora, czy testy w Etapie 2 zmienia sam Etap 2?
2. `## Struktura wewnętrzna`, linia 68: „Log Etapu 1 odnotowuje przerwanie jako ostatni wpis” — nowy log ma tylko start i zakończenie. Proponuję zapis przerwania jako wpis zakończenia z wynikiem „przerwane przez użytkownika”. Zostawić tak?
3. Do dalszego odchudzenia, jeśli chcesz: sekcja `## Tryby pracy Etapu 1` (linia 29) ma jedno zdanie, które powtarza `## Struktura wewnętrzna` — można usunąć; sekcja `## Struktura wewnętrzna` (linie 44–69) da się skrócić o połowę.

## Claude

Polecenie (z rozmowy): usunąć tryb zadaniowy także z Etapu 2, dostosować kopertę, przerwanie przez użytkownika → wpis w logu, usunąć `## Tryby pracy Etapu 1`, skrócić `## Struktura wewnętrzna`.

### Rezultat zmian

`refactor-legacy-v0.1.0/etap1.md` (198 → 186 linii):
1. Usunięta sekcja `## Tryby pracy Etapu 1`.
2. `## Struktura wewnętrzna: Faza Analizy i Faza Implementacji` (linia 39) — skrócona do trzech akapitów: iteracja, warunek `stage.done`, przerwanie (wpis w logu + `stage.aborted`).
3. `## Log Etapu 1` — dopisana zasada „jeśli użytkownik przerwał — wpis, że użytkownik przerwał (w miejsce wpisu o zakończeniu)” i przykład przerwania. Twoje wpisy w tej sekcji nietknięte.

`refactor-legacy-v0.1.0/etap2.md` — testy z Etapu 1 aktualizuje sam Etap 2:
4. `## Zasada własności testów` zastąpiona sekcją `## Zmiany w testach z Etapu 1` (linia 17): tylko dwa przypadki (Krok 1 — nazwy, Krok 3 — konstruktor i mocki), zmiany zapowiedziane w planie kroku i akceptowane razem z nim, asercje / dane wejściowe / zakres testu nietknięte, każda zmiana w logu.
5. `### Krok 1`, punkt 3 — zamiast requestu `test.update` z `requires_user_ack`: plan wymienia czerwone testy, Etap 2 aktualizuje wyłącznie nazwy.
6. `### Krok 3`, punkt 3 — zamiast `test.update` / `test.mock.add` / `test.mock.enable`: Etap 2 aktualizuje wywołania konstruktora i podstawia mock/stub. Zasada mocków przepisana z `etap1.md` „Mocki w testach”: użyj tego, co jest; jeśli nie ma — utwórz; nie Moq. Brak wiedzy o zachowaniu zależności → `user.input`. Punkty 4 i 5 — „request na testy” / „zgłoszone w punkcie 3” zamienione na aktualizację testów / zapowiedź w planie iteracji.
7. `### Reguła niezaliczonego testu`, punkty 2 i 3 — wykonawcą jest Etap 2.
8. `## Log Etapu 2` — zamiast requestów z `msg_id`: każda zmiana w testach (które testy, przez jaką zmianę w kodzie).
9. `## Format wyjścia Etapu 2`, punkt 4 — „jakie requesty zostaną wystawione” → „jakie zmiany zostaną w nich wprowadzone”.

`refactor-legacy-v0.1.0/orkiestrator.md` (koperta i routing):
10. `## Rola orkiestratora` (linia 68) — usunięty punkt 6 „Routuje requesty między etapami”, numeracja 7–9 → 6–8.
11. `### Zasada nieprzeskakiwania` (linia 329) — usunięty opis routingu zadaniowego; zostało: etapy nie zlecają sobie nawzajem zadań.
12. `### Brama wyjściowa`, warunek 3 (linia 304) — „żaden nie wisi bez `response`” → na każdy request poszedł `stage.resume` z jego `msg_id` w `corr_id`.
13. `### Koperta wiadomości` (linia 539) — usunięte pole `requires_user_ack` (służyło tylko requestom na testy) i typ `response`; `user_message` wymagane dla `user.input`, `user.approval`, `stage.aborted`. Przykład koperty na `user.input`.
14. `### Katalog akcji` (linia 561) — usunięte `test.update`, `test.add`, `test.remove`, `test.mock.enable`, `test.mock.add`, `task.execute` i opis `type: "response"`; `stage.resume` niesie odpowiedź użytkownika w `payload.user_answer`.
15. Przykład „Etap 2 zleca zmianę testu Etapowi 1” zastąpiony przykładem `### Przykład: Etap 2 pyta użytkownika` (linia 581): `user.input` o magic numbers → `stage.resume` z odpowiedzią.
16. `## Pętla sterowania`, punkt 5 „Czuwaj” (linia 660) — usunięty punkt o `test.*` / `task.execute`; odpowiedź na `user.input` / `user.approval` wraca do etapu w `stage.resume`.

### Wątpliwości

1. Transparentność zmian w testach (dawniej `requires_user_ack: true` przed zmianą) — teraz zapewnia ją plan kroku (sekcja „Wpływ na testy z Etapu 1”), akceptowany przed zmianą kodu. Testy czerwone spoza planu = regresja (stop). Jeśli chcesz osobny komunikat do użytkownika tuż przed zmianą testów, trzeba dodać akcję `event` w katalogu.
2. `docs/communication-protocol.md` (katalog główny repo) opisuje kopertę z `requires_user_ack` i akcjami `test.*` — to dokument historii dla wszystkich wersji, nie zmieniałem.

## Claude

Polecenie (z rozmowy): usunąć tryb zadaniowy z orkiestratora, żeby nie przekazywał zadań do Etapu 1; `docs/communication-protocol.md` zostaje bez zmian.

### Rezultat zmian

1. `refactor-legacy-v0.1.0/orkiestrator.md` — tryb zadaniowy usunięty już w poprzedniej porcji (punkty 10–16 wyżej: rola orkiestratora, zasada nieprzeskakiwania, brama wyjściowa, koperta, katalog akcji, przykład, pętla sterowania).
2. Dodatkowo `## Protokół komunikacji orkiestrator ↔ etapy`, akapit wstępny (linia 534): „każda potrzeba działania po stronie innego etapu” → „każda potrzeba decyzji lub informacji od użytkownika”; dopisane zdanie „Orkiestrator nie przekazuje etapom zadań zleconych przez inne etapy.”
3. Sprawdzone wyszukiwaniem w `orkiestrator.md`: brak `task.execute`, `test.*`, `requires_user_ack`, `response`, `resume_point`, „trybu zadaniowego” i routingu do Etapu 1.
4. `docs/communication-protocol.md` — bez zmian.

## Claude

Polecenie (z rozmowy): usunąć tryb test z orkiestratora i ramki.

### Rezultat zmian

`refactor-legacy-v0.1.0/orkiestrator.md` (779 → 600 linii):
1. Usunięte sekcje: `## Tryb uruchomienia (normalny / test)` (z `### Pytanie T` i `### Tryb jako część konfiguracji`) oraz `## Tryb testowy (test)` w całości (izolacja, mock-paczka, brak mocka, odstępstwa, ocena przebiegu, odłożone do kolejnych iteracji).
2. `## Status dokumentu` — usunięte zdanie o trybie testowym i mockach.
3. `## Rola orkiestratora` — usunięty punkt 2 „Ustala tryb uruchomienia”, numeracja 3–8 → 2–7.
4. `### Interpretacja raportu` — bez `refactor-result-test1`.
5. `### Plik stanu sesji` — usunięte pole „Tryb uruchomienia” i akapit o wartości „tak (tryb test — …)”.
6. `### Brama wejściowa` — usunięte zdanie o mocku Etapu 0, „Pytanie T (tryb)” z warunku 1 i wyjątek dla Etapu 3 z warunku 5. `### Brama wyjściowa` — usunięty akapit o trybie test.
7. `## Konfiguracja wstępna` — usunięty akapit o Pytaniu T; w przykładzie `refactor-decisions.md` sekcja „Tryb uruchomienia (Pytanie T)” zamieniona na „Katalog wynikowy”.
8. `### Katalog wynikowy` — jedna nazwa `refactor-resultN`, usunięta tabela trybów i zasada 2 (rozdział katalogów `-test`), numeracja zasad 3–4 → 2–3; kolejność bez „tryb →”.
9. `## Snapshot konfiguracji` — snapshot bez trybu.
10. Ramka: `### Katalog akcji` — `stage.start` bez „(razem z `tryb`)”; `payload.config` nie ma już pola `tryb`.
11. `## Pętla sterowania` — usunięty punkt 0 (Pytanie T) i wtrącenia o trybie test w punktach 1, 2 i 4.
12. `### Log orkiestratora` — bez trybu i mocków; przykład bez wpisu o trybie, numeracja 1–7.

Poza orkiestratorem (konsekwencja usunięcia pola `tryb` i sekcji „Tryb testowy”, do których się odwoływały):
13. `etap0.md` — usunięty akapit „W trybie test Etap 0 nie wykonuje się”, tabela katalogów per tryb zastąpiona listą `refactor-result1`, `refactor-result2`, …; z raportu JSON usunięte pole `tryb` i jego opis.
14. `etap3.md` — usunięty wyjątek dla trybu test; zostało: próba uruchomienia pustego Etapu 3 → `error.critical`.

### Wątpliwości

1. Razem z `## Tryb testowy` zniknęła lista „Odłożone do kolejnych iteracji”. Jedna pozycja nie dotyczyła trybu test: „Plik JSON z konfiguracją harnessu — docelowo może zastąpić pytania wstępne”. Przywrócić ją gdzieś (np. w `## Status dokumentu`)?
2. `etap2.md`, sekcja `## Wariant "Refaktor"` (linia 91), odsyła do „Podstawa metodyczna” w `orkiestrator.md`, a tej sekcji w orkiestratorze już nie ma (usunięta po Twojej stronie). Usunąć odwołanie z `etap2.md`?

## Claude

1. Lista „Odłożone do kolejnych iteracji” była w `refactor-legacy-v0.1.0/orkiestrator.md`, podsekcja `### Odłożone do kolejnych iteracji` w sekcji `## Tryb testowy (test)`; usunięta razem z tą sekcją. Wersja sprzed zmian jest w git: `git show HEAD:refactor-legacy-v0.1.0/orkiestrator.md`, linia 814.
2. Odwołania do „Podstawa metodyczna” w orkiestratorze: w `orkiestrator.md` nie ma już żadnego (wiersze z `feathers-*.md` w tabeli plików i „technika spoza tabeli Feathersa” w katalogu akcji odnoszą się do plików `references/etap1/`, nie do sekcji). Jedyne odwołanie do tej sekcji było w `etap2.md`, sekcja `## Wariant "Refaktor"` (linia 90) — usunięte zdanie „zgodnie z zasadami Fowlera, Feathersa i clean code (patrz "Podstawa metodyczna" w `orkiestrator.md`)”.

## user - zadania

nic nie przywracamy, sekcja odłożonedo kolejnych iteracji już nie wróci.
jest tam taki olbrzymi przykłąd który zaczyna się od brmay etapów, utwórz w tej wersji katalog examples/orchestrator-examples/ tu wrzuć pllik z tymi przykładami i dopisz w orkiestratorze że tu się znajduje, wszystkie przykłady z orkiestratora przenieś w te miejsce, tylko do odpowiedniego pliku, bo plików może być tu wiecej a w samym orkiestratorze odwołania do tych plików


## Claude

### Rezultat zmian

1. Nowy katalog `refactor-legacy-v0.1.0/examples/orchestrator-examples/`, jeden plik na przykład (nagłówek „Przykład — …”, znacznik `wersja-harnessu: 0.1.1`, wskazanie sekcji orkiestratora):
   - `stan-sesji-harnessu.md` — z `### Plik stanu sesji (refactor-session.md)`;
   - `log-decyzji.md` — z `### Log decyzji` (przykład `refactor-decisions.md`);
   - `koperta-wiadomosci.md` — z `### Koperta wiadomości`;
   - `etap2-pyta-uzytkownika.md` — dawna podsekcja `### Przykład: Etap 2 pyta użytkownika` (request `user.input` + dispatch `stage.resume`), podsekcja usunięta z orkiestratora;
   - `log-orkiestratora.md` — z `### Log orkiestratora`.
2. `refactor-legacy-v0.1.0/orkiestrator.md` (600 → 491 linii) — w miejscu każdego przykładu odwołanie do pliku (linie 187, 322, 403, 430, 490); w `## Struktura harnessu (pliki)` nowy wiersz `examples/orchestrator-examples/*.md`. Opis pól koperty (`msg_id`, `corr_id`, `user_message`) został w orkiestratorze.
3. `refactor-legacy-v0.1.0/manifest.json` — `pliki_harnessu` uzupełnione o 5 plików z `examples/orchestrator-examples/`.
4. `.claude/agents/instalationHarnessRefactor.md`, `## Wersje harnessu` — wiersz `0.1.1` uzupełniony o `examples/orchestrator-examples/`.

### Wątpliwości

1. „Olbrzymi przykład, który zaczyna się od bramy etapów” — w orkiestratorze nie było przykładu zaczynającego się od `## Bramy etapów`; bezpośrednio przed tą sekcją kończył się przykład `refactor-session.md`. Przeniosłem wszystkie przykłady, więc ten, o który chodziło, jest wśród nich.
2. W orkiestratorze zostały: blok formatu znacznika czasu `yyyy-MM-dd; HH-mm-ss` w `## Znaczniki czasu w logach` (linie 85–87) i jednoliniowe przykłady znacznika w tekście — to definicja formatu, nie przykład. Przenieść też?
3. `etap0.md` ma własny duży przykład raportu JSON — nie ruszałem, zadanie dotyczyło orkiestratora.

## user zadania

z etapu0 też usuń przykład i wrzuć go w takie samej formie to katalogu examples tylko dla etapu0

jezeli chodzi o formatu znacznika czasu sprawdz jak to jest robione w wersji 0.2.2 tam jest skrypt do tego wiec go skopiuj z tamtej wersji.
usunołme sekscje Snapshot konfiguracji i kontrola integralności sprawdz czy są jakieś odwołania do niej i też usuń

## Claude

### Rezultat zmian

**Przykład z Etapu 0**
1. Nowy plik `refactor-legacy-v0.1.0/examples/etap0-examples/etap0-raport.md` — raport JSON z sekcji `## Wyjście — raport JSON` w `etap0.md`, w tej samej formie co pliki w `examples/orchestrator-examples/`. W `etap0.md` (linia 72) odwołanie do pliku; opis pól pod przykładem został.

**Znacznik czasu — skrypt z 0.2.2**
2. Nowy plik `refactor-legacy-v0.1.0/scripts/wspolne/wpis-logu.ps1` — kopia z `refactor-legacy-v0.2.0/scripts/wspolne/wpis-logu.ps1` z dostosowaniem do 0.1.1:
   - znacznik `wersja-harnessu: 0.1.1`; w opisie logi 0.1.1 (`orkiestrator-log.md`, `etap1-decisions-log.md`, `etap2-decisions-log.md`) i pola JSON (`timestamp`, `generated_at`);
   - usunięty parametr `-Konfiguracja` (czytał `refactor-config.json`, którego w 0.1.1 nie ma) — format stały `yyyy-MM-dd; HH-mm-ss`;
   - nagłówek `zadania` („### Zadania zlecone” — tryb zadaniowy, usunięty) zastąpiony nagłówkiem `sekcja` z parametrem `-Nazwa` → `### <nazwa>`; potrzebny dla nagłówków `### Krok N` / `### Krok N — iteracja M` w logu Etapu 2.
3. `orkiestrator.md`, `## Znaczniki czasu w logach` — jak w 0.2.2: blok formatu zostaje; zasada 4 zastąpiona „Znacznik nadaje skrypt, nie model” (zapis do logu tylko skryptem, Write/Edit zabroniony), nowa zasada 5 (pola czasu w JSON z `-TylkoZnacznik`), blok wywołań skryptu. Usunięty podwójny separator `---` po tej sekcji.
4. `orkiestrator.md`, `## Struktura harnessu (pliki)` — wiersze `scripts/wspolne/wpis-logu.ps1` i `examples/etap0-examples/*.md`.
5. `etap1.md`, `## Log Etapu 1` — pierwsza zasada: wpisy dopisuje wyłącznie skrypt. `etap2.md`, `## Log Etapu 2` — „wczytanym z `refactor-decisions.md`” → wpisy i nagłówki dopisuje wyłącznie skrypt.

**Odwołania do usuniętej sekcji „Snapshot konfiguracji i kontrola integralności”**
6. `orkiestrator.md`:
   - `## Rola orkiestratora` — usunięty punkt „Pilnuje integralności konfiguracji”, numeracja 6–7 → 5–6;
   - `## Znaczniki czasu w logach`, zasada 1 — usunięte „Podlega kontroli integralności…”;
   - `### Interpretacja raportu` — „staje się snapshotem referencyjnym” → „jest wczytywana z `refactor-decisions.md`”;
   - `### Brama wejściowa`, warunek 2 — bez „zgadza się ze snapshotem w pamięci”;
   - `### Brama wyjściowa` — usunięty warunek 5 „Kontrola integralności konfiguracji wypada zgodnie”;
   - `## Pętla sterowania`, punkt 2 — bez „zrób snapshot w pamięci”; punkt 6 — bez „(obejmuje kontrolę integralności)” i „Rozjazd konfiguracji → CRITICAL ERROR”;
   - `### Log orkiestratora` — bez „wynik każdej kontroli integralności”.
7. `etap1.md`, `## Wejście z orkiestratora` — usunięte zdanie o weryfikacji pliku względem snapshotu orkiestratora.

**Instalacja**
8. `manifest.json` — dopisane `examples/etap0-examples/etap0-raport.md` i `scripts/wspolne/wpis-logu.ps1`. `.claude/agents/instalationHarnessRefactor.md`, wiersz `0.1.1` — `examples/`, `scripts/` → `<.claude>/`.

### Wątpliwości

1. Skrypt wymaga `pwsh` (tak jak w 0.2.2). Nie uruchamiałem go.
2. `etap0.md`, `## Wyjście — raport JSON`: „Etap 0 zwraca raport jako `payload.report` w odpowiedzi do orkiestratora” — typ `response` usunąłem wcześniej z koperty. Zmienić na `stage.done` z `payload.report`?
3. Instalator kopiuje `scripts/` i `examples/` bezpośrednio do `<.claude>/` (wersja 0.1.1 nie ma własnego katalogu, `katalog_harnessu` pusty). Jeśli projekt ma już `.claude/scripts/` albo `.claude/examples/`, pliki trafią obok cudzych. Zostawić tak?

## user zadania

zostawiamy tak jak jest
