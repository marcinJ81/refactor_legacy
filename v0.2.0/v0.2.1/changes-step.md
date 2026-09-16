##INfo dla cluade
To jest plik gdzie komunikujemy zmiany, ja podaje swoje ty dopisujesz wątpliwości i rezultaty zmian,
Swoją sekcje oznaczacz Claude
Piszemy zwięźle i bez skrótów, adresujemy dokąłdnie zmiany i pytania czyli np jaki plik nazwa i nazwa sekcji która linia,
Nie uruchamiamy żadnych dodatkowych narzędzi, to jest etap tworzenia harnessa, testy będę przeprowadzał gdzie indziej
Zmiany są dla refactor-legacy-v0.2.0
##

 
Kolejne zmiany:

sprawdzenie ale tylko w pliku czy nie ma jakiś nie spójności w tekście orkiestratora albo w step1
1 - sprawdz teraz czy orkiestrator wywołuje poprawnie step 1 z etapu 1
2 - sprawdz czy step1 analiza ma zapisane poprawne generowanie plików, czy oczym nie zapomnieliśmy,
3 - sprawdz czy qualuy gate dla step 1 będzie porpawnie wywołany,
4 - sprawdz czy orkiestrator odpowie właściwie dla quality gate który skończył się porażką,
5 - sprawdz czy quality gate we właściwy sposób zareaguje na ponowne uruchomienie

**Claude — wynik sprawdzenia (2026-09-16):**

Sprawdzone: `orkiestrator.md`, `etap1/step1.md`, `etap1/step2.md`,
`etap1/etap1.md`, `scripts/step1/*.ps1`, `refactor-config.example.json`.
Nic nie zmieniałem — poniżej same rozjazdy.

**1 — orkiestrator wywołuje Step 1**

- **Nie ma koperty `step.start` → `etap1.step1`.** Sekcja „Przekazanie między
  krokami Etapu 1" pokazuje trzy wiadomości (step1→ork, ork→step2, step2→ork);
  brakuje tej, którą Step 1 w ogóle jest uruchamiany. `step1.md` oczekuje
  `payload.iteracja`, orkiestrator pisze tylko „z `payload.config` i numerem
  iteracji" — nazwa pola nie pada nigdzie po stronie orkiestratora.
- **Katalog akcji** opisuje `step.start` jako „`payload` = payload z `step.done`
  poprzedniego kroku + `config`". Dla Step 1 poprzedniego kroku nie ma —
  wariantu brak.
- **Punkt 4a vs 4b'.** 4a: „dla kolejnych — `biezaca + 1` z ostatniej
  wiadomości" (reguła bezwarunkowa). 4b' przy ponowieniu każe wrócić do 4a
  z **tym samym** numerem. Sprzeczne, dopóki 4a nie zaznaczy wyjątku.
- **Katalog wynikowy.** Jest w konfiguracji (`harness.katalog_wynikowy`), ale
  `step1.md` w „Wyjście" odsyła tylko do sekcji orkiestratora, nie do pola
  configu. Krok pisze pliki, więc powinien mieć wskazane pole wprost.
- **`etap1/etap1.md` jest nieaktualny** — opisuje Fazę Analizy kończącą się
  `user.approval` i każe czytać `refactor-decisions.md`, plik skasowany
  w v0.2.0. Nie ma go w tabeli struktury harnessu, ale leży w katalogu obok
  step1/step2 (backlog A7).

**2 — pliki generowane przez Step 1**

- **Opcja B nie ma nazwy pliku zbiorczego.** `step1.md`: „ścieżkę pliku
  zbiorczego orkiestrator podaje skryptom parametrem `-PlikAnalizy`". Ani
  Pytanie 1, ani `refactor-config.json` nie ustalają, jak ten plik się nazywa —
  orkiestrator nie ma skąd wziąć tej ścieżki.
- **`pliki[]` ma 2 pozycje, „Wyjście" mówi o czterech plikach.** Nie jest to
  błąd (brama sprawdza komplet skryptem `01-pliki.ps1`), ale nigdzie nie jest
  powiedziane, że `pliki[]` to wsad dla Step 2, a nie lista wyjścia kroku.
