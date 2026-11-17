// =================================================================================================
//  JAVASCRIPT FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
//
//  Run:   node javascript_tour.mjs          (Node.js 24 or newer)
//
//  Verified with Node.js 26.13 and 24 (the two current LTS lines). Older versions reject the
//  file because of the `using` declarations in section 7. A few of the newest library
//  features (Temporal, Math.sumPrecise ...) are detected at run time and skipped if absent.
//
//  The language is JavaScript itself (ECMAScript 2026) on the Node.js runtime; nothing here
//  needs a browser. TypeScript, which adds a C#-like static type system on top, is a separate
//  language and is not covered.
//
//  How to read. Each section is a function `sectionNN...`; `main()` at the end calls them in
//  order. A "C#:" note shows the closest C# counterpart. Commented-out lines show the error
//  they would raise.
//
//  The main differences from C# to keep in mind from the first line:
//
//   1. Dynamic and weak typing. Variables have no types, values do, and operators convert
//      their operands silently (`'3' * '4'` is 12). Mistakes surface at run time.
//   2. One number type: a 64-bit float. There are no int, long or decimal (only BigInt).
//   3. Objects are open dictionaries of properties, and inheritance goes through prototype
//      chains. `class` is syntax on top of that; there are no interfaces and no overloading.
//   4. `this` depends on how a function is CALLED, not on where it is defined.
//   5. Two kinds of "nothing": `undefined` (never set) and `null` (set to nothing).
//   6. One thread and an event loop. Nothing blocks: I/O is asynchronous (callbacks,
//      promises, async/await), and parallelism means separate workers that pass messages.
//   7. Code is organised in modules (files), not in namespaces and assemblies.
//
//  Contents:
//    1. Basics: values, types, coercion, control flow     8. Asynchronous code
//    2. Functions and closures                            9. Modules and the runtime
//    3. Objects                                          10. Metaprogramming
//    4. Arrays and collections                           11. Text, regex, Intl, dates, bytes
//    5. Prototypes and classes                           12. Threads: workers, shared memory
//    6. Iterators and generators                         13. The newest: ES2023 - ES2026
//    7. Errors and resources
// =================================================================================================

// Static imports. C#: using. `node:` marks modules built into the runtime.
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { setTimeout as sleep } from 'node:timers/promises';
import { fileURLToPath } from 'node:url';
import { inspect } from 'node:util';
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';

const header = (title) => console.log(`\n=== ${title} ===`);

// Prints every value on one line; strings as they are, everything else in literal notation.
const oneLine = { depth: 5, breakLength: Infinity, compact: true };
const format = (value) => (typeof value === 'string' ? value : inspect(value, oneLine));
const show = (...values) => console.log(...values.map(format));

// =================================================================================================
//  1. BASICS: values, types, coercion, control flow
// =================================================================================================

function section01Basics() {
  header('1. Basics');

  // --- Variables: `let` can be reassigned, `const` cannot; `var` is the legacy form ---
  let count = 1;
  const limit = 10;
  count += limit;
  // limit = 11;        // TypeError: Assignment to constant variable.

  // Types belong to values, not to variables. There are eight of them:
  show(typeof 42, typeof 4.2, typeof 10n, typeof 'text', typeof true, typeof undefined,
    typeof Symbol('id'), typeof {}, '|', typeof null, typeof [], typeof (() => 1));
  // (`typeof null === 'object'` is a bug from 1995 kept for compatibility; arrays are objects
  // and functions are callable objects.)

  // --- Numbers: ONE numeric type, a 64-bit float. C#: double ---
  show(7 / 2, Math.trunc(7 / 2), 7 % 3, 2 ** 10, 0.1 + 0.2 === 0.3, Number.MAX_SAFE_INTEGER,
    2 ** 53 === 2 ** 53 + 1); // integers are exact only up to 2^53
  show(1 / 0, -1 / 0, 0 / 0, Number.isNaN(NaN), NaN === NaN, Number.parseInt('42px'),
    Number('42px'), +'3.5', (255).toString(16), 1_000_000, count);
  // BigInt: integers of any size; they never mix with numbers implicitly.
  show(2n ** 100n, 7n / 2n, BigInt(Number.MAX_SAFE_INTEGER) + 2n);
  // 1n + 1             // TypeError: Cannot mix BigInt and other types

  // --- Strings: immutable UTF-16, as in C#. Template literals interpolate ---
  const name = 'World';
  const greeting = `Hello, ${name}!`; // C#: $"Hello, {name}!"
  show(greeting, greeting.length, greeting.toUpperCase(), greeting.slice(7, 12), greeting.at(-1),
    greeting.includes('World'), greeting.split(', '));
  const multi = `line one
line two`; // a template literal may span lines
  show(multi.split('\n'), 'ab'.repeat(3), '5'.padStart(3, '0'), ' x '.trim(),
    'a-b-c'.replaceAll('-', '+'), 'tour'[0], 'b' > 'a');
  const mixed = 'aß😀'; // length counts UTF-16 units; iteration goes by code points
  show(mixed.length, [...mixed].length, mixed.codePointAt(2).toString(16));

  // --- undefined and null: two "nothing" values ---
  let nothing; // declared, never assigned: undefined
  const user = { name: 'Ann', address: null };
  show(nothing, user.age, user.address, user.address?.city, user.age ?? 'unknown');
  // user.address.city  // TypeError: Cannot read properties of null (reading 'city')

  // --- Equality and coercion ---
  // `==` converts its operands before comparing; `===` never does. Always use `===`.
  show(1 == '1', 1 === '1', 0 == '', null == undefined, null === undefined, [] == false,
    Object.is(NaN, NaN));
  // `+` concatenates if either side is a string; the other operators convert to numbers.
  show([1 + '2', '3' * '4', 1 + 2 + '3', '3' - 1, [] + [], true + 1, [1, 2] + '']);
  // Falsy values: false, 0, -0, 0n, '', null, undefined, NaN. Everything else is truthy,
  // including [] and {} and the string '0'.
  show([0, '', null, undefined, NaN, [], {}, '0'].map(Boolean));
  // `||` yields the first truthy operand, `&&` the first falsy one, `??` the first operand
  // that is neither null nor undefined (the C# meaning).
  show([0 || 'default', 0 ?? 'default', '' && 'never', 'a' && 'b']);

  // --- Control flow ---
  let sum = 0;
  for (let i = 0; i < 5; i++) sum += i;
  for (const value of [10, 20, 30]) sum += value; // for...of: the values. C#: foreach
  const keys = [];
  for (const key in { a: 1, b: 2 }) keys.push(key); // for...in: the property NAMES
  const kind = (letter) => {
    switch (letter) { // compares with ===; falls through without a break
      case 'a':
      case 'e':
        return 'vowel';
      default:
        return 'consonant';
    }
  };
  outer: for (let row = 0; row < 3; row++) {
    for (let col = 0; col < 3; col++) {
      if (col > row) continue outer; // a label lets break/continue reach an outer loop
      sum += 100;
    }
  }
  show(sum, keys, kind('e'), kind('z'), sum % 2 === 0 ? 'even' : 'odd');
}

