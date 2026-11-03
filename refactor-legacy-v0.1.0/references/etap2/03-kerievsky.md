# Katalog refaktoryzacji — Joshua Kerievsky
<!-- wersja-harnessu: 0.1.1 -->

Źródło: J. Kerievsky, *Refactoring to Patterns*, 2004.

Zasada autora: do wzorca dochodzi się serią małych refaktoryzacji, gdy kod tego wymaga — nie projektuje się go z góry. Każda technika z tego pliku ma też wariant „odwrotny” (odejście od wzorca), gdy wzorzec okazuje się zbędny.

---

## K01. Compose Method (Komponuj metodę)

**Opis:** przekształcasz metodę tak, by składała się z wywołań metod na tym samym poziomie abstrakcji i czytała się jak opis algorytmu — to docelowy kształt metody, osiągany serią F01/F03/F18 (F01 to pojedynczy ruch, K01 to wynik).

```csharp
// Przed
public void Add(object element)
{
    if (!_readOnly)
    {
        int newSize = _size + 1;
        if (newSize > _elements.Length)
        {
            var newElements = new object[_elements.Length + 10];
            for (int i = 0; i < _size; i++)
            {
                newElements[i] = _elements[i];
            }
            _elements = newElements;
        }
        _elements[_size++] = element;
    }
}

// Po
private const int GrowthIncrement = 10;

public void Add(object element)
{
    if (_readOnly)
    {
        return;
    }
    if (AtCapacity)
    {
        Grow();
    }
    AddElement(element);
}

private bool AtCapacity => _size + 1 > _elements.Length;

private void Grow()
{
    var newElements = new object[_elements.Length + GrowthIncrement];
    Array.Copy(_elements, newElements, _size);
    _elements = newElements;
}

private void AddElement(object element)
{
    _elements[_size] = element;
    _size++;
}
```

**Kiedy:** gdy metoda miesza poziomy szczegółowości (reguła biznesowa obok pętli kopiującej tablicę) i nie da się jej zrozumieć w kilka sekund.

---

## K02. Chain Constructors (Połącz konstruktory w łańcuch)

**Opis:** konstruktory powtarzające inicjalizację wywołują jeden konstruktor zbiorczy (catch-all constructor) przez `: this(...)`.

```csharp
// Przed
public class Loan
{
    private readonly ICapitalStrategy _strategy;
    private readonly decimal _commitment;
    private readonly int _riskRating;
    private readonly DateTime _maturity;
    private readonly DateTime? _expiry;

    public Loan(decimal commitment, int riskRating, DateTime maturity)
    {
        _commitment = commitment;
        _riskRating = riskRating;
        _maturity = maturity;
        _strategy = new TermLoanStrategy();
    }

    public Loan(decimal commitment, int riskRating, DateTime maturity, DateTime expiry)
    {
        _commitment = commitment;
        _riskRating = riskRating;
        _maturity = maturity;
        _expiry = expiry;
        _strategy = new RevolvingTermStrategy();
    }
}

// Po
public class Loan
{
    private readonly ICapitalStrategy _strategy;
    private readonly decimal _commitment;
    private readonly int _riskRating;
    private readonly DateTime _maturity;
    private readonly DateTime? _expiry;

    public Loan(decimal commitment, int riskRating, DateTime maturity)
        : this(new TermLoanStrategy(), commitment, riskRating, maturity, null)
    {
    }

    public Loan(decimal commitment, int riskRating, DateTime maturity, DateTime expiry)
        : this(new RevolvingTermStrategy(), commitment, riskRating, maturity, expiry)
    {
    }

    private Loan(ICapitalStrategy strategy, decimal commitment, int riskRating, DateTime maturity, DateTime? expiry)
    {
        _strategy = strategy;
        _commitment = commitment;
        _riskRating = riskRating;
        _maturity = maturity;
        _expiry = expiry;
    }
}
```

**Kiedy:** gdy kilka konstruktorów powtarza ten sam kod; także gdy dodajesz konstruktor z zależnościami, a stary (bezparametrowy) musi zostać dla istniejących wywołań.

---

## K03. Replace Conditional Logic with Strategy (Zastąp logikę warunkową strategią)

**Opis:** warianty algorytmu wybierane warunkiem przenosisz do osobnych klas strategii, przekazywanych do obiektu (kompozycja — w odróżnieniu od dziedziczenia w F19).

