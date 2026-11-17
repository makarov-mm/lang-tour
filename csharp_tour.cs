#:property AllowUnsafeBlocks=true
#:property PublishAot=false
// Чтобы включить примеры C# 15 из раздела 15 (нужен .NET SDK 11), раскомментируйте строку:
// #define CSHARP15

// =====================================================================================
//  C# ДЛЯ C++-РАЗРАБОТЧИКА — тур по языку в одном файле, от простого к сложному
// =====================================================================================
//
//  Запуск (нужен .NET SDK 10 или новее). Проект не требуется: это «файловая программа»,
//  а строки `#:property` в начале файла — её настройки.
//
//      dotnet run csharp_tour.cs
//
//  Что означают настройки:
//    AllowUnsafeBlocks — разрешить unsafe-код и указатели (разделы 10 и 11);
//    PublishAot=false  — файловые программы по умолчанию готовятся к компиляции в нативный
//                        код (Native AOT), а тур использует рефлексию и dynamic (раздел 14),
//                        которые с AOT несовместимы.
//
//  Сборка обычным проектом: `dotnet new console`, заменить Program.cs этим файлом, добавить
//  в .csproj <AllowUnsafeBlocks>true</AllowUnsafeBlocks> и удалить обе строки `#:property`.
//
//  Проверено: .NET SDK 10.0.115, язык C# 14. Примеры C# 15 (.NET 11) в конце файла
//  выключены символом CSHARP15 и при проверке НЕ компилировались: в среде проверки был
//  только SDK 10. Их синтаксис взят из документации Microsoft «What's new in C# 15».
//
//  Как читать. Каждый раздел — статический класс `SectionNN_*` с методом Run; типы, нужные
//  разделу, объявлены прямо перед ним. Пометка «C++:» показывает ближайший аналог в C++.
//  Закомментированные строки с кодом ошибки (CS0266 и т.п.) — то, что компилятор отвергнет.
//
//  Главные отличия от C++, которые стоит держать в голове с первой строки:
//
//   1. Управляемая среда. Код компилируется в байт-код (IL), а в машинный код его
//      превращает JIT-компилятор при запуске. Памятью управляет сборщик мусора (GC):
//      `delete` нет, а висячих ссылок, двойного освобождения и выхода за границы массива
//      в безопасном коде не бывает — вместо UB всегда исключение.
//   2. Поведение при копировании задаёт сам ТИП, а не место использования: `class` —
//      ссылочный тип (объект в куче, переменная хранит ссылку), `struct` — значимый
//      (копируется целиком). В C++ это одно и то же; здесь — главное различие (раздел 2).
//   3. Детерминированных деструкторов нет. RAII заменяют IDisposable и `using` (раздел 9).
//   4. Нет заголовков, прототипов и порядка объявлений. Единица компиляции — сборка
//      (assembly): типы видят друг друга независимо от порядка и файла.
//   5. Обобщения (generics) — не шаблоны: тело проверяется один раз по ограничениям
//      `where`, а не при каждой подстановке; специализаций и вычислений над типами нет,
//      зато обобщённые типы существуют во время выполнения (раздел 6).
//   6. Одиночное наследование классов и множественная реализация интерфейсов; у всех
//      типов общий предок — System.Object.
//   7. О типах всё известно во время выполнения: рефлексия, атрибуты, генерация кода
//      на лету (раздел 14). В C++ рефлексия появляется только в C++26, и та статическая.
//   8. Препроцессора в смысле C++ нет: ни макросов, ни #include — только #if и #define.
//
//  Содержание:
//    1. Основы: типы, переменные, строки              9. Ошибки, ресурсы, GC, null-безопасность
//    2. Значимые и ссылочные типы                    10. Память и скорость: Span, ref, SIMD
//    3. Классы, свойства, записи (records)           11. unsafe-код и вызов нативных функций
//    4. Наследование и интерфейсы                    12. Потоки и синхронизация
//    5. Сопоставление с образцом                     13. async/await
//    6. Обобщения (generics)                         14. Рефлексия, атрибуты, генерация кода
//    7. Делегаты, лямбды, события                    15. Новейшее: C# 12–14 и C# 15
//    8. Коллекции, итераторы, LINQ
// =====================================================================================

// `using` открывает пространство имён. C++: using namespace. Подключать файлы не нужно:
// типы берутся из сборок, на которые ссылается проект. Шаблон консольного проекта и
// файловые программы включают «неявные using» (System, System.Linq, System.Threading.Tasks
// и ещё несколько); здесь всё перечислено явно, чтобы было видно, что откуда берётся.
using System;
using System.Buffers;
using System.Buffers.Binary;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Frozen;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Linq.Expressions;
using System.Numerics;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;
using System.Runtime.Intrinsics.X86;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Channels;
using System.Threading.Tasks;
using static Tour; // using static: члены статического класса Tour доступны без его имени
using Coordinates = (double Latitude, double Longitude); // псевдоним типа (C++: using X = ...)

// =====================================================================================
//  ТОЧКА ВХОДА
// =====================================================================================
// Операторы верхнего уровня (C# 9): компилятор сам завернёт этот код в метод Main.
// C++: int main(). Объявления типов обязаны идти ПОСЛЕ этих операторов.

// Консоль Windows по умолчанию не в UTF-8: без этой строки не-ASCII символы станут «?».
Console.OutputEncoding = Encoding.UTF8;

// Числа и даты по умолчанию форматируются по региональным настройкам ОС («3,5» или «3.5»).
// Фиксируем инвариантную культуру, чтобы вывод был одинаковым на любой машине.
CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture; // для потоков пула

Section01_Basics.Run();
Section02_ValueAndReferenceTypes.Run();
Section03_Classes.Run();
Section04_Inheritance.Run();
Section05_PatternMatching.Run();
Section06_Generics.Run();
Section07_Delegates.Run();
Section08_CollectionsAndLinq.Run();
Section09_ErrorsAndResources.Run();
Section10_MemoryAndPerformance.Run();
Section11_UnsafeAndInterop.Run();
Section12_Threads.Run();
await Section13_AsyncAwait.RunAsync(); // await разрешён прямо на верхнем уровне
Section14_Reflection.Run();
Section15_Newest.Run();
#if CSHARP15
CSharp15.Demo.Run();
#endif

Console.WriteLine("\nAll 15 sections completed.");

// static class — «контейнер» статических членов: экземпляр создать нельзя.
// Свободных функций в C# нет: любой метод принадлежит какому-нибудь типу.
static class Tour
{
    // Метод-выражение (`=>`) — сокращённая запись тела из одного выражения.
    public static void Header(int number, string title) =>
        Console.WriteLine($"\n=== {number,2}. {title} ===");

    // Склеить элементы последовательности — пригодится во всех разделах.
    public static string Join<T>(IEnumerable<T> items, string separator = ", ") =>
        string.Join(separator, items);
}

// =====================================================================================
//  1. ОСНОВЫ: типы, переменные, строки, управление потоком
// =====================================================================================

// enum — именованные константы целого типа со строгой типизацией. C++: enum class.
enum Color : byte { Red, Green, Blue }

// [Flags] — атрибут: «это набор битовых флагов». Влияет на ToString() и разбор.
[Flags]
enum Permissions { None = 0, Read = 1, Write = 2, Execute = 4, All = Read | Write | Execute }

static class Section01_Basics
{
    // const — константа времени компиляции (числа, bool, char, string, enum). C++: constexpr.
    const int MaxPoints = 100_000; // `_` — разделитель разрядов (C++: 100'000)

    // static readonly — значение вычисляется один раз, при инициализации типа.
    static readonly double Tau = 2 * Math.PI;

    public static void Run()
    {
        Header(1, "Basics: types, variables, strings, control flow");

        // --- Встроенные типы ------------------------------------------------------------
        // Размеры ФИКСИРОВАНЫ на всех платформах (в C++ зависят от компилятора и ОС):
        // sbyte/byte — 8 бит, short/ushort — 16, int/uint — 32, long/ulong — 64,
        // nint/nuint — размер указателя, float — 32, double — 64, char — 16 (UTF-16!).
        int a = 42;
        var d = 3.5;              // var: тип выводится (double). C++: auto
        long big = 9_000_000_000;
        float f = 2.5f;
        decimal price = 19.99m;   // 128-битное ДЕСЯТИЧНОЕ число для денег; в C++ аналога нет
        char letter = 'я';        // 16-битная единица UTF-16 (в C++ char — один байт)
        bool flag = true;         // bool не преобразуется в число: `if (a)` — ошибка компиляции
        byte b = 0xFF;
        nint native = -1;         // C++: intptr_t
        Console.WriteLine($"{a} {d} {big} {f} {price} {letter} {flag} {b} {native}");
        Console.WriteLine($"sizeof: char {sizeof(char)}, int {sizeof(int)}, long {sizeof(long)}, " +
                          $"decimal {sizeof(decimal)}, nint {nint.Size}");
        Console.WriteLine($"0.1 + 0.2 == 0.3: double {0.1 + 0.2 == 0.3}, decimal {0.1m + 0.2m == 0.3m}" +
                          $" | MaxPoints {MaxPoints}, Tau {Tau:F4}");

        // Локальную переменную нельзя прочитать до присваивания: ошибка КОМПИЛЯЦИИ CS0165
        // (в C++ — мусор и неопределённое поведение).
        //     int garbage;
        //     Console.WriteLine(garbage);

        // --- Преобразования и переполнение ----------------------------------------------
        double ratio = a / 5;      // целочисленное деление, как в C++: 8
        int truncated = (int)3.99; // явное приведение: 3
        long widened = a;          // расширение — неявное
        // int bad = 3.7;          // CS0266: неявного сужения нет (C++ молча отбросил бы дробь)

        // Переполнение ОПРЕДЕЛЕНО всегда: по умолчанию значение заворачивается (в C++ для
        // знаковых типов это UB), а в контексте checked — бросается исключение.
        int max = int.MaxValue;
        int wrapped = unchecked(max + 1);
        string overflow;
        try
        {
            checked { max++; }
            overflow = "no exception";
        }
        catch (OverflowException)
        {
            overflow = "OverflowException";
        }
        Console.WriteLine($"{ratio} {truncated} {widened} {wrapped} {overflow}");

        // --- Строки -----------------------------------------------------------------------
        // string — НЕИЗМЕНЯЕМАЯ последовательность единиц UTF-16; ссылочный тип, который
        // сравнивается по содержимому. C++: ближе к shared_ptr<const u16string>, чем к std::string.
        string name = "World";
        string greeting = $"Hello, {name}!"; // интерполяция. C++: std::format
        string path = @"C:\dir\file";        // «дословная» строка: без экранирования
        string json = """
            {"kind": "raw string", "escaping": "not needed"}
            """; // raw-строка (C# 11): общий отступ срезается по закрывающим кавычкам
        string template = $$"""{"value": {{a}}}"""; // $$: подстановка в двойных скобках
        Console.WriteLine($"{greeting} | {greeting.Length} | {greeting.ToUpperInvariant()} | " +
                          $"{greeting[7..12]} | {greeting.Contains("World")}");
        Console.WriteLine($"{path} | {json} | {template}");

        string built = string.Concat("Hel", "lo"); // новая строка, созданная во время выполнения
        Console.WriteLine($"same text: {built == "Hello"}, same object: {ReferenceEquals(built, "Hello")}, " +
                          $"ignore case: {string.Equals(built, "HELLO", StringComparison.OrdinalIgnoreCase)}");

        // Каждая «правка» строки создаёт новую строку. Для сборки по частям — StringBuilder
        // (C++: std::string с += или std::ostringstream).
        var builder = new StringBuilder("[");
        for (int i = 1; i <= 5; i++) builder.Append(i).Append(i < 5 ? ", " : "]");
        Console.WriteLine(builder.ToString());

        // Форматирование: {значение,ширина:формат}.
        Console.WriteLine($"[{9.87654,8:F3}] [{"ab",-6}] [{255:X4}] [{0.256:P1}] [{1234567.891:N2}] " +
                          $"[{42:D5}] [{1234.5:E2}] [{7:+0;-0}]");

        // Length считает 16-битные единицы, а не символы: эмодзи — это две единицы.
        string mixed = "aя😀";
        Console.WriteLine($"UTF-16 units {mixed.Length}, code points {mixed.EnumerateRunes().Count()}, " +
                          $"UTF-8 bytes {Encoding.UTF8.GetByteCount(mixed)}");

        // --- Nullable-значения: `int?` — это Nullable<int>. C++: std::optional<int> ---------
        int? maybe = null;
        int fallback = maybe ?? -1; // ?? — «взять правое, если слева null»
        maybe ??= 10;               // присвоить, только если сейчас null
        Console.WriteLine($"{fallback} {maybe} {maybe.HasValue} {maybe.Value + 1}");

        // --- Массивы ----------------------------------------------------------------------
        // Массив — объект в куче: знает свою длину, границы проверяются при каждом обращении.
        int[] primes = [2, 3, 5, 7, 11]; // выражение-коллекция (C# 12)
        int[] alias = primes;            // копируется ССЫЛКА: это тот же массив (std::array скопировался бы)
        alias[0] = 100;
        int[] copy = [.. primes];        // а это копия: `..` разворачивает коллекцию (spread)
        copy[1] = -1;
        // ^1 — индекс от конца, 1..^1 — диапазон; срез массива создаёт НОВЫЙ массив.
        Console.WriteLine($"{primes[0]} {primes[1]} | length {primes.Length} | last {primes[^1]} | " +
                          $"middle [{Join(primes[1..^1])}]");
        try
        {
            _ = primes[10]; // `_` — «значение не нужно» (discard)
        }
        catch (IndexOutOfRangeException e)
        {
            Console.WriteLine($"primes[10] -> {e.GetType().Name}, not undefined behaviour");
        }

        int[,] grid = new int[2, 3];               // прямоугольный массив: один блок памяти
        grid[1, 2] = 7;
        int[][] jagged = [[1], [2, 3], [4, 5, 6]]; // «зубчатый»: массив массивов (vector<vector<int>>)
        Console.WriteLine($"grid {grid.GetLength(0)}x{grid.GetLength(1)}, grid[1, 2] = {grid[1, 2]}, " +
                          $"jagged[2].Length = {jagged[2].Length}");

        // --- Управление потоком -----------------------------------------------------------
        // if / while / do / for — как в C++, но условие обязано иметь тип bool.
        int sum = 0;
        for (int i = 0; i < 5; i++) sum += i;
        foreach (int p in primes) sum += p; // C++: range-for

        // switch-оператор: «проваливания» из ветки в ветку нет — нужен break или return.
        string kind;
        switch (letter)
        {
            case 'a':
            case 'e':
            case 'o': // несколько меток на одну ветку — можно
                kind = "latin vowel";
                break;
            case >= 'а' and <= 'я': // в case допустимы образцы (раздел 5)
                kind = "cyrillic letter";
                break;
            default:
                kind = "something else";
                break;
        }

        // switch-ВЫРАЖЕНИЕ (C# 8) возвращает значение.
        string size = a switch { < 10 => "small", < 100 => "medium", _ => "large" };
        Console.WriteLine($"sum {sum}, '{letter}' is a {kind}, {a} is {size}");

        // --- Кортежи. C++: std::tuple и структурные привязки ------------------------------
        (int quotient, int remainder) = Math.DivRem(17, 5);
        var point = (X: 3, Y: 4); // элементам можно дать имена
        (int x, int y) = point;   // деконструкция
        (x, y) = (y, x);          // обмен значений без временной переменной
        Coordinates munich = (48.137, 11.575);
        Console.WriteLine($"17 / 5 = {quotient} rem {remainder} | {point} | swapped ({x}, {y}) | " +
                          $"equal: {point == (3, 4)} | latitude {munich.Latitude}");

        // --- Перечисления -----------------------------------------------------------------
        Color color = Color.Green;
        Permissions rights = Permissions.Read | Permissions.Write;
        Console.WriteLine($"{color} = {(int)color}, parsed {Enum.Parse<Color>("Blue")}, " +
                          $"all: {Join(Enum.GetValues<Color>(), "/")}");
        Console.WriteLine($"{rights} | can write: {rights.HasFlag(Permissions.Write)} | " +
                          $"can execute: {(rights & Permissions.Execute) != 0} | All = {(int)Permissions.All}");
    }
}

