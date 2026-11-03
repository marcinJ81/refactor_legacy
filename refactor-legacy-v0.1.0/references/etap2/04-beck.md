# Katalog refaktoryzacji — Kent Beck
<!-- wersja-harnessu: 0.1.1 -->

Źródło: K. Beck, *Tidy First? A Personal Exercise in Empirical Software Design*, 2023.

Tidyings (porządki) to najmniejsze refaktoryzacje — zmieniają strukturę, nie zachowanie, i mają ułatwić następną zmianę. Zasada autora: porządki commituj osobno od zmian zachowania. Pominięte tu (opisane gdzie indziej): Guard Clauses (F18), Explaining Variables (F03), Explaining Constants (P12), Extract Helper (F01), Move Declaration and Initialization Together (F08), Delete Redundant Comments (P11).

---

## B01. Dead Code (Usuń martwy kod)

**Opis:** usuwasz kod, który się nie wykonuje — nieużywane metody, gałęzie niemożliwe do osiągnięcia, zakomentowane bloki; historia zostaje w Git.

```csharp
// Przed
public decimal CalculateFee(Order order)
{
    // decimal oldFee = order.Total * 0.02m; // stawka do 2019
    if (order.Total < 0m) // Order gwarantuje Total >= 0 w konstruktorze → gałąź martwa
    {
        return LegacyNegativeFee(order);
    }
    return order.Total * FeeRate;
}

private decimal LegacyNegativeFee(Order order)
{
    return 0m;
}

private decimal UnusedRounding(decimal value)
{
    return Math.Round(value, 4);
}

// Po
public decimal CalculateFee(Order order)
{
    return order.Total * FeeRate;
}
```

**Kiedy:** zawsze przed innymi refaktoryzacjami (mniej kodu do zrozumienia); w legacy MVC przed usunięciem sprawdź wywołania niewidoczne dla „Find Usages”: akcje wołane z jQuery/AJAX po URL, widoki Razor, refleksję, rejestracje DI, konfigurację (`web.config`).

---

## B02. Normalize Symmetries (Ujednolić symetrie)

**Opis:** ten sam problem rozwiązany w kodzie na kilka sposobów sprowadzasz do jednego zapisu, nie zmieniając zachowania.

```csharp
// Przed — trzy zapisy leniwej inicjalizacji w jednej klasie
public IList<Item> Items
{
    get
    {
        if (_items == null)
        {
            _items = new List<Item>();
        }
        return _items;
    }
}

public Settings Settings => _settings ?? (_settings = LoadSettings());

public PriceList Prices
{
    get { return _prices != null ? _prices : (_prices = LoadPrices()); }
}

// Po — jeden zapis
public IList<Item> Items => _items ?? (_items = new List<Item>());

public Settings Settings => _settings ?? (_settings = LoadSettings());

public PriceList Prices => _prices ?? (_prices = LoadPrices());
```

**Kiedy:** gdy różnice w zapisie sugerują różnice w zachowaniu, których nie ma — czytelnik traci czas na szukanie powodu; ujednolicaj **formę**, nie zachowanie (np. różna obsługa `default` w dwóch `switch` to różnica zachowania — zostaw).

---

## B03. New Interface, Old Implementation (Nowy interfejs, stara implementacja)

**Opis:** tworzysz metodę o wygodnym interfejsie, która na razie tylko woła starą implementację, i stopniowo przepinasz na nią wywołujących.

```csharp
// Stara metoda — wiele wywołań, niewygodna, ryzykowna do przepisania
public IList<Offer> GetOffers(int customerId, bool onlyActive, bool includeArchived, int top, string sort)
{
    // ... 120 linii
}

// Nowy interfejs, stara implementacja
public IList<Offer> GetActiveOffers(int customerId)
{
    return GetOffers(customerId, onlyActive: true, includeArchived: false, top: int.MaxValue, sort: "date");
}

// Wywołujący
IList<Offer> offers = _offerService.GetActiveOffers(customerId);
```

**Kiedy:** gdy wywołanie istniejącej metody jest skomplikowane, a jej zmiana teraz jest zbyt ryzykowna (różnica względem F04: F04 zmienia deklarację tej samej metody, B03 dodaje nowy punkt wejścia o innym kształcie, a stary zostaje).

---

## B04. Reading Order (Kolejność czytania)

**Opis:** przestawiasz elementy pliku w kolejności, w jakiej czytelnik chce je poznawać — publiczne API i główny przepływ najpierw, szczegóły niżej.

```csharp
// Przed — kolejność powstawania
public class OfferService
{
    private static decimal ApplyDiscount(decimal amount, decimal rate) { /* ... */ }
    private bool HasLines(Offer offer) { /* ... */ }
    public decimal CalculateGross(int offerId) { /* ... */ }
    private decimal LineValue(OfferLine line) { /* ... */ }
    public decimal CalculateNet(int offerId) { /* ... */ }
}

// Po — od ogółu do szczegółu
public class OfferService
{
    public decimal CalculateNet(int offerId) { /* ... */ }
    public decimal CalculateGross(int offerId) { /* ... */ }

    private bool HasLines(Offer offer) { /* ... */ }
    private decimal LineValue(OfferLine line) { /* ... */ }
    private static decimal ApplyDiscount(decimal amount, decimal rate) { /* ... */ }
}
```

