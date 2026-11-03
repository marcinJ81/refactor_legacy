# Katalog refaktoryzacji — Martin Fowler
<!-- wersja-harnessu: 0.1.1 -->

Źródło: M. Fowler, *Refactoring*, 2nd ed., 2018; https://refactoring.com/catalog/

---

## F01. Extract Function (Wydziel funkcję) — dawniej Extract Method

**Opis:** fragment kodu, który da się nazwać intencją, przenosisz do osobnej metody, a w miejscu wywołania zostaje jej nazwa.

```csharp
// Przed
public void PrintOwing(Invoice invoice)
{
    PrintBanner();
    decimal outstanding = 0m;
    foreach (var line in invoice.Lines)
    {
        outstanding += line.Amount;
    }
    Console.WriteLine($"Customer: {invoice.CustomerName}");
    Console.WriteLine($"Amount: {outstanding}");
}

// Po
public void PrintOwing(Invoice invoice)
{
    PrintBanner();
    decimal outstanding = CalculateOutstanding(invoice);
    PrintDetails(invoice, outstanding);
}

private static decimal CalculateOutstanding(Invoice invoice)
{
    decimal result = 0m;
    foreach (var line in invoice.Lines)
    {
        result += line.Amount;
    }
    return result;
}

private static void PrintDetails(Invoice invoice, decimal outstanding)
{
    Console.WriteLine($"Customer: {invoice.CustomerName}");
    Console.WriteLine($"Amount: {outstanding}");
}
```

**Kiedy:** gdy musisz przeczytać fragment kodu, żeby zrozumieć *co* robi — wydziel go i nazwij to *co*.

---

## F02. Inline Function (Wchłoń funkcję)

**Opis:** zastępujesz wywołanie metody jej ciałem i usuwasz metodę, gdy nazwa nie mówi więcej niż treść.

```csharp
// Przed
public int GetRating(Driver driver)
{
    return MoreThanFiveLateDeliveries(driver) ? 2 : 1;
}

private static bool MoreThanFiveLateDeliveries(Driver driver)
{
    return driver.NumberOfLateDeliveries > 5;
}

// Po
public int GetRating(Driver driver)
{
    return driver.NumberOfLateDeliveries > 5 ? 2 : 1;
}
```

**Kiedy:** gdy metoda pośrednia nic nie wyjaśnia albo gdy chcesz zebrać źle pocięty kod w jedno miejsce, żeby pociąć go ponownie (W06).

---

## F03. Extract Variable (Wydziel zmienną)

**Opis:** część złożonego wyrażenia zapisujesz w zmiennej lokalnej o nazwie wyjaśniającej jej znaczenie.

```csharp
// Przed
return order.Quantity * order.ItemPrice
    - Math.Max(0, order.Quantity - 500) * order.ItemPrice * 0.05m
    + Math.Min(order.Quantity * order.ItemPrice * 0.1m, 100m);

// Po
decimal basePrice = order.Quantity * order.ItemPrice;
decimal quantityDiscount = Math.Max(0, order.Quantity - 500) * order.ItemPrice * 0.05m;
decimal shipping = Math.Min(basePrice * 0.1m, 100m);
return basePrice - quantityDiscount + shipping;
```

**Kiedy:** gdy wyrażenie jest złożone, a jego części mają znaczenie biznesowe, które warto nazwać lokalnie.

---

## F04. Change Function Declaration (Zmień deklarację funkcji) — Rename Method, Add/Remove Parameter

**Opis:** zmieniasz nazwę lub listę parametrów metody; przy wielu wywołaniach robisz to migracyjnie — nowa metoda, stara deleguje i jest oznaczona `[Obsolete]`, po przepięciu wywołujących stara znika.

```csharp
// Przed
public decimal Circum(decimal radius)
{
    return 2 * (decimal)Math.PI * radius;
}

// Krok migracyjny
[Obsolete("Use Circumference")]
public decimal Circum(decimal radius)
{
    return Circumference(radius);
}

public decimal Circumference(decimal radius)
{
    return 2 * (decimal)Math.PI * radius;
}

// Po przepięciu wszystkich wywołań — Circum usunięta
```

**Kiedy:** gdy nazwa nie oddaje intencji lub parametry nie pasują do tego, czego metoda faktycznie potrzebuje (uwaga: metody wywoływane z widoków Razor, JS/AJAX lub przez kontrakt WCF/Web API nie są widoczne w „Find Usages”).