// =====================================================================================
//  2. ЗНАЧИМЫЕ И ССЫЛОЧНЫЕ ТИПЫ
// =====================================================================================
//
//  В C++ любой тип — значение, а «ссылочность» выбирают в месте использования: T, T&, T*.
//  В C# наоборот — поведение зашито в сам тип:
//
//    struct (а также int, double, bool, enum, кортежи) — ЗНАЧИМЫЙ тип. Переменная хранит
//      сами данные; присваивание и передача в метод их копируют. Значение живёт на стеке
//      или прямо внутри объекта или массива, которому принадлежит.
//
//    class (а также string, массивы, делегаты) — ССЫЛОЧНЫЙ тип. Объект лежит в управляемой
//      куче, переменная хранит ссылку; присваивание копирует ссылку. Ближайшая аналогия —
//      shared_ptr<T>, только без счётчика: недостижимые объекты находит и удаляет GC.

struct PointStruct
{
    public double X, Y; // публичные поля — для краткости; обычно пишут свойства (раздел 3)

    // override — переопределение виртуального метода базового типа (здесь — object).
    public override readonly string ToString() => $"({X}, {Y})";
}

class PointClass
{
    public double X, Y;

    public override string ToString() => $"({X}, {Y})";
}

static class Section02_ValueAndReferenceTypes
{
    // Аргумент — всегда копия ПЕРЕМЕННОЙ: для struct это копия данных, для class — копия ссылки.
    static void MoveStruct(PointStruct p) => p.X += 10; // меняется локальная копия
    static void MoveClass(PointClass p) => p.X += 10;   // меняется общий объект

    // ref — параметр-псевдоним переменной вызывающего. C++: T&.
    static void MoveByRef(ref PointStruct p) => p.X += 10;

    // in — ссылка только для чтения, без копирования. C++: const T&.
    static double Length(in PointStruct p) => Math.Sqrt(p.X * p.X + p.Y * p.Y);

    // out — «выходной» параметр: метод обязан его присвоить. Идиома Try...: признак успеха
    // возвращается как bool, результат — через out. C++: bool f(T& result) или std::optional.
    static bool TryParsePoint(string text, out PointStruct point)
    {
        point = default; // default — «нулевое» значение любого типа
        string[] parts = text.Split(',');
        return parts.Length == 2
            && double.TryParse(parts[0], CultureInfo.InvariantCulture, out point.X)
            && double.TryParse(parts[1], CultureInfo.InvariantCulture, out point.Y);
    }

    // Массив создаётся в отдельном методе: когда метод вернулся, ссылок на массив больше
    // нет нигде. (NoInlining запрещает JIT-компилятору встроить метод в вызывающий.)
    [MethodImpl(MethodImplOptions.NoInlining)]
    static long AllocateAndForget()
    {
        var garbage = new byte[10_000_000];
        garbage[0] = 1;
        return GC.GetTotalMemory(forceFullCollection: false);
    }

    public static void Run()
    {
        Header(2, "Value and reference types");

        // --- Копирование ------------------------------------------------------------------
        var s1 = new PointStruct { X = 1, Y = 2 }; // инициализатор объекта
        var s2 = s1; // КОПИЯ всех полей
        s2.X = 100;
        var c1 = new PointClass { X = 1, Y = 2 };
        var c2 = c1; // копия ССЫЛКИ: c1 и c2 — один и тот же объект
        c2.X = 100;
        Console.WriteLine($"struct: s1 = {s1}, s2 = {s2} | class: c1 = {c1}, c2 = {c2}, " +
                          $"same object: {ReferenceEquals(c1, c2)}");

        // --- Передача параметров ----------------------------------------------------------
        MoveStruct(s1); // s1 не изменится
        MoveClass(c1);  // объект изменится
        Console.WriteLine($"after Move: s1 = {s1}, c1 = {c1}");
        MoveByRef(ref s1); // `ref` пишут и в месте вызова: передачу по ссылке видно глазами
        // Аргументы вычисляются строго слева направо (в C++ порядок не определён), поэтому
        // переменную parsed можно объявить в одном аргументе и использовать в следующем.
        Console.WriteLine($"after MoveByRef: s1 = {s1}, length {Length(in s1):F3} | " +
                          $"{TryParsePoint("3, 4", out var parsed)} {parsed} | {TryParsePoint("oops", out _)}");

        // --- Сравнение --------------------------------------------------------------------
        // Для классов == по умолчанию сравнивает ССЫЛКИ (как указатели). Сравнение по
        // содержимому нужно определить самому — или взять record (раздел 3).
        var c3 = new PointClass { X = c1.X, Y = c1.Y };
        Console.WriteLine($"c1 == c3: {c1 == c3}, struct Equals compares fields: {s1.Equals(s1 with { })}");

        // --- Упаковка (boxing) ------------------------------------------------------------
        // Значимый тип можно привести к object или интерфейсу: значение КОПИРУЕТСЯ в новый
        // объект в куче. Это скрытая аллокация — в горячем коде её избегают (обобщения!).
        int number = 42;
        object boxed = number;    // упаковка
        number = 43;              // на упакованную копию не влияет
        int unboxed = (int)boxed; // распаковка: проверка типа и копирование обратно
        Console.WriteLine($"boxed {boxed}, unboxed {unboxed}, number {number}, type {boxed.GetType().Name}, " +
                          $"is int: {boxed is int}, is long: {boxed is long}");

        // --- null -------------------------------------------------------------------------
        // Ссылка может быть null; `?` после типа говорит об этом компилятору (раздел 9).
        // Обращение через null — всегда исключение NullReferenceException, а не UB.
        PointClass? nothing = null;
        Console.WriteLine($"nothing?.X is null: {nothing?.X is null}, default(int) = {default(int)}, " +
                          $"default(PointStruct) = {default(PointStruct)}");
        try
        {
            Console.WriteLine(nothing!.X); // `!` — «ручаюсь, что не null» (и напрасно)
        }
        catch (NullReferenceException)
        {
            Console.WriteLine("NullReferenceException instead of undefined behaviour");
        }

        // --- Где лежат данные -------------------------------------------------------------
        // Массив структур — один сплошной блок памяти (как std::vector<Point>). Массив
        // объектов класса — блок ССЫЛОК на отдельные объекты (как vector<shared_ptr<Point>>).
        var structs = new PointStruct[1000]; // 16 000 байт; все точки уже существуют (нулевые)
        var classes = new PointClass[1000];  // 1000 ссылок, пока все null
        Console.WriteLine($"structs[0] = {structs[0]}, classes[0] is null: {classes[0] is null}, " +
                          $"size of PointStruct: {Unsafe.SizeOf<PointStruct>()} bytes");

        // --- Сборщик мусора ---------------------------------------------------------------
        // Объект жив, пока достижим по ссылкам. Освобождать ничего не нужно, но и момент
        // освобождения не определён: деструкторов в смысле C++ нет (раздел 9).
        long before = GC.GetTotalMemory(forceFullCollection: true); // именованный аргумент
        long during = AllocateAndForget(); // 10 МБ выделены и тут же стали мусором
        long after = GC.GetTotalMemory(forceFullCollection: true);
        Console.WriteLine($"allocated ~{(during - before) / 1_000_000} MB, " +
                          $"after collection ~{(after - before) / 1_000_000} MB");
    }
}

// =====================================================================================
//  3. КЛАССЫ, СВОЙСТВА, ЗАПИСИ (RECORDS)
// =====================================================================================

// readonly record struct: неизменяемый значимый тип в одну строку. Компилятор генерирует
// конструктор, свойства X и Y, Equals/GetHashCode/==, ToString и деконструкцию.
// C++: struct с `operator<=>(...) = default` и вручную написанным выводом.
readonly record struct Vec2(double X, double Y)
{
    public static readonly Vec2 Zero = new(0, 0);

    // Свойство без хранилища: вычисляется при каждом обращении.
    public double LengthSquared => X * X + Y * Y;
    public double Length => Math.Sqrt(LengthSquared);

    // Перегрузка операторов: всегда public static. C++: свободная функция или член класса.
    public static Vec2 operator +(Vec2 a, Vec2 b) => new(a.X + b.X, a.Y + b.Y);
    public static Vec2 operator -(Vec2 a, Vec2 b) => new(a.X - b.X, a.Y - b.Y);
    public static Vec2 operator *(Vec2 v, double k) => new(v.X * k, v.Y * k);
    public static Vec2 operator -(Vec2 v) => new(-v.X, -v.Y);

    // Пользовательские преобразования: implicit — неявное, explicit — только через приведение.
    // C++: конструктор без explicit и `explicit operator double()`.
    public static implicit operator Vec2((double X, double Y) tuple) => new(tuple.X, tuple.Y);
    public static explicit operator double(Vec2 v) => v.Length;

    // Сгенерированный ToString перечислил бы все свойства; любой сгенерированный член
    // можно заменить своим.
    public override string ToString() => $"({X}, {Y})";
}

// Класс: объявление и определение — в одном месте, порядок членов не важен.
// Модификатор доступа пишут у КАЖДОГО члена (по умолчанию — private).
class Particle
{
    private static int _created; // static: одно поле на тип

    // Свойство — пара методов get/set, которая выглядит как поле. В C++ аналога нет:
    // там пишут getX()/setX(). Автосвойство само заводит скрытое поле-хранилище.
    public string Name { get; }               // только чтение: задаётся в конструкторе
    public double Mass { get; private set; }  // читать могут все, менять — только сам класс
    public Vec2 Position { get; set; }
    public Vec2 Velocity { get; set; } = Vec2.Zero; // инициализатор

    // Свойство с проверкой. `field` (C# 14) — то самое скрытое поле автосвойства.
    public double Charge
    {
        get;
        set => field = Math.Clamp(value, -1, 1);
    }

    // required: вызывающий ОБЯЗАН задать свойство в инициализаторе объекта;
    // init: задать можно только там, потом свойство неизменяемо.
    public required string Kind { get; init; }

    // Вычисляемое свойство.
    public double KineticEnergy => 0.5 * Mass * Velocity.LengthSquared;

    public static int Created => _created;

    public Particle(string name, double mass)
    {
        Name = name;
        Mass = mass;
        _created++;
    }

    // Делегирование другому конструктору. C++: Particle(string n) : Particle(n, 1.0) {}
    public Particle(string name) : this(name, 1.0) { }

    public void Advance(double dt) => Position += Velocity * dt;

    // Деконструкция: позволяет писать `var (name, mass) = particle;`.
    public void Deconstruct(out string name, out double mass) => (name, mass) = (Name, Mass);

    // C++: operator<< или специализация std::formatter.
    public override string ToString() => $"{Kind} '{Name}' at ({Position.X}, {Position.Y})";
}

// record (class): ссылочный тип с семантикой значения — сравнение по содержимому
// и «неразрушающее изменение» через with. Записи можно наследовать.
record Employee(string Name, string Department, decimal Salary);

record Manager(string Name, string Department, decimal Salary, int Reports)
    : Employee(Name, Department, Salary);

// Первичный конструктор класса (C# 12): параметры видны во всём теле класса.
class Counter(string name, int start = 0) // параметр со значением по умолчанию
{
    private int _value = start;

    public string Name => name;

    public int Next() => ++_value;
}

// params — переменное число аргументов. C++: вариативный шаблон или initializer_list.
class Polynomial(params double[] coefficients)
{
    private readonly double[] _c = coefficients; // readonly: поле нельзя переприсвоить

    public int Degree => _c.Length - 1;

