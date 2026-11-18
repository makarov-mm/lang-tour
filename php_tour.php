<?php

// =================================================================================================
//  PHP FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
//
//  Run:   php php_tour.php          (PHP 8.3 or newer, command line)
//
//  Verified with PHP 8.3.6 with every error level reported (E_ALL). Newer interpreters were
//  not available where this file was checked, so the additions of PHP 8.4 - 8.6 (property
//  hooks, the pipe operator ...) are shown in section 10 as comments that were NOT run.
//
//  How to read. Each section is a function `sectionNN...`; the classes and functions a
//  section needs are declared right before it; `main()` at the end calls the sections in
//  order. A "C#:" note shows the closest C# counterpart. Commented-out lines show the error
//  they would raise.
//
//  The main differences from C# to keep in mind from the first line:
//
//   1. Dynamic typing with optional type declarations. Declared parameter, return and
//      property types ARE enforced, but at run time; there is no compile step.
//   2. Arrays are values, objects are handles. The array (an ordered hash map that serves
//      as list, dictionary and tuple) is copied on assignment; an object is shared.
//   3. No generics. Collections are untyped arrays, documented with `@var list<Foo>` for
//      static analysers (PHPStan, Psalm), which play the role of the C# compiler.
//   4. "Shared nothing": in the classic web model every request starts the script from
//      scratch and discards all state at the end. No application-wide memory, no threads.
//   5. A huge global function library with inconsistent names (strlen, str_replace,
//      array_map ...) next to a modern class system.
//   6. Legacy still shows: `==` converts types (use `===`), `.` concatenates strings,
//      variables start with `$`, and old failures are warnings rather than exceptions.
//
//  Contents:
//    1. Basics: variables, strings, comparison, control flow    6. Iterators and generators
//    2. Arrays                                                   7. Strings, regex, JSON, dates, files
//    3. Functions and closures                                   8. Reflection, attributes, namespaces
//    4. Classes, interfaces, traits, enums                       9. The execution model and fibers
//    5. Types and errors                                        10. The newest
// =================================================================================================

// Must be the first statement: scalar arguments are no longer converted silently
// (`strlen(42)` becomes a TypeError instead of quietly meaning strlen("42")).
declare(strict_types=1);

// A namespace groups classes, functions and constants. C#: namespace. A file may hold
// several; this small one is used in section 8.
namespace Tour\Geometry;

const TAU = 2 * M_PI;

function circleArea(float $radius): float
{
    return M_PI * $radius ** 2;
}

namespace Tour;

// `use` imports names into the file. C#: using. Classes need it (or a leading backslash);
// built-in FUNCTIONS such as strlen() are found without it.
use ArrayAccess;
use ArrayIterator;
use Attribute;
use Closure;
use Countable;
use DateInterval;
use DateTimeImmutable;
use DateTimeZone;
use ErrorException;
use Fiber;
use Generator;
use InvalidArgumentException;
use Iterator;
use IteratorAggregate;
use JsonSerializable;
use Override;
use ReflectionClass;
use ReflectionParameter;
use RuntimeException;
use SplFixedArray;
use SplObjectStorage;
use SplPriorityQueue;
use SplStack;
use stdClass;
use Stringable;
use Throwable;
use Traversable;
use TypeError;
use ValueError;
use WeakMap;

use function Tour\Geometry\circleArea;

use const Tour\Geometry\TAU;

function title(string $text): void
{
    echo "\n=== $text ===\n";
}

/** Prints the values on one line: strings as they are, everything else as JSON. */
function show(mixed ...$values): void
{
    $flags = JSON_UNESCAPED_SLASHES | JSON_PRESERVE_ZERO_FRACTION;
    $parts = array_map(fn(mixed $v): string => is_string($v) ? $v : json_encode($v, $flags), $values);
    echo implode(' ', $parts), "\n";
}

// =================================================================================================
//  1. BASICS: variables, strings, comparison, control flow
// =================================================================================================

const MAX_POINTS = 100_000; // a compile-time constant. C#: const

