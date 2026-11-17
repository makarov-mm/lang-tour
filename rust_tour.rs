// =====================================================================================
//  RUST FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
// =====================================================================================
//
//  Build and run (only rustc is needed; no Cargo and no third-party crates):
//
//      rustc --edition 2024 rust_tour.rs
//      ./rust_tour                          (Windows: rust_tour.exe)
//
//  Built-in unit tests (section 12):
//
//      rustc --edition 2024 --test rust_tour.rs -o rust_tour_tests
//      ./rust_tour_tests
//
//  Verified with rustc 1.97 (edition 2024); older versions have not been tested.
//
//  How to read. Each section is a function `sectionNN_*`; the types and functions a
//  section needs are declared right before it. `main()` at the end of the file calls the
//  sections in order. A "C#:" note shows the closest C# counterpart. Commented-out lines
//  with an error code (E0382 and so on) are code the compiler REFUSES to build: uncomment
//  one and read the message — Rust diagnostics are a tutorial in themselves.
//
//  The main differences from C# to keep in mind from the first line:
//
//   1. No GC and no runtime. Memory is released deterministically — when the owner of
//      a value goes out of scope. The compiler proves that references are valid.
//   2. No null and no exceptions. Their place is taken by Option<T> and Result<T, E>.
//   3. No classes and no inheritance. There is data (struct, enum), behaviour (impl)
//      and traits (interfaces on steroids).
//   4. Everything is immutable by default; mutability is requested explicitly (`mut`).
//   5. Generics are monomorphized like C++ templates: separate machine code for every
//      set of types. Generics do not exist at run time, and neither does reflection.
//   6. Values are moved, not copied by reference: for a String, `let b = a;` makes `a`
//      unusable. That is section 3, the most important one in this file.
//
//  Contents:
//    1. Basics: variables, types, expressions       10. Lifetimes
//    2. Functions, tuples, arrays, slices, strings  11. Smart pointers, interior mutability
//    3. Ownership, moves, borrowing                 12. Modules, attributes, tests
//    4. Structs and methods                         13. Concurrency
//    5. Enums and pattern matching                  14. Macros
//    6. Error handling                              15. Compile-time evaluation
//    7. Collections                                 16. Advanced type system
//    8. Closures and iterators                      17. unsafe and FFI
//    9. Traits and generics                         18. async/await from the inside
// =====================================================================================

// A crate-level attribute (`#!` means "applies to the whole file"). C#: #pragma warning disable.
#![allow(dead_code)] // a teaching file: some items are declared for show only

// `use` is the counterpart of C# `using`: it brings names into scope. Braces group names.
// Part of std is available without imports (the "prelude"): Option, Result, Vec, String,
// Box, Clone, Drop, Iterator, Future and so on.
use std::any::Any;
use std::borrow::Cow;
use std::cell::{Cell, RefCell};
use std::collections::{BTreeMap, BinaryHeap, HashMap, HashSet, VecDeque};
use std::error::Error;
use std::ffi::{c_char, c_int, c_void};
use std::fmt;
use std::marker::PhantomData;
use std::mem::MaybeUninit;
use std::pin::{Pin, pin};
use std::rc::{Rc, Weak};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, LazyLock, Mutex, RwLock, mpsc};
use std::task::{Context, Poll, Wake, Waker};
use std::thread;
use std::time::{Duration, Instant};

/// Prints a section header.
/// Three slashes start a documentation comment (C#: `/// <summary>`); the body is Markdown.
fn header(number: u32, title: &str) {
    println!("\n=== {number:>2}. {title} ===");
}

// =====================================================================================
//  1. BASICS: variables, types, expressions, control flow
// =====================================================================================

/// A compile-time constant. C#: `const int MaxPoints = 100_000;`.
/// The type is mandatory; the name is SCREAMING_SNAKE_CASE (the compiler checks naming style).
const MAX_POINTS: u32 = 100_000;

/// A global variable with a fixed address. C#: `static readonly`.
/// Mutable global state means atomics and Mutex (section 13) or `static mut`,
/// which is reachable from unsafe code only (section 17).
static GREETING: &str = "Hello";

fn section01_basics() {
    header(1, "Basics: variables, types, control flow");

    // --- Variables ----------------------------------------------------------------
    // `let` declares a variable; the type is inferred (like `var` in C#).
    // DIFFERENCE FROM C#: a variable is IMMUTABLE by default.
    let x = 5; // i32 is the default integer type
    // x = 6;  // E0384: cannot assign twice to immutable variable `x`
    let mut y = 10; // `mut` allows modification
    y += x;

    // Shadowing: the same name can be declared again, even with a different type.
    // In C# that is error CS0128; in Rust it is an idiom: "parsed the string, kept the name".
    let input = "42";
    let input: i32 = input.parse().expect("not a number"); // now input is a number
    println!("x = {x}, y = {y}, input = {input}"); // {x} captures the variable, like $"{x}"
    println!("{GREETING}, MAX_POINTS = {MAX_POINTS}");

    // --- Scalar types -------------------------------------------------------------
    // The width is part of the type name: i8..i128, u8..u128, isize/usize (pointer-sized),
    // f32/f64. C#: sbyte/short/int/long/Int128, byte/ushort/uint/ulong, nint/nuint.
    let byte: u8 = 255;
    let million = 1_000_000_i64; // a type suffix plus digit separators
    let (hex, octal, binary, ascii) = (0xFF, 0o77, 0b1010_1010, b'A'); // b'A' is a u8
    let big: u128 = 2_u128.pow(100);
    let ratio = 2.5_f32;
    let flag = true;
    // char is a Unicode scalar value, 4 bytes (in C# a char is a 16-bit UTF-16 code unit).
    let letter = 'é';
    println!("{byte} {million} {hex} {octal} {binary} {ascii} {big} {ratio} {flag} {letter}");
    println!(
        "size_of::<char>() = {}, size_of::<usize>() = {}",
        size_of::<char>(),
        size_of::<usize>()
    );

    // --- Conversions --------------------------------------------------------------
    // There are NO implicit numeric conversions at all: `1_i32 + 1_i64` does not compile (E0308).
    let small: i32 = 300;
    let widened: i64 = small.into(); // lossless — through the From/Into traits (section 9)
    let truncated = small as u8; // `as` is an explicit cast that silently drops the high bits: 44
    let checked = u8::try_from(small); // a checked conversion -> Result (Err here)
    let floored = 3.99_f64 as i32; // towards zero: 3. NaN -> 0, out of range -> saturation
    println!("{widened} {truncated} {checked:?} {floored}");

    // --- Overflow -----------------------------------------------------------------
    // C#: wraps silently by default (unchecked). Rust: a panic in debug builds, wrapping
    // in release builds. It is better to name the behaviour you want explicitly:
    let max = u8::MAX;
    println!(
        "wrapping {} | checked {:?} | saturating {} | overflowing {:?}",
        max.wrapping_add(1),    // 0
        max.checked_add(1),     // None
        max.saturating_add(1),  // 255
        max.overflowing_add(1)  // (0, true)
    );

    // --- Everything is an expression ------------------------------------------------
    // `if` returns a value (no separate ?: operator is needed). A block `{}` returns the
    // value of its last expression if that expression is NOT followed by a semicolon.
    let parity = if x % 2 == 0 { "even" } else { "odd" };
    let squared_plus_one = {
        let t = x * x;
        t + 1 // no `;` => this is the value of the block
    };
    println!("{x} is {parity}, x*x+1 = {squared_plus_one}");

    // --- Loops --------------------------------------------------------------------
    // `loop` is an infinite loop; `break` can return a value from it.
    let mut power = 1_u32;
    let first_over_1000 = loop {
        power *= 2;
        if power > 1000 {
            break power;
        }
    };

    // `while` works as in C#. `for` works ONLY with iterators: there is no `for (;;)` counter.
    let mut countdown = 3;
    while countdown > 0 {
        countdown -= 1;
    }
    let mut sum = 0;
    for i in 0..5 {
        sum += i; // 0, 1, 2, 3, 4 — the upper bound is excluded
    }
    for i in (1..=3).rev() {
        sum += i; // 3, 2, 1 — `..=` includes the upper bound
    }
    for (index, ch) in "abc".chars().enumerate() {
        print!("{index}:{ch} "); // print! does not add a newline
    }
    println!("| first power of two over 1000 = {first_over_1000}, sum = {sum}");

    // Loop labels: break/continue for an OUTER loop.
    // (C# only got `break outer;` in C# 15; before that it took a goto or a flag.)
    'outer: for i in 1..10 {
        for j in 1..10 {
            if i * j == 42 {
                println!("found 42 = {i} * {j}");
                break 'outer;
            }
        }
    }

    // --- match --------------------------------------------------------------------
    // Like a C# switch expression, but it MUST cover every case (otherwise E0004).
    let description = match x {
        0 => "zero",
        1 | 2 => "small",         // alternatives
        3..=9 => "digit",         // a range
        _ if x < 0 => "negative", // `_` plus a guard condition
        _ => "large",             // the default arm
    };
    println!("{x} is a {description}");

    // The unit type `()` is "a value that carries no information". A function without `->`
    // returns it. C#: void — except that `()` is a real type and can be used as a generic
    // argument (for example, `Result<(), E>` means "success with no data").
    println!("size_of::<()>() = {}", size_of::<()>());
}

// =====================================================================================
//  2. FUNCTIONS, TUPLES, ARRAYS, SLICES, STRINGS
// =====================================================================================

/// Parameter and result types are always written in a signature: type inference works
/// only INSIDE functions. The last expression without `;` is the return value.
/// C#: `static int Add(int a, int b) => a + b;`
///
/// Rust has no function overloading, no default parameter values and no named arguments.
/// Instead: different names (`new` / `with_capacity`), `Option<T>`, builders and traits.
fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// Several results are returned as a tuple. C#: `(int Quotient, int Remainder)`.
fn div_rem(a: i32, b: i32) -> (i32, i32) {
    (a / b, a % b)
}

/// A slice `&[T]` is a "fat pointer" (address + length) to someone else's data, no copying.
/// It accepts an array, a Vec, or a part of either. C#: ReadOnlySpan<T>.
fn sum_slice(values: &[i32]) -> i32 {
    let mut total = 0;
    for v in values {
        total += v;
    }
    total
}

/// `&mut [T]` is a mutable slice. C#: Span<T>.
fn double_in_place(values: &mut [i32]) {
    for v in values {
        *v *= 2; // `*` dereferences the reference to write to the place it points at
    }
}

/// `&str` is a string slice. String parameters are almost always taken as `&str`: both
/// a literal and a `&String` can be passed. The result is a slice of the input as well.
fn first_word(text: &str) -> &str {
    text.split_whitespace().next().unwrap_or("")
}

fn section02_functions_and_data() {
    header(2, "Functions, tuples, arrays, slices, strings");

    // --- Tuples -------------------------------------------------------------------
    let triple = (1, "one", 2.5); // the type is (i32, &str, f64)
    let (number, name, _) = triple; // destructuring; `_` means "not interested"
    let (quotient, remainder) = div_rem(17, 5);
    println!(
        "{number} {name} {} | 17 / 5 = {quotient} rem {remainder} | {}",
        triple.2,
        add(2, 3)
    );

    // --- Arrays -------------------------------------------------------------------
    // `[T; N]`: the length is part of the type and the data lives on the stack. It is a
    // VALUE, not a reference to the heap like `int[]` in C#: assignment copies every element.
    let primes: [i32; 5] = [2, 3, 5, 7, 11];
    let zeros = [0_u8; 16]; // sixteen zeros
    let matrix = [[1, 2, 3], [4, 5, 6]]; // [[i32; 3]; 2] — one contiguous block of memory
    let mut copy = primes; // a bitwise copy of the whole array
    copy[0] = 100;
    println!(
        "{primes:?} vs {copy:?}, zeros.len() = {}, matrix[1][2] = {}",
        zeros.len(),
        matrix[1][2]
    );

    // Going out of bounds is a panic (C#: IndexOutOfRangeException), not memory corruption.
    // Safe access without a panic is `get`, which returns an Option (section 5).
    println!(
        "primes.get(1) = {:?}, primes.get(10) = {:?}",
        primes.get(1),
        primes.get(10)
    );

    // --- Slices -------------------------------------------------------------------
    let middle = &primes[1..4]; // [3, 5, 7] — not a copy but a "window" into the array
    let mut data = [1, 2, 3];
    double_in_place(&mut data); // an array coerces to a slice implicitly
    println!(
        "middle = {middle:?}, sum = {}, doubled = {data:?}",
        sum_slice(middle)
    );

    // --- Strings ------------------------------------------------------------------
    // Two main types, both UTF-8 (not UTF-16 as in C#):
    //   String — owns a heap buffer and can grow (closer to StringBuilder);
    //   &str   — a slice of someone else's bytes (closer to ReadOnlySpan<char>).
    //            A literal is a &'static str.
    let literal: &str = "hello";
    let mut owned = String::from("Hello"); // or "Hello".to_string()
    owned.push_str(", world");
    owned.push('!');
    let word = first_word(&owned); // &String coerces to &str automatically
    let message = format!("{owned} has {} bytes, first word: {word}", owned.len());
    println!("{literal} | {message}"); // format! ≈ $"..." — it returns a String

    // There is no `s[i]` indexing: a character takes 1 to 4 bytes in UTF-8.
    let accented = "Grüße";
    println!(
        "'{accented}': {} bytes, {} chars, first char {:?}, bytes[0..4] = '{}'",
        accented.len(),           // 7
        accented.chars().count(), // 5
        accented.chars().next(),  // Some('G')
        &accented[0..4]           // a BYTE slice; cutting a character in half panics
    );

    // Handy methods: most of them return slices or lazy iterators rather than copies.
    let csv = "  alpha, beta ,gamma  ";
    let fields: Vec<&str> = csv.split(',').map(|s| s.trim()).collect();
    println!(
        "{fields:?} | {} | {} | {:?}",
        csv.trim().to_uppercase(),
        csv.replace(' ', ""),
        csv.find("beta") // Option<usize>: a position in bytes
    );

    // Literals.
    let raw = r#"C:\dir\file "quoted""#; // a raw string: no escaping (C#: @"" and """ """)
    let multiline = "line one
line two"; // an ordinary literal may contain a line break
    let continued = "one logical \
                     line"; // a trailing `\` swallows the line break and the indentation
    let bytes = b"ASCII"; // a byte string: &[u8; 5]
    println!(
        "{raw} | {} lines | {continued} | {bytes:?}",
        multiline.lines().count()
    );

    // --- Formatting -----------------------------------------------------------------
    // The mini-language resembles C#: width, alignment, precision, radix.
    // {:?} is debug output (the Debug trait); {:#?} is the same, pretty-printed.
    println!(
        "[{:>8.3}] [{:<6}] [{:^6}] [{:08.2}] [{:#x}] [{:#010b}] [{:e}] [{:+}]",
        9.87654, "ab", "mid", 2.5, 255, 5, 1234.5, 7
    );
    let width = 6;
    // Variable names, argument positions and a width taken from a variable (`width$`).
    println!(
        "[{number:>width$}] [{0}/{1}/{0}] [{triple:?}]",
        quotient, remainder
    );
}