// =================================================================================================
//  2. FUNCTIONS AND CLOSURES
// =================================================================================================

function section02Functions() {
  header('2. Functions');

  // Three ways to make a function. Declarations are hoisted: usable before their line.
  show(declared(2));
  function declared(x) {
    return x * 2;
  }
  const expression = function (x) {
    return x * 3;
  };
  const arrow = (x) => x * 4; // C#: x => x * 4
  show(expression(2), arrow(2), typeof arrow, arrow.name, declared.length);

  // No overloading, and no checks of argument count or type: missing arguments are
  // undefined, extra ones are ignored.
  const describe = (name, greeting = 'Hello', ...rest) =>
    `${greeting}, ${name}${rest.length > 0 ? ` (+${rest.length})` : ''}`;
  show(describe('Ann'), '|', describe('Bob', 'Hi'), '|', describe('Cid', undefined, 1, 2), '|',
    describe());
  show(Math.max(...[3, 1, 2])); // spread: an array as separate arguments
  // "Named arguments" are an options object plus destructuring.
  const connect = ({ host = 'localhost', port = 5432, ssl = false } = {}) =>
    `${ssl ? 'https' : 'http'}://${host}:${port}`;
  show(connect(), connect({ port: 8080, ssl: true }));

  // Closures capture variables, as in C#.
  const makeCounter = () => {
    let value = 0;
    return { next: () => ++value, reset: () => (value = 0) };
  };
  const counter = makeCounter();
  counter.next();
  counter.next();
  show(counter.next());
  // `let` in a for loop makes a fresh binding per iteration; `var` shares one.
  const withLet = [];
  const withVar = [];
  for (let i = 0; i < 3; i++) withLet.push(() => i);
  for (var j = 0; j < 3; j++) withVar.push(() => j);
  show(withLet.map((f) => f()), withVar.map((f) => f()));

  // `this` is decided by HOW a function is called, not by where it is written.
  const account = {
    owner: 'Ann',
    regular() {
      return this?.owner; // `this` is the object before the dot
    },
    arrow: () => typeof this, // an arrow has no `this` of its own: it sees the outer one
  };
  const detached = account.regular; // the function, without its object
  show(account.regular(), detached(), account.arrow(), detached.call({ owner: 'Bob' }),
    detached.bind({ owner: 'Cid' })());

  // Functions are values: pass them, return them, store them.
  const compose = (...fns) => (x) => fns.reduceRight((acc, fn) => fn(acc), x);
  const curry = (a) => (b) => (c) => a + b + c;
  const memoize = (fn, cache = new Map()) => (n) => {
    if (!cache.has(n)) cache.set(n, fn(n));
    return cache.get(n);
  };
  const fib = memoize((n) => (n < 2 ? n : fib(n - 1) + fib(n - 2)));
  show(compose((x) => x + 1, (x) => x * 2)(5), curry(1)(2)(3), fib(70));

  // A tagged template: the function receives the literal parts and the values separately.
  // C#: FormattableString.
  const sql = (strings, ...values) => ({ text: strings.join('?'), values });
  const id = 7;
  show(sql`SELECT * FROM users WHERE id = ${id} AND active = ${true}`);
}

// =================================================================================================
//  3. OBJECTS
// =================================================================================================