function section01Basics(): void
{
    title('1. Basics');

    // --- Variables start with `$`, need no declaration and have no fixed type ---
    $a = 42;                // int (64-bit)
    $b = 3.5;               // float (a double)
    $text = 'World';
    $flag = true;
    $nothing = null;
    $a = 'now a string';    // the type belongs to the value, not to the variable
    show(gettype($a), gettype($b), gettype($flag), gettype($nothing), get_debug_type([1]), PHP_INT_MAX);

    // --- Numbers ---
    // `/` gives an int when the division is exact and a float otherwise; an int that
    // overflows turns into a float.
    show(7 / 2, 10 / 5, intdiv(7, 2), 7 % 3, -7 % 3, 2 ** 10, 0.1 + 0.2 === 0.3, PHP_INT_MAX + 1, 0x1F, 0b1010);

    // --- Strings: byte sequences without an encoding. `.` concatenates ---
    $greeting = "Hello, $text!";   // double quotes interpolate variables. C#: $"Hello, {text}!"
    $literal = 'Hello, $text!\n';  // single quotes: no interpolation, no escapes
    $user = ['name' => 'Ann', 'tags' => ['a', 'b']];
    $complex = "{$user['name']} has tag {$user['tags'][1]} and " . strlen($greeting) . ' bytes';
    show($greeting, '|', $literal, '|', $complex);
    show(strtoupper($greeting), substr($greeting, 7, 5), $greeting[0], $greeting[-1], str_repeat('ab', 3));
    $heredoc = <<<TEXT
        A heredoc interpolates: $text.
        The indentation of the closing marker is removed.
        TEXT;
    $nowdoc = <<<'TEXT'
        A nowdoc is the single-quoted form: $text stays as it is.
        TEXT;
    show(str_replace("\n", ' / ', $heredoc), '|', $nowdoc);
    $accented = 'Grüße'; // strlen counts bytes; the mb_* functions understand UTF-8
    show(strlen($accented), mb_strlen($accented), mb_strtoupper('strasse'));

    // --- Comparison: `==` converts types first ("loose"), `===` never does. Use `===` ---
    show([1 == '1', 1 === '1', '10' == '1e1', 0 == 'a', null == false, [] == false, '' == null]);
    show(1 <=> 2, 'b' <=> 'a', [1, 2] <=> [1, 3]); // the "spaceship": -1, 0 or 1. C#: CompareTo
    // Falsy values: false, 0, 0.0, '', '0', [] and null. Everything else is truthy.
    show(array_map(fn(mixed $v): bool => (bool) $v, [0, '', '0', [], null, 'false', [0], '0.0']));
    // Arithmetic converts numeric strings even under strict_types.
    show(1 + '1', '5' * '4', '1.5' + 1, 10 . '');
    // `??` is null-coalescing and also covers missing array keys; `?:` is the short ternary;
    // `?->` is the null-safe member access. C#: ??, ?: with a repeated operand, ?.
    $config = ['port' => 0];
    show($config['host'] ?? 'localhost', $config['port'] ?: 8080, $config['port'] ?? 8080, $nothing?->name);

    // --- Control flow ---
    $sum = 0;
    for ($i = 0; $i < 5; $i++) {
        $sum += $i;
    }
    foreach ([10, 20, 30] as $index => $value) { // C#: foreach, with the key for free
        $sum += $index * $value;
    }
    $n = 3;
    while ($n-- > 0) {
        $sum += 10;
    }
    // match: an expression with strict comparison and no fall-through; it must cover the value.
    $kind = match (true) {
        $sum % 15 === 0 => 'fizzbuzz',
        $sum % 3 === 0, $sum % 5 === 0 => 'fizz or buzz',
        default => 'plain',
    };
    $size = match ($sum <=> 100) {
        -1 => 'small',
        0 => 'exact',
        1 => 'large',
    };
    // `switch` still exists, with loose comparison and fall-through, as in C.
    show($sum, $kind, $size, $sum % 2 === 0 ? 'even' : 'odd', MAX_POINTS);
}

// =================================================================================================
//  2. ARRAYS
// =================================================================================================

