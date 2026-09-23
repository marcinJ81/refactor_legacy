# Katalog technik rozrywania zależności (Dependency-Breaking Techniques) – C#

Źródło: Michael Feathers, *Working Effectively with Legacy Code* (2004), rozdział 25.
Przykłady to pseudokod w składni C# 7. Każda technika ma dwa przykłady:
- **NIEWŁAŚCIWE**: stan wyjściowy, w którym zależność blokuje testy.
- **WŁAŚCIWE**: stan docelowy, w którym technika wprowadziła szew (seam).

Wszystkie techniki wprowadzają Object Seam (szew obiektowy) i korzystają wyłącznie z mechanizmów języka C# oraz standardowej biblioteki .NET.

---

## 1. Adapt Parameter (adaptacja parametru)

Gdy parametr metody jest typem trudnym do utworzenia w teście, a nie da się z niego wydzielić interfejsu, owija się go własnym, wąskim interfejsem.

**NIEWŁAŚCIWE**
```csharp
public class ReportService
{
    public void Generate(HttpRequest request)
    {
        var userId = request.QueryString["userId"];
        // logika
    }
}
```

**WŁAŚCIWE**
```csharp
public interface IParameterSource
{
    string GetValue(string name);
}

public class HttpParameterSource : IParameterSource
{
    private readonly HttpRequest _request;

    public HttpParameterSource(HttpRequest request)
    {
        _request = request;
    }

    public string GetValue(string name)
    {
        return _request.QueryString[name];
    }
}

public class ReportService
{
    public void Generate(IParameterSource source)
    {
        var userId = source.GetValue("userId");
        // logika
    }
}
```

---

## 2. Break Out Method Object (wydzielenie obiektu metody)

Długa metoda korzystająca z wielu pól klasy zostaje przeniesiona do osobnej klasy, a jej zmienne lokalne stają się polami tej klasy.

**NIEWŁAŚCIWE**
```csharp
public class OrderProcessor
{
    private readonly Db _db;

    public void Process(Order order)
    {
        // 300 linii: walidacja, rabaty, podatki, zapis do _db
    }
}
```

**WŁAŚCIWE**
```csharp
public class OrderProcessor
{
    private readonly Db _db;

    public void Process(Order order)
    {
        new OrderProcessing(order, _db).Execute();
    }
}

public class OrderProcessing
{
    private readonly Order _order;
    private readonly IDb _db;

    public OrderProcessing(Order order, IDb db)
    {
        _order = order;
        _db = db;
    }

    public void Execute()
    {
        // ta sama logika, testowalna niezależnie
    }
}
```

---

## 3. Encapsulate Global References (hermetyzacja referencji globalnych)

Globalne lub statyczne dane i funkcje zostają zgrupowane w klasie, którą da się podmienić w teście.

**NIEWŁAŚCIWE**
```csharp
public static class Globals
{
    public static decimal VatRate;
    public static string ConnectionString;
}

public class Invoice
{
    public decimal Gross(decimal net)
    {
        return net * (1 + Globals.VatRate);
    }
}
```

**WŁAŚCIWE**
```csharp
public class AppSettings
{
    public virtual decimal VatRate { get; set; }
    public virtual string ConnectionString { get; set; }
}

public class Invoice
{
    private readonly AppSettings _settings;

    public Invoice(AppSettings settings)
    {
        _settings = settings;
    }

    public decimal Gross(decimal net)
    {
        return net * (1 + _settings.VatRate);
    }
}
```

---

## 4. Expose Static Method (upublicznienie metody statycznej)

Metodę, która nie korzysta ze stanu instancji, zamienia się na publiczną metodę statyczną. Pozwala to przetestować ją bez tworzenia obiektu, którego konstruktor jest problematyczny.

**NIEWŁAŚCIWE**
```csharp
public class RsclModule
{
    public RsclModule()
    {
        // łączenie z bazą, ładowanie konfiguracji
    }

    private bool ValidatePacket(Packet p)
    {
        return p.Length > 0 && p.Checksum == Compute(p);
    }
}
```

**WŁAŚCIWE**
```csharp
public class RsclModule
{
    public RsclModule()
    {
        // łączenie z bazą, ładowanie konfiguracji
    }

    public static bool ValidatePacket(Packet p)
    {
        return p.Length > 0 && p.Checksum == Compute(p);
    }
}

// test: RsclModule.ValidatePacket(packet), bez konstruktora
```

