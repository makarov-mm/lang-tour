#:property AllowUnsafeBlocks=true
#:property PublishAot=false
// To enable the C# 15 examples of section 15 (.NET SDK 11 required), uncomment this line:
// #define CSHARP15

// =====================================================================================
//  C# FOR C++ DEVELOPERS — a language tour in a single file, from simple to advanced
// =====================================================================================
//
//  Running (.NET SDK 10 or newer required). No project is needed: this is a "file-based
//  app", and the `#:property` lines at the top of the file are its settings.
//
//      dotnet run csharp_tour.cs
//
//  What the settings mean:
//    AllowUnsafeBlocks — allow unsafe code and pointers (sections 10 and 11);
//    PublishAot=false  — file-based apps are prepared for native compilation (Native AOT)
//                        by default, while the tour uses reflection and dynamic
//                        (section 14), which are incompatible with AOT.
//
//  Building as a regular project: `dotnet new console`, replace Program.cs with this file,
//  add <AllowUnsafeBlocks>true</AllowUnsafeBlocks> to the .csproj and delete both
//  `#:property` lines.
//
//  Verified with .NET SDK 10.0.115, language C# 14. The C# 15 (.NET 11) examples at the
//  end of the file are switched off by the CSHARP15 symbol and were NOT compiled during
//  verification: only SDK 10 was available. Their syntax follows Microsoft's
//  "What's new in C# 15" documentation.
//
//  How to read. Each section is a static class `SectionNN_*` with a Run method; the types
//  a section needs are declared right before it. A "C++:" note shows the closest C++
//  counterpart. Commented-out lines with an error code (CS0266 and the like) show what
//  the compiler rejects.
//
//  The main differences from C++ to keep in mind from the first line:
//
//   1. A managed runtime. Code is compiled to bytecode (IL), and a JIT compiler turns it
//      into machine code at startup. Memory is managed by a garbage collector (GC): there
//      is no `delete`, and dangling references, double frees and out-of-bounds array
//      access do not exist in safe code — instead of UB there is always an exception.
//   2. Copy behaviour is defined by the TYPE itself, not by the point of use: a `class`
//      is a reference type (an object on the heap, the variable holds a reference), a
//      `struct` is a value type (copied as a whole). In C++ the two are the same thing;
//      here it is the main distinction (section 2).
//   3. There are no deterministic destructors. IDisposable and `using` replace RAII
//      (section 9).
//   4. No headers, no prototypes, no declaration order. The unit of compilation is the
//      assembly: types see each other regardless of order and file.
//   5. Generics are not templates: the body is checked once against the `where`
//      constraints rather than at every instantiation; there are no specializations and
//      no computations over types, but generic types exist at run time (section 6).
//   6. Single inheritance of classes and multiple implementation of interfaces; all types
//      share one ancestor, System.Object.
//   7. Everything about types is known at run time: reflection, attributes, code
//      generation on the fly (section 14). C++ gets reflection only in C++26, and only
//      a static one.
//   8. There is no preprocessor in the C++ sense: no macros, no #include — only #if and
//      #define.
//
//  Contents:
//    1. Basics: types, variables, strings             9. Errors, resources, GC, null safety
//    2. Value types and reference types              10. Memory and speed: Span, ref, SIMD
//    3. Classes, properties, records                 11. unsafe code and native interop
//    4. Inheritance and interfaces                   12. Threads and synchronization
//    5. Pattern matching                             13. async/await
//    6. Generics                                     14. Reflection, attributes, code generation
//    7. Delegates, lambdas, events                   15. The newest: C# 12-14 and C# 15
//    8. Collections, iterators, LINQ
// =====================================================================================

// `using` opens a namespace. C++: using namespace. There are no files to include: types
// come from the assemblies the project references. The console project template and
// file-based apps turn on "implicit usings" (System, System.Linq, System.Threading.Tasks
// and a few more); here everything is listed explicitly to show where each name comes from.
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
using static Tour; // using static: members of the static class Tour are usable without its name
using Coordinates = (double Latitude, double Longitude); // a type alias (C++: using X = ...)

// =====================================================================================
//  ENTRY POINT
// =====================================================================================
// Top-level statements (C# 9): the compiler wraps this code into a Main method by itself.
// C++: int main(). Type declarations must come AFTER these statements.

// The Windows console is not UTF-8 by default: without this line non-ASCII characters turn into "?".
Console.OutputEncoding = Encoding.UTF8;

// Numbers and dates are formatted by the OS regional settings by default ("3,5" or "3.5").
// Pin the invariant culture so that the output is the same on any machine.
CultureInfo.CurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture; // for thread-pool threads

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
await Section13_AsyncAwait.RunAsync(); // await is allowed right at the top level
Section14_Reflection.Run();
Section15_Newest.Run();
#if CSHARP15
CSharp15.Demo.Run();
#endif

Console.WriteLine("\nAll 15 sections completed.");

// A static class is a "container" of static members: it cannot be instantiated.
// C# has no free functions: every method belongs to some type.
static class Tour
{
    // An expression-bodied method (`=>`) is shorthand for a body made of a single expression.
    public static void Header(int number, string title) =>
        Console.WriteLine($"\n=== {number,2}. {title} ===");

    // Joins the elements of a sequence — used in every section.
    public static string Join<T>(IEnumerable<T> items, string separator = ", ") =>
        string.Join(separator, items);
}

// =====================================================================================
//  1. BASICS: types, variables, strings, control flow
// =====================================================================================

// An enum is a set of strongly typed named integer constants. C++: enum class.
enum Color : byte { Red, Green, Blue }

// [Flags] is an attribute: "this is a set of bit flags". It affects ToString() and parsing.
[Flags]
enum Permissions { None = 0, Read = 1, Write = 2, Execute = 4, All = Read | Write | Execute }

static class Section01_Basics
{
    // const is a compile-time constant (numbers, bool, char, string, enum). C++: constexpr.
    const int MaxPoints = 100_000; // `_` is a digit separator (C++: 100'000)

    // static readonly: the value is computed once, when the type is initialized.
    static readonly double Tau = 2 * Math.PI;

    public static void Run()
    {
        Header(1, "Basics: types, variables, strings, control flow");

        // --- Built-in types -------------------------------------------------------------
        // Sizes are FIXED on every platform (in C++ they depend on the compiler and the OS):
        // sbyte/byte — 8 bits, short/ushort — 16, int/uint — 32, long/ulong — 64,
        // nint/nuint — pointer-sized, float — 32, double — 64, char — 16 (UTF-16!).
        int a = 42;
        var d = 3.5;              // var: the type is inferred (double). C++: auto
        long big = 9_000_000_000;
        float f = 2.5f;
        decimal price = 19.99m;   // a 128-bit DECIMAL number for money; C++ has no counterpart
        char letter = 'λ';        // a 16-bit UTF-16 code unit (in C++ a char is one byte)
        bool flag = true;         // bool does not convert to a number: `if (a)` is a compile error
        byte b = 0xFF;
        nint native = -1;         // C++: intptr_t
        Console.WriteLine($"{a} {d} {big} {f} {price} {letter} {flag} {b} {native}");
        Console.WriteLine($"sizeof: char {sizeof(char)}, int {sizeof(int)}, long {sizeof(long)}, " +
                          $"decimal {sizeof(decimal)}, nint {nint.Size}");
        Console.WriteLine($"0.1 + 0.2 == 0.3: double {0.1 + 0.2 == 0.3}, decimal {0.1m + 0.2m == 0.3m}" +
                          $" | MaxPoints {MaxPoints}, Tau {Tau:F4}");

        // A local variable cannot be read before it is assigned: COMPILE error CS0165
        // (in C++ — garbage and undefined behaviour).
        //     int garbage;
        //     Console.WriteLine(garbage);

        // --- Conversions and overflow ---------------------------------------------------
        double ratio = a / 5;      // integer division, as in C++: 8
        int truncated = (int)3.99; // an explicit cast: 3
        long widened = a;          // widening is implicit
        // int bad = 3.7;          // CS0266: no implicit narrowing (C++ would silently drop the fraction)

        // Overflow is ALWAYS defined: by default the value wraps around (in C++ that is UB for
        // signed types), and in a checked context an exception is thrown.
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

        // --- Strings ----------------------------------------------------------------------
        // A string is an IMMUTABLE sequence of UTF-16 code units; a reference type that is
        // compared by content. C++: closer to shared_ptr<const u16string> than to std::string.
        string name = "World";
        string greeting = $"Hello, {name}!"; // interpolation. C++: std::format
        string path = @"C:\dir\file";        // a "verbatim" string: no escaping
        string json = """
            {"kind": "raw string", "escaping": "not needed"}
            """; // a raw string (C# 11): the common indentation is cut at the closing quotes
        string template = $$"""{"value": {{a}}}"""; // $$: interpolation uses double braces
        Console.WriteLine($"{greeting} | {greeting.Length} | {greeting.ToUpperInvariant()} | " +
                          $"{greeting[7..12]} | {greeting.Contains("World")}");
        Console.WriteLine($"{path} | {json} | {template}");

        string built = string.Concat("Hel", "lo"); // a new string created at run time
        Console.WriteLine($"same text: {built == "Hello"}, same object: {ReferenceEquals(built, "Hello")}, " +
                          $"ignore case: {string.Equals(built, "HELLO", StringComparison.OrdinalIgnoreCase)}");

        // Every "edit" of a string creates a new string. To build one piece by piece use
        // StringBuilder (C++: std::string with += or std::ostringstream).
        var builder = new StringBuilder("[");
        for (int i = 1; i <= 5; i++) builder.Append(i).Append(i < 5 ? ", " : "]");
        Console.WriteLine(builder.ToString());

        // Formatting: {value,width:format}.
        Console.WriteLine($"[{9.87654,8:F3}] [{"ab",-6}] [{255:X4}] [{0.256:P1}] [{1234567.891:N2}] " +
                          $"[{42:D5}] [{1234.5:E2}] [{7:+0;-0}]");

        // Length counts 16-bit code units, not characters: an emoji is two units.
        string mixed = "aß😀";
        Console.WriteLine($"UTF-16 units {mixed.Length}, code points {mixed.EnumerateRunes().Count()}, " +
                          $"UTF-8 bytes {Encoding.UTF8.GetByteCount(mixed)}");

        // --- Nullable values: `int?` is Nullable<int>. C++: std::optional<int> --------------
        int? maybe = null;
        int fallback = maybe ?? -1; // ?? means "take the right side if the left one is null"
        maybe ??= 10;               // assign only if it is null now
        Console.WriteLine($"{fallback} {maybe} {maybe.HasValue} {maybe.Value + 1}");

        // --- Arrays -----------------------------------------------------------------------
        // An array is a heap object: it knows its length, and bounds are checked on every access.
        int[] primes = [2, 3, 5, 7, 11]; // a collection expression (C# 12)
        int[] alias = primes;            // the REFERENCE is copied: it is the same array (a std::array would be copied)
        alias[0] = 100;
        int[] copy = [.. primes];        // and this is a copy: `..` spreads a collection
        copy[1] = -1;
        // ^1 is an index from the end, 1..^1 is a range; slicing an array creates a NEW array.
        Console.WriteLine($"{primes[0]} {primes[1]} | length {primes.Length} | last {primes[^1]} | " +
                          $"middle [{Join(primes[1..^1])}]");
        try
        {
            _ = primes[10]; // `_` is a discard: "the value is not needed"
        }
        catch (IndexOutOfRangeException e)
        {
            Console.WriteLine($"primes[10] -> {e.GetType().Name}, not undefined behaviour");
        }

        int[,] grid = new int[2, 3];               // a rectangular array: one block of memory
        grid[1, 2] = 7;
        int[][] jagged = [[1], [2, 3], [4, 5, 6]]; // a "jagged" one: an array of arrays (vector<vector<int>>)
        Console.WriteLine($"grid {grid.GetLength(0)}x{grid.GetLength(1)}, grid[1, 2] = {grid[1, 2]}, " +
                          $"jagged[2].Length = {jagged[2].Length}");

        // --- Control flow -----------------------------------------------------------------
        // if / while / do / for work as in C++, but the condition must be of type bool.
        int sum = 0;
        for (int i = 0; i < 5; i++) sum += i;
        foreach (int p in primes) sum += p; // C++: range-for

        // The switch statement: no fall-through from one branch to the next — break or return is required.
        string kind;
        switch (letter)
        {
            case 'a':
            case 'e':
            case 'o': // several labels for one branch are allowed
                kind = "latin vowel";
                break;
            case >= 'α' and <= 'ω': // patterns are allowed in case labels (section 5)
                kind = "greek letter";
                break;
            default:
                kind = "something else";
                break;
        }

        // The switch EXPRESSION (C# 8) returns a value.
        string size = a switch { < 10 => "small", < 100 => "medium", _ => "large" };
        Console.WriteLine($"sum {sum}, '{letter}' is a {kind}, {a} is {size}");

        // --- Tuples. C++: std::tuple and structured bindings ------------------------------
        (int quotient, int remainder) = Math.DivRem(17, 5);
        var point = (X: 3, Y: 4); // elements can be named
        (int x, int y) = point;   // deconstruction
        (x, y) = (y, x);          // a swap without a temporary variable
        Coordinates munich = (48.137, 11.575);
        Console.WriteLine($"17 / 5 = {quotient} rem {remainder} | {point} | swapped ({x}, {y}) | " +
                          $"equal: {point == (3, 4)} | latitude {munich.Latitude}");

        // --- Enumerations -----------------------------------------------------------------
        Color color = Color.Green;
        Permissions rights = Permissions.Read | Permissions.Write;
        Console.WriteLine($"{color} = {(int)color}, parsed {Enum.Parse<Color>("Blue")}, " +
                          $"all: {Join(Enum.GetValues<Color>(), "/")}");
        Console.WriteLine($"{rights} | can write: {rights.HasFlag(Permissions.Write)} | " +
                          $"can execute: {(rights & Permissions.Execute) != 0} | All = {(int)Permissions.All}");
    }
}