    // Индексатор. C++: operator[].
    public double this[int power] => power < _c.Length ? _c[power] : 0.0;

    public double Evaluate(double x)
    {
        double result = 0;
        for (int i = Degree; i >= 0; i--) result = result * x + _c[i]; // схема Горнера
        return result;
    }

    public static Polynomial operator +(Polynomial a, Polynomial b)
    {
        var sum = new double[Math.Max(a._c.Length, b._c.Length)];
        for (int i = 0; i < sum.Length; i++) sum[i] = a[i] + b[i];
        return new Polynomial(sum);
    }

    public override string ToString() =>
        Join(_c.Select((c, power) => power == 0 ? $"{c}" : $"{c}x^{power}"), " + ");
}

static class Section03_Classes
{
    public static void Run()
    {
        Header(3, "Classes, properties, records");

        // Объект класса создаётся только через new и только в куче; delete не существует.
        var electron = new Particle("electron", 9.109e-31)
        {
            Kind = "lepton", // инициализатор объекта: присваивания свойствам сразу после конструктора
            Velocity = new Vec2(2e6, 0),
            Charge = -5, // сеттер ограничит значение диапазоном [-1, 1]
        };
        electron.Advance(1e-6);
        // electron.Name = "x";       // CS0200: у свойства нет сеттера
        // _ = new Particle("x");     // CS9035: не задано обязательное свойство Kind
        var (particleName, mass) = electron; // пользовательская деконструкция
        Console.WriteLine($"{electron} | charge {electron.Charge} | E = {electron.KineticEnergy:E3} J | " +
                          $"{particleName}, {mass:E3} kg | created: {Particle.Created}");

        // --- Запись-структура -------------------------------------------------------------
        Vec2 v = new(3, 4);             // new с выводом типа из левой части
        Vec2 w = (1, 1);                // implicit operator из кортежа
        Vec2 moved = v with { X = 30 }; // копия с изменённым свойством
        var (vx, vy) = v;               // деконструкция, сгенерированная для record
        Console.WriteLine($"{v + w * 2} | {-v} | length {(double)v} | {moved} | {vx}, {vy} | " +
                          $"equal: {v == new Vec2(3, 4)}");

        // --- Записи-классы ----------------------------------------------------------------
        var alice = new Employee("Alice", "R&D", 5200m);
        var twin = new Employee("Alice", "R&D", 5200m);
        var promoted = alice with { Salary = 6000m };
        Employee boss = new Manager("Bob", "R&D", 9000m, Reports: 7); // именованный аргумент
        Console.WriteLine($"equal by value: {alice == twin}, same object: {ReferenceEquals(alice, twin)}");
        Console.WriteLine($"{promoted} | {boss}");

        // --- Первичный конструктор, params, индексатор, операторы -------------------------
        var counter = new Counter("requests", start: 10);
        counter.Next();
        var polynomial = new Polynomial(1, 2, 3) + new Polynomial(0, 0, 0, 4);
        Console.WriteLine($"{counter.Name}: {counter.Next()} | p(x) = {polynomial} | degree {polynomial.Degree} | " +
                          $"p[2] = {polynomial[2]} | p(2) = {polynomial.Evaluate(2)}");

        // Уровни доступа: public; private (по умолчанию для членов); protected; internal —
        // «в пределах сборки» (по умолчанию для типов); protected internal; private protected;
        // file — тип виден только в своём файле (C# 11).
    }
}

// =====================================================================================
//  4. НАСЛЕДОВАНИЕ И ИНТЕРФЕЙСЫ
// =====================================================================================

// Абстрактный класс. Наследование всегда «публичное»; базовый класс может быть только один.
abstract class Shape
{
    // Абстрактное свойство. C++: virtual double area() const = 0;
    public abstract double Area { get; }

    // virtual — как в C++: без этого слова метод невиртуальный.
    public virtual string Name => "shape";

    // Невиртуальный метод, вызывающий виртуальные члены.
    public string Describe() => $"{Name} with area {Area:F2}";

    // Виртуальный деструктор не нужен: деструкторов нет, память освобождает GC.
}

// sealed — запрет наследования (C++: final). Первичный конструктор хранит radius.
sealed class Circle(double radius) : Shape
{
    public double Radius => radius;

    // override ОБЯЗАТЕЛЕН (в C++ — лишь рекомендуется).
    public override double Area => Math.PI * radius * radius;
    public override string Name => "circle";
}

class Rectangle(double width, double height) : Shape
{
    public double Width { get; } = width;
    public double Height { get; } = height;

    public override double Area => Width * Height;
    public override string Name => "rectangle";
}

// Вызов конструктора базового класса. C++: Square(double s) : Rectangle(s, s) {}
sealed class Square(double side) : Rectangle(side, side)
{
    // base — обращение к реализации базового класса. C++: Rectangle::name().
    public override string Name => $"square, a {base.Name}";
}

// Интерфейс — контракт без состояния. Класс наследует ОДИН класс, но реализует сколько
// угодно интерфейсов. C++: абстрактный класс из одних чисто виртуальных функций.
interface IDrawable
{
    string Draw();

    // Метод с реализацией по умолчанию (C# 8): интерфейс можно расширять, не ломая
    // существующие реализации. Доступен только через ссылку на интерфейс.
    string DrawTwice() => Draw() + Draw();
}

interface IExportable
{
    string Export();
}

class Label(string text) : IDrawable, IExportable
{
    public string Draw() => $"[{text}]";

    // Явная реализация интерфейса: метод виден только через ссылку типа IExportable.
    // Так разрешают конфликты имён между интерфейсами.
    string IExportable.Export() => $"{{\"label\": \"{text}\"}}"; // {{ }} — экранированные скобки
}

// Сокрытие и переопределение.
class Animal
{
    public virtual string Speak() => "...";
    public string Kind() => "animal";
}

class Dog : Animal
{
    public override string Speak() => "Woof"; // переопределение: работает через ссылку на базу
    public new string Kind() => "dog";        // new: СОКРЫТИЕ невиртуального метода (как в C++)
}

// Порядок инициализации отличается от C++: инициализаторы полей наследника выполняются
// ДО конструктора базы, а виртуальный вызов из конструктора базы попадает в наследника.
class BaseWidget
{
    public BaseWidget() => Console.WriteLine($"    BaseWidget ctor sees {Who()}");

    public virtual string Who() => "BaseWidget";
}

class DerivedWidget : BaseWidget
{
    private readonly string _fromInitializer = "set";
    private readonly string? _fromConstructor;

    public DerivedWidget() => _fromConstructor = "set";

    public override string Who() =>
        $"DerivedWidget (initializer: {_fromInitializer}, constructor: {_fromConstructor ?? "not yet"})";
}

static class Section04_Inheritance
{
    public static void Run()
    {
        Header(4, "Inheritance and interfaces");

        // Полиморфизм «из коробки»: переменная типа Shape — это уже ссылка, а объекты лежат
        // в куче. Никаких unique_ptr и никакой «срезки» (slicing).
        Shape[] shapes = [new Circle(1.0), new Rectangle(2.0, 3.0), new Square(2.0)];
        double total = 0;
        foreach (Shape shape in shapes)
        {
            total += shape.Area;
            Console.WriteLine(shape.Describe());
            // Проверка типа с объявлением переменной. C++: if (auto* c = dynamic_cast<Circle*>(p)).
            if (shape is Circle circle) Console.WriteLine($"    it is a circle of radius {circle.Radius}");
        }
        Console.WriteLine($"total area {total:F2}");

        // Приведения: `as` даёт null при неудаче, (T)x бросает InvalidCastException.
        Shape first = shapes[0];
        Rectangle? notRectangle = first as Rectangle;
        string castResult;
        try
        {
            castResult = ((Rectangle)first).Name;
        }
        catch (InvalidCastException)
        {
            castResult = "InvalidCastException";
        }
        Console.WriteLine($"as Rectangle is null: {notRectangle is null}, (Rectangle)circle -> {castResult}");

        // У всех типов общий предок object: ToString, Equals, GetHashCode, GetType.
        object anything = shapes[2];
        Console.WriteLine($"{anything.GetType().Name} : {anything.GetType().BaseType?.Name}, " +
                          $"is Shape: {anything is Shape}, is IDrawable: {anything is IDrawable}");

        // --- Интерфейсы -------------------------------------------------------------------
        var label = new Label("OK");
        IDrawable drawable = label;
        IExportable exportable = label;
        // label.Export();     // CS1061: явная реализация не видна через тип Label
        // label.DrawTwice();  // CS1061: метод по умолчанию виден только через интерфейс
        Console.WriteLine($"{label.Draw()} {drawable.DrawTwice()} {exportable.Export()}");

        // --- override и new ---------------------------------------------------------------
        Dog dog = new();
        Animal animal = dog;
        Console.WriteLine($"override: {animal.Speak()} / {dog.Speak()} | new: {animal.Kind()} / {dog.Kind()}");

        // --- Порядок инициализации ----------------------------------------------------------
        var widget = new DerivedWidget();
        Console.WriteLine($"    fully constructed: {widget.Who()}");
    }
}

// =====================================================================================
//  5. СОПОСТАВЛЕНИЕ С ОБРАЗЦОМ (PATTERN MATCHING)
// =====================================================================================
//
//  В C++ есть только структурные привязки и std::visit; сопоставление с образцом в стандарт
//  пока не вошло. В C# это большая часть языка: образцы проверяют тип, значения,
//  свойства и форму данных — и одновременно раскладывают их по переменным.

// Дерево выражения из записей: каждый узел — отдельный маленький тип.
abstract record Expr;
record Num(double Value) : Expr;
record Var(string Name) : Expr;
record Neg(Expr Operand) : Expr;
record Add(Expr Left, Expr Right) : Expr;
record Mul(Expr Left, Expr Right) : Expr;

static class Section05_PatternMatching
{
    static string Classify(object? value) => value switch
    {
        null => "null",
        int n when n < 0 => $"negative int {n}",            // образец типа + условие when
        0 or 1 => "bit",                                     // константы и логическое `or`
        int n => $"int {n}",
        double d and > 0 and < 1 => $"fraction {d}",         // относительные образцы и `and`
        string { Length: 0 } => "empty string",              // образец свойства
        string { Length: var length } => $"string of length {length}",
        Vec2(0, 0) => "origin",                              // позиционный образец (деконструкция)
        Vec2 { X: var x, Y: var y } when x == y => $"diagonal point {x}",
        int[] { Length: 0 } => "empty array",
        int[] and [var first, .., var last] => $"array {first}..{last}", // образец списка (C# 11)
        (int a, int b) => $"pair with sum {a + b}",          // кортеж
        Shape { Area: > 10 } shape => $"big {shape.Name}",   // свойство + имя для всего объекта
        not IDisposable => "something not disposable",       // отрицание
        _ => "something else",                               // образец «что угодно»
    };

    // Кортеж как предмет сопоставления: таблица решений без вложенных if.
    static string Play(string first, string second) => (first, second) switch
    {
        ("rock", "scissors") or ("scissors", "paper") or ("paper", "rock") => "first wins",
        _ when first == second => "draw",
        _ => "second wins",
    };

    // Рекурсивный обход дерева: позиционные образцы раскладывают записи на части.
    // Иерархия Expr открыта для наследования, поэтому без ветки `_` компилятор выдаст
    // предупреждение о неполном switch. (В C# 15 для этого есть `closed` и `union`:
    // с ними компилятор знает все варианты и ветка `_` не нужна.)
    static double Eval(Expr expr, IReadOnlyDictionary<string, double> variables) => expr switch
    {
        Num(var value) => value,
        Var(var name) => variables[name],
        Neg(var operand) => -Eval(operand, variables),
        Add(var left, var right) => Eval(left, variables) + Eval(right, variables),
        Mul(var left, var right) => Eval(left, variables) * Eval(right, variables),
        _ => throw new NotSupportedException(expr.GetType().Name),
    };

    // Вложенные образцы: алгебраические упрощения записываются почти как в учебнике.
    // Сначала упрощаются поддеревья, затем к паре результатов применяются правила.
    static Expr Simplify(Expr expr) => expr switch
    {
        Add(var l, var r) => (Simplify(l), Simplify(r)) switch
        {
            (Num(0), var right) => right,                    // 0 + x = x
            (var left, Num(0)) => left,                      // x + 0 = x
            (Num(var a), Num(var b)) => new Num(a + b),      // свёртка констант
            var (left, right) => new Add(left, right),
        },
        Mul(var l, var r) => (Simplify(l), Simplify(r)) switch
        {
            (Num(0), _) or (_, Num(0)) => new Num(0),        // 0 * x = 0
            (Num(1), var right) => right,                    // 1 * x = x
            (var left, Num(1)) => left,                      // x * 1 = x
            (Num(var a), Num(var b)) => new Num(a * b),
            var (left, right) => new Mul(left, right),
        },
        Neg(var operand) => Simplify(operand) switch
        {
            Neg(var inner) => inner,                         // -(-x) = x
            Num(var value) => new Num(-value),
            var simplified => new Neg(simplified),
        },
        _ => expr,
    };

    static string Show(Expr expr) => expr switch
    {
        Num(var value) => value.ToString(CultureInfo.InvariantCulture),
        Var(var name) => name,
        Neg(var operand) => $"-{Show(operand)}",
        Add(var left, var right) => $"({Show(left)} + {Show(right)})",
        Mul(var left, var right) => $"{Show(left)} * {Show(right)}",
        _ => "?",
    };

