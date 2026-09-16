# changes.md — v0.2.1

Wersja główna: **v0.2.0** (harness w `refactor-legacy-v0.2.0/`).
Wersja konkretna: **v0.2.1** — zmiany z tego pliku trafiają do `refactor-legacy-v0.2.0/`.

Zasada ta sama co w poprzednich plikach `changes*.md`: wpisy użytkownika zostają
nietknięte, adnotacja o wprowadzeniu trafia pod wpis.

Poprzednie pliki: `v0.1.0/v0.1.0/changes.md`, `v0.1.0/v0.1.0/changes_test.md`,
`v0.2.0/v0.2.0/changes2.md`. Otwarte pozycje: `backlog.md` w katalogu głównym.

Zakres na start: zmiany w agencie Etapu 1 (`refactor-legacy-v0.2.0/etap1/`).

---
Zmiany dla step1 struktura pliku nie będzie miała punktu do akceptacji,
rezultat kroku 1 będzie wysyłany do orkiesttratora który wywoła quality gate dla tego etapu,
Ta brama to będzie skrypt który potwierdzi że w pliku z analizy czyli step1-analiza-N.md gdzie N to kolejny etap iteracji (etapy iteracji będą zapisane w logu) znajdują się kolejne punkty które są w strukturze pliku odpowiedzi wymienione.
Brama oprócz tego sprawdza czy jest plik loga z tego etapu, oraz plik json który zostanie wysłany do kroku drugiego.
struktura json jest w pliku step1.md
Więc ta brama będzie sprawdzać
- istnienie plików w odpowiednim katalogu dla kroku pierwszego,
- czy w pliku wynikkowym analizy są odpowiednie sekcje - punkty,
- czy istnieje plik json z wygenerowanymi zmiana dla kroku drugieg,
- czy struktura jsona jest poprawna

orkiestrator będzie wywoływał skrypty zgromadzone w katalogu scripts/step1
etap1 będzie informował o zakończeniu poprzez requesta w formacie json zapisanego tam gdzie bedą inne pliki związane z etapem pierwszym.
TO orkiestrator na podstawie tych skryptów stwierdzi czy etap analizy jest poprawny.

Co do agenta z kroku pierwszego będzie jeszcze jedna informacja która będzie weryfikowana, jednym z plików które zostaną wygenerowane będdzie json z opisem zmian trafiający do etap1 - implementacja,
ten json będzie się składał z conajmniej jednej struktury, agen będzie musiał je zliczyć i wprowadzić na koniec pliku, liczba ta będzie też wpisana w plik opisowy który też będzie wynikiem etapu 1, powstał już wcześniej,
teraz będzie musiał być uzupełniony o tę inforamcje

a sam orkiesttratora będzie uruchamiał jeszcze jeden skrypt który to zliczy,

każdy z tych skryptów będzie zapisywał wyniki sprawdzenia w katalogu quality-gate-step1-analize-result.
jak to będzie zrobione pójdziemy dalej

**Claude — pytania przed implementacją (2026-09-16):**

1. **JSON ze zmianami vs. request `step.done`.** W `step1.md` jest dziś tylko
   koperta `step.done` (`kolejnosc_implementacji` = lista stringów). Czy to
   ma być: (a) osobny plik `step1-zmiany-N.json` z tablicą struktur zmian +
   licznik na końcu, a `step.done` osobno jako request kończący, czy (b) jeden
   plik — `kolejnosc_implementacji` staje się tablicą struktur, licznik wchodzi
   do tego samego payloadu?
2. **Struktura pojedynczej zmiany.** Nie ma jej nigdzie zdefiniowanej. Mam ją
   zaproponować (np. `id`, `plik`, `typ_seamu`, `opis`, `kolejnosc`) i dopisać
   do `step1.md`?
3. **Język skryptów** w `scripts/step1/`: bash + jq czy python3?
4. **Katalog `quality-gate-step1-analize-result`** — w katalogu wynikowym
   przebiegu (`refactor-resultN/`)? Osobny podkatalog per iteracja czy pliki
   z numerem iteracji w nazwie?