---

## F05. Introduce Parameter Object (Wprowadź obiekt parametrów)

**Opis:** grupę parametrów, która zawsze wędruje razem, zastępujesz jednym obiektem, który może przejąć związane z nią reguły.

```csharp
// Przed
public IEnumerable<Reading> ReadingsOutsideRange(Station station, int min, int max)
{
    return station.Readings.Where(r => r.Temperature < min || r.Temperature > max);
}

// Po
public sealed class TemperatureRange
{
    public TemperatureRange(int min, int max)
    {
        if (min > max)
        {
            throw new ArgumentException("Min must not be greater than max.");
        }
        Min = min;
        Max = max;
    }

    public int Min { get; }
    public int Max { get; }

    public bool Contains(int value)
    {
        return value >= Min && value <= Max;
    }
}

public IEnumerable<Reading> ReadingsOutsideRange(Station station, TemperatureRange range)
{
    return station.Readings.Where(r => !range.Contains(r.Temperature));
}
```

**Kiedy:** gdy ta sama grupa parametrów (data clump — zlepek danych) pojawia się w kilku sygnaturach.

---

## F06. Replace Primitive with Object (Zastąp typ prosty obiektem)

**Opis:** wartość prostą (string, int, decimal) z regułami zastępujesz małą klasą (value object — obiekt wartości), która te reguły hermetyzuje.

```csharp
// Przed
public string Priority { get; set; } // "low", "normal", "high", "rush"

if (order.Priority == "high" || order.Priority == "rush")
{
    Expedite(order);
}

// Po
public sealed class Priority
{
    private static readonly string[] Levels = { "low", "normal", "high", "rush" };
    private readonly int _index;

    public Priority(string value)
    {
        _index = Array.IndexOf(Levels, value);
        if (_index < 0)
        {
            throw new ArgumentException("Unknown priority: " + value, nameof(value));
        }
    }

    public bool HigherThan(Priority other)
    {
        return _index > other._index;
    }

    public override string ToString()
    {
        return Levels[_index];
    }
}

if (order.Priority.HigherThan(new Priority("normal")))
{
    Expedite(order);
}
```

**Kiedy:** gdy wartość prosta ma walidację lub zachowanie rozsiane po kodzie (kwota + waluta, NIP, numer oferty, priorytet) — tzw. primitive obsession (obsesja typów prostych).

---

## F07. Replace Temp with Query (Zastąp zmienną tymczasową zapytaniem)

**Opis:** zmienną tymczasową liczoną z pól obiektu zastępujesz metodą/właściwością, dostępną w całej klasie.

```csharp
// Przed
public decimal GetPrice()
{
    decimal basePrice = _quantity * _itemPrice;
    decimal discountFactor = basePrice > 1000m ? 0.95m : 0.98m;
    return basePrice * discountFactor;
}

// Po
public decimal GetPrice()
{
    return BasePrice * DiscountFactor;
}

private decimal BasePrice => _quantity * _itemPrice;

private decimal DiscountFactor => BasePrice > 1000m ? 0.95m : 0.98m;
```

**Kiedy:** gdy zmienna tymczasowa blokuje Extract Function albo jest potrzebna w kilku metodach — tylko dla obliczeń tanich i bez efektów ubocznych.

---

## F08. Slide Statements (Przesuń instrukcje)

**Opis:** przesuwasz powiązane instrukcje tak, by stały obok siebie (deklaracja przy pierwszym użyciu).

```csharp
// Przed
var pricingPlan = RetrievePricingPlan();
var order = RetrieveOrder();
decimal baseCharge = pricingPlan.Base;
decimal discount;
decimal chargePerUnit = pricingPlan.Unit;
int units = order.Units;

// Po
var pricingPlan = RetrievePricingPlan();
decimal baseCharge = pricingPlan.Base;
decimal chargePerUnit = pricingPlan.Unit;

var order = RetrieveOrder();
int units = order.Units;
decimal discount;
```

**Kiedy:** przed Extract Function, gdy instrukcje jednego kroku są porozrzucane — sprawdź, czy przesuwane instrukcje nie mają efektów ubocznych zależnych od kolejności.

---

## F09. Split Loop (Rozdziel pętlę)

**Opis:** pętlę liczącą kilka niezależnych rzeczy dzielisz na kilka pętli, z których każda liczy jedną.

