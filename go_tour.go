//go:build go1.24

// =================================================================================================
//  GO FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
//
//  Run:   go run go_tour.go          (Go 1.24 or newer; no go.mod is needed for a single file)
//
//  Verified with Go 1.24.7 — also with `go vet`, `gofmt` and the race detector
//  (`go run -race go_tour.go`). Newer toolchains were not available where this file was
//  checked, so what Go 1.25 - 1.27 added (generic methods, `new(expr)` ...) is described in
//  section 11 as comments that were NOT compiled.
//
//  How to read. Each section is a function `sectionNN...`; the types and functions a section
//  needs are declared right before it; `main()` at the end calls the sections in order.
//  A "C#:" note shows the closest C# counterpart.
//
//  The main differences from C# to keep in mind from the first line:
//
//   1. A deliberately small language. No classes, no inheritance, no exceptions, no
//      overloading, no default arguments, no ternary operator, no attributes, no LINQ.
//   2. Composition instead of inheritance: struct embedding plus interfaces that a type
//      satisfies implicitly, just by having the methods.
//   3. Errors are ordinary return values checked with `if err != nil`; panic is for bugs.
//   4. Concurrency is built in: goroutines and channels instead of Task and async/await.
//      There is no "async" colour: every function may block, and the runtime multiplexes.
//   5. Compiled ahead of time to one static executable with a garbage collector and a small
//      runtime inside; no JIT and no virtual machine.
//   6. Visibility is spelled by case: Capitalized names are exported from the package,
//      lower-case names are private to it.
//   7. Strictness as a feature: an unused variable or import is a compile error, formatting
//      is dictated by gofmt (tabs), and every variable has a well-defined zero value.
//
//  Contents:
//    1. Basics: variables, types, strings, control flow     7. Collections and iteration
//    2. Arrays, slices, maps, structs, pointers             8. Concurrency
//    3. Functions                                           9. Standard library
//    4. Methods and interfaces                             10. Reflection, unsafe, runtime
//    5. Errors                                             11. Tooling and the newest
//    6. Generics
// =================================================================================================

// Every file belongs to a package; `main` with a func main() is an executable.
// C#: a package is a namespace and an assembly-level visibility boundary in one.
package main

// Imports name packages by path. C#: using. An unused import does not compile.
import (
	"bufio"
	"cmp"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"iter"
	"maps"
	"math"
	"os"
	"path/filepath"
	"reflect"
	"regexp"
	"runtime"
	"slices"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
	"unicode/utf8"
	"unsafe"
	"weak"
)

func header(title string) { fmt.Printf("\n=== %s ===\n", title) }

// =================================================================================================
//  1. BASICS: variables, types, strings, control flow
// =================================================================================================

// MaxPoints is an untyped constant: it adapts to the type its context needs. C#: const.
const MaxPoints = 100_000

// Color shows the idiom that replaces enums: a named integer type plus iota constants.
type Color int

const (
	Red Color = iota // iota counts 0, 1, 2 ... within one const block
	Green
	Blue
)

// String makes Color a fmt.Stringer, so printing shows the name. C#: ToString().
func (c Color) String() string { return [...]string{"Red", "Green", "Blue"}[c] }

