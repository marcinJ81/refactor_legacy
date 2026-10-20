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
# Uwagi - reguły
-  Claude nie będzie zmieniał nic w pliku orkiestrator.md ani w plikach poszczególnych etapów, chyba napiszę że trzeba coś zmienić
- pomoc claude polega na odczycie plików harnessa, analize i przedstawieniu w pliku changes jakie zmiany należy wprowadzić
##

## User - zadania
Zmieniamy podejście tworzenia orkiestratora
Potrzebuje takich zmian etap0 zwraca kopertę wiadomości będzie ona pododbna z tą która była w wersji 0.1.0 oraz 0.2.2 ale będzie mniejsza, musimy ją uprościć, poza tym etap0 tworzy katalog  comunication gdzie będzie się odbywać zapis ramek wiadomości który będzie wchodził i wychodził z orkiestratora,
na razie tworzymy hybrydę wersji 0.1.0 i 0.2.x.
Więc pewne rzeczy które działały w wersji 0.2.2 to jest ostatnia, będe przenosił, napewno etap0 i jego agentowa natura będzie przeniesiona, więc dostosuj etap0 do zmian które napisałem. Skopiuj etap0 z wersji 0.2.2 ale zmiany ogranicz tylko do etapu0 orkiestratora nie ruszaj, będziemy go później przyłączać.
Skopiuj też ramkę która jest wysyłana między eptapem0 a orkiestratorem to jest ramka jednokierunowa, czyli od etapu0 do orkiestratora, hook też zostanie.
Dodaj katalog ze skryptami i przenieś tam skrypty dotyczące agenta etap 0,


## Claude — rezultat zmian (2026-10-20)

Zakres: wyłącznie Etap 0 w `refactor-legacy-v0.3.0`. Pliki `orkiestrator.md`, `etap1.md`–`etap3.md` i `references/` nietknięte.

### Skopiowane z wersji 0.2.2 (`refactor-legacy-v0.2.0`), znacznik `wersja-harnessu` zmieniony na 0.3.0
- `.claude/agents/etap0.md` — agent Etapu 0.
- `.claude/hooks/etap0-start.ps1` — hook startu agenta.
- `.claude/settings.json` — tylko wpis `SubagentStart` z matcherem `etap0` (wpis `SubagentStop` / `step2` pominięty).
- `scripts/etap0/00-rozpoznanie.ps1`, `scripts/etap0/_wspolne.ps1` — nowy katalog skryptów.
- `etap0-examples/etap0-raport.md` — z `orchestrator-examples/etap0-raport.md` (przeniesione do katalogu Etapu 0, bo `orchestrator-examples/` należy do orkiestratora).

### Usunięte
- `refactor-legacy-v0.3.0/etap0.md` — był kopią `refactor-legacy-v0.1.0/etap0.md` (różnił się tylko znacznikiem wersji); zastąpiony przez `.claude/agents/etap0.md`.

### Nowe
- `etap0-examples/koperta-wiadomosci.md` — uproszczona koperta.
- `etap0-examples/ramka-etap0.md` — ramka Etap 0 → orkiestrator.

### Uproszczona koperta (`.claude/agents/etap0.md`, sekcja „Koperta wiadomości")
Zostaje 8 pól: `msg_id`, `corr_id`, `from`, `to`, `action`, `status`, `payload`, `timestamp`.
Usunięte względem 0.1.0 / 0.2.2: `type` (rodzaj wynika z `action`), `requires_user_ack` i `user_message` (o tym, co pokazać użytkownikowi, decyduje orkiestrator). Z `status` usunięte `needs_user`.

### Katalog `communication/` i ramka
- `scripts/etap0/00-rozpoznanie.ps1`, blok „Ramka Etap 0 → orkiestrator" (po zapisie raportu): skrypt zakłada `communication/` w katalogu wynikowym, w którym zapisuje raport, i zapisuje tam ramkę `<NNN>-etap0-stage.done.json` (`msg_id: e0-<NNN>`, `corr_id: null`, `action: stage.done`, `status: done`, `payload.report` = raport).
- `scripts/etap0/_wspolne.ps1`, nowa funkcja `Get-NastepnyNumerRamki` — `NNN` = największy numer w `communication/` + 1.
- Podsumowanie skryptu ma piątą linię `[etap0] ramka: <ścieżka>`.
- `.claude/agents/etap0.md`, sekcje „Przebieg", „Jedyne zapisy Etapu 0", nowe „Katalog `communication/`", „Koperta wiadomości", „Ramka Etap 0 → orkiestrator": agent zwraca treść pliku ramki zamiast samego `payload.report`.

