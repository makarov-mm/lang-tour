// =================================================================================================
//  C FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
//
//  Build and run (a C23 compiler is required; `-lm` links the math library):
//      gcc   -std=c23 -O2 -Wall -Wextra -Wpedantic c_tour.c -o c_tour -lm && ./c_tour
//      clang -std=c23 -O2 -Wall -Wextra -Wpedantic c_tour.c -o c_tour -lm && ./c_tour
//
//  Verified with GCC 14.2 and Clang 20 on Linux (glibc 2.39), also under the address and
//  undefined-behaviour sanitizers, and as a Windows build made with MinGW-w64 GCC 13
//  (-std=c2x) and run under Wine. MSVC has not been tested: its C compiler does not
//  implement enough of C23 (constexpr, _BitInt, [[attributes]] ...).
//
//  Parts of the library that not every platform has (<threads.h>, <stdbit.h>, <stdckdint.h>)
//  are detected with __has_include; where one is missing, its example is skipped.
//
//  How to read. Each section is a function `sectionNN_*`; the types and functions a section
//  needs are declared right before it; `main()` at the end calls the sections in order.
//  A "C#:" note shows the closest C# counterpart.
//
//  The main differences from C# to keep in mind from the first line:
//
//   1. No runtime underneath: no garbage collector, no exceptions, no bounds checks, no
//      reflection. Source is compiled straight to machine code; what you write is what runs.
//   2. Manual memory management. Every malloc needs exactly one free; the language does not
//      help you remember, and getting it wrong is silent memory corruption.
//   3. Undefined behaviour (UB). Indexing outside an array, using freed memory, overflowing a
//      signed integer, reading an uninitialized variable: no error is raised, the program is
//      simply allowed to do anything (section 10).
//   4. No classes, methods, generics, namespaces, overloading or closures. A program is made
//      of functions and plain data; everything else is a convention built on pointers.
//   5. Strings and arrays are not objects: they are raw memory. An array does not know its
//      length, a string is "bytes up to the first zero".
//   6. The preprocessor rewrites the text before compilation (#include, #define), and code
//      is split into headers (.h, declarations) and translation units (.c, definitions).
//
//  Contents:
//    1. Basics: types, variables, control flow        7. Function pointers and callbacks
//    2. Functions                                      8. The preprocessor and generic code
//    3. Pointers and arrays                            9. Errors and I/O
//    4. Strings                                       10. Bits, integers, undefined behaviour
//    5. Structs, unions, enums                        11. Concurrency
//    6. Dynamic memory                                12. C23 in one place
// =================================================================================================

// `#include` pastes a header file in textually; a header holds declarations only.
// C#: using + an assembly reference, except that nothing is linked automatically.
#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <inttypes.h>
#include <limits.h>
#include <math.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Conditional compilation. C#: #if. __has_include asks whether a header exists.
#if __has_include(<stdbit.h>)
#include <stdbit.h>
#define HAVE_STDBIT 1
#endif
#if __has_include(<stdckdint.h>)
#include <stdckdint.h>
#define HAVE_STDCKDINT 1
#endif
#if !defined(__STDC_NO_ATOMICS__)
#include <stdatomic.h>
#define HAVE_ATOMICS 1
#endif
#if !defined(__STDC_NO_THREADS__) && __has_include(<threads.h>)
#include <threads.h>
#define HAVE_THREADS 1
#endif

#if defined(_WIN32)
#define PLATFORM "Windows"
#elif defined(__linux__)
#define PLATFORM "Linux"
#elifdef __APPLE__ // C23 spelling of `#elif defined(...)`
#define PLATFORM "macOS"
#else
#define PLATFORM "unknown"
#endif

// `static` at file scope: visible in this translation unit only. C#: private / internal.
static void header(const char *title) { printf("\n=== %s ===\n", title); }

// =================================================================================================
//  1. BASICS: types, variables, control flow
// =================================================================================================

constexpr int max_points = 100'000; // C23: a real compile-time constant. C#: const
#define BUFFER_SIZE 64              // the classic way: plain text substitution
enum { RETRIES = 3 };               // the pre-C23 idiom: an unnamed enum as an integer constant

static void section01_basics(void) {
    header("1. Basics");

    // --- Built-in types ---
    // Unlike C#, sizes are implementation-defined: int is "at least 16 bits", long is 64 bits
    // on Linux and 32 on Windows. When the width matters, use the <stdint.h> types.
    int a = 42;
    unsigned u = 42u;
    long long big = 9'000'000'000LL; // digit separators (C23)
    double d = 3.5;
    float f = 2.5f;
    char letter = 'A';    // ONE BYTE, not a UTF-16 unit; the constant 'A' itself has type int
    bool flag = true;     // keywords since C23 (before: _Bool and <stdbool.h>)
    int32_t exact = -1;   // exactly 32 bits
    uint8_t byte = 0xFF;  // exactly 8 bits, unsigned
    size_t count = sizeof(int); // the unsigned type of sizes and indices. C#: nuint
    // printf: the format string decides how the arguments are read; a mismatch is UB.
    printf("%d %u %lld %.1f %.1f %c %d %" PRId32 " %d %zu\n", a, u, big, d, (double)f, letter, flag,
           exact, byte, count);
    printf("sizeof: char %zu, short %zu, int %zu, long %zu, long long %zu, pointer %zu\n",
           sizeof(char), sizeof(short), sizeof(int), sizeof(long), sizeof(long long),
           sizeof(void *));
    printf("INT_MAX %d, CHAR_BIT %d, 0b1010 = %d, 0x1F = %d, 017 = %d (a leading 0 means octal)\n",
           INT_MAX, CHAR_BIT, 0b1010, 0x1F, 017);
    printf("constants: %d %d %d\n", max_points, BUFFER_SIZE, RETRIES);

    // A local variable without an initializer holds garbage, and reading it is UB.
    // (C#: compile error CS0165.) `= {}` is the universal zero initializer (C23).
    int zeroed = {};

    // --- Type inference (C23) ---
    auto inferred = 2.5 * a;      // double. C#: var
    typeof(a) same_type = a + 1;  // typeof names the type of an expression
    printf("%d %.1f %d\n", zeroed, inferred, same_type);

    // --- Conversions: implicit and silent ---
    double ratio = a / 5;         // integer division first (8), and only then 8 -> 8.0
    int truncated = (int)3.99;    // a cast; this is the only cast syntax C has
    double precise = 3.7;
    int narrowed = precise;       // compiles without a cast (C# rejects it): the fraction is lost
    unsigned wrapped = 0u - 1u;   // unsigned arithmetic wraps modulo 2^N — this is defined
    // int overflow = INT_MAX + 1; // SIGNED overflow is undefined behaviour!
    // Mixing signed and unsigned silently converts the signed operand: -1 turns into UINT_MAX,
    // so `-1 < 1u` is false. (The cast below makes that conversion visible.)
    int minus_one = -1;
    bool surprising = (unsigned)minus_one < 1u;
    printf("%.1f %d %d %u %d\n", ratio, truncated, narrowed, wrapped, surprising);

    // --- Control flow ---
    // Any scalar is a condition: zero is false, everything else is true (C# demands a bool).
    int sum = 0;
    for (int i = 0; i < 5; i++) sum += i;
    int n = 3;
    while (n--) sum += 10; // runs while n is non-zero
    do {
        sum++;
    } while (sum % 7 != 0);

    // switch falls through from one case into the next unless a `break` stops it.
    const char *kind;
    switch (letter) {
        case 'A':
        case 'E':
            kind = "vowel";
            break;
        case 'B':
            sum += 1000;
            [[fallthrough]]; // attribute: the fall-through is intentional, do not warn
        default:
            kind = "consonant";
    }
    const char *parity = (sum % 2 == 0) ? "even" : "odd";
    printf("sum %d is %s, '%c' is a %s\n", sum, parity, letter, kind);
    // `goto` exists and has one respectable use: jumping forward to cleanup code (section 6).
}