// =====================================================================================
//  3. OWNERSHIP, MOVES, BORROWING
// =====================================================================================
//
//  The ownership rules:
//    1) every value has exactly ONE owner;
//    2) when the owner goes out of scope, the value is destroyed (dropped);
//    3) assignment and passing to a function MOVE the value instead of copying it.
//
//  The borrowing rule — at any moment a value has
//    EITHER any number of shared references `&T` (read-only),
//    OR exactly one exclusive reference `&mut T` (read and write).
//
//  The compiler (the borrow checker) enforces these rules. They rule out use-after-free,
//  double free, dangling references, iterator invalidation and data races —
//  with no GC and no run-time overhead.

/// A type with a destructor. The `Drop` trait is the counterpart of `IDisposable.Dispose()`,
/// but it is called AUTOMATICALLY and deterministically. No `using` is needed: it is implied.
struct Noisy(&'static str);

impl Drop for Noisy {
    fn drop(&mut self) {
        println!("    drop({})", self.0);
    }
}

/// Takes a String by value: ownership moves into the function and the caller loses it.
fn consume(text: String) -> usize {
    text.len()
} // `text` is destroyed here and its heap buffer is freed

/// Borrows for reading. Taking `&str` is more idiomatic — that is what the Clippy linter
/// points out; `&String` is kept here for clarity and the warning is switched off.
#[allow(clippy::ptr_arg)]
fn inspect(text: &String) -> usize {
    text.len()
}

/// Borrows for writing.
fn append_bang(text: &mut String) {
    text.push('!');
}

/// Returning a value hands ownership to the caller — the buffer is not copied.
fn make_greeting(name: &str) -> String {
    format!("Hello, {name}")
}

fn section03_ownership() {
    header(3, "Ownership, moves, borrowing");

    // --- Moves ----------------------------------------------------------------------
    let s1 = String::from("data");
    let s2 = s1; // the buffer now belongs to s2; s1 is considered uninitialized
    // println!("{s1}"); // E0382: borrow of moved value: `s1`
    //
    // In C#, `var s2 = s1;` would copy the reference and both names would see one object.
    // Rust never has "two owners" — which is exactly why it needs no garbage collector.

    let s3 = s2.clone(); // a deep copy — always explicit and visible in the code
    println!("s2 = {s2}, s3 = {s3}");

    // Types marked Copy (numbers, bool, char, `&T` references, tuples and arrays of Copy
    // types) are copied bitwise — like a C# struct. For them a "move" keeps the original.
    let n1 = 5;
    let n2 = n1;
    println!("n1 = {n1}, n2 = {n2}");

    // --- Borrowing ----------------------------------------------------------------
    let mut text = make_greeting("Rust");
    let length = inspect(&text); // `&text` is a shared reference
    append_bang(&mut text); // `&mut text` is an exclusive reference
    println!("{text} (was {length} bytes)");
    let consumed = consume(text); // text is moved into the function and destroyed there
    // println!("{text}"); // E0382: value borrowed here after move
    println!("consumed {consumed} bytes");

    // The borrow checker at work. The equivalent C# code (`foreach` + `list.Add`) fails at
    // run time with InvalidOperationException; here it simply does not compile.
    let mut scores = vec![10, 20, 30];
    let first = &scores[0]; // a reference into the vector
    // scores.push(40); // E0502: push may reallocate the buffer while `first` is still needed
    println!("first = {first}");
    scores.push(40); // allowed now: `first` is no longer used (non-lexical lifetimes)

    let mut name = String::from("a");
    let exclusive = &mut name;
    // let second = &mut name; // E0499: cannot borrow `name` as mutable more than once
    exclusive.push('b');
    println!("scores = {scores:?}, name = {name}");

    // A dangling reference is impossible:
    // fn dangle<'a>() -> &'a String { let s = String::new(); &s } // E0515

    // --- RAII and destruction order -------------------------------------------------
    {
        let _a = Noisy("a");
        let _b = Noisy("b");
        let c = Noisy("c");
        drop(c); // early destruction: the drop function simply takes ownership
        println!("    end of scope");
    } // b and then a are destroyed here — in reverse order of declaration

    // `let _ = ...` destroys the value at once; `let _name = ...` at the end of the block.
    let _ = Noisy("temporary");
    println!("    after temporary");

    // --- Replacing a value in place -------------------------------------------------
    // A value cannot simply be taken out from behind `&mut` (it would leave a hole),
    // but it can be swapped for another one.
    let mut current = String::from("old");
    let previous = std::mem::replace(&mut current, String::from("new"));
    let taken = std::mem::take(&mut current); // leaves the default value behind: ""
    println!("previous = {previous}, taken = {taken}, current = '{current}'");
}

// =====================================================================================
//  4. STRUCTS AND METHODS
// =====================================================================================

/// A struct with named fields. C#: the closest match is a `record struct`.
///
/// `#[derive(...)]` generates implementations of standard traits (the way `record` gives
/// you Equals and ToString): Debug — printing with {:?}; Clone, Copy — copying;
/// PartialEq — the == operator; PartialOrd — ordering; Default — a default value.
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Default)]
struct Vec2 {
    x: f64,
    y: f64,
}

/// Behaviour is added in `impl` blocks (there can be any number of them).
impl Vec2 {
    /// An associated constant. C#: `public static readonly Vec2 Zero`.
    const ZERO: Vec2 = Vec2 { x: 0.0, y: 0.0 };

    /// An associated function (no self) is the counterpart of a static method.
    /// The language has no constructors; by convention the "constructor" is called `new`.
    fn new(x: f64, y: f64) -> Self {
        Self { x, y } // shorthand for `Vec2 { x: x, y: y }`
    }

    /// `&self` — the method reads the object (borrows it).
    fn length(&self) -> f64 {
        self.x.hypot(self.y)
    }

    /// `&mut self` — the method modifies the object; it can only be called on a `mut` variable.
    fn scale(&mut self, factor: f64) {
        self.x *= factor;
        self.y *= factor;
    }

    /// `self` by value — the method CONSUMES the object. For a Copy type that is just a copy.
    fn normalized(self) -> Self {
        let length = self.length();
        if length == 0.0 {
            self
        } else {
            Self::new(self.x / length, self.y / length)
        }
    }
}

/// Operator overloading means implementing traits from `std::ops`.
/// C#: `public static Vec2 operator +(Vec2 a, Vec2 b)`.
impl std::ops::Add for Vec2 {
    type Output = Vec2; // the result type is an associated type of the trait
    fn add(self, rhs: Vec2) -> Vec2 {
        Vec2::new(self.x + rhs.x, self.y + rhs.y)
    }
}

impl std::ops::Sub for Vec2 {
    type Output = Vec2;
    fn sub(self, rhs: Vec2) -> Vec2 {
        Vec2::new(self.x - rhs.x, self.y - rhs.y)
    }
}

/// The right-hand operand may have a different type: `Vec2 * f64`.
impl std::ops::Mul<f64> for Vec2 {
    type Output = Vec2;
    fn mul(self, factor: f64) -> Vec2 {
        Vec2::new(self.x * factor, self.y * factor)
    }
}

impl std::ops::Neg for Vec2 {
    type Output = Vec2;
    fn neg(self) -> Vec2 {
        Vec2::new(-self.x, -self.y)
    }
}

/// Compound assignment `+=` is a separate trait. (In C#, `+=` is derived from `+`;
/// defining it separately has only been possible since C# 14.)
impl std::ops::AddAssign for Vec2 {
    fn add_assign(&mut self, rhs: Vec2) {
        self.x += rhs.x;
        self.y += rhs.y;
    }
}

/// `Display` is the "human" output used by `{}`. C#: `override ToString()`.
impl fmt::Display for Vec2 {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        // Honour the precision requested by the caller: for `{:.1}`, precision() == Some(1).
        let precision = f.precision().unwrap_or(2);
        write!(f, "({:.precision$}, {:.precision$})", self.x, self.y)
    }
}

/// A tuple struct and the newtype idiom: a new type with zero overhead.
/// `Meters` and `Seconds` cannot be mixed up although both wrap an f64.
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Meters(f64);

#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Seconds(f64);

fn speed(distance: Meters, time: Seconds) -> f64 {
    distance.0 / time.0 // tuple struct fields are accessed by index
}

/// A unit struct: no data, 0 bytes. Useful as a marker or as a carrier for a trait.
struct Marker;

/// A struct that owns heap data (a String): it is not Copy and is moved on assignment,
/// but it can be Clone.
#[derive(Debug, Clone, PartialEq, Default)]
struct Particle {
    name: String,
    position: Vec2,
    velocity: Vec2,
    mass: f64,
}

impl Particle {
    fn kinetic_energy(&self) -> f64 {
        0.5 * self.mass * self.velocity.length().powi(2)
    }

    /// An integration step: state is modified through `&mut self`.
    fn advance(&mut self, dt: f64) {
        self.position += self.velocity * dt;
    }
}

fn section04_structs() {
    header(4, "Structs and methods");

    let mut v = Vec2::new(3.0, 4.0);
    v.scale(2.0);
    // One object in three formats: Display, Display with a precision, Debug.
    println!("{v} | {v:.0} | {v:?} | length = {}", v.length());

    let combined = -(v + Vec2::new(1.0, 1.0) * 2.0 - Vec2::ZERO);
    println!(
        "combined = {combined}, unit = {:.3}, default = {}",
        v.normalized(),
        Vec2::default()
    );
    println!("speed = {} m/s", speed(Meters(100.0), Seconds(9.58)));
    // speed(Seconds(9.58), Meters(100.0)); // E0308: mismatched types — the point of a newtype

    // "Struct update syntax": take the remaining fields from another value. C#: `with { }`.
    let electron = Particle {
        name: String::from("electron"),
        mass: 9.109e-31,
        velocity: Vec2::new(2.0e6, 0.0),
        ..Default::default()
    };
    let mut muon = Particle {
        name: "muon".to_string(),
        mass: 1.884e-28,
        ..electron.clone()
    };
    muon.advance(1.0e-6);

    // Destructuring a struct: `..` skips the remaining fields.
    let Particle { name, position, .. } = &muon;
    println!("{name} at {position}, E = {:.3e} J", muon.kinetic_energy());
    println!("equal: {}, electron = {electron:?}", electron == muon); // PartialEq comes from derive

    // No hidden object headers and no method tables: the size is the sum of the fields.
    println!(
        "size_of: Vec2 = {}, Marker = {}, Particle = {}",
        size_of::<Vec2>(),
        size_of::<Marker>(),
        size_of::<Particle>() // String (pointer + length + capacity = 24) + 2 * Vec2 + f64
    );
}

// =====================================================================================
//  5. ENUMS AND PATTERN MATCHING
// =====================================================================================

/// A Rust `enum` is a sum type (a tagged union): every variant can carry its own data.
/// C#: a hierarchy of records plus a switch, or a `union` from C# 15.
#[derive(Debug, Clone, PartialEq)]
enum Shape {
    Circle { radius: f64 }, // a variant with named fields
    Rectangle { width: f64, height: f64 },
    Triangle(f64, f64, f64), // a tuple variant
    Point,                   // a variant without data
}

impl Shape {
    fn area(&self) -> f64 {
        // `match` must cover ALL variants. Add a new variant and the compiler points at
        // every place in the program that has to be updated.
        match self {
            Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle(a, b, c) => {
                let s = (a + b + c) / 2.0;
                (s * (s - a) * (s - b) * (s - c)).sqrt() // Heron's formula
            }
            Shape::Point => 0.0,
        }
    }
}

/// A "plain" enum as in C#: explicit values and a chosen underlying type.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
#[repr(u8)]
enum Level {
    Low = 1,
    Medium = 5,
    High = 10,
}

/// `Option<T>` replaces null. In std it is declared literally like this:
///     enum Option<T> { None, Some(T) }
/// "There may be no value" is visible in the type, and T cannot be reached without a check.
/// C#: `T?` — except that the check is mandatory and it works the same way for every type.
///
/// The loop is written by hand for clarity. The idiomatic version is a one-liner with an
/// iterator (section 8): `values.iter().copied().find(|v| v % 2 == 0)`.
#[allow(clippy::manual_find)]
fn find_even(values: &[i32]) -> Option<i32> {
    for &value in values {
        if value % 2 == 0 {
            return Some(value); // `return` is for early exits
        }
    }
    None
}