// =====================================================================================
//  2. VALUE TYPES AND REFERENCE TYPES
// =====================================================================================
//
//  In C++ every type is a value, and "reference-ness" is chosen at the point of use: T, T&, T*.
//  In C# it is the other way round — the behaviour is built into the type itself:
//
//    struct (as well as int, double, bool, enum, tuples) is a VALUE type. The variable holds
//      the data itself; assignment and passing to a method copy it. The value lives on the
//      stack or right inside the object or array it belongs to.
//
//    class (as well as string, arrays, delegates) is a REFERENCE type. The object lives on the
//      managed heap and the variable holds a reference; assignment copies the reference. The
//      closest analogy is shared_ptr<T>, only without a counter: unreachable objects are
//      found and removed by the GC.

struct PointStruct
{
    public double X, Y; // public fields for brevity; normally properties are used (section 3)

    // override: overriding a virtual method of the base type (here, object).
    public override readonly string ToString() => $"({X}, {Y})";
}

class PointClass
{
    public double X, Y;

    public override string ToString() => $"({X}, {Y})";
}

static class Section02_ValueAndReferenceTypes
{
    // An argument is always a copy of the VARIABLE: for a struct a copy of the data, for a class a copy
    // of the reference.
    static void MoveStruct(PointStruct p) => p.X += 10; // the local copy changes
    static void MoveClass(PointClass p) => p.X += 10;   // the shared object changes

    // ref: the parameter is an alias of the caller's variable. C++: T&.
    static void MoveByRef(ref PointStruct p) => p.X += 10;

    // in: a read-only reference, no copy. C++: const T&.
    static double Length(in PointStruct p) => Math.Sqrt(p.X * p.X + p.Y * p.Y);

    // out: an "output" parameter that the method must assign. The Try... idiom: success is
    // returned as a bool, the result through out. C++: bool f(T& result) or std::optional.
    static bool TryParsePoint(string text, out PointStruct point)
    {
        point = default; // default is the "zero" value of any type
        string[] parts = text.Split(',');
        return parts.Length == 2
            && double.TryParse(parts[0], CultureInfo.InvariantCulture, out point.X)
            && double.TryParse(parts[1], CultureInfo.InvariantCulture, out point.Y);
    }

    // The array is created in a separate method: once the method returns, no references to
    // the array remain anywhere. (NoInlining forbids the JIT to inline the method into its caller.)
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

        // --- Copying ----------------------------------------------------------------------
        var s1 = new PointStruct { X = 1, Y = 2 }; // an object initializer
        var s2 = s1; // a COPY of all fields
        s2.X = 100;
        var c1 = new PointClass { X = 1, Y = 2 };
        var c2 = c1; // a copy of the REFERENCE: c1 and c2 are one and the same object
        c2.X = 100;
        Console.WriteLine($"struct: s1 = {s1}, s2 = {s2} | class: c1 = {c1}, c2 = {c2}, " +
                          $"same object: {ReferenceEquals(c1, c2)}");

        // --- Parameter passing ------------------------------------------------------------
        MoveStruct(s1); // s1 does not change
        MoveClass(c1);  // the object changes
        Console.WriteLine($"after Move: s1 = {s1}, c1 = {c1}");
        MoveByRef(ref s1); // `ref` is written at the call site too: passing by reference is visible
        // Arguments are evaluated strictly left to right (in C++ the order is unspecified), so
        // the variable parsed can be declared in one argument and used in the next.
        Console.WriteLine($"after MoveByRef: s1 = {s1}, length {Length(in s1):F3} | " +
                          $"{TryParsePoint("3, 4", out var parsed)} {parsed} | {TryParsePoint("oops", out _)}");

        // --- Comparison -------------------------------------------------------------------
        // For classes == compares REFERENCES by default (like pointers). Comparison by content
        // has to be defined by hand — or use a record (section 3).
        var c3 = new PointClass { X = c1.X, Y = c1.Y };
        Console.WriteLine($"c1 == c3: {c1 == c3}, struct Equals compares fields: {s1.Equals(s1 with { })}");

        // --- Boxing -----------------------------------------------------------------------
        // A value type can be converted to object or to an interface: the value is COPIED into a
        // new heap object. That is a hidden allocation — hot code avoids it (generics!).
        int number = 42;
        object boxed = number;    // boxing
        number = 43;              // does not affect the boxed copy
        int unboxed = (int)boxed; // unboxing: a type check and a copy back
        Console.WriteLine($"boxed {boxed}, unboxed {unboxed}, number {number}, type {boxed.GetType().Name}, " +
                          $"is int: {boxed is int}, is long: {boxed is long}");

        // --- null -------------------------------------------------------------------------
        // A reference can be null; `?` after the type tells the compiler so (section 9).
        // Access through null is always a NullReferenceException, not UB.
        PointClass? nothing = null;
        Console.WriteLine($"nothing?.X is null: {nothing?.X is null}, default(int) = {default(int)}, " +
                          $"default(PointStruct) = {default(PointStruct)}");
        try
        {
            Console.WriteLine(nothing!.X); // `!` means "I vouch it is not null" (wrongly, here)
        }
        catch (NullReferenceException)
        {
            Console.WriteLine("NullReferenceException instead of undefined behaviour");
        }

        // --- Where the data lives ---------------------------------------------------------
        // An array of structs is one contiguous block of memory (like std::vector<Point>). An
        // array of class objects is a block of REFERENCES to separate objects (like
        // vector<shared_ptr<Point>>).
        var structs = new PointStruct[1000]; // 16,000 bytes; all points already exist (zeroed)
        var classes = new PointClass[1000];  // 1000 references, all null so far
        Console.WriteLine($"structs[0] = {structs[0]}, classes[0] is null: {classes[0] is null}, " +
                          $"size of PointStruct: {Unsafe.SizeOf<PointStruct>()} bytes");

        // --- The garbage collector --------------------------------------------------------
        // An object is alive while it is reachable through references. Nothing has to be freed,
        // but the moment of release is not defined either: there are no destructors in the C++
        // sense (section 9).
        long before = GC.GetTotalMemory(forceFullCollection: true); // a named argument
        long during = AllocateAndForget(); // 10 MB allocated and immediately turned into garbage
        long after = GC.GetTotalMemory(forceFullCollection: true);
        Console.WriteLine($"allocated ~{(during - before) / 1_000_000} MB, " +
                          $"after collection ~{(after - before) / 1_000_000} MB");
    }
}

// =====================================================================================
//  3. CLASSES, PROPERTIES, RECORDS
// =====================================================================================

// readonly record struct: an immutable value type in one line. The compiler generates the
// constructor, the properties X and Y, Equals/GetHashCode/==, ToString and deconstruction.
// C++: a struct with `operator<=>(...) = default` and hand-written printing.
readonly record struct Vec2(double X, double Y)
{
    public static readonly Vec2 Zero = new(0, 0);

    // A property with no backing storage: computed on every access.
    public double LengthSquared => X * X + Y * Y;
    public double Length => Math.Sqrt(LengthSquared);

    // Operator overloading: always public static. C++: a free function or a class member.
    public static Vec2 operator +(Vec2 a, Vec2 b) => new(a.X + b.X, a.Y + b.Y);
    public static Vec2 operator -(Vec2 a, Vec2 b) => new(a.X - b.X, a.Y - b.Y);
    public static Vec2 operator *(Vec2 v, double k) => new(v.X * k, v.Y * k);
    public static Vec2 operator -(Vec2 v) => new(-v.X, -v.Y);

    // User-defined conversions: implicit ones apply silently, explicit ones only through a cast.
    // C++: a constructor without explicit and `explicit operator double()`.
    public static implicit operator Vec2((double X, double Y) tuple) => new(tuple.X, tuple.Y);
    public static explicit operator double(Vec2 v) => v.Length;

    // The generated ToString would list all properties; any generated member can be replaced
    // with your own.
    public override string ToString() => $"({X}, {Y})";
}

// A class: declaration and definition are in one place, and member order does not matter.
// The access modifier is written on EVERY member (the default is private).
class Particle
{
    private static int _created; // static: one field per type

    // A property is a get/set pair of methods that looks like a field. C++ has no counterpart:
    // one writes getX()/setX() there. An auto-property creates its hidden backing field by itself.
    public string Name { get; }               // read-only: set in the constructor
    public double Mass { get; private set; }  // anyone can read, only the class itself can change it
    public Vec2 Position { get; set; }
    public Vec2 Velocity { get; set; } = Vec2.Zero; // an initializer

