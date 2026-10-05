 ## INfo dla cluade
To jest plik gdzie komunikujemy zmiany, ja podaje swoje ty dopisujesz wątpliwości i rezultaty zmian,
Swoją sekcje oznaczacz Claude
Piszemy zwięźle i bez skrótów, adresujemy dokładnie zmiany i pytania czyli np jaki plik nazwa i nazwa sekcji która linia,
Nie uruchamiamy żadnych dodatkowych narzędzi, to jest etap tworzenia harnessa, testy będę przeprowadzał gdzie indziej
Zmiany są dla refactor-legacy-v0.2.0
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

Zmień konfiguracje zgodnie z wcześniejszymi ustaleniami, łącznie z orkiestratorem i przykładami,
do konfiguracji trzeba by wpisać skąd będzie harness uruchamiany żeby można było podmienić  ścieżke,
dostosuj do tego konfiguracje przykłądy oraz te wywołania które mają ściężke.
Chyba że łatwiej było by coś ustalić na początku żeby nie trzeba było zmian, tzn. instrukcja dla uruchomienia harnessa

### Claude
Decyzje (pytania w sesji): harness **kopiowany do projektu**; `pytanie_0.build` / `pytanie_0.testy` **zastąpione zgodą**.

Dlaczego nie pole w konfiguracji: `refactor-config.json` powstaje w katalogu wynikowym po Etapie 0, a hooki i agenci są wczytywani z `.claude/` katalogu startu sesji jeszcze przed nim — ścieżki nie da się podmienić z konfiguracji. Ustalenie sposobu uruchomienia na początku usuwa potrzebę podmiany.

