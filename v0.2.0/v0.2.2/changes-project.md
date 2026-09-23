##INfo dla cluade
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



## Claude
Zmiana wykonana: `refactor-legacy-v0.2.0/.cluade/` → `refactor-legacy-v0.2.0/.claude/` (git mv, historia zachowana).
Zawartość bez zmian: `.claude/settings.json`, `.claude/agents/etap0.md`, `.claude/agents/etap1/step1.md`, `.claude/agents/etap1/step2.md`.
Pozostałe wystąpienia ciągu "cluade" są tylko w nagłówkach `##INfo dla cluade` plików changes-* (Twoje wpisy) — nie ruszałem.

## User
dostosuj zmiany katalogów i miejsce aktualnie etapów do tego co jest w orkiestratorze, dodaj katalog hooks i wrzuć tam hooki dla etap0
zrób to zgodnie z dokumenatacją

## Claude
Wybór potwierdzony w rozmowie: pliki etapów zostają w `.claude/agents/`, orkiestrator.md dostosowany do nich; katalog hooków w `.claude/hooks/`.

Wykonane:
1. `scripts/etap0/hook-start.ps1` → `.claude/hooks/etap0-start.ps1`.
2. `.claude/settings.json` — komenda hooka wskazuje teraz `${CLAUDE_PROJECT_DIR}/.claude/hooks/etap0-start.ps1`. Zdarzenie i matcher bez zmian (`SubagentStart`, matcher `etap0`).
3. `.claude/hooks/etap0-start.ps1` — korzeń harnessu odtwarzany ze ścieżki skryptu (`Split-Path` dwa poziomy w górę), wywołanie `scripts/etap0/00-rozpoznanie.ps1`. Nagłówek komentarza opisuje rejestrację w settings.json zamiast frontmattera.
4. `.claude/agents/etap0.md` — z frontmattera usunięty blok `hooks: SessionStart`. Powód: wg sub-agents.md frontmatter subagenta przyjmuje wyłącznie `PreToolUse`, `PostToolUse` i `Stop` (to ostatnie zamieniane na `SubagentStop`). `SessionStart` nie był tam obsługiwany, a `${CLAUDE_PLUGIN_ROOT}` rozwija się tylko dla pluginów — harness nie ma manifestu `.claude-plugin/plugin.json`. Zaktualizowana tabela „Kto wykonuje" (wiersz hooka) i cała sekcja „Hook".
5. `scripts/etap0/00-rozpoznanie.ps1` — nagłówek komentarza, linie 6-7: nowa ścieżka hooka.
6. `orkiestrator.md` — tabela „Struktura harnessu (pliki)" linie 42-51: dopisane `.claude/settings.json` i `.claude/hooks/etap0-start.ps1`, pliki etapów przeniesione pod `.claude/agents/`. Wszystkie pozostałe odwołania w pliku przepisane na nowe ścieżki (linie 25, 126, 188, 282, 301, 319, 349, 411, 434, 499, 543, 567, 821, 845, 851). Odwołanie do nieistniejącego `etap1.md` (linia 567) wskazuje teraz `.claude/agents/etap1/step1.md`.

Wątpliwości:
1. `.claude/agents/etap1/step1.md` i `step2.md` nie mają frontmattera. Wg sub-agents.md plik bez pola `name` jest pomijany i traktowany jako dokumentacja — te dwa kroki nie są więc subagentami i nie da się ich wywołać przez `subagent_type`. Potrzebny frontmatter z `name` i `description`, plus `model: opus` / `model: sonnet` zgodnie z tabelą w orkiestrator.md linia 430. Uwaga: `name` nie może zawierać dwukropka, a nazwa z kropką nie jest w dokumentacji potwierdzona — adresy protokołu `etap1.step1` / `etap1.step2` nie nadają się wprost na `name`. Proponuję `etap1-step1` / `etap1-step2` i mapowanie adres protokołu → nazwa agenta opisane w orkiestrator.md. Czekam na decyzję, nie zmieniam.
2. Tabela struktury wymienia `.claude/agents/etap2.md` i `.claude/agents/etap3.md`, ale tych plików nie ma na dysku. Zostawiłem wpisy, bo opisują planowaną strukturę — potwierdź, czy mają zostać.
3. `${CLAUDE_PROJECT_DIR}` to korzeń projektu, w którym wystartowała sesja. Ścieżka w settings.json zadziała tylko wtedy, gdy harness jest rozpakowany w korzeniu refaktorowanego projektu. Jeśli ma leżeć w podkatalogu, hook trzeba przełączyć na ścieżkę względem tego podkatalogu albo wrócić do wariantu pluginu z `${CLAUDE_PLUGIN_ROOT}`.