function section03Objects() {
  header('3. Objects');

  // An object is a dictionary of properties, and the literal is the usual way to make one.
  // C#: an anonymous type crossed with Dictionary<string, object>.
  const x = 1;
  const key = 'dynamic';
  const point = {
    x, // shorthand for x: x
    y: 2,
    [`${key}Key`]: true, // a computed property name
    'needs quotes': 0,
    describe() {
      return `(${this.x}, ${this.y})`;
    },
  };
  point.z = 3; // properties can be added...
  delete point['needs quotes']; // ...and removed at any time
  show(point, point.describe(), 'z' in point, Object.keys(point), point.missing);

  // Destructuring and spread. C#: deconstruction and `with` expressions.
  const { x: px, y: py = 0, w = 'default', ...others } = point;
  const moved = { ...point, x: 100 }; // a shallow copy with one property replaced
  const [first, , third = 'none', ...tail] = [1, 2, 3, 4, 5];
  let a = 1;
  let b = 2;
  [a, b] = [b, a]; // a swap
  show(px, py, w, Object.keys(others), moved.x, point.x, first, third, tail, a, b);

  // Objects are references: assignment shares them, and copies are explicit.
  const original = { name: 'Ann', tags: ['a'], when: new Date(0) };
  const alias = original;
  const shallow = { ...original };
  const deep = structuredClone(original); // a real deep copy (Date, Map, cycles ...)
  alias.name = 'Bob';
  shallow.tags.push('b');
  show(original.name, original.tags, deep.tags, deep.when instanceof Date, { a: 1 } === { a: 1 });

  // Getters, setters and property descriptors. C#: properties.
  const temperature = {
    celsius: 20,
    get fahrenheit() {
      return (this.celsius * 9) / 5 + 32;
    },
    set fahrenheit(value) {
      this.celsius = ((value - 32) * 5) / 9;
    },
  };
  temperature.fahrenheit = 212;
  Object.defineProperty(temperature, 'id', { value: 42, writable: false, enumerable: false });
  const frozen = Object.freeze({ nested: { open: true } }); // shallow: `nested` stays mutable
  frozen.nested.open = false;
  show(temperature.celsius, temperature.fahrenheit, temperature.id, Object.keys(temperature),
    Object.isFrozen(frozen), frozen.nested.open);
  // temperature.id = 1; // TypeError: Cannot assign to read only property 'id'

  // Enumerating and transforming.
  const prices = { apple: 1.2, pear: 0.8, kiwi: 2.5 };
  const doubled = Object.fromEntries(Object.entries(prices).map(([name, p]) => [name, p * 2]));
  show(Object.entries(prices), doubled, Object.values(prices).reduce((s, p) => s + p).toFixed(1));

  // JSON is (almost) a subset of the literal syntax.
  const data = { name: 'tour', tags: ['js'], skipped: undefined, when: new Date(0) };
  const json = JSON.stringify(data); // undefined properties are left out
  const parsed = JSON.parse(json, (k, v) => (k === 'when' ? new Date(v) : v)); // a "reviver"
  show(json, parsed.when.getUTCFullYear(), JSON.stringify({ a: [1, 2] }, null, 1).length);

  // Symbols: unique property keys that can never collide with string keys.
  const secret = Symbol('secret');
  const holder = { visible: 1, [secret]: 2 };
  show(Object.keys(holder), holder[secret], secret.toString(),
    Symbol.for('app.id') === Symbol.for('app.id'));
}

// =================================================================================================
//  4. ARRAYS AND COLLECTIONS
// =================================================================================================

function section04Collections() {
  header('4. Arrays and collections');

  // An array is a resizable list of anything. C#: List<object>.
  const numbers = [5, 3, 8, 1];
  numbers.push(9); // add at the end; pop() removes from the end
  numbers.unshift(7); // add at the front; shift() removes from the front
  show(numbers, numbers.length, numbers.at(-1), numbers.indexOf(8), numbers.includes(4),
    numbers.slice(1, 3), numbers[99]); // reading past the end gives undefined, not an error

  // The functional core. C#: LINQ Select / Where / Aggregate.
  const squares = numbers.map((n) => n * n);
  const even = numbers.filter((n) => n % 2 === 0);
  const total = numbers.reduce((sum, n) => sum + n, 0);
  show(squares, even, total, numbers.find((n) => n > 6), numbers.findLast((n) => n > 6),
    numbers.some((n) => n > 8), numbers.every((n) => n > 0));
  show([[1, 2], [3, [4]]].flat(), ['a b', 'c'].flatMap((s) => s.split(' ')),
    Array.from({ length: 4 }, (_, i) => i * 2), [...'abc'].join('-'));

  // sort() works IN PLACE and, without a comparer, compares the elements AS STRINGS.
  show([10, 9, 1].sort(), [10, 9, 1].sort((p, q) => p - q));
  // The copying variants leave the original alone.
  show(numbers.toSorted((p, q) => p - q), numbers.toReversed(), numbers.with(0, 70),
    numbers.toSpliced(1, 2), numbers);
  const people = [
    { name: 'Ann', age: 31 },
    { name: 'Bob', age: 25 },
    { name: 'Cid', age: 31 },
  ];
  const byAgeThenName = people.toSorted((p, q) => q.age - p.age || p.name.localeCompare(q.name));
  const groups = Object.groupBy(people, (p) => (p.age > 30 ? 'senior' : 'junior')); // C#: GroupBy
  show(byAgeThenName.map((p) => p.name), Object.keys(groups), groups.senior.map((p) => p.name));

  // Map: a real dictionary with keys of any type, in insertion order. C#: Dictionary.
  const stock = new Map([['bolt', 10], ['nut', 5]]);
  stock.set('screw', 25).set('bolt', stock.get('bolt') + 5);
  const byObject = new Map([[people[0], 'first']]); // object keys compare by identity
  show(stock, stock.get('missing'), stock.has('nut'), stock.size, [...stock.keys()],
    byObject.get(people[0]));

  // Set: unique values, with set algebra. C#: HashSet<T>.
  const odd = new Set([1, 3, 5, 7, 9]);
  const prime = new Set([2, 3, 5, 7]);
  show(odd.intersection(prime), odd.union(prime), odd.difference(prime),
    new Set([3, 5]).isSubsetOf(odd), [...new Set('mississippi')].join(''));

  // WeakMap: data attached to an object without keeping it alive. C#: ConditionalWeakTable.
  const metadata = new WeakMap();
  metadata.set(people[0], { visits: 1 });
  show(metadata.get(people[0]), metadata.has(people[1]));

  // Typed arrays: real fixed-size numeric arrays over raw memory. C#: byte[], double[].
  const bytes = new Uint8Array([250, 251, 252]);
  bytes[0] += 10; // wraps modulo 256
  show(bytes, new Float64Array(2).fill(1.5), new Uint8Array(new Uint16Array([0x0102]).buffer));
}