    // A property with validation. `field` (C# 14) is that hidden backing field of the auto-property.
    public double Charge
    {
        get;
        set => field = Math.Clamp(value, -1, 1);
    }

    // required: the caller MUST set the property in the object initializer;
    // init: it can be set only there, afterwards the property is immutable.
    public required string Kind { get; init; }

    // A computed property.
    public double KineticEnergy => 0.5 * Mass * Velocity.LengthSquared;

    public static int Created => _created;

    public Particle(string name, double mass)
    {
        Name = name;
        Mass = mass;
        _created++;
    }

    // Delegating to another constructor. C++: Particle(string n) : Particle(n, 1.0) {}
    public Particle(string name) : this(name, 1.0) { }

    public void Advance(double dt) => Position += Velocity * dt;

    // Deconstruction: allows writing `var (name, mass) = particle;`.
    public void Deconstruct(out string name, out double mass) => (name, mass) = (Name, Mass);

    // C++: operator<< or a std::formatter specialization.
    public override string ToString() => $"{Kind} '{Name}' at ({Position.X}, {Position.Y})";
}

// record (class): a reference type with value semantics — comparison by content and
// "non-destructive mutation" through with. Records can be inherited.
record Employee(string Name, string Department, decimal Salary);

record Manager(string Name, string Department, decimal Salary, int Reports)
    : Employee(Name, Department, Salary);

// A primary constructor of a class (C# 12): the parameters are visible in the whole class body.
class Counter(string name, int start = 0) // a parameter with a default value
{
    private int _value = start;

    public string Name => name;

    public int Next() => ++_value;
}

// params: a variable number of arguments. C++: a variadic template or initializer_list.
class Polynomial(params double[] coefficients)
{
    private readonly double[] _c = coefficients; // readonly: the field cannot be reassigned

    public int Degree => _c.Length - 1;

    // An indexer. C++: operator[].
    public double this[int power] => power < _c.Length ? _c[power] : 0.0;

    public double Evaluate(double x)
    {
        double result = 0;
        for (int i = Degree; i >= 0; i--) result = result * x + _c[i]; // Horner's scheme
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

        // A class object is created only with new and only on the heap; delete does not exist.
        var electron = new Particle("electron", 9.109e-31)
        {
            Kind = "lepton", // an object initializer: property assignments right after the constructor
            Velocity = new Vec2(2e6, 0),
            Charge = -5, // the setter clamps the value to the range [-1, 1]
        };
        electron.Advance(1e-6);
        // electron.Name = "x";       // CS0200: the property has no setter
        // _ = new Particle("x");     // CS9035: the required property Kind is not set
        var (particleName, mass) = electron; // user-defined deconstruction
        Console.WriteLine($"{electron} | charge {electron.Charge} | E = {electron.KineticEnergy:E3} J | " +
                          $"{particleName}, {mass:E3} kg | created: {Particle.Created}");

        // --- A record struct --------------------------------------------------------------
        Vec2 v = new(3, 4);             // new with the type inferred from the left-hand side
        Vec2 w = (1, 1);                // the implicit operator from a tuple
        Vec2 moved = v with { X = 30 }; // a copy with one property changed
        var (vx, vy) = v;               // deconstruction generated for the record
        Console.WriteLine($"{v + w * 2} | {-v} | length {(double)v} | {moved} | {vx}, {vy} | " +
                          $"equal: {v == new Vec2(3, 4)}");

        // --- Record classes ---------------------------------------------------------------
        var alice = new Employee("Alice", "R&D", 5200m);
        var twin = new Employee("Alice", "R&D", 5200m);
        var promoted = alice with { Salary = 6000m };
        Employee boss = new Manager("Bob", "R&D", 9000m, Reports: 7); // a named argument
        Console.WriteLine($"equal by value: {alice == twin}, same object: {ReferenceEquals(alice, twin)}");
        Console.WriteLine($"{promoted} | {boss}");

        // --- Primary constructor, params, indexer, operators ------------------------------
        var counter = new Counter("requests", start: 10);
        counter.Next();
        var polynomial = new Polynomial(1, 2, 3) + new Polynomial(0, 0, 0, 4);
        Console.WriteLine($"{counter.Name}: {counter.Next()} | p(x) = {polynomial} | degree {polynomial.Degree} | " +
                          $"p[2] = {polynomial[2]} | p(2) = {polynomial.Evaluate(2)}");

        // Access levels: public; private (the default for members); protected; internal —
        // "within the assembly" (the default for types); protected internal; private protected;
        // file — the type is visible only in its own file (C# 11).
    }
}

// =====================================================================================
//  4. INHERITANCE AND INTERFACES
// =====================================================================================

// An abstract class. Inheritance is always "public"; there can be only one base class.
abstract class Shape
{
    // An abstract property. C++: virtual double area() const = 0;
    public abstract double Area { get; }

    // virtual — as in C++: without the word the method is non-virtual.
    public virtual string Name => "shape";

    // A non-virtual method that calls virtual members.
    public string Describe() => $"{Name} with area {Area:F2}";

    // No virtual destructor is needed: there are no destructors, the GC frees the memory.
}

// sealed forbids inheritance (C++: final). The primary constructor keeps radius.
sealed class Circle(double radius) : Shape
{
    public double Radius => radius;

    // override is MANDATORY (in C++ it is merely recommended).
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

// Calling the base class constructor. C++: Square(double s) : Rectangle(s, s) {}
sealed class Square(double side) : Rectangle(side, side)
{
    // base refers to the base class implementation. C++: Rectangle::name().
    public override string Name => $"square, a {base.Name}";
}

// An interface is a contract without state. A class inherits ONE class but implements any
// number of interfaces. C++: an abstract class made only of pure virtual functions.
interface IDrawable
{
    string Draw();

    // A method with a default implementation (C# 8): an interface can be extended without
    // breaking existing implementations. It is reachable only through an interface reference.
    string DrawTwice() => Draw() + Draw();
}

interface IExportable
{
    string Export();
}

class Label(string text) : IDrawable, IExportable
{
    public string Draw() => $"[{text}]";

    // Explicit interface implementation: the method is visible only through a reference of
    // type IExportable. This is how name clashes between interfaces are resolved.
    string IExportable.Export() => $"{{\"label\": \"{text}\"}}"; // {{ }} are escaped braces
}

// Hiding and overriding.
class Animal
{
    public virtual string Speak() => "...";
    public string Kind() => "animal";
}

class Dog : Animal
{
    public override string Speak() => "Woof"; // overriding: works through a base reference
    public new string Kind() => "dog";        // new: HIDING a non-virtual method (as in C++)
}

// The initialization order differs from C++: the field initializers of the derived class
// run BEFORE the base constructor, and a virtual call from the base constructor reaches
// the derived class.
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

        // Polymorphism out of the box: a variable of type Shape is already a reference and the
        // objects live on the heap. No unique_ptr and no slicing.
        Shape[] shapes = [new Circle(1.0), new Rectangle(2.0, 3.0), new Square(2.0)];
        double total = 0;
        foreach (Shape shape in shapes)
        {
            total += shape.Area;
            Console.WriteLine(shape.Describe());
            // A type test that declares a variable. C++: if (auto* c = dynamic_cast<Circle*>(p)).
            if (shape is Circle circle) Console.WriteLine($"    it is a circle of radius {circle.Radius}");
        }
        Console.WriteLine($"total area {total:F2}");

        // Casts: `as` yields null on failure, (T)x throws InvalidCastException.
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

        // All types share the ancestor object: ToString, Equals, GetHashCode, GetType.
        object anything = shapes[2];
        Console.WriteLine($"{anything.GetType().Name} : {anything.GetType().BaseType?.Name}, " +
                          $"is Shape: {anything is Shape}, is IDrawable: {anything is IDrawable}");

        // --- Interfaces -------------------------------------------------------------------
        var label = new Label("OK");
        IDrawable drawable = label;
        IExportable exportable = label;
        // label.Export();     // CS1061: the explicit implementation is not visible through type Label
        // label.DrawTwice();  // CS1061: the default method is visible only through the interface
        Console.WriteLine($"{label.Draw()} {drawable.DrawTwice()} {exportable.Export()}");

        // --- override and new -------------------------------------------------------------
        Dog dog = new();
        Animal animal = dog;
        Console.WriteLine($"override: {animal.Speak()} / {dog.Speak()} | new: {animal.Kind()} / {dog.Kind()}");

        // --- Initialization order -----------------------------------------------------------
        var widget = new DerivedWidget();
        Console.WriteLine($"    fully constructed: {widget.Who()}");
    }
}

// =====================================================================================
//  5. PATTERN MATCHING
// =====================================================================================
//
//  C++ has only structured bindings and std::visit; pattern matching has not made it into
//  the standard yet. In C# it is a large part of the language: patterns test the type, the
//  values, the properties and the shape of data — and bind the parts to variables at once.

// An expression tree made of records: every node is a small type of its own.
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
        int n when n < 0 => $"negative int {n}",            // a type pattern + a when condition
        0 or 1 => "bit",                                     // constants and the logical `or`
        int n => $"int {n}",
        double d and > 0 and < 1 => $"fraction {d}",         // relational patterns and `and`
        string { Length: 0 } => "empty string",              // a property pattern
        string { Length: var length } => $"string of length {length}",
        Vec2(0, 0) => "origin",                              // a positional pattern (deconstruction)
        Vec2 { X: var x, Y: var y } when x == y => $"diagonal point {x}",
        int[] { Length: 0 } => "empty array",
        int[] and [var first, .., var last] => $"array {first}..{last}", // a list pattern (C# 11)
        (int a, int b) => $"pair with sum {a + b}",          // a tuple
        Shape { Area: > 10 } shape => $"big {shape.Name}",   // a property + a name for the whole object
        not IDisposable => "something not disposable",       // negation
        _ => "something else",                               // the "anything" pattern
    };

    // A tuple as the subject of the match: a decision table without nested ifs.
    static string Play(string first, string second) => (first, second) switch
    {
        ("rock", "scissors") or ("scissors", "paper") or ("paper", "rock") => "first wins",
        _ when first == second => "draw",
        _ => "second wins",
    };

    // A recursive tree walk: positional patterns take the records apart.
    // The Expr hierarchy is open for inheritance, so without the `_` arm the compiler warns
    // about a non-exhaustive switch. (C# 15 has `closed` and `union` for this: with them the
    // compiler knows all the cases and the `_` arm is not needed.)
    static double Eval(Expr expr, IReadOnlyDictionary<string, double> variables) => expr switch
    {
        Num(var value) => value,
        Var(var name) => variables[name],
        Neg(var operand) => -Eval(operand, variables),
        Add(var left, var right) => Eval(left, variables) + Eval(right, variables),
        Mul(var left, var right) => Eval(left, variables) * Eval(right, variables),
        _ => throw new NotSupportedException(expr.GetType().Name),
    };

    // Nested patterns: algebraic simplifications are written almost as in a textbook.
    // First the subtrees are simplified, then the rules are applied to the pair of results.
    static Expr Simplify(Expr expr) => expr switch
    {
        Add(var l, var r) => (Simplify(l), Simplify(r)) switch
        {
            (Num(0), var right) => right,                    // 0 + x = x
            (var left, Num(0)) => left,                      // x + 0 = x
            (Num(var a), Num(var b)) => new Num(a + b),      // constant folding
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

        // Patterns in conditions: `is` tests and declares variables at the same time.
        Shape shape = new Circle(2);
        if (shape is Circle { Radius: > 1 and var radius }) Console.WriteLine($"a circle with radius {radius}");
        int age = 42;
        Console.WriteLine($"{age is >= 18 and < 65}, {shape is not Rectangle}, " +
                          $"{Play("rock", "scissors")}, {Play("paper", "paper")}, {Play("rock", "paper")}");

        // List patterns: the beginning, the end and "everything else".
        int[] numbers = [1, 2, 3, 4, 5];
        if (numbers is [var head, .. var middle, var tail])
        {
            Console.WriteLine($"head {head}, middle [{Join(middle)}], tail {tail}");
        }

        // -(x + 2) * 3 and an expression that simplifies completely.
        Expr formula = new Mul(new Neg(new Add(new Var("x"), new Num(2))), new Num(3));
        Expr noisy = new Add(new Mul(new Num(1), new Var("x")), new Mul(new Var("y"), new Num(0)));
        var variables = new Dictionary<string, double> { ["x"] = 5 };
        Console.WriteLine($"{Show(formula)} = {Eval(formula, variables)} | " +
                          $"{Show(noisy)} simplifies to {Show(Simplify(noisy))}");
    }
}

