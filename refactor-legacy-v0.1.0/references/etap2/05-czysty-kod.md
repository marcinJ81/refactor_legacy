# Katalog dobrych praktyk — czysty kod
<!-- wersja-harnessu: 0.1.1 -->

Źródło główne: R. C. Martin, *Clean Code*, 2008 (oznaczenia w nawiasach kwadratowych — kody zapachów z rozdz. 17: N = nazwy, F = funkcje, C = komentarze, G = ogólne). Uzupełnienia: Hunt & Thomas (DRY), Evans (język wszechobecny), konwencje .NET (Microsoft Framework Design Guidelines).

Format: opis (1 zdanie) → przykład źle/dobrze → kiedy (1 zdanie). Zasady SOLID pominięte celowo.

---

## P01. Use Intention-Revealing Names (Nazwy ujawniające intencję) [N1, N4]

**Opis:** nazwa mówi, po co coś istnieje i jak tego używać, bez potrzeby komentarza ani zaglądania do implementacji.

```csharp
// Źle
int d; // dni od ostatniej modyfikacji
public List<Offer> GetList2(int t) { /* ... */ }

// Dobrze
int daysSinceLastModification;
public IReadOnlyList<Offer> GetOffersExpiringWithinDays(int days) { /* ... */ }
```

**Kiedy:** zawsze, gdy nazwa wymaga komentarza; w legacy MVC zmiana nazwy właściwości ViewModelu/DTO może zepsuć model binding z formularzy i jQuery/AJAX oraz kontrakt JSON/XML — sprawdź przed Rename.

---

## P02. Pick One Word per Concept (Jedno słowo na jedno pojęcie)

**Opis:** dla tej samej operacji lub pojęcia używasz w całym module jednego słowa, najlepiej z języka domeny (Evans: Ubiquitous Language — język wszechobecny).

```csharp
// Źle
Customer customer = _customerRepository.FetchById(id);
Offer offer = _offerRepository.GetById(id);
Invoice invoice = _invoiceRepository.RetrieveById(id);

// Dobrze
Customer customer = _customerRepository.GetById(id);
Offer offer = _offerRepository.GetById(id);
Invoice invoice = _invoiceRepository.GetById(id);
```

**Kiedy:** gdy w module istnieje kilka synonimów (Get/Fetch/Retrieve, Client/Customer/Kontrahent) dla jednego pojęcia — to B02 na poziomie nazw.

---

## P03. Avoid Encodings (Unikaj kodowania typów w nazwach) [N6]

**Opis:** nazwa nie zawiera typu ani zakresu zmiennej (notacja węgierska, `m_`, `str`, `i`).

```csharp
// Źle
string strCustomerName;
int iCount;
private decimal m_total;

// Dobrze
string customerName;
int count;
private decimal _total;
```

**Kiedy:** przy edycji kodu z notacją węgierską — zmieniaj w obrębie dotykanej klasy, nie hurtem (szum w diffie); prefiksy `_` dla pól prywatnych i `I` dla interfejsów to konwencje platformy .NET — zostają.

---

## P04. Do One Thing (Funkcja robi jedną rzecz) [G30]

**Opis:** funkcja wykonuje jedną rzecz na jednym poziomie abstrakcji — test Martina: jeśli da się z niej wydzielić funkcję o nazwie niebędącej przeformułowaniem jej nazwy, robi więcej niż jedną rzecz.

```csharp
// Źle
public void SaveAndSendOffer(Offer offer)
{
    _repository.Save(offer);
    _mailer.Send(offer.CustomerEmail, BuildBody(offer));
}

// Dobrze — dwie operacje, orkiestracja w miejscu, które jej potrzebuje
public void Save(Offer offer)
{
    _repository.Save(offer);
}

public void Send(Offer offer)
{
    _mailer.Send(offer.CustomerEmail, BuildBody(offer));
}
```

**Kiedy:** gdy w nazwie pojawia się „And”/„Or” lub gdy funkcja dzieli się na sekcje (komentarze-nagłówki, puste linie) → F01, W04.

---

## P05. One Level of Abstraction per Function (Jeden poziom abstrakcji w funkcji) [G34]

**Opis:** w jednej funkcji nie mieszasz wywołań reguł biznesowych ze szczegółami technicznymi (SQL, formatowanie, operacje na tablicach).

