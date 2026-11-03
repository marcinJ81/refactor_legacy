# Katalog refaktoryzacji — Michael Feathers
<!-- wersja-harnessu: 0.1.1 -->

Źródło: M. Feathers, *Working Effectively with Legacy Code*, 2004:
- rozdz. 20 — *This Class Is Too Big and I Don't Want It to Get Any Bigger*
- rozdz. 21 — *I'm Changing the Same Code All Over the Place*
- rozdz. 22 — *I Need to Change a Monster Method and I Can't Write Tests for It*

Zakres: wyłącznie techniki refaktoryzacji. Pominięte: techniki łamania zależności (rozdz. 25, np. Extract Interface, Parameterize Constructor), szwy (seams) oraz Introduce Sensing Variable — służą przygotowaniu kodu do testów. Break Out Method Object opisany w `01-fowler.md` jako F12.

---

## W01. Extract What You Know / Extract Small Pieces (Wydziel to, co rozumiesz / Wydzielaj małe kawałki)

**Opis:** w metodzie-potworze zaczynasz od małych fragmentów o 0–1 zmiennych wejściowych i bez przypisań do zmiennych spoza fragmentu, bo ich wydzielenie jest najmniej ryzykowne i buduje słownik nazw.

```csharp
// Przed — fragment 300-liniowej metody
// ...
string normalizedTaxId = taxId.Replace("-", string.Empty).Replace(" ", string.Empty).Trim();
if (normalizedTaxId.Length != 10)
{
    errors.Add("Invalid tax id");
}
// ...
string postalCode = address.PostalCode.Trim().ToUpperInvariant();
// ...

// Po — tylko małe, bezpieczne wydzielenia; struktura metody bez zmian
// ...
string normalizedTaxId = NormalizeTaxId(taxId);
if (normalizedTaxId.Length != 10)
{
    errors.Add("Invalid tax id");
}
// ...
string postalCode = NormalizePostalCode(address.PostalCode);
// ...

private static string NormalizeTaxId(string taxId)
{
    return taxId.Replace("-", string.Empty).Replace(" ", string.Empty).Trim();
}

private static string NormalizePostalCode(string postalCode)
{
    return postalCode.Trim().ToUpperInvariant();
}
```

**Kiedy:** na początku pracy z dużą metodą, gdy nie znasz jeszcze jej struktury — małe ekstrakcje zmniejszają ilość kodu do ogarnięcia, zanim podejmiesz decyzje o większym podziale.

---

## W02. Gleaning Dependencies (Oddziel logikę główną od pobocznej)

**Opis:** oddzielasz rdzeń logiki biznesowej od kodu pobocznego (logowanie, powiadomienia, audyt), wydzielając rdzeń do osobnej metody.

```csharp
// Przed
public void AddEntry(Entry entry)
{
    _logger.Info("Adding entry " + entry.Id);
    if (entry.Date > _lastPostingDate)
    {
        _entries.Add(entry);
        _total += entry.Amount;
    }
    _notifier.EntryAdded(entry.Id);
    _logger.Info("Entry added");
}

// Po
public void AddEntry(Entry entry)
{
    _logger.Info("Adding entry " + entry.Id);
    PostEntry(entry);
    _notifier.EntryAdded(entry.Id);
    _logger.Info("Entry added");
}

private void PostEntry(Entry entry)
{
    if (entry.Date <= _lastPostingDate)
    {
        return;
    }
    _entries.Add(entry);
    _total += entry.Amount;
}
```

**Kiedy:** gdy reguła biznesowa ginie w kodzie infrastrukturalnym i chcesz ją czytać — a później przenosić (F14) — bez szumu.

---

## W03. Skeletonize Methods (Zostaw szkielet metody)

**Opis:** z instrukcji warunkowej wydzielasz **osobno** warunek i **osobno** ciało, tak by w metodzie został sam szkielet decyzji.