function section02Arrays(): void
{
    title('2. Arrays');

    // ONE structure serves as list, dictionary, tuple, stack and queue: an ordered hash map.
    $list = [5, 3, 8];                 // keys 0, 1, 2. C#: List<int>
    $list[] = 1;                       // append
    array_unshift($list, 9);           // prepend; the integer keys are renumbered
    $map = ['bolt' => 10, 'nut' => 5]; // C#: Dictionary<string, int>, in insertion order
    $map['screw'] = 25;
    unset($map['nut']);
    $mixed = [1 => 'a', 'key' => 'b', 'c']; // keys may be mixed; the next automatic key is 2
    show($list, $map, $mixed, count($list), $list[0], $map['bolt']);
    show(isset($map['nut']), array_key_exists('bolt', $map), array_is_list($list), array_is_list($map));
    // $map['missing']      // Warning: Undefined array key "missing" — and the value is null

    // Arrays are VALUES: assignment and argument passing copy them (lazily, on first write).
    // C#: like a struct. Objects, by contrast, are handles (section 4).
    $copy = $list;
    $copy[0] = 99;
    $alias = &$list; // a reference: a second name for the same variable
    $alias[1] = 55;
    show($list[0], $copy[0], $list[1]);
    unset($alias); // removes the name, not the value

    // Destructuring, spread, nesting.
    [$first, , $third] = $list;
    ['bolt' => $bolts, 'screw' => $screws] = $map;
    [$x, $y] = [$third, $first];
    $merged = [...$list, ...[100, 200]];
    $defaults = ['host' => 'localhost', 'port' => 5432];
    $settings = [...$defaults, 'port' => 8080]; // later keys win. C#: a `with` expression
    $matrix = [[1, 2, 3], [4, 5, 6]];
    show($first, $third, $bolts + $screws, $x, $y, count($merged), $settings, $matrix[1][2]);
    show(array_map(null, ...$matrix)); // array_map(null, ...) zips: here it transposes

    // The functional toolbox. C#: LINQ Select / Where / Aggregate.
    $numbers = [5, 3, 8, 1, 9];
    $squares = array_map(fn(int $n): int => $n * $n, $numbers);
    $even = array_filter($numbers, fn(int $n): bool => $n % 2 === 0); // keeps the ORIGINAL keys
    $total = array_reduce($numbers, fn(int $carry, int $n): int => $carry + $n, 0);
    show($squares, $even, array_values($even), $total, array_sum($numbers), max($numbers));
    show(in_array(8, $numbers, true), array_search(8, $numbers, true), array_slice($numbers, 1, 2), range(1, 10, 3));

    // Sorting works in place, and the function name says what happens to the keys.
    $sorted = $numbers;
    sort($sorted); // by value; keys renumbered
    $byName = ['pear' => 3, 'fig' => 9, 'kiwi' => 1];
    ksort($byName); // by key
    $byValue = $byName;
    arsort($byValue); // by value, descending; keys kept
    $people = [
        ['name' => 'Ann', 'age' => 31],
        ['name' => 'Bob', 'age' => 25],
        ['name' => 'Cid', 'age' => 31],
    ];
    // usort takes a comparison function; comparing arrays compares element by element.
    usort($people, fn(array $p, array $q): int => [$q['age'], $p['name']] <=> [$p['age'], $q['name']]);
    show($sorted, $byName, $byValue, array_column($people, 'name'), array_column($people, 'age', 'name'));
    show(array_keys($byName), array_flip(['a', 'b']), array_combine(['x', 'y'], [1, 2]), array_unique([1, 1, 2]));

    // Key conversion: numeric strings become integers, true becomes 1.
    $keys = [];
    $keys['1'] = 'a';
    $keys[1] = 'b';
    $keys[true] = 'c';
    show($keys, array_key_first($byName), array_key_last($byName), compact('first', 'third'));
}

// =================================================================================================
//  3. FUNCTIONS AND CLOSURES
// =================================================================================================

function describe(string $name, string $greeting = 'Hello', string ...$extras): string
{
    $suffix = $extras === [] ? '' : ' (+' . count($extras) . ')'; // ...$extras: C# params
    return "$greeting, $name$suffix";
}

/** Several results are returned as an array (or an object). */
function divide(int $dividend, int $divisor): array
{
    return [intdiv($dividend, $divisor), $dividend % $divisor];
}

function increment(int &$value, int $by = 1): void // `&`: by reference. C#: ref
{
    $value += $by;
}

function nextId(): int
{
    static $counter = 0; // keeps its value between calls
    return ++$counter;
}

function lengthOf(int|string|null $value): ?int // a union type; `?int` means int|null
{
    return match (true) {
        $value === null => null,
        is_int($value) => $value,
        default => strlen($value),
    };
}

function section03Functions(): void
{
    title('3. Functions and closures');

    // Named arguments may come in any order and skip defaults.
    show(describe('Ann'), '|', describe('Bob', 'Hi'), '|', describe('Cid', 'Hey', 'x', 'y'), '|',
        describe(greeting: 'Yo', name: 'Dee'));
    [$quotient, $remainder] = divide(17, 5);
    $n = 5;
    increment($n);
    increment($n, by: 10);
    show($quotient, $remainder, $n, nextId(), nextId(), lengthOf('four'), lengthOf(7), lengthOf(null));

    // Declared types are checked on every call, at run time.
    try {
        describe(42);
    } catch (TypeError $e) {
        show('TypeError:', strtok($e->getMessage(), ','));
    }

    // Closures. `function` captures explicitly with `use` — BY VALUE, at creation time,
    // unless written `&$var`. An arrow function `fn` captures automatically (by value) and
    // is a single expression. C#: lambdas always capture the variable itself.
    $factor = 3;
    $byValue = function (int $x) use ($factor): int {
        return $x * $factor;
    };
    $byReference = function (int $x) use (&$factor): int {
        return $x * $factor;
    };
    $arrow = fn(int $x): int => $x * $factor;
    $factor = 10;
    show($byValue(2), $byReference(2), $arrow(2));

    $makeCounter = function (): Closure {
        $count = 0;
        return function () use (&$count): int {
            return ++$count;
        };
    };
    $counter = $makeCounter();
    $counter();
    show($counter(), $counter());

    // Callables: closures, function names as strings, [object, 'method'] pairs, and the
    // first-class callable syntax `f(...)`, which the engine checks.
    $length = strlen(...);
    $upper = 'strtoupper';
    $compose = fn(callable ...$fns): Closure =>
        fn(mixed $x): mixed => array_reduce($fns, fn(mixed $acc, callable $f): mixed => $f($acc), $x);
    $shout = $compose(trim(...), $upper, fn(string $s): string => $s . '!');
    show($length('four'), $upper('abc'), $shout('  hello '), array_map(strrev(...), ['ab', 'cd']));
    // A string callable needs the fully qualified name.
    show(is_callable('nextId'), is_callable('Tour\nextId'), is_callable(__NAMESPACE__ . '\nextId'));
}