// =================================================================================================
//  5. PROTOTYPES AND CLASSES
// =================================================================================================

function section05Classes() {
  header('5. Prototypes and classes');

  // Underneath `class` lies prototypal inheritance: every object links to another object,
  // its prototype, and a property lookup walks that chain.
  const animal = {
    legs: 4,
    describe() {
      return `${this.name} has ${this.legs} legs`;
    },
  };
  const dog = Object.create(animal); // an object whose prototype is `animal`
  dog.name = 'Rex';
  const bird = Object.create(animal, { name: { value: 'Tweety' }, legs: { value: 2 } });
  show(dog.describe(), '|', bird.describe(), '|', Object.getPrototypeOf(dog) === animal,
    Object.hasOwn(dog, 'legs'), 'legs' in dog);

  // A class is syntax over the same mechanism.
  class Vector {
    static #created = 0; // a private static field
    static ZERO = new Vector(0, 0);
    #secret = 'hidden'; // `#` makes a member really private (not a convention)
    x; // public fields
    y;

    constructor(x, y) {
      this.x = x;
      this.y = y;
      Vector.#created++;
    }

    get length() { // C#: a get-only property
      return Math.hypot(this.x, this.y);
    }

    plus(other) { // there is no operator overloading
      return new Vector(this.x + other.x, this.y + other.y);
    }

    static get created() {
      return Vector.#created;
    }

    static fromArray([x, y]) {
      return new Vector(x, y);
    }

    isVector(other) {
      return #secret in other; // a "brand check"
    }

    toString() {
      return `Vector(${this.x}, ${this.y})`;
    }

    toJSON() { // used by JSON.stringify
      return [this.x, this.y];
    }

    *[Symbol.iterator]() { // makes instances iterable and destructurable
      yield this.x;
      yield this.y;
    }
  }
  const v = new Vector(3, 4);
  const [vx, vy] = v;
  show(`${v}`, v.length, `${v.plus(Vector.fromArray([1, 1]))}`, JSON.stringify(v), vx + vy,
    Vector.created, v.isVector({}), typeof Vector, Object.keys(v));
  // v.#secret          // SyntaxError: a private field is not reachable outside its class

  // Inheritance.
  class Shape {
    constructor(name) {
      this.name = name;
    }

    get area() { // there is no `abstract` keyword
      throw new Error('not implemented');
    }

    describe() {
      return `${this.name} with area ${this.area.toFixed(2)}`;
    }
  }
  class Circle extends Shape {
    constructor(radius) {
      super('circle'); // must run before `this` is touched
      this.radius = radius;
    }

    get area() {
      return Math.PI * this.radius ** 2;
    }
  }
  class Square extends Shape {
    constructor(side) {
      super('square');
      this.side = side;
    }

    get area() {
      return this.side ** 2;
    }

    describe() {
      return `a perfect ${super.describe()}`;
    }
  }
  const shapes = [new Circle(1), new Square(2)];
  show(shapes.map((s) => s.describe()), shapes[0] instanceof Shape,
    Object.getPrototypeOf(Circle) === Shape, shapes[1].constructor.name);

  // Duck typing: no interfaces; anything with the right members will do.
  const blob = { name: 'blob', area: 9.5, describe: Shape.prototype.describe };
  show(blob.describe());

  // A mixin: a function that takes a class and returns a subclass of it.
  const Serializable = (Base) =>
    class extends Base {
      serialize() {
        return JSON.stringify(this);
      }
    };
  class Tagged extends Serializable(Square) {
    static registry;
    static { // a static initialization block
      Tagged.registry = new Map();
    }

    tag = 'special';
  }
  show(new Tagged(3).serialize(), new Tagged(1) instanceof Square, Tagged.registry.size);

  // Classes stay open at run time ("monkey patching").
  Square.prototype.perimeter = function () {
    return this.side * 4;
  };
  show(shapes[1].perimeter());
}