// =====================================================================================
//  6. GENERICS
// =====================================================================================
//
//  A C++ template is a recipe: new code is generated for every set of arguments, and the
//  body is checked at instantiation. A C# generic is compiled ONCE, and inside it only what
//  the `where` constraints allow can be done with T. The consequences:
//    + errors appear at the declaration and are short; generic types are visible to reflection;
//    + for value types the JIT still produces separate machine code (no boxing), for
//      reference types one shared version;
//    - no specializations, no value parameters (only types) and no computations over types.

// A generic class that implements the standard enumeration interface.
class ArrayStack<T> : IEnumerable<T>
{
    private T[] _items = new T[4];
    private int _count;

    public int Count => _count;

    public void Push(T item)
    {
        if (_count == _items.Length) Array.Resize(ref _items, _count * 2); // passing by ref
        _items[_count++] = item;
    }

    // throw is an expression: it can be an arm of the ternary operator.
    public T Pop() => _count > 0 ? _items[--_count] : throw new InvalidOperationException("stack is empty");

    // An attribute for the null analyser: "if the method returned false, item may be null".
    public bool TryPop([MaybeNullWhen(false)] out T item)
    {
        if (_count == 0)
        {
            item = default; // default(T): null for reference types, zeros for value types
            return false;
        }
        item = _items[--_count];
        return true;
    }

    // GetEnumerator() is all a type needs to work in foreach and LINQ. A method with
    // `yield return` is an iterator (section 8): the compiler builds the state machine by itself.
    public IEnumerator<T> GetEnumerator()
    {
        for (int i = _count - 1; i >= 0; i--) yield return _items[i];
    }

    IEnumerator IEnumerable.GetEnumerator() => GetEnumerator(); // the non-generic version of the interface
}

// Variance. `out` is covariance: an IProducer<Circle> fits where an IProducer<Shape> is
// expected. `in` is contravariance: an IConsumer<Shape> fits as an IConsumer<Circle>.
// C++ templates are invariant: vector<Circle*> does not convert to vector<Shape*>.
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

// Static abstract interface members (C# 11): a contract for the "static part" of a type.
// The TSelf parameter is the same trick as CRTP in C++.
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

// A static generic class: every T gets its own set of static fields.
// This is how a "per-type cache" is made — the closest substitute for template specialization.
static class TypeDescription<T>
{
    public static readonly string Description =
        $"{typeof(T).Name} ({(typeof(T).IsValueType ? "value" : "reference")} type)";
}

static class Section06_Generics
{
    // An interface constraint. C++: template <std::totally_ordered T>.
    static T MaxOf<T>(T a, T b) where T : IComparable<T> => a.CompareTo(b) >= 0 ? a : b;

    // new(): "T has a parameterless constructor"; class: "T is a reference type".
    static T CreateDefault<T>() where T : class, new() => new T();

    // unmanaged: a "flat" type without references (C++: trivially copyable); sizeof works for it.
    static unsafe int SizeOf<T>() where T : unmanaged => sizeof(T);

    // Generic math (C# 11): INumber<T> requires operators and constants from T.
    // C++: a template with a concept. Works for int, double, decimal, BigInteger, ...
    static T Sum<T>(IEnumerable<T> values) where T : INumber<T>
    {
        T total = T.Zero; // a static member called through the type parameter
        foreach (T value in values) total += value;
        return total;
    }

    static T Average<T>(params ReadOnlySpan<T> values) where T : INumber<T> =>
        Sum(values.ToArray()) / T.CreateChecked(values.Length);

    // Unit conversion through static abstract members.
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
        // stack implements IEnumerable<T>, so foreach, LINQ and string.Join all work.
        Console.WriteLine($"popped {top}, left [{Join(stack)}], longest: {stack.MaxBy(w => w.Length)}");
        var numbers = new ArrayStack<int>();
        Console.WriteLine($"TryPop on empty: {numbers.TryPop(out int missing)} (item = {missing})");

        // Type arguments are usually inferred from the call arguments.
        Console.WriteLine($"{MaxOf(3, 7)} {MaxOf("apple", "pear")} {MaxOf(2.5, 1.5)} | " +
                          $"{CreateDefault<StringBuilder>().Append("created").Length} | " +
                          $"sizeof: {SizeOf<int>()} {SizeOf<Vec2>()} {SizeOf<Guid>()}");
        // MaxOf(new object(), new object()); // CS0311: object does not implement IComparable<object>

        // Generic math: one method for any numeric type.
        BigInteger[] huge = [1, BigInteger.Pow(2, 100)];
        Console.WriteLine($"{Sum(new[] { 1, 2, 3 })} {Sum(new[] { 0.5, 1.5 })} {Sum(new[] { 0.1m, 0.2m })} | " +
                          $"{Average(1.0, 2.0, 6.0)} {Average(10, 20)} | {Sum(huge)}");

        // Static abstract members.
        var distance = new Kilometers(1.5);
        Meters inMeters = ConvertUnit<Kilometers, Meters>(distance);
        Console.WriteLine($"{Format(distance)} = {Format(inMeters)} | record text: {inMeters}");

        // Variance.
        IProducer<Shape> producer = new CircleFactory();    // covariance: Circle -> Shape
        IConsumer<Circle> consumer = new ShapePrinter();    // contravariance: Shape <- Circle
        consumer.Consume(new CircleFactory().Produce());
        IEnumerable<Shape> shapes = new List<Circle> { new(1), new(2) }; // IEnumerable<out T>
        Console.WriteLine($"produced {producer.Produce().Name}, {shapes.Count()} circles seen as shapes");

        // Generic types exist at run time: they can be inspected and constructed.
        Type open = typeof(Dictionary<,>); // an "open" type: the arguments are not given yet
        Type constructed = open.MakeGenericType(typeof(string), typeof(int));
        Console.WriteLine($"{open.Name} -> [{Join(constructed.GetGenericArguments().Select(t => t.Name))}] | " +
                          $"{TypeDescription<int>.Description} | {TypeDescription<string>.Description}");
    }
}

// =====================================================================================
//  7. DELEGATES, LAMBDAS, EVENTS
// =====================================================================================

// A delegate is a "reference to a method" type: it holds a code pointer and, if needed, an object.
// C++: std::function<double(double, double)>.
delegate double BinaryOperation(double a, double b);

class Thermostat
{
    private double _temperature;

    // An event is a list of subscribers. Outside the class only += and -= are possible; only
    // the class itself can raise it. C++: hand-written signals and slots.
    public event Action<double, double>? TemperatureChanged; // (old value, new value)
    public event EventHandler<string>? Alarm;                // the standard shape: (sender, args)

    public double Temperature
    {
        get => _temperature;
        set
        {
            if (value == _temperature) return;
            double old = _temperature;
            _temperature = value;
            TemperatureChanged?.Invoke(old, value); // `?.` invokes only if there are subscribers
            if (value > 30) Alarm?.Invoke(this, $"overheating: {value}");
        }
    }
}

static class Section07_Delegates
{
    static double Power(double a, double b) => Math.Pow(a, b);

    // A higher-order function. Func<T, TResult> and Action<T> are ready-made generic delegates.
    static int ApplyTwice(Func<int, int> f, int x) => f(f(x));

    // Returning a function from a function.
    static Func<int, int> MakeAdder(int n) => x => x + n;

    public static void Run()
    {
        Header(7, "Delegates, lambdas, events");

        // --- Delegates --------------------------------------------------------------------
        BinaryOperation multiply = (a, b) => a * b; // from a lambda
        BinaryOperation power = Power;              // from a method name (a "method group")
        Console.WriteLine($"{multiply(6, 7)} {power(2, 10)} {ApplyTwice(x => x * 3, 2)} {MakeAdder(10)(5)}");

        // A delegate can hold SEVERAL methods: += adds one, an invocation runs them all in order.
        Action<string> log = message => Console.Write($"[A: {message}] ");
        log += message => Console.Write($"[B: {message.ToUpperInvariant()}] ");
        log("multicast");
        Console.WriteLine($"<- {log.GetInvocationList().Length} targets");

        // --- Lambdas ----------------------------------------------------------------------
        var square = (int x) => x * x;                    // the lambda's type is inferred: Func<int, int>
        var increment = (int x, int step = 1) => x + step; // default parameters (C# 12)
        Func<int, int, int> gcd = static (a, b) =>         // static: capturing is forbidden
        {
            while (b != 0) (a, b) = (b, a % b);
            return a;
        };
        Console.WriteLine($"{square(9)} {increment(5)} {increment(5, 10)} {gcd(84, 36)}");

        // A closure captures the VARIABLE itself — by reference, extending its lifetime
        // (in C++ that is [&], but with no risk of a dangling reference: the variable moves to the heap).
        int counter = 0;
        Action bump = () => counter++;
        bump();
        bump();
        Console.WriteLine($"counter changed through the closure: {counter}");

        // The classic trap: a for loop has one variable for all iterations...
        var actions = new List<Func<int>>();
        for (int i = 0; i < 3; i++) actions.Add(() => i);
        string fromFor = Join(actions.Select(action => action()));
        // ...while foreach has a fresh one on every iteration.
        actions.Clear();
        foreach (int i in Enumerable.Range(0, 3)) actions.Add(() => i);
        string fromForeach = Join(actions.Select(action => action()));
        Console.WriteLine($"captured in for: {fromFor} | captured in foreach: {fromForeach}");

        // A local function: it sees local variables, can be recursive and may be declared after
        // its use. Unlike a C# lambda, it does not require creating a delegate.
        // C++: a lambda stored in a local variable.
        Console.WriteLine($"factorial(10) = {Factorial(10)}");

        long Factorial(int n) => n <= 1 ? 1 : n * Factorial(n - 1);

        // --- Events -----------------------------------------------------------------------
        var thermostat = new Thermostat();
        var history = new List<string>();
        void OnChanged(double from, double to) => history.Add($"{from} -> {to}");

        thermostat.TemperatureChanged += OnChanged;                  // subscribe
        thermostat.Alarm += (_, message) => history.Add($"ALARM {message}");
        thermostat.Temperature = 21;
        thermostat.Temperature = 35;
        thermostat.TemperatureChanged -= OnChanged;                  // unsubscribe
        thermostat.Temperature = 18;                                 // nobody hears this change any more
        Console.WriteLine(Join(history, " | "));
        // A subscription keeps the subscriber alive until it is removed: a forgotten subscription
        // is the most common cause of memory "leaks" in .NET.
    }
}

