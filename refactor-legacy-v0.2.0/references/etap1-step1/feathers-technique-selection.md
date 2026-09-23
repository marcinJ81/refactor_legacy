# Wybór techniki rozrywania zależności – tabela objaw → technika

Plik służy do **wyboru** techniki. Implementacja każdej techniki znajduje się w pliku `feathers-dependency-breaking-csharp.md`. Numery w nawiasach `[n]` odpowiadają numerom sekcji w tamtym pliku.

Źródło: Michael Feathers, *Working Effectively with Legacy Code* (2004), rozdziały 9, 10 i 25.

---

## 1. Tabela objaw → technika

| # | Objaw w kodzie | Sygnał rozpoznania | Pierwszy wybór | Zapasowa | Warunek / uwaga |
|---|---|---|---|---|---|
| A | Konstruktor tworzy zależność | `new X()` w konstruktorze, X to baza, sieć, plik, e-mail, zewnętrzny system | Parameterize Constructor [12] | Extract and Override Factory Method [6], Extract and Override Getter [7] | Stary konstruktor zostaje i deleguje do nowego. [6] tylko wtedy, gdy nadpisanie nie korzysta z pól podklasy. |
| B | Konstruktor tworzy wiele zależności, a zmiana sygnatury ma duży wpływ | wiele `new` w konstruktorze, wielu klientów konstruktora | Extract and Override Getter [7] | Supersede Instance Variable [20] | [20] to ostateczność: obiekt przez chwilę istnieje z prawdziwą zależnością. |
| C | Metoda tworzy zależność lokalnie | `new X()` wewnątrz metody | Parameterize Method [13] | Extract and Override Call [5] | Stara sygnatura zostaje i deleguje do nowej. |
| D | Pole lub parametr ma typ konkretnej klasy z naszego kodu, trudnej do utworzenia | typ bez interfejsu, konstruktor wymaga infrastruktury | Extract Interface [9] | Extract Implementer [8] | Interfejs zawiera tylko metody używane przez testowany kod. [8] tylko wtedy, gdy nazwa klasy jest właściwą nazwą abstrakcji. |
| E | Parametr ma typ frameworka lub zewnętrznej biblioteki | `HttpRequest`, `HttpContext`, `SqlDataReader`, klasa `sealed` | Adapt Parameter [1] | Primitivize Parameter [14] | Nie wydzielać interfejsu z typu, którego nie jesteśmy właścicielem. [14] to ostateczność. |
| F | Wywołanie statycznej metody **naszej** klasy | `NaszaKlasa.Metoda(...)` z efektem ubocznym | Introduce Instance Delegator [10] | Extract and Override Call [5] | Po [10] klient dostaje instancję przez konstruktor [12]. |
| G | Wywołanie statycznej metody **zewnętrznej** klasy | `DateTime.Now`, `File.*`, `Directory.*`, `Guid.NewGuid()`, statyczne API biblioteki | Replace Function with Function Pointer [17] | Extract and Override Call [5] | [17]: delegat `Func<>`/`Action<>` przekazany konstruktorem, domyślnie wskazujący oryginalną metodę. |
| H | Odwołanie do singletona | `X.Instance`, `X.GetInstance()` | Replace Global Reference with Getter [18] | Introduce Static Setter [11] | [11] to ostateczność: wymaga resetu po każdym teście i blokuje testy równoległe. |
| I | Odwołanie do globalnych danych statycznych | `static class` z polami lub konfiguracją, `ConfigurationManager.AppSettings` | Encapsulate Global References [3] | Replace Global Reference with Getter [18] | Po [3] obiekt ustawień wstrzyknąć przez [12]. |
| J | Efekt uboczny w środku testowanej logiki | wysyłka e-mail, zapis do pliku, `MessageBox`, logowanie do systemu zewnętrznego | Subclass and Override Method [19] | Extract and Override Call [5] | Metoda z efektem ubocznym: `protected virtual`. |
| K | Wiele zależności od UI lub platformy rozsianych po klasie | wiele wywołań UI w różnych metodach | Push Down Dependency [16] | Subclass and Override Method [19] | Zmiana hierarchii: większy wpływ, wymaga sprawdzenia wszystkich miejsc tworzenia klasy. |
| L | Czysta logika w klasie z ciężkimi zależnościami, wiele metod do przetestowania | metody nie używają pól z zależnościami | Pull Up Feature [15] | Break Out Method Object [2] | Zmiana hierarchii: większy wpływ. |
| M | Metoda nie korzysta ze stanu instancji, a konstruktor klasy jest problematyczny | brak odwołań do `this`, pól i metod instancyjnych | Expose Static Method [4] | Break Out Method Object [2] | Metoda staje się `public static`. Nie stosować, jeśli metoda korzysta z pól. |
| N | Długa metoda z wieloma zmiennymi lokalnymi i odwołaniami do pól | metoda ponad 50 linii, trudna do przetestowania w całości | Parameterize Method [13] | Break Out Method Object [2] | [13] wtedy, gdy blokujące zależności da się podać parametrami bez rozsadzenia sygnatury (stara sygnatura zostaje i deleguje). [2] wtedy, gdy metoda korzysta z wielu pól klasy — nowa klasa dostaje zależności przez konstruktor jako interfejsy, zmienne lokalne stają się jej polami. |
| O | Zależność od typu tworzonego przez `new()` w kodzie generycznym lub infrastrukturalnym | ten sam typ konkretny tworzony w wielu miejscach, brak możliwości wstrzyknięcia instancji | Parameterize Constructor [12] | Template Redefinition [21] | [21] jest rzadkie i należy do poziomu 3: stosować tylko wtedy, gdy wstrzyknięcie instancji przez [12] nie jest możliwe, z uzasadnieniem wymaganym dla poziomu 3. |