fn section05_enums_and_patterns() {
    header(5, "Enums and pattern matching");

    let shapes = [
        Shape::Circle { radius: 1.0 },
        Shape::Rectangle {
            width: 2.0,
            height: 3.0,
        },
        Shape::Triangle(3.0, 4.0, 5.0),
        Shape::Point,
    ];
    for shape in &shapes {
        println!("{shape:?} -> area {:.3}", shape.area());
    }

    // `if let` — when only one variant matters. C#: `if (shape is Circle { Radius: var r })`.
    if let Shape::Circle { radius } = &shapes[0] {
        println!("the first shape is a circle of radius {radius}");
    }

    // let chains (edition 2024): patterns and ordinary conditions joined with `&&`.
    let numbers = [1, 3, 4, 7, 10];
    if let Some(even) = find_even(&numbers)
        && even > 2
        && let Some(square) = even.checked_mul(even)
    {
        println!("first even number {even}, its square {square}");
    }

    // `while let` — a loop that runs while the pattern matches.
    let mut stack = vec![1, 2, 3];
    while let Some(top) = stack.pop() {
        print!("popped {top}; ");
    }
    println!();

    // Patterns: tuples, alternatives, ranges, `@` bindings, guard conditions.
    for point in [(0, 0), (5, 0), (2, -2), (7, 30), (-4, 9)] {
        let text = match point {
            (0, 0) => "origin".to_string(),
            (x, 0) | (0, x) => format!("on an axis at {x}"),
            (x, y) if x == -y => format!("on the anti-diagonal ({x}, {y})"),
            (x @ 1..=9, _) => format!("x is a small positive number: {x}"),
            _ => "somewhere else".to_string(),
        };
        println!("{point:?}: {text}");
    }

    // Slice patterns. C#: list patterns `[first, .., last]`.
    for slice in [&numbers[..0], &numbers[..1], &numbers[..]] {
        match slice {
            [] => println!("empty"),
            [single] => println!("one element: {single}"),
            [first, middle @ .., last] => {
                println!("first {first}, last {last}, {} in between", middle.len())
            }
        }
    }

    // `matches!` tests a pattern and yields a bool. C#: `x is A or B`.
    let has_flat = shapes
        .iter()
        .any(|s| matches!(s, Shape::Point | Shape::Rectangle { .. }));
    println!("has point or rectangle: {has_flat}");

    // `let ... else`: "get the value or leave" — without extra nesting. The else branch
    // must contain code that does not fall through: continue, break, return, panic!.
    let mut settings = Vec::new();
    for line in ["width = 42", "broken line", "height = tall", "depth=7"] {
        let Some((key, raw_value)) = line.split_once('=') else {
            continue; // no '=' in the line
        };
        let Ok(value) = raw_value.trim().parse::<i32>() else {
            continue; // the right-hand side is not a number (Ok is a variant of Result, section 6)
        };
        settings.push((key.trim(), value));
    }
    println!("parsed settings: {settings:?}");

    // --- Option: combinators instead of null checks ---------------------------------
    let found = find_even(&numbers); // Some(4)
    let doubled = found.map(|v| v * 2); // C#: found is int v ? v * 2 : null
    let fallback = find_even(&[1, 3]).unwrap_or(-1); // C#: ?? -1
    let chained = found.and_then(|v| v.checked_sub(10)).filter(|v| *v > 0); // None
    println!(
        "{found:?} {doubled:?} {fallback} {chained:?} {}",
        found.is_some_and(|v| v > 3)
    );
    // `unwrap()` / `expect("...")` — "I am sure the value is there"; otherwise a panic.

    // The niche optimization: None for a reference is encoded as the null address, so
    // Option<&T> takes exactly as much space as &T. The abstraction is free.
    println!(
        "size_of: Option<&i32> = {}, &i32 = {}, Option<i32> = {}",
        size_of::<Option<&i32>>(),
        size_of::<&i32>(),
        size_of::<Option<i32>>()
    );

    // A numeric enum: converts to a number with `as`, compares and sorts (derive Ord).
    let mut levels = [Level::High, Level::Low, Level::Medium];
    levels.sort();
    println!("{levels:?} as numbers: {:?}", levels.map(|l| l as u8));
}

// =====================================================================================
//  6. ERROR HANDLING
// =====================================================================================
//
//  Rust has no exceptions. Errors come in two kinds:
//    - expected ones (a missing file, bad input) — a `Result<T, E>` in the signature:
//          enum Result<T, E> { Ok(T), Err(E) }
//    - bugs (a broken invariant) — a `panic!`, which terminates the thread.

/// A custom error type is an ordinary enum; its variants are convenient to match on.
#[derive(Debug)]
enum ConfigError {
    Missing(String),
    InvalidNumber {
        key: String,
        source: std::num::ParseIntError,
    },
    OutOfRange {
        key: String,
        value: i64,
        min: i64,
        max: i64,
    },
}

impl fmt::Display for ConfigError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            ConfigError::Missing(key) => write!(f, "missing key '{key}'"),
            ConfigError::InvalidNumber { key, .. } => write!(f, "key '{key}' is not a number"),
            ConfigError::OutOfRange {
                key,
                value,
                min,
                max,
            } => {
                write!(f, "key '{key}' = {value} is outside {min}..={max}")
            }
        }
    }
}

/// The `Error` trait makes the type a "real" error: it can go into a `Box<dyn Error>`
/// and it has a chain of causes, `source()` (C#: InnerException).
impl Error for ConfigError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            ConfigError::InvalidNumber { source, .. } => Some(source),
            _ => None,
        }
    }
}

fn read_port(config: &HashMap<&str, &str>) -> Result<u16, ConfigError> {
    let key = "port";
    // `ok_or_else` turns an Option into a Result.
    // The `?` operator: on Err, return the error from the function at once; on Ok, unwrap
    // the value. It is "exception propagation", but explicit and visible in the signature.
    let raw = config
        .get(key)
        .ok_or_else(|| ConfigError::Missing(key.to_string()))?;
    let value: i64 = raw
        .trim()
        .parse()
        .map_err(|source| ConfigError::InvalidNumber {
            key: key.to_string(),
            source,
        })?;
    if !(1..=65_535).contains(&value) {
        return Err(ConfigError::OutOfRange {
            key: key.to_string(),
            value,
            min: 1,
            max: 65_535,
        });
    }
    Ok(value as u16)
}

/// `Box<dyn Error>` means "any error" (C#: `catch (Exception)`). Handy in applications;
/// libraries prefer concrete enums. `?` boxes the error by itself through From.
fn average(text: &str) -> Result<f64, Box<dyn Error>> {
    let mut sum = 0.0;
    let mut count = 0;
    for token in text.split(',').filter(|t| !t.trim().is_empty()) {
        sum += token.trim().parse::<f64>()?; // ParseFloatError -> Box<dyn Error>
        count += 1;
    }
    if count == 0 {
        return Err("no numbers in the input".into()); // &str -> Box<dyn Error>
    }
    Ok(sum / count as f64)
}

/// A function that can fail returns a `Result`. `()` means "success with no data".
fn section06_errors() -> Result<(), Box<dyn Error>> {
    header(6, "Error handling");

    let configs = [
        HashMap::from([("port", "8080")]),
        HashMap::from([("host", "localhost")]),
        HashMap::from([("port", "80a")]),
        HashMap::from([("port", "70000")]),
    ];
    for config in &configs {
        // A Result is an ordinary enum: take it apart with match.
        match read_port(config) {
            Ok(port) => println!("port = {port}"),
            // A pattern with a binding: a separate arm for one particular error variant.
            Err(error @ ConfigError::InvalidNumber { .. }) => {
                println!("error: {error}; caused by: {}", error.source().unwrap())
            }
            Err(error) => println!("error: {error}"),
        }
    }

    // Result combinators work like those of Option.
    let port_or_default = read_port(&configs[1]).unwrap_or(8000);
    let as_text = read_port(&configs[0]).map(|p| format!("http://localhost:{p}"));
    println!(
        "{port_or_default} | {as_text:?} | {}",
        read_port(&configs[3]).is_err()
    );

    println!("average = {}", average("1.5, 2.5, 5")?); // `?` at work: Ok -> the value
    for bad in ["", "1, two, 3"] {
        if let Err(error) = average(bad) {
            println!("average({bad:?}) failed: {error}");
        }
    }

    // --- Panics -----------------------------------------------------------------
    // `panic!` (as well as unwrap on None, an out-of-bounds index, division by zero) unwinds
    // the stack, calling Drop for local values, and terminates the THREAD. It is not an
    // error-handling mechanism: `catch_unwind` is only for boundaries (FFI, thread pools).
    let default_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {})); // keep the demo quiet: do not print the panic message
    let outcome = std::panic::catch_unwind(|| {
        let empty: Vec<i32> = Vec::new();
        empty[0] // a panic: index out of bounds
    });
    std::panic::set_hook(default_hook);
    println!("catch_unwind caught a panic: {}", outcome.is_err());

    Ok(())
}

// =====================================================================================
//  7. COLLECTIONS
// =====================================================================================

fn section07_collections() {
    header(7, "Collections");

    // --- Vec<T>, a growable array. C#: List<T> ---------------------------------------
    let mut values: Vec<i32> = Vec::new();
    values.push(3);
    values.extend([1, 4, 1, 5, 9, 2, 6]);
    let mut sorted = values.clone();
    sorted.sort(); // in place; sort_unstable() is faster, sort_by_key(..) sorts by a key
    sorted.dedup(); // remove adjacent duplicates
    sorted.retain(|v| *v != 9); // C#: RemoveAll(v => v == 9)
    sorted.insert(0, 0); // inserting at the front is O(n), as in List<T>
    let last = sorted.pop(); // Option<i32>: None for an empty vector
    println!(
        "{values:?} -> {sorted:?}, popped {last:?}, capacity {}",
        sorted.capacity()
    );

    // The `vec!` macro: the length is known only at run time, so an array would not do.
    let zeros = vec![0_u8; values.len() * 2];
    // Slice methods are available to both arrays and Vec.
    let words = ["delta", "alpha", "charlie", "bravo"];
    println!(
        "{} {:?} {:?} {:?} {:?}",
        zeros.len(),
        words.first(), // Option<&&str>
        words.contains(&"alpha"),
        sorted.binary_search(&4), // Ok(index) or Err(insertion point)
        words.concat().len()
    );
    for pair in values.windows(2).take(2) {
        print!("window {pair:?}; "); // a sliding window
    }
    for chunk in values.chunks(3) {
        print!("chunk {chunk:?}; "); // non-overlapping chunks
    }
    println!();

    // Three ways to walk a collection:
    //   for x in &v      — by shared references; v stays usable;
    //   for x in &mut v  — by mutable references; elements can be modified;
    //   for x in v       — CONSUMES the collection and hands out owned elements.
    let mut squares = vec![1, 2, 3];
    for value in &mut squares {
        *value *= *value;
    }
    for value in squares {
        print!("{value} ");
    }
    println!("<- squares"); // after `for value in squares` the vector is gone: it was consumed

    // --- HashMap<K, V>. C#: Dictionary<TKey, TValue> ---------------------------------
    let mut stock: HashMap<String, u32> = HashMap::new();
    stock.insert("bolt".to_string(), 10);
    stock.insert("nut".to_string(), 0);
    // `get` returns Option<&V>: there is no KeyNotFoundException.
    println!(
        "bolt: {:?}, screw: {:?}",
        stock.get("bolt"),
        stock.get("screw")
    );
    // The entry API: "find or insert" with a single hash lookup.
    *stock.entry("screw".to_string()).or_insert(0) += 25;
    stock
        .entry("bolt".to_string())
        .and_modify(|n| *n -= 3)
        .or_insert(0);
    if let Some(removed) = stock.remove("nut") {
        println!("removed nut with quantity {removed}");
    }

    // Counting frequencies — the entry + or_default idiom.
    let text = "the quick brown fox jumps over the lazy dog the end";
    let mut frequency: HashMap<&str, usize> = HashMap::new();
    for word in text.split(' ') {
        *frequency.entry(word).or_default() += 1;
    }
    // The iteration order of a HashMap is unspecified (and deliberately differs between
    // runs: protection against HashDoS), so sort before printing.
    let mut top: Vec<(&str, usize)> = frequency.into_iter().collect();
    top.sort_by(|a, b| b.1.cmp(&a.1).then(a.0.cmp(b.0))); // by descending frequency, then by word
    println!("top words: {:?}", &top[..3]);

    // --- The other standard collections ---------------------------------------------
    // BTreeMap — an ordered map. C#: SortedDictionary.
    let mut by_name: BTreeMap<&str, u32> = stock.iter().map(|(k, v)| (k.as_str(), *v)).collect();
    by_name.insert("anchor", 7);
    println!(
        "{by_name:?}, range b..n: {:?}",
        by_name.range("b".."n").collect::<Vec<_>>()
    );

    // HashSet — a set with set operations.
    let a: HashSet<i32> = HashSet::from([1, 2, 3, 4]);
    let b: HashSet<i32> = (3..=6).collect();
    let mut common: Vec<_> = a.intersection(&b).copied().collect();
    common.sort();
    println!(
        "intersection {common:?}, union size {}",
        a.union(&b).count()
    );

    // VecDeque — a double-ended queue on a ring buffer (C#: Queue<T>, but with both ends).
    let mut queue: VecDeque<&str> = VecDeque::from(["second", "third"]);
    queue.push_front("first");
    queue.push_back("fourth");
    println!(
        "{:?} then {:?}, left {queue:?}",
        queue.pop_front(),
        queue.pop_back()
    );

    // BinaryHeap — a heap with the MAXIMUM on top (C#: PriorityQueue keeps the minimum on top).
    let mut heap = BinaryHeap::from([3, 8, 1, 5]);
    heap.push(7);
    println!(
        "heap max {:?}, sorted {:?}",
        heap.peek().copied(),
        heap.into_sorted_vec()
    );
}

// =====================================================================================
//  8. CLOSURES AND ITERATORS
// =====================================================================================

/// A higher-order function. `impl Fn(i32) -> i32` means "any type that implements Fn".
/// For every closure passed in, the compiler creates its own copy of the function and can
/// inline the call. C#: `Func<int, int>`, but there the call goes through a delegate.
fn apply_twice(f: impl Fn(i32) -> i32, x: i32) -> i32 {
    f(f(x))
}

/// A closure can be returned as `impl Fn` — a concrete but unnameable type...
fn make_adder(n: i32) -> impl Fn(i32) -> i32 {
    move |x| x + n // `move`: the closure takes n for itself; a reference would outlive the function
}

/// ...or as `Box<dyn Fn>` — when DIFFERENT closures must share one type (≈ a delegate).
fn make_operation(symbol: char) -> Box<dyn Fn(f64, f64) -> f64> {
    match symbol {
        '+' => Box::new(|a, b| a + b),
        '*' => Box::new(|a, b| a * b),
        '^' => Box::new(f64::powf), // an ordinary function implements Fn as well
        _ => Box::new(|_, _| f64::NAN),
    }
}

/// A custom iterator: implementing `next()` is enough, and all the adapters (map, filter,
/// zip, ...) come for free. C#: IEnumerator<T> or a method with `yield return`.
struct Fibonacci {
    current: Option<u64>, // None — the sequence is over: the next number does not fit into u64
    next: Option<u64>,
}

impl Iterator for Fibonacci {
    type Item = u64; // an associated type: what the iterator yields