// =====================================================================================
//  8. COLLECTIONS, ITERATORS, LINQ
// =====================================================================================

record Person(string Name, int Age, string City);

// Extension methods: static methods that are called like instance methods.
// All of LINQ is built on them. C++: a free function (there is no uniform call syntax there).
static class SequenceExtensions
{
    // The classic form (C# 3): `this` before the first parameter.
    // It is an iterator as well: a method with `yield return` runs lazily, one step per element.
    public static IEnumerable<(T Previous, T Current)> Pairwise<T>(this IEnumerable<T> source)
    {
        using IEnumerator<T> enumerator = source.GetEnumerator();
        if (!enumerator.MoveNext()) yield break; // yield break ends the sequence
        T previous = enumerator.Current;
        while (enumerator.MoveNext())
        {
            yield return (previous, enumerator.Current);
            previous = enumerator.Current;
        }
    }

    // An extension block (C# 14): properties and static members can be added too.
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
    // An iterator: the compiler turns the method into a state machine that advances one step
    // per request for the next element. C++: a generator coroutine (C++23).
    static IEnumerable<ulong> Fibonacci()
    {
        ulong current = 0, next = 1;
        while (true)
        {
            yield return current;
            if (next > ulong.MaxValue - current) // the next sum would not fit into a ulong
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
        list.RemoveAt(1); // remove by index
        list.Sort();
        list.RemoveAll(x => x > 8); // C++: std::erase_if
        Console.WriteLine($"[{Join(list)}] count {list.Count}, index of 3: {list.IndexOf(3)}, " +
                          $"contains 8: {list.Contains(8)}, last: {list[^1]}");

        // --- Dictionary<TKey, TValue>. C++: std::unordered_map ----------------------------
        var stock = new Dictionary<string, int> { ["bolt"] = 10, ["nut"] = 0 };
        stock["screw"] = 25;       // the indexer inserts or replaces
        stock.TryAdd("bolt", 999); // while TryAdd leaves an existing key alone
        stock["bolt"] -= 3;
        // Reading a missing key through the indexer throws KeyNotFoundException
        // (in C++ operator[] would silently insert an element). The safe way is TryGetValue.
        bool hasWasher = stock.TryGetValue("washer", out int washers);
        stock.Remove("nut", out int removedNuts);
        // A reference to the value INSIDE the dictionary: "find or insert" with a single hash lookup.
        ref int gaskets = ref CollectionsMarshal.GetValueRefOrAddDefault(stock, "gasket", out _);
        gaskets += 4;
        Console.Write($"washer found: {hasWasher} ({washers}), removed nuts: {removedNuts} |");
        foreach ((string item, int quantity) in stock.OrderBy(pair => pair.Key)) // deconstructing the pair
        {
            Console.Write($" {item}={quantity}");
        }
        Console.WriteLine();

        // Counting frequencies.
        string text = "the quick brown fox jumps over the lazy dog the end";
        var frequency = new Dictionary<string, int>();
        foreach (string word in text.Split(' ')) frequency[word] = frequency.GetValueOrDefault(word) + 1;
        var top = frequency.OrderByDescending(pair => pair.Value).ThenBy(pair => pair.Key).Take(3);
        string phrase = "Was it a car or a cat I saw";
        Console.WriteLine($"top words: {Join(top.Select(pair => $"{pair.Key}:{pair.Value}"))} | " +
                          $"extension members: {text.WordCount} words, palindrome: {phrase.IsPalindrome()}");

        // --- The other standard collections -----------------------------------------------
        var sorted = new SortedDictionary<string, int>(stock); // a tree. C++: std::map
        HashSet<int> set = [1, 2, 3, 4];                       // C++: std::unordered_set
        set.IntersectWith([3, 4, 5, 6]);
        var queue = new Queue<string>(["first", "second"]);    // C++: std::queue
        queue.Enqueue("third");
        var stack = new Stack<int>([1, 2, 3]);                 // C++: std::stack
        var heap = new PriorityQueue<string, int>();           // a heap with the MINIMUM on top
        heap.Enqueue("routine", 5);
        heap.Enqueue("urgent", 1);
        Console.WriteLine($"sorted keys: {Join(sorted.Keys)} | set [{Join(set.Order())}] | " +
                          $"dequeued {queue.Dequeue()} | popped {stack.Pop()} | heap gives {heap.Dequeue()}");

        // Immutable collections: a "change" returns a new collection, the original stays as it was.
        ImmutableList<int> original = [1, 2, 3];
        ImmutableList<int> extended = original.Add(4);
        // "Frozen" ones: expensive to build but the fastest to look up. For reference data.
        FrozenDictionary<string, int> frozen = stock.ToFrozenDictionary();
        int[] merged = [.. list, 100, .. set]; // `..` in a collection expression concatenates collections
        Console.WriteLine($"immutable: {original.Count} -> {extended.Count} | frozen bolt: {frozen["bolt"]} | " +
                          $"merged [{Join(merged)}]");

        // --- Iterators --------------------------------------------------------------------
        // The laziness is visible: elements are produced on demand, and Take(2) cuts the
        // generation short.
        foreach (int value in Traced(5).Take(2)) Console.Write($"got {value}; ");
        Console.WriteLine();
        Console.WriteLine($"fibonacci: {Join(Fibonacci().TakeWhile(x => x < 100))} | " +
                          $"terms that fit in ulong: {Fibonacci().Count()} | " +
                          $"pairwise: {Join(new[] { 1, 4, 9, 16 }.Pairwise().Select(p => p.Current - p.Previous))}");

        // --- LINQ: queries over any sequence. C++: ranges and views -----------------------
        // A chain of extension methods over IEnumerable<T>. A query is lazy: it is a description
        // of a computation that runs when it is enumerated.
        int[] numbers = [.. Enumerable.Range(1, 10)];
        IEnumerable<int> evenSquares = numbers.Where(n => n % 2 == 0).Select(n => n * n);
        Console.WriteLine($"[{Join(evenSquares)}] sum {numbers.Sum()}, average {numbers.Average()}, " +
                          $"any > 9: {numbers.Any(n => n > 9)}, all > 0: {numbers.All(n => n > 0)}, " +
                          $"first > 4: {numbers.First(n => n > 4)}, " +
                          $"first > 100 or default: {numbers.FirstOrDefault(n => n > 100)}");
        // Aggregate is a fold (C++: std::accumulate / fold_left), SelectMany is flattening.
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
        // Sorting by several keys, grouping, dictionaries.
        var byAge = people.OrderByDescending(p => p.Age).ThenBy(p => p.Name).Select(p => p.Name);
        var byCity = people.GroupBy(p => p.City).OrderBy(group => group.Key)
            .Select(group => $"{group.Key}: {Join(group.Select(p => p.Name), "+")} ({group.Average(p => p.Age):F1})");
        Dictionary<string, int> ageByName = people.ToDictionary(p => p.Name, p => p.Age);
        Console.WriteLine($"{Join(byAge)} | {Join(byCity, "; ")} | oldest: {people.MaxBy(p => p.Age)?.Name} | " +
                          $"Cid is {ageByName["Cid"]} | by decade: {Join(people.CountBy(p => p.Age / 10 * 10))}");

        // Query syntax is sugar over the same methods. `new { ... }` is an anonymous type:
        // an "ad-hoc struct" with read-only properties.
        var seniors =
            from person in people
            where person.Age >= 30
            orderby person.Age descending
            select new { person.Name, Decade = person.Age / 10 * 10 };
        Console.WriteLine(Join(seniors));

        // Deferred execution: the query re-reads the source on EVERY enumeration.
        IEnumerable<int> big = list.Where(x => x > 2);
        list.Add(50);
        Console.WriteLine($"the query sees the element added later: [{Join(big)}]; materialise with ToList/ToArray");
    }
}

// =====================================================================================
//  9. ERRORS, RESOURCES, GC, NULL SAFETY
// =====================================================================================

// A custom exception type. Only objects derived from System.Exception can be thrown
// (in C++ — anything, even an int). There are no specifications like noexcept.
class ConfigException(string key, string message, Exception? inner = null)
    : Exception($"config key '{key}': {message}", inner)
{
    public string Key { get; } = key;
}

// IDisposable is the contract "the object owns a resource that must be released on time":
// a file, a socket, a lock, native memory. The memory of the object itself is freed by
// the GC — some day; Dispose is called deterministically. This is the replacement for RAII.
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
        ObjectDisposedException.ThrowIf(_disposed, this); // the object is alive but the resource is gone
        Console.WriteLine($"    use {_name}");
    }

    public void Dispose()
    {
        if (_disposed) return; // a repeated Dispose call must be harmless
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
            port = int.Parse(text); // throws FormatException or OverflowException
        }
        catch (FormatException e)
        {
            // Wrap the error, keeping the cause in InnerException. C++: std::throw_with_nested.
            throw new ConfigException("port", $"'{text}' is not a number", e);
        }
        if (port is < 1 or > 65535)
        {
            throw new ArgumentOutOfRangeException(nameof(config), $"port {port} is out of range");
        }
        return port;
    }

    // The Try idiom: where failure is routine, a bool is returned instead of throwing.
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

    // NoInlining guarantees that the temporary object does not stay rooted in the caller's frame.
    [MethodImpl(MethodImplOptions.NoInlining)]
    static WeakReference<object> CreateShortLived() => new(new object());

    public static void Run()
    {
        Header(9, "Errors, resources, GC, null safety");

        // --- Exceptions -------------------------------------------------------------------
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
            // An exception filter: the when condition is evaluated BEFORE the stack is unwound.
            catch (ConfigException e) when (e.InnerException is not null)
            {
                Console.WriteLine($"{e.Message}; caused by {e.InnerException.GetType().Name}");
            }
            catch (ConfigException e) // from specific to general
            {
                Console.WriteLine($"{e.Message} [Key = {e.Key}]");
            }
            catch (Exception e) // the common ancestor of all exceptions
            {
                Console.WriteLine($"{e.GetType().Name}: {e.Message} (TryReadPort: {TryReadPort(config, out _)})");
            }
        }

        // finally runs on any exit from try. C++ does not have it: destructors do the job there.
        try
        {
            Console.WriteLine("    try");
            throw new InvalidOperationException("boom");
        }
        catch (InvalidOperationException e)
        {
            Console.WriteLine($"    catch: {e.Message}"); // `throw;` here would rethrow the exception
        }
        finally
        {
            Console.WriteLine("    finally");
        }

        // --- using: deterministic release of resources ------------------------------------
        using (var outer = new TracedResource("outer")) // the block form: Dispose at the end of the block
        {
            using var inner = new TracedResource("inner"); // a using declaration: Dispose at the end of the scope
            outer.Use();
            inner.Use();
        } // release inner, then release outer — in reverse order, like C++ destructors

        // Unlike RAII: after Dispose the object is still there and can be accessed.
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

        // --- The garbage collector --------------------------------------------------------
        // The GC is generational: new objects (generation 0) are collected often and cheaply,
        // survivors are promoted to generations 1 and 2. During a collection objects are MOVED
        // (memory is compacted), so the address of a managed object is not stable — see fixed in
        // section 11.
        WeakReference<object> weak = CreateShortLived(); // a weak reference. C++: std::weak_ptr
        var survivor = new object();
        int generationBefore = GC.GetGeneration(survivor);
        GC.Collect(); // a forced collection — for demos and tests only
        GC.WaitForPendingFinalizers();
        Console.WriteLine($"weak target alive after GC: {weak.TryGetTarget(out _)} | " +
                          $"survivor moved from generation {generationBefore} to {GC.GetGeneration(survivor)}");
        // A finalizer (`~TypeName()`) is NOT a C++ destructor: the GC calls it some day on a
        // special thread, and may never call it at all. It is a safety net for native resources
        // (section 11).

        // --- Null safety (C# 8) -----------------------------------------------------------
        // `string` means "never null here", `string?` means "may be null". These are hints for
        // the static analyser (it issues warnings), not different types.
        string? nickname = FindNickname("Alice");
        // Console.WriteLine(nickname.Length); // warning CS8602: possible dereference of null
        Console.WriteLine($"{nickname?.Length ?? -1} | {nickname ?? "(none)"} | " +
                          $"{FindNickname("Robert")?.ToUpperInvariant()}"); // ?. means "call if not null"
        nickname ??= "n/a";
        Console.WriteLine($"after `??=` the compiler knows it is not null: {nickname.Length}");
    }
}

