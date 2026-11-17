// =====================================================================================
//  C++ FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
// =====================================================================================
//
//  Build and run (a compiler and a standard library with C++23 support are required):
//
//      g++ -std=c++23 -O2 -Wall -Wextra -Wpedantic cpp_tour.cpp -o cpp_tour
//      clang++ -std=c++23 -stdlib=libc++ -O2 -Wall -Wextra -Wpedantic cpp_tour.cpp -o cpp_tour
//      cl /std:c++latest /utf-8 /EHsc /W4 cpp_tour.cpp
//      ./cpp_tour
//
//  Verified with GCC 14.2 (libstdc++) and Clang 20 (libc++), in -std=c++23 and -std=c++26
//  modes, plus runs under the address, undefined-behaviour and thread sanitizers. An MSVC
//  build has not been tested; according to Microsoft's conformance table the language
//  features used here are available from VS 2022 17.14.
//  With -std=c++26 the C++26 examples in section 16 are enabled as well.
//
//  Not every compiler and library has all of C++23/26 yet. Such fragments are wrapped in
//  feature-test macro checks (`#ifdef __cpp_lib_generator` and the like): where a feature
//  is missing, the example is simply skipped and the file still builds.
//
//  How to read. Each section is a function `sectionNN_*`; the types and functions a
//  section needs are declared right before it; `main()` at the end of the file calls the
//  sections in order. A "C#:" note shows the closest C# counterpart.
//
//  The main differences from C# to keep in mind from the first line:
//
//   1. No garbage collector. Object lifetime is deterministic: an object is destroyed when
//      it goes out of scope (or when its owner goes away). The central idiom of the
//      language, RAII, is built on that (section 4).
//   2. EVERY type is a value type. A variable is the object itself, not a reference to
//      it, and `b = a` copies the whole object. Reference semantics is requested
//      explicitly: `T&`, `T*`, smart pointers. `struct` and `class` are the same thing
//      (they differ only in default access).
//   3. Undefined behaviour (UB). Going out of array bounds, using a destroyed object,
//      signed overflow, a data race — these are not exceptions but "the program may do
//      anything". The compiler does not catch them.
//   4. Templates are not CLR generics. They are compile-time code generation: a separate
//      copy per set of types, with the body checked at instantiation (section 9).
//   5. Compilation goes top to bottom: a name must be declared before use. Historically
//      code is split into headers (.h) and translation units (.cpp); C++20 modules are
//      covered in section 16.
//   6. Inheritance can be multiple, there is no separate "interface" entity, and the
//      virtual destructor of a base class is yours to remember (section 6).
//   7. There is no run-time reflection; a lot is decided at compile time (section 12).
//
//  Contents:
//    1. Basics: types, variables, functions        9. Templates and concepts
//    2. Values, references, pointers              10. Sum types: optional, variant, any
//    3. Strings, containers, formatting           11. Error handling
//    4. Classes and RAII                          12. Compile-time evaluation
//    5. Memory ownership: smart pointers          13. Low level: memory, bits, allocators
//    6. Inheritance and polymorphism              14. Concurrency
//    7. Lambdas and callable objects              15. Coroutines
//    8. Algorithms and ranges                     16. C++23, C++26, modules
// =====================================================================================

// `#include` pastes a header file in textually — that is the preprocessor at work, not an
// assembly import. C#: using + an assembly reference. The standard library is split into
// dozens of headers; only the needed ones are included.
#include <algorithm>
#include <any>
#include <array>
#include <atomic>
#include <bit>
#include <bitset>
#include <charconv>
#include <chrono>
#include <cmath>
#include <concepts>
#include <condition_variable>
#include <coroutine>
#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <exception>
#include <expected>
#include <format>
#include <functional>
#include <future>
#include <initializer_list>
#include <iostream>
#include <iterator>
#include <latch>
#include <limits>
#include <map>
#include <memory>
#include <memory_resource>
#include <mutex>
#include <new>
#include <numbers>
#include <numeric>
#include <optional>
#include <print>
#include <queue>
#include <ranges>
#include <set>
#include <shared_mutex>
#include <source_location>
#include <span>
#include <stdexcept>
#include <stop_token>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <tuple>
#include <type_traits>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <variant>
#include <vector>
#include <version> // __cpp_lib_* macros: which library features are really available

// Conditional compilation. C#: #if. Headers of new features are included only if present.
#ifdef __cpp_lib_generator
#include <generator>
#endif
#ifdef __cpp_lib_mdspan
#include <mdspan>
#endif
#ifdef __cpp_lib_flat_map
#include <flat_map>
#endif

// Brings the literal suffixes into scope: "text"s, "text"sv, 10ms.
// A blanket `using namespace std;` is avoided in serious code: far too many names.
using namespace std::literals;

// Prints a section header. std::string_view is a "window" into someone else's string
// (section 3).
void header(int number, std::string_view title) {
    std::println("\n=== {:>2}. {} ===", number, title);
}

// Joins the elements of any range into a string. `auto&&` in the parameter makes the
// function a template (section 9): it accepts a vector, an array, a set, a lazy view —
// anything that can be iterated and whose elements std::format can print.
// (Printing ranges out of the box — `std::println("{}", vec)` — is part of C++23 but not
// in every library yet; see section 16.)
std::string join(auto&& range, std::string_view separator = ", ") {
    std::string result;
    bool first = true;
    for (const auto& item : range) {
        if (!first) result += separator;
        result += std::format("{}", item);
        first = false;
    }
    return result;
}

// =====================================================================================
//  1. BASICS: types, variables, functions, control flow
// =====================================================================================

// A compile-time constant. C#: const. The apostrophe is a digit separator (C#: 100_000).
constexpr int max_points = 100'000;

// A strongly typed enumeration with a chosen underlying type. C#: enum Color : byte.
// The "old" enum (without the word class) converts to int implicitly and its value names
// leak into the enclosing scope — new code avoids it.
enum class Color : std::uint8_t { red, green, blue };

// A declaration (prototype) without a body. The compiler reads the file top to bottom,
// and a name must be declared BEFORE it is used. In C# member order does not matter;
// here it does.
std::string_view color_name(Color color);

// Functions. Overloading and default parameters work as in C#; there are no named arguments.
int add(int a, int b) { return a + b; }
double add(double a, double b) { return a + b; } // an overload on parameter types
int scale(int value, int factor = 2) { return value * factor; }

// `auto` instead of the result type: the type is deduced from the return statement.
auto cube(int x) { return x * x * x; }

// A trailing return type is an alternative notation; handy in templates and lambdas.
auto half(double x) -> double { return x / 2; }

std::string_view color_name(Color color) {
    // switch: WITHOUT a break, execution "falls through" into the next case (C# forbids that).
    switch (color) {
        case Color::red:
            return "red";
        case Color::green:
            [[fallthrough]]; // an attribute: the fall-through is intentional, do not warn
        case Color::blue:
            return "cold";
    }
    std::unreachable(); // C++23: "control never gets here". If it does — UB
}

// A namespace. C#: namespace. Nesting is written with `::`.
namespace geometry::units {
constexpr double mm_per_inch = 25.4;
constexpr double to_mm(double inches) { return inches * mm_per_inch; }
} // namespace geometry::units

void section01_basics() {
    header(1, "Basics: types, variables, functions, control flow");

    // --- Variables and initialization -------------------------------------------------
    int a = 42;   // initialization "with equals"
    int b{7};     // braces: the uniform syntax, which forbids narrowing
    // int bad{3.7};  // error: narrowing conversion from 'double' to 'int'
    auto d = 3.5;  // double; auto is the counterpart of var
    auto f = 2.5f; // float
    bool flag = true;
    char letter = 'A'; // ONE BYTE, not a UTF-16 code unit like a C# char

    // The sizes of int, long and so on depend on the platform (long: 8 bytes on Linux, 4 on
    // Windows). When the width matters, use the types from <cstdint>.
    std::int64_t big = 9'000'000'000; // C#: long
    std::uint8_t byte = 0xFF;         // C#: byte
    std::size_t count = 10uz;         // an unsigned "size" (C#: nuint); the uz suffix is C++23
    std::println("{} {} {} {} {} {} {} {} {}", a, b, d, f, flag, letter, big, byte, count);
    std::println("sizeof: char {}, int {}, long {}, long long {}, double {}, pointer {}",
                 sizeof(char), sizeof(int), sizeof(long), sizeof(long long), sizeof(double),
                 sizeof(void*));

    // A local variable without an initializer holds garbage and must not be read: before
    // C++26 that is UB, in C++26 "erroneous behaviour". (In C# it is compile error CS0165.)
    //     int garbage;
    //     std::println("{}", garbage);

    // --- const and constexpr ----------------------------------------------------------
    const int limit = a * 2;                     // cannot be changed after initialization
    constexpr double tau = 2 * std::numbers::pi; // the value must be known at compile time
    std::println("limit {}, tau {:.4f}, max_points {}", limit, tau, max_points);

    // --- Conversions: generous and dangerous ------------------------------------------
    // C++ converts numbers implicitly where C# would demand an explicit cast.
    double ratio = a / 5;                   // integer division: 8, and only then 8 -> 8.0
    int truncated = static_cast<int>(3.99); // an explicit cast: 3. Write static_cast, not (int)x
    unsigned wrapped = 0u - 1u;             // unsigned values wrap modulo 2^32
    // int overflow = std::numeric_limits<int>::max() + 1; // SIGNED overflow is UB!
    std::println("{} {} {} (int max is {})", ratio, truncated, wrapped,
                 std::numeric_limits<int>::max());

    // --- Functions --------------------------------------------------------------------
    std::println("{} {} {} {} {} {}", add(2, 3), add(2.5, 0.5), scale(5), scale(5, 10), cube(3),
                 half(5));

    // --- Control flow -----------------------------------------------------------------
    // if with an initializer (C++17): the variable lives only inside the if/else.
    if (int remainder = a % 5; remainder == 0) {
        std::println("{} is divisible by 5", a);
    } else {
        std::println("{} % 5 = {}", a, remainder);
    }
    const char* parity = (a % 2 == 0) ? "even" : "odd"; // the ternary operator works as in C#

    int sum = 0;
    for (int i = 0; i < 5; ++i) sum += i;        // the classic for
    for (int value : {10, 20, 30}) sum += value; // a range-based for. C#: foreach
    int countdown = 3;
    while (countdown > 0) --countdown;
    do {
        ++countdown;
    } while (countdown < 2);
    std::println("{} is {}, sum = {}, countdown = {}", a, parity, sum, countdown);

    for (Color color : {Color::red, Color::green, Color::blue}) {
        // An enum class converts to a number only explicitly; std::to_underlying is C++23.
        std::print("{}={} ", color_name(color), std::to_underlying(color));
    }
    std::println("");

    // --- Namespaces -------------------------------------------------------------------
    using geometry::units::to_mm; // bring a single name into scope
    namespace gu = geometry::units; // a namespace alias
    std::println("2 in = {} mm, {} mm per inch", to_mm(2.0), gu::mm_per_inch);
}

// =====================================================================================
//  2. VALUES, REFERENCES, POINTERS
// =====================================================================================
//
//  The most important difference from C#. There the type itself defines the behaviour:
//  a class is a reference to a heap object, a struct is a value. In C++ EVERY type is a
//  value:
//    - a variable of type T is the object itself, not a reference to it;
//    - `b = a` copies the whole object, be it an int or a vector of a million elements;
//    - "reference-ness" is chosen at the point of use: T& (reference) or T* (pointer).

struct Point {
    double x = 0.0; // a default member initializer
    double y = 0.0;
};

// How a parameter is taken is the function author's decision:
Point shifted(Point p, double dx) { // by value: the function works on a COPY
    p.x += dx;
    return p;
}

void shift(Point& p, double dx) { p.x += dx; } // by reference: the original changes. C#: ref

// By const reference: no copy, read-only. This is how anything more expensive than a
// couple of machine words is passed. C#: in.
double norm(const Point& p) { return std::hypot(p.x, p.y); }

void shift_if_present(Point* p, double dx) { // by pointer: "there may be no object"
    if (p != nullptr) p->x += dx;            // `->` is member access through a pointer
}

// Several results: a pair, a tuple or a struct.
std::pair<int, int> div_rem(int a, int b) { return {a / b, a % b}; }

void section02_values_references_pointers() {
    header(2, "Values, references, pointers");

    // --- Copying ----------------------------------------------------------------------
    std::vector<int> first{1, 2, 3};
    std::vector<int> second = first; // A FULL COPY (C# would copy only the reference)
    second.push_back(4);
    std::vector<int>& alias = first; // this is "the C# way": a second name for THE SAME object
    alias.push_back(99);
    std::println("first [{}], second [{}]", join(first), join(second));

    // --- References and pointers ------------------------------------------------------
    int x = 10;
    int& ref = x; // a reference: bound at once, never "empty", cannot be reseated
    int* ptr = &x; // a pointer: a variable holding an address. `&x` takes it, `*ptr` dereferences
    ref += 1;
    *ptr += 1;
    int* nothing = nullptr;    // C#: null. Dereferencing it is UB, not a NullReferenceException
    const int* read_only = &x; // a pointer to const: the value cannot be changed through it
    std::println("x = {}, *ptr = {}, is null: {}, *read_only = {}", x, *ptr, nothing == nullptr,
                 *read_only);

    // --- Aggregates -------------------------------------------------------------------
    Point p1{1.0, 2.0};           // aggregate initialization in field order
    Point p2{.x = 3.0, .y = 4.0}; // designated initializers (C++20). C#: new Point { X = 3 }
    Point p3 = p1;                // a copy of all fields
    p3.y = 20.0;
    auto [px, py] = p2; // structured bindings (C++17). C#: var (x, y) = point
    auto [quotient, remainder] = div_rem(17, 5);
    std::println("p1.y = {}, p3.y = {}, p2 = ({}, {}), 17 / 5 = {} rem {}", p1.y, p3.y, px, py,
                 quotient, remainder);

    // --- Parameter passing ------------------------------------------------------------
    Point p{3.0, 4.0};
    Point copy = shifted(p, 10.0);  // p is unchanged
    shift(p, 1.0);                  // p.x == 4
    shift_if_present(&p, 1.0);      // p.x == 5
    shift_if_present(nullptr, 1.0); // does nothing
    std::println("p.x = {}, copy.x = {}, norm = {:.3f}", p.x, copy.x, norm(p));

    // --- Arrays -----------------------------------------------------------------------
    int raw[4] = {1, 2, 3, 4};            // a C-style array: passed to a function without its size
    std::array<int, 4> fixed{1, 2, 3, 4}; // an array value; the size is part of the type
    std::array<int, 4> duplicate = fixed; // copied as a whole (int[] in C# is a reference)
    duplicate[0] = 100;
    std::println("raw has {} elements, fixed[0] = {}, duplicate[0] = {}", std::size(raw), fixed[0],
                 duplicate[0]);
    // fixed[10]    — out of bounds with no check: UB.
    // fixed.at(10) — checked: throws std::out_of_range.
}

