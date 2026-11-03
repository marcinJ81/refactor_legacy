# Przykłady refaktoryzacji krok po kroku
<!-- wersja-harnessu: 0.1.1 -->

Założenia dla wszystkich scenariuszy:

- Kod jest pokryty testami (NUnit), testy zielone przed startem.
- Po każdym kroku: testy → commit (komunikat z ID techniki, np. `tidy: F18 guard clause in CalculateTotal`).
- Każdy krok zachowuje zachowanie — także tekst logów, komunikaty wyjątków i reprezentację `decimal` (skala).
- C# 7.3 / .NET Framework 4.8.1.

| Scenariusz | Problem | Główne techniki |
|---|---|---|
| S1 | Długa metoda obliczeniowa z flagą i magicznymi liczbami | P01, W02, F17, F18, P12, F01, F10, F16, F22, F04, B04 |
| S2 | Powtarzane `switch` po przewoźniku | B02, F01, P12, B05, F13, F14, F04, K03, K02 |
| S3 | Duża klasa o wielu odpowiedzialnościach | W07, B05, F01, F13, F14, B06, P09, F04, K02 |
| S4 | Przejścia statusu oferty rozsiane w warunkach | B02, F18, F16, P15, P14, K04, F02 |

---

# S1. Długa metoda obliczeniowa — `OfferService.Calc`

## Kod wyjściowy

```csharp
public class OfferService
{
    private readonly ILog _log;
    private readonly IOfferRepository _repository;

    public OfferService(ILog log, IOfferRepository repository)
    {
        _log = log;
        _repository = repository;
    }

    public decimal Calc(int offerId, bool vat)
    {
        _log.Info("Calc start " + offerId);
        var o = _repository.GetById(offerId);
        decimal t = 0;
        if (o != null)
        {
            if (o.Lines != null && o.Lines.Count > 0)
            {
                foreach (var l in o.Lines)
                {
                    decimal v = l.Qty * l.Price;
                    if (l.Qty >= 100)
                    {
                        v = v - v * 0.05m;
                    }
                    t += v;
                }
                if (o.CustomerType == "VIP")
                {
                    t = t - t * 0.1m;
                }
                else if (o.CustomerType == "PARTNER")
                {
                    if (t > 10000)
                    {
                        t = t - t * 0.07m;
                    }
                }
                if (vat)
                {
                    t = t * 1.23m;
                }
            }
        }
        _log.Info("Calc end " + t);
        return Math.Round(t, 2);
    }
}
```

## Diagnoza

- Mysterious Name — `o`, `t`, `l`, `v`, `Calc` (P01).
- Long Function, mieszanie logowania z regułami (P05, W02).
- Zagnieżdżone warunki (F18).
- Magiczne liczby (P12), ta sama formuła rabatu 3 razy (P14).
- Argument-flaga `vat` (F22).
- Pętla akumulująca (F10).

## Plan

P01 → W02 → F17 + F18 → P12 + F01 → F01 + F10 → F16 + F17 → F22 + F04 → B04

## Krok 1 — P01: nazwy zmiennych (Rename w IDE)

- `o` → `offer`, `t` → `total`, `l` → `line`, `v` → `lineValue`.
- Nazwa publiczna `Calc` zostaje do kroku 7 (publiczne API — wywołujący poza klasą).

## Krok 2 — W02: oddzielenie rdzenia od logowania

Logowanie i zaokrąglenie zostają w metodzie publicznej; rdzeń trafia do osobnej metody. Log loguje wartość **przed** zaokrągleniem — kolejność zachowana.

```csharp
public decimal Calc(int offerId, bool vat)
{
    _log.Info("Calc start " + offerId);
    decimal total = CalculateTotal(offerId, vat);
    _log.Info("Calc end " + total);
    return Math.Round(total, 2);
}

private decimal CalculateTotal(int offerId, bool vat)
{
    var offer = _repository.GetById(offerId);
    decimal total = 0;
    if (offer != null)
    {
        if (offer.Lines != null && offer.Lines.Count > 0)
        {
            foreach (var line in offer.Lines)
            {
                decimal lineValue = line.Qty * line.Price;
                if (line.Qty >= 100)
                {
                    lineValue = lineValue - lineValue * 0.05m;
                }
                total += lineValue;
            }
            if (offer.CustomerType == "VIP")
            {
                total = total - total * 0.1m;
            }
            else if (offer.CustomerType == "PARTNER")
            {
                if (total > 10000)
                {
                    total = total - total * 0.07m;
                }
            }
            if (vat)
            {
                total = total * 1.23m;
            }
        }
    }
    return total;
}
```

## Krok 3 — F17 + F18: scalenie warunków i klauzula strażnicza

```csharp
private decimal CalculateTotal(int offerId, bool vat)
{
    var offer = _repository.GetById(offerId);
    if (!HasLines(offer))
    {
        return 0m;
    }

    decimal total = 0;
    foreach (var line in offer.Lines)
    {
        // ... bez zmian
    }
    // ... rabaty klienta i VAT bez zmian
    return total;
}

private static bool HasLines(Offer offer)
{
    return offer != null && offer.Lines != null && offer.Lines.Count > 0;
}
```