---

## 5. Extract and Override Call (wydzielenie i nadpisanie wywołania)

Problematyczne wywołanie zostaje wydzielone do metody `protected virtual`, którą w teście nadpisuje podklasa.

**NIEWŁAŚCIWE**
```csharp
public class PageLayout
{
    public void Rebind()
    {
        var styles = StyleMaster.FormStyles(_template, _id);
        // logika na styles
    }
}
```

**WŁAŚCIWE**
```csharp
public class PageLayout
{
    public void Rebind()
    {
        var styles = FormStyles(_template, _id);
        // logika na styles
    }

    protected virtual List<Style> FormStyles(Template t, int id)
    {
        return StyleMaster.FormStyles(t, id);
    }
}

// test
public class TestingPageLayout : PageLayout
{
    protected override List<Style> FormStyles(Template t, int id)
    {
        return new List<Style>();
    }
}
```

---

## 6. Extract and Override Factory Method (wydzielenie i nadpisanie metody fabrykującej)

Tworzenie zależności w konstruktorze zostaje przeniesione do wirtualnej metody fabrykującej, nadpisywanej w teście.

Uwaga: w C# wywołanie metody wirtualnej z konstruktora bazowego wykona wersję z podklasy, zanim konstruktor podklasy się wykona. Nadpisanie nie może więc korzystać z pól podklasy.

**NIEWŁAŚCIWE**
```csharp
public class WorkflowEngine
{
    private readonly TransactionManager _tm;

    public WorkflowEngine()
    {
        _tm = new TransactionManager(new SqlReader(), new SqlPersister());
    }
}
```

**WŁAŚCIWE**
```csharp
public class WorkflowEngine
{
    private readonly TransactionManager _tm;

    public WorkflowEngine()
    {
        _tm = CreateTransactionManager();
    }

    protected virtual TransactionManager CreateTransactionManager()
    {
        return new TransactionManager(new SqlReader(), new SqlPersister());
    }
}

// test
public class TestWorkflowEngine : WorkflowEngine
{
    protected override TransactionManager CreateTransactionManager()
    {
        return new FakeTransactionManager();
    }
}
```

---

## 7. Extract and Override Getter (wydzielenie i nadpisanie gettera)

Pole tworzone w konstruktorze zostaje zainicjalizowane leniwie w wirtualnym getterze, który w teście da się nadpisać. Omija to problem wywoływania metod wirtualnych w konstruktorze.

**NIEWŁAŚCIWE**
```csharp
public class WorkflowEngine
{
    private readonly TransactionManager _tm;

    public WorkflowEngine()
    {
        _tm = new TransactionManager(new SqlReader(), new SqlPersister());
    }

    public void Run()
    {
        _tm.Begin();
    }
}
```

**WŁAŚCIWE**
```csharp
public class WorkflowEngine
{
    private TransactionManager _tm;

    protected virtual TransactionManager GetTransactionManager()
    {
        if (_tm == null)
        {
            _tm = new TransactionManager(new SqlReader(), new SqlPersister());
        }
        return _tm;
    }

    public void Run()
    {
        GetTransactionManager().Begin();
    }
}

// test
public class TestWorkflowEngine : WorkflowEngine
{
    protected override TransactionManager GetTransactionManager()
    {
        return new FakeTransactionManager();
    }
}
```

---

## 8. Extract Implementer (wydzielenie implementacji)

Implementacja klasy zostaje przeniesiona do nowej klasy, a oryginalna nazwa staje się interfejsem. Stosuje się to, gdy nazwa klasy jest już dobrą nazwą interfejsu, a IDE nie ma automatycznego refaktoru.

**NIEWŁAŚCIWE**
```csharp
public class ModelNode
{
    public void AddChild(ModelNode node)
    {
        // implementacja
    }
}

public class Consumer
{
    public void Build(ModelNode root)
    {
    }
}
```

**WŁAŚCIWE**
```csharp
public interface IModelNode
{
    void AddChild(IModelNode node);
}

public class ProductionModelNode : IModelNode
{
    public void AddChild(IModelNode node)
    {
        // dotychczasowa implementacja
    }
}

public class Consumer
{
    public void Build(IModelNode root)
    {
    }
}
```

