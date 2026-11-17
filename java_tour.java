// =================================================================================================
//  JAVA FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
//
//  Run (JDK 25 or newer; no project and no separate compilation step):
//      java java_tour.java
//
//  Verified with OpenJDK 25.0.5.
//
//  This is a "compact source file" (Java 25): methods and `void main()` stand at the top
//  level, much like C# top-level statements. The compiler wraps the file in an implicit
//  class and imports the whole java.base module (java.util, java.util.function,
//  java.util.stream, java.time, java.nio.file ...), which is why there are no import lines.
//  The traditional shape of the same program is
//
//      package tour;                              // C#: namespace
//      import java.util.*;                        // C#: using
//      public class JavaTour {                    // one public class per file: JavaTour.java
//          public static void main(String[] args) { ... }
//      }
//
//  compiled with `javac` and started with `java tour.JavaTour`.
//
//  How to read. Each section is a method `sectionNN...`; the types a section needs are
//  declared right before it; `main()` at the end calls the sections in order. A "C#:" note
//  shows the closest C# counterpart. Commented-out lines show what the compiler rejects.
//
//  Java and C# are close relatives: a managed runtime (the JVM), garbage collection, single
//  inheritance plus interfaces, generics, lambdas. Most C# knowledge carries over; this is
//  what does not:
//
//   1. No value types yet. Apart from eight primitives (int, double, boolean ...) everything
//      is a reference type on the heap: no struct, no ref/out parameters, no unsigned ints.
//   2. Generics are erased. `List<String>` and `List<Integer>` are one class at run time,
//      and a primitive cannot be a type argument: there is no List<int>, only List<Integer>.
//   3. `==` on objects compares references — for strings too. Content is compared with
//      equals(). There is no operator overloading.
//   4. Checked exceptions: a method must either handle or declare (`throws`) them.
//   5. No properties, events, delegates, extension methods, async/await or string
//      interpolation. Their jobs are done by accessor methods and records, functional
//      interfaces, streams, and virtual threads.
//   6. Methods are virtual unless marked `final`; classes are inheritable unless `final` or
//      `sealed`. Members without a modifier are package-private (roughly C# internal).
//   7. Naming: methodsAndVariables in camelCase, Types in PascalCase, CONSTANTS in upper
//      case, packages in lower case.
//
//  Contents:
//    1. Basics: primitives, strings, arrays, control flow     7. Exceptions and resources
//    2. Classes, records, enums                               8. Pattern matching
//    3. Inheritance and interfaces                            9. Text, numbers, time, files
//    4. Generics                                             10. Concurrency
//    5. Lambdas and functional interfaces                    11. Reflection and annotations
//    6. Collections and streams                              12. The newest: Java 21 - 25
// =================================================================================================

// Top-level fields and methods are members of the implicit class.
static final int MAX_POINTS = 100_000; // C#: const

void header(String title) {
    IO.println("\n=== " + title + " ==="); // IO.println (Java 25) is short for System.out.println
}

// Formatting is locale-sensitive, as in C#: Locale.ROOT keeps the output the same everywhere.
static String fmt(String format, Object... args) { // varargs. C#: params object[]
    return String.format(Locale.ROOT, format, args);
}

void say(String format, Object... args) {
    IO.println(fmt(format, args));
}

// =================================================================================================
//  1. BASICS: primitives, strings, arrays, control flow
// =================================================================================================

void section01Basics() {
    header("1. Basics");

    // --- Primitive types: fixed sizes on every platform, and no unsigned variants ---
    int a = 42;                 // 32 bits
    long big = 9_000_000_000L;  // 64 bits
    double d = 3.5;
    float f = 2.5f;
    char letter = 'A';          // a 16-bit UTF-16 code unit, as in C#
    boolean flag = true;        // `boolean`, not `bool`
    byte b = (byte) 0xFF;       // a byte is SIGNED: this is -1
    var inferred = 2.5 * a;     // local type inference. C#: var
    say("%d %d %.1f %.1f %c %b %d %.1f", a, big, d, f, letter, flag, b, inferred);

    // Every primitive has a wrapper class (Integer, Double ...) for places that need an
    // object; the conversion ("boxing") is automatic. `==` on wrappers compares REFERENCES:
    // small values come from a cache and look equal, larger ones do not.
    Integer boxed = a;
    Integer small1 = 127, small2 = 127, large1 = 1000, large2 = 1000;
    say("boxed %d | 127 == 127: %b | 1000 == 1000: %b | equals: %b", boxed, small1 == small2,
            large1 == large2, large1.equals(large2));

    // --- Conversions and overflow ---
    double ratio = a / 5;       // integer division first: 8.0
    int truncated = (int) 3.99; // an explicit cast: 3
    long widened = a;           // widening is implicit
    // int narrowed = 3.7;      // error: incompatible types: possible lossy conversion
    int wrapped = Integer.MAX_VALUE + 1; // overflow wraps silently; there is no `checked`
    say("%.1f %d %d %d | -7 / 2 = %d, -7 %% 2 = %d | %d %d", ratio, truncated, widened, wrapped,
            -7 / 2, -7 % 2, -16 >> 2, -16 >>> 28); // >>> is the unsigned right shift
    try {
        Math.addExact(Integer.MAX_VALUE, 1); // the checked alternative
    } catch (ArithmeticException e) {
        say("Math.addExact: %s", e.getMessage());
    }

    // --- Strings: immutable, UTF-16, compared with equals() ---
    String name = "World";
    String greeting = "Hello, " + name + "!"; // no string interpolation in Java
    String formatted = "%s has %d chars".formatted(greeting, greeting.length());
    String built = new String("Hello"); // a distinct object with the same text
    say("%s | %s | %s | %s", greeting, formatted, greeting.toUpperCase(),
            greeting.substring(7, 12));
    say("== %b | equals %b | equalsIgnoreCase %b | compareTo %d", built == "Hello",
            built.equals("Hello"), built.equalsIgnoreCase("HELLO"), "apple".compareTo("banana"));
    String block = """
            {"kind": "text block", "escaping": "not needed"}
            """; // a text block: the common indentation is removed. C#: raw string literal
    var builder = new StringBuilder("["); // C#: StringBuilder
    for (int i = 1; i <= 5; i++) builder.append(i).append(i < 5 ? ", " : "]");
    say("%s | %s | %s | %b | %s", block.strip(), builder, String.join("-", "a", "b", "c"),
            "  ".isBlank(), "ab".repeat(3));
    String mixed = "aß😀";
    say("UTF-16 units %d, code points %d", mixed.length(), mixed.codePointCount(0, mixed.length()));

    // --- Arrays: objects with a fixed length; every access is bounds-checked ---
    int[] primes = {2, 3, 5, 7, 11};
    int[] alias = primes; // a second reference to the SAME array
    alias[0] = 99;
    int[] copy = Arrays.copyOf(primes, 3);
    int[][] jagged = {{1}, {2, 3}, {4, 5, 6}}; // arrays of arrays; no rectangular arrays
    say("%d %s %d %d %b", primes[0], Arrays.toString(copy), primes.length, jagged[2][1],
            Arrays.equals(copy, new int[]{99, 3, 5}));
    try {
        int _ = primes[10]; // `_` is an unnamed variable (Java 22)
    } catch (ArrayIndexOutOfBoundsException e) {
        say("caught: %s", e.getMessage());
    }

    // --- Control flow: as in C#, with a few twists ---
    int sum = 0;
    for (int i = 0; i < 5; i++) sum += i;
    for (int p : primes) sum += p; // the enhanced for. C#: foreach
    outer: // a label: break and continue can target an outer loop
    for (int row = 0; row < 3; row++) {
        for (int col = 0; col < 3; col++) {
            if (col > row) continue outer;
            if (row + col == 3) break outer;
            sum += 100;
        }
    }

    // switch as an expression: arrows, no fall-through, and it must cover every case.
    String kind = switch (letter) {
        case 'A', 'E', 'I', 'O', 'U' -> "vowel";
        case 'Y' -> {
            String note = "sometimes a vowel";
            yield note; // `yield` returns a value from a block
        }
        default -> "consonant";
    };
    // The old statement form (`case 'A': ... break;`) still exists and DOES fall through.
    String parity = (sum % 2 == 0) ? "even" : "odd";
    say("sum %d is %s, '%c' is a %s, MAX_POINTS %d", sum, parity, letter, kind, MAX_POINTS);
}