// =================================================================================================
//  6. ITERATORS AND GENERATORS
// =================================================================================================

function section06Iterators() {
  header('6. Iterators and generators');

  // The iteration protocol by hand: [Symbol.iterator]() returns an object with next().
  // C#: IEnumerable / IEnumerator.
  const countdown = (from) => ({
    [Symbol.iterator]() {
      let current = from;
      return {
        next: () => (current > 0 ? { value: current--, done: false } : { done: true }),
      };
    },
  });
  show([...countdown(3)], Math.max(...countdown(5)), Array.from(countdown(2), (n) => n * 10));

  // A generator function does the same with `yield`. C#: yield return.
  function* fibonacci() {
    let [a, b] = [0, 1];
    while (true) { // infinite, but lazy
      yield a;
      [a, b] = [b, a + b];
    }
  }
  function* flatten(nested) {
    for (const item of nested) {
      if (Array.isArray(item)) yield* flatten(item); // delegate to another generator
      else yield item;
    }
  }
  // Iterator helpers: lazy map / filter / take / drop directly on iterators. C#: LINQ.
  show(fibonacci().filter((n) => n % 2 === 0).map((n) => n * 10).take(5).toArray(),
    fibonacci().drop(10).take(3).toArray(), [...flatten([1, [2, [3, 4]], 5])]);
  show(Iterator.from(countdown(4)).reduce((sum, n) => sum + n, 0),
    new Map([['a', 1], ['b', 2]]).entries().map(([k, n]) => k + n).toArray(),
    fibonacci().some((n) => n > 100));

  // Two-way traffic: next(value) becomes the result of the suspended `yield`.
  function* runningAverage() {
    let total = 0;
    let count = 0;
    let average;
    while (true) {
      const value = yield average;
      total += value;
      average = total / ++count;
    }
  }
  const averager = runningAverage();
  averager.next(); // run to the first yield
  show([10, 20, 60].map((n) => averager.next(n).value));

  // Built-in iterables: arrays, strings, Map, Set, typed arrays.
  const entries = [];
  for (const [index, letter] of ['x', 'y'].entries()) entries.push(`${index}:${letter}`);
  show(entries, [...new Set([1, 1, 2])], Object.fromEntries(new Map([['k', 'v']])));
}

// =================================================================================================
//  7. ERRORS AND RESOURCES
// =================================================================================================

class ConfigError extends Error {
  constructor(key, reason, options) {
    super(`config key '${key}': ${reason}`, options); // options.cause. C#: InnerException
    this.name = 'ConfigError';
    this.key = key;
  }
}

function parsePort(text) {
  const port = Number(text);
  if (!Number.isInteger(port)) {
    throw new ConfigError('port', 'not a number', { cause: new TypeError(`bad input: ${text}`) });
  }
  if (port < 1 || port > 65535) throw new ConfigError('port', `${port} is out of range`);
  return port;
}

function section07Errors() {
  header('7. Errors and resources');

  for (const text of ['8080', 'http', '99999']) {
    try {
      show(`port ${parsePort(text)}`);
    } catch (error) {
      // There are no typed catch clauses: test the error and rethrow what is not yours.
      if (!(error instanceof ConfigError)) throw error;
      show(`${error.message} [${error.cause?.name ?? 'no cause'}]`);
    } finally {
      // runs in every case
    }
  }

  // Anything can be thrown, which is why careful code checks `instanceof Error`.
  try {
    throw { code: 42 };
  } catch (thrown) {
    show(thrown instanceof Error, thrown.code);
  }
  // Mistakes that C# would refuse to compile show up at run time.
  const attempts = [
    () => undefined.property,
    () => notDeclaredAnywhere,
    () => null(),
    () => new Array(-1),
    () => JSON.parse('{oops}'),
    () => 1n + 1,
  ];
  const nameOfError = (attempt) => {
    try {
      attempt();
      return 'no error';
    } catch (error) {
      return error.name;
    }
  };
  show(attempts.map(nameOfError));

  // Explicit resource management: `using` disposes at the end of the block, in reverse
  // order. C#: using declarations and IDisposable.
  const log = [];
  const resource = (name) => ({ name, [Symbol.dispose]: () => log.push(`release ${name}`) });
  try {
    using outer = resource('outer');
    using inner = resource('inner');
    log.push(`use ${outer.name} and ${inner.name}`);
    throw new Error('boom');
  } catch (error) {
    log.push(`caught ${error.message}`);
  }
  {
    using stack = new DisposableStack(); // gathers cleanup actions
    stack.defer(() => log.push('deferred cleanup'));
    stack.adopt({ id: 1 }, (handle) => log.push(`closed handle ${handle.id}`));
  }
  show(log);

  // AggregateError carries several failures (see Promise.any in the next section).
  const aggregate = new AggregateError([new RangeError('a'), new TypeError('b')], 'two problems');
  show(aggregate.message, aggregate.errors.map((e) => e.name), Error.isError(aggregate));
}

// =================================================================================================
//  8. ASYNCHRONOUS CODE
// =================================================================================================