```csharp
// Przed
if (customer.Orders.Count(o => o.Year == year) > 10 && customer.Debt == 0m && !customer.IsBlocked)
{
    customer.DiscountRate = 0.05m;
    customer.LoyaltyPoints += 100;
    _mailer.Send(customer.Email, "Loyalty discount granted");
}

// Po
if (QualifiesForLoyaltyDiscount(customer, year))
{
    GrantLoyaltyDiscount(customer);
}

private static bool QualifiesForLoyaltyDiscount(Customer customer, int year)
{
    return customer.Orders.Count(o => o.Year == year) > 10
        && customer.Debt == 0m
        && !customer.IsBlocked;
}

private void GrantLoyaltyDiscount(Customer customer)
{
    customer.DiscountRate = 0.05m;
    customer.LoyaltyPoints += 100;
    _mailer.Send(customer.Email, "Loyalty discount granted");
}
```

**Kiedy:** gdy metoda jest siecią decyzji (snarled method — metoda splątana) i ważniejsza jest struktura decyzji niż kolejność kroków.

---

## W04. Find Sequences (Znajdź sekwencje)

**Opis:** wydzielasz warunek **razem** z jego ciałem do jednej metody, aby metoda nadrzędna czytała się jako ciąg kroków.

```csharp
// Przed — fragment dłuższej metody z kilkoma blokami if w kolejności
public void CloseYear(Customer customer, int year)
{
    if (customer.Orders.Count(o => o.Year == year) > 10 && customer.Debt == 0m && !customer.IsBlocked)
    {
        // ... przyznanie rabatu
    }
    if (customer.Orders.Any(o => o.Year < year - 5))
    {
        // ... archiwizacja
    }
    if (customer.Debt > 0m)
    {
        // ... przeliczenie limitu
    }
}

// Po
public void CloseYear(Customer customer, int year)
{
    ApplyLoyaltyDiscountIfQualified(customer, year);
    ArchiveOldOrders(customer, year);
    RecalculateCreditLimit(customer);
}

private void ApplyLoyaltyDiscountIfQualified(Customer customer, int year)
{
    if (!QualifiesForLoyaltyDiscount(customer, year))
    {
        return;
    }
    GrantLoyaltyDiscount(customer);
}
```

**Kiedy:** gdy metoda to lista kroków procesu (bulleted method — metoda wypunktowana) i ważniejsza jest kolejność niż szczegóły warunków; Feathers zaleca wybór W03 albo W04 zależnie od tego, co ma być widoczne w metodzie nadrzędnej.

---

## W05. Extract to the Current Class First (Najpierw wydzielaj do bieżącej klasy)

**Opis:** fragmenty dużej metody wydzielasz najpierw jako prywatne metody tej samej klasy, a dopiero gdy widać skupiska, przenosisz je do nowej klasy.

```csharp
// Przed — fragment metody budującej fakturę
public InvoiceDocument BuildInvoice(Order order)
{
    // ...
    decimal net = order.Lines.Sum(line => line.Net);
    decimal vat = 0m;
    foreach (var group in order.Lines.GroupBy(line => line.VatCode))
    {
        vat += group.Sum(line => line.Net) * _vatRates[group.Key];
    }
    // ... numeracja, PDF, zapis
}

// Krok 1 — wydzielenie do bieżącej klasy
decimal net = CalculateNet(order);
decimal vat = CalculateVat(order);

private static decimal CalculateNet(Order order)
{
    return order.Lines.Sum(line => line.Net);
}

private decimal CalculateVat(Order order)
{
    decimal vat = 0m;
    foreach (var group in order.Lines.GroupBy(line => line.VatCode))
    {
        vat += group.Sum(line => line.Net) * _vatRates[group.Key];
    }
    return vat;
}

// Krok 2 — obie metody używają tylko order.Lines i _vatRates → F13 + F14
public sealed class InvoiceTaxCalculator
{
    private readonly IReadOnlyDictionary<string, decimal> _vatRates;

    public InvoiceTaxCalculator(IReadOnlyDictionary<string, decimal> vatRates)
    {
        _vatRates = vatRates;
    }

    public decimal CalculateNet(Order order)
    {
        return order.Lines.Sum(line => line.Net);
    }

    public decimal CalculateVat(Order order)
    {
        decimal vat = 0m;
        foreach (var group in order.Lines.GroupBy(line => line.VatCode))
        {
            vat += group.Sum(line => line.Net) * _vatRates[group.Key];
        }
        return vat;
    }
}
```

