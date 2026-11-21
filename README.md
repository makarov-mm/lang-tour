# lang-tour

Language tours in a single file: one long, heavily commented, runnable source file per language.
Each file walks from the first line of the language to its modern and advanced features, and
every section prints what it demonstrates.

The tours are written for a developer who knows C#. A `C#:` note next to a construct names its
closest counterpart in C#, and each file starts with the differences that matter most.
The one exception is `csharp_tour.cs`, which goes the other way and introduces C# to a C++
developer.

## The tours

| Language | File | Run | Verified with |
|---|---|---|---|
| Rust | [rust_tour.rs](rust_tour.rs) | `rustc --edition 2024 rust_tour.rs && ./rust_tour` | rustc 1.97 |
| C++ | [cpp_tour.cpp](cpp_tour.cpp) | `g++ -std=c++23 -O2 cpp_tour.cpp -o cpp_tour && ./cpp_tour` | GCC 14.2, Clang 20 with libc++ (C++23 and C++26) |
| C# for C++ developers | [csharp_tour.cs](csharp_tour.cs) | `dotnet run csharp_tour.cs` | .NET SDK 10 (C# 14) |
| Python | [python_tour.py](python_tour.py) | `python3 python_tour.py` | CPython 3.14 |
| C | [c_tour.c](c_tour.c) | `gcc -std=c23 -O2 c_tour.c -o c_tour -lm && ./c_tour` | GCC 14.2, Clang 20 |
| Java | [java_tour.java](java_tour.java) | `java java_tour.java` | OpenJDK 25 |
| JavaScript | [javascript_tour.mjs](javascript_tour.mjs) | `node javascript_tour.mjs` | Node.js 26 and 24 |
| Go | [go_tour.go](go_tour.go) | `go run go_tour.go` | Go 1.24 |
| PHP | [php_tour.php](php_tour.php) | `php php_tour.php` | PHP 8.3 |
| Perl | [perl_tour.pl](perl_tour.pl) | `perl perl_tour.pl` | Perl 5.38 |
| R | [r_tour.R](r_tour.R) | `Rscript r_tour.R` | R 4.3 |
| SQL (PostgreSQL) | [sql_tour.sql](sql_tour.sql) | `psql -X -d postgres -f sql_tour.sql` | PostgreSQL 16 |
| Visual Basic (.NET) | [vb_tour/vb_tour.vb](vb_tour/vb_tour.vb) | `dotnet run --project vb_tour` | .NET SDK 10 (Visual Basic 17.13) |
| Fortran | [fortran_tour.f90](fortran_tour.f90) | `gfortran -std=f2018 -O2 fortran_tour.f90 -o fortran_tour && ./fortran_tour` | gfortran 14.2 |
| Delphi | [delphi_tour.dpr](delphi_tour.dpr) | `fpc delphi_tour.dpr && ./delphi_tour`, or `dcc64 delphi_tour.dpr` | Free Pascal 3.2.2 in Delphi mode, not Delphi itself |
| x86-64 assembly (NASM) | [asm_tour.asm](asm_tour.asm) | `nasm` and a linker, for Linux or for Windows: see the top of the file | NASM 2.16 |
| Erlang | [erlang_tour.erl](erlang_tour.erl) | `escript erlang_tour.erl` | Erlang/OTP 25 |
| Elixir | [elixir_tour.exs](elixir_tour.exs) | `elixir elixir_tour.exs` | Elixir 1.14 on OTP 25 |
| Haskell | [haskell_tour.hs](haskell_tour.hs) | `runghc haskell_tour.hs` | GHC 9.4 |

The comment at the top of each file has the exact commands, with the warning options the file was
checked under, and the oldest version it needs. The commands above are written for a Unix
shell; on Windows the program that a compiler produces is started as `.\rust_tour.exe` instead
of `./rust_tour`.

## What each tour covers

- **Rust** — ownership, moves and borrowing; enums and pattern matching; traits, generics and
  lifetimes; smart pointers; concurrency; macros; unsafe and FFI; async/await from the inside.
- **C++** — values, references and pointers; RAII and smart pointers; lambdas; ranges;
  templates and concepts; compile-time evaluation; concurrency; coroutines; C++23 and C++26.
- **C#** — value and reference types; records; pattern matching; generics; LINQ; Span, ref and
  SIMD; unsafe code and native interop; threads; async/await; reflection and code generation.