    public static void Run()
    {
        Header(5, "Pattern matching");

        object?[] samples =
        [
            null, -5, 1, 42, 0.25, "", "hello", new Vec2(0, 0), new Vec2(2, 2), Array.Empty<int>(),
            new[] { 1, 2, 3 }, (3, 4), new Square(4), new Circle(1), new MemoryStream(),
        ];
        foreach (object? sample in samples) Console.Write($"{Classify(sample)}; ");
        Console.WriteLine();

        // Образцы в условиях: `is` проверяет и одновременно объявляет переменные.
        Shape shape = new Circle(2);
        if (shape is Circle { Radius: > 1 and var radius }) Console.WriteLine($"a circle with radius {radius}");
        int age = 42;
        Console.WriteLine($"{age is >= 18 and < 65}, {shape is not Rectangle}, " +
                          $"{Play("rock", "scissors")}, {Play("paper", "paper")}, {Play("rock", "paper")}");

        // Образцы списков: начало, конец и «всё остальное».
        int[] numbers = [1, 2, 3, 4, 5];
        if (numbers is [var head, .. var middle, var tail])
        {
            Console.WriteLine($"head {head}, middle [{Join(middle)}], tail {tail}");
        }

        // -(x + 2) * 3 и выражение, которое полностью упрощается.
        Expr formula = new Mul(new Neg(new Add(new Var("x"), new Num(2))), new Num(3));
        Expr noisy = new Add(new Mul(new Num(1), new Var("x")), new Mul(new Var("y"), new Num(0)));
        var variables = new Dictionary<string, double> { ["x"] = 5 };
        Console.WriteLine($"{Show(formula)} = {Eval(formula, variables)} | " +
                          $"{Show(noisy)} simplifies to {Show(Simplify(noisy))}");
    }
}

// =====================================================================================
//  6. ОБОБЩЕНИЯ (GENERICS)
// =====================================================================================
//
//  Шаблон C++ — рецепт: для каждого набора аргументов генерируется новый код, а тело
//  проверяется при подстановке. Обобщение C# компилируется ОДИН раз, и внутри с T можно
//  делать только то, что разрешают ограничения `where`. Следствия:
//    + ошибки — в месте объявления, короткие; обобщённые типы видны рефлексии;
//    + для значимых типов JIT всё же создаёт отдельный машинный код (без упаковки),
//      для ссылочных — один общий;
//    − нет специализаций, параметров-значений (кроме типов) и вычислений над типами.

// Обобщённый класс, реализующий стандартный интерфейс перечисления.
class ArrayStack<T> : IEnumerable<T>
{
    private T[] _items = new T[4];
    private int _count;

    public int Count => _count;

    public void Push(T item)
    {
        if (_count == _items.Length) Array.Resize(ref _items, _count * 2); // передача по ref
        _items[_count++] = item;
    }

    // throw — выражение: его можно поставить в ветку тернарного оператора.
    public T Pop() => _count > 0 ? _items[--_count] : throw new InvalidOperationException("stack is empty");

    // Атрибут для анализатора null: «если метод вернул false, item может быть null».
    public bool TryPop([MaybeNullWhen(false)] out T item)
    {
        if (_count == 0)
        {
            item = default; // default(T): null для ссылочных типов, нули для значимых
            return false;
        }
        item = _items[--_count];
        return true;
    }

    // Чтобы тип работал в foreach и LINQ, достаточно GetEnumerator(). Метод с `yield return` —
    // итератор (раздел 8): компилятор сам построит конечный автомат.
    public IEnumerator<T> GetEnumerator()
    {
        for (int i = _count - 1; i >= 0; i--) yield return _items[i];
    }

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator(); // необобщённая версия интерфейса
}

// Вариантность. `out` — ковариантность: IProducer<Circle> годится там, где ждут
// IProducer<Shape>. `in` — контравариантность: IConsumer<Shape> годится как IConsumer<Circle>.
// В C++ шаблоны инвариантны: vector<Circle*> не преобразуется в vector<Shape*>.
interface IProducer<out T>
{
    T Produce();
}

interface IConsumer<in T>
{
    void Consume(T item);
}

class CircleFactory : IProducer<Circle>
{
    public Circle Produce() => new(1.0);
}

class ShapePrinter : IConsumer<Shape>
{
    public void Consume(Shape item) => Console.WriteLine($"    consumed {item.Describe()}");
}

// Статические абстрактные члены интерфейсов (C# 11): контракт на «статическую часть» типа.
// Параметр TSelf — тот же приём, что CRTP в C++.
interface IUnit<TSelf> where TSelf : IUnit<TSelf>
{
    static abstract string Symbol { get; }
    static abstract TSelf FromBase(double value);
    double Value { get; }
    double ToBase();
}

readonly record struct Meters(double Value) : IUnit<Meters>
{
    public static string Symbol => "m";
    public static Meters FromBase(double value) => new(value);
    public double ToBase() => Value;
}

readonly record struct Kilometers(double Value) : IUnit<Kilometers>
{
    public static string Symbol => "km";
    public static Kilometers FromBase(double value) => new(value / 1000);
    public double ToBase() => Value * 1000;
}

// Статический обобщённый класс: у каждого T свой экземпляр статических полей.
// Так делают «кеш по типу» — ближайшая замена специализации шаблона.
static class TypeDescription<T>
{
    public static readonly string Description =
        $"{typeof(T).Name} ({(typeof(T).IsValueType ? "value" : "reference")} type)";
}

static class Section06_Generics
{
    // Ограничение-интерфейс. C++: template <std::totally_ordered T>.
    static T MaxOf<T>(T a, T b) where T : IComparable<T> => a.CompareTo(b) >= 0 ? a : b;

    // new() — «у T есть конструктор без параметров»; class — «T — ссылочный тип».
    static T CreateDefault<T>() where T : class, new() => new T();

    // unmanaged — «плоский» тип без ссылок (C++: trivially copyable): для него работает sizeof.
    static unsafe int SizeOf<T>() where T : unmanaged => sizeof(T);

    // Обобщённая математика (C# 11): INumber<T> требует от T операторы и константы.
    // C++: шаблон с концептом. Работает для int, double, decimal, BigInteger, ...
    static T Sum<T>(IEnumerable<T> values) where T : INumber<T>
    {
        T total = T.Zero; // статический член, вызванный через параметр-тип
        foreach (T value in values) total += value;
        return total;
    }

    static T Average<T>(params ReadOnlySpan<T> values) where T : INumber<T> =>
        Sum(values.ToArray()) / T.CreateChecked(values.Length);

    // Преобразование единиц через статические абстрактные члены.
    static TTo ConvertUnit<TFrom, TTo>(TFrom value)
        where TFrom : IUnit<TFrom>
        where TTo : IUnit<TTo> => TTo.FromBase(value.ToBase());

    static string Format<T>(T quantity) where T : IUnit<T> => $"{quantity.Value} {T.Symbol}";

    public static void Run()
    {
        Header(6, "Generics");

        var stack = new ArrayStack<string>();
        foreach (string word in new[] { "alpha", "beta", "gamma" }) stack.Push(word);
        string top = stack.Pop();
        // stack реализует IEnumerable<T>, поэтому работают foreach, LINQ и string.Join.
        Console.WriteLine($"popped {top}, left [{Join(stack)}], longest: {stack.MaxBy(w => w.Length)}");
        var numbers = new ArrayStack<int>();
        Console.WriteLine($"TryPop on empty: {numbers.TryPop(out int missing)} (item = {missing})");

        // Аргументы-типы обычно выводятся из аргументов вызова.
        Console.WriteLine($"{MaxOf(3, 7)} {MaxOf("apple", "pear")} {MaxOf(2.5, 1.5)} | " +
                          $"{CreateDefault<StringBuilder>().Append("created").Length} | " +
                          $"sizeof: {SizeOf<int>()} {SizeOf<Vec2>()} {SizeOf<Guid>()}");
        // MaxOf(new object(), new object()); // CS0311: object не реализует IComparable<object>

        // Обобщённая математика: один метод для любых числовых типов.
        BigInteger[] huge = [1, BigInteger.Pow(2, 100)];
        Console.WriteLine($"{Sum(new[] { 1, 2, 3 })} {Sum(new[] { 0.5, 1.5 })} {Sum(new[] { 0.1m, 0.2m })} | " +
                          $"{Average(1.0, 2.0, 6.0)} {Average(10, 20)} | {Sum(huge)}");

        // Статические абстрактные члены.
        var distance = new Kilometers(1.5);
        Meters inMeters = ConvertUnit<Kilometers, Meters>(distance);
        Console.WriteLine($"{Format(distance)} = {Format(inMeters)} | record text: {inMeters}");

        // Вариантность.
        IProducer<Shape> producer = new CircleFactory();    // ковариантность: Circle -> Shape
        IConsumer<Circle> consumer = new ShapePrinter();    // контравариантность: Shape <- Circle
        consumer.Consume(new CircleFactory().Produce());
        IEnumerable<Shape> shapes = new List<Circle> { new(1), new(2) }; // IEnumerable<out T>
        Console.WriteLine($"produced {producer.Produce().Name}, {shapes.Count()} circles seen as shapes");

        // Обобщённые типы существуют во время выполнения: их можно исследовать и создавать.
        Type open = typeof(Dictionary<,>); // «открытый» тип: аргументы ещё не заданы
        Type constructed = open.MakeGenericType(typeof(string), typeof(int));
        Console.WriteLine($"{open.Name} -> [{Join(constructed.GetGenericArguments().Select(t => t.Name))}] | " +
                          $"{TypeDescription<int>.Description} | {TypeDescription<string>.Description}");
    }
}

// =====================================================================================
//  7. ДЕЛЕГАТЫ, ЛЯМБДЫ, СОБЫТИЯ
// =====================================================================================

// Делегат — тип «ссылка на метод»: хранит указатель на код и, если нужно, объект.
// C++: std::function<double(double, double)>.
delegate double BinaryOperation(double a, double b);

class Thermostat
{
    private double _temperature;

    // Событие — список подписчиков. Снаружи класса с ним можно делать только += и -=,
    // вызвать его может лишь сам класс. C++: сигналы и слоты, написанные вручную.
    public event Action<double, double>? TemperatureChanged; // (старое значение, новое значение)
    public event EventHandler<string>? Alarm;                // стандартная форма: (sender, args)

    public double Temperature
    {
        get => _temperature;
        set
        {
            if (value == _temperature) return;
            double old = _temperature;
            _temperature = value;
            TemperatureChanged?.Invoke(old, value); // `?.` — вызвать, только если есть подписчики
            if (value > 30) Alarm?.Invoke(this, $"overheating: {value}");
        }
    }
}

static class Section07_Delegates
{
    static double Power(double a, double b) => Math.Pow(a, b);

    // Функция высшего порядка. Func<T, TResult> и Action<T> — готовые обобщённые делегаты.
    static int ApplyTwice(Func<int, int> f, int x) => f(f(x));

    // Вернуть функцию из функции.
    static Func<int, int> MakeAdder(int n) => x => x + n;

    public static void Run()
    {
        Header(7, "Delegates, lambdas, events");

        // --- Делегаты ---------------------------------------------------------------------
        BinaryOperation multiply = (a, b) => a * b; // из лямбды
        BinaryOperation power = Power;              // из имени метода («группа методов»)
        Console.WriteLine($"{multiply(6, 7)} {power(2, 10)} {ApplyTwice(x => x * 3, 2)} {MakeAdder(10)(5)}");

        // Делегат может хранить НЕСКОЛЬКО методов: += добавляет, вызов выполняет все по очереди.
        Action<string> log = message => Console.Write($"[A: {message}] ");
        log += message => Console.Write($"[B: {message.ToUpperInvariant()}] ");
        log("multicast");
        Console.WriteLine($"<- {log.GetInvocationList().Length} targets");

        // --- Лямбды -----------------------------------------------------------------------
        var square = (int x) => x * x;                    // тип лямбды выводится: Func<int, int>
        var increment = (int x, int step = 1) => x + step; // параметры по умолчанию (C# 12)
        Func<int, int, int> gcd = static (a, b) =>         // static: захват запрещён
        {
            while (b != 0) (a, b) = (b, a % b);
            return a;
        };
        Console.WriteLine($"{square(9)} {increment(5)} {increment(5, 10)} {gcd(84, 36)}");

        // Замыкание захватывает саму ПЕРЕМЕННУЮ — по ссылке и с продлением её жизни
        // (в C++ это [&], но без риска висячей ссылки: переменная переезжает в кучу).
        int counter = 0;
        Action bump = () => counter++;
        bump();
        bump();
        Console.WriteLine($"counter changed through the closure: {counter}");

        // Классическая ловушка: у цикла for переменная одна на все итерации...
        var actions = new List<Func<int>>();
        for (int i = 0; i < 3; i++) actions.Add(() => i);
        string fromFor = Join(actions.Select(action => action()));
        // ...а у foreach — новая на каждой итерации.
        actions.Clear();
        foreach (int i in Enumerable.Range(0, 3)) actions.Add(() => i);
        string fromForeach = Join(actions.Select(action => action()));
        Console.WriteLine($"captured in for: {fromFor} | captured in foreach: {fromForeach}");

        // Локальная функция: видит локальные переменные, может быть рекурсивной, и её можно
        // объявить после использования. В отличие от лямбды C#, не требует создания делегата.
        // C++: лямбда, сохранённая в локальной переменной.
        Console.WriteLine($"factorial(10) = {Factorial(10)}");

        long Factorial(int n) => n <= 1 ? 1 : n * Factorial(n - 1);

        // --- События ----------------------------------------------------------------------
        var thermostat = new Thermostat();
        var history = new List<string>();
        void OnChanged(double from, double to) => history.Add($"{from} -> {to}");

        thermostat.TemperatureChanged += OnChanged;                  // подписка
        thermostat.Alarm += (_, message) => history.Add($"ALARM {message}");
        thermostat.Temperature = 21;
        thermostat.Temperature = 35;
        thermostat.TemperatureChanged -= OnChanged;                  // отписка
        thermostat.Temperature = 18;                                 // это изменение уже никто не слышит
        Console.WriteLine(Join(history, " | "));
        // Подписчик удерживает объект от сборки мусора, пока не отписан: забытая подписка —
        // самая частая причина «утечек» памяти в .NET.
    }
}

