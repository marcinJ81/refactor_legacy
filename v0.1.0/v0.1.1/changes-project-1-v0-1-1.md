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
Które już tam są niepotrzebnes

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

### Rezultat poprawek uwag

Poprawione uwagi 1–5 i 7. Numer wersji bez zmian (0.1.1). Niczego nie uruchamiałem.

- Uwaga 1, `etap2.md`, sekcja „Zmiany w testach z Etapu 1": lista rozszerzona o zmianę sygnatury oraz przeniesienie metody lub klasy. Dodany punkt o mockach i stubach, bez frameworka Moq.
- Uwaga 2, `etap2.md`: dopisane sekcje „iteracja - plan i akceptacja", „iteracja - wykonanie", „Koniec iteracji i etapu". Do sekcji „iteracja - analiza" dopisane wczytanie `refactor-decisions.md` i logu przed każdą iteracją. Twój tekst w tej sekcji jest bez zmian.
- Uwaga 3, `etap2.md`: wróciły „Reguła niezaliczonego testu" i „Zakaz zgadywania", opisane przez iteracje zamiast kroków 1–3. Zakaz obejmuje teraz literały, odpowiedzialność elementu i zachowanie zależności.
- Uwaga 4, `etap2.md`, sekcje „Log Etapu 2" i „Format wyjścia Etapu 2": warianty i kroki zastąpione iteracjami. Plik szczegółowy nazywa się `etap2-iteracja-M-zmiany.md`, nagłówek logu `### Iteracja N`.
- Uwaga 5, `orkiestrator.md`: poprawiony opis Etapu 2 w tabeli plików, sekcja „Bramy etapów" (warunek 4 bramy wyjściowej) odsyła do „Zakaz zgadywania", usunięty przykład `Krok 3 — iteracja 2` z sekcji „Znaczniki czasu w logach".
- Uwaga 7, `examples/etap0-examples/etap0-raport.md`: pola `wariant` i `ostatni_krok` zastąpione polem `iteracje`, opis requestu mówi o literałach.

Te same nieaktualne odwołania poprawiłem też poza listą uwag:

- `examples/orchestrator-examples/etap2-pyta-uzytkownika.md`, `koperta-wiadomosci.md`, `etap0-raport.md`: `msg_id` `e2-k2-004` zmienione na `e2-i2-004`.
- `examples/orchestrator-examples/log-orkiestratora.md` (linia 17): „od kroku 2" zmienione na „od iteracji 2".
- `etap0.md` (linia 40): usunięta nazwa `etap2-krok-N-zmiany.md`.
- `references/orkiestrator/protokol-komunikacji.md` (linia 27): „magic numbera" zmienione na „literału".
- `scripts/wspolne/wpis-logu.ps1` (linia 19, komentarz): usunięty przykład `Krok 3 — iteracja 2`.

### Pytania otwarte

1. Uwaga 6, `etap3.md` (linie 6–14): nie zmieniałem, bo potrzebna jest Twoja decyzja. Warunek uruchomienia opiera się na wariantach, których już nie ma. Proponuję usunąć ten warunek i zostawić Etap 3 jako pusty, do zdefiniowania. Czy tak zrobić?
2. `references/orkiestrator/konfiguracja-wstepna.md`, Pytanie 1: nie ma tam opcji pliku szczegółowego, a `etap1.md` (linia 167), `etap2.md`, sekcja „Format wyjścia Etapu 2", oraz `examples/etap0-examples/etap0-raport.md` (linia 24, pole `plik_szczegolowy`) się do niej odwołują. Czy dodać tę opcję do Pytania 1, czy usunąć odwołania?
3. Reguła w `etap2.md`, sekcja „Zakaz zgadywania": wróciła w szerszym zakresie, niż była (wcześniej dotyczyła literałów i zachowania zależności, teraz także odpowiedzialności elementu). Do Twojej oceny.

## user - zadania

etap3 jest pusty i tak zostaje, na razie,
plik szczegółów wylatuje, nie będzie już go trzeba go usunąć,
dodatkowo trzeba się zastasnowić na iteracjami, teraz krok drugi może ich zrobić kilka więc trzeba sprawdzić czy wytrzyma wiecej niż jedną iteracje, przekaże odpowiednie inforamcje do następnej?
wszystkie dane są teraz przekazywane przez kopertę wiadomośc (okno wiadomości czy jak to nazwaliśmy),
Format wyjścia Etapu 2 ta sekcja będzie ograniczona do braku wyboru czyli Opcja A ,

## Claude

### Rezultat zmian

Numer wersji bez zmian (0.1.1). Niczego nie uruchamiałem.