// =================================================================================================
//  2. CLASSES, RECORDS, ENUMS
// =================================================================================================

/// A class. In a compact source file every type declared here is nested in the implicit
/// top-level class, and `static` makes a nested class independent of an enclosing instance
/// (C# nested classes always behave that way). `Counter.Step` below shows the other kind.
/// (Three slashes start a Markdown documentation comment, Java 23. C#: `///` XML comments.)
static class Account {
    private static int created = 0; // one per class. C#: static field
    private final String owner;     // final: assigned exactly once. C#: readonly
    private double balance;

    Account(String owner, double balance) { // no modifier: package-private
        this.owner = owner;
        this.balance = balance;
        created++;
    }

    Account(String owner) {
        this(owner, 0.0); // constructor chaining. C#: `: this(owner, 0.0)`
    }

    // There are no properties: the convention is accessor methods.
    String getOwner() { return owner; }

    double getBalance() { return balance; }

    void deposit(double amount) {
        if (amount <= 0) throw new IllegalArgumentException("amount must be positive");
        balance += amount;
    }

    static int getCreated() { return created; }

    // Every class extends Object; these three methods are the ones to override.
    @Override
    public boolean equals(Object other) {
        return other instanceof Account that && owner.equals(that.owner);
    }

    @Override
    public int hashCode() { return owner.hashCode(); }

    @Override
    public String toString() { return fmt("Account[%s, %.2f]", owner, balance); }
}

/// A record: an immutable data carrier. The compiler generates the constructor, the
/// accessors x() and y(), equals, hashCode and toString. C#: record.
record Point(double x, double y) {
    static final Point ORIGIN = new Point(0, 0);

    Point { // a compact constructor: validation before the fields are assigned
        if (Double.isNaN(x) || Double.isNaN(y)) throw new IllegalArgumentException("NaN");
    }

    double distanceTo(Point other) { return Math.hypot(x - other.x, y - other.y); }

    Point withX(double newX) { return new Point(newX, y); } // no `with` expression in Java
}

/// An enum is a full class with a fixed set of instances: fields, a constructor, methods.
enum Planet {
    MERCURY(3.303e+23, 2.4397e6),
    EARTH(5.976e+24, 6.37814e6),
    JUPITER(1.9e+27, 7.1492e7);

    private final double mass, radius;

    Planet(double mass, double radius) {
        this.mass = mass;
        this.radius = radius;
    }

    double surfaceGravity() { return 6.67300E-11 * mass / (radius * radius); }
}

/// Each constant can even carry its own implementation of a method.
enum Operation {
    ADD("+") {
        int apply(int a, int b) { return a + b; }
    },
    MULTIPLY("*") {
        int apply(int a, int b) { return a * b; }
    };

    final String symbol;

    Operation(String symbol) { this.symbol = symbol; }

    abstract int apply(int a, int b);
}

/// An inner (non-static) class keeps a hidden reference to the outer object that created
/// it. C#: no counterpart; there the outer object would be passed explicitly.
static class Counter {
    private int value;

    class Step {
        void forward() { value++; } // reaches the private field of the outer instance
    }

    Step step() { return new Step(); }

    int value() { return value; }
}

