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

działamy na wersji 0.1.0
##

##User - zadania

w katalogu /refactor-legacy-v0.1.0/references/etap2/
znajdują się pliki z metodami refaktoryzacji trzeba te pliki włączyć do etapu2
ale nim to zrobisz to ja usunę częśc rzeczy z etapu drugiego.
Które już tam są niepotrzebne

## Claude

### Rezultat zmian

Pliki z `references/etap2/` są włączone do Etapu 2. Numer wersji bez zmian (0.1.1). Niczego nie uruchamiałem.

- `etap2.md`, nowa sekcja „Katalog technik" (linie 45–81): tabela plików, kolejność wczytywania, 5 kroków wyboru techniki, zapis identyfikatora techniki do logu.
- `etap2.md`, sekcja „Zmiany w testach z Etapu 1" (linia 24): usunięte odwołania do „Krok 1" i „Krok 3".
- `manifest.json`, pole `pliki_harnessu`: dodane 8 plików `references/etap2/`.
- `orkiestrator.md`, tabela plików (linia 33): dodany wiersz `references/etap2/*.md`.
- `references/etap2/*.md`, linia 2 (8 plików): dodany znacznik `wersja-harnessu: 0.1.1`.

Dwie reguły w sekcji „Katalog technik" dodałem od siebie, do Twojej oceny:

- Etap 2 nie commituje, choć pliki katalogu mówią o commicie po każdym kroku. Powód: `references/orkiestrator/konfiguracja-wstepna.md`, Pytanie 0, „Commitowanie".
- Gdy żadna technika z katalogu nie pasuje, etap wystawia `user.input`.

### Pytania i wątpliwości

Poniższych miejsc nie zmieniałem. Czekam na Twoją decyzję.

1. `etap2.md`, sekcja „Zmiany w testach z Etapu 1" (linie 23–24): Etap 2 może zmieniać testy tylko przy zmianie nazwy i przeniesieniu zależności do konstruktora. Techniki katalogu zmieniają też sygnatury i miejsce metod (np. F04, F13, F14). Czy rozszerzyć tę listę?
2. `etap2.md`, sekcja „iteracja - analiza" (linia 40): opisany jest tylko krok analizy. Brakuje wykonania zmiany, akceptacji planu iteracji i warunku zakończenia iteracji. Czy dopiszesz to sam, czy mam zaproponować treść?
3. `etap2.md`: usunięcie objęło też „Regułę niezaliczonego testu" i zakaz zgadywania znaczenia literałów. Nie ma teraz reguły, co zrobić, gdy test po iteracji jest czerwony. Czy obie reguły mają wrócić?
4. `etap2.md`, sekcja „Log Etapu 2" (linie 94–102) i sekcja „Format wyjścia Etapu 2" (linie 118, 124–128, 133): zostały odwołania do wariantów, „Krok N", „krok 3" i magic numbers. Czy zastąpić je opisem iteracji?
5. `orkiestrator.md`, tabela plików (linia 32): opis „Refaktor i/lub Zmiana logiki" jest nieaktualny. Brama wyjściowa (linie 229–230) odwołuje się do nieistniejącego „Krok 2" w `etap2.md`. Czy poprawić?
6. `etap3.md` (linie 6–14): uruchomienie Etapu 3 zależy od wariantu wybranego w Etapie 2, a wariantów już nie ma. Czy Etap 3 zostaje, a jeśli tak, to co ma go uruchamiać?
7. `examples/etap0-examples/etap0-raport.md` (linie 47, 58, 62): przykład nadal pokazuje wariant `refaktor` i magic numbers z kroku 2. Czy zaktualizować?