    fn next(&mut self) -> Option<u64> {
        let value = self.current?; // `?` works with Option too: None => return None at once
        let following = self.next.and_then(|n| n.checked_add(value)); // None on overflow
        self.current = self.next;
        self.next = following;
        Some(value)
    }
}

fn fibonacci() -> Fibonacci {
    Fibonacci {
        current: Some(0),
        next: Some(1),
    }
}

fn section08_closures_and_iterators() {
    header(8, "Closures and iterators");

    // --- Closures -----------------------------------------------------------------
    // Syntax: |parameters| expression. Types are inferred. Every closure has its own unique
    // type; what it can do is described by three traits:
    //   Fn      — only reads what it captured (can be called any number of times);
    //   FnMut   — modifies what it captured (needs exclusive access);
    //   FnOnce  — consumes what it captured (can be called once).
    let factor = 3;
    let triple = |x: i32| x * factor; // Fn: borrows factor by `&`
    let mut calls = 0;
    let mut count_and_add = |x: i32| {
        calls += 1; // FnMut: borrows calls by `&mut`
        x + 1
    };
    let (first, second) = (count_and_add(1), count_and_add(10));
    println!(
        "triple(7) = {}, twice = {}, {first} {second} calls = {calls}",
        triple(7),
        apply_twice(triple, 2)
    );

    let token = String::from("one-shot");
    let give_away = move || token; // returns the captured value => FnOnce
    let received = give_away();
    // give_away(); // E0382: the closure has already been used up
    let add_five = make_adder(5);
    println!(
        "{received} | {} | {} | {}",
        add_five(1),
        make_operation('*')(6.0, 7.0),
        make_operation('^')(2.0, 10.0)
    );

    // --- Iterators: LINQ without the overhead ----------------------------------------
    // They are lazy like IEnumerable<T>: a chain does nothing until it is "consumed"
    // (collect, sum, for, ...). Unlike LINQ, a chain compiles down to an ordinary loop
    // with no allocations and no virtual calls.
    let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let even_squares: Vec<i32> = numbers
        .iter() // an iterator over &i32 references
        .filter(|&&x| x % 2 == 0) // C#: Where
        .map(|&x| x * x) // C#: Select
        .collect(); // C#: ToList; the target type comes from the annotation on the left
    let total: i32 = numbers.iter().sum();
    let factorial: u64 = (1..=10_u64).product();
    println!("{even_squares:?} sum {total} 10! = {factorial}");

    let (small, large): (Vec<i32>, Vec<i32>) = numbers.iter().partition(|&&x| x <= 3);
    println!(
        "{small:?} {large:?} any>9: {} all>0: {} position of 7: {:?} max: {:?}",
        numbers.iter().any(|&x| x > 9),
        numbers.iter().all(|&x| x > 0),
        numbers.iter().position(|&x| x == 7),
        numbers.iter().max()
    );

    let words = ["apple", "fig", "banana", "kiwi"];
    // C#: ToDictionary.
    let lengths: HashMap<&str, usize> = words.iter().map(|w| (*w, w.len())).collect();
    let initials: String = words.iter().filter_map(|w| w.chars().next()).collect(); // into a String
    let longest = words.iter().max_by_key(|w| w.len()); // C#: MaxBy
    let shouted = words.map(|w| w.to_uppercase()).join(", "); // arrays have map too
    println!("{} {initials} {longest:?} {shouted}", lengths["banana"]);

    // zip / enumerate / chain / rev / skip / step_by / take_while / flat_map / fold.
    let weights = [0.5, 0.25, 0.25];
    let weighted: f64 = [10.0, 20.0, 40.0]
        .iter()
        .zip(&weights)
        .map(|(v, w)| v * w)
        .sum();
    let letters: Vec<char> = ["ab", "cd"].iter().flat_map(|s| s.chars()).collect(); // SelectMany
    let dashed = numbers.iter().skip(6).fold(String::new(), |mut acc, n| {
        if !acc.is_empty() {
            acc.push('-');
        }
        acc += &n.to_string();
        acc
    }); // C#: Aggregate
    let stepped: Vec<i32> = (0..20).step_by(5).chain([100, 200]).rev().collect();
    println!("{weighted} {letters:?} {dashed} {stepped:?}");

    // collect can turn types "inside out": an iterator of Results -> a Result holding a vector.
    let parsed: Result<Vec<i32>, _> = ["1", "2", "3"].iter().map(|s| s.parse::<i32>()).collect();
    let failed: Result<Vec<i32>, _> = ["1", "x", "3"].iter().map(|s| s.parse::<i32>()).collect();
    println!("{parsed:?} | {}", failed.is_err());

    // A custom iterator with the standard adapters.
    let below_100: Vec<u64> = fibonacci().take_while(|&x| x < 100).collect();
    let every_third: Vec<u64> = fibonacci().skip(10).step_by(3).take(3).collect();
    println!(
        "{below_100:?} {every_third:?} terms that fit in u64: {}",
        fibonacci().count()
    );

    // Generators on the fly: successors and from_fn instead of `yield return`.
    let powers: Vec<u32> = std::iter::successors(Some(1_u32), |&x| x.checked_mul(10)).collect();
    let mut state = 0;
    let countdown: Vec<i32> = std::iter::from_fn(|| {
        state += 1;
        (state <= 3).then_some(4 - state) // bool -> Option
    })
    .collect();
    println!("{} powers of ten fit in u32; {countdown:?}", powers.len());

    // Sorting by several keys. C#: OrderBy(..).ThenBy(..).
    let mut people = [("Ann", 30), ("Bob", 25), ("Cid", 30), ("Dan", 25)];
    people.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(b.0)));
    // Grouping adjacent elements. A full GroupBy is done with HashMap + entry.
    let groups: Vec<(i32, Vec<&str>)> = people
        .chunk_by(|a, b| a.1 == b.1)
        .map(|group| (group[0].1, group.iter().map(|p| p.0).collect()))
        .collect();
    println!("{groups:?}");
}

// =====================================================================================
//  9. TRAITS AND GENERICS
// =====================================================================================
//
//  A trait ≈ a C# interface, but broader:
//    - it can be implemented for a FOREIGN type, built-in ones included (i32, Vec<T>, str);
//    - it can hold default methods, associated types and constants, and functions
//      without self (C#: static abstract);
//    - the same trait serves both static polymorphism (generics: the call is resolved at
//      compile time) and dynamic polymorphism (`dyn Trait`: the call goes through a vtable).
//  A restriction (the orphan rule): you may implement YOUR trait, or a trait for YOUR type.

trait Describe {
    /// An associated constant with a default value.
    const KIND: &'static str = "value";

    /// A required method.
    fn name(&self) -> String;

    /// A method with a default implementation. C#: default interface method.
    fn describe(&self) -> String {
        format!("{} '{}'", Self::KIND, self.name())
    }
}

impl Describe for Particle {
    const KIND: &'static str = "particle";

    fn name(&self) -> String {
        self.name.clone()
    }
}

/// Implementing our trait for a built-in type: i32 gains a `describe()` method.
impl Describe for i32 {
    fn name(&self) -> String {
        self.to_string()
    }
}

/// A blanket implementation: "for ANY `T: Describe`, a `Vec<T>` is Describe as well".
impl<T: Describe> Describe for Vec<T> {
    const KIND: &'static str = "list";

    fn name(&self) -> String {
        self.iter()
            .map(|item| item.name())
            .collect::<Vec<_>>()
            .join("+")
    }
}

/// An extension trait — the "extension methods" idiom for a foreign type (here, `str`).
trait StrExt {
    fn is_palindrome(&self) -> bool;
}

impl StrExt for str {
    fn is_palindrome(&self) -> bool {
        let letters: Vec<char> = self
            .chars()
            .filter(|c| c.is_alphanumeric())
            .flat_map(char::to_lowercase)
            .collect();
        letters.iter().eq(letters.iter().rev())
    }
}

/// A generic function with trait bounds. C#: `where T : IComparable<T>`.
/// MONOMORPHIZATION: a separate version is compiled for every T that is used
/// (like C++ templates), so calls are static and can be inlined.
fn largest<T: PartialOrd + Copy>(items: &[T]) -> Option<T> {
    let mut iter = items.iter().copied();
    let mut best = iter.next()?;
    for item in iter {
        if item > best {
            best = item;
        }
    }
    Some(best)
}

/// `impl Trait` in argument position is sugar for an anonymous type parameter.
fn print_description(item: &impl Describe) {
    println!("    {}", item.describe());
}

/// Generic arithmetic through operator traits; the bounds are moved into a `where` clause.
/// C#: generic math (`INumber<T>`).
fn dot<T>(a: &[T], b: &[T]) -> T
where
    T: Copy + Default + std::ops::Add<Output = T> + std::ops::Mul<Output = T>,
{
    a.iter()
        .zip(b)
        .fold(T::default(), |acc, (&x, &y)| acc + x * y)
}

/// `impl Trait` in return position: "some type that implements Iterator" — concrete but
/// unnameable (the types of iterator chains and closures cannot be written by hand).
fn even_squares(limit: u32) -> impl Iterator<Item = u32> {
    (0..=limit).filter(|n| n % 2 == 0).map(|n| n * n)
}

/// A generic struct. C#: `class Stack<T>`.
#[derive(Debug, Clone, Default)]
struct Stack<T> {
    items: Vec<T>,
}

impl<T> Stack<T> {
    fn new() -> Self {
        Self { items: Vec::new() }
    }

    /// Returning `&mut Self` allows method chaining.
    fn push(&mut self, item: T) -> &mut Self {
        self.items.push(item);
        self
    }

    fn pop(&mut self) -> Option<T> {
        self.items.pop()
    }

    fn peek(&self) -> Option<&T> {
        self.items.last()
    }

    fn len(&self) -> usize {
        self.items.len()
    }
}

/// An impl block with an extra bound: the method exists only when `T: Display`.
/// In C# this is only possible through an extension method with a constraint.
impl<T: fmt::Display> Stack<T> {
    fn render(&self) -> String {
        self.items
            .iter()
            .map(|item| item.to_string())
            .collect::<Vec<_>>()
            .join(" > ")
    }
}

/// An indexer. C#: `public T this[int index]`.
impl<T> std::ops::Index<usize> for Stack<T> {
    type Output = T;

    fn index(&self, index: usize) -> &T {
        &self.items[index]
    }
}

/// `for item in &stack` — implementing IntoIterator for the reference is enough.
/// C#: `IEnumerable<T>.GetEnumerator()`.
impl<'a, T> IntoIterator for &'a Stack<T> {
    type Item = &'a T;
    type IntoIter = std::slice::Iter<'a, T>;

    fn into_iter(self) -> Self::IntoIter {
        self.items.iter()
    }
}

/// `iterator.collect::<Stack<_>>()` — through FromIterator.
impl<T> FromIterator<T> for Stack<T> {
    fn from_iter<I: IntoIterator<Item = T>>(iter: I) -> Self {
        Self {
            items: iter.into_iter().collect(),
        }
    }
}

/// From/Into are the standard lossless conversions (C#: implicit operator).
/// Implement From and you get Into for free.
impl From<(f64, f64)> for Vec2 {
    fn from((x, y): (f64, f64)) -> Self {
        Vec2::new(x, y) // a tuple pattern sits right in the parameter list
    }
}

/// TryFrom is a conversion that can fail (C#: explicit operator + an exception).
impl TryFrom<i32> for Level {
    type Error = String;

    fn try_from(value: i32) -> Result<Self, Self::Error> {
        match value {
            1 => Ok(Level::Low),
            5 => Ok(Level::Medium),
            10 => Ok(Level::High),
            other => Err(format!("no Level with value {other}")),
        }
    }
}

/// FromStr plugs the type into `str::parse`. C#: `IParsable<T>`.
impl std::str::FromStr for Vec2 {
    type Err = String;

    fn from_str(text: &str) -> Result<Self, Self::Err> {
        let (x, y) = text.split_once(',').ok_or("expected 'x,y'")?; // &str -> String through From
        let number = |part: &str| part.trim().parse::<f64>().map_err(|e| e.to_string());
        Ok(Vec2::new(number(x)?, number(y)?))
    }
}

trait HasArea {
    fn area(&self) -> f64;
}

/// A supertrait: every Drawable must also be HasArea and Debug (≈ interface inheritance).
trait Drawable: HasArea + fmt::Debug {
    fn draw(&self) -> String {
        format!("{self:?}, area {:.2}", self.area())
    }
}

#[derive(Debug)]
struct Circle {
    radius: f64,
}

#[derive(Debug)]
struct Square {
    side: f64,
}

impl HasArea for Circle {
    fn area(&self) -> f64 {
        std::f64::consts::PI * self.radius.powi(2)
    }
}

impl HasArea for Square {
    fn area(&self) -> f64 {
        self.side * self.side
    }
}

impl Drawable for Circle {} // all methods take their defaults

impl Drawable for Square {
    fn draw(&self) -> String {
        format!("square {0} x {0}", self.side)
    }
}

/// Static dispatch: T is known at compile time and the `area()` call can be inlined.
fn total_area_static<T: HasArea>(shapes: &[T]) -> f64 {
    shapes.iter().map(|shape| shape.area()).sum()
}

/// Dynamic dispatch. `dyn HasArea` is a trait object; a pointer to it is "fat": the address
/// of the data plus the address of a method table. That is how C# interfaces work.
/// It is needed when one collection holds values of DIFFERENT types.
fn total_area_dynamic(shapes: &[Box<dyn HasArea>]) -> f64 {
    shapes.iter().map(|shape| shape.area()).sum()
}

/// Const generics: a VALUE parameter in a type (C# has no counterpart; C++: `template<size_t N>`).
/// `Matrix<2, 3>` and `Matrix<3, 2>` are different types; sizes are checked at compile time.
#[derive(Debug, Clone, Copy, PartialEq)]
struct Matrix<const R: usize, const C: usize> {
    data: [[f64; C]; R],
}

impl<const R: usize, const C: usize> Matrix<R, C> {
    fn transpose(&self) -> Matrix<C, R> {
        let mut data = [[0.0; R]; C];
        for (r, row) in self.data.iter().enumerate() {
            for (c, value) in row.iter().enumerate() {
                data[c][r] = *value;
            }
        }
        Matrix { data }
    }
}

/// Multiplication is defined only for matching sizes: (R x K) * (K x C) = (R x C).
impl<const R: usize, const K: usize, const C: usize> std::ops::Mul<Matrix<K, C>> for Matrix<R, K> {
    type Output = Matrix<R, C>;

