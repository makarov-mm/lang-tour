#!/usr/bin/env python3
# ==================================================================================================
#  PYTHON FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
#
#  Run:   python3 python_tour.py          (Python 3.14 or newer)
#
#  Verified with CPython 3.14.6. Older interpreters reject the file: it uses template strings
#  and `except` without parentheses (a SyntaxError before 3.14) and relies on the deferred
#  evaluation of annotations.
#
#  How to read. Each section is a function `section_NN_*`; the classes and helpers a section
#  needs are defined right before it; `main()` at the end calls the sections in order. A "C#:"
#  note shows the closest C# counterpart. Lines that would fail are commented out together with
#  the error they raise.
#
#  The main differences from C# to keep in mind from the first line:
#
#   1. Dynamic typing. Names have no type, objects do. Type hints (`x: int`) are optional
#      documentation for external checkers (mypy, pyright); the interpreter ignores them.
#   2. Every value is an object behind a reference: no value types, no boxing. Immutable
#      objects (int, str, tuple) merely behave like values.
#   3. Indentation is syntax: a block is a deeper indentation level after a colon.
#   4. Nothing is bound statically. `def` and `class` are statements that create objects at run
#      time; names are looked up when the code runs, not when it is compiled.
#   5. No access modifiers. A leading underscore means "private by convention".
#   6. Memory is reference-counted with a cycle collector on top, so objects usually die at
#      once. Resources are still released explicitly with `with` (C#: using).
#   7. In the default build one lock (the GIL) lets only one thread run Python code at a time.
#      Concurrency means asyncio for I/O and processes for CPU work.
#
#  Contents:
#    1. Basics: names, numbers, strings, control flow     7. Errors and resources
#    2. Collections and comprehensions                    8. Pattern matching
#    3. Functions, closures, decorators                   9. Standard library highlights
#    4. Classes, dataclasses, enums                      10. Metaprogramming
#    5. Type hints, generics, protocols                  11. Concurrency: threads, asyncio
#    6. Iterators and generators                         12. The newest: 3.12 - 3.14
# ==================================================================================================

# `import` binds a module object to a name. C#: using + an assembly reference. A module is
# simply a .py file; its top-level code runs once, on first import.
import annotationlib
import ast
import asyncio
import copy
import dataclasses
import decimal
import enum
import functools
import inspect
import io
import itertools
import json
import math
import operator
import random
import re
import statistics
import sys
import tempfile
import threading
import time
import warnings
from abc import ABC, abstractmethod
from collections import Counter, defaultdict, deque
from collections.abc import Callable, Iterable, Iterator
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor
from contextlib import contextmanager, suppress
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal
from fractions import Fraction
from pathlib import Path
from typing import Any, NamedTuple, Protocol, Self, TypedDict, overload, override, runtime_checkable


def header(title: str) -> None:
    print(f"\n=== {title} ===")


# ==================================================================================================
#  1. BASICS: names, numbers, strings, control flow
# ==================================================================================================

def section_01_basics() -> None:
    header("1. Basics")

    # --- Names and objects ---
    # A variable is a name bound to an object; assignment never copies. C#: every variable
    # behaves like a variable of a reference type.
    a = 42
    b = a                       # a second name for the same object
    a = "text"                  # rebinding: the type belongs to the object, not to the name
    print(a, b, type(a).__name__, type(b).__name__)

    # --- Numbers ---
    big = 2 ** 100              # int has arbitrary precision: it never overflows
    ratio = 7 / 2               # `/` is always true division: 3.5
    floor, rem = 7 // 2, -7 % 3   # floor division; the remainder takes the sign of the divisor
    print(big, ratio, floor, rem, 0.1 + 0.2 == 0.3, math.isclose(0.1 + 0.2, 0.3))
    print(Decimal("0.1") + Decimal("0.2"), Fraction(1, 3) + Fraction(1, 6), (1 + 2j) * 1j,
          1_000_000, 0xFF, 0b1010, int("42") + int(3.99), float("1e3"), round(2.675, 2))
    # (round(2.675, 2) gives 2.67: a float is binary, and 2.675 is really 2.67499999...)

    # --- Strings: immutable sequences of Unicode code points (not UTF-16 units as in C#) ---
    name = "World"
    greeting = f"Hello, {name}!"                # an f-string. C#: $"Hello, {name}!"
    print(greeting, len(greeting), greeting.upper(), greeting[7:12], greeting[-1], greeting[::-1])
    print(f"{math.pi:.3f} | {255:#x} | {42:>6} | {'ab':<6}| {1234567.891:,.2f} | {0.256:.1%} | "
          f"{name!r} | {ratio = }")
    raw = r"C:\dir\file"                        # a raw string: backslashes are literal. C#: @"..."
    multi = """line one
line two"""                                     # triple quotes keep line breaks
    print(raw, "|", multi.splitlines(), "|", "a,b,c".split(","), "|", "-".join(["x", "y"]),
          "|", "  padded ".strip(), "|", "tour" in "detour", "|", "ab" * 3)
    mixed = "aß😀"
    print(len(mixed), len(mixed.encode("utf-8")), [hex(ord(ch)) for ch in mixed])
    # greeting[0] = "J"         # TypeError: 'str' object does not support item assignment

    # --- Truthiness: 0, "", None and empty containers are false; everything else is true ---
    print({repr(value): bool(value) for value in (0, 1, "", "x", [], [0], None)})
    # `and` / `or` return one of their operands, not a bool. C#: `??` covers only null.
    print(None or "default", "" or "default", 0 and "never", [1] and "last")

    # `==` compares values, `is` compares identity (C#: ReferenceEquals). Comparisons chain.
    x, y = [1, 2], [1, 2]
    print(x == y, x is y, x is not None, 1 < 2 < 3, 1 == 1.0, "a" < "b")

    # --- Control flow ---
    n = 17
    if n % 2 == 0:
        kind = "even"
    elif n % 3 == 0:
        kind = "divisible by 3"
    else:
        kind = "other"
    parity = "even" if n % 2 == 0 else "odd"    # the conditional expression. C#: ?:
    total = 0
    for i in range(1, 6):                       # range(1, 6) is 1..5; there is no C-style for
        total += i
    while total > 10:
        total -= 4
    # for/else: the `else` branch runs only if the loop was NOT left through `break`.
    for divisor in range(2, int(n ** 0.5) + 1):
        if n % divisor == 0:
            verdict = f"{n} = {divisor} * {n // divisor}"
            break
    else:
        verdict = f"{n} is prime"
    print(kind, parity, total, verdict)

    # The walrus operator `:=` assigns inside an expression. C#: `is var` / assignment in `if`.
    if (found := re.search(r"(\d+)-(\d+)", "pages 10-25")) is not None:
        print("range:", int(found[1]), "to", int(found[2]))