// =====================================================================================
//  8. КОЛЛЕКЦИИ, ИТЕРАТОРЫ, LINQ
// =====================================================================================

record Person(string Name, int Age, string City);

// Методы расширения: статические методы, которые вызываются как методы экземпляра.
// На них построен весь LINQ. C++: свободная функция (единого синтаксиса вызова там нет).
static class SequenceExtensions
{
    // Классическая форма (C# 3): `this` перед первым параметром.
    // Заодно это итератор: метод с `yield return` выполняется лениво, по шагу на элемент.
    public static IEnumerable<(T Previous, T Current)> Pairwise<T>(this IEnumerable<T> source)
    {
        using IEnumerator<T> enumerator = source.GetEnumerator();
        if (!enumerator.MoveNext()) yield break; // yield break — закончить последовательность
        T previous = enumerator.Current;
        while (enumerator.MoveNext())
        {
            yield return (previous, enumerator.Current);
            previous = enumerator.Current;
        }
    }

    // Блок extension (C# 14): расширять можно и свойствами, и статическими членами.
    extension(string text)
    {
        public int WordCount => text.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length;

        public bool IsPalindrome()
        {
            string letters = string.Concat(text.Where(char.IsLetterOrDigit).Select(char.ToLowerInvariant));
            return letters.SequenceEqual(letters.Reverse());
        }
    }
}

static class Section08_CollectionsAndLinq
{
    // Итератор: компилятор превращает метод в конечный автомат, который выполняется по
    // одному шагу на каждый запрос следующего элемента. C++: корутина-генератор (C++23).
    static IEnumerable<ulong> Fibonacci()
    {
        ulong current = 0, next = 1;
        while (true)
        {
            yield return current;
            if (next > ulong.MaxValue - current) // следующая сумма не поместится в ulong
            {
                yield return next;
                yield break;
            }
            (current, next) = (next, current + next);
        }
    }

    static IEnumerable<int> Traced(int count)
    {
        for (int i = 1; i <= count; i++)
        {
            Console.Write($"<produce {i}> ");
            yield return i;
        }
    }

    public static void Run()
    {
        Header(8, "Collections, iterators, LINQ");

        // --- List<T>. C++: std::vector ----------------------------------------------------
        List<int> list = [5, 3, 8];
        list.Add(1);
        list.AddRange([9, 2]);
        list.Insert(0, 0);
        list.RemoveAt(1); // удалить по индексу
        list.Sort();
        list.RemoveAll(x => x > 8); // C++: std::erase_if
        Console.WriteLine($"[{Join(list)}] count {list.Count}, index of 3: {list.IndexOf(3)}, " +
                          $"contains 8: {list.Contains(8)}, last: {list[^1]}");

        // --- Dictionary<TKey, TValue>. C++: std::unordered_map ----------------------------
        var stock = new Dictionary<string, int> { ["bolt"] = 10, ["nut"] = 0 };
        stock["screw"] = 25;       // индексатор вставляет или заменяет
        stock.TryAdd("bolt", 999); // а TryAdd существующий ключ не трогает
        stock["bolt"] -= 3;
        // Чтение отсутствующего ключа через индексатор бросает KeyNotFoundException
        // (в C++ operator[] молча вставил бы элемент). Безопасный вариант — TryGetValue.
        bool hasWasher = stock.TryGetValue("washer", out int washers);
        stock.Remove("nut", out int removedNuts);
        // Ссылка на значение ВНУТРИ словаря: «найти или вставить» за один поиск по хешу.
        ref int gaskets = ref CollectionsMarshal.GetValueRefOrAddDefault(stock, "gasket", out _);
        gaskets += 4;
        Console.Write($"washer found: {hasWasher} ({washers}), removed nuts: {removedNuts} |");
        foreach ((string item, int quantity) in stock.OrderBy(pair => pair.Key)) // деконструкция пары
        {
            Console.Write($" {item}={quantity}");
        }
        Console.WriteLine();

        // Подсчёт частот.
        string text = "the quick brown fox jumps over the lazy dog the end";
        var frequency = new Dictionary<string, int>();
        foreach (string word in text.Split(' ')) frequency[word] = frequency.GetValueOrDefault(word) + 1;
        var top = frequency.OrderByDescending(pair => pair.Value).ThenBy(pair => pair.Key).Take(3);
        string phrase = "Was it a car or a cat I saw";
        Console.WriteLine($"top words: {Join(top.Select(pair => $"{pair.Key}:{pair.Value}"))} | " +
                          $"extension members: {text.WordCount} words, palindrome: {phrase.IsPalindrome()}");

        // --- Остальные стандартные коллекции ----------------------------------------------
        var sorted = new SortedDictionary<string, int>(stock); // дерево. C++: std::map
        HashSet<int> set = [1, 2, 3, 4];                       // C++: std::unordered_set
        set.IntersectWith([3, 4, 5, 6]);
        var queue = new Queue<string>(["first", "second"]);    // C++: std::queue
        queue.Enqueue("third");
        var stack = new Stack<int>([1, 2, 3]);                 // C++: std::stack
        var heap = new PriorityQueue<string, int>();           // куча с МИНИМУМОМ на вершине
        heap.Enqueue("routine", 5);
        heap.Enqueue("urgent", 1);
        Console.WriteLine($"sorted keys: {Join(sorted.Keys)} | set [{Join(set.Order())}] | " +
                          $"dequeued {queue.Dequeue()} | popped {stack.Pop()} | heap gives {heap.Dequeue()}");

        // Неизменяемые коллекции: «изменение» возвращает новую коллекцию, исходная не меняется.
        ImmutableList<int> original = [1, 2, 3];
        ImmutableList<int> extended = original.Add(4);
        // «Замороженные»: дорогое построение, зато самый быстрый поиск. Для справочников.
        FrozenDictionary<string, int> frozen = stock.ToFrozenDictionary();
        int[] merged = [.. list, 100, .. set]; // `..` в выражении-коллекции склеивает коллекции
        Console.WriteLine($"immutable: {original.Count} -> {extended.Count} | frozen bolt: {frozen["bolt"]} | " +
                          $"merged [{Join(merged)}]");

        // --- Итераторы --------------------------------------------------------------------
        // Ленивость видна глазами: элементы производятся по требованию, а Take(2) обрывает
        // генерацию раньше времени.
        foreach (int value in Traced(5).Take(2)) Console.Write($"got {value}; ");
        Console.WriteLine();
        Console.WriteLine($"fibonacci: {Join(Fibonacci().TakeWhile(x => x < 100))} | " +
                          $"terms that fit in ulong: {Fibonacci().Count()} | " +
                          $"pairwise: {Join(new[] { 1, 4, 9, 16 }.Pairwise().Select(p => p.Current - p.Previous))}");

        // --- LINQ: запросы к любым последовательностям. C++: ranges и views ---------------
        // Цепочка методов расширения над IEnumerable<T>. Запрос ленив: это описание
        // вычисления, которое выполняется при обходе.
        int[] numbers = [.. Enumerable.Range(1, 10)];
        IEnumerable<int> evenSquares = numbers.Where(n => n % 2 == 0).Select(n => n * n);
        Console.WriteLine($"[{Join(evenSquares)}] sum {numbers.Sum()}, average {numbers.Average()}, " +
                          $"any > 9: {numbers.Any(n => n > 9)}, all > 0: {numbers.All(n => n > 0)}, " +
                          $"first > 4: {numbers.First(n => n > 4)}, " +
                          $"first > 100 or default: {numbers.FirstOrDefault(n => n > 100)}");
        // Aggregate — свёртка (C++: std::accumulate / fold_left), SelectMany — «расплющивание».
        string dashed = numbers.Skip(6).Aggregate("", (acc, n) => acc == "" ? $"{n}" : $"{acc}-{n}");
        var zipped = numbers.Take(3).Zip(["a", "b", "c"], (n, s) => $"{n}{s}");
        var chunks = numbers.Chunk(4).Select(chunk => $"[{Join(chunk, " ")}]");
        Console.WriteLine($"aggregate: {dashed} | zip: {Join(zipped)} | chunks: {Join(chunks, " ")} | " +
                          $"flattened: {Join(new[] { "ab", "cd" }.SelectMany(s => s))}");

        Person[] people =
        [
            new("Ann", 30, "Berlin"), new("Bob", 25, "Munich"), new("Cid", 35, "Berlin"),
            new("Dan", 25, "Munich"), new("Eve", 41, "Hamburg"),
        ];
        // Сортировка по нескольким ключам, группировка, словари.
        var byAge = people.OrderByDescending(p => p.Age).ThenBy(p => p.Name).Select(p => p.Name);
        var byCity = people.GroupBy(p => p.City).OrderBy(group => group.Key)
            .Select(group => $"{group.Key}: {Join(group.Select(p => p.Name), "+")} ({group.Average(p => p.Age):F1})");
        Dictionary<string, int> ageByName = people.ToDictionary(p => p.Name, p => p.Age);
        Console.WriteLine($"{Join(byAge)} | {Join(byCity, "; ")} | oldest: {people.MaxBy(p => p.Age)?.Name} | " +
                          $"Cid is {ageByName["Cid"]} | by decade: {Join(people.CountBy(p => p.Age / 10 * 10))}");

        // Синтаксис запросов — сахар над теми же методами. `new { ... }` — анонимный тип:
        // «структура на месте» со свойствами только для чтения.
        var seniors =
            from person in people
            where person.Age >= 30
            orderby person.Age descending
            select new { person.Name, Decade = person.Age / 10 * 10 };
        Console.WriteLine(Join(seniors));

        // Отложенное выполнение: запрос перечитывает источник при КАЖДОМ обходе.
        IEnumerable<int> big = list.Where(x => x > 2);
        list.Add(50);
        Console.WriteLine($"the query sees the element added later: [{Join(big)}]; materialise with ToList/ToArray");
    }
}

// =====================================================================================
//  9. ОШИБКИ, РЕСУРСЫ, GC, NULL-БЕЗОПАСНОСТЬ
// =====================================================================================

// Свой тип исключения. Бросать можно только объекты, производные от System.Exception
// (в C++ — что угодно, хоть int). Спецификаций вроде noexcept нет.
class ConfigException(string key, string message, Exception? inner = null)
    : Exception($"config key '{key}': {message}", inner)
{
    public string Key { get; } = key;
}

// IDisposable — контракт «у объекта есть ресурс, который нужно освободить вовремя»:
// файл, сокет, блокировка, нативная память. Память самого объекта освобождает GC —
// когда-нибудь; Dispose вызывают детерминированно. Это и есть замена RAII.
sealed class TracedResource : IDisposable
{
    private readonly string _name;
    private bool _disposed;

    public TracedResource(string name)
    {
        _name = name;
        Console.WriteLine($"    acquire {_name}");
    }

    public void Use()
    {
        ObjectDisposedException.ThrowIf(_disposed, this); // объект жив, а ресурса уже нет
        Console.WriteLine($"    use {_name}");
    }

    public void Dispose()
    {
        if (_disposed) return; // повторный вызов Dispose должен быть безвредным
        _disposed = true;
        Console.WriteLine($"    release {_name}");
    }
}

static class Section09_ErrorsAndResources
{
    static int ReadPort(IReadOnlyDictionary<string, string> config)
    {
        if (!config.TryGetValue("port", out string? text))
        {
            throw new ConfigException("port", "is missing");
        }
        int port;
        try
        {
            port = int.Parse(text); // бросает FormatException или OverflowException
        }
        catch (FormatException e)
        {
            // Обернуть ошибку, сохранив причину в InnerException. C++: std::throw_with_nested.
            throw new ConfigException("port", $"'{text}' is not a number", e);
        }
        if (port is < 1 or > 65535)
        {
            throw new ArgumentOutOfRangeException(nameof(config), $"port {port} is out of range");
        }
        return port;
    }

    // Идиома Try: там, где неудача — обычное дело, вместо исключения возвращают bool.
    static bool TryReadPort(IReadOnlyDictionary<string, string> config, out int port)
    {
        port = 0;
        return config.TryGetValue("port", out string? text)
            && int.TryParse(text, out port)
            && port is >= 1 and <= 65535;
    }

    static string? FindNickname(string name) => name switch
    {
        "Robert" => "Bob",
        "Margaret" => "Peggy",
        _ => null,
    };

    // NoInlining гарантирует, что временный объект не «зацепится» за кадр вызывающего метода.
    [MethodImpl(MethodImplOptions.NoInlining)]
    static WeakReference<object> CreateShortLived() => new(new object());

