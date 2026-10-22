# Kontrakty pseudokodu harnessu
<!-- wersja-harnessu: 0.3.0 -->

Pseudokod w plikach agentów (np. `.claude/agents/etap0.md`, blok `flow`) używa
metod opisanych poniżej. Każda metoda to kontrakt: dla podanych parametrów
wejściowych zwróć opisany wynik. Sposób realizacji dowolny.

## Składnia

| Element | Znaczenie |
|---|---|
| `flow <Nazwa>.Start { ... }` | Blok głównych instrukcji do wykonania, od góry do dołu |
| `x = Metoda(...)` | Wywołaj kontrakt, zapamiętaj wynik pod nazwą `x` |
| `if (x is null) { ... }` | Wykonaj blok, gdy kontrakt nie zwrócił wyniku |
| `return ...` | Zakończ `flow` i zwróć wynik |

## Enumy (współdzielone)

```
enum SearchType
{
   Regex
}

enum FrameActions
{
   Done,
   Failed
}

enum FrameStatus
{
   in_progress,
   done,
   failed,
   blocked
}
```

## Metody

### GetProjectDirectory
```
string GetProjectDirectory()
```
Zwraca ścieżkę katalogu projektu, w którym zainstalowano harness — wartość
z linii `[etap0] projekt: <ścieżka>` w kontekście startowym agenta (linię
dopisuje hook `.claude/hooks/etap0-start.ps1`). Brak linii → `null`.

### FindDirectory
```
string FindDirectory(SearchType searchType, string pattern, string rootDirectory)
```
Szuka w `rootDirectory` katalogów, których nazwa pasuje do `pattern`
interpretowanego zgodnie z `searchType`. Zwraca nazwę katalogu o największym
numerze N. Brak dopasowania → `null`.

### CreateDirectory
```
string CreateDirectory(string mainDirectory, string innerDirectory, string rootDirectory)
```
Tworzy `mainDirectory` w `rootDirectory`, a w nim `innerDirectory`. Zwraca `mainDirectory`.
Błąd utworzenia któregokolwiek katalogu → `null`.

### GetFramePath
```
string GetFramePath()
```
Zwraca ścieżkę ramki z linii `[etap0] ramka: <ścieżka>` w kontekście
startowym agenta (ramkę zapisał skrypt `00-rozpoznanie.ps1` albo hook).
Brak linii → `null`.

### GetHookError
```
string GetHookError()
```
Zwraca treść linii `[etap0][hook] ... Ramka failed nie została zapisana`
z kontekstu startowego agenta. Brak linii → `null`.

### GetResultDirectory
```
string GetResultDirectory(string framePath)
```
Zwraca katalog `refactor-resultN`, w którego podkatalogu `communication/`
leży ramka `framePath`.

### ReadFrame
```
Frame ReadFrame(string framePath)
```
Zwraca treść ramki z pliku `framePath`. Pliku nie zmienia.

### GetDirectories
```
string[] GetDirectories(string directory)
```
Zwraca listę nazw katalogów znajdujących się w `directory`.

### Frame
```
Frame new Frame(string directory, string fileName) { pola koperty }
```
Tworzy ramkę wiadomości z podanych pól, zapisuje ją jako JSON do pliku
`directory/fileName` i zwraca jej treść. Pola koperty —
`etap0-examples/message-frame.md`.

```
Frame new Frame { pola koperty }
```
Wersja bez `(directory, fileName)` — tworzy ramkę i zwraca ją bez zapisu do pliku.

### GetDateTime
```
string GetDateTime()
```
Zwraca bieżący czas w formacie `yyyy-MM-dd; HH-mm-ss`.