```csharp
// Przed
public decimal ShippingCost(Parcel parcel)
{
    if (parcel.Carrier == Carrier.Post)
    {
        return 12m + parcel.WeightKg * 1.5m;
    }
    if (parcel.Carrier == Carrier.Courier)
    {
        return parcel.WeightKg <= 5m ? 20m : 20m + (parcel.WeightKg - 5m) * 3m;
    }
    if (parcel.Carrier == Carrier.Pickup)
    {
        return 0m;
    }
    throw new NotSupportedException(parcel.Carrier.ToString());
}

// Po
public interface IShippingCostStrategy
{
    decimal Calculate(Parcel parcel);
}

public sealed class PostShipping : IShippingCostStrategy
{
    private const decimal BaseFee = 12m;
    private const decimal FeePerKg = 1.5m;

    public decimal Calculate(Parcel parcel)
    {
        return BaseFee + parcel.WeightKg * FeePerKg;
    }
}

public sealed class CourierShipping : IShippingCostStrategy
{
    private const decimal BaseFee = 20m;
    private const decimal IncludedWeightKg = 5m;
    private const decimal FeePerExtraKg = 3m;

    public decimal Calculate(Parcel parcel)
    {
        if (parcel.WeightKg <= IncludedWeightKg)
        {
            return BaseFee;
        }
        return BaseFee + (parcel.WeightKg - IncludedWeightKg) * FeePerExtraKg;
    }
}

public sealed class PickupShipping : IShippingCostStrategy
{
    public decimal Calculate(Parcel parcel)
    {
        return 0m;
    }
}

public sealed class ShippingCalculator
{
    private readonly IReadOnlyDictionary<Carrier, IShippingCostStrategy> _strategies;

    public ShippingCalculator(IReadOnlyDictionary<Carrier, IShippingCostStrategy> strategies)
    {
        _strategies = strategies;
    }

    public decimal ShippingCost(Parcel parcel)
    {
        IShippingCostStrategy strategy;
        if (!_strategies.TryGetValue(parcel.Carrier, out strategy))
        {
            throw new NotSupportedException(parcel.Carrier.ToString());
        }
        return strategy.Calculate(parcel);
    }
}
```

**Kiedy:** gdy warianty obliczenia rosną, mają własne stałe i reguły, a obiekt, który ich używa (np. encja EF), nie powinien stawać się hierarchią podklas.

---

## K04. Replace State-Altering Conditionals with State (Zastąp warunki zmieniające stan wzorcem Stan)

**Opis:** przejścia między stanami rozsiane w warunkach wielu metod przenosisz do klas stanów, z których każda zna dozwolone przejścia.

```csharp
// Przed
public class Offer
{
    public OfferStatus Status { get; private set; } = OfferStatus.Draft;

    public void Submit()
    {
        if (Status != OfferStatus.Draft)
        {
            throw new InvalidOperationException("Cannot submit in status " + Status);
        }
        Status = OfferStatus.Submitted;
    }

    public void Approve()
    {
        if (Status != OfferStatus.Submitted)
        {
            throw new InvalidOperationException("Cannot approve in status " + Status);
        }
        Status = OfferStatus.Approved;
    }

    public void Reject()
    {
        if (Status != OfferStatus.Submitted)
        {
            throw new InvalidOperationException("Cannot reject in status " + Status);
        }
        Status = OfferStatus.Rejected;
    }
}

// Po
internal abstract class OfferState
{
    public abstract OfferStatus Status { get; }

    public virtual OfferState Submit() => throw Invalid("submit");
    public virtual OfferState Approve() => throw Invalid("approve");
    public virtual OfferState Reject() => throw Invalid("reject");

    private InvalidOperationException Invalid(string action)
    {
        return new InvalidOperationException("Cannot " + action + " in status " + Status);
    }
}

internal sealed class DraftState : OfferState
{
    public override OfferStatus Status => OfferStatus.Draft;
    public override OfferState Submit() => new SubmittedState();
}

internal sealed class SubmittedState : OfferState
{
    public override OfferStatus Status => OfferStatus.Submitted;
    public override OfferState Approve() => new ApprovedState();
    public override OfferState Reject() => new RejectedState();
}

internal sealed class ApprovedState : OfferState
{
    public override OfferStatus Status => OfferStatus.Approved;
}

internal sealed class RejectedState : OfferState
{
    public override OfferStatus Status => OfferStatus.Rejected;
}

public class Offer
{
    private OfferState _state = new DraftState();

    public OfferStatus Status => _state.Status;

    public void Submit()
    {
        _state = _state.Submit();
    }

    public void Approve()
    {
        _state = _state.Approve();
    }

    public void Reject()
    {
        _state = _state.Reject();
    }
}
```

