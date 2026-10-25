---
name: Etap1
description: analiza kodu pod względem dostosowania go do uruchomienia testów charakteryzujących. Etap składa się z analizy i impelementacji. Quality gate-m jest człowiek. Jeżeli będie to uruchomione jako agent wtedy całość działa w agancie a człowiek sprawdza tylko wynik końcowy.Analiza oprata jest o zestaw technik zaproponowanych przez Feathers, który jest dołączony.
---
# Etap 1 — Przygotowanie "placu boju" (Characterization + Seams)
<!-- wersja-harnessu: 0.1.1 -->

Uruchamiany przez orkiestratora (`orkiestrator.md`) wiadomością `stage.start`.
Konfiguracja wstępna przychodzi w `payload.config` — Etap 1 jej nie zbiera.

Cel etapu: umożliwić bezpieczne wprowadzenie zmiany poprzez objęcie fragmentu
testem charakteryzującym (characterization test — dokumentuje **aktualne**
zachowanie kodu, niezależnie od tego, czy jest ono poprawne) oraz odsprzęgnięcie
(decoupling) zależności blokujących testowalność.

## Katalog technik Feathersa

Wybór i wykonanie techniki rozrywania zależności (seam) w Fazie Analizy
i Fazie Implementacji opiera się na dwóch plikach:

| Plik | Do czego |
|---|---|
| `references/etap1/feathers-technique-selection.md` | Wybór techniki: tabela objaw → technika, kolejność preferencji (poziomy 1–3), warunki wstępne technik opartych na dziedziczeniu, reguły wyboru |
| `references/etap1/feathers-dependency-breaking-csharp.md` | Wykonanie techniki: 21 technik z przykładami C# (stan wyjściowy / stan docelowy); numer sekcji = numer `[n]` z pliku wyboru |

Wczytaj plik wyboru przed krokiem 2 Fazy Analizy. Plik z technikami wczytuj
tylko w sekcjach wybranych technik.

## Wejście z orkiestratora

Przed rozpoczęciem **każdej kolejnej iteracji** (Faza Analizy każdej iteracji)
Etap 1 wczytuje na nowo z dysku `refactor-decisions.md` (ustalenia z Pytań 0–2
oraz format znacznika czasu obowiązujący w logach).
Etap nie musi trzymać konfiguracji w pamięci między iteracjami ani między
wywołaniami — plik jest źródłem prawdy i przypominajką.

## Struktura wewnętrzna: Faza Analizy i Faza Implementacji

Iteracja: Analiza → zatwierdzenie użytkownika → Implementacja → sprawdzenie
użytkownika. Mały fragment (np. jedna metoda) — jedna iteracja. Duży fragment
(moduł, klasa, kontroler) — kolejne iteracje dla kolejnych podfragmentów.

Gdy cały wskazany zakres jest objęty testami charakteryzującymi, etap wysyła
`stage.done`.

Użytkownik może przerwać w dowolnym momencie, bez uzasadnienia → wpis w logu,
że użytkownik przerwał, i `stage.aborted` do orkiestratora.

## Faza Analizy — kroki

1. **Ocena testowalności fragmentu**
   - Czy zmieniany fragment (metoda/funkcja) da się objąć unit testem
     bez modyfikacji kodu? Testujemy **zachowanie**, nie implementację.
   - Jeśli tak → przejdź do Fazy Implementacji, krok 1 (napisz test na obecny
     stan).
   - Jeśli nie → przejdź do kroku 2 poniżej.
   - Jeśli w konfiguracji wstępnej (Pytanie 0) wybrano granulację **dynamiczną**:
     jeśli fragment okaże się zbyt duży/złożony, aby objąć go jedną spójną
     iteracją Fazy Analizy, zatrzymaj się tutaj — wyślij do orkiestratora
     `user.input` z opisem, co dokładnie jest za duże i dlaczego (pod kątem
     wprowadzenia unit testów), i poczekaj na decyzję użytkownika (np. podział
     na mniejsze podfragmenty i przejście na tryb iteracyjny) zamiast
     kontynuować samodzielnie. To jest ten określony krok, w którym dla
     granulacji dynamicznej musi paść pytanie o zakres zmian, zanim powstanie
     jakikolwiek test.

2. **Wybór techniki dla każdej zależności blokującej testowalność**
   - Rozpoznanie zależności i wybór techniki: wyłącznie według
     `references/etap1/feathers-technique-selection.md`.
   - Objaw spoza tabeli → `user.input` do orkiestratora z opisem zależności.

3. **Propozycja do zatwierdzenia**
   - Propozycja trafia do pliku planu (patrz "Format wyjścia Etapu 1")
     i czeka na zatwierdzenie użytkownika (`user.approval`). Bez zatwierdzenia
     Faza Implementacji się nie rozpoczyna.

