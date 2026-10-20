---
name: refactor-legacy
description: Harness do bezpiecznej refaktoryzacji i wprowadzania zmian w kodzie legacy (np. .NET Framework 4.8.1, .NET MVC, jQuery). Używać zawsze gdy użytkownik prosi o refaktor, zmianę zachowania istniejącego kodu, wydzielenie metod/klas, dodanie testów do kodu bez pokrycia testami, lub redukcję couplingu. Orkiestrator prowadzi proces etapami, pilnuje poprawnego wykonania każdego etapu nie pomijać etapów, nawet jeśli zadanie wygląda na proste. Orkiestator działa według ustalonej sekwencji kroków. Nie wymysla nowych, nie wychodzi po za zakres zdefiniowanych wartości.
Orkiestrator ma zdefiniowane które służą do opisu zachowania:
- komenda mówi wykonaj akcje
- reguły - zestaw reguł lub jedna reguła która musi być spełniona żeby można było wykonąć zdarzenie
- event - zdarzenie które będzie wynikiem wywołania komendy
---
<!-- wersja-harnessu: 0.3.0 -->

# Refactor Legacy — Orkiestrator

Ten plik jest **punktem wejścia** i pełni rolę **orkiestratora**.

To nie jest typowy skill — to **harness**: warstwa nadrzędna, która sama nie
wykonuje refaktoryzacji, tylko **pilnuje, żeby poszczególne etapy zostały
wykonane poprawnie i w ustalonym porządku**. Merytoryka refaktoru siedzi
w plikach etapów; orkiestrator zbiera konfigurację, uruchamia etapy, waliduje
ich wejście i wyjście, przyjmuje od nich requesty i kieruje sterowanie do
właściwego etapu.

Praktyczna konsekwencja: **żaden etap nie jest uruchamiany bezpośrednio**.
Wejściem zawsze jest orkiestrator — tylko on zna konfigurację, kolejność
etapów i stan procesu.


## Struktura harnessu (pliki)

| Plik | Rola |
|---|---|
| `orkiestrator.md` (ten plik) | Orkiestrator: rozpoznanie stanu, konfiguracja wstępna, protokół, pętla sterowania |
| `manifest.json` | Wersja harnessu i lista plików wymaganych do działania — czyta go instalator |
| `.claude/settings.json` | Hooki harnessu — `SubagentStart` z matcherem `etap0`, |
| `.claude/hooks/etap0-start.ps1` | Opakowanie hooka Etapu 0 — woła skrypt rozpoznania i wypisuje podsumowanie do kontekstu agenta |

Orkiestrator wczytuje plik etapu dopiero w momencie jego uruchomienia. Etapy
nie wywołują się nawzajem bezpośrednio — **każde przejście między etapami idzie
przez orkiestratora**.

---

## Przykłady
---
**Przykłady są poza tym plikiem.** Payloady, JSON-y i szablony plików leżą
w `orchestrator-examples/`, **jeden plik na sekcję orkiestratora** (nazwa pliku
= nazwa sekcji). W treści orkiestratora zostaje reguła i ścieżka do przykładu,
nigdy sam przykład.

Orkiestrator wczytuje plik etapu (albo kroku) dopiero w momencie jego
uruchomienia. Etapy nie wywołują się nawzajem bezpośrednio — **każde przejście
między etapami idzie przez orkiestratora**.
---

### Zasada działania

## Uruchom etap 0 wyślij do agenta etap 0

Orkiestrator uruchamia etap 0 zlecając go agentowi etap0
Generuje kopertę wiadomości która zasila agenta.
Ramka zawiera inforacje o tym co ma zrobić etap0
Opowiedzią jest informacja na temat stanu poprzedniej sesji
Jest to ramka mówiąca czy jest poprzednia sesja dostępna i można ja kontynuować czy trzea zacząć nową.

if (etap0.result == 'newSesion')
{
   wygeneruj plik ''
   uruchom '/orkiestartor-refaktor-skill/refactor-legacy-v0.3.0/references/orchestrator/Configuration.md'
}

# scenario: odpowiedz z etapu 0
# given: poprzednia sesja została wykryta
# when: pytanie do usera
# then: kontynuacja
# and: odczyt danych z poprzedniego etapu i kontynuacja

# scenario: odpowiedz z etapu 0
# given: poprzednia sesja została wykryta
# when: pytanie do usera
# then: nowa sesja
# and: stworzenie struktury pod nową sesje, wywołanie agenta - skryptu tworzącego nową infrastrukture katalogów

# scenario: odpowiedz z etapu 0
# given: poprzednia sesja nie została wykryta
# when: rozpoczynamy nową sesje
# then: stworzenie struktury pod nową sesje, wywołanie agenta - skryptu tworzącego nową infrastrukture katalogów

# command uzpełnij konfigiracje początkową

Orkiestrator wywołuje pytania konfiguracyjne
# configuration rules - user nie może ich pominąć są obowiązkowe
- comitowanie reczne/automatyczne
- zgoda na build true/false
- zgoda na uruchomienie unit testów true/false
- wersja .net projektu któ©rego będzie dotyczyć zadanie
- ścieżka do pliku .sln - solucja
- sekwencje budowania projektu, solucji
- podać projekt testowy
- wybrać framework do testów
- wybrać cel uruchomienia harnessa, wybór ma być w formie checkboxów, user wybiera co najmniej jeden z nich:
   - etap1 - testy charakteryzujące
   - etap2 - wprowadzenie zmian
   - etap3 - refaktoryzacja
# rules - niezmiennik
- granulacja zmian jest automatyczna bez możliwości zmian przez użytkownika
- dla każdej iteracji tworzy się plik zmian
- iteracja to analiza -> implementacja
- orkiestrator odpowiada za uruchomienie kolejnej iteracji