- **Opcja B a licznik.** `04-licznik.ps1` szuka `Liczba zmian: K` wewnątrz
  wyciętego bloku iteracji; `step1.md` nie mówi, że przy pliku zbiorczym linia
  ma stać w bloku iteracji, a nie na końcu całego pliku.
- **Brak instrukcji dla powtórnego uruchomienia** — czy Step 1 nadpisuje swoje
  pliki, czy dopisuje. To domena B5, ale krok nie ma żadnej reguły.

**3 — wywołanie quality gate**

- **Wywołanie w orkiestratorze nie ma `-PlikAnalizy`.** Przy Opcji B brama
  poleci na `step1-analiza-N.md`, którego nie ma: `01-pliki` → „brak",
  `02-sekcje` → exit 2. Twardy rozjazd z `step1.md`.
- **Kod wyjścia 2 nie jest obsłużony.** Gdy `00-brama.ps1` kończy się 2 (brak
  katalogu wynikowego), **`podsumowanie.json` w ogóle nie powstaje** — a
  ścieżka błędu zna tylko `passed` i `failed`. Brama wejściowa Step 2 wtedy
  zablokuje się bez zdefiniowanej reakcji.
- **Ścieżka do skryptów.** `.\scripts\step1\00-brama.ps1` — nie jest
  powiedziane, że jest względna do katalogu harnessu ani skąd orkiestrator zna
  ten katalog (`refactor-config.json` trzyma tylko katalog wynikowy).
- **Tryb `test`.** Tabela odstępstw mówi, że bramy kroków działają normalnie,
  czyli skrypty PS odpalają się też w przebiegu testowym. „Mock to paczka"
  wymienia „plik wynikowy etapu, log etapu" — bez `step1-zmiany-N.json`
  i `step1-step-done-N.json`. Paczka mocka Step 1 musi mieć komplet czterech
  plików, inaczej brama zawsze `failed`. Nie dopisane.
- **Wymóg logu orkiestratora** nadal brzmi „wynik quality gate każdego kroku
  z rozbiciem na build i testy i kto je wykonał" — dla Step 1 bramą są cztery
  skrypty, build/testów nie ma. Nie ma też wymogu odnotowania numeru próby,
  choć 4b tego żąda.

**4 — reakcja orkiestratora na `failed`**

- **`refactor-session.md` nie ma pól na wynik bramy i numer próby**, a 4b każe
  je tam zapisać. Szablon ma tylko tryb, katalog, Etap 0, raport, sesje,
  kontekst, kontynuację, etap/krok w toku, iterację i ostatnią zamkniętą
  jednostkę.
- **Przerwanie po drugim `failed` nie ma akcji w protokole.** `error.critical`
  i `stage.aborted` to akcje **etap → orkiestrator**. Nie ma wiadomości, którą
  orkiestrator sam przerywa przebieg i notyfikuje użytkownika, ani zapisu, co
  wtedy ląduje w `refactor-session.md` i czy taki przebieg da się wznowić.
- **Warunki 1–4 bramy wyjściowej kroku nie mają ścieżki błędu.** Procedura
  (jedno ponowienie → przerwanie) opisana jest wyłącznie dla warunku 5.
  Gdy padnie np. brak `liczba_zmian` w `step.done`, zostaje ogólne „nie zamyka
  kroku", bez ponowienia i bez limitu.
- **Przykład logu pętli kroków (wpisy 13–19) jest sprzed zmiany:** „quality
  gate nie_wykonany (w budowie), zatwierdzone przez użytkownika", brak wpisu
  o uruchomieniu bramy i numerze próby, „Pliki ze zmianami: step1-analiza-2.md"
  zamiast `step1-zmiany-2.json`.
- **„Status dokumentu" i „Odłożone do kolejnych iteracji"** nadal deklarują
  ścieżkę nieudanego quality gate kroku jako *w budowie* — dla Step 1 już nie
  jest.
- **`payload.quality_gate_step1`** wymieniony w 4c i w „Bramy kroków", ale nie
  ma go w przykładzie `orc-022` (ork→Step 2) ani w opisie wejścia w `step2.md`.
- **`wejscie_wykonane`**: orkiestrator w przykładzie `step.done` ze Step 2 ma
  `step1-analiza-2.md`, `step2.md` — `step1-zmiany-2.json`.

