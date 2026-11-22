# Etap 1 — Wspólne zasady agentów
<!-- wersja-harnessu: 0.1.2 -->

Dotyczy `etap1-analiza` i `etap1-implementacja`. Wczytaj na początku każdego
wywołania.

Wywołuje Cię wyłącznie orkiestrator. Nie wywołujesz drugiego agenta. Każde
wywołanie kończysz **jedną** wiadomością do orkiestratora, zapisaną
w `komunikacja/` (format: `references/orkiestrator/protokol-komunikacji.md`).
Nie czekasz na odpowiedź użytkownika — przyjdzie w kolejnym wywołaniu.

## Wejście

Przed każdym wywołaniem wczytaj z dysku `refactor-decisions.md` (ustalenia
z Pytania 0 oraz format znacznika czasu). Plik jest źródłem prawdy; nie
korzystasz z konfiguracji z pamięci poprzedniego wywołania.

## Stan iteracji

Każda wiadomość agentów Etapu 1 niesie `payload.stan_iteracji`. Pola i zasady:
`references/orkiestrator/protokol-komunikacji.md`, sekcja "Stan iteracji".
`stan_iteracji` zmienia tylko `etap1-analiza`. `etap1-implementacja` odsyła je
bez zmian.

## Mocki w testach

Jeżeli są potrzebne mocki albo stuby to dołącz je, staraj się wykorzystać to co
jest, jeżeli nie ma utwórz, **nie używaj frameworka moq**.

## Log Etapu 1 (`etap1-decisions-log.md`)

Jeden plik logu dla obu agentów, oddzielny od `refactor-decisions.md` i od logu
orkiestratora. Wpisy dopisuje wyłącznie skrypt `scripts/wspolne/wpis-logu.ps1`
(patrz "Znaczniki czasu w logach" w `orkiestrator.md`). Numer następnego wpisu
odczytujesz z logu.

Wpisy:
- `etap1-analiza`: rozpoczęcie etapu, wynik rozpoznania testów (pełne,
  niepełne, brak), liczba iteracji z podziału, wysłanie planu iteracji N,
  zakończenie etapu z liczbą iteracji;
- `etap1-implementacja`: rozpoczęcie i zakończenie implementacji iteracji N;
- agent, który dostał `stage.abort`: że użytkownik przerwał (w miejsce wpisu
  o zakończeniu).

Przykład:

```markdown
# Log Etapu 1 — <fragment/moduł>

## Uruchomienie 2026-08-30; 17-05-12

2026-08-30; 17-05-30 — 1. etap1-analiza: uruchomienie etapu1
2026-08-30; 17-07-02 — 2. etap1-analiza: rozpoznanie testów — brak, iteracji 3
2026-08-30; 17-09-40 — 3. etap1-analiza: plan iteracji 1 wysłany do akceptacji
2026-08-30; 17-12-15 — 4. etap1-implementacja: start iteracji 1
2026-08-30; 17-20-48 — 5. etap1-implementacja: koniec iteracji 1
2026-08-30; 17-58-02 — 12. etap1-analiza: zakończenie etapu1, iteracji 3
```

Przykład przerwania:

```markdown
2026-08-30; 17-05-30 — 1. etap1-analiza: uruchomienie etapu1
2026-08-30; 17-12-44 — 2. etap1-analiza: użytkownik przerwał etap1 w iteracji 1
```