func section01Basics() {
	header("1. Basics")

	// --- Variables: `var` with a type, or `:=` with inference (inside functions only) ---
	var a int = 42
	var zero int                // no initializer: the zero value (0, "", false, nil)
	b := 3.5                    // float64. C#: var b = 3.5
	big := int64(9_000_000_000) // conversions are always explicit
	var u8 uint8 = 255
	letter := 'A' // a rune: an int32 holding a Unicode code point
	flag := true
	fmt.Println(a, zero, b, big, u8, letter, string(letter), flag)
	fmt.Printf("%T %T %T %T %T\n", a, b, big, letter, "text")

	// --- Conversions and overflow ---
	ratio := float64(a) / 5 // int and float64 never mix implicitly: `a / 5.5` does not compile
	f := 3.99
	truncated := int(f)
	u8++ // integer overflow wraps (and is defined for signed types too, unlike in C)
	maxInt32 := int32(math.MaxInt32)
	maxInt32++
	fmt.Println(ratio, truncated, u8, maxInt32, 7/2, -7/2, -7%2, 7.0/2)

	// --- Strings: immutable byte sequences, by convention UTF-8 (C#: UTF-16) ---
	name := "World"
	greeting := "Hello, " + name + "!"
	// No string interpolation: Sprintf formats. Backquotes make a raw literal (C#: @"...").
	formatted := fmt.Sprintf("%s has %d bytes", greeting, len(greeting))
	raw := `C:\dir\file "quoted"`
	fmt.Println(greeting, "|", formatted, "|", raw, "|", strings.ToUpper(greeting), greeting[7:12])
	accented := "Grüße"
	fmt.Println(len(accented), utf8.RuneCountInString(accented), accented[2], len([]rune(accented)))
	for index, r := range "aß" { // ranging over a string decodes runes; index is a byte offset
		fmt.Printf("%d:%U(%d bytes) ", index, r, utf8.RuneLen(r))
	}
	fmt.Println()

	// --- Control flow: `for` is the only loop, and conditions take no parentheses ---
	sum := 0
	for i := 0; i < 5; i++ { // the classic form
		sum += i
	}
	for sum < 20 { // "while"
		sum += 7
	}
	for i := range 3 { // ranging over an integer: 0, 1, 2
		sum += i
	}
	for index, value := range []int{10, 20, 30} { // C#: foreach, with the index for free
		sum += index * value
	}
	if n := sum % 7; n == 0 { // `if` with an init statement; n lives only in the if/else
		fmt.Println("divisible by 7")
	} else {
		fmt.Println("remainder", n)
	}

	kind := ""
	switch { // a switch without a tag is an if/else chain; cases do NOT fall through
	case letter == 'A' || letter == 'E':
		kind = "vowel"
	case letter >= 'B' && letter <= 'Z':
		kind = "consonant"
	default:
		kind = "something else"
	}
	switch c := Green; c { // a switch may declare a variable; `fallthrough` is explicit
	case Red, Green:
		kind += ", then " + c.String()
	case Blue:
		kind += ", then blue"
	}
outer: // labels work with break and continue
	for row := range 3 {
		for col := range 3 {
			if col > row {
				continue outer
			}
			sum += 100
		}
	}
	fmt.Println(sum, kind, MaxPoints, Blue, Color(0))
}

// =================================================================================================
//  2. ARRAYS, SLICES, MAPS, STRUCTS, POINTERS
// =================================================================================================

// Point is a struct: a value type, as in C#.
type Point struct {
	X, Y float64 // capitalized fields are exported; lower-case ones are package-private
}

func section02CompositeTypes() {
	header("2. Arrays, slices, maps, structs, pointers")

	// --- Arrays are VALUES whose length is part of the type; rarely used directly ---
	primes := [5]int{2, 3, 5, 7, 11}
	copyOfPrimes := primes // copies all five elements
	copyOfPrimes[0] = 99
	fmt.Println(primes[0], copyOfPrimes[0], len(primes), primes == [5]int{2, 3, 5, 7, 11})

	// --- Slices: a (pointer, length, capacity) view of an array. C#: List<T> + Span<T> ---
	numbers := []int{5, 3, 8}
	numbers = append(numbers, 1, 9) // append returns the slice, possibly reallocated
	window := numbers[1:4]          // shares memory with numbers
	window[0] = 33
	fmt.Println(numbers, window, len(window), cap(window))
	grown := append(window, 100)        // there is spare capacity, so this OVERWRITES numbers[4]
	safe := append(numbers[1:4:4], 200) // a full slice expression caps the capacity: append copies
	fmt.Println(numbers, grown, safe)
	made := make([]int, 3, 10) // length 3 (zeros), capacity 10
	var nilSlice []int         // the zero value of a slice is nil, and append accepts it
	nilSlice = append(nilSlice, 1)
	fmt.Println(made, len(made), cap(made), nilSlice, numbers[len(numbers)-1])
	// numbers[10]   // panic: runtime error: index out of range [10] with length 5

	// --- Maps: hash tables. C#: Dictionary<TKey, TValue>. Iteration order is random ---
	ages := map[string]int{"Ann": 30, "Bob": 25}
	ages["Cid"] = 41
	delete(ages, "Bob")
	age, found := ages["Zed"] // a missing key gives the zero value; "comma ok" tells them apart
	fmt.Println(ages["Ann"], age, found, len(ages), slices.Sorted(maps.Keys(ages)))
	counts := map[rune]int{}
	for _, r := range "mississippi" {
		counts[r]++ // the zero value makes counting trivial
	}
	var nilMap map[string]int
	fmt.Println(counts['s'], counts['z'], nilMap["x"], len(nilMap)) // reading a nil map is fine
	// nilMap["x"] = 1   // panic: assignment to entry in nil map

	// --- Structs are values ---
	p := Point{X: 1, Y: 2}
	q := p // a copy
	q.X = 100
	anonymous := struct {
		Name string
		Tags []string
	}{"tour", []string{"go"}}
	fmt.Println(p, q, p == Point{1, 2}, anonymous.Name, fmt.Sprintf("%+v", p))

	// --- Pointers: addresses without arithmetic; the garbage collector tracks them ---
	pointer := &p
	pointer.X = 10          // automatic dereference: the same as (*pointer).X
	created := &Point{3, 4} // the address of a literal: the value moves to the heap if needed
	number := new(int)      // new(T) returns a pointer to a zero T
	*number = 7
	var nothing *Point
	fmt.Println(p.X, *created, *number, nothing == nil)
	// nothing.X   // panic: runtime error: invalid memory address or nil pointer dereference
}