// =================================================================================================
//  4. CLASSES, INTERFACES, TRAITS, ENUMS
// =================================================================================================

interface HasArea // C#: interface IHasArea
{
    public const UNITS = 'cm2'; // an interface may hold constants

    public function area(): float;
}

abstract class Shape implements HasArea, Stringable
{
    private static int $created = 0; // C#: static field

    // Constructor promotion: the parameter also declares and assigns the property.
    public function __construct(protected readonly string $name)
    {
        self::$created++;
    }

    abstract public function area(): float;

    public function describe(): string // every method is virtual; `final` forbids overriding
    {
        return sprintf('%s with area %.2f', $this->name, $this->area());
    }

    public function __toString(): string // C#: ToString()
    {
        return $this->describe();
    }

    public static function created(): int
    {
        return self::$created;
    }

    // `static` is the class the call was made on ("late static binding").
    public static function create(mixed ...$arguments): static
    {
        return new static(...$arguments);
    }
}

final class Circle extends Shape // final: cannot be extended. C#: sealed
{
    public function __construct(private readonly float $radius)
    {
        parent::__construct('circle'); // C#: `: base("circle")`
    }

    #[Override] // the engine verifies that a parent method really exists
    public function area(): float
    {
        return M_PI * $this->radius ** 2;
    }
}

class Rectangle extends Shape
{
    public function __construct(
        protected float $width,
        protected float $height,
        string $name = 'rectangle',
    ) {
        parent::__construct($name);
    }

    public function area(): float
    {
        return $this->width * $this->height;
    }
}

class Square extends Rectangle
{
    public function __construct(float $side)
    {
        parent::__construct($side, $side, 'square');
    }

    public function describe(): string
    {
        return 'a perfect ' . parent::describe(); // C#: base.Describe()
    }
}

// A trait: methods and properties that are copied into the classes that `use` it.
// C#: the closest things are default interface methods and extension methods.
trait Timestamps
{
    private ?string $touchedAt = null;

    public function touch(string $when): static
    {
        $this->touchedAt = $when;
        return $this; // returning $this allows chaining
    }

    public function touchedAt(): ?string
    {
        return $this->touchedAt;
    }
}

trait Tags
{
    /** @var list<string> */
    private array $tags = [];

    public function tag(string ...$tags): static
    {
        $this->tags = [...$this->tags, ...$tags];
        return $this;
    }
}

final class Article implements JsonSerializable
{
    use Timestamps;
    use Tags;

    public const string DEFAULT_STATUS = 'draft'; // a typed class constant

    public function __construct(public string $title, public string $status = self::DEFAULT_STATUS)
    {
    }

    public function jsonSerialize(): array // what json_encode sees
    {
        return ['title' => $this->title, 'status' => $this->status, 'tags' => $this->tags];
    }
}

// A backed enum. C#: enum — but a real type with methods, constants and interfaces.
enum Suit: string
{
    case Hearts = 'H';
    case Spades = 'S';
    case Clubs = 'C';

    public const Wild = self::Spades;

    public function color(): string
    {
        return match ($this) { // a match over an enum has to cover every case
            self::Hearts => 'red',
            self::Spades, self::Clubs => 'black',
        };
    }

    public static function fromName(string $name): self
    {
        return self::{$name}; // a class constant fetched by a run-time name
    }
}

enum Status // a pure enum: cases without scalar values
{
    case Active;
    case Archived;
}

// "Magic" methods and array-like interfaces. C#: indexers, IEnumerable, DynamicObject.
final class Bag implements ArrayAccess, Countable, IteratorAggregate
{
    private array $items = [];

    public function __get(string $name): mixed // reading a missing or inaccessible property
    {
        return $this->items[$name] ?? null;
    }

    public function __set(string $name, mixed $value): void
    {
        $this->items[$name] = $value;
    }

    public function __isset(string $name): bool
    {
        return isset($this->items[$name]);
    }

    public function __call(string $method, array $arguments): string // calling a missing method
    {
        return $method . '(' . implode(', ', $arguments) . ')';
    }

    public function __invoke(int $x): int // makes the object callable
    {
        return $x * count($this);
    }

    public function offsetExists(mixed $offset): bool // isset($bag['key'])
    {
        return isset($this->items[$offset]);
    }

    public function offsetGet(mixed $offset): mixed // $bag['key']
    {
        return $this->items[$offset] ?? null;
    }

    public function offsetSet(mixed $offset, mixed $value): void // $bag['key'] = ...
    {
        $this->items[$offset] = $value;
    }

    public function offsetUnset(mixed $offset): void // unset($bag['key'])
    {
        unset($this->items[$offset]);
    }

    public function count(): int // count($bag)
    {
        return count($this->items);
    }