# ==================================================================================================
#  2. COLLECTIONS AND COMPREHENSIONS
# ==================================================================================================

def section_02_collections() -> None:
    header("2. Collections")

    # --- list: a mutable dynamic array. C#: List<object> ---
    numbers = [5, 3, 8, 1]
    numbers.append(9)
    numbers.insert(0, 7)
    numbers.extend([2, 6])
    last = numbers.pop()
    print(numbers, last, len(numbers), 8 in numbers, numbers.index(8))
    # Slicing [start:stop:step] copies; negative indices count from the end.
    print(numbers[1:4], numbers[:2], numbers[-2:], numbers[::2], numbers[::-1])
    alias, shallow = numbers, numbers[:]        # an alias and a shallow copy
    alias[0] = 70
    print(numbers[0], shallow[0])
    # sorted() returns a new list, list.sort() sorts in place; `key` is a projection.
    words = ["pear", "Fig", "banana", "kiwi"]
    print(sorted(words), sorted(words, key=str.lower), sorted(words, key=len, reverse=True))

    # --- tuple: an immutable sequence, and the way to return several values ---
    point = (3, 4)
    x, y = point                                # unpacking. C#: var (x, y) = point
    x, y = y, x                                 # a swap without a temporary
    first, *middle, tail = [1, 2, 3, 4, 5]      # star-unpacking takes "the rest"
    print(point, x, y, first, middle, tail, (1,), ())
    # point[0] = 9              # TypeError: 'tuple' object does not support item assignment

    # --- dict: a hash map that keeps insertion order. C#: Dictionary<TKey, TValue> ---
    ages = {"Ann": 30, "Bob": 25}
    ages["Cid"] = 41
    ages |= {"Bob": 26}                         # merge-update
    print(ages, ages["Ann"], ages.get("Zed"), ages.get("Zed", -1), "Bob" in ages)
    # ages["Zed"]               # KeyError: 'Zed'
    del ages["Cid"]
    print([f"{name}={age}" for name, age in ages.items()], list(ages), list(ages.values()))
    counts: dict[str, int] = {}
    for ch in "mississippi":
        counts[ch] = counts.get(ch, 0) + 1
    print(counts, max(counts, key=counts.get))

    # --- set: unique hashable elements with set algebra. C#: HashSet<T> ---
    odd, prime = {1, 3, 5, 7, 9}, {2, 3, 5, 7}
    print(odd & prime, odd | prime, odd - prime, odd ^ prime, {3, 5} <= odd, sorted(set("abca")))

    # --- Comprehensions: the idiomatic map/filter. C#: LINQ Select / Where ---
    squares = [n * n for n in range(10) if n % 2 == 0]
    lengths = {word: len(word) for word in words}
    initials = {word[0].lower() for word in words}
    pairs = [(a, b) for a in range(3) for b in range(a)]        # nested loops, left to right
    matrix = [[row * 3 + col for col in range(3)] for row in range(2)]
    transposed = [list(column) for column in zip(*matrix)]      # zip(*rows) transposes
    print(squares, lengths, sorted(initials), pairs, matrix, transposed)

    # Handy built-ins: enumerate, zip, map, any/all, sum/min/max.
    print([f"{index}:{word}/{size}" for index, (word, size)
           in enumerate(zip(words, map(len, words)), start=1)])
    print(any(n > 8 for n in numbers), all(n > 0 for n in numbers), sum(numbers),
          min(words, key=len))

    # A mutability trap: list multiplication copies REFERENCES to the inner list.
    grid_bad = [[0] * 2] * 2
    grid_ok = [[0] * 2 for _ in range(2)]
    grid_bad[0][0] = grid_ok[0][0] = 1
    print(grid_bad, grid_ok, copy.deepcopy(grid_ok) == grid_ok)


# ==================================================================================================
#  3. FUNCTIONS, CLOSURES, DECORATORS
# ==================================================================================================

def describe(name: str, /, greeting: str = "Hello", *, punctuation: str = "!") -> str:
    """`/` ends the positional-only parameters, `*` starts the keyword-only ones.
    This string is the docstring: documentation kept on the object (C#: XML doc comments)."""
    return f"{greeting}, {name}{punctuation}"


def collect(*args: int, **options: object) -> str:
    """*args gathers extra positional arguments (C#: params), **options the keyword ones."""
    return f"args={args} options={options}"


def append_bad(item, bucket=[]):                # a default is evaluated ONCE, at `def` time
    bucket.append(item)
    return bucket


def append_ok(item, bucket=None):               # the idiom: None as "not given"
    if bucket is None:
        bucket = []
    bucket.append(item)
    return bucket


def make_counter() -> Callable[[], int]:
    count = 0

    def increment() -> int:
        nonlocal count                          # rebinding an outer variable needs `nonlocal`
        count += 1
        return count

    return increment