5. **Sekcja 7 „Do akceptacji"** w strukturze `step1-analiza-N.md` — usuwam
   całkowicie (brama zastępuje akceptację), czy zostaje jako informacja dla
   użytkownika bez blokowania kroku?
6. **Skutek negatywnego wyniku bramy** — orkiestrator ponawia Step 1 tej samej
   iteracji, pyta użytkownika, czy przerywa? W `changes.md` tego nie ma.

   odpowiedzi
1. to są dwa osobne pliki,
2. doprezycuj
3. wybierz co ma większe możliwości i nie potrzebuje żeby doinstalować jakieś dodatkowe biblioteki czy narzędzia, ten harenes będzie uruchamiany w windowsie
4. tak to będzie katalog pod każdą iteracje czyli też będzie numerowany, bo pętli analiza - impelemntacja może być więcej a orkiestrator musi wiedzieć które były wykonane a które jeszcze nie
5. ta sekcja będzię usunięta, bramy dla kroku 1 (step1) jak i drugiego będzie odpalać orkiestrator, dla kroku 1 będą to skrypty sprawdzające stkrukturę plików odpowiedzi
6. jest tylko jedno ponowienie trzeba bedzię zmienić orkiestrator żeby przyjoł taki wynik i ponownie wywołał analizę czyli step 1 z etapu 1,
    tu jest ściezka do rostrzygnięcie wrzuć to do backloga bo jeszczenie jestem pewny, :
    - opcja jeden ponowne odpalenie agenta do analizy nowy kontekst, nowe pliki ale co ze starymi?
    - opcja dwa orkiestrator dostaje negatywną odpowiedz uruchamia skrypt czyszczący wygenenrowane dane dla etapu 1 step1, potem uruchamia ponownie analize, odnowtowując że zapierwszym razem nie wyszło,
      kolejny błąd zwrócony z quality gate to przeywanie procesu i notyfiakcja do usera

**Claude — propozycja do zatwierdzenia (2026-09-16):**

Ad 3 — **PowerShell 5.1** (`.ps1`). Jest w każdym Windowsie, ma natywny
`ConvertFrom-Json` i `Test-Path`; bash wymagałby `jq`, python — instalacji.

Ad 2 — pliki Step 1 per iteracja N (w katalogu wynikowym przebiegu):