void section02Classes() {
    header("2. Classes, records, enums");

    var account = new Account("Ann", 150.5); // always on the heap; there is no `delete`
    account.deposit(50);
    Account same = account; // copies the reference, not the object
    same.deposit(1);
    say("%s %s %.1f %d", account, account.getOwner(), account.getBalance(), Account.getCreated());
    var twin = new Account("Ann");
    say("== %b | equals %b | same hash %b", account == twin, account.equals(twin),
            account.hashCode() == twin.hashCode());
    Account nobody = null; // any reference may be null; the type system does not track it
    try {
        nobody.deposit(1);
    } catch (NullPointerException e) { // C#: NullReferenceException
        say("caught a NullPointerException");
    }

    var p = new Point(3, 4);
    say("%s | %.1f | %s | %b | %.1f", p, p.distanceTo(Point.ORIGIN), p.withX(30),
            p.equals(new Point(3, 4)), p.x());

    say("%s %d %s %.2f %s", Planet.EARTH, Planet.EARTH.ordinal(), Arrays.toString(Planet.values()),
            Planet.EARTH.surfaceGravity(), Planet.valueOf("JUPITER").name());
    var line = new StringBuilder();
    for (var op : Operation.values()) line.append(fmt("6 %s 7 = %d  ", op.symbol, op.apply(6, 7)));
    IO.println(line.toString().strip());
    var visited = EnumSet.of(Planet.MERCURY, Planet.EARTH); // C#: a [Flags] enum
    var moons = new EnumMap<Planet, Integer>(Planet.class);
    moons.put(Planet.EARTH, 1);
    say("%s %s", visited, moons);

    var counter = new Counter();
    Counter.Step step = counter.step();
    step.forward();
    step.forward();
    say("the inner object moved its outer counter to %d", counter.value());
}

// =================================================================================================
//  3. INHERITANCE AND INTERFACES
// =================================================================================================

static abstract class Shape { // C#: abstract class
    private final String name;

    protected Shape(String name) { this.name = name; }

    abstract double area(); // C#: abstract

    String describe() { // virtual by default; `final` would forbid overriding
        return fmt("%s with area %.2f", name, area());
    }
}

static class Circle extends Shape { // C#: class Circle : Shape
    private final double radius;

    Circle(double radius) {
        super("circle"); // C#: `: base("circle")`
        this.radius = radius;
    }

    @Override // optional, but always written: the compiler then checks that it overrides
    double area() { return Math.PI * radius * radius; }
}

static class Rectangle extends Shape {
    protected final double width, height;

    Rectangle(double width, double height) { this("rectangle", width, height); }

    protected Rectangle(String name, double width, double height) {
        super(name);
        this.width = width;
        this.height = height;
    }

    @Override
    double area() { return width * height; }
}

static final class Square extends Rectangle { // final: cannot be extended. C#: sealed
    Square(double side) { super("square", side, side); }

    @Override
    String describe() { return "a perfect " + super.describe(); } // C#: base.Describe()
}

/// An interface: a contract. A class extends one class and implements any number of
/// interfaces.
interface Drawable {
    String draw(); // implicitly public and abstract

    default String drawTwice() { // a default method: an implementation inside the interface
        return draw() + " " + draw();
    }

    static Drawable of(String text) { // a static factory method
        return () -> text; // an interface with ONE abstract method can be a lambda
    }
}

interface Exportable {
    String export();
}

static class Label implements Drawable, Exportable {
    private final String text;

    Label(String text) { this.text = text; }

    @Override
    public String draw() { return "[" + text + "]"; } // interface methods are public

    @Override
    public String export() { return "{\"label\": \"" + text + "\"}"; }
}

static class Base {
    Base() { IO.println("  Base() sees: " + describe()); }

    String describe() { return "Base"; }
}

static class Derived extends Base {
    private String tag = "set";

    @Override
    String describe() { return "Derived, tag = " + tag; }
}

void section03Inheritance() {
    header("3. Inheritance and interfaces");

    List<Shape> shapes = List.of(new Circle(1), new Rectangle(2, 3), new Square(2));
    for (Shape shape : shapes) IO.println("  " + shape.describe());
    // new Shape("x");   // error: Shape is abstract; cannot be instantiated

    Shape first = shapes.get(0); // no indexer syntax for collections: get(i)
    if (first instanceof Circle circle) { // a type test that declares a variable. C#: is Circle c
        say("the first shape is a circle of area %.2f", circle.area());
    }
    say("%b %b %s", shapes.get(2) instanceof Rectangle, shapes.get(1) instanceof Square,
            shapes.get(2).getClass().getSimpleName());

    var label = new Label("ok");
    Drawable drawable = label;
    say("%s | %s | %s | %s", label.draw(), drawable.drawTwice(), label.export(),
            Drawable.of("lambda").drawTwice());

    // An anonymous class: a one-off implementation defined where it is used. Before lambdas
    // this was the only way to pass behaviour, and old code is full of it.
    Drawable anonymous = new Drawable() {
        private int calls;

        @Override
        public String draw() { return "call " + ++calls; }
    };
    say("%s", anonymous.drawTwice());

    // Types can be declared inside a method as well.
    record Pair(String left, String right) {}
    say("%s", new Pair("a", "b"));

    // Initialization order: the base constructor runs BEFORE the field initializers of the
    // subclass, so a virtual call from it sees `tag` still null. (C# runs the field
    // initializers first and would print "set".)
    new Derived();
}

// =================================================================================================
//  4. GENERICS
// =================================================================================================

/// A generic class. C#: class Stack<T>. T exists only at compile time ("type erasure").
static class Stack<T> implements Iterable<T> {
    private final ArrayList<T> items = new ArrayList<>(); // `<>`: the arguments are inferred

    Stack<T> push(T item) {
        items.add(item);
        return this;
    }

    T pop() {
        if (items.isEmpty()) throw new NoSuchElementException("the stack is empty");
        return items.removeLast();
    }

    Optional<T> peek() { // Optional: "a value or nothing" as a return type
        return items.isEmpty() ? Optional.empty() : Optional.of(items.getLast());
    }

    int size() { return items.size(); }

    @Override
    public Iterator<T> iterator() { return items.reversed().iterator(); } // enables for-each
}

/// A generic method with a bounded type parameter. C#: where T : IComparable<T>.
static <T extends Comparable<? super T>> T maxOf(List<? extends T> items) {
    T best = items.get(0);
    for (T item : items) if (item.compareTo(best) > 0) best = item;
    return best;
}