**Kiedy:** gdy zrozumienie głównego przepływu wymaga skakania po pliku w górę i w dół (odpowiada zasadzie zstępującej P06).

---

## B05. Cohesion Order (Kolejność spójności)

**Opis:** elementy, które zmieniają się razem, stawiasz obok siebie (w pliku, w katalogu), zanim zdecydujesz o ich wydzieleniu.

```csharp
// Przed — metody rabatowe rozrzucone między metodami wysyłki i zapisu
public class OrderService
{
    public void Save(Order order) { /* ... */ }
    public decimal LoyaltyDiscount(Order order) { /* ... */ }
    public void Ship(Order order) { /* ... */ }
    public decimal VolumeDiscount(Order order) { /* ... */ }
    public void Cancel(Order order) { /* ... */ }
    public decimal SeasonalDiscount(Order order) { /* ... */ }
}

// Po — skupiska obok siebie; widać kandydata na OrderDiscounts (F13)
public class OrderService
{
    public void Save(Order order) { /* ... */ }
    public void Ship(Order order) { /* ... */ }
    public void Cancel(Order order) { /* ... */ }

    public decimal LoyaltyDiscount(Order order) { /* ... */ }
    public decimal VolumeDiscount(Order order) { /* ... */ }
    public decimal SeasonalDiscount(Order order) { /* ... */ }
}
```

**Kiedy:** gdy zmiana jednej funkcjonalności wymaga edycji w kilku odległych miejscach pliku; to tani krok przed F13, czasem wystarczający sam w sobie.

---

## B06. Explicit Parameters (Jawne parametry)

**Opis:** zamiast przekazywać „worek” danych (słownik, `FormCollection`, cały obiekt konfiguracji, `HttpContext.Current`) przekazujesz do metody dokładnie te wartości, których używa.

```csharp
// Przed
public decimal CalculateFee(FormCollection form)
{
    decimal amount = decimal.Parse(form["amount"], CultureInfo.InvariantCulture);
    var tier = (CustomerTier)Enum.Parse(typeof(CustomerTier), form["tier"]);
    return tier == CustomerTier.Premium ? amount * 0.01m : amount * 0.02m;
}

// Po — parsowanie na granicy (kontroler), logika z jawnymi parametrami
// kontroler
decimal amount = decimal.Parse(form["amount"], CultureInfo.InvariantCulture);
var tier = (CustomerTier)Enum.Parse(typeof(CustomerTier), form["tier"]);
decimal fee = _feeCalculator.CalculateFee(amount, tier);

// logika
private const decimal PremiumFeeRate = 0.01m;
private const decimal StandardFeeRate = 0.02m;

public decimal CalculateFee(decimal amount, CustomerTier tier)
{
    decimal rate = tier == CustomerTier.Premium ? PremiumFeeRate : StandardFeeRate;
    return amount * rate;
}
```

**Kiedy:** gdy z sygnatury nie da się wyczytać, czego metoda potrzebuje, a logika jest związana z formatem wejścia (formularz, sesja, `ViewBag`).

---

# Siatka zastosowania — Beck

| Sygnał w kodzie | Technika | Łączenie / sekwencja kroków | Nie stosuj, gdy |
|---|---|---|---|
| Nieużywane metody, zakomentowany kod, niemożliwe gałęzie | B01 | B01 → dowolna inna technika (zawsze pierwszy) | nie wykluczono wywołań przez URL/Razor/refleksję/DI |
| Ten sam problem zapisany na kilka sposobów | B02 | B02 → W08 (duplikacja staje się widoczna) → F01 | różnica zapisu oznacza różnicę zachowania |
| Niewygodna sygnatura, ryzykowna implementacja | B03 | B03 → przepinanie wywołujących → F04/F02 starej metody | jest jedno wywołanie — wtedy F04 |
| Trzeba skakać po pliku, by zrozumieć przepływ | B04 | B04 → K01 | plik jest krótki |
| Elementy zmieniane razem są rozrzucone | B05 | B05 → F13 → F14 | elementy nie zmieniają się razem |
| Metoda przyjmuje „worek” danych | B06 | B06 → F05 (gdy jawnych parametrów jest dużo) → F22 (gdy pojawia się flaga) | metoda faktycznie jest adapterem formatu wejścia |

## Kiedy porządkować (Beck)

- **Przed** zmianą — gdy porządek ułatwi zmianę (Beck: najpierw uczyń zmianę łatwą, potem wykonaj łatwą zmianę).
- **Po** zmianie — gdy wiesz już, jak kod powinien wyglądać.
- **Później** — gdy porządek nie dotyczy bieżącej pracy (zapisz w backlogu, np. jako „perełka kodu”).
- **Nigdy** — gdy kod się nie zmienia i nie jest czytany.
