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
| `orkiestrator.md` (ten plik) | Orkiestrator: rozpoznanie stanu, konfiguracja wstępna, protokół, pętla sterowania |
| `manifest.json` | Wersja harnessu i lista plików wymaganych do działania — czyta go instalator |
| `.claude/settings.json` | Hooki harnessu — `SubagentStart` z matcherem `etap0`, |
| `.claude/hooks/etap0-start.ps1` | Opakowanie hooka Etapu 0 — woła skrypt rozpoznania i wypisuje podsumowanie do kontekstu agenta |
| `.claude/agents/etap0.md` | Etap 0 — Rozpoznanie stanu (wznowienie sesji) |

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