```csharp
// Źle
public void Approve(Offer offer)
{
    offer.Approve();
    using (var cmd = new SqlCommand("UPDATE Offers SET Status = 3 WHERE Id = @id", _connection))
    {
        cmd.Parameters.AddWithValue("@id", offer.Id);
        cmd.ExecuteNonQuery();
    }
    NotifyCustomer(offer);
}

// Dobrze
public void Approve(Offer offer)
{
    offer.Approve();
    _repository.UpdateStatus(offer);
    NotifyCustomer(offer);
}
```

**Kiedy:** gdy czytając funkcję przełączasz się między „co” a „jak” → F01, K01.

---

## P06. The Stepdown Rule (Zasada zstępująca)

**Opis:** kod czyta się z góry na dół — każda funkcja stoi przed funkcjami, które wywołuje, o jeden poziom abstrakcji niżej.

```csharp
// Dobrze
public decimal CalculateGross(int offerId)
{
    return AddVat(CalculateNet(offerId));
}

private decimal CalculateNet(int offerId)
{
    return SumLines(LoadOffer(offerId));
}

private Offer LoadOffer(int offerId) { /* ... */ }
private decimal SumLines(Offer offer) { /* ... */ }
private decimal AddVat(decimal net) { /* ... */ }
```

**Kiedy:** po serii ekstrakcji, gdy nowe metody trafiły w przypadkowe miejsca pliku → B04.

---

## P07. Few Arguments, No Output Arguments (Mało argumentów, bez argumentów wyjściowych) [F1, F2]

**Opis:** funkcja ma 0–2 argumenty (wyjątkowo 3), nie zwraca wyników przez `out`/`ref` i nie przyjmuje flag.

```csharp
// Źle
public void CalculateTotals(Offer offer, bool includeDiscounts, out decimal net, out decimal vat, out decimal gross)
{
    // ...
}

// Dobrze
public OfferTotals CalculateTotals(Offer offer)
{
    // ...
}

public sealed class OfferTotals
{
    public OfferTotals(decimal net, decimal vat)
    {
        Net = net;
        Vat = vat;
    }

    public decimal Net { get; }
    public decimal Vat { get; }
    public decimal Gross => Net + Vat;
}
```

**Kiedy:** > 3 argumenty → F05 lub B06; `out`/`ref` → obiekt wynikowy; `bool` → F22 (wyjątek: idiom .NET `TryXxx(…, out T)`).

---

## P08. Have No Side Effects (Brak ukrytych efektów ubocznych)

**Opis:** funkcja nie robi niczego, czego nie zapowiada jej nazwa — szczególnie zapytania (`Is`, `Get`, `Can`, `Has`) nie zmieniają stanu.

```csharp
// Źle
public bool IsValidPassword(User user, string password)
{
    bool valid = _hasher.Verify(user.PasswordHash, password);
    if (valid)
    {
        _session.Initialize(user); // ukryty efekt uboczny
    }
    return valid;
}

// Dobrze
public bool IsValidPassword(User user, string password)
{
    return _hasher.Verify(user.PasswordHash, password);
}

public void SignIn(User user)
{
    _session.Initialize(user);
}
```

**Kiedy:** gdy nazwa sugeruje zapytanie, a metoda zmienia stan → F21 (zmiana podziału = zmiana kontraktu dla wywołujących — sprawdź wszystkie wywołania).

---

## P09. Prefer Exceptions to Error Codes; Error Handling Is One Thing (Wyjątki zamiast kodów błędów; obsługa błędów to jedna rzecz)

**Opis:** błędy sygnalizujesz wyjątkami zamiast kodów zwrotnych, a blok `try/catch` wydzielasz tak, by funkcja z `try` nie robiła nic poza obsługą błędu.

```csharp
// Źle
public int DeleteOffer(int id)
{
    Offer offer = _repository.FindById(id);
    if (offer == null)
    {
        return -1;
    }
    if (!offer.IsDraft)
    {
        return -2;
    }
    _repository.Delete(offer);
    return 0;
}

// Dobrze
public void DeleteOffer(int id)
{
    Offer offer = _repository.GetById(id); // rzuca OfferNotFoundException
    offer.EnsureDeletable();               // rzuca InvalidOperationException
    _repository.Delete(offer);
}

// Obsługa błędu jako osobna funkcja — na granicy (kontroler)
public ActionResult Delete(int id)
{
    try
    {
        _offerService.DeleteOffer(id);
    }
    catch (OfferNotFoundException)
    {
        return HttpNotFound();
    }
    return RedirectToAction("Index");
}
```