// =================================================================================================
//  3. FUNCTIONS
// =================================================================================================

// divide returns several results; the last one is conventionally an error.
func divide(dividend, divisor int) (quotient, remainder int, err error) { // named results
	if divisor == 0 {
		return 0, 0, errors.New("division by zero")
	}
	return dividend / divisor, dividend % divisor, nil
}

func sum(values ...int) int { // variadic. C#: params int[]
	total := 0
	for _, v := range values {
		total += v
	}
	return total
}

func makeCounter() func() int { // returns a closure over `count`
	count := 0
	return func() int {
		count++
		return count
	}
}

func apply(values []int, transform func(int) int) []int { // functions are first-class values
	result := make([]int, 0, len(values))
	for _, v := range values {
		result = append(result, transform(v))
	}
	return result
}

// safeDivide shows defer and recover. A deferred call runs when the surrounding function
// returns (C#: finally); a deferred closure may even change a named result, and recover()
// stops a panic that is unwinding the stack.
func safeDivide(a, b int) (result int, err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("recovered: %v", r)
		}
	}()
	return a / b, nil // integer division by zero panics
}

func deferOrder() (log []string) {
	for i := range 3 {
		defer func() { log = append(log, fmt.Sprintf("deferred %d", i)) }() // last in, first out
	}
	log = append(log, "body done")
	return log
}

func section03Functions() {
	header("3. Functions")

	q, r, err := divide(17, 5)
	fmt.Println(q, r, err)
	_, _, err = divide(1, 0) // `_` discards a value
	fmt.Println(err)
	fmt.Println(sum(), sum(1, 2, 3), sum([]int{4, 5}...)) // a slice spread into the variadic call

	counter := makeCounter()
	counter()
	counter()
	fmt.Println(counter(), apply([]int{1, 2, 3}, func(x int) int { return x * x }))

	fmt.Println(safeDivide(7, 2))
	fmt.Println(safeDivide(1, 0))
	fmt.Println(deferOrder())

	// Function types, and functions as map values.
	type operation func(float64, float64) float64
	table := map[string]operation{"hypot": math.Hypot, "max": math.Max, "pow": math.Pow}
	for _, name := range slices.Sorted(maps.Keys(table)) {
		fmt.Printf("%s(3, 4) = %v  ", name, table[name](3, 4))
	}
	fmt.Println()
}

// =================================================================================================
//  4. METHODS AND INTERFACES
// =================================================================================================

// Vec has methods: functions with a receiver. Any named type can have them; there are no
// classes.
type Vec struct{ X, Y float64 }

func (v Vec) Length() float64 { return math.Hypot(v.X, v.Y) } // value receiver: gets a copy
func (v *Vec) Scale(k float64) { // pointer receiver: can modify the original
	v.X *= k
	v.Y *= k
}
func (v Vec) String() string { return fmt.Sprintf("(%g, %g)", v.X, v.Y) }

// Shape is an interface: a set of methods. A type satisfies it IMPLICITLY, just by having
// them; there is no `implements`. C#: an interface, but structural.
type Shape interface {
	Area() float64
	Name() string
}

type Circle struct{ Radius float64 }
type Rect struct{ Width, Height float64 }

func (c Circle) Area() float64 { return math.Pi * c.Radius * c.Radius }
func (c Circle) Name() string  { return "circle" }
func (r Rect) Area() float64   { return r.Width * r.Height }
func (r Rect) Name() string    { return "rectangle" }

// Square embeds Rect: composition with automatic forwarding of fields and methods. This
// replaces inheritance; there is no base class, no virtual and no override.
type Square struct {
	Rect  // an embedded field: Square gets Area() and Name() for free
	Label string
}

func (s Square) Name() string { return "square" } // shadows the promoted Rect.Name

func describe(s Shape) string { return fmt.Sprintf("%s with area %.2f", s.Name(), s.Area()) }

type Logger struct{ prefix string }

func (l *Logger) Log(message string) string { return l.prefix + message }

type Service struct {
	*Logger // a pointer can be embedded as well
	Name    string
}

