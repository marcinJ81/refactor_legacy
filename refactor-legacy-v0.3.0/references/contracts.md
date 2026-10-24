# Kontrakty pseudokodu harnessu
<!-- wersja-harnessu: 0.3.0 -->

Pseudokod w plikach agentów (np. `.claude/agents/etap0.md`, blok `flow`) używa
metod opisanych poniżej. Każda metoda to kontrakt: dla podanych parametrów
wejściowych zwróć opisany wynik. Sposób realizacji dowolny.

contract GetFramePath() -> string?
{
   pre  { }
   post
   {
      Q1: zwraca <ścieżka> z linii "[etap0] ramka: <ścieżka>" w StartupContext
      Q2: brak takiej linii => null
   }
   invariant
   {
      I1: źródło danych = wyłącznie StartupContext   // nie szuka pliku na dysku
   }
}

contract GetHookError() -> string?
{
   pre  { }
   post
   {
      Q1: zwraca pełną treść linii zaczynającej się od "[etap0][hook]"
      Q2: brak takiej linii => null
   }
   invariant
   {
      I1: źródło danych = wyłącznie StartupContext
   }
}

contract ReadRaw(path) -> string?
{
   pre
   {
      P1: path != null
   }
   post
   {
      Q1: plik istnieje i jest czytelny => zwraca treść bez zmian
      Q2: w przeciwnym razie => null
   }
   invariant
   {
      I1: brak parsowania i ponownej serializacji
   }
}

contract FailedFrame(error) -> Frame
{
   pre
   {
      P1: error != null && error != ""
   }
   post
   {
      Q1: msg_id == "002" && corr_id == "001"
      Q2: from == Participant.stage0 && to == Participant.orchestrator
      Q3: action == Action.stageDone && status == FrameStatus.failed
      Q4: payload == { error }
      Q5: timestamp == bieżący czas, ISO 8601 z offsetem
   }
   invariant
   {
      I1: ramka nie jest zapisywana na dysk
      I2: wynik spełnia invariant model Frame (references/frame-model.md)
   }
}

contract ValidateEtap0Frame(frame) -> { valid: bool, errors: string[] }
{
   pre
   {
      P1: frame != null                       // JSON ramki: plik albo tekst odpowiedzi agenta etap0
   }
   do
   {
      ramka zapisana w pliku => pwsh -File scripts/orchestrator/validate-etap0-frame.ps1 -SciezkaRamki <ścieżka>
      ramka tylko w odpowiedzi => pwsh -File scripts/orchestrator/validate-etap0-frame.ps1 -Tresc '<JSON>'
   }
   post
   {
      Q1: wynik == JSON ze stdout skryptu, bez zmian
      Q2: valid == true  <=> kod wyjścia 0
      Q3: valid == false <=> kod wyjścia 1 && errors niepuste
      Q4: kod wyjścia 2 => valid == false, errors == [ treść stdout skryptu ]
   }
   invariant
   {
      I1: sprawdzane: każde pole ramki według model Frame (references/frame-model.md, enumy i I1–I8)
      I2: status == done && payload niepusty
          => payload ma wyłącznie: directories (wymagane, string[]), files (opcjonalne, string[])
      I3: skrypt niczego nie zapisuje ani nie zmienia
   }
}