// =====================================================================================
//  10. MEMORY AND SPEED: Span, ref, layout, SIMD
// =====================================================================================
//
//  "Managed" does not mean "slow": C# has the means to write allocation-free code with full
//  control over memory while staying in the safe subset of the language.

// A ref struct is a type whose instances live ONLY on the stack. It cannot be stored in a
// class field, in an array or in a lambda, nor carried across an await. This is how the
// compiler guarantees that a "window" does not outlive the memory it looks at (in C++ that
// is the programmer's job).
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

// Controlling the memory layout of a struct.
[StructLayout(LayoutKind.Explicit)] // all fields at offset 0 — the union of C and C++
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

struct NaturalHeader // the default layout: declaration order, with alignment
{
    public byte Tag;
    public int Length;
    public short Flags;
}

// A fixed-length array INSIDE a struct (C# 12). C++: float data[4].
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

    // A ref return: the method hands out a REFERENCE to the element, not a copy. C++: T& find(...).
    static ref int FirstNegative(Span<int> values)
    {
        for (int i = 0; i < values.Length; i++)
        {
            if (values[i] < 0) return ref values[i];
        }
        throw new InvalidOperationException("no negative values");
    }

    // SIMD. Vector<T> is a vector "as wide as the register" (portable code); there are also
    // Vector128/256/512<T> and direct instructions in System.Runtime.Intrinsics (C++: <immintrin.h>).
    // AggressiveInlining is a strong request to the JIT to inline the method (C++: [[gnu::always_inline]]).
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
        for (; i < values.Length; i++) sum += values[i]; // the "tail" that is not a multiple of the vector width
        return sum;
    }

    public static void Run()
    {
        Header(10, "Memory and performance: Span, ref, layout, SIMD");

        // --- Span<T>: a window into contiguous memory. C++: std::span<T> --------------------
        int[] array = [1, 2, 3, 4, 5, 6];
        Span<int> window = array.AsSpan(1, 4); // elements 2, 3, 4, 5 — no copying
        window[0] = 20;                        // the write goes straight into the array
        window[2..].Fill(0);                   // a slice of a span is a span too, not a copy
        Console.WriteLine($"array after edits through the span: [{Join(array)}]");

        // stackalloc: memory on the stack, bypassing the GC. C++: a local array or alloca.
        Span<byte> buffer = stackalloc byte[8];
        for (int i = 0; i < buffer.Length; i++) buffer[i] = (byte)(i * 3);
        Console.WriteLine($"stackalloc: {Convert.ToHexString(buffer)}, sum {Sum(buffer)}");

        // ReadOnlySpan<char>: parsing text without a single allocation. C++: std::string_view.
        ReadOnlySpan<char> line = "width=42;height=7;depth=13";
        int total = 0;
        foreach (Range part in line.Split(';')) // RANGES are enumerated: no strings are created
        {
            ReadOnlySpan<char> pair = line[part];
            total += int.Parse(pair[(pair.IndexOf('=') + 1)..]); // int.Parse reads straight from the span
        }
        var reader = new WordReader("  spans   avoid  allocations ");
        int words = 0, letters = 0;
        while (reader.TryRead(out ReadOnlySpan<char> word))
        {
            words++;
            letters += word.Length;
        }
        Console.WriteLine($"parsed total {total} | {words} words, {letters} letters");

        // --- ref locals and ref returns ---------------------------------------------------
        int[] data = [3, -1, 4, -5];
        ref int negative = ref FirstNegative(data); // an alias of an array element. C++: int&
        negative = 0;
        Console.WriteLine($"[{Join(data)}] after writing through the returned reference");
        // More of the same family: `in` parameters (const T&), `readonly struct` (all methods const),
        // `ref readonly` (const T& as a result), `scoped` (the reference will not leave the method).

        // --- Memory layout ----------------------------------------------------------------
        var bits = new FloatBits { Value = 1.0f };
        var packed = new PackedHeader { Tag = 1, Length = 2, Flags = 3 };
        var natural = new NaturalHeader { Tag = packed.Tag, Length = packed.Length, Flags = packed.Flags };
        uint viaConverter = BitConverter.SingleToUInt32Bits(1.0f); // C++: std::bit_cast
        Console.WriteLine($"1.0f = 0x{bits.Bits:X8} via the union, 0x{viaConverter:X8} via BitConverter | " +
                          $"header sizes: packed {Unsafe.SizeOf<PackedHeader>()}, " +
                          $"natural {Unsafe.SizeOf<NaturalHeader>()} " +
                          $"(tag {natural.Tag}, length {natural.Length}, flags {natural.Flags})");

        Float4 quad = new();
        quad[3] = 4f;                  // an inline array is indexed directly...
        Span<float> components = quad; // ...and converts to a Span without copying
        components[0] = 1f;
        Console.WriteLine($"inline array: [{Join(components.ToArray())}], " +
                          $"{Unsafe.SizeOf<Float4>()} bytes inside the struct");

        // MemoryMarshal is "reinterpret_cast for spans": the same bytes, another element type.
        Span<float> floats = [1.0f, 2.0f];
        Span<uint> asUInts = MemoryMarshal.Cast<float, uint>(floats);
        Span<byte> asBytes = MemoryMarshal.AsBytes(floats);
        // BinaryPrimitives: reading and writing with an explicit byte order.
        BinaryPrimitives.WriteInt32BigEndian(buffer, 0x11223344);
        int littleEndian = BinaryPrimitives.ReadInt32LittleEndian(buffer);
        Console.WriteLine($"2.0f = 0x{asUInts[1]:X8}, {asBytes.Length} bytes | " +
                          $"big-endian bytes {Convert.ToHexString(buffer[..4])} " +
                          $"read as little-endian: 0x{littleEndian:X8}");
        // BitOperations is the counterpart of the <bit> header.
        const uint Mask = 0b1011_0000; // a binary literal
        Console.WriteLine($"popcount {BitOperations.PopCount(Mask)}, " +
                          $"trailing zeros {BitOperations.TrailingZeroCount(Mask)}, " +
                          $"rotl 0x{BitOperations.RotateLeft(Mask, 28):X}, " +
                          $"next power of two {BitOperations.RoundUpToPowerOf2(100u)}");

        // --- ArrayPool: reusing buffers to take load off the GC ---------------------------
        byte[] rented = ArrayPool<byte>.Shared.Rent(1000); // returns an array AT LEAST as large as requested
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
//  11. UNSAFE CODE AND NATIVE INTEROP
// =====================================================================================
//
//  C# does have pointers, but only inside `unsafe` and only with the project's permission
//  (AllowUnsafeBlocks). Bounds and type checks do not apply there: it is plain C with all
//  its power and all its consequences. unsafe is rarely needed — for interop with native
//  code and for extreme optimization; Span<T> and ref cover the rest (section 10).

// A struct for exchange with native code: only "flat" fields, laid out as in C.
[StructLayout(LayoutKind.Sequential)]
struct Rgba
{
    public byte R, G, B, A;
}

// Calling native functions (P/Invoke). In C++ an #include and linking are enough; here the
// signature is declared in C#, and the runtime finds the library and the function by name.
// The example uses the C standard library: it exists everywhere, only under different names.
static unsafe partial class Native
{
    private const string UnixLibC = "libc";
    private const string WindowsCrt = "msvcrt";

    // The classic way: [DllImport] + extern. Argument conversion (marshalling) is done by the
    // runtime while the program is running.
    [DllImport(UnixLibC, EntryPoint = "abs")]
    private static extern int AbsUnix(int value);

    [DllImport(WindowsCrt, EntryPoint = "abs", CallingConvention = CallingConvention.Cdecl)]
    private static extern int AbsWindows(int value);

    public static int Abs(int value) => OperatingSystem.IsWindows() ? AbsWindows(value) : AbsUnix(value);

    // The modern way (.NET 7): [LibraryImport]. The marshalling code is produced by a source
    // generator AT COMPILE TIME — it writes the body of the partial method.
    [LibraryImport(UnixLibC, EntryPoint = "strlen", StringMarshalling = StringMarshalling.Utf8)]
    private static partial nuint StrLenUnix(string text);

    [LibraryImport(WindowsCrt, EntryPoint = "strlen", StringMarshalling = StringMarshalling.Utf8)]
    [UnmanagedCallConv(CallConvs = [typeof(CallConvCdecl)])]
    private static partial nuint StrLenWindows(string text);

    public static nuint StrLen(string text) =>
        OperatingSystem.IsWindows() ? StrLenWindows(text) : StrLenUnix(text);

    // A callback from native code: the parameter is a pointer to a function with the C calling convention.
    [DllImport(UnixLibC, EntryPoint = "qsort")]
    private static extern void QSortUnix(
        void* data, nuint count, nuint size, delegate* unmanaged[Cdecl]<void*, void*, int> compare);

    [DllImport(WindowsCrt, EntryPoint = "qsort", CallingConvention = CallingConvention.Cdecl)]
    private static extern void QSortWindows(
        void* data, nuint count, nuint size, delegate* unmanaged[Cdecl]<void*, void*, int> compare);

    public static void QSort(Span<int> values)
    {
        fixed (int* data = values) // pin the memory for the duration of the native call
        {
            nuint count = (nuint)values.Length;
            if (OperatingSystem.IsWindows()) QSortWindows(data, count, sizeof(int), &CompareInts);
            else QSortUnix(data, count, sizeof(int), &CompareInts);
        }
    }

    // A method that is called ONLY by native code. C++: a function with extern "C".
    [UnmanagedCallersOnly(CallConvs = [typeof(CallConvCdecl)])]
    private static int CompareInts(void* a, void* b) => (*(int*)a).CompareTo(*(int*)b);
}

// Native memory and the full "Dispose pattern".
sealed unsafe class NativeBuffer : IDisposable
{
    private byte* _memory;

    public int Length { get; }

    public NativeBuffer(int length)
    {
        _memory = (byte*)NativeMemory.AllocZeroed((nuint)length); // C: calloc
        Length = length;
    }

    // A safe Span is exposed to the outside, not a pointer.
    public Span<byte> Bytes =>
        _memory != null ? new Span<byte>(_memory, Length) : throw new ObjectDisposedException(nameof(NativeBuffer));

    public void Dispose()
    {
        Free();
        GC.SuppressFinalize(this); // the resource was released manually — the finalizer is no longer needed
    }

    // The finalizer: a safety net in case Dispose was forgotten. The GC calls it some day.
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

        // --- Pointers ---------------------------------------------------------------------
        int value = 10;
        int* pointer = &value; // a local variable lives on the stack and will not move
        *pointer += 1;
        Console.WriteLine($"value through the pointer: {*pointer}, pointer size {sizeof(int*)}");

        // The GC is free to MOVE managed objects. The fixed statement pins an object for the
        // duration of the block so that a pointer to it stays valid.
        int[] array = [10, 20, 30, 40];
        fixed (int* first = array)
        {
            int third = *(first + 2); // pointer arithmetic — as in C
            first[3] = 400;           // indexing a pointer; bounds are NOT checked
            Console.WriteLine($"third {third}, array[3] is now {array[3]}");
        }

        // A pointer to a struct and the -> operator.
        Rgba color = new() { R = 0x11, G = 0x22, B = 0x33, A = 0xFF };
        Rgba* colorPointer = &color;
        colorPointer->G = 0x99;
        uint packed = *(uint*)colorPointer; // reinterpreting bytes. C++: reinterpret_cast
        Console.WriteLine($"G = 0x{color.G:X2}, packed 0x{packed:X8}, sizeof(Rgba) = {sizeof(Rgba)}");

        // stackalloc whose result is a pointer.
        byte* scratch = stackalloc byte[4];
        for (int i = 0; i < 4; i++) scratch[i] = (byte)('a' + i);
        Console.WriteLine($"stackalloc bytes as text: {Encoding.ASCII.GetString(scratch, 4)}");

        // A function pointer (C# 9): a call with no delegate and no allocations. C++: int (*)(int, int).
        delegate*<int, int, int> add = &Add;
        Console.WriteLine($"function pointer: {add(2, 3)}");

        // --- Native memory ----------------------------------------------------------------
        using (var native = new NativeBuffer(16))
        {
            native.Bytes.Fill(0xAB);
            native.Bytes[0] = 1;
            Console.WriteLine($"native buffer: {Convert.ToHexString(native.Bytes[..4])}..., " +
                              $"{native.Length} bytes outside the GC heap");
        } // Dispose freed the memory immediately, without waiting for the GC

        // --- P/Invoke ---------------------------------------------------------------------
        int[] unsorted = [42, -7, 19, 0, 3];
        Native.QSort(unsorted);
        Console.WriteLine($"abs(-7) = {Native.Abs(-7)}, strlen = {Native.StrLen("hello from C")}, " +
                          $"qsort: [{Join(unsorted)}]");
        // For OS handles (files, sockets, windows) there is a ready-made wrapper, SafeHandle:
        // a finalizer, usage counting and protection against double release.
    }
}