| Plik | Rola |
|---|---|
| `step1-analiza-N.md` | opis analizy, sekcje 1–6 (bez „Do akceptacji"), na końcu `Liczba zmian: K` |
| `step1-zmiany-N.json` | kontrakt dla Step 2 — tablica struktur + licznik |
| `step1-step-done-N.json` | request `step.done` do orkiestratora |
| `step1-log.md` | log kroku (bez zmian) |

`step1-zmiany-N.json`:

```json
{
  "etap": "etap1", "krok": "step1", "iteracja": 2,
  "zmiany": [
    {
      "id": "zm-1",
      "kolejnosc": 1,
      "plik": "src/Orders/OrderCalculator.cs",
      "zakres": "CalculateOrderTotal, linie 42-88",
      "typ": "seam",
      "technika": "Extract Interface + DI",
      "opis": "Wydzielić IClock dla DateTime.Now, wstrzyknąć przez konstruktor"
    }
  ],
  "liczba_zmian": 1
}
```

`typ`: `seam` albo `test`. `technika` obowiązkowa dla `seam` (katalog
Feathersa), pusta dla `test`. `liczba_zmian` — ostatnie pole pliku, ta sama
wartość co `Liczba zmian: K` w `.md`.

Ad 1+4+5 — skrypty w `scripts/step1/`, każdy osobno wywoływalny, exit 0/1,
wynik do `refactor-resultN/quality-gate-step1-analize-result/iteracja-N/`:

| Skrypt | Sprawdza |
|---|---|
| `01-pliki.ps1` | istnienie 4 plików wyżej w katalogu iteracji |
| `02-sekcje.ps1` | sekcje 1–6 w `step1-analiza-N.md` |
| `03-json.ps1` | `step1-zmiany-N.json` parsuje się i ma wymagane pola w każdej strukturze |
| `04-licznik.ps1` | `liczba_zmian` == liczba elementów `zmiany[]` == `Liczba zmian: K` w `.md` |

Każdy zapisuje `NN-<nazwa>.json` (`wynik`, `szczegoly[]`, `timestamp`),
orkiestrator dopisuje `podsumowanie.json` (`passed`/`failed` + która próba).

Ad 6 — ponowienie: 1. próba `failed` → orkiestrator odnotowuje i ponawia
Step 1 tej samej iteracji; 2. `failed` → przerwanie i notyfikacja użytkownika.
Wybór między opcją 1 (nowy kontekst, stare pliki?) a opcją 2 (skrypt czyszczący
przed ponowieniem) — wrzucone do `backlog.md` jako B5.

**Pliki do zmiany:** `etap1/step1.md` (wyjście, struktura JSON, usunięcie
sekcji 7 i „Do akceptacji", quality gate zamiast *w budowie*), `orkiestrator.md`
(brama kroku = skrypty, jedno ponowienie), `scripts/step1/*.ps1` (4 nowe),
`backlog.md` (B5).

Zatwierdzasz?

**Claude — wprowadzono (2026-09-16):**

Nowe pliki — `refactor-legacy-v0.2.0/scripts/step1/`:
`_wspolne.ps1` (funkcje wspólne), `01-pliki.ps1`, `02-sekcje.ps1`, `03-json.ps1`,
`04-licznik.ps1`, `00-brama.ps1` (uruchamia komplet + `podsumowanie.json`).
Każdy skrypt: `-KatalogWynikowy`, `-Iteracja`, opcjonalnie `-PlikAnalizy`
(Opcja B z Pytania 1); exit 0 = passed, 1 = failed, 2 = błąd wywołania;
wynik do `quality-gate-step1-analize-result/iteracja-N/`.

`etap1/step1.md`: sekcja „Wyjście" opisuje teraz cztery pliki iteracji
(`step1-analiza-N.md`, `step1-zmiany-N.json`, `step1-step-done-N.json`,
`step1-log.md`) i strukturę zmiany; sekcja 7 „Do akceptacji" usunięta;
`zatwierdzenie_uzytkownika` usunięte z `step.done`, doszło `liczba_zmian`,
`kolejnosc_implementacji` to teraz lista `id`; nowa sekcja „Quality gate
Step 1" (bez „w budowie") — bramę uruchamia orkiestrator, krok nie zna jej
wyniku; log bez wpisu o quality gate.

`orkiestrator.md`: brama wejściowa Step 2 wymaga `podsumowanie.json` ze
`status: passed` zamiast zgody użytkownika; brama wyjściowa kroku ma punkt 5
(quality gate Step 1) z wywołaniem skryptów i ścieżką błędu (próba 1 `failed` →
ponowienie tej samej iteracji, próba 2 `failed` → przerwanie + notyfikacja);
pętla sterowania rozszerzona o 4b'; `scripts/step1/*.ps1` w tabeli struktury
harnessu.

`etap1/step2.md`: wsadem wiążącym jest `step1-zmiany-N.json` (`.md` to opis,
przy rozjeździe rozstrzyga JSON) — zmiana wymuszona nowym kontraktem.

`backlog.md`: B1 zamknięte (✅), doszło B5 — mechanika ponowienia.

**Czego nie zrobiłem:** skrypty nie zostały uruchomione — na tej maszynie nie
ma PowerShella. Napisane pod PS 5.1 (tylko `ConvertFrom-Json`, `Test-Path`,
`Get-Content`), bez zewnętrznych zależności. Uruchomienia nie będzie: to środowisko
służy wyłącznie do tworzenia harnessu, skrypty testuje się gdzie indziej.



