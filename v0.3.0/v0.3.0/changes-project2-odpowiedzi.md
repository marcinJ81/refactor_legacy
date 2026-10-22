# Odpowiedzi Claude do changes-project2.md

## Claude - zadania1

Analizowany plik: `refactor-legacy-v0.3.0/.claude/agents/etap0.md`, pseudokod w liniach 9–56. Porównanie z `refactor-legacy-v0.3.0/etap0-examples/message-frame.md`.

### Błędy składniowe i literówki

| Linia | Jest | Powinno być |
|---|---|---|
| 12 | `Faild` | `Failed` |
| 24 | `FindDictionary` | `FindDirectory` |
| 24 | `regex` — identyfikator niezdefiniowany | enum, np. `SearchType.Regex` |
| 27 | `CraeteDirectory` | `CreateDirectory` |
| 27 | `"comunication"` | `"communication"` |
| 27 | `("comunication","refactor-result1")` | `("refactor-result1","communication")` — zgodnie z poprawką w changes-project2.md, sekcja „User - zadania1”, linia 86 |
| 35 | `Frame.Faild` | `FrameActions.Failed` |
| 48 | `Frame.Done` | `FrameActions.Done` |
| 35, 36, 47, 48, 49 | brak przecinków po wartościach pól | dodać przecinki |
| 47 | wklejony tekst `enumy to wiadomo` | usunąć |
| 42 | `GetDiretories("directory")` — przekazany napis zamiast zmiennej | `GetDirectories(directory)` |
| 53 | nadmiarowy nawias `}` | usunąć |

### Błędy logiczne

1. Linia 24 — wzorzec `^refactor-result[1-9]{1,4}$` nie dopasuje `refactor-result10`, `refactor-result20` itd. (cyfra 0 wykluczona). Propozycja: `^refactor-result[1-9][0-9]{0,3}$`.
2. Linia 24 — kontrakt nie określa, który katalog zwrócić, gdy pasuje kilka. Opis w etap0.md, sekcja „Katalog `communication/`”, linia 87: najnowszy, czyli o największym N.
3. Linia 30 — gałąź `directory is null`: `new Frame(directory, ...)` nie ma katalogu do zapisu. Payload mówi „frame-message zapisana w głównym katalogu projektu”, ale ścieżka katalogu projektu nie jest nigdzie przekazana.
4. Linie 30 i 43 — nazwa pliku `001-Etap0-message-frame.json` na sztywno. Opis, linia 93: `NNN` = największy numer w katalogu + 1 (przy wznowieniu katalog już zawiera ramki). Potrzebna metoda typu `GetNextFrameNumber(directory)`.
5. Linie 32 i 45 — `msg_id = 1`; w message-frame.md `"e0-001"`.
6. Brak pola `to` — wymagane przez kopertę (etap0.md, sekcja „Koperta wiadomości”, linia 104).
7. Pole `action` — enum `Done`/`Failed` nie zgadza się z message-frame.md, gdzie `action` ma wartość `"stage.done"`, a wynik niesie `status`. Do decyzji: czy `FrameActions` zastępuje `stage.done`, czy enum powinien zawierać `stage.done`.
8. Pole `from` — w pseudokodzie `"Etap0"`, w message-frame.md `"etap0"`. Nazwa pliku `Etap0` vs `etap0` analogicznie.
9. Linia 50 — `payload = {directories}` to nowy kontrakt. Opis w liniach 113–117 i `etap0-examples/etap0-raport.md` zakładają `payload.report` albo pusty `payload`.

### Sprzeczności z opisem pod pseudokodem (etap0.md)

1. Linia 66 „Nie przeszukuj katalogów ani plików” — pseudokod przeszukuje katalogi (`FindDirectory`, `GetDirectories`).
2. Linia 79 „Nie zapisuj, nie zmieniaj i nie usuwaj żadnego pliku” — pseudokod tworzy katalogi i zapisuje ramkę.
3. Hook `.claude/hooks/etap0-start.ps1` i skrypt `scripts/etap0/00-rozpoznanie.ps1` nadal wykonują to samo — przy obecnym kształcie praca będzie zdublowana. Do decyzji: czy pseudokod zastępuje skrypt.

### Katalog projektu (pytanie z changes-project2.md, linia 88)