// =====================================================================================
//  3. STRINGS, CONTAINERS, FORMATTING
// =====================================================================================

// std::span<T> is a "window" into a contiguous sequence: an array, a std::array, a vector.
// C#: Span<T> / ReadOnlySpan<T>.
int sum_of_span(std::span<const int> values) {
    int total = 0;
    for (int v : values) total += v;
    return total;
}

// std::optional<T> is a value that may be absent. C#: T?
std::optional<int> first_even(std::span<const int> values) {
    for (int v : values) {
        if (v % 2 == 0) return v;
    }
    return std::nullopt;
}

void section03_strings_and_containers() {
    header(3, "Strings, containers, formatting");

    // --- std::string ------------------------------------------------------------------
    // A mutable sequence of BYTES that owns its buffer; it knows nothing about encodings.
    // In spirit it is closer to StringBuilder than to the immutable C# string.
    std::string text = "Hello";
    text += ", world";
    text.push_back('!');
    std::string copy = text; // a copy of the buffer (C# strings are immutable and therefore shared)
    copy[0] = 'J';
    std::println("{} | {} | size {} | equal: {}", text, copy, text.size(), text == copy);

    // std::string_view is a non-owning "window" into someone else's string.
    // C#: ReadOnlySpan<char>. It is cheap to copy (pointer + length) but does NOT extend the
    // string's life: returning a view of a local std::string is the classic dangling reference.
    std::string_view view = text;
    std::string_view word = view.substr(0, 5); // no copying and no allocations
    std::println("{} | starts_with: {} | contains: {} | find: {}", word,
                 view.starts_with("Hello"), view.contains("wor"), view.find("world"));

    // Literals. A plain "..." is an array const char[N]; the suffixes produce real objects.
    auto owned = "std::string literal"s;   // std::string
    auto viewed = "string_view literal"sv; // std::string_view
    auto raw = R"(C:\dir\file "quoted")";  // a raw string, no escaping. C#: @"..." and """..."""
    std::println("{} | {} | {}", owned, viewed, raw);

    // Numbers <-> strings.
    int parsed = std::stoi("42"); // throws an exception on failure
    std::string_view digits = "1234abc";
    int fast = 0;
    // from_chars: no allocations, locales or exceptions; returns the stop position and an
    // error code.
    auto [stop, error] = std::from_chars(digits.data(), digits.data() + digits.size(), fast);
    std::println("{} | {} ({} chars, ok: {}) | {}", parsed, fast, stop - digits.data(),
                 error == std::errc{}, std::to_string(2026) + "!");

    // size() counts bytes. In UTF-8 a letter outside ASCII takes two or more.
    std::string accented = "Grüße";
    std::println("'{}' takes {} bytes", accented, accented.size());

    // --- std::vector<T>, a dynamic array. C#: List<T> -----------------------------------
    std::vector<int> values{5, 3, 8};
    values.push_back(1);
    values.emplace_back(9);           // construct the element right inside the vector
    values.insert(values.begin(), 0); // positions are given by ITERATORS, not indices
    values.erase(values.begin() + 1); // erase the element at index 1
    std::println("[{}] size {}, front {}, back {}, at(2) {}", join(values), values.size(),
                 values.front(), values.back(), values.at(2));
    // values[100] is UB (no bounds check!); values.at(100) throws std::out_of_range.

    // span and optional at work.
    int c_array[] = {7, 9, 4};
    std::array<int, 3> std_array{1, 3, 5};
    std::println("sums: {} {} {} | first even: {} {}", sum_of_span(values), sum_of_span(c_array),
                 sum_of_span(std::span{values}.subspan(1, 2)),
                 first_even(c_array).value_or(-1), first_even(std_array).has_value());

    // --- Maps and sets ----------------------------------------------------------------
    std::map<std::string, int> ages{{"Ann", 30}, {"Bob", 25}}; // a tree. C#: SortedDictionary
    ages["Cid"] = 41;
    ages["Dan"]; // A TRAP: operator[] inserts a default value if the key is missing
    // Lookup without insertion: find returns an iterator; "not found" is end().
    if (auto it = ages.find("Bob"); it != ages.end()) {
        std::println("found {} -> {}", it->first, it->second);
    }
    std::print("contains Eve: {}, size {}:", ages.contains("Eve"), ages.size());
    for (const auto& [name, age] : ages) { // a structured binding to a (key, value) pair
        std::print(" {}={}", name, age);
    }
    std::println("");

    std::unordered_map<std::string, int> stock{{"bolt", 10}}; // a hash table. C#: Dictionary
    stock.try_emplace("nut", 5);       // insert only if the key is not there yet
    stock.insert_or_assign("bolt", 7); // insert or replace
    ++stock["screw"]; // here the automatic zero insertion is exactly what a counter needs
    std::set<int> unique{3, 1, 3, 2};                // an ordered set. C#: SortedSet
    std::unordered_set<std::string> seen{"a", "b"};  // C#: HashSet
    std::deque<int> queue{2, 3};                     // a double-ended queue
    queue.push_front(1);
    queue.push_back(4);
    std::println("stock: bolt {}, nut {}, screw {} | unique [{}] | seen a: {} | deque [{}]",
                 stock.at("bolt"), stock.at("nut"), stock.at("screw"), join(unique),
                 seen.contains("a"), join(queue));

    // --- Tuples -----------------------------------------------------------------------
    std::tuple<int, std::string, double> record{1, "one", 1.5}; // C#: (int, string, double)
    auto [id, label, weight] = record;
    std::println("{} {} {} | get<1>: {} | get<double>: {}", id, label, weight, std::get<1>(record),
                 std::get<double>(record));

    // --- Formatting: std::format and std::print (C++20/23) ------------------------------
    // The mini-language is almost the C# one; the format string is checked AT COMPILE TIME.
    std::println("[{:>8.3f}] [{:<6}] [{:^6}] [{:08.2f}] [{:#x}] [{:#010b}] [{:e}] [{:+}]", 9.87654,
                 "ab", "mid", 2.5, 255, 5, 1234.5, 7);
    // Positional arguments and a width taken from an argument.
    std::string line = std::format("{0}/{1}/{0} [{2:>{3}}]", "x", "y", 42, 6);
    std::println("{}", line);
    // Before C++20 there were only iostreams; they appear in any existing code base.
    std::cout << "iostream: " << 42 << ' ' << 3.5 << '\n';
}

// =====================================================================================
//  4. CLASSES AND RAII
// =====================================================================================

// A class with encapsulation. `public:` and `private:` are section labels, not
// modifiers on every member as in C#.
class Vec2 {
public:
    // Constructors. After the colon comes the member initializer list: fields are
    // INITIALIZED there rather than assigned in the body.
    constexpr Vec2() = default; // "= default": ask the compiler for the standard implementation
    constexpr Vec2(double x, double y) : x_{x}, y_{y} {}

    // A delegating constructor. explicit forbids the implicit conversion `Vec2 v = 5.0;`
    // (a one-parameter constructor without explicit acts like a C# implicit operator).
    constexpr explicit Vec2(double both) : Vec2{both, both} {}

    // `const` after the parameter list: the method does not modify the object and can be
    // called through a const reference. C#: readonly members of structs. [[nodiscard]] makes
    // the compiler warn when the result is ignored.
    [[nodiscard]] constexpr double x() const { return x_; }
    [[nodiscard]] constexpr double y() const { return y_; }
    [[nodiscard]] double length() const { return std::hypot(x_, y_); }

    // Operator overloading. Compound assignment is a method that returns *this.
    constexpr Vec2& operator+=(const Vec2& rhs) {
        x_ += rhs.x_;
        y_ += rhs.y_;
        return *this; // this is a pointer to the current object, *this is the object itself
    }
    constexpr Vec2 operator-() const { return {-x_, -y_}; }

    // Binary operators are usually free functions. friend gives them access to private
    // members and lets them be defined right inside the class.
    friend constexpr Vec2 operator+(Vec2 lhs, const Vec2& rhs) { return lhs += rhs; }
    friend constexpr Vec2 operator*(Vec2 v, double k) { return {v.x_ * k, v.y_ * k}; }
    friend constexpr Vec2 operator*(double k, Vec2 v) { return v * k; }

    // Memberwise comparison generated by the compiler (C++20). C#: record struct.
    friend constexpr bool operator==(const Vec2&, const Vec2&) = default;

    // A static method — as in C#.
    static constexpr Vec2 unit_x() { return {1.0, 0.0}; }

private:
    double x_ = 0.0; // by convention private fields get a suffix or a prefix
    double y_ = 0.0;
};

// Plugging a custom type into std::format / std::print means specializing the template
// std::formatter. C#: ToString() / IFormattable. We inherit from formatter<double> so
// that a specification such as `{:.2f}` applies to both coordinates.
template <>
struct std::formatter<Vec2> : std::formatter<double> {
    auto format(const Vec2& v, std::format_context& ctx) const {
        auto out = std::format_to(ctx.out(), "(");
        ctx.advance_to(out);
        out = std::formatter<double>::format(v.x(), ctx);
        ctx.advance_to(std::format_to(out, ", "));
        out = std::formatter<double>::format(v.y(), ctx);
        return std::format_to(out, ")");
    }
};

// The <=> operator ("spaceship", C++20): one line yields ==, !=, <, <=, >, >= with
// lexicographic comparison of the fields. C#: a record plus a hand-written IComparable<T>.
struct Date {
    int year = 1970;
    int month = 1;
    int day = 1;
    auto operator<=>(const Date&) const = default;
};

// A "tracer" class: it reports when it is created, copied, moved and destroyed.
class Tracer {
public:
    explicit Tracer(std::string name) : name_{std::move(name)} {
        ++live_;
        std::println("    ctor  {}", name_);
    }

    // The copy constructor: how to make a second, identical object from an existing one.
    Tracer(const Tracer& other) : name_{other.name_ + "-copy"} {
        ++live_;
        std::println("    copy  {} -> {}", other.name_, name_);
    }

    // The move constructor: how to "steal" the contents of an object that is no longer
    // needed. `Tracer&&` is an rvalue reference. C# has no counterpart: class objects there
    // are never copied in the first place, they are passed by reference.
    Tracer(Tracer&& other) noexcept : name_{std::move(other.name_)} {
        other.name_ = "(moved-from)";
        ++live_;
        std::println("    move  {}", name_);
    }

    Tracer& operator=(const Tracer&) = delete; // "= delete" forbids the operation
    Tracer& operator=(Tracer&&) = delete;

    // The destructor is called automatically and deterministically — at the moment the
    // object's lifetime ends. C#: Dispose(), but without `using` and without "forgot to".
    ~Tracer() {
        --live_;
        std::println("    dtor  {}", name_);
    }

    [[nodiscard]] const std::string& name() const { return name_; }
    [[nodiscard]] static int live() { return live_; }

private:
    std::string name_;
    static inline int live_ = 0; // a static field; inline means "defined right in the class"
};

// Returning by value does not copy: the object is built directly in its destination
// (copy elision). Returning "big" objects by value is normal.
Tracer make_tracer(std::string name) { return Tracer{std::move(name)}; }

// A by-value parameter is a separate object; it is destroyed when the function returns.
void consume(Tracer tracer) { std::println("    consume({})", tracer.name()); }

// The "rule of five". A class that manages a resource by hand needs all five special
// functions: the destructor, the copy and move constructors, the copy and move assignments.
class Buffer {
public:
    explicit Buffer(std::size_t size) : size_{size}, data_{new double[size]{}} {}

    ~Buffer() { delete[] data_; } // release the resource; delete[] on nullptr is safe

    Buffer(const Buffer& other) : size_{other.size_}, data_{new double[other.size_]} {
        std::copy_n(other.data_, size_, data_); // a deep copy
    }

    // std::exchange(a, b): store b in a and return the previous value of a.
    Buffer(Buffer&& other) noexcept
        : size_{std::exchange(other.size_, 0)}, data_{std::exchange(other.data_, nullptr)} {}

    // Assignment with the copy-and-swap idiom: the by-value parameter already holds a copy
    // (or a moved-from object's contents); all that remains is to swap with it.
    Buffer& operator=(Buffer other) noexcept {
        swap(other);
        return *this;
    } // the previous contents are destroyed together with other

    void swap(Buffer& other) noexcept {
        std::swap(size_, other.size_);
        std::swap(data_, other.data_);
    }

    // An indexer in two versions: for a mutable object and for a const one. C#: this[int index].
    double& operator[](std::size_t index) { return data_[index]; }
    const double& operator[](std::size_t index) const { return data_[index]; }