/// Wildcards give variance at the point of USE ("producer extends, consumer super"):
/// a `Collection<? extends Number>` can be read as Numbers, a `List<? super Integer>` can
/// take Integers. C#: variance is declared once, on the interface (`out T`, `in T`).
static double sumOf(Collection<? extends Number> numbers) {
    double total = 0;
    for (Number n : numbers) total += n.doubleValue();
    return total;
}

static void fill(List<? super Integer> target, int count) {
    for (int i = 1; i <= count; i++) target.add(i);
}

void section04Generics() {
    header("4. Generics");

    var stack = new Stack<String>().push("a").push("b").push("c");
    say("%s %s %d %s", stack.pop(), stack.peek().orElse("empty"), stack.size(),
            String.join(" ", stack));

    say("%d %s %.1f", maxOf(List.of(3, 9, 4)), maxOf(List.of("pear", "fig")),
            sumOf(List.of(1, 2.5, 3L)));
    List<Number> numbers = new ArrayList<>();
    fill(numbers, 3);
    List<Object> objects = new ArrayList<>();
    fill(objects, 2);
    say("%s %s", numbers, objects);

    // Type arguments must be reference types: List<int> does not exist, List<Integer> boxes.
    List<Integer> boxes = new ArrayList<>(List.of(10, 20, 30));
    boxes.remove(Integer.valueOf(10)); // remove(Object): removes the VALUE 10
    boxes.remove(0);                   // remove(int): removes INDEX 0 — an overload trap
    say("%s", boxes);

    // Erasure: at run time both lists have the same class, and T cannot be inspected.
    List<String> strings = new ArrayList<>();
    say("same class: %b (%s)", strings.getClass() == boxes.getClass(),
            strings.getClass().getSimpleName());
    // if (objects instanceof List<String>) ...   // error: cannot be safely cast
    // T[] array = new T[10];                      // error: generic array creation

    // Arrays are covariant and checked at run time; generics are invariant and checked at
    // compile time.
    Object[] array = new String[1];
    try {
        array[0] = 42;
    } catch (ArrayStoreException e) {
        say("ArrayStoreException: %s", e.getMessage());
    }
    // List<Object> list = new ArrayList<String>();   // error: incompatible types
}

// =================================================================================================
//  5. LAMBDAS AND FUNCTIONAL INTERFACES
// =================================================================================================

@FunctionalInterface // optional: asks the compiler to enforce "exactly one abstract method"
interface BinaryOp {
    int apply(int a, int b);
}

Function<Integer, Integer> makeAdder(int n) { // returns a closure over n
    return x -> x + n;
}

void section05Lambdas() {
    header("5. Lambdas and functional interfaces");

    // Java has no delegate types. A lambda converts to any interface with a single abstract
    // method; java.util.function supplies the common shapes (C#: Func<>, Action<>).
    BinaryOp add = (a, b) -> a + b;
    BinaryOp multiply = (a, b) -> {
        int product = a * b;
        return product;
    };
    Function<Integer, Integer> twice = x -> x * 2;        // C#: Func<int, int>
    BiFunction<Integer, Integer, Integer> power = (x, y) -> (int) Math.pow(x, y);
    Supplier<String> supplier = () -> "supplied";         // C#: Func<string>
    Consumer<String> printer = text -> IO.println("consumed " + text); // C#: Action<string>
    Predicate<String> isEmpty = String::isEmpty;          // C#: Predicate<string>
    UnaryOperator<String> upper = String::toUpperCase;
    IntBinaryOperator max = Math::max; // primitive specializations avoid boxing
    say("%d %d %d %d %s %b %s %d", add.apply(2, 3), multiply.apply(2, 3), twice.apply(21),
            power.apply(2, 10), supplier.get(), isEmpty.test(""), upper.apply("abc"),
            max.applyAsInt(3, 9));
    printer.accept("text");

    // Method references come in four kinds.
    Function<String, Integer> parse = Integer::parseInt;  // a static method
    Function<String, String> greet = "Hello, "::concat;   // a method of one particular object
    Function<String, Integer> length = String::length;    // a method of the argument itself
    Supplier<List<String>> factory = ArrayList::new;      // a constructor
    say("%d | %s | %d | %s", parse.apply("42"), greet.apply("Bob"), length.apply("four"),
            factory.get());

    // Composition comes from default methods of the functional interfaces.
    Function<Integer, Integer> plusOneTimesTwo = makeAdder(1).andThen(twice);
    Predicate<String> notEmpty = isEmpty.negate();
    Comparator<String> byLengthThenAlphabet =
            Comparator.comparing(String::length).thenComparing(Comparator.naturalOrder());
    var words = new ArrayList<>(List.of("pear", "fig", "banana", "kiwi"));
    words.sort(byLengthThenAlphabet);
    say("%d %b %s", plusOneTimesTwo.apply(4), notEmpty.test("x"), words);

    // A lambda may capture a local variable only if it is "effectively final" (never
    // reassigned). C# closures capture the variable itself and may modify it.
    int base = 10;
    Supplier<Integer> capture = () -> base + 1;
    // base++;   // error: local variables referenced from a lambda expression must be final
    int[] box = {0}; // the usual workaround: a mutable holder
    Runnable increment = () -> box[0]++;
    increment.run();
    increment.run();
    say("%d %d", capture.get(), box[0]);
}

// =================================================================================================
//  6. COLLECTIONS AND STREAMS
// =================================================================================================

record Employee(String name, String department, double salary, int age) {}