async function section08Async() {
  header('8. Asynchronous code');

  // JavaScript runs on ONE thread with an event loop. Nothing blocks: a slow operation
  // returns a promise, and the loop runs the continuation later. Callbacks of settled
  // promises ("microtasks") run before timers and I/O ("macrotasks").
  const order = [];
  setTimeout(() => order.push('4: timer'), 0);
  queueMicrotask(() => order.push('2: microtask'));
  Promise.resolve().then(() => order.push('3: promise callback'));
  order.push('1: synchronous code');
  await sleep(5);
  show(order);

  // A Promise is a value that arrives later. C#: Task<T> — always "hot", never cancellable.
  const delay = (ms, value) => new Promise((resolve) => setTimeout(() => resolve(value), ms));
  const failing = (ms, message) =>
    new Promise((_, reject) => setTimeout(() => reject(new Error(message)), ms));
  const chained = await delay(5, 2)
    .then((n) => n * 21) // C#: ContinueWith
    .then((n) => {
      if (n > 40) throw new RangeError('too big');
      return n;
    })
    .catch((error) => `recovered from a ${error.name}`)
    .finally(() => order.push('5: finally'));
  show(chained, order.length);

  // async / await is syntax over promises, as in C#.
  const fetchUser = async (id) => {
    await delay(10);
    if (id < 0) throw new Error('no such user');
    return { id, name: `user${id}` };
  };
  try {
    show(await fetchUser(1));
    await fetchUser(-1);
  } catch (error) {
    show(`caught: ${error.message}`);
  }

  // Combinators. C#: Task.WhenAll / Task.WhenAny.
  const started = performance.now();
  const all = await Promise.all([delay(30, 'a'), delay(20, 'b'), delay(10, 'c')]);
  const concurrent = performance.now() - started < 55; // about 30 ms, not 60
  const settled = await Promise.allSettled([delay(5, 'ok'), failing(5, 'bad')]);
  const fastest = await Promise.race([delay(20, 'slow'), delay(5, 'fast')]);
  const firstSuccess = await Promise.any([failing(5, 'x'), delay(10, 'winner')]);
  show(all, concurrent, settled.map((r) => r.status), fastest, firstSuccess);

  // A promise settled from outside (C#: TaskCompletionSource), and Promise.try, which turns
  // a synchronous result or exception into a promise.
  const { promise, resolve } = Promise.withResolvers();
  setTimeout(() => resolve('resolved from outside'), 5);
  show(await promise, '|', await Promise.try(() => 'wrapped by Promise.try'));

  // Cancellation is cooperative, through AbortSignal. C#: CancellationToken.
  const controller = new AbortController();
  setTimeout(() => controller.abort(), 5);
  try {
    await sleep(1000, 'finished', { signal: controller.signal });
  } catch (error) {
    show(`cancelled: ${error.name} (${error.code})`);
  }
  try {
    await sleep(1000, null, { signal: AbortSignal.timeout(10) });
  } catch (error) {
    show(`timed out: ${error.name}, cause ${error.cause?.name}`);
  }

  // Async generators and `for await`. C#: IAsyncEnumerable<T> and await foreach.
  async function* ticker(limit) {
    for (let i = 0; i < limit; i++) {
      await delay(1);
      yield i;
    }
  }
  const ticks = [];
  for await (const tick of ticker(4)) ticks.push(tick);
  show(ticks, await Array.fromAsync(ticker(3), (n) => n * 10));

  // An `await` inside a loop runs the operations one after another; mapping to promises
  // first and awaiting them together runs them concurrently.
  const ids = [1, 2, 3];
  const sequential = [];
  for (const id of ids) sequential.push((await fetchUser(id)).name);
  const together = (await Promise.all(ids.map(fetchUser))).map((user) => user.name);
  show(sequential, together);
  // A rejected promise that nobody handles terminates the process, so every promise needs
  // an `await` or a `.catch`.
}

// =================================================================================================
//  9. MODULES AND THE RUNTIME
// =================================================================================================

async function section09Modules() {
  header('9. Modules and the runtime');

  // This file is an ES module (.mjs): its own scope, strict mode, `import` / `export`,
  // `await` at the top level. C#: a file-scoped namespace plus `using`. There are no
  // assemblies: a package is a folder with a package.json, installed by npm.
  //   export const pi = 3.14;  export default function main() {}   // in lib.mjs
  //   import main, { pi } from './lib.mjs';                         // somewhere else
  //   const fs = require('node:fs');                                // CommonJS, the older system
  const thisFile = fileURLToPath(import.meta.url);
  show(path.basename(thisFile), import.meta.url.startsWith('file://'), typeof import.meta.dirname);

  // A dynamic import loads a module at run time and returns a promise of its exports.
  const os = await import('node:os');
  const { default: assert } = await import('node:assert/strict');
  assert.equal(1 + 1, 2);
  show(os.cpus().length > 0, Object.keys(await import('node:path')).includes('join'));

  // Files, through promises. C#: File.WriteAllTextAsync / File.ReadAllLinesAsync.
  const folder = await mkdtemp(path.join(tmpdir(), 'js-tour-'));
  const file = path.join(folder, 'notes.txt');
  try {
    await writeFile(file, 'first\nsecond\n', 'utf8');
    await writeFile(file, 'third\n', { flag: 'a' });
    const lines = (await readFile(file, 'utf8')).trimEnd().split('\n');
    show(path.basename(file), path.extname(file), lines);
    await readFile(path.join(folder, 'missing.txt'));
  } catch (error) {
    show(`${error.code} from ${error.syscall}`); // system errors carry a `code`
  } finally {
    await rm(folder, { recursive: true });
  }

  // The global object and the process.
  show(typeof globalThis.setTimeout, process.argv.length >= 2,
    Number(process.versions.node.split('.')[0]) >= 24, typeof process.env.PATH);
}