**Kiedy:** gdy dodanie stanu lub przejścia wymaga zmian w wielu metodach, a zachowanie zależne od stanu rośnie; przy 3–4 stanach i prostych regułach wystarczą nazwane predykaty (F16) — Kerievsky sam ostrzega przed nadużywaniem wzorców.

---

## K05. Form Template Method (Utwórz metodę szablonową)

**Opis:** klasy wykonujące te same kroki w tej samej kolejności, różniące się szczegółami kroków, sprowadzasz do klasy bazowej z metodą szablonową i abstrakcyjnymi krokami.

```csharp
// Przed
public class SalesReport
{
    public string Generate(Period period)
    {
        IReadOnlyList<Sale> sales = _salesRepository.Load(period);
        var sb = new StringBuilder();
        sb.AppendLine("SALES " + period);
        foreach (var sale in sales)
        {
            sb.AppendLine(sale.Product + ";" + sale.Amount);
        }
        sb.AppendLine("Total: " + sales.Sum(sale => sale.Amount));
        return sb.ToString();
    }
}

public class CostReport
{
    public string Generate(Period period)
    {
        IReadOnlyList<Cost> costs = _costRepository.Load(period);
        var sb = new StringBuilder();
        sb.AppendLine("COSTS " + period);
        foreach (var cost in costs)
        {
            sb.AppendLine(cost.Category + ";" + cost.Value);
        }
        sb.AppendLine("Total: " + costs.Sum(cost => cost.Value));
        return sb.ToString();
    }
}

// Po
public abstract class PeriodReport<TRow>
{
    public string Generate(Period period)
    {
        IReadOnlyList<TRow> rows = Load(period);
        var sb = new StringBuilder();
        sb.AppendLine(Title + " " + period);
        foreach (var row in rows)
        {
            sb.AppendLine(FormatRow(row));
        }
        sb.AppendLine("Total: " + rows.Sum(row => Amount(row)));
        return sb.ToString();
    }

    protected abstract string Title { get; }
    protected abstract IReadOnlyList<TRow> Load(Period period);
    protected abstract string FormatRow(TRow row);
    protected abstract decimal Amount(TRow row);
}

public sealed class SalesReport : PeriodReport<Sale>
{
    private readonly ISalesRepository _salesRepository;

    public SalesReport(ISalesRepository salesRepository)
    {
        _salesRepository = salesRepository;
    }

    protected override string Title => "SALES";
    protected override IReadOnlyList<Sale> Load(Period period) => _salesRepository.Load(period);
    protected override string FormatRow(Sale sale) => sale.Product + ";" + sale.Amount;
    protected override decimal Amount(Sale sale) => sale.Amount;
}
```

**Kiedy:** gdy dwie lub więcej klas powtarza ten sam szkielet algorytmu (wykryty np. przez W08) — przy wariantach wymienianych w runtime lepsza jest K03.

---

## K06. Replace Conditional Dispatcher with Command (Zastąp dyspozytor warunkowy poleceniami)

**Opis:** rozbudowany `if/switch` wybierający akcję po kluczu (string, enum) zastępujesz słownikiem obiektów-poleceń, z których każde realizuje jedną akcję.

```csharp
// Przed
public void Handle(string action, Offer offer)
{
    if (action == "submit")
    {
        // ... 20 linii
    }
    else if (action == "approve")
    {
        // ... 30 linii
    }
    else if (action == "archive")
    {
        // ... 15 linii
    }
    else
    {
        throw new NotSupportedException(action);
    }
}

// Po
public interface IOfferCommand
{
    void Execute(Offer offer);
}

public sealed class SubmitOfferCommand : IOfferCommand
{
    public void Execute(Offer offer)
    {
        // ... logika „submit”
    }
}

public sealed class OfferCommandDispatcher
{
    private readonly IReadOnlyDictionary<string, IOfferCommand> _commands;

    public OfferCommandDispatcher(IReadOnlyDictionary<string, IOfferCommand> commands)
    {
        _commands = commands;
    }

    public void Handle(string action, Offer offer)
    {
        IOfferCommand command;
        if (!_commands.TryGetValue(action, out command))
        {
            throw new NotSupportedException(action);
        }
        command.Execute(offer);
    }
}
```

