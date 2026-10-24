# Odpowiedzi Claude do changes-project2.md — zadanie2

## Claude - zadanie2: kontrakt `Contract.orkiestrator.start`

Analizowany plik: `refactor-legacy-v0.3.0/orkiestrator.md`, linie 51–75. Wzorzec: `.claude/agents/etap0.md`, `contract Etap0.Start`. Przykłady ramek: `etap0-examples/message-frame.md`. W orkiestratorze nic nie zmieniałem.

### 1. Zasady Meyera — krótko

| Część | Co w niej jest | Kto za nią odpowiada |
|---|---|---|
| `pre` | warunki, które **muszą być prawdziwe przed** wywołaniem. Nie zawiera akcji | wywołujący |
| `post` | warunki, które **są prawdziwe po** wykonaniu. Opisuje wynik, nie sposób jego uzyskania | wywoływany |
| `invariant` | warunki prawdziwe **zawsze**: przed i po każdym kontrakcie danego obiektu (tu: orkiestratora) | obiekt |

Gdy kontrakt A wywołuje kontrakt B, A musi spełnić `pre` kontraktu B. Wtedy może polegać na `post` kontraktu B. Tak wygląda „kolejny wywołany kontrakt” — dobrze to rozumiesz.

### 2. Uwagi do linii 51–75

| Linia | Jest | Problem | Wskazówka |
|---|---|---|---|
| 51 | `Contract.orkiestrator.start` | inny zapis niż w etap0.md (`contract Etap0.Start`) | `contract Orkiestrator.Start` |
| 55 | `P1: uruchom Etap0` | to akcja, nie warunek | przenieść do kroków (sekcja `do`, punkt 3) albo do osobnego kontraktu |
| 56 | `P2: GenerateFrameMessage()` | to akcja, nie warunek | jak wyżej; ramka startowa jest **wynikiem** (`post`) kontraktu wysyłającego |
| 61 | `Q1: output == wyłącznie JSON ramki` | to `post` kontraktu **etap0** (tam jako Q1), nie orkiestratora | w orkiestratorze: warunek wejściowy kontraktu, który przyjmuje odpowiedź (`pre` kontraktu `Orkiestrator.RouteEtap0`) |
| 62 | `Q2: framePath != null` | `framePath` to szczegół wewnętrzny etap0; orkiestrator go nie zna | usunąć |
| 63–66 | `payload is not empty` / `payload is empty` | ramka `done` „brak poprzedniej sesji” ma `payload.directories` (message-frame.md), więc payload **nigdy nie jest pusty**, a Q4 nigdy się nie spełni | rozróżniać po `payload.report`: `!= null` → jest poprzednia sesja; `== null` → brak |
| 64 | `=> ContinueSesstion()` | literówka; scenariusz w liniach 88–97 wymaga **pytania do usera** przed kontynuacją | `=> AskUser(ContinueOrNew)`, a dopiero wynik prowadzi do `ContinueSession()` albo `NewSession()` |
| 67 | `failed && payload is not empty` | warunek `payload` jest zbędny: `frame-model.md` I2 gwarantuje `payload.error` przy `failed` | `status == failed => ReportErrorToUser(payload.error)` |
| 68 | `ErrotUser()` | literówka | `ReportErrorToUser(...)` |
| — | brak | nie są sprawdzane `from`, `to`, `action` ani powiązanie odpowiedzi z wysłaną ramką | patrz punkt 3, `pre` kontraktu `Orkiestrator.RouteEtap0` |
| — | brak | nie są obsłużone statusy `in_progress` i `blocked` (message-frame.md, koperta) | dopisać gałąź albo zawęzić statusy odpowiedzi etap0 do `done`/`failed` w `pre` |
| 73 | `I1:` puste | — | patrz punkt 4 |
| 6 | „enumy w `references/frame-model.md`” | w frame-model.md nie ma definicji `FrameStatus` | dopisać enum do frame-model.md |

### 3. Proponowany podział — trzy małe kontrakty

