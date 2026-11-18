' =================================================================================================
'  VISUAL BASIC FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
'
'  This is Visual Basic .NET: the language that shares the compiler platform (Roslyn), the
'  runtime and the libraries with C#. It is not VB6 and not VBA; section 14 lists what changed
'  since VB6.
'
'  Run, from the root of the repository:
'
'      dotnet run --project vb_tour
'
'  Verified with .NET SDK 10.0.115 (Visual Basic 17.13, the latest version of the language) on
'  Linux. Visual Basic has no single-file mode like `dotnet run file.cs`, so the tour lives in
'  a folder of its own, next to a small project file, vb_tour.vbproj.
'
'  How to read. Go from top to bottom: Main calls the sections in order, and every section
'  prints what it demonstrates. A "C#:" note gives the closest counterpart in C#. A line that
'  is commented out and followed by a BC code does not compile, and the code is the reason.
'
'  The main differences from C# to keep in mind from the first line:
'
'   1. Words instead of punctuation. A block ends with End If / End Sub / Next / Loop; there
'      are no braces and no semicolons: the end of the line ends the statement.
'   2. Names and keywords are case-insensitive: Total, total and TOTAL are one identifier.
'   3. `=` both assigns and compares, `<>` is "not equal", and Not / And / Or stand for
'      ! & |. And / Or evaluate both sides; AndAlso / OrElse short-circuit like && and ||.
'   4. The type follows the name (Dim count As Integer), generics are written (Of T), and
'      parentheses do both calls and indexing: items(0).
'   5. An array is declared by its UPPER BOUND: Dim a(4) As Integer has five elements.
'   6. Integer arithmetic is checked: an overflow throws instead of wrapping around.
'   7. Nothing is C#'s `default`, not only null: for an Integer it is 0.
'   8. Compiler options change the rules. Option Strict is Off by default, which permits
'      implicit narrowing conversions and late binding; this file turns it On, and so should
'      every new project.
'
'  Contents:
'    1. Basics: variables, types, operators        8. Errors and resources
'    2. Control flow                               9. LINQ and extension methods
'    3. Procedures, lambdas, delegates            10. XML literals
'    4. Arrays, collections, tuples               11. Nothing and nullable values
'    5. Classes, properties, structures, enums    12. Iterators, Async / Await, threads
'    6. Inheritance, interfaces, events           13. The VB library, attributes, reflection
'    7. Generics                                  14. Coming from VB6, and the newest
' =================================================================================================

Option Strict On        ' no implicit narrowing conversions, no late binding (C# is always so)
Option Explicit On      ' every variable must be declared (the default)
Option Infer On         ' Dim x = 5 makes x an Integer (the default). C#: var
Option Compare Binary   ' = on strings compares code points (the default); Text ignores case

' The project imports these namespaces into every file by itself (C#: implicit usings):
' Microsoft.VisualBasic, System, System.Collections, System.Collections.Generic, System.Data,
' System.Diagnostics, System.Linq, System.Threading.Tasks, System.Xml.Linq.
Imports System.Globalization
Imports System.Reflection
Imports System.Runtime.CompilerServices
Imports System.Text
Imports System.Text.Json.Nodes
Imports System.Threading

