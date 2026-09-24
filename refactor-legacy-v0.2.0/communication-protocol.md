# Koperta wiadomości — opis pól

Opis na podstawie stanu obecnego plików (bez zmian w nich):

- `orkiestrator.md` → „Protokół komunikacji orkiestrator ↔ etapy i kroki” (l. 699–797)
- `orchestrator-examples/koperta-wiadomosci.md` — komplet pól
- `orchestrator-examples/etap2-zleca-zmiane-testu.md`, `orchestrator-examples/przekazanie-miedzy-krokami-etapu-1.md`, `etap1-step1-examples/step-done.md` — przykłady
- `.claude/agents/etap0.md` + `scripts/etap0/00-rozpoznanie.ps1` — jak koperta jest czytana przy wznowieniu

## 1. Budowa

Każda wiadomość to jeden obiekt JSON o stałym zestawie 11 pól. Koperta jest wspólna dla wszystkich typów; zmienia się tylko zawartość `payload`.

```json
{
  "msg_id": "e1s1-i2-done",
  "corr_id": "orc-021",
  "type": "response",
  "from": "etap1.step1",
  "to": "orkiestrator",
  "action": "step.done",
  "status": "done",
  "requires_user_ack": false,
  "user_message": "",
  "payload": { },
  "timestamp": "2026-09-09; 11-04-22"
}
```

## 2. Pola

### `msg_id` — identyfikator wiadomości
- **Co to:** unikalny identyfikator tej wiadomości.
- **Wartości:** string. Formalnej konwencji nie ma, przykłady stosują:
  - `orc-NNN` — wiadomości orkiestratora (`orc-014`, `orc-022`),
  - `e2-k1-007` — etap 2, krok refaktoru 1, numer kolejny,
  - `e1s1-i2-done` / `e1s2-i2-done` — etap1.step1 / step2, iteracja 2, `step.done`.
- **Kiedy:** zawsze, w każdej wiadomości. Wiadomość bez `msg_id` jest pomijana przez Etap 0 przy szukaniu otwartych requestów.

### `corr_id` — identyfikator korelacji
- **Co to:** `msg_id` wiadomości, na którą ta wiadomość odpowiada / z której wynika.
- **Wartości:** `msg_id` innej wiadomości albo `null`.
- **Kiedy:**
  - `null` — nowa wiadomość, inicjująca wątek (np. request `test.update` z Etapu 2),
  - `msg_id` poprzednika — dispatch na request (`task.execute` → `corr_id` requestu), `step.done` → `corr_id` = `step.start`, `step.start` Step 2 → `corr_id` = `step.done` Step 1, `stage.resume` → `corr_id` requestu, w którym etap został przerwany.
- **Znaczenie dla harnessu:** request jest „otwarty”, dopóki żadna wiadomość nie ma go w `corr_id`. Po tym Etap 0 odtwarza wiszące requesty, a brama wyjściowa etapu sprawdza, czy żaden request nie został bez odpowiedzi.

### `type` — rodzaj wiadomości
| Wartość | Kierunek | Kiedy |
|---|---|---|
| `request` | etap/krok → orkiestrator | etap czegoś potrzebuje (test.*, user.input, user.approval) |
| `event` | etap/krok → orkiestrator | etap informuje o zdarzeniu (stage.done, stage.aborted, error.critical) |
| `dispatch` | orkiestrator → etap/krok | polecenie: stage.start, step.start, task.execute, stage.resume, stage.abort |
| `response` | etap/krok → orkiestrator | odpowiedź na dispatch; w `payload.result` — co faktycznie zrobiono |

Uwaga: `step.done` w przykładach ma `type: "response"` (odpowiedź na `step.start`), choć w katalogu akcji stoi w tabeli „Etap → orkiestrator (`request` / `event`)”. Podział request vs event nie jest nigdzie przypisany do konkretnych akcji — powyższy rozkład to interpretacja.

### `from` / `to` — nadawca i odbiorca
- **Wartości:** `orkiestrator`, `etap0`, `etap1`, `etap2`, `etap3`, `etap1.step1`, `etap1.step2`.
- **Reguły:**
  - każda wiadomość idzie przez orkiestratora — jedna strona zawsze to `orkiestrator`,
  - krok nigdy nie adresuje drugiego kroku; krok ma w `to` zawsze `orkiestrator`,
  - etapy też nie piszą do siebie nawzajem (Etap 2 → orkiestrator → Etap 1).