## User
dostosuj etap0 do zmian

## Claude
Przejrzałem `.claude/agents/etap0.md` w całości i dociągnąłem go do faktycznego stanu hooka i skryptów. Poza przeniesieniem hooka znalazłem rozjazd z kodem: plik opisywał tryb `test`, którego skrypty nie mają.

Zmiany w `.claude/agents/etap0.md`:
1. Sekcja „Kto wykonuje", wiersz `.claude/hooks/etap0-start.ps1` — usunięte „i tryb" (hook nie ustala trybu). Wiersz `_wspolne.ps1` — „wyszukanie katalogów trybu" → „wyszukanie katalogów wynikowych".
2. Sekcja „Przebieg" — usunięty punkt 2 („Agent sprawdza zgodność trybu ... uruchamia skrypt ponownie z właściwym `-Tryb`"). Powód: `00-rozpoznanie.ps1` nie ma parametru `-Tryb`, a `$TRYB` jest w nim ustawione na stałe na `normalny` (linia 25). Zostały dwa punkty. Dopisany akapit, że harness ma jeden tryb — spójne z „Pozycja `tryb`" w orkiestrator.md linie 626-633.
3. Sekcja „Przebieg", akapit o zmiennych — usunięte `REFACTOR_TRYB`. Opisana faktyczna kolejność ustalania katalogu w `etap0-start.ps1`: `REFACTOR_KATALOG_PROJEKTU` → pole `cwd` z wejścia JSON → katalog bieżący. Usunięte odwołanie do nieistniejącego „punktu 4".
4. Sekcja „Wywołanie skryptu" — z sygnatury usunięty `[-Tryb normalny|test]`, z tabeli parametrów usunięty wiersz `-Tryb`. Opis `-Wyjscie`: „najnowszy katalog trybu" → „najnowszy katalog wynikowy". Z akapitu o zapisach usunięty wariant `refactor-result-test1`.
5. Sekcja „Zakres przeszukania" — usunięta tabela dwóch trybów i akapit o szczelnym rozdziale trybów. W zamian jeden wzorzec `refactor-result<N>`, zgodny z regexem w `scripts/etap0/_wspolne.ps1` linia 67 (`^refactor-result(\d+)$`).
6. Sekcja „Wyjście — raport JSON" — usunięty wiersz `katalogi_innego_trybu[]`; skrypt nie zapisuje tego pola (`$raport` w `00-rozpoznanie.ps1` linie 397-412). Opis pola `tryb` doprecyzowany: zawsze `normalny`.

Poza `etap0.md` nic nie zmieniałem. `orchestrator-examples/etap0-raport.md` sprawdzony — nie zawiera pola `katalogi_innego_trybu` ani odwołań do trybu `test`, więc był już zgodny.

Wątpliwość: zdanie „Sposób ustawiania tej zmiennej przez orkiestratora — *w budowie*" (sekcja „Przebieg") zostaje bez zmian. Jeśli `REFACTOR_KATALOG_PROJEKTU` nie zostanie ustawione, hook zejdzie na `cwd` zdarzenia — czyli katalog, w którym wystartowała sesja. Dla większości przebiegów to będzie właściwy katalog projektu i zmienna może okazać się niepotrzebna. Potwierdź, czy domykamy to teraz, czy zostaje „w budowie".