W C# zmiana nazwy klasy na interfejs łamie konwencję prefiksu `I`, dlatego Extract Interface zwykle jest prostszy.

---

## 9. Extract Interface (wydzielenie interfejsu)

Z klasy wydziela się interfejs zawierający tylko metody używane przez testowany kod, a zależność zmienia się na ten interfejs.

**NIEWŁAŚCIWE**
```csharp
public class PayrollService
{
    private readonly SqlTransactionLog _log = new SqlTransactionLog();

    public void Pay(Employee e)
    {
        _log.Save(new Transaction(e));
    }
}
```

**WŁAŚCIWE**
```csharp
public interface ITransactionRecorder
{
    void Save(Transaction t);
}

public class SqlTransactionLog : ITransactionRecorder
{
    public void Save(Transaction t)
    {
        // zapis do bazy
    }
}

public class PayrollService
{
    private readonly ITransactionRecorder _log;

    public PayrollService(ITransactionRecorder log)
    {
        _log = log;
    }

    public void Pay(Employee e)
    {
        _log.Save(new Transaction(e));
    }
}
```

---

## 10. Introduce Instance Delegator (wprowadzenie delegatora instancyjnego)

Obok metody statycznej dodaje się metodę instancyjną, która do niej deleguje. Klient korzysta z instancji, którą w teście można podmienić.

**NIEWŁAŚCIWE**
```csharp
public class BankingServices
{
    public static void UpdateAccountBalance(int userId, decimal amount)
    {
        // wywołanie systemu bankowego
    }
}

public class Transfer
{
    public void Execute(int userId, decimal amount)
    {
        BankingServices.UpdateAccountBalance(userId, amount);
    }
}
```

**WŁAŚCIWE**
```csharp
public class BankingServices
{
    public static void UpdateAccountBalance(int userId, decimal amount)
    {
        // wywołanie systemu bankowego
    }

    public virtual void UpdateBalance(int userId, decimal amount)
    {
        UpdateAccountBalance(userId, amount);
    }
}

public class Transfer
{
    private readonly BankingServices _banking;

    public Transfer(BankingServices banking)
    {
        _banking = banking;
    }

    public void Execute(int userId, decimal amount)
    {
        _banking.UpdateBalance(userId, amount);
    }
}
```

---

## 11. Introduce Static Setter (wprowadzenie statycznego settera)

Singletonowi dodaje się statyczny setter, który w teście podmienia instancję na atrapę.

Uwaga: stan statyczny współdzielony między testami wymaga resetu w `TearDown` (NUnit) i blokuje równoległe wykonywanie testów.

**NIEWŁAŚCIWE**
```csharp
public class PermitRepository
{
    private static PermitRepository _instance;

    private PermitRepository()
    {
    }

    public static PermitRepository GetInstance()
    {
        if (_instance == null)
        {
            _instance = new PermitRepository();
        }
        return _instance;
    }

    public Permit FindPermit(int id)
    {
        // baza danych
    }
}
```

**WŁAŚCIWE**
```csharp
public class PermitRepository
{
    private static PermitRepository _instance;

    protected PermitRepository()
    {
    }

    public static PermitRepository GetInstance()
    {
        if (_instance == null)
        {
            _instance = new PermitRepository();
        }
        return _instance;
    }

    public static void SetTestingInstance(PermitRepository instance)
    {
        _instance = instance;
    }

    public virtual Permit FindPermit(int id)
    {
        // baza danych
    }
}

// test
// PermitRepository.SetTestingInstance(new FakePermitRepository());
// [TearDown]: PermitRepository.SetTestingInstance(null);
```

---

## 12. Parameterize Constructor (parametryzacja konstruktora)

Obiekt tworzony w konstruktorze zostaje przekazany jako parametr. Stary konstruktor pozostaje i deleguje do nowego, więc istniejący klienci się nie zmieniają.

**NIEWŁAŚCIWE**
```csharp
public class MailChecker
{
    private readonly MailReceiver _receiver;

    public MailChecker(int checkPeriod)
    {
        _receiver = new MailReceiver();
    }
}
```

**WŁAŚCIWE**
```csharp
public class MailChecker
{
    private readonly IMailReceiver _receiver;

    public MailChecker(int checkPeriod)
        : this(new MailReceiver(), checkPeriod)
    {
    }

    public MailChecker(IMailReceiver receiver, int checkPeriod)
    {
        _receiver = receiver;
    }
}
```