void section06Collections() {
    header("6. Collections and streams");

    // --- Lists. Interfaces (List, Map, Set) are kept apart from implementations ---
    List<Integer> list = new ArrayList<>(List.of(5, 3, 8)); // C#: List<int>
    list.add(1);
    list.addFirst(9); // sequenced collections (Java 21)
    Collections.sort(list);
    say("%s | first %d | last %d | reversed %s | contains(8) %b", list, list.getFirst(),
            list.getLast(), list.reversed(), list.contains(8));
    List<String> fixed = List.of("a", "b"); // immutable
    try {
        fixed.add("c");
    } catch (UnsupportedOperationException e) {
        say("List.of() is immutable, but only at run time: the type is still List");
    }

    // --- Maps and sets ---
    Map<String, Integer> stock = new HashMap<>(Map.of("bolt", 10, "nut", 5)); // C#: Dictionary
    stock.put("screw", 25);
    stock.merge("bolt", 5, Integer::sum); // insert, or combine with the existing value
    stock.putIfAbsent("nut", 999);
    // get() returns null for a missing key. C#: KeyNotFoundException, or TryGetValue.
    say("%d %s %d %s", stock.get("bolt"), stock.get("missing"), stock.getOrDefault("missing", 0),
            new TreeMap<>(stock)); // TreeMap: sorted by key. C#: SortedDictionary
    Map<Character, Integer> counts = new TreeMap<>();
    for (char ch : "mississippi".toCharArray()) counts.merge(ch, 1, Integer::sum);
    Set<Integer> odd = new TreeSet<>(Set.of(1, 3, 5, 7, 9));
    odd.retainAll(Set.of(2, 3, 5, 7)); // intersection, in place
    var ordered = new LinkedHashMap<String, Integer>(); // keeps insertion order
    ordered.put("z", 1);
    ordered.put("a", 2);
    Deque<Integer> deque = new ArrayDeque<>(List.of(1, 2, 3)); // a stack and a queue in one
    deque.push(0);
    var heap = new PriorityQueue<>(List.of(5, 1, 4)); // the minimum on top
    say("%s %s %s %s %d %d", counts, odd, ordered, ordered.firstEntry().getKey(),
            deque.pollLast(), heap.poll());

    // --- Streams: lazy pipelines over collections. C#: LINQ ---
    var staff = List.of(
            new Employee("Ann", "R&D", 5200, 34), new Employee("Bob", "Sales", 4100, 45),
            new Employee("Cid", "R&D", 6100, 29), new Employee("Dee", "Sales", 3900, 38),
            new Employee("Eve", "Ops", 4700, 51));
    List<String> seniors = staff.stream()
            .filter(e -> e.age() > 35)                                       // C#: Where
            .sorted(Comparator.comparingDouble(Employee::salary).reversed()) // OrderByDescending
            .map(Employee::name)                                             // Select
            .toList();                                                       // ToList
    double total = staff.stream().mapToDouble(Employee::salary).sum();
    Map<String, Double> averageByDepartment = staff.stream().collect(Collectors.groupingBy(
            Employee::department, TreeMap::new, Collectors.averagingDouble(Employee::salary)));
    Map<Boolean, Long> wellPaid = staff.stream()
            .collect(Collectors.partitioningBy(e -> e.salary() > 4500, Collectors.counting()));
    String names = staff.stream().map(Employee::name).collect(Collectors.joining(", ", "[", "]"));
    Optional<Employee> youngest = staff.stream().min(Comparator.comparingInt(Employee::age));
    say("%s | %.0f | %s | %s | %s | %s", seniors, total, averageByDepartment, wellPaid, names,
            youngest.map(Employee::name).orElse("nobody"));

    // Ranges, flatMap, reduce, infinite streams. A stream can be consumed only once.
    int sumOfSquares = IntStream.rangeClosed(1, 5).map(n -> n * n).sum();
    List<Integer> flat = Stream.of(List.of(1, 2), List.of(3), List.<Integer>of())
            .flatMap(List::stream).toList(); // C#: SelectMany
    List<Long> fibonacci = Stream.iterate(new long[]{0, 1}, t -> new long[]{t[1], t[0] + t[1]})
            .limit(10).map(t -> t[0]).toList();
    int product = Stream.of(1, 2, 3, 4).reduce(1, (x, y) -> x * y); // C#: Aggregate
    say("%d %s %s %d", sumOfSquares, flat, fibonacci, product);

    // Gatherers (Java 24): user-defined intermediate operations — windows, scans, folds.
    say("%s %s %s", Stream.of(1, 2, 3, 4, 5, 6, 7).gather(Gatherers.windowFixed(3)).toList(),
            Stream.of(1, 2, 3, 4).gather(Gatherers.windowSliding(2)).toList(),
            Stream.of(1, 2, 3, 4).gather(Gatherers.scan(() -> 0, Integer::sum)).toList());

    // Optional<T> is the conventional "maybe" result. C#: nullable reference types.
    Optional<String> found = staff.stream().map(Employee::name)
            .filter(n -> n.startsWith("Z")).findFirst();
    say("%b %s %s", found.isPresent(), found.orElse("no match"),
            Optional.of("x").map(String::toUpperCase).get());
}

// =================================================================================================
//  7. EXCEPTIONS AND RESOURCES
// =================================================================================================

/// A CHECKED exception (extends Exception): callers must catch it or declare `throws`.
static class ConfigException extends Exception {
    private final String key;

    ConfigException(String key, String message, Throwable cause) {
        super("config key '" + key + "': " + message, cause);
        this.key = key;
    }

    String key() { return key; }
}

/// An UNCHECKED exception (extends RuntimeException): no declaration needed — the way
/// every C# exception behaves.
static class InsufficientFundsException extends RuntimeException {
    InsufficientFundsException(String message) { super(message); }
}

static int parsePort(String text) throws ConfigException { // `throws` is part of the signature
    try {
        int port = Integer.parseInt(text);
        if (port < 1 || port > 65535) {
            throw new ConfigException("port", port + " is out of range", null);
        }
        return port;
    } catch (NumberFormatException e) {
        throw new ConfigException("port", "not a number", e); // wrap, keeping the cause
    }
}

/// AutoCloseable plus try-with-resources. C#: IDisposable plus using.
static class Resource implements AutoCloseable {
    private final String name;
    private final List<String> log;

    Resource(String name, List<String> log) {
        this.name = name;
        this.log = log;
        log.add("open " + name);
    }