## User-zadanie
zmieniamy etap1 - step1
krok pierwszy otrzymuje metody według któ©ych będzie przeprowadzał analizę są one w
references/
        |-etap1-step1
            |- feathers-technique-selection.md
            |- feathers-dependency-breaking-csharp.md
feathers-technique-selection - ten plik wybór techniki z tabelą co kiedy wybierać, drugi plik to feathers-dependency-breaking-csharp są tam opisane implementacje konkretynch technik.

To trzeba zaimplementować do step1 etapu 1.

Na początek zmień sekcje podstawa metodyczna żeby brało z tych dwóch plików,
Zbadaj ten plik czy ta podstawa metodyczna się nie powtarza jeżeli tak uswaj duplikaty to ma działać w oparciu te dwa pliki ich zawartość.
Na razie tyle potem przejdziemy dalej.

## Claude
Zmiany tylko w `.claude/agents/etap1/step1.md`. Pliki referencyjne nietknięte.

1. Sekcja „Podstawa metodyczna kroku" (linie 27–44 przed zmianą) — przepisana od zera. Zamiast ogólnego odwołania do książki Feathersa jest tabela dwóch plików z rolami (`feathers-technique-selection.md` = wybór, `feathers-dependency-breaking-csharp.md` = implementacja) plus siedem reguł korzystania z katalogu: zakaz wychodzenia poza katalog i łączenia technik, kanoniczna nazwa techniki (nagłówek sekcji, bez numeru i bez polskiego tłumaczenia), droga wyboru objaw → wiersz tabeli → pierwszy wybór → zapasowa, warunki wstępne dla technik `[5] [6] [7] [15] [16] [18] [19]`, poziomy preferencji 1–3 z obowiązkiem uzasadnienia, „objaw bez wiersza — nie zgaduj, `user.input`", granulacja jedna zależność = jedna technika = jedna pozycja w JSON.
2. Wiersz tabeli nagłówkowej „Podstawa metodyczna" (linia 16) — wskazuje `references/etap1-step-1/`, nie książkę.
3. **Usunięty duplikat:** krok 2 analizy („Identyfikacja zależności blokujących") miał własną, krótszą listę technik: „Extract Interface + DI, Extract and Override Call, Adapter, Parameterize Method — zgodnie z katalogiem technik Feathersa". Zastąpione odesłaniem do tabeli objaw → technika i do sekcji „Podstawa metodyczna kroku". Dwie z tych czterech nazw były niezgodne z katalogiem: „Adapter" nie istnieje (jest `Adapt Parameter [1]`), a „Extract Interface + DI" to dwie rzeczy zlepione w jedną.
4. Przykład JSON, pole `technika` (linia 225 przed zmianą) — było „Extract Interface + DI" dla `DateTime.Now`, czyli nazwa spoza katalogu i technika niezgodna z wierszem G tabeli. Jest `Replace Function with Function Pointer`, opis dostosowany (`Func<DateTime>` przez konstruktor).
5. Opis pola `technika` w tabeli pól (linia 251 przed zmianą) — „technika z katalogu Feathersa" → „angielska nazwa sekcji z `feathers-dependency-breaking-csharp.md`, bez numeru".
6. Sekcja 2 pliku analizy („Zależności blokujące") — „wraz z typem seamu" → „nazwa wybranej techniki, wiersz tabeli objaw → technika i poziom preferencji".

Wątpliwości:
1. **Ścieżka katalogu.** W zadaniu podałeś `references/etap1-step1/`, na dysku jest `references/etap1-step-1/` (z myślnikiem przed jedynką). W step1.md wpisałem ścieżkę faktyczną. Potwierdź nazwę katalogu albo zmień na dysku — jeśli zostaje `etap1-step-1`, to nazewnictwo rozjeżdża się z `step1` używanym wszędzie indziej.
2. **Definicja seamu.** Pliki referencyjne nie definiują pojęcia „seam" ani „test charakteryzujący" — tworzą techniki, ale nie tłumaczą, co to szew. Zostawiłem w step1.md definicje „testu charakteryzującego" i „najmniejszej możliwej zmiany" jako osobny akapit z adnotacją, że pliki referencyjne ich nie definiują. Definicję seamu z poprzedniej wersji usunąłem (była zlepiona z listą zasad Feathersa). Jeśli ma zostać, wskaż gdzie: step1.md czy trzeci plik referencyjny.
3. **Brama nie sprawdza techniki.** `03-json.ps1` weryfikuje tylko, czy pole `technika` jest niepuste dla `typ: "seam"` — nie sprawdza, czy nazwa istnieje w katalogu 21 technik. Agent może wpisać technikę spoza katalogu i brama to przepuści. Jeśli ma to być wymuszone, potrzebna lista dopuszczalnych nazw w skrypcie bramy. Nie ruszałem `scripts/step1/03-json.ps1`.
4. **Poziom preferencji nie ma pola w JSON.** Reguła nakazuje uzasadnić przejście na poziom 2/3, ale kontrakt `step1-zmiany-N.json` nie ma pola na poziom ani na uzasadnienie — trafia to tylko do sekcji 3 pliku opisowego, której brama nie czyta merytorycznie. Rozszerzenie schematu zmieniłoby kontrakt dla Step 2 i bramy, więc nie dodawałem. Powiedz, czy dokładamy pola `poziom` i `uzasadnienie_poziomu`.
5. Frontmatter (linie 1–5) nietknięty. Nadal ma `descritpion` zamiast `description` i `name: step1 - analize` ze spacjami — wcześniejsza wątpliwość o `name` subagenta dalej otwarta.

## User
Zmieniłem nazwę katalogu, poprawiłem description,  zmieniłeś sekcje kroki analizy,
Tak trzeba poprwić bramę żeby sprawdzałą czy step1 wybrał technikę z katalogu dostępnych, więc trzeba zmienić skrypt żeby sprawdzał ten element zgodnie z dopisz do skrytpu tablicę jeżeli jest taka możliwość z technikami z pliku,
na razie na tym poprzestaniemy, czyli popraw bramę

mógłbyś wyjaśnić po co nam ten poziom prefencji?



## Claude
Poprawiona brama + trzy wyrównania w step1.md po zmianie nazwy katalogu.

### `scripts/step1/03-json.ps1`
1. Dopisana tablica `$TECHNIKI` (linie 20–50) — 21 nazw technik, po dot-source `_wspolne.ps1`, przed ustaleniem ścieżki pliku. Nazwy wzięte z nagłówków `## n. Nazwa` pliku `references/etap1-step1/feathers-dependency-breaking-csharp.md`, bez numeru i bez polskiego tłumaczenia w nawiasie; przy każdej pozycji komentarz z numerem sekcji, żeby dało się ją zestawić z odnośnikiem `[n]` z pliku wyboru. Sprawdziłem zestaw znak po znaku wobec pliku referencyjnego — 21 nazw, zero rozjazdów.
2. Sprawdzenie pola `technika` (linie 119–136) — było tylko „niepuste dla typ=seam". Teraz dla `typ: "seam"`: białe znaki normalizowane (wielokrotne spacje → jedna, obcięcie), nazwa szukana w `$TECHNIKI`. Trzy osobne komunikaty: brak pola, nazwa spoza katalogu (`technika='X' (nie ma tej nazwy w katalogu 21 technik)`), nazwa z katalogu ale w innym zapisie wielkości liter (`zapis niezgodny z katalogiem, ma być 'Y'` — porównanie `-eq` w PowerShell jest nieczułe na wielkość liter, więc ten przypadek trzeba było wyłapać osobno przez `-cne`).
3. Dodane sprawdzenie odwrotne: dla `typ: "test"` pole `technika` musi być puste. Wcześniej nie sprawdzał tego żaden skrypt, choć step1.md tego wymaga.
4. Dodany wpis diagnostyczny `katalog-technik` w szczegółach wyniku (liczba dopuszczalnych nazw) — po pliku `03-json.json` widać, na jakiej wersji katalogu brama działała.
5. Nagłówek komentarza skryptu (linie 5–6) — dopisana nowa odpowiedzialność.

Bez zmian: `00-brama.ps1`, `_wspolne.ps1`, pozostałe skrypty. Kody wyjścia bez zmian (`0`/`1`/`2`).

### `.claude/agents/etap1/step1.md`
6. Ścieżki `references/etap1-step-1/` → `references/etap1-step1/` (3 wystąpienia: wiersz tabeli nagłówkowej linia 16, tabela plików linie 34–35) — po Twojej zmianie nazwy katalogu.
7. Reguła nazewnicza w „Podstawa metodyczna kroku" (linie 42–47) — dopisany skutek bramowy: zapis sprawdzany znak po znaku wobec `$TECHNIKI`, nazwa spoza katalogu albo inny zapis → `failed`; dla `typ: "test"` pole puste.
8. Tabela bramy (linia 424), wiersz `03-json.ps1` — dopisane sprawdzenie nazwy techniki wobec katalogu.

### Odpowiedź: po co poziom preferencji

Poziom robi trzy rzeczy, których tabela objaw → technika nie robi:

1. **Szereguje propozycje między sobą.** Sekcja 4 pliku wyboru każe uszeregować pozycje „od najmniejszego wpływu", a `step1-zmiany-N.json` ma pole `kolejnosc`. Tabela mówi tylko, co wybrać dla jednego objawu — nie mówi, która z pięciu zmian w iteracji jest najtańsza. Poziom daje to porównanie.
2. **Zatrzymuje zjazd na techniki z trwałym kosztem.** Poziom 3 to cztery techniki, które zostawiają ślad w kodzie i w testach na stałe: `Introduce Static Setter` (reset stanu po każdym teście, blokada testów równoległych), `Supersede Instance Variable` (obiekt przez chwilę żyje z prawdziwą zależnością), `Primitivize Parameter` (rozjazd sygnatury), `Template Redefinition`. Bez progu „poziom 3 = pisemne uzasadnienie" agent wybierze to, co najłatwiej opisać, a nie to, co najtaniej utrzymać.
3. **Daje Ci czytelny sygnał w wyjściu.** Poziom 3 w pliku analizy = miejsce do przejrzenia ręcznie, bez czytania całej analizy.

Czego poziom **nie** robi: nie rozstrzyga typowego przypadku. Dla większości wierszy tabeli „pierwszy wybór" i tak jest na niższym poziomie niż „zapasowa", więc poziom powtarza informację, która już jest w tabeli.

**Znalazłem przy tym konflikt w pliku referencyjnym** — dwa wiersze, w których tabela i poziomy mówią coś innego:
- wiersz **N** (długa metoda): pierwszy wybór `Break Out Method Object [2]` = poziom 2, zapasowa `Parameterize Method [13]` = poziom 1;
- wiersz **O** (`new()` w kodzie generycznym): pierwszy wybór `Template Redefinition [21]` = poziom 3, zapasowa `Parameterize Constructor [12]` = poziom 1.

Dla tych dwóch wierszy reguła „wybieraj najniższy możliwy poziom" (sekcja 2) i tabela (sekcja 1) dają sprzeczne wskazania — w obecnym brzmieniu step1.md agent nie wie, co ma pierwszeństwo.

Moja propozycja: **tabela ma pierwszeństwo** (jest specyficzna dla objawu, poziom jest ogólny), a poziom zostaje w kroku tylko do dwóch zadań: szeregowanie pozycji w `kolejnosc` i próg uzasadnienia dla poziomu 3. Wymaga to jednego zdania w pliku wyboru (sekcja 2 albo 4) i skrócenia punktu „Poziom preferencji" w step1.md. Nie robię tego teraz — plików referencyjnych nie ruszam bez Twojej decyzji. Alternatywa: poprawić wiersze N i O w pliku wyboru tak, żeby pierwszy wybór był zawsze na niższym poziomie, i wtedy konflikt znika sam.

## User
Wynieś przykłady z pliku step1 do katalogu
