<!-- wersja-harnessu: 0.3.0 -->
enum Participant
{
   orchestrator, stage0,
   stage1part1, stage1part2,
   stage2part1, stage2part2,
   stage3part1, stage3part2
}
enum Action
{
   testUpdate, -- istniejący test wymaga aktualizacji (np. po zmianie nazwy)
   testAdd, -- trzeba dopisać nowy test
   testRemove, -- test stał się zbędny
   testMockEnabled, -- trzeba włączyć obsługę mocków w projekcie testowym
   testMockAdd, -- trzeba dodać mock/stub dla przeniesionej zależności
   userInput, -- potrzebna informacja od użytkownika
   userApproval, -- akceptacja usera
   stageDone, -- etap zakończony
   stepDone, --krok zakończony
   stageAborted, --przerwanie działania
   error, --zgłoszenie wyjątku
   stageStart, -- start etapu
   stepStart, --start kroku
   taskExecute, -- do przemyślenia
}

enum FrameStatus
{
   in_progress, done, failed, blocked
}

model Frame
{
   msg_id:    string
   corr_id:   string?
   from:      Participant
   to:        Participant
   action:    Action
   status:    FrameStatus
   payload
   timestamp: string

   isInitial() := msg_id == "001"

   invariant
   {
      I1: msg_id matches ^(?:00[1-9]|0[1-9][0-9]|[1-9][0-9]{2})$
      I2: isInitial()      implies  corr_id == null
      I3: not isInitial()  implies  corr_id != null
                                    && corr_id matches regex(I1)
                                    && toInt(corr_id) < toInt(msg_id)
      I4: from != to
      I5: from == orchestrator || to == orchestrator     -- jeśli topologia gwiazdy
      I6: status == failed   implies  payload.error.isNotBlank()
      I7: status == blocked  implies  payload.reason.isNotBlank()
      I8: timestamp is ISO 8601 with offset
   }
}