func section04MethodsAndInterfaces() {
	header("4. Methods and interfaces")

	v := Vec{3, 4}
	v.Scale(2) // the compiler takes the address for you: (&v).Scale(2)
	fmt.Println(v, v.Length())

	shapes := []Shape{Circle{1}, Rect{2, 3}, Square{Rect{2, 2}, "sq"}}
	for _, s := range shapes {
		fmt.Print(describe(s), "; ")
	}
	fmt.Println()
	sq := Square{Rect{2, 2}, "sq"}
	service := Service{&Logger{"[svc] "}, "api"}
	fmt.Println(sq.Width, sq.Rect.Name(), sq.Name(), service.Log("started"))

	// A type assertion extracts the concrete value. C#: `shape is Circle c`.
	var shape Shape = Circle{2}
	if circle, ok := shape.(Circle); ok {
		fmt.Println("a circle with radius", circle.Radius)
	}
	_, isRect := shape.(Rect)
	fmt.Println(isRect)

	// `any` (an alias of interface{}) holds a value of any type. C#: object.
	// A type switch branches on the dynamic type. C#: switch with type patterns.
	for _, value := range []any{42, "text", 3.5, []int{1}, nil, Circle{1}, Red} {
		switch x := value.(type) {
		case nil:
			fmt.Print("nil; ")
		case int:
			fmt.Print("int ", x+1, "; ")
		case string:
			fmt.Print("string of length ", len(x), "; ")
		case fmt.Stringer: // an interface case: anything that has String()
			fmt.Print("Stringer ", x.String(), "; ")
		case Shape:
			fmt.Print("shape ", x.Name(), "; ")
		default:
			fmt.Printf("other %T; ", x)
		}
	}
	fmt.Println()

	// Small interfaces compose well: io.Reader, io.Writer, fmt.Stringer, error.
	var stringer fmt.Stringer = v // Vec has String(), hence it is a Stringer
	fmt.Println(stringer)
	// var s Shape = v   // compile error: Vec does not implement Shape (missing method Area)
}

// =================================================================================================
//  5. ERRORS
// =================================================================================================

// ErrNotFound is a sentinel error: a package-level value that callers compare with errors.Is.
// Errors are ordinary values of the interface type `error`; there are no exceptions.
var ErrNotFound = errors.New("not found")

// ConfigError is an error type that carries data; errors.As extracts it.
type ConfigError struct {
	Key string
	Err error
}

func (e *ConfigError) Error() string { return fmt.Sprintf("config key %q: %v", e.Key, e.Err) }
func (e *ConfigError) Unwrap() error { return e.Err } // lets errors.Is / errors.As look inside

func parsePort(text string) (int, error) {
	port, err := strconv.Atoi(text)
	if err != nil {
		return 0, &ConfigError{Key: "port", Err: err}
	}
	if port < 1 || port > 65535 {
		return 0, &ConfigError{Key: "port", Err: fmt.Errorf("%d is out of range", port)}
	}
	return port, nil
}

func findUser(id int) (string, error) {
	users := map[int]string{1: "ann"}
	name, ok := users[id]
	if !ok {
		return "", fmt.Errorf("user %d: %w", id, ErrNotFound) // %w wraps: context + the cause
	}
	return name, nil
}

func lookupBroken() error {
	var e *ConfigError // a nil pointer...
	return e           // ...inside a NON-nil interface value: the classic trap
}

func section05Errors() {
	header("5. Errors")

	for _, text := range []string{"8080", "http", "99999"} {
		port, err := parsePort(text)
		if err != nil { // the ubiquitous check; nothing in the language forces it
			var configError *ConfigError
			if errors.As(err, &configError) { // C#: catch (ConfigException e)
				fmt.Printf("%v [key %s, cause %T]\n", err, configError.Key, configError.Err)
			}
			continue
		}
		fmt.Println("port", port)
	}

	_, err := findUser(7)
	fmt.Println(err, "|", errors.Is(err, ErrNotFound), err == ErrNotFound)
	joined := errors.Join(errors.New("first"), errors.New("second")) // several errors as one
	fmt.Println(strings.ReplaceAll(joined.Error(), "\n", " + "), "|", lookupBroken() == nil)

	// panic is for bugs and impossible states (index out of range, nil dereference), not
	// for expected failures. recover() works only inside a deferred function.
	func() {
		defer func() { fmt.Println("recovered:", recover()) }()
		var values []int
		_ = values[3]
	}()
}

// =================================================================================================
//  6. GENERICS
// =================================================================================================

// MaxOf has a type parameter with a constraint; cmp.Ordered is "anything that supports <".
// C#: T Max<T>(params T[] values) where T : IComparable<T>.
func MaxOf[T cmp.Ordered](values ...T) T {
	best := values[0]
	for _, v := range values[1:] {
		if v > best {
			best = v
		}
	}
	return best
}

// Number is a constraint: an interface listing types. `~int` means "any type whose
// underlying type is int".
type Number interface {
	~int | ~int64 | ~float64
}

