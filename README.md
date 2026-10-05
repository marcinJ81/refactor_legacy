# refactor-legacy

[Polski](#polski) · [English](#english)

---

## Polski

**refactor-legacy** to harness dla Claude Code do bezpiecznej refaktoryzacji
i wprowadzania zmian w kodzie legacy .NET (Framework / Core / .NET 5+).
Bieżąca wersja: **0.2.2** (`refactor-legacy-v0.2.0/`).

### Idea

- **Orkiestrator** (`orkiestrator.md`) jest jedynym punktem wejścia. Sam nie
  refaktoruje ani nie analizuje kodu — uruchamia etapy, pilnuje ich kolejności,
  sprawdza bramy wejściowe i wyjściowe, routuje requesty i prowadzi log.
- **Etapy i kroki** to subagenty (`.claude/agents/`). Nie wywołują się
  nawzajem — każde przejście idzie przez orkiestratora.
- **Komunikacja** odbywa się wiadomościami JSON o stałej kopercie (11 pól),
  zapisywanymi na dysku (`docs/communication-protocol.md`).
- **Konfiguracja** przebiegu jest w jednym pliku `refactor-config.json`
  (szablon: `refactor-config.example.json`).
- **Wyniki** (logi, plany, wiadomości, wyniki bram) trafiają do katalogu
  `refactor-resultN` w refaktorowanym projekcie; istniejący katalog nigdy nie
  jest nadpisywany.
- **Deterministyczne skrypty PowerShell** (`scripts/`) wykonują rozpoznanie
  stanu, quality gates i zapis logów — nie agent.

### Przebieg

| Etap | Rola | Status |
|---|---|---|
| Etap 0 | Rozpoznanie stanu: nowe uruchomienie czy wznowienie sesji (hook `SubagentStart` → skrypt rozpoznania) | opisany |
| Konfiguracja wstępna | Pytania 0–2: wybory obowiązkowe, granulacja, struktura plików, zakres etapów | opisana |
| Etap 1 / Step 1 | Analiza (opus): dobór technik Feathersa, instrukcje dla implementacji; zamknięcie — quality gate skryptami `scripts/step1/`, przy porażce jedno ponowienie z eraserem | opisany |
| Etap 1 / Step 2 | Implementacja (sonnet): seamy i testy; zamknięcie — hook `SubagentStop` uruchamia build + unit testy | opisany |
| Etap 2 | Wprowadzenie zmiany (Refaktor / Zmiana logiki) | w budowie |
| Etap 3 | Refaktoryzacja rezultatu Etapu 2 | do zdefiniowania |

Obowiązuje happy path; większość ścieżek błędu jest w budowie.

### Struktura repozytorium

| Ścieżka | Zawartość |
|---|---|
| `refactor-legacy-v0.2.0/` | Bieżący harness (0.2.2): orkiestrator, agenty, hooki, skrypty, przykłady, referencje, `manifest.json` |
| `refactor-legacy-v0.1.0/` | Wersja 0.1.0 (nierozwijana) |
| `.claude/agents/instalationHarnessRefactor.md` + `instalator/scripts/` | Agent instalacyjny i jego skrypty |
| `instalationInfo.md` | Instrukcja instalacji |
| `docs/communication-protocol.md` | Opis koperty wiadomości |
| `v0.1.0/`, `v0.2.0/` | Historia zmian per wersja (`changes*.md`) |
| `instructions/` | Lokalne kopie dokumentacji Claude Code (poza repozytorium) |

### Instalacja

Wymagany `pwsh` (PowerShell 7) w `PATH`. Skopiuj agenta instalacyjnego
i `instalator/scripts/` do katalogu startu, następnie uruchom
`claude --agent instalationHarnessRefactor`. Szczegóły: `instalationInfo.md`.

Harness trafia do `.claude/refactor-legacy/` w katalogu projektu; wpisy hooków
są dopisywane do istniejącego `settings.json` / `settings.local.json`, nie
nadpisują go.

---

## English

**refactor-legacy** is a Claude Code harness for safely refactoring and
changing legacy .NET code (Framework / Core / .NET 5+).
Current version: **0.2.2** (`refactor-legacy-v0.2.0/`).

### Concept

- **The orchestrator** (`orkiestrator.md`) is the only entry point. It does not
  refactor or analyse code itself — it starts stages, enforces their order,
  checks entry and exit gates, routes requests and keeps a log.
- **Stages and steps** are subagents (`.claude/agents/`). They never call each
  other — every transition goes through the orchestrator.
- **Communication** uses JSON messages with a fixed envelope (11 fields),
  stored on disk (`docs/communication-protocol.md`).
- **Run configuration** lives in a single `refactor-config.json` file
  (template: `refactor-config.example.json`).
- **Results** (logs, plans, messages, gate results) go to a `refactor-resultN`
  directory inside the refactored project; an existing directory is never
  overwritten.
- **Deterministic PowerShell scripts** (`scripts/`) perform state detection,
  quality gates and log writing — not the agent.

### Flow

| Stage | Role | Status |
|---|---|---|
| Stage 0 | State detection: new run or session resume (`SubagentStart` hook → detection script) | described |
| Initial configuration | Questions 0–2: mandatory choices, granularity, output file structure, stage scope | described |
| Stage 1 / Step 1 | Analysis (opus): selects Feathers techniques, writes instructions for implementation; closed by a quality gate (`scripts/step1/`), on failure one retry with the eraser | described |
| Stage 1 / Step 2 | Implementation (sonnet): seams and tests; closed by the `SubagentStop` hook running build + unit tests | described |
| Stage 2 | Applying the change (Refactor / Logic change) | in progress |
| Stage 3 | Refactoring the Stage 2 result | to be defined |

Happy path applies; most error paths are still in progress.

### Repository layout

| Path | Contents |
|---|---|
| `refactor-legacy-v0.2.0/` | Current harness (0.2.2): orchestrator, agents, hooks, scripts, examples, references, `manifest.json` |
| `refactor-legacy-v0.1.0/` | Version 0.1.0 (no longer developed) |
| `.claude/agents/instalationHarnessRefactor.md` + `instalator/scripts/` | Installer agent and its scripts |
| `instalationInfo.md` | Installation guide (Polish) |
| `docs/communication-protocol.md` | Message envelope description |
| `v0.1.0/`, `v0.2.0/` | Per-version change history (`changes*.md`) |
| `instructions/` | Local copies of Claude Code documentation (not in the repository) |

### Installation

Requires `pwsh` (PowerShell 7) in `PATH`. Copy the installer agent and
`instalator/scripts/` into the start directory, then run
`claude --agent instalationHarnessRefactor`. Details: `instalationInfo.md`.

The harness is installed into `.claude/refactor-legacy/` in the project
directory; hook entries are appended to the existing `settings.json` /
`settings.local.json` instead of overwriting it.

> Harness files (prompts, configuration fields, scripts) are written in Polish.