    fn mul(self, rhs: Matrix<K, C>) -> Matrix<R, C> {
        let mut data = [[0.0; C]; R];
        for (r, row) in data.iter_mut().enumerate() {
            for (c, cell) in row.iter_mut().enumerate() {
                *cell = (0..K).map(|k| self.data[r][k] * rhs.data[k][c]).sum();
            }
        }
        Matrix { data }
    }
}

fn section09_traits_and_generics() {
    header(9, "Traits and generics");

    let proton = Particle {
        name: "proton".into(),
        mass: 1.673e-27,
        ..Default::default()
    };
    print_description(&proton);
    print_description(&42);
    print_description(&vec![1, 2, 3]);
    println!(
        "    i32::KIND = {}, palindrome: {}",
        <i32 as Describe>::KIND, // the full syntax: "KIND from the Describe implementation for i32"
        "A man, a plan, a canal: Panama".is_palindrome()
    );

    // The type is usually inferred from the arguments; when needed it is given explicitly
    // with the "turbofish" syntax: `largest::<u8>(...)`.
    println!(
        "{:?} {:?} {:?} {:?}",
        largest(&[3, 9, 2]),
        largest(&[1.5, -2.0]),
        largest(&['x', 'b']),
        largest::<u8>(&[])
    );
    println!(
        "dot: {} and {}",
        dot(&[1, 2, 3], &[4, 5, 6]),
        dot(&[0.5, 1.5], &[2.0, 4.0])
    );
    println!("even squares: {:?}", even_squares(10).collect::<Vec<_>>());

    // A custom generic container plugged into the language: chaining, indexer, for, collect.
    let mut stack = Stack::new(); // T is inferred from the first push
    stack.push(1).push(2).push(3);
    let top = stack.pop();
    println!(
        "{} | popped {top:?} | peek {:?} | stack[0] = {} | len {}",
        stack.render(),
        stack.peek(),
        stack[0],
        stack.len()
    );
    let doubled: Stack<i32> = stack.into_iter().map(|x| x * 2).collect();
    for item in &doubled {
        print!("{item} ");
    }
    println!("<- doubled");
    // Stack::<Shape>::new().render(); // E0599: Shape is not Display, so it has no render method

    // Conversions.
    let from_tuple: Vec2 = (1.0, 2.0).into();
    println!(
        "{from_tuple} | {:?} | {:?}",
        "3.5, -1".parse::<Vec2>(),
        "oops".parse::<Vec2>()
    );
    println!(
        "{:?} | {:?} | {}",
        Level::try_from(5),
        Level::try_from(7),
        i64::from(7_i32) + i64::from(true)
    );

    // A custom type as a map key: derive(PartialEq, Eq, Hash) is enough.
    // (Items — struct, fn, impl — can also be declared inside a function.)
    #[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
    struct GridPos {
        row: u8,
        col: u8,
    }
    let mut board = HashMap::new();
    board.insert(GridPos { row: 0, col: 0 }, 'X');
    board.insert(GridPos { row: 1, col: 1 }, 'O');
    println!(
        "board[1,1] = {:?}, board[2,2] = {:?}",
        board.get(&GridPos { row: 1, col: 1 }),
        board.get(&GridPos { row: 2, col: 2 })
    );

    // Static and dynamic dispatch.
    let circles = [Circle { radius: 1.0 }, Circle { radius: 2.0 }];
    let mixed: Vec<Box<dyn HasArea>> = vec![
        Box::new(Circle { radius: 1.0 }),
        Box::new(Square { side: 2.0 }),
    ];
    println!(
        "areas: {:.2} and {:.2}",
        total_area_static(&circles),
        total_area_dynamic(&mixed)
    );

    let drawables: [&dyn Drawable; 2] = [&Circle { radius: 0.5 }, &Square { side: 3.0 }];
    for drawable in drawables {
        println!("    {}", drawable.draw());
    }
    // Casting a trait object to its supertrait (upcasting, Rust 1.86).
    let as_area: &dyn HasArea = drawables[0];
    println!(
        "    upcast area {:.3}; size_of: &dyn HasArea = {}, &Circle = {}",
        as_area.area(),
        size_of::<&dyn HasArea>(), // 16: two pointers
        size_of::<&Circle>()       // 8
    );

    // Const generics.
    let m = Matrix {
        data: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
    }; // Matrix<2, 3>
    let product = m * m.transpose(); // Matrix<2, 3> * Matrix<3, 2> = Matrix<2, 2>
    // let bad = m * m; // E0308: a Matrix<2, 3> cannot be multiplied by a Matrix<2, 3>
    println!("m * mT = {:?}", product.data);
}

// =====================================================================================
//  10. LIFETIMES
// =====================================================================================
//
//  A lifetime is the stretch of code over which a reference is guaranteed to be valid.
//  The compiler tracks it for every reference. An annotation `'a` extends nothing: it only
//  LINKS references in a signature so that the calling code can be checked.

/// "The result lives no longer than BOTH arguments."
/// Without the annotation — E0106: the compiler cannot tell which argument the result
/// depends on.
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

// In simple cases the annotations are inferred (lifetime elision). The signature
//     fn first_word(text: &str) -> &str
// is shorthand for
//     fn first_word<'a>(text: &'a str) -> &'a str

#[derive(Debug, Clone, Copy, PartialEq)]
enum TokenKind {
    Number,
    Ident,
    Symbol,
}

/// A struct that stores a reference must declare a lifetime: an instance cannot outlive
/// the data it looks at. C#: a `ref struct` with ref fields is a similar idea.
#[derive(Debug)]
struct Token<'src> {
    kind: TokenKind,
    text: &'src str,
}

/// A zero-copy lexer: tokens are slices of the source string; no allocations for the text.
struct Lexer<'src> {
    rest: &'src str,
}

impl<'src> Lexer<'src> {
    fn new(source: &'src str) -> Self {
        Self { rest: source }
    }
}

impl<'src> Iterator for Lexer<'src> {
    type Item = Token<'src>; // tokens are tied to the source string, not to the lexer

    fn next(&mut self) -> Option<Token<'src>> {
        self.rest = self.rest.trim_start();
        let first = self.rest.chars().next()?;
        let end_of = |stop: fn(char) -> bool| self.rest.find(stop).unwrap_or(self.rest.len());
        let (kind, length) = if first.is_ascii_digit() {
            (
                TokenKind::Number,
                end_of(|c| !c.is_ascii_digit() && c != '.'),
            )
        } else if first.is_alphabetic() || first == '_' {
            (
                TokenKind::Ident,
                end_of(|c| !c.is_alphanumeric() && c != '_'),
            )
        } else {
            (TokenKind::Symbol, first.len_utf8())
        };
        let (text, rest) = self.rest.split_at(length);
        self.rest = rest;
        Some(Token { kind, text })
    }
}

fn section10_lifetimes() {
    header(10, "Lifetimes");

    let outer = String::from("a long-lived string");
    let length;
    {
        let inner = String::from("short");
        let winner = longest(&outer, &inner); // 'a = the overlap of the scopes of outer and inner
        length = winner.len(); // a number leaves the block, not a reference — that is fine
        // Taking `winner` out of the block gives E0597: `inner` does not live long enough.
    }
    println!("the longest string has {length} bytes");

    let source = String::from("force = mass * 9.81 + offset_2");
    let tokens: Vec<Token<'_>> = Lexer::new(&source).collect();
    for token in &tokens {
        print!("{:?}:{} ", token.kind, token.text);
    }
    println!();
    // drop(source); // E0505: cannot move out of `source` because it is borrowed
    let identifiers = tokens.iter().filter(|t| t.kind == TokenKind::Ident).count();
    println!("{identifiers} identifiers, {} tokens", tokens.len());

    // `'static` means "valid until the program ends": string literals, static variables
    // and deliberately leaked memory.
    let literal: &'static str = "string literals live in the binary";
    let leaked: &'static mut Vec<i32> = Box::leak(Box::new(vec![1, 2, 3]));
    leaked.push(4);
    println!("{literal} | leaked: {leaked:?}");
    // The bound `T: 'static` means "T contains no short-lived references": such a value can
    // be owned for as long as you like. `thread::spawn`, for one, requires it.
}

// =====================================================================================
//  11. SMART POINTERS AND INTERIOR MUTABILITY
// =====================================================================================

/// `Box<T>` is sole ownership of a value on the heap (C++: unique_ptr). It is needed for:
///   - recursive types (their size would otherwise be infinite);
///   - trait objects, `Box<dyn Trait>`;
///   - large values that should not be moved byte by byte.
#[derive(Debug)]
enum Expr {
    Num(f64),
    Var(String),
    Neg(Box<Expr>),
    Add(Box<Expr>, Box<Expr>),
    Mul(Box<Expr>, Box<Expr>),
}

impl Expr {
    fn eval(&self, variables: &HashMap<&str, f64>) -> Result<f64, String> {
        Ok(match self {
            Expr::Num(value) => *value,
            Expr::Var(name) => *variables
                .get(name.as_str())
                .ok_or_else(|| format!("unknown variable '{name}'"))?,
            Expr::Neg(inner) => -inner.eval(variables)?,
            Expr::Add(a, b) => a.eval(variables)? + b.eval(variables)?,
            Expr::Mul(a, b) => a.eval(variables)? * b.eval(variables)?,
        })
    }
}

/// `Rc<T>` is reference counting for SHARED ownership within one thread (C++: shared_ptr;
/// in C# every object reference behaves this way, with a GC instead of a counter).
///
/// Rc gives read-only access. Changing a shared value takes "interior mutability":
/// `RefCell<T>` moves the borrow-rule check from compile time to run time
/// (a violation is a panic, not memory corruption).
///
/// `Weak<T>` is a weak reference (C#: WeakReference<T>). Without it an Rc cycle would leak:
/// there is no GC.
#[derive(Debug)]
struct TreeNode {
    name: String,
    parent: RefCell<Weak<TreeNode>>, // upwards — a weak reference
    children: RefCell<Vec<Rc<TreeNode>>>, // downwards — strong ones
}

impl TreeNode {
    fn new(name: &str) -> Rc<TreeNode> {
        Rc::new(TreeNode {
            name: name.to_string(),
            parent: RefCell::new(Weak::new()),
            children: RefCell::new(Vec::new()),
        })
    }

    fn add_child(parent: &Rc<TreeNode>, child: Rc<TreeNode>) {
        *child.parent.borrow_mut() = Rc::downgrade(parent);
        parent.children.borrow_mut().push(child);
    }

    fn path(&self) -> String {
        // upgrade: Weak -> Option<Rc>, i.e. "is the parent still alive?"
        match self.parent.borrow().upgrade() {
            Some(parent) => format!("{}/{}", parent.path(), self.name),
            None => self.name.clone(),
        }
    }
}

/// `Cow` (clone on write): either borrowed data or owned data.
/// It avoids an allocation when nothing had to be changed.
fn escape_html(input: &str) -> Cow<'_, str> {
    if !input.contains(['<', '>', '&']) {
        return Cow::Borrowed(input); // the fast path: not a single allocation
    }
    let mut escaped = String::with_capacity(input.len() + 8);
    for ch in input.chars() {
        match ch {
            '<' => escaped.push_str("&lt;"),
            '>' => escaped.push_str("&gt;"),
            '&' => escaped.push_str("&amp;"),
            other => escaped.push(other),
        }
    }
    Cow::Owned(escaped)
}

/// A custom smart pointer. The `Deref` trait enables auto-dereferencing: methods of T can
/// be called directly on the wrapper. `Cell<T>` is interior mutability for Copy values:
/// the counter changes even through `&self`.
struct Tracked<T> {
    value: T,
    reads: Cell<u32>,
}

impl<T> std::ops::Deref for Tracked<T> {
    type Target = T;

    fn deref(&self) -> &T {
        self.reads.set(self.reads.get() + 1);
        &self.value
    }
}

fn section11_smart_pointers() {
    header(11, "Smart pointers and interior mutability");

    // Box: the value is on the heap, the pointer on the stack. Dereference with `*`.
    let boxed = Box::new(41);
    println!("boxed + 1 = {}", *boxed + 1);

    // -(x + 2) * 3 — an expression tree built from a recursive enum.
    let expr = Expr::Mul(
        Box::new(Expr::Neg(Box::new(Expr::Add(
            Box::new(Expr::Var("x".to_string())),
            Box::new(Expr::Num(2.0)),
        )))),
        Box::new(Expr::Num(3.0)),
    );
    let variables = HashMap::from([("x", 5.0)]);
    println!(
        "eval = {:?}, without x: {:?}",
        expr.eval(&variables),
        expr.eval(&HashMap::new())
    );

    // Rc: cloning bumps the counter; the data is not copied.
    let shared = Rc::new(String::from("shared text"));
    let alias = Rc::clone(&shared);
    println!(
        "strong count = {}, same allocation: {}",
        Rc::strong_count(&shared),
        Rc::ptr_eq(&shared, &alias)
    );
    drop(alias);
    println!("strong count after drop = {}", Rc::strong_count(&shared));

    // RefCell: borrow() and borrow_mut() are checked at run time.
    let cell = RefCell::new(vec![1, 2, 3]);
    cell.borrow_mut().push(4);
    {
        let reader = cell.borrow();
        let writer = cell.try_borrow_mut(); // Err: there is already a reader
        println!(
            "{reader:?}; try_borrow_mut while reading fails: {}",
            writer.is_err()
        );
    }

    // A tree with back references: Rc downwards, Weak upwards.
    let root = TreeNode::new("root");
    let usr = TreeNode::new("usr");
    let bin = TreeNode::new("bin");
    TreeNode::add_child(&root, Rc::clone(&usr));
    TreeNode::add_child(&usr, Rc::clone(&bin));
    println!(
        "{} | usr: strong {} weak {}",
        bin.path(),
        Rc::strong_count(&usr),
        Rc::weak_count(&usr)
    );
    drop(root); // the root is destroyed: the weak reference usr.parent no longer upgrades
    println!("{} after the root is dropped", bin.path());

    // Cow: an allocation only when it is really needed.
    for input in ["plain text", "a < b && b > c"] {
        let escaped = escape_html(input);
        let kind = if matches!(escaped, Cow::Borrowed(_)) {
            "borrowed"
        } else {
            "owned"
        };
        println!("{kind}: {escaped}");
    }

    // Deref: len() and to_uppercase() are str methods called through Tracked<String>.
    let tracked = Tracked {
        value: String::from("deref"),
        reads: Cell::new(0),
    };
    let summary = format!("{} {}", tracked.len(), tracked.to_uppercase());
    println!("{summary}, value was read {} times", tracked.reads.get());
}