// =================================================================================================
//  2. FUNCTIONS
// =================================================================================================

// A declaration (prototype). The compiler reads the file top to bottom: a function must be
// declared before it is called. In a real project the prototypes live in a header that is
// #included by every .c file that uses them.
static int gcd(int a, int b);

static int square(int x) { return x * x; }

// Arguments are ALWAYS passed by value. To change the caller's variable, pass its address.
static int doubled(int value) {
    value *= 2; // changes the function's own copy only
    return value;
}
static void increment(int *value) { (*value)++; } // C#: ref int value

// Several results: through "out" pointers (or by returning a struct, section 5).
static bool divide(int dividend, int divisor, int *quotient, int *remainder) {
    if (divisor == 0) return false;
    *quotient = dividend / divisor;
    *remainder = dividend % divisor;
    return true;
}

// A static local keeps its value between calls: it lives as long as the program does.
static int next_id(void) {
    static int counter = 0;
    return ++counter;
}

// An array parameter is really a pointer, so the length travels separately.
static int sum_array(const int values[], size_t count) {
    int total = 0;
    for (size_t i = 0; i < count; i++) total += values[i];
    return total;
}

// A variadic function: the callee cannot know how many arguments it got or of which type.
// C#: params, but without any type safety.
static double average(int count, ...) {
    va_list args;
    va_start(args, count);
    double total = 0;
    for (int i = 0; i < count; i++) total += va_arg(args, double);
    va_end(args);
    return count > 0 ? total / count : 0;
}

[[nodiscard]] static int must_use(void) { return 42; } // a warning if the result is ignored
static inline int max_int(int a, int b) { return a > b ? a : b; }
static int gcd(int a, int b) { return b == 0 ? a : gcd(b, a % b); }
// No overloading, no default arguments, no namespaces: every function needs a unique name,
// hence prefixes such as `vec2_add` or `list_free` below.

static void section02_functions(void) {
    header("2. Functions");
    int x = 5;
    int twice = doubled(x);
    printf("after doubled(x): x = %d, result %d\n", x, twice);
    increment(&x);
    printf("after increment(&x): x = %d\n", x);

    int quotient, remainder;
    if (divide(17, 5, &quotient, &remainder)) printf("17 / 5 = %d rem %d\n", quotient, remainder);
    printf("division by zero accepted: %d\n", divide(1, 0, &quotient, &remainder));

    // The evaluation order of function arguments is unspecified (C#: strictly left to right),
    // so calls with side effects go into separate statements.
    int first = next_id();
    int second = next_id();
    int values[] = {3, 1, 4, 1, 5};
    printf("ids %d %d, sum %d, average %.2f, gcd %d, square %d, max %d\n", first, second,
           sum_array(values, 5), average(3, 1.0, 2.0, 6.0), gcd(84, 36), square(7), max_int(3, 9));
    int used = must_use();
    // must_use();   // warning: ignoring return value of 'must_use', declared 'nodiscard'
    printf("%d\n", used);
}

// =================================================================================================
//  3. POINTERS AND ARRAYS
// =================================================================================================