- **Python** — comprehensions; closures and decorators; dataclasses; type hints and protocols;
  generators; pattern matching; metaprogramming; threads, processes and asyncio.
- **C** — pointers and arrays; strings; dynamic memory; function pointers; the preprocessor;
  undefined behaviour; threads; C23.
- **Java** — records and enums; generics; lambdas and streams; pattern matching; virtual
  threads; reflection and annotations; what is new in Java 21 to 25.
- **JavaScript** — closures; prototypes and classes; iterators and generators; asynchronous
  code; modules; proxies; workers and shared memory; ES2023 to ES2026.
- **Go** — slices and maps; methods and interfaces; errors; generics; goroutines and channels;
  reflection and unsafe.
- **PHP** — arrays; closures; classes, traits and enums; the type system; generators;
  reflection and attributes; fibers.
- **Perl** — context; references; regular expressions; packages and objects; idioms.
- **R** — vectors; data frames; functional programming; S3, S4 and reference classes;
  conditions; code as data; statistics.
- **SQL** — joins; grouping; common table expressions; window functions; upsert and MERGE;
  transactions; JSON, arrays and ranges; indexes and query plans; functions and triggers.
- **Visual Basic** — Option Strict; Select Case; events with WithEvents and Handles; LINQ query
  syntax; XML literals; nullable logic; Async/Await; a note for readers who remember VB6.
- **Fortran** — array expressions; modules and generic names; derived types and polymorphism;
  allocatable variables; interoperability with C; do concurrent; submodules.
- **Delphi** — records with operators; classes and manual object lifetime; class references;
  interfaces and reference counting; generics; helpers; RTTI; threads.
- **x86-64 assembly** — registers and flags; addressing; the stack and both calling conventions
  (System V and Microsoft x64); string instructions; macros; SSE, AVX2 and AVX-512; atomic
  instructions; a virtual table by hand.
- **Erlang** — pattern matching; recursion; the bit syntax; processes and messages; links and
  monitors; gen_server and supervisor; ETS.
- **Elixir** — pattern matching; pipes; Enum and Stream; structs, protocols and behaviours;
  processes, tasks and agents; GenServer and Supervisor; macros.
- **Haskell** — algebraic data types; type classes; Functor, Applicative and Monad; laziness;
  GADTs and type families; State; concurrency and STM; a parser built from scratch.

## How a tour is organized

- A header: how to run the file, what it was verified with, the main differences from C#, and
  a table of contents.
- Numbered sections that go from simple to advanced. Each one is a function that prints
  `=== N. Title ===` and then the results of what it shows, so the output can be read next to
  the source.
- Lines that are commented out and followed by an error message show what the compiler or the
  interpreter rejects.
- The last section, "The newest", collects the recent additions to the language.

## What was verified, and what was not

Every file was compiled and run on Linux with the toolchain named in the table, with the
warnings of the compiler or interpreter switched on, and its output was checked.

- Language features that are newer than those toolchains appear only as comments that say
  "NOT compiled" or "NOT run": among them C# 15, Go 1.25 to 1.27, PHP 8.4 to 8.6,
  PostgreSQL 17 to 19, Fortran 2023, Erlang/OTP 26 to 29, Elixir 1.15 to 1.20, GHC 9.6 to
  9.14, and Intel APX in the assembly tour.
- `delphi_tour.dpr` was compiled with Free Pascal in its Delphi mode only. It keeps to the
  language that both compilers share; what only Delphi has (anonymous methods, inline
  variables, attributes) is shown in comments.
- Nothing was built with the Microsoft C and C++ compilers, and nothing was run on Windows
  itself or on macOS. The C, Go and assembly tours were built for Windows as well and run
  under Wine.
- `sql_tour.sql` creates a schema named `sql_tour` in the database it is run against and
  drops it at the end; an existing schema of that name is replaced.

## Notes

- Visual Basic has no single-file mode, so its tour lives in the folder `vb_tour` next to a
  small project file. (A project file in the root folder would also make
  `dotnet run csharp_tour.cs` start that project instead of the C# file.)
- Compilers leave executables and intermediate files next to the sources: `*.o`, `*.obj`,
  `*.hi`, `*.mod`, `*.beam`, the folders `bin` and `obj`, and the programs themselves.

## License

MIT. See [LICENSE](LICENSE).