- `from` trafia do nazwy pliku w `komunikacja/`.

### `action` — co wiadomość robi

**Etap/krok → orkiestrator:**

| `action` | Kiedy |
|---|---|
| `test.update` | istniejący test wymaga aktualizacji (np. po zmianie nazwy) |
| `test.add` | trzeba dopisać nowy test |
| `test.remove` | test stał się zbędny |
| `test.mock.enable` | trzeba włączyć obsługę mocków w projekcie testowym |
| `test.mock.add` | trzeba dodać mock/stub dla przeniesionej zależności |
| `user.input` | potrzebna informacja od użytkownika (magic number, wybór frameworka, wynik ręcznego build/testów) |
| `user.approval` | plan gotowy, czeka na akceptację |
| `stage.done` | etap zakończony (orkiestrator sprawdza bramę wyjściową) |
| `step.done` | krok zakończony — jedyny sposób zakończenia pracy kroku |
| `stage.aborted` | użytkownik przerwał iterację/etap |
| `error.critical` | sytuacja blokująca |

Akcje `test.*` są routowane wyłącznie do Etapu 1 (`task.execute`).

**Orkiestrator → etap/krok (`dispatch`):**

| `action` | Kiedy |
|---|---|
| `stage.start` | start etapu po przejściu bramy wejściowej |
| `step.start` | start kroku Etapu 1; payload = payload `step.done` poprzedniego kroku + `config` |
| `task.execute` | pojedyncze zadanie zlecone przez inny etap |
| `stage.resume` | wznowienie etapu po obsłużonym requeście albo po nieprzejściu bramy wyjściowej (z listą braków) |
| `stage.abort` | zakończenie etapu (decyzja użytkownika / critical error) |

### `status` — stan nadawcy w chwili wysłania
| Wartość | Znaczenie / użycie w przykładach |
|---|---|
| `blocked` | nadawca stoi i czeka na obsłużenie requestu (np. Etap 2 przy `test.update`) |
| `in_progress` | praca trwa — używane w dispatchach orkiestratora |
| `done` | zakończone powodzeniem (`step.done`, `response`) |
| `failed` | wykonanie nie powiodło się (`response`) |
| `needs_user` | do dokończenia potrzebny jest użytkownik (`response`) |

Dla `response` dopuszczalne są tylko `done` / `failed` / `needs_user`. Dla pozostałych typów przypisanie wartości nie jest opisane — wynika wyłącznie z przykładów.

Uwaga: to jest `status` koperty. `payload.quality_gate.status` (`passed` / `failed` / `nie_wykonany`) to osobne pole payloadu.

### `requires_user_ack` — czy pokazać użytkownikowi
- **Wartości:** `true` / `false`.
- **`true`:** orkiestrator przed dalszym działaniem pokazuje `user_message` użytkownikowi (np. `test.update` — transparentność zmian w testach; `step.done` Step 2 — podsumowanie iteracji; przerwanie po drugim `failed` bramy Step 1).
- **`false`:** wiadomość czysto sterująca (dispatche, `step.done` Step 1).

### `user_message` — tekst dla użytkownika
- **Wartości:** string; dokładna treść do pokazania, bez przeredagowania przez orkiestratora.
- **Reguła:** nie może być pusty, gdy `requires_user_ack: true`. Przy `false` — `""`.
- Etap 0 używa go jako opisu otwartego requestu (przycięty do 160 znaków).

### `payload` — treść merytoryczna
- **Wartości:** obiekt; zawartość zależy od `action`.
- Stałe elementy:
  - `payload.config` — w każdym `stage.start`, `step.start`, `task.execute`, `stage.resume`; zawartość `refactor-config.json` wczytana z dysku przy każdej wiadomości,
  - `payload.wejscie` — w `step.start` do Step 2: payload `step.done` Step 1 bez zmian,
  - `payload.quality_gate_step1` — w `step.start` do Step 2: wynik bramy Step 1,
  - `payload.task` — w `task.execute`: kopia payloadu requestu,
  - `payload.result` — w `response`: co faktycznie zrobiono,
  - `payload.resume_point` — w requeście przerywającym etap: miejsce powrotu,
  - `payload.iteracje` — w wiadomościach kroków Etapu 1; czytane przez Etap 0.