// =================================================================================================
//  10. METAPROGRAMMING
// =================================================================================================

function section10Metaprogramming() {
  header('10. Metaprogramming');

  // A Proxy intercepts the basic operations on an object. C#: DispatchProxy, DynamicObject.
  const validated = new Proxy({ price: 1 }, {
    set(target, property, value) {
      if (property === 'price' && !(value > 0)) {
        throw new RangeError(`price must be positive, got ${value}`);
      }
      return Reflect.set(target, property, value);
    },
    get: (target, property) =>
      property in target ? Reflect.get(target, property) : `<no ${String(property)}>`,
  });
  validated.price = 9.5;
  let rejected;
  try {
    validated.price = 0;
  } catch (error) {
    rejected = error.message;
  }
  show(validated.price, validated.weight, '|', rejected);

  // A recording proxy: every method call is captured, whatever its name.
  const calls = [];
  const recorder = new Proxy({}, {
    get: (_, name) => (...args) => {
      calls.push(`${String(name)}(${args.join(', ')})`);
      return recorder;
    },
  });
  recorder.connect('db').select('users', 10).close();
  show(calls);

  // Reflection: objects can be examined and reshaped freely.
  class Planet {
    constructor(name, moons) {
      this.name = name;
      this.moons = moons;
    }

    orbit() {
      return `${this.name} orbits`;
    }
  }
  const mars = Reflect.construct(Planet, ['Mars', 2]);
  show(Reflect.ownKeys(mars), Object.getOwnPropertyNames(Planet.prototype),
    Reflect.has(mars, 'orbit'), mars.constructor.name, Planet.length, mars['or' + 'bit']());

  // Well-known symbols hook an object into language features.
  const money = {
    amount: 12.5,
    currency: 'EUR',
    [Symbol.toPrimitive](hint) {
      return hint === 'number' ? this.amount : `${this.amount} ${this.currency}`;
    },
    get [Symbol.toStringTag]() {
      return 'Money';
    },
  };
  class Even {
    static [Symbol.hasInstance](value) {
      return Number.isInteger(value) && value % 2 === 0;
    }
  }
  show(`${money}`, money * 2, Object.prototype.toString.call(money), 4 instanceof Even,
    5 instanceof Even);

  // Code from text: possible, slow, and dangerous with untrusted input.
  const add = new Function('a', 'b', 'return a + b');
  show(add(2, 3));

  // WeakRef observes an object without keeping it alive (rarely needed).
  const target = { payload: 'data' };
  show(new WeakRef(target).deref() === target);
}

// =================================================================================================
//  11. TEXT, REGULAR EXPRESSIONS, INTL, DATES, BYTES
// =================================================================================================

function section11Text() {
  header('11. Text, regular expressions, Intl, dates, bytes');

  // Regular expressions are literals. C#: Regex.
  const log = '2026-11-17 ERROR disk full; 2026-11-18 WARN retry; 2026-11-19 ERROR timeout';
  const entry = /(?<date>\d{4}-\d{2}-\d{2}) (?<level>[A-Z]+) (?<text>[^;]+)/g;
  const errorDates = [...log.matchAll(entry)]
    .filter((match) => match.groups.level === 'ERROR')
    .map((match) => match.groups.date);
  show(errorDates, log.replace(/(\d+)-(\d+)-(\d+)/, '$3.$2.$1').slice(0, 10),
    'a1b22c333'.match(/\d+/g), /^[\w.]+@\w+\.\w+$/.test('ann@example.com'),
    'x=1;y=22'.split(/[=;]/));
  show('5 USD, 7 EUR'.replace(/(\d+) ([A-Z]{3})/g, (_, amount, cur) => `${cur} ${amount * 2}`),
    RegExp.escape('1+1=2?'), /[\p{L}--[a-z]]/v.test('Q')); // the `v` flag: set operations

  // Intl: locale-aware formatting. C#: CultureInfo. Pass the locale for stable output.
  const number = 1234567.891;
  show(new Intl.NumberFormat('en-US').format(number), new Intl.NumberFormat('de-DE').format(number),
    new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(number),
    new Intl.NumberFormat('en-US', { notation: 'compact' }).format(number),
    (0.256).toLocaleString('en-US', { style: 'percent', maximumFractionDigits: 1 }));
  show(new Intl.ListFormat('en', { type: 'conjunction' }).format(['a', 'b', 'c']),
    new Intl.PluralRules('en-US', { type: 'ordinal' }).select(22),
    ['b', 'a', 'C'].toSorted(new Intl.Collator('en').compare),
    [...new Intl.Segmenter('en', { granularity: 'word' }).segment('Hello, big world')]
      .filter((segment) => segment.isWordLike).length);

  // Date: a timestamp in milliseconds behind a clumsy API (months start at 0; mutable).
  const date = new Date(Date.UTC(2026, 10, 17, 9, 30)); // month 10 is November
  const later = new Date(date.getTime() + 45 * 24 * 3600 * 1000);
  show(date.toISOString(), later.toISOString().slice(0, 10), date.getUTCDay(),
    new Intl.DateTimeFormat('en-GB', { dateStyle: 'medium', timeZone: 'UTC' }).format(date),
    Math.round((later - date) / 86_400_000));
  // Temporal replaces Date with immutable, explicit types. C#: DateOnly, TimeSpan.
  if (typeof Temporal === 'object') {
    const day = Temporal.PlainDate.from('2026-11-17');
    show(day.add({ days: 45 }).toString(), day.dayOfWeek,
      day.until(Temporal.PlainDate.from('2026-12-24')).days,
      Temporal.Duration.from({ hours: 27, minutes: 15 }).toString());
  } else {
    show('Temporal is not available in this runtime');
  }

  // Bytes: an ArrayBuffer is raw memory; typed arrays and DataView are windows onto it.
  const buffer = new ArrayBuffer(8);
  const view = new DataView(buffer);
  view.setUint16(0, 0x1234, false); // big-endian
  view.setFloat32(4, 1.5, true); // little-endian
  const utf8 = new TextEncoder().encode('Grüße');
  show(new Uint8Array(buffer), view.getUint16(0), view.getFloat32(4, true), utf8.length,
    new TextDecoder().decode(utf8).length, Buffer.from('hello').toString('base64'));
}