// =====================================================================================
//  12. MODULES, ATTRIBUTES, TESTS
// =====================================================================================

/// A module is the unit of encapsulation (C#: namespace and internal in one). Everything
/// is private by default, and the privacy boundary is the MODULE, not the type. In a real
/// project `mod geometry;` would pull in the file geometry.rs; here the module is inline.
mod geometry {
    use std::sync::atomic::{AtomicU32, Ordering};

    /// `pub` — the item is visible outside the module.
    #[derive(Debug, Clone, Copy)]
    pub struct Rect {
        pub width: f64,
        pub height: f64,
        id: u32, // private: code outside the module cannot write a `Rect { .. }` literal
    }

    impl Rect {
        pub fn new(width: f64, height: f64) -> Self {
            Self {
                width,
                height,
                id: next_id(),
            }
        }

        /// A "getter" is an ordinary method: the language has no properties.
        pub fn id(&self) -> u32 {
            self.id
        }

        pub fn area(&self) -> f64 {
            self.width * self.height
        }

        /// `pub(crate)` — visible in the whole crate but not outside it (C#: internal).
        pub(crate) fn scale(&mut self, factor: f64) {
            self.width *= factor;
            self.height *= factor;
        }
    }

    /// A private function of the module.
    fn next_id() -> u32 {
        // A static inside a function: visible only here, alive for the whole program.
        static NEXT_ID: AtomicU32 = AtomicU32::new(1);
        NEXT_ID.fetch_add(1, Ordering::Relaxed)
    }

    /// A nested module. `super::` is the parent module, `crate::` is the crate root.
    pub mod units {
        pub const MM_PER_INCH: f64 = 25.4;

        pub fn inches_to_mm(inches: f64) -> f64 {
            inches * MM_PER_INCH
        }

        pub fn diagonal_mm(rect: &super::Rect) -> f64 {
            inches_to_mm(rect.width.hypot(rect.height))
        }
    }
}

// `use` can group and rename. C#: `using Rectangle = Geometry.Rect;`.
use geometry::Rect as Rectangle;
use geometry::units::{self, inches_to_mm};

/// Attributes (C#: `[Attributes]`) are instructions to the compiler.
#[must_use = "a checksum is useless unless it is checked"] // warn if the result is discarded
#[inline] // a hint to the optimizer
fn checksum(data: &[u8]) -> u32 {
    data.iter()
        .fold(0_u32, |acc, &byte| acc.rotate_left(5) ^ u32::from(byte))
}

#[deprecated(since = "0.2.0", note = "use `checksum` instead")] // C#: [Obsolete]
fn old_checksum(data: &[u8]) -> u32 {
    checksum(data)
}

/// Conditional compilation (C#: `#if`). The function exists only on a matching platform.
#[cfg(target_os = "windows")]
fn platform_name() -> &'static str {
    "Windows"
}

#[cfg(not(target_os = "windows"))]
fn platform_name() -> &'static str {
    "Unix-like"
}

/// Unit tests are part of the language and live next to the code. `#[cfg(test)]`: the
/// module is compiled only by `rustc --test` / `cargo test`.
/// C#: a separate project with xUnit or NUnit.
#[cfg(test)]
mod tests {
    use super::*; // tests can see the private items of the parent module too

    #[test]
    fn checksum_depends_on_content() {
        assert_eq!(checksum(b"abc"), checksum(b"abc"));
        assert_ne!(checksum(b"abc"), checksum(b"abd"));
    }

    #[test]
    fn matrix_transpose_is_an_involution() {
        let m = Matrix {
            data: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
        };
        assert_eq!(m.transpose().transpose(), m);
    }

    #[test]
    #[should_panic(expected = "index out of bounds")]
    fn indexing_past_the_end_panics() {
        let values = vec![1, 2, 3];
        let index = values.len();
        let _ = values[index];
    }
}

fn section12_modules() {
    header(12, "Modules, attributes, tests");

    let mut rect = Rectangle::new(3.0, 4.0); // geometry::Rect under an alias
    rect.scale(2.0);
    // rect.id = 7; // E0616: field `id` of struct `Rect` is private
    println!(
        "rect #{}: {} x {}, area {}, diagonal {:.1} mm",
        rect.id(),
        rect.width,
        rect.height,
        rect.area(),
        units::diagonal_mm(&rect)
    );
    println!(
        "{} mm per inch, 2 in = {} mm",
        units::MM_PER_INCH,
        inches_to_mm(2.0)
    );

    #[allow(deprecated)] // an attribute can be attached to a single statement as well
    let legacy = old_checksum(b"rust");
    println!(
        "checksum {:#010x} (legacy {legacy:#010x}), platform: {}, debug build: {}",
        checksum(b"rust"),
        platform_name(),
        cfg!(debug_assertions) // cfg! — the same condition as an expression
    );
    // Macros that report the place in the code. C#: [CallerFilePath], [CallerLineNumber].
    println!("{}:{} in module `{}`", file!(), line!(), module_path!());
}

// =====================================================================================
//  13. CONCURRENCY
// =====================================================================================
//
//  Thread safety is built into the type system through two marker traits:
//    Send — a value can be MOVED to another thread;
//    Sync — a value can be REFERENCED from several threads at once.
//  The compiler derives them automatically. `Rc<T>`, `RefCell<T>` and raw pointers do not
//  have them, so a data race in safe Rust is a compile error.

fn section13_concurrency() {
    header(13, "Concurrency");

    // --- An OS thread ---------------------------------------------------------------
    // `spawn` takes a closure and returns a JoinHandle<T>. C#: Task.Run / new Thread.
    // The closure must be `Send + 'static`, so data is moved into it (`move`).
    let limit = 1000_u64;
    let handle = thread::spawn(move || (1..=limit).sum::<u64>());
    let total = handle.join().expect("worker panicked"); // Err if the thread panicked
    println!("sum computed in another thread: {total}");

    // --- Arc<Mutex<T>>: shared mutable state -----------------------------------------
    // The mutex OWNS the data: there is no way to reach it without taking the lock.
    // (In C#, `lock (obj)` and the fields it protects are tied together only by convention.)
    // Arc is a thread-safe Rc with an atomic counter.
    let counter = Arc::new(Mutex::new(0_u64));
    let mut workers = Vec::new();
    for _ in 0..4 {
        let counter = Arc::clone(&counter); // each thread gets its own Arc
        workers.push(thread::spawn(move || {
            for _ in 0..1000 {
                let mut guard = counter.lock().unwrap(); // MutexGuard is an RAII lock
                *guard += 1;
            } // the lock is released when guard is destroyed
        }));
    }
    for worker in workers {
        worker.join().unwrap();
    }
    println!("counter = {}", *counter.lock().unwrap());

    // --- Scoped threads: threads that borrow local data -------------------------------
    // `scope` guarantees that all threads finish before the block is left, so they can be
    // given plain references to the stack — no Arc and no `'static`.
    let data: Vec<u64> = (1..=1_000).collect();
    let chunk_sums: Vec<u64> = thread::scope(|scope| {
        let handles: Vec<_> = data
            .chunks(250)
            .map(|chunk| scope.spawn(move || chunk.iter().sum::<u64>()))
            .collect();
        handles.into_iter().map(|h| h.join().unwrap()).collect()
    });
    println!(
        "chunk sums {chunk_sums:?}, total {}",
        chunk_sums.iter().sum::<u64>()
    );

    // --- Channels -------------------------------------------------------------------
    // mpsc = multiple producers, single consumer. C#: System.Threading.Channels.
    let (sender, receiver) = mpsc::channel::<String>();
    for id in 0..3 {
        let sender = sender.clone();
        thread::spawn(move || {
            sender.send(format!("worker {id} done")).unwrap(); // the message MOVES into the channel
        });
    }
    drop(sender); // the channel closes once every sender is gone
    let mut messages: Vec<String> = receiver.iter().collect(); // until the channel closes
    messages.sort(); // the arrival order of messages is unspecified
    println!("{messages:?}");

    // --- Atomics. C#: Interlocked ---------------------------------------------------
    let hits = AtomicU64::new(0);
    thread::scope(|scope| {
        for _ in 0..4 {
            scope.spawn(|| {
                for _ in 0..1000 {
                    hits.fetch_add(1, Ordering::Relaxed);
                }
            });
        }
    });
    println!("atomic hits = {}", hits.load(Ordering::Relaxed));

    // --- RwLock: many readers or one writer. C#: ReaderWriterLockSlim ----------------
    let settings = RwLock::new(HashMap::from([("mode", "fast")]));
    let before = settings.read().unwrap()["mode"];
    settings.write().unwrap().insert("mode", "safe");
    println!("mode: {before} -> {}", settings.read().unwrap()["mode"]);

    // --- Lazy global initialization. C#: Lazy<T> --------------------------------------
    static PRIMES: LazyLock<Vec<u32>> = LazyLock::new(|| {
        (2..50_u32)
            .filter(|n| (2..*n).all(|d| n % d != 0))
            .collect()
    });
    println!(
        "{} primes below 50, the last one is {:?}",
        PRIMES.len(),
        PRIMES.last()
    );

    // --- Send and Sync are checked at compile time ------------------------------------
    fn assert_send<T: Send>() {}
    assert_send::<Arc<Mutex<Vec<i32>>>>();
    // assert_send::<Rc<i32>>(); // E0277: `Rc<i32>` cannot be sent between threads safely
}

// =====================================================================================
//  14. MACROS
// =====================================================================================
//
//  A name with an exclamation mark (println!, vec!, format!) is a macro: code that
//  generates code at compile time. Macros take any number of arguments and check format
//  strings at compile time — an ordinary function cannot do that.
//  The closest thing in C# is source generators, but those are much heavier to write.

/// A declarative macro: pattern matching over TOKENS.
///   `$key:expr`   — an expression fragment (others: ident, ty, literal, pat, tt, ...);
///   `$( ... ),*`  — a comma-separated repetition, zero or more times;
///   `$(,)?`       — an optional trailing comma.
/// Macros are hygienic: the local `map` inside does not clash with your own `map` variable.
macro_rules! hashmap {
    ($($key:expr => $value:expr),* $(,)?) => {{
        let mut map = ::std::collections::HashMap::new();
        $( map.insert($key, $value); )*
        map
    }};
}

/// A recursive macro with two arms: `max!(a, b, c, ...)` for any number of arguments.
macro_rules! max {
    ($only:expr) => { $only };
    ($first:expr, $($rest:expr),+) => {{
        let (a, b) = ($first, max!($($rest),+));
        if a > b { a } else { b }
    }};
}

/// A macro that generates ITEMS (a type and its impls): this is how boilerplate is removed.
macro_rules! unit_type {
    ($name:ident, $suffix:literal) => {
        #[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
        struct $name(f64);

        impl fmt::Display for $name {
            fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
                write!(f, "{} {}", self.0, $suffix)
            }
        }

        impl std::ops::Add for $name {
            type Output = $name;
            fn add(self, rhs: $name) -> $name {
                $name(self.0 + rhs.0)
            }
        }
    };
}

unit_type!(Kilograms, "kg");
unit_type!(Newtons, "N");

/// A common trick: implement a trait for a whole list of types at once.
macro_rules! impl_describe_for_numbers {
    ($($ty:ty),+) => {
        $(
            impl Describe for $ty {
                fn name(&self) -> String {
                    format!("{self}{}", stringify!($ty)) // stringify! — tokens as a string
                }
            }
        )+
    };
}

impl_describe_for_numbers!(u8, u64, f64);

fn section14_macros() {
    header(14, "Macros");

    let capitals = hashmap! {
        "France" => "Paris",
        "Japan" => "Tokyo",
    };
    println!(
        "{} entries, France -> {:?}",
        capitals.len(),
        capitals.get("France")
    );
    println!("max: {} and {}", max!(3), max!(1.5, 9.25, -4.0));

    let total = Kilograms(2.5) + Kilograms(0.5);
    println!("{total} | {} | {}", Newtons(9.81), 7_u8.describe());
    // let nonsense = Kilograms(1.0) + Newtons(1.0); // E0308: macro-generated types do not mix

    // Built-in macros.
    let value = 6 * 7;
    println!("{} = {value}", stringify!(6 * 7)); // C#: [CallerArgumentExpression]
    println!("{}", concat!("glued ", "at ", "compile time"));
    assert!(value > 0, "value must be positive, got {value}"); // panics with this message
    assert_eq!(value, 42);
    debug_assert!(value < 100); // checked in debug builds only. C#: Debug.Assert
    // Also useful:
    //   todo!(), unimplemented!(), unreachable!() — stubs: they compile but panic when reached;
    //   dbg!(expr) — prints file, line, expression and value to stderr and returns the value;
    //   include_str!("file.txt"), include_bytes!(..) — embed a file at compile time;
    //   env!("VAR") — the value of an environment variable at compile time;
    //   compile_error!("...") — stop compilation with your own message.
    //
    // Procedural macros (`#[derive(Serialize)]`, `#[tokio::main]`, `sqlx::query!`) are
    // ordinary Rust functions "tokens -> tokens". They live in a separate crate, so they
    // cannot be shown in a single file.
}

// =====================================================================================
//  15. COMPILE-TIME EVALUATION
// =====================================================================================

/// A `const fn` can be called at compile time (C++: constexpr). C# has nothing like it:
/// there a constant can only be an expression made of literals.
const fn factorial(n: u64) -> u64 {
    if n <= 1 { 1 } else { n * factorial(n - 1) }
}

const FACTORIAL_20: u64 = factorial(20); // computed by the compiler, stored as a ready number

/// A CRC-32 table built at compile time. A const fn may contain loops, branches and
/// mutable locals, but not `for` yet: iterators are traits, and trait methods cannot be
/// called in constant evaluation so far. Hence `while`.
const fn build_crc_table() -> [u32; 256] {
    let mut table = [0_u32; 256];
    let mut index = 0;
    while index < 256 {
        let mut crc = index as u32;
        let mut bit = 0;
        while bit < 8 {
            crc = if crc & 1 != 0 {
                (crc >> 1) ^ 0xEDB8_8320
            } else {
                crc >> 1
            };
            bit += 1;
        }
        table[index] = crc;
        index += 1;
    }
    table
}