---

## 13. Parameterize Method (parametryzacja metody)

Obiekt tworzony wewnątrz metody zostaje przekazany jako parametr. Opcjonalnie stara sygnatura pozostaje i deleguje do nowej.

**NIEWŁAŚCIWE**
```csharp
public class TestCase
{
    public void Run()
    {
        var result = new TestResult();
        // logika zapisująca do result
    }
}
```

**WŁAŚCIWE**
```csharp
public class TestCase
{
    public void Run()
    {
        Run(new TestResult());
    }

    public void Run(ITestResult result)
    {
        // logika zapisująca do result
    }
}
```

---

## 14. Primitivize Parameter (sprowadzenie parametru do typów prostych)

Logikę operującą na trudnym do utworzenia obiekcie przenosi się do metody przyjmującej tylko typy proste. Feathers traktuje tę technikę jako ostateczność, bo prowadzi do anemicznego kodu.

**NIEWŁAŚCIWE**
```csharp
public class SequenceComparer
{
    public bool HasGapFor(Sequence pattern)
    {
        // Sequence wymaga całego środowiska (np. połączenia z urządzeniem)
        return pattern.Events.Any(e => e.Duration > MaxGap);
    }
}
```

**WŁAŚCIWE**
```csharp
public class SequenceComparer
{
    public bool HasGapFor(Sequence pattern)
    {
        return HasGap(pattern.Events.Select(e => e.Duration).ToArray());
    }

    public static bool HasGap(int[] durations)
    {
        return durations.Any(d => d > MaxGap);
    }
}
```

---

## 15. Pull Up Feature (przeniesienie funkcjonalności w górę hierarchii)

Testowane metody przenosi się do nowej abstrakcyjnej klasy bazowej. Test tworzy podklasę bazy, bez problematycznych zależności oryginału.

**NIEWŁAŚCIWE**
```csharp
public class Scheduler
{
    private readonly ExternalCalendar _calendar; // problematyczna zależność

    public Scheduler()
    {
        _calendar = new ExternalCalendar();
    }

    public int CalculateSlots(int minutes)
    {
        return minutes / 15; // czysta logika do przetestowania
    }
}
```

**WŁAŚCIWE**
```csharp
public abstract class SchedulingServices
{
    public int CalculateSlots(int minutes)
    {
        return minutes / 15;
    }
}

public class Scheduler : SchedulingServices
{
    private readonly ExternalCalendar _calendar;

    public Scheduler()
    {
        _calendar = new ExternalCalendar();
    }
}

// test
public class TestingSchedulingServices : SchedulingServices
{
}
```

---

## 16. Push Down Dependency (przeniesienie zależności w dół hierarchii)

Problematyczne zależności przenosi się do podklasy produkcyjnej. Klasa bazowa staje się abstrakcyjna i testowalna przez własną podklasę testową.

**NIEWŁAŚCIWE**
```csharp
public class OffMarketTradeValidator
{
    public bool IsValid(Trade t)
    {
        if (t.Price < 0)
        {
            ShowErrorDialog("Invalid price"); // zależność od UI
            return false;
        }
        return true;
    }

    private void ShowErrorDialog(string msg)
    {
        MessageBox.Show(msg);
    }
}
```

**WŁAŚCIWE**
```csharp
public abstract class OffMarketTradeValidator
{
    public bool IsValid(Trade t)
    {
        if (t.Price < 0)
        {
            ShowErrorDialog("Invalid price");
            return false;
        }
        return true;
    }

    protected abstract void ShowErrorDialog(string msg);
}

public class WindowsOffMarketTradeValidator : OffMarketTradeValidator
{
    protected override void ShowErrorDialog(string msg)
    {
        MessageBox.Show(msg);
    }
}

// test
public class TestingOffMarketTradeValidator : OffMarketTradeValidator
{
    protected override void ShowErrorDialog(string msg)
    {
    }
}
```

---

## 17. Replace Function with Function Pointer (zastąpienie funkcji wskaźnikiem do funkcji)

Bezpośrednie wywołanie statycznej metody zastępuje się wywołaniem delegata (`Func<>` lub `Action<>`) przekazanego z zewnątrz.