    public function getIterator(): ArrayIterator // foreach ($bag as ...)
    {
        return new ArrayIterator($this->items);
    }
}

function section04Classes(): void
{
    title('4. Classes, interfaces, traits, enums');

    $shapes = [new Circle(1), new Rectangle(2, 3), Square::create(2)];
    show(implode('; ', array_map(strval(...), $shapes)));
    show($shapes[2] instanceof Rectangle, $shapes[0] instanceof HasArea, $shapes[2]::class, Shape::created(),
        HasArea::UNITS);
    // new Shape('x');      // Error: Cannot instantiate abstract class Tour\Shape

    // Objects are handles: assignment copies the handle, not the object — the opposite of
    // arrays. `clone` makes a shallow copy.
    $article = new Article('Tour');
    $same = $article;
    $same->title = 'Changed';
    $copy = clone $article;
    $copy->title = 'Copy';
    $article->touch('2026-11-17')->tag('php', 'c#');
    show($article->title, $copy->title, $article->touchedAt(), json_encode($article), $article == $copy,
        $article === $same);

    show(Suit::Hearts->value, Suit::from('S')->name, Suit::tryFrom('X'), Suit::Clubs->color(),
        array_map(fn(Suit $suit): string => $suit->name, Suit::cases()), Suit::Wild === Suit::Spades,
        Suit::fromName('Hearts') === Suit::Hearts, Status::Active->name);

    $bag = new Bag();
    $bag->color = 'red'; // __set
    $bag['size'] = 42;   // offsetSet
    $pairs = [];
    foreach ($bag as $key => $value) {
        $pairs[] = "$key=$value";
    }
    show($bag->color, $bag->missing, isset($bag->color), $bag['size'], count($bag), $pairs,
        $bag->anything(1, 2), $bag(10));

    // An anonymous class: a one-off implementation.
    $unit = new class implements HasArea {
        public function area(): float
        {
            return 1.0;
        }
    };
    show($unit->area(), $unit instanceof HasArea);
}

// =================================================================================================
//  5. TYPES AND ERRORS
// =================================================================================================

// A readonly class: every property can be assigned once. C#: a record with init-only
// properties.
final readonly class Money
{
    public function __construct(public int $amount, public string $currency)
    {
    }

    public function plus(Money $other): self
    {
        if ($other->currency !== $this->currency) {
            throw new InvalidArgumentException("cannot add $other->currency to $this->currency");
        }
        return new self($this->amount + $other->amount, $this->currency);
    }
}

// Anything thrown implements Throwable, which has two branches: Exception (application
// errors) and Error (engine failures such as TypeError).
class ConfigException extends RuntimeException
{
    public function __construct(public readonly string $key, string $reason, ?Throwable $previous = null)
    {
        parent::__construct("config key '$key': $reason", previous: $previous); // C#: InnerException
    }
}

function parsePort(string $text): int
{
    if (!ctype_digit($text)) {
        throw new ConfigException('port', 'not a number', new ValueError("bad input: $text"));
    }
    $port = (int) $text;
    // `throw` is an expression and can stand in a ternary or after `??`.
    return $port >= 1 && $port <= 65535 ? $port : throw new ConfigException('port', "$port is out of range");
}

/** A DNF type: an intersection inside a union. `mixed` is the top type, `never` the bottom. */
function countItems((Countable&Traversable)|array $items): int
{
    return count($items);
}

final class Resource
{
    public static array $log = [];

    public function __construct(private readonly string $name)
    {
        self::$log[] = "open $name";
    }

    // Objects are reference-counted, so the destructor runs as soon as the last handle
    // disappears. C#: Dispose — without needing `using`.
    public function __destruct()
    {
        self::$log[] = "close $this->name";
    }
}

function section05TypesAndErrors(): void
{
    title('5. Types and errors');

    foreach (['8080', 'http', '99999'] as $text) {
        try {
            show('port', parsePort($text));
        } catch (ConfigException $e) {
            $cause = $e->getPrevious() === null ? 'no cause' : $e->getPrevious()::class;
            show($e->getMessage(), "[key $e->key, $cause]");
        } finally {
            // runs in every case
        }
    }

    // Engine failures are exceptions too. (`catch (TypeError | ValueError $e)` takes several.)
    $nothing = null;
    $attempts = [
        'intdiv by zero' => fn() => intdiv(1, 0),
        'modulo by zero' => fn() => 1 % (int) '0',
        'wrong argument type' => fn() => strlen([]),
        'too few arguments' => fn() => divide(1),
        'method call on null' => fn() => $nothing->method(),
        'unknown function' => fn() => missingFunction(),
        'bad enum value' => fn() => Suit::from('X'),
        'write to readonly' => function (): void {
            $money = new Money(1, 'EUR');
            $money->amount = 2;
        },
        'text arithmetic' => fn() => 'abc' * (int) '2',
        'broken JSON' => fn() => json_decode('{oops}', flags: JSON_THROW_ON_ERROR),
    ];
    $outcomes = [];
    foreach ($attempts as $label => $attempt) {
        try {
            $attempt();
            $outcomes[] = "$label: no error";
        } catch (Throwable $e) {
            $outcomes[] = "$label: " . $e::class;
        }
    }
    show(implode('; ', $outcomes));

    // Warnings and notices are the older channel that does not throw (an undefined array
    // key, a failed fopen). A handler can turn them into exceptions.
    set_error_handler(fn(int $level, string $message) => throw new ErrorException($message, 0, $level));
    try {
        $empty = [];
        echo $empty['missing'];
    } catch (ErrorException $e) {
        show('a warning turned into an exception:', $e->getMessage());
    } finally {
        restore_error_handler();
    }

    $ten = (new Money(4, 'EUR'))->plus(new Money(6, 'EUR'));
    show($ten, countItems([1, 2, 3]), countItems(new ArrayIterator([1])), get_debug_type($ten), gettype(1.5));

    // Deterministic destruction.
    $outer = new Resource('outer');
    (function (): void {
        $inner = new Resource('inner');
        Resource::$log[] = 'work with ' . $inner::class;
    })(); // $inner is destroyed here, when the closure returns
    unset($outer);
    show(Resource::$log);
}