static void swap_ints(int *a, int *b) {
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

static void section03_pointers(void) {
    header("3. Pointers and arrays");

    // --- Pointers: variables that hold an address ---
    int x = 10, y = 99;
    int *p = &x;           // `&x` takes the address, `*p` goes to the object ("dereference")
    *p = 20;
    int **pp = &p;         // a pointer to a pointer
    **pp += 1;
    int *nothing = nullptr; // C23 keyword; older code uses the macro NULL
    printf("x = %d, *p = %d, p == &x: %d, null: %d\n", x, *p, p == &x, nothing == nullptr);
    // *nothing = 1;       // UB (in practice a crash), not a NullReferenceException
    swap_ints(&x, &y);
    printf("swapped: x = %d, y = %d\n", x, y);

    // --- const ---
    const int limit = 100;       // read-only through this name. C#: readonly, roughly
    const int *read_only = &x;   // pointer to const: `*read_only = 1` is an error
    int *const fixed = &x;       // const pointer: `fixed = &y` is an error, `*fixed = 1` is fine
    *fixed = 30;
    printf("%d %d %d\n", limit, *read_only, x);

    // --- Arrays: a fixed block of elements, with no length stored anywhere ---
    int primes[5] = {2, 3, 5, 7, 11};
    int zeros[8] = {};                    // all zero
    int sparse[6] = {[1] = 10, [4] = 40}; // designated initializers; the rest is zero
    size_t n = sizeof primes / sizeof primes[0]; // the element-count idiom
    // In most expressions an array "decays" into a pointer to its first element, and
    // `a[i]` is defined as `*(a + i)`. Pointer arithmetic moves in units of the element size.
    int *first = primes;
    printf("%zu elements: %d %d %d, sparse %d, zeros %d\n", n, first[2], *(first + 2), 2 [primes],
           sparse[4], zeros[7]);
    // There are NO bounds checks: primes[10] is undefined behaviour, not an exception.
    for (int *it = primes; it != primes + n; ++it) *it *= 2; // a pointer as an "iterator"
    ptrdiff_t distance = &primes[4] - &primes[1];             // a difference counts elements
    printf("doubled: %d..%d, distance %td, sum %d\n", primes[0], primes[4], distance,
           sum_array(primes, n));

    // --- Multidimensional and variable-length arrays ---
    int grid[2][3] = {{1, 2, 3}, {4, 5, 6}}; // one contiguous block, row after row
    size_t rows = 3;
    int vla[rows]; // a VLA: the size is a run-time value, the storage is on the stack
    for (size_t i = 0; i < rows; i++) vla[i] = (int)(i * i);
    printf("grid[1][2] = %d, sizeof grid = %zu, vla[2] = %d, sizeof vla = %zu\n", grid[1][2],
           sizeof grid, vla[2], sizeof vla);

    // --- void*: a pointer to "something" ---
    void *anything = &x;   // any object pointer converts to void* implicitly
    int *back = anything;  // ...and back, without a cast (C++ requires one)
    printf("through void*: %d\n", *back);
    // Passing an array to a function passes the pointer: the callee can modify the elements
    // and cannot find out the length. C#: Span<T> carries the length, a C pointer does not.
}

// =================================================================================================
//  4. STRINGS
// =================================================================================================

static void section04_strings(void) {
    header("4. Strings");

    // There is no string type: a string is a char array that ends with a zero byte ('\0').
    char greeting[] = "Hello";     // a mutable array of 6 chars: five letters and '\0'
    const char *literal = "World"; // a pointer to a read-only literal
    greeting[0] = 'J';
    // literal[0] = 'w';           // UB: string literals must not be modified
    printf("%s %s, strlen %zu, sizeof %zu\n", greeting, literal, strlen(greeting), sizeof greeting);

    // No `+` for strings. snprintf formats into a buffer and never writes past its end.
    char buffer[32];
    int written = snprintf(buffer, sizeof buffer, "%s, %s! %d", greeting, literal, 2026);
    printf("%s (%d chars)\n", buffer, written);
    // strcpy(buffer, some_long_text);   // the classic buffer overflow: no size check at all

    // `==` compares ADDRESSES; strcmp compares contents and returns 0 for equal strings.
    char twin[] = "Jello";
    const char *left = greeting, *right = twin;
    printf("same address: %d, strcmp: %d, strncmp(apple, apply, 4): %d\n", left == right,
           strcmp(left, right), strncmp("apple", "apply", 4));

    // Searching and splitting.
    const char *text = "key=value;mode=fast";
    const char *equals = strchr(text, '=');
    printf("'=' at %td, tail \"%s\"\n", equals - text, strstr(text, "mode"));
    char line[] = "alpha,beta,,gamma"; // strtok writes '\0' into the string it splits
    for (char *token = strtok(line, ","); token != nullptr; token = strtok(nullptr, ","))
        printf("[%s] ", token);
    printf("\n");

    // Numbers <-> strings.
    char *end;
    long number = strtol("123abc", &end, 10);
    printf("%ld, rest \"%s\", %.1f, %d\n", number, end, strtod("2.5e3", nullptr), atoi("42"));

    // <ctype.h> classifies single characters.
    char shout[16] = "MiXed 42";
    for (char *c = shout; *c != '\0'; c++) *c = (char)toupper((unsigned char)*c);
    printf("%s, isdigit('7') %d, isalpha('7') %d\n", shout, isdigit('7') != 0, isalpha('7') != 0);

    // A char is a byte, not a character: strlen counts bytes of the UTF-8 encoding.
    printf("\"Gr\\u00fc\\u00dfe\": %zu bytes for 5 characters\n", strlen("Gr\u00fc\u00dfe"));

    // A string on the heap: strdup allocates a copy that the caller must free (section 6).
    char *owned = strdup("heap copy");
    if (owned != nullptr) {
        owned[0] = 'H';
        printf("%s\n", owned);
        free(owned);
    }
}

// =================================================================================================
//  5. STRUCTS, UNIONS, ENUMS
// =================================================================================================

// A struct is a VALUE type, as in C#: assignment and argument passing copy all its bytes.
// It has no methods, constructors or access control: functions take the struct (or a pointer
// to it) as a parameter. `typedef` gives the type a one-word name.
typedef struct {
    double x, y;
} Vec2;

static Vec2 vec2_add(Vec2 a, Vec2 b) { return (Vec2){a.x + b.x, a.y + b.y}; } // compound literal
static void vec2_scale(Vec2 *v, double factor) { // `v->x` is shorthand for `(*v).x`
    v->x *= factor;
    v->y *= factor;
}
static double vec2_length(const Vec2 *v) { return hypot(v->x, v->y); }

// An enum with a fixed underlying type (C23). C#: enum Color : byte. The enumerators live in
// the global namespace (hence the prefix) and convert to and from int freely.
enum Color : unsigned char { COLOR_RED, COLOR_GREEN = 5, COLOR_BLUE };

typedef struct {
    char name[16]; // an array INSIDE the struct: it is copied together with the struct
    enum Color color;
    Vec2 position;
} Sprite;

// A tagged union: the C spelling of a sum type. All members of a union share one piece of
// memory; the tag says which one is alive. C#: a class hierarchy, or a `union` in C# 15.
typedef enum { SHAPE_CIRCLE, SHAPE_RECT } ShapeKind;

typedef struct {
    ShapeKind kind;
    union { // an anonymous union: its members are reached directly
        struct {
            double radius;
        } circle;
        struct {
            double width, height;
        } rect;
    };
} Shape;

static double shape_area(const Shape *shape) {
    switch (shape->kind) {
        case SHAPE_CIRCLE: return 3.141592653589793 * shape->circle.radius * shape->circle.radius;
        case SHAPE_RECT: return shape->rect.width * shape->rect.height;
    }
    unreachable(); // C23: "control never gets here"; if it does, that is UB
}

// Bit-fields: several small values packed into one machine word.
typedef struct {
    unsigned ready : 1;
    unsigned mode : 3;
    unsigned level : 4;
} Flags;

// Fields are laid out in declaration order with padding for alignment; the order matters.
typedef struct {
    char tag;     // 1 + 7 (padding)
    double value; // 8
    int count;    // 4 + 4 (padding) = 24 bytes
} Padded;

typedef struct {
    double value; // 8
    int count;    // 4
    char tag;     // 1 + 3 (padding) = 16 bytes
} Reordered;

// A flexible array member: a header and a variable-length payload in ONE allocation.
typedef struct {
    size_t length;
    int items[];
} IntBlock;

static void section05_structs(void) {
    header("5. Structs, unions, enums");

    Vec2 a = {1.0, 2.0};           // positional initialization
    Vec2 b = {.y = 4.0, .x = 3.0}; // designated initializers. C#: new Vec2 { X = 3, Y = 4 }
    Vec2 copy = a;                 // a COPY of all the fields
    copy.x = 100;
    Vec2 sum = vec2_add(a, b);
    vec2_scale(&sum, 0.5);
    printf("a.x = %.0f, copy.x = %.0f, sum = (%.1f, %.1f), |b| = %.1f\n", a.x, copy.x, sum.x, sum.y,
           vec2_length(&b));

    Sprite hero = {.name = "hero", .color = COLOR_BLUE, .position = {5, 7}};
    Sprite clone = hero; // the embedded array is copied too
    clone.name[0] = 'z';
    printf("%s %s, color %d, sizeof(enum Color) = %zu\n", hero.name, clone.name, hero.color,
           sizeof(enum Color));
    // There is no `==` for structs: compare field by field (memcmp would see the padding).

    Shape shapes[] = {
        {.kind = SHAPE_CIRCLE, .circle = {.radius = 1.0}},
        {.kind = SHAPE_RECT, .rect = {.width = 2.0, .height = 3.0}},
    };
    for (size_t i = 0; i < sizeof shapes / sizeof shapes[0]; i++)
        printf("area %.2f  ", shape_area(&shapes[i]));
    printf("\n");

    Flags flags = {.ready = 1, .mode = 5, .level = 9};
    flags.mode += 4; // 3 bits: 9 wraps to 1
    printf("flags: ready %u, mode %u, level %u, sizeof %zu\n", flags.ready, flags.mode, flags.level,
           sizeof flags);
    printf("sizeof Padded %zu, Reordered %zu, offsetof(Padded, value) %zu, alignof(double) %zu\n",
           sizeof(Padded), sizeof(Reordered), offsetof(Padded, value), alignof(double));

    IntBlock *block = malloc(sizeof *block + 3 * sizeof block->items[0]);
    if (block != nullptr) {
        block->length = 3;
        for (size_t i = 0; i < block->length; i++) block->items[i] = (int)(10 * (i + 1));
        printf("block: %zu items, last %d\n", block->length, block->items[2]);
        free(block);
    }
}

// =================================================================================================
//  6. DYNAMIC MEMORY
// =================================================================================================
//
//  Three places for data: static storage (globals; the whole run), the stack (locals; until
//  the function returns) and the heap (malloc; until YOU call free). There is no garbage
//  collector. Each heap block needs one owner that frees it exactly once:
//    - never freed              -> a leak;
//    - freed twice              -> UB;
//    - used after free          -> UB (a "dangling pointer");
//    - returning &local_variable -> a dangling pointer as well.

// A growable array. C#: List<int>. Everything List<T> does for you is written out here.
typedef struct {
    int *data;
    size_t size, capacity;
} IntVec;

static bool intvec_push(IntVec *vec, int value) {
    if (vec->size == vec->capacity) {
        size_t new_capacity = vec->capacity != 0 ? vec->capacity * 2 : 4;
        int *grown = realloc(vec->data, new_capacity * sizeof *grown); // may move the block
        if (grown == nullptr) return false; // on failure the old block is still valid
        vec->data = grown;
        vec->capacity = new_capacity;
    }
    vec->data[vec->size++] = value;
    return true;
}

static void intvec_free(IntVec *vec) {
    free(vec->data);
    *vec = (IntVec){}; // leave no dangling pointer behind
}

// A singly linked list: a struct that points to its own type.
typedef struct Node {
    int value;
    struct Node *next;
} Node;

static Node *list_prepend(Node *head, int value) {
    Node *node = malloc(sizeof *node); // `sizeof *node` stays correct if the type changes
    if (node == nullptr) return head;
    *node = (Node){.value = value, .next = head};
    return node;
}

static void list_free(Node *head) {
    while (head != nullptr) {
        Node *next = head->next; // read the link BEFORE freeing the node
        free(head);
        head = next;
    }
}

// The "goto cleanup" idiom: one exit path releases everything acquired so far.
// C#: try/finally or using. C++: destructors.
static bool build_message(bool fail_midway, char *out, size_t out_size) {
    bool ok = false;
    char *first = nullptr, *second = nullptr;

    first = malloc(32);
    if (first == nullptr) goto cleanup;
    strcpy(first, "first block");
    if (fail_midway) goto cleanup;
    second = malloc(32);
    if (second == nullptr) goto cleanup;
    strcpy(second, "second block");
    snprintf(out, out_size, "%s + %s", first, second);
    ok = true;

cleanup:
    free(second); // free(nullptr) does nothing, so no checks are needed
    free(first);
    return ok;
}

static void section06_memory(void) {
    header("6. Dynamic memory");

    int *numbers = malloc(4 * sizeof *numbers); // uninitialized memory; nullptr on failure
    double *zeros = calloc(4, sizeof *zeros);   // zero-filled, with an overflow-checked size
    if (numbers == nullptr || zeros == nullptr) {
        free(numbers);
        free(zeros);
        return;
    }
    for (int i = 0; i < 4; i++) numbers[i] = i * i;
    printf("%d %d %.1f\n", numbers[2], numbers[3], zeros[3]);
    free(numbers);
    free(zeros);
    numbers = nullptr; // a habit that turns a use-after-free into a visible null dereference

    IntVec vec = {};
    for (int i = 1; i <= 10; i++) intvec_push(&vec, i * i);
    printf("vector: size %zu, capacity %zu, last %d\n", vec.size, vec.capacity,
           vec.data[vec.size - 1]);
    intvec_free(&vec);

    Node *list = nullptr;
    for (int i = 1; i <= 4; i++) list = list_prepend(list, i);
    printf("list:");
    for (const Node *node = list; node != nullptr; node = node->next) printf(" %d", node->value);
    printf("\n");
    list_free(list);

    char message[64] = "(nothing)";
    bool failed_run = build_message(true, message, sizeof message);
    printf("failing run: ok=%d, message \"%s\"\n", failed_run, message);
    bool good_run = build_message(false, message, sizeof message);
    printf("good run: ok=%d, message \"%s\"\n", good_run, message);
    // The checkers for all of this are external tools: -fsanitize=address, valgrind.
}

// =================================================================================================
//  7. FUNCTION POINTERS AND CALLBACKS
// =================================================================================================

typedef int (*BinaryOp)(int, int); // C#: delegate int BinaryOp(int a, int b)

static int add(int a, int b) { return a + b; }
static int multiply(int a, int b) { return a * b; }
static int apply(BinaryOp op, int a, int b) { return op(a, b); }

// qsort calls back with pointers to two elements; the result is negative, zero or positive.
static int compare_ints(const void *a, const void *b) {
    int x = *(const int *)a, y = *(const int *)b;
    return (x > y) - (x < y); // `x - y` could overflow
}

typedef struct {
    const char *name;
    int age;
} Person;

static int compare_by_age_desc(const void *a, const void *b) {
    const Person *left = a, *right = b;
    return (right->age > left->age) - (right->age < left->age);
}

// C has no closures: a callback gets its state through an extra `void *context` parameter.
typedef void (*Visitor)(int value, void *context);

static void for_each(const int *values, size_t count, Visitor visit, void *context) {
    for (size_t i = 0; i < count; i++) visit(values[i], context);
}

static void add_to_total(int value, void *context) { *(long *)context += value; }

// Polymorphism by hand. An "interface" is a struct of function pointers (a vtable), and each
// object carries a pointer to its table. This is what a C++ or C# compiler generates for
// virtual methods.
typedef struct Animal Animal;

typedef struct {
    const char *(*sound)(const Animal *self);
    int (*legs)(const Animal *self);
} AnimalVtable;

struct Animal {
    const AnimalVtable *vtable;
    const char *name;
};

static const char *dog_sound(const Animal *self) {
    (void)self; // "unused on purpose"
    return "Woof";
}
static const char *bird_sound(const Animal *self) {
    (void)self;
    return "Tweet";
}
static int four_legs([[maybe_unused]] const Animal *self) { return 4; }
static int two_legs([[maybe_unused]] const Animal *self) { return 2; }

static const AnimalVtable dog_vtable = {.sound = dog_sound, .legs = four_legs};
static const AnimalVtable bird_vtable = {.sound = bird_sound, .legs = two_legs};

static void section07_function_pointers(void) {
    header("7. Function pointers and callbacks");

    BinaryOp op = add; // a function name converts to a pointer to the function
    printf("%d %d %d\n", op(2, 3), apply(multiply, 2, 3), apply(add, 10, 20));

    // A dispatch table: an array of function pointers.
    struct {
        char symbol;
        BinaryOp run;
    } table[] = {{'+', add}, {'*', multiply}};
    for (size_t i = 0; i < sizeof table / sizeof table[0]; i++)
        printf("6 %c 7 = %d  ", table[i].symbol, table[i].run(6, 7));
    printf("\n");

    int values[] = {42, 7, 19, 3, 25};
    size_t count = sizeof values / sizeof values[0];
    qsort(values, count, sizeof values[0], compare_ints);
    int key = 19;
    const int *found = bsearch(&key, values, count, sizeof values[0], compare_ints);
    printf("sorted: %d %d %d %d %d, 19 found at index %td\n", values[0], values[1], values[2],
           values[3], values[4], found != nullptr ? found - values : (ptrdiff_t)-1);

    Person people[] = {{"Ann", 31}, {"Bob", 25}, {"Cid", 47}};
    qsort(people, 3, sizeof people[0], compare_by_age_desc);
    printf("oldest first: %s %s %s\n", people[0].name, people[1].name, people[2].name);

    long total = 0;
    for_each(values, count, add_to_total, &total);
    printf("total through a callback with context: %ld\n", total);

    Animal zoo[] = {{&dog_vtable, "Rex"}, {&bird_vtable, "Tweety"}};
    for (size_t i = 0; i < 2; i++) {
        const Animal *animal = &zoo[i];
        printf("%s says %s on %d legs\n", animal->name, animal->vtable->sound(animal),
               animal->vtable->legs(animal));
    }
}

// =================================================================================================
//  8. THE PREPROCESSOR AND GENERIC CODE
// =================================================================================================
//
//  The preprocessor runs before the compiler and works on text, knowing nothing about types
//  or scopes. C# kept only #if and #define; in C it is also the tool for constants, inline
//  "functions", code generation and generic programming.

#define SQUARE_BAD(x) x * x   // pure text: SQUARE_BAD(1 + 2) becomes 1 + 2 * 1 + 2
#define SQUARE(x) ((x) * (x)) // parenthesize everything; the argument is still evaluated twice
#define ARRAY_LEN(a) (sizeof(a) / sizeof((a)[0]))
#define STRINGIFY(x) #x     // `#` turns an argument into a string literal
#define CONCAT(a, b) a##b   // `##` glues two tokens into one
// A variadic macro; __VA_OPT__(,) emits the comma only when extra arguments are present.
#define LOG(format, ...) printf("[%s] " format "\n", __func__ __VA_OPT__(, ) __VA_ARGS__)
// `do { ... } while (0)` makes a multi-statement macro behave like one statement.
#define SWAP(a, b)                                                                                 \
    do {                                                                                           \
        typeof(a) swap_tmp = (a);                                                                  \
        (a) = (b);                                                                                 \
        (b) = swap_tmp;                                                                            \
    } while (0)

// An X-macro: one list, several expansions, so an enum and its names never drift apart.
#define WEEKDAYS(X) X(MONDAY) X(TUESDAY) X(WEDNESDAY)
#define AS_ENUM(name) name,
#define AS_STRING(name) #name,
enum Weekday { WEEKDAYS(AS_ENUM) WEEKDAY_COUNT };
static const char *const weekday_names[] = {WEEKDAYS(AS_STRING)};

// _Generic selects an expression by the TYPE of its argument: overloading through a macro.
#define TYPE_NAME(x)                                                                               \
    _Generic((x), int: "int", double: "double", char *: "string", const char *: "string",          \
        default: "something else")
#define ABS_OF(x) _Generic((x), int: abs, long: labs, double: fabs, float: fabsf)(x)

// A compile-time assertion. C#: nothing comparable in the language itself.
static_assert(sizeof(int) >= 4, "this tour assumes an int of at least 32 bits");

// "Templates" by macro: one expansion produces a complete, typed stack. C#: Stack<T>.
#define DEFINE_STACK(T, Name)                                                                      \
    typedef struct {                                                                               \
        T items[16];                                                                               \
        size_t count;                                                                              \
    } Name;                                                                                        \
    [[maybe_unused]] static bool Name##_push(Name *stack, T item) {                                \
        if (stack->count == ARRAY_LEN(stack->items)) return false;                                 \
        stack->items[stack->count++] = item;                                                       \
        return true;                                                                               \
    }                                                                                              \
    [[maybe_unused]] static bool Name##_pop(Name *stack, T *out) {                                 \
        if (stack->count == 0) return false;                                                       \
        *out = stack->items[--stack->count];                                                       \
        return true;                                                                               \
    }

