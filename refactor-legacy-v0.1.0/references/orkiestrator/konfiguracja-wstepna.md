# Orkiestrator — Konfiguracja wstępna
<!-- wersja-harnessu: 0.1.1 -->

Sekcja wyniesiona z `orkiestrator.md` („Konfiguracja wstępna”).

Konfigurację poprzedza **Etap 0** (rozpoznanie stanu) — dopiero jego raport
mówi, czy pytania zadajemy od nowa, czy wznawiamy przebieg z istniejącą
konfiguracją (patrz "Etap 0 i wznowienie sesji" w `orkiestrator.md`).

Orkiestrator nie może uruchomić żadnego etapu (z wyjątkiem etapu 0), dopóki ta konfiguracja nie
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

## Kolejka etapów

Użytkownik nie wybiera etapów. Kolejka jest stała: Etap 1, potem Etap 2.

- Etap 1 wykonuje się zawsze. Gdy fragment ma już pełne testy, Etap 1 ich nie
  pisze, tylko przechodzi do Etapu 2 (patrz "Rozpoznanie istniejących testów"
  w `etap1.md`).
- Etap 3 jest pusty i pomijany.
- Etap 0 jest poza kolejką.

## Log decyzji

Po przejściu Pytania 0 orkiestrator zapisuje wynik konfiguracji jako
checklistę do osobnego pliku, tworzonego obok plików dotyczących etapów, np.
`refactor-decisions.md`. Plik ten pełni rolę logu decyzji użytkownika i jest
punktem odniesienia przy każdej kolejnej iteracji/etapie tego samego
refaktoru.

Przykład: `examples/orchestrator-examples/log-decyzji.md`.

Pozycja "Format znacznika czasu" nie jest pytaniem do użytkownika — to stała
harnessu zapisywana w pliku konfiguracyjnym po to, żeby etapy wczytywały ją
razem z resztą konfiguracji i stosowały bez wyjątku (patrz "Znaczniki czasu
w logach" w `orkiestrator.md`).