const CRC_TABLE: [u32; 256] = build_crc_table();

const fn crc32(bytes: &[u8]) -> u32 {
    let mut crc = u32::MAX;
    let mut index = 0;
    while index < bytes.len() {
        crc = CRC_TABLE[((crc ^ bytes[index] as u32) & 0xFF) as usize] ^ (crc >> 8);
        index += 1;
    }
    !crc
}

// Compile-time checks (C++: static_assert). `const _` is an unnamed constant that exists
// only so that its value gets computed.
const _: () = assert!(size_of::<Vec2>() == 16, "Vec2 must stay two f64 wide");
// The reference CRC-32 value for "123456789": a unit test executed by the compiler.
const _: () = assert!(crc32(b"123456789") == 0xCBF4_3926);

/// Checking a generic parameter: the `const { }` block is evaluated separately for each N.
fn first_element<const N: usize>(values: [i32; N]) -> i32 {
    const { assert!(N > 0, "the array must not be empty") };
    values[0]
}

fn section15_compile_time() {
    header(15, "Compile-time evaluation");

    // A const fn can also be called at run time — it is an ordinary function.
    println!(
        "20! = {FACTORIAL_20}, crc32(\"hello\") = {:#010x}",
        crc32(b"hello")
    );

    // A constant initialized by a block with a loop.
    const SQUARES: [u32; 8] = {
        let mut table = [0; 8];
        let mut i = 0;
        while i < 8 {
            table[i] = (i * i) as u32;
            i += 1;
        }
        table
    };
    println!("{SQUARES:?}, first_element = {}", first_element([7, 8, 9]));
    // first_element([]); // a COMPILE error: evaluation panicked: the array must not be empty

    // The result of a const fn fits wherever a constant is required — in an array length, say.
    let buffer = [0_u8; factorial(4) as usize]; // the type is [u8; 24]
    println!("buffer of {} bytes", buffer.len());
}

// =====================================================================================
//  16. ADVANCED TYPE SYSTEM
// =====================================================================================

// --- Typestate: the state of an object is written in its TYPE ---------------------------
// Invalid transitions do not "throw an exception" — they do not compile.

struct Disconnected; // marker types for the states
struct Connected;

struct Connection<State> {
    address: String,
    bytes_sent: usize,
    _state: PhantomData<State>, // a zero-sized field that "uses" the State parameter
}

impl Connection<Disconnected> {
    fn new(address: &str) -> Self {
        Connection {
            address: address.to_string(),
            bytes_sent: 0,
            _state: PhantomData,
        }
    }

    /// `self` by value: after the call the "disconnected" connection no longer exists.
    fn connect(self) -> Connection<Connected> {
        Connection {
            address: self.address,
            bytes_sent: self.bytes_sent,
            _state: PhantomData,
        }
    }
}

impl Connection<Connected> {
    fn send(&mut self, data: &[u8]) -> &mut Self {
        self.bytes_sent += data.len();
        self
    }

    fn disconnect(self) -> Connection<Disconnected> {
        Connection {
            address: self.address,
            bytes_sent: self.bytes_sent,
            _state: PhantomData,
        }
    }
}

/// Methods shared by all states.
impl<State> Connection<State> {
    fn address(&self) -> &str {
        &self.address
    }
}

// --- GATs: generic associated types ---------------------------------------------------

/// An associated type with a parameter OF ITS OWN (here, a lifetime). The classic example
/// is a "lending" iterator: its item borrows the iterator itself and lives only until the
/// next `next()`. The ordinary `Iterator` trait cannot express that.
trait LendingIterator {
    type Item<'a>
    where
        Self: 'a;

    fn next(&mut self) -> Option<Self::Item<'_>>;
}

/// Overlapping MUTABLE windows over a slice. (The standard `windows()` yields read-only
/// windows only: two overlapping `&mut` cannot exist at the same time.)
struct WindowsMut<'s, T> {
    slice: &'s mut [T],
    start: usize,
    size: usize,
}

impl<'s, T> LendingIterator for WindowsMut<'s, T> {
    type Item<'a>
        = &'a mut [T]
    where
        Self: 'a;

    fn next(&mut self) -> Option<&mut [T]> {
        let window = self.slice.get_mut(self.start..self.start + self.size)?;
        self.start += 1;
        Some(window)
    }
}

// --- HRTBs: higher-ranked trait bounds --------------------------------------------------

/// `for<'a>` reads "for ANY lifetime 'a": the closure must work with a string that lives
/// for any length of time and return a part of that same string.
fn map_strs<'s, F>(items: &'s [String], f: F) -> Vec<&'s str>
where
    F: for<'a> Fn(&'a str) -> &'a str,
{
    items.iter().map(|item| f(item)).collect()
}

// --- Any: type information at run time ---------------------------------------------------

/// A safe downcast. C#: `value is int number`.
/// This is all the reflection the language has: no list of fields or methods at run time.
fn describe_any(value: &dyn Any) -> String {
    if let Some(number) = value.downcast_ref::<i32>() {
        format!("i32 {number}")
    } else if let Some(text) = value.downcast_ref::<String>() {
        format!("String {text:?}")
    } else {
        "something else".to_string()
    }
}

// --- impl Trait in traits ---------------------------------------------------------------

/// A trait method can return `impl Trait` (Rust 1.75): every implementation hands out
/// its own iterator type — no Box and no virtual calls.
trait Graph {
    fn neighbors(&self, node: usize) -> impl Iterator<Item = usize>;
}

/// A graph given by adjacency lists.
struct AdjacencyList(Vec<Vec<usize>>);

impl Graph for AdjacencyList {
    fn neighbors(&self, node: usize) -> impl Iterator<Item = usize> {
        self.0[node].iter().copied()
    }
}

/// A ring of n nodes: neighbours are computed on the fly, no memory for edges is needed.
struct Ring(usize);

impl Graph for Ring {
    fn neighbors(&self, node: usize) -> impl Iterator<Item = usize> {
        [(node + self.0 - 1) % self.0, (node + 1) % self.0].into_iter()
    }
}

/// A generic algorithm on top of the trait: breadth-first traversal.
fn breadth_first(graph: &impl Graph, start: usize) -> Vec<usize> {
    let mut seen = HashSet::from([start]);
    let mut queue = VecDeque::from([start]);
    let mut order = Vec::new();
    while let Some(node) = queue.pop_front() {
        order.push(node);
        for next in graph.neighbors(node) {
            if seen.insert(next) {
                queue.push_back(next); // insert returned true: the node is seen for the first time
            }
        }
    }
    order
}

// --- Function pointers, type aliases, the `!` type --------------------------------------

/// A type alias (C#: `using UnaryOp = System.Func<double, double>;`).
/// `fn(f64) -> f64` is a function pointer: an address-sized value with no state.
/// Ordinary functions and closures that capture nothing coerce to it.
type UnaryOp = fn(f64) -> f64;

fn apply_all(value: f64, operations: &[(&str, UnaryOp)]) -> Vec<String> {
    operations
        .iter()
        .map(|(name, op)| format!("{name}({value}) = {:.3}", op(value)))
        .collect()
}

/// `!` (never) is the type of expressions that do not return control: `panic!`, `return`,
/// `break`, an infinite `loop`. It coerces to ANY type, so an arm with `panic!` does not
/// break the typing of a `match`. `-> !` in signatures has long been available; writing
/// `!` in any position (for example, `Result<T, !>`) is allowed since Rust 1.100
/// (November 2026).
fn fail(message: &str) -> ! {
    panic!("fatal: {message}")
}

fn section16_advanced_types() {
    header(16, "Advanced type system");

    // Typestate.
    let mut connection = Connection::new("db.local:5432").connect();
    connection.send(b"SELECT 1").send(b";");
    let closed = connection.disconnect();
    // closed.send(b"x"); // E0599: no method named `send` found for `Connection<Disconnected>`
    println!(
        "sent {} bytes to {}; PhantomData is free: {} == {}",
        closed.bytes_sent,
        closed.address(),
        size_of::<Connection<Connected>>(),
        size_of::<String>() + size_of::<usize>()
    );

    // GATs: smoothing with a sliding window right inside the original array.
    let mut samples = [1.0, 5.0, 3.0, 9.0, 4.0];
    let mut windows = WindowsMut {
        slice: &mut samples,
        start: 0,
        size: 3,
    };
    while let Some(window) = windows.next() {
        window[1] = (window[0] + window[1] + window[2]) / 3.0;
    }
    println!("smoothed in place: {samples:?}");

    // HRTB.
    let names = vec![String::from("  Ada "), String::from(" Grace")];
    println!("{:?}", map_strs(&names, |s| s.trim()));

    // Any.
    let values: [Box<dyn Any>; 3] = [
        Box::new(7_i32),
        Box::new(String::from("seven")),
        Box::new(7.0),
    ];
    for value in &values {
        print!("{}; ", describe_any(value.as_ref()));
    }
    println!(
        "type_name: {}",
        std::any::type_name::<HashMap<String, Vec<u8>>>()
    );

    // impl Trait in traits.
    let list = AdjacencyList(vec![vec![1, 2], vec![3], vec![3], vec![]]);
    println!(
        "bfs: {:?}, ring: {:?}",
        breadth_first(&list, 0),
        breadth_first(&Ring(5), 0)
    );

    // Function pointers: methods, functions and non-capturing closures in one array.
    for line in apply_all(
        2.0,
        &[
            ("sqrt", f64::sqrt),
            ("exp", f64::exp),
            ("half", |x| x / 2.0),
        ],
    ) {
        println!("    {line}");
    }

    // `!` at work: the match arms have types u32 and `!`; the result is u32.
    let parsed: u32 = match "42".parse() {
        Ok(number) => number,
        Err(_) => fail("not a number"),
    };
    println!("parsed {parsed}");
}

// =====================================================================================
//  17. UNSAFE AND FFI
// =====================================================================================
//
//  `unsafe` does NOT switch off the borrow checker or the other checks. It only permits
//  five extra actions:
//    1) dereferencing raw pointers `*const T` / `*mut T`;
//    2) calling unsafe functions (including foreign ones, from C);
//    3) accessing a `static mut`;
//    4) implementing unsafe traits (Send and Sync, for example);
//    5) reading union fields.
//  The idea: a small unsafe core wrapped in a safe API whose invariants are your
//  responsibility. By convention every unsafe block carries a `// SAFETY:` comment.
//  C#: `unsafe { }`, pointers and `fixed` — the same role and the same rarity of use.

// FFI: declarations of functions from a C library (here libc, which std links against
// anyway). C#: [DllImport] / [LibraryImport]. In edition 2024 the block must be
// `unsafe extern`; a function whose contract cannot be violated may be marked `safe`.
unsafe extern "C" {
    safe fn abs(value: c_int) -> c_int;
    fn strlen(text: *const c_char) -> usize;
    fn qsort(
        base: *mut c_void,
        count: usize,
        size: usize,
        compare: extern "C" fn(*const c_void, *const c_void) -> c_int,
    );
}

/// A function with the C calling convention: it can be handed to C code as a callback.
/// C#: `[UnmanagedCallersOnly]` + a `delegate* unmanaged` function pointer.
extern "C" fn compare_i32(a: *const c_void, b: *const c_void) -> c_int {
    // SAFETY: qsort passes pointers to elements of an i32 array.
    let (a, b) = unsafe { (*a.cast::<i32>(), *b.cast::<i32>()) };
    a.cmp(&b) as c_int // Ordering is an enum with the values -1, 0, 1
}

/// `#[repr(C)]` fixes the field layout to that of C (C#: `[StructLayout(Sequential)]`).
/// Without it the compiler is free to reorder fields for tighter packing.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
struct Rgba {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}

/// `union`: all fields share one piece of memory (C#: `[StructLayout(Explicit)]` +
/// `[FieldOffset(0)]`). Reading a field is unsafe: the compiler does not know which one
/// was written last.
#[repr(C)]
union Pixel {
    rgba: Rgba,
    packed: u32,
    bytes: [u8; 4],
}

/// An unsafe function: it has a precondition the compiler cannot check.
/// By convention it is described in a `# Safety` section of the documentation.
///
/// # Safety
/// `index` must be less than `values.len()`.
unsafe fn element_unchecked(values: &[f64], index: usize) -> f64 {
    // Since edition 2024, unsafe operations inside an unsafe function are written in an
    // `unsafe` block as well (otherwise the compiler warns).
    unsafe { *values.get_unchecked(index) }
}

/// A mutable global variable: every access is unsafe (a data race is possible).
/// New code uses atomics, Mutex or LazyLock instead (section 13).
static mut LEGACY_CALLS: u32 = 0;

/// A wrapper around a raw pointer is not Send by default. If WE guarantee that access to
/// the data is synchronized, the promise is made explicitly — with `unsafe impl`.
struct FrameBuffer(*mut u8);

unsafe impl Send for FrameBuffer {}

/// A safe abstraction over unsafe: a fixed-capacity vector with no heap
/// (C#: `stackalloc` or `[InlineArray]` plus manual length tracking).
/// INVARIANT: the elements at `0..len` are initialized; the rest are not.
struct ArrayVec<T, const N: usize> {
    items: [MaybeUninit<T>; N], // memory for N elements, possibly uninitialized
    len: usize,
}

impl<T, const N: usize> ArrayVec<T, N> {
    fn new() -> Self {
        Self {
            items: [const { MaybeUninit::uninit() }; N],
            len: 0,
        }
    }

    /// On overflow the value is handed back to the caller.
    fn push(&mut self, value: T) -> Result<(), T> {
        if self.len == N {
            return Err(value);
        }
        self.items[self.len].write(value); // writing into an uninitialized slot is safe
        self.len += 1;
        Ok(())
    }

    fn pop(&mut self) -> Option<T> {
        if self.len == 0 {
            return None;
        }
        self.len -= 1;
        // SAFETY: slot `len` was initialized by push, and after len is decremented it no longer
        // counts as occupied, so the value will not be read twice.
        Some(unsafe { self.items[self.len].assume_init_read() })
    }

    fn as_slice(&self) -> &[T] {
        // SAFETY: the first `len` elements are initialized (the invariant), and the layout of
        // MaybeUninit<T> is the same as that of T.
        unsafe { std::slice::from_raw_parts(self.items.as_ptr().cast::<T>(), self.len) }
    }
}