    public static void Run()
    {
        Header(9, "Errors, resources, GC, null safety");

        // --- Исключения -------------------------------------------------------------------
        Dictionary<string, string>[] configs =
        [
            new() { ["port"] = "8080" }, new() { ["host"] = "localhost" },
            new() { ["port"] = "80a" }, new() { ["port"] = "70000" },
        ];
        foreach (var config in configs)
        {
            try
            {
                Console.WriteLine($"port = {ReadPort(config)} (TryReadPort agrees: {TryReadPort(config, out _)})");
            }
            // Фильтр исключений: условие when проверяется ДО раскрутки стека.
            catch (ConfigException e) when (e.InnerException is not null)
            {
                Console.WriteLine($"{e.Message}; caused by {e.InnerException.GetType().Name}");
            }
            catch (ConfigException e) // от частного к общему
            {
                Console.WriteLine($"{e.Message} [Key = {e.Key}]");
            }
            catch (Exception e) // общий предок всех исключений
            {
                Console.WriteLine($"{e.GetType().Name}: {e.Message} (TryReadPort: {TryReadPort(config, out _)})");
            }
        }

        // finally выполняется при любом выходе из try. В C++ его нет: там работают деструкторы.
        try
        {
            Console.WriteLine("    try");
            throw new InvalidOperationException("boom");
        }
        catch (InvalidOperationException e)
        {
            Console.WriteLine($"    catch: {e.Message}"); // `throw;` здесь перебросил бы исключение дальше
        }
        finally
        {
            Console.WriteLine("    finally");
        }

        // --- using: детерминированное освобождение ресурсов -------------------------------
        using (var outer = new TracedResource("outer")) // блочная форма: Dispose в конце блока
        {
            using var inner = new TracedResource("inner"); // using-объявление: Dispose в конце области видимости
            outer.Use();
            inner.Use();
        } // release inner, затем release outer — в обратном порядке, как деструкторы C++

        // Отличие от RAII: после Dispose объект никуда не делся, и к нему можно обратиться.
        var stale = new TracedResource("stale");
        stale.Dispose();
        try
        {
            stale.Use();
        }
        catch (ObjectDisposedException e)
        {
            Console.WriteLine($"    {e.GetType().Name}: the object is alive, its resource is not");
        }

        // --- Сборщик мусора ---------------------------------------------------------------
        // GC поколенческий: новые объекты (поколение 0) собираются часто и дёшево, выжившие
        // переходят в поколения 1 и 2. При сборке объекты ПЕРЕМЕЩАЮТСЯ (память уплотняется),
        // поэтому адрес управляемого объекта нестабилен — см. fixed в разделе 11.
        WeakReference<object> weak = CreateShortLived(); // слабая ссылка. C++: std::weak_ptr
        var survivor = new object();
        int generationBefore = GC.GetGeneration(survivor);
        GC.Collect(); // принудительная сборка — только для демонстраций и тестов
        GC.WaitForPendingFinalizers();
        Console.WriteLine($"weak target alive after GC: {weak.TryGetTarget(out _)} | " +
                          $"survivor moved from generation {generationBefore} to {GC.GetGeneration(survivor)}");
        // Финализатор (`~TypeName()`) — НЕ деструктор C++: его когда-нибудь вызовет GC в особом
        // потоке, а может и не вызвать вовсе. Это страховка для нативных ресурсов (раздел 11).

        // --- Null-безопасность (C# 8) -----------------------------------------------------
        // `string` — «null здесь не бывает», `string?` — «может быть null». Это подсказки
        // статическому анализатору (он выдаёт предупреждения), а не разные типы.
        string? nickname = FindNickname("Alice");
        // Console.WriteLine(nickname.Length); // предупреждение CS8602: возможно разыменование null
        Console.WriteLine($"{nickname?.Length ?? -1} | {nickname ?? "(none)"} | " +
                          $"{FindNickname("Robert")?.ToUpperInvariant()}"); // ?. — «вызвать, если не null»
        nickname ??= "n/a";
        Console.WriteLine($"after `??=` the compiler knows it is not null: {nickname.Length}");
    }
}

// =====================================================================================
//  10. ПАМЯТЬ И СКОРОСТЬ: Span, ref, раскладка, SIMD
// =====================================================================================
//
//  «Управляемый» не значит «медленный»: в C# есть средства писать код без аллокаций
//  и с полным контролем над памятью, оставаясь в безопасном подмножестве языка.

// ref struct — тип, экземпляры которого живут ТОЛЬКО на стеке. Его нельзя сохранить в поле
// класса, в массиве, в лямбде или пронести через await. Так компилятор гарантирует, что
// «окно» не переживёт память, на которую смотрит (в C++ за этим следит программист).
ref struct WordReader(ReadOnlySpan<char> text)
{
    private ReadOnlySpan<char> _rest = text;

    public bool TryRead(out ReadOnlySpan<char> word)
    {
        _rest = _rest.TrimStart();
        if (_rest.IsEmpty)
        {
            word = default;
            return false;
        }
        int end = _rest.IndexOf(' ');
        if (end < 0) end = _rest.Length;
        word = _rest[..end];
        _rest = _rest[end..];
        return true;
    }
}

// Управление раскладкой структуры в памяти.
[StructLayout(LayoutKind.Explicit)] // все поля по смещению 0 — это union из C и C++
struct FloatBits
{
    [FieldOffset(0)] public float Value;
    [FieldOffset(0)] public uint Bits;
}

[StructLayout(LayoutKind.Sequential, Pack = 1)] // C++: #pragma pack(push, 1)
struct PackedHeader
{
    public byte Tag;
    public int Length;
    public short Flags;
}

struct NaturalHeader // раскладка по умолчанию: в порядке объявления, с выравниванием
{
    public byte Tag;
    public int Length;
    public short Flags;
}

// Массив фиксированной длины ВНУТРИ структуры (C# 12). C++: float data[4].
[InlineArray(4)]
struct Float4
{
    private float _element0;
}

static class Section10_MemoryAndPerformance
{
    static int Sum(ReadOnlySpan<byte> values)
    {
        int total = 0;
        foreach (byte value in values) total += value;
        return total;
    }

    // ref-возврат: метод отдаёт ССЫЛКУ на элемент, а не копию. C++: T& find(...).
    static ref int FirstNegative(Span<int> values)
    {
        for (int i = 0; i < values.Length; i++)
        {
            if (values[i] < 0) return ref values[i];
        }
        throw new InvalidOperationException("no negative values");
    }

    // SIMD. Vector<T> — вектор «во всю ширину регистра» (переносимый код); есть также
    // Vector128/256/512<T> и прямые инструкции в System.Runtime.Intrinsics (C++: <immintrin.h>).
    // AggressiveInlining — настойчивая просьба к JIT встроить метод (C++: [[gnu::always_inline]]).
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static float SumVectorized(ReadOnlySpan<float> values)
    {
        var accumulator = Vector<float>.Zero;
        int i = 0;
        for (; i <= values.Length - Vector<float>.Count; i += Vector<float>.Count)
        {
            accumulator += new Vector<float>(values.Slice(i, Vector<float>.Count));
        }
        float sum = Vector.Sum(accumulator);
        for (; i < values.Length; i++) sum += values[i]; // «хвост», не кратный ширине вектора
        return sum;
    }

    public static void Run()
    {
        Header(10, "Memory and performance: Span, ref, layout, SIMD");

        // --- Span<T>: окно в непрерывную память. C++: std::span<T> --------------------------
        int[] array = [1, 2, 3, 4, 5, 6];
        Span<int> window = array.AsSpan(1, 4); // элементы 2, 3, 4, 5 — без копирования
        window[0] = 20;                        // запись идёт прямо в массив
        window[2..].Fill(0);                   // срез спана — тоже спан, а не копия
        Console.WriteLine($"array after edits through the span: [{Join(array)}]");

        // stackalloc — память на стеке, мимо GC. C++: локальный массив или alloca.
        Span<byte> buffer = stackalloc byte[8];
        for (int i = 0; i < buffer.Length; i++) buffer[i] = (byte)(i * 3);
        Console.WriteLine($"stackalloc: {Convert.ToHexString(buffer)}, sum {Sum(buffer)}");

        // ReadOnlySpan<char> — разбор текста без единой аллокации. C++: std::string_view.
        ReadOnlySpan<char> line = "width=42;height=7;depth=13";
        int total = 0;
        foreach (Range part in line.Split(';')) // перечисляются ДИАПАЗОНЫ: строки не создаются
        {
            ReadOnlySpan<char> pair = line[part];
            total += int.Parse(pair[(pair.IndexOf('=') + 1)..]); // int.Parse читает прямо из спана
        }
        var reader = new WordReader("  spans   avoid  allocations ");
        int words = 0, letters = 0;
        while (reader.TryRead(out ReadOnlySpan<char> word))
        {
            words++;
            letters += word.Length;
        }
        Console.WriteLine($"parsed total {total} | {words} words, {letters} letters");

        // --- ref-локальные переменные и ref-возврат ---------------------------------------
        int[] data = [3, -1, 4, -5];
        ref int negative = ref FirstNegative(data); // псевдоним элемента массива. C++: int&
        negative = 0;
        Console.WriteLine($"[{Join(data)}] after writing through the returned reference");
        // Ещё из этой серии: `in`-параметры (const T&), `readonly struct` (все методы const),
        // `ref readonly` (const T& как результат), `scoped` (ссылка не покинет метод).

        // --- Раскладка в памяти -----------------------------------------------------------
        var bits = new FloatBits { Value = 1.0f };
        var packed = new PackedHeader { Tag = 1, Length = 2, Flags = 3 };
        var natural = new NaturalHeader { Tag = packed.Tag, Length = packed.Length, Flags = packed.Flags };
        uint viaConverter = BitConverter.SingleToUInt32Bits(1.0f); // C++: std::bit_cast
        Console.WriteLine($"1.0f = 0x{bits.Bits:X8} via the union, 0x{viaConverter:X8} via BitConverter | " +
                          $"header sizes: packed {Unsafe.SizeOf<PackedHeader>()}, " +
                          $"natural {Unsafe.SizeOf<NaturalHeader>()} " +
                          $"(tag {natural.Tag}, length {natural.Length}, flags {natural.Flags})");

        Float4 quad = new();
        quad[3] = 4f;                  // встроенный массив индексируется напрямую...
        Span<float> components = quad; // ...и превращается в Span без копирования
        components[0] = 1f;
        Console.WriteLine($"inline array: [{Join(components.ToArray())}], " +
                          $"{Unsafe.SizeOf<Float4>()} bytes inside the struct");

        // MemoryMarshal — «reinterpret_cast для спанов»: те же байты, другой тип элементов.
        Span<float> floats = [1.0f, 2.0f];
        Span<uint> asUInts = MemoryMarshal.Cast<float, uint>(floats);
        Span<byte> asBytes = MemoryMarshal.AsBytes(floats);
        // BinaryPrimitives — чтение и запись с явным порядком байтов.
        BinaryPrimitives.WriteInt32BigEndian(buffer, 0x11223344);
        int littleEndian = BinaryPrimitives.ReadInt32LittleEndian(buffer);
        Console.WriteLine($"2.0f = 0x{asUInts[1]:X8}, {asBytes.Length} bytes | " +
                          $"big-endian bytes {Convert.ToHexString(buffer[..4])} " +
                          $"read as little-endian: 0x{littleEndian:X8}");
        // BitOperations — аналог заголовка <bit>.
        const uint Mask = 0b1011_0000; // двоичный литерал
        Console.WriteLine($"popcount {BitOperations.PopCount(Mask)}, " +
                          $"trailing zeros {BitOperations.TrailingZeroCount(Mask)}, " +
                          $"rotl 0x{BitOperations.RotateLeft(Mask, 28):X}, " +
                          $"next power of two {BitOperations.RoundUpToPowerOf2(100u)}");

        // --- ArrayPool: переиспользование буферов, чтобы не нагружать GC ------------------
        byte[] rented = ArrayPool<byte>.Shared.Rent(1000); // вернёт массив НЕ МЕНЬШЕ запрошенного
        try
        {
            rented.AsSpan(0, 1000).Fill(0xFF);
            Console.WriteLine($"rented a buffer of at least 1000 bytes: {rented.Length >= 1000}, " +
                              $"sum {Sum(rented.AsSpan(0, 1000))}");
        }
        finally
        {
            ArrayPool<byte>.Shared.Return(rented);
        }

        // --- SIMD -------------------------------------------------------------------------
        float[] samples = new float[1003];
        for (int i = 0; i < samples.Length; i++) samples[i] = i % 7;
        Console.WriteLine($"SIMD sum {SumVectorized(samples)} == scalar sum {samples.Sum()} | " +
                          $"Vector<float>.Count = {Vector<float>.Count}, " +
                          $"hardware accelerated: {Vector.IsHardwareAccelerated}, AVX2: {Avx2.IsSupported}");
    }
}

// =====================================================================================
//  11. UNSAFE-КОД И ВЫЗОВ НАТИВНЫХ ФУНКЦИЙ
// =====================================================================================
//
//  Указатели в C# есть, но только внутри `unsafe` и только с разрешения проекта
//  (AllowUnsafeBlocks). Проверки границ и типов там не действуют: это обычный C со всеми
//  его возможностями и последствиями. Нужен unsafe редко — для взаимодействия с нативным
//  кодом и предельной оптимизации; остальное закрывают Span<T> и ref (раздел 10).

// Структура для обмена с нативным кодом: только «плоские» поля, раскладка как в C.
[StructLayout(LayoutKind.Sequential)]
struct Rgba
{
    public byte R, G, B, A;
}

// Вызов нативных функций (P/Invoke). В C++ хватает #include и линковки; здесь сигнатуру
// объявляют на C#, а среда выполнения сама находит библиотеку и функцию по именам.
// Для примера взята стандартная библиотека C: она есть везде, только называется по-разному.
static unsafe partial class Native
{
    private const string UnixLibC = "libc";
    private const string WindowsCrt = "msvcrt";

    // Классический способ: [DllImport] + extern. Преобразование аргументов (маршалинг)
    // выполняет среда во время работы программы.
    [DllImport(UnixLibC, EntryPoint = "abs")]
    private static extern int AbsUnix(int value);

    [DllImport(WindowsCrt, EntryPoint = "abs", CallingConvention = CallingConvention.Cdecl)]
    private static extern int AbsWindows(int value);

    public static int Abs(int value) => OperatingSystem.IsWindows() ? AbsWindows(value) : AbsUnix(value);

    // Современный способ (.NET 7): [LibraryImport]. Код маршалинга создаёт генератор
    // исходного кода ПРИ КОМПИЛЯЦИИ — он дописывает тело partial-метода.
    [LibraryImport(UnixLibC, EntryPoint = "strlen", StringMarshalling = StringMarshalling.Utf8)]
    private static partial nuint StrLenUnix(string text);