' A Module is C#'s static class, with one addition: its members can be used anywhere in the
' project without the module's name. Types declared in this file land in the namespace VbTour,
' the RootNamespace of the project; a Namespace block would nest INSIDE it.
Module Program

    ' The entry point. C#: static void Main(). (There are no top-level statements.)
    Sub Main()
        ' Format numbers and dates the same way on every machine: 3.5, not 3,5.
        CultureInfo.CurrentCulture = CultureInfo.InvariantCulture

        Section01_Basics()
        Section02_ControlFlow()
        Section03_Procedures()
        Section04_Collections()
        Section05_Classes()
        Section06_Inheritance()
        Section07_Generics()
        Section08_Errors()
        Section09_Linq()
        Section10_Xml()
        Section11_Nothing()
        Section12_Async()
        Section13_Library()
        Section14_Newest()
    End Sub

    Sub Title(number As Integer, text As String)
        Console.WriteLine()
        Console.WriteLine($"=== {number}. {text} ===")
    End Sub

    ' =============================================================================================
    '  1. Basics: variables, types, operators
    ' =============================================================================================

    Sub Section01_Basics()
        Title(1, "Basics: variables, types, operators")

        ' Dim declares a variable, and the type follows the name. C#: int count = 5;
        Dim count As Integer = 5                ' Integer = int, Long = long, Short = short
        Dim price As Decimal = 19.99D           ' the suffix D means Decimal. C#: 19.99m
        Dim big As Long = 9_000_000_000L
        Dim ratio = 2.5                         ' inferred as Double. C#: var ratio = 2.5;
        Dim rough As Single = 0.1F              ' Single = float
        Dim letter As Char = "A"c               ' a Char literal is a string literal plus c
        Dim done As Boolean = True
        Dim mask = &HFF                         ' hexadecimal; &B1010 is binary, &O17 octal
        Dim release As Date = #2026-11-17#      ' a date literal; Date is System.DateTime
        Const Tau As Double = 6.283185307179586
        Dim width, height As Integer            ' BOTH are Integer (in VB6 width was a Variant)
        Console.WriteLine($"{count} {price} {big} {ratio} {rough} {letter} {done} {mask} " &
                          $"{release:yyyy-MM-dd} {Tau:F3} {width + height}")

        ' Names are case-insensitive: this is the variable declared above.
        COUNT = Count + 1
        Console.WriteLine($"count is now {count}")

        ' Arithmetic. / always divides as floating point, \ divides integers, ^ is a power.
        Console.WriteLine($"7 / 2 = {7 / 2}, 7 \ 2 = {7 \ 2}, 7 Mod 3 = {7 Mod 3}, " &
                          $"2 ^ 10 = {2 ^ 10}")
        ' & concatenates and turns its operands into strings.
        Console.WriteLine("count: " & count & ", price: " & price)
        ' And, Or, Xor, Not work on the bits of integers (and on Booleans as logic).
        Console.WriteLine($"1 << 4 = {1 << 4}, 6 And 3 = {6 And 3}, 6 Or 3 = {6 Or 3}, " &
                          $"6 Xor 3 = {6 Xor 3}, Not 0 = {Not 0}")
        ' There are compound assignments (+= -= *= \= &= ...), but no ++ and no --.
        count += 1

        ' In an expression = compares; as a statement it assigns. <> means "not equal".
        Dim isSeven = count = 7                 ' assigns the result of the comparison
        ' And / Or evaluate both operands; AndAlso / OrElse stop as soon as the answer is known.
        Dim missing As String = Nothing
        If missing IsNot Nothing AndAlso missing.Length > 0 Then Console.WriteLine("not printed")
        ' If missing IsNot Nothing And missing.Length > 0 Then ...     ' NullReferenceException
        ' Is / IsNot compare references. C#: `is null`, `is not null`, ReferenceEquals.
        Console.WriteLine($"isSeven: {isSeven}; missing Is Nothing: {missing Is Nothing}")

        ' Integer arithmetic is checked. C#: unchecked unless you write `checked`.
        Dim limit = Integer.MaxValue
        Try
            limit += 1
        Catch ex As OverflowException
            Console.WriteLine("Integer.MaxValue + 1 throws " & ex.GetType().Name)
        End Try

        ' Conversions. Widening ones are implicit. With Option Strict On a narrowing one must be
        ' written out with a conversion function: CInt, CLng, CDbl, CDec, CStr, CBool ...
        Dim half As Double = 2.5
        ' Dim bad As Integer = half
        '     BC30512: Option Strict On disallows implicit conversions from 'Double' to 'Integer'.
        ' CInt ROUNDS, and halves go to the even neighbour; a C# cast truncates.
        Console.WriteLine($"CInt(2.5) = {CInt(half)}, CInt(3.5) = {CInt(3.5)}, " &
                          $"Fix(2.5) = {Fix(half)}, CInt(""42"") + 1 = {CInt("42") + 1}")

        Dim boxed As Object = "text"
        Dim asString = DirectCast(boxed, String)        ' a pure cast. C#: (string)boxed
        Dim asList = TryCast(boxed, List(Of Integer))   ' Nothing on a mismatch. C#: `as`
        Dim asNumber = CType("3.5", Double)             ' the general form; CDbl("3.5") is the same
        Console.WriteLine($"{asString.Length} {asList Is Nothing} {asNumber} " &
                          $"{ChrW(66)} {AscW("B"c)}")

        ' Strings are .NET strings. There are no backslash escapes: a quote is doubled, and
        ' control characters come from constants such as vbTab, vbCrLf and vbLf.
        Dim name = "World"
        Dim greeting = $"Hello, {name}! {count:D3} {price:F1}"      ' interpolation as in C#
        Dim quoted = "She said ""hi"" and left a \ behind"
        Console.WriteLine(greeting)
        Console.WriteLine(quoted & vbTab & "<- a tab")

        ' = on strings compares the contents and treats Nothing as an empty string.
        ' Like matches simple wildcard patterns.
        Dim sameLetters = "a" = "A"
        Dim nothingIsEmpty = missing = ""
        Dim ignoringCase = String.Equals("a", "A", StringComparison.OrdinalIgnoreCase)
        Console.WriteLine($"""a"" = ""A"": {sameLetters}; Nothing = """": {nothingIsEmpty}; " &
                          $"ignoring case: {ignoringCase}; Like: {"tour.vb" Like "*.vb"}")

        ' The If operator: with three arguments it is C#'s ?:, with two it is ??.
        ' (IIf is an ordinary library function: it evaluates both branches.)
        Dim size = If(count > 3, "big", "small")
        Dim shown = If(missing, "(nothing)")
        Console.WriteLine($"{size} {shown}")

        ' A statement ends with its line. It continues on the next line after an operator, a
        ' comma or an open parenthesis, or anywhere after a space and an underscore. A colon
        ' separates two statements on one line.
        Dim total = 1 +
                    2 +
                    3
        Dim average As Double _
            = total / 3
        Dim x = 1 : Dim y = 2
        Console.WriteLine($"{total} {average} {x + y}")
    End Sub

    ' =============================================================================================
    '  2. Control flow
    ' =============================================================================================

    Sub Section02_ControlFlow()
        Title(2, "Control flow")

        ' If ... Then ... ElseIf ... Else ... End If. An If on one line needs no End If.
        Dim n = 7
        If n Mod 2 = 0 Then
            Console.WriteLine("even")
        ElseIf n > 5 Then
            Console.WriteLine("odd and greater than 5")
        Else
            Console.WriteLine("odd and small")
        End If
        If n > 0 Then Console.WriteLine("positive") Else Console.WriteLine("not positive")

        ' Select Case has no fall-through and no break. A Case takes values, ranges and
        ' comparisons. C#: switch with relational patterns.
        For Each value In {2, 5, 9, 42}
            Select Case value
                Case 1, 2, 3
                    Console.WriteLine($"{value}: one of 1, 2, 3")
                Case 4 To 6
                    Console.WriteLine($"{value}: from 4 to 6")
                Case Is < 10
                    Console.WriteLine($"{value}: less than 10")
                Case Else
                    Console.WriteLine($"{value}: something else")
            End Select
        Next

        ' For ... Next counts from the first bound to the second, BOTH included.
        Dim line As New StringBuilder()
        For i = 1 To 5
            line.Append(i).Append(" "c)
        Next
        For i = 10 To 0 Step -5
            line.Append(i).Append(" "c)
        Next
        Console.WriteLine(line.ToString().TrimEnd())

        ' For Each walks any IEnumerable. Exit For is C#'s break, Continue For is continue.
        line.Clear()
        For Each word In {"alpha", "beta", "gamma", "delta"}
            If word.StartsWith("b"c) Then Continue For
            If word = "delta" Then Exit For
            line.Append(word).Append(" "c)
        Next
        Console.WriteLine(line.ToString().TrimEnd())

        ' Do loops test While or Until, at the top or at the bottom.
        Dim power = 1
        Do While power < 100
            power *= 2
        Loop
        Dim attempts = 0
        Do
            attempts += 1
        Loop Until attempts >= 3                ' the body runs at least once. C#: do ... while
        While power > 100                       ' the same as Do While ... Loop
            power \= 2
        End While
        Console.WriteLine($"power {power}, attempts {attempts}")

        ' With avoids repeating an object: a leading dot refers to it.
        With line
            .Clear()
            .Append("built ")
            .Append("with With")
            Console.WriteLine(.ToString() & ", length " & .Length)
        End With
    End Sub

    ' =============================================================================================
    '  3. Procedures, lambdas, delegates
    ' =============================================================================================

    ' A Sub returns nothing (C#: void); a Function returns a value.
    Function Add(a As Integer, b As Integer) As Integer
        Return a + b
    End Function

    ' Parameters are ByVal unless ByRef is written. ByRef passes the variable itself (C#: ref),
    ' and nothing at the call site shows it.
    Sub Swap(ByRef first As Integer, ByRef second As Integer)
        Dim keep = first
        first = second
        second = keep
    End Sub

    ' An Optional parameter needs a default value; ParamArray is C#'s params.
    Function Power(base As Double, Optional exponent As Integer = 2) As Double
        Return base ^ exponent
    End Function

    Function JoinAll(separator As String, ParamArray parts As String()) As String
        Return String.Join(separator, parts)
    End Function

    ' Overloads differ in their parameters, as in C#.
    Function Describe(value As Integer) As String
        Return "the integer " & value
    End Function

    Function Describe(value As String) As String
        Return "the string """ & value & """"
    End Function

    ' The old way to return a value: assign it to the function's own name. It still compiles.
    Function LegacySum(a As Integer, b As Integer) As Integer
        LegacySum = a + b
    End Function

    ' A Static local keeps its value between calls. C#: no counterpart; a private field.
    Function NextTicket() As Integer
        Static issued As Integer = 100
        issued += 1
        Return issued
    End Function

    ' A delegate type. C#: delegate int BinaryOperation(int a, int b);
    Delegate Function BinaryOperation(a As Integer, b As Integer) As Integer

    Function Apply(operation As BinaryOperation, a As Integer, b As Integer) As Integer
        Return operation(a, b)
    End Function

    Sub Section03_Procedures()
        Title(3, "Procedures, lambdas, delegates")

        Dim a = 1, b = 2
        Swap(a, b)
        Console.WriteLine($"Add: {Add(2, 3)}; swapped: {a} {b}")
        ' An argument in extra parentheses is an expression, so ByRef receives a copy of it.
        Swap((a), b)
        Console.WriteLine($"a stays {a}, b becomes {b}")

        ' Named arguments use := and may come in any order.
        Console.WriteLine($"{Power(3)} {Power(2, 10)} {Power(exponent:=3, base:=2)}")
        Console.WriteLine(JoinAll("-", "a", "b", "c") & " | " & Describe(5) & " | " &
                          Describe("five"))
        Console.WriteLine($"{LegacySum(2, 2)} {NextTicket()} {NextTicket()}")

        ' Lambdas: Function(...) returns a value, Sub(...) does not. C#: x => x * x
        Dim square = Function(x As Integer) x * x
        Dim classify = Function(x As Integer) As String
                           If x < 0 Then Return "negative"
                           Return If(x = 0, "zero", "positive")
                       End Function
        Dim log As Action(Of String) = Sub(message) Console.WriteLine("  log: " & message)
        log($"{square(7)} {classify(-3)} {classify(0)}")

        ' A method turns into a delegate with AddressOf. C#: the bare method name.
        Dim adder As Func(Of Integer, Integer, Integer) = AddressOf Add
        Dim multiply As BinaryOperation = Function(p, q) p * q
        Console.WriteLine($"{adder(2, 3)} {Apply(multiply, 4, 5)} {Apply(AddressOf Add, 6, 7)}")

        ' Closures capture variables, not values, as in C#.
        Dim counter = 0
        Dim increment = Sub() counter += 1
        increment()
        increment()
        Console.WriteLine($"counter after two calls: {counter}")

        ' A call without arguments may drop its parentheses, so a method can look like a
        ' property. Editors add the parentheses back.
        Dim digits = DateTime.UtcNow.Year.ToString.Length
        Console.WriteLine($"digits in the year: {digits}")
    End Sub

    ' =============================================================================================
    '  4. Arrays, collections, tuples
    ' =============================================================================================

    ' A tuple as a return type. C#: (int Min, int Max) MinMax(IEnumerable<int> values)
    Function MinMax(values As IEnumerable(Of Integer)) As (Min As Integer, Max As Integer)
        Return (values.Min(), values.Max())
    End Function

    Sub Section04_Collections()
        Title(4, "Arrays, collections, tuples")

        ' The number in an array declaration is the UPPER BOUND, not the length.
        Dim slots(4) As Integer                         ' five elements: slots(0) ... slots(4)
        Dim primes = {2, 3, 5, 7, 11}                   ' an array literal: Integer()
        Dim names As String() = {"Ann", "Bob"}
        Dim grid(1, 2) As Double                        ' 2 x 3. C#: new double[2, 3]
        Dim table = {{1, 2, 3}, {4, 5, 6}}              ' Integer(,): rectangular
        Dim jagged = {({1}), ({2, 3}), ({4, 5, 6})}     ' Integer()(): an array of arrays
        slots(4) = 40
        grid(1, 2) = 1.5
        Console.WriteLine($"slots has {slots.Length} elements; " &
                          $"UBound(primes) = {UBound(primes)}; " &
                          $"the last name is {names(names.Length - 1)}; " &
                          $"grid is {grid.GetLength(0)}x{grid.GetLength(1)}; " &
                          $"{table(1, 2)} {jagged(2)(1)}")

        ' ReDim resizes an array, and Preserve keeps its contents. C#: Array.Resize
        ReDim Preserve primes(6)
        primes(5) = 13
        primes(6) = 17
        Console.WriteLine(String.Join(" ", primes))
        ' There is no primes(^1) and no primes(1..3): use Length - 1, Skip and Take.

        ' The collections are the .NET ones. From { ... } is a collection initializer.
        Dim numbers As New List(Of Integer) From {3, 1, 2}
        numbers.Add(5)
        numbers.Sort()
        Dim ages As New Dictionary(Of String, Integer) From {{"Ann", 31}, {"Bob", 27}}
        ages("Cid") = 40                                ' an indexer uses parentheses as well
        Dim age As Integer                              ' declared first: there is no `out var`
        If ages.TryGetValue("Bob", age) Then Console.WriteLine($"Bob is {age}")
        Console.WriteLine(String.Join(" ", numbers) & " | " &
                          String.Join(", ", ages.Select(Function(pair) $"{pair.Key}={pair.Value}")))
        Dim unique As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase) From {"a", "A", "b"}
        Console.WriteLine($"a set of {unique.Count}")

        ' Tuples. The elements can have names; a tuple cannot be deconstructed into variables.
        Dim point = (X:=3, Y:=4)
        Dim person As (Name As String, Age As Integer) = ("Ann", 31)
        Dim range = MinMax(primes)
        Console.WriteLine($"{point.X + point.Y} {person.Name} {person.Item2} " &
                          $"{range.Min}..{range.Max}")
        ' Dim (lowest, highest) = MinMax(primes)        ' BC30203: Identifier expected.
    End Sub

    ' =============================================================================================
    '  5. Classes, properties, structures, enums     (the types are declared below the module)
    ' =============================================================================================

    Sub Section05_Classes()
        Title(5, "Classes, properties, structures, enums")

        Dim savings As New Account("Ann", 100D)         ' or: Dim savings = New Account(...)
        savings.Deposit(50D)
        savings.Note = "savings"
        Console.WriteLine($"{savings}; accounts opened: {Account.Opened}")
        Try
            savings.Withdraw(500D)
        Catch ex As InvalidOperationException
            Console.WriteLine("Withdraw failed: " & ex.Message)
        End Try
        ' savings.Balance = 5D
        '     BC31102: 'Set' accessor of property 'Balance' is not accessible.

        ' An object initializer is written With { ... } and a dot before each member.
        Dim current = New Account("Bob") With {.Note = "current"}
        Console.WriteLine($"{current}; accounts opened: {Account.Opened}")

        ' Anonymous types. Only the properties marked Key are read-only and take part in Equals;
        ' the others can be assigned. C#: all properties are read-only and compared.
        Dim draft = New With {Key .Id = 1, .Label = "draft"}
        Dim final = New With {Key .Id = 1, .Label = "final"}
        draft.Label = "edited"
        Console.WriteLine($"{draft.Label}; equal by key: {draft.Equals(final)}")

        ' A Structure is copied on assignment. Its operators and conversions are user-defined.
        Dim v = New Vector(3, 4)
        Dim w = v
        w += New Vector(1, 1)
        Dim asText As String = v                        ' the Widening conversion, implicitly
        Dim asLength = CType(v, Double)                 ' the Narrowing one must be written out
        Console.WriteLine($"{asText} + (1, 1) = {CType(w, String)}; length {asLength}; " &
                          $"equal: {v = New Vector(3, 4)}; doubled: {CType(v * 2, String)}")

        ' Enums. Flags are combined with Or and tested with And or HasFlag. Square brackets
        ' escape a keyword: [Enum] is the type System.Enum.
        Dim rank = Level.Senior
        Dim rights = Access.Read Or Access.Write
        Console.WriteLine($"{rank} = {CInt(rank)}; {rights}; " &
                          $"write: {rights.HasFlag(Access.Write)}; " &
                          $"execute: {(rights And Access.Execute) <> 0}; " &
                          $"parsed: {[Enum].Parse(Of Level)("Middle")}")
    End Sub

    ' =============================================================================================
    '  6. Inheritance, interfaces, events
    ' =============================================================================================

    Sub Section06_Inheritance()
        Title(6, "Inheritance, interfaces, events")

        Dim shapes As Shape() = {New Circle(1), New Rectangle(2, 3)}
        For Each item In shapes
            Console.WriteLine(item.Describe())
            ' TypeOf ... Is tests the type. There are no patterns, so a cast follows.
            If TypeOf item Is Circle Then
                Console.WriteLine("  its radius is " & DirectCast(item, Circle).Radius)
            End If
        Next

        Dim small = New Rectangle(1, 2), large = New Rectangle(3, 4)
        Dim labelled As ILabelled = large
        Console.WriteLine($"compare: {small.CompareByArea(large)}; label: {labelled.Label}")
        ' Console.WriteLine(large.Label)      ' BC30456: 'Label' is not a member of 'Rectangle'.

        ' Events. Handles subscribes declaratively (see the class Alarm); AddHandler and
        ' RemoveHandler do it at run time. C#: += and -=.
        Dim sensor As New Thermometer()
        Dim alarm As New Alarm(sensor)
        Dim readings As New List(Of Double)
        Dim onChanged As EventHandler(Of Double) = Sub(sender, degrees) readings.Add(degrees)
        AddHandler sensor.Changed, onChanged
        sensor.Report(36.6)
        sensor.Report(120)
        RemoveHandler sensor.Changed, onChanged
        sensor.Report(150)
        Console.WriteLine($"readings: {String.Join(" ", readings)}; " &
                          $"alarm log: {String.Join("; ", alarm.Log)}")
    End Sub

    ' =============================================================================================
    '  7. Generics
    ' =============================================================================================

    ' A constraint follows As. C#: where T : IComparable<T>
    Function Largest(Of T As IComparable(Of T))(ParamArray values As T()) As T
        Dim best = values(0)
        For Each value In values
            If value.CompareTo(best) > 0 Then best = value
        Next
        Return best
    End Function

    ' Several constraints go in braces. C#: where T : class, ICollection<int>, new()
    Function CreateFilled(Of T As {Class, ICollection(Of Integer), New})(count As Integer) As T
        Dim result As New T()
        For i = 1 To count
            result.Add(i * i)
        Next
        Return result
    End Function

    Sub Section07_Generics()
        Title(7, "Generics")

        Dim stack As New TinyStack(Of String)
        stack.Push("first")
        stack.Push("second")
        stack.Push("third")
        Console.WriteLine($"top: {stack(0)}; count: {stack.Count}; popped: {stack.Pop()}; " &
                          $"left: {String.Join(" ", stack)}")

        ' The type arguments of a generic method are usually inferred.
        Console.WriteLine($"{Largest(3, 9, 4)} {Largest("pear", "apple")} " &
                          $"{Largest(Of Double)(1, 2.5)}")
        Dim squares = CreateFilled(Of List(Of Integer))(4)
        Console.WriteLine(String.Join(" ", squares))

        ' Covariance: a producer of circles is a producer of shapes.
        Dim producer As IProducer(Of Shape) = New CircleFactory()
        Console.WriteLine(producer.Produce().Describe())
    End Sub

    ' =============================================================================================
    '  8. Errors and resources
    ' =============================================================================================

    Function ParseAge(text As String) As Integer
        Dim age As Integer
        If Not Integer.TryParse(text, age) Then
            Throw New ValidationException("age", $"'{text}' is not a number")
        End If
        If age < 0 OrElse age > 150 Then
            Throw New ArgumentOutOfRangeException(NameOf(text), age, "the age is out of range")
        End If
        Return age
    End Function

    ' Unstructured error handling, inherited from VB6: On Error jumps to a label, and the Err
    ' object describes the error. It still compiles, but it cannot be mixed with Try in one
    ' method, and new code should not use it.
    Function LegacyDivide(a As Integer, b As Integer) As String
        On Error GoTo Failed
        Dim result = a \ b
        Return "result " & result
Failed:
        Return $"Err.Number {Err.Number}: {Err.Description}"
    End Function

    Sub Section08_Errors()
        Title(8, "Errors and resources")

        ' Try / Catch / Finally as in C#. A Catch can have a When filter, which is evaluated
        ' before the stack is unwound; Visual Basic had filters long before C# 6.
        For Each candidate In {"42", "abc", "-5", "999"}
            Try
                Console.WriteLine($"age {ParseAge(candidate)}")
            Catch ex As ValidationException
                Console.WriteLine($"invalid {ex.Field}: {ex.Message}")
            Catch ex As ArgumentOutOfRangeException When CInt(ex.ActualValue) < 0
                Console.WriteLine("a negative age")
            Catch ex As ArgumentException
                Console.WriteLine($"{ex.GetType().Name} for the parameter '{ex.ParamName}'")
            End Try
        Next

        ' Throw without an argument rethrows and keeps the stack trace. C#: throw;
        Dim zero = 0
        Try
            Try
                Console.WriteLine(1 \ zero)
            Catch ex As DivideByZeroException
                Console.WriteLine("inner handler: " & ex.Message)
                Throw
            Finally
                Console.WriteLine("Finally always runs")
            End Try
        Catch ex As Exception
            Console.WriteLine("outer handler: " & ex.GetType().Name)
        End Try
        Console.WriteLine($"1 / 0 as Double: {1 / zero}")       ' floating point does not throw

        ' Using disposes its resources at End Using, also when an exception is thrown.
        ' (There is no `using` declaration without a block.)
        Using first As New Resource("A"), second As New Resource("B")
            Console.WriteLine("  working")
        End Using

        Console.WriteLine(LegacyDivide(7, 2) & " | " & LegacyDivide(1, 0))
    End Sub

    ' =============================================================================================
    '  9. LINQ and extension methods
    ' =============================================================================================

    Sub Section09_Linq()
        Title(9, "LINQ and extension methods")

        Dim people = {
            New Person("Ann", 31, "Munich"), New Person("Bob", 27, "Berlin"),
            New Person("Cid", 45, "Munich"), New Person("Dee", 38, "Vienna"),
            New Person("Eve", 27, "Berlin")
        }

        ' Query syntax. A Select with several items builds an anonymous type.
        Dim adults = From p In people
                     Where p.Age >= 30
                     Order By p.Age Descending, p.Name
                     Select p.Name, p.Age
        Console.WriteLine(String.Join(", ", adults.Select(Function(a) $"{a.Name} ({a.Age})")))

        ' The query syntax has more keywords than C#'s: Aggregate, Distinct, Skip, Take,
        ' Skip While, Take While.
        Dim totalAge = Aggregate p In people Into Sum(p.Age)
        Dim stats = Aggregate p In people Into Average(p.Age), Oldest = Max(p.Age), Count()
        Dim cities = From p In people Select p.City Distinct Order By City
        Dim page = From p In people Order By p.Name Skip 1 Take 3 Select p.Name
        Console.WriteLine($"{totalAge}; {stats.Average} {stats.Oldest} {stats.Count}; " &
                          $"{String.Join(" ", cities)}; {String.Join(" ", page)}")

        ' Group By ... Into names the aggregates; Group is the group itself.
        Dim byCity = From p In people
                     Group By p.City Into Residents = Count(), Oldest = Max(p.Age), Group
                     Order By City
        For Each entry In byCity
            Dim names = String.Join(" ", From p In entry.Group Select p.Name)
            Console.WriteLine($"  {entry.City}: {entry.Residents} resident(s), " &
                              $"the oldest is {entry.Oldest}: {names}")
        Next

        Dim offices = {(City:="Munich", Desks:=20), (City:="Berlin", Desks:=8)}
        Dim seated = From p In people
                     Join o In offices On p.City Equals o.City
                     Where p.Age > 30
                     Select $"{p.Name}@{o.City}"
        Console.WriteLine(String.Join(" ", seated))

        ' The method syntax is the same API as in C#, with Function(...) lambdas. Shout and
        ' Median are the extension methods declared in the module TextExtensions below.
        Dim youngest = people.OrderBy(Function(p) p.Age).ThenBy(Function(p) p.Name).First()
        Dim allAges = people.Select(Function(p) p.Age)
        Console.WriteLine($"{youngest.Name.Shout()} median age: {allAges.Median()}")
    End Sub

    ' =============================================================================================
    '  10. XML literals
    ' =============================================================================================

    Sub Section10_Xml()
        Title(10, "XML literals")

        ' XML is part of the expression syntax: a literal creates System.Xml.Linq objects, and
        ' <%= ... %> embeds a value or a whole query. C# has nothing like it.
        Dim day = "2026-11-17"
        Dim dishes = {(Name:="tea", Price:=3.5D), (Name:="cake", Price:=4.25D),
                      (Name:="soup", Price:=6D)}
        Dim menu = <menu date=<%= day %>>
                       <%= From dish In dishes
                           Select <dish name=<%= dish.Name %> price=<%= dish.Price %>/> %>
                       <note>cash only</note>
                   </menu>
        Console.WriteLine(menu)

        ' Axis properties read the tree: .<name> for children, ...<name> for descendants,
        ' .@name for an attribute (as a String).
        Dim expensive = From dish In menu.<dish>
                        Where CDec(dish.@price) > 4
                        Select dish.@name
        Console.WriteLine($"dishes: {menu.<dish>.Count()}; " &
                          $"expensive: {String.Join(", ", expensive)}; " &
                          $"note: {menu.<note>.Value}; date: {menu.@date}")

        ' The axis properties can be assigned as well.
        menu.<note>.Value = "cards accepted"
        menu.<dish>(0).@price = "3.75"
        Console.WriteLine(menu.<dish>(0).ToString() & " " & menu...<note>.Value)
    End Sub

    ' =============================================================================================
    '  11. Nothing and nullable values
    ' =============================================================================================

    Sub Section11_Nothing()
        Title(11, "Nothing and nullable values")

        ' Nothing is the default value of ANY type. C#: default
        Dim zero As Integer = Nothing
        Dim noDate As Date = Nothing
        Dim noText As String = Nothing
        Console.WriteLine($"{zero} {noDate:yyyy-MM-dd} {noText Is Nothing}")

        ' T? is Nullable(Of T), as in C#.
        Dim maybe As Integer? = Nothing
        Dim known As Integer? = 7
        Console.WriteLine($"{maybe.HasValue} {known.Value} {If(maybe, -1)} " &
                          $"{maybe.GetValueOrDefault()}")

        ' Operators on nullable values propagate Nothing — comparisons too. maybe > 5 is a
        ' Boolean? that is neither True nor False, the logic of SQL's NULL. C#: the comparison
        ' is simply false.
        Dim sum = maybe + known
        Dim comparison As Boolean? = maybe > 5
        Console.WriteLine($"the sum has a value: {sum.HasValue}; " &
                          $"the comparison has one: {comparison.HasValue}")
        If maybe > 5 Then
            Console.WriteLine("greater")
        Else
            Console.WriteLine("If takes Nothing for False: `not greater` and `unknown` look alike")
        End If
        ' If maybe = Nothing Then ...
        '     warning BC42037: This expression will always evaluate to Nothing. Write Is Nothing.
        Console.WriteLine($"Is Nothing: {maybe Is Nothing}; " &
                          $"Nothing And False: {comparison And False}; " &
                          $"Nothing Or True: {comparison Or True}")

        ' ?. and ?( ) stop at Nothing, as in C#.
        Dim people As List(Of Person) = Nothing
        Dim count = people?.Count                       ' Integer?
        Dim firstName = people?(0).Name                 ' String
        Console.WriteLine($"{count.HasValue} {If(firstName, "(none)")} {If(noText?.Length, 0)}")

        ' There are no nullable reference types (String?), so the compiler does not track
        ' which references may be Nothing. The = operator and the VB library functions treat a
        ' Nothing string as empty; .NET members do not:
        Console.WriteLine($"{noText = ""} {Len(noText)} {String.IsNullOrEmpty(noText)}")
        ' Console.WriteLine(noText.Length)              ' NullReferenceException at run time
    End Sub

    ' =============================================================================================
    '  12. Iterators, Async / Await, threads
    ' =============================================================================================

    ' An Iterator function produces its sequence lazily with Yield. C#: yield return
    Iterator Function Fibonacci() As IEnumerable(Of Long)
        Dim current = 0L, following = 1L
        Do
            Yield current
            Dim sum = current + following
            current = following
            following = sum
        Loop
    End Function

    ' Async and Await work as in C#. Nothing as a default value is C#'s `default`.
    Async Function FetchAsync(id As Integer, delayMs As Integer,
                              Optional token As CancellationToken = Nothing) As Task(Of String)
        Await Task.Delay(delayMs, token)
        Return $"item {id}"
    End Function

    Async Function Section12Async() As Task
        Dim first = Await FetchAsync(1, 30)
        Dim rest = Await Task.WhenAll(FetchAsync(2, 20), FetchAsync(3, 10))
        Console.WriteLine($"{first}; {String.Join(", ", rest)}")

        ' Cancellation arrives as an exception. Await is not allowed inside Catch, Finally or
        ' SyncLock (BC36943), so the handler only records what happened.
        Dim outcome = "pending"
        Using source As New CancellationTokenSource(20)
            Try
                outcome = Await FetchAsync(4, 5000, source.Token)
            Catch ex As OperationCanceledException
                outcome = "cancelled"
            End Try
        End Using
        Console.WriteLine(outcome)
    End Function

    Sub Section12_Async()
        Title(12, "Iterators, Async / Await, threads")

        Console.WriteLine(String.Join(" ", Fibonacci().Take(12)))
        ' A lambda can be an iterator as well.
        Dim countdown = Iterator Function()
                            For i = 3 To 1 Step -1
                                Yield i
                            Next
                        End Function
        Console.WriteLine(String.Join(" ", countdown()))

        ' Main cannot be Async in Visual Basic (BC30737), so the tour waits for the task here.
        Section12Async().GetAwaiter().GetResult()

        ' SyncLock is C#'s lock. Threads, tasks, Parallel and Interlocked are the .NET ones.
        Dim gate As New Object()
        Dim total = 0
        Dim atomic = 0L
        Parallel.For(1, 1001,
                     Sub(i)
                         SyncLock gate
                             total += i
                         End SyncLock
                         Interlocked.Add(atomic, i)
                     End Sub)
        Dim worker As New Thread(Sub() Interlocked.Increment(atomic))
        worker.Start()
        worker.Join()
        Console.WriteLine($"total {total}, atomic {atomic}")
    End Sub

    ' =============================================================================================
    '  13. The VB library, attributes, reflection
    ' =============================================================================================

    Sub Section13_Library()
        Title(13, "The VB library, attributes, reflection")

        ' Microsoft.VisualBasic is a part of .NET and is imported by default. Its functions
        ' come from the BASIC tradition, and positions in a string start at 1 in them.
        Dim text = "Visual Basic"
        Console.WriteLine($"{Len(text)} {Left(text, 6)} {Right(text, 5)} {Mid(text, 8, 3)} " &
                          $"{InStr(text, "Basic")} {UCase(text)} {StrReverse("abc")} " &
                          $"{StrDup(3, "x"c)} {Replace(text, " ", "_")}")
        Console.WriteLine($"{Val("12.5 kg")} {IsNumeric("1e3")} {Format(1234.5, "#,##0.00")} " &
                          $"{Hex(255)} " &
                          $"{DateDiff(DateInterval.Day, #2026-01-01#, #2026-11-17#)} " &
                          $"{DateAdd(DateInterval.Month, 1, #2026-01-31#):yyyy-MM-dd}")

        ' True converts to -1 with CInt, a relic of BASIC's bitwise logic; .NET itself says 1.
        Console.WriteLine($"CInt(True) = {CInt(True)}, " &
                          $"Convert.ToInt32(True) = {Convert.ToInt32(True)}")

        ' The My namespace (My.Computer, My.Application, My.Settings) offers shortcuts in Windows
        ' desktop projects. A plain console project such as this one does not get them:
        '     My.Computer.FileSystem.ReadAllText(path)
        '         BC30456: 'Computer' is not a member of 'VbTour.My'.

        ' Attributes are written in angle brackets, and their named arguments use :=.
        ' GetType(T) is C#'s typeof(T).
        Dim type = GetType(Greeter)
        Dim note = type.GetCustomAttribute(Of TourNoteAttribute)()
        Dim properties = From item In type.GetProperties() Select item.Name
        Console.WriteLine($"{type.FullName}: ""{note.Text}"", priority {note.Priority}; " &
                          $"properties: {String.Join(" ", properties)}")

        ' Late binding. With Option Strict Off a call on an Object is resolved at run time
        ' (C#: dynamic). With it On the same is spelled out with CallByName or with reflection.
        Dim target As Object = New Greeter()
        CallByName(target, "Greeting", CallType.Set, "Good day")
        Dim reply = CallByName(target, "Greet", CallType.Method, "Ann")
        Console.WriteLine($"{reply} | {NameOf(Greeter.Greet)}")

        ' Conditional compilation: #If tests #Const values and the constants of the project.
#If DEBUG Then
        Console.WriteLine("compiled in the Debug configuration")
#Else
        Console.WriteLine("compiled in the Release configuration")
#End If

        ' Native functions are declared with <DllImport> as in C#, or in the older style:
        '     Declare Function GetTickCount64 Lib "kernel32" () As ULong
    End Sub

    ' =============================================================================================
    '  14. Coming from VB6, and the newest
    ' =============================================================================================

    ' CallerArgumentExpression hands over the source text of an argument (understood since
    ' Visual Basic 17.0).
    Sub Check(condition As Boolean,
              <CallerArgumentExpression("condition")> Optional expression As String = Nothing)
        Console.WriteLine($"  check `{expression}`: {condition}")
    End Sub

    Sub Section14_Newest()
        Title(14, "Coming from VB6, and the newest")

        ' For readers who remember Visual Basic 6: the syntax is familiar, the rules changed.
        '   - Integer has 32 bits and Long 64 (VB6: 16 and 32). Currency became Decimal, and
        '     Variant became Object.
        '   - Arrays always start at 0: there is no Option Base 1 and no Dim a(1 To 5).
        '   - Arguments are passed ByVal unless ByRef is written (VB6: ByRef by default).
        '   - Objects are assigned without Set, and there are no parameterless default
        '     properties: Text1 = "x" no longer means Text1.Text = "x".
        '   - Memory is garbage-collected. There is no Class_Terminate at the last release;
        '     use IDisposable and Using.
        '   - Calls need parentheses, While ends with End While instead of Wend, and GoSub,
        '     DefInt, fixed-length strings and Debug.Print are gone.
        '   - On Error still compiles (section 8), but Try / Catch is the way.

        ' The language is stable by design: it is kept working with every new .NET, and it
        ' gets almost no new syntax. Its last additions:
        '   14      ?. and NameOf, string interpolation, read-only auto-properties
        '   15.x    tuples, binary literals, digit separators, Private Protected, named
        '           arguments in front of positional ones
        '   16.x    comments after a line continuation; init-only properties can be set (16.9)
        '   17.0    CallerArgumentExpression
        '   17.13   the `unmanaged` constraint and OverloadResolutionPriority are understood
        Dim flags = &B1010_0101
        Dim million = 1_000_000
        Dim options = New JsonNodeOptions With {.PropertyNameCaseInsensitive = True}    ' init-only
        Console.WriteLine($"{flags} {million} {options.PropertyNameCaseInsensitive} " &
                          $"{Power(base:=5, 2)}")
        Check(million > flags)
        Check(NameOf(Section14_Newest).Length = 16)

        ' What C# has and Visual Basic does not: pattern matching, records, deconstruction,
        ' local functions, `out var`, ranges and indices, nullable reference types, unsafe
        ' code, async streams, Async Main, top-level statements and single-file programs.
        ' A ref struct cannot be used at all:
        '     Dim span As Span(Of Integer) = numbers.AsSpan()
        '         BC30668: 'Span(Of Integer)' is obsolete: 'Types with embedded references are
        '         not supported in this version of your compiler.'
    End Sub

End Module

' =================================================================================================
'  Types for section 5
' =================================================================================================

' Access levels: Public, Friend (C#: internal), Protected, Private, Protected Friend and
' Private Protected. A type without a modifier is Friend. A member without one is Public —
' C#: private — except a field declared with Dim in a class, which is Private.

Enum Level
    Junior                                              ' 0
    Middle
    Senior
End Enum

<Flags>
Enum Access As Byte                                     ' the underlying type follows As
    None = 0
    Read = 1
    Write = 2
    Execute = 4
End Enum

Class Account
    Private _balance As Decimal                         ' a field

    Public ReadOnly Property Owner As String            ' read-only: assigned in the constructor
    Public Property Note As String = "none"             ' an auto-property with an initial value
    Public Shared ReadOnly Property Opened As Integer   ' Shared is C#'s static

    ' The constructor is called New. Me is C#'s this.
    Public Sub New(owner As String, Optional opening As Decimal = 0D)
        Me.Owner = owner
        _balance = opening
        _Opened += 1            ' an auto-property P has a hidden backing field named _P
    End Sub

    ' A property written out in full. An accessor may narrow the access level.
    Public Property Balance As Decimal
        Get
            Return _balance
        End Get
        Private Set(value As Decimal)
            If value < 0 Then Throw New InvalidOperationException("insufficient funds")
            _balance = value
        End Set
    End Property

    Public Sub Deposit(amount As Decimal)
        Balance += amount
    End Sub

    Public Sub Withdraw(amount As Decimal)
        Balance -= amount
    End Sub

    Public Overrides Function ToString() As String
        Return $"{Owner}: {Balance:F2} ({Note})"
    End Function
End Class

' A Structure is a value type (C#: struct). Operators are Shared procedures named Operator.
Structure Vector
    Public ReadOnly X As Double
    Public ReadOnly Y As Double

    Public Sub New(x As Double, y As Double)
        Me.X = x                                        ' the parameter hides the field of the
        Me.Y = y                                        ' same (case-insensitive) name
    End Sub

    Public ReadOnly Property Length As Double
        Get
            Return Math.Sqrt(X * X + Y * Y)
        End Get
    End Property

    Public Shared Operator +(a As Vector, b As Vector) As Vector
        Return New Vector(a.X + b.X, a.Y + b.Y)
    End Operator

    Public Shared Operator *(v As Vector, factor As Double) As Vector
        Return New Vector(v.X * factor, v.Y * factor)
    End Operator

    Public Shared Operator =(a As Vector, b As Vector) As Boolean      ' = and <> come in pairs
        Return a.X = b.X AndAlso a.Y = b.Y
    End Operator

    Public Shared Operator <>(a As Vector, b As Vector) As Boolean
        Return Not a = b                                ' Not binds looser than =: Not (a = b)
    End Operator

    ' Conversions: Widening is C#'s implicit, Narrowing is C#'s explicit.
    Public Shared Widening Operator CType(v As Vector) As String
        Return $"({v.X}, {v.Y})"
    End Operator

    Public Shared Narrowing Operator CType(v As Vector) As Double
        Return v.Length
    End Operator
End Structure

' =================================================================================================
'  Types for section 6
' =================================================================================================

' MustInherit is C#'s abstract class, MustOverride an abstract member, Overridable is virtual,
' Overrides is override, NotOverridable is a sealed override, NotInheritable a sealed class.
' Also: Shadows hides a base member by name (C#: new), Partial splits a type over files, and
' MyClass.Method() calls this class's own version of an Overridable method.
MustInherit Class Shape
    Public MustOverride Function Area() As Double

    Public Overridable Function Describe() As String
        Return $"{Kind()} with the area {Area():F2}"
    End Function

    ' Private Protected: visible to derived classes of this assembly only.
    Private Protected Function Kind() As String
        Return Me.GetType().Name
    End Function
End Class

NotInheritable Class Circle
    Inherits Shape                                      ' Inherits stands on a line of its own

    Public ReadOnly Property Radius As Double

    Public Sub New(radius As Double)
        Me.Radius = radius
    End Sub

    Public Overrides Function Area() As Double
        Return Math.PI * Radius ^ 2
    End Function
End Class

Interface ILabelled
    ReadOnly Property Label As String
End Interface

Class Rectangle
    Inherits Shape
    Implements IComparable(Of Rectangle), ILabelled

    Public ReadOnly Property Width As Double
    Public ReadOnly Property Height As Double

    Public Sub New(width As Double, height As Double)
        Me.Width = width
        Me.Height = height
    End Sub

    Public Overrides Function Area() As Double
        Return Width * Height
    End Function

    Public Overrides Function Describe() As String
        Return "a rectangle: " & MyBase.Describe()      ' MyBase is C#'s base
    End Function

    ' An Implements clause ties a member to an interface member explicitly, so the names need
    ' not match. A Private member with Implements is C#'s explicit interface implementation.
    Public Function CompareByArea(other As Rectangle) As Integer _
        Implements IComparable(Of Rectangle).CompareTo
        Return Area().CompareTo(other.Area())
    End Function

    Private ReadOnly Property SizeLabel As String Implements ILabelled.Label
        Get
            Return $"{Width}x{Height}"
        End Get
    End Property
End Class

Class Thermometer
    ' An event declared with a parameter list gets its delegate type from the compiler ...
    Public Event Overheated(source As Thermometer, degrees As Double)
    ' ... or it names a delegate type, as in C#.
    Public Event Changed As EventHandler(Of Double)

    Public Sub Report(degrees As Double)
        RaiseEvent Changed(Me, degrees)                 ' no check for Nothing is needed
        If degrees > 100 Then RaiseEvent Overheated(Me, degrees)
    End Sub
End Class

Class Alarm
    ' A WithEvents field lets methods subscribe with a Handles clause. Assigning another
    ' thermometer to the field moves the subscriptions to it.
    Private WithEvents _sensor As Thermometer

    Public ReadOnly Property Log As New List(Of String)

    Public Sub New(sensor As Thermometer)
        _sensor = sensor
    End Sub

    Private Sub OnOverheated(source As Thermometer, degrees As Double) Handles _sensor.Overheated
        Log.Add($"too hot at {degrees}")
    End Sub
End Class

' =================================================================================================
'  Types for section 7
' =================================================================================================

' Type parameters are written (Of T). C#: class TinyStack<T> : IEnumerable<T>
Class TinyStack(Of T)
    Implements IEnumerable(Of T)

    Private ReadOnly _items As New List(Of T)

    Public ReadOnly Property Count As Integer
        Get
            Return _items.Count
        End Get
    End Property

    Public Sub Push(item As T)
        _items.Add(item)
    End Sub

    Public Function Pop() As T
        If _items.Count = 0 Then Throw New InvalidOperationException("the stack is empty")
        Dim top = _items(_items.Count - 1)
        _items.RemoveAt(_items.Count - 1)
        Return top
    End Function

    ' A Default property is an indexer: stack(0). C#: public T this[int index]
    Default Public ReadOnly Property Item(index As Integer) As T
        Get
            Return _items(_items.Count - 1 - index)
        End Get
    End Property

    Public Function GetEnumerator() As IEnumerator(Of T) Implements IEnumerable(Of T).GetEnumerator
        Return Enumerable.Reverse(_items).GetEnumerator()
    End Function

    Private Function GetUntypedEnumerator() As IEnumerator Implements IEnumerable.GetEnumerator
        Return GetEnumerator()
    End Function
End Class

' Variance is declared with Out and In, as in C#.
Interface IProducer(Of Out T)
    Function Produce() As T
End Interface

Class CircleFactory
    Implements IProducer(Of Circle)

    Public Function Produce() As Circle Implements IProducer(Of Circle).Produce
        Return New Circle(2)
    End Function
End Class

' =================================================================================================
'  Types for sections 8, 9 and 13
' =================================================================================================

Class ValidationException
    Inherits Exception

    Public ReadOnly Property Field As String

    Public Sub New(field As String, message As String)
        MyBase.New(message)                             ' the base constructor is called first
        Me.Field = field
    End Sub
End Class

Class Resource
    Implements IDisposable

    Private ReadOnly _name As String

    Public Sub New(name As String)
        _name = name
        Console.WriteLine($"  open {_name}")
    End Sub

    Public Sub Dispose() Implements IDisposable.Dispose
        Console.WriteLine($"  close {_name}")
    End Sub
End Class

Class Person
    Public ReadOnly Property Name As String
    Public ReadOnly Property Age As Integer
    Public ReadOnly Property City As String

    Public Sub New(name As String, age As Integer, city As String)
        Me.Name = name
        Me.Age = age
        Me.City = city
    End Sub
End Class

' Extension methods live in a Module and carry <Extension>; the first parameter is the
' receiver. C#: a static class and `this`.
Module TextExtensions
    <Extension>
    Function Shout(text As String) As String
        Return text.ToUpperInvariant() & "!"
    End Function

    <Extension>
    Function Median(values As IEnumerable(Of Integer)) As Double
        Dim sorted = values.OrderBy(Function(v) v).ToArray()
        Dim middle = sorted.Length \ 2
        If sorted.Length Mod 2 = 1 Then Return sorted(middle)
        Return (sorted(middle - 1) + sorted(middle)) / 2
    End Function
End Module

' An attribute is a class that inherits Attribute. C#: [AttributeUsage(...)]
<AttributeUsage(AttributeTargets.Class)>
Class TourNoteAttribute
    Inherits Attribute

    Public ReadOnly Property Text As String
    Public Property Priority As Integer

    Public Sub New(text As String)
        Me.Text = text
    End Sub
End Class

<TourNote("a class with an attribute", Priority:=2)>
Class Greeter
    Public Property Greeting As String = "Hello"

    Public Function Greet(name As String) As String
        Return $"{Greeting}, {name}!"
    End Function
End Class