DEFINE_STACK(int, IntStack)
DEFINE_STACK(double, DoubleStack)

// The other road to generic code: one implementation over raw bytes, the element size and
// a comparison callback. This is how qsort and bsearch are declared.
static const void *generic_max(const void *base, size_t count, size_t size,
                               int (*compare)(const void *, const void *)) {
    const unsigned char *best = base;
    for (size_t i = 1; i < count; i++) {
        const unsigned char *candidate = (const unsigned char *)base + i * size;
        if (compare(candidate, best) > 0) best = candidate;
    }
    return count > 0 ? best : nullptr;
}

static void section08_preprocessor(void) {
    header("8. The preprocessor and generic code");

    printf("SQUARE_BAD(1 + 2) = %d, SQUARE(1 + 2) = %d\n", SQUARE_BAD(1 + 2), SQUARE(1 + 2));
    int CONCAT(my, Value) = 7; // declares a variable named myValue
    printf("%s = %d, platform %s, line %d of %s\n", STRINGIFY(myValue), myValue, PLATFORM, __LINE__,
           __FILE__);
    LOG("no arguments");
    LOG("%d + %d = %d", 2, 3, 2 + 3);

    double left = 1.5, right = 2.5;
    SWAP(left, right);
    printf("swapped: %.1f %.1f\n", left, right);

    for (int day = MONDAY; day < WEEKDAY_COUNT; day++) printf("%d=%s ", day, weekday_names[day]);
    printf("\n");

    printf("%s %s %s %s | %d %.1f\n", TYPE_NAME(42), TYPE_NAME(4.2), TYPE_NAME("text"),
           TYPE_NAME('c' + 0L), ABS_OF(-5), ABS_OF(-2.5));

    IntStack ints = {};
    DoubleStack doubles = {};
    IntStack_push(&ints, 1);
    IntStack_push(&ints, 2);
    DoubleStack_push(&doubles, 2.5);
    int top = 0;
    IntStack_pop(&ints, &top);
    printf("typed stacks: popped %d, %zu left, doubles %zu\n", top, ints.count, doubles.count);

    int values[] = {4, 9, 2};
    const int *biggest = generic_max(values, ARRAY_LEN(values), sizeof values[0], compare_ints);
    printf("generic_max: %d\n", biggest != nullptr ? *biggest : -1);
}