- Pola obowiązkowe `step.done`:
  - Step 1: `iteracje.biezaca`, `iteracje.zaplanowane`, `quality_gate.status` (zawsze `nie_wykonany`), `liczba_zmian`, `pliki[]` (`nazwa`, `sciezka`), `kolejnosc_implementacji`; propozycja `nastepny`,
  - Step 2: `ukonczono`, `iteracje`, `quality_gate.status` + dla każdej pozycji bramy `wynik` i `wykonal` (`krok` / `uzytkownik`).
- Orkiestrator nie przepisuje ani nie interpretuje payloadu merytorycznie — czyta tylko to, czego potrzebuje do sterowania (iteracje, pliki, wynik bramy).

### `timestamp` — moment wysłania
- **Wartości:** `yyyy-MM-dd; HH-mm-ss`, np. `2026-09-09; 11-04-22` (format z `refactor-config.json`, pole `harness.znacznik_czasu`).
- W dwóch przykładach (`koperta-wiadomosci.md`, `etap2-zleca-zmiane-testu.md`) stoi placeholder `<data>` / `<data i godzina>`.

## 3. Zapis

- Każda wiadomość to osobny plik w `<katalog wynikowy>/komunikacja/`: `<NNN>-<from>-<action>.json`, np. `014-etap1.step1-step.done.json` (NNN — numeracja chronologiczna).
- `step.done` Step 1 jest dodatkowo zapisywany jako `step1-step-done-N.json` w katalogu wynikowym.
- `komunikacja/` to źródło, z którego orkiestrator (i Etap 0) odtwarza stan przy wznowieniu.

## 4. Luki zauważone przy opisie

1. Brak formalnej konwencji `msg_id` — tylko przykłady.
2. `type` `request` vs `event` — nieprzypisane do akcji; `step.done` jest w przykładach `response`, a w katalogu w grupie request/event.
3. `status` — dozwolone wartości per `type` opisane tylko dla `response`.
4. `timestamp` — placeholdery w dwóch przykładach zamiast formatu.
5. Przykład `step.done` w `.claude/agents/etap1/step2.md` (l. 175–198) nie ma `msg_id` ani `corr_id` — koperta niepełna.

## 5. Gdzie opisane są pola — pliki i linie

Ścieżki względem `refactor-legacy-v0.2.0/`. „Opis” = definicja/reguła, „Przykład” = wartość w JSON-ie, „Użycie” = odczyt przez skrypt lub reguła, która z pola korzysta.

### Koperta jako całość
| Plik | Linie | Co |
|---|---|---|
| `orkiestrator.md` | 699–704 | wstęp: każde zakończenie / przerwanie / potrzeba = wiadomość JSON |
| `orkiestrator.md` | 706–717 | sekcja „Koperta wiadomości” — opis części pól |
| `orchestrator-examples/koperta-wiadomosci.md` | 1–20 | komplet 11 pól (wzorzec) |
| `.claude/agents/etap1/step1.md` | 303–304 | odesłanie do „Protokołu komunikacji” |
| `.claude/agents/etap1/step2.md` | 202–203 | odesłanie do „Protokołu komunikacji” |

### `msg_id`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 710 | Opis — „unikalny identyfikator wiadomości” |
| `.claude/agents/etap0.md` | 113, 142 | Użycie — request otwarty; pole w `requesty_otwarte[]` |
| `scripts/etap0/00-rozpoznanie.ps1` | 177, 204–205, 211 | Użycie — odczyt, pominięcie wiadomości bez `msg_id` |
| `orchestrator-examples/koperta-wiadomosci.md` | 9 | Przykład `e2-k1-003` |
| `orchestrator-examples/etap2-zleca-zmiane-testu.md` | 9, 40 | Przykład `e2-k1-007`, `orc-014` |
| `orchestrator-examples/przekazanie-miedzy-krokami-etapu-1.md` | 9, 59, 80 | Przykład `e1s1-i2-done`, `orc-022`, `e1s2-i2-done` |
| `etap1-step1-examples/step-done.md` | 11 | Przykład `e1s1-i2-done` |
| `orchestrator-examples/etap0-raport.md` | 87 | Przykład w raporcie Etapu 0 |