```csharp
// Przed
int youngest = int.MaxValue;
decimal totalSalary = 0m;
foreach (var person in people)
{
    if (person.Age < youngest)
    {
        youngest = person.Age;
    }
    totalSalary += person.Salary;
}

// Po
decimal totalSalary = 0m;
foreach (var person in people)
{
    totalSalary += person.Salary;
}

int youngest = int.MaxValue;
foreach (var person in people)
{
    if (person.Age < youngest)
    {
        youngest = person.Age;
    }
}
```

**Kiedy:** gdy jedna pętla robi kilka rzeczy i chcesz każdą wydzielić osobno; koszt drugiego przejścia mierz, nie zakładaj (wyjątek: `IQueryable`/`IEnumerable` z leniwym odczytem z bazy — drugie przejście = drugie zapytanie).

---

## F10. Replace Loop with Pipeline (Zastąp pętlę potokiem — LINQ)

**Opis:** pętlę filtrującą/mapującą/agregującą zastępujesz łańcuchem operacji LINQ.

```csharp
// Przed
var cities = new List<string>();
foreach (var office in offices)
{
    if (office.Country == "PL")
    {
        cities.Add(office.City);
    }
}

// Po
var cities = offices
    .Where(office => office.Country == "PL")
    .Select(office => office.City)
    .ToList();
```

**Kiedy:** gdy pętla to czyste filtrowanie, mapowanie lub agregacja; nie stosuj, gdy pętla ma efekty uboczne lub gdy zmiana na `IQueryable` zmieni generowany SQL.

---

## F11. Split Phase (Rozdziel na fazy)

**Opis:** metodę wykonującą dwa różne etapy (np. parsowanie i obliczenie) dzielisz na dwie fazy połączone pośrednią strukturą danych.

```csharp
// Przed
public decimal PriceOrder(string orderLine, PriceList priceList)
{
    string[] parts = orderLine.Split(';');
    string productCode = parts[0];
    int quantity = int.Parse(parts[1], CultureInfo.InvariantCulture);
    decimal price = priceList.PriceOf(productCode) * quantity;
    return quantity > 100 ? price * 0.9m : price;
}

// Po
public decimal PriceOrder(string orderLine, PriceList priceList)
{
    OrderRequest request = ParseOrderLine(orderLine);
    return CalculatePrice(request, priceList);
}

private static OrderRequest ParseOrderLine(string orderLine)
{
    string[] parts = orderLine.Split(';');
    return new OrderRequest(parts[0], int.Parse(parts[1], CultureInfo.InvariantCulture));
}

private static decimal CalculatePrice(OrderRequest request, PriceList priceList)
{
    decimal price = priceList.PriceOf(request.ProductCode) * request.Quantity;
    return request.Quantity > 100 ? price * 0.9m : price;
}

public sealed class OrderRequest
{
    public OrderRequest(string productCode, int quantity)
    {
        ProductCode = productCode;
        Quantity = quantity;
    }

    public string ProductCode { get; }
    public int Quantity { get; }
}
```

**Kiedy:** gdy metoda wykonuje kolejno dwa etapy (odczyt + przetwarzanie, parsowanie + reguły) i druga faza nie musi znać formatu pierwszej.

---

## F12. Replace Function with Command (Zastąp funkcję obiektem polecenia)

**Opis:** długą metodę z wieloma zmiennymi lokalnymi przenosisz do osobnej klasy, w której zmienne lokalne stają się polami, co pozwala wydzielać metody bez parametrów.