    [[nodiscard]] std::size_t size() const { return size_; }

    // A conversion operator; explicit — it only works in conditions: `if (buffer)`.
    explicit operator bool() const { return data_ != nullptr; }

private:
    std::size_t size_;
    double* data_;
};

// The "rule of zero": the same buffer built from ready-made RAII bricks. The compiler
// generates copying, moving and destruction by itself — and correctly. Application code
// is written this way; manual new/delete stays inside library containers.
struct SafeBuffer {
    std::vector<double> data;
};

// RAII instead of finally: the destructor runs the action on ANY exit from the block —
// by return, by an exception, by break. C#: try/finally or using.
template <typename Action>
class ScopeGuard {
public:
    explicit ScopeGuard(Action action) : action_{std::move(action)} {}
    ~ScopeGuard() { action_(); }
    ScopeGuard(const ScopeGuard&) = delete;
    ScopeGuard& operator=(const ScopeGuard&) = delete;

private:
    Action action_;
};

void section04_classes_and_raii() {
    header(4, "Classes and RAII");

    Vec2 v{3.0, 4.0};
    v += Vec2{1.0};
    const Vec2 w = -(v + Vec2::unit_x() * 2.0);
    // w += v; // error: w is declared const and operator+= is not a const method
    std::println("v = {}, w = {:.1f}, |v| = {:.3f}, equal: {}", v, w, v.length(), v == Vec2{4, 5});

    constexpr Date release{2026, 11, 17};
    static_assert(release > Date{2026, 2, 28}); // the comparison is done at compile time
    std::println("dates: {} {} {}", release == Date{2026, 11, 17}, release < Date{2027, 1, 1},
                 Date{} < release);

    // --- Object lifetime --------------------------------------------------------------
    {
        Tracer a{"a"};               // the object lives right on the stack, no new
        Tracer b = make_tracer("b"); // neither a copy nor a move: copy elision
        Tracer c = a;                // the copy constructor
        // std::move moves nothing: it is a cast that says "I no longer need this object, it may
        // be robbed". The actual moving is done by the constructor Tracer(Tracer&&).
        Tracer d = std::move(a);
        // After the move `a` is alive but "empty": it may only be destroyed or assigned
        // a new value.
        consume(std::move(c));
        std::println("    live objects: {}", Tracer::live());
        std::println("    end of scope");
    } // destructors run HERE, in reverse order of construction: d, c, b, a

    // --- The rule of five and the rule of zero ----------------------------------------
    Buffer original{3};
    original[0] = 1.5;
    Buffer deep_copy = original;         // the copy constructor: an independent buffer
    deep_copy[0] = 99.0;
    Buffer stolen = std::move(original); // the move constructor: original is left empty
    std::println("original alive: {}, stolen[0] = {}, deep_copy[0] = {}, sizes {} and {}",
                 static_cast<bool>(original), stolen[0], deep_copy[0], stolen.size(),
                 deep_copy.size());

    SafeBuffer safe{{1.0, 2.0, 3.0}};
    SafeBuffer safe_copy = safe;        // generated copying
    SafeBuffer safe_moved = std::move(safe); // generated moving
    std::println("rule of zero: copy has {}, moved has {}", safe_copy.data.size(),
                 safe_moved.data.size());

    // --- RAII as a replacement for finally --------------------------------------------
    {
        ScopeGuard guard{[] { std::println("    guard: cleanup runs on scope exit"); }};
        std::println("    guard: doing work");
    }
}

// =====================================================================================
//  5. MEMORY OWNERSHIP: SMART POINTERS
// =====================================================================================
//
//  Local objects live on the stack and are destroyed automatically. A heap object is
//  created by `new` and has to be released manually with `delete`:
//
//      Tracer* raw = new Tracer{"heap"};
//      delete raw;       // forget it — a leak; do it twice — UB; use the object after — UB
//
//  That is why modern C++ does not use new/delete directly. Ownership is expressed in types:
//    std::unique_ptr<T> — one owner (the default choice, no overhead);
//    std::shared_ptr<T> — many owners, reference counting;
//    std::weak_ptr<T>   — an observer of a shared_ptr that does not keep the object alive;
//    T* and T&          — non-owning "observers": whoever receives one deletes nothing.

// A tree with back references: owning ones downwards, weak ones upwards.
struct TreeNode {
    std::string name;
    std::vector<std::shared_ptr<TreeNode>> children;
    std::weak_ptr<TreeNode> parent; // a shared_ptr here would make a cycle and leak: no GC

    explicit TreeNode(std::string node_name) : name{std::move(node_name)} {}

    [[nodiscard]] std::string path() const {
        // lock(): weak_ptr -> shared_ptr; empty if the object has already been destroyed.
        if (auto owner = parent.lock()) return owner->path() + "/" + name;
        return name;
    }
};

void add_child(const std::shared_ptr<TreeNode>& parent, std::shared_ptr<TreeNode> child) {
    child->parent = parent;
    parent->children.push_back(std::move(child));
}

// A custom "deleter": an RAII wrapper for a resource from a C library. Here it is memory
// from std::malloc; FILE*, OS handles, OpenGL objects and so on are wrapped the same way.
struct FreeDeleter {
    void operator()(void* memory) const noexcept { std::free(memory); }
};
using CString = std::unique_ptr<char, FreeDeleter>; // using declares a type alias

CString duplicate_c_string(std::string_view text) {
    auto* memory = static_cast<char*>(std::malloc(text.size() + 1));
    if (memory == nullptr) throw std::bad_alloc{};
    std::memcpy(memory, text.data(), text.size());
    memory[text.size()] = '\0';
    return CString{memory};
}

// A unique_ptr in a signature documents a transfer of ownership.
std::unique_ptr<Tracer> make_owned(std::string name) {
    return std::make_unique<Tracer>(std::move(name)); // a "factory": ownership goes to the caller
}

void take_ownership(std::unique_ptr<Tracer> owned) { // a "sink": the function takes ownership
    std::println("    took ownership of {}", owned->name());
} // the object is destroyed here

void section05_smart_pointers() {
    header(5, "Memory ownership: smart pointers");

    // --- unique_ptr -------------------------------------------------------------------
    auto owner = make_owned("unique");
    // auto copy = owner;           // compile error: a unique_ptr cannot be copied
    Tracer* observer = owner.get(); // a raw pointer as a non-owning observer is perfectly fine
    std::println("    observer sees {}", observer->name());
    auto new_owner = std::move(owner); // ownership has moved; owner is now guaranteed nullptr
    std::println("    owner is null: {}, new owner holds {}", owner == nullptr, new_owner->name());
    take_ownership(std::move(new_owner));
    std::println("    after take_ownership");
    // observer is now a DANGLING pointer: the object is destroyed. Dereferencing it is UB,
    // and the compiler will not warn about it.

    auto numbers = std::make_unique<int[]>(4); // a heap array; std::vector is usually better
    numbers[2] = 7;
    CString c_string = duplicate_c_string("released by std::free");
    std::println("numbers[2] = {}, c string: {}", numbers[2], c_string.get());

    // --- shared_ptr and weak_ptr ------------------------------------------------------
    // The closest thing to an ordinary C# reference, with an (atomic) counter instead of a GC.
    auto shared = std::make_shared<std::string>("shared text");
    auto another = shared; // a copy of the pointer: +1 to the counter, the string is not copied
    std::println("use_count = {}, same object: {}", shared.use_count(), shared == another);
    another.reset(); // give up its share of the ownership
    std::println("use_count after reset = {}", shared.use_count());

    auto root = std::make_shared<TreeNode>("root");
    auto usr = std::make_shared<TreeNode>("usr");
    auto bin = std::make_shared<TreeNode>("bin");
    add_child(root, usr);
    add_child(usr, bin);
    std::println("{} | usr use_count = {}", bin->path(), usr.use_count());
    root.reset(); // the root is destroyed: the weak reference usr->parent has expired
    std::println("{} after the root is destroyed", bin->path());

    // Typical mistakes that C++ does NOT catch (all of them UB):
    //   - returning a reference or a string_view to a local variable;
    //   - keeping an iterator, reference or pointer to a vector element across a push_back
    //     (the vector may have moved to a new buffer);
    //   - touching an object after delete / reset / its owner leaving scope;
    //   - going out of array bounds; reading an uninitialized variable.
    // The tools: warnings (-Wall -Wextra), sanitizers (-fsanitize=address,undefined), static
    // analysers. And above all — RAII and the standard containers instead of manual memory
    // management.
}

// =====================================================================================
//  6. INHERITANCE AND POLYMORPHISM
// =====================================================================================

// An abstract base class. C#: abstract class.
class Shape {
public:
    // A VIRTUAL DESTRUCTOR is mandatory if objects are deleted through a pointer to the base:
    // otherwise the derived destructor is not called (UB).
    virtual ~Shape() = default;

    // "= 0" marks a pure virtual function. C#: abstract.
    [[nodiscard]] virtual double area() const = 0;

    // A virtual function with an implementation. C#: virtual.
    // NOTE: without the word virtual a method is NOT virtual — same as C#, unlike Java.
    [[nodiscard]] virtual std::string name() const { return "shape"; }

    // A non-virtual method that calls virtual ones (the "template method" pattern).
    [[nodiscard]] std::string describe() const {
        return std::format("{} with area {:.2f}", name(), area());
    }
};

// Inheritance. `public` means "is-a". final is like sealed in C#.
class Circle final : public Shape {
public:
    explicit Circle(double radius) : radius_{radius} {}

    // override: the compiler checks that the method really overrides a virtual one.
    [[nodiscard]] double area() const override { return std::numbers::pi * radius_ * radius_; }
    [[nodiscard]] std::string name() const override { return "circle"; }
    [[nodiscard]] double radius() const { return radius_; }

private:
    double radius_;
};

class Rectangle : public Shape {
public:
    Rectangle(double width, double height) : width_{width}, height_{height} {}

    [[nodiscard]] double area() const override { return width_ * height_; }
    [[nodiscard]] std::string name() const override { return "rectangle"; }

protected: // accessible to the class itself and to derived classes
    double width_;
    double height_;
};

class Square final : public Rectangle {
public:
    // Calling the base class constructor. C#: `: base(side, side)`.
    explicit Square(double side) : Rectangle{side, side} {}

    // Calling the base class implementation. C#: base.Name().
    [[nodiscard]] std::string name() const override { return "square, a " + Rectangle::name(); }
};

// There is no separate "interface" entity: it is a class that has only pure virtual
// functions. Multiple inheritance is allowed for any classes.
struct Drawable {
    virtual ~Drawable() = default;
    [[nodiscard]] virtual std::string draw() const = 0;
};

struct Serializable {
    virtual ~Serializable() = default;
    [[nodiscard]] virtual std::string serialize() const = 0;
};

class Label final : public Drawable, public Serializable {
public:
    explicit Label(std::string text) : text_{std::move(text)} {}

    [[nodiscard]] std::string draw() const override { return "[" + text_ + "]"; }
    [[nodiscard]] std::string serialize() const override {
        return std::format("{{\"label\": \"{}\"}}", text_); // {{ and }} are escaped braces
    }

private:
    std::string text_;
};

// Order: constructors run from base to derived, destructors the other way round. While
// the base constructor is running, the object still "is" the base: a virtual call does
// NOT reach the derived class. (In C# it would — in an object whose constructor has not
// run yet.)
struct Base {
    Base() { std::println("    Base ctor sees {}", who()); }
    virtual ~Base() { std::println("    Base dtor"); }
    [[nodiscard]] virtual std::string who() const { return "Base"; }
};

struct Derived : Base {
    Derived() { std::println("    Derived ctor sees {}", who()); }
    ~Derived() override { std::println("    Derived dtor"); }
    [[nodiscard]] std::string who() const override { return "Derived"; }
};

void section06_inheritance() {
    header(6, "Inheritance and polymorphism");

    // Polymorphism works only through a reference or a pointer. A container of heterogeneous
    // objects is a container of (smart) pointers to the base class.
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(1.0));
    shapes.push_back(std::make_unique<Rectangle>(2.0, 3.0));
    shapes.push_back(std::make_unique<Square>(2.0));

    double total = 0.0;
    for (const auto& shape : shapes) {
        total += shape->area(); // a virtual call through the method table (vtable)
        std::println("{}", shape->describe());
        // dynamic_cast is a checked cast down the hierarchy.
        // C#: `if (shape is Circle circle)`.
        if (const auto* circle = dynamic_cast<const Circle*>(shape.get())) {
            std::println("    it is a circle of radius {}", circle->radius());
        }
    }
    std::println("total area {:.2f}", total);

    // "Slicing": copying a derived object into a variable of the base type keeps only the
    // base part. The object sliced is an honest Rectangle, not a Square.
    Square square{2.0};
    Rectangle sliced = square;
    const Shape& reference = square; // through a reference the object stays itself
    std::println("sliced: {} | by reference: {}", sliced.name(), reference.name());

    // Multiple inheritance: one object is visible through both "interfaces".
    Label label{"OK"};
    const Drawable& drawable = label;
    const Serializable& serializable = label;
    std::println("{} {}", drawable.draw(), serializable.serialize());

    {
        Derived derived;
        std::println("    fully constructed object is {}", derived.who());
    }
}

// =====================================================================================
//  7. LAMBDAS AND CALLABLE OBJECTS
// =====================================================================================

// A functor is a class with operator(). A lambda is syntactic sugar for exactly such a
// class: the compiler creates an unnamed type whose fields are the captured variables.
struct Multiplier {
    int factor;
    int operator()(int x) const { return x * factor; }
};

// A higher-order function. A callable is taken as a template parameter: then the call
// is resolved at compile time and inlined. std::invocable is a concept (section 9).
int apply_twice(std::invocable<int> auto&& f, int x) { return f(f(x)); }