def timed(function):
    """A decorator: a function that takes a function and returns its replacement."""
    @functools.wraps(function)                  # copies __name__, __doc__ and so on to the wrapper
    def wrapper(*args, **kwargs):
        start = time.perf_counter()
        try:
            return function(*args, **kwargs)
        finally:
            wrapper.calls += 1
            wrapper.seconds += time.perf_counter() - start

    wrapper.calls = 0                           # functions are objects and can carry attributes
    wrapper.seconds = 0.0
    return wrapper


def repeat(times: int):
    """A decorator WITH arguments is a function that returns a decorator."""
    def decorator(function):
        @functools.wraps(function)
        def wrapper(*args, **kwargs):
            return [function(*args, **kwargs) for _ in range(times)]
        return wrapper
    return decorator


@timed                                          # the same as: slow_sum = timed(slow_sum)
def slow_sum(n: int) -> int:
    return sum(range(n))


@repeat(3)
def roll(sides: int = 6) -> int:
    return sides


@functools.cache                                # memoization from the standard library
def fib(n: int) -> int:
    return n if n < 2 else fib(n - 1) + fib(n - 2)


def section_03_functions() -> None:
    header("3. Functions")
    print(describe("Ann"), describe("Bob", "Hi"), describe("Cid", punctuation="?"))
    # describe(name="Ann")      # TypeError: positional-only argument passed as keyword argument
    print(collect(1, 2, 3, verbose=True, depth=2))
    values, settings = [1, 2], {"verbose": False}
    print(collect(*values, **settings))         # unpacking arguments at the call site
    print(describe.__name__, "|", describe.__doc__.splitlines()[0])

    # The mutable-default trap: both calls return the SAME list.
    print(append_bad(1), append_bad(2), "|", append_ok(1), append_ok(2))

    # Functions are first-class objects: store them, pass them, return them.
    operations = {"add": lambda a, b: a + b, "max": max, "pow": pow}
    print({name: op(2, 5) for name, op in operations.items()})
    counter = make_counter()
    print(counter(), counter(), counter())

    # Closures capture VARIABLES, not values (as in C#): all three lambdas see the last i...
    late = [lambda: i for i in range(3)]
    bound = [lambda i=i: i for i in range(3)]   # ...unless a default argument freezes the value
    print([f() for f in late], [f() for f in bound])

    slow_sum(100_000)
    slow_sum(200_000)
    print(slow_sum.__name__, slow_sum.calls, slow_sum.seconds < 1, roll(), fib(90))
    two_to_the = functools.partial(pow, 2)      # partial application: pow(2, x)
    print(two_to_the(10), functools.reduce(lambda acc, n: acc * n, range(1, 6)),
          fib.cache_info().currsize)


# ==================================================================================================
#  4. CLASSES, DATACLASSES, ENUMS
# ==================================================================================================

class Vector:
    """A small value-like class. Special ("dunder") methods plug it into the language."""

    __slots__ = ("x", "y")      # a fixed attribute set: no per-instance dict, less memory

    def __init__(self, x: float, y: float) -> None:     # the initializer. C#: constructor
        self.x = x                                      # attributes are created by assignment
        self.y = y

    def __repr__(self) -> str:                          # C#: ToString()
        return f"Vector({self.x}, {self.y})"

    def __eq__(self, other: object) -> bool:            # C#: Equals + operator ==
        return isinstance(other, Vector) and (self.x, self.y) == (other.x, other.y)

    def __hash__(self) -> int:                          # defining __eq__ removes the default hash
        return hash((self.x, self.y))

    def __add__(self, other: Vector) -> Vector:         # C#: operator +
        return Vector(self.x + other.x, self.y + other.y)

    def __mul__(self, factor: float) -> Vector:
        return Vector(self.x * factor, self.y * factor)

    __rmul__ = __mul__                                  # makes `2 * v` work as well as `v * 2`

    def __abs__(self) -> float:
        return math.hypot(self.x, self.y)

    def __bool__(self) -> bool:
        return bool(self.x or self.y)

    def __iter__(self) -> Iterator[float]:              # enables unpacking: x, y = v
        yield self.x
        yield self.y


class Account:
    """Properties, class attributes, class methods and static methods."""

    interest_rate = 0.02        # a class attribute, shared by all instances. C#: static field
    _created = 0

    def __init__(self, owner: str, balance: float = 0.0) -> None:
        self.owner = owner
        self._balance = balance                 # one underscore: "private by convention"
        self.__pin = "0000"                     # two underscores: mangled to _Account__pin
        Account._created += 1

    @property                                   # C#: public double Balance { get { ... } }
    def balance(self) -> float:
        return self._balance

    @balance.setter
    def balance(self, value: float) -> None:
        if value < 0:
            raise ValueError("balance cannot be negative")
        self._balance = value

    @classmethod                                # receives the class: an alternative constructor
    def from_text(cls, text: str) -> Self:
        owner, amount = text.split(":")
        return cls(owner, float(amount))

    @staticmethod                               # a plain function in the class namespace
    def is_valid_owner(name: str) -> bool:
        return name.isalpha()

    @classmethod
    def created(cls) -> int:
        return cls._created


class Shape(ABC):
    """An abstract base class. C#: abstract class."""

    def __init__(self, name: str) -> None:
        self.name = name

    @property
    @abstractmethod
    def area(self) -> float: ...

    def describe(self) -> str:                  # every method is virtual
        return f"{self.name} with area {self.area:.2f}"


class Circle(Shape):
    def __init__(self, radius: float) -> None:
        super().__init__("circle")              # C#: `: base("circle")`
        self.radius = radius

    @property
    def area(self) -> float:
        return math.pi * self.radius ** 2


class Rectangle(Shape):
    def __init__(self, width: float, height: float, name: str = "rectangle") -> None:
        super().__init__(name)
        self.width, self.height = width, height

    @property
    def area(self) -> float:
        return self.width * self.height