**Kiedy:** gdy dyspozytor rośnie o kolejne akcje, a każda ma rozbudowaną logikę (różnica względem K03: K03 to warianty tego samego obliczenia, K06 to różne akcje).

---

## K07. Move Embellishment to Decorator (Przenieś ozdobnik do dekoratora)

**Opis:** opcjonalne dodatki (cache, logowanie, retry, audyt) włączane flagami przenosisz do dekoratora implementującego ten sam interfejs i opakowującego klasę główną.

```csharp
// Przed
public class OfferRepository : IOfferRepository
{
    private readonly bool _cacheEnabled;
    private readonly Dictionary<int, Offer> _cache = new Dictionary<int, Offer>();

    public Offer GetById(int id)
    {
        if (_cacheEnabled && _cache.TryGetValue(id, out var cached))
        {
            return cached;
        }
        Offer offer = LoadFromDatabase(id);
        if (_cacheEnabled)
        {
            _cache[id] = offer;
        }
        return offer;
    }
}

// Po
public class OfferRepository : IOfferRepository
{
    public Offer GetById(int id)
    {
        return LoadFromDatabase(id);
    }
}

public sealed class CachedOfferRepository : IOfferRepository
{
    private readonly IOfferRepository _inner;
    private readonly ConcurrentDictionary<int, Offer> _cache = new ConcurrentDictionary<int, Offer>();

    public CachedOfferRepository(IOfferRepository inner)
    {
        _inner = inner;
    }

    public Offer GetById(int id)
    {
        return _cache.GetOrAdd(id, key => _inner.GetById(key));
    }
}

// Konfiguracja: flaga decyduje o złożeniu, nie o logice wewnątrz klasy
IOfferRepository repository = cacheEnabled
    ? new CachedOfferRepository(new OfferRepository())
    : (IOfferRepository)new OfferRepository();
```

**Kiedy:** gdy ozdobniki zaciemniają główną logikę i są włączane flagami (uwaga przy zmianie: `Dictionary` → `ConcurrentDictionary` i `GetOrAdd` może wywołać fabrykę więcej niż raz przy współbieżności — sprawdź, czy to akceptowalne).

---

# Siatka zastosowania — Kerievsky

| Sygnał w kodzie | Technika | Łączenie / sekwencja kroków | Nie stosuj, gdy |
|---|---|---|---|
| Metoda miesza poziomy abstrakcji | K01 | W01 → F03 → F18 → F01 → K01 | metoda ma < ~10 linii i jeden poziom |
| Konstruktory powtarzają inicjalizację | K02 | K02 → (opcjonalnie) F04 dla nazwanych fabryk | jest jeden konstruktor |
| Warianty obliczenia wybierane `if/switch`, warianty rosną | K03 | F16 → F01 (gałęzie do metod) → F13 (klasy wariantów) → K03 | 2 stabilne warianty w jednym miejscu |
| Przejścia stanów rozsiane w wielu metodach | K04 | B02 → F16 (predykaty `CanX`) → F18 → K04 | ≤ 4 stany, proste reguły — wystarczy F16 |
| Klasy powtarzają szkielet algorytmu | K05 | W08 → F01 (kroki jako metody) → F04 (te same nazwy) → K05 | warianty wymieniane w runtime — K03 |
| Rosnący dyspozytor akcji po kluczu | K06 | F01 (każda gałąź) → F13 (klasa polecenia) → K06 | 2–3 krótkie akcje |
| Cache/logowanie/retry włączane flagą w klasie | K07 | F01 (wydziel ozdobnik) → interfejs → K07 | ozdobnik jest częścią reguły biznesowej |

## Wybór między K03, K04, K05, K06 i F19

- Wariant zależy od **typu obiektu**, stały przez jego życie → F19.
- Wariant **wymienny**, wybierany z danych/konfiguracji, obiekt nie powinien być hierarchią → K03.
- Zachowanie zależy od **stanu, który się zmienia** → K04.
- Ten sam **szkielet kroków**, różne szczegóły → K05.
- Różne **akcje** wybierane kluczem → K06.