- `return 0m` daje tę samą wartość i skalę co pierwotne `decimal t = 0` → log „Calc end 0” bez zmian.
- Świadomie bez F20 (repozytorium zwracające obiekt zamiast `null`) — zmiana dotyczy wszystkich wywołujących repozytorium, poza zakresem.

## Krok 4 — P12 + F01: stałe nazwane i wspólna formuła rabatu (P14)

```csharp
private const int BulkQuantityThreshold = 100;
private const decimal BulkDiscountRate = 0.05m;
private const string VipCustomerType = "VIP";
private const decimal VipDiscountRate = 0.1m;
private const string PartnerCustomerType = "PARTNER";
private const decimal PartnerDiscountThreshold = 10000m;
private const decimal PartnerDiscountRate = 0.07m;
private const decimal VatRate = 0.23m;

private static decimal ApplyDiscount(decimal amount, decimal rate)
{
    return amount - amount * rate;
}

private static decimal AddVat(decimal netAmount)
{
    return netAmount * (1m + VatRate);
}
```

- Literały przepisane 1:1 (`0.1m`, nie `0.10m`) — skala `decimal` wpływa na `ToString()`, czyli na tekst logu.
- `1m + VatRate` to stała kompilacji równa `1.23m` (ta sama skala co oryginał).
- `ApplyDiscount` zachowuje dokładnie formułę `x - x * rate` (nie `x * (1 - rate)`).

## Krok 5 — F01 + F10: wartość pozycji i potok LINQ

```csharp
decimal total = offer.Lines.Sum(line => LineValue(line));

private static decimal LineValue(OfferLine line)
{
    decimal value = line.Qty * line.Price;
    if (line.Qty < BulkQuantityThreshold)
    {
        return value;
    }
    return ApplyDiscount(value, BulkDiscountRate);
}
```

- `Enumerable.Sum` dla `decimal` sumuje sekwencyjnie od `0m` — wynik identyczny z pętlą.
- `Lines` to kolekcja w pamięci (nie `IQueryable`) — brak zmiany SQL.

## Krok 6 — F16 + F17: rabat klienta jako nazwana reguła

```csharp
private static decimal ApplyCustomerDiscount(string customerType, decimal total)
{
    if (customerType == VipCustomerType)
    {
        return ApplyDiscount(total, VipDiscountRate);
    }
    if (customerType == PartnerCustomerType && total > PartnerDiscountThreshold)
    {
        return ApplyDiscount(total, PartnerDiscountRate);
    }
    return total;
}
```

`CalculateTotal` po kroku:

```csharp
private decimal CalculateTotal(int offerId, bool vat)
{
    var offer = _repository.GetById(offerId);
    if (!HasLines(offer))
    {
        return 0m;
    }
    decimal linesTotal = offer.Lines.Sum(line => LineValue(line));
    decimal total = ApplyCustomerDiscount(offer.CustomerType, linesTotal);
    if (vat)
    {
        total = AddVat(total);
    }
    return total;
}
```

- Świadomie bez K03/F19 — typ klienta decyduje o rabacie w jednym miejscu (KISS); wrócić do tematu, gdy `CustomerType` pojawi się w kolejnych `if`.

## Krok 7 — F22 + F04: usunięcie flagi `vat` z migracją wywołujących

```csharp
public decimal CalculateNet(int offerId)
{
    return RoundMoney(CalculateWithLogging(offerId, NetTotal));
}

public decimal CalculateGross(int offerId)
{
    return RoundMoney(CalculateWithLogging(offerId, GrossTotal));
}

[Obsolete("Use CalculateNet or CalculateGross")]
public decimal Calc(int offerId, bool vat)
{
    return vat ? CalculateGross(offerId) : CalculateNet(offerId);
}

private decimal CalculateWithLogging(int offerId, Func<int, decimal> calculation)
{
    _log.Info("Calc start " + offerId);
    decimal total = calculation(offerId);
    _log.Info("Calc end " + total);
    return total;
}

private decimal NetTotal(int offerId)
{
    Offer offer = _repository.GetById(offerId);
    return HasLines(offer) ? DiscountedTotal(offer) : 0m;
}

private decimal GrossTotal(int offerId)
{
    Offer offer = _repository.GetById(offerId);
    return HasLines(offer) ? AddVat(DiscountedTotal(offer)) : 0m;
}
```

- Dlaczego nie `AddVat(NetTotal(id))`: dla oferty bez pozycji `AddVat(0m)` daje `0.00m` (skala 2), a oryginał zwracał `0` (skala 0) — wartość równa, ale log i ewentualne wyświetlenie bez formatowania różnią się. Testy porównujące tylko wartość tego nie wykryją.
- Teksty logów („Calc start/end”) bez zmian — mogą być monitorowane.
- `Calc` z `[Obsolete]` usuwany po przepięciu wywołujących (sprawdź kontrolery, widoki, wywołania AJAX).

## Krok 8 — B04: kolejność czytania (zasada zstępująca P06)

Wynik końcowy:

```csharp
public class OfferService
{
    private const int BulkQuantityThreshold = 100;
    private const decimal BulkDiscountRate = 0.05m;
    private const string VipCustomerType = "VIP";
    private const decimal VipDiscountRate = 0.1m;
    private const string PartnerCustomerType = "PARTNER";
    private const decimal PartnerDiscountThreshold = 10000m;
    private const decimal PartnerDiscountRate = 0.07m;
    private const decimal VatRate = 0.23m;
    private const int MoneyDecimals = 2;

    private readonly ILog _log;
    private readonly IOfferRepository _repository;

    public OfferService(ILog log, IOfferRepository repository)
    {
        _log = log;
        _repository = repository;
    }

    public decimal CalculateNet(int offerId)
    {
        return RoundMoney(CalculateWithLogging(offerId, NetTotal));
    }

    public decimal CalculateGross(int offerId)
    {
        return RoundMoney(CalculateWithLogging(offerId, GrossTotal));
    }

    [Obsolete("Use CalculateNet or CalculateGross")]
    public decimal Calc(int offerId, bool vat)
    {
        return vat ? CalculateGross(offerId) : CalculateNet(offerId);
    }

    private decimal CalculateWithLogging(int offerId, Func<int, decimal> calculation)
    {
        _log.Info("Calc start " + offerId);
        decimal total = calculation(offerId);
        _log.Info("Calc end " + total);
        return total;
    }

    private decimal NetTotal(int offerId)
    {
        Offer offer = _repository.GetById(offerId);
        return HasLines(offer) ? DiscountedTotal(offer) : 0m;
    }

    private decimal GrossTotal(int offerId)
    {
        Offer offer = _repository.GetById(offerId);
        return HasLines(offer) ? AddVat(DiscountedTotal(offer)) : 0m;
    }

    private static bool HasLines(Offer offer)
    {
        return offer != null && offer.Lines != null && offer.Lines.Count > 0;
    }

    private static decimal DiscountedTotal(Offer offer)
    {
        decimal linesTotal = offer.Lines.Sum(line => LineValue(line));
        return ApplyCustomerDiscount(offer.CustomerType, linesTotal);
    }

    private static decimal LineValue(OfferLine line)
    {
        decimal value = line.Qty * line.Price;
        if (line.Qty < BulkQuantityThreshold)
        {
            return value;
        }
        return ApplyDiscount(value, BulkDiscountRate);
    }

    private static decimal ApplyCustomerDiscount(string customerType, decimal total)
    {
        if (customerType == VipCustomerType)
        {
            return ApplyDiscount(total, VipDiscountRate);
        }
        if (customerType == PartnerCustomerType && total > PartnerDiscountThreshold)
        {
            return ApplyDiscount(total, PartnerDiscountRate);
        }
        return total;
    }

    private static decimal ApplyDiscount(decimal amount, decimal rate)
    {
        return amount - amount * rate;
    }

    private static decimal AddVat(decimal netAmount)
    {
        return netAmount * (1m + VatRate);
    }

    private static decimal RoundMoney(decimal amount)
    {
        return Math.Round(amount, MoneyDecimals);
    }
}
```

## Zasady czystego kodu zastosowane

- P01 nazwy, P04 jedna rzecz na metodę, P05 jeden poziom abstrakcji, P06 zasada zstępująca, P07 brak flagi, P12 stałe, P14 jedna formuła rabatu, P15 nazwane predykaty (`HasLines`).

## Świadomie niezmienione (osobne tematy, nie refaktoryzacja)

- `Math.Round(x, 2)` używa domyślnie zaokrąglenia bankierskiego (`MidpointRounding.ToEven`) — zmiana trybu to zmiana zachowania.
- Repozytorium zwracające `null` (F20 — zmiana kontraktu repozytorium).
- `CustomerType` jako `string` (F06/K03 — gdy reguły zależne od typu klienta zaczną się rozsiewać).

---

# S2. Powtarzane `switch` po przewoźniku — `ShippingService`

## Kod wyjściowy

```csharp
public class ShippingService
{
    public decimal GetCost(Parcel parcel)
    {
        switch (parcel.Carrier)
        {
            case Carrier.Post:
                return 12m + parcel.WeightKg * 1.5m;
            case Carrier.Courier:
                if (parcel.WeightKg <= 5m)
                {
                    return 20m;
                }
                return 20m + (parcel.WeightKg - 5m) * 3m;
            case Carrier.Pickup:
                return 0m;
            default:
                throw new NotSupportedException(parcel.Carrier.ToString());
        }
    }

    public int GetDeliveryDays(Parcel parcel)
    {
        if (parcel.Carrier == Carrier.Post)
        {
            return parcel.IsPriority ? 1 : 3;
        }
        else if (parcel.Carrier == Carrier.Courier)
        {
            return 1;
        }
        else if (parcel.Carrier == Carrier.Pickup)
        {
            return 0;
        }
        throw new NotSupportedException(parcel.Carrier.ToString());
    }

    public string GetTrackingUrl(Parcel parcel)
    {
        switch (parcel.Carrier)
        {
            case Carrier.Post:
                return "https://tracking.post.example/" + parcel.TrackingNumber;
            case Carrier.Courier:
                return string.Format("https://courier.example/track?no={0}", parcel.TrackingNumber);
            default:
                return string.Empty;
        }
    }
}
```

## Diagnoza