// =================================================================================================
//  6. ITERATORS AND GENERATORS
// =================================================================================================

/** A generator: the body is suspended at each `yield`. C#: an iterator with yield return. */
function fibonacci(): Generator
{
    [$a, $b] = [0, 1];
    while (true) { // infinite, but lazy
        yield $a;
        [$a, $b] = [$b, $a + $b];
    }
}

function take(iterable $items, int $limit): Generator
{
    if ($limit <= 0) {
        return;
    }
    foreach ($items as $key => $item) {
        yield $key => $item; // a generator may yield keys as well
        if (--$limit === 0) {
            return;
        }
    }
}

function mapLazy(callable $transform, iterable $items): Generator
{
    foreach ($items as $key => $item) {
        yield $key => $transform($item);
    }
}

function flatten(array $nested): Generator
{
    foreach ($nested as $item) {
        if (is_array($item)) {
            yield from flatten($item); // delegate to another generator
        } else {
            yield $item;
        }
    }
}

function runningAverage(): Generator
{
    $total = 0;
    $count = 0;
    $average = null;
    while (true) {
        $value = yield $average; // send() passes a value INTO the generator
        if ($value === null) {
            return $count; // read with getReturn()
        }
        $total += $value;
        $average = $total / ++$count;
    }
}

/** The Iterator interface by hand. C#: IEnumerator<T>. */
final class Countdown implements Iterator
{
    private int $current;

    public function __construct(private readonly int $start)
    {
        $this->current = $start;
    }

    public function current(): int
    {
        return $this->current;
    }

    public function key(): int
    {
        return $this->start - $this->current;
    }

    public function next(): void
    {
        $this->current--;
    }

    public function rewind(): void
    {
        $this->current = $this->start;
    }

    public function valid(): bool
    {
        return $this->current > 0;
    }
}

function section06Iterators(): void
{
    title('6. Iterators and generators');

    $squares = mapLazy(fn(int $n): int => $n * $n, fibonacci());
    show(iterator_to_array(new Countdown(3)), iterator_to_array(take(fibonacci(), 10)),
        iterator_to_array(take($squares, 6)));
    // `yield from` keeps the inner keys, so the keys must be dropped when collecting.
    show(iterator_to_array(flatten([1, [2, [3, 4]], 5]), preserve_keys: false));

    $averager = runningAverage();
    $averager->current(); // run to the first yield
    $averages = [$averager->send(10), $averager->send(20), $averager->send(60)];
    $averager->send(null);
    show($averages, $averager->getReturn());

    // SPL: ready-made data structures.
    $stack = new SplStack();
    $stack->push('a');
    $stack->push('b');
    $queue = new SplPriorityQueue();
    $queue->insert('low', 1);
    $queue->insert('high', 10);
    $set = new SplObjectStorage(); // a set or map keyed by object identity
    $key = new stdClass();
    $set[$key] = 'metadata';
    $fixed = SplFixedArray::fromArray([1, 2, 3]); // a real fixed-size array
    show($stack->pop(), $queue->extract(), count($set), $set[$key], $fixed->getSize(), array_sum($fixed->toArray()));
}

// =================================================================================================
//  7. STRINGS, REGULAR EXPRESSIONS, JSON, DATES, FILES
// =================================================================================================