class Square(Rectangle):
    def __init__(self, side: float) -> None:
        super().__init__(side, side, "square")

    @override                                   # checkers verify that a base method exists
    def describe(self) -> str:
        return "a perfect " + super().describe()


class JsonMixin:
    """A mixin: multiple inheritance used to share behaviour rather than state."""

    def to_json(self) -> str:
        return json.dumps(vars(self), sort_keys=True)


class Loud:
    def describe(self) -> str:
        return super().describe().upper()       # super() follows the MRO, not "the" base class


class LoudCircle(Loud, JsonMixin, Circle):      # method resolution order: left to right
    pass


@dataclass(frozen=True, order=True, slots=True)
class Version:
    """A dataclass generates __init__, __repr__, __eq__, ordering and hashing. C#: record."""

    major: int
    minor: int = 0
    patch: int = 0

    def bumped(self) -> Version:
        return dataclasses.replace(self, patch=self.patch + 1)   # C#: `with { Patch = ... }`


@dataclass
class Order:
    customer: str
    items: list[str] = field(default_factory=list)      # a fresh list for every instance
    total: float = field(default=0.0, repr=False)

    def __post_init__(self) -> None:                    # runs after the generated __init__
        self.customer = self.customer.strip().title()


class Color(enum.Enum):
    RED = 1
    GREEN = 2
    BLUE = 3

    @property
    def is_warm(self) -> bool:                  # enum members are full objects with methods
        return self is Color.RED


class Permission(enum.Flag):                    # C#: [Flags] enum
    READ = enum.auto()
    WRITE = enum.auto()
    EXECUTE = enum.auto()


def section_04_classes() -> None:
    header("4. Classes")
    v, w = Vector(3, 4), Vector(1, 1)
    x, y = v
    print(v, v + w, 2 * v, abs(v), v == Vector(3, 4), v is Vector(3, 4), bool(Vector(0, 0)),
          x, y, len({v, Vector(3, 4)}))
    # v.z = 1                   # AttributeError: 'Vector' object has no attribute 'z' (__slots__)

    account = Account.from_text("Ann:150.5")
    account.balance += 50                       # goes through the property getter and setter
    try:
        account.balance = -1
    except ValueError as error:
        print("rejected:", error)
    print(account.owner, account.balance, Account.created(), Account.is_valid_owner("R2D2"))
    # There is no real privacy: "private" attributes are reachable if you insist.
    print(account._balance, account._Account__pin, hasattr(account, "__pin"))
    # Objects are open: attributes can be added at run time (unless __slots__ forbids it).
    account.nickname = "main"
    print(vars(account))

    shapes: list[Shape] = [Circle(1), Rectangle(2, 3), Square(2)]
    print("; ".join(shape.describe() for shape in shapes))
    # Shape("x")                # TypeError: Can't instantiate abstract class Shape
    print(isinstance(shapes[2], Rectangle), issubclass(Square, Shape), type(shapes[2]).__name__)
    loud = LoudCircle(2)
    print(loud.describe(), loud.to_json(), [cls.__name__ for cls in LoudCircle.__mro__])

    v1, v2 = Version(1, 2), Version(1, 10)
    print(v1, v1 < v2, v1 == Version(1, 2, 0), v1.bumped(), max(v1, v2),
          hash(v1) == hash(Version(1, 2)))
    # v1.major = 2              # dataclasses.FrozenInstanceError: cannot assign to field 'major'
    print(Order("  ann lee "), Order("bob").items is Order("bob").items)

    print(Color.RED, Color(2), Color["BLUE"], Color.RED.is_warm, [c.name for c in Color],
          Color.RED.value)
    access = Permission.READ | Permission.WRITE
    print(access, Permission.WRITE in access, Permission.EXECUTE in access)


# ==================================================================================================
#  5. TYPE HINTS, GENERICS, PROTOCOLS
# ==================================================================================================

class SupportsArea(Protocol):
    """Structural typing: any class with a matching `area` fits, no inheritance required.
    C#: there is no direct counterpart (interfaces are nominal); C++: a concept."""

    @property
    def area(self) -> float: ...


@runtime_checkable                              # allows isinstance() against the protocol
class Closeable(Protocol):
    def close(self) -> None: ...


class Stack[T]:
    """A generic class (the [T] syntax arrived in 3.12). C#: class Stack<T>."""

    def __init__(self) -> None:
        self._items: list[T] = []

    def push(self, item: T) -> Self:
        self._items.append(item)
        return self

    def pop(self) -> T:
        return self._items.pop()

    def __len__(self) -> int:
        return len(self._items)


def largest[T: (int, float, str)](items: Iterable[T]) -> T:    # T limited to the listed types
    return max(items)


def total_area(shapes: Iterable[SupportsArea]) -> float:
    return sum(shape.area for shape in shapes)


# A type alias; it may refer to itself.
type Json = None | bool | int | float | str | list[Json] | dict[str, Json]


class Movie(TypedDict):                         # the shape of a plain dict, for checkers only
    title: str
    year: int


class Coordinates(NamedTuple):                  # a tuple with named fields
    latitude: float
    longitude: float


@overload
def parse(value: str) -> int: ...
@overload
def parse(value: bytes) -> bytes: ...
def parse(value):                               # one body; the overloads exist for checkers
    return int(value) if isinstance(value, str) else value[::-1]