func SumOf[T Number](values []T) T {
	var total T // the zero value of T
	for _, v := range values {
		total += v
	}
	return total
}

func Map[T, U any](values []T, transform func(T) U) []U {
	result := make([]U, 0, len(values))
	for _, v := range values {
		result = append(result, transform(v))
	}
	return result
}

// Stack is a generic type. C#: class Stack<T>.
type Stack[T any] struct{ items []T }

func (s *Stack[T]) Push(item T) { s.items = append(s.items, item) }

func (s *Stack[T]) Pop() (T, bool) {
	var zero T
	if len(s.items) == 0 {
		return zero, false
	}
	last := s.items[len(s.items)-1]
	s.items = s.items[:len(s.items)-1]
	return last, true
}

// All returns an iterator over the items, top first (see section 7).
func (s *Stack[T]) All() iter.Seq[T] {
	return func(yield func(T) bool) {
		for i := len(s.items) - 1; i >= 0; i-- {
			if !yield(s.items[i]) {
				return
			}
		}
	}
}

type Pair[K comparable, V any] struct {
	Key   K
	Value V
}

type StringPair[V any] = Pair[string, V] // a generic type alias (Go 1.24)

type Celsius float64 // a distinct type with float64 underneath

func section06Generics() {
	header("6. Generics")

	// Type arguments are inferred; they are written out when inference is not enough.
	fmt.Println(MaxOf(3, 9, 4), MaxOf("pear", "fig"), MaxOf(2.5, 1.5), MaxOf[float64](1, 2.5))
	texts := Map([]int{1, 2, 3}, strconv.Itoa) // []string
	fmt.Println(SumOf([]int{1, 2, 3}), SumOf([]Celsius{20.5, 1.5}), texts, len(texts[0]))

	stack := &Stack[string]{}
	stack.Push("a")
	stack.Push("b")
	stack.Push("c")
	top, _ := stack.Pop()
	fmt.Println(top, slices.Collect(stack.All()), StringPair[int]{"answer", 42})
	// Limits compared with C#: no specialization, no operators in constraints beyond the
	// built-in ones and, before Go 1.27, no type parameters on methods (section 11).
}

// =================================================================================================
//  7. COLLECTIONS AND ITERATION
// =================================================================================================

type Employee struct {
	Name       string
	Department string
	Salary     float64
	Age        int
}

// Fibonacci is an infinite iterator: a function that calls `yield` for each element and
// stops when yield returns false. C#: an iterator method with yield return.
func Fibonacci() iter.Seq[int] {
	return func(yield func(int) bool) {
		a, b := 0, 1
		for {
			if !yield(a) {
				return
			}
			a, b = b, a+b
		}
	}
}

// Filter and Take show how LINQ-style operators are written over iterators; the standard
// library deliberately ships only a handful of them.
func Filter[T any](seq iter.Seq[T], keep func(T) bool) iter.Seq[T] {
	return func(yield func(T) bool) {
		for v := range seq {
			if keep(v) && !yield(v) {
				return
			}
		}
	}
}

func Take[T any](seq iter.Seq[T], n int) iter.Seq[T] {
	return func(yield func(T) bool) {
		if n <= 0 {
			return
		}
		taken := 0
		for v := range seq {
			if !yield(v) {
				return
			}
			if taken++; taken == n {
				return
			}
		}
	}
}

func section07Collections() {
	header("7. Collections and iteration")

	// The slices package: generic helpers. C#: Array / List<T> / LINQ methods.
	numbers := []int{5, 3, 8, 1, 9, 3}
	sorted := slices.Sorted(slices.Values(numbers)) // a sorted copy
	index, found := slices.BinarySearch(sorted, 8)
	reversed := slices.Clone(sorted)
	slices.Reverse(reversed) // in place
	fmt.Println(sorted, index, found, slices.Contains(numbers, 4), slices.Index(numbers, 8),
		slices.Max(numbers), slices.Compact(slices.Clone(sorted)), reversed)
	fmt.Println(min(3, 1, 2), max(2.5, 1)) // min and max are built in

	// There is no LINQ: filtering and grouping are loops; sorting takes a comparison function.
	staff := []Employee{
		{"Ann", "R&D", 5200, 34}, {"Bob", "Sales", 4100, 45}, {"Cid", "R&D", 6100, 29},
		{"Dee", "Sales", 3900, 38}, {"Eve", "Ops", 4700, 51},
	}
	slices.SortFunc(staff, func(a, b Employee) int { // by department, then by salary descending
		return cmp.Or(cmp.Compare(a.Department, b.Department), cmp.Compare(b.Salary, a.Salary))
	})
	byDepartment := map[string][]string{}
	total := 0.0
	for _, e := range staff {
		byDepartment[e.Department] = append(byDepartment[e.Department], e.Name)
		total += e.Salary
	}
	seniors := slices.DeleteFunc(slices.Clone(staff), func(e Employee) bool { return e.Age <= 35 })
	oldest := slices.MaxFunc(staff, func(a, b Employee) int { return cmp.Compare(a.Age, b.Age) })
	fmt.Println(byDepartment["R&D"], byDepartment["Sales"], total, len(seniors), oldest.Name,
		slices.Sorted(maps.Keys(byDepartment)))

	// Iterators: `for range` over a function (Go 1.23).
	isEven := func(n int) bool { return n%2 == 0 }
	fmt.Println(slices.Collect(Take(Fibonacci(), 10)),
		slices.Collect(Take(Filter(Fibonacci(), isEven), 5)))
	for i, word := range strings.Fields("the quick brown fox") { // index and value
		fmt.Print(i, ":", word, " ")
	}
	for part := range strings.SplitSeq("a,b,c", ",") { // lazily, without building a slice
		fmt.Print(part, " ")
	}
	fmt.Println()

	// strings.Builder: efficient concatenation. C#: StringBuilder.
	var builder strings.Builder
	for i := range 5 {
		fmt.Fprintf(&builder, "%d,", i)
	}
	fmt.Println(strings.TrimSuffix(builder.String(), ","), strings.Repeat("ab", 3),
		strings.Split("a-b-c", "-"), strings.Contains("detour", "tour"),
		strings.Join([]string{"x", "y"}, "+"))
}

