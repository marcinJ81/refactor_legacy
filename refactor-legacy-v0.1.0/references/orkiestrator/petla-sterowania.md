# Orkiestrator — Pętla sterowania
<!-- wersja-harnessu: 0.1.1 -->

Sekcja wyniesiona z `orkiestrator.md` („Pętla sterowania orkiestratora”).

1. **Rozpoznanie stanu.** Wczytaj `refactor-session.md`. Gdy `Stan raportu` ma
   wartość `do wczytania`, nie zlecaj Etapu 0. W przeciwnym razie zleć Etap 0 agentowi, odbierz raport JSON, zapisz `etap0-raport.json`
   i `refactor-session.md`, odnotuj to w logu i dopiero **potem** wyczyść
   kontekst (`/clear`). Po odzyskaniu sterowania zinterpretuj raport i ustal z użytkownikiem: nowa
   sesja czy wznowienie (patrz "Etap 0 i wznowienie sesji" w `orkiestrator.md`). Ustal katalog
   wynikowy przebiegu (patrz `references/orkiestrator/katalog-wynikowy.md`).
2. Przeprowadź konfigurację wstępną (Pytanie 0), zapisz
   `refactor-decisions.md` (razem z formatem znacznika czasu), przy
   wznowieniu: pokaż istniejącą konfigurację do
   potwierdzenia zamiast pytać od nowa.
3. Kolejka etapów jest stała: Etap 1, potem Etap 2. Etap 3 nie wchodzi do
   kolejki, dopóki `etap3.md` jest pusty; odnotuj to w logu. Przy wznowieniu
   kolejka zaczyna się od etapu z pola `wznowienie.etap` raportu Etapu 0.
4. Dla kolejnego etapu z kolejki: sprawdź **bramę wejściową**. Gdy przechodzi —
   wczytaj plik etapu (`etap1.md` / `etap2.md`) i wyślij
   `stage.start` z `payload.config`. Przy wznowieniu dołącz
   `payload.stan_iteracji` z pola `wznowienie.stan_iteracji` raportu Etapu 0,
   jeśli nie jest `null` (patrz "Stan iteracji"
   w `references/orkiestrator/protokol-komunikacji.md`). Gdy brama nie
   przechodzi — zgłoś użytkownikowi niespełniony warunek i czekaj.
5. **Czuwaj.** W trakcie działania etapu przyjmuj przychodzące wiadomości:
   - `user.approval` / `user.input` → przekaż `user_message` użytkownikowi,
     poczekaj na odpowiedź, odeślij ją do etapu w `stage.resume`
     (`corr_id` = `msg_id` requestu) razem z niezmienionym
     `payload.stan_iteracji`.
   - `stage.aborted` → odnotuj w logu, zatrzymaj kolejkę, oddaj sterowanie
     użytkownikowi.
   - `error.critical` → przerwij działanie harnessu z komunikatem.
6. Po `stage.done`: sprawdź **bramę wyjściową**. Przechodzi → wróć do punktu 4 dla następnego
   etapu. Braki → `stage.resume` z listą braków lub zgłoszenie użytkownikowi.
7. Po wyczerpaniu kolejki: podsumuj przebieg i zakończ.