def section_05_typing() -> None:
    header("5. Type hints, generics, protocols")

    # Hints are not enforced: the second call "violates" the annotation and runs anyway.
    def double(value: int) -> int:
        return value * 2

    print(double(21), double("ab"), double.__annotations__)

    stack = Stack[int]().push(1).push(2)        # the [int] is for readers and checkers only
    stack.push("three")                         # a checker complains; the interpreter does not
    print(len(stack), stack.pop(), largest([3, 1, 2]), largest("hello"))

    class Plot:                                 # no base class, but it has `area`
        area = 600.0

    print(total_area([Circle(1), Plot()]))
    print(isinstance(io.StringIO(), Closeable), isinstance(42, Closeable))

    movie: Movie = {"title": "Alien", "year": 1979}
    home = Coordinates(48.137, 11.575)
    latitude, _ = home
    print(movie["title"], home, home.longitude, latitude, parse("42"), parse(b"abc"))
    print(Stack.__type_params__, Json.__name__, type(Json).__name__, str | None)


# ==================================================================================================
#  6. ITERATORS AND GENERATORS
# ==================================================================================================

class Countdown:
    """The iterator protocol by hand: __iter__ returns an object that has __next__.
    C#: IEnumerable<T> and IEnumerator<T>."""

    def __init__(self, start: int) -> None:
        self.current = start

    def __iter__(self) -> Self:
        return self

    def __next__(self) -> int:
        if self.current <= 0:
            raise StopIteration                 # the "no more items" signal
        self.current -= 1
        return self.current + 1


def fibonacci() -> Iterator[int]:
    """A generator: the body is suspended at every `yield`. C#: yield return."""
    a, b = 0, 1
    while True:                                 # infinite, but lazy
        yield a
        a, b = b, a + b


def flatten(nested: Iterable[Any]) -> Iterator[Any]:
    for item in nested:
        if isinstance(item, (list, tuple)):
            yield from flatten(item)            # delegate to a sub-generator
        else:
            yield item


def running_average():
    """A generator is a coroutine too: `send` passes a value INTO the suspended `yield`."""
    total, count, average = 0.0, 0, None
    while True:
        value = yield average
        total, count = total + value, count + 1
        average = total / count


def section_06_iterators() -> None:
    header("6. Iterators and generators")
    print(list(Countdown(3)), sum(Countdown(4)), max(Countdown(5)))
    # A `for` loop is: it = iter(obj), then next(it) again and again until StopIteration.
    iterator = iter([10, 20])
    print(next(iterator), next(iterator), next(iterator, "exhausted"))

    print(list(itertools.islice(fibonacci(), 10)),
          list(itertools.takewhile(lambda n: n < 50, fibonacci()))[-3:])
    print(list(flatten([1, [2, (3, 4)], [[5]], 6])))

    # A generator expression is a lazy comprehension: nothing runs until it is consumed.
    lazy = (n * n for n in range(1_000_000_000))        # instant, and takes no memory
    print(next(lazy), next(lazy), next(lazy), sum(n * n for n in range(10)))

    averager = running_average()
    next(averager)                              # run to the first yield ("priming")
    print([averager.send(value) for value in (10, 20, 60)])

    # itertools is the standard toolbox for lazy pipelines.
    print(list(itertools.chain("ab", [1, 2])), list(itertools.pairwise([1, 2, 3, 4])),
          list(itertools.batched(range(7), 3)), list(itertools.accumulate([1, 2, 3, 4])))
    print(list(itertools.product("xy", [1, 2])), list(itertools.combinations("abc", 2)),
          list(zip("abc", itertools.count(1))))
    fruits = sorted(["apple", "avocado", "banana", "blueberry", "cherry"])
    print({letter: list(group) for letter, group in itertools.groupby(fruits, key=lambda s: s[0])})
    # A generator can be consumed only once; a second pass yields nothing.
    once = (n for n in range(3))
    print(list(once), list(once))


# ==================================================================================================
#  7. ERRORS AND RESOURCES
# ==================================================================================================

class ConfigError(Exception):
    """A custom exception. Anything raised must derive from BaseException."""

    def __init__(self, key: str, reason: str) -> None:
        super().__init__(f"config key '{key}': {reason}")
        self.key = key


def parse_port(text: str) -> int:
    try:
        port = int(text)
    except ValueError as error:
        raise ConfigError("port", "not a number") from error    # C#: InnerException
    if not 0 < port < 65536:
        raise ConfigError("port", f"{port} is out of range")
    return port


class Resource:
    """A context manager by hand: __enter__ and __exit__. C#: IDisposable + using."""

    log: list[str] = []

    def __init__(self, name: str) -> None:
        self.name = name

    def __enter__(self) -> Self:
        Resource.log.append(f"acquire {self.name}")
        return self

    def __exit__(self, exc_type, exc, traceback) -> bool:
        suffix = f" (after {exc_type.__name__})" if exc_type else ""
        Resource.log.append(f"release {self.name}{suffix}")
        return False                            # False: do not swallow the exception


@contextmanager
def precision(digits: int):
    """The same as a generator: the code before `yield` enters, the code after it exits."""
    context = decimal.getcontext()
    saved = context.prec
    context.prec = digits
    try:
        yield context
    finally:
        context.prec = saved


def section_07_errors() -> None:
    header("7. Errors and resources")
    for text in ("8080", "http", "99999"):
        try:
            port = parse_port(text)
        except ConfigError as error:
            cause = type(error.__cause__).__name__ if error.__cause__ else "no cause"
            print(f"{error} [{cause}]")
        else:
            print("port", port)                 # else: runs only when nothing was raised
        finally:
            pass                                # finally: runs in every case

    # "Easier to ask forgiveness than permission": try first, handle the failure afterwards.
    stock = {"bolt": 10}
    try:
        quantity = stock["nut"]
    except KeyError:
        quantity = 0
    try:
        result = 1 / quantity
    except (ZeroDivisionError, OverflowError) as error:     # several types, one handler
        result = f"{type(error).__name__}: {error}"
    print(quantity, result)

    with Resource("outer") as outer, Resource("inner"):     # released in reverse order
        Resource.log.append(f"use {outer.name}")
    with suppress(KeyError), Resource("failing"):           # suppress: an empty except clause
        raise KeyError("boom")
    print(Resource.log)

    with precision(5):
        short = Decimal(1) / Decimal(7)
    print(short, Decimal(1) / Decimal(7))

    # Exception groups: several unrelated failures travel together; `except*` selects by type.
    try:
        raise ExceptionGroup("batch failed", [ValueError("bad value"), KeyError("id"),
                                              ValueError("worse")])
    except* ValueError as group:
        print("value errors:", [str(e) for e in group.exceptions])
    except* KeyError as group:
        print("key errors:", [repr(e) for e in group.exceptions])

    # Notes add context without wrapping. `assert` checks invariants and is removed by `-O`.
    try:
        try:
            assert quantity > 0, "quantity must be positive"
        except AssertionError as error:
            error.add_note("raised while checking the order")
            raise                               # re-raise the current exception. C#: throw;
    except AssertionError as error:
        print(type(error).__name__, error, error.__notes__)


