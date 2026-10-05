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


Zrób readme, to ma być skrót tego co jest w całym projekcie, napisz w dwóch jezykach polski i angielski

### Claude
Zrobione: `README.md` w katalogu głównym repozytorium (nadpisany dotychczasowy jednolinijkowy plik). Dwie sekcje: „Polski" i „English", w każdej: idea harnessu, tabela przebiegu (Etap 0 – Etap 3 ze statusem), struktura repozytorium, instalacja (skrót `instalationInfo.md`).
Wątpliwość: README opisuje wersję 0.2.2 — przy kolejnej wersji trzeba zaktualizować numer w obu sekcjach (linie „Bieżąca wersja" / „Current version" i tabele struktury). Czy dopisać `README.md` do listy plików z numerem wersji w zasadzie z linii 7?