4. **Gdy odsprzęgnięcie bez zmiany logiki nie jest możliwe**
   - Jeśli żadna technika z kroku 2 nie pozwala objąć fragmentu
     testem bez ingerencji w logikę biznesową, przedstaw użytkownikowi do
     wyboru poniższe kierunki. Wybór jest obowiązkowy i odnotowywany w logu
     Etapu 1.

   - **Opcja 1 — Opakowanie w dodatkową abstrakcję.** Stosowana, gdy problem
     dotyczy całego modułu, dużej klasy lub metody. Problematyczny kod
     zostaje opakowany w dodatkową abstrakcję, co pozwala wprowadzić
     przełącznik kierujący sterowanie do nowej implementacji — stara
     struktura pozostaje nietknięta. Nowa implementacja powstaje w podejściu
     TDD. Po wyborze tej opcji i wskazaniu frameworka do mocków etap
     zatrzymuje się z adnotacją "w budowie" — dalsze rozwinięcie (przebieg
     TDD, dobór mocków) zamknięte do kolejnej iteracji.

   - **Opcja 2 — Jak Opcja 1, z pytaniem o kierunek zmian.** Ta sama
     technika (abstrakcja + przełącznik), ale przed jej zastosowaniem etap
     pyta użytkownika, czy celem jest: (a) refaktor przez przepisanie
     starego rozwiązania na nowe, zachowanie bez zmian, czy (b) zmiana
     logiki/funkcjonalności realizowana równolegle z refaktorem. Kierunek
     wybiera użytkownik.

## Faza Implementacji — kroki

1. **Napisanie testu charakteryzującego (characterization test)**
   - Test w frameworku ustalonym w Pytaniu 0, dokumentujący obecne zachowanie
     fragmentu (przed jakąkolwiek zmianą logiki).
   - Test musi przechodzić na kodzie w stanie obecnym — to jest punkt odniesienia
     (baseline), względem którego będzie weryfikowana poprawność późniejszego
     refaktoru.

2. **Wprowadzenie seamu**
   - Wykonaj zatwierdzone techniki według sekcji `[n]` w
     `references/etap1/feathers-dependency-breaking-csharp.md`.

3. **Sprawdzenie wyniku przez użytkownika**
   - Wynik (nowe testy + wprowadzony seam) trafia do użytkownika do
     sprawdzenia — to jest koniec danej iteracji.
   - **Tylko w pierwszej iteracji:** zapytaj, czy zastosowane techniki są
     właściwe. Użytkownik może narzucić własne reguły na kolejne iteracje.
   - Kolejny podfragment → wróć do Fazy Analizy, krok 1.
   - Ostatnia iteracja dla całego zakresu → `stage.done` do orkiestratora.

## Mocki w testach

Jeżeli są potrzebne mocki albo stuby to dołącz je, staraj się wykorzystać to co jest, jezlei nie ma utwórz, **nie używaj frameworka moq**.


## Log Etapu 1 (`etap1-decisions-log.md`)

Każde uruchomienie Etapu 1 (dla danego fragmentu) prowadzi własny, osobny plik
logu, oddzielny od logu konfiguracji wstępnej (`refactor-decisions.md`) i od
logu orkiestratora. Nie mieszać zawartości tych plików.

Zasady prowadzenia logu:
- wpisy dopisuje wyłącznie skrypt `scripts/wspolne/wpis-logu.ps1` (patrz "Znaczniki czasu w logach" w `orkiestrator.md`)
- jest wpis że rozpoczęto pracę
- a potem że zakończon z jakim wynikiem czyli np wygenerowana N (gdzie N to liczaba) iteracji
- jeśli użytkownik przerwał — wpis, że użytkownik przerwał (w miejsce wpisu o zakończeniu)


Przykład:

```markdown
# Log Etapu 1 — <fragment/moduł>

## Uruchomienie 2026-08-30; 17-05-12

2026-08-30; 17-05-30 — 1. Uruchomienie etapu1
2026-08-30; 17-30-02 — 2. Zakończenie etapu1, iteracji 10
```

Przykład przerwania:

```markdown
2026-08-30; 17-05-30 — 1. Uruchomienie etapu1
2026-08-30; 17-12-44 — 2. Użytkownik przerwał etap1 w iteracji 3
```

## Format wyjścia Etapu 1

Lokalizacja: katalog wynikowy (patrz "Katalog wynikowy"
w `orkiestrator.md`).

Struktura pliku/sekcji zależy od wyboru dokonanego w Pytaniu 1:

- **Opcja A (osobny plik na etap):** plan zapisywany w `etap1-plan.md`.
- **Opcja B (jeden zbiorczy plik):** plan to sekcja `## Etap 1` w pliku
  zbiorczym `refactor-plan.md`, dopisywana/rozbudowywana w miarę postępu
  iteracji.
- **Dodatkowy plik szczegółowy per iteracja** (tylko jeśli użytkownik wybrał
  tę opcję w Pytaniu 1): po zakończeniu każdej iteracji, niezależnie od logu
  (`etap1-decisions-log.md`), powstaje plik `etap1-iteracja-N-zmiany.md` ze
  szczegółowym opisem zmian tej iteracji. Log pozostaje przy tym wyłącznie
  listą decyzji — bez treści merytorycznej.

Struktura planu (niezależna od wyboru A/B), sekcje w kolejności:

1. **Fragment** — wskazanie metody/klasy/modułu objętego iteracją.
2. **Zależności blokujące** — lista zależności, dla każdej: objaw z tabeli
   (litera), technika z numerem `[n]` i poziom preferencji; przy poziomie 2
   i 3 uzasadnienie wymagane przez plik wyboru.
3. **Proponowany seam** — opis zmiany dla każdej techniki.
4. **Test charakteryzujący** — opis zakresu/przypadków, jakie ma pokryć test
   (bez treści kodu — kod trafia bezpośrednio do pliku testowego, nie do
   planu).
5. **Do akceptacji** — jawne pytanie do użytkownika kończące Fazę Analizy tej
   iteracji.