**Kiedy:** gdy wywołujący sprawdzają magiczne kody zwrotne; zamiana kodów na wyjątki zmienia kontrakt — rób to tylko przy kontroli nad wszystkimi wywołującymi, a na granicach (Web API, WCF) mapuj wyjątki na odpowiedzi w jednym miejscu.

---

## P10. Don't Return Null, Don't Pass Null (Nie zwracaj i nie przekazuj null)

**Opis:** kolekcje zwracasz puste zamiast `null`, a dla pojedynczych obiektów kontrakt `null` wyrażasz nazwą lub obiektem przypadku szczególnego.

```csharp
// Źle
public List<Offer> GetOffers(int customerId)
{
    // ...
    return null;
}

// Dobrze
public IReadOnlyList<Offer> GetOffers(int customerId)
{
    // ...
    return Array.Empty<Offer>();
}

// Konwencja nazw dla pojedynczego obiektu
public Offer FindById(int id) { /* może zwrócić null */ }
public Offer GetById(int id) { /* rzuca wyjątek, gdy brak */ }
```

**Kiedy:** gdy wywołujący powtarzają sprawdzenia `null` → F20 lub rozdzielenie `Find`/`Get`; zmiana zwracanej wartości z `null` na pustą kolekcję zmienia zachowanie wywołujących, którzy testują `== null`.

---

## P11. Explain Yourself in Code (Wyrażaj intencję w kodzie, nie w komentarzu) [C2, C3, C5]

**Opis:** komentarz opisujący *co* robi kod zastępujesz nazwą; zostawiasz komentarze *dlaczego* (decyzja biznesowa, link do zgłoszenia, ostrzeżenie), a zakomentowany kod usuwasz.

```csharp
// Źle
// sprawdź, czy klient ma prawo do rabatu seniora
if ((customer.Flags & 0x04) != 0 && customer.Age > 65)
{
    // ...
}

// Dobrze
if (customer.IsEligibleForSeniorDiscount)
{
    // ...
}

// Komentarz, który zostaje — wyjaśnia „dlaczego”
// Zaokrąglenie bankierskie zgodnie z wymaganiem działu księgowości (zgłoszenie FIN-1432)
return Math.Round(amount, 2, MidpointRounding.ToEven);
```

**Kiedy:** gdy komentarz da się zastąpić nazwą zmiennej (F03), metody (F01) lub predykatu (F16).

---

## P12. Replace Magic Numbers with Named Constants (Stałe nazwane zamiast magicznych liczb) [G25]

**Opis:** literały o znaczeniu biznesowym zastępujesz stałymi o nazwach opisujących to znaczenie.

```csharp
// Źle
if (line.Quantity >= 100)
{
    value = value - value * 0.05m;
}

// Dobrze
private const int BulkQuantityThreshold = 100;
private const decimal BulkDiscountRate = 0.05m;

if (line.Quantity >= BulkQuantityThreshold)
{
    value = value - value * BulkDiscountRate;
}
```

**Kiedy:** przy każdym literale, którego znaczenie nie jest oczywiste; przy `decimal` przepisz literał 1:1 (`0.1m` ≠ `0.10m` w `ToString()` — inna skala daje inny tekst w logach i widokach).

---

## P13. Law of Demeter — Avoid Train Wrecks (Prawo Demeter — bez „wraków pociągu”) [G36]

**Opis:** obiekt rozmawia z bezpośrednimi współpracownikami, a nie nawiguje przez ich wnętrza łańcuchem wywołań.

```csharp
// Źle
string city = offer.GetCustomer().GetBillingAccount().GetAddress().GetCity();

// Dobrze — obiekt udostępnia to, czego potrzebuje wywołujący (Fowler: Hide Delegate)
string city = offer.CustomerBillingCity;
```

**Kiedy:** gdy łańcuch przechodzi przez obiekty z zachowaniem i każda zmiana struktury pośredniej psuje wywołujących; nie dotyczy struktur danych (DTO, ViewModel) ani płynnych interfejsów typu LINQ.

---

## P14. DRY — Don't Repeat Knowledge (Nie powtarzaj wiedzy) [G5]

