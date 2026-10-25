# Etap 2 — Wprowadzenie zmiany (Refaktor i/lub Zmiana logiki)
<!-- wersja-harnessu: 0.1.1 -->

Uruchamiany przez orkiestratora (`orkiestrator.md`) wiadomością `stage.start`.
Konfiguracja wstępna przychodzi w `payload.config` — Etap 2 jej nie zbiera.

## Brama wejściowa (warunek uruchomienia)

Etap 2 uruchamia się dopiero po zakończeniu Etapu 1 **i** po jawnej akceptacji
przez użytkownika wyniku Etapu 1 (utworzone unit testy do istniejącego kodu
i/lub zmiany umożliwiające testowanie — seamy, extract method/interface).
Brak akceptacji = brak startu Etapu 2. Bramy pilnuje orkiestrator.

Etap 2 to już konkretne zmiany w kodzie. Zmiana jest bezpieczna, ponieważ
istnieje siatka testów z Etapu 1, względem której można weryfikować skutki.

## Zmiany w testach z Etapu 1

Etap 2 sam aktualizuje testy z Etapu 1, wyłącznie w dwóch przypadkach:
zmiana nazwy (Krok 1) i przeniesienie zależności do konstruktora (Krok 3).
- Zmiany w testach są zapowiedziane w planie kroku (sekcja "Wpływ na testy
  z Etapu 1") i akceptowane razem z nim, przed zmianą kodu.
- Asercje, dane wejściowe i zakres testu pozostają nietknięte.
- Każda zmiana w testach jest odnotowana w logu Etapu 2.

## Pytanie startowe Etapu 2 — Rodzaj zmiany

Zanim ruszy jakakolwiek zmiana kodu, użytkownik wybiera jedną z opcji:
- **Refaktor** — wyłącznie zmiana struktury kodu, zachowanie bez zmian
  (behavior-preserving).
- **Zmiana logiki** — zmiana zachowania biznesowego.
- **Oba** — refaktor i zmiana logiki razem.

**Reguła rozgałęzienia:** jeśli wybór zawiera zmianę logiki (opcja "Zmiana
logiki" lub "Oba"), Etap 2 **staje się etapem wprowadzenia zmiany logiki** i
zawęża się wyłącznie do niej. Refaktoryzacja nie jest wtedy wykonywana
w Etapie 2 — zostaje odroczona i przechodzi do Etapu 3, który staje się
dedykowanym etapem refaktoryzacji rezultatu Etapu 2. Jeśli wybrano samą opcję
"Refaktor" (bez zmiany logiki), ta reguła się nie stosuje i Etap 2 pozostaje
czystym refaktorem — przebiega wtedy według sekcji "Wariant Refaktor" niżej.

Wybrany wariant jest raportowany do orkiestratora, bo od niego zależy, czy
Etap 3 zostanie w ogóle uruchomiony.

---

## Wariant "Zmiana logiki" *(w budowie)*

Ścieżka uruchamiana, gdy w pytaniu startowym wybrano "Zmiana logiki" lub "Oba".

**Krok wejściowy — opis zmiany od użytkownika.** Zanim ruszy cokolwiek innego,
użytkownik wprowadza opis zmiany, obejmujący:
- czego dotyczą zmiany (opis merytoryczny),
- jakich części systemu / kodu dotykają,
- jakie są przewidziane granice zmian (co jest poza zakresem),
- co jest sednem problemu, który zmiana ma rozwiązać.

Opis jest wejściem dla wszystkich dalszych kroków tego wariantu i trafia do
pliku wynikowego Etapu 2.

**Status: w budowie.** Dalszy przebieg wariantu (kroki po opisie wejściowym,
sposób weryfikacji względem testów z Etapu 1, tryb aktualizacji testów) nie
jest jeszcze ustalony — do zdefiniowania w kolejnej iteracji. Do tego czasu
etap po zebraniu opisu wejściowego zatrzymuje się z adnotacją "w budowie",
raportuje to orkiestratorowi i czeka na decyzję użytkownika.

Poniższa lista to **wstępny zarys do rewizji**, nie zatwierdzony przebieg:

1. Zakres Etapu 2 zawężony wyłącznie do zmiany logiki biznesowej — bez
   refaktoryzacji struktury.
2. Wprowadź zmianę logiki zgodnie z ustaleniami z użytkownikiem.
3. Uruchom testy z Etapu 1 (testy charakteryzujące zachowanie sprzed zmiany).
4. Dla każdego testu, który przestał przechodzić w wyniku zmiany logiki:
   odnotuj to jawnie i zweryfikuj z użytkownikiem, czy to zamierzona zmiana
   zachowania (wtedy test wymaga aktualizacji) czy niezamierzony efekt uboczny
   (wtedy to błąd do poprawy, nie do zaakceptowania jako nowy stan).
5. Nie wykonuj żadnej zmiany strukturalnej/refaktoryzacyjnej w tym kroku —
   nawet jeśli przy okazji widać oczywisty refaktor. Odnotuj taką obserwację
   do rozważenia w Etapie 3, ale nie realizuj jej teraz.

---

## Wariant "Refaktor" (bez zmiany logiki)

Ścieżka uruchamiana, gdy w pytaniu startowym wybrano wyłącznie "Refaktor".
Etap 2 koncentruje się wtedy na dwóch rzeczach naraz: na **zmianach w kodzie**
i na **testach tych zmian** — każda zmiana jest natychmiast weryfikowana
siatką testów z Etapu 1.

Wariant dzieli się na **pod-etapy (kroki)** wykonywane po kolei. Każdy krok kończy się sprawdzeniem/potwierdzeniem przez
użytkownika, zanim ruszy następny.

### Krok 1 — Czytelność (nazewnictwo)

Cel: doprowadzić nazwy do zgodności z tym, co kod **faktycznie** robi. Bez
zmiany zachowania.

1. Popraw nazwy zmiennych, nazwy metod i nazwy klas tak, aby odpowiadały ich
   rzeczywistej odpowiedzialności — nie temu, co sugeruje nazwa historyczna.
2. Nie zmieniaj zachowania. Ten krok to wyłącznie rename
   (behavior-preserving), żadnych zmian struktury ani logiki.
3. **Sprzężenie z Etapem 1 (obowiązkowe).** Zmiana nazwy metody lub klasy
   objętej testami z Etapu 1 spowoduje, że te testy przestaną się
   kompilować/przechodzić. To skutek zamierzony, nie regresja. Postępowanie:

   - Plan kroku wymienia testy, które zaświecą na czerwono, i zmianę nazwy,
     która to spowoduje.
   - Po zmianie nazwy Etap 2 aktualizuje w tych testach **wyłącznie nazwy**
     (patrz "Zmiany w testach z Etapu 1").

   To jedyny przypadek w wariancie "Refaktor", w którym niezaliczony test nie
   jest sygnałem regresji — rozstrzygnięcie w "Regule niezaliczonego testu".
4. **Efekt uboczny wykorzystywany w dalszych krokach:** zmiana nazwy ujawnia
   zasięg zmiany — pokazuje wszystkie miejsca w kodzie odwołujące się do
   zmienianego elementu. Ta lista miejsc jest wejściem dla kolejnych kroków
   (ocena rzeczywistego zakresu refaktoru) i trafia do pliku wynikowego
   Etapu 2.

### Krok 2 — Usunięcie magic numbers

Cel: zastąpić literały o nieoczywistym znaczeniu nazwanymi stałymi. Bez zmiany
zachowania.

1. **Wykonuje LLM.** Znajdź w zakresie kroku literały (liczby, ale też stringi
   pełniące rolę kodów/flag), których znaczenie da się jednoznacznie wywieść
   z kodu — z nazwy zmiennej, kontekstu użycia, warunku, komentarza. Zastąp je
   nazwaną stałą / elementem enuma, zgodnie z konwencją panującą w projekcie.
2. **Zakaz zgadywania.** Jeśli znaczenia literału **nie da się** wywnioskować
   ani znaleźć w kodzie — LLM **nic nie wymyśla**. Wystawia do orkiestratora
   request `user.input` z listą literałów, których nie rozpoznał, wraz
   z miejscami wystąpienia. Nie nadaje im nazw "na oko", nie zostawia
   domyślnej nazwy typu `MAGIC_1`, nie pomija ich po cichu.
3. **Wkład użytkownika.** Użytkownik ustala, czym są te wartości, i przekazuje
   je w dowolnej użytecznej formie:
   - wpis w odpowiednim pliku (np. w pliku wynikowym Etapu 2),
   - enum wrzucony bezpośrednio do kodu,
   - klasa statyczna ze stałymi,
   - inna forma umożliwiająca wykorzystanie tych wartości w kodzie.

   Dopiero po otrzymaniu tej informacji LLM podstawia wartości w kodzie.
   Literały nierozpoznane i nieopisane przez użytkownika zostają nietknięte
   i są wymienione w pliku wynikowym jako pozycje otwarte.
4. **Testy po kroku.** Ten krok nie powinien zmieniać zachowania, więc czerwony
   test jest tu mało prawdopodobny — ale testy uruchamiamy i sprawdzamy
   **po każdym kroku, bez wyjątku**. Czerwony test po kroku 2 nie ma
   usprawiedliwienia w postaci renamu, więc obowiązuje punkt 4 "Reguły
   niezaliczonego testu" (regresja → stop i zgłoszenie).

### Krok 3 — Przerwanie zależności

Cel: uwidocznić zależności od systemów zewnętrznych i przesunąć je do
konstruktora, tak żeby dało się je w testach zamockować lub zastubować. Bez
zmiany zachowania.

1. **Wykrycie zależności od systemów zewnętrznych.** Pod tym hasłem kryje się
   więcej niż baza danych. Szukaj w zakresie kroku:
   - zewnętrznych klas (typów spoza zakresu refaktorowanej jednostki,
     tworzonych przez `new` wewnątrz metody lub konstruktora),
   - dostępu do bazy danych (kontekst ORM, połączenia, repozytoria, zapytania
     w kodzie),
   - wywołań API / usług zdalnych (HTTP, kolejki, usługi sieciowe),
   - innych wywołań wychodzących poza jednostkę: wywołania statyczne,
     singletony, dostęp do zegara (`DateTime.Now`), systemu plików,
     konfiguracji, kontekstu HTTP.

   Wynik to lista zależności z miejscami wystąpienia — trafia do sekcji "Stan
   wyjściowy" pliku wynikowego. Lista Etapu 1 ("Zależności blokujące") jest tu
   punktem wyjścia, ale Krok 3 idzie szerzej: Etap 1 zajmował się wyłącznie
   tym, co blokowało napisanie testu, a tu chodzi o **wszystkie** zależności
   zewnętrzne w zakresie.

2. **Przesunięcie do konstruktora.** Każdą znalezioną zależność przesuwamy do
   postaci **zależności przychodzącej "od góry"** — wstrzykiwanej przez
   konstruktor, zamiast tworzonej lub pobieranej wewnątrz metody.
   - Zależność dostaje interfejs (albo używa istniejącego), jeśli go jeszcze
     nie ma.
   - Konstruktor przyjmuje ją jako parametr i zapamiętuje w polu.
   - Miejsca użycia wołają pole zamiast tworzyć instancję / wołać statykę.
   - **Liczba zależności nie ma na tym etapie znaczenia.** Nawet jeśli
     konstruktor urośnie do kilkunastu parametrów — to nie jest problem tego
     kroku, tylko jego **zamierzony efekt**: krok ma je *uwidocznić*.
     Uporządkowanie ich liczby (grupowanie, wydzielanie ról, rozbicie klasy)
     jest przedmiotem późniejszych kroków, nie tego. Nie skracaj listy przez
     upychanie zależności w fabryki ani serwis-agregat "żeby ładniej wyglądało".
   - Zmiana jest behavior-preserving: te same wywołania, ta sama kolejność,
     ten sam wynik — zmienia się wyłącznie sposób, w jaki obiekt dostaje
     współpracowników.
   - Kryterium akceptacji kroku dla pojedynczej zależności: da się ją
     w teście podmienić na mock/stub bez dotykania kodu produkcyjnego.

3. **Sprzężenie z Etapem 1 (obowiązkowe).** Przeniesienie zależności do
   konstruktora zmienia sygnaturę konstruktora, więc testy z Etapu 1 przestaną
   się kompilować. To skutek zamierzony, nie regresja. Postępowanie:
   - Plan iteracji wymienia testy, które zaświecą na czerwono, i przeniesione
     zależności, które to spowodują.
   - Etap 2 aktualizuje w testach wyłącznie wywołania konstruktora
     i podstawia mock/stub za przeniesioną zależność (patrz "Zmiany w testach
     z Etapu 1"). Mocki: użyj tego, co jest w projekcie; jeśli nie ma — utwórz
     własne; **nie używaj frameworka Moq**.
   - Mock ma odtworzyć dotychczasowe zachowanie zależności. Test, który po
     podstawieniu mocka przechodzi tylko dzięki zmienionej asercji, nie jest
     dowodem zachowania. Gdy zachowania zależności nie da się ustalić z kodu —
     `user.input`, bez zgadywania.

4. **Krok jest iteracyjny.** Zależności może być dużo, więc Krok 3 wykonuje
   się w kilku przebiegach — nie próbuj przenieść wszystkiego naraz:
   - Podziel listę z punktu 1 na porcje (np. jedna klasa / jedna grupa
     powiązanych zależności na iterację). Podział trafia do pliku wynikowego.
   - Każda iteracja to pełny mały cykl: plan porcji → akceptacja → przeniesienie
     → aktualizacja testów → **uruchomienie testów na zielono** → potwierdzenie
     użytkownika.
   - Kolejna iteracja startuje dopiero na zielonych testach. Nie kumuluj
     nieprzeniesionych zależności ani czerwonych testów między iteracjami.
   - Log grupuje wpisy nagłówkiem `### Krok 3 — iteracja N`.
   - Krok kończy się, gdy lista z punktu 1 jest wyczerpana albo gdy pozostałe
     pozycje są jawnie odłożone decyzją użytkownika (wtedy trafiają do
     "Pozycji otwartych" z uzasadnieniem).

5. **Testy po kroku.** Po każdej iteracji i na zakończenie kroku uruchom testy.
   Czerwony test, którego przyczyną **nie** jest zmiana sygnatury konstruktora
   ani brak atrapy (czyli coś, czego nie zapowiedział plan iteracji), to
   regresja — obowiązuje punkt 4 "Reguły niezaliczonego testu": stop
   i zgłoszenie.

### Kolejne kroki *(do zdefiniowania)*

Podział wariantu "Refaktor" na dalsze pod-etapy (po kroku 3) — do ustalenia
w kolejnej iteracji.

### Reguła niezaliczonego testu (obowiązuje we wszystkich krokach)

1. Uruchom testy z Etapu 1 po każdej wprowadzonej zmianie cząstkowej oraz na
   zakończenie każdego kroku.
2. Test przestał przechodzić **z powodu zmiany nazwy** (krok 1) →
   aktualizacja nazw w teście przez Etap 2 (patrz krok 1, punkt 3).
3. Test przestał przechodzić **z powodu przeniesienia zależności do
   konstruktora** (krok 3) → aktualizacja testu i podstawienie mocka/stuba
   przez Etap 2 (patrz krok 3, punkt 3).
   Dotyczy wyłącznie zależności wymienionych w planie bieżącej iteracji kroku
   3 — zależność nieplanowana nie jest wymówką.
4. Test przestał przechodzić **z jakiegokolwiek innego powodu** → to sygnał
   regresji (zmiana zachowania tam, gdzie miało go nie być), nieakceptowalny
   wynik refaktoru. Zatrzymaj się i zgłoś to użytkownikowi zamiast kontynuować
   lub modyfikować test pod nowy wynik.
5. Kontynuuj małymi krokami (behavior-preserving), aż do zakończenia
   zaplanowanego kroku.

---

## Log Etapu 2 (`etap2-decisions-log.md`)

Osobny plik logu, analogicznie do Etapu 1 — nie mieszać z logiem konfiguracji
wstępnej, logiem Etapu 1 ani logiem orkiestratora. Te same zasady prowadzenia:
wyłącznie decyzje i wybory, żadnego kodu ani diffów, wpisy numerowane
chronologicznie, w miarę jak są podejmowane, **każdy wpis poprzedzony
znacznikiem daty i godziny** w formacie `yyyy-MM-dd; HH-mm-ss`. Wpisy
i nagłówki dopisuje wyłącznie skrypt `scripts/wspolne/wpis-logu.ps1` (patrz
"Znaczniki czasu w logach" w `orkiestrator.md`). Pierwszym wpisem każdego uruchomienia Etapu 2 jest
nagłówek `## Uruchomienie <znacznik>` z datą i godziną startu etapu.

Log musi jednoznacznie odnotować na starcie, który wariant został wybrany
(Refaktor / Zmiana logiki / Oba → zawężone do Zmiana logiki), ponieważ od
tego zależy, czy Etap 3 zostanie uruchomiony jako refaktoryzacja rezultatu.

Dodatkowo, dla wariantu "Refaktor": wpisy grupowane są nagłówkiem
`### Krok N` (pod-etap), a w krokach iteracyjnych (krok 3) —
`### Krok N — iteracja M`. **Każda zmiana jest odnotowana w logu tak czy
inaczej** — w szczególności każda zmiana w testach z Etapu 1 (które testy,
przez jaką zmianę w kodzie).

## Format wyjścia Etapu 2

Analogiczny do Etapu 1. Lokalizacja: katalog wynikowy (patrz "Katalog
wynikowy" w `orkiestrator.md`).

Struktura pliku/sekcji zależy od wyboru dokonanego w Pytaniu 1:

- **Opcja A (osobny plik na etap):** plan zapisywany w `etap2-plan.md`.
- **Opcja B (jeden zbiorczy plik):** plan to sekcja `## Etap 2` w pliku
  zbiorczym `refactor-plan.md`, dopisywana/rozbudowywana w miarę postępu
  kroków.
- **Dodatkowy plik szczegółowy per krok** (tylko jeśli użytkownik wybrał tę
  opcję w Pytaniu 1): po zakończeniu każdego kroku powstaje plik
  `etap2-krok-N-zmiany.md` ze szczegółowym opisem zmian tego kroku. Dla kroków
  iteracyjnych (krok 3) plik powstaje po każdej iteracji jako
  `etap2-krok-N-iteracja-M-zmiany.md`. Log pozostaje przy tym wyłącznie listą
  decyzji.

Struktura planu (niezależna od wyboru A/B), sekcje w kolejności:

1. **Zakres kroku** — wariant (Refaktor / Zmiana logiki), numer i nazwa kroku
   (dla kroków iteracyjnych także numer iteracji i porcja zależności objęta tą
   iteracją), objęte pliki/klasy/metody.
2. **Stan wyjściowy** — co konkretnie jest do poprawy w tym kroku (np. lista
   nazw do zmiany, lista magic numbers z miejscami wystąpienia).
3. **Planowane zmiany** — opis zmian, bez treści kodu.
4. **Wpływ na testy z Etapu 1** — które testy prawdopodobnie zaświecą się na
   czerwono i z jakiego powodu; jakie zmiany zostaną w nich wprowadzone.
5. **Pozycje otwarte** — to, czego LLM nie rozstrzygnął sam (np.
   nierozpoznane magic numbers czekające na wkład użytkownika).
6. **Do akceptacji** — jawne pytanie do użytkownika kończące fazę planowania
   tego kroku.

Zgodnie z wyborem obowiązkowym z Pytania 0 (brak zmian bez pliku `.md`), plan
kroku powstaje i jest akceptowany **przed** wprowadzeniem zmian w kodzie —
tak samo jak w Etapie 1.
