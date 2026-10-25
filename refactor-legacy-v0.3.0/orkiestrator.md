---
name: refactor-legacy
description: Harness do bezpiecznej refaktoryzacji i wprowadzania zmian w kodzie legacy. Używać zawsze gdy użytkownik prosi o refaktor, zmianę zachowania istniejącego kodu, wydzielenie metod/klas, dodanie testów do kodu bez pokrycia testami, lub redukcję couplingu. Orkiestrator prowadzi proces etapami, pilnuje poprawnego wykonania każdego etapu nie pomijać etapów, nawet jeśli zadanie wygląda na proste. Orkiestator działa według ustalonej sekwencji kroków. Nie wymysla nowych, nie wychodzi po za zakres zdefiniowanych wartości.
---
<!-- wersja-harnessu: 0.3.0 -->
Model ramki wiadomości oraz enumy w  `references/frame-model.md`

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
| `orkiestrator.md` (ten plik) | Orkiestrator: kontrakty uruchomienia Etapu 0, konfiguracja wstępna, pętla sterowania |
| `manifest.json` | Wersja harnessu i lista plików wymaganych do działania — czyta go instalator |
| `references/frame-model.md` | Model ramki wiadomości (`Frame`) i enumy `Participant`, `Action`, `FrameStatus` — wspólne dla wszystkich ramek |
| `references/contracts.md` | Kontrakty metod używanych w kontraktach orkiestratora i agentów (`GetFramePath`, `GetHookError`, `ReadRaw`, `FailedFrame`, `ValidateEtap0Frame`) |
| `references/orchestrator/Configuration.md` | Konfiguracja wstępna — ładowana przez orkiestratora po Etapie 0, gdy to nowa sesja |
| `references/etap1-step1/feathers-technique-selection.md` | Wybór techniki łamania zależności — źródło dla analizy w Etapie 1 |
| `references/etap1-step1/feathers-dependency-breaking-csharp.md` | Katalog technik łamania zależności w C# — źródło dla analizy w Etapie 1 |
| `etap0-examples/message-frame.md` | Przykłady ramek: startowa orkiestratora, `done` (z poprzednią sesją i bez), `failed` |
| `etap1.md` | Etap 1 — testy charakteryzujące |
| `etap2.md` | Etap 2 — wprowadzenie zmiany (refaktor i/lub zmiana logiki) |
| `etap3.md` | Etap 3 — refaktoryzacja rezultatu Etapu 2 |
| `.claude/settings.json` | Hooki harnessu — `SubagentStart` z matcherem `etap0` |
| `.claude/hooks/etap0-start.ps1` | Hook startu agenta Etapu 0 — woła skrypt rozpoznania, przy błędzie zapisuje ramkę `failed`, przekazuje ścieżkę ramki do kontekstu agenta |
| `.claude/agents/etap0.md` | Agent Etapu 0 — kontrakt `Etap0.Start`: zwraca ramkę zapisaną przez skrypt rozpoznania albo hook; gdy ramki nie ma — ramkę `failed` (`FailedFrame`) |
| `scripts/etap0/00-rozpoznanie.ps1` | Skrypt rozpoznania — szuka najnowszego `refactor-resultN`, zakłada `communication/`, zapisuje ramkę `done` (`payload.files`, `payload.directories`) |
| `scripts/etap0/_wspolne.ps1` | Funkcje wspólne skryptu rozpoznania (znacznik czasu, katalogi wynikowe, numer ramki, zapis JSON) |
| `scripts/orchestrator/validate-etap0-frame.ps1` | Walidacja ramki z Etapu 0 według `references/frame-model.md` i struktury payload — uruchamia orkiestrator (kontrakt `ValidateEtap0Frame`) |

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
invariant Orkiestrator
{
   I1: żaden etap nie jest uruchamiany inaczej niż przez orkiestratora
   I2: orkiestrator nie modyfikuje ramek zapisanych w communication/
   I3: w danej chwili aktywny jest co najwyżej jeden etap
   I4: każda ramka spełnia invariant model Frame (references/frame-model.md)
}

contract Orkiestrator.Start
{
   pre  { }
   do
   {
      request  = SendStartEtap0()
      response = <odpowiedź agenta etap0>
      validation = ValidateEtap0Frame(response)
      validation.valid == false => ReportErrorToUser(validation.errors), proces zatrzymany
      validation.valid == true  => RouteEtap0(request, response)
   }
   post
   {
      Q1: validation.valid == false => RouteEtap0 nie został wywołany
      Q2: validation.valid == true  => dokładnie jedna z gałęzi RouteEtap0 Q1–Q3 została wykonana
   }
}

contract Orkiestrator.SendStartEtap0 -> Frame request
{
   pre
   {
      P1: harness zainstalowany (manifest.json istnieje)
   }
   post
   {
      Q1: request.from == Participant.orchestrator && request.to == Participant.stage0
      Q2: request.action == Action.stageStart
      Q3: request.isInitial()
      Q4: agent etap0 został uruchomiony z request jako wejściem
   }
}

contract Orkiestrator.RouteEtap0(Frame request, Frame response)
{
   pre
   {
      P1: ValidateEtap0Frame(response).valid == true
      P2: response.from == Participant.stage0 && response.to == Participant.orchestrator
      P3: response.action == Action.stageDone
      P4: response.corr_id == request.msg_id
      P5: response.status ∈ { FrameStatus.done, FrameStatus.failed }
   }
   post
   {
      Q1: response.status == FrameStatus.failed
          => ReportErrorToUser(response.payload.error) && proces zatrzymany
      Q2: response.status == FrameStatus.done && response.payload.files != null
          => AskUser(ContinueOrNew) wykonane
      Q3: response.status == FrameStatus.done && response.payload.files == null
          => NewSession()
   }
}