Jeden kontrakt `Start` łączy trzy rzeczy: wysłanie, odbiór i decyzję. Fragmentami łatwiej:

```
contract Orkiestrator.SendStartEtap0 -> Frame request
{
   pre
   {
      P1: harness zainstalowany (manifest.json istnieje)
   }
   post
   {
      Q1: request.from == orkiestrator && request.to == etap0
      Q2: request.action == "stage.start"
      Q3: request.msg_id jest unikalny
      Q4: agent etap0 został uruchomiony z request jako wejściem
   }
}

contract Orkiestrator.RouteEtap0(Frame request, Frame response)
{
   pre
   {
      P1: response jest poprawnym JSON zgodnym z model Frame
      P2: response.from == etap0 && response.to == orkiestrator
      P3: response.action == "stage.done"
      P4: response.corr_id == request.msg_id
      P5: response.status ∈ { done, failed }
   }
   post
   {
      Q1: response.status == failed
          => ReportErrorToUser(response.payload.error) && proces zatrzymany
      Q2: response.status == done && response.payload.report != null
          => AskUser(ContinueOrNew) wykonane
      Q3: response.status == done && response.payload.report == null
          => NewSession()
   }
}

contract Orkiestrator.Start
{
   pre  { }
   do
   {
      request  = SendStartEtap0()
      response = <odpowiedź agenta etap0>
      RouteEtap0(request, response)
   }
   post
   {
      Q1: dokładnie jedna z gałęzi RouteEtap0 Q1–Q3 została wykonana
   }
}
```

Uwagi do propozycji:
- Sekcja `do` nie jest elementem klasycznego zapisu Meyera (on zostawia ciało metody w kodzie). Tu ciało opisuje kolejność wywołań kontraktów. Bez niej LLM nie wie, w jakim porządku je wykonać.
- `P4: corr_id == request.msg_id` — obecnie ramkę `done` zapisuje skrypt uruchamiany przez hook, z `corr_id = null` (message-frame.md). Do decyzji: czy skrypt ma dostać `msg_id` ramki startowej (hook `SubagentStart` musiałby go skądś odczytać), czy rezygnujemy z P4.
- `"stage.start"` — nowa wartość `action`; do decyzji, czy wpisać ją do enum `FrameActions` w frame-model.md.
- `AskUser`, `NewSession`, `ContinueSession`, `ReportErrorToUser`, `SendStartEtap0` — każda wymaga własnego kontraktu w `references/contracts.md`. Robimy je kolejno, gdy dojdziemy do danego fragmentu.

### 4. Inwarianty — jak je szukać

Inwariant to zdanie prawdziwe **w każdej chwili** pracy orkiestratora, a nie tylko po jednym kroku. Pytanie kontrolne: „czy to musi być prawdą także między etapami?”. Kandydaci wynikający z obecnego `orkiestrator.md`:

```
invariant Orkiestrator
{
   I1: żaden etap nie jest uruchamiany inaczej niż przez orkiestratora          // linie 19–21
   I2: etapy nie komunikują się bezpośrednio; każda ramka ma from lub to == orkiestrator  // linie 34–36
   I3: orkiestrator nie modyfikuje ramek zapisanych w communication/
   I4: w danej chwili aktywny jest co najwyżej jeden etap
   I5: każda ramka spełnia invariant model Frame (frame-model.md)
}
```

Inwarianty należą do orkiestratora jako całości. Lepiej trzymać je w jednym bloku `invariant Orkiestrator` niż powtarzać w każdym kontrakcie.

### Do decyzji

1. Podział na trzy kontrakty (punkt 3) czy jeden `Orkiestrator.Start` z poprawionymi `pre`/`post`?
2. `corr_id` — wiązać odpowiedź z ramką startową czy nie (punkt 3, uwaga 2)?
3. `action` ramki startowej — `"stage.start"`?
4. Statusy `in_progress`/`blocked` w odpowiedzi etap0 — dopuszczalne czy wykluczone w `pre`?

## user

zaimplementuj to co zaproponowałeś, nie będzie my robić dosłownego Meyera, ale będziemy go dostsowywać do potrzeb, za step to co ja napisałem swoim a ja reszte sobie usunę sam