**Opis:** każda reguła biznesowa ma jedno źródło w kodzie (Hunt & Thomas: DRY dotyczy wiedzy, nie identycznego tekstu).

```csharp
// Źle — stawka VAT i reguła w trzech miejscach
decimal gross1 = net * 1.23m;           // OfferService
decimal gross2 = net + net * 0.23m;     // InvoiceService
decimal gross3 = net * (1 + 23m / 100); // ReportService

// Dobrze
public static class Vat
{
    public const decimal StandardRate = 0.23m;

    public static decimal AddTo(decimal net)
    {
        return net * (1m + StandardRate);
    }
}
```

**Kiedy:** gdy ta sama reguła występuje po raz trzeci (reguła trzech, Don Roberts — przytoczona przez Fowlera); nie scalaj duplikacji przypadkowej — ten sam kod, różne powody zmiany (np. `CanEdit` i `CanSubmit` sprawdzające ten sam status).

---

## P15. Encapsulate Conditionals, Avoid Negative Conditionals (Hermetyzuj warunki, unikaj zaprzeczeń) [G28, G29]

**Opis:** złożony warunek zastępujesz nazwanym predykatem w formie twierdzącej.

```csharp
// Źle
if (!(offer.Status != OfferStatus.Draft || offer.Lines.Count == 0))
{
    // ...
}

// Dobrze
if (offer.CanBeSubmitted)
{
    // ...
}

public bool CanBeSubmitted => Status == OfferStatus.Draft && Lines.Count > 0;
```

**Kiedy:** gdy warunek ma więcej niż jeden operator logiczny lub podwójne zaprzeczenie → F16, F17.

---

## P16. The Boy Scout Rule (Zasada skauta)

**Opis:** zostawiasz kod, którego dotknąłeś, nieco czystszym, niż go zastałeś — w legacy tylko w obrębie dotykanego fragmentu.

```text
Przykładowa sekwencja commitów przy zmianie funkcjonalnej:
1. tidy: B01 usunięcie martwego kodu w OfferService
2. tidy: P01 nazwy zmiennych w OfferService.Calc
3. tidy: F16 wydzielenie warunku rabatu partnerskiego
4. feat: nowy próg rabatu partnerskiego (zmiana zachowania)
```

**Kiedy:** przy każdej zmianie w kodzie legacy; porządki w osobnych commitach od zmiany zachowania (Beck), zakres ograniczony do bieżącej pracy (Feathers: Focus on the Current Work).

---

# Siatka zastosowania — czysty kod

| Zasada | Sygnał naruszenia | Techniki realizujące |
|---|---|---|
| P01 Nazwy | komentarz przy deklaracji, skróty, `data2`, `tmp` | Rename (IDE), F04, F03 |
| P02 Jedno słowo | Get/Fetch/Retrieve w jednym module | F04, B02 |
| P03 Bez kodowań | `strName`, `m_total`, `iCount` | Rename (IDE) |
| P04 Jedna rzecz | „And” w nazwie, sekcje w funkcji | F01, W04, F11, F21 |
| P05 Jeden poziom abstrakcji | SQL/formatowanie obok reguł biznesowych | F01, K01, W02 |
| P06 Zasada zstępująca | skakanie po pliku | B04 |
| P07 Mało argumentów | > 3 parametry, `out`, `bool` | F05, B06, F22, F12 |
| P08 Brak efektów ubocznych | `IsX`/`GetX` zmienia stan | F21 |
| P09 Wyjątki zamiast kodów | `return -1`, `bool` jako status błędu | F01 (wydzielenie `try`), F04 |
| P10 Bez null | `return null` dla kolekcji, wielokrotne `== null` | F20, F04 (`Find`/`Get`) |
| P11 Kod zamiast komentarza | komentarz „co”, zakomentowany kod | F03, F01, F16, B01 |
| P12 Stałe nazwane | literały biznesowe w kodzie | F03 → stała |
| P13 Demeter | łańcuch `a.B().C().D()` | Hide Delegate, F14 |
| P14 DRY | ta sama reguła w 3+ miejscach | W08, F01, F14, K05 |
| P15 Warunki | `!(... \|\| ...)`, długi warunek | F16, F17 |
| P16 Zasada skauta | — (postawa) | B01–B06 jako porządki przy zmianie |