// Returning a lambda from a function: the result type is deduced (it cannot be spelled).
auto make_adder(int n) {
    return [n](int x) { return x + n; }; // n is captured BY VALUE: the copy lives inside the lambda
    // Capturing by reference (`[&n]`) would dangle: n dies when make_adder returns.
}

struct Person {
    std::string name;
    int age;
};

void section07_lambdas() {
    header(7, "Lambdas and callable objects");

    // --- Captures --------------------------------------------------------------------
    // [captures](parameters) { body }. A C# closure always captures the VARIABLE
    // (by reference); in C++ the capture mode is chosen explicitly.
    int factor = 3;
    auto by_value = [factor](int x) { return x * factor; }; // a copy of factor inside the lambda
    auto by_reference = [&factor](int x) { return x * factor; }; // a reference to factor
    factor = 10;
    std::println("by value {}, by reference {}", by_value(2), by_reference(2)); // 6 and 20
    // [=] captures everything that is used by value, [&] captures everything by reference.

    // An init-capture plus mutable: the lambda gets mutable state of its own.
    auto next_id = [id = 100]() mutable { return id++; };
    // The calls are separate statements for a reason: the evaluation order of function
    // arguments is NOT defined in C++ (in C# it is strictly left to right), so
    // `print(next_id(), next_id())` would give different results with different compilers.
    int id1 = next_id();
    int id2 = next_id();
    int id3 = next_id();
    std::println("ids: {} {} {}", id1, id2, id3);

    // A move capture: the only way to put a unique_ptr into a lambda.
    auto resource = std::make_unique<std::string>("moved into the lambda");
    auto use_resource = [owned = std::move(resource)] { return owned->size(); };
    std::println("resource moved away: {}, size {}", resource == nullptr, use_resource());

    // A generic lambda: auto parameters make it a template.
    auto smaller = [](const auto& a, const auto& b) { return a < b ? a : b; };
    std::println("{} {} {}", smaller(3, 7), smaller(2.5, 1.5), smaller("pear"s, "apple"s));

    // --- Every kind of "callable" -----------------------------------------------------
    Multiplier triple{3};                       // a functor
    int (*function_pointer)(int, int) = add;    // a function pointer (the int overload is selected)
    int (*from_lambda)(int) = [](int x) { return x + 1; }; // a lambda WITHOUT captures -> a pointer
    std::println("{} {} {} {} {}", triple(5), function_pointer(2, 3), from_lambda(41),
                 apply_twice(triple, 2), apply_twice(make_adder(10), 1));

    // std::function is the "delegate": one type for any callable with a given signature.
    // C#: Func<double, double, double>. The price is an indirect call and possibly an
    // allocation, so where the type is known at compile time, templates are preferred.
    std::map<char, std::function<double(double, double)>> operations{
        {'+', std::plus<>{}}, // ready-made functors from <functional>
        {'*', [](double a, double b) { return a * b; }},
        {'^', [](double a, double b) { return std::pow(a, b); }},
    };
    std::println("6 * 7 = {}, 2 ^ 10 = {}", operations['*'](6, 7), operations['^'](2, 10));

    // Pointers to class members and the universal std::invoke.
    Vec2 v{3, 4};
    double (Vec2::*method)() const = &Vec2::length; // a pointer to a method
    int Person::*field = &Person::age;              // a pointer to a field
    Person ann{"Ann", 30};
    std::println("{} {} {} {}", (v.*method)(), ann.*field, std::invoke(method, v),
                 std::invoke(&Person::name, ann));

    // Partial application: "bind" the leading arguments.
    auto times_two = std::bind_front(std::multiplies<>{}, 2);
    std::println("bind_front: {}", times_two(21));

    // An immediately invoked lambda: complex initialization of a const variable.
    const std::string banner = [&] {
        std::string result = "factor";
        if (factor > 5) result += " is big";
        return result;
    }();
    std::println("{}", banner);

    // --- Lambdas + algorithms + projections -------------------------------------------
    std::vector<Person> people{{"Cid", 35}, {"Ann", 30}, {"Bob", 25}};
    // The third argument is a projection: "compare by the age field".
    // C#: OrderByDescending(p => p.Age).
    std::ranges::sort(people, std::greater<>{}, &Person::age);
    std::println("by age desc: {}", join(people | std::views::transform(&Person::name)));
    auto youngest = std::ranges::min_element(people, {}, &Person::age);
    std::println("youngest: {} ({})", youngest->name, youngest->age);
}

// =====================================================================================
//  8. ALGORITHMS AND RANGES
// =====================================================================================

void section08_algorithms_and_ranges() {
    header(8, "Algorithms and ranges");

    std::vector<int> numbers{5, 3, 8, 1, 9, 2, 7, 4, 6, 10};

    // --- Classic algorithms: an iterator pair [begin, end) ------------------------------
    // An iterator is a generalized pointer: `*it` is the element, `++it` the next one, and
    // end() points one PAST the last element. C#: IEnumerator, but with arithmetic.
    auto seven = std::find(numbers.begin(), numbers.end(), 7);
    int total = std::accumulate(numbers.begin(), numbers.end(), 0); // C#: Sum / Aggregate
    std::println("7 is at index {}, total {}", seven - numbers.begin(), total);

    // --- Range algorithms (C++20): the whole container ----------------------------------
    std::ranges::sort(numbers);
    auto [smallest, largest] = std::ranges::minmax(numbers);
    auto is_even = [](int n) { return n % 2 == 0; };
    std::println("[{}] min {} max {} | any even: {} | all positive: {} | count > 5: {}",
                 join(numbers), smallest, largest, std::ranges::any_of(numbers, is_even),
                 std::ranges::all_of(numbers, [](int n) { return n > 0; }),
                 std::ranges::count_if(numbers, [](int n) { return n > 5; }));

    // Binary search over a sorted range; contains is C++23.
    auto lower = std::ranges::lower_bound(numbers, 6);
    std::println("lower_bound(6) at index {}, contains 11: {}", lower - numbers.begin(),
                 std::ranges::contains(numbers, 11));

    // Removal by a predicate. C#: RemoveAll.
    std::vector<int> odds = numbers;
    std::erase_if(odds, is_even);
    // Transformation in place and into another container.
    std::vector<int> doubled(odds.size());
    std::ranges::transform(odds, doubled.begin(), [](int n) { return n * 2; });
    std::println("odds [{}], doubled [{}]", join(odds), join(doubled));

    // --- Views: lazy pipelines. C#: LINQ ----------------------------------------------
    // Adaptors are joined with the `|` operator. A view computes and stores nothing: it is
    // a description of a traversal. The work happens when someone iterates over it.
    auto square = [](int n) { return n * n; };
    auto even_squares = numbers | std::views::filter(is_even)   // C#: Where
                                | std::views::transform(square); // C#: Select
    std::println("even squares: {}", join(even_squares));

    // Materializing into a container (C++23). C#: ToList().
    auto as_vector = even_squares | std::ranges::to<std::vector>();
    auto as_set = numbers | std::views::transform([](int n) { return n % 3; })
                          | std::ranges::to<std::set>();
    std::println("vector of {} elements, set of remainders [{}]", as_vector.size(), join(as_set));

    // iota is a sequence generator. C#: Enumerable.Range.
    // An infinite range + take_while: only what is asked for gets computed.
    auto below_60 = [](int n) { return n < 60; };
    auto squares_below_60 = std::views::iota(1) | std::views::transform(square)
                                                | std::views::take_while(below_60);
    std::println("iota(1, 6): {} | squares below 60: {}", join(std::views::iota(1, 6)),
                 join(squares_below_60));

    // take / drop / reverse. C#: Take, Skip, Reverse.
    std::println("last three reversed: {} | without first seven: {}",
                 join(numbers | std::views::reverse | std::views::take(3)),
                 join(numbers | std::views::drop(7)));

    // keys / values are projections of map pairs.
    std::map<std::string, int> ages{{"Ann", 30}, {"Bob", 25}, {"Cid", 35}};
    std::println("keys: {} | values: {}", join(ages | std::views::keys),
                 join(ages | std::views::values));

    // split cuts a string without copying: each piece is a subrange of characters.
    std::vector<std::string_view> parts;
    for (auto part : "alpha,beta,gamma"sv | std::views::split(',')) {
        parts.emplace_back(part.begin(), part.end());
    }
    std::println("split: {}", join(parts, " | "));

    // join flattens nested ranges. C#: SelectMany.
    std::vector<std::vector<int>> nested{{1, 2}, {3}, {4, 5, 6}};
    std::println("flattened: {}", join(nested | std::views::join));

    // A view does not own the data: change the source and the traversal result changes too.
    numbers[1] = 100;
    std::println("after numbers[1] = 100: {}", join(even_squares));
    // The C++23 adaptors (zip, enumerate, chunk, slide, ...) are in section 16.
}

// =====================================================================================
//  9. TEMPLATES AND CONCEPTS
// =====================================================================================
//
//  A C# generic is one compiled method that works with any T satisfying its `where`
//  constraints. A C++ template is a RECIPE: for every set of arguments the compiler
//  generates a separate function or class and only then checks the body. Hence:
//    + zero overhead, specializations, computations over types and values;
//    + "duck typing": any type for which the body compiles will do;
//    - a template must be fully visible where it is used (usually in a header);
//    - without concepts the errors are long and arise deep inside.

// --- A function template ----------------------------------------------------------------
template <typename T>
T max_of(T a, T b) {
    return a < b ? b : a; // the requirement "T has operator<" is written nowhere: duck typing
}

// --- Concepts (C++20): named constraints. C#: where T : ... ------------------------------
template <typename T>
concept Number = std::integral<T> || std::floating_point<T>;

// A requires-expression describes what CAN be done with a type: "the object has an
// area() method and the result converts to double". The type need not inherit anything.
template <typename T>
concept HasArea = requires(const T& value) {
    { value.area() } -> std::convertible_to<double>;
};

// A constraint on a template parameter plus a separate requires-clause.
template <std::ranges::input_range Range>
    requires Number<std::ranges::range_value_t<Range>>
auto sum_of(const Range& range) {
    std::ranges::range_value_t<Range> total{}; // "the element type of this range"
    for (const auto& value : range) total += value;
    return total;
}

// --- Variadic templates and fold expressions (C++17) ------------------------------------
// `auto` in a parameter is the abbreviated template syntax; `...` is a parameter pack.
double total_area(const HasArea auto&... shapes) {
    return (0.0 + ... + shapes.area()); // expands to 0.0 + a.area() + b.area() + ...
}

template <typename... Args>
std::string concat(const Args&... args) {
    std::string result;
    // A fold over the comma operator: evaluate an expression for every argument of the pack.
    ((result += std::format("{}", args)), ...);
    return result;
}

// --- A class template with VALUE parameters ---------------------------------------------
// C# has no counterpart. Matrix<double, 2, 3> and Matrix<double, 3, 2> are different
// types, and the sizes are checked at compile time.
template <Number T, std::size_t Rows, std::size_t Cols>
class Matrix {
public:
    constexpr Matrix() = default;

    constexpr Matrix(std::initializer_list<T> values) { // allows writing Matrix{1, 2, 3}
        std::copy_n(values.begin(), std::min(values.size(), data_.size()), data_.begin());
    }

    // A multidimensional operator[] (C++23): m[row, col].
    constexpr T& operator[](std::size_t row, std::size_t col) { return data_[row * Cols + col]; }
    constexpr const T& operator[](std::size_t row, std::size_t col) const {
        return data_[row * Cols + col];
    }

    [[nodiscard]] constexpr Matrix<T, Cols, Rows> transposed() const {
        Matrix<T, Cols, Rows> result;
        for (std::size_t r = 0; r < Rows; ++r) {
            for (std::size_t c = 0; c < Cols; ++c) result[c, r] = (*this)[r, c];
        }
        return result;
    }

private:
    std::array<T, Rows * Cols> data_{}; // the array size is computed from the template parameters
};

// Multiplication is defined only for matching sizes: (R x K) * (K x C) = (R x C).
// Mismatched sizes are a compile error: no suitable function is found at all.
template <Number T, std::size_t R, std::size_t K, std::size_t C>
constexpr Matrix<T, R, C> operator*(const Matrix<T, R, K>& a, const Matrix<T, K, C>& b) {
    Matrix<T, R, C> result;
    for (std::size_t r = 0; r < R; ++r) {
        for (std::size_t c = 0; c < C; ++c) {
            for (std::size_t k = 0; k < K; ++k) result[r, c] += a[r, k] * b[k, c];
        }
    }
    return result;
}

// --- Specialization: a dedicated implementation for particular arguments -----------------
template <typename T>
struct TypeName { // the general case
    static constexpr std::string_view value = "something";
};

template <>
struct TypeName<int> { // a full specialization
    static constexpr std::string_view value = "int";
};

template <typename T>
struct TypeName<std::vector<T>> { // a partial one: for ANY vector
    static constexpr std::string_view value = "vector";
};

template <typename T>
struct TypeName<T*> { // a partial one: for any pointer
    static constexpr std::string_view value = "pointer";
};

// --- if constexpr: branching at compile time (C++17) -------------------------------------
// The branch that is not taken is not instantiated, so it may contain code that does
// not compile at all for the given T.
template <typename T>
std::string describe(const T& value) {
    if constexpr (std::is_arithmetic_v<T>) {
        return std::format("number {}", value);
    } else if constexpr (std::convertible_to<T, std::string_view>) {
        return std::format("text '{}'", std::string_view{value});
    } else if constexpr (std::ranges::range<T>) {
        return std::format("range of {} elements", std::ranges::distance(value));
    } else {
        return "something else";
    }
}

// --- A class template, a deduction guide, a constructor template -------------------------
template <typename T>
class Stack {
public:
    Stack() = default;