## Claude - wykonanie

`refactor-legacy-v0.3.0/orkiestrator.md`, w miejscu `Contract.orkiestrator.start` (po sekcji „Przykłady”, przed „### Zasada działania”): blok `invariant Orkiestrator` (I1–I4) oraz kontrakty `Orkiestrator.Start`, `Orkiestrator.SendStartEtap0`, `Orkiestrator.RouteEtap0` według punktu 3. Pozostała treść orkiestratora bez zmian.

Dopasowanie do `references/frame-model.md` (w wersji, którą zmieniłeś w międzyczasie):
- nadawca i odbiorca jako `Participant.orchestrator` / `Participant.stage0`;
- `action` jako `Action.stateStart` / `Action.stageDone` — w ten sposób decyzja 3 odpada;
- `SendStartEtap0` Q3: `request.isInitial()` zamiast „msg_id unikalny”;
- `RouteEtap0` P4: `response.corr_id == request.msg_id`, ściśle, zgodnie z frame-model.md I3;
- z `invariant Orkiestrator` usunięty mój punkt „każda ramka ma from lub to == orkiestrator”, bo pokrywa go frame-model.md I5.

W `frame-model.md` nic nie zmieniłem.

Rozbieżności do decyzji:
1. `frame-model.md`, enum `Action`: `stateStart` — literówka? (powinno być `stageStart`; w kontrakcie użyłem nazwy z pliku).
2. `frame-model.md`, `model Frame`: pole `action: Acton` — literówka (`Action`).
3. Skrypt `scripts/etap0/00-rozpoznanie.ps1` i hook `etap0-start.ps1` zapisują ramki niezgodne z nowym modelem: `msg_id = "e0-NNN"` (model: `NNN`), `corr_id = null` (model I3: wymagany przy ramce nie-początkowej), `from = "etap0"` / `to = "orkiestrator"` (model: `stage0` / `orchestrator`), `action = "stage.done"` (model: `stageDone`), `timestamp = "yyyy-MM-dd; HH-mm-ss"` (model I8: ISO 8601 z offsetem). Przy obecnym skrypcie warunki `RouteEtap0` P1–P4 nie zostaną spełnione. To samo dotyczy przykładów w `etap0-examples/message-frame.md` i kontraktu `.claude/agents/etap0.md`.
4. Skrypt uruchamiany przez hook `SubagentStart` nie zna `msg_id` ramki startowej orkiestratora — bez tego nie ustawi `corr_id` (P4).
5. Statusy `in_progress`/`blocked` wykluczone w P5 (decyzja 4 przyjęta jak w propozycji).
6. Kontrakty `AskUser`, `NewSession`, `ReportErrorToUser` jeszcze nie istnieją — następny fragment.

## user - uwagi

popraw skrypty będzie prostrzy msg_id będzie teraz tylko liczbą w formacie 001 do 999,
popraw literówki
examble też popraw,
ramka będzie tylko jedna czyli ta z frame-model.md, tyczy się też ramki powracającej z etapu 0

## Claude - wykonanie uwag (skrypty, literówki, przykłady, jedna ramka)

Wszystkie ramki mają format `references/frame-model.md`: `msg_id` `"NNN"` (001–999), `from`/`to` z enum `Participant`, `action` z enum `Action`, `timestamp` ISO 8601 z offsetem (`yyyy-MM-ddTHH:mm:sszzz`).

1. `scripts/etap0/_wspolne.ps1`:
   - `Get-NastepnyNumerRamki` zwraca najmniej 2 (numer 001 ma ramka startowa orkiestratora, `isInitial`), a powyżej 999 zgłasza błąd;
   - nowa funkcja `Get-ZnacznikRamki` (timestamp ramki).
   `Get-Znacznik` (logi) bez zmian.
2. `scripts/etap0/00-rozpoznanie.ps1`:
   - zapis ramki `done`: `msg_id = NNN`, `corr_id = "001"`, `stage0` → `orchestrator`, `stageDone`, `Get-ZnacznikRamki`;
   - odczyt ramek poprzedniej sesji (`Get-RequestyOtwarte`, `Get-Etapy`): `orchestrator`, `stageDone`, `stepDone`, `stageAborted`, `stageStart`, `stepStart`; adres etapu `stage<N>` (dopasowanie po prefiksie — obejmuje `stage1part1`, `stage1part2`);
   - nagłówek: odsyłacz do frame-model.md, opis `payload.directories`.
3. `.claude/hooks/etap0-start.ps1`, `Save-RamkaFailed`: te same pola co w punkcie 2, numer najmniej 002.
4. `references/frame-model.md`: `stateStart` → `stageStart`, `Acton` → `Action`, w komentarzach `zakońcozny` → `zakończony`, `przewanie` → `przerwanie`. `orkiestrator.md`, `SendStartEtap0` Q2: `Action.stageStart`.
5. `etap0-examples/message-frame.md`: przepisany. Doszła ramka startowa orkiestratora; ramki `done`, `failed` i `failed` bez pliku są w nowym formacie. Usunięta sekcja „Koperta — komplet pól” (zastępuje ją frame-model.md).
6. `etap0-examples/etap0-raport.md`, `requesty_otwarte`: przykład w nowym formacie (`msg_id "031"`, `stage2part1`, `userInput`).
7. `references/contracts.md`: nowy kontrakt `FailedFrame(error)`. Był używany w `.claude/agents/etap0.md` (Q3, Q4), ale nie miał definicji.

Uwagi do decyzji:
1. `corr_id = "001"` na sztywno — wynika z `SendStartEtap0` Q3 (`request.isInitial()`). Ramka startowa nie jest zapisywana do `communication/`. Przy wznowieniu katalog zawiera już `001` z poprzedniego przebiegu, więc nowa ramka startowa ma ten sam numer co istniejący plik. Do decyzji: czy ramka startowa ma być zapisywana i numerowana jak pozostałe (wtedy `isInitial` nie może oznaczać `msg_id == "001"`).
2. Ramka startowa w przykładzie ma `status: in_progress` — model wymaga statusu, a żadna wartość nie pasuje wprost.
3. `FailedFrame`: `msg_id = "002"` umownie, bo ramka nie trafia na dysk.
4. Usunięta akcja `stage.resume` (brak w enum `Action`) — skrypt nie rozpoznaje jej już jako „w toku”.
5. Znaczniki w logach (`orkiestrator-log.md`, `generated_at` w raporcie) zostają w formacie `yyyy-MM-dd; HH-mm-ss` — dotyczą logu, nie ramki.

## user uwagi

popraw przykłądową ramke ona nie może powinna być inprogres dostosuj przykłąd do istniejącego status,
format znacznika czasu w logach ustaw taki jak w ramce,

dodaj skrypt uruchamiany przez orkiestrator który będzie uruchamiany dla ramki która przychodzi z etapu0, ten skrypt ma sprawdzić czy ramka jest zgodna z jej modelem, to będzie skrypt który będzie sprawdzał każde pole ramki według frame-model.md oraz dodatkowo będzie sprawdzał czy payload zawiera odpowiednią strukturę, ale tylko wtedy gdy status jest done i payload nie jest pusty.
Tam chodzi o strukurę która wcześniej była w raporcie etapu0. tle że teraz ten paylod będzie zmniejszony bo będzie tam wypisane jakie pliku zostały wygenerowane w poprzedniej sesji.
Ten skrypt wepnij w kontrakty

## Claude - wykonanie uwag (status ramki startowej, znacznik czasu, walidator)

Decyzje z rozmowy: ramka startowa ma `status: done`; payload Etapu 0 zawiera tylko listę plików (bez raportu); walidator leży w `scripts/orchestrator/`.

1. `etap0-examples/message-frame.md`:
   - ramka startowa: `status: done`;
   - ramka `done` z poprzednią sesją: `payload.files` zamiast `payload.report`.
2. Znacznik czasu: `scripts/etap0/_wspolne.ps1`, `Get-Znacznik` — ISO 8601 z offsetem, ten sam format dla ramek i logów. Usunięta funkcja `Get-ZnacznikRamki` (zastępuje ją `Get-Znacznik`). `orkiestrator.md` nie opisuje formatu logu, więc nie było tam czego zmieniać.
3. Payload Etapu 0 — `scripts/etap0/00-rozpoznanie.ps1` przepisany:
   - ramka `done`: `payload.files` (ścieżki wszystkich plików w aktywnym `refactor-resultN`, względne, separator `/`; tylko gdy jest poprzednia sesja, czyli istnieje `refactor-config.json`) + `payload.directories` (zawsze);
   - lista plików powstaje przed zapisem nowej ramki — obejmuje tylko pliki poprzedniej sesji;
   - usunięte budowanie raportu i funkcje, których używał (`Get-Konfiguracja`, `Get-Sesje`, `Get-Komunikaty`, `Get-RequestyOtwarte`, `Get-Etapy`, `Get-PozycjeOtwarte`, `Get-SesjaPoprzednia`, anomalie). Z `_wspolne.ps1` usunięte nieużywane `ConvertFrom-Znacznik`, `Get-ZnacznikZLinii`, `Read-JsonPliku`, `Get-PoleObiektu`, `Get-OstatniaAktywnosc`. Treść jest w historii git;
   - usunięty plik `etap0-examples/etap0-raport.md` (przykład raportu) i jego wpis w `manifest.json`.
4. Walidator — nowy plik `scripts/orchestrator/validate-etap0-frame.ps1`:
   - wejście: `-SciezkaRamki <plik>` albo `-Tresc '<JSON>'` (ramka `failed` bez pliku istnieje tylko w odpowiedzi agenta);
   - enumy `Participant`, `Action`, `FrameStatus` czyta z `references/frame-model.md` — jedno źródło prawdy, bez kopii w skrypcie;
   - sprawdza: komplet pól i brak pól spoza modelu, typy, enumy, invarianty I1–I8;
   - gdy `status == done` i payload niepusty: dozwolone tylko `directories` (wymagane, tablica niepustych napisów) i `files` (opcjonalne, tablica niepustych napisów);
   - wyjście: `{"valid": bool, "errors": [...]}`, kod 0 / 1 / 2 (poprawna / niepoprawna / błąd wywołania);
   - JSON parsowany przez `System.Text.Json` — `ConvertFrom-Json` w PowerShell 7 zamienia napisy ISO 8601 na daty i walidacja `timestamp` byłaby niemożliwa.
5. Kontrakty:
   - `references/contracts.md`: nowy kontrakt `ValidateEtap0Frame(frame)` — wywołanie skryptu, znaczenie kodów wyjścia;
   - `orkiestrator.md`, `Orkiestrator.Start`: po odpowiedzi agenta `ValidateEtap0Frame`; niepoprawna ramka → `ReportErrorToUser(validation.errors)` i stop, poprawna → `RouteEtap0`;
   - `RouteEtap0`: P1 = `ValidateEtap0Frame(response).valid == true`; Q2/Q3 rozróżniają po `payload.files` zamiast `payload.report`.
6. `manifest.json`, `pliki_harnessu`: dopisane `references/frame-model.md` i `scripts/orchestrator/validate-etap0-frame.ps1`. `references/frame-model.md` dostał znacznik `wersja-harnessu`.

Uwagi:
1. `.claude/agents/etap0.md`, frontmatter `description`: nadal „raport poprzedniej sesji” — do poprawy na „lista plików poprzedniej sesji” (plik etapu, czekam na decyzję).
2. `payload.files` zawiera wszystkie pliki z `refactor-resultN`, łącznie z ramkami w `communication/`. Do decyzji: czy pomijać `communication/`.
3. Walidator nie sprawdza `corr_id == request.msg_id` (P4 `RouteEtap0`) — nie zna ramki startowej. Przy obecnym `corr_id = "001"` warunek jest spełniony z definicji.