// =====================================================================================
//  12. THREADS AND SYNCHRONIZATION
// =====================================================================================

static class Section12_Threads
{
    public static void Run()
    {
        Header(12, "Threads and synchronisation");

        // --- An OS thread. C++: std::thread -----------------------------------------------
        long sum = 0;
        var thread = new Thread(() =>
        {
            for (int i = 1; i <= 1000; i++) sum += i; // the lambda captured the variable sum
        });
        thread.Start();
        thread.Join();
        Console.WriteLine($"sum computed in another thread: {sum}");
        // Threads are rarely created by hand: work is handed to the THREAD POOL — through
        // Task.Run, Parallel and async/await (section 13).

        // --- lock, Interlocked, thread-local data -----------------------------------------
        // A data race in C# is not UB: memory stays intact, but the result will be wrong.
        // lock is a mutex that is released automatically (C++: std::scoped_lock).
        // The dedicated Lock type arrived in C# 13; before it an arbitrary object was locked.
        Lock gate = new();
        long guarded = 0, atomic = 0;
        using var perThread = new ThreadLocal<int>(() => 0, trackAllValues: true); // C++: thread_local
        Parallel.For(0, 4, _ => // a parallel loop on the thread pool
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

        // --- Thread-safe collections (standard C++ has none) ------------------------------
        var hits = new ConcurrentDictionary<string, int>();
        Parallel.ForEach(new[] { "a", "b", "a", "c", "a", "b" },
            key => hits.AddOrUpdate(key, 1, (_, count) => count + 1));
        var counted = hits.OrderBy(pair => pair.Key).Select(pair => $"{pair.Key}={pair.Value}");
        Console.WriteLine($"concurrent dictionary: {Join(counted)}");

        // A blocking producer-consumer queue. C++: mutex + condition_variable.
        using var queue = new BlockingCollection<int>(boundedCapacity: 2);
        Task<int> consumer = Task.Run(() => queue.GetConsumingEnumerable().Sum());
        for (int i = 1; i <= 5; i++) queue.Add(i); // waits until the queue has room
        queue.CompleteAdding();
        Console.WriteLine($"consumer received a total of {consumer.Result}"); // Result blocks until the task is done

        // --- PLINQ: parallel LINQ with a single call. C++: std::execution::par ------------
        long evenSquares = Enumerable.Range(1, 1_000_000).AsParallel()
            .Where(n => n % 2 == 0)
            .Sum(n => (long)n * n);
        Console.WriteLine($"PLINQ sum of even squares: {evenSquares}");

        // --- Lazy initialization and signals ----------------------------------------------
        // Lazy<T>: thread-safe, exactly once. C++: a static local variable.
        var primes = new Lazy<int[]>(() =>
            [.. Enumerable.Range(2, 48).Where(n => Enumerable.Range(2, n - 2).All(d => n % d != 0))]);
        Console.WriteLine($"created: {primes.IsValueCreated}, primes below 50: {primes.Value.Length}, " +
                          $"created: {primes.IsValueCreated}");

        using var allDone = new CountdownEvent(3); // C++: std::latch
        for (int i = 0; i < 3; i++) ThreadPool.QueueUserWorkItem(_ => allDone.Signal());
        allDone.Wait();
        Console.WriteLine("countdown event released after 3 pool tasks");
        // There are also SemaphoreSlim, ReaderWriterLockSlim (std::shared_mutex), Barrier,
        // ManualResetEventSlim, Monitor.Wait/Pulse (a condition variable) and the volatile keyword.
    }
}

// =====================================================================================
//  13. ASYNC/AWAIT
// =====================================================================================
//
//  The compiler turns an async method into a state machine. At every await the method may
//  "fall asleep", returning control to its caller, and continue later — possibly on another
//  pool thread. C++: coroutines with co_await. The differences:
//    - everything needed (Task, a scheduler, the thread pool, timers) is already in the library;
//    - a Task is "hot": execution starts when the method is called, not at the first await;
//    - cancellation, exceptions and synchronization contexts are standardized.

static class TimeSpanAwaiterExtensions
{
    // await works with ANY type that has a suitable GetAwaiter() method — even if it is an
    // extension method. C++: operator co_await.
    public static TaskAwaiter GetAwaiter(this TimeSpan delay) => Task.Delay(delay).GetAwaiter();
}

static class Section13_AsyncAwait
{
    static async Task<int> FetchLengthAsync(string name, int delayMs, CancellationToken cancellation = default)
    {
        await Task.Delay(delayMs, cancellation); // a timer, not Thread.Sleep: no thread is blocked
        return name.Length * delayMs;
    }

    // ValueTask<T> is a struct instead of a Task object: no allocation when the result is
    // often ready at once (for example, it sits in a cache).
    static ValueTask<int> CachedLengthAsync(Dictionary<string, int> cache, string name) =>
        cache.TryGetValue(name, out int cached)
            ? ValueTask.FromResult(cached)
            : new ValueTask<int>(FetchLengthAsync(name, 5));

    // An asynchronous iterator: `yield return` and `await` in one method.
    static async IAsyncEnumerable<int> TicksAsync(
        int count, [EnumeratorCancellation] CancellationToken cancellation = default)
    {
        for (int i = 1; i <= count; i++)
        {
            await Task.Delay(5, cancellation);
            yield return i;
        }
    }

    // A resource with asynchronous release (for example, flushing buffers to the network).
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

        // A task starts at the moment of the call; await waits for the result without blocking a thread.
        Task<int> pending = FetchLengthAsync("alpha", 30);
        Console.WriteLine($"task started, completed yet: {pending.IsCompleted}");
        Console.WriteLine($"awaited result: {await pending}");

        // Concurrent waiting: the total time is the maximum, not the sum.
        var stopwatch = Stopwatch.StartNew();
        int[] results = await Task.WhenAll(FetchLengthAsync("beta", 40), FetchLengthAsync("gamma", 20));
        Console.WriteLine($"WhenAll -> [{Join(results)}] in about {stopwatch.ElapsedMilliseconds} ms (not 60)");

        Task<int> winner = await Task.WhenAny(FetchLengthAsync("slow", 200), FetchLengthAsync("fast", 10));
        Console.WriteLine($"WhenAny -> the first finished task returned {await winner}");

        // Cancellation is cooperative, through CancellationToken. C++: std::stop_token.
        using var timeout = new CancellationTokenSource(TimeSpan.FromMilliseconds(20));
        try
        {
            await FetchLengthAsync("never", 5_000, timeout.Token);
        }
        catch (OperationCanceledException)
        {
            Console.WriteLine("cancelled by timeout: OperationCanceledException");
        }

        // An exception from a task is stored in it and rethrown at the await point.
        // (`int () => ...` is a lambda with an explicitly specified return type.)
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

        // An asynchronous stream of values is consumed with `await foreach`.
        int tickSum = 0;
        await foreach (int tick in TicksAsync(3)) tickSum += tick;
        Console.WriteLine($"await foreach received ticks with sum {tickSum}");

        // `await using` is the asynchronous counterpart of using.
        await using (var resource = new AsyncResource("connection"))
        {
            Console.WriteLine("    working with the connection");
        }

        // A channel is an asynchronous producer-consumer queue.
        var channel = Channel.CreateBounded<int>(capacity: 2);
        Task producer = Task.Run(async () =>
        {
            for (int i = 1; i <= 5; i++) await channel.Writer.WriteAsync(i); // waits for free room
            channel.Writer.Complete();
        });
        int received = 0;
        await foreach (int item in channel.Reader.ReadAllAsync()) received += item;
        await producer;

        // Processing a collection in parallel with asynchronous operations.
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