- Repeated Switches — ten sam podział po `Carrier` w trzech metodach.
- Shotgun Surgery — nowy przewoźnik = zmiany w trzech miejscach.
- Dwa style zapisu tego samego (`switch` vs `if/else if`) (B02).
- Magiczne liczby (P12).
- `Parcel` to encja EF z `Carrier` jako enum z bazy → F19 (podklasy `Parcel`) zmieniłby mapowanie; wybór: K03.

## Plan

B02 → F01 + P12 → B05 → F13 + F14 + F04 → K03 → K02

## Krok 1 — B02: ujednolicenie formy

```csharp
public int GetDeliveryDays(Parcel parcel)
{
    switch (parcel.Carrier)
    {
        case Carrier.Post:
            return parcel.IsPriority ? 1 : 3;
        case Carrier.Courier:
            return 1;
        case Carrier.Pickup:
            return 0;
        default:
            throw new NotSupportedException(parcel.Carrier.ToString());
    }
}
```

- Ujednolicona **forma**, nie zachowanie: `GetTrackingUrl` dla `Pickup` i wartości nieznanych nadal zwraca `string.Empty` (inne metody rzucają wyjątek) — ta asymetria to zachowanie i zostaje.

## Krok 2 — F01 + P12: każda gałąź jako metoda

```csharp
public decimal GetCost(Parcel parcel)
{
    switch (parcel.Carrier)
    {
        case Carrier.Post:
            return PostCost(parcel);
        case Carrier.Courier:
            return CourierCost(parcel);
        case Carrier.Pickup:
            return PickupCost(parcel);
        default:
            throw new NotSupportedException(parcel.Carrier.ToString());
    }
}

private const decimal PostBaseFee = 12m;
private const decimal PostFeePerKg = 1.5m;

private static decimal PostCost(Parcel parcel)
{
    return PostBaseFee + parcel.WeightKg * PostFeePerKg;
}

// analogicznie: CourierCost, PickupCost,
// PostDeliveryDays, CourierDeliveryDays, PickupDeliveryDays,
// PostTrackingUrl, CourierTrackingUrl
```

## Krok 3 — B05: kolejność spójności

```csharp
// Post
private static decimal PostCost(Parcel parcel) { /* ... */ }
private static int PostDeliveryDays(Parcel parcel) { /* ... */ }
private static string PostTrackingUrl(Parcel parcel) { /* ... */ }

// Courier
private static decimal CourierCost(Parcel parcel) { /* ... */ }
private static int CourierDeliveryDays(Parcel parcel) { /* ... */ }
private static string CourierTrackingUrl(Parcel parcel) { /* ... */ }

// Pickup
private static decimal PickupCost(Parcel parcel) { /* ... */ }
private static int PickupDeliveryDays(Parcel parcel) { /* ... */ }
```

Wspólny prefiks + skupiska = kandydaci na klasy (F13).

## Krok 4 — F13 + F14 + F04: klasa per przewoźnik

```csharp
public sealed class PostCarrier
{
    private const decimal BaseFee = 12m;
    private const decimal FeePerKg = 1.5m;
    private const int PriorityDeliveryDays = 1;
    private const int StandardDeliveryDays = 3;
    private const string TrackingBaseUrl = "https://tracking.post.example/";

    public decimal Cost(Parcel parcel)
    {
        return BaseFee + parcel.WeightKg * FeePerKg;
    }

    public int DeliveryDays(Parcel parcel)
    {
        return parcel.IsPriority ? PriorityDeliveryDays : StandardDeliveryDays;
    }

    public string TrackingUrl(Parcel parcel)
    {
        return TrackingBaseUrl + parcel.TrackingNumber;
    }
}

// ShippingService — przejściowo deleguje w switch
private readonly PostCarrier _post = new PostCarrier();
private readonly CourierCarrier _courier = new CourierCarrier();
private readonly PickupCarrier _pickup = new PickupCarrier();

public decimal GetCost(Parcel parcel)
{
    switch (parcel.Carrier)
    {
        case Carrier.Post:
            return _post.Cost(parcel);
        case Carrier.Courier:
            return _courier.Cost(parcel);
        case Carrier.Pickup:
            return _pickup.Cost(parcel);
        default:
            throw new NotSupportedException(parcel.Carrier.ToString());
    }
}
```

- F04: prefiks przewoźnika usunięty z nazw — wynika teraz z klasy (`PostCost` → `PostCarrier.Cost`).
- `PickupCarrier.TrackingUrl` zwraca `string.Empty` — przeniesione zachowanie gałęzi `default` dla `Pickup`.

## Krok 5 — K03: wspólny interfejs i wybór strategii po kluczu

```csharp
public interface ICarrier
{
    decimal Cost(Parcel parcel);
    int DeliveryDays(Parcel parcel);
    string TrackingUrl(Parcel parcel);
}

public class ShippingService
{
    private readonly IReadOnlyDictionary<Carrier, ICarrier> _carriers;

    public ShippingService(IReadOnlyDictionary<Carrier, ICarrier> carriers)
    {
        _carriers = carriers;
    }

    public decimal GetCost(Parcel parcel)
    {
        return CarrierFor(parcel).Cost(parcel);
    }

    public int GetDeliveryDays(Parcel parcel)
    {
        return CarrierFor(parcel).DeliveryDays(parcel);
    }

    public string GetTrackingUrl(Parcel parcel)
    {
        ICarrier carrier;
        if (!_carriers.TryGetValue(parcel.Carrier, out carrier))
        {
            return string.Empty;
        }
        return carrier.TrackingUrl(parcel);
    }

    private ICarrier CarrierFor(Parcel parcel)
    {
        ICarrier carrier;
        if (!_carriers.TryGetValue(parcel.Carrier, out carrier))
        {
            throw new NotSupportedException(parcel.Carrier.ToString());
        }
        return carrier;
    }
}
```