---

## 2. Kolejność preferencji

**Poziom 1: preferowane (szew jawny, bez dziedziczenia)**
- Parameterize Constructor [12]
- Parameterize Method [13]
- Extract Interface [9]
- Adapt Parameter [1]
- Replace Function with Function Pointer [17]

**Poziom 2: dopuszczalne (szew przez dziedziczenie lub zmianę struktury)**
- Extract and Override Call [5]
- Extract and Override Factory Method [6]
- Extract and Override Getter [7]
- Subclass and Override Method [19]
- Replace Global Reference with Getter [18]
- Introduce Instance Delegator [10]
- Expose Static Method [4]
- Encapsulate Global References [3]
- Break Out Method Object [2]
- Extract Implementer [8]
- Pull Up Feature [15]
- Push Down Dependency [16]

**Poziom 3: ostateczność (wymaga pisemnego uzasadnienia, dlaczego poziomy 1 i 2 nie są możliwe)**
- Supersede Instance Variable [20]
- Introduce Static Setter [11]
- Primitivize Parameter [14]
- Template Redefinition [21]

---

## 3. Warunki wstępne technik opartych na dziedziczeniu

Dotyczy: [5], [6], [7], [15], [16], [18], [19].

- Klasa nie może być `sealed`.
- Nadpisywana metoda musi być `virtual` lub `abstract`. Jeśli nie jest, zmiana na `protected virtual` jest częścią techniki.
- Metoda wirtualna wywołana z konstruktora wykonuje się przed konstruktorem podklasy. Nadpisanie nie może korzystać z pól podklasy.
- Jeśli któryś warunek nie jest spełniony, wybrać technikę z poziomu 1.

---

## 4. Reguły wyboru

- Jedna zależność = jedna technika = jedna propozycja zmiany.
- Jeśli kod ma kilka objawów, rozpoznać każdą zależność osobno i uszeregować propozycje od najmniejszego wpływu.
- Wybierać najniższy możliwy poziom preferencji. Przejście na wyższy poziom wymaga wskazania, który warunek blokuje technikę niższego poziomu.
- Technika nie może zmieniać zachowania kodu produkcyjnego. Istniejące publiczne sygnatury zostają i delegują do nowych.
- Jeśli objaw nie pasuje do żadnego wiersza tabeli, nie zgadywać techniki. Opisać zależność i zwrócić pytanie.