# ==================================================================================================
#  8. PATTERN MATCHING
# ==================================================================================================

@dataclass(frozen=True)
class Num:
    value: float


@dataclass(frozen=True)
class Add:
    left: Expr
    right: Expr


@dataclass(frozen=True)
class Mul:
    left: Expr
    right: Expr


@dataclass(frozen=True)
class Neg:
    operand: Expr


type Expr = Num | Add | Mul | Neg               # a "sum type" spelled as a union of classes


def evaluate(expr: Expr) -> float:
    match expr:                                 # C#: switch expression with patterns
        case Num(value):                        # a class pattern that captures the field
            return value
        case Add(left, right):
            return evaluate(left) + evaluate(right)
        case Mul(left=a, right=b):              # the keyword form
            return evaluate(a) * evaluate(b)
        case Neg(operand):
            return -evaluate(operand)
        case _:
            raise TypeError(f"not an expression: {expr!r}")


def simplify(expr: Expr) -> Expr:
    match expr:                                 # first simplify the children...
        case Add(left, right):
            expr = Add(simplify(left), simplify(right))
        case Mul(left, right):
            expr = Mul(simplify(left), simplify(right))
        case Neg(operand):
            expr = Neg(simplify(operand))
    match expr:                                 # ...then apply the rules to the result
        case Add(Num(0), other) | Add(other, Num(0)):       # alternatives bind the same names
            return other
        case Mul(Num(1), other) | Mul(other, Num(1)):
            return other
        case Mul(Num(0), _) | Mul(_, Num(0)):
            return Num(0)
        case Neg(Neg(inner)):
            return inner
        case Add(Num(a), Num(b)):
            return Num(a + b)
        case _:
            return expr


def classify(value: object) -> str:
    match value:
        case None:
            return "nothing"
        case True | False:                      # before int: bool is a subclass of int
            return "a bool"
        case int() | float() as number if number < 0:       # type test, capture and a guard
            return f"negative number {number}"
        case 0 | 1:
            return "a bit"
        case str() as text if not text:
            return "empty string"
        case [x, y]:                            # a sequence of exactly two items
            return f"pair {x} and {y}"
        case [first, *rest]:
            return f"sequence starting with {first} (+{len(rest)})"
        case {"type": "circle", "radius": radius}:          # a mapping; extra keys are fine
            return f"circle of radius {radius}"
        case {"type": kind, **others}:
            return f"shape '{kind}' with {sorted(others)}"
        case Vector(x=0, y=0):
            return "the origin"
        case Color.RED | Color.GREEN:           # dotted names are constants, not captures
            return "red or green"
        case _:
            return "something else"


def section_08_pattern_matching() -> None:
    header("8. Pattern matching")
    samples = [None, True, -2.5, 1, "", [1, 2], (1, 2, 3),
               {"type": "circle", "radius": 2, "color": "red"}, {"type": "box", "w": 1, "h": 2},
               Vector(0, 0), Color.GREEN, "text"]
    for sample in samples:
        print(f"{sample!r} -> {classify(sample)}")
    tree = Mul(Neg(Add(Num(4), Num(2))), Num(3))            # -(4 + 2) * 3
    messy = Add(Mul(Num(1), Num(7)), Mul(Num(0), Neg(Neg(Num(9)))))
    print(evaluate(tree), simplify(messy), evaluate(simplify(messy)))


# ==================================================================================================
#  9. STANDARD LIBRARY HIGHLIGHTS ("batteries included")
# ==================================================================================================

def section_09_standard_library() -> None:
    header("9. Standard library highlights")

    # collections: specialised containers.
    words = "the quick brown fox jumps over the lazy dog the end".split()
    by_length: defaultdict[int, list[str]] = defaultdict(list)     # missing keys get a default
    for word in words:
        by_length[len(word)].append(word)
    queue = deque([1, 2, 3], maxlen=3)          # O(1) at both ends; maxlen drops the far end
    queue.appendleft(0)
    print(Counter(words).most_common(2), by_length[5], queue)

    # pathlib: paths as objects. C#: Path, File, Directory.
    with tempfile.TemporaryDirectory() as folder:
        path = Path(folder) / "data" / "notes.txt"          # `/` joins path parts
        path.parent.mkdir(parents=True)
        path.write_text("first\nsecond\n", encoding="utf-8")
        with path.open("a", encoding="utf-8") as file:      # closed at the end of the block
            file.write("third\n")
        with path.open(encoding="utf-8") as file:
            lines = [line.rstrip() for line in file]        # a file is an iterator of lines
        print(path.name, path.suffix, path.stat().st_size, lines,
              [p.name for p in Path(folder).rglob("*.txt")])

    # json: dict, list, str, int, float, bool and None map one-to-one to JSON.
    document = {"name": "tour", "tags": ["py", "c#"], "stars": 4.5, "draft": False, "next": None}
    text = json.dumps(document, sort_keys=True)
    print(text, json.loads(text)["tags"][1])

    # re: regular expressions.
    log = "2026-11-17 ERROR disk full; 2026-11-18 WARN retry; 2026-11-19 ERROR timeout"
    pattern = re.compile(r"(?P<date>\d{4}-\d{2}-\d{2}) (?P<level>[A-Z]+) (?P<text>[^;]+)")
    errors = [m["date"] for m in pattern.finditer(log) if m["level"] == "ERROR"]
    print(errors, pattern.sub(r"\g<level>@\g<date>", log, count=1)[:16],
          re.split(r";\s*", log)[1], re.findall(r"\d+", "a1b22c333"))

    # datetime: dates, times and durations. C#: DateTimeOffset, TimeSpan.
    start = datetime(2026, 11, 17, 9, 30, tzinfo=timezone.utc)
    later = start + timedelta(days=45, hours=3)
    print(later.isoformat(), later.strftime("%d.%m.%Y %H:%M"), (later - start).days,
          date(2026, 12, 24).strftime("%A"), later > start)

    # operator, functools, statistics, random: small tools that replace small loops.
    people = [("Ann", 31), ("Bob", 25), ("Cid", 31)]
    print(sorted(people, key=operator.itemgetter(1, 0), reverse=True),
          functools.reduce(operator.mul, range(1, 6)), statistics.median(age for _, age in people),
          random.Random(42).choice(people)[0])