- Zachowanie dla wartości spoza słownika identyczne z oryginałem: `GetCost`/`GetDeliveryDays` rzucają ten sam wyjątek z tym samym komunikatem, `GetTrackingUrl` zwraca pusty tekst.

## Krok 6 — K02: łańcuch konstruktorów dla istniejących wywołań

Istniejący kod (i testy) tworzy `new ShippingService()` — konstruktor bezparametrowy zostaje.

```csharp
public ShippingService()
    : this(DefaultCarriers())
{
}

public ShippingService(IReadOnlyDictionary<Carrier, ICarrier> carriers)
{
    _carriers = carriers;
}

private static IReadOnlyDictionary<Carrier, ICarrier> DefaultCarriers()
{
    return new Dictionary<Carrier, ICarrier>
    {
        { Carrier.Post, new PostCarrier() },
        { Carrier.Courier, new CourierCarrier() },
        { Carrier.Pickup, new PickupCarrier() }
    };
}
```

## Wynik końcowy — klasy przewoźników

```csharp
public sealed class PostCarrier : ICarrier
{
    private const decimal BaseFee = 12m;
    private const decimal FeePerKg = 1.5m;
    private const int PriorityDeliveryDays = 1;
    private const int StandardDeliveryDays = 3;
    private const string TrackingBaseUrl = "https://tracking.post.example/";

    public decimal Cost(Parcel parcel)
    {
        return BaseFee + parcel.WeightKg * FeePerKg;
    }

    public int DeliveryDays(Parcel parcel)
    {
        return parcel.IsPriority ? PriorityDeliveryDays : StandardDeliveryDays;
    }

    public string TrackingUrl(Parcel parcel)
    {
        return TrackingBaseUrl + parcel.TrackingNumber;
    }
}

public sealed class CourierCarrier : ICarrier
{
    private const decimal BaseFee = 20m;
    private const decimal IncludedWeightKg = 5m;
    private const decimal FeePerExtraKg = 3m;
    private const int DeliveryDaysCount = 1;
    private const string TrackingUrlFormat = "https://courier.example/track?no={0}";

    public decimal Cost(Parcel parcel)
    {
        if (parcel.WeightKg <= IncludedWeightKg)
        {
            return BaseFee;
        }
        return BaseFee + (parcel.WeightKg - IncludedWeightKg) * FeePerExtraKg;
    }

    public int DeliveryDays(Parcel parcel)
    {
        return DeliveryDaysCount;
    }

    public string TrackingUrl(Parcel parcel)
    {
        return string.Format(TrackingUrlFormat, parcel.TrackingNumber);
    }
}

public sealed class PickupCarrier : ICarrier
{
    public decimal Cost(Parcel parcel)
    {
        return 0m;
    }

    public int DeliveryDays(Parcel parcel)
    {
        return 0;
    }

    public string TrackingUrl(Parcel parcel)
    {
        return string.Empty;
    }
}
```

## Zasady czystego kodu zastosowane

- P02 jedno słowo na pojęcie (`Cost`, `DeliveryDays`, `TrackingUrl` w każdej klasie), P04 jedna rzecz, P12 stałe, P14 wiedza o przewoźniku w jednym miejscu.
- Nowy przewoźnik = nowa klasa + wpis w `DefaultCarriers` (wcześniej: trzy `switch`).

---

# S3. Duża klasa — `OfferManager`

## Kod wyjściowy

```csharp
public class OfferManager
{
    private readonly string _connectionString;
    private readonly string _smtpHost;
    private readonly decimal _vatRate;

    public OfferManager(string connectionString, string smtpHost, decimal vatRate)
    {
        _connectionString = connectionString;
        _smtpHost = smtpHost;
        _vatRate = vatRate;
    }

    public Offer Load(int id) { /* ... ADO.NET: SqlConnection(_connectionString), SELECT, mapowanie */ }

    public void Save(Offer offer) { /* ... ADO.NET: SqlConnection(_connectionString), UPDATE */ }

    public decimal GetGrossTotal(Offer offer)
    {
        return offer.Lines.Sum(l => l.Net) * (1 + _vatRate);
    }

    public decimal GetVat(Offer offer)
    {
        return offer.Lines.Sum(l => l.Net) * _vatRate;
    }

    public bool Send(Offer offer)
    {
        try
        {
            string body = "Offer " + offer.Number + Environment.NewLine
                + "Gross: " + GetGrossTotal(offer).ToString("N2");
            using (var client = new SmtpClient(_smtpHost))
            {
                client.Send("offers@company.example", offer.CustomerEmail, "Offer " + offer.Number, body);
            }
            offer.SentAt = DateTime.Now;
            Save(offer);
            return true;
        }
        catch (SmtpException)
        {
            return false;
        }
    }
}
```

## Diagnoza