// =================================================================================================
//  8. CONCURRENCY
// =================================================================================================

func worker(jobs <-chan int, results chan<- int, wg *sync.WaitGroup) { // directional channels
	defer wg.Done()
	for job := range jobs { // receives until the channel is closed
		results <- job * job
	}
}

// generate is a pipeline stage that owns its output channel and stops when ctx is cancelled.
func generate(ctx context.Context, limit int) <-chan int {
	out := make(chan int)
	go func() {
		defer close(out)
		for i := 1; i <= limit; i++ {
			select {
			case out <- i:
			case <-ctx.Done():
				return
			}
		}
	}()
	return out
}

func section08Concurrency() {
	header("8. Concurrency")

	// --- Goroutines: lightweight threads scheduled by the runtime; `go f()` starts one.
	// Code is written in plain blocking style: there is no async/await. ---
	var wg sync.WaitGroup // C#: CountdownEvent, or Task.WhenAll
	var mu sync.Mutex
	var atomicCounter atomic.Int64
	shared := 0
	for range 4 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for range 10_000 {
				mu.Lock() // C#: lock (sync) { ... }
				shared++
				mu.Unlock()
				atomicCounter.Add(1) // C#: Interlocked.Increment
			}
		}()
	}
	wg.Wait()
	fmt.Println(shared, atomicCounter.Load())

	// --- Channels: typed pipes between goroutines. "Do not communicate by sharing memory;
	// share memory by communicating." C#: System.Threading.Channels ---
	messages := make(chan string) // unbuffered: a send blocks until somebody receives
	go func() { messages <- "ping" }()
	fmt.Println(<-messages)

	jobs := make(chan int, 8) // buffered: a send blocks only when the buffer is full
	results := make(chan int, 8)
	var workers sync.WaitGroup
	for range 3 {
		workers.Add(1)
		go worker(jobs, results, &workers)
	}
	for job := 1; job <= 6; job++ {
		jobs <- job
	}
	close(jobs) // closing tells the receivers that nothing more will come
	workers.Wait()
	close(results)
	var squares []int
	for square := range results {
		squares = append(squares, square)
	}
	slices.Sort(squares) // the completion order is not deterministic
	fmt.Println(squares)

	// --- select waits on several channel operations at once ---
	fast, slow := make(chan string, 1), make(chan string, 1)
	go func() { time.Sleep(5 * time.Millisecond); fast <- "fast" }()
	go func() { time.Sleep(200 * time.Millisecond); slow <- "slow" }()
	select {
	case message := <-fast:
		fmt.Println("received", message)
	case message := <-slow:
		fmt.Println("received", message)
	case <-time.After(time.Second):
		fmt.Println("timeout")
	}

	// --- context: cancellation and deadlines handed down the call chain.
	// C#: CancellationToken ---
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel() // the idiom: always release a context, even if it is cancelled earlier
	received := 0
	for value := range generate(ctx, 1_000_000) {
		received += value
		if value == 5 {
			cancel() // the generator sees ctx.Done() and stops
			break
		}
	}
	timeoutCtx, cancelTimeout := context.WithTimeout(context.Background(), 10*time.Millisecond)
	defer cancelTimeout()
	<-timeoutCtx.Done()
	fmt.Println(received, ctx.Err(), "|", timeoutCtx.Err())

	// --- Run-once initialization, and results gathered from goroutines ---
	loadConfig := sync.OnceValue(func() string { return "config loaded" }) // C#: Lazy<T>

	answers := make([]string, 3) // one slot per goroutine, so no lock is needed
	var group sync.WaitGroup
	for i := range answers {
		group.Add(1)
		go func() {
			defer group.Done()
			answers[i] = fmt.Sprintf("%s for goroutine %d", loadConfig(), i)
		}()
	}
	group.Wait()
	fmt.Println(answers[2], runtime.NumCPU() > 0)
	// A data race (unsynchronized access from two goroutines) is a bug the compiler does
	// not catch; the race detector finds it at run time: `go run -race go_tour.go`.
}