### `corr_id`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 711 | Opis — `msg_id` wiadomości, na którą odpowiada; `null` dla nowej |
| `orkiestrator.md` | 744 | Opis — `stage.resume` wznawia „w punkcie `corr_id`” |
| `orkiestrator.md` | 756 | Opis — `stage.resume` z `corr_id: "e2-k1-007"` |
| `.claude/agents/etap0.md` | 113 | Użycie — request otwarty = brak odwołania w `corr_id` |
| `scripts/etap0/00-rozpoznanie.ps1` | 178, 196–199 | Użycie — odczyt, lista odpowiedzianych |
| `.claude/agents/etap1/step2.md` | 245, 304, 325–326 | Użycie — log trybu zadaniowego zapisuje `corr_id` |
| przykłady | `koperta-wiadomosci.md` 10; `etap2-zleca-zmiane-testu.md` 10, 41; `przekazanie-miedzy-krokami-etapu-1.md` 10, 60, 81; `step-done.md` 12 | Przykład |

### `type`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 721 | Opis — `request` / `event` (etap → orkiestrator) |
| `orkiestrator.md` | 737 | Opis — `dispatch` (orkiestrator → etap) |
| `orkiestrator.md` | 747–748 | Opis — `response` |
| `.claude/agents/etap1/step2.md` | 241–242 | Opis — odpowiedź w trybie zadaniowym = `response` |
| `.claude/agents/etap0.md` | 113 | Użycie — otwarte są tylko `request` / `event` |
| `scripts/etap0/00-rozpoznanie.ps1` | 179, 201 | Użycie — filtr `request` / `event` |
| `orchestrator-examples/koperta-wiadomosci.md` | 11 | Wartości `request \| dispatch \| response \| event` |
| przykłady | `etap2-zleca-zmiane-testu.md` 11, 42; `przekazanie-miedzy-krokami-etapu-1.md` 11, 61, 82; `step-done.md` 13; `step2.md` 176 | Przykład |

### `from` / `to`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 712–714 | Opis — adresy, krok nie adresuje kroku |
| `orkiestrator.md` | 428–435 | Opis — adresy kroków `etap1.step1` / `etap1.step2` (tabela) |
| `orkiestrator.md` | 437–449 | Opis — izolacja kroków, komunikacja tylko przez orkiestratora |
| `orkiestrator.md` | 793–795 | Użycie — `from` w nazwie pliku `komunikacja/` |
| `scripts/etap0/00-rozpoznanie.ps1` | 180–181, 202 | Użycie — odczyt; pominięcie wiadomości od orkiestratora |
| przykłady | `koperta-wiadomosci.md` 12–13; `etap2-zleca-zmiane-testu.md` 12–13, 43–44; `przekazanie-miedzy-krokami-etapu-1.md` 12–13, 62–63, 83–84; `step-done.md` 14–15; `step2.md` 177–178 | Przykład |

### `action`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 719–748 | Opis — katalog akcji (obie strony) |
| `orkiestrator.md` | 758–787 | Opis — `step.done` / `step.start` między krokami |
| `orkiestrator.md` | 852–866 | Opis — reakcja orkiestratora na akcje (pętla, pkt 5) |
| `orkiestrator.md` | 793–795 | Użycie — `action` w nazwie pliku |
| `.claude/agents/etap1/step2.md` | 220–245 | Opis — akcje trybu zadaniowego (`test.*`) |
| `.claude/agents/etap0.md` | 106–115, 142 | Użycie — status etapu z akcji; pominięcie `stage.done` / `step.done` |
| `scripts/etap0/00-rozpoznanie.ps1` | 182, 206 | Użycie — odczyt, filtr |
| przykłady | `koperta-wiadomosci.md` 14; `etap2-zleca-zmiane-testu.md` 14, 45; `przekazanie-miedzy-krokami-etapu-1.md` 14, 64, 85; `step-done.md` 16; `step2.md` 179; `etap0-raport.md` 89 | Przykład |