    @Override
    public void close() { log.add("close " + name); }
}

void section07Exceptions() {
    header("7. Exceptions and resources");

    for (String text : List.of("8080", "http", "99999")) {
        try {
            say("port %d", parsePort(text));
        } catch (ConfigException e) {
            Throwable inner = e.getCause(); // C#: InnerException
            String cause = inner == null ? "no cause" : inner.getClass().getSimpleName();
            say("%s [key %s, %s]", e.getMessage(), e.key(), cause);
        } finally {
            // runs in every case
        }
    }
    // parsePort("1");   // error: unreported exception ConfigException; must be caught or
    //                   //        declared to be thrown

    try {
        Object text = "not a number";
        Integer number = (Integer) text; // ClassCastException. C#: InvalidCastException
        say("%d", number);
    } catch (ClassCastException | ArithmeticException e) { // multi-catch
        say("caught %s", e.getClass().getSimpleName());
    }

    var log = new ArrayList<String>();
    try (var _ = new Resource("outer", log); var _ = new Resource("inner", log)) {
        log.add("work");
        throw new InsufficientFundsException("balance too low");
    } catch (InsufficientFundsException e) {
        log.add("caught: " + e.getMessage()); // both resources are closed by now, inner first
    }
    say("%s", log);

    // Checked exceptions and lambdas do not mix: Function.apply declares none, so a lambda
    // that calls parsePort has to handle the exception itself.
    Function<String, Integer> portOrMinusOne = text -> {
        try {
            return parsePort(text);
        } catch (ConfigException e) {
            return -1;
        }
    };
    say("%d %d", portOrMinusOne.apply("443"), portOrMinusOne.apply("x"));

    try {
        Objects.requireNonNull(null, "value must not be null");
    } catch (NullPointerException e) {
        StackTraceElement top = e.getStackTrace()[0]; // a stack trace is data too
        say("\"%s\" thrown in %s.%s", e.getMessage(), top.getClassName(), top.getMethodName());
    }
}

// =================================================================================================
//  8. PATTERN MATCHING
// =================================================================================================

/// A sealed interface knows all its implementations (here: the ones in this file), so the
/// compiler can check a switch for completeness. C#: `closed` types and unions of C# 15.
sealed interface Expr {}

record Num(double value) implements Expr {}

record Add(Expr left, Expr right) implements Expr {}

record Mul(Expr left, Expr right) implements Expr {}

record Neg(Expr operand) implements Expr {}

static double evaluate(Expr expr) {
    return switch (expr) { // no default: all four cases are covered, and that is checked
        case Num(double value) -> value; // a record pattern takes the record apart
        case Add(Expr left, Expr right) -> evaluate(left) + evaluate(right);
        case Mul(var left, var right) -> evaluate(left) * evaluate(right);
        case Neg(var operand) -> -evaluate(operand);
    };
}

static Expr simplify(Expr expr) {
    Expr reduced = switch (expr) { // first simplify the children...
        case Add(var l, var r) -> new Add(simplify(l), simplify(r));
        case Mul(var l, var r) -> new Mul(simplify(l), simplify(r));
        case Neg(var o) -> new Neg(simplify(o));
        case Num n -> n;
    };
    return switch (reduced) { // ...then apply the rules; patterns nest, `when` adds a guard
        case Add(Num(var a), Num(var b)) -> new Num(a + b);
        case Add(Num(var zero), var other) when zero == 0 -> other;
        case Add(var other, Num(var zero)) when zero == 0 -> other;
        case Mul(Num(var one), var other) when one == 1 -> other;
        case Mul(var other, Num(var one)) when one == 1 -> other;
        case Mul(Num(var zero), var _) when zero == 0 -> new Num(0); // `_`: unnamed pattern
        case Mul(var _, Num(var zero)) when zero == 0 -> new Num(0);
        case Neg(Neg(var inner)) -> inner;
        default -> reduced;
    };
}

static String classify(Object value) {
    return switch (value) {
        case null -> "null"; // a switch may handle null explicitly
        case Integer n when n < 0 -> "negative int " + n; // a type pattern with a guard
        case Integer n -> "int " + n;
        case Double d -> fmt("double %.1f", d);
        case String s when s.isEmpty() -> "empty string";
        case String s -> "string of length " + s.length();
        case int[] array -> "int array of length " + array.length;
        case Point(var x, var y) when x == 0 && y == 0 -> "the origin";
        case Point(var x, var _) -> fmt("point with x = %.0f", x);
        case Planet.EARTH -> "home";
        case Planet planet -> "planet " + planet;
        case List<?> list when list.isEmpty() -> "empty list";
        case List<?> list -> "list starting with " + list.getFirst();
        default -> "something else: " + value.getClass().getSimpleName();
    };
}

void section08PatternMatching() {
    header("8. Pattern matching");

    Object[] samples = {null, -5, 42, 2.5, "", "text", new int[3], new Point(0, 0),
            new Point(7, 1), Planet.EARTH, Planet.JUPITER, List.of(), List.of("x", "y"), 'c'};
    var line = new StringBuilder();
    for (Object sample : samples) line.append(classify(sample)).append("; ");
    IO.println(line.toString());

    Expr tree = new Mul(new Neg(new Add(new Num(4), new Num(2))), new Num(3)); // -(4 + 2) * 3
    Expr messy = new Add(new Mul(new Num(1), new Num(7)),
            new Mul(new Num(0), new Neg(new Neg(new Num(9)))));
    say("%.1f | %s | %.1f", evaluate(tree), simplify(messy), evaluate(simplify(messy)));
}

// =================================================================================================
//  9. TEXT, NUMBERS, TIME, FILES
// =================================================================================================