function section07Text(): void
{
    title('7. Strings, regular expressions, JSON, dates, files');

    show(strrev('abc'), ucfirst('tour'), str_pad('5', 3, '0', STR_PAD_LEFT), trim("  x \n"),
        str_contains('detour', 'tour'), str_starts_with('tour', 'to'), explode(',', 'a,b,,c'),
        implode('-', ['x', 'y']), substr_count('mississippi', 'ss'), ucwords('hello big world'));
    show(sprintf('%05.1f|%-6s|%+d|%x|%b', 3.14159, 'ab', 5, 255, 5), number_format(1234567.891, 2),
        number_format(1234567.891, 2, ',', '.'), (string) 1.0, (int) '42abc', (float) '2.5e3', intval('ff', 16));

    // PCRE regular expressions. C#: Regex.
    $log = '2026-11-17 ERROR disk full; 2026-11-18 WARN retry; 2026-11-19 ERROR timeout';
    $pattern = '/(?<date>\d{4}-\d{2}-\d{2}) (?<level>[A-Z]+) (?<text>[^;]+)/';
    preg_match_all($pattern, $log, $matches, PREG_SET_ORDER);
    $errors = array_filter($matches, fn(array $match): bool => $match['level'] === 'ERROR');
    show(array_column($errors, 'date'), substr(preg_replace('/(\d+)-(\d+)-(\d+)/', '$3.$2.$1', $log, 1), 0, 10),
        preg_split('/[=;]/', 'x=1;y=22'), preg_match('/^[\w.]+@\w+\.\w+$/', 'ann@example.com'),
        preg_replace_callback('/\d+/', fn(array $m): string => (string) ($m[0] * 2), 'a1b22'));

    // JSON: an array becomes a JSON array or object depending on its keys.
    $json = json_encode(['name' => 'tour', 'tags' => ['php', 'c#'], 'stars' => 4.5, 'next' => null]);
    $asArray = json_decode($json, associative: true);
    $asObject = json_decode($json); // stdClass objects
    show($json, $asArray['tags'][1], $asObject->stars, json_validate('{"a":1}'), json_validate('{oops}'));

    // Dates: DateTimeImmutable. C#: DateTimeOffset, TimeSpan.
    $start = new DateTimeImmutable('2026-11-17 09:30', new DateTimeZone('UTC'));
    $later = $start->add(new DateInterval('P45DT3H'));
    show($later->format('Y-m-d H:i'), $later->format('l'), $start->diff($later)->days, $later > $start,
        $start->modify('last day of this month')->format('d.m.Y'),
        $start->setTimezone(new DateTimeZone('Europe/Berlin'))->format('H:i T'));

    // Files. C#: File.WriteAllText / File.ReadAllLines; fopen is the stream API of C.
    $path = tempnam(sys_get_temp_dir(), 'php-tour-');
    file_put_contents($path, "first\nsecond\n");
    file_put_contents($path, "third\n", FILE_APPEND);
    $lines = file($path, FILE_IGNORE_NEW_LINES);
    $handle = fopen($path, 'r');
    $firstLine = rtrim(fgets($handle));
    fclose($handle);
    // `@` silences the warning of one expression; the function then just returns false.
    show($lines, $firstLine, filesize($path), pathinfo('/tmp/notes.txt', PATHINFO_EXTENSION),
        basename('/tmp/notes.txt'), @file_get_contents($path . '.missing') === false);
    unlink($path);
}

// =================================================================================================
//  8. REFLECTION, ATTRIBUTES, NAMESPACES
// =================================================================================================

#[Attribute(Attribute::TARGET_METHOD)]
final class Route // an attribute is an ordinary class. C#: class RouteAttribute : Attribute
{
    public function __construct(public string $path, public string $method = 'GET')
    {
    }
}

final class UserController
{
    public function __construct(private string $prefix = 'user')
    {
    }

    #[Route('/users')]
    public function index(): string
    {
        return "$this->prefix list";
    }

    #[Route('/users', method: 'POST')]
    public function create(string $name): string
    {
        return "$this->prefix $name created";
    }

    private function secret(): string
    {
        return 'hidden';
    }
}

function section08Reflection(): void
{
    title('8. Reflection, attributes, namespaces');

    // Reflection and attributes: how routers, ORMs and DI containers work.
    $class = new ReflectionClass(UserController::class);
    $routes = [];
    foreach ($class->getMethods() as $method) {
        foreach ($method->getAttributes(Route::class) as $attribute) {
            $route = $attribute->newInstance(); // the attribute object is created only here
            $routes[] = "$route->method $route->path -> {$method->getName()}";
        }
    }
    $controller = $class->newInstanceArgs(['admin']);
    $parameters = $class->getMethod('create')->getParameters();
    show($routes, $class->getShortName(), $class->isFinal(), $class->getMethod('secret')->invoke($controller),
        array_map(fn(ReflectionParameter $p): string => "{$p->getType()} \${$p->getName()}", $parameters));

    // Everything can be addressed by name at run time.
    $className = UserController::class; // the fully qualified name, as a string
    $methodName = 'index';
    $object = new $className('guest');
    $function = 'str' . 'rev';
    $property = 'title';
    $article = new Article('Dynamic');
    show($object->$methodName(), $function('abc'), $article->$property, [$object, 'create']('Ann'),
        method_exists($object, 'index'), property_exists($article, 'status'), get_object_vars($article));

    // Closure::bind lets a closure into the private scope of another object.
    $peek = fn(): string => $this->prefix;
    show(Closure::bind($peek, $object, UserController::class)());

    // Namespaces, magic constants, variable variables.
    $name = 'dynamicVariable';
    $$name = 'set through $$';
    show(__FUNCTION__, __NAMESPACE__, basename(__FILE__), $dynamicVariable, round(TAU, 4),
        round(circleArea(1), 4), \strlen('global'), namespace\MAX_POINTS);
    // Classes are loaded on demand by an autoloader (spl_autoload_register); with Composer
    // the namespace maps to a folder (PSR-4), so there are no `require` lines in real code.

    // WeakMap: data attached to objects without keeping them alive. C#: ConditionalWeakTable.
    $cache = new WeakMap();
    $cache[$object] = 'cached value';
    $before = count($cache);
    unset($object); // the last handle goes away, and the entry goes with it
    show($before, count($cache));
}