// =================================================================================================
//  9. STANDARD LIBRARY
// =================================================================================================

// Document shows struct tags: string metadata on fields, read through reflection.
// C#: attributes such as [JsonPropertyName("name")].
type Document struct {
	Name    string   `json:"name"`
	Tags    []string `json:"tags"`
	Stars   float64  `json:"stars,omitempty"`
	Draft   bool     `json:"draft"`
	private int      // unexported fields are invisible to encoding/json
}

func section09StandardLibrary() {
	header("9. Standard library")

	// fmt verbs: %v default, %+v with field names, %#v Go syntax, %T type, %q quoted.
	p := Point{1.5, 2}
	fmt.Printf("%v | %+v | %#v | %T | %q | %x | %08.3f | %-5d| %5.1f%%\n",
		p, p, p, p, "hi", 255, math.Pi, 42, 25.6)

	// strconv: explicit conversions between strings and numbers.
	number, err := strconv.Atoi("42x")
	parsed, _ := strconv.ParseFloat("2.5e3", 64)
	fmt.Println(number, err, parsed, strconv.Itoa(2026)+"!", strconv.Quote("a\tb"),
		strconv.FormatInt(255, 2))

	// encoding/json maps structs through their tags.
	doc := Document{Name: "tour", Tags: []string{"go", "c#"}, private: 1}
	encoded, _ := json.Marshal(doc)
	var decoded Document
	err = json.Unmarshal([]byte(`{"name":"back","tags":["x"],"stars":4.5,"unknown":1}`), &decoded)
	var loose map[string]any // JSON of unknown shape
	_ = json.Unmarshal(encoded, &loose)
	fmt.Println(string(encoded), decoded.Name, decoded.Stars, err, loose["tags"], doc.private)

	// time: instants and durations. C#: DateTime, TimeSpan. A layout is written as the
	// reference time "Mon Jan 2 15:04:05 2006".
	start := time.Date(2026, time.November, 17, 9, 30, 0, 0, time.UTC)
	later := start.Add(45*24*time.Hour + 3*time.Hour)
	fmt.Println(later.Format("2006-01-02 15:04"), later.Weekday(), later.Sub(start),
		later.After(start), 90*time.Minute)

	// regexp uses RE2 syntax: no backtracking, hence no lookarounds or backreferences.
	log := "2026-11-17 ERROR disk full; 2026-11-18 WARN retry; 2026-11-19 ERROR timeout"
	pattern := regexp.MustCompile(`(?P<date>\d{4}-\d{2}-\d{2}) (?P<level>[A-Z]+) (?P<text>[^;]+)`)
	var errorDates []string
	for _, match := range pattern.FindAllStringSubmatch(log, -1) {
		if match[pattern.SubexpIndex("level")] == "ERROR" {
			errorDates = append(errorDates, match[pattern.SubexpIndex("date")])
		}
	}
	fmt.Println(errorDates, pattern.ReplaceAllString(log, "${level}@${date}")[:16],
		regexp.MustCompile(`\d+`).FindAllString("a1b22c333", -1))

	// Files: os, bufio, io. Every call returns an error; `defer` closes and cleans up.
	folder, err := os.MkdirTemp("", "go-tour-")
	if err != nil {
		fmt.Println("no temporary directory:", err)
		return
	}
	defer os.RemoveAll(folder)
	path := filepath.Join(folder, "notes.txt")
	if err := os.WriteFile(path, []byte("first\nsecond\n"), 0o644); err != nil {
		fmt.Println(err)
		return
	}
	if file, err := os.OpenFile(path, os.O_APPEND|os.O_WRONLY, 0o644); err == nil {
		fmt.Fprintln(file, "third")
		file.Close()
	}
	reader, err := os.Open(path)
	if err != nil {
		fmt.Println(err)
		return
	}
	defer reader.Close()
	var lines []string
	scanner := bufio.NewScanner(reader) // reads an io.Reader line by line
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}
	_, missing := os.ReadFile(filepath.Join(folder, "missing.txt"))
	fmt.Println(filepath.Base(path), lines, errors.Is(missing, os.ErrNotExist))
}

