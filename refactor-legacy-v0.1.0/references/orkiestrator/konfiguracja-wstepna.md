# Orkiestrator — Konfiguracja wstępna
<!-- wersja-harnessu: 0.1.1 -->

Sekcja wyniesiona z `orkiestrator.md` („Konfiguracja wstępna”).

Wymagana przed uruchomieniem jakiegokolwiek etapu.

Konfigurację poprzedza **Etap 0** (rozpoznanie stanu) — dopiero jego raport
mówi, czy pytania zadajemy od nowa, czy wznawiamy przebieg z istniejącą
konfiguracją (patrz "Etap 0 i wznowienie sesji" w `orkiestrator.md`).

Orkiestrator nie może uruchomić żadnego etapu, dopóki ta konfiguracja nie
zostanie przeprowadzona z użytkownikiem. Konfiguracja to jeden przepływ pytań.
Żadne pytanie nie jest pomijane milcząco — każde wymaga jawnego wyboru
użytkownika, nawet jeśli dla części z nich dopuszczalna jest w praktyce tylko
jedna sensowna odpowiedź.

## Pytanie 0 — Wybory obowiązkowe + granulacja fragmentu

Poniższe wybory użytkownik musi podjąć zawsze, na starcie każdego uruchomienia
harnessu:

- Commitowanie: (musi wybrać) — brak commitów automatycznych, commit wykonuje
  wyłącznie użytkownik, ręcznie.
- Build: (musi wybrać) — brak buildów/kompilacji bez wyraźnej prośby
  użytkownika.
- Zmiany bez planu: (musi wybrać) — brak zmian w kodzie produkcyjnym, dopóki
  nie istnieje plik `.md` opisujący planowane zmiany, chyba że użytkownik
  jawnie powie inaczej w danej sesji.
- Framework unit testów: (musi wybrać) — NUnit / xUnit / MSTest / inny.
  Logika ustalenia:
  1. Sprawdź solucję — jeśli w projekcie(-ach) testowym(-ych) już jest
     zainstalowany i używany któryś z frameworków (referencje w `.csproj`,
     istniejące pliki testów), zaproponuj go jako **domyślny wybór** i poproś
     użytkownika o potwierdzenie.
  2. Jeśli w solucji nie ma żadnego frameworka testowego (brak projektu
     testowego lub brak referencji), zapytaj użytkownika wprost, którego
     frameworka użyć — nie zakładaj domyślnie.
  3. Jeśli w solucji istnieje więcej niż jeden framework jednocześnie
     (mieszane projekty testowe), przedstaw wszystkie znalezione i zapytaj,
     którego użyć dla nowych testów w ramach tego refaktoru.
Tu nie ma wyboru ale jest informacja że podział będzie dynamiczny
- Dynamiczna —  ten tryb polega na tym że LLM sam określa ile będzie iteracji pozwalających na zaspokojenie wszystkich zmian,
- Tu również pada pytane o zakres, np użytkownik określa, że zajmujemy się klasą lub metodą albo kontrolerem lub też całym modułem

## Pytanie 1 — Struktura plików wynikowych
- Opcja A: Osobny plik `.md` dla każdego etapu.
- Opcja B: Jeden zbiorczy plik `.md` na wszystkie etapy (rozbudowywany
  sekcjami w miarę postępu).

## Pytanie 2 — Zakres etapów
- Opcja A: Wykonujemy wszystkie etapy po kolei.
- Opcja B: Użytkownik pomija wybrane etapy (np. Etap 1 zbędny, bo fragment
  jest już pokryty unit testami) — użytkownik wskazuje, które etapy
  pomijamy i orkiestrator to respektuje (nie dispatchuje pominiętych etapów).
- Opcja C: Użytkownik sam wybiera jakie etapy będą wykonywane ale zachowane musi być że zawsze jest wykonany etap 1 jako pierwszy.

Pytanie dotyczy wyłącznie Etapów 1–3. **Etap 0 nie podlega pominięciu** — jest
wykonywany przed tym pytaniem i warunkuje samo jego zadanie.

## Log decyzji

Po przejściu Pytań 0–2 orkiestrator zapisuje wynik konfiguracji jako
checklistę do osobnego pliku, tworzonego obok plików dotyczących etapów, np.
`refactor-decisions.md`. Plik ten pełni rolę logu decyzji użytkownika i jest
punktem odniesienia przy każdej kolejnej iteracji/etapie tego samego
refaktoru.

Przykład: `examples/orchestrator-examples/log-decyzji.md`.

Pozycja "Format znacznika czasu" nie jest pytaniem do użytkownika — to stała
harnessu zapisywana w pliku konfiguracyjnym po to, żeby etapy wczytywały ją
razem z resztą konfiguracji i stosowały bez wyjątku (patrz "Znaczniki czasu
w logach" w `orkiestrator.md`).