**Kiedy:** gdy kusi utworzenie nowej klasy od razu — najpierw nazwy i granice w znanym kontekście, potem przenosiny (mniejsze ryzyko złej abstrakcji).

---

## W06. Be Prepared to Redo Extractions (Bądź gotów powtórzyć ekstrakcje)

**Opis:** gdy po serii ekstrakcji podział okazuje się nietrafiony, wchłaniasz metody z powrotem (F02) i tniesz ponownie wzdłuż lepiej widocznych granic.

```csharp
// Pierwsze cięcie — metody mieszają walidację z mapowaniem
public void Import(OrderDto dto)
{
    OrderHeader header = ValidateAndMapHeader(dto);
    IList<OrderLine> lines = ValidateAndMapLines(dto, header);
    _repository.Save(header, lines);
}

// Krok 1 — F02: wchłoń ValidateAndMapHeader i ValidateAndMapLines z powrotem do Import
// Krok 2 — F08: zbierz wszystkie walidacje razem, wszystkie mapowania razem
// Krok 3 — F01: tnij wzdłuż nowych granic

public void Import(OrderDto dto)
{
    Validate(dto);
    OrderHeader header = MapHeader(dto);
    IList<OrderLine> lines = MapLines(dto, header);
    _repository.Save(header, lines);
}
```

**Kiedy:** gdy wydzielone metody mają w nazwie „And”, przekazują sobie wiele parametrów lub każda zmiana dotyka kilku z nich naraz.

---

## W07. Feature Sketch (Szkic funkcjonalności) — Group Methods, Look for Hidden Methods, Look for Internal Relationships

**Opis:** rysujesz, które metody używają których pól (i wywołują które metody); rozłączne skupiska to kandydaci na osobne klasy, a grupa prywatnych metod używanych tylko razem to „klasa ukryta w klasie”.

```text
Szkic dla klasy OfferManager

                   _connectionString   _smtpHost   _templates   _vatRate
Load()                    X
Save()                    X
GrossTotal()                                                       X
Vat()                                                              X
Send()                                     X           X
RenderTemplate()                                       X

Skupiska:
  [Load, Save]               → OfferRepository
  [GrossTotal, Vat]          → OfferPricing
  [Send, RenderTemplate]     → OfferMailer
```

```csharp
// Po — klasy wynikające ze szkicu (F13 + F14 dla każdego skupiska)
public sealed class OfferRepository
{
    private readonly string _connectionString;
    // Load, Save
}

public sealed class OfferPricing
{
    private readonly decimal _vatRate;
    // GrossTotal, Vat
}

public sealed class OfferMailer
{
    private readonly string _smtpHost;
    private readonly ITemplateStore _templates;
    // Send, RenderTemplate
}
```

**Kiedy:** gdy klasa jest duża i nie wiadomo, gdzie przebiegają granice odpowiedzialności — szkic daje dowód zamiast intuicji.

---

## W08. Remove Duplication — Start Small (Usuwaj duplikację od małych kawałków)

**Opis:** duplikację usuwasz od najmniejszych powtarzających się fragmentów, a dopiero gdy różnice stają się widoczne, scalasz większe struktury.