    [LibraryImport(WindowsCrt, EntryPoint = "strlen", StringMarshalling = StringMarshalling.Utf8)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    private static partial nuint StrLenWindows(string text);

    public static nuint StrLen(string text) =>
        OperatingSystem.IsWindows() ? StrLenWindows(text) : StrLenUnix(text);

    // Обратный вызов из нативного кода: параметр — указатель на функцию с соглашением C.
    [DllImport(UnixLibC, EntryPoint = "qsort")]
    private static extern void QSortUnix(
        void* data, nuint count, nuint size, delegate* unmanaged[Cdecl]<void*, void*, int> compare);

    [DllImport(WindowsCrt, EntryPoint = "qsort", CallingConvention = CallingConvention.Cdecl)]
    private static extern void QSortWindows(
        void* data, nuint count, nuint size, delegate* unmanaged[Cdecl]<void*, void*, int> compare);

    public static void QSort(Span<int> values)
    {
        fixed (int* data = values) // закрепить память на время нативного вызова
        {
            nuint count = (nuint)values.Length;
            if (OperatingSystem.IsWindows()) QSortWindows(data, count, sizeof(int), &CompareInts);
            else QSortUnix(data, count, sizeof(int), &CompareInts);
        }
    }

    // Метод, который вызывает ТОЛЬКО нативный код. C++: функция с extern "C".
    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvCdecl)])]
    private static int CompareInts(void* a, void* b) => (*(int*)a).CompareTo(*(int*)b);
}

// Нативная память и полный «шаблон Dispose».
sealed unsafe class NativeBuffer : IDisposable
{
    private byte* _memory;

    public int Length { get; }

    public NativeBuffer(int length)
    {
        _memory = (byte*)NativeMemory.AllocZeroed((nuint)length); // C: calloc
        Length = length;
    }

    // Наружу отдаём безопасный Span, а не указатель.
    public Span<byte> Bytes =>
        _memory != null ? new Span<byte>(_memory, Length) : throw new ObjectDisposedException(nameof(NativeBuffer));

    public void Dispose()
    {
        Free();
        GC.SuppressFinalize(this); // ресурс освобождён вручную — финализатор больше не нужен
    }

    // Финализатор: страховка на случай, если Dispose забыли. Его когда-нибудь вызовет GC.
    ~NativeBuffer() => Free();

    private void Free()
    {
        if (_memory == null) return;
        NativeMemory.Free(_memory); // C: free
        _memory = null;
    }
}

static class Section11_UnsafeAndInterop
{
    static int Add(int a, int b) => a + b;

    public static unsafe void Run()
    {
        Header(11, "unsafe code and native interop");

        // --- Указатели --------------------------------------------------------------------
        int value = 10;
        int* pointer = &value; // локальная переменная лежит на стеке и никуда не переедет
        *pointer += 1;
        Console.WriteLine($"value through the pointer: {*pointer}, pointer size {sizeof(int*)}");

        // Управляемые объекты GC вправе ПЕРЕМЕЩАТЬ. Оператор fixed закрепляет объект на
        // время блока, чтобы указатель на него оставался действительным.
        int[] array = [10, 20, 30, 40];
        fixed (int* first = array)
        {
            int third = *(first + 2); // арифметика указателей — как в C
            first[3] = 400;           // индексация указателя; границы НЕ проверяются
            Console.WriteLine($"third {third}, array[3] is now {array[3]}");
        }

        // Указатель на структуру и оператор ->.
        Rgba color = new() { R = 0x11, G = 0x22, B = 0x33, A = 0xFF };
        Rgba* colorPointer = &color;
        colorPointer->G = 0x99;
        uint packed = *(uint*)colorPointer; // переинтерпретация байтов. C++: reinterpret_cast
        Console.WriteLine($"G = 0x{color.G:X2}, packed 0x{packed:X8}, sizeof(Rgba) = {sizeof(Rgba)}");

        // stackalloc, результат которого — указатель.
        byte* scratch = stackalloc byte[4];
        for (int i = 0; i < 4; i++) scratch[i] = (byte)('a' + i);
        Console.WriteLine($"stackalloc bytes as text: {Encoding.ASCII.GetString(scratch, 4)}");

        // Указатель на функцию (C# 9): вызов без делегата и аллокаций. C++: int (*)(int, int).
        delegate*<int, int, int> add = &Add;
        Console.WriteLine($"function pointer: {add(2, 3)}");

        // --- Нативная память --------------------------------------------------------------
        using (var native = new NativeBuffer(16))
        {
            native.Bytes.Fill(0xAB);
            native.Bytes[0] = 1;
            Console.WriteLine($"native buffer: {Convert.ToHexString(native.Bytes[..4])}..., " +
                              $"{native.Length} bytes outside the GC heap");
        } // Dispose освободил память немедленно, не дожидаясь GC

        // --- P/Invoke ---------------------------------------------------------------------
        int[] unsorted = [42, -7, 19, 0, 3];
        Native.QSort(unsorted);
        Console.WriteLine($"abs(-7) = {Native.Abs(-7)}, strlen = {Native.StrLen("hello from C")}, " +
                          $"qsort: [{Join(unsorted)}]");
        // Для дескрипторов ОС (файлы, сокеты, окна) есть готовая обёртка SafeHandle:
        // финализатор, подсчёт использований и защита от повторного освобождения.
    }
}

// =====================================================================================
//  12. ПОТОКИ И СИНХРОНИЗАЦИЯ
// =====================================================================================

static class Section12_Threads
{
    public static void Run()
    {
        Header(12, "Threads and synchronisation");

        // --- Поток ОС. C++: std::thread ---------------------------------------------------
        long sum = 0;
        var thread = new Thread(() =>
        {
            for (int i = 1; i <= 1000; i++) sum += i; // лямбда захватила переменную sum
        });
        thread.Start();
        thread.Join();
        Console.WriteLine($"sum computed in another thread: {sum}");
        // Вручную потоки создают редко: работу отдают ПУЛУ ПОТОКОВ — через Task.Run,
        // Parallel и async/await (раздел 13).

        // --- lock, Interlocked, локальные данные потока -----------------------------------
        // Гонка данных в C# — не UB: память останется целой, но результат будет неверным.
        // lock — мьютекс, который отпускается автоматически (C++: std::scoped_lock).
        // Специальный тип Lock появился в C# 13; до него блокировали произвольный object.
        Lock gate = new();
        long guarded = 0, atomic = 0;
        using var perThread = new ThreadLocal<int>(() => 0, trackAllValues: true); // C++: thread_local
        Parallel.For(0, 4, _ => // параллельный цикл на пуле потоков
        {
            for (int n = 0; n < 1000; n++)
            {
                lock (gate)
                {
                    guarded++;
                }
                Interlocked.Increment(ref atomic); // C++: std::atomic<long>::fetch_add
                perThread.Value++;
            }
        });
        Console.WriteLine($"lock: {guarded}, Interlocked: {Interlocked.Read(ref atomic)}, " +
                          $"thread-local counters add up to {perThread.Values.Sum()}");

        // --- Потокобезопасные коллекции (в стандарте C++ таких нет) -----------------------
        var hits = new ConcurrentDictionary<string, int>();
        Parallel.ForEach(new[] { "a", "b", "a", "c", "a", "b" },
            key => hits.AddOrUpdate(key, 1, (_, count) => count + 1));
        var counted = hits.OrderBy(pair => pair.Key).Select(pair => $"{pair.Key}={pair.Value}");
        Console.WriteLine($"concurrent dictionary: {Join(counted)}");

        // Блокирующая очередь «производитель — потребитель». C++: mutex + condition_variable.
        using var queue = new BlockingCollection<int>(boundedCapacity: 2);
        Task<int> consumer = Task.Run(() => queue.GetConsumingEnumerable().Sum());
        for (int i = 1; i <= 5; i++) queue.Add(i); // ждёт, пока в очереди есть место
        queue.CompleteAdding();
        Console.WriteLine($"consumer received a total of {consumer.Result}"); // Result блокирует до готовности

        // --- PLINQ: параллельный LINQ одним вызовом. C++: std::execution::par -------------
        long evenSquares = Enumerable.Range(1, 1_000_000).AsParallel()
            .Where(n => n % 2 == 0)
            .Sum(n => (long)n * n);
        Console.WriteLine($"PLINQ sum of even squares: {evenSquares}");

        // --- Ленивая инициализация и сигналы ----------------------------------------------
        // Lazy<T> — потокобезопасно, один раз. C++: статическая локальная переменная.
        var primes = new Lazy<int[]>(() =>
            [.. Enumerable.Range(2, 48).Where(n => Enumerable.Range(2, n - 2).All(d => n % d != 0))]);
        Console.WriteLine($"created: {primes.IsValueCreated}, primes below 50: {primes.Value.Length}, " +
                          $"created: {primes.IsValueCreated}");

        using var allDone = new CountdownEvent(3); // C++: std::latch
        for (int i = 0; i < 3; i++) ThreadPool.QueueUserWorkItem(_ => allDone.Signal());
        allDone.Wait();
        Console.WriteLine("countdown event released after 3 pool tasks");
        // Ещё есть: SemaphoreSlim, ReaderWriterLockSlim (std::shared_mutex), Barrier,
        // ManualResetEventSlim, Monitor.Wait/Pulse (условная переменная), ключевое слово volatile.
    }
}

// =====================================================================================
//  13. ASYNC/AWAIT
// =====================================================================================
//
//  async-метод компилятор превращает в конечный автомат. На каждом await метод может
//  «уснуть», вернув управление вызывающему, а позже продолжиться — возможно, в другом
//  потоке пула. C++: корутины с co_await. Отличия:
//    - всё нужное (Task, планировщик, пул потоков, таймеры) уже есть в библиотеке;
//    - Task «горячая»: выполнение начинается при вызове метода, а не при первом await;
//    - отмена, исключения и контексты синхронизации стандартизованы.

static class TimeSpanAwaiterExtensions
{
    // await работает с ЛЮБЫМ типом, у которого есть подходящий метод GetAwaiter(), — даже
    // если это метод расширения. C++: operator co_await.
    public static TaskAwaiter GetAwaiter(this TimeSpan delay) => Task.Delay(delay).GetAwaiter();
}

static class Section13_AsyncAwait
{
    static async Task<int> FetchLengthAsync(string name, int delayMs, CancellationToken cancellation = default)
    {
        await Task.Delay(delayMs, cancellation); // таймер, а не Thread.Sleep: поток не занят
        return name.Length * delayMs;
    }

    // ValueTask<T> — структура вместо объекта Task: без аллокации, когда результат
    // часто готов сразу (например, лежит в кеше).
    static ValueTask<int> CachedLengthAsync(Dictionary<string, int> cache, string name) =>
        cache.TryGetValue(name, out int cached)
            ? ValueTask.FromResult(cached)
            : new ValueTask<int>(FetchLengthAsync(name, 5));

    // Асинхронный итератор: `yield return` и `await` в одном методе.
    static async IAsyncEnumerable<int> TicksAsync(
        int count, [EnumeratorCancellation] CancellationToken cancellation = default)
    {
        for (int i = 1; i <= count; i++)
        {
            await Task.Delay(5, cancellation);
            yield return i;
        }
    }

    // Ресурс с асинхронным освобождением (например, сброс буферов в сеть).
    sealed class AsyncResource(string name) : IAsyncDisposable
    {
        public async ValueTask DisposeAsync()
        {
            await Task.Delay(1);
            Console.WriteLine($"    {name} disposed asynchronously");
        }
    }

    public static async Task RunAsync()
    {
        Header(13, "async/await");

        // Задача стартует в момент вызова; await ждёт результат, не блокируя поток.
        Task<int> pending = FetchLengthAsync("alpha", 30);
        Console.WriteLine($"task started, completed yet: {pending.IsCompleted}");
        Console.WriteLine($"awaited result: {await pending}");

        // Параллельное ожидание: общее время — максимум, а не сумма.
        var stopwatch = Stopwatch.StartNew();
        int[] results = await Task.WhenAll(FetchLengthAsync("beta", 40), FetchLengthAsync("gamma", 20));
        Console.WriteLine($"WhenAll -> [{Join(results)}] in about {stopwatch.ElapsedMilliseconds} ms (not 60)");

        Task<int> winner = await Task.WhenAny(FetchLengthAsync("slow", 200), FetchLengthAsync("fast", 10));
        Console.WriteLine($"WhenAny -> the first finished task returned {await winner}");

        // Отмена — кооперативная, через CancellationToken. C++: std::stop_token.
        using var timeout = new CancellationTokenSource(TimeSpan.FromMilliseconds(20));
        try
        {
            await FetchLengthAsync("never", 5_000, timeout.Token);
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine("cancelled by timeout: OperationCanceledException");
        }

        // Исключение из задачи сохраняется в ней и перебрасывается в точке await.
        // (`int () => ...` — лямбда с явно указанным типом результата.)
        Task<int> failing = Task.Run(int () => throw new InvalidOperationException("failed on the thread pool"));
        try
        {
            await failing;
        }
        catch (InvalidOperationException e)
        {
            Console.WriteLine($"caught at await: {e.Message}");
        }

        var cache = new Dictionary<string, int> { ["cached"] = 6 };
        Console.WriteLine($"ValueTask: {await CachedLengthAsync(cache, "cached")} from the cache, " +
                          $"{await CachedLengthAsync(cache, "fresh")} computed");

        // Асинхронный поток значений потребляют через `await foreach`.
        int tickSum = 0;
        await foreach (int tick in TicksAsync(3)) tickSum += tick;
        Console.WriteLine($"await foreach received ticks with sum {tickSum}");

        // `await using` — асинхронный аналог using.
        await using (var resource = new AsyncResource("connection"))
        {
            Console.WriteLine("    working with the connection");
        }

        // Канал — асинхронная очередь «производитель — потребитель».
        var channel = Channel.CreateBounded<int>(capacity: 2);
        Task producer = Task.Run(async () =>
        {
            for (int i = 1; i <= 5; i++) await channel.Writer.WriteAsync(i); // ждёт свободного места
            channel.Writer.Complete();
        });
        int received = 0;
        await foreach (int item in channel.Reader.ReadAllAsync()) received += item;
        await producer;

        // Параллельная обработка коллекции асинхронными операциями.
        int processed = 0;
        await Parallel.ForEachAsync(
            Enumerable.Range(1, 8),
            new ParallelOptions { MaxDegreeOfParallelism = 4 },
            async (number, cancellation) =>
            {
                await Task.Delay(5, cancellation);
                Interlocked.Add(ref processed, number);
            });
        Console.WriteLine($"channel delivered {received}, Parallel.ForEachAsync processed {processed}");

        await TimeSpan.FromMilliseconds(5); // работает благодаря GetAwaiter-расширению выше

        // TaskCompletionSource — задача, результат которой задают вручную. C++: std::promise.
        var completion = new TaskCompletionSource<string>();
        _ = Task.Run(() => completion.SetResult("set from another thread"));
        Console.WriteLine($"TaskCompletionSource: {await completion.Task} | " +
                          $"continuing on a pool thread: {Thread.CurrentThread.IsThreadPoolThread}");
        // Правила хорошего тона: async void — только для обработчиков событий; не блокировать
        // поток вызовами .Result и .Wait() там, где можно написать await.
    }
}