```csharp
// Przed
public decimal Score(Candidate candidate, MedicalExam exam, ScoringGuide guide)
{
    decimal result = 0m;
    int healthLevel = 0;
    bool highMedicalRiskFlag = false;

    if (exam.IsSmoker)
    {
        healthLevel += 10;
        highMedicalRiskFlag = true;
    }

    if (guide.StateWithLowCertification(candidate.OriginState))
    {
        result -= 5m;
    }

    // ... kolejne 150 linii operujących na result, healthLevel, highMedicalRiskFlag

    result -= Math.Max(healthLevel - 5, 0);
    return result;
}

// Po
public decimal Score(Candidate candidate, MedicalExam exam, ScoringGuide guide)
{
    return new Scorer(candidate, exam, guide).Execute();
}

internal sealed class Scorer
{
    private readonly Candidate _candidate;
    private readonly MedicalExam _exam;
    private readonly ScoringGuide _guide;

    private decimal _result;
    private int _healthLevel;
    private bool _highMedicalRiskFlag;

    public Scorer(Candidate candidate, MedicalExam exam, ScoringGuide guide)
    {
        _candidate = candidate;
        _exam = exam;
        _guide = guide;
    }

    public decimal Execute()
    {
        _result = 0m;
        _healthLevel = 0;
        _highMedicalRiskFlag = false;

        ScoreSmoking();
        ScoreCertification();
        // ... kolejne wydzielone kroki

        _result -= Math.Max(_healthLevel - 5, 0);
        return _result;
    }

    private void ScoreSmoking()
    {
        if (!_exam.IsSmoker)
        {
            return;
        }
        _healthLevel += 10;
        _highMedicalRiskFlag = true;
    }

    private void ScoreCertification()
    {
        if (_guide.StateWithLowCertification(_candidate.OriginState))
        {
            _result -= 5m;
        }
    }
}
```

**Kiedy:** gdy Extract Function na długiej metodzie daje metody z 4+ parametrami lub parametrami `ref`/`out`, bo fragmenty modyfikują wspólne zmienne lokalne.

---

## F13. Extract Class (Wydziel klasę)

**Opis:** podzbiór pól i metod, które zmieniają się razem, przenosisz do nowej klasy.

```csharp
// Przed
public class Person
{
    public string Name { get; set; }
    public string OfficeAreaCode { get; set; }
    public string OfficeNumber { get; set; }

    public string TelephoneNumber => $"({OfficeAreaCode}) {OfficeNumber}";
}

// Po
public class Person
{
    public string Name { get; set; }
    public TelephoneNumber OfficeTelephone { get; } = new TelephoneNumber();
}

public class TelephoneNumber
{
    public string AreaCode { get; set; }
    public string Number { get; set; }

    public override string ToString()
    {
        return $"({AreaCode}) {Number}";
    }
}
```

**Kiedy:** gdy grupa pól i metod nie potrzebuje reszty klasy (sygnał: wspólny prefiks nazw, rozłączne skupiska w szkicu W07).

---

## F14. Move Function (Przenieś funkcję)

**Opis:** metodę przenosisz do klasy, której danych używa najczęściej (feature envy — zazdrość o cechy).

```csharp
// Przed
public class Account
{
    public AccountType Type { get; set; }
    public int DaysOverdrawn { get; set; }

    public decimal OverdraftCharge()
    {
        if (Type.IsPremium)
        {
            const decimal baseCharge = 10m;
            return DaysOverdrawn <= 7 ? baseCharge : baseCharge + (DaysOverdrawn - 7) * 0.85m;
        }
        return DaysOverdrawn * 1.75m;
    }
}

// Po
public class AccountType
{
    public bool IsPremium { get; set; }

    public decimal OverdraftCharge(int daysOverdrawn)
    {
        if (IsPremium)
        {
            const decimal baseCharge = 10m;
            return daysOverdrawn <= 7 ? baseCharge : baseCharge + (daysOverdrawn - 7) * 0.85m;
        }
        return daysOverdrawn * 1.75m;
    }
}

public class Account
{
    public AccountType Type { get; set; }
    public int DaysOverdrawn { get; set; }

    public decimal OverdraftCharge()
    {
        return Type.OverdraftCharge(DaysOverdrawn);
    }
}
```

**Kiedy:** gdy metoda częściej sięga po dane innej klasy niż własnej, albo gdy zmiana w klasie B zawsze wymusza zmianę tej metody w klasie A.

---

## F15. Encapsulate Collection (Hermetyzuj kolekcję)

**Opis:** publiczną modyfikowalną kolekcję zastępujesz widokiem tylko do odczytu oraz metodami dodawania/usuwania pilnującymi reguł.

```csharp
// Przed
public class Order
{
    public List<OrderLine> Lines { get; set; } = new List<OrderLine>();
}

order.Lines.Add(line); // nikt nie pilnuje reguł

// Po
public class Order
{
    private readonly List<OrderLine> _lines = new List<OrderLine>();

    public IReadOnlyCollection<OrderLine> Lines => _lines.AsReadOnly();

    public void AddLine(OrderLine line)
    {
        if (line == null)
        {
            throw new ArgumentNullException(nameof(line));
        }
        _lines.Add(line);
    }

    public void RemoveLine(OrderLine line)
    {
        _lines.Remove(line);
    }
}
```