// =================================================================================================
//  9. ERRORS AND I/O
// =================================================================================================
//
//  There are no exceptions. A function reports failure through its return value (a status
//  code, a null pointer, a negative number) and sometimes through the thread-local variable
//  errno. Nothing forces the caller to look, so checking every call is your discipline.

typedef enum { PARSE_OK, PARSE_EMPTY, PARSE_NOT_A_NUMBER, PARSE_OUT_OF_RANGE } ParseStatus;

static const char *parse_status_text(ParseStatus status) {
    switch (status) {
        case PARSE_OK: return "ok";
        case PARSE_EMPTY: return "empty input";
        case PARSE_NOT_A_NUMBER: return "not a number";
        case PARSE_OUT_OF_RANGE: return "out of range";
    }
    return "unknown";
}

// The Try... pattern of C#: the status is the result, the value goes through a pointer.
[[nodiscard]] static ParseStatus parse_port(const char *text, int *port) {
    if (text == nullptr || *text == '\0') return PARSE_EMPTY;
    char *end;
    errno = 0;
    long value = strtol(text, &end, 10);
    if (*end != '\0') return PARSE_NOT_A_NUMBER;
    if (errno == ERANGE || value < 1 || value > 65535) return PARSE_OUT_OF_RANGE;
    *port = (int)value;
    return PARSE_OK;
}

