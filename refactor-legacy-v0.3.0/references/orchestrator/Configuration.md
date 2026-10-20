---
name: creatorConfiguration
description: tego nie uruchamia agent, jest to ładowane przez orkiestratrator, po uruchomieniu etapu 0 i stwierdzeniu że to nowa sesja, ten etap polega na stworzeniu pliku konfiguracyjnego i jego sprawdzeniu, Plik będzie tworzony poprzez skrypt powershelowy, będzie to json z polami do uzupełnienia przez użytkownika. Na czas uzupełnienia orkiestrator czeka, uzupłenienie następuje po za LLM-em. Po zwróceniu inforamcji do LLM-a że konfigracja jest zakończona następuje sprawdzenie poprawności.
---

## Warunki uruchomienia
- orkiestrator uruchamia po tym jak  etap 0 zwróci że trzeba zacząć nową sesje
- koperta wiadomości z komendą generuj plik