**NIEWŁAŚCIWE**
```csharp
public class Scanner
{
    public void Scan()
    {
        var data = HardwareApi.ReadSensor();
        // logika
    }
}
```

**WŁAŚCIWE**
```csharp
public class Scanner
{
    private readonly Func<SensorData> _readSensor;

    public Scanner()
        : this(HardwareApi.ReadSensor)
    {
    }

    public Scanner(Func<SensorData> readSensor)
    {
        _readSensor = readSensor;
    }

    public void Scan()
    {
        var data = _readSensor();
        // logika
    }
}
```

---

## 18. Replace Global Reference with Getter (zastąpienie referencji globalnej getterem)

Każde odwołanie do globalnego lub statycznego obiektu zastępuje się wywołaniem wirtualnego gettera, nadpisywanego w teście.

**NIEWŁAŚCIWE**
```csharp
public class RegisterSale
{
    public void AddItem(Barcode code)
    {
        var item = Inventory.Instance.ItemForBarcode(code);
        // logika
    }
}
```

**WŁAŚCIWE**
```csharp
public class RegisterSale
{
    public void AddItem(Barcode code)
    {
        var item = GetInventory().ItemForBarcode(code);
        // logika
    }

    protected virtual IInventory GetInventory()
    {
        return Inventory.Instance;
    }
}

// test
public class TestingRegisterSale : RegisterSale
{
    protected override IInventory GetInventory()
    {
        return new FakeInventory();
    }
}
```

---

## 19. Subclass and Override Method (podklasa i nadpisanie metody)

Podstawowa technika szwu obiektowego: metodę z problematycznym zachowaniem oznacza się jako `protected virtual` i nadpisuje w podklasie testowej. Większość pozostałych technik to jej warianty.

**NIEWŁAŚCIWE**
```csharp
public class MessageForwarder
{
    public void Forward(Message m)
    {
        var msg = CreateForwardMessage(m);
        SmtpSender.Send(msg); // wysyłka realnej poczty
    }
}
```

**WŁAŚCIWE**
```csharp
public class MessageForwarder
{
    public void Forward(Message m)
    {
        var msg = CreateForwardMessage(m);
        Send(msg);
    }

    protected virtual void Send(MailMessage msg)
    {
        SmtpSender.Send(msg);
    }
}

// test
public class TestingMessageForwarder : MessageForwarder
{
    public List<MailMessage> Sent = new List<MailMessage>();

    protected override void Send(MailMessage msg)
    {
        Sent.Add(msg);
    }
}
```

---

## 20. Supersede Instance Variable (zastąpienie zmiennej instancyjnej)

Po utworzeniu obiektu podmienia się jego pole przez dedykowaną metodę, gdy nie da się sparametryzować konstruktora. Stosuje się to w ostateczności, bo obiekt przez chwilę istnieje z prawdziwą zależnością.

**NIEWŁAŚCIWE**
```csharp
public class Pager
{
    private IPrinter _printer;

    public Pager()
    {
        _printer = new NetworkPrinter(); // wielu klientów, nie można zmienić konstruktora
    }
}
```

**WŁAŚCIWE**
```csharp
public class Pager
{
    private IPrinter _printer;

    public Pager()
    {
        _printer = new NetworkPrinter();
    }

    public void SupersedePrinter(IPrinter printer)
    {
        _printer = printer;
    }
}

// test
// var pager = new Pager();
// pager.SupersedePrinter(new FakePrinter());
```

---

## 21. Template Redefinition (redefinicja szablonu)

Klasę zamienia się w typ generyczny parametryzowany typem zależności, z ograniczeniem (constraint) na interfejs.

**NIEWŁAŚCIWE**
```csharp
public class AsyncReceptionPort
{
    private readonly CSocket _socket = new CSocket();

    public void Run()
    {
        _socket.Receive();
    }
}
```

**WŁAŚCIWE**
```csharp
public class AsyncReceptionPortImpl<TSocket>
    where TSocket : ISocket, new()
{
    private readonly TSocket _socket = new TSocket();

    public void Run()
    {
        _socket.Receive();
    }
}

public class AsyncReceptionPort : AsyncReceptionPortImpl<CSocket>
{
}

// test
// var port = new AsyncReceptionPortImpl<FakeSocket>();
```