void section09Library() {
    header("9. Text, numbers, time, files");

    // Big numbers: methods instead of operators. C#: BigInteger and decimal.
    BigInteger factorial = BigInteger.ONE;
    for (int i = 2; i <= 25; i++) factorial = factorial.multiply(BigInteger.valueOf(i));
    BigDecimal price = new BigDecimal("19.99");
    BigDecimal total = price.multiply(BigDecimal.valueOf(3)).setScale(1, RoundingMode.HALF_UP);
    say("%s | %s | %b", factorial, total, 0.1 + 0.2 == 0.3);

    // Regular expressions.
    var pattern = Pattern.compile("(?<date>\\d{4}-\\d{2}-\\d{2}) (?<level>[A-Z]+) (?<text>[^;]+)");
    String log = "2026-11-17 ERROR disk full; 2026-11-18 WARN retry; 2026-11-19 ERROR timeout";
    List<String> errorDates = pattern.matcher(log).results()
            .filter(m -> m.group("level").equals("ERROR")).map(m -> m.group("date")).toList();
    say("%s | %s | %s", errorDates, log.replaceAll("\\d{4}-", ""),
            Arrays.toString("x=1;y=22".split("[=;]")));

    // java.time: immutable dates and times. C#: DateOnly, DateTimeOffset, TimeSpan.
    LocalDate date = LocalDate.of(2026, 11, 17);
    LocalDateTime start = date.atTime(9, 30);
    ZonedDateTime local = start.atZone(ZoneId.of("Europe/Berlin"));
    Duration duration = Duration.ofHours(27).plusMinutes(15);
    say("%s | %s | %s UTC | %s | %d days | %s", date.plusDays(45), date.getDayOfWeek(),
            local.withZoneSameInstant(ZoneOffset.UTC).toLocalTime(),
            start.plus(duration).format(DateTimeFormatter.ofPattern("dd.MM.yyyy HH:mm")),
            ChronoUnit.DAYS.between(date, LocalDate.of(2026, 12, 24)), duration);

    // Files: java.nio.file. C#: File, Path, Directory. IOException is checked.
    try {
        Path folder = Files.createTempDirectory("java-tour");
        Path file = folder.resolve("notes.txt");
        Files.writeString(file, "first\nsecond\n");
        Files.writeString(file, "third\n", StandardOpenOption.APPEND);
        List<String> lines = Files.readAllLines(file);
        try (Stream<String> stream = Files.lines(file)) { // lazy, so it must be closed
            say("%s, %d bytes, %s, longest line: %s", file.getFileName(), Files.size(file), lines,
                    stream.max(Comparator.comparingInt(String::length)).orElse(""));
        }
        Files.delete(file);
        Files.delete(folder);
    } catch (IOException e) {
        say("I/O failed: %s", e.getMessage());
    }
}

// =================================================================================================
//  10. CONCURRENCY
// =================================================================================================

static final ScopedValue<String> CURRENT_USER = ScopedValue.newInstance();

static String whoAmI() { return CURRENT_USER.isBound() ? CURRENT_USER.get() : "anonymous"; }

void section10Concurrency() throws Exception {
    header("10. Concurrency");

    // --- Platform threads: one OS thread each. C#: Thread ---
    int[] sum = {0};
    Thread worker = new Thread(() -> {
        for (int i = 1; i <= 1000; i++) sum[0] += i;
    }, "worker");
    worker.start();
    worker.join();
    say("the worker computed %d", sum[0]);

    // --- synchronized, explicit locks, atomics ---
    int[] plain = {0}, guarded = {0};
    Object monitor = new Object();
    var lock = new ReentrantLock();
    var atomic = new AtomicInteger();
    Runnable task = () -> {
        for (int i = 0; i < 10_000; i++) {
            synchronized (monitor) { // C#: lock (monitor) { ... }
                plain[0]++;
            }
            lock.lock(); // an explicit lock must be released in `finally`
            try {
                guarded[0]++;
            } finally {
                lock.unlock();
            }
            atomic.incrementAndGet(); // C#: Interlocked.Increment
        }
    };
    var threads = new ArrayList<Thread>();
    for (int i = 0; i < 4; i++) threads.add(Thread.ofPlatform().start(task));
    for (Thread thread : threads) thread.join();
    say("synchronized %d, lock %d, atomic %d", plain[0], guarded[0], atomic.get());

    // --- Executors and futures. C#: Task.Run and Task.WhenAll ---
    try (ExecutorService pool = Executors.newFixedThreadPool(4)) { // close() awaits the tasks
        var futures = new ArrayList<Future<Integer>>();
        for (int n : List.of(10, 100, 1000)) {
            futures.add(pool.submit(() -> IntStream.rangeClosed(1, n).sum()));
        }
        var results = new ArrayList<Integer>();
        for (var future : futures) results.add(future.get()); // blocks until the task is done
        say("pool results %s", results);
    }

    // --- CompletableFuture: composable asynchronous results. C#: Task<T> + ContinueWith ---
    CompletableFuture<Integer> price = CompletableFuture.supplyAsync(() -> 40);
    CompletableFuture<Integer> tax = CompletableFuture.supplyAsync(() -> 2);
    String message = price.thenCombine(tax, Integer::sum)
            .thenApply(total -> "total " + total)
            .exceptionally(Throwable::getMessage)
            .get(5, TimeUnit.SECONDS);
    say("%s", message);

    // --- Virtual threads (Java 21): cheap threads scheduled by the JVM. Plain blocking code
    // scales to huge numbers of them; this is Java's answer to async/await. ---
    long started = System.nanoTime();
    try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
        var tasks = new ArrayList<Future<String>>();
        for (int i = 0; i < 10_000; i++) {
            int id = i;
            tasks.add(executor.submit(() -> {
                Thread.sleep(Duration.ofMillis(50)); // parks the virtual thread, not an OS thread
                return "task " + id;
            }));
        }
        int done = 0;
        for (var future : tasks) if (future.get().startsWith("task")) done++;
        long elapsedMs = (System.nanoTime() - started) / 1_000_000;
        say("%d virtual threads slept 50 ms each; all done in under 5 s: %b", done,
                elapsedMs < 5000);
    }
    Thread virtual = Thread.startVirtualThread(() -> {});
    virtual.join();
    say("isVirtual: %b", virtual.isVirtual());

    // --- Concurrent collections, parallel streams, blocking queues ---
    var hits = new ConcurrentHashMap<String, Integer>();
    IntStream.range(0, 1000).parallel() // C#: PLINQ
            .forEach(i -> hits.merge(i % 2 == 0 ? "even" : "odd", 1, Integer::sum));
    var queue = new LinkedBlockingQueue<Integer>(2); // C#: BlockingCollection<T>
    Thread producer = Thread.ofVirtual().start(() -> {
        try {
            for (int i = 1; i <= 5; i++) queue.put(i); // blocks while the queue is full
            queue.put(-1);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt(); // restore the interrupt flag
        }
    });
    int consumed = 0;
    for (int item; (item = queue.take()) != -1; ) consumed += item;
    producer.join();
    say("%s, consumed %d", new TreeMap<>(hits), consumed);

    // --- Scoped values (Java 25): immutable context bound for the duration of a call and
    // inherited by child tasks. C#: AsyncLocal<T>. They replace most uses of ThreadLocal. ---
    String inside = ScopedValue.where(CURRENT_USER, "ann").call(() -> whoAmI());
    say("inside the scope: %s, outside: %s", inside, whoAmI());
}