**5 — brama a ponowienie**

- **Próba 2 nadpisuje wyniki próby 1.** Oba przebiegi piszą do tego samego
  `quality-gate-step1-analize-result/iteracja-N/`, a `proba` jest wyłącznie
  w `podsumowanie.json`, które też zostaje nadpisane. Po przerwaniu procesu
  w katalogu nie ma śladu, że próba 1 w ogóle była — a orkiestrator ma z tego
  katalogu poznawać stan bram.
- **Pliki `01`–`04` nie mają pola `proba`** — nie da się ich przypisać do próby.
- **Brama jest bezstanowa.** `-Proba` to tylko etykieta: nic nie sprawdza, czy
  próba 2 następuje po nieudanej próbie 1, ani czy pliki Step 1 są świeże
  (żaden skrypt nie patrzy na czas modyfikacji). Jeśli ponowiony Step 1
  przerwie się przed nadpisaniem plików, brama oceni artefakty z próby 1 —
  i może zwrócić `passed`.
- **`01-pliki.ps1` sprawdza `### Iteracja N` w logu wspólnym dla iteracji.**
  Po próbie 1 ten nagłówek już istnieje, więc warunek przechodzi niezależnie
  od tego, czy ponowiony krok cokolwiek dopisał.
- To jest sedno B5: przy opcji „czyszczenie przed ponowieniem" trzeba
  rozstrzygnąć, czy skrypt czyści też `quality-gate-step1-analize-result/
  iteracja-N/`; przy opcji „nowe pliki obok starych" brama dziś nie ma jak
  odróżnić jednych od drugich.

**Najpilniejsze (blokują happy path, nie czekają na B5):** 3 — brak
`-PlikAnalizy` w wywołaniu i brak obsługi kodu 2; 1 — brak koperty
`step.start` do Step 1 i nazwy pola `iteracja`; 2 — brak nazwy pliku zbiorczego
dla Opcji B; 4 — brak pól próby w `refactor-session.md` i brak akcji
przerwania w protokole.

##User - zadania

Zaczniemy od tyłu:
5 - brama a ponowienie
Trzeba jednak zrobić czyszczenie wcześniejszego wyniku bramy, orkiestrator dostaje wyniki negatywny z bramy:
- uruchamia skrypt umieszczony w katalogu scripts/step1/eraser
- ten skrypt ma zadanie wyczyścić wyniki quality gate wszystkie pliki,
- wrzuć do backloga taki wpis - usuwanie plików z quality gate - po każdej iteracji - do rozważenia
To powinno załatwić sprawę problemów z przy kolejnym wywołaniu bramy przy negatywnym rezultacie,

4 - reakcja orkiestratora na `failed`
Musimy wprowadzić do orkiestraotra taki zapis który obłsuży systuacje jeżeli jest faild z bramy za piewrszym razem ponawiamy ale wywołujemy eraser skrypt, drugi raz powiadomienia do usera, ale orkiestrator w logach musi zapisać że już raz wywołał dla danego kroku, bo chodzi o ten sam krok a nie że jakikolwiek faild.

jest tak dużo zmian że na razie tylko te dwa punkty i pilne, a potem reszta

**Claude — wprowadzone (2026-09-16):**

**Nowy plik: `scripts/step1/eraser/00-eraser.ps1`**
Parametry: `-KatalogWynikowy` (wymagany), `-Iteracja` (wymagany), `-Powod`
(opcjonalny, trafia do komunikatu). Usuwa komplet plików bramy tej iteracji
(`01`–`04`, `podsumowanie.json`) razem z katalogiem
`quality-gate-step1-analize-result/iteracja-N/`. Wypisuje listę usuniętych
plików (do logu orkiestratora). Kody wyjścia: `0` = wyczyszczone albo nie było
czego czyścić, `1` = coś zostało, `2` = brak katalogu wynikowego.
Korzysta z `../_wspolne.ps1` (`Get-Znacznik`, `Get-KatalogWynikuBramy`).
**Plików Step 1 nie rusza** (`step1-analiza-N.md`, `step1-zmiany-N.json`,
`step1-step-done-N.json`, log kroku) — nadpisuje je ponowiony krok.