- Large Class / Divergent Change — trzy powody zmiany: baza, ceny, poczta.
- Duplikacja sumy netto (P14).
- `Send` miesza obsługę błędów, budowę treści, wysyłkę i zapis (P04, P09).
- Magiczne literały (P12).

## Plan

W07 → B05 → F01 + P14 → F13 + F14 (OfferPricing) → F13 + F14 (OfferRepository) → F13 + B06 (OfferMailer) → P09 + F01 + F04 (TrySend) → K02

## Krok 1 — W07: szkic funkcjonalności

```text
                  _connectionString   _smtpHost   _vatRate
Load()                   X
Save()                   X
GetGrossTotal()                                       X
GetVat()                                              X
Send()             (przez Save)          X       (przez GetGrossTotal)

Skupiska: [Load, Save] → repozytorium; [GetGrossTotal, GetVat] → ceny; Send → poczta + orkiestracja
```

## Krok 2 — B05: kolejność spójności

Metody ułożone skupiskami: `Load`, `Save` | `GetGrossTotal`, `GetVat` | `Send`. Bez zmian w kodzie metod.

## Krok 3 — F01 + P14: suma netto i budowa treści maila

```csharp
public decimal GetGrossTotal(Offer offer)
{
    return NetTotal(offer) * (1 + _vatRate);
}

public decimal GetVat(Offer offer)
{
    return NetTotal(offer) * _vatRate;
}

private static decimal NetTotal(Offer offer)
{
    return offer.Lines.Sum(line => line.Net);
}

private string Body(Offer offer)
{
    return "Offer " + offer.Number + Environment.NewLine
        + "Gross: " + GetGrossTotal(offer).ToString("N2");
}

private static string Subject(Offer offer)
{
    return "Offer " + offer.Number;
}
```

## Krok 4 — F13 + F14: `OfferPricing`

```csharp
public sealed class OfferPricing
{
    private readonly decimal _vatRate;

    public OfferPricing(decimal vatRate)
    {
        _vatRate = vatRate;
    }

    public decimal GrossTotal(Offer offer)
    {
        return NetTotal(offer) * (1 + _vatRate);
    }

    public decimal Vat(Offer offer)
    {
        return NetTotal(offer) * _vatRate;
    }

    private static decimal NetTotal(Offer offer)
    {
        return offer.Lines.Sum(line => line.Net);
    }
}

// OfferManager — publiczne API bez zmian, deleguje (pośrednik celowy na czas migracji)
public decimal GetGrossTotal(Offer offer)
{
    return _pricing.GrossTotal(offer);
}
```

## Krok 5 — F13 + F14: `OfferRepository`

```csharp
public sealed class OfferRepository
{
    private readonly string _connectionString;

    public OfferRepository(string connectionString)
    {
        _connectionString = connectionString;
    }

    public Offer Load(int id) { /* ... przeniesione 1:1 */ }

    public void Save(Offer offer) { /* ... przeniesione 1:1 */ }
}
```

## Krok 6 — F13 + B06: `OfferMailer` z jawnymi parametrami

```csharp
public sealed class OfferMailer
{
    private const string SenderAddress = "offers@company.example";
    private readonly string _smtpHost;

    public OfferMailer(string smtpHost)
    {
        _smtpHost = smtpHost;
    }

    public void Send(string recipient, string subject, string body)
    {
        using (var client = new SmtpClient(_smtpHost))
        {
            client.Send(SenderAddress, recipient, subject, body);
        }
    }
}
```

- B06: mailer nie zna `Offer` — dostaje tylko adresata, temat i treść.

## Krok 7 — P09 + F01 + F04: wydzielenie obsługi błędu i nazwa `TrySend`

```csharp
[Obsolete("Use TrySend")]
public bool Send(Offer offer)
{
    return TrySend(offer);
}

public bool TrySend(Offer offer)
{
    if (!TrySendMail(offer))
    {
        return false;
    }
    MarkAsSent(offer);
    return true;
}

private bool TrySendMail(Offer offer)
{
    try
    {
        _mailer.Send(offer.CustomerEmail, Subject(offer), Body(offer));
        return true;
    }
    catch (SmtpException)
    {
        return false;
    }
}

private void MarkAsSent(Offer offer)
{
    offer.SentAt = DateTime.Now;
    _repository.Save(offer);
}
```

- Zachowanie identyczne: `SmtpException` → `false` bez oznaczenia; wyjątki z `Save` (np. `SqlException`) propagują jak wcześniej, bo oryginał łapał tylko `SmtpException`.
- `TrySend` — konwencja .NET dla metody zwracającej `bool` zamiast rzucać (Try-pattern); zamiana na wyjątki (pełne P09) zmieniłaby kontrakt wywołujących — osobna decyzja.
- `DateTime.Now` zostaje — wprowadzanie abstrakcji czasu to praca nad testowalnością, poza zakresem.

## Krok 8 — K02: łańcuch konstruktorów

Istniejący konstruktor `(connectionString, smtpHost, vatRate)` zostaje dla obecnych wywołań i deleguje do nowego, przyjmującego wydzielone klasy (widoczne w wyniku końcowym).

## Wynik końcowy