// setjmp / longjmp: a non-local jump, the nearest thing to `throw`. No cleanup code runs on
// the way, so anything acquired in between leaks. Rarely the right tool.
static jmp_buf recovery_point;

static void innermost(void) { longjmp(recovery_point, 42); }
static void middle(void) { innermost(); }
static void fail_deep_inside(void) { middle(); }

static void section09_errors_and_io(void) {
    header("9. Errors and I/O");

    const char *inputs[] = {"8080", "", "http", "99999"};
    for (size_t i = 0; i < ARRAY_LEN(inputs); i++) {
        int port = 0;
        ParseStatus status = parse_port(inputs[i], &port);
        if (status == PARSE_OK)
            printf("\"%s\" -> port %d\n", inputs[i], port);
        else
            printf("\"%s\" -> error: %s\n", inputs[i], parse_status_text(status));
    }

    // errno and its text. perror("fopen") would print the same message to stderr.
    FILE *missing = fopen("no-such-directory/file.txt", "r");
    if (missing == nullptr) printf("fopen failed: errno %d (%s)\n", errno, strerror(errno));

    // --- Files: FILE* streams. C#: FileStream with a StreamReader / StreamWriter ---
    FILE *file = tmpfile(); // an anonymous temporary file, deleted when it is closed
    if (file == nullptr) {
        printf("tmpfile failed: %s\n", strerror(errno));
    } else {
        fprintf(file, "alpha 1\nbeta 22\ngamma 333\n");
        rewind(file);
        char line[64], word[32];
        int number = 0, total = 0, lines = 0;
        while (fgets(line, sizeof line, file) != nullptr) { // at most size - 1 chars per call
            if (sscanf(line, "%31s %d", word, &number) == 2) { // returns the number of matches
                total += number;
                lines++;
            }
        }
        printf("text: %d lines, total %d, last word \"%s\"\n", lines, total, word);

        // Binary I/O copies the raw bytes of objects: fast, and not portable between machines.
        rewind(file);
        Vec2 out[] = {{1.5, 2.5}, {3.5, 4.5}};
        size_t written = fwrite(out, sizeof out[0], ARRAY_LEN(out), file);
        rewind(file);
        Vec2 in[2] = {};
        size_t read = fread(in, sizeof in[0], ARRAY_LEN(in), file);
        printf("binary: wrote %zu, read %zu, in[1] = (%.1f, %.1f)\n", written, read, in[1].x,
               in[1].y);
        fclose(file); // nothing closes it for you
    }

    // assert: a debug-only check; compiling with -DNDEBUG removes it. C#: Debug.Assert.
    assert(ARRAY_LEN(inputs) == 4);

    // volatile: the variable is changed between setjmp and longjmp and read afterwards.
    volatile int attempts = 0;
    int code = setjmp(recovery_point); // returns 0 now, and 42 when longjmp comes back here
    if (code == 0) {
        attempts = attempts + 1;
        fail_deep_inside();
        printf("never printed\n");
    } else {
        printf("recovered from a longjmp with code %d after %d attempt(s)\n", code, attempts);
    }
}