**Kiedy:** gdy zmiana zawartości kolekcji wymaga reguł lub aktualizacji innego stanu (uwaga: EF6 nie mapuje prywatnej kolekcji bez dodatkowej konfiguracji — przy encjach EF sprawdź mapowanie przed zmianą).

---

## F16. Decompose Conditional (Rozbij warunek)

**Opis:** warunek i każdą gałąź wydzielasz do metod o nazwach opisujących regułę biznesową.

```csharp
// Przed
if (date >= _summerStart && date <= _summerEnd)
{
    charge = quantity * _summerRate;
}
else
{
    charge = quantity * _regularRate + _regularServiceCharge;
}

// Po
charge = IsSummer(date) ? SummerCharge(quantity) : RegularCharge(quantity);

private bool IsSummer(DateTime date)
{
    return date >= _summerStart && date <= _summerEnd;
}

private decimal SummerCharge(int quantity)
{
    return quantity * _summerRate;
}

private decimal RegularCharge(int quantity)
{
    return quantity * _regularRate + _regularServiceCharge;
}
```

**Kiedy:** gdy zrozumienie warunku lub gałęzi wymaga czytania kodu zamiast nazwy reguły.

---

## F17. Consolidate Conditional Expression (Scal wyrażenia warunkowe)

**Opis:** kilka warunków dających ten sam wynik łączysz w jedno wyrażenie i wydzielasz je pod nazwą reguły.

```csharp
// Przed
public decimal DisabilityAmount(Employee employee)
{
    if (employee.Seniority < 2)
    {
        return 0m;
    }
    if (employee.MonthsDisabled > 12)
    {
        return 0m;
    }
    if (employee.IsPartTime)
    {
        return 0m;
    }
    return CalculateDisability(employee);
}

// Po
public decimal DisabilityAmount(Employee employee)
{
    if (!IsEligibleForDisability(employee))
    {
        return 0m;
    }
    return CalculateDisability(employee);
}

private static bool IsEligibleForDisability(Employee employee)
{
    return employee.Seniority >= 2
        && employee.MonthsDisabled <= 12
        && !employee.IsPartTime;
}
```

**Kiedy:** gdy kilka warunków to w istocie jedna reguła; nie scalaj, gdy są to niezależne reguły zmieniające się z różnych powodów.

---

## F18. Replace Nested Conditional with Guard Clauses (Zastąp zagnieżdżone warunki klauzulami strażniczymi)

**Opis:** przypadki szczególne obsługujesz wczesnym `return`/`throw` na początku metody, zostawiając normalny przepływ bez zagnieżdżeń.

```csharp
// Przed
public decimal GetPayAmount(Employee employee)
{
    decimal result;
    if (employee.IsSeparated)
    {
        result = 0m;
    }
    else
    {
        if (employee.IsRetired)
        {
            result = 0m;
        }
        else
        {
            result = CalculateNormalPay(employee);
        }
    }
    return result;
}

// Po
public decimal GetPayAmount(Employee employee)
{
    if (employee.IsSeparated)
    {
        return 0m;
    }
    if (employee.IsRetired)
    {
        return 0m;
    }
    return CalculateNormalPay(employee);
}
```

**Kiedy:** gdy jedna gałąź to normalny przepływ, a pozostałe to przypadki wyjątkowe.

---

## F19. Replace Conditional with Polymorphism (Zastąp warunek polimorfizmem)

**Opis:** `switch`/`if` po typie zastępujesz hierarchią klas, w której każda podklasa nadpisuje zachowanie swojego przypadku.

```csharp
// Przed
public decimal Speed(Bird bird)
{
    switch (bird.Type)
    {
        case BirdType.European:
            return 35m;
        case BirdType.African:
            return 40m - 2 * bird.NumberOfCoconuts;
        case BirdType.NorwegianBlue:
            return bird.IsNailed ? 0m : 10m + bird.Voltage / 10m;
        default:
            throw new ArgumentOutOfRangeException(nameof(bird));
    }
}

// Po
public abstract class Bird
{
    public abstract decimal Speed { get; }
}

public sealed class EuropeanSwallow : Bird
{
    public override decimal Speed => 35m;
}

public sealed class AfricanSwallow : Bird
{
    private readonly int _numberOfCoconuts;

    public AfricanSwallow(int numberOfCoconuts)
    {
        _numberOfCoconuts = numberOfCoconuts;
    }

    public override decimal Speed => 40m - 2 * _numberOfCoconuts;
}

public sealed class NorwegianBlueParrot : Bird
{
    private readonly bool _isNailed;
    private readonly decimal _voltage;

    public NorwegianBlueParrot(bool isNailed, decimal voltage)
    {
        _isNailed = isNailed;
        _voltage = voltage;
    }

    public override decimal Speed => _isNailed ? 0m : 10m + _voltage / 10m;
}
```