// =====================================================================================
//  14. РЕФЛЕКСИЯ, АТРИБУТЫ, ГЕНЕРАЦИЯ КОДА
// =====================================================================================
//
//  Сборка .NET хранит полные метаданные: типы, члены, сигнатуры, атрибуты. Программа
//  может читать их во время выполнения, создавать объекты и вызывать методы по имени,
//  строить и компилировать код на лету. В C++ статическая рефлексия появляется только
//  в C++26, а рефлексии времени выполнения нет совсем.

// Свой атрибут — класс-наследник Attribute. Компилятор записывает его в метаданные.
[AttributeUsage(AttributeTargets.Property)]
sealed class ColumnAttribute(string name) : Attribute
{
    public string Name => name;
    public bool IsKey { get; init; }
}

class Planet
{
    [Column("planet_name", IsKey = true)]
    public string Name { get; set; } = "";

    [Column("mass_kg")]
    public double Mass { get; set; }

    public int Moons { get; set; } // без атрибута

    public double SurfaceGravity(double radius) => 6.674e-11 * Mass / (radius * radius);
}

// Генератор исходного кода: во время КОМПИЛЯЦИИ дописывает тело partial-члена. Здесь он
// создаёт готовый конечный автомат для регулярного выражения — без разбора шаблона при
// запуске. C++: constexpr-библиотеки вроде CTRE.
static partial class Patterns
{
    [GeneratedRegex(@"(?<key>\w+)=(?<value>\d+)")]
    public static partial Regex KeyValue { get; }
}

static class Section14_Reflection
{
    // Атрибуты «сведений о вызывающем»: значения параметров подставляет компилятор.
    // C++: std::source_location; текст выражения там даёт только макрос с `#`.
    static string Check(
        bool condition,
        [CallerArgumentExpression(nameof(condition))] string expression = "",
        [CallerMemberName] string member = "",
        [CallerLineNumber] int line = 0) =>
        $"`{expression}` is {condition} (in {member}, line {line})";

    public static void Run()
    {
        Header(14, "Reflection, attributes, code generation");

        // --- Рефлексия --------------------------------------------------------------------
        var earth = new Planet { Name = "Earth", Mass = 5.972e24, Moons = 1 };
        Type type = earth.GetType(); // или typeof(Planet). C++: typeid, но несравнимо богаче
        Console.WriteLine($"{type.Name} : {type.BaseType?.Name} | properties: " +
                          Join(type.GetProperties().Select(p => $"{p.PropertyType.Name} {p.Name}")));

        // Чтение атрибутов и значений: так устроены ORM, сериализаторы, DI-контейнеры.
        foreach (PropertyInfo property in type.GetProperties())
        {
            var column = property.GetCustomAttribute<ColumnAttribute>();
            if (column is null) continue;
            Console.WriteLine($"    {property.Name} -> column '{column.Name}'{(column.IsKey ? " (key)" : "")}" +
                              $" = {property.GetValue(earth)}");
        }

        // Запись свойства и вызов метода по имени; создание объекта по описанию типа.
        type.GetProperty("Moons")!.SetValue(earth, 2);
        object? gravity = type.GetMethod(nameof(Planet.SurfaceGravity))!.Invoke(earth, [6.371e6]);
        var blank = (Planet)Activator.CreateInstance(type)!;
        Console.WriteLine($"moons set by name: {earth.Moons} | method invoked by name: {gravity:F2} m/s^2 | " +
                          $"object created from Type: Moons = {blank.Moons}");

        // Сериализация без единой строки ручного кода — рефлексия в действии.
        string json = JsonSerializer.Serialize(earth);
        Planet restored = JsonSerializer.Deserialize<Planet>(json)!;
        Console.WriteLine($"{json} -> {restored.Name} with {restored.Moons} moons");

        // nameof и атрибуты Caller*.
        Console.WriteLine($"{nameof(Planet.SurfaceGravity)} | {Check(earth.Moons > 1)}");

        // --- Деревья выражений ------------------------------------------------------------
        // Лямбда, полученная не как код, а как ДАННЫЕ: объектная модель выражения. Её можно
        // разобрать (так LINQ-провайдеры переводят запросы в SQL) или скомпилировать.
        Expression<Func<double, double>> formula = x => x * x + 2 * x + 1;
        Func<double, double> compiled = formula.Compile(); // JIT-компиляция во время выполнения
        Console.WriteLine($"{formula.Body} | root node: {formula.Body.NodeType} | f(3) = {compiled(3)}");

        // Дерево можно собрать и вручную — это генерация кода во время выполнения.
        ParameterExpression parameter = Expression.Parameter(typeof(double), "x");
        Expression body = Expression.Add(
            Expression.Multiply(parameter, Expression.Constant(3.0)),
            Expression.Constant(1.0));
        var linear = Expression.Lambda<Func<double, double>>(body, parameter).Compile();
        Console.WriteLine($"built at run time: {body} | linear(2) = {linear(2)}");

        // --- dynamic: позднее связывание --------------------------------------------------
        // Поиск членов откладывается до выполнения, как в Python. Нужен для COM и «утиных» API.
        dynamic value = 21;
        value *= 2;                // оператор будет найден во время выполнения
        value = $"{value}!";       // тип значения может меняться
        int length = value.Length; // свойство Length тоже ищется динамически
        Console.WriteLine($"dynamic: {value} has length {length}");

        // --- Генераторы исходного кода ----------------------------------------------------
        Match match = Patterns.KeyValue.Match("width=42");
        Console.WriteLine($"generated regex: {match.Groups["key"].Value} -> {match.Groups["value"].Value}");
        // Так же устроены [LibraryImport] (раздел 11), System.Text.Json в режиме без рефлексии
        // и [LoggerMessage]. Генератор — обычная .NET-библиотека, подключаемая к компилятору.
    }
}

// =====================================================================================
//  15. НОВЕЙШЕЕ: C# 12–14 И C# 15
// =====================================================================================
//
//  Язык обновляется каждый год вместе с .NET. Часть новинок уже встречалась выше:
//  выражения-коллекции и первичные конструкторы (C# 12), тип Lock (C# 13), слово field
//  и блоки extension (C# 14). Здесь — остальное.

// Пользовательское СОСТАВНОЕ присваивание (C# 14): `+=` меняет объект на месте.
// До C# 14 запись `a += b` всегда означала `a = a + b`, то есть создание нового значения.
struct Accumulator
{
    public double Total;
    public int Count;

    public void operator +=(double value)
    {
        Total += value;
        Count++;
    }

    public readonly double Mean => Count == 0 ? 0 : Total / Count;
}

class Order
{
    public string? Note { get; set; }
    public int Quantity { get; set; }
}

static class NewestExtensions
{
    // Блок extension без имени получателя: статические члены и операторы для чужого типа.
    extension(string)
    {
        public static string operator *(string text, int count) =>
            string.Concat(Enumerable.Repeat(text, count));
    }

    // Обобщённый блок: свойство-расширение для любой последовательности.
    extension<T>(IEnumerable<T> source)
    {
        public bool IsEmpty => !source.Any();
    }
}

// ref struct может реализовывать интерфейсы (C# 13).
interface IDescribable
{
    string Describe();
}

ref struct SpanStats(ReadOnlySpan<int> values) : IDescribable
{
    private readonly ReadOnlySpan<int> _values = values;

    public string Describe()
    {
        int min = int.MaxValue, max = int.MinValue;
        foreach (int value in _values) (min, max) = (Math.Min(min, value), Math.Max(max, value));
        return $"{_values.Length} values in [{min}, {max}]";
    }
}

// partial: определение типа можно разбить на части (обычно — по разным файлам).
// Частичное свойство (C# 13): объявление в одной части, реализация — в другой.
// Именно так генераторы кода дописывают ваши классы.
partial class Telemetry
{
    public partial string Source { get; }
}

partial class Telemetry
{
    public partial string Source => "sensor-7";
}

delegate bool TryParseDelegate(string text, out int result);

static class Section15_Newest
{
    // `allows ref struct` (C# 13): обобщённый метод, принимающий в том числе ref struct.
    static string DescribeAny<T>(T item) where T : IDescribable, allows ref struct => item.Describe();

    // params с любой коллекцией (C# 13): для ReadOnlySpan массив в куче не создаётся.
    static int Total(params ReadOnlySpan<int> values)
    {
        int total = 0;
        foreach (int value in values) total += value;
        return total;
    }

    public static void Run()
    {
        Header(15, "Newest features: C# 12-14 (and C# 15)");

        // --- C# 14 ------------------------------------------------------------------------
        var stats = new Accumulator();
        stats += 3.0; // вызывает наш operator += и меняет stats на месте
        stats += 5.0;
        Console.WriteLine($"compound assignment operator: mean {stats.Mean} of {stats.Count} values");

        // Присваивание через `?.`: выполняется, только если слева не null.
        Order? order = null;
        order?.Quantity = 5; // ничего не происходит — и никакого исключения
        Console.WriteLine($"assignment through null: order is still null: {order is null}");
        order = new Order();
        order?.Quantity = 5;
        order?.Note ??= "added later";
        Console.WriteLine($"null-conditional assignment: {order?.Quantity}, '{order?.Note}'");

        // Операторы и свойства из блоков extension.
        Console.WriteLine($"extension operator: {"ab" * 3} | extension property: {Array.Empty<int>().IsEmpty}");

        // nameof для открытого обобщённого типа; модификаторы параметров лямбды без типов.
        TryParseDelegate parse = (text, out result) => int.TryParse(text, out result);
        Console.WriteLine($"{nameof(List<>)} | {parse("42", out int number)} {number}");

        // Спаны — «первоклассные» типы: массив сам превращается в Span там, где он нужен.
        int[] measurements = [7, 3, 9];
        Console.WriteLine($"{Total(measurements)} {Total(1, 2, 3)} | {DescribeAny(new SpanStats(measurements))}");

        // --- C# 13 ------------------------------------------------------------------------
        var telemetry = new Telemetry();
        var buffer = new List<int> { 1, 2, 3 };
        Console.WriteLine($"partial property: {telemetry.Source} | escape \\e is U+{(int)'\e':X4} | " +
                          $"index from the end: {buffer[^1]}");

        // --- C# 12 ------------------------------------------------------------------------
        Coordinates home = (48.137, 11.575); // псевдоним кортежа, объявленный в начале файла
        int[] row = [1, 2, 3];
        int[][] table = [row, [.. row, 4], []];
        Console.WriteLine($"type alias: {home.Latitude}, {home.Longitude} | " +
                          $"collection expressions, row lengths: {Join(table.Select(r => r.Length))}");
    }
}

#if CSHARP15
// =====================================================================================
//  C# 15 (.NET 11) — включается символом CSHARP15 в начале файла
// =====================================================================================
//
//  ВНИМАНИЕ: этот блок при проверке не компилировался (в среде проверки был только
//  .NET SDK 10). Синтаксис взят из документации Microsoft «What's new in C# 15».
namespace CSharp15
{
    public record class Cat(string Name);
    public record class Dog(string Name);
    public record class Bird(string Name);

    // Тип-объединение: значение Pet — это РОВНО ОДИН из перечисленных типов.
    // C++: std::variant<Cat, Dog, Bird>.
    public union Pet(Cat, Dog, Bird);

    // Закрытая иерархия: наследники возможны только в этой сборке, поэтому компилятор
    // знает их все и проверяет switch на исчерпываемость.
    public closed record class GateState;
    public record class Closed : GateState;
    public record class Open(float Percent) : GateState;

    public static class Demo
    {
        static string Describe(GateState state) => state switch
        {
            Closed => "closed",
            Open(var percent) => $"{percent}% open",
            // Ветка `_` не нужна: перечислены все прямые наследники GateState.
        };

        public static void Run()
        {
            Console.WriteLine("\n=== C# 15 ===");

            Pet pet = new Dog("Rex"); // неявное преобразование из типа-случая
            string name = pet switch  // исчерпывающий switch без ветки `_`
            {
                Dog dog => dog.Name,
                Cat cat => cat.Name,
                Bird bird => bird.Name,
            };
            Console.WriteLine($"union: {name} | closed hierarchy: {Describe(new Open(40))}, {Describe(new Closed())}");

            // Аргументы конструктора прямо в выражении-коллекции.
            string[] values = ["one", "two", "three"];
            List<string> names = [with(capacity: values.Length * 2), .. values];
            HashSet<string> set = [with(StringComparer.OrdinalIgnoreCase), "Hello", "HELLO", "hello"];
            Console.WriteLine($"with(...): capacity {names.Capacity}, set size {set.Count}");

            // break и continue с меткой: выход из вложенных циклов без goto и флагов.
            int visited = 0;
            outer: for (int row = 0; row < 3; row++)
            {
                for (int column = 0; column < 3; column++)
                {
                    if (column > row) continue outer;   // перейти к следующей строке
                    if (row + column == 3) break outer; // выйти из обоих циклов
                    visited++;
                }
            }
            Console.WriteLine($"labeled break/continue: {visited} cells visited");
        }
    }
}
#endif