// =================================================================================================
//  9. THE EXECUTION MODEL AND FIBERS
// =================================================================================================
//
//  PHP's classic model is "shared nothing": each web request gets a fresh interpreter state,
//  runs the script from top to bottom and throws everything away. There are no threads and
//  no shared memory, hence no locks and nothing to leak between requests. (C#: imagine a new
//  process per request.) Long-running servers and asynchronous I/O exist as extensions and
//  libraries: Swoole, FrankenPHP, ReactPHP, AMPHP.

function section09Fibers(): void
{
    title('9. The execution model and fibers');

    // A fiber is the primitive under those async libraries: a function with a stack of its
    // own that can suspend itself anywhere and be resumed later. C#: the state machine the
    // compiler builds for async/await, done at run time instead.
    $log = [];
    $fiber = new Fiber(function (string $name) use (&$log): string {
        $log[] = "$name started";
        $reply = Fiber::suspend('first pause'); // hands a value out and waits for one to come in
        $log[] = "$name resumed with $reply";
        $reply = Fiber::suspend('second pause');
        return "$name finished with $reply";
    });
    $first = $fiber->start('fiber');
    $second = $fiber->resume('A');
    $fiber->resume('B');
    show($first, '|', $second, '|', $fiber->isTerminated(), $fiber->getReturn(), $log);

    // A tiny round-robin scheduler: three "tasks" take turns on one thread.
    $trace = [];
    // (A `fn` would not do here: it captures $trace by value, and the log would be lost.)
    $task = function (string $name, int $steps) use (&$trace): Fiber {
        return new Fiber(function () use ($name, $steps, &$trace): void {
            for ($i = 1; $i <= $steps; $i++) {
                $trace[] = "$name$i";
                Fiber::suspend(); // "await": give control back to the scheduler
            }
        });
    };
    $ready = [$task('a', 2), $task('b', 3), $task('c', 1)];
    while ($ready !== []) {
        $fiber = array_shift($ready);
        $fiber->isStarted() ? $fiber->resume() : $fiber->start();
        if (!$fiber->isTerminated()) {
            $ready[] = $fiber;
        }
    }
    show(implode(' ', $trace));
}

// =================================================================================================
//  10. THE NEWEST
// =================================================================================================

function section10Newest(): void
{
    title('10. The newest');

    // Used above:
    //   8.0  named arguments, match, constructor promotion, union types, ?->, attributes
    //   8.1  enums, readonly properties, first-class callables f(...), fibers, array_is_list
    //   8.2  readonly classes, DNF types
    //   8.3  typed class constants, #[Override], json_validate, Suit::{$name}
    show(PHP_VERSION_ID >= 80300, PHP_OS_FAMILY !== '', PHP_INT_SIZE);

    // Newer than the interpreter this file was verified with — NOT run here:
    //
    //   8.4   class Temperature {
    //             public float $celsius = 0.0;
    //             public float $fahrenheit {                    // property hooks. C#: properties
    //                 get => $this->celsius * 9 / 5 + 32;
    //                 set (float $value) { $this->celsius = ($value - 32) * 5 / 9; }
    //             }
    //             public private(set) int $version = 1;         // C#: { get; private set; }
    //         }
    //         $admin = array_find($users, fn(User $u): bool => $u->isAdmin);
    //         $name = new ReflectionClass(Article::class)->getShortName();   // no extra parentheses
    //
    //   8.5   $slug = $title |> trim(...) |> strtolower(...);   // the pipe operator
    //         $copy = clone($money, ['amount' => 10]);          // clone with changed properties
    //         $last = array_last($list);                        // and array_first()
    //
    //   8.6   (due on 19 November 2026) partial function application:
    //         $double = multiply(2, ?);
}

// =================================================================================================
//  ENTRY POINT
// =================================================================================================

function main(): void
{
    section01Basics();
    section02Arrays();
    section03Functions();
    section04Classes();
    section05TypesAndErrors();
    section06Iterators();
    section07Text();
    section08Reflection();
    section09Fibers();
    section10Newest();
}

// A script simply runs from top to bottom: there is no required entry point.
main();