```csharp
public class OfferManager
{
    private readonly OfferRepository _repository;
    private readonly OfferPricing _pricing;
    private readonly OfferMailer _mailer;

    public OfferManager(string connectionString, string smtpHost, decimal vatRate)
        : this(new OfferRepository(connectionString), new OfferPricing(vatRate), new OfferMailer(smtpHost))
    {
    }

    public OfferManager(OfferRepository repository, OfferPricing pricing, OfferMailer mailer)
    {
        _repository = repository;
        _pricing = pricing;
        _mailer = mailer;
    }

    public Offer Load(int id)
    {
        return _repository.Load(id);
    }

    public void Save(Offer offer)
    {
        _repository.Save(offer);
    }

    public decimal GetGrossTotal(Offer offer)
    {
        return _pricing.GrossTotal(offer);
    }

    public decimal GetVat(Offer offer)
    {
        return _pricing.Vat(offer);
    }

    [Obsolete("Use TrySend")]
    public bool Send(Offer offer)
    {
        return TrySend(offer);
    }

    public bool TrySend(Offer offer)
    {
        if (!TrySendMail(offer))
        {
            return false;
        }
        MarkAsSent(offer);
        return true;
    }

    private bool TrySendMail(Offer offer)
    {
        try
        {
            _mailer.Send(offer.CustomerEmail, Subject(offer), Body(offer));
            return true;
        }
        catch (SmtpException)
        {
            return false;
        }
    }

    private void MarkAsSent(Offer offer)
    {
        offer.SentAt = DateTime.Now;
        _repository.Save(offer);
    }

    private static string Subject(Offer offer)
    {
        return "Offer " + offer.Number;
    }

    private string Body(Offer offer)
    {
        return "Offer " + offer.Number + Environment.NewLine
            + "Gross: " + _pricing.GrossTotal(offer).ToString("N2");
    }
}
```

## Kolejne kroki (poza tym scenariuszem)

- Przepięcie wywołujących z `OfferManager.Load/Save/GetGrossTotal/GetVat` bezpośrednio na nowe klasy → F02 (Remove Middle Man) delegatów w `OfferManager`.
- `OfferManager` zostaje jako koordynator wysyłki oferty.

## Zasady czystego kodu zastosowane

- P04 jedna rzecz na klasę i metodę, P07 jawne parametry mailera, P09 obsługa błędu jako osobna funkcja, P12 stałe, P14 jedna suma netto.

---

# S4. Przejścia statusu oferty — `Offer`

## Kod wyjściowy

```csharp
public class Offer
{
    public OfferStatus Status { get; set; }
    public DateTime? SubmittedAt { get; set; }
    public string RejectReason { get; set; }

    public void Submit()
    {
        if (Status != OfferStatus.Draft)
        {
            throw new InvalidOperationException("Only draft can be submitted");
        }
        Status = OfferStatus.Submitted;
        SubmittedAt = DateTime.Now;
    }

    public void Approve()
    {
        if (Status == OfferStatus.Submitted)
        {
            Status = OfferStatus.Approved;
        }
        else
        {
            throw new InvalidOperationException("Only submitted offer can be approved");
        }
    }

    public void Reject(string reason)
    {
        if (!(Status == OfferStatus.Submitted || Status == OfferStatus.Approved))
        {
            throw new InvalidOperationException("Cannot reject in status " + Status);
        }
        if (string.IsNullOrWhiteSpace(reason))
        {
            throw new ArgumentException("Reason required", nameof(reason));
        }
        Status = OfferStatus.Rejected;
        RejectReason = reason;
    }

    public bool CanEdit()
    {
        return Status == OfferStatus.Draft;
    }
}
```

## Diagnoza

- Trzy różne style sprawdzania stanu (B02).
- `if/else` z wyjątkiem w `else` (F18).
- Warunki zapisane wprost, z zaprzeczeniem (P15).
- Publiczny setter `Status` — każdy może ominąć reguły przejść.

## Plan

Wariant A (wystarczający przy obecnej złożoności): B02 + F18 → F16 + P15
Wariant B (gdy reguły zależne od stanu rosną): wariant A → K04 → F02

## Krok 1 — B02 + F18: jeden styl strażników

```csharp
public void Approve()
{
    if (Status != OfferStatus.Submitted)
    {
        throw new InvalidOperationException("Only submitted offer can be approved");
    }
    Status = OfferStatus.Approved;
}
```

## Krok 2 — F16 + P15: nazwane predykaty w formie twierdzącej

Wynik wariantu A:

```csharp
public class Offer
{
    public OfferStatus Status { get; set; }
    public DateTime? SubmittedAt { get; set; }
    public string RejectReason { get; set; }

    public void Submit()
    {
        if (!CanSubmit())
        {
            throw new InvalidOperationException("Only draft can be submitted");
        }
        Status = OfferStatus.Submitted;
        SubmittedAt = DateTime.Now;
    }

    public void Approve()
    {
        if (!CanApprove())
        {
            throw new InvalidOperationException("Only submitted offer can be approved");
        }
        Status = OfferStatus.Approved;
    }

    public void Reject(string reason)
    {
        if (!CanReject())
        {
            throw new InvalidOperationException("Cannot reject in status " + Status);
        }
        if (string.IsNullOrWhiteSpace(reason))
        {
            throw new ArgumentException("Reason required", nameof(reason));
        }
        Status = OfferStatus.Rejected;
        RejectReason = reason;
    }

    public bool CanEdit()
    {
        return Status == OfferStatus.Draft;
    }

    private bool CanSubmit()
    {
        return Status == OfferStatus.Draft;
    }

    private bool CanApprove()
    {
        return Status == OfferStatus.Submitted;
    }

    private bool CanReject()
    {
        return Status == OfferStatus.Submitted || Status == OfferStatus.Approved;
    }
}
```