impl<T, const N: usize> Drop for ArrayVec<T, N> {
    fn drop(&mut self) {
        // MaybeUninit destroys nothing by itself: the live elements must be dropped manually.
        for slot in &mut self.items[..self.len] {
            // SAFETY: the slots `0..len` are initialized (the invariant).
            unsafe { slot.assume_init_drop() };
        }
    }
}

fn section17_unsafe_and_ffi() {
    header(17, "unsafe and FFI");

    // --- Raw pointers -----------------------------------------------------------------
    let mut value = 10;
    let reader: *const i32 = &raw const value; // creating a raw pointer is safe
    let writer: *mut i32 = &raw mut value;
    // SAFETY: both pointers refer to a live local variable; no references to it exist now.
    unsafe {
        *writer += 1;
        println!("through raw pointers: {}", *reader);
    }

    // Pointer arithmetic. C: `*(p + 2)`.
    let array = [10, 20, 30, 40];
    let pointer = array.as_ptr();
    // SAFETY: offset 2 is inside the array of four elements.
    let third = unsafe { *pointer.add(2) };
    // SAFETY: index 1 is less than the slice length.
    let unchecked = unsafe { element_unchecked(&[0.5, 1.5], 1) };
    println!("third = {third}, unchecked = {unchecked}");

    // Two non-overlapping `&mut` into one slice: the borrow checker cannot prove that alone.
    // std implements split_at_mut with unsafe and exposes a safe API.
    let mut numbers = [1, 2, 3, 4, 5, 6];
    let (left, right) = numbers.split_at_mut(3);
    left[0] += right[0];
    std::mem::swap(&mut left[1], &mut right[1]);
    // The same for individual elements (Rust 1.86): Err if indices coincide or are out of bounds.
    if let Ok([first, last]) = numbers.get_disjoint_mut([0, 5]) {
        std::mem::swap(first, last);
    }
    println!("{numbers:?}");

    // --- Reinterpreting bits ------------------------------------------------------------
    // Numbers have safe methods for this: to_bits / from_bits, to_le_bytes / from_le_bytes.
    let bits = 1.0_f32.to_bits();
    let float = f32::from_bits(0x4049_0FDB);
    println!("1.0f32 is {bits:#x}; 0x40490fdb is {float}");

    // transmute is the last resort: "treat these bytes as a value of another type".
    let color = Rgba {
        r: 0x11,
        g: 0x22,
        b: 0x33,
        a: 0xFF,
    };
    // SAFETY: Rgba is a #[repr(C)] struct of four u8: its size equals the size of u32,
    // and any bit pattern is a valid u32.
    let transmuted = unsafe { std::mem::transmute::<Rgba, u32>(color) };
    let pixel = Pixel { rgba: color };
    // SAFETY: all fields of Pixel are plain 4-byte data; any of them may be read.
    let (packed, bytes) = unsafe { (pixel.packed, pixel.bytes) };
    println!(
        "transmute {transmuted:#010x} == union {packed:#010x} (LE), bytes {bytes:02x?}, size {}",
        size_of::<Pixel>()
    );

    // --- Calling into C ---------------------------------------------------------------
    let text = c"hello from C"; // a C string literal: a &CStr with a terminating NUL (Rust 1.77)
    // SAFETY: a pointer to a valid C string is passed.
    let length = unsafe { strlen(text.as_ptr()) };
    let mut unsorted = [42, -7, 19, 0, 3];
    // SAFETY: the pointer, the element count and the element size describe the array
    // `unsorted`, and the comparison function reads exactly one i32 through each pointer.
    unsafe {
        qsort(
            unsorted.as_mut_ptr().cast(),
            unsorted.len(),
            size_of::<i32>(),
            compare_i32,
        )
    };
    println!(
        "abs(-7) = {}, strlen = {length}, qsort: {unsorted:?}",
        abs(-7)
    );

    // --- static mut -------------------------------------------------------------------
    // SAFETY: the program is single-threaded here; nothing else touches LEGACY_CALLS.
    let calls = unsafe {
        LEGACY_CALLS += 1;
        LEGACY_CALLS
    };
    println!("legacy calls = {calls}");

    // --- A safe wrapper over unsafe ------------------------------------------------------
    let mut small: ArrayVec<String, 2> = ArrayVec::new();
    small.push("alpha".to_string()).unwrap();
    small.push("beta".to_string()).unwrap();
    let overflow = small.push("gamma".to_string()); // Err: no room left, the string is handed back
    println!("{:?}, overflow: {overflow:?}", small.as_slice());
    println!(
        "popped {:?}, {} bytes on the stack, no heap for the array",
        small.pop(),
        size_of_val(&small)
    );
} // here Drop for ArrayVec destroys the remaining string "alpha"

// =====================================================================================
//  18. ASYNC/AWAIT FROM THE INSIDE
// =====================================================================================
//
//  An `async fn` returns a Future — a state machine that DOES NOTHING BY ITSELF until it
//  is polled with `poll`. Differences from C#:
//    - a C# Task is "hot" (it starts running at once); a Rust Future is "lazy";
//    - no allocation per async call: nested futures are inlined into one state machine;
//    - the executor is not part of the language but a library: tokio, smol, embassy.
//  Below is a hand-written executor that shows the mechanics: the Future trait,
//  Poll, Context and Waker, and pinning with Pin.

/// A Future that is ready on the second poll: it yields control to the executor.
/// C#: `await Task.Yield()`.
struct YieldNow {
    yielded: bool,
}

impl Future for YieldNow {
    type Output = ();

    /// `Pin<&mut Self>` guarantees that the future is not moved in memory between polls:
    /// the state machine may hold references to its own fields.
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<()> {
        if self.yielded {
            return Poll::Ready(());
        }
        self.yielded = true;
        cx.waker().wake_by_ref(); // "poll me again" — otherwise the task would be forgotten
        Poll::Pending
    }
}

fn yield_now() -> YieldNow {
    YieldNow { yielded: false }
}

/// A timer. C#: `Task.Delay`. For simplicity it starts a helper thread that wakes the
/// task; real runtimes keep one shared timer queue.
struct Sleep {
    deadline: Instant,
    timer_started: bool,
}

impl Future for Sleep {
    type Output = ();

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<()> {
        if Instant::now() >= self.deadline {
            return Poll::Ready(());
        }
        if !self.timer_started {
            self.timer_started = true;
            let waker = cx.waker().clone(); // a Waker is the "handle" used to wake the task
            let deadline = self.deadline;
            thread::spawn(move || {
                thread::sleep(deadline.saturating_duration_since(Instant::now()));
                waker.wake();
            });
        }
        Poll::Pending
    }
}

fn sleep(duration: Duration) -> Sleep {
    Sleep {
        deadline: Instant::now() + duration,
        timer_started: false,
    }
}

/// The Waker for `block_on`: it wakes a parked thread. The `Wake` trait turns an `Arc<T>`
/// into a Waker without hand-written function tables.
struct ThreadWaker(thread::Thread);

impl Wake for ThreadWaker {
    fn wake(self: Arc<Self>) {
        self.0.unpark();
    }
}

/// The simplest executor: polls one future on the current thread until it is ready.
/// C#: `task.GetAwaiter().GetResult()`.
fn block_on<F: Future>(future: F) -> F::Output {
    let mut future = pin!(future); // pin it to the stack: it must not move after the first poll
    let waker = Waker::from(Arc::new(ThreadWaker(thread::current())));
    let mut cx = Context::from_waker(&waker);
    loop {
        match future.as_mut().poll(&mut cx) {
            Poll::Ready(output) => return output,
            Poll::Pending => thread::park(), // sleep until someone calls wake()
        }
    }
}

/// Waiting for two futures concurrently on ONE thread. C#: `Task.WhenAll`.
async fn join2<A: Future, B: Future>(a: A, b: B) -> (A::Output, B::Output) {
    let (mut a, mut b) = (pin!(a), pin!(b));
    let (mut result_a, mut result_b) = (None, None);
    // poll_fn builds a future from a closure: handy for hand-written combinators.
    std::future::poll_fn(move |cx| {
        if result_a.is_none()
            && let Poll::Ready(output) = a.as_mut().poll(cx)
        {
            result_a = Some(output);
        }
        if result_b.is_none()
            && let Poll::Ready(output) = b.as_mut().poll(cx)
        {
            result_b = Some(output);
        }
        if result_a.is_some() && result_b.is_some() {
            Poll::Ready((result_a.take().unwrap(), result_b.take().unwrap()))
        } else {
            Poll::Pending
        }
    })
    .await
}

/// An ordinary async function. The compiler turns it into a state machine (an enum with a
/// variant per `.await` point). `.await` is postfix, which suits chains: `x.await?.len()`.
async fn fetch(name: &str, delay_ms: u64) -> u64 {
    sleep(Duration::from_millis(delay_ms)).await;
    name.len() as u64 * delay_ms
}

/// Async closures and the `AsyncFn*` traits (Rust 1.85). C#: `Func<uint, Task<uint>>`.
async fn retry<F>(attempts: u32, operation: F) -> Result<u32, String>
where
    F: AsyncFn(u32) -> Result<u32, String>,
{
    let mut last = Err("no attempts were made".to_string());
    for attempt in 1..=attempts {
        last = operation(attempt).await;
        if last.is_ok() {
            break;
        }
    }
    last
}

/// `async fn` in traits (Rust 1.75). C#: an interface method that returns `Task<T>`.
trait Sensor {
    async fn read(&self) -> f64;
}

struct Thermometer {
    celsius: f64,
}

impl Sensor for Thermometer {
    async fn read(&self) -> f64 {
        yield_now().await;
        self.celsius
    }
}

async fn average_reading(sensor: &impl Sensor, samples: u32) -> f64 {
    let mut sum = 0.0;
    for _ in 0..samples {
        sum += sensor.read().await;
    }
    sum / f64::from(samples)
}

// --- An executor with a task queue: real runtimes in miniature --------------------------

/// A future of an arbitrary type, pinned on the heap. C#: simply `Task`.
type BoxFuture = Pin<Box<dyn Future<Output = ()> + Send>>;

struct Task {
    future: Mutex<Option<BoxFuture>>, // None — the task has finished
    ready_queue: mpsc::Sender<Arc<Task>>,
}

impl Wake for Task {
    /// Waking a task = putting it back into the ready queue.
    fn wake(self: Arc<Self>) {
        let _ = self.ready_queue.send(Arc::clone(&self));
    }
}

struct Executor {
    sender: mpsc::Sender<Arc<Task>>,
    receiver: mpsc::Receiver<Arc<Task>>,
}

impl Executor {
    fn new() -> Self {
        let (sender, receiver) = mpsc::channel();
        Self { sender, receiver }
    }

    /// C#: `Task.Run`. The future must be Send + 'static: the task outlives its creator.
    fn spawn(&self, future: impl Future<Output = ()> + Send + 'static) {
        let task = Task {
            future: Mutex::new(Some(Box::pin(future))),
            ready_queue: self.sender.clone(),
        };
        self.sender.send(Arc::new(task)).expect("the queue is open");
    }

    /// Polls ready tasks until none are left.
    fn run(self) {
        let Executor { sender, receiver } = self;
        drop(sender); // now the channel closes once all tasks and their Wakers are gone
        while let Ok(task) = receiver.recv() {
            let mut slot = task.future.lock().unwrap();
            if let Some(mut future) = slot.take() {
                let waker = Waker::from(Arc::clone(&task));
                let mut cx = Context::from_waker(&waker);
                if future.as_mut().poll(&mut cx).is_pending() {
                    *slot = Some(future); // not ready: put it back until the next wake()
                }
            }
        }
    }
}

fn section18_async() {
    header(18, "async/await from the inside");

    // A Future is lazy: creating it starts nothing.
    let future = fetch("alpha", 30);
    println!(
        "future created, nothing has run yet; its state machine takes {} bytes",
        size_of_val(&future)
    );
    println!("block_on -> {}", block_on(future));

    // Two futures concurrently on one thread: the total time is the maximum, not the sum.
    let started = Instant::now();
    let (beta, gamma) = block_on(join2(fetch("beta", 40), fetch("gamma", 20)));
    println!(
        "join2 -> ({beta}, {gamma}) in about {} ms (not 60)",
        started.elapsed().as_millis()
    );

    // An async block, an async closure and an async trait method.
    let (result, attempts, average) = block_on(async {
        let attempts = RefCell::new(Vec::new());
        // The closure borrows `attempts`, and so does the future it returns.
        let result = retry(5, async |attempt| {
            attempts.borrow_mut().push(attempt);
            yield_now().await;
            if attempt < 3 {
                Err(format!("attempt {attempt} failed"))
            } else {
                Ok(attempt * 14)
            }
        })
        .await;
        let average = average_reading(&Thermometer { celsius: 21.5 }, 4).await;
        (result, attempts.into_inner(), average)
    });
    println!("retry -> {result:?} after attempts {attempts:?}; average reading {average}");

    // An executor with a queue: three independent tasks on one thread.
    let log = Arc::new(Mutex::new(Vec::new()));
    let executor = Executor::new();
    for (name, delay_ms) in [("slow", 45), ("fast", 15), ("medium", 30)] {
        let log = Arc::clone(&log);
        executor.spawn(async move {
            sleep(Duration::from_millis(delay_ms)).await;
            log.lock().unwrap().push(name);
        });
    }
    executor.run();
    println!("tasks finished in this order: {:?}", log.lock().unwrap());
}

// =====================================================================================
//  ENTRY POINT
// =====================================================================================

/// `main` may return a Result: on `Err` the program prints the error to stderr and exits
/// with code 1. That is why the `?` operator can be used inside it.
fn main() -> Result<(), Box<dyn Error>> {
    section01_basics();
    section02_functions_and_data();
    section03_ownership();
    section04_structs();
    section05_enums_and_patterns();
    section06_errors()?;
    section07_collections();
    section08_closures_and_iterators();
    section09_traits_and_generics();
    section10_lifetimes();
    section11_smart_pointers();
    section12_modules();
    section13_concurrency();
    section14_macros();
    section15_compile_time();
    section16_advanced_types();
    section17_unsafe_and_ffi();
    section18_async();

    println!("\nAll 18 sections completed.");
    Ok(())
}