Wprowadzone — instalacja i ścieżki:
- Nowy plik `refactor-legacy-v0.2.0/INSTALACJA.md`: co kopiować dokąd (`.claude/agents`, `.claude/hooks`, `.claude/settings.json` → `<projekt>/.claude/`; reszta harnessu → `<projekt>/.claude/refactor-legacy/`), scalanie z istniejącym `settings.json` projektu, struktura wynikowa, polecenie startowe, wymagany `pwsh`.
- `.claude/hooks/etap0-start.ps1` i `.claude/hooks/step2-stop.ps1`: katalog harnessu = `<projekt>/.claude/refactor-legacy/` (wcześniej rodzic `.claude/`); katalog projektu dodatkowo z `CLAUDE_PROJECT_DIR`.
- `orkiestrator.md`, „Struktura harnessu (pliki)": akapit „Ścieżki" (od czego liczone są ścieżki `.claude/…` i pozostałe); w tabeli wiersze `step2-stop.ps1`, `scripts/step2/00-brama.ps1`; wiersz `settings.json` z `SubagentStop`.
- `.claude/agents/etap1/step1.md` (przed „Przykłady są poza tym plikiem") i `step2.md` (pod pierwszym akapitem): jedno zdanie o regule ścieżek.
- `.claude/agents/etap0.md`, „Hook", akapit „Komenda wskazuje…": położenie katalogu harnessu.
- `orkiestrator.md`, pętla 4b': `scripts\step1\eraser\…` → `scripts/step1/eraser/…` (ujednolicenie separatora).

Wprowadzone — konfiguracja:
- `refactor-config.example.json`: `build`, `testy` → `zgoda_build`, `zgoda_testy` (`true` / `false`), nowe `wersja_dotnet` (`framework` / `core` / `net5plus`); `schema_version` 1 → 2 (zmiana znaczenia pól).
- `orchestrator-examples/refactor-config.md`: to samo.
- `orkiestrator.md`, „Pytanie 0": nowe wybory (zgoda na build, zgoda na testy, wersja .NET z logiką wykrycia z `.csproj` + potwierdzenie); akapit „Build i testy — dlaczego domyślnie automatycznie" z tabelą automatyczny/ręczny zastąpiony akapitem „Zgoda na build i testy" — zgoda w konfiguracji to jedyna akceptacja (hook, agent ani orkiestrator nie pytają), `false` → `nie_wykonano`.
- `orkiestrator.md`, „Plik konfiguracji", wartości dopuszczalne; „Przekazanie między krokami", pola obowiązkowe `step.done` Step 2 (`testy_zaimplementowane`, `wykonal` zawsze `hook`); pętla punkt 2; pętla punkt 5 — usunięty `user.input` przy ustawieniu `reczny`; „Log orkiestratora" — kto wykonał build/testy.
- `scripts/etap0/00-rozpoznanie.ps1`, lista pól wymaganych konfiguracji, i `orchestrator-examples/etap0-raport.md`: nowe pola.
- `orchestrator-examples/przekazanie-miedzy-krokami-etapu-1.md`, `step.done` Step 2: `wykonal: "hook"`, `testy_zaimplementowane`, `wejscie_wykonane: step1-zmiany-2.json`; `log-orkiestratora.md` wpis 18: „wykonał hook".
- `.claude/agents/etap1/step2.md`, „Wejście" punkt 4: „zgoda na build/testy, wersja .NET".
- `scripts/step2/00-brama.ps1`: czyta `zgoda_build`, `zgoda_testy`, `wersja_dotnet`, `framework_testow`; brak zgody → `nie_wykonano` z komunikatem; wybór według wersji w `Invoke-Build` / `Invoke-Testy` — same polecenia nadal *(w budowie)*.

Odłożone:
- Polecenia build / testy dla `framework` / `core` / `net5plus` w `scripts/step2/00-brama.ps1`. Do tego potrzebna wskazówka, co budować — ścieżka do `.sln` (nowe pole konfiguracji, np. `projekt.solucja`?) — do decyzji.
- Repozytorium harnessu ma dalej starą strukturę (bez `.claude/refactor-legacy/`); hooki znajdą skrypty dopiero po instalacji według `INSTALACJA.md`.

Pytania:
- Czy zamiast ręcznego kopiowania ma powstać skrypt instalacyjny (np. `instaluj.ps1 -KatalogProjektu …`)?

## User - Zadania

Wprowadzamy zmiany do konfiguracji, użytkownik będzie musiał podać co budować, ścieżke do sln.

Dostosuj plik konfiguracji oraz orkiestrator. Oraz skrypt quality gate dla step2 który buduje i urchamia testy, ale tu uwaga istotna, nie będzie budowania całej solucji tylko wybrane projekty, bo możliwe jest że cała solucja się nie zbuduje a do działa jest potrzebne projekty w których były zmiany albo jakaś sekwencja budowania.

Więc na razie dodaj do konfiguracji coś wstylu sekwencja budowania projektów oraz ścieżka do sln

### Claude
Wprowadzone — konfiguracja (`schema_version` bez zmian = 2, tylko nowe pola):
- `refactor-config.example.json`, `pytanie_0`: nowe pola `solucja` (ścieżka do `.sln`), `sekwencja_budowania` (lista `.csproj` w kolejności budowania), `projekty_testowe` (lista `.csproj` z testami). Ścieżki względem katalogu projektu.
- `orchestrator-examples/refactor-config.md`: to samo z przykładowymi wartościami.
- `scripts/etap0/00-rozpoznanie.ps1`, lista `$wymagane`, i `orchestrator-examples/etap0-raport.md`, `odpowiedzi`: nowe pola (pusta lista = brak).

Wprowadzone — orkiestrator:
- `orkiestrator.md`, „Pytanie 0": nowy wybór „Co budować" — znaczenie trzech pól, solucja nie jest budowana w całości (jej katalog = `SolutionDir`), logika ustalenia (znajdź `.sln`, zaproponuj projekty z fragmentem i ich testy, użytkownik wskazuje sekwencję). Pytanie pada też przy `zgoda_build: false`.
- `orkiestrator.md`, „Zgoda na build i testy": punkt `wersja_dotnet … (w budowie)` zastąpiony opisem poleceń; nowy punkt o budowaniu tylko projektów z sekwencji.
- `orkiestrator.md`, „Plik konfiguracji", wartości dopuszczalne: trzy nowe pola.
- `.claude/agents/etap1/step2.md`, „Wejście" punkt 4 i opis hooka (punkt 2): budowanie projektów z sekwencji, testy z `projekty_testowe`.

Wprowadzone — quality gate Step 2:
- `scripts/step2/00-brama.ps1`: nowy parametr `-KatalogProjektu`; buduje projekty z `sekwencja_budowania` po kolei (pierwszy błąd przerywa), potem projekty testowe spoza sekwencji, potem testy z każdego projektu testowego.
  - `framework`: `MSBuild.exe` (przez `vswhere`, zapasowo PATH) `/restore /t:Build /p:Configuration=Debug /p:RestorePackagesConfig=true /p:SolutionDir=<katalog .sln>`; testy: `vstest.console.exe` na DLL ustalonej przez `msbuild -getProperty:TargetPath`.
  - `core` / `net5plus`: `dotnet build -c Debug /p:SolutionDir=…`, `dotnet test --no-build --logger trx`.
  - Liczby testów z `.trx` (`ResultSummary/Counters`). Logi poleceń i `.trx` w `quality-gate-step2-result/iteracja-N/` (`build-<nr>.log`, `testy-<nr>.log`, `testy-<nr>.trx`).
  - `podsumowanie.json`: dodane `solucja`, `build.projekty`, `testy.projekty` (wynik per projekt, polecenie, log).
  - Brak `solucja` / pliku `.sln` / pusta lista → build `nie_wykonano` z komunikatem.
- `.claude/hooks/step2-stop.ps1`: katalog projektu ustalany zawsze (nie tylko przy względnym katalogu wynikowym) i przekazywany do bramy.

Odłożone:
- Konfiguracja build (`Debug`) zapisana na sztywno w `00-brama.ps1` (`$KonfiguracjaBuild`) — pole w konfiguracji, jeśli potrzebne.
- Sekwencja jest stała na cały przebieg; zmiana per iteracja (np. Step 1 wskazuje projekty ze zmianami) — tylko ręcznie w `refactor-config.json` („Konfiguracja w trakcie przebiegu").
- `step.done` (`step2.md`, tabela „Zakończenie kroku") nie przenosi `projekty` — szczegóły zostają w `podsumowanie.json`.

Wątpliwości (do sprawdzenia w testach):
- `msbuild -getProperty` wymaga MSBuild 17.8+ (VS 2022 17.8). Starsze VS → `nie ustalono DLL projektu testowego`.
- `vstest.console.exe` z NUnit / xUnit wymaga adaptera w projekcie testowym (`NUnit3TestAdapter`, `xunit.runner.visualstudio`).
- Restore `packages.config` przez `/restore /p:RestorePackagesConfig=true` per projekt — przy starszych projektach może być potrzebny `nuget.exe restore <sln>`.

## User - zadania

Dodaj prewnecyjnie dla ściezki .net framework restora pakietu nuget, bo ja mma akurat takie środowisko co tego wymaga, a wychodzę z założenia że lepiej mieć niż miało by nie działać.
Uzupłenij tylko o to

### Claude
Wprowadzone:
- `scripts/step2/00-brama.ps1`: nowe funkcje `Find-NuGet` i `Invoke-RestoreNuGet`; w `Invoke-Build`, tylko dla `wersja_dotnet: framework`, przed MSBuild każdego projektu: `nuget.exe restore <csproj> -SolutionDirectory <katalog .sln> -NonInteractive` (pakiety do `<katalog .sln>/packages`). Log: `restore-<nr>.log`. Wynik restore w `build.projekty[].restore` (`ok` / `blad` / `pominieto`).
  - Restore wykonywany tylko, gdy obok `.csproj` leży `packages.config` (projekty PackageReference obsługuje `MSBuild /restore`).
  - `nuget.exe` szukany w PATH; brak → `pominieto` z komunikatem, build idzie dalej z `MSBuild /restore`.
  - Błąd restore → build `blad`, sekwencja przerwana.
- Komentarz nagłówkowy `00-brama.ps1` i `orkiestrator.md`, „Zgoda na build i testy", punkt `wersja_dotnet`: opis kroku restore.

Wątpliwości:
- `nuget.exe` tylko z PATH (nie ma go w instalacji VS). Jeśli u Ciebie leży w innym miejscu — dodać do PATH albo pole w konfiguracji.

## User zadania

Trzeba zmienić wpisy czasu  w logach, testy wykazały dziwne zachowanie w tym miejsciu podawania czasu to wygląda jakby raz było wpisane i powielone a nie o to mi chodzi.
na początek mała analiza kiedy idzie wpis do loga, potem rozwiązanie, wypisz tutaj miejsca kiedy jest wpis

### Claude
Analiza (bez zmian w harnessie — czekam na decyzję co do rozwiązania).

Przyczyna:
- Wszystkie trzy logi (`orkiestrator-log.md`, `step1-log.md`, `step2-log.md`) pisze **model** (orkiestrator / agent kroku) narzędziem Write/Edit, a nie skrypt. Model nie ma zegara: zna najwyżej datę z kontekstu sesji, godziny nie zna wcale. Znacznik jest więc wymyślany — raz na początku, a potem powielany albo „przesuwany" o kilka sekund. To jest zachowanie, które widać w testach.
- `orkiestrator.md`, „Znaczniki czasu w logach", zasada 4 („moment podjęcia decyzji, nie moment zapisu") dodatkowo zachęca do wpisywania czasu z pamięci.
- Prawdziwy czas (`Get-Date`) mają tylko skrypty: `scripts/step1/_wspolne.ps1` (`Get-Znacznik`, pole `timestamp` w JSON-ach bramy), `scripts/step2/00-brama.ps1` (`Get-Znacznik`, `podsumowanie.json`), `scripts/etap0/_wspolne.ps1`. One nie piszą do logów `.md`.

Miejsca, w których powstaje wpis do loga (wszystkie pisze model):

`orkiestrator-log.md` — pisze orkiestrator:
1. `orkiestrator.md`, „Rola orkiestratora", punkt 7 (linia ~121) — zasada ogólna.
2. `orkiestrator.md`, „Etap 0 i wznowienie sesji" → „Przebieg", punkt 4 (linia ~190) — nagłówek `## Uruchomienie`, wczytanie raportu Etapu 0, decyzja kontynuacja / nowa sesja, zapis `refactor-session.md`.
3. `orkiestrator.md`, „Bramy kroków (Etap 1)" (linie ~353, ~382) — wynik bramy Step 1, zużycie ponowienia, eraser.
4. `orkiestrator.md`, „Przekazanie Step 1 → Step 2" (linia ~439) i „Iteracje i wznawianie" (linia ~464) — quality gate Step 1, korekta liczby iteracji.
5. `orkiestrator.md`, „Pętla sterowania orkiestratora", punkty 2, 4, 5, 6 (linie ~811, ~835, ~842, ~867) — decyzja wznowienia, start/koniec etapu i kroku, routing requestów, `stage.aborted`, wynik bramy wejściowej/wyjściowej.
6. `orkiestrator.md`, „Log orkiestratora" (linia ~875) — pełna lista wpisów obowiązkowych.
7. `.claude/agents/etap0.md`, „Log Etapu 0" (linia ~180) — Etap 0 nie ma własnego logu, jego przebieg wpisuje orkiestrator.

`step1-log.md` — pisze agent Step 1:
8. `.claude/agents/etap1/step1.md`, „Log Step 1" (linia ~312) — nagłówek `## Uruchomienie`, `### Iteracja N`, każda decyzja, deklaracja liczby iteracji, zapis każdego pliku wyjściowego.
9. `.claude/agents/etap1/step1.md` (linia ~177) — wybór kierunku zmiany.

`step2-log.md` — pisze agent Step 2:
10. `.claude/agents/etap1/step2.md`, „Log Step 2" (linia ~174) — nagłówek, iteracja, lista testów, wynik quality gate z hooka, `step.done`, przerwanie.
11. `.claude/agents/etap1/step2.md`, „Przebieg" punkt po hooku (linia ~72) — wpisy po wyniku hooka.
12. `.claude/agents/etap1/step2.md`, tryb zadaniowy punkt 6 (linia ~171) — każde zadanie zlecone.

Ten sam problem (czas wymyślany przez model) poza logami:
13. Pole `timestamp` w `step.done` Step 1 i Step 2 oraz w kopercie wiadomości (`orkiestrator.md`, „Koperta wiadomości"; `step2.md` linia ~126; przykłady w `orchestrator-examples/`, `etap1-step1-examples/step-done.md`). Etap 0 wiąże sesje po znacznikach (`scripts/etap0/00-rozpoznanie.ps1`), więc błędny czas psuje też rozpoznanie wznowienia.

Proponowane rozwiązanie:
- Nowy skrypt `scripts/wspolne/wpis-logu.ps1 -Plik <log> -Tresc "<treść>" [-Naglowek uruchomienie|iteracja -Iteracja N]` — dopisuje linię na końcu pliku ze znacznikiem z `Get-Date` w formacie `yyyy-MM-dd; HH-mm-ss` (numer wpisu dalej podaje model w treści). Model **nie pisze znacznika sam**; jedyną drogą dopisania wpisu do logu jest ten skrypt (Bash).
- Drugi tryb tego samego skryptu: `-TylkoZnacznik` — wypisuje bieżący znacznik, do wstawienia w pole `timestamp` JSON-ów (`step.done`, koperta).
- Zmiany w opisach: `orkiestrator.md`, „Znaczniki czasu w logach" — zasada „znacznik nadaje skrypt, nie model", usunięcie zasady 4; `step1.md`, „Log Step 1", `step2.md`, „Log Step 2" — wywołanie skryptu zamiast zapisu ręcznego; tabela „Struktura harnessu (pliki)" — nowy wiersz.
- Koszt: jedno wywołanie Bash na wpis (zamiast Write/Edit) — liczba wywołań narzędzi się nie zmienia.
- Odrzucone: hook `PostToolUse` na Write/Edit podmieniający znaczniki w logu — hook nie wie, które wpisy są nowe, a przy Write całego pliku nadpisałby stare znaczniki.

Pytanie:
- Czy wprowadzać to rozwiązanie (skrypt dla logów + `-TylkoZnacznik` dla `timestamp` w JSON)?

## User zadanie

dodaj skrypt, zobaczymy jak to będzie wyglądać po testach,

## User
tak dodaj skytp, na razie hooka nie robimy

### Claude
Wprowadzone:
- Nowy `scripts/wspolne/wpis-logu.ps1`: znacznik z `Get-Date` w chwili wywołania. Tryby: `-Tresc "<nr>. <treść>"` → `<znacznik> — <nr>. <treść>`; `-Naglowek uruchomienie` → `## Uruchomienie <znacznik>`; `-Naglowek iteracja -Iteracja N` → `### Iteracja N`; `-Naglowek zadania` → `### Zadania zlecone`; `-TylkoZnacznik` → sam znacznik na wyjście, bez zapisu. `-Tytul` tworzy plik z `# <tytuł>`; `-Konfiguracja` czyta format z `harness.znacznik_czasu`. Zapis UTF-8 bez BOM, dopisywanie na końcu pliku.
- `orkiestrator.md`, „Struktura harnessu (pliki)": wiersz `scripts/wspolne/wpis-logu.ps1`.
- `orkiestrator.md`, „Znaczniki czasu w logach": zasada 4 („moment decyzji, nie zapisu") zastąpiona zasadą „znacznik nadaje skrypt, nie model" (zakaz zapisu logu przez Write/Edit); nowa zasada 5 — pola czasu w JSON (`timestamp`, `utworzono`, `zaktualizowano`) z `-TylkoZnacznik`; blok z czterema wywołaniami.
- `orkiestrator.md`, „Log orkiestratora": wpisy tylko skryptem, tytuł `Log orkiestratora`.
- `orkiestrator.md`, „Koperta wiadomości": punkt `timestamp`; `orchestrator-examples/koperta-wiadomosci.md`: `"timestamp": "<wpis-logu.ps1 -TylkoZnacznik>"`.
- `.claude/agents/etap1/step1.md`, „Log Step 1", i `.claude/agents/etap1/step2.md`, „Log Step 2": nowy punkt — wpisy tylko skryptem, `timestamp` w `step.done` z `-TylkoZnacznik`; `step2.md`, „Przebieg" punkt 3: „dopisuje wpisy w logu (skryptem …)".

Odłożone:
- Hook (zgodnie z decyzją).
- Przykłady logów (`log-orkiestratora.md`, `log-step1.md`) bez zmian — format wyniku jest taki sam.

Wątpliwości (do sprawdzenia w testach):
- Agenci mają `permissionMode: manual` — każde wywołanie `pwsh … wpis-logu.ps1` może wymagać zgody. Do decyzji: reguła `allow` w `.claude/settings.json` (np. `Bash(pwsh -NoProfile -File .claude/refactor-legacy/scripts/wspolne/wpis-logu.ps1:*)`).
- Treść wpisu z cudzysłowami / `$` w `-Tresc` — model musi poprawnie cytować w Bash; przy problemach zamiana na pojedyncze cudzysłowy.

## User zadania

Teraz kwestia instrukcji,
trzeba zrobić tak żeby na początek zainstalować ten harness a właściwie odpowiednio go przekopiować
Wybeiramy systuacje gdzie user ma ściagnięte pliku na dysk wybiera ktalog źródłowy i wersje harnesa aktualnie są dwie.
Wersja 0.1.0 jest prosta ponieważ wystarzy przekopwiać pliki orkiestratora oraz etapów do katalogu .claude projektu albo solucji a potem załadować orkiestratora
Wersja 0.2.0 jest sprawa bardziej skomplikowana, tutaj trzeba skopiować katalogi:
- etap1-step1-examples
- orchestrator-examples
- refences
- scripts
plik orkiestrator.md oraz refactor-onfig.example.json
dodatkowo mamy hooki i agentów powyższe rzeczy wystarczy skopiować ale hooks i agents należy dodać do katalogu .claude oraz dołaćzyć wpis do pliku setting.json lub settings.local.json.

Teraz uwaga do realizacji stwórz plik w formie agenta, trudno instalcje trzeba będzie przeprowadzać jako agent ze skryptami.
Agent będzie miał jako name ustawione instalationHarnessRefactor, description opis typu instalacja harnessa do refaktryzacji , na razie tyle potem uzupełnie to ręcznie.

Przed startem instalacji pytanie do usera o katalog źródłowy i docelowy - tu bardziej projekt bo ten harnes musi być w projekcie uruchamiany.
Potem agnet musi sprawdzić czy docelowe pliki są w odpowiedniej wersji od teraz numerujemy każdy plik ma mieć w opisie numer wersji zaczynamy od wersji 0.2.2 a wersja druga to wersja 0.1.0 -ta nie będzie rozwijanam, przynajmniej na razie.

Sprawdzenie wersji to poprostu sprawdzenie źródła czy są wszystkie katalogi i pliku potrzebne do poprawnego działania, potem spradzenie miejsca docelowego, czyli zaczynamy od wersji jeżeli wykryta została wersja niższa to wrzucały ze źródła nowszą jeżeli źródło jest starsze niż miejsce docelowe info że jest nowsza wersja wgrana, jeżeli są takie same to info że już jest, jeżeli w miejscu docelowym brakuje czegoś info że brakuje i opcja wgrania ale wszystkiego,
Jeżeli w źródle brakuje czegoś no to info że żródło ma braki i nie można zainstalować.

Z reguły hooks i agents będzie w główym katalogu .claude dotyczącym całego rozwiazania solucji ale użytkownik i tak musi podać lokalizacje. ustawienia odnośnie hooków muszą być dodane do istniejacych nie może być tak że cały plik setting będzie nadpisany, ona ma być tylko rozszerzony, jeżeli go nie ma to trzeba go dodać, to samo z katalogiem.claude,
Przed ruchomieniem trzeba spytać o uprawnienia do katalogu źródłowego i docelowego.
Bedzie też log instalacji tym razem same kroki tu czas nie ma znaczenie, ten log to tylko po to żeby było widać co było zrobione, będzie też podsumowaniem zadania instalacyjnego z instrukcją co należy potem wpisać i inforamcją że kontektst przed uruchomieniem harnesa powinien być wyczyszzony przez użytkownika. dotychczasowy plik instrukcji trzeba usunąć

### Claude
Wprowadzone — agent instalacyjny:
- Nowy `.claude/agents/instalationHarnessRefactor.md` (w katalogu głównym repozytorium, nie w harnessie): `name: instalationHarnessRefactor`, `description` — instalacja harnessu do refaktoryzacji. Uruchomienie: `claude --agent instalationHarnessRefactor` w katalogu z pobranymi plikami. Agent działa jako główna sesja (nie subagent), bo tylko tak ma narzędzie do pytań do użytkownika (AskUserQuestion jest odcięty w subagentach — `sub-agents.md`, „Available tools").
- Przebieg w agencie, sekcja „Przebieg": 1. pytania (katalog źródłowy, katalog docelowy, lokalizacja `.claude` — domyślnie `<docelowy>/.claude`); 2. zgoda na odczyt źródła i zapis w `.claude` (brak zgody → koniec); 3. lista wersji w źródle, wybór wersji, dla 0.2.2 wybór `settings.json` / `settings.local.json`, sprawdzenie kompletu źródła (braki → instalacja niemożliwa); 4. stan celu: `brak` / `starsza` → instalacja, `taka_sama` → info, `nowsza` → info, `niekompletna` → lista braków + pytanie „wgrać wszystko"; 5. instalacja; 6. podsumowanie z instrukcją (nowa sesja w katalogu nadrzędnym `.claude`, `/clear` przed startem, polecenie startowe).
- Agent nie kopiuje i nie edytuje plików sam — tylko skrypty.

Wprowadzone — skrypty `instalator/scripts/`:
- `_wspolne.ps1`: odczyt wersji pliku, porównanie wersji, odczyt manifestów, mapa źródło → cel, `Merge-Settings` (rozszerza tylko sekcję `hooks`; wpis harnessu rozpoznawany po nazwie skryptu w `.claude/hooks/` — brak → dodaje, inny → podmienia, ten sam → bez zmian; inne klucze i hooki nietknięte; brak pliku → tworzy; kopia `<plik>.przed-instalacja.bak` przed zapisem), `Add-KrokLogu`.
- `01-zrodlo.ps1` (wersje w źródle / komplet plików wersji), `02-cel.ps1` (status miejsca docelowego), `03-instaluj.ps1` (kopiowanie z nadpisaniem, tworzenie `.claude` i podkatalogów, rozszerzenie ustawień), `log-instalacji.ps1` (nagłówek / krok / blok).
- Log: `<.claude>/instalacja-harnessu-log.md` — same kroki, numerowane, bez czasu; każde uruchomienie to nowa sekcja `## Uruchomienie instalatora`, na końcu `## Podsumowanie`.

Wprowadzone — wersjonowanie:
- Znacznik w każdym pliku `refactor-legacy-v0.2.0/` (`0.2.2`) i `refactor-legacy-v0.1.0/` (`0.1.0`): `.md` — `<!-- wersja-harnessu: X.Y.Z -->` pod frontmatterem albo pod pierwszym nagłówkiem; `.ps1` — linia `wersja-harnessu: X.Y.Z` w komentarzu nagłówkowym; `refactor-config.example.json` i `orchestrator-examples/refactor-config.md` — pole `"wersja_harnessu": "0.2.2"`.
- Nowe `refactor-legacy-v0.2.0/manifest.json` i `refactor-legacy-v0.1.0/manifest.json`: wersja, katalog harnessu w `.claude` (`refactor-legacy` / pusty = sam `.claude`), plik startowy, `pliki_harnessu`, `pliki_claude`, `settings`. Manifest zostaje w źródle (nie jest kopiowany).
- Pliki instalatora mają osobny znacznik `wersja-instalatora: 0.2.2` (nie są częścią harnessu).

Wprowadzone — porządki:
- Usunięty `refactor-legacy-v0.2.0/INSTALACJA.md`. Odwołania zamienione na agenta instalacyjnego: `orkiestrator.md` akapit „Ścieżki", `.claude/agents/etap0.md` sekcja „Hook", komentarze w `.claude/hooks/etap0-start.ps1` i `step2-stop.ps1`.
- `orkiestrator.md`, tabela „Struktura harnessu (pliki)": nowy wiersz `manifest.json`; wiersz `.claude/settings.json` — w projekcie plik jest rozszerzany, nie nadpisywany.

Decyzje podjęte bez pytania (do weryfikacji):
- Harness zawsze w `<.claude>/refactor-legacy/` tej samej `.claude`, w której są agenci i hooki — tego wymagają hooki (katalog harnessu wyznaczany ze swojego położenia) i ścieżki w agentach. Rozdzielenie (agenci/hooki w `.claude` solucji, harness w `.claude` projektu) wymagałoby przepisywania ścieżek przy instalacji.
- Wersja 0.1.0 instalowana bezpośrednio do `<.claude>/` (zgodnie z opisem). Przy instalacji 0.2.2 na 0.1.0 pliki 0.1.0 zostają — agent informuje, że można je usunąć ręcznie.
- Pliki bez znacznika wersji w celu traktowane jak starsza wersja → instalacja.
- `.claude/settings.json` harnessu bez znacznika wersji — jest scalany, nie kopiowany, a dodatkowy klucz mógłby nie przejść walidacji ustawień. Kompletność sprawdzana po obecności wpisów hooków.

Wątpliwości (do sprawdzenia w testach):
- `ConvertTo-Json` przy zapisie przeformatowuje plik ustawień projektu (wcięcia, kolejność bez zmian) — treść zachowana, kopia zapasowa obok.
- Katalog docelowy spoza katalogu startu sesji — Claude Code będzie pytał o dostęp; ewentualnie start z `--add-dir <projekt>`.
- Znacznik wersji w treści agentów (`<!-- … -->` pod frontmatterem) trafia do promptu agenta — bez wpływu na działanie, ale do obejrzenia.

## user zadanie

dodaj plik instalationInfo.md w którym napisz że trzeba ręczenie wrzucić pliki potrzebne do instalcji

### Claude
Wprowadzone:
- Nowy `instalationInfo.md` w katalogu głównym repozytorium: pliki instalatora trzeba wrzucić ręcznie — `.claude/agents/instalationHarnessRefactor.md` → `<katalog startu>/.claude/agents/`, `instalator/scripts/` → `<katalog startu>/instalator/scripts/`; obok katalogi wersji harnessu (albo ich ścieżka jako katalog źródłowy); wymagany `pwsh`; polecenie `claude --agent instalationHarnessRefactor`.