// =================================================================================================
//  10. BITS, INTEGERS, UNDEFINED BEHAVIOUR
// =================================================================================================

static void print_bits(const char *label, uint8_t value) {
    char text[9];
    for (int bit = 7; bit >= 0; bit--) text[7 - bit] = ((value >> bit) & 1u) != 0 ? '1' : '0';
    text[8] = '\0';
    printf("%s %s", label, text);
}

static void section10_bits(void) {
    header("10. Bits, integers, undefined behaviour");

    // --- Bit manipulation ---
    uint8_t flags = 0b0000'0101;
    flags |= (uint8_t)(1u << 3);  // set bit 3
    flags &= (uint8_t)~(1u << 0); // clear bit 0
    flags ^= (uint8_t)(1u << 7);  // toggle bit 7
    print_bits("flags", flags);
    printf(", bit 2 is %u, low nibble %u\n", (flags >> 2) & 1u, flags & 0x0Fu);

    // --- Endianness: the order of the bytes of an integer in memory ---
    uint32_t word = 0x11223344;
    unsigned char bytes[4];
    memcpy(bytes, &word, sizeof word); // memcpy is the legal way to look at an object's bytes
    printf("first byte in memory: %02X (%s-endian)\n", bytes[0],
           bytes[0] == 0x44 ? "little" : "big");

    // --- Reinterpreting bits ("type punning") ---
    float one = 1.0f;
    uint32_t pattern;
    memcpy(&pattern, &one, sizeof pattern);
    // *(uint32_t *)&one   // breaks the strict aliasing rule: UB
    union {
        float as_float;
        uint32_t as_bits;
    } pun = {.as_float = 1.0f}; // reading the other member is allowed in C (not in C++)
    printf("1.0f = 0x%08" PRIX32 " = 0x%08" PRIX32 "\n", pattern, pun.as_bits);

    // --- Integer promotions: operands narrower than int become int before arithmetic ---
    uint8_t small = 200, other = 100;
    int promoted = small + other;            // 300: computed as int
    uint8_t stored = (uint8_t)(small + other); // 44: cut back to 8 bits
    printf("promoted %d, stored %d, -7 / 2 = %d, -7 %% 2 = %d\n", promoted, stored, -7 / 2, -7 % 2);

    // --- Checked arithmetic. C#: checked { ... } ---
#ifdef HAVE_STDCKDINT
    int checked_sum = 0;
    bool overflowed = ckd_add(&checked_sum, INT_MAX, 1); // true if the result did not fit
    bool fine = ckd_mul(&checked_sum, 1000, 1000);
    printf("ckd_add overflowed: %d, ckd_mul overflowed: %d (result %d)\n", overflowed, fine,
           checked_sum);
#else
    printf("<stdckdint.h> is not available with this compiler\n");
#endif

    // --- Bit utilities. C#: System.Numerics.BitOperations ---
#ifdef HAVE_STDBIT
    printf("count_ones %u, leading_zeros %u, bit_width %u, bit_ceil %u\n",
           (unsigned)stdc_count_ones(0xB0u), (unsigned)stdc_leading_zeros((uint32_t)1),
           (unsigned)stdc_bit_width(1000u), (unsigned)stdc_bit_ceil(100u));
#else
    printf("<stdbit.h> is not available with this C library\n");
#endif

    // --- _BitInt(N): an integer of any exact width ---
#ifdef __BITINT_MAXWIDTH__
    unsigned _BitInt(24) rgb = 0xFFFFFF;
    rgb += 1; // wraps at 24 bits
    printf("24-bit counter after overflow: %u, sizeof %zu\n", (unsigned)rgb, sizeof rgb);
#else
    printf("_BitInt is not available with this compiler\n");
#endif

    // --- Alignment ---
    static alignas(64) char cache_line[64]; // start on a 64-byte boundary
    printf("cache_line aligned to 64: %d, alignof(max_align_t) %zu\n",
           (int)((uintptr_t)cache_line % 64 == 0), alignof(max_align_t));

    // Undefined behaviour: the standard puts NO requirements on a program that
    //   - reads an uninitialized variable, or dereferences a null or dangling pointer;
    //   - indexes outside an array, or uses memory after free(), or frees it twice;
    //   - overflows a signed integer, or shifts by at least the width of the type;
    //   - modifies a string literal or a const object;
    //   - accesses an object through a pointer of an unrelated type (strict aliasing);
    //   - modifies a variable twice in one expression: `i = i++ + 1`.
    // The compiler assumes none of this happens and optimizes on that assumption, so the
    // result is not "a wrong value" but anything at all. The safety net is external:
    // warnings (-Wall -Wextra), sanitizers (-fsanitize=address,undefined), valgrind.
}