**Kiedy:** gdy ten sam `switch` po typie powtarza się w kilku metodach, a typ jest stały przez życie obiektu; pojedynczy, stabilny `switch` zostaw (KISS) — wybór względem K03/K04/K06 w `06-siatka-globalna.md`.

---

## F20. Introduce Special Case (Wprowadź przypadek szczególny) — Null Object

**Opis:** powtarzane sprawdzanie przypadku szczególnego (np. `null`, „klient nieznany”) zastępujesz obiektem, który ten przypadek reprezentuje i ma domyślne zachowanie.

```csharp
// Przed (powtarzane w wielu miejscach)
string name = customer == null ? "occupant" : customer.Name;
BillingPlan plan = customer == null ? BillingPlan.Basic : customer.BillingPlan;

// Po
public class Customer
{
    private readonly string _name;
    private readonly BillingPlan _billingPlan;

    public Customer(string name, BillingPlan billingPlan)
    {
        _name = name;
        _billingPlan = billingPlan;
    }

    protected Customer()
    {
    }

    public virtual string Name => _name;
    public virtual BillingPlan BillingPlan => _billingPlan;
    public virtual bool IsUnknown => false;
}

public sealed class UnknownCustomer : Customer
{
    public override string Name => "occupant";
    public override BillingPlan BillingPlan => BillingPlan.Basic;
    public override bool IsUnknown => true;
}

// repozytorium zwraca new UnknownCustomer() zamiast null
string name = customer.Name;
BillingPlan plan = customer.BillingPlan;
```

**Kiedy:** gdy wiele miejsc sprawdza ten sam przypadek szczególny i reaguje tak samo; nie stosuj, gdy `null` znaczy co innego w różnych miejscach.

---

## F21. Separate Query from Modifier (Oddziel zapytanie od modyfikatora) — CQS

**Opis:** metodę, która zwraca wartość i jednocześnie zmienia stan, dzielisz na zapytanie (bez efektów ubocznych) i polecenie (bez wartości zwracanej).

```csharp
// Przed
public string FindAndAlertMiscreant(IEnumerable<string> people)
{
    foreach (var person in people)
    {
        if (person == "Don" || person == "John")
        {
            SetOffAlarms();
            return person;
        }
    }
    return string.Empty;
}

// Po
public string FindMiscreant(IEnumerable<string> people)
{
    return people.FirstOrDefault(IsMiscreant) ?? string.Empty;
}

public void AlertForMiscreant(IEnumerable<string> people)
{
    if (FindMiscreant(people).Length > 0)
    {
        SetOffAlarms();
    }
}

private static bool IsMiscreant(string person)
{
    return person == "Don" || person == "John";
}
```

**Kiedy:** gdy wywołujący nie może bezpiecznie zapytać o wartość bez wywołania efektu ubocznego (wyjątki idiomatyczne: `Stack.Pop`, wzorzec `TryXxx`).

---

## F22. Remove Flag Argument (Usuń argument-flagę)

**Opis:** parametr `bool` wybierający gałąź logiki zastępujesz osobnymi metodami o jawnych nazwach.

```csharp
// Przed
public DateTime DeliveryDate(Order order, bool isRush)
{
    if (isRush)
    {
        return order.PlacedOn.AddDays(1);
    }
    return order.PlacedOn.AddDays(3);
}

DateTime date = DeliveryDate(order, true); // co znaczy true?

// Po
public DateTime RushDeliveryDate(Order order)
{
    return order.PlacedOn.AddDays(1);
}

public DateTime RegularDeliveryDate(Order order)
{
    return order.PlacedOn.AddDays(3);
}
```

**Kiedy:** gdy wywołujący przekazuje literał `true`/`false`; gdy wartość flagi pochodzi z danych (formularz, baza), rozważ enum zamiast dwóch metod.

---

# Siatka zastosowania — Fowler

