##INfo dla cluade
To jest plik gdzie komunikujemy zmiany, ja podaje swoje ty dopisujesz wątpliwości i rezultaty zmian,
Swoją sekcje oznaczacz Claude
Piszemy zwięźle i bez skrótów, adresujemy dokąłdnie zmiany i pytania czyli np jaki plik nazwa i nazwa sekcji która linia,
Nie uruchamiamy żadnych dodatkowych narzędzi, to jest etap tworzenia harnessa, testy będę przeprowadzał gdzie indziej
Zmiany są dla refactor-legacy-v0.2.0
##

##User - zadania
Orkiestrator stął się za duży 1200 linii i będzie puchnoł czas na odchudzanie.
Kroki odchudzania:
- wprowadzamy katalg orchestrator-exemples w nim będą przechowywane przykłady paylodów, jsonów, jeżele ten plik będzie także za bardzo rosnoł to będziemy go dzielić na pliki z nazwami sekcji,
    w sammy orkiestratorze zamiast przykąłdów użycia będzie ścieżka do pliku z przykładem,
- na pierwszy ogień idzie # Stan sesji harnessu taka sekcja - zróbmy jednak od razu każda sekcja będzie miała osobny plik nawet jeżeli miała by być to jedna linia,
- usuń nawiązania do backloga jeżeli coś jest nie pełne to tylko adnotacja "w budowie"
- jeżeli brakuje czegoś, jakiegoś kroku, zawsze stosuj adnotacje "w budowie", żadnych odwołań do innych plików typu backlog czy changes

**Claude — wprowadzone (2026-09-16):**

**Nowy katalog `refactor-legacy-v0.2.0/orchestrator-examples/`** — jeden plik
na sekcję orkiestratora, każdy z nagłówkiem „# Przykład — …" i linią „Sekcja
orkiestratora: …", żeby dało się wrócić do miejsca pochodzenia:

| Plik | Sekcja orkiestratora | Co zawiera |
|---|---|---|
| `stan-sesji-harnessu.md` | „Plik stanu sesji (`refactor-session.md`)" | szablon pliku stanu |
| `refactor-config.md` | „Plik konfiguracji (`refactor-config.json`)" | komplet pól konfiguracji |
| `koperta-wiadomosci.md` | „Koperta wiadomości" | koperta z kompletem pól |
| `etap2-zleca-zmiane-testu.md` | „Przykład: Etap 2 zleca zmianę testu Etapowi 1" | request `test.update` + dispatch `task.execute` |
| `przekazanie-miedzy-krokami-etapu-1.md` | „Przekazanie między krokami Etapu 1" | trzy wiadomości iteracji |
| `log-orkiestratora.md` | „Log orkiestratora (`orkiestrator-log.md`)" | dwa przykłady wpisów |

**`orkiestrator.md`**
- Z każdej z tych sześciu sekcji wycięty przykład, w jego miejsce jedna linia
  ze ścieżką do pliku. Reguły i listy pól obowiązkowych zostały w orkiestratorze
  — wyniesione są wyłącznie przykłady.
- „Struktura harnessu (pliki)" — dodany wiersz `orchestrator-examples/*.md`
  i akapit z regułą: przykłady są poza plikiem, jeden plik na sekcję, nazwa
  pliku = nazwa sekcji; w treści zostaje reguła i ścieżka, nigdy sam przykład.
- Odwołania do `backlog.md` — usunięte (były dwa: w „Bramy kroków (Etap 1)"
  i w `etap1/step1.md`); zastąpione treścią rozstrzygnięcia z `changes-step.md`.
- Rozmiar: **1270 → 1096 linii** (po doliczeniu zmian z `changes-step.md`,
  które ten plik powiększyły o ~60 linii).

**Co zostało w orkiestratorze jako blok kodu (celowo, to nie są przykłady):**
format znacznika czasu (`yyyy-MM-dd; HH-mm-ss`) oraz dwa wywołania PowerShell
(`00-brama.ps1`, eraser) — to interfejs do uruchomienia, nie ilustracja.

**Wątpliwości:**

1. **Nazwa katalogu** — poprawiona na `orchestrator-examples` (na Twoje
   polecenie). Reszta harnessu jest po polsku (`komunikacja/`,
   `scripts/step1/eraser`) — jeśli ma być spójnie, zostaje wariant
   `orkiestrator-przyklady`.
2. **Granulacja „jeden plik na sekcję"** — sekcje „Przykład: Etap 2 zleca
   zmianę testu" i „Przekazanie między krokami Etapu 1" mają po 2–3 wiadomości;
   trzymam je w jednym pliku sekcji (rozdzielone nagłówkami `##`). Jeśli
   „osobny plik nawet na jedną linię" ma znaczyć plik na **każdą wiadomość**,
   rozbiję je na 5 plików.
3. **Reszta odchudzania** — po wycięciu przykładów największe sekcje to
   „Konfiguracja wstępna (Pytania 0–2)" (~150 linii), „Tryb testowy" (~110)
   i „Protokół komunikacji" (~90). Jeśli plik ma dalej chudnąć, to one są
   następne w kolejce — czekam na decyzję, czy tniemy je tą samą metodą
   (osobne pliki), czy dopiero gdy urosną.