// =================================================================================================
//  11. CONCURRENCY
// =================================================================================================
//
//  C11 added threads (<threads.h>) and atomics (<stdatomic.h>) to the standard library; on
//  POSIX systems the older pthreads API is still the common choice. A data race (two threads
//  touching a plain variable, at least one of them writing, with no synchronization) is UB.

#ifdef HAVE_THREADS

typedef struct {
    mtx_t *mutex;
    long *shared;
    atomic_long *atomic_counter;
    int iterations;
} WorkerArgs;

static thread_local int calls_on_this_thread = 0; // one copy per thread. C#: [ThreadStatic]

static int worker(void *raw) { // C#: a ThreadStart delegate; the argument travels as void*
    WorkerArgs *args = raw;
    for (int i = 0; i < args->iterations; i++) {
        mtx_lock(args->mutex); // C#: lock (sync) { ... }, but unlocking is up to you
        ++*args->shared;
        mtx_unlock(args->mutex);
        atomic_fetch_add(args->atomic_counter, 1); // C#: Interlocked.Increment
        calls_on_this_thread++;
    }
    return calls_on_this_thread; // the thread's exit code
}

static once_flag init_flag = ONCE_FLAG_INIT;
static int init_calls = 0;
static void init_once(void) { init_calls++; }

// A one-slot mailbox: a mutex plus a condition variable. C#: Monitor.Wait / Monitor.Pulse.
typedef struct {
    mtx_t mutex;
    cnd_t ready;
    bool has_value;
    int value;
} Mailbox;

static int producer(void *raw) {
    Mailbox *box = raw;
    mtx_lock(&box->mutex);
    box->value = 4242;
    box->has_value = true;
    mtx_unlock(&box->mutex);
    cnd_signal(&box->ready);
    return 0;
}

#endif // HAVE_THREADS

static void section11_concurrency(void) {
    header("11. Concurrency");
#ifdef HAVE_THREADS
    enum { THREADS = 4, ITERATIONS = 25'000 };
    mtx_t mutex;
    if (mtx_init(&mutex, mtx_plain) != thrd_success) return;
    long shared = 0;
    atomic_long atomic_counter = 0;
    WorkerArgs args = {&mutex, &shared, &atomic_counter, ITERATIONS};

    thrd_t threads[THREADS];
    int started = 0;
    for (; started < THREADS; started++)
        if (thrd_create(&threads[started], worker, &args) != thrd_success) break;
    long per_thread_total = 0;
    for (int i = 0; i < started; i++) {
        int result = 0;
        thrd_join(threads[i], &result); // a thread must be joined or detached
        per_thread_total += result;
        call_once(&init_flag, init_once); // runs init_once on the first call only
    }
    printf("%d threads: mutex-protected %ld, atomic %ld, thread-local sum %ld, init calls %d\n",
           started, shared, atomic_load(&atomic_counter), per_thread_total, init_calls);
    mtx_destroy(&mutex);

    Mailbox box = {.has_value = false};
    mtx_init(&box.mutex, mtx_plain);
    cnd_init(&box.ready);
    thrd_t sender;
    if (thrd_create(&sender, producer, &box) == thrd_success) {
        mtx_lock(&box.mutex);
        while (!box.has_value) cnd_wait(&box.ready, &box.mutex); // releases the mutex while waiting
        printf("mailbox delivered %d\n", box.value);
        mtx_unlock(&box.mutex);
        thrd_join(sender, nullptr);
    }
    cnd_destroy(&box.ready);
    mtx_destroy(&box.mutex);
#else
    printf("<threads.h> is not available with this C library; ");
#ifdef HAVE_ATOMICS
    atomic_int counter = 0;
    atomic_fetch_add(&counter, 5);
    printf("atomics alone: %d\n", atomic_load(&counter));
#else
    printf("neither are atomics\n");
#endif
#endif
}

// =================================================================================================
//  12. C23 IN ONE PLACE
// =================================================================================================

[[deprecated("use section12_c23 instead")]] [[maybe_unused]] static void old_api(void) {}

static void section12_c23(void) {
    header("12. C23 in one place");

    // Used above: bool / true / false / nullptr / static_assert / alignas / thread_local as
    // keywords, constexpr objects, auto and typeof, [[attributes]], enums with a fixed
    // underlying type, binary literals and digit separators, `= {}`, __VA_OPT__, #elifdef,
    // __has_include, unreachable(), _BitInt, <stdckdint.h>, <stdbit.h>, strdup.
    constexpr double tau = 6.283185307179586;
    constexpr unsigned char mask = 0b1111'0000;
    nullptr_t null = nullptr; // nullptr has a type of its own
    typeof_unqual(tau) copy = tau; // typeof without the qualifiers: a plain, writable double
    copy += 1;
    printf("%.4f %.4f %d %d\n", tau, copy, mask, null == nullptr);
    // old_api();   // warning: 'old_api' is deprecated: use section12_c23 instead

    // `f()` now means `f(void)`: an empty parameter list no longer says "anything goes", and
    // K&R-style definitions are gone. Labels may stand right before a declaration or a `}`.
    static_assert(sizeof(long long) >= 8); // the message is optional

    // Not shown, because compilers are still catching up:
    //   #embed "logo.png"                         // binary file -> initializer (GCC 15, Clang 19)
    //   printf("%b", 5u);                          // binary output; needs a C23 library
    //   <stdbit.h>, <stdckdint.h> on other libcs   // detected above with __has_include
    // And things C still does not have: generics, namespaces, RAII (`defer` is being
    // discussed for the next standard), a module system, a string type.
    // C23 is 202311L; compilers that are still completing C23 report 202000L.
    printf("__STDC_VERSION__ = %ldL\n", __STDC_VERSION__);
}

// =================================================================================================
//  ENTRY POINT
// =================================================================================================

// argc counts the command-line arguments, argv[0] is the program name. C#: string[] args.
// The return value is the process exit code.
int main(int argc, char *argv[]) {
    printf("C tour: %s, %d extra argument(s)\n", argc > 0 ? "started" : "no argv", argc - 1);
    (void)argv;

    section01_basics();
    section02_functions();
    section03_pointers();
    section04_strings();
    section05_structs();
    section06_memory();
    section07_function_pointers();
    section08_preprocessor();
    section09_errors_and_io();
    section10_bits();
    section11_concurrency();
    section12_c23();
    return EXIT_SUCCESS;
}