| Sygnał w kodzie | Technika | Łączenie / sekwencja kroków | Nie stosuj, gdy |
|---|---|---|---|
| Fragment metody wymaga komentarza lub czytania, by zrozumieć *co* robi | F01 | F08 → F01; gdy zmienne blokują: F07 → F01 | nazwa byłaby powtórzeniem treści kodu |
| Metoda pośrednia nic nie wyjaśnia; zły podział metod | F02 | F02 → F08 → F01 (ponowne cięcie, W06) | metoda jest `virtual`/`override` |
| Złożone wyrażenie z częściami o znaczeniu biznesowym | F03 | F03 → F07 (gdy wartość potrzebna w kilku metodach) | wyrażenie jest trywialne |
| Nazwa lub parametry nie pasują do intencji | F04 | nowa metoda + `[Obsolete]` stara → przepięcie → usunięcie | to publiczny kontrakt zewnętrzny (WCF, Web API) — wtedy wersjonowanie |
| Ta sama grupa 2–4 parametrów w wielu sygnaturach | F05 | F05 → F14 (reguły do nowego obiektu) | parametry występują razem przypadkowo |
| `string`/`int`/`decimal` z walidacją rozsianą po kodzie | F06 | F06 → F14 (walidacje do obiektu wartości) | wartość nie ma reguł |
| Zmienna tymczasowa blokuje wydzielenie metody | F07 | F07 → F01 | obliczenie kosztowne lub z efektami ubocznymi |
| Instrukcje jednego kroku są rozrzucone | F08 | F08 → F01 | kolejność ma znaczenie (efekty uboczne) |
| Pętla liczy kilka niezależnych rzeczy | F09 | F09 → F10 → F01 | drugie przejście = drugie zapytanie do bazy |
| Pętla filtruje / mapuje / agreguje | F10 | F09 → F10 | pętla ma efekty uboczne; zmiana na `IQueryable` zmienia SQL |
| Metoda: parsuj + licz, czytaj + przetwarzaj | F11 | F11 → F01 dla każdej fazy → F13 | jedna z faz jest trywialna |
| Długa metoda, wiele zmiennych lokalnych modyfikowanych przez fragmenty | F12 | F12 → F01 wewnątrz klasy polecenia → W06 | F01 daje metody z ≤ 3 parametrami |
| Grupa pól z tym samym prefiksem; rozłączne skupiska metod | F13 | B05 → F13 → F14 | klasa jest mała i spójna |
| Metoda używa głównie danych innej klasy | F14 | F01 (wydziel zazdrosny fragment) → F14 → F02 (zbędny delegat) | metoda celowo łączy dane kilku klas (orkiestracja) |
| Publiczna modyfikowalna kolekcja | F15 | F15 → F14 (reguły dodawania do właściciela) | encja EF6 bez sprawdzonego mapowania |
| Warunek/gałąź wymaga czytania kodu | F16 | F16 → F17 → F18 | warunek jest oczywisty |
| Kilka warunków → ten sam wynik | F17 | F17 → F16 (nazwa reguły) | warunki to niezależne reguły |
| Zagnieżdżone `if/else`, zmienna `result` | F18 | F17 → F18 | obie gałęzie są równorzędne (wtedy `if/else`) |
| Ten sam `switch` po typie w kilku miejscach | F19 | F16 → F01 → F19 | pojedynczy, stabilny `switch` |
| Powtarzane sprawdzanie `null` / przypadku szczególnego | F20 | F20 → F02 (usunięcie sprawdzeń) | `null` ma różne znaczenia w różnych miejscach |
| Metoda zwraca wartość i zmienia stan | F21 | F21 → F01 / F02 | idiomy `TryXxx`, `Pop` |
| Literał `true`/`false` w wywołaniu | F22 | F04 (migracja) → F22 | flaga pochodzi z danych — rozważ enum |

## Pary odwrotne (cofanie kroku)

- F01 ↔ F02
- F03 ↔ Inline Variable (Wchłoń zmienną)
- F13 ↔ Inline Class (Wchłoń klasę)
- F14 ↔ F14 w przeciwnym kierunku

## Warunki wstępne

- F19 wymaga najpierw F16/F01 — każda gałąź jako osobna metoda.
- F10 zwykle wymaga najpierw F09.
- F01 na długiej metodzie często wymaga najpierw F07 lub F08.
- F14 dla grupy parametrów wymaga najpierw F05.
