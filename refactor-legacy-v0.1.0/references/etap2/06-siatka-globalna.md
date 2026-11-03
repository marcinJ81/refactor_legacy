# Siatka globalna — wybór i łączenie technik
<!-- wersja-harnessu: 0.1.1 -->

Identyfikatory: F = Fowler, W = Feathers, K = Kerievsky, B = Beck, P = czysty kod (Martin).

---

## 1. Poziomy ryzyka — kolejność pracy

Zasada: zaczynaj od najniższego poziomu; wyższy poziom zwykle wymaga wykonania niższych.

| Poziom | Zakres zmiany | Techniki | Blast radius (zasięg skutków) |
|---|---|---|---|
| 0 — kosmetyka | zapis, kolejność, nazwy lokalne | B01, B02, B04, B05, P01 (zmienne lokalne), P03, P11, P12 | wnętrze pliku |
| 1 — wnętrze metody | wyrażenia, warunki, pętle | F03, F07, F08, F09, F10, F16, F17, F18, W01 | jedna metoda |
| 2 — granice metod | podział i sygnatury metod | F01, F02, F04, F11, F12, F21, F22, W02, W03, W04, W06, K01, B03, B06 | klasa + wywołujący |
| 3 — granice klas | nowe klasy, przenoszenie zachowania | F05, F06, F13, F14, F15, W05, W07, K02 | moduł, mapowania EF, DI |
| 4 — struktury polimorficzne / wzorce | hierarchie, strategie, stany | F19, F20, K03, K04, K05, K06, K07, W08 (etap scalania) | moduł + konfiguracja + konstrukcja obiektów |

---

## 2. Zapach → sekwencja kroków

Nazwy zapachów wg Fowlera (*Refactoring*, 2nd ed., rozdz. 3) i Kerievsky'ego.

| Zapach (code smell) | Sekwencja kroków | Uwagi |
|---|---|---|
| Mysterious Name (Tajemnicza nazwa) | P01 → F04 → P02 | rename w kodzie wołanym z Razor/JS — sprawdź ręcznie |
| Duplicated Code (Zduplikowany kod) | B02 → W08 → F08 → F01 → (K05 lub funkcja wyższego rzędu) | duplikacja przypadkowa zostaje (P14) |
| Long Function (Długa funkcja) | B01 → W01 → W02 → F03/F07 → W03 lub W04 → K01 | wiele zmiennych lokalnych → F12 przed dalszymi F01 |
| Long Function — dwie fazy | F11 → F01 dla każdej fazy | |
| Long Parameter List (Długa lista parametrów) | B06 → F05 → F22 | parametr wyliczalny z innego → usuń (Fowler: Replace Parameter with Query) |
| Divergent Change (Rozbieżna zmiana — klasa zmieniana z różnych powodów) | W07 → B05 → F11 → F13 → F14 | |
| Shotgun Surgery (Chirurgia śrutowa — jedna zmiana w wielu miejscach) | F14 → F13 (zebranie w jedną klasę) → B05 | gdy przyczyną jest `switch` → K03/F19 |
| Feature Envy (Zazdrość o cechy) | F01 (zazdrosny fragment) → F14 | |
| Data Clumps (Zlepki danych) | F05 → F13 → F14 | |
| Primitive Obsession (Obsesja typów prostych) | F06 → F14 | kod typu jako string/enum → F19/K03 |
| Repeated Switches (Powtarzane switche) | F16 → F01 → B05 → F13 → F19 / K03 / K04 / K06 | wybór — sekcja 3.1 |
| Loops (Pętle) | F09 → F10 | |
| Lazy Element (Leniwy element) | F02 / Inline Class | |
| Speculative Generality (Spekulatywna ogólność) | B01 → F02 → Inline Class | |
| Temporary Field (Pole tymczasowe) | F13 → F20 | |
| Message Chains (Łańcuchy wywołań) | P13 (Hide Delegate) lub F01 → F14 | |
| Middle Man (Pośrednik) | F02 (Remove Middle Man) | pośrednik tymczasowy przy migracji jest celowy |
| Large Class (Duża klasa) | W07 → B05 → W05 → F13 → F14 | |
| Data Class (Klasa danych) | F15 → F14 (zachowanie do danych) | DTO/ViewModel — zostaw |
| Comments (Komentarze „co”) | F03 → F01 → F16 → P11 | |
| Mutable Data / query z efektem ubocznym | F21 | |
| Duplikacja w konstruktorach (Kerievsky) | K02 | |
| Ozdobniki włączane flagami (Kerievsky) | F01 → K07 | |
| Warunki zmieniające stan (Kerievsky) | B02 → F16 → F18 → K04 | |