### `status`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 747–748 | Opis — dla `response`: `done` / `failed` / `needs_user` |
| `orkiestrator.md` | 321–322 | Użycie — brama wejściowa Step 2 wymaga `status: "done"` w `step.done` Step 1 |
| `.claude/agents/etap1/step2.md` | 241–242 | Opis — odpowiedź w trybie zadaniowym |
| `scripts/etap0/00-rozpoznanie.ps1` | 183 | Użycie — odczyt |
| `orchestrator-examples/koperta-wiadomosci.md` | 15 | Wartości `blocked \| in_progress \| done \| failed \| needs_user` |
| przykłady | `etap2-zleca-zmiane-testu.md` 15, 46; `przekazanie-miedzy-krokami-etapu-1.md` 15, 65, 86; `step-done.md` 17; `step2.md` 180 | Przykład |

Nie mylić z: `payload.quality_gate.status` (`step-done.md` 31, `przekazanie-…` 29, 96, `step2.md` 190) i `etapy[].status` w raporcie Etapu 0 (`etap0-raport.md` 48, 57, 67, 76).

### `requires_user_ack`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 715 | Opis — czy przed wykonaniem pokazać coś użytkownikowi |
| `orkiestrator.md` | 380 | Użycie — przerwanie po drugim `failed` bramy Step 1 |
| `orkiestrator.md` | 842 | Użycie — to samo w pętli (4b') |
| `orkiestrator.md` | 857–858 | Użycie — `test.*` z `true` → najpierw pokaż użytkownikowi |
| `.claude/agents/etap1/step2.md` | 235 | Użycie — tryb zadaniowy |
| przykłady | `koperta-wiadomosci.md` 16; `etap2-zleca-zmiane-testu.md` 16, 47; `przekazanie-miedzy-krokami-etapu-1.md` 16, 66, 87; `step-done.md` 18; `step2.md` 181 | Przykład |

### `user_message`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 716–717 | Opis — dokładna treść; niepusta przy `requires_user_ack: true` |
| `orkiestrator.md` | 854, 858 | Użycie — przekazanie użytkownikowi |
| `.claude/agents/etap1/step2.md` | 235 | Użycie — tryb zadaniowy |
| `scripts/etap0/00-rozpoznanie.ps1` | 184, 208–209 | Użycie — opis otwartego requestu (max 160 znaków) |
| przykłady | `koperta-wiadomosci.md` 17; `etap2-zleca-zmiane-testu.md` 17, 48; `przekazanie-miedzy-krokami-etapu-1.md` 17, 67, 88; `step-done.md` 19; `step2.md` 182 | Przykład |

### `payload`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 96–100 | Opis — `payload.config` w każdej wiadomości do etapu/kroku |
| `orkiestrator.md` | 680–685 | Opis — `payload.config` wczytywany z dysku przy każdym wysłaniu |
| `orkiestrator.md` | 320–323 | Użycie — `payload.pliki` w bramie wejściowej Step 2 |
| `orkiestrator.md` | 359–362 | Opis — `payload.quality_gate_step1` |
| `orkiestrator.md` | 741–742, 747–748 | Opis — `payload.config`, payload `step.start`, `payload.result` |
| `orkiestrator.md` | 766–787 | Opis — pola obowiązkowe `step.done` Step 1 / Step 2, `payload.wejscie` |
| `orkiestrator.md` | 472–474 | Opis — payload nie jest przepisywany ani interpretowany |
| `.claude/agents/etap1/step1.md` | 84–95 | Opis — wejście: `payload.config`, `payload.iteracja` |
| `.claude/agents/etap1/step1.md` | 284–297 | Opis — tabela pól payloadu `step.done` Step 1 |
| `.claude/agents/etap1/step2.md` | 40–58 | Opis — wejście: `payload.wejscie`, `payload.config`, `payload.wejscie.iteracje.biezaca` |
| `.claude/agents/etap1/step2.md` | 157–171 | Opis — tabela pól payloadu `step.done` Step 2 |
| `.claude/agents/etap1/step2.md` | 222–240, 274 | Opis — `payload.allowed_scope`, `payload.forbidden`, `payload.result` |
| `.claude/agents/etap0.md` | 26, 41, 49, 127 | Opis — `payload.report`, `payload.config.tryb` |
| `scripts/etap0/00-rozpoznanie.ps1` | 188–190 | Użycie — odczyt `payload.iteracje` |
| przykłady | `koperta-wiadomosci.md` 18; `etap2-zleca-zmiane-testu.md` 18–31, 49–52; `przekazanie-miedzy-krokami-etapu-1.md` 18–50, 68–71, 89–102; `step-done.md` 20–52; `step2.md` 183–197 | Przykład |

### `timestamp`
| Plik | Linie | Rodzaj |
|---|---|---|
| `orkiestrator.md` | 132–160 | Opis — format znacznika czasu (l. 142), źródło w konfiguracji (l. 151) |
| `refactor-config.example.json` | 13 | Wartość `harness.znacznik_czasu` |
| `scripts/etap0/00-rozpoznanie.ps1` | 185, 214 | Użycie — odczyt; `wystawiony` otwartego requestu |
| `orchestrator-examples/koperta-wiadomosci.md` | 19 | Placeholder `<data i godzina>` |
| `orchestrator-examples/etap2-zleca-zmiane-testu.md` | 32, 53 | Placeholder `<data>` |
| przykłady | `przekazanie-miedzy-krokami-etapu-1.md` 51, 72, 103; `step-done.md` 53; `step2.md` 198; `quality-gate-step1.md` 16 | Przykład |

Uwaga: `orkiestrator.md` l. 132–160 mówi o znacznikach czasu **w logach**; że ten sam format obowiązuje w polu `timestamp` koperty, wynika tylko z przykładów.

### Zapis wiadomości
| Plik | Linie | Co |
|---|---|---|
| `orkiestrator.md` | 789–797 | `komunikacja/<NNN>-<from>-<action>.json` |
| `orkiestrator.md` | 763–766 | `step1-step-done-N.json` + kopia w `komunikacja/` |
| `orkiestrator.md` | 492–495 | wznowienie z `komunikacja/` |
| `.claude/agents/etap1/step1.md` | 276–282 | zapis `step1-step-done-N.json`, kopia w `komunikacja/` |
| `.claude/agents/etap0.md` | 93, 106–115 | odczyt `komunikacja/*.json` |
| `scripts/etap0/00-rozpoznanie.ps1` | 160–192 | odczyt `komunikacja/*.json` |

## 6. Wzmianki o kopercie w plikach changes

Przeszukane: `v0.1.0/v0.1.0/changes.md`, `changes_test.md`, `v0.2.0/v0.2.0/changes2.md`, `v0.2.0/v0.2.1/changes.md`, `changes-orchestrator.md`, `changes-step.md`, `v0.2.0/v0.2.2/changes-orchestrator.md`, `changes-project.md` (ścieżki względem `orkiestartor-refaktor-skill/`). Szukane: „koperta” oraz nazwy pól.

### Wprost o kopercie
| Plik | Linia | Treść |
|---|---|---|
| `v0.1.0/v0.1.0/changes.md` | 75 | **Wprowadzenie koperty**: 11 pól, katalog akcji w obie strony, przykład routingu Etap 2 → Etap 1 → `stage.resume`, zapis w `komunikacja/` |
| `v0.2.0/v0.2.0/changes2.md` | 248–278 | nowe adresy `etap1.step1` / `etap1.step2`, akcje `step.start` / `step.done`; krok w `to` ma zawsze `orkiestrator` (l. 253); `payload.pliki` w bramie (l. 275) |
| `v0.2.0/v0.2.1/changes-orchestrator.md` | 28 | przeniesienie koperty do `orchestrator-examples/koperta-wiadomosci.md` |
| `v0.2.0/v0.2.1/changes-orchestrator.md` | 113–114 | reguła: request otwarty = `msg_id` bez odwołania w `corr_id` |
| `v0.2.0/v0.2.1/changes.md` | 42 | pytanie: koperta `step.done` a osobny plik `step1-zmiany-N.json` |
| `v0.2.0/v0.2.1/changes-step.md` | 27–33 | **luka**: brak koperty `step.start` → `etap1.step1`; nazwa `payload.iteracja` nie pada po stronie orkiestratora; `step.start` w katalogu akcji nie ma wariantu dla Step 1 |
| `v0.2.0/v0.2.1/changes-step.md` | 104–105 | **luka**: `payload.quality_gate_step1` nie ma w przykładzie `orc-022` ani w wejściu `step2.md` |
| `v0.2.0/v0.2.1/changes-step.md` | 130–134 | najpilniejsze: brak koperty `step.start` do Step 1 i nazwy pola `iteracja` |
| `v0.2.0/v0.2.2/changes-orchestrator.md` | 204–206 | `koperta-wiadomosci.md` bez zmian przy zmianie trybu |
| `v0.2.0/v0.2.2/changes-project.md` | 210 | rozjazd dwóch przykładów `step.done` (pełna koperta vs niepełna) |
| `v0.2.0/v0.2.2/changes-project.md` | 217 | ujednolicenie: `step-done.md` = pełna koperta z `przekazanie-…` |

### O polach koperty (bez słowa „koperta”)
| Plik | Linia | Pole | Treść |
|---|---|---|---|
| `v0.1.0/v0.1.0/changes.md` | 58 | `requires_user_ack` | aktualizacja testów po renamie: najpierw request z `true` |
| `v0.1.0/v0.1.0/changes.md` | 59 | `msg_id` | log Etapu 2 zapisuje `msg_id` każdego requestu na testy |
| `v0.1.0/v0.1.0/changes.md` | 73 | `payload.config` | konfiguracja idzie do etapów w `stage.start` |
| `v0.1.0/v0.1.0/changes.md` | 131 | `requires_user_ack`, `payload` | zmiana konstruktora: `allowed_scope`, `forbidden` |
| `v0.1.0/v0.1.0/changes_test.md` | 14 | `payload.report` | Etap 0 też idzie protokołem |
| `v0.1.0/v0.1.0/changes_test.md` | 25 | `payload.config` | flaga poza konfiguracją |
| `v0.1.0/v0.1.0/changes_test.md` | 34 | `to`, `action`, `corr_id` | brak klucza adresowania mocków w testach harnessu |
| `v0.1.0/v0.1.0/changes_test.md` | 130 | `payload.config` | `tryb` w `payload.config` |
| `v0.2.0/v0.2.0/changes2.md` | 107 | `payload.config` | wejście Step 1 |
| `v0.2.0/v0.2.1/changes.md` | 120 | `timestamp` | pole w wynikach skryptów bramy (nie koperta) |
| `v0.2.0/v0.2.1/changes-orchestrator.md` | 191, 199, 216 | `payload.config`, `payload.report` | tryb, odczyt config z dysku, raport Etapu 0 |
| `v0.2.0/v0.2.2/changes-orchestrator.md` | 53, 188, 272 | `payload.config.tryb` | pozycja `tryb` |
| `v0.2.0/v0.2.2/changes-project.md` | 250–251 | `payload.iteracja` | dwie nazwy pola iteracji (Step 1 vs Step 2) → propozycja jednego pola |
| `v0.2.0/v0.2.2/changes-project.md` | 252–253 | `requires_user_ack` | Step 2 kończy z `true` → propozycja `false` |
| `v0.2.0/v0.2.2/changes-project.md` | 274 | payload `step.start` | treść `step.start` dla Step 1 niezdefiniowana |
| `v0.2.0/v0.2.2/changes-project.md` | 276–277 | `payload.wyjscie` | propozycja pełnych ścieżek od orkiestratora |
| `v0.2.0/v0.2.2/changes-project.md` | 279 | `payload.zakres_iteracji` | propozycja |
| `v0.2.0/v0.2.2/changes-project.md` | 281 | `payload.proba`, `payload.niezaliczone[]` | propozycja dla ponowienia |
| `v0.2.0/v0.2.2/changes-project.md` | 285 | `status: needs_user`, `payload.odpowiedz_uzytkownika` | `user.input` z subagenta |
| `v0.2.0/v0.2.2/changes-project.md` | 291 | payload `step.done` | propozycja okrojenia pól Step 1 |
| `v0.2.0/v0.2.2/changes-project.md` | 293 | zapis | kto zapisuje kopię w `komunikacja/` |
| `v0.2.0/v0.2.2/changes-project.md` | 299 | `timestamp` | porównanie `timestamp` `step-done` z czasem `step.start` próby 2 |

Uwaga: numery linii cytowane **wewnątrz** plików changes (np. „`orkiestrator.md` linia 768”) odnoszą się do stanu z chwili pisania i mogą nie zgadzać się z obecnym plikiem.