- `etap3.md`: bez mojej zmiany. Plik jest już pusty po Twojej edycji.
- Plik szczegółowy usunięty z: `etap1.md` i `etap2.md` (sekcja „Format wyjścia"), `etap0.md` (tabela „Szukane pozycje"), `references/orkiestrator/katalog-wynikowy.md` (linia 7), `examples/etap0-examples/etap0-raport.md` (linia 24).
- `etap2.md`, sekcja „Format wyjścia Etapu 2" (linia 146): zostaje tylko `etap2-plan.md`, bez wyboru A/B.
- `orkiestrator.md`, sekcja „Brama wyjściowa", warunek 1 (linie 223–224): dopisane, że Etap 2 zapisuje plan zawsze w `etap2-plan.md`. Bez tego brama nie przechodzi, gdy użytkownik wybierze Opcję B.

### Sprawdzenie: czy Etap 2 wytrzyma więcej niż jedną iterację

Wynik: bez przerwy w pracy i przy zachowanym kontekście tak, bo model pamięta przebieg. Po przerwaniu albo po wyczyszczeniu kontekstu nie, bo informacje do następnej iteracji nie są nigdzie przekazywane w całości. Niczego z poniższej listy nie zmieniałem.

1. `references/orkiestrator/protokol-komunikacji.md` (linie 28, 37, 38): koperta nie niesie stanu iteracji. `stage.start` ma tylko `payload.config`, `stage.resume` ma tylko `payload.user_answer`, a `user.approval` nie ma opisanego `payload`.
2. `etap2.md`, sekcja „uruchomienie refaktryzacji" i linia 134: analiza ustala liczbę iteracji, ale nigdzie nie zapisuje podziału zakresu na iteracje. Następna iteracja nie wie, którą część zakresu ma wziąć. Nie ma też reguły zmiany liczby iteracji w trakcie pracy, choć tryb jest dynamiczny.
3. `references/etap2/06-siatka-globalna.md`, sekcja 2: sekwencja technik (np. F13 → F14) może przechodzić przez kilka iteracji. Nigdzie nie ma zapisu, które techniki z sekwencji zostały do wykonania.
4. `etap2.md`, sekcja „Format wyjścia Etapu 2": nie ma reguły, czy plan kolejnej iteracji jest dopisywany do `etap2-plan.md`, czy go nadpisuje. Reguła „dopisywana" była tylko w usuniętej Opcji B.
5. `etap2.md`, sekcja „iteracja - wykonanie" (mój tekst) i `protokol-komunikacji.md` (linia 28): `user.approval` służy teraz do akceptacji planu i do sprawdzenia wyniku, a tabela opisuje tylko plan. Etap po `stage.resume` nie wie, której akceptacji dotyczy odpowiedź. Nie ma też reguły, co zrobić, gdy użytkownik odrzuci plan albo wynik.
6. `etap2.md` (linia 101, mój tekst): `00-README.md` i `06-siatka-globalna.md` są wczytywane tylko w pierwszej iteracji. Po wyczyszczeniu kontekstu kolejna iteracja działa bez nich. To mój błąd.
7. `references/orkiestrator/petla-sterowania.md` (linia 16): wznowienie wskazuje etap, ale nie iterację. Etap 2 po wznowieniu zacząłby od analizy całego zakresu. Pole `iteracje` w `examples/etap0-examples/etap0-raport.md`, które dodałem, nie jest opisane w `etap0.md`.
8. `etap2.md`, sekcja „iteracja - wykonanie", punkt 1 i sekcja „Reguła niezaliczonego testu": nie ma reguły dla testów czerwonych już na starcie iteracji, np. po przerwaniu w połowie poprzedniej. Etap nie commituje, więc po regresji nie ma punktu powrotu, jeśli użytkownik nie zrobił commita.
9. `etap2.md` (linia 45, mój tekst) i `etap1.md` (linie 31–35): dane między iteracjami są czytane z dysku, co jest niezgodne z Twoją informacją, że wszystkie dane idą przez kopertę.

### Propozycja (czeka na Twoją decyzję)

Stan iteracji przechodzi przez kopertę w polu `payload.stan_iteracji`:

- Etap 2 wysyła pole w każdym `user.approval`, z dodatkowym polem `payload.rodzaj`: `plan` albo `wynik`.
- Orkiestrator odsyła je bez zmian w `stage.resume`. Nie interpretuje go, więc nie przejmuje merytoryki etapu.
- Przy wznowieniu orkiestrator bierze pole z ostatniej wiadomości w `komunikacja/` i przekazuje je w `stage.start`. Wiadomości są już zapisywane na dysku, więc stan przetrwa przerwanie.