    // A constructor template: it accepts a pair of any iterators.
    template <std::input_iterator Iterator>
    Stack(Iterator first, Iterator last) : items_(first, last) {}

    void push(T item) { items_.push_back(std::move(item)); }

    std::optional<T> pop() {
        if (items_.empty()) return std::nullopt;
        T top = std::move(items_.back());
        items_.pop_back();
        return top;
    }

    [[nodiscard]] std::size_t size() const { return items_.size(); }

private:
    std::vector<T> items_;
};

// A deduction guide: how to obtain T from the constructor arguments.
// Thanks to it `Stack s(v.begin(), v.end());` deduces Stack<int> by itself.
template <std::input_iterator Iterator>
Stack(Iterator, Iterator) -> Stack<std::iter_value_t<Iterator>>;

// --- Perfect forwarding ------------------------------------------------------------------
// With type deduction `Args&&` is a "universal" reference: it accepts both lvalues and
// rvalues. std::forward passes the argument on, preserving that category (whether to
// copy or to move is the receiver's decision). decltype(auto) preserves the
// reference-ness of the result.
template <typename Function, typename... Args>
decltype(auto) logged_call(std::string_view label, Function&& function, Args&&... args) {
    std::println("    calling {} with {} argument(s)", label, sizeof...(Args));
    return std::invoke(std::forward<Function>(function), std::forward<Args>(args)...);
}

// --- CRTP: static polymorphism -----------------------------------------------------------
// The base class is parameterized by the derived one and calls its methods WITHOUT
// virtual dispatch: everything is resolved at compile time. (In C++23 the same is done
// more simply with "deducing this", section 16.)
template <typename Derived>
class Describable {
public:
    [[nodiscard]] std::string describe() const {
        const auto& self = static_cast<const Derived&>(*this);
        return std::format("{} #{}", self.kind(), self.id());
    }
};

class Sensor : public Describable<Sensor> {
public:
    [[nodiscard]] std::string_view kind() const { return "sensor"; }
    [[nodiscard]] int id() const { return 7; }
};

// --- SFINAE: how templates were constrained before concepts ------------------------------
// "Substitution failure is not an error": if substituting a type yields an ill-formed
// signature, the template is silently removed from the overload set. Found in any
// older code base.
template <typename T, std::enable_if_t<std::is_integral_v<T>, int> = 0>
bool is_even_legacy(T value) {
    return value % 2 == 0;
}

// The same thing with a concept.
bool is_even(std::integral auto value) { return value % 2 == 0; }

// --- Alias templates and variable templates ----------------------------------------------
template <typename T>
using Grid = std::vector<std::vector<T>>;

template <typename T>
constexpr T golden_ratio = T(1.6180339887498948482L);

// Types usable with total_area: they have no common base class whatsoever.
struct UnitSquare {
    [[nodiscard]] double area() const { return 1.0; }
};

struct Disc {
    double radius;
    [[nodiscard]] double area() const { return std::numbers::pi * radius * radius; }
};

void section09_templates() {
    header(9, "Templates and concepts");

    // Template arguments are deduced from the call arguments; when needed they are explicit.
    std::println("{} {} {} {}", max_of(3, 7), max_of(2.5, 1.5), max_of("apple"s, "pear"s),
                 max_of<double>(3, 7.5));
    // max_of(3, 7.5); // error: T cannot be int and double at the same time

    std::println("sum_of: {} {} | total_area {:.3f} | concat {}", sum_of(std::vector{1, 2, 3}),
                 sum_of(std::array{0.5, 1.5}), total_area(UnitSquare{}, Disc{1.0}, UnitSquare{}),
                 concat("x=", 42, ", pi=", 3.14));
    // sum_of(std::vector<std::string>{}); // error: constraints not satisfied — brief and clear
    static_assert(Number<int> && !Number<std::string>); // a concept is also a boolean constant
    static_assert(HasArea<Disc> && !HasArea<int>);

    // Matrices: the sizes are part of the type.
    constexpr Matrix<int, 2, 3> m{1, 2, 3, 4, 5, 6};
    constexpr auto product = m * m.transposed(); // Matrix<int, 2, 2>, computed at compile time
    static_assert(product[0, 0] == 14 && product[1, 1] == 77);
    // auto bad = m * m; // error: no operator* for Matrix<int, 2, 3> and Matrix<int, 2, 3>
    std::println("m * mT = [[{}, {}], [{}, {}]]", product[0, 0], product[0, 1], product[1, 0],
                 product[1, 1]);

    std::println("TypeName: {} {} {} {}", TypeName<int>::value, TypeName<double>::value,
                 TypeName<std::vector<char>>::value, TypeName<int*>::value);
    std::println("{} | {} | {} | {}", describe(42), describe("text"), describe(std::vector{1, 2}),
                 describe(Disc{2.0}));

    // CLASS template argument deduction (CTAD, C++17): no need to write <int>.
    std::vector source{1, 2, 3}; // std::vector<int>
    std::pair pair{1, 2.5};      // std::pair<int, double>
    Stack stack(source.begin(), source.end()); // Stack<int> — through our deduction guide
    stack.push(4);
    int popped = stack.pop().value_or(-1);
    std::println("pair ({}, {}), popped {}, stack size {}, empty pop: {}", pair.first, pair.second,
                 popped, stack.size(), Stack<int>{}.pop().has_value());

    std::string name = "forwarded";
    auto length = logged_call("size", [](const std::string& s) { return s.size(); }, name);
    auto moved = logged_call("move", [](std::string s) { return s; }, std::move(name));
    std::println("    length {}, moved '{}', the source is now empty: {}", length, moved,
                 name.empty());

    Grid<int> grid(2, std::vector<int>(3, 7));
    std::println("{} | legacy {} | concept {} | grid {}x{} | phi {} {}", Sensor{}.describe(),
                 is_even_legacy(10), is_even(7L), grid.size(), grid[0].size(),
                 golden_ratio<float>, golden_ratio<double>);

    // Types are compile-time data too: decltype and type traits.
    auto lambda = [](int x) { return x * 0.5; };
    static_assert(std::same_as<decltype(lambda(1)), double>);
    static_assert(std::same_as<std::remove_cvref_t<const int&>, int>);
    static_assert(std::same_as<std::common_type_t<int, double>, double>);
}

// =====================================================================================
//  10. SUM TYPES: optional, variant, any
// =====================================================================================

// The "overloaded set of lambdas" idiom for std::visit: the class inherits from all the
// lambdas passed in at once and brings all their operator() into one scope. Three
// lines that show variadic inheritance, a using-declaration with a pack and template
// argument deduction for an aggregate, all together.
template <typename... Functions>
struct overloaded : Functions... {
    using Functions::operator()...;
};

// std::variant is a type-safe union: it holds EXACTLY ONE of the listed alternatives
// and remembers which one. C#: a C# 15 union, or a hierarchy of records + switch.
struct CircleData {
    double radius;
};
struct RectData {
    double width, height;
};
struct TriangleData {
    double a, b, c;
};
using ShapeData = std::variant<CircleData, RectData, TriangleData>;

double area_of(const ShapeData& shape) {
    // std::visit calls the overload that matches the current content.
    // Forget to handle an alternative and it is a compile error (like an exhaustive switch).
    return std::visit(
        overloaded{
            [](const CircleData& c) { return std::numbers::pi * c.radius * c.radius; },
            [](const RectData& r) { return r.width * r.height; },
            [](const TriangleData& t) {
                double s = (t.a + t.b + t.c) / 2; // Heron's formula
                return std::sqrt(s * (s - t.a) * (s - t.b) * (s - t.c));
            },
        },
        shape);
}

// A recursive type: an expression tree. A variant cannot contain itself by value (its
// size would be infinite), so child nodes are held through unique_ptr.
struct Expr; // a forward declaration: "this type exists, the definition comes later"
using ExprPtr = std::unique_ptr<Expr>;

struct Num {
    double value;
};
struct Var {
    std::string name;
};
struct Neg {
    ExprPtr operand;
};
struct Add {
    ExprPtr left, right;
};
struct Mul {
    ExprPtr left, right;
};

struct Expr {
    std::variant<Num, Var, Neg, Add, Mul> node;
};

// Small node "constructors" so that the tree reads like a formula.
ExprPtr num(double value) { return std::make_unique<Expr>(Expr{Num{value}}); }
ExprPtr var(std::string name) { return std::make_unique<Expr>(Expr{Var{std::move(name)}}); }
ExprPtr neg(ExprPtr e) { return std::make_unique<Expr>(Expr{Neg{std::move(e)}}); }
ExprPtr add(ExprPtr l, ExprPtr r) {
    return std::make_unique<Expr>(Expr{Add{std::move(l), std::move(r)}});
}
ExprPtr mul(ExprPtr l, ExprPtr r) {
    return std::make_unique<Expr>(Expr{Mul{std::move(l), std::move(r)}});
}

double eval(const Expr& expr, const std::map<std::string, double>& variables) {
    return std::visit(
        overloaded{
            [](const Num& n) { return n.value; },
            // at() throws std::out_of_range if the variable is missing (section 11).
            [&](const Var& v) { return variables.at(v.name); },
            [&](const Neg& n) { return -eval(*n.operand, variables); },
            [&](const Add& a) { return eval(*a.left, variables) + eval(*a.right, variables); },
            [&](const Mul& m) { return eval(*m.left, variables) * eval(*m.right, variables); },
        },
        expr.node);
}

std::optional<double> safe_sqrt(double x) {
    if (x < 0) return std::nullopt;
    return std::sqrt(x);
}

void section10_sum_types() {
    header(10, "Sum types: optional, variant, any");

    // --- std::optional<T>: a value or "nothing". C#: T? --------------------------------
    std::optional<double> root = safe_sqrt(16.0);
    if (root) { // an optional converts to bool: "is there a value"
        std::println("sqrt = {}", *root); // `*` extracts the value; on an empty optional that is UB
    }
    std::println("value_or: {} | has_value: {}", safe_sqrt(-1.0).value_or(0.0),
                 safe_sqrt(-1.0).has_value());
    // .value() on an empty optional throws std::bad_optional_access — checked access.

    // Monadic operations (C++23): a chain without explicit checks. C#: ?. and ??
    auto described = safe_sqrt(81.0)
                         .and_then(safe_sqrt) // continue if there is a value
                         .transform([](double x) { return std::format("4th root = {}", x); })
                         .or_else([] { return std::optional{"no value"s}; }); // the fallback
    std::println("{} | {}", *described,
                 safe_sqrt(-4.0).transform([](double x) { return x + 1; }).has_value());

    // --- std::variant -----------------------------------------------------------------
    std::vector<ShapeData> shapes{CircleData{1.0}, RectData{2.0, 3.0}, TriangleData{3, 4, 5}};
    for (const auto& shape : shapes) {
        std::print("alternative #{} area {:.3f}; ", shape.index(), area_of(shape));
    }
    std::println("");

    ShapeData shape = RectData{4.0, 5.0};
    // Three ways to look inside without visit:
    bool is_rect = std::holds_alternative<RectData>(shape); // check the type
    if (const auto* rect = std::get_if<RectData>(&shape)) {  // a pointer or nullptr
        std::println("rect {} x {}, is_rect {}", rect->width, rect->height, is_rect);
    }
    try {
        (void)std::get<CircleData>(shape); // throws if another type is stored
    } catch (const std::bad_variant_access& error) {
        std::println("std::get of the wrong type throws: {}", error.what());
    }

    // -(x + 2) * 3
    ExprPtr formula = mul(neg(add(var("x"), num(2.0))), num(3.0));
    std::println("eval = {}", eval(*formula, {{"x", 5.0}}));

    // --- std::any: a value of any type. C#: object + a type check -----------------------
    std::vector<std::any> things{42, "text"s, 3.5};
    for (const auto& thing : things) {
        if (const int* number = std::any_cast<int>(&thing)) { // a pointer or nullptr
            std::print("int {}; ", *number);
        } else if (const auto* string = std::any_cast<std::string>(&thing)) {
            std::print("string '{}'; ", *string);
        } else {
            // type() returns std::type_info — the rudiments of run-time type information.
            std::print("something else, a double: {}; ", thing.type() == typeid(double));
        }
    }
    std::println("");
}

// =====================================================================================
//  11. ERROR HANDLING
// =====================================================================================
//
//  Two approaches coexist in C++:
//    - exceptions — as in C# but without finally: destructors (RAII) play its role;
//    - errors as values: error codes, std::optional, std::expected (C++23).
//  Exceptions suit truly exceptional situations. Where an error is a regular outcome
//  (parsing input, lookups), returning std::expected is increasingly common.

// A custom exception class. The standard hierarchy starts at std::exception.
class ConfigError : public std::runtime_error {
public:
    ConfigError(std::string key, const std::string& message)
        : std::runtime_error{"config key '" + key + "': " + message}, key_{std::move(key)} {}

    [[nodiscard]] const std::string& key() const noexcept { return key_; }

private:
    std::string key_;
};

int read_port(const std::map<std::string, std::string>& config) {
    auto it = config.find("port");
    if (it == config.end()) throw ConfigError{"port", "is missing"}; // thrown BY VALUE
    int port = 0;
    const std::string& text = it->second;
    auto [end, error] = std::from_chars(text.data(), text.data() + text.size(), port);
    if (error != std::errc{} || end != text.data() + text.size()) {
        throw ConfigError{"port", "'" + text + "' is not a number"};
    }
    if (port < 1 || port > 65535) throw std::out_of_range{"port " + text + " is out of range"};
    return port;
}

// An error as a value: std::expected<T, E> holds either the result or the error.
// C#: nothing comparable in the standard library (third-party Result<T, E> types exist).
enum class ParseError { empty, not_a_number, out_of_range };

constexpr std::string_view to_string(ParseError error) {
    switch (error) {
        case ParseError::empty: return "empty input";
        case ParseError::not_a_number: return "not a number";
        case ParseError::out_of_range: return "out of range";
    }
    std::unreachable();
}