// =================================================================================================
//  11. REFLECTION AND ANNOTATIONS
// =================================================================================================

@Retention(RetentionPolicy.RUNTIME) // keep the annotation visible to reflection
@Target(ElementType.FIELD)
@interface Column { // an annotation type. C#: class ColumnAttribute : Attribute
    String name();

    boolean nullable() default true;
}

static class Customer {
    @Column(name = "customer_id", nullable = false)
    private long id = 7;

    @Column(name = "full_name")
    private String name = "Ann";

    private int cache; // not annotated

    public String greet(String greeting) { return greeting + ", " + name; }
}

interface Greeter {
    String greet(String name);
}

void section11Reflection() throws Exception {
    header("11. Reflection and annotations");

    var customer = new Customer();
    Class<?> type = customer.getClass(); // or Customer.class. C#: GetType() / typeof
    say("%s extends %s and declares %d fields", type.getSimpleName(),
            type.getSuperclass().getSimpleName(), type.getDeclaredFields().length);

    // Reading annotations and private fields: how ORMs, serializers and DI containers work.
    for (Field field : type.getDeclaredFields()) {
        Column column = field.getAnnotation(Column.class);
        if (column == null) continue;
        field.setAccessible(true); // look past `private`
        say("  %s -> column %s, nullable %b, value %s", field.getName(), column.name(),
                column.nullable(), field.get(customer));
    }

    // Calling a method by name; creating an object from its Class.
    Method method = type.getMethod("greet", String.class);
    Object created = type.getDeclaredConstructor().newInstance();
    say("%s | %s | %s", method.invoke(customer, "Hello"), created.getClass().getSimpleName(),
            Modifier.toString(method.getModifiers()));

    // Records describe themselves.
    var components = new StringBuilder();
    for (RecordComponent component : Point.class.getRecordComponents()) {
        components.append(component.getType()).append(' ').append(component.getName()).append("; ");
    }
    say("Point(%s)", components.toString().strip());

    // A dynamic proxy: an implementation of an interface generated at run time. (The bare
    // name `Proxy` would be ambiguous here: java.net has one too, and a compact source file
    // imports the whole java.base module.)
    var calls = new ArrayList<String>();
    Greeter greeter = (Greeter) java.lang.reflect.Proxy.newProxyInstance(
            Greeter.class.getClassLoader(), new Class<?>[]{Greeter.class},
            (proxy, invoked, arguments) -> {
                calls.add(invoked.getName() + Arrays.toString(arguments));
                return "Hi, " + arguments[0];
            });
    say("%s %s", greeter.greet("Bob"), calls);

    // Generic type arguments survive in declarations (fields, signatures), not in objects.
    say("%s", Stack.class.getDeclaredField("items").getGenericType());
}

// =================================================================================================
//  12. THE NEWEST: Java 21 - 25
// =================================================================================================

/// Flexible constructor bodies (Java 25): statements may run BEFORE `super(...)`, to check
/// or compute its arguments, as long as they do not touch `this`.
static class PositiveCircle extends Circle {
    PositiveCircle(double radius) {
        if (radius <= 0) throw new IllegalArgumentException("the radius must be positive");
        double rounded = Math.round(radius * 10) / 10.0;
        super(rounded);
    }
}

void section12Newest() {
    header("12. The newest: Java 21 - 25");

    // Already used above: records, record patterns, sealed types, patterns in switch,
    // sequenced collections, virtual threads (21); unnamed variables `_` (22); Markdown
    // documentation comments (23); stream gatherers (24); compact source files, instance
    // `main`, module imports and scoped values (25).
    say("%s", new PositiveCircle(1.26).describe());
    try {
        new PositiveCircle(-1);
    } catch (IllegalArgumentException e) {
        say("rejected before super(): %s", e.getMessage());
    }

    // `_` wherever the language demands a name that the code does not need.
    int count = 0;
    for (var _ : List.of("a", "b", "c")) count++;
    BiFunction<Integer, Integer, Integer> first = (x, _) -> x;
    say("%d %d", count, first.apply(1, 2));

    // Still in preview in JDK 25 (they need --enable-preview and were not compiled here):
    //   primitive types in patterns:  if (value instanceof int i) ...
    //   structured concurrency:       try (var scope = StructuredTaskScope.open()) { ... }
    //   stable values:                a field that is initialized lazily, exactly once
    // Still being designed (Project Valhalla): value classes, Java's counterpart of struct.
    say("running on Java %d", Runtime.version().feature());
}

// =================================================================================================
//  ENTRY POINT
// =================================================================================================

// An instance `main` without parameters (Java 25); `String[] args` is optional.
void main() throws Exception {
    section01Basics();
    section02Classes();
    section03Inheritance();
    section04Generics();
    section05Lambdas();
    section06Collections();
    section07Exceptions();
    section08PatternMatching();
    section09Library();
    section10Concurrency();
    section11Reflection();
    section12Newest();
}
