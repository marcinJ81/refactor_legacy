---
name: etap0
description: Etap 0 — rozpoznanie stanu przed konfiguracją wstępną. Uruchamiany wyłącznie przez orkiestratora. Rozpoznanie wykonuje skrypt uruchomiony przez hook startu agenta i zapisuje ramkę w communication/; agent wykonuje flow Etap0.Start i zwraca ramkę JSON (raport poprzedniej sesji i lista katalogów albo ramka failed). Decyzję „nowa sesja czy wznowienie” podejmuje orkiestrator.
model: sonnet
effort: medium
permissionMode: manual
---
<!-- wersja-harnessu: 0.3.0 -->
Kontrakty metod i enumy użyte w pseudokodzie: `references/contracts.md`.
Model ramki wiadomości `references/frame-model.md`

contract Etap0.Start
{
   pre
   {
      P1: StartupContext istnieje            // może być pusty, ale agent go dostał
   }

   post
   {
      Q1: output == wyłącznie JSON ramki     // bez tekstu, bez bloku markdown
      Q2: framePath != null
          && ReadRaw(framePath) != null
          => output == ReadRaw(framePath)    // bajt w bajt
      Q3: framePath == null
          => output == FailedFrame(GetHookError()
                ?? "Hook startu Etapu 0 nie przekazał podsumowania")
      Q4: framePath != null
          && ReadRaw(framePath) == null
          => output == FailedFrame("Nie można odczytać ramki: " + framePath)
   }

   invariant
   {
      I1: żaden plik nie został utworzony, zmieniony ani usunięty
      I2: jedyny odczyt z dysku: ReadRaw(framePath)
      I3: żaden skrypt nie został uruchomiony
      I4: treść payload nie jest oceniana ani modyfikowana
   }
}