std::expected<int, ParseError> parse_int(std::string_view text) {
    if (text.empty()) return std::unexpected{ParseError::empty};
    int value = 0;
    auto [end, error] = std::from_chars(text.data(), text.data() + text.size(), value);
    if (error == std::errc::result_out_of_range) return std::unexpected{ParseError::out_of_range};
    if (error != std::errc{} || end != text.data() + text.size()) {
        return std::unexpected{ParseError::not_a_number};
    }
    return value;
}

std::expected<int, ParseError> parse_port(std::string_view text) {
    // and_then continues the chain only on success; an error flows straight through.
    return parse_int(text).and_then([](int value) -> std::expected<int, ParseError> {
        if (value < 1 || value > 65535) return std::unexpected{ParseError::out_of_range};
        return value;
    });
}

// noexcept is a promise not to throw. Breaking the promise terminates the program
// (std::terminate), but in return the compiler and containers can pick faster paths.
int clamp_percent(int value) noexcept { return std::clamp(value, 0, 100); }

// std::source_location (C++20): the call site is filled in automatically.
// C#: [CallerFilePath], [CallerLineNumber], [CallerMemberName].
void log_here(std::string_view message,
              std::source_location where = std::source_location::current()) {
    std::println("    [line {} in {}] {}", where.line(), where.function_name(), message);
}

void section11_errors() {
    header(11, "Error handling");

    // --- Exceptions ---------------------------------------------------------------------
    const std::vector<std::map<std::string, std::string>> configs{
        {{"port", "8080"}}, {{"host", "localhost"}}, {{"port", "80a"}}, {{"port", "70000"}}};
    for (const auto& config : configs) {
        try {
            std::println("port = {}", read_port(config));
        } catch (const ConfigError& error) { // catch by const reference; the narrower type first
            std::println("config error for key '{}': {}", error.key(), error.what());
        } catch (const std::exception& error) { // the base class of the standard exceptions
            std::println("other error: {}", error.what());
        }
        // catch (...) would catch everything, including non-exceptions such as `throw 42;`
    }

    // During stack unwinding the destructors of all local objects run — that is how RAII
    // works: resources are released without finally. C#: using / try-finally.
    try {
        Tracer guard{"unwound by exception"};
        throw std::runtime_error{"boom"};
    } catch (const std::exception& error) {
        std::println("    caught: {}", error.what());
    }
    std::println("clamp_percent is noexcept: {}, clamp_percent(150) = {}",
                 noexcept(clamp_percent(0)), clamp_percent(150));

    // --- std::expected ----------------------------------------------------------------
    for (std::string_view text : {"8080", "", "80a", "99999999999", "70000"}) {
        if (auto port = parse_port(text)) {
            std::println("'{}' -> port {}", text, *port);
        } else {
            std::println("'{}' -> error: {}", text, to_string(port.error()));
        }
    }
    // transform maps the value, value_or supplies a fallback, or_else handles the error.
    std::println("{} | {}", parse_port("80").transform([](int p) { return p * 2; }).value_or(0),
                 parse_port("oops").value_or(8000));

    // --- Error codes ------------------------------------------------------------------
    // std::error_code is "an error number + a category". System and networking libraries
    // report errors this way: std::filesystem has overloads both with a code and with
    // an exception.
    std::error_code code = std::make_error_code(std::errc::permission_denied);
    std::println("error_code {}: {}", code.value(), code.message());

    log_here("source_location captured the call site");
    // assert(condition) from <cassert> is checked only in debug builds (without NDEBUG);
    // static_assert is checked at compile time (section 12).
}

// =====================================================================================
//  12. COMPILE-TIME EVALUATION
// =====================================================================================
//
//  A constexpr function can be called both at run time and at compile time — whenever
//  the result is needed as a constant. In C# a constant can only be an expression made
//  of literals; here almost the whole language runs at compile time: loops, classes,
//  containers and even dynamic memory (if it is freed before the evaluation ends).

constexpr std::uint64_t factorial(unsigned n) { return n <= 1 ? 1 : n * factorial(n - 1); }

// static_assert is a compile-time check. If it fails, the program does not build.
static_assert(factorial(20) == 2'432'902'008'176'640'000ULL);

// The CRC-32 table and the function itself are constexpr.
constexpr std::array<std::uint32_t, 256> make_crc_table() {
    std::array<std::uint32_t, 256> table{};
    for (std::uint32_t i = 0; i < 256; ++i) {
        std::uint32_t crc = i;
        for (int bit = 0; bit < 8; ++bit) {
            crc = (crc & 1u) != 0 ? (crc >> 1) ^ 0xEDB8'8320u : crc >> 1;
        }
        table[i] = crc;
    }
    return table;
}

inline constexpr auto crc_table = make_crc_table(); // 1 KB of data computed by the compiler

constexpr std::uint32_t crc32(std::string_view text) {
    std::uint32_t crc = 0xFFFF'FFFFu;
    for (char ch : text) {
        crc = crc_table[(crc ^ static_cast<unsigned char>(ch)) & 0xFFu] ^ (crc >> 8);
    }
    return ~crc;
}