Zawartość pola:

```json
{
  "iteracja": 2,
  "iteracje_planowane": 3,
  "zakres_pozostaly": ["OrderService.Calculate"],
  "wykonane": [{ "iteracja": 1, "techniki": ["F16", "F01"], "pliki": ["OrderService.cs"] }],
  "sekwencja_pozostala": ["F13", "F14"],
  "pozycje_otwarte": [],
  "nastepny_numer_wpisu_logu": 14
}
```

Pozostałe zmiany w tej propozycji:

- `etap2.md`: każda iteracja dopisuje do `etap2-plan.md` sekcję `## Iteracja N`, a liczbę iteracji można zmienić w planie kolejnej iteracji.
- `etap2.md`: `00-README.md` i `06-siatka-globalna.md` są wczytywane na początku każdej iteracji.
- `etap2.md`: odrzucenie planu oznacza poprawę planu, a odrzucenie wyniku oznacza zatrzymanie etapu i `user.input`.
- `etap2.md`: czerwone testy na starcie iteracji oznaczają zatrzymanie etapu i `user.input`.
- `etap2.md`: wiadomość z wynikiem iteracji w `user_message` przypomina o commicie użytkownika.
- `protokol-komunikacji.md`, `petla-sterowania.md`, `etap0.md` oraz przykłady: opis nowych pól.

### Pytania