        await TimeSpan.FromMilliseconds(5); // works thanks to the GetAwaiter extension above

        // TaskCompletionSource: a task whose result is set manually. C++: std::promise.
        var completion = new TaskCompletionSource<string>();
        _ = Task.Run(() => completion.SetResult("set from another thread"));
        Console.WriteLine($"TaskCompletionSource: {await completion.Task} | " +
                          $"continuing on a pool thread: {Thread.CurrentThread.IsThreadPoolThread}");
        // Good manners: async void is for event handlers only; do not block a thread with
        // .Result and .Wait() where an await can be written.
    }
}

// =====================================================================================
//  14. REFLECTION, ATTRIBUTES, CODE GENERATION
// =====================================================================================
//
//  A .NET assembly stores full metadata: types, members, signatures, attributes. A program
//  can read it at run time, create objects and call methods by name, build and compile code
//  on the fly. In C++ static reflection arrives only in C++26, and there is no run-time
//  reflection at all.

// A custom attribute is a class derived from Attribute. The compiler writes it into the metadata.
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

    public int Moons { get; set; } // no attribute

    public double SurfaceGravity(double radius) => 6.674e-11 * Mass / (radius * radius);
}

// A source generator: it writes the body of a partial member at COMPILE time. Here it
// produces a ready-made state machine for the regular expression — no pattern parsing at
// startup. C++: constexpr libraries such as CTRE.
static partial class Patterns
{
    [GeneratedRegex(@"(?<key>\w+)=(?<value>\d+)")]
    public static partial Regex KeyValue { get; }
}

static class Section14_Reflection
{
    // "Caller info" attributes: the compiler supplies the parameter values.
    // C++: std::source_location; the text of an expression is available there only through a
    // macro with `#`.
    static string Check(
        bool condition,
        [CallerArgumentExpression(nameof(condition))] string expression = "",
        [CallerMemberName] string member = "",
        [CallerLineNumber] int line = 0) =>
        $"`{expression}` is {condition} (in {member}, line {line})";

    public static void Run()
    {
        Header(14, "Reflection, attributes, code generation");

        // --- Reflection -------------------------------------------------------------------
        var earth = new Planet { Name = "Earth", Mass = 5.972e24, Moons = 1 };
        Type type = earth.GetType(); // or typeof(Planet). C++: typeid, but incomparably richer
        Console.WriteLine($"{type.Name} : {type.BaseType?.Name} | properties: " +
                          Join(type.GetProperties().Select(p => $"{p.PropertyType.Name} {p.Name}")));

        // Reading attributes and values: this is how ORMs, serializers and DI containers work.
        foreach (PropertyInfo property in type.GetProperties())
        {
            var column = property.GetCustomAttribute<ColumnAttribute>();
            if (column is null) continue;
            Console.WriteLine($"    {property.Name} -> column '{column.Name}'{(column.IsKey ? " (key)" : "")}" +
                              $" = {property.GetValue(earth)}");
        }

        // Setting a property and calling a method by name; creating an object from a type description.
        type.GetProperty("Moons")!.SetValue(earth, 2);
        object? gravity = type.GetMethod(nameof(Planet.SurfaceGravity))!.Invoke(earth, [6.371e6]);
        var blank = (Planet)Activator.CreateInstance(type)!;
        Console.WriteLine($"moons set by name: {earth.Moons} | method invoked by name: {gravity:F2} m/s^2 | " +
                          $"object created from Type: Moons = {blank.Moons}");

        // Serialization without a single line of hand-written code — reflection in action.
        string json = JsonSerializer.Serialize(earth);
        Planet restored = JsonSerializer.Deserialize<Planet>(json)!;
        Console.WriteLine($"{json} -> {restored.Name} with {restored.Moons} moons");

        // nameof and the Caller* attributes.
        Console.WriteLine($"{nameof(Planet.SurfaceGravity)} | {Check(earth.Moons > 1)}");

        // --- Expression trees -------------------------------------------------------------
        // A lambda received not as code but as DATA: an object model of the expression. It can be
        // analysed (this is how LINQ providers translate queries to SQL) or compiled.
        Expression<Func<double, double>> formula = x => x * x + 2 * x + 1;
        Func<double, double> compiled = formula.Compile(); // JIT compilation at run time
        Console.WriteLine($"{formula.Body} | root node: {formula.Body.NodeType} | f(3) = {compiled(3)}");

        // A tree can also be assembled by hand — that is run-time code generation.
        ParameterExpression parameter = Expression.Parameter(typeof(double), "x");
        Expression body = Expression.Add(
            Expression.Multiply(parameter, Expression.Constant(3.0)),
            Expression.Constant(1.0));
        var linear = Expression.Lambda<Func<double, double>>(body, parameter).Compile();
        Console.WriteLine($"built at run time: {body} | linear(2) = {linear(2)}");

        // --- dynamic: late binding --------------------------------------------------------
        // Member lookup is deferred until run time, as in Python. Needed for COM and "duck-typed" APIs.
        dynamic value = 21;
        value *= 2;                // the operator is resolved at run time
        value = $"{value}!";       // the type of the value may change
        int length = value.Length; // the Length property is looked up dynamically too
        Console.WriteLine($"dynamic: {value} has length {length}");

        // --- Source generators ------------------------------------------------------------
        Match match = Patterns.KeyValue.Match("width=42");
        Console.WriteLine($"generated regex: {match.Groups["key"].Value} -> {match.Groups["value"].Value}");
        // [LibraryImport] (section 11), System.Text.Json in its reflection-free mode and
        // [LoggerMessage] work the same way. A generator is an ordinary .NET library plugged into
        // the compiler.
    }
}

// =====================================================================================
//  15. THE NEWEST: C# 12-14 AND C# 15
// =====================================================================================
//
//  The language is updated every year together with .NET. Some of the novelties have already
//  appeared above: collection expressions and primary constructors (C# 12), the Lock type
//  (C# 13), the field keyword and extension blocks (C# 14). The rest is here.

// User-defined COMPOUND assignment (C# 14): `+=` modifies the object in place.
// Before C# 14 `a += b` always meant `a = a + b`, that is, creating a new value.
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
    // An extension block without a receiver name: static members and operators for a foreign type.
    extension(string)
    {
        public static string operator *(string text, int count) =>
            string.Concat(Enumerable.Repeat(text, count));
    }

    // A generic block: an extension property for any sequence.
    extension<T>(IEnumerable<T> source)
    {
        public bool IsEmpty => !source.Any();
    }
}

// A ref struct can implement interfaces (C# 13).
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

// partial: a type definition can be split into parts (usually across files).
// A partial property (C# 13): the declaration in one part, the implementation in another.
// This is exactly how source generators complete your classes.
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
    // `allows ref struct` (C# 13): a generic method that accepts ref structs as well.
    static string DescribeAny<T>(T item) where T : IDescribable, allows ref struct => item.Describe();

    // params with any collection (C# 13): for a ReadOnlySpan no heap array is created.
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
        stats += 3.0; // calls our operator += and modifies stats in place
        stats += 5.0;
        Console.WriteLine($"compound assignment operator: mean {stats.Mean} of {stats.Count} values");

        // Assignment through `?.`: it happens only if the left side is not null.
        Order? order = null;
        order?.Quantity = 5; // nothing happens — and no exception either
        Console.WriteLine($"assignment through null: order is still null: {order is null}");
        order = new Order();
        order?.Quantity = 5;
        order?.Note ??= "added later";
        Console.WriteLine($"null-conditional assignment: {order?.Quantity}, '{order?.Note}'");

        // Operators and properties from the extension blocks.
        Console.WriteLine($"extension operator: {"ab" * 3} | extension property: {Array.Empty<int>().IsEmpty}");

        // nameof for an open generic type; lambda parameter modifiers without types.
        TryParseDelegate parse = (text, out result) => int.TryParse(text, out result);
        Console.WriteLine($"{nameof(List<>)} | {parse("42", out int number)} {number}");

        // Spans are "first-class" types: an array converts to a Span by itself wherever one is needed.
        int[] measurements = [7, 3, 9];
        Console.WriteLine($"{Total(measurements)} {Total(1, 2, 3)} | {DescribeAny(new SpanStats(measurements))}");

        // --- C# 13 ------------------------------------------------------------------------
        var telemetry = new Telemetry();
        var buffer = new List<int> { 1, 2, 3 };
        Console.WriteLine($"partial property: {telemetry.Source} | escape \\e is U+{(int)'\e':X4} | " +
                          $"index from the end: {buffer[^1]}");

        // --- C# 12 ------------------------------------------------------------------------
        Coordinates home = (48.137, 11.575); // the tuple alias declared at the top of the file
        int[] row = [1, 2, 3];
        int[][] table = [row, [.. row, 4], []];
        Console.WriteLine($"type alias: {home.Latitude}, {home.Longitude} | " +
                          $"collection expressions, row lengths: {Join(table.Select(r => r.Length))}");
    }
}

#if CSHARP15
// =====================================================================================
//  C# 15 (.NET 11) — enabled by the CSHARP15 symbol at the top of the file
// =====================================================================================
//
//  NOTE: this block was not compiled during verification (only .NET SDK 10 was available).
//  The syntax follows Microsoft's "What's new in C# 15" documentation.
namespace CSharp15
{
    public record class Cat(string Name);
    public record class Dog(string Name);
    public record class Bird(string Name);

    // A union type: a Pet value is EXACTLY ONE of the listed types.
    // C++: std::variant<Cat, Dog, Bird>.
    public union Pet(Cat, Dog, Bird);

    // A closed hierarchy: derived types are possible only in this assembly, so the compiler
    // knows them all and checks a switch for exhaustiveness.
    public closed record class GateState;
    public record class Closed : GateState;
    public record class Open(float Percent) : GateState;

    public static class Demo
    {
        static string Describe(GateState state) => state switch
        {
            Closed => "closed",
            Open(var percent) => $"{percent}% open",
            // No `_` arm is needed: all direct subtypes of GateState are listed.
        };

        public static void Run()
        {
            Console.WriteLine("\n=== C# 15 ===");

            Pet pet = new Dog("Rex"); // an implicit conversion from a case type
            string name = pet switch  // an exhaustive switch without a `_` arm
            {
                Dog dog => dog.Name,
                Cat cat => cat.Name,
                Bird bird => bird.Name,
            };
            Console.WriteLine($"union: {name} | closed hierarchy: {Describe(new Open(40))}, {Describe(new Closed())}");

            // Constructor arguments right in a collection expression.
            string[] values = ["one", "two", "three"];
            List<string> names = [with(capacity: values.Length * 2), .. values];
            HashSet<string> set = [with(StringComparer.OrdinalIgnoreCase), "Hello", "HELLO", "hello"];
            Console.WriteLine($"with(...): capacity {names.Capacity}, set size {set.Count}");

            // Labeled break and continue: leaving nested loops without goto and flags.
            int visited = 0;
            outer: for (int row = 0; row < 3; row++)
            {
                for (int column = 0; column < 3; column++)
                {
                    if (column > row) continue outer;   // go on to the next row
                    if (row + column == 3) break outer; // leave both loops
                    visited++;
                }
            }
            Console.WriteLine($"labeled break/continue: {visited} cells visited");
        }
    }
}
#endif