// =================================================================================================
//  12. THREADS: WORKERS AND SHARED MEMORY
// =================================================================================================

async function section12Workers() {
  header('12. Threads: workers and shared memory');

  // Parallelism comes from workers: separate threads, each with its own heap and event
  // loop. They share nothing by default and exchange messages, which are copied.
  // C#: closer to actors or separate processes than to Task.Run.
  const runWorker = (data) =>
    new Promise((resolve, reject) => {
      const worker = new Worker(new URL(import.meta.url), { workerData: data }); // this file
      worker.once('message', resolve);
      worker.once('error', reject);
    });
  const [small, large] = await Promise.all([
    runWorker({ job: 'sumOfSquares', n: 1000 }),
    runWorker({ job: 'sumOfSquares', n: 100_000 }),
  ]);
  show(small, large);

  // The exception is SharedArrayBuffer: memory that several threads see at once, with
  // Atomics for safe access. C#: Interlocked.
  const shared = new SharedArrayBuffer(4);
  await Promise.all([1, 2, 3, 4].map(() => runWorker({ job: 'increment', shared, times: 25_000 })));
  show(Atomics.load(new Int32Array(shared), 0));
}

// The body of a worker thread: the same file is loaded again with isMainThread === false.
function workerMain() {
  const { job, n, shared, times } = workerData;
  if (job === 'sumOfSquares') {
    let sum = 0;
    for (let i = 1; i <= n; i++) sum += i * i;
    parentPort.postMessage({ n, sum });
  } else {
    const counter = new Int32Array(shared);
    for (let i = 0; i < times; i++) Atomics.add(counter, 0, 1);
    parentPort.postMessage('done');
  }
}

// =================================================================================================
//  13. THE NEWEST: ES2023 - ES2026
// =================================================================================================

function section13Newest() {
  header('13. The newest: ES2023 - ES2026');

  // Used above:
  //   ES2023  toSorted / toReversed / toSpliced / with, findLast
  //   ES2024  Object.groupBy, Promise.withResolvers, the RegExp `v` flag
  //   ES2025  iterator helpers, Set algebra, Promise.try, RegExp.escape
  //   ES2026  using / DisposableStack, Array.fromAsync, Error.isError, Temporal
  const available = (name, present) => `${name}: ${present ? 'yes' : 'no'}`;
  show([
    available('Math.sumPrecise', typeof Math.sumPrecise === 'function'),
    available('Iterator.concat', typeof Iterator.concat === 'function'),
    available('Uint8Array.fromBase64', typeof Uint8Array.fromBase64 === 'function'),
    available('Float16Array', typeof globalThis.Float16Array === 'function'),
    available('Temporal', typeof globalThis.Temporal === 'object'),
  ].join(', '));
  const values = [1e20, 0.1, -1e20];
  show(values.reduce((sum, n) => sum + n), Math.sumPrecise?.(values) ?? 'n/a',
    new Uint8Array([1, 2, 255]).toHex?.() ?? 'n/a');
  // Not in the engines yet: decorators (@logged), pattern matching, the pipeline operator.
}

// =================================================================================================
//  ENTRY POINT
// =================================================================================================

async function main() {
  section01Basics();
  section02Functions();
  section03Objects();
  section04Collections();
  section05Classes();
  section06Iterators();
  section07Errors();
  await section08Async();
  await section09Modules();
  section10Metaprogramming();
  section11Text();
  await section12Workers();
  section13Newest();
}

// An ES module may `await` at its top level. The same file also serves as the worker script
// of section 12.
if (isMainThread) await main();
else workerMain();
