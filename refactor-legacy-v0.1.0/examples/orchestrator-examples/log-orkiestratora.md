# Przykład — Log orkiestratora — `orkiestrator-log.md`
<!-- wersja-harnessu: 0.1.1 -->

Sekcja orkiestratora: „Pętla sterowania orkiestratora” → „Log orkiestratora”.

```markdown
# Log orkiestratora

## Uruchomienie 2026-08-30; 18-51-00

2026-08-30; 18-51-02 — 1. Wczytano refactor-session.md; ostatni wpis starszy niż 4 h → nowa sesja.
2026-08-30; 18-51-05 — 2. Zlecono Etap 0 agentowi.
2026-08-30; 18-52-28 — 3. Odebrano raport Etapu 0: 2 poprzednie sesje (refactor-result1, refactor-result2), Etap 2 in_progress, 1 request otwarty.
2026-08-30; 18-52-30 — 4. Zapisano etap0-raport.json i refactor-session.md.
2026-08-30; 18-52-41 — 5. Wyczyszczono kontekst (automatycznie).
2026-08-30; 18-53-10 — 6. Po odzyskaniu sterowania: różnica 29 s < 4 h → środowisko przygotowane, Etap 0 pominięty.
2026-08-30; 18-54-00 — 7. Użytkownik wybrał wznowienie Etapu 2 od kroku 2 → kontynuacja w refactor-result2, bez nowego katalogu.
```