---

## 3. Wybór między technikami konkurencyjnymi

### 3.1. Logika warunkowa po typie/stanie/kluczu

| Sytuacja | Wybór |
|---|---|
| Jeden `switch`, w jednym miejscu, stabilny | zostaw (KISS) lub F16 |
| `switch` po typie powtarza się w wielu metodach, typ stały przez życie obiektu, obiekt może być hierarchią | F19 |
| Jak wyżej, ale obiekt to encja EF / DTO, typ pochodzi z danych | K03 (strategia wybierana po enum) |
| Zachowanie zależy od stanu, który zmienia się w czasie | K04 (lub nazwane predykaty F16 przy prostych regułach) |
| Te same kroki algorytmu, różne szczegóły | K05 |
| Różne akcje wybierane kluczem (string/enum) | K06 |
| Wiele sprawdzeń `null` / przypadku szczególnego | F20 |

### 3.2. Pozostałe pary

| Sytuacja | Wybór |
|---|---|
| Decyzja ważniejsza niż kolejność / kolejność ważniejsza niż decyzja | W03 / W04 |
| Ekstrakcja daje ≤ 3 parametry / więcej lub `ref`/`out` | F01 / F12 |
| Grupa parametrów / pojedyncza wartość z regułami / grupa pól i metod | F05 / F06 / F13 |
| Zmiana sygnatury tej samej metody / nowy wygodny punkt wejścia obok starego | F04 / B03 |
| Dziedziczenie szkieletu / kompozycja wariantów | K05 / K03 |
| Pośrednik ukrywa strukturę / pośrednik tylko przekazuje | Hide Delegate / F02 (Remove Middle Man) |

---

## 4. Macierz zależności

### 4.1. Pary odwrotne (cofnięcie kroku)

| Technika | Odwrotność |
|---|---|
| F01 Extract Function | F02 Inline Function |
| F03 Extract Variable | Inline Variable |
| F13 Extract Class | Inline Class |
| F14 Move Function | F14 w drugą stronę |
| Hide Delegate (P13) | Remove Middle Man (F02) |
| K03/K04/K05/K06/K07 | odejście od wzorca: Inline Class + F16 (Kerievsky opisuje refaktoryzacje „away from” wzorca) |

### 4.2. Warunki wstępne (co zwykle musi być wcześniej)

| Technika | Wymaga wcześniej |
|---|---|
| F01 na długiej metodzie | F07 lub F08 (gdy zmienne/instrukcje blokują) |
| F10 | F09 |
| F13 | B05 lub W07 (dowód granic) |
| F14 dla grupy parametrów | F05 |
| F19, K03, K06 | F16 + F01 — każda gałąź jako osobna metoda |
| K04 | F16 (predykaty `CanX`) + B02 (jeden styl strażników) |
| K05 | W08 + F04 (te same nazwy kroków w klasach) |
| K07 | F01 (ozdobnik jako osobna metoda) |
| W06 | wcześniejsza seria F01 |

### 4.3. Typowe łańcuchy (powtarzalne sekwencje)

| Łańcuch | Cel |
|---|---|
| B01 → W01 → W02 → W03/W04 → K01 | oswojenie metody-potwora |
| F08 → F01 → F14 | przeniesienie fragmentu do właściwej klasy |
| F09 → F10 → F01 | pętla wielozadaniowa → nazwane zapytania |
| F16 → F17 → F18 | czytelna logika warunkowa |
| F16 → F01 → B05 → F13 → K03 | `switch` → strategie |
| W07 → B05 → W05 → F13 → F14 → K02 | podział dużej klasy z zachowaniem starego konstruktora |
| F04 (`[Obsolete]`) → przepięcie → F02/B01 | bezpieczna zmiana API z wieloma wywołującymi |
| F02 → F08 → F01 | ponowne cięcie (W06) |

---

## 5. Kiedy przestać

- Kolejny krok nie ułatwia bieżącej zmiany (Beck: najpierw uczyń zmianę łatwą, potem wykonaj łatwą zmianę; Feathers: skup się na bieżącej pracy).
- Następny poziom ryzyka (sekcja 1) wychodzi poza zakres, który możesz zweryfikować testami.
- Zmiana wymagałaby modyfikacji publicznego kontraktu (WCF, Web API, model binding, kolumny bazy) — to osobna decyzja, nie refaktoryzacja.
- Działający, brzydki kod jest lepszy niż ryzykowny refaktor — niewykonane kroki zapisz w backlogu.