# ==================================================================================================
#  10. METAPROGRAMMING
# ==================================================================================================

class Positive:
    """A descriptor: an object that customises attribute access on ANOTHER class.
    Properties, methods, classmethod and staticmethod are all built on this protocol."""

    def __set_name__(self, owner: type, name: str) -> None:     # called when the owner is created
        self.private_name = "_" + name

    def __get__(self, instance: object, owner: type | None = None) -> Any:
        return self if instance is None else getattr(instance, self.private_name)

    def __set__(self, instance: object, value: float) -> None:
        if value <= 0:
            raise ValueError(f"{self.private_name[1:]} must be positive, got {value}")
        setattr(instance, self.private_name, value)


class Product:
    price = Positive()
    quantity = Positive()

    def __init__(self, price: float, quantity: int) -> None:
        self.price, self.quantity = price, quantity


class Recorder:
    """__getattr__ runs only when the normal lookup fails: dynamic proxies, lazy attributes."""

    def __init__(self) -> None:
        self.calls: list[str] = []

    def __getattr__(self, name: str) -> Callable[..., Self]:
        def method(*args: object) -> Self:
            self.calls.append(f"{name}{args}")
            return self
        return method


class Plugin:
    """__init_subclass__ runs for every subclass: a registry without a metaclass."""

    registry: dict[str, type] = {}

    def __init_subclass__(cls, /, key: str, **kwargs: Any) -> None:
        super().__init_subclass__(**kwargs)
        Plugin.registry[key] = cls


class CsvPlugin(Plugin, key="csv"): ...
class JsonPlugin(Plugin, key="json"): ...


class Singleton(type):
    """A metaclass: the class of a class. It controls how classes are built and called."""

    _instances: dict[type, object] = {}

    def __call__(cls, *args: Any, **kwargs: Any) -> Any:    # runs on `Settings()`
        if cls not in Singleton._instances:
            Singleton._instances[cls] = super().__call__(*args, **kwargs)
        return Singleton._instances[cls]


class Settings(metaclass=Singleton):
    def __init__(self) -> None:
        self.values: dict[str, str] = {}


def auto_repr(cls):
    """A class decorator: it receives the finished class and may change or replace it."""
    def __repr__(self) -> str:
        fields = ", ".join(f"{name}={value!r}" for name, value in vars(self).items())
        return f"{type(self).__name__}({fields})"

    cls.__repr__ = __repr__
    return cls


@auto_repr
class Planet:
    def __init__(self, name: str, moons: int) -> None:
        self.name, self.moons = name, moons


def section_10_metaprogramming() -> None:
    header("10. Metaprogramming")
    product = Product(9.5, 3)
    try:
        product.quantity = 0
    except ValueError as error:
        print(error, "|", product.price, product.quantity, vars(product))

    recorder = Recorder().connect("db").select("users", 10).close()
    print(recorder.calls)
    print(sorted(Plugin.registry), Settings() is Settings(), Planet("Mars", 2))

    # Introspection: everything can be examined at run time. C#: reflection.
    print(type(product).__name__, [name for name in dir(product) if not name.startswith("_")],
          getattr(product, "price"), hasattr(product, "weight"), callable(recorder.anything))
    signature = inspect.signature(describe)
    print(signature, [f"{p.name}:{p.kind.name}" for p in signature.parameters.values()])

    # Classes are created at run time; `type(name, bases, namespace)` is what `class` calls.
    Point3 = type("Point3", (), {"dims": 3, "norm": lambda self: "computed"})
    setattr(Point3, "origin", (0, 0, 0))        # "monkey patching"
    print(Point3.__name__, Point3().norm(), Point3.origin, Point3.dims)

    # exec / eval / ast: code is data. Powerful, and dangerous with untrusted input.
    namespace: dict[str, Any] = {}
    exec("def cube(n):\n    return n ** 3", namespace)
    print(eval("cube(3) + 1", namespace), ast.dump(ast.parse("1 + 2", mode="eval").body))


# ==================================================================================================
#  11. CONCURRENCY: threads, processes, asyncio
# ==================================================================================================

def cpu_task(n: int) -> int:
    return sum(i * i for i in range(n))


async def fetch(name: str, delay: float) -> str:
    await asyncio.sleep(delay)                  # a timer, not a blocked thread. C#: Task.Delay
    return f"{name} after {delay}s"


async def ticker(limit: int):
    """An asynchronous generator. C#: IAsyncEnumerable<T>."""
    for i in range(limit):
        await asyncio.sleep(0.001)
        yield i