// The reference CRC-32 value: a unit test executed by the compiler.
static_assert(crc32("123456789") == 0xCBF4'3926u);

// A constexpr function with a std::vector inside: memory is allocated and freed right
// at compile time (C++20).
constexpr int count_primes_below(std::size_t limit) {
    std::vector<bool> composite(limit, false);
    int count = 0;
    for (std::size_t n = 2; n < limit; ++n) {
        if (composite[n]) continue;
        ++count;
        for (std::size_t m = n * 2; m < limit; m += n) composite[m] = true;
    }
    return count;
}

static_assert(count_primes_below(100) == 25);

// A consteval ("immediate") function (C++20) MUST be evaluated at compile time.
// A throw during constant evaluation is a compile error that points at the exact place.
consteval int checked_percent(int value) {
    if (value < 0 || value > 100) throw std::invalid_argument{"percent must be within 0..100"};
    return value;
}

constexpr int default_quality = checked_percent(85);
// constexpr int broken = checked_percent(150); // does not compile

// The "switch on strings" the language lacks: the labels are hashes computed at compile time.
constexpr std::uint32_t fnv1a(std::string_view text) {
    std::uint32_t hash = 2'166'136'261u;
    for (char ch : text) {
        hash ^= static_cast<unsigned char>(ch);
        hash *= 16'777'619u;
    }
    return hash;
}

std::string_view command_kind(std::string_view command) {
    switch (fnv1a(command)) { // and here the same function runs at run time
        case fnv1a("start"):
        case fnv1a("stop"):
            return "lifecycle";
        case fnv1a("status"):
            return "query";
        default:
            return "unknown";
    }
}

// User-defined literals: `1.5_km`. The suffix is an ordinary function, operator"".
struct Meters {
    double value;
    constexpr auto operator<=>(const Meters&) const = default;
};
constexpr Meters operator""_m(long double value) { return {static_cast<double>(value)}; }
constexpr Meters operator""_km(long double value) { return {static_cast<double>(value) * 1000.0}; }
constexpr Meters operator+(Meters a, Meters b) { return {a.value + b.value}; }

static_assert(1.5_km + 500.0_m == 2000.0_m);

// A class object as a template parameter (C++20). FixedString lets a string literal be
// passed to a template: Quantity<"kg"> and Quantity<"N"> are different types.
template <std::size_t Size>
struct FixedString {
    char chars[Size]{};

    constexpr FixedString(const char (&text)[Size]) { // an implicit conversion from a literal
        std::copy_n(text, Size, chars);
    }

    [[nodiscard]] constexpr std::string_view view() const { return {chars, Size - 1}; }
};

template <FixedString Unit>
struct Quantity {
    double value;

    static constexpr std::string_view unit() { return Unit.view(); }

    friend constexpr Quantity operator+(Quantity a, Quantity b) { return {a.value + b.value}; }
};

// Computations over TYPES: a fold over a pack of types.
template <typename T, typename... Candidates>
constexpr bool is_one_of = (std::same_as<T, Candidates> || ...);

static_assert(is_one_of<int, char, int, double> && !is_one_of<float, char, int>);

// Walking a tuple: std::apply unpacks the tuple into arguments and a fold visits them.
template <typename... Items>
std::string tuple_to_string(const std::tuple<Items...>& tuple) {
    return std::apply(
        [](const Items&... items) {
            std::string result;
            ((result += std::format("<{}>", items)), ...);
            return result;
        },
        tuple);
}

// constinit: a guarantee that a global variable is initialized at compile time (not
// before main() in an unspecified order) while it still remains mutable.
constinit int launch_count = default_quality / 85;

void section12_compile_time() {
    header(12, "Compile-time evaluation");

    std::println("20! = {}, crc32(\"hello\") = {:#010x}, quality {}", factorial(20), crc32("hello"),
                 default_quality);

    // A table filled by an immediately invoked constexpr lambda.
    constexpr auto squares = [] {
        std::array<int, 8> table{};
        for (std::size_t i = 0; i < table.size(); ++i) table[i] = static_cast<int>(i * i);
        return table;
    }();
    static_assert(squares[7] == 49);
    std::println("squares [{}], primes below 100: {}", join(squares), count_primes_below(100));

    // The result of a constexpr function fits wherever a constant is required: an array
    // size, a template argument, a case label.
    std::array<std::byte, factorial(4)> buffer{}; // std::array<std::byte, 24>
    std::println("buffer of {} bytes | commands: {} {} {}", buffer.size(), command_kind("stop"),
                 command_kind("status"), command_kind("dance"));

    Quantity<"kg"> mass{2.5};
    Quantity<"kg"> total = mass + Quantity<"kg">{0.5};
    Quantity<"N"> force{9.81};
    // auto nonsense = mass + force; // error: there is no operator+ for different units
    std::println("{} {} | {} {} | {} m", total.value, total.unit(), force.value, force.unit(),
                 (1.5_km + 250.0_m).value);

    ++launch_count;
    std::println("{} | launch_count {}", tuple_to_string(std::tuple{1, "two", 3.5}), launch_count);
}

// =====================================================================================
//  13. LOW LEVEL: memory, bits, allocators
// =====================================================================================

// Fields are laid out in declaration order, with alignment. The order affects the size.
struct Padded { // 1 + 7 (padding) + 8 + 4 + 4 (padding) = 24 bytes
    char tag;
    double value;
    int count;
};

struct Reordered { // 8 + 4 + 1 + 3 (padding) = 16 bytes
    double value;
    int count;
    char tag;
};

struct alignas(64) CacheAligned { // align to a 64-byte boundary (a cache line)
    int counter;
};

struct Flags { // bit-fields: several values in one machine word
    unsigned ready : 1;
    unsigned mode : 3;
    unsigned level : 4;
};

// union: all fields share the same memory. In C++ only the field written last may be
// read (reading another one is UB), so bytes are reinterpreted with std::bit_cast or
// std::memcpy, and "this type or that type" is expressed with std::variant.
union IntOrFloat {
    std::int32_t as_int;
    float as_float;
};

// A fixed-capacity vector with no heap: raw memory + manual control of object lifetime.
// This is how std::vector and std::optional work inside. (C++26 brings a ready-made
// std::inplace_vector.) C#: stackalloc / [InlineArray] + manual length tracking.
template <typename T, std::size_t Capacity>
class StaticVector {
public:
    StaticVector() = default;
    StaticVector(const StaticVector&) = delete; // copying is disabled for brevity
    StaticVector& operator=(const StaticVector&) = delete;

    // The destructors of the live elements have to be called manually.
    ~StaticVector() { std::destroy_n(data(), size_); }

    template <typename... Args>
    T& emplace_back(Args&&... args) {
        if (size_ == Capacity) throw std::length_error{"StaticVector is full"};
        // construct_at is "placement new": create an object in memory that is ALREADY allocated.
        T* created = std::construct_at(data() + size_, std::forward<Args>(args)...);
        ++size_;
        return *created;
    }

    void pop_back() {
        --size_;
        std::destroy_at(data() + size_); // run the destructor without freeing the memory
    }

    T& operator[](std::size_t index) { return data()[index]; }
    [[nodiscard]] std::size_t size() const { return size_; }
    T* begin() { return data(); } // begin()/end() make the class usable in a range-based for
    T* end() { return data() + size_; }

private:
    // reinterpret_cast: "treat this address as the address of a T". The most dangerous cast.
    T* data() { return reinterpret_cast<T*>(storage_); }

    alignas(T) std::byte storage_[Capacity * sizeof(T)]; // storage for the elements, no objects yet
    std::size_t size_ = 0;
};

void section13_low_level() {
    header(13, "Low level: memory, bits, allocators");

    // --- Sizes and alignment ----------------------------------------------------------
    std::println("sizeof: Padded {}, Reordered {}, CacheAligned {} | alignof: double {}, {}",
                 sizeof(Padded), sizeof(Reordered), sizeof(CacheAligned), alignof(double),
                 alignof(CacheAligned));
    Flags flags{.ready = 1, .mode = 5, .level = 9};
    std::println("Flags: {} byte(s), ready {}, mode {}, level {}", sizeof(Flags),
                 static_cast<unsigned>(flags.ready), static_cast<unsigned>(flags.mode),
                 static_cast<unsigned>(flags.level));

    // --- Pointers and arithmetic ------------------------------------------------------
    int data[5] = {10, 20, 30, 40, 50};
    int* pointer = data; // an array "decays" to a pointer to its first element
    int third = *(pointer + 2); // the same as pointer[2] and data[2]
    std::ptrdiff_t distance = &data[4] - pointer; // a pointer difference is measured in elements
    std::println("third {}, distance {}, bytes between: {}", third, distance,
                 distance * static_cast<std::ptrdiff_t>(sizeof(int)));
    // pointer + 10 points outside the array: merely computing it is already UB.

    // --- Bytes and bits ---------------------------------------------------------------
    float one = 1.0f;
    auto bits = std::bit_cast<std::uint32_t>(one); // C++20: "the same bytes, another type"
    std::uint32_t copied = 0;
    std::memcpy(&copied, &one, sizeof one); // the way it was done before C++20
    // *reinterpret_cast<std::uint32_t*>(&one) violates the strict aliasing rule: UB.
    IntOrFloat number{.as_int = 7};
    number.as_float = 2.5f; // as_float is the "active" member now; as_int must not be read
    std::println("1.0f = {:#x} (memcpy {:#x}), union holds {}", bits, copied, number.as_float);

    auto raw_bytes = std::as_bytes(std::span{data}); // a "byte view" of the array
    std::println("{} bytes, first: {:#04x}, little-endian: {}", raw_bytes.size(),
                 std::to_integer<int>(raw_bytes[0]), std::endian::native == std::endian::little);

    std::uint32_t mask = 0b1011'0000u;
    std::println("popcount {}, countr_zero {}, rotl {:#x}, bit_ceil(100) {}, byteswap {:#010x}",
                 std::popcount(mask), std::countr_zero(mask), std::rotl(mask, 28),
                 std::bit_ceil(100u), std::byteswap(0x1122'3344u));
    std::bitset<8> bitset{0b0101'0011};
    bitset.flip(0).set(7);
    std::println("bitset {} has {} bits set", bitset.to_string(), bitset.count());

    // --- Manual lifetime management ---------------------------------------------------
    {
        StaticVector<Tracer, 3> tracers; // Tracer from section 4 shows construction and destruction
        tracers.emplace_back("first");
        tracers.emplace_back("second");
        tracers.pop_back();
        std::println("    {} element(s) left, {} bytes, all on the stack", tracers.size(),
                     sizeof(tracers));
    } // the StaticVector destructor destroys "first"

    // --- Polymorphic allocators (C++17) -----------------------------------------------
    // A container takes memory from a given "resource". Here it is a buffer on the stack:
    // not a single heap call, and all the memory is released at once. This is how arenas
    // in games and real-time systems are built.
    std::array<std::byte, 1024> arena{};
    std::pmr::monotonic_buffer_resource resource{arena.data(), arena.size(),
                                                 std::pmr::null_memory_resource()};
    std::pmr::vector<int> fast{&resource};
    fast.reserve(100);
    for (int i = 0; i < 100; ++i) fast.push_back(i * i);
    // std::less defines a total order for pointers (comparing pointers to different
    // objects with `<` is unspecified).
    const auto* storage = reinterpret_cast<const std::byte*>(fast.data());
    bool inside = !std::less<>{}(storage, arena.data()) &&
                  std::less<>{}(storage, arena.data() + arena.size());
    std::println("pmr vector: {} elements, last {}, storage is inside the arena: {}", fast.size(),
                 fast.back(), inside);

    // --- Interop with C ---------------------------------------------------------------
    // C headers are included directly (<cstdlib>, <cstring>, ...); no wrappers like
    // P/Invoke are needed. A captureless lambda converts to a plain function pointer.
    int unsorted[] = {42, -7, 19, 0, 3};
    std::qsort(unsorted, std::size(unsorted), sizeof(int), [](const void* a, const void* b) {
        int x = *static_cast<const int*>(a);
        int y = *static_cast<const int*>(b);
        return (x > y) - (x < y);
    });
    std::println("qsort: [{}], strlen: {}", join(unsorted), std::strlen("hello from C"));
}

// =====================================================================================
//  14. CONCURRENCY
// =====================================================================================
//
//  Threads, mutexes and atomics are part of the standard library. The main difference
//  from C#: a data race (unsynchronized concurrent writing and reading of an ordinary
//  variable from different threads) is UB, not "merely a wrong result". And a mutex is
//  in no way tied to the data it protects: the discipline is entirely on the programmer.

// A thread-safe queue built on a mutex and a condition variable.
// C#: BlockingCollection<T> or System.Threading.Channels.
template <typename T>
class Channel {
public:
    void send(T value) {
        {
            std::scoped_lock lock{mutex_}; // an RAII lock. C#: lock (sync) { ... }
            queue_.push(std::move(value));
        } // the mutex is released here, before the notification
        ready_.notify_one();
    }

    void close() {
        {
            std::scoped_lock lock{mutex_};
            closed_ = true;
        }
        ready_.notify_all();
    }

    // Waits for a value; std::nullopt means "the channel is closed and empty".
    std::optional<T> receive() {
        std::unique_lock lock{mutex_}; // a unique_lock can release the mutex temporarily
        // wait releases the mutex, sleeps until notified and re-checks the condition.
        ready_.wait(lock, [this] { return !queue_.empty() || closed_; });
        if (queue_.empty()) return std::nullopt;
        T value = std::move(queue_.front());
        queue_.pop();
        return value;
    }

private:
    std::mutex mutex_;
    std::condition_variable ready_;
    std::queue<T> queue_;
    bool closed_ = false;
};

// thread_local: every thread has its own copy. C#: [ThreadStatic] / ThreadLocal<T>.
thread_local int calls_in_this_thread = 0;

// A static local variable is initialized once, on the first call, and that
// initialization is thread-safe. C#: Lazy<T>.
const std::vector<int>& small_primes() {
    static const std::vector<int> primes = [] {
        std::vector<int> result;
        for (int n = 2; n < 50; ++n) {
            bool is_prime = std::ranges::none_of(result, [n](int p) { return n % p == 0; });
            if (is_prime) result.push_back(n);
        }
        return result;
    }();
    return primes;
}

void section14_concurrency() {
    header(14, "Concurrency");

    // --- std::jthread (C++20) ---------------------------------------------------------
    // An OS thread. Unlike the older std::thread, it joins in its destructor by itself
    // and carries a cooperative cancellation token. C#: Thread + CancellationToken.
    std::atomic<int> ticks{0};
    {
        std::jthread ticker{[&ticks](std::stop_token stop) {
            while (!stop.stop_requested()) {
                ++ticks;
                std::this_thread::sleep_for(1ms); // a std::chrono literal
            }
        }};
        std::this_thread::sleep_for(20ms);
    } // the jthread destructor: request_stop() and join()
    std::println("ticker made some ticks: {}", ticks > 0);

    // --- A mutex and an atomic --------------------------------------------------------
    long long counter = 0; // an ordinary variable: accessed only under the mutex
    std::mutex counter_mutex;
    std::atomic<long long> atomic_counter{0}; // C#: Interlocked
    {
        std::vector<std::jthread> workers;
        for (int i = 0; i < 4; ++i) {
            workers.emplace_back([&] {
                for (int n = 0; n < 1000; ++n) {
                    {
                        std::scoped_lock lock{counter_mutex};
                        ++counter;
                    }
                    atomic_counter.fetch_add(1, std::memory_order_relaxed);
                    ++calls_in_this_thread; // each thread has its own counter
                }
            });
        }
    } // all threads have finished and are joined
    std::println("mutex counter {}, atomic counter {}, thread_local in main: {}", counter,
                 atomic_counter.load(), calls_in_this_thread);

    // --- std::async and std::future. C#: Task.Run and task.Result -----------------------
    std::future<long long> sum = std::async(std::launch::async, [] {
        long long total = 0;
        for (int i = 1; i <= 1000; ++i) total += i;
        return total;
    });
    // get() waits for the result (and rethrows the exception if the task failed).
    std::println("async sum = {}", sum.get());

    // std::promise is a "manual" source of a result. C#: TaskCompletionSource<T>.
    std::promise<std::string> promise;
    std::future<std::string> answer = promise.get_future();
    std::jthread producer{[&promise] { promise.set_value("a value from another thread"); }};
    std::println("promise delivered: {}", answer.get());

    // --- Producers and a consumer through Channel ---------------------------------------
    Channel<int> channel;
    std::vector<int> received;
    {
        std::jthread consumer{[&] {
            while (auto value = channel.receive()) received.push_back(*value);
        }};
        std::vector<std::jthread> producers;
        for (int id = 0; id < 3; ++id) {
            producers.emplace_back([&channel, id] {
                for (int i = 0; i < 3; ++i) channel.send(id * 10 + i);
            });
        }
        producers.clear(); // the jthread destructors wait for the producers
        channel.close();   // the consumer drains the queue and leaves its loop
    }
    std::ranges::sort(received); // the arrival order of messages is unspecified
    std::println("received: {}", join(received));

    // --- C++20 primitives -------------------------------------------------------------
    std::latch all_done{3}; // a single-use counter. C#: CountdownEvent
    std::atomic<int> finished{0};
    std::vector<std::jthread> tasks;
    for (int i = 0; i < 3; ++i) {
        tasks.emplace_back([&] {
            ++finished;
            all_done.count_down();
        });
    }
    all_done.wait(); // wait until the counter reaches zero
    std::println("latch released after {} tasks | {} primes below 50, lazily initialised",
                 finished.load(), small_primes().size());
    // There are also std::shared_mutex (C#: ReaderWriterLockSlim), std::counting_semaphore,
    // std::barrier, std::call_once, and parallel versions of the algorithms:
    // std::sort(std::execution::par, first, last).
}

// =====================================================================================
//  15. COROUTINES (C++20)
// =====================================================================================
//
//  A coroutine is a function whose body contains co_yield, co_await or co_return. The
//  compiler turns it into a state object (a "frame") that can suspend itself.
//  C#: `yield return` is co_yield, `await` is co_await.
//
//  The fundamental difference: the language provides only the MECHANISM. What a
//  "generator" or a "task" is gets decided by a library: the coroutine's return type
//  must contain a nested promise_type whose methods the compiler calls at key points.
//  Both types are written by hand below to show what they are made of.

// --- A generator: a lazy sequence. C#: IEnumerable<T> + yield return ---------------------
template <typename T>
class Generator {
public:
    struct promise_type {
        const T* current = nullptr; // the address of the value handed out by co_yield

        Generator get_return_object() { return Generator{Handle::from_promise(*this)}; }
        std::suspend_always initial_suspend() noexcept { return {}; } // do not start right away
        std::suspend_always final_suspend() noexcept { return {}; }   // keep the frame alive
        std::suspend_always yield_value(const T& value) noexcept {    // called on co_yield
            current = std::addressof(value);
            return {}; // suspend and return control to the caller
        }
        void return_void() noexcept {}
        void unhandled_exception() { throw; } // rethrow an exception from the coroutine body
    };

    using Handle = std::coroutine_handle<promise_type>; // the "remote control" of the coroutine

    explicit Generator(Handle handle) : handle_{handle} {}
    Generator(Generator&& other) noexcept : handle_{std::exchange(other.handle_, {})} {}
    Generator(const Generator&) = delete;
    Generator& operator=(const Generator&) = delete;
    ~Generator() {
        if (handle_) handle_.destroy(); // the frame lives on the heap; destroy it manually
    }

    // A minimal iterator so that the generator works in a range-based for.
    struct Sentinel {};
    struct Iterator {
        Handle handle;
        const T& operator*() const { return *handle.promise().current; }
        Iterator& operator++() {
            handle.resume(); // resume the coroutine until the next co_yield
            return *this;
        }
        bool operator==(Sentinel) const { return handle.done(); }
    };

    Iterator begin() {
        handle_.resume(); // run to the first co_yield
        return Iterator{handle_};
    }
    Sentinel end() { return {}; }

private:
    Handle handle_;
};

// The coroutine itself looks like an ordinary function. An infinite loop is fine:
// execution proceeds only when the caller asks for the next value.
Generator<std::uint64_t> fibonacci() {
    std::uint64_t a = 0, b = 1;
    while (true) {
        co_yield a;
        a = std::exchange(b, a + b);
    }
}

Generator<std::string> tokens(std::string text) { // the parameter is copied into the frame
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t end = text.find(' ', start);
        if (end == std::string::npos) end = text.size();
        if (end > start) co_yield text.substr(start, end - start);
        start = end + 1;
    }
}

// --- A scheduler: a queue of ready coroutines and timers -----------------------------------
// The role played in C# by the task scheduler and SynchronizationContext is taken here
// by a class of some thirty lines that runs on a single thread.
class Scheduler {
public:
    using Clock = std::chrono::steady_clock;

    // An object that can be co_awaited must have three methods (it is an "awaitable").
    struct SleepAwaiter {
        Scheduler& scheduler;
        Clock::time_point wake_at;

        bool await_ready() const noexcept { return false; } // "the result is not ready yet"
        void await_suspend(std::coroutine_handle<> handle) { // where to put the suspended coroutine
            scheduler.timers_.emplace(wake_at, handle);
        }
        void await_resume() const noexcept {} // the result of the co_await expression
    };

    SleepAwaiter sleep_for(std::chrono::milliseconds delay) { // C#: Task.Delay
        return SleepAwaiter{*this, Clock::now() + delay};
    }

    // The event loop: resume coroutines as their timers fire.
    void run() {
        while (!timers_.empty()) {
            auto next = timers_.begin();
            std::this_thread::sleep_until(next->first);
            auto handle = next->second;
            timers_.erase(next);
            handle.resume();
        }
    }

private:
    std::multimap<Clock::time_point, std::coroutine_handle<>> timers_;
};

// --- Job: a fire-and-forget coroutine. C#: async void -------------------------------------
struct Job {
    struct promise_type {
        Job get_return_object() noexcept { return {}; }
        std::suspend_never initial_suspend() noexcept { return {}; } // starts immediately
        std::suspend_never final_suspend() noexcept { return {}; }   // the frame destroys itself
        void return_void() noexcept {}
        void unhandled_exception() { std::terminate(); }
    };
};

// --- Task<T>: a lazy task with a result. C#: Task<T> --------------------------------------
template <typename T>
class Task {
public:
    struct promise_type {
        std::optional<T> result;
        std::exception_ptr error;
        std::coroutine_handle<> continuation = std::noop_coroutine(); // who awaits this task

        Task get_return_object() { return Task{Handle::from_promise(*this)}; }
        std::suspend_always initial_suspend() noexcept { return {}; } // lazy: waits for a co_await

        // When the task reaches its end, control is transferred to the awaiting coroutine.
        auto final_suspend() noexcept {
            struct Awaiter {
                bool await_ready() const noexcept { return false; }
                std::coroutine_handle<> await_suspend(
                    std::coroutine_handle<promise_type> finished) const noexcept {
                    return finished.promise().continuation; // "symmetric transfer"
                }
                void await_resume() const noexcept {}
            };
            return Awaiter{};
        }

        void return_value(T value) { result = std::move(value); } // called on co_return
        void unhandled_exception() { error = std::current_exception(); }
    };

    using Handle = std::coroutine_handle<promise_type>;

    explicit Task(Handle handle) : handle_{handle} {}
    Task(Task&& other) noexcept : handle_{std::exchange(other.handle_, {})} {}
    Task(const Task&) = delete;
    Task& operator=(const Task&) = delete;
    ~Task() {
        if (handle_) handle_.destroy();
    }

    // Task is itself an awaitable: `co_await task` starts the task and waits for it.
    bool await_ready() const noexcept { return false; }
    std::coroutine_handle<> await_suspend(std::coroutine_handle<> awaiting) noexcept {
        handle_.promise().continuation = awaiting;
        return handle_; // resume the task; the awaiter stays suspended
    }
    T await_resume() {
        if (handle_.promise().error) std::rethrow_exception(handle_.promise().error);
        return std::move(*handle_.promise().result);
    }

private:
    Handle handle_;
};

// Asynchronous functions: they look like the C# ones, only there is no async in the
// signature — the words co_await / co_return in the body are what makes a coroutine.
Task<int> fetch_length(Scheduler& scheduler, std::string name, int delay_ms) {
    co_await scheduler.sleep_for(std::chrono::milliseconds{delay_ms});
    co_return static_cast<int>(name.size()) * delay_ms;
}

Task<int> fetch_both(Scheduler& scheduler) {
    int first = co_await fetch_length(scheduler, "alpha", 20); // sequentially, like await in C#
    int second = co_await fetch_length(scheduler, "beta", 10);
    co_return first + second;
}

Job run_and_store(Task<int> task, int& output) { // a bridge between Task and synchronous code
    output = co_await std::move(task);
}

Job worker(Scheduler& scheduler, std::string name, int delay_ms, std::vector<std::string>& log) {
    co_await scheduler.sleep_for(std::chrono::milliseconds{delay_ms});
    log.push_back(std::move(name));
}

void section15_coroutines() {
    header(15, "Coroutines");

    // Generators.
    std::vector<std::uint64_t> first_fibonacci;
    for (std::uint64_t value : fibonacci()) {
        if (value > 100) break; // the consumer cuts the infinite sequence short
        first_fibonacci.push_back(value);
    }
    std::vector<std::string> words;
    for (const std::string& word : tokens("coroutines are  lazy state machines")) {
        words.push_back(word);
    }
    std::println("fibonacci: {} | tokens: {}", join(first_fibonacci), join(words, "|"));

#ifdef __cpp_lib_generator
    // C++23: the ready-made std::generator — no need to write your own Generator any more.
    auto squares = []() -> std::generator<int> {
        for (int i = 1;; ++i) co_yield i * i;
    };
    std::println("std::generator: {}", join(squares() | std::views::take(5)));
#else
    std::println("std::generator is not available in this standard library");
#endif

    // Three independent coroutines on one thread: each "sleeps" without blocking the others.
    Scheduler scheduler;
    std::vector<std::string> log;
    worker(scheduler, "slow", 30, log);
    worker(scheduler, "fast", 10, log);
    worker(scheduler, "medium", 20, log);
    int total = 0;
    run_and_store(fetch_both(scheduler), total);
    std::println("coroutines started, nothing finished yet: log is empty: {}", log.empty());
    scheduler.run(); // the event loop: wakes coroutines while timers remain
    std::println("finished in order: {} | fetch_both -> {}", join(log), total);
}

// =====================================================================================
//  16. C++23, C++26, MODULES
// =====================================================================================
//
//  The language is revised every three years; compilers catch up with the standard
//  gradually. Feature-test macros tell what is available: __cpp_* for the language,
//  __cpp_lib_* for the library (header <version>) and __has_cpp_attribute for attributes.
//  C#: #if NET9_0_OR_GREATER.

// --- Deducing this (C++23): an explicit "this object" parameter --------------------------
// One function template instead of a const / non-const pair of overloads, and a
// replacement for CRTP: the type Self is deduced from what the method is called on.
struct TextBuilder {
    std::string text;

    template <typename Self>
    Self&& append(this Self&& self, std::string_view part) {
        self.text += part;
        return std::forward<Self>(self); // an lvalue returns by reference, a temporary is moved
    }
};

// --- if consteval (C++23): different code for compile time and run time ------------------
constexpr double fast_or_exact_sqrt(double x) {
    if consteval {
        double guess = x > 1 ? x / 2 : 1.0; // at compile time: Newton's method
        for (int i = 0; i < 60; ++i) guess = (guess + x / guess) / 2;
        return guess;
    } else {
        return std::sqrt(x); // at run time: the library function
    }
}

// --- static operator() (C++23): a stateless functor passes no hidden this ----------------
struct IsPositive {
    static constexpr bool operator()(int value) { return value > 0; }
};

// The C++26 examples are enabled only if the file is built with -std=c++26 (or newer)
// AND the compiler already supports the particular feature.

// --- Pack indexing (C++26) --------------------------------------------------------------
#if __cplusplus > 202302L && defined(__cpp_pack_indexing)
template <typename... Types>
constexpr auto last_of(Types... values) {
    return values...[sizeof...(Types) - 1]; // this used to require recursion or a tuple
}
#endif

// --- `= delete` with a reason (C++26). C#: [Obsolete("...", error: true)] ----------------
#if __cplusplus > 202302L && defined(__cpp_deleted_function)
void legacy_draw(int handle) = delete("use Canvas::draw instead");
#endif

void section16_modern_cpp() {
    header(16, "C++23, C++26, modules");
    std::println("__cplusplus = {}", __cplusplus);

    // Deducing this.
    TextBuilder builder;
    builder.append("deducing").append(" this");
    std::string built = TextBuilder{}.append("temporary ").append("object").text;
    // A recursive lambda: previously a lambda could not refer to itself.
    auto fibonacci_number = [](this auto self, int n) -> int {
        return n < 2 ? n : self(n - 1) + self(n - 2);
    };
    std::println("{} | {} | fib(20) = {}", builder.text, built, fibonacci_number(20));

    constexpr double at_compile_time = fast_or_exact_sqrt(2.0);
    double at_run_time = fast_or_exact_sqrt(2.0);
    std::println("if consteval: {:.6f} vs {:.6f} | static operator(): {}", at_compile_time,
                 at_run_time, std::ranges::count_if(std::array{-1, 2, 3}, IsPositive{}));

#if __has_cpp_attribute(assume)
    // [[assume(expr)]] (C++23): a promise to the optimizer. Break the promise and it is UB.
    int divisor = 8;
    [[assume(divisor > 0)]];
    std::println("[[assume]]: 100 / divisor = {}", 100 / divisor);
#endif

    // --- New range adaptors (C++23) -----------------------------------------------------
    [[maybe_unused]] std::vector<std::string> names{"Ann", "Bob", "Cid"};
    [[maybe_unused]] std::vector<int> scores{90, 75, 82};
#ifdef __cpp_lib_ranges_zip
    for (const auto& [name, score] : std::views::zip(names, scores)) { // C#: Zip
        std::print("{}:{} ", name, score);
    }
    std::println("<- zip");
#endif
#ifdef __cpp_lib_ranges_enumerate
    for (const auto& [index, name] : names | std::views::enumerate) { // C#: Select((x, i) => ...)
        std::print("{}:{} ", index, name);
    }
    std::println("<- enumerate");
#endif
#ifdef __cpp_lib_ranges_chunk
    for (auto chunk : std::views::iota(1, 8) | std::views::chunk(3)) { // C#: Chunk(3)
        std::print("[{}] ", join(chunk));
    }
    std::println("<- chunk");
#endif
#ifdef __cpp_lib_ranges_slide
    for (auto window : scores | std::views::slide(2)) { // a sliding window
        std::print("[{}] ", join(window));
    }
    std::println("<- slide");
#endif
#ifdef __cpp_lib_ranges_cartesian_product
    for (const auto& [letter, digit] : std::views::cartesian_product("ab"sv, std::array{1, 2})) {
        std::print("{}{} ", letter, digit); // C#: from a in A from b in B
    }
    std::println("<- cartesian_product");
#endif
#ifdef __cpp_lib_ranges_fold
    // fold_left folds a range left to right starting from an initial value. C#: Aggregate.
    std::println("fold_left: {}", std::ranges::fold_left(scores, 0, std::plus<>{}));
#endif

#ifdef __cpp_lib_format_ranges
    // Ranges, tuples and maps print out of the box.
    std::println("format ranges: {} {} {}", scores, std::pair{1, "one"},
                 std::map<std::string, int>{{"a", 1}});
#endif

#ifdef __cpp_lib_move_only_function
    // std::move_only_function: a "delegate" that can hold non-copyable objects.
    auto state = std::make_unique<int>(41);
    std::move_only_function<int()> task = [state = std::move(state)] { return *state + 1; };
    std::println("move_only_function: {}", task());
#endif

#ifdef __cpp_lib_mdspan
    // std::mdspan: a multidimensional "view" over a flat array.
    // C#: Span2D<T> from CommunityToolkit.HighPerformance.
    std::array<double, 6> flat{1, 2, 3, 4, 5, 6};
    std::mdspan grid{flat.data(), 2, 3}; // 2 rows, 3 columns, the data is not copied
    grid[1, 2] = 60.0;
    std::println("mdspan {}x{}: grid[1, 2] = {}, flat[5] = {}", grid.extent(0), grid.extent(1),
                 grid[1, 2], flat[5]);
#endif

#ifdef __cpp_lib_flat_map
    // std::flat_map: a map built on two sorted vectors — dense memory, fast lookup,
    // slow insertion.
    std::flat_map<std::string, int> flat_ages{{"Bob", 25}, {"Ann", 30}};
    flat_ages["Cid"] = 35;
    std::println("flat_map keys: {}", join(flat_ages.keys()));
#endif

    // --- C++26 ------------------------------------------------------------------------
#if __cplusplus > 202302L && defined(__cpp_pack_indexing)
    std::println("pack indexing: last_of(1, 2.5, 'z') = {}", last_of(1, 2.5, 'z'));
#endif
#if __cplusplus > 202302L && defined(__cpp_placeholder_variables)
    {
        // `_` is a placeholder name, "the value is of no interest"; it may be repeated in a scope.
        std::mutex mutex;
        auto [_, minor_version] = std::pair{26, 1};
        std::scoped_lock _{mutex};
        std::println("placeholder variables: minor = {}", minor_version);
    }
#endif
#if __cplusplus > 202302L && defined(__cpp_deleted_function)
    // legacy_draw(1); // a compile error with your own text: "use Canvas::draw instead"
    std::println("= delete(\"reason\") is supported");
#endif

    // The rest of C++26 is only just appearing in compilers, so what follows is comments:
    // these fragments were NOT compiled here and follow the text of the standard proposals.
    //
    // Static reflection (P2996): `^^T` yields a value that describes an entity, `[: r :]`
    // turns it back into code. An enum to a string without macros or code generation:
    //
    //     template <typename E>
    //     constexpr std::string_view enum_name(E value) {
    //         template for (constexpr auto e :
    //                       std::define_static_array(std::meta::enumerators_of(^^E)))
    //             if (value == [:e:]) return std::meta::identifier_of(e);
    //         return "<unknown>";
    //     }
    //
    // Contracts (P2900): pre- and postconditions right in the function declaration.
    //
    //     double checked_sqrt(double x)
    //         pre(x >= 0)
    //         post(result: result >= 0);
    //
    // In the library: std::execution (senders and receivers — a model of asynchrony),
    // std::inplace_vector, std::simd, <linalg> (BLAS on top of mdspan), <hazard_pointer>, <rcu>.
    //
    // Modules (C++20) replace the textual #include: an interface is compiled once and
    // macros do not leak out. Building them needs build-system support (CMake 3.28+),
    // so the example does not fit into a single file:
    //
    //     // math.cppm                              // main.cpp
    //     export module math;                      import math;
    //     export int add(int a, int b) {           import std;   // C++23: the whole library
    //         return a + b;                        int main() { std::println("{}", add(2, 3)); }
    //     }
}

// =====================================================================================
//  ENTRY POINT
// =====================================================================================

// main returns the process exit code; `return 0;` at the end of main may be omitted.
// C#: static int Main(string[] args).
int main() {
    try {
        section01_basics();
        section02_values_references_pointers();
        section03_strings_and_containers();
        section04_classes_and_raii();
        section05_smart_pointers();
        section06_inheritance();
        section07_lambdas();
        section08_algorithms_and_ranges();
        section09_templates();
        section10_sum_types();
        section11_errors();
        section12_compile_time();
        section13_low_level();
        section14_concurrency();
        section15_coroutines();
        section16_modern_cpp();
        std::println("\nAll 16 sections completed.");
    } catch (const std::exception& error) {
        // An exception that nobody caught ends the program through std::terminate.
        std::println(stderr, "unhandled exception: {}", error.what());
        return 1;
    }
}