// =================================================================================================
//  10. REFLECTION, UNSAFE, RUNTIME
// =================================================================================================

func section10ReflectionAndUnsafe() {
	header("10. Reflection, unsafe, runtime")

	// reflect inspects types and values at run time. C#: System.Reflection.
	doc := Document{Name: "tour", Tags: []string{"go"}, Stars: 4.5}
	t := reflect.TypeOf(doc)
	fmt.Println(t.Name(), t.Kind(), t.NumField())
	for i := range t.NumField() {
		field := t.Field(i)
		fmt.Printf("  %-8s %-9s json=%q exported=%v\n", field.Name, field.Type,
			field.Tag.Get("json"), field.IsExported())
	}
	value := reflect.ValueOf(&doc).Elem() // a value is settable only through a pointer
	value.FieldByName("Name").SetString("changed by reflection")
	method, hasMethod := reflect.TypeOf(Vec{}).MethodByName("Length")
	fmt.Println(doc.Name, "|", hasMethod, method.Type, reflect.DeepEqual([]int{1, 2}, []int{1, 2}))

	// unsafe steps outside the type system. C#: unsafe code, Unsafe.As, Marshal.SizeOf.
	type padded struct {
		tag   byte    // 1 + 7 bytes of padding
		value float64 // 8
		count int32   // 4 + 4 bytes of padding = 24
	}
	type reordered struct {
		value float64 // 8
		count int32   // 4
		tag   byte    // 1 + 3 bytes of padding = 16
	}
	bits := math.Float32bits(1.0) // the safe way to reinterpret the bits of a float
	one := float32(1.0)
	sameBits := *(*uint32)(unsafe.Pointer(&one)) // the unsafe way: a pointer cast
	fmt.Printf("%d %d %d %#x %#x\n", unsafe.Sizeof(padded{}), unsafe.Sizeof(reordered{}),
		unsafe.Offsetof(padded{}.value), bits, sameBits)

	// The runtime: a concurrent garbage collector, goroutine scheduler, weak pointers.
	strong := &Point{1, 2}
	weakPointer := weak.Make(strong) // C#: WeakReference<T>
	fmt.Println(weakPointer.Value() == strong, runtime.NumGoroutine() >= 1, runtime.GOOS != "")
	runtime.KeepAlive(strong)
	// cgo (`import "C"`) calls C code, at the price of a C toolchain and slower calls.
}

// =================================================================================================
//  11. TOOLING AND THE NEWEST
// =================================================================================================

func section11Newest() {
	header("11. Tooling and the newest")

	// The tools are part of the language culture:
	//   gofmt      one canonical formatting, so nobody argues about style
	//   go vet     static checks for suspicious code
	//   go test    tests live next to the code in *_test.go files:
	//                  func TestSum(t *testing.T) { if sum(1, 2) != 3 { t.Fatal("wrong") } }
	//   go mod     modules and dependencies (go.mod); a module is a tree of packages
	//   go build   one statically linked executable; GOOS=windows go build cross-compiles
	//
	// Recent language changes used above: min / max / clear and the slices and maps
	// packages (1.21), range over integers and a fresh loop variable per iteration (1.22),
	// range-over-func iterators (1.23), generic type aliases and weak pointers (1.24).
	values := map[string]int{"a": 1, "b": 2}
	clear(values) // empties a map (or zeroes a slice)
	var funcs []func() int
	for i := range 3 {
		funcs = append(funcs, func() int { return i }) // each closure sees its own i
	}
	fmt.Println(len(values), funcs[0](), funcs[1](), funcs[2](), runtime.Version())

	// Newer than the toolchain this file was verified with — NOT compiled here:
	//
	//   Go 1.25   var wg sync.WaitGroup
	//             wg.Go(func() { work() })               // Add(1) + go + Done() in one call
	//   Go 1.26   age := new(42)                         // new(expr): a *int pointing to 42
	//             type Adder[A Adder[A]] interface { Add(A) A }   // self-referential constraint
	//   Go 1.27   func (s *Stack[T]) MapTo[U any](f func(T) U) *Stack[U] { ... }
	//                                                    // generic methods: a method with its
	//                                                    // own type parameters
	//             also in 1.27: encoding/json/v2 and a uuid package in the standard library
}

// =================================================================================================
//  ENTRY POINT
// =================================================================================================

func main() {
	section01Basics()
	section02CompositeTypes()
	section03Functions()
	section04MethodsAndInterfaces()
	section05Errors()
	section06Generics()
	section07Collections()
	section08Concurrency()
	section09StandardLibrary()
	section10ReflectionAndUnsafe()
	section11Newest()
}
