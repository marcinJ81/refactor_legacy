# Instalacja harnessu w projekcie

Harness jest kopiowany do katalogu refaktorowanego projektu. Sesja Claude Code
startuje w katalogu projektu — wtedy `${CLAUDE_PROJECT_DIR}` wskazuje projekt,
a agenci i hooki z `<projekt>/.claude/` są wczytywani automatycznie.

## Kopiowanie

| Z harnessu (`refactor-legacy-v0.2.0/`) | Do projektu |
|---|---|
| `.claude/agents/` | `<projekt>/.claude/agents/` |
| `.claude/hooks/` | `<projekt>/.claude/hooks/` |
| `.claude/settings.json` | `<projekt>/.claude/settings.json` |
| `orkiestrator.md`, `refactor-config.example.json`, `scripts/`, `references/`, `orchestrator-examples/`, `etap1-step1-examples/` | `<projekt>/.claude/refactor-legacy/` |

Nie kopiujemy: `INSTALACJA.md`.

Jeśli projekt ma już `.claude/settings.json` — nie nadpisuj go, dopisz do niego
sekcję `hooks` z `.claude/settings.json` harnessu (zdarzenia `SubagentStart`
i `SubagentStop`).

## Wynikowa struktura w projekcie

```
<projekt>/
└── .claude/
    ├── settings.json            ← hooki: SubagentStart (etap0), SubagentStop (step2)
    ├── hooks/
    │   ├── etap0-start.ps1
    │   └── step2-stop.ps1
    ├── agents/
    │   ├── etap0.md
    │   └── etap1/
    │       ├── step1.md
    │       └── step2.md
    └── refactor-legacy/         ← katalog harnessu
        ├── orkiestrator.md
        ├── refactor-config.example.json
        ├── scripts/
        ├── references/
        ├── orchestrator-examples/
        └── etap1-step1-examples/
```

Hooki wyznaczają katalog harnessu ze swojego położenia:
`<projekt>/.claude/hooks/` → `<projekt>/.claude/refactor-legacy/`.

## Uruchomienie

1. W katalogu projektu uruchom `claude`.
2. Zaakceptuj zaufanie katalogu (workspace trust) — bez tego hooki projektu
   nie działają.
3. Polecenie startowe: `Wczytaj .claude/refactor-legacy/orkiestrator.md i uruchom harness.`

Wymagany `pwsh` (PowerShell 7) w `PATH` — komendy hooków w `settings.json`
wołają `pwsh`.
