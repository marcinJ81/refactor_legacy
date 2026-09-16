# Etap 3 — Refaktoryzacja rezultatu Etapu 2

*(pusty — do zdefiniowania)*

Uruchamiany warunkowo przez orkiestratora: tylko wtedy, gdy w Etapie 2 wybrano
wariant zawierający zmianę logiki ("Zmiana logiki" lub "Oba"), przez co
refaktoryzacja została tam odroczona. Etap 3 przejmuje wtedy refaktoryzację
kodu w stanie **po** zmianie logiki z Etapu 2, wykorzystując zaktualizowaną
siatkę testów jako podstawę bezpieczeństwa zmian.

Jeśli w Etapie 2 wybrano wyłącznie wariant "Refaktor", ten warunek nie
zachodzi — zasady uruchomienia Etapu 3 w takim przypadku do zdefiniowania
osobno, później.

Kroki, log, format wyjścia i obsługa protokołu komunikacji — do zdefiniowania
w kolejnej iteracji.

**Dopóki ten plik jest pusty:** w trybie `normalny` próba uruchomienia Etapu 3
kończy się `error.critical` (warunek 5 bramy wejściowej). W trybie `test` ten
warunek przechodzi dla Etapu 3 zawsze, żeby przebieg testowy mógł dojść do
końca kolejki — patrz "Tryb testowy" w `orkiestrator.md`.
