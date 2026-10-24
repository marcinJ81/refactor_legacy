 ## INfo dla cluade
To jest plik gdzie komunikujemy zmiany, ja podaje swoje ty dopisujesz wątpliwości i rezultaty zmian,
Swoją sekcje oznaczacz Claude
Piszemy zwięźle i bez skrótów, adresujemy dokładnie zmiany i pytania czyli np jaki plik nazwa i nazwa sekcji która linia,
Nie uruchamiamy żadnych dodatkowych narzędzi, to jest etap tworzenia harnessa, testy będę przeprowadzał gdzie indziej
Zmiany są dla refactor-legacy-v0.3.0
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
|-refactro-legacy-v0.3.0
    |-etap0
    |-etap1
    |-etap2
    |-etap3
    |-orkiestrator
    |-references
        ├── feathers-technique-selection.md
        └── feathers-dependency-breaking-csharp.md


struktura będzie dostosowywana
## Uwagi - reguły
-  Claude nie będzie zmieniał nic w pliku orkiestrator.md ani w plikach poszczególnych etapów, chyba napiszę że trzeba coś zmienić
- pomoc claude polega na odczycie plików harnessa, analize i przedstawieniu w pliku changes jakie zmiany należy wprowadzić
- dodatkowo do każdego pliku zadania będzie powstawał plik odpowiedzi tworzony przez claude, będą tam odpowiedzi do konkretnych zadań **w tym pliku claude nie może nic zmienić**
stwórz plik changes-project2-odpowiedzi2.md
##

## User - zadania1

etap0 został zrobiony pseudo kodem,
ale poniżej pseudo kodu jest opis czyli co było wcześniej,
ten psuedo kod na razie jest testem, sprawdz mi to tylko jeszcze nie wiem do czego to porównać bo nie ma bazy takiego kodu.
Na początek zrób mi plik z deklaracjami tych metod których tam użyłem, to będzie info dla agenta jak ma interpretować ten kodem
opisze ci po krótce co mają robić poszczególne metody. założenie jest takie że to są kontrakty i realizacja kontraktu będzie zależeć od LLM-a, jak on to zrobi to nie ma znaczenia, ja potrzebuje otrzymać odpiwiedni wynik dając paramtery wejściowe

enumy to wiadomo co to jest, trzeba będzie je przenieśc do osobnego pliku który będzie współdzielony, reszte też na razie testuje wiec trochę po omacku,

flow name.start - to będzie blok głównych instrukcji do wykonania

Metoda będzie zwracać nazwę katalogu, przyjmować będzie typ paramteru, w moim przykładzie regex, drugi parametr to patern według którego trzeba szukać
string FindDictionary(string typeParameter, string dictionaryPattern)

metoda tworząca katalog m zwraca nazwę katalogu który tworzy, pierwszy parametr to główny katalog który musi być stworzony jako pierwszy a potem tworzony jest katalog wewnętrzny, i ten jest zwracany

directory = CraeteDirectory("comunication","refactor-result1")

Frame to jest ramka wiadomości jest opisana w pliku etap0

Ta metoda zwraca listę katalogów a paramtetrem jest z jakiego katalogu
directories = GetDiretories("directory")

a widzę już błąd CreateDirectory powinien wpierw stworzyć refactor-result1 a w nim katalog communication ale musi zwrócić właśnie refactor-result1, bo to jest główny katalog z komunikacja i logami

jeszcze jedna rzecz jest do rozważenia, trzeba będzie przemycić do etapu0 katalog w którym ma szukać ale to powinien być katalog projektu w którym zainstalowałem harnessa,
Te teksty, usunę jak mój pseudo kod będzie działał

a potem testy

## user zadanie2
Etap0 został przerobiony na programowanie kontraktowe według Meyera, jego wzorzec progrmaowani kontraktowego pozostanie wzorem do budowania orkiestratora,

w orkiestratorze dopisałem  kotnrakt, nie jestem jeszcze obyty w  tym wiec na razie to jest moja prób interpretacji tego, jak wygląda kod w etap0, dopisz zmiany w tym pliku, nie ma go to stwórz plik changes-project2-odpowiedzi2.md

bedziemy orkiestratora robić korok po kroku nie całość mały mi fragmentami póki nie zrozumiem jak dzałają kontrakty, na razie kontrakt który mówi o uruchomieniu etapu0
na wstępie daje frame który idzie do agenta etap0 który to frame mówi o uruchomieniu agenta, potem
następuje frame od agenta do orkiestratora, w sumie tam powinno być więcej warunków, bo from będzie etap0 to orkiestrator, mam tam przykłady gdzie coś się udaje albo nie, invariantów jeszcze nie wiem jakie mogą być.
mam tam jakby kolejne kontrakty wywołane bo tak to rozumiem,
nie zmieniaj nic w orkiestratorze tylko w pliku z odpowiedziami daj mi wskazówki jak to powinno wyglądać