### Dostosowanie odczytu do nowej koperty (`scripts/etap0/00-rozpoznanie.ps1`)
- `Get-Komunikaty`: katalog `komunikacja` → `communication`; nie czyta `type` i `user_message`.
- `Get-RequestyOtwarte`: bez filtra po `type`; pole `opis` usunięte z `requesty_otwarte[]` (również w tabeli pól w `.claude/agents/etap0.md` i w `etap0-examples/etap0-raport.md`).
- `zrodlo_statusu`: wartość `komunikacja` → `communication`.

### Wersje
- `manifest.json`: `katalog_harnessu` = `refactor-legacy` (wymagane przez hook — szuka skryptu w `<projekt>/.claude/refactor-legacy/scripts/etap0/`); `pliki_harnessu`, `pliki_claude`, `settings` uzupełnione; `etap0.md` usunięty z listy.
- Nie zmienione: tabela „Wersje harnessu" w `.claude/agents/instalationHarnessRefactor.md` nie ma wiersza `0.3.0`. Nie ma też `refactor-config.example.json` ani `orchestrator-examples/refactor-config.md` w 0.3.0.

### Wątpliwości / pytania
1. Nazwa katalogu: w zadaniu „comunication" — przyjąłem `communication`. Potwierdź.
2. Położenie `communication/`: przyjąłem wewnątrz katalogu wynikowego (`refactor-resultN/communication/`), jak `komunikacja/` w 0.2.2. Przy nowej sesji orkiestrator założy `refactor-result(N+1)`, a ramka Etapu 0 zostanie w starym katalogu. Alternatywa: `communication/` w korzeniu projektu. Które?
3. `scripts/etap0/00-rozpoznanie.ps1`, `Get-Konfiguracja`, lista `$wymagane` — to pola konfiguracji 0.2.2 (m.in. `granulacja`, `zmiany_bez_planu`, `pytanie_1.*`), a w 0.3.0 (`orkiestrator.md`, sekcja „command uzpełnij konfigiracje początkową") granulacja jest niezmiennikiem, a plik konfiguracji ma powstać według `references/orchestrator/Configuration.md`. Lista zostawiona bez zmian — do dostosowania, gdy będzie format pliku konfiguracji 0.3.0.
4. Odwołania do sekcji orkiestratora, których w 0.3.0 nie ma („Katalog wynikowy", „Pozycja `tryb`"): `.claude/agents/etap0.md` sekcja „Zakres przeszukania"; `scripts/etap0/00-rozpoznanie.ps1` komentarze przy `$TRYB`, `$wymagane` i przy zapisie raportu; `scripts/etap0/_wspolne.ps1` `Get-WzorzecKatalogow`. Zostawione do przyłączenia orkiestratora.
5. `.claude/agents/etap0.md`: zlecenie od orkiestratora (dawniej `stage.start` → `etap0`) usunięte z tabeli „Kto wykonuje", bo ramka wejściowa nie jest jeszcze zdefiniowana. Czy ramka orkiestrator → Etap 0 też ma być w uproszczonej kopercie?
6. Status etapu w `Get-Etapy` nadal opiera się na akcjach `stage.aborted`, `stage.done`, `stage.start`, `step.start`, `stage.resume` z 0.2.2 — katalog akcji 0.3.0 jeszcze nie istnieje.

## user - zadanie

czy w etap 0 potrzebuje tyle tekstu zaznacze co bym usunoł, znacznikami ##delete{ tu będa linie }
##update{ linie które bym zmienił}
##insert {jezeli uznam że coś trzeba dodać}
##comment

to nie jet powiedziane że to musi być usuniętę po prostu mam wątpliwości do tych sekcji, wiec potwierdz albo zaprzecz ale uzasdnij dlaczego


## Claude — odpowiedź na znaczniki w `.claude/agents/etap0.md` (2026-10-20)

Zasada, według której oceniam: plik `.claude/agents/etap0.md` jest promptem agenta Etapu 0 — czyta go wyłącznie ten agent. Zostaje w nim to, co agent ma **zrobić** albo czego **nie robić**. Opis działania skryptu, hooka i raportu jest dla człowieka (opiekuna harnessu) i dla orkiestratora — agent go nie wykorzystuje, a płaci za niego kontekstem. Zgodne z `instructions/skills.md` („state what to do rather than narrating how or why").

Pliku `etap0.md` nie zmieniałem — czekam na Twoją decyzję.

### Linie 16–22 (`##delete`, „Rozpoznanie jest deterministyczne")
Potwierdzam usunięcie. Uzasadnienie (determinizm, skrypt zamiast agenta) jest dla człowieka.
Zostawić jedno zdanie-instrukcję: „Nie przeszukuj katalogów ani plików — rozpoznanie wykonał już skrypt." Bez niego agent (model `sonnet`, `effort: high`) może zacząć sam szukać plików.

### Linie 24–42 (`##delete`, sekcja „Kto wykonuje") i komentarz w liniach 44–49
Potwierdzam usunięcie tabeli. Masz rację — agent nie musi wiedzieć, że hook istnieje; potrzebuje tylko wiedzieć, gdzie w kontekście startowym jest ścieżka ramki.
Zostawić jedną regułę z linii 40–41: „Nie interpretuj raportu i nie rozstrzygaj, czy to nowa sesja, czy wznowienie." To ograniczenie zachowania, nie opis.
Sekcja „Przebieg" (linie 52–60) — zgoda na skrócenie do: „W kontekście startowym jest linia `[etap0] ramka: <ścieżka>`. Zwróć orkiestratorowi treść tego pliku bez zmian."
Brakuje natomiast przypadku błędu: gdy hook nie wykonał rozpoznania (linie 253–255), ramka nie powstaje, a agent nie ma czego zwrócić. Pytanie: czy w tym przypadku ramkę ze `status: failed` ma zapisać hook (`.claude/hooks/etap0-start.ps1`, blok `catch`), czy agent zwraca ją bez zapisu do `communication/`? Proponuję hook — wtedy agent nadal niczego nie zapisuje.

### Linie 62–65 (bez znacznika, `REFACTOR_KATALOG_PROJEKTU`)
Proponuję usunąć z pliku agenta — to wiedza hooka i już jest w komentarzu `.claude/hooks/etap0-start.ps1`, linie 20–21.

### Linie 67–71 (`##delete`, tryb pracy)
Potwierdzam. W 0.3.0 nie ma trybów. Konsekwentnie do usunięcia: pole `tryb` w raporcie (`scripts/etap0/00-rozpoznanie.ps1`, zmienna `$TRYB` i pole `tryb` w `$raport`) oraz w `etap0-examples/etap0-raport.md` i `etap0-examples/ramka-etap0.md`.

### Linie 73–99 (bez znacznika, „Wywołanie skryptu", „Jedyne zapisy Etapu 0")
Proponuję usunąć z pliku agenta — agent nie wywołuje skryptu, robi to hook. Parametry są w nagłówku skryptu. Zamiast listy zapisów jedna instrukcja: „Nie zapisuj, nie zmieniaj i nie usuwaj żadnego pliku."

### Linie 101–118 (bez znacznika, „Zakres przeszukania")
Jak wyżej — opis skryptu, nie instrukcja dla agenta. Do przeniesienia razem z regułami (patrz niżej).

### Linie 120–146 (`##delete`, „Reguły rozpoznania") i komentarz w liniach 148–151
Z pliku agenta — potwierdzam usunięcie (to reguły skryptu, agent ich nie stosuje). Co do treści — zgadzam się, że są dziwne, i mają konkretne wady:
1. Reguła 1 (sesje) — **niezgodna ze skryptem**: tekst mówi o odtwarzaniu sesji z przerw między znacznikami, a `Get-Sesje` w `scripts/etap0/00-rozpoznanie.ps1` przy braku nagłówków zwraca pustą listę i dopisuje anomalię. Poza tym `orkiestrator-log.md` nie jest zdefiniowany w `orkiestrator.md` 0.3.0 — reguła nie ma na czym działać.
2. Reguła 2 (wpisy bez znacznika) — dotyczy logów sprzed reguły znaczników; w 0.3.0 nie będzie takich logów. Do usunięcia.
3. Reguła 3 (status etapu) — jedyna potrzebna do decyzji „nowa sesja czy wznowienie". Ale akcje `stage.start`, `step.start`, `stage.resume`, `stage.aborted` pochodzą z katalogu akcji 0.2.2, którego w 0.3.0 nie ma. Spełni się dopiero, gdy etapy będą zapisywać ramki w `communication/`.
4. Reguła 4 (request otwarty) — w 0.3.0 nie ma jeszcze żadnej pary request/odpowiedź; ramka Etapu 0 jest jednokierunkowa. Dziś nigdy nie znajdzie niczego. Do usunięcia albo odłożenia.
5. Reguła 5 (pozycje otwarte) — sekcja „Pozycje otwarte" istnieje tylko w `etap2.md` (linia 323), plików planów 0.3.0 nie ma ustalonych. Orkiestrator nie potrzebuje jej do decyzji o sesji — może ją przeczytać przy wznowieniu.
6. Reguła 6 („brak pliku to false") — zasada ogólna skryptu, nie reguła rozpoznania.

Propozycja: najpierw ustalić, czego orkiestrator potrzebuje do decyzji (w `orkiestrator.md` 0.3.0, sekcja „Uruchom etap 0", trzy scenariusze: sesja wykryta → pytanie do usera; brak sesji → nowa). Wystarczą: czy jest katalog wynikowy, czy jest kompletna konfiguracja, status każdego etapu. Wtedy reguły to: (a) sesja wykryta = istnieje `refactor-resultN` z plikiem konfiguracji; (b) status etapu z ostatniej ramki etapu w `communication/`. Reszta raportu (`sesje[]`, `requesty_otwarte[]`, `pozycje_otwarte[]`, `sesja_poprzednia`) do usunięcia ze skryptu albo odłożenia.
Gdzie trzymać opis skryptu: nagłówek `scripts/etap0/00-rozpoznanie.ps1` albo osobny plik np. `references/etap0/rozpoznanie.md`, którego agent nie ładuje.

### Linie 152–154 (bez znacznika, „nie wchodzi do plików źródłowych")
Zostawić, ale jako instrukcję w trybie rozkazującym: „Nie czytaj kodu ani testów projektu."

### Linie 156–191 (`##delete`, „Wyjście — raport JSON")
Potwierdzam usunięcie z pliku agenta — agent przekazuje raport bez czytania pól. Odbiorcą opisu pól jest orkiestrator; komplet jest już w `etap0-examples/etap0-raport.md`. Linie 184–190 (numer kolejnego katalogu, brak katalogu to nie błąd) są regułami orkiestratora — do przeniesienia przy jego przyłączaniu.

### Linie 193–230 (bez znacznika, „Katalog `communication/`", „Koperta wiadomości", „Ramka Etap 0 → orkiestrator")
Też nie są instrukcjami dla agenta (zapisuje skrypt, nie agent). Koperta jest wspólna dla całego harnessu, więc jej miejsce to docelowo orkiestrator albo osobny plik protokołu. Na teraz wystarczy w pliku agenta odwołanie: „Format ramki — `etap0-examples/ramka-etap0.md`."

### Linie 232–250 (`##delete`, sekcja „Hook")
Potwierdzam. To uzasadnienie konfiguracji dla opiekuna harnessu; `settings.json` i komentarz w `.claude/hooks/etap0-start.ps1` mówią to samo.

### Linie 257–260 (bez znacznika, „Log Etapu 0")
Do usunięcia — agent i tak nic nie loguje; wystarczy instrukcja „nie zapisuj żadnego pliku".

### Co zostaje w pliku agenta po wszystkich zmianach (propozycja, ok. 15 linii)
- frontmatter,
- jedno zdanie celu (linie 12–15),
- instrukcje: zwróć treść pliku z linii `[etap0] ramka: <ścieżka>` bez zmian; gdy zamiast ramki jest komunikat `[etap0][hook]` — postępowanie według odpowiedzi na pytanie o błąd hooka; nie przeszukuj katalogów; nie czytaj kodu ani testów; nie zapisuj plików; nie interpretuj raportu,
- odwołanie do `etap0-examples/ramka-etap0.md`.

## Claude — ramka `failed` przy błędzie hooka (2026-10-20)

### Błąd znaleziony przy okazji — hook 0.2.2 nie przekazywał niczego agentowi
`instructions/hooks.md`, linia 789: zwykły stdout trafia do kontekstu tylko dla `UserPromptSubmit`, `UserPromptExpansion`, `SessionStart`, `PostModelSwitch`. Dla `SubagentStart` (linie 2370–2383) kontekst agenta trzeba przekazać JSON-em `hookSpecificOutput.additionalContext`. Hook 0.2.2 pisał zwykły tekst — podsumowanie nie docierało do agenta Etapu 0 (dotyczy też `refactor-legacy-v0.2.0`).

### `.claude/hooks/etap0-start.ps1` — przepisany
- Całe wyjście (podsumowanie skryptu i komunikaty hooka) zbierane i wypisywane na końcu jako jeden JSON `{"hookSpecificOutput":{"hookEventName":"SubagentStart","additionalContext":"..."}}`.
- Wyjście skryptu przechwytywane przez `*>&1` (skrypt pisze `Write-Host`).
- Błąd rozpoznania = jedno z: brak skryptu `scripts/etap0/00-rozpoznanie.ps1`; kod wyjścia skryptu różny od 0; brak linii `[etap0] ramka: <ścieżka>` w wyjściu; wyjątek.
- Przy błędzie nowa funkcja `Save-RamkaFailed` zapisuje `communication/<NNN>-etap0-stage.done.json` ze `status: failed` i `payload.error`, w najnowszym `refactor-resultN` (gdy brak — w `refactor-result1`), i dopisuje do kontekstu `[etap0] ramka: <ścieżka>`. Funkcja nie korzysta z `scripts/etap0/_wspolne.ps1` — ramka ma powstać także wtedy, gdy brakuje skryptów.
- Gdy nie istnieje katalog projektu, ramka nie jest zapisywana (żeby nie tworzyć katalogu projektu) — do kontekstu idzie `[etap0][hook] Ramka failed nie została zapisana: ...`.

### `.claude/agents/etap0.md`
- „Przebieg", punkt 2 — odwołanie do nowej sekcji.
- „Ramka Etap 0 → orkiestrator" — `status`: `done` albo `failed`; nowe pole `payload.error`.
- Nowa sekcja „Błąd rozpoznania" — tabela trzech przypadków: ramka zapisana (zwróć plik bez zmian); hook nie zapisał ramki; hook się nie uruchomił (np. brak `pwsh`, przekroczony `timeout: 30`) — w dwóch ostatnich agent zwraca ramkę `failed` w odpowiedzi, bez zapisu pliku, `msg_id: e0-brak-pliku`, `timestamp: null`.
- Akapit o kodzie wyjścia hooka (dawniej „Ramka wtedy nie powstaje") — teraz odsyła do „Błąd rozpoznania".
- Znaczniki `##delete` / `##comment` nietknięte.

### `etap0-examples/ramka-etap0.md`
Dopisane dwa przykłady: ramka `failed` zapisana przez hook, ramka `failed` bez pliku zwracana przez agenta.

### Wątpliwości
1. Ramka `failed` ma `action: stage.done`. `Get-Etapy` w `scripts/etap0/00-rozpoznanie.ps1` przy następnym uruchomieniu uzna Etap 0 za `done` (nie sprawdza `status`). Dla decyzji o sesji to bez znaczenia, ale jeśli status Etapu 0 ma być wiarygodny — `Get-Etapy` powinien czytać `status` ramki.
2. Ramka bez pliku (`e0-brak-pliku`) nie trafia do `communication/` — w audycie zostanie po niej ślad dopiero, gdy orkiestrator zapisze ramki przychodzące. Do ustalenia przy przyłączaniu orkiestratora.

## Claude — usunięte bloki `##delete` w `.claude/agents/etap0.md` (2026-10-20)

Usunięte wszystkie 6 bloków. Zastąpione jednym zdaniem:
- „Rozpoznanie jest deterministyczne" → „Nie przeszukuj katalogów ani plików — rozpoznanie wykonał już skrypt uruchomiony przez hook."
- „Kto wykonuje" → „Nie interpretuj raportu i nie rozstrzygaj, czy to nowa sesja, czy wznowienie — decyduje orkiestrator."

Usunięte bez zastępstwa: tryb pracy, „Reguły rozpoznania", „Wyjście — raport JSON", „Hook" — to opis skryptu/raportu/konfiguracji, nie instrukcje dla agenta. Opis pól raportu został w `etap0-examples/etap0-raport.md`.

Bloki `##comment` zostawione. Sekcje bez znacznika, które proponowałem usunąć (zmienna `REFACTOR_KATALOG_PROJEKTU`, „Wywołanie skryptu", „Jedyne zapisy Etapu 0", „Zakres przeszukania", „Log Etapu 0"), zostawione — czekają na decyzję.

## Claude — usunięte sekcje bez znacznika w `.claude/agents/etap0.md` (2026-10-20)

Usunięte: akapit o zmiennej `REFACTOR_KATALOG_PROJEKTU` (jest w komentarzu `.claude/hooks/etap0-start.ps1`), „Wywołanie skryptu" (parametry są w nagłówku `scripts/etap0/00-rozpoznanie.ps1`), „Zakres przeszukania", „Log Etapu 0".
„Jedyne zapisy Etapu 0" zastąpione zdaniem: „Nie zapisuj, nie zmieniaj i nie usuwaj żadnego pliku."

## user - zadanie
Będzie tylko jedna ramka wiadomości, tym razem ja poprawiam a ty sprawdzasz, jeżeli czegoś brakuje piszesz tutaj.


## Claude — sprawdzenie zmian usera w `.claude/agents/etap0.md` (2026-10-20)

Zmiany usera: usunięte bloki `##comment`; usunięta sekcja „Ramka Etap 0 → orkiestrator"; odwołanie do koperty zmienione na `etap0-examples/message-frame.md`; dopisane linie 60–61 (sesja znaleziona → dane w `payload`; brak sesji → `status: done`, pusty `payload`).

### Do poprawy
1. Linia 48 — plik `etap0-examples/message-frame.md` nie istnieje; jest `etap0-examples/koperta-wiadomosci.md` (wpisany w `manifest.json`). Albo zmienić nazwę pliku (i wpis w `manifest.json`), albo przywrócić odwołanie.
2. Linie 28–29 („patrz „Ramka Etap 0 → orkiestrator"") i linia 75 („pozostałe pola jak w „Ramka Etap 0 → orkiestrator"") — odwołują się do usuniętej sekcji. Ramka `e0-brak-pliku` traci przez to opis pól (`from`, `to`, `action`, `corr_id`). Propozycja: odwołanie do `etap0-examples/ramka-etap0.md` (po usunięciu sekcji ten plik nie jest nigdzie wskazany).
3. Linie 60–61 — niezgodne ze skryptem. `scripts/etap0/00-rozpoznanie.ps1` zawsze wpisuje do ramki `payload.report` z pełnym raportem, także gdy nic nie znalazł (puste tablice). Żeby było jak w linii 61, skrypt musi przy braku poprzedniej sesji zapisać `payload: {}`.
4. Linie 60–61 — brakuje definicji „poprzedniej sesji". Propozycja: poprzednia sesja = istnieje `refactor-resultN` i jest w nim `refactor-config.json` (tak rozstrzygał orkiestrator 0.2.2, `refactor-legacy-v0.2.0/orkiestrator.md`, sekcja „Interpretacja raportu": katalog bez konfiguracji = nowa sesja).
5. Linie 60–61 — podmiotem jest „etap 0 wpisuje", a agent ma zakaz zapisu (linia 32). Wpisuje skrypt; proponuję sformułowanie: „Ramka ma `status: done`. Gdy skrypt znalazł poprzednią sesję — `payload.report` zawiera raport; gdy nie — `payload` jest pusty. Pusty `payload` nie jest błędem."
6. Linia 60–61 — literówki: „sesje", „payload-y", „wpisue sttus", „paylod", „poprawy efekt".
7. Przy braku poprzedniej sesji skrypt nadal tworzy `refactor-result1` i `etap0-raport.json`. Czy raport ma wtedy w ogóle powstawać? Ramka musi gdzieś leżeć — `communication/` w `refactor-result1` zostaje potrzebne (wątek: pytanie 2 o położenie `communication/`).

Bez zastrzeżeń: usunięcie bloków `##comment`.

## user -zadanie
001-etap0-stage.done.json tej ramki już nie będzie będzie tylko jedna ramka, czyli format message-frame.md, to jest wspólny format wiadomości dla wszystkich etapów
sprawdz,

a potem popraw skrypty żeby były zgoden ze zmianami

do etapu0 dopisz
 Brak definicji „poprzedniej sesji”. Proponuję: istnieje katalog refactor-resultN z plikiem refactor-config.json. Tak rozstrzygał orkiestrator w 0.2.2., czyli tak jak było wcześniej, w wersji 0.2.2.

 popraw to

  Sformułowanie „etap 0 wpisuje” kłóci się z zakazem zapisu w linii 32, bo wpisuje skrypt, a nie agent. Gotowe sformułowanie jest w changes-project1.md.

  popraw literówki, jeżeli nie ma poprzedniej sesji nie będzie już raportu, po prostu powastanie frame który będzie mówił że jest pusto

## Claude — jedna ramka `message-frame`, brak raportu bez sesji (2026-10-20)

### Sprawdzenie `etap0-examples/message-frame.md` (zmiany usera) — poprawione
- „Ramka powodzenia" pokazywała raport z pustymi tablicami — to przypadek braku sesji, w którym teraz `payload` jest pusty. Zastąpiona dwoma przykładami: „Ramka `done` — jest poprzednia sesja" (`payload.report`, skrócony, odwołanie do `etap0-raport.md`) i „Ramka `done` — brak poprzedniej sesji" (`payload: {}`).
- „Ramka `failed` — zapisuje hook": `payload` nie był poprawnym JSON-em (wartość bez klucza) — dodany klucz `error`, tak jak zapisuje hook.

### Nazwa pliku ramki
Przyjęta z Twoich przykładów: `<NNN>-<from>-message-frame.json` (dla Etapu 0: `<NNN>-etap0-message-frame.json`). Zmienione w `scripts/etap0/00-rozpoznanie.ps1`, `.claude/hooks/etap0-start.ps1` (komentarz i `Save-RamkaFailed`), `.claude/agents/etap0.md` sekcja „Katalog `communication/`" (było `<NNN>-<from>-<action>.json`).

### `scripts/etap0/00-rozpoznanie.ps1`
- Nie zapisuje już `etap0-raport.json`; usunięty parametr `-Wyjscie`.
- Poprzednia sesja (`$sesjaZnaleziona`) = najnowszy `refactor-resultN` z `refactor-config.json`. Tak → `payload.report`; nie → `payload: {}`; `status: done` w obu przypadkach.
- Gdy nie ma żadnego `refactor-resultN`, nadal tworzy `refactor-result1` — żeby ramka miała gdzie leżeć.
- Podsumowanie: pierwsza linia `[etap0] poprzednia sesja: tak|nie; ...`; linie o sesjach/requestach tylko przy znalezionej sesji; linia `[etap0] raport:` usunięta.

### `.claude/agents/etap0.md`
- „Przebieg" punkt 1 — bez wzmianki o pliku raportu; punkt 2 — brakująca kropka.
- „Katalog `communication/`" — położenie: najnowszy `refactor-resultN`, gdy brak — `refactor-result1`.
- Linie z „etap 0 wpisuje" — przepisane: definicja poprzedniej sesji (jak w 0.2.2) i sformułowanie „Ramkę zapisuje skrypt..."; literówki usunięte.

### `etap0-examples/etap0-raport.md`
Tytuł i opis: raport istnieje tylko jako `payload.report`, osobny plik nie powstaje. Przykład podsumowania hooka dostosowany do nowych linii.

### Do decyzji
1. Katalog `refactor-result1` zakładany przy braku jakiegokolwiek katalogu wynikowego: gdy orkiestrator potem zdecyduje „nowa sesja", czy użyje tego `refactor-result1` (ma już ramkę Etapu 0, nie ma konfiguracji), czy założy `refactor-result2`? Według definicji sesji `refactor-result1` bez konfiguracji nie jest sesją, więc naturalnie byłby użyty.
2. Gdy istnieje `refactor-resultN` bez `refactor-config.json` (nie jest sesją), ramka i tak trafia do jego `communication/` — jak wyżej.

## Claude — `refactor-result1` zakłada skrypt (2026-10-20)

Decyzja usera: `refactor-result1` zakłada skrypt Etapu 0, orkiestrator go nie zakłada. Skrypt już tak działa (`scripts/etap0/00-rozpoznanie.ps1`, blok przed zapisem ramki) — bez zmian. Dopisane w `.claude/agents/etap0.md`, sekcja „Katalog `communication/`".
Pytania „Do decyzji" 1 i 2 z poprzedniej sekcji — zamknięte: orkiestrator używa katalogu, w którym leży ramka Etapu 0.

Otwarte: gdy poprzednia sesja jest (`refactor-resultN` z konfiguracją), a użytkownik wybierze nową sesję — kto zakłada `refactor-result(N+1)`: orkiestrator czy skrypt (np. skrypt tworzący infrastrukturę nowej sesji z `orkiestrator.md`, scenariusz „nowa sesja")?

## Claude — `refactor-result(N+1)` zakłada orkiestrator (2026-10-20)

Decyzja usera: gdy jest poprzednia sesja, użytkownik wybiera nową sesję albo kontynuację; przy nowej sesji `refactor-result(N+1)` zakłada orkiestrator (dostaje ramkę Etapu 0 z `katalogi_wynikowe[].numer`).
Etap 0 bez zmian. Do wpisania przy przyłączaniu orkiestratora — `orkiestrator.md`, sekcja „Uruchom etap 0 wyślij do agenta etap 0", scenariusz „poprzednia sesja została wykryta / nowa sesja". `orkiestrator.md` nie zmieniany.

## braki

Stan na 2026-10-20 — tylko pozycje niezrobione.

### Etap 0 — skrypt `scripts/etap0/00-rozpoznanie.ps1`
1. `Get-Konfiguracja`, lista `$wymagane` — pola konfiguracji z 0.2.2 (`tryb`, `granulacja`, `zmiany_bez_planu`, `pytanie_1.*`). Do dostosowania, gdy powstanie format pliku konfiguracji 0.3.0 (`references/orchestrator/Configuration.md`).
2. Pole `tryb` — w 0.3.0 nie ma trybów; do usunięcia: zmienna `$TRYB` i pole `tryb` w `$raport`, `tryb` w `Get-SesjaPoprzednia`, `tryb` w `etap0-examples/etap0-raport.md` (linie 16, 31, 109).
3. Zakres raportu — do ograniczenia do danych potrzebnych orkiestratorowi do decyzji (katalogi wynikowe, konfiguracja, status etapów). Do usunięcia albo odłożenia: `sesje[]` (opiera się na `orkiestrator-log.md`, niezdefiniowanym w 0.3.0), `requesty_otwarte[]` (w 0.3.0 nie ma par request/odpowiedź — nigdy nic nie znajdzie), `pozycje_otwarte[]` (pliki planów 0.3.0 nieustalone), `sesja_poprzednia` (`refactor-session.md` niezdefiniowany w 0.3.0), anomalia `refactor-decisions.md` (pozostałość po 0.1.0).
4. `Get-Etapy` — status etapu opiera się na akcjach z 0.2.2 (`stage.start`, `step.start`, `stage.resume`, `stage.aborted`); katalog akcji 0.3.0 nie istnieje.
5. `Get-Etapy` — nie czyta `status` ramki: ramka `failed` Etapu 0 (`action: stage.done`) przy następnym uruchomieniu da status `done`.
6. Odwołania do sekcji orkiestratora, których w 0.3.0 nie ma: `00-rozpoznanie.ps1` linie 27–28 („Pozycja `tryb`"), linia 63 (`orkiestrator.md` i `refactor-config.example.json`); `_wspolne.ps1` linia 67 („Katalog wynikowy").

### Etap 0 — `.claude/agents/etap0.md`
7. Ramka wejściowa orkiestrator → Etap 0 — niezdefiniowana. Czy w formacie `etap0-examples/message-frame.md`?
8. Akapit „Etap 0 nie wchodzi do plików źródłowych projektu" — propozycja: zamienić na instrukcję „Nie czytaj kodu ani testów projektu."

### Orkiestrator (`orkiestrator.md` — do wpisania przy przyłączaniu)
9. Przy nowej sesji orkiestrator zakłada `refactor-result(N+1)` (N z `katalogi_wynikowe[].numer`); przy braku jakiegokolwiek katalogu używa `refactor-result1` założonego przez Etap 0. Sekcja „Uruchom etap 0 wyślij do agenta etap 0", scenariusze nowej sesji.
10. Ramka `failed` bez pliku (`msg_id: e0-brak-pliku`) nie trafia do `communication/` — ustalić, czy orkiestrator zapisuje ramki przychodzące.
11. Ustawianie zmiennej `REFACTOR_KATALOG_PROJEKTU` przez orkiestratora — *w budowie* (hook ma zapas: `CLAUDE_PROJECT_DIR`, `cwd`).
12. Koperta `message-frame.md` jest wspólna dla wszystkich etapów, a leży w `etap0-examples/` — docelowe miejsce do ustalenia.

### Wersje i instalacja
13. `.claude/agents/instalationHarnessRefactor.md`, tabela „Wersje harnessu" — brak wiersza `0.3.0`.
14. Brak `refactor-config.example.json` i `orchestrator-examples/refactor-config.md` w 0.3.0 (pole `wersja_harnessu` wymagane regułą wersji).

### Poza 0.3.0
15. `refactor-legacy-v0.2.0/.claude/hooks/etap0-start.ps1` — ten sam błąd co naprawiony w 0.3.0: zwykły stdout `SubagentStart` nie trafia do kontekstu agenta (`instructions/hooks.md`, linia 789); potrzebny JSON `hookSpecificOutput.additionalContext`.
