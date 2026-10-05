# Instalacja harnessu refactor-legacy
<!-- wersja-instalatora: 0.2.2 -->

Pliki potrzebne do instalacji trzeba wrzucić ręcznie — instalator nie
zainstaluje sam siebie.

## Pliki instalatora

Do katalogu, w którym uruchomisz instalator (np. katalog z pobranymi plikami
harnessu), skopiuj ręcznie:

| Plik / katalog | Dokąd |
|---|---|
| `.claude/agents/instalationHarnessRefactor.md` | `<katalog startu>/.claude/agents/` |
| `instalator/scripts/` (cały katalog) | `<katalog startu>/instalator/scripts/` |

Obok muszą leżeć katalogi wersji harnessu (`refactor-legacy-v0.1.0/`,
`refactor-legacy-v0.2.0/`) albo ich ścieżkę podajesz instalatorowi jako
katalog źródłowy.

Wymagany `pwsh` (PowerShell 7) w `PATH`.

## Uruchomienie

W katalogu startu: `claude --agent instalationHarnessRefactor`.

Agent zapyta o katalog źródłowy, katalog docelowy i lokalizację `.claude`,
poprosi o zgodę na dostęp, a resztę wykona skryptami. Na końcu pokaże
podsumowanie z poleceniem uruchomienia harnessu.