1. Czy wprowadzić powyższą propozycję?
2. Czy `stan_iteracji` ma też obowiązywać w Etapie 1? `etap1.md` (linie 31–35) czyta `refactor-decisions.md` z dysku. Czy to też ma przejść na `payload.config`?
3. `references/orkiestrator/konfiguracja-wstepna.md`, Pytanie 1: skoro Etap 2 nie ma wyboru, a Etap 3 jest pusty, Opcja B dotyczy tylko Etapu 1. Czy Pytanie 1 usunąć i wszędzie przyjąć Opcję A?
4. `references/orkiestrator/konfiguracja-wstepna.md`, Pytanie 2, Opcja A („wszystkie etapy"): orkiestrator wyśle `stage.start` do pustego `etap3.md`, a brama wyjściowa nigdy nie przejdzie. Razem z tekstem w `etap3.md` zniknęła też reguła `error.critical`. Proponuję, żeby orkiestrator pomijał Etap 3, dopóki jest pusty, i odnotowywał to w logu. Czy tak zrobić?

## user - odpowiedzi

1. możesz wprowadzić poprawkę
2. etapy mogą czytać pliki z dysku, a ten plik refactor-decisions to konfiguracja to musi być czytane, koperta wiadomości jest tworzona jako komunikacja miedzy orkiestratorem a etapami, albo etapami a orkiestratorem i w kolejnych krokach iteracji jako zapis ostatniego stanu, dzięki temu wznowienie będzie mogło spojrzeć na ostatnią ramkę wiadomości i sprawdzic w jakim jest stanie nawet jeżeli nie będzie jej zaimplementowanej albo proces się przerwie to w najgorszym wypadku ta ramka zostanie ponownie zaimplementowana a nie cały proces zacznie się od zera.
3. tak przyjmij wszędzie opcje A - uprości to trochę
4. Etap3 będzie pomijany. Aktualnie mamy dwa etap1 i etap2 etap0 też ale on służy do czegoś innego i jest odpapany zawsze na starcie wiec go nie wliczamy do wyboru

## Claude

### Rezultat zmian

Numer wersji bez zmian (0.1.1). Niczego nie uruchamiałem.

Odpowiedzi 1 i 2, stan iteracji w kopercie:

- `references/orkiestrator/protokol-komunikacji.md`: nowa sekcja „Stan iteracji" (ramka, pola, zasady wznowienia). W „Katalogu akcji" opisane `payload.rodzaj` oraz `payload.stan_iteracji` w `stage.start` i `stage.resume`.
- `references/orkiestrator/petla-sterowania.md`, punkty 4 i 5: przekazanie stanu przy wznowieniu i w `stage.resume`.
- `examples/orchestrator-examples/stan-iteracji.md`: nowy plik z przykładem, dodany do `manifest.json`, pole `pliki_harnessu`. Pole dopisane też w `etap2-pyta-uzytkownika.md`.
- `etap0.md`, sekcja „Wyjście — raport JSON": opisane pole `etapy[].iteracje`.
- `etap2.md`: nowa sekcja „Stan iteracji i wznowienie", podział zakresu na iteracje, dopisywanie sekcji `## Iteracja N` do planu, wczytywanie `00-README.md` i `06-siatka-globalna.md` w każdej iteracji, reguły odrzucenia planu i wyniku, reguła czerwonych testów na starcie, przypomnienie o commicie.
- `etap1.md`: nowa sekcja „Stan iteracji i wznowienie", dopisywanie sekcji `## Iteracja N` do planu. Czytanie `refactor-decisions.md` z dysku zostaje (linie 31–35).

Odpowiedź 3, Opcja A wszędzie:

- `references/orkiestrator/konfiguracja-wstepna.md`: usunięte Pytanie 1 o strukturę plików. „Zakres etapów" to teraz Pytanie 1, a we wszystkich plikach „Pytania 0–2" zmienione na „Pytania 0–1".
- `etap1.md`, sekcja „Format wyjścia Etapu 1": zostaje tylko `etap1-plan.md`.
- `orkiestrator.md`, brama wyjściowa, warunek 1: plik wynikowy to `etapN-plan.md`.
- `etap0.md`, tabela „Szukane pozycje": usunięty `refactor-plan.md`.
- `examples/orchestrator-examples/log-decyzji.md` i `examples/etap0-examples/etap0-raport.md`: usunięta stara pozycja Pytania 1, a pole `pytanie_2` zmienione na `pytanie_1`.

Odpowiedź 4, Etap 3 pomijany:

- `references/orkiestrator/petla-sterowania.md`, punkt 3: Etap 3 nie wchodzi do kolejki, dopóki `etap3.md` jest pusty. Orkiestrator odnotowuje to w logu.
- `references/orkiestrator/konfiguracja-wstepna.md`, „Zakres etapów": pytanie dotyczy tylko Etapów 1–2.
- `orkiestrator.md`, tabela plików, i `examples/etap0-examples/etap0-raport.md`: opis Etapu 3 zmieniony na pomijany, wpis Etapu 3 usunięty z przykładu.

Trzy miejsca, w których odszedłem od przyjętej propozycji albo ją doprecyzowałem:

- Usunąłem pole `nastepny_numer_wpisu_logu`. Po powtórzeniu iteracji numer byłby nieaktualny, a etap może czytać log z dysku (Twoja odpowiedź 2), więc numer odczytuje z logu.
- Stan iteracji obowiązuje w Etapie 1 i Etapie 2. Twoją odpowiedź 2 odczytałem jako regułę dla wszystkich iteracji.
- Pole `wykonane` obejmuje tylko iteracje potwierdzone przez użytkownika. Gdy proces przerwie się po potwierdzeniu, a przed kolejną ramką, iteracja zostanie powtórzona. Etap najpierw sprawdza kod i testy, więc nie wykona zmian drugi raz.

### Pytania

1. `references/orkiestrator/konfiguracja-wstepna.md`, Pytanie 1, Opcje B i C (linie 48–51): Opcja B pozwala pominąć Etap 1, a Opcja C wymaga, żeby Etap 1 był zawsze wykonany. Przy dwóch etapach to sprzeczne. `etap2.md`, „Brama wejściowa" (linia 13), też wymaga zakończenia Etapu 1. Czy można pominąć Etap 1, gdy kod ma już testy?
2. `orkiestrator.md`, „Etap 0 i wznowienie sesji", punkt 2: przy istniejącym `refactor-session.md` Etap 0 nie jest uruchamiany ponownie, a orkiestrator korzysta z zapisanego `etap0-raport.json`. Raport może być starszy niż przerwany przebieg, więc może wskazać niewłaściwy etap. Proponuję, żeby etap do wznowienia wskazywała ostatnia ramka w `komunikacja/`. Czy tak zrobić?

## user - odpowiedzi

likwidujemy możliwość wyboru tylko etapu2, bo faktycznie tam jest reguła że etap1 musi być wykonany.
Ale ta reguła może być pominięta ale nie przez nie wykonanie etapu1 ale w etapie1 musi znaleźć się zapis jeżeli są unit testy do wybranego fragmentu kodu przejdz do etapu2. Bo to logiczne jest skoro mam testy to po co mam je robić drugi raz.
Podsumowujac zabieramy z konfiguracji możliwość wybrania etapu ale etap1 nie zawsze zakończy się wykonaniem testów ale zawsze się wykona, bo jeżeli testy istnieją robienie ich ponownie nie ma sensu.
Tu jest odstępstwo jeżeli testy są niepełne to trzeba je dopełnić czyli wtedy etap1 musi je dogenerowa czyli zrobić analizę kontekstu wybranego przez użytkownika pod kątem brakujacych testów.
Dopisz to do etapu1

## Claude

### Rezultat zmian

Numer wersji bez zmian (0.1.1). Niczego nie uruchamiałem.

Wybór etapów usunięty, Etap 1 wykonuje się zawsze:

- `references/orkiestrator/konfiguracja-wstepna.md`: usunięte Pytanie 1 „Zakres etapów”, nowa sekcja „Kolejka etapów”.
- `orkiestrator.md`, „Brama wejściowa”: usunięty warunek 3 o pominięciu etapu, dawny warunek 4 ma teraz numer 3. „Zasada nieprzeskakiwania”: kolejka jest stała.
- `references/orkiestrator/petla-sterowania.md`, punkt 3: kolejka jest stała.
- „Pytania 0–1” zmienione na „Pytanie 0” w `orkiestrator.md`, `etap0.md`, `etap1.md`, `petla-sterowania.md`, `konfiguracja-wstepna.md`.
- `etap0.md`, sekcja „Wyjście — raport JSON”: usunięty status `skipped`.
- `examples/orchestrator-examples/log-decyzji.md`, `examples/etap0-examples/etap0-raport.md`: usunięte Pytanie 1 i pole `pytanie_1`.
- `etap1.md`: nowa sekcja „Rozpoznanie istniejących testów” z trzema przypadkami (testy pełne, niepełne, brak). Sekcja „Format wyjścia Etapu 1”: nowa sekcja planu `## Rozpoznanie testów`. Sekcja „Log Etapu 1”: nowy wpis z wynikiem rozpoznania.
- `etap2.md`, „Brama wejściowa”: testy z Etapu 1 obejmują też testy istniejące, rozpoznane jako pełne albo uzupełnione.

Wznowienie zawsze przez Etap 0:

- `etap0.md`: nowa sekcja „Ostatnia ramka (pole `wznowienie`)”, tabela „Szukane pozycje” obejmuje odczyt ramki.
- `orkiestrator.md`, „Etap 0 i wznowienie sesji”, „Przebieg” i „Interpretacja raportu”: każde wejście przechodzi przez Etap 0, decyzję o wznowieniu opiera się na polu `wznowienie`.
- `references/orkiestrator/protokol-komunikacji.md`, `petla-sterowania.md`, punkty 1 i 4: orkiestrator nie czyta `komunikacja/`, bierze `wznowienie.stan_iteracji` z raportu.
- `examples/etap0-examples/etap0-raport.md`: nowe pole `wznowienie`.

Miejsca, w których odszedłem od propozycji albo dodałem coś od siebie, do Twojej oceny:

- `orkiestrator.md`, „Przebieg”, punkt 2: dawny zapis „Etap 0 nie jest uruchamiany ponownie” chronił też przed zapętleniem, bo po `/clear` plik `refactor-session.md` już istnieje. Dodałem pole `Stan raportu` (`do wczytania` / `wczytany`) w `refactor-session.md`. Etap 0 nie jest zlecany tylko przy `do wczytania`, czyli przy powrocie po czyszczeniu. Pole opisane w `examples/orchestrator-examples/stan-sesji-harnessu.md`.
- `orkiestrator.md`, „Przebieg”, punkt 6: pytanie „wznowienie czy nowa sesja” pada teraz po raporcie Etapu 0, a nie przed nim. Tak mówi już sekcja „Interpretacja raportu”, a odpowiedź ma się opierać na raporcie.
- `orkiestrator.md`, „Przebieg”, punkt 5: dopisany `/clear`, który był w tytule punktu i w `petla-sterowania.md`, punkt 1, ale nie w treści punktu.
- `examples/orchestrator-examples/log-orkiestratora.md` (linie 11, 16): usunięta nieopisana nigdzie reguła „4 h”, zastąpiona polem `Stan raportu`.
- `etap1.md`, „Rozpoznanie istniejących testów”: czerwony istniejący test zatrzymuje etap i wysyła `user.input`, bo taki test nie jest punktem odniesienia dla Etapu 2.
- `etap1.md`, wiersz „Testy są pełne”: przed `stage.done` etap wysyła `user.approval`, bo `orkiestrator.md`, „Brama wejściowa”, warunek 3 wymaga akceptacji wyniku. Plan zawsze powstaje, bo wymaga go „Brama wyjściowa”, warunek 1.

### Pytania

1. `etap1.md`, „Rozpoznanie istniejących testów”: nie ma definicji „testy są pełne”. Etap ocenia to sam, a użytkownik potwierdza w `user.approval`. Czy to wystarczy, czy podać kryterium, np. każda ścieżka i warunek brzegowy fragmentu?