**`orkiestrator.md`**
- „Struktura harnessu (pliki)" — dodany wiersz z erasrem.
- „Bramy kroków (Etap 1)" → „Ścieżka błędu" przepisana: tytuł „jedno
  ponowienie na parę (krok, iteracja)"; przy `failed` orkiestrator najpierw
  czyta z `refactor-session.md`, czy ponowienie tej pary jest zużyte; jeśli
  nie — eraser, zapis zużycia, `step.start` z tym samym numerem iteracji,
  brama z `-Proba 2`; jeśli tak — przerwanie i notyfikacja. Dopisane:
  wywołanie erasera, jego kody wyjścia, oraz że kod `1`/`2` = brak ponowienia
  (przerwanie), bo nie wiadomo, czyje pliki oceniałaby brama. Usunięty akapit
  „mechanika otwarta, patrz backlog B5".
- „Plik stanu sesji" — dwa nowe pola w szablonie: `Quality gate Step 1:
  <passed|failed> (iteracja N, próba K)` oraz `Ponowienia kroku: <krok> /
  iteracja N — zużyte (1 z 1) | dostępne (0 z 1)`, z opisem pod szablonem.
  Wiersz ponowienia zostaje po `passed` — jest dowodem zużycia limitu.
  (Sam szablon leży teraz w `orchestrator-examples/stan-sesji-harnessu.md` —
  patrz `changes-orchestrator.md`.)
- Pętla sterowania: 4a ma teraz jawny wyjątek „wejście z 4b' idzie z tym samym
  numerem iteracji"; 4b' przepisane na eraser + licznik per para.
- Log orkiestratora: wymóg zapisu numeru próby, listy niezaliczonych
  sprawdzeń, każdego uruchomienia erasera z kodem wyjścia i jawnego wpisu, dla
  której pary (krok, iteracja) ponowienie zostało zużyte. Przykład pętli
  kroków rozszerzony o wpisy 16a–16d (failed → eraser → ponowienie → passed);
  przy okazji poprawione dwa nieaktualne fragmenty w tym przykładzie
  (`step1-analiza-2.md` → `step1-zmiany-2.json`, „zatwierdzone przez
  użytkownika").
- „Status dokumentu" i „Odłożone do kolejnych iteracji" — ścieżka nieudanej
  bramy **Step 1** nie jest już *w budowie*; oznaczenie zostaje dla Step 2.

**`etap1/step1.md`** — „Wynik negatywny — jedno ponowienie": dopisane wywołanie
erasera, zużycie ponowienia per para (krok, iteracja) i to, że ponowiony krok
nadpisuje własne pliki. Usunięte odesłanie do `backlog.md` / B5.

**`backlog.md`** — B5 przestawione na ✅ z opisem rozstrzygnięcia; nowa pozycja
**B6**: „usuwanie plików quality gate po każdej iteracji — do rozważenia" (❓).

**Wątpliwości:**

1. **Eraser nie czyści plików Step 1, więc dziura ze starymi artefaktami
   zostaje.** Jeśli ponowiony Step 1 przerwie się, zanim nadpisze
   `step1-analiza-N.md` / `step1-zmiany-N.json`, brama próby 2 oceni pliki
   z próby 1 — i może zwrócić `passed`. Tak samo `01-pliki.ps1` sprawdza
   nagłówek `### Iteracja N` w logu kroku, który po próbie 1 już tam jest.
   Zakres erasera wziąłem dosłownie z polecenia („wyczyścić wyniki quality
   gate"). Czy ma też kasować pliki Step 1 tej iteracji (albo dostać do tego
   osobny przełącznik)?
2. **Numer próby nie ma źródła prawdy poza `refactor-session.md`** — eraser
   kasuje `podsumowanie.json`, więc po restarcie orkiestratora jedynym śladem
   zużytego ponowienia jest plik stanu sesji i log. Przyjąłem plik stanu sesji
   jako źródło prawdy; jeśli ma nim być log, trzeba to odwrócić.
3. **Nazwa skryptu** — `00-eraser.ps1`, żeby trzymać konwencję „`00-` =
   punkt wejścia" z `00-brama.ps1`. Jeśli wolisz `eraser.ps1`, zmienię.