Propozycja: hook `SubagentStart` (matcher `etap0`) przekazuje w kontekście startowym linię `[etap0] projekt: <ścieżka>` z wartością `${CLAUDE_PROJECT_DIR}` (zmienna dostępna w hookach — `instructions/hooks.md`). `FindDirectory` dostaje trzeci parametr `rootDirectory`, a gałąź błędu (linia 30) ma gdzie zapisać ramkę.

### Proponowane kontrakty (do pliku deklaracji)

```
string   FindDirectory(SearchType searchType, string pattern, string rootDirectory)
         // zwraca nazwę katalogu o największym N pasującego do wzorca; null gdy brak
string   CreateDirectory(string mainDirectory, string innerDirectory)
         // tworzy mainDirectory, w nim innerDirectory; zwraca mainDirectory; null przy błędzie
string[] GetDirectories(string directory)
         // zwraca listę katalogów w directory
Frame    new Frame(string directory, string fileName) { pola koperty }
         // zapisuje ramkę JSON do directory/fileName i ją zwraca
string   GetDateTime()
         // bieżący czas w formacie "yyyy-MM-dd; HH-mm-ss"
enum     FrameActions, FrameStatus, SearchType — osobny plik współdzielony
```

Pytanie: gdzie ma leżeć plik deklaracji i plik enumów (propozycja: `refactor-legacy-v0.3.0/references/contracts.md`)?

## uwagi

popraw literówki i błędy składniowe,
dopisz kontrakty plik kontraktów będzie tam gdzie wskazałeś,
katalog projektu zrób tak jak napisałeś,

na razie tyle

## Claude - wykonanie uwag

1. Literówki i błędy składniowe — poprawione w `refactor-legacy-v0.3.0/.claude/agents/etap0.md`, blok `flow Etap0.Start`, wszystkie pozycje z tabeli „Błędy składniowe i literówki”. Enumy przeniesione z etap0.md do pliku kontraktów; w ich miejscu linia odsyłająca do `references/contracts.md`.
2. Kontrakty — nowy plik `refactor-legacy-v0.3.0/references/contracts.md`: sekcje „Składnia”, „Enumy (współdzielone)” (`SearchType`, `FrameActions`, `FrameStatus`), „Metody” (`GetProjectDirectory`, `FindDirectory`, `CreateDirectory`, `GetDirectories`, `Frame`, `GetDateTime`). Dodany do `manifest.json`, lista `pliki_harnessu`.
3. Katalog projektu — `refactor-legacy-v0.3.0/.claude/hooks/etap0-start.ps1`, blok ustalania `$katalogProjektu` (po linii 94): hook dopisuje do kontekstu linię `[etap0] projekt: <ścieżka>`. W etap0.md pierwsza instrukcja flow: `projectDirectory = GetProjectDirectory()`; `projectDirectory` przekazany do `FindDirectory` i do ramki w gałęzi błędu.

Świadomie nie zmienione (czekają na decyzję — sekcje „Błędy logiczne” i „Sprzeczności z opisem pod pseudokodem”): wzorzec regex, numer pliku `001` na sztywno, `msg_id = 1`, brak pola `to`, `action` vs `stage.done`, `Etap0` vs `etap0`, `payload = {directories}`, opis pod pseudokodem (linie 66 i 79), dublowanie ze skryptem `00-rozpoznanie.ps1`.

Uwaga: `CreateDirectory("refactor-result1", "communication")` nie dostaje `projectDirectory` — kontrakt tworzy katalog względem bieżącego katalogu. Do decyzji: dodać parametr `rootDirectory` jak w `FindDirectory`.

## Claude - CreateDirectory z rootDirectory

`CreateDirectory` ma trzeci parametr `rootDirectory`: `references/contracts.md`, sekcja „Metody” → „CreateDirectory”; `.claude/agents/etap0.md`, flow `Etap0.Start` — wywołanie `CreateDirectory("refactor-result1", "communication", projectDirectory)`.

## uwagi

sprawdz co robi skrypt jeżeli to robi też pseudo kod to usuń pseudo kod,
pozostaw tylko to co robi etap0, ale nie robi tego skrypt,

## Claude - porównanie pseudokodu ze skryptem

Porównanie `.claude/agents/etap0.md` (flow `Etap0.Start`) z `scripts/etap0/00-rozpoznanie.ps1` i `.claude/hooks/etap0-start.ps1`:

| Pseudokod | Kto już to robi | Decyzja |
|---|---|---|
| `GetProjectDirectory()` | hook, `$katalogProjektu` (linie 82–94) | usunięte z flow |
| `FindDirectory(...)` — najnowszy `refactor-resultN` | skrypt, `Get-KatalogiWynikowe` (linia 359), aktywny = ostatni | usunięte |
| `CreateDirectory("refactor-result1", "communication", ...)` | skrypt, linie 404–416 | usunięte |
| gałąź błędu — ramka `failed` | hook, `Save-RamkaFailed` (linie 23–72, 118–127) | usunięte |
| `new Frame(...)` — zapis ramki `done` | skrypt, linie 411–431 (`msg_id`, `to`, numer NNN, `stage.done` poprawnie) | usunięte |
| `GetDateTime()` | skrypt, `Get-Znacznik` | usunięte |
| `GetDirectories(directory)` — lista katalogów w `refactor-resultN` | **nikt** — raport ma `katalogi_wynikowe` (katalogi `refactor-resultN` w projekcie), nie zawartość aktywnego katalogu | **zostaje** |

Nowy flow w `.claude/agents/etap0.md`: `GetFramePath()` → `GetResultDirectory(framePath)` → `GetDirectories(directory)` → `ReadFrame(framePath)` → `frame.payload.directories = directories` → `return frame`. Nowe kontrakty `GetFramePath`, `GetResultDirectory`, `ReadFrame` dopisane w `references/contracts.md`, sekcja „Metody”.

Do decyzji:
1. `directories` trafia tylko do odpowiedzi agenta, plik ramki pozostaje bez zmian (zgodnie z etap0.md, linia „Nie zapisuj, nie zmieniaj i nie usuwaj żadnego pliku”). Alternatywa: skrypt dopisuje listę do ramki — wtedy pseudokod nie jest potrzebny wcale.
2. Nieużywane po zmianie: kontrakty `GetProjectDirectory`, `FindDirectory`, `CreateDirectory`, `Frame`, `GetDateTime`, enumy `SearchType`, `FrameActions`, linia `[etap0] projekt:` w hooku. Usunąć czy zostawić na potrzeby kolejnych etapów?



## uwagi

usuń wszystko po za pseudo kodem skoro to nie jest już potrzebne

decyzja 1 zmień żeby mozna usunąć psudo kodem
decyzja 2 : pozostaw

## Claude - wykonanie uwag (pseudokod, decyzje 1 i 2)

Przyjęta interpretacja (wybór w rozmowie: „Skrypt + krótki flow”):

1. `scripts/etap0/00-rozpoznanie.ps1`, blok zapisu ramki (po `$payload = ...`, ok. linia 418): skrypt dopisuje `payload.directories` — listę nazw katalogów w aktywnym `refactor-resultN`, zawsze (także przy braku poprzedniej sesji). Ramka `failed` hooka bez zmian.
2. `.claude/agents/etap0.md`: usunięty cały opis pod pseudokodem. Zostały frontmatter, znacznik wersji, odsyłacz do kontraktów i flow `Etap0.Start`: `GetFramePath()` → gdy brak, ramka `failed` bez zapisu (`msg_id = "e0-brak-pliku"`, `payload.error` = `GetHookError()` albo „Hook startu Etapu 0 nie przekazał podsumowania”) → inaczej `return ReadFrame(framePath)`. Przeniosłem tu obsługę błędów z usuniętej sekcji „Błąd rozpoznania”.
3. `references/contracts.md`: dopisany kontrakt `GetHookError` i wariant `new Frame { ... }` bez zapisu do pliku. Pozostałe kontrakty i enumy zostawione (decyzja 2).
4. `etap0-examples/message-frame.md`: przykłady ramek `done` mają pole `payload.directories`.

Uwagi:
- Opis we frontmatterze etap0.md (`description`) nie zmieniony — nadal aktualny.
- `GetResultDirectory` i `GetDirectories` nie są już używane w flow — zostawione (decyzja 2).
- `FrameActions` nie użyty w nowym flow; `action = "stage.done"` jako napis, zgodnie z message-frame.md.

## Claude - description etap0

`.claude/agents/etap0.md`, frontmatter, pole `description`: usunięte „Ustala, czy to nowe uruchomienie…” (decyduje orkiestrator); dopisane, że agent wykonuje flow `Etap0.Start` i zwraca ramkę (raport, `directories` albo `failed`).