- P14: `CanEdit` i `CanSubmit` sprawdzają to samo, ale to **różne reguły** (edycja vs wysłanie) — scalenie byłoby duplikacją przypadkową; każda może zmienić się niezależnie.
- Opcjonalnie `Status { get; private set; }` — tylko jeśli wyszukanie `.Status =` w całym rozwiązaniu (C#, Razor, mapowania) nie znajdzie zapisów spoza klasy; EF6 mapuje właściwości z prywatnym setterem.

## Kryterium przejścia do wariantu B

| Wariant A wystarcza | Wariant B (K04) uzasadniony |
|---|---|
| ≤ 4 stany, 3–4 operacje zależne od stanu | dochodzą kolejne operacje zależne od stanu (np. `CanAddLine`, powiadomienia per stan) |
| reguły zmieniają się rzadko | nowy stan wymaga zmian w wielu metodach |
| przejścia czytelne w jednym pliku | zachowanie per stan rośnie poza same przejścia |

## Krok 3 — K04: klasy stanów (wariant B)

Stan w bazie pozostaje enumem — obiekt stanu jest wyliczany z `Status`, mapowanie EF bez zmian.

```csharp
internal abstract class OfferState
{
    public abstract OfferStatus Status { get; }

    public virtual bool CanEdit => false;

    public virtual OfferStatus Submit()
    {
        throw new InvalidOperationException("Only draft can be submitted");
    }

    public virtual OfferStatus Approve()
    {
        throw new InvalidOperationException("Only submitted offer can be approved");
    }

    public virtual OfferStatus Reject()
    {
        throw new InvalidOperationException("Cannot reject in status " + Status);
    }

    public static OfferState For(OfferStatus status)
    {
        switch (status)
        {
            case OfferStatus.Draft:
                return new DraftState();
            case OfferStatus.Submitted:
                return new SubmittedState();
            case OfferStatus.Approved:
                return new ApprovedState();
            case OfferStatus.Rejected:
                return new RejectedState();
            default:
                throw new ArgumentOutOfRangeException(nameof(status));
        }
    }
}

internal sealed class DraftState : OfferState
{
    public override OfferStatus Status => OfferStatus.Draft;
    public override bool CanEdit => true;

    public override OfferStatus Submit()
    {
        return OfferStatus.Submitted;
    }
}

internal sealed class SubmittedState : OfferState
{
    public override OfferStatus Status => OfferStatus.Submitted;

    public override OfferStatus Approve()
    {
        return OfferStatus.Approved;
    }

    public override OfferStatus Reject()
    {
        return OfferStatus.Rejected;
    }
}

internal sealed class ApprovedState : OfferState
{
    public override OfferStatus Status => OfferStatus.Approved;

    public override OfferStatus Reject()
    {
        return OfferStatus.Rejected;
    }
}

internal sealed class RejectedState : OfferState
{
    public override OfferStatus Status => OfferStatus.Rejected;
}
```

- `For` to jedyny pozostały `switch` — punkt mapowania enum → obiekt stanu.
- Różnica zachowania tylko dla wartości enum spoza zakresu (`ArgumentOutOfRangeException` zamiast `InvalidOperationException`) — nieosiągalna, jeśli kolumna w bazie jest ograniczona; zweryfikuj przed zmianą.

## Krok 4 — F02 + B01: delegacja do stanu, usunięcie zbędnych predykatów

Wynik wariantu B:

```csharp
public class Offer
{
    public OfferStatus Status { get; set; }
    public DateTime? SubmittedAt { get; set; }
    public string RejectReason { get; set; }

    private OfferState State => OfferState.For(Status);

    public void Submit()
    {
        Status = State.Submit();
        SubmittedAt = DateTime.Now;
    }

    public void Approve()
    {
        Status = State.Approve();
    }

    public void Reject(string reason)
    {
        OfferStatus rejected = State.Reject();
        if (string.IsNullOrWhiteSpace(reason))
        {
            throw new ArgumentException("Reason required", nameof(reason));
        }
        Status = rejected;
        RejectReason = reason;
    }

    public bool CanEdit()
    {
        return State.CanEdit;
    }
}
```

- Kolejność walidacji w `Reject` zachowana: najpierw stan, potem powód, na końcu zmiana stanu.
- Komunikaty wyjątków identyczne z oryginałem.
- `State` jest prywatną właściwością tylko do odczytu — EF6 jej nie mapuje (konwencja: mapowane są publiczne właściwości z setterem).

## Zasady czystego kodu zastosowane

- P02 spójne nazewnictwo (`CanX`), P04 jedna rzecz, P14 rozróżnienie wiedzy i przypadkowej duplikacji, P15 predykaty twierdzące, P16 zakres ograniczony do klasy `Offer`.