async def async_main() -> None:
    # Calling an async function only creates a coroutine object: nothing runs until it is
    # awaited. (A C# Task is "hot" and starts at once.)
    coroutine = fetch("lazy", 0.01)
    print(type(coroutine).__name__, await coroutine)

    start = time.perf_counter()
    results = await asyncio.gather(fetch("a", 0.03), fetch("b", 0.02), fetch("c", 0.01))
    print(results, f"elapsed < 0.06s: {time.perf_counter() - start < 0.06}")   # C#: Task.WhenAll

    # Structured concurrency: a TaskGroup waits for all its tasks; if one fails, the others
    # are cancelled and the errors arrive together as an ExceptionGroup.
    async with asyncio.TaskGroup() as group:
        first = group.create_task(fetch("x", 0.02))
        second = group.create_task(fetch("y", 0.01))
    print(first.result(), "|", second.result())

    try:
        async with asyncio.timeout(0.01):       # C#: a CancellationTokenSource with a timeout
            await fetch("slow", 1)
    except TimeoutError:
        print("timed out")

    print([i async for i in ticker(4)])

    # Producer and consumer through a queue. C#: System.Threading.Channels.
    queue: asyncio.Queue[int | None] = asyncio.Queue(maxsize=2)

    async def producer() -> None:
        for i in range(5):
            await queue.put(i)                  # waits while the queue is full
        await queue.put(None)

    async def consumer() -> int:
        total = 0
        while (item := await queue.get()) is not None:
            total += item
        return total

    _, total = await asyncio.gather(producer(), consumer())
    # Blocking code goes to a worker thread so that the event loop stays responsive.
    print(total, await asyncio.to_thread(cpu_task, 1000))


def section_11_concurrency() -> None:
    header("11. Concurrency")

    # --- Threads: real OS threads, but with the GIL only one of them runs Python bytecode at
    # a time. Good for blocking I/O, useless for CPU-bound work. ---
    counter = 0
    lock = threading.Lock()

    def work() -> None:
        nonlocal counter
        for _ in range(10_000):
            with lock:                          # C#: lock (sync) { ... }
                counter += 1

    threads = [threading.Thread(target=work) for _ in range(4)]
    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()
    print(counter, "| GIL enabled:", sys._is_gil_enabled())

    # --- Pools and futures. C#: Task.Run + Task.WhenAll ---
    with ThreadPoolExecutor(max_workers=4) as pool:
        print(list(pool.map(len, ["a", "bb", "ccc"])), pool.submit(pow, 2, 10).result())
    # Processes sidestep the GIL: arguments and results are pickled and sent between them.
    # The workers import this file again, hence the `if __name__ == "__main__"` guard below.
    with ProcessPoolExecutor(max_workers=2) as pool:
        print(list(pool.map(cpu_task, [10, 100, 1000])))

    # --- asyncio: cooperative concurrency on one thread. C#: async/await with an explicit
    # event loop ---
    asyncio.run(async_main())


# ==================================================================================================
#  12. THE NEWEST: 3.12 - 3.14
# ==================================================================================================

def section_12_newest() -> None:
    header("12. The newest: 3.12 - 3.14")

    # Template strings (3.14): `t"..."` builds a Template object instead of a str, so a library
    # can treat the literal parts and the interpolated values differently (safe SQL, HTML,
    # logging). C#: FormattableString and interpolated string handlers.
    user, limit = "ann'; DROP TABLE users; --", 10
    template = t"SELECT * FROM users WHERE name = {user} LIMIT {limit}"
    sql = "".join(part if isinstance(part, str) else "?" for part in template)
    print(type(template).__name__, template.strings,
          [item.expression for item in template.interpolations])
    print(sql, template.values)

    # Deferred evaluation of annotations (3.14): hints are evaluated on first use, so forward
    # references need no quotes (see Vector.__add__ in section 4) and cost nothing at import.
    def link(node: Node) -> Node: ...

    class Node: ...

    print(annotationlib.get_annotations(link, format=annotationlib.Format.STRING),
          annotationlib.get_annotations(link)["node"] is Node)

    # `except` with several types no longer needs parentheses (3.14).
    try:
        int("x")
    except ValueError, TypeError:
        print("caught without parentheses")

    # 3.12: f-strings may reuse the outer quotes and nest freely.
    print(f"{", ".join(f"{n:02}" for n in range(3))}")

    # 3.13: copy.replace() for dataclasses and named tuples; warnings.deprecated marks obsolete
    # API (C#: [Obsolete]); type parameters may have defaults.
    print(copy.replace(Version(1, 2, 3), minor=9),
          copy.replace(Coordinates(1.0, 2.0), longitude=5.0))

    @warnings.deprecated("use new_api() instead")
    def old_api() -> int:
        return 1

    with warnings.catch_warnings(record=True) as caught:
        warnings.simplefilter("always")
        old_api()
    print(caught[0].category.__name__, caught[0].message)

    class Box[T = int]:
        def __init__(self, item: T) -> None:
            self.item = item

    print(Box.__type_params__[0].__default__, sys.version_info[:2], sys.implementation.name)

    # Also new and not shown here: the free-threaded build without the GIL (a separate
    # executable, officially supported since 3.14), sub-interpreters in the standard library
    # (concurrent.interpreters), and a JIT compiler that is still experimental.


# ==================================================================================================
#  ENTRY POINT
# ==================================================================================================

def main() -> None:
    sections = [
        section_01_basics, section_02_collections, section_03_functions, section_04_classes,
        section_05_typing, section_06_iterators, section_07_errors, section_08_pattern_matching,
        section_09_standard_library, section_10_metaprogramming, section_11_concurrency,
        section_12_newest,
    ]
    for section in sections:
        section()


# True only when the file is run as a script, not when it is imported as a module.
# C#: the closest thing is `static void Main`.
if __name__ == "__main__":
    main()
