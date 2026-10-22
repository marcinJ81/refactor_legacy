---
name: etap0
description: Etap 0 — rozpoznanie stanu przed konfiguracją wstępną. Uruchamiany wyłącznie przez orkiestratora. Rozpoznanie wykonuje skrypt uruchomiony przez hook startu agenta i zapisuje ramkę w communication/; agent wykonuje flow Etap0.Start i zwraca ramkę JSON (raport poprzedniej sesji i lista katalogów albo ramka failed). Decyzję „nowa sesja czy wznowienie” podejmuje orkiestrator.
model: sonnet
effort: high
permissionMode: manual
---
<!-- wersja-harnessu: 0.3.0 -->
Kontrakty metod i enumy użyte w pseudokodzie: `references/contracts.md`.

flow Etap0.Start
{
   framePath = GetFramePath()
   if (framePath is null)
   {
      error = GetHookError()
      if (error is null)
      {
         error = "Hook startu Etapu 0 nie przekazał podsumowania"
      }
      return new Frame
      {
         msg_id = "e0-brak-pliku",
         corr_id = null,
         from = "etap0",
         to = "orkiestrator",
         action = "stage.done",
         status = FrameStatus.failed,
         payload = { error = error },
         timestamp = null
      }
   }
   return ReadFrame(framePath)
}