```csharp
// Przed
public string ExportInvoices(IEnumerable<Invoice> invoices)
{
    var sb = new StringBuilder();
    sb.Append("Date;Number;Amount").Append("\r\n");
    foreach (var invoice in invoices)
    {
        sb.Append(invoice.Date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture))
          .Append(';').Append(invoice.Number)
          .Append(';').Append(invoice.Amount.ToString(CultureInfo.InvariantCulture))
          .Append("\r\n");
    }
    return sb.ToString();
}

public string ExportPayments(IEnumerable<Payment> payments)
{
    var sb = new StringBuilder();
    sb.Append("Date;Reference;Amount").Append("\r\n");
    foreach (var payment in payments)
    {
        sb.Append(payment.Date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture))
          .Append(';').Append(payment.Reference)
          .Append(';').Append(payment.Amount.ToString(CultureInfo.InvariantCulture))
          .Append("\r\n");
    }
    return sb.ToString();
}

// Krok 1 — najmniejsze wspólne elementy
private static string FormatDate(DateTime date)
{
    return date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
}

private static string FormatAmount(decimal amount)
{
    return amount.ToString(CultureInfo.InvariantCulture);
}

private static void AppendRow(StringBuilder sb, params string[] cells)
{
    sb.Append(string.Join(";", cells)).Append("\r\n");
}

// Krok 2 — teraz widać, że różnią się tylko nagłówkiem i mapowaniem wiersza
private static string ExportCsv<T>(string[] header, IEnumerable<T> items, Func<T, string[]> toCells)
{
    var sb = new StringBuilder();
    AppendRow(sb, header);
    foreach (var item in items)
    {
        AppendRow(sb, toCells(item));
    }
    return sb.ToString();
}

public string ExportInvoices(IEnumerable<Invoice> invoices)
{
    return ExportCsv(
        new[] { "Date", "Number", "Amount" },
        invoices,
        invoice => new[] { FormatDate(invoice.Date), invoice.Number, FormatAmount(invoice.Amount) });
}

public string ExportPayments(IEnumerable<Payment> payments)
{
    return ExportCsv(
        new[] { "Date", "Reference", "Amount" },
        payments,
        payment => new[] { FormatDate(payment.Date), payment.Reference, FormatAmount(payment.Amount) });
}
```

**Kiedy:** gdy ten sam kod jest w kilku miejscach z drobnymi różnicami — start od małych kawałków ujawnia faktyczne różnice i chroni przed przedwczesną abstrakcją.

---

# Siatka zastosowania — Feathers

| Sygnał w kodzie | Technika | Łączenie / sekwencja kroków | Nie stosuj, gdy |
|---|---|---|---|
| Metoda-potwór, nie znasz jej struktury | W01 | B01 → W01 → W02 → W03/W04 | metoda jest krótka — od razu F01 |
| Logika biznesowa przemieszana z logowaniem/powiadomieniami/audytem | W02 | W02 → F14 (rdzeń do klasy domenowej) | kod poboczny jest częścią reguły (np. audyt wymagany prawnie w tej samej transakcji) |
| Metoda jako sieć decyzji (snarled) | W03 | W01 → W03 → F17 → F18 | ważniejsza jest kolejność kroków — W04 |
| Metoda jako lista kroków (bulleted) | W04 | W01 → W04 → K01 | ważniejsza jest struktura decyzji — W03 |
| Pokusa utworzenia nowej klasy „od razu” | W05 | W05 → W07 → F13 → F14 | granice klasy są już oczywiste i potwierdzone szkicem |
| Wydzielone metody z „And”, wiele parametrów, zmiany dotykają kilku naraz | W06 | F02 → F08 → F01 | podział jest trafny |
| Duża klasa, nieznane granice odpowiedzialności | W07 | W07 → B05 → W05 → F13 → F14 | klasa < ~200 linii i spójna |
| Ten sam kod z drobnymi różnicami w kilku miejscach | W08 | W08 → F01 → K05 (gdy w hierarchii) lub funkcja wyższego rzędu | podobieństwo przypadkowe (różne powody zmiany — P14) |

## Kolejność dla metody-potwora (rozdz. 22)

1. W01 — małe, bezpieczne wydzielenia.
2. W02 — oddzielenie rdzenia od kodu pobocznego.
3. W03 lub W04 — ujawnienie struktury.
4. F12 — jeśli zmienne lokalne blokują dalsze ekstrakcje.
5. W05 → W07 → F13 — przeniesienie skupisk do nowych klas.
6. W06 — w każdym momencie, gdy podział okaże się nietrafiony.
