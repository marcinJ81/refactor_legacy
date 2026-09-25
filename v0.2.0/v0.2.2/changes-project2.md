 ## INfo dla cluade
To jest plik gdzie komunikujemy zmiany, ja podaje swoje ty dopisujesz wątpliwości i rezultaty zmian,
Swoją sekcje oznaczacz Claude
Piszemy zwięźle i bez skrótów, adresujemy dokładnie zmiany i pytania czyli np jaki plik nazwa i nazwa sekcji która linia,
Nie uruchamiamy żadnych dodatkowych narzędzi, to jest etap tworzenia harnessa, testy będę przeprowadzał gdzie indziej
Zmiany są dla refactor-legacy-v0.2.0
korzystasz z dokumentacji:
Hooki

https://code.claude.com/docs/en/hooks.md — zdarzenia (SessionStart, SubagentStart/SubagentStop, PreToolUse, PostToolUse, Stop itd.), schemat matcherów, ${CLAUDE_PROJECT_DIR}/${CLAUDE_PLUGIN_ROOT}, lokalizacje konfiguracji (settings.json / settings.local.json / plugin hooks.json), debugowanie hooków.

Subagenty

https://code.claude.com/docs/en/sub-agents.md — pełna lista pól frontmattera, lokalizacje (.claude/agents/, ~/.claude/agents/, plugin agents/), priorytety, wywoływanie przez Agent tool (subagent_type), hooki we frontmatterze subagenta (PreToolUse/PostToolUse/Stop).

Skille

https://code.claude.com/docs/en/skills.md — frontmatter skilla, progressive disclosure (SKILL.md + pliki referencyjne), limit ~500 linii, zasada „state what to do rather than narrating how or why", hooki we frontmatterze skilla i ich zasięg („rest of session once invoked").

Pluginy (na wypadek gdybyś jednak wrócił do tej opcji przy dystrybucji harnessu)

https://code.claude.com/docs/en/plugins.md — tworzenie pluginu, manifest .claude-plugin/plugin.json, struktura katalogów (agents/, hooks/hooks.json, skills/), namespacing (plugin-name:agent-name).
https://code.claude.com/docs/en/plugins-reference.md — pełna specyfikacja techniczna (nie sprawdzałem jej dziś wprost, ale to źródło, do którego odsyłają powyższe strony po szczegóły schematu manifestu i katalogów).

Ustawienia / precedencja

https://code.claude.com/docs/en/settings.md — kolejność rozstrzygania settings.json vs settings.local.json vs managed policy, co dokładnie idzie do którego pliku.

struktura:
<refactor-legacy-v0.2.0>/
├── orkiestrator.md
├── refactor-config.example.json
├── .claude/
│   ├── settings.json              ← hooki tutaj (SubagentStart, matcher etap0)
│   ├── hooks/
│   │   └── etap0-start.ps1        ← opakowanie hooka Etapu 0
│   └── agents/
│       ├── etap0.md
│       └── etap1/
│           ├── step1.md
│           └── step2.md
├── scripts/
│   ├── etap0/
│   │   ├── 00-rozpoznanie.ps1
│   │   └── _wspolne.ps1
│   └── step1/
│       ├── 00-brama.ps1
│       ├── 01-pliki.ps1
│       ├── 02-sekcje.ps1
│       ├── 03-json.ps1
│       ├── 04-licznik.ps1
│       ├── _wspolne.ps1
│       └── eraser/
│           └── 00-eraser.ps1
└── orchestrator-examples/
|__ references/
        |-etap1-step1
            |- feathers-technique-selection.md
            |- feathers-dependency-breaking-csharp.md

struktura będzie dostosowywana
##

## User - zadanie
Dodaj do plików agentów model z jakiego mają korzystać i sposbó zachowania:
etap 0 - model sonnet effort high
step1 - model opus effort high
step2 - model sonnet effort medium

zachowanie - automat

### Claude
Wprowadzone (edycję plików wykonał user — klasyfikator trybu auto zablokował Claude zapis w `.claude/agents/`; Claude zweryfikował treść na dysku):
- `refactor-legacy-v0.2.0/.claude/agents/etap0.md`, frontmatter: `model: sonnet`, `effort: high`, `permissionMode: auto`.
- `refactor-legacy-v0.2.0/.claude/agents/etap1/step1.md`, frontmatter: `model: opus`, `effort: high`, `permissionMode: auto`; `name` zmienione z `step1 - analize` na `step1`.
- `refactor-legacy-v0.2.0/.claude/agents/etap1/step2.md`, dodany frontmatter (wcześniej brak): `name: step2`, `description`, `model: sonnet`, `effort: medium`, `permissionMode: auto`.

Interpretacja: „zachowanie - automat" = `permissionMode: auto` (tryb automatyczny według https://code.claude.com/docs/en/sub-agents.md — klasyfikator w tle ocenia wywołania narzędzi zamiast pytać użytkownika).

Uwagi:
- Interakcja `permissionMode: auto` subagenta z trybem uprawnień głównej sesji nie była sprawdzana — do weryfikacji w testach.
- Nikt w harnessie nie odwołuje się do starych nazw agentów (`step1 - analize`) — sprawdzone grep w `refactor-legacy-v0.2.0/`.

## User - zadanie
