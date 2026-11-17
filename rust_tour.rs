// =====================================================================================
//  RUST ДЛЯ C#-РАЗРАБОТЧИКА — тур по языку в одном файле, от простого к сложному
// =====================================================================================
//
//  Сборка и запуск (нужен только rustc; Cargo и сторонние крейты не используются):
//
//      rustc --edition 2024 rust_tour.rs
//      ./rust_tour                          (Windows: rust_tour.exe)
//
//  Встроенные модульные тесты (раздел 12):
//
//      rustc --edition 2024 --test rust_tour.rs -o rust_tour_tests
//      ./rust_tour_tests
//
//  Проверено на rustc 1.97 (edition 2024); на более старых версиях не проверялось.
//
//  Как читать. Каждый раздел — функция `sectionNN_*`; типы и функции, нужные разделу,
//  объявлены прямо перед ней. `main()` в конце файла вызывает разделы по порядку.
//  Пометка «C#:» показывает ближайший аналог в C#. Закомментированные строки с кодом
//  ошибки (E0382 и т.п.) — то, что компилятор ОТКАЖЕТСЯ собирать; раскомментируйте
//  и посмотрите на сообщение — диагностика в Rust сама по себе учебник.
//
//  Главные отличия от C#, которые стоит держать в голове с первой строки:
//
//   1. Нет GC и нет рантайма. Память освобождается детерминированно — когда владелец
//      значения выходит из области видимости. Корректность ссылок доказывает компилятор.
//   2. Нет null и нет исключений. Вместо них — типы Option<T> и Result<T, E>.
//   3. Нет классов и наследования. Есть данные (struct, enum), поведение (impl)
//      и трейты (интерфейсы «на стероидах»).
//   4. Всё неизменяемо по умолчанию; изменяемость запрашивается явно (`mut`).
//   5. Обобщения мономорфизируются, как шаблоны C++: отдельный машинный код на каждый
//      набор типов. В рантайме обобщений нет, рефлексии тоже нет.
//   6. Значения перемещаются (move), а не копируются по ссылке: `let b = a;` для
//      String делает `a` недоступной. Об этом — раздел 3, самый важный в файле.
//
//  Содержание:
//    1. Основы: переменные, типы, выражения        10. Времена жизни (lifetimes)
//    2. Функции, кортежи, массивы, срезы, строки   11. Умные указатели, внутр. изменяемость
//    3. Владение, перемещение, заимствование       12. Модули, атрибуты, тесты
//    4. Структуры и методы                         13. Многопоточность
//    5. Перечисления и сопоставление с образцом    14. Макросы
//    6. Обработка ошибок                           15. Вычисления при компиляции
//    7. Коллекции                                  16. Продвинутая система типов
//    8. Замыкания и итераторы                      17. unsafe и FFI
//    9. Трейты и обобщения                         18. async/await изнутри
// =====================================================================================

// Атрибут уровня крейта (`#!` — «относится ко всему файлу»). C#: #pragma warning disable.
#![allow(dead_code)] // учебный файл: часть элементов объявлена только «для показа»

// `use` — аналог using в C#: вносит имена в область видимости. Фигурные скобки группируют.
// Часть std доступна без импорта («прелюдия»): Option, Result, Vec, String, Box,
// Clone, Drop, Iterator, Future и т.д.
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

/// Печатает заголовок раздела.
/// Три косые черты — документирующий комментарий (C#: `/// <summary>`), внутри Markdown.
fn header(number: u32, title: &str) {
    println!("\n=== {number:>2}. {title} ===");
}

// =====================================================================================
//  1. ОСНОВЫ: переменные, типы, выражения, управление потоком
// =====================================================================================

/// Константа времени компиляции. C#: `const int MaxPoints = 100_000;`.
/// Тип обязателен; имя — в SCREAMING_SNAKE_CASE (за стилем имён следит компилятор).
const MAX_POINTS: u32 = 100_000;

/// Глобальная переменная с фиксированным адресом. C#: `static readonly`.
/// Изменяемое глобальное состояние — это атомики и Mutex (раздел 13) либо `static mut`,
/// доступный только из unsafe-кода (раздел 17).
static GREETING: &str = "Hello";

fn section01_basics() {
    header(1, "Basics: variables, types, control flow");

    // --- Переменные ---------------------------------------------------------------
    // `let` объявляет переменную, тип выводится (как `var` в C#).
    // ОТЛИЧИЕ ОТ C#: переменная по умолчанию НЕИЗМЕНЯЕМА.
    let x = 5; // i32 — целый тип по умолчанию
    // x = 6;  // E0384: cannot assign twice to immutable variable `x`
    let mut y = 10; // `mut` разрешает изменение
    y += x;

    // Затенение (shadowing): то же имя можно объявить заново, даже с другим типом.
    // В C# это ошибка CS0128, в Rust — идиома: «распарсил строку, имя оставил».
    let input = "42";
    let input: i32 = input.parse().expect("not a number"); // теперь input — число
    println!("x = {x}, y = {y}, input = {input}"); // {x} захватывает переменную, как $"{x}"
    println!("{GREETING}, MAX_POINTS = {MAX_POINTS}");

    // --- Скалярные типы -----------------------------------------------------------
    // Разрядность — в имени типа: i8..i128, u8..u128, isize/usize (размер указателя),
    // f32/f64. C#: sbyte/short/int/long/Int128, byte/ushort/uint/ulong, nint/nuint.
    let byte: u8 = 255;
    let million = 1_000_000_i64; // суффикс типа + разделители разрядов
    let (hex, octal, binary, ascii) = (0xFF, 0o77, 0b1010_1010, b'A'); // b'A' — это u8
    let big: u128 = 2_u128.pow(100);
    let ratio = 2.5_f32;
    let flag = true;
    // char — скалярное значение Unicode, 4 байта (в C# char — 16-битная единица UTF-16).
    let letter = 'я';
    println!("{byte} {million} {hex} {octal} {binary} {ascii} {big} {ratio} {flag} {letter}");
    println!(
        "size_of::<char>() = {}, size_of::<usize>() = {}",
        size_of::<char>(),
        size_of::<usize>()
    );

    // --- Преобразования -----------------------------------------------------------
    // Неявных числовых преобразований нет ВООБЩЕ: `1_i32 + 1_i64` не скомпилируется (E0308).
    let small: i32 = 300;
    let widened: i64 = small.into(); // без потерь — через трейт From/Into (раздел 9)
    let truncated = small as u8; // `as` — явный каст, молча отбрасывает старшие биты: 44
    let checked = u8::try_from(small); // проверяемое преобразование -> Result (здесь Err)
    let floored = 3.99_f64 as i32; // к нулю: 3. NaN -> 0, выход за диапазон -> насыщение
    println!("{widened} {truncated} {checked:?} {floored}");

    // --- Переполнение -------------------------------------------------------------
    // C#: по умолчанию молча заворачивается (unchecked). Rust: паника в debug-сборке,
    // заворачивание в release. Нужное поведение лучше назвать явно:
    let max = u8::MAX;
    println!(
        "wrapping {} | checked {:?} | saturating {} | overflowing {:?}",
        max.wrapping_add(1),    // 0
        max.checked_add(1),     // None
        max.saturating_add(1),  // 255
        max.overflowing_add(1)  // (0, true)
    );

    // --- Всё есть выражение ---------------------------------------------------------
    // `if` возвращает значение (отдельный оператор ?: не нужен). Блок `{}` возвращает
    // значение последнего выражения, если после него НЕТ точки с запятой.
    let parity = if x % 2 == 0 { "even" } else { "odd" };
    let squared_plus_one = {
        let t = x * x;
        t + 1 // нет `;` => это значение блока
    };
    println!("{x} is {parity}, x*x+1 = {squared_plus_one}");

    // --- Циклы --------------------------------------------------------------------
    // `loop` — бесконечный цикл; `break` может вернуть из него значение.
    let mut power = 1_u32;
    let first_over_1000 = loop {
        power *= 2;
        if power > 1000 {
            break power;
        }
    };

    // `while` — как в C#. `for` работает ТОЛЬКО с итераторами: счётчика `for (;;)` нет.
    let mut countdown = 3;
    while countdown > 0 {
        countdown -= 1;
    }
    let mut sum = 0;
    for i in 0..5 {
        sum += i; // 0, 1, 2, 3, 4 — правая граница не включается
    }
    for i in (1..=3).rev() {
        sum += i; // 3, 2, 1 — `..=` включает правую границу
    }
    for (index, ch) in "abc".chars().enumerate() {
        print!("{index}:{ch} "); // print! — без перевода строки
    }
    println!("| first power of two over 1000 = {first_over_1000}, sum = {sum}");

    // Метки циклов: break/continue для ВНЕШНЕГО цикла.
    // (В C# `break outer;` появился только в C# 15; раньше — goto или флаг.)
    'outer: for i in 1..10 {
        for j in 1..10 {
            if i * j == 42 {
                println!("found 42 = {i} * {j}");
                break 'outer;
            }
        }
    }

    // --- match --------------------------------------------------------------------
    // Как switch-выражение C#, но ОБЯЗАН покрывать все случаи (иначе E0004).
    let description = match x {
        0 => "zero",
        1 | 2 => "small",         // альтернативы
        3..=9 => "digit",         // диапазон
        _ if x < 0 => "negative", // `_` + охранное условие (guard)
        _ => "large",             // ветка по умолчанию
    };
    println!("{x} is a {description}");

    // Единичный тип `()` — «значение без информации». Его возвращает функция без `->`.
    // C#: void, только `()` — настоящий тип: его можно подставить в обобщение
    // (например, `Result<(), E>` — «успех без данных»).
    println!("size_of::<()>() = {}", size_of::<()>());
}

// =====================================================================================
//  2. ФУНКЦИИ, КОРТЕЖИ, МАССИВЫ, СРЕЗЫ, СТРОКИ
// =====================================================================================

/// Типы параметров и результата в сигнатуре пишутся всегда: вывод типов работает только
/// ВНУТРИ функций. Последнее выражение без `;` — возвращаемое значение.
/// C#: `static int Add(int a, int b) => a + b;`
///
/// В Rust нет перегрузки функций, значений по умолчанию и именованных аргументов.
/// Вместо них — разные имена (`new` / `with_capacity`), `Option<T>`, builder-ы и трейты.
fn add(a: i32, b: i32) -> i32 {
    a + b
}

/// Несколько результатов возвращают кортежем. C#: `(int Quotient, int Remainder)`.
fn div_rem(a: i32, b: i32) -> (i32, i32) {
    (a / b, a % b)
}

/// Срез `&[T]` — «толстый указатель» (адрес + длина) на чужие данные, без копирования.
/// Принимает и массив, и Vec, и их части. C#: ReadOnlySpan<T>.
fn sum_slice(values: &[i32]) -> i32 {
    let mut total = 0;
    for v in values {
        total += v;
    }
    total
}

/// `&mut [T]` — изменяемый срез. C#: Span<T>.
fn double_in_place(values: &mut [i32]) {
    for v in values {
        *v *= 2; // `*` разыменовывает ссылку, чтобы записать в то место, куда она смотрит
    }
}

/// `&str` — срез строки. Строковые параметры почти всегда принимают как `&str`: сюда
/// можно передать и литерал, и `&String`. Результат — тоже срез исходной строки.
fn first_word(text: &str) -> &str {
    text.split_whitespace().next().unwrap_or("")
}

fn section02_functions_and_data() {
    header(2, "Functions, tuples, arrays, slices, strings");

    // --- Кортежи ------------------------------------------------------------------
    let triple = (1, "one", 2.5); // тип: (i32, &str, f64)
    let (number, name, _) = triple; // деструктуризация; `_` — «не интересует»
    let (quotient, remainder) = div_rem(17, 5);
    println!(
        "{number} {name} {} | 17 / 5 = {quotient} rem {remainder} | {}",
        triple.2,
        add(2, 3)
    );

    // --- Массивы ------------------------------------------------------------------
    // `[T; N]`: длина — часть типа, данные лежат на стеке. Это ЗНАЧЕНИЕ, а не ссылка
    // на кучу, как `int[]` в C#: присваивание копирует все элементы.
    let primes: [i32; 5] = [2, 3, 5, 7, 11];
    let zeros = [0_u8; 16]; // шестнадцать нулей
    let matrix = [[1, 2, 3], [4, 5, 6]]; // [[i32; 3]; 2] — один сплошной кусок памяти
    let mut copy = primes; // побитовая копия всего массива
    copy[0] = 100;
    println!(
        "{primes:?} vs {copy:?}, zeros.len() = {}, matrix[1][2] = {}",
        zeros.len(),
        matrix[1][2]
    );

    // Выход за границы — паника (C#: IndexOutOfRangeException), а не порча памяти.
    // Безопасный доступ без паники — `get`, возвращает Option (раздел 5).
    println!(
        "primes.get(1) = {:?}, primes.get(10) = {:?}",
        primes.get(1),
        primes.get(10)
    );

    // --- Срезы --------------------------------------------------------------------
    let middle = &primes[1..4]; // [3, 5, 7] — не копия, а «окно» в массив
    let mut data = [1, 2, 3];
    double_in_place(&mut data); // массив неявно приводится к срезу
    println!(
        "middle = {middle:?}, sum = {}, doubled = {data:?}",
        sum_slice(middle)
    );

    // --- Строки -------------------------------------------------------------------
    // Два основных типа, оба в UTF-8 (не UTF-16, как в C#):
    //   String — владеет буфером в куче, может расти (ближе к StringBuilder);
    //   &str   — срез чужих байтов (ближе к ReadOnlySpan<char>). Литерал — это &'static str.
    let literal: &str = "hello";
    let mut owned = String::from("Hello"); // или "Hello".to_string()
    owned.push_str(", world");
    owned.push('!');
    let word = first_word(&owned); // &String автоматически приводится к &str
    let message = format!("{owned} has {} bytes, first word: {word}", owned.len());
    println!("{literal} | {message}"); // format! ≈ $"..." — возвращает String

    // Индексации `s[i]` нет: символ в UTF-8 занимает от 1 до 4 байт.
    let cyrillic = "Привет";
    println!(
        "'{cyrillic}': {} bytes, {} chars, first char {:?}, bytes[0..4] = '{}'",
        cyrillic.len(),           // 12
        cyrillic.chars().count(), // 6
        cyrillic.chars().next(),  // Some('П')
        &cyrillic[0..4]           // срез по БАЙТАМ; разрез посередине символа — паника
    );

    // Полезные методы: большинство возвращают срезы или ленивые итераторы, а не копии.
    let csv = "  alpha, beta ,gamma  ";
    let fields: Vec<&str> = csv.split(',').map(|s| s.trim()).collect();
    println!(
        "{fields:?} | {} | {} | {:?}",
        csv.trim().to_uppercase(),
        csv.replace(' ', ""),
        csv.find("beta") // Option<usize>: позиция в байтах
    );

    // Литералы.
    let raw = r#"C:\dir\file "quoted""#; // raw-строка: без экранирования (C#: @"" и """ """)
    let multiline = "line one
line two"; // обычный литерал может содержать перевод строки
    let continued = "one logical \
                     line"; // `\` в конце съедает перевод строки и отступ
    let bytes = b"ASCII"; // байтовая строка: &[u8; 5]
    println!(
        "{raw} | {} lines | {continued} | {bytes:?}",
        multiline.lines().count()
    );

    // --- Форматирование -------------------------------------------------------------
    // Мини-язык похож на C#: ширина, выравнивание, точность, система счисления.
    // {:?} — отладочный вывод (трейт Debug), {:#?} — он же «в столбик».
    println!(
        "[{:>8.3}] [{:<6}] [{:^6}] [{:08.2}] [{:#x}] [{:#010b}] [{:e}] [{:+}]",
        9.87654, "ab", "mid", 2.5, 255, 5, 1234.5, 7
    );
    let width = 6;
    // Имена переменных, позиции аргументов и ширина из переменной (`width$`).
    println!(
        "[{number:>width$}] [{0}/{1}/{0}] [{triple:?}]",
        quotient, remainder
    );
}

// =====================================================================================
//  3. ВЛАДЕНИЕ, ПЕРЕМЕЩЕНИЕ, ЗАИМСТВОВАНИЕ
// =====================================================================================
//
//  Правила владения (ownership):
//    1) у каждого значения ровно ОДИН владелец;
//    2) когда владелец выходит из области видимости, значение уничтожается (drop);
//    3) присваивание и передача в функцию ПЕРЕМЕЩАЮТ значение, а не копируют.
//
//  Правило заимствования (borrowing) — в каждый момент времени на значение есть
//    ЛИБО сколько угодно разделяемых ссылок `&T` (только чтение),
//    ЛИБО ровно одна эксклюзивная ссылка `&mut T` (чтение и запись).
//
//  Эти правила проверяет компилятор (borrow checker). Они исключают use-after-free,
//  двойное освобождение, висячие ссылки, инвалидацию итераторов и гонки данных —
//  без GC и без накладных расходов в рантайме.

/// Тип с деструктором. Трейт `Drop` — аналог `IDisposable.Dispose()`, только вызывается
/// АВТОМАТИЧЕСКИ и детерминированно. `using` не нужен: он как бы есть всегда.
struct Noisy(&'static str);

impl Drop for Noisy {
    fn drop(&mut self) {
        println!("    drop({})", self.0);
    }
}

/// Принимает String по значению: владение переходит в функцию, вызывающий его теряет.
fn consume(text: String) -> usize {
    text.len()
} // здесь `text` уничтожается, буфер в куче освобождается

/// Заимствует на чтение. Идиоматичнее принимать `&str` — об этом и напоминает линтер
/// Clippy; здесь `&String` оставлен ради наглядности, а предупреждение отключено.
#[allow(clippy::ptr_arg)]
fn inspect(text: &String) -> usize {
    text.len()
}

/// Заимствует на запись.
fn append_bang(text: &mut String) {
    text.push('!');
}

/// Возврат значения передаёт владение вызывающему — без копирования буфера.
fn make_greeting(name: &str) -> String {
    format!("Hello, {name}")
}

fn section03_ownership() {
    header(3, "Ownership, moves, borrowing");

    // --- Перемещение (move) ---------------------------------------------------------
    let s1 = String::from("data");
    let s2 = s1; // буфер теперь принадлежит s2; s1 считается неинициализированной
    // println!("{s1}"); // E0382: borrow of moved value: `s1`
    //
    // В C# `var s2 = s1;` скопировало бы ссылку, и оба имени видели бы один объект.
    // В Rust «двух владельцев» не бывает — поэтому и не нужен сборщик мусора.

    let s3 = s2.clone(); // глубокая копия — всегда явная и заметная в коде
    println!("s2 = {s2}, s3 = {s3}");

    // Типы с маркером Copy (числа, bool, char, ссылки `&T`, кортежи и массивы из Copy)
    // копируются побитово — как struct в C#. Для них «перемещение» оставляет оригинал.
    let n1 = 5;
    let n2 = n1;
    println!("n1 = {n1}, n2 = {n2}");

    // --- Заимствование ------------------------------------------------------------
    let mut text = make_greeting("Rust");
    let length = inspect(&text); // `&text` — разделяемая ссылка
    append_bang(&mut text); // `&mut text` — эксклюзивная ссылка
    println!("{text} (was {length} bytes)");
    let consumed = consume(text); // text перемещён в функцию и там уничтожен
    // println!("{text}"); // E0382: value borrowed here after move
    println!("consumed {consumed} bytes");

    // Borrow checker в действии. Аналогичный код на C# (`foreach` + `list.Add`) падает
    // в рантайме с InvalidOperationException; здесь он просто не компилируется.
    let mut scores = vec![10, 20, 30];
    let first = &scores[0]; // ссылка внутрь вектора
    // scores.push(40); // E0502: push может перевыделить буфер, а `first` ещё нужен ниже
    println!("first = {first}");
    scores.push(40); // теперь можно: `first` больше не используется (non-lexical lifetimes)

    let mut name = String::from("a");
    let exclusive = &mut name;
    // let second = &mut name; // E0499: cannot borrow `name` as mutable more than once
    exclusive.push('b');
    println!("scores = {scores:?}, name = {name}");

    // Висячая ссылка невозможна:
    // fn dangle<'a>() -> &'a String { let s = String::new(); &s } // E0515

    // --- RAII и порядок уничтожения -------------------------------------------------
    {
        let _a = Noisy("a");
        let _b = Noisy("b");
        let c = Noisy("c");
        drop(c); // досрочное уничтожение: функция drop просто забирает владение
        println!("    end of scope");
    } // здесь уничтожаются b, затем a — в порядке, обратном объявлению

    // `let _ = ...` уничтожает значение сразу, `let _name = ...` — в конце блока.
    let _ = Noisy("temporary");
    println!("    after temporary");

    // --- Замена значения «на месте» -------------------------------------------------
    // Из-под `&mut` нельзя просто забрать значение (останется дыра), но можно обменять.
    let mut current = String::from("old");
    let previous = std::mem::replace(&mut current, String::from("new"));
    let taken = std::mem::take(&mut current); // оставляет значение по умолчанию: ""
    println!("previous = {previous}, taken = {taken}, current = '{current}'");
}

// =====================================================================================
//  4. СТРУКТУРЫ И МЕТОДЫ
// =====================================================================================

/// Структура с именованными полями. C#: ближе всего `record struct`.
///
/// `#[derive(...)]` генерирует реализации стандартных трейтов (как `record` даёт
/// Equals и ToString): Debug — печать через {:?}; Clone, Copy — копирование;
/// PartialEq — оператор ==; PartialOrd — сравнение; Default — значение по умолчанию.
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd, Default)]
struct Vec2 {
    x: f64,
    y: f64,
}

/// Поведение добавляется в блоках `impl` (их может быть сколько угодно).
impl Vec2 {
    /// Ассоциированная константа. C#: `public static readonly Vec2 Zero`.
    const ZERO: Vec2 = Vec2 { x: 0.0, y: 0.0 };

    /// Ассоциированная функция (без self) — аналог статического метода.
    /// Конструкторов в языке нет; по соглашению «конструктор» называют `new`.
    fn new(x: f64, y: f64) -> Self {
        Self { x, y } // сокращение для `Vec2 { x: x, y: y }`
    }

    /// `&self` — метод читает объект (заимствует его).
    fn length(&self) -> f64 {
        self.x.hypot(self.y)
    }

    /// `&mut self` — метод изменяет объект; вызвать можно только на `mut`-переменной.
    fn scale(&mut self, factor: f64) {
        self.x *= factor;
        self.y *= factor;
    }

    /// `self` по значению — метод ПОГЛОЩАЕТ объект. Для Copy-типа это просто копия.
    fn normalized(self) -> Self {
        let length = self.length();
        if length == 0.0 {
            self
        } else {
            Self::new(self.x / length, self.y / length)
        }
    }
}

/// Перегрузка операторов — реализация трейтов из `std::ops`.
/// C#: `public static Vec2 operator +(Vec2 a, Vec2 b)`.
impl std::ops::Add for Vec2 {
    type Output = Vec2; // тип результата — ассоциированный тип трейта
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

/// Правый операнд может быть другого типа: `Vec2 * f64`.
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

/// Составное присваивание `+=` — отдельный трейт. (В C# `+=` выводится из `+`;
/// определить его отдельно можно только начиная с C# 14.)
impl std::ops::AddAssign for Vec2 {
    fn add_assign(&mut self, rhs: Vec2) {
        self.x += rhs.x;
        self.y += rhs.y;
    }
}

/// `Display` — «человеческий» вывод через `{}`. C#: `override ToString()`.
impl fmt::Display for Vec2 {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        // Уважаем точность, запрошенную вызывающим: для `{:.1}` precision() == Some(1).
        let precision = f.precision().unwrap_or(2);
        write!(f, "({:.precision$}, {:.precision$})", self.x, self.y)
    }
}

/// Кортежная структура и идиома newtype: новый тип с нулевыми накладными расходами.
/// `Meters` и `Seconds` нельзя перепутать, хотя внутри у обоих f64.
#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Meters(f64);

#[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
struct Seconds(f64);

fn speed(distance: Meters, time: Seconds) -> f64 {
    distance.0 / time.0 // поля кортежной структуры — по индексу
}

/// Unit-структура: данных нет, размер 0 байт. Нужна как маркер или носитель трейта.
struct Marker;

/// Структура, владеющая данными в куче (String): она не Copy и при присваивании
/// перемещается, но может быть Clone.
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

    /// Шаг интегрирования: меняем состояние через `&mut self`.
    fn advance(&mut self, dt: f64) {
        self.position += self.velocity * dt;
    }
}

fn section04_structs() {
    header(4, "Structs and methods");

    let mut v = Vec2::new(3.0, 4.0);
    v.scale(2.0);
    // Один и тот же объект в трёх форматах: Display, Display с точностью, Debug.
    println!("{v} | {v:.0} | {v:?} | length = {}", v.length());

    let combined = -(v + Vec2::new(1.0, 1.0) * 2.0 - Vec2::ZERO);
    println!(
        "combined = {combined}, unit = {:.3}, default = {}",
        v.normalized(),
        Vec2::default()
    );
    println!("speed = {} m/s", speed(Meters(100.0), Seconds(9.58)));
    // speed(Seconds(9.58), Meters(100.0)); // E0308: mismatched types — в этом и смысл newtype

    // «Синтаксис обновления»: остальные поля взять из другого значения. C#: `with { }`.
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

    // Деструктуризация структуры: `..` пропускает остальные поля.
    let Particle { name, position, .. } = &muon;
    println!("{name} at {position}, E = {:.3e} J", muon.kinetic_energy());
    println!("equal: {}, electron = {electron:?}", electron == muon); // PartialEq из derive

    // Никаких скрытых заголовков объекта и таблиц методов: размер = сумма полей.
    println!(
        "size_of: Vec2 = {}, Marker = {}, Particle = {}",
        size_of::<Vec2>(),
        size_of::<Marker>(),
        size_of::<Particle>() // String (указатель + длина + ёмкость = 24) + 2 * Vec2 + f64
    );
}

// =====================================================================================
//  5. ПЕРЕЧИСЛЕНИЯ И СОПОСТАВЛЕНИЕ С ОБРАЗЦОМ
// =====================================================================================

/// `enum` в Rust — тип-сумма (tagged union): каждый вариант может нести свои данные.
/// C#: иерархия record-ов + switch, либо `union` из C# 15.
#[derive(Debug, Clone, PartialEq)]
enum Shape {
    Circle { radius: f64 }, // вариант с именованными полями
    Rectangle { width: f64, height: f64 },
    Triangle(f64, f64, f64), // кортежный вариант
    Point,                   // вариант без данных
}

impl Shape {
    fn area(&self) -> f64 {
        // `match` обязан покрыть ВСЕ варианты. Добавите новый вариант — компилятор
        // покажет каждое место в программе, которое нужно дописать.
        match self {
            Shape::Circle { radius } => std::f64::consts::PI * radius * radius,
            Shape::Rectangle { width, height } => width * height,
            Shape::Triangle(a, b, c) => {
                let s = (a + b + c) / 2.0;
                (s * (s - a) * (s - b) * (s - c)).sqrt() // формула Герона
            }
            Shape::Point => 0.0,
        }
    }
}

/// «Обычный» enum, как в C#: с явными значениями и заданным базовым типом.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
#[repr(u8)]
enum Level {
    Low = 1,
    Medium = 5,
    High = 10,
}

/// `Option<T>` заменяет null. В std он объявлен буквально так:
///     enum Option<T> { None, Some(T) }
/// «Значения может не быть» видно в типе, и достать T без проверки нельзя.
/// C#: `T?`, только обязательный к проверке и одинаковый для любых типов.
///
/// Цикл написан вручную ради наглядности. Идиоматичная запись — одна строка
/// с итератором (раздел 8): `values.iter().copied().find(|v| v % 2 == 0)`.
#[allow(clippy::manual_find)]
fn find_even(values: &[i32]) -> Option<i32> {
    for &value in values {
        if value % 2 == 0 {
            return Some(value); // `return` — для раннего выхода
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

    // `if let` — когда интересен один вариант. C#: `if (shape is Circle { Radius: var r })`.
    if let Shape::Circle { radius } = &shapes[0] {
        println!("the first shape is a circle of radius {radius}");
    }

    // let-цепочки (edition 2024): образцы и обычные условия через `&&`.
    let numbers = [1, 3, 4, 7, 10];
    if let Some(even) = find_even(&numbers)
        && even > 2
        && let Some(square) = even.checked_mul(even)
    {
        println!("first even number {even}, its square {square}");
    }

    // `while let` — цикл, пока образец совпадает.
    let mut stack = vec![1, 2, 3];
    while let Some(top) = stack.pop() {
        print!("popped {top}; ");
    }
    println!();

    // Образцы: кортежи, альтернативы, диапазоны, привязка `@`, охранные условия.
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

    // Образцы для срезов. C#: list patterns `[first, .., last]`.
    for slice in [&numbers[..0], &numbers[..1], &numbers[..]] {
        match slice {
            [] => println!("empty"),
            [single] => println!("one element: {single}"),
            [first, middle @ .., last] => {
                println!("first {first}, last {last}, {} in between", middle.len())
            }
        }
    }

    // `matches!` — проверка образца как bool. C#: `x is A or B`.
    let has_flat = shapes
        .iter()
        .any(|s| matches!(s, Shape::Point | Shape::Rectangle { .. }));
    println!("has point or rectangle: {has_flat}");

    // `let ... else`: «достань значение или уйди» — без лишней вложенности. В ветке else
    // обязан стоять код, не возвращающий управление: continue, break, return, panic!.
    let mut settings = Vec::new();
    for line in ["width = 42", "broken line", "height = tall", "depth=7"] {
        let Some((key, raw_value)) = line.split_once('=') else {
            continue; // в строке нет '='
        };
        let Ok(value) = raw_value.trim().parse::<i32>() else {
            continue; // справа не число (Ok — вариант типа Result, раздел 6)
        };
        settings.push((key.trim(), value));
    }
    println!("parsed settings: {settings:?}");

    // --- Option: комбинаторы вместо проверок на null --------------------------------
    let found = find_even(&numbers); // Some(4)
    let doubled = found.map(|v| v * 2); // C#: found is int v ? v * 2 : null
    let fallback = find_even(&[1, 3]).unwrap_or(-1); // C#: ?? -1
    let chained = found.and_then(|v| v.checked_sub(10)).filter(|v| *v > 0); // None
    println!(
        "{found:?} {doubled:?} {fallback} {chained:?} {}",
        found.is_some_and(|v| v > 3)
    );
    // `unwrap()` / `expect("...")` — «я уверен, что значение есть»; иначе паника.

    // Нишевая оптимизация: None для ссылки кодируется нулевым адресом, поэтому
    // Option<&T> занимает ровно столько же, сколько &T. Абстракция бесплатна.
    println!(
        "size_of: Option<&i32> = {}, &i32 = {}, Option<i32> = {}",
        size_of::<Option<&i32>>(),
        size_of::<&i32>(),
        size_of::<Option<i32>>()
    );

    // Числовой enum: приводится к числу через `as`, сравнивается и сортируется (derive Ord).
    let mut levels = [Level::High, Level::Low, Level::Medium];
    levels.sort();
    println!("{levels:?} as numbers: {:?}", levels.map(|l| l as u8));
}

// =====================================================================================
//  6. ОБРАБОТКА ОШИБОК
// =====================================================================================
//
//  Исключений в Rust нет. Ошибки бывают двух видов:
//    - ожидаемые (нет файла, плохой ввод) — значение `Result<T, E>` в сигнатуре функции:
//          enum Result<T, E> { Ok(T), Err(E) }
//    - баги (нарушен инвариант) — паника `panic!`, которая завершает поток.

/// Свой тип ошибки — обычный enum; по вариантам удобно делать match.
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

/// Трейт `Error` делает тип «настоящей» ошибкой: его можно положить в `Box<dyn Error>`,
/// и у него есть цепочка причин `source()` (C#: InnerException).
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
    // `ok_or_else` превращает Option в Result.
    // Оператор `?`: при Err — немедленно вернуть ошибку из функции, при Ok — развернуть
    // значение. Это «проброс исключения», только явный и видимый в сигнатуре.
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

/// `Box<dyn Error>` — «любая ошибка» (C#: `catch (Exception)`). Удобно в приложениях;
/// в библиотеках предпочитают конкретные enum-ы. `?` сам упаковывает ошибку через From.
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

/// Функция, которая может не выполниться, возвращает `Result`. `()` — «успех без данных».
fn section06_errors() -> Result<(), Box<dyn Error>> {
    header(6, "Error handling");

    let configs = [
        HashMap::from([("port", "8080")]),
        HashMap::from([("host", "localhost")]),
        HashMap::from([("port", "80a")]),
        HashMap::from([("port", "70000")]),
    ];
    for config in &configs {
        // Result — обычный enum: разбираем его через match.
        match read_port(config) {
            Ok(port) => println!("port = {port}"),
            // Образец с привязкой: отдельная ветка для конкретного варианта ошибки.
            Err(error @ ConfigError::InvalidNumber { .. }) => {
                println!("error: {error}; caused by: {}", error.source().unwrap())
            }
            Err(error) => println!("error: {error}"),
        }
    }

    // Комбинаторы Result — как у Option.
    let port_or_default = read_port(&configs[1]).unwrap_or(8000);
    let as_text = read_port(&configs[0]).map(|p| format!("http://localhost:{p}"));
    println!(
        "{port_or_default} | {as_text:?} | {}",
        read_port(&configs[3]).is_err()
    );

    println!("average = {}", average("1.5, 2.5, 5")?); // `?` в действии: Ok -> значение
    for bad in ["", "1, two, 3"] {
        if let Err(error) = average(bad) {
            println!("average({bad:?}) failed: {error}");
        }
    }

    // --- Паника -----------------------------------------------------------------
    // `panic!` (а также unwrap на None, выход за границы, деление на ноль) раскручивает
    // стек, вызывая Drop у локальных значений, и завершает ПОТОК. Это не механизм
    // обработки ошибок: `catch_unwind` нужен только на границах (FFI, пул потоков).
    let default_hook = std::panic::take_hook();
    std::panic::set_hook(Box::new(|_| {})); // на время демонстрации не печатаем трассировку
    let outcome = std::panic::catch_unwind(|| {
        let empty: Vec<i32> = Vec::new();
        empty[0] // паника: index out of bounds
    });
    std::panic::set_hook(default_hook);
    println!("catch_unwind caught a panic: {}", outcome.is_err());

    Ok(())
}

// =====================================================================================
//  7. КОЛЛЕКЦИИ
// =====================================================================================

fn section07_collections() {
    header(7, "Collections");

    // --- Vec<T> — динамический массив. C#: List<T> -----------------------------------
    let mut values: Vec<i32> = Vec::new();
    values.push(3);
    values.extend([1, 4, 1, 5, 9, 2, 6]);
    let mut sorted = values.clone();
    sorted.sort(); // на месте; sort_unstable() быстрее, sort_by_key(..) — по ключу
    sorted.dedup(); // убрать соседние дубликаты
    sorted.retain(|v| *v != 9); // C#: RemoveAll(v => v == 9)
    sorted.insert(0, 0); // вставка в начало — O(n), как и в List<T>
    let last = sorted.pop(); // Option<i32>: у пустого вектора вернёт None
    println!(
        "{values:?} -> {sorted:?}, popped {last:?}, capacity {}",
        sorted.capacity()
    );

    // Макрос `vec!`: длина известна только во время выполнения — массив не подошёл бы.
    let zeros = vec![0_u8; values.len() * 2];
    // Методы срезов доступны и массивам, и Vec.
    let words = ["delta", "alpha", "charlie", "bravo"];
    println!(
        "{} {:?} {:?} {:?} {:?}",
        zeros.len(),
        words.first(), // Option<&&str>
        words.contains(&"alpha"),
        sorted.binary_search(&4), // Ok(индекс) или Err(место для вставки)
        words.concat().len()
    );
    for pair in values.windows(2).take(2) {
        print!("window {pair:?}; "); // скользящее окно
    }
    for chunk in values.chunks(3) {
        print!("chunk {chunk:?}; "); // непересекающиеся куски
    }
    println!();

    // Три способа обойти коллекцию:
    //   for x in &v      — по разделяемым ссылкам, v остаётся доступным;
    //   for x in &mut v  — по изменяемым ссылкам, элементы можно менять;
    //   for x in v       — ПОГЛОЩАЕТ коллекцию и отдаёт элементы во владение.
    let mut squares = vec![1, 2, 3];
    for value in &mut squares {
        *value *= *value;
    }
    for value in squares {
        print!("{value} ");
    }
    println!("<- squares"); // после `for value in squares` вектора больше нет: он поглощён

    // --- HashMap<K, V>. C#: Dictionary<TKey, TValue> ---------------------------------
    let mut stock: HashMap<String, u32> = HashMap::new();
    stock.insert("bolt".to_string(), 10);
    stock.insert("nut".to_string(), 0);
    // `get` возвращает Option<&V>: никакого KeyNotFoundException.
    println!(
        "bolt: {:?}, screw: {:?}",
        stock.get("bolt"),
        stock.get("screw")
    );
    // Entry API — «найти или вставить» за один поиск по хешу.
    *stock.entry("screw".to_string()).or_insert(0) += 25;
    stock
        .entry("bolt".to_string())
        .and_modify(|n| *n -= 3)
        .or_insert(0);
    if let Some(removed) = stock.remove("nut") {
        println!("removed nut with quantity {removed}");
    }

    // Подсчёт частот — идиома на entry + or_default.
    let text = "the quick brown fox jumps over the lazy dog the end";
    let mut frequency: HashMap<&str, usize> = HashMap::new();
    for word in text.split(' ') {
        *frequency.entry(word).or_default() += 1;
    }
    // Порядок обхода HashMap не определён (и нарочно меняется от запуска к запуску:
    // защита от HashDoS), поэтому для вывода сортируем.
    let mut top: Vec<(&str, usize)> = frequency.into_iter().collect();
    top.sort_by(|a, b| b.1.cmp(&a.1).then(a.0.cmp(b.0))); // по убыванию частоты, затем по слову
    println!("top words: {:?}", &top[..3]);

    // --- Остальные стандартные коллекции --------------------------------------------
    // BTreeMap — упорядоченный словарь. C#: SortedDictionary.
    let mut by_name: BTreeMap<&str, u32> = stock.iter().map(|(k, v)| (k.as_str(), *v)).collect();
    by_name.insert("anchor", 7);
    println!(
        "{by_name:?}, range b..n: {:?}",
        by_name.range("b".."n").collect::<Vec<_>>()
    );

    // HashSet — множество с операциями над множествами.
    let a: HashSet<i32> = HashSet::from([1, 2, 3, 4]);
    let b: HashSet<i32> = (3..=6).collect();
    let mut common: Vec<_> = a.intersection(&b).copied().collect();
    common.sort();
    println!(
        "intersection {common:?}, union size {}",
        a.union(&b).count()
    );

    // VecDeque — двусторонняя очередь на кольцевом буфере (C#: Queue<T>, но с обоими концами).
    let mut queue: VecDeque<&str> = VecDeque::from(["second", "third"]);
    queue.push_front("first");
    queue.push_back("fourth");
    println!(
        "{:?} then {:?}, left {queue:?}",
        queue.pop_front(),
        queue.pop_back()
    );

    // BinaryHeap — куча с МАКСИМУМОМ на вершине (C#: PriorityQueue, там на вершине минимум).
    let mut heap = BinaryHeap::from([3, 8, 1, 5]);
    heap.push(7);
    println!(
        "heap max {:?}, sorted {:?}",
        heap.peek().copied(),
        heap.into_sorted_vec()
    );
}

// =====================================================================================
//  8. ЗАМЫКАНИЯ И ИТЕРАТОРЫ
// =====================================================================================

/// Функция высшего порядка. `impl Fn(i32) -> i32` — «любой тип, реализующий Fn».
/// Для каждого переданного замыкания компилятор создаёт свою копию функции и может
/// заинлайнить вызов. C#: `Func<int, int>`, но там вызов идёт через делегат.
fn apply_twice(f: impl Fn(i32) -> i32, x: i32) -> i32 {
    f(f(x))
}

/// Вернуть замыкание можно как `impl Fn` — конкретный, но безымянный тип...
fn make_adder(n: i32) -> impl Fn(i32) -> i32 {
    move |x| x + n // `move`: замыкание забирает n себе, иначе ссылка пережила бы функцию
}

/// ...или как `Box<dyn Fn>` — если под одним типом нужны РАЗНЫЕ замыкания (≈ делегат).
fn make_operation(symbol: char) -> Box<dyn Fn(f64, f64) -> f64> {
    match symbol {
        '+' => Box::new(|a, b| a + b),
        '*' => Box::new(|a, b| a * b),
        '^' => Box::new(f64::powf), // обычная функция тоже реализует Fn
        _ => Box::new(|_, _| f64::NAN),
    }
}

/// Свой итератор: достаточно реализовать `next()`, и все адаптеры (map, filter, zip, ...)
/// появятся автоматически. C#: IEnumerator<T> или метод с `yield return`.
struct Fibonacci {
    current: Option<u64>, // None — ряд закончился: следующее число не помещается в u64
    next: Option<u64>,
}

impl Iterator for Fibonacci {
    type Item = u64; // ассоциированный тип: что выдаёт итератор

    fn next(&mut self) -> Option<u64> {
        let value = self.current?; // `?` работает и с Option: None => сразу вернуть None
        let following = self.next.and_then(|n| n.checked_add(value)); // None при переполнении
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

    // --- Замыкания ----------------------------------------------------------------
    // Синтаксис: |параметры| выражение. Типы выводятся. У каждого замыкания свой
    // уникальный тип; что оно умеет, описывают три трейта:
    //   Fn      — только читает захваченное (можно вызывать сколько угодно раз);
    //   FnMut   — изменяет захваченное (нужен эксклюзивный доступ);
    //   FnOnce  — поглощает захваченное (вызвать можно один раз).
    let factor = 3;
    let triple = |x: i32| x * factor; // Fn: заимствует factor по `&`
    let mut calls = 0;
    let mut count_and_add = |x: i32| {
        calls += 1; // FnMut: заимствует calls по `&mut`
        x + 1
    };
    let (first, second) = (count_and_add(1), count_and_add(10));
    println!(
        "triple(7) = {}, twice = {}, {first} {second} calls = {calls}",
        triple(7),
        apply_twice(triple, 2)
    );

    let token = String::from("one-shot");
    let give_away = move || token; // возвращает захваченное значение => FnOnce
    let received = give_away();
    // give_away(); // E0382: замыкание уже израсходовано
    let add_five = make_adder(5);
    println!(
        "{received} | {} | {} | {}",
        add_five(1),
        make_operation('*')(6.0, 7.0),
        make_operation('^')(2.0, 10.0)
    );

    // --- Итераторы — LINQ без накладных расходов -------------------------------------
    // Ленивы, как IEnumerable<T>: цепочка ничего не делает, пока её не «потребят»
    // (collect, sum, for, ...). В отличие от LINQ, цепочка компилируется в обычный цикл
    // без аллокаций и виртуальных вызовов.
    let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    let even_squares: Vec<i32> = numbers
        .iter() // итератор по ссылкам &i32
        .filter(|&&x| x % 2 == 0) // C#: Where
        .map(|&x| x * x) // C#: Select
        .collect(); // C#: ToList; целевой тип задаёт аннотация слева
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
    let initials: String = words.iter().filter_map(|w| w.chars().next()).collect(); // в String
    let longest = words.iter().max_by_key(|w| w.len()); // C#: MaxBy
    let shouted = words.map(|w| w.to_uppercase()).join(", "); // map есть и у массивов
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

    // collect умеет «выворачивать» типы: итератор из Result -> Result с вектором внутри.
    let parsed: Result<Vec<i32>, _> = ["1", "2", "3"].iter().map(|s| s.parse::<i32>()).collect();
    let failed: Result<Vec<i32>, _> = ["1", "x", "3"].iter().map(|s| s.parse::<i32>()).collect();
    println!("{parsed:?} | {}", failed.is_err());

    // Свой итератор со стандартными адаптерами.
    let below_100: Vec<u64> = fibonacci().take_while(|&x| x < 100).collect();
    let every_third: Vec<u64> = fibonacci().skip(10).step_by(3).take(3).collect();
    println!(
        "{below_100:?} {every_third:?} terms that fit in u64: {}",
        fibonacci().count()
    );

    // Генераторы «на лету»: successors и from_fn вместо `yield return`.
    let powers: Vec<u32> = std::iter::successors(Some(1_u32), |&x| x.checked_mul(10)).collect();
    let mut state = 0;
    let countdown: Vec<i32> = std::iter::from_fn(|| {
        state += 1;
        (state <= 3).then_some(4 - state) // bool -> Option
    })
    .collect();
    println!("{} powers of ten fit in u32; {countdown:?}", powers.len());

    // Сортировка по нескольким ключам. C#: OrderBy(..).ThenBy(..).
    let mut people = [("Ann", 30), ("Bob", 25), ("Cid", 30), ("Dan", 25)];
    people.sort_by(|a, b| b.1.cmp(&a.1).then_with(|| a.0.cmp(b.0)));
    // Группировка соседних элементов. Полноценный GroupBy делают через HashMap + entry.
    let groups: Vec<(i32, Vec<&str>)> = people
        .chunk_by(|a, b| a.1 == b.1)
        .map(|group| (group[0].1, group.iter().map(|p| p.0).collect()))
        .collect();
    println!("{groups:?}");
}

// =====================================================================================
//  9. ТРЕЙТЫ И ОБОБЩЕНИЯ
// =====================================================================================
//
//  Трейт ≈ интерфейс C#, но шире:
//    - его можно реализовать для ЧУЖОГО типа, в том числе встроенного (i32, Vec<T>, str);
//    - в нём бывают методы по умолчанию, ассоциированные типы и константы, функции
//      без self (C#: static abstract);
//    - один и тот же трейт служит и статическому полиморфизму (обобщения: вызов
//      разрешается при компиляции), и динамическому (`dyn Trait`: вызов через vtable).
//  Ограничение (orphan rule): реализовать можно либо СВОЙ трейт, либо для СВОЕГО типа.

trait Describe {
    /// Ассоциированная константа со значением по умолчанию.
    const KIND: &'static str = "value";

    /// Обязательный метод.
    fn name(&self) -> String;

    /// Метод с реализацией по умолчанию. C#: default interface method.
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

/// Реализация своего трейта для встроенного типа: у i32 появляется метод `describe()`.
impl Describe for i32 {
    fn name(&self) -> String {
        self.to_string()
    }
}

/// Blanket-реализация: «для ЛЮБОГО `T: Describe` вектор `Vec<T>` — тоже Describe».
impl<T: Describe> Describe for Vec<T> {
    const KIND: &'static str = "list";

    fn name(&self) -> String {
        self.iter()
            .map(|item| item.name())
            .collect::<Vec<_>>()
            .join("+")
    }
}

/// Extension trait — идиома «методы расширения» для чужого типа (здесь — для `str`).
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

/// Обобщённая функция с ограничениями (trait bounds). C#: `where T : IComparable<T>`.
/// МОНОМОРФИЗАЦИЯ: для каждого использованного T компилируется отдельная версия
/// (как шаблоны C++), поэтому вызовы статические и инлайнятся.
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

/// `impl Trait` в аргументе — сахар для безымянного параметра-типа.
fn print_description(item: &impl Describe) {
    println!("    {}", item.describe());
}

/// Обобщённая арифметика через трейты операторов; условия вынесены в `where`.
/// C#: generic math (`INumber<T>`).
fn dot<T>(a: &[T], b: &[T]) -> T
where
    T: Copy + Default + std::ops::Add<Output = T> + std::ops::Mul<Output = T>,
{
    a.iter()
        .zip(b)
        .fold(T::default(), |acc, (&x, &y)| acc + x * y)
}

/// `impl Trait` в возвращаемом типе: «некий тип, реализующий Iterator» — конкретный,
/// но безымянный (типы цепочек итераторов и замыканий руками не записать).
fn even_squares(limit: u32) -> impl Iterator<Item = u32> {
    (0..=limit).filter(|n| n % 2 == 0).map(|n| n * n)
}

/// Обобщённая структура. C#: `class Stack<T>`.
#[derive(Debug, Clone, Default)]
struct Stack<T> {
    items: Vec<T>,
}

impl<T> Stack<T> {
    fn new() -> Self {
        Self { items: Vec::new() }
    }

    /// Возврат `&mut Self` позволяет вызывать методы цепочкой.
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

/// Блок impl с дополнительным ограничением: метод существует только при `T: Display`.
/// В C# такое возможно лишь через метод расширения с ограничением.
impl<T: fmt::Display> Stack<T> {
    fn render(&self) -> String {
        self.items
            .iter()
            .map(|item| item.to_string())
            .collect::<Vec<_>>()
            .join(" > ")
    }
}

/// Индексатор. C#: `public T this[int index]`.
impl<T> std::ops::Index<usize> for Stack<T> {
    type Output = T;

    fn index(&self, index: usize) -> &T {
        &self.items[index]
    }
}

/// `for item in &stack` — достаточно реализовать IntoIterator для ссылки.
/// C#: `IEnumerable<T>.GetEnumerator()`.
impl<'a, T> IntoIterator for &'a Stack<T> {
    type Item = &'a T;
    type IntoIter = std::slice::Iter<'a, T>;

    fn into_iter(self) -> Self::IntoIter {
        self.items.iter()
    }
}

/// `iterator.collect::<Stack<_>>()` — через FromIterator.
impl<T> FromIterator<T> for Stack<T> {
    fn from_iter<I: IntoIterator<Item = T>>(iter: I) -> Self {
        Self {
            items: iter.into_iter().collect(),
        }
    }
}

/// From/Into — стандартные преобразования без потерь (C#: implicit operator).
/// Реализовали From — Into получили бесплатно.
impl From<(f64, f64)> for Vec2 {
    fn from((x, y): (f64, f64)) -> Self {
        Vec2::new(x, y) // образец-кортеж стоит прямо в списке параметров
    }
}

/// TryFrom — преобразование, которое может не удаться (C#: explicit operator + исключение).
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

/// FromStr подключает тип к `str::parse`. C#: `IParsable<T>`.
impl std::str::FromStr for Vec2 {
    type Err = String;

    fn from_str(text: &str) -> Result<Self, Self::Err> {
        let (x, y) = text.split_once(',').ok_or("expected 'x,y'")?; // &str -> String через From
        let number = |part: &str| part.trim().parse::<f64>().map_err(|e| e.to_string());
        Ok(Vec2::new(number(x)?, number(y)?))
    }
}

trait HasArea {
    fn area(&self) -> f64;
}

/// Супертрейт: всякий Drawable обязан быть ещё HasArea и Debug (≈ наследование интерфейсов).
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

impl Drawable for Circle {} // все методы берём по умолчанию

impl Drawable for Square {
    fn draw(&self) -> String {
        format!("square {0} x {0}", self.side)
    }
}

/// Статическая диспетчеризация: T известен при компиляции, вызов `area()` инлайнится.
fn total_area_static<T: HasArea>(shapes: &[T]) -> f64 {
    shapes.iter().map(|shape| shape.area()).sum()
}

/// Динамическая диспетчеризация. `dyn HasArea` — трейт-объект; указатель на него
/// «толстый»: адрес данных + адрес таблицы методов. Так устроены интерфейсы в C#.
/// Нужна, когда в одной коллекции лежат значения РАЗНЫХ типов.
fn total_area_dynamic(shapes: &[Box<dyn HasArea>]) -> f64 {
    shapes.iter().map(|shape| shape.area()).sum()
}

/// Const generics: параметр-ЗНАЧЕНИЕ в типе (в C# аналога нет; C++: `template<size_t N>`).
/// `Matrix<2, 3>` и `Matrix<3, 2>` — разные типы; размеры проверяются при компиляции.
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

/// Умножение определено только для согласованных размеров: (R x K) * (K x C) = (R x C).
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
        <i32 as Describe>::KIND, // полный синтаксис: «KIND из реализации Describe для i32»
        "A man, a plan, a canal: Panama".is_palindrome()
    );

    // Тип обычно выводится из аргументов; при необходимости его указывают явно
    // синтаксисом «turbofish»: `largest::<u8>(...)`.
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

    // Свой обобщённый контейнер, подключённый к языку: цепочки, индексатор, for, collect.
    let mut stack = Stack::new(); // T выведется из первого push
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
    // Stack::<Shape>::new().render(); // E0599: Shape не Display, метода render у него нет

    // Преобразования.
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

    // Свой тип как ключ словаря: достаточно derive(PartialEq, Eq, Hash).
    // (Элементы — struct, fn, impl — можно объявлять и внутри функции.)
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

    // Статическая и динамическая диспетчеризация.
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
    // Приведение трейт-объекта к супертрейту (upcasting, Rust 1.86).
    let as_area: &dyn HasArea = drawables[0];
    println!(
        "    upcast area {:.3}; size_of: &dyn HasArea = {}, &Circle = {}",
        as_area.area(),
        size_of::<&dyn HasArea>(), // 16: два указателя
        size_of::<&Circle>()       // 8
    );

    // Const generics.
    let m = Matrix {
        data: [[1.0, 2.0, 3.0], [4.0, 5.0, 6.0]],
    }; // Matrix<2, 3>
    let product = m * m.transpose(); // Matrix<2, 3> * Matrix<3, 2> = Matrix<2, 2>
    // let bad = m * m; // E0308: Matrix<2, 3> нельзя умножить на Matrix<2, 3>
    println!("m * mT = {:?}", product.data);
}

// =====================================================================================
//  10. ВРЕМЕНА ЖИЗНИ (LIFETIMES)
// =====================================================================================
//
//  Время жизни — участок кода, на котором ссылка гарантированно действительна.
//  Компилятор отслеживает его для каждой ссылки. Аннотация `'a` ничего не продлевает:
//  она лишь СВЯЗЫВАЕТ ссылки в сигнатуре, чтобы можно было проверить вызывающий код.

/// «Результат живёт не дольше, чем ОБА аргумента».
/// Без аннотации — E0106: компилятор не знает, от какого аргумента зависит результат.
fn longest<'a>(a: &'a str, b: &'a str) -> &'a str {
    if a.len() >= b.len() { a } else { b }
}

// В простых случаях аннотации выводятся сами (lifetime elision). Запись
//     fn first_word(text: &str) -> &str
// это сокращение для
//     fn first_word<'a>(text: &'a str) -> &'a str

#[derive(Debug, Clone, Copy, PartialEq)]
enum TokenKind {
    Number,
    Ident,
    Symbol,
}

/// Структура, хранящая ссылку, обязана объявить время жизни: экземпляр не может
/// пережить данные, на которые смотрит. C#: `ref struct` с ref-полями — похожая идея.
#[derive(Debug)]
struct Token<'src> {
    kind: TokenKind,
    text: &'src str,
}

/// Лексер без копирования: токены — срезы исходной строки, ни одной аллокации под текст.
struct Lexer<'src> {
    rest: &'src str,
}

impl<'src> Lexer<'src> {
    fn new(source: &'src str) -> Self {
        Self { rest: source }
    }
}

impl<'src> Iterator for Lexer<'src> {
    type Item = Token<'src>; // токены привязаны к исходной строке, а не к лексеру

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
        let winner = longest(&outer, &inner); // 'a = пересечение областей outer и inner
        length = winner.len(); // наружу уходит число, а не ссылка — всё в порядке
        // Если вынести из блока сам `winner`: E0597 `inner` does not live long enough.
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

    // `'static` — «действительна до конца программы»: строковые литералы, static-переменные
    // и сознательно «утёкшая» память.
    let literal: &'static str = "string literals live in the binary";
    let leaked: &'static mut Vec<i32> = Box::leak(Box::new(vec![1, 2, 3]));
    leaked.push(4);
    println!("{literal} | leaked: {leaked:?}");
    // Ограничение `T: 'static` значит «T не содержит недолговечных ссылок»: таким
    // значением можно владеть сколько угодно. Его требует, например, `thread::spawn`.
}

// =====================================================================================
//  11. УМНЫЕ УКАЗАТЕЛИ И ВНУТРЕННЯЯ ИЗМЕНЯЕМОСТЬ
// =====================================================================================

/// `Box<T>` — единоличное владение значением в куче (C++: unique_ptr). Нужен для:
///   - рекурсивных типов (иначе размер был бы бесконечным);
///   - трейт-объектов `Box<dyn Trait>`;
///   - больших значений, которые не хочется перемещать побайтно.
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

/// `Rc<T>` — подсчёт ссылок для РАЗДЕЛЯЕМОГО владения в одном потоке (C++: shared_ptr;
/// в C# так ведёт себя любая ссылка на объект, только вместо счётчика — GC).
///
/// Rc даёт доступ только на чтение. Чтобы менять общее значение, нужна «внутренняя
/// изменяемость»: `RefCell<T>` переносит проверку правил заимствования из компиляции
/// в рантайм (нарушение — паника, а не порча памяти).
///
/// `Weak<T>` — слабая ссылка (C#: WeakReference<T>). Без неё цикл из Rc утёк бы: GC нет.
#[derive(Debug)]
struct TreeNode {
    name: String,
    parent: RefCell<Weak<TreeNode>>,      // вверх — слабая ссылка
    children: RefCell<Vec<Rc<TreeNode>>>, // вниз — сильные
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
        // upgrade: Weak -> Option<Rc>, т.е. «жив ли ещё родитель?»
        match self.parent.borrow().upgrade() {
            Some(parent) => format!("{}/{}", parent.path(), self.name),
            None => self.name.clone(),
        }
    }
}

/// `Cow` (clone on write): либо заимствованные данные, либо собственные.
/// Позволяет не аллоцировать, когда менять ничего не пришлось.
fn escape_html(input: &str) -> Cow<'_, str> {
    if !input.contains(['<', '>', '&']) {
        return Cow::Borrowed(input); // быстрый путь: ни одной аллокации
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

/// Свой умный указатель. Трейт `Deref` включает авторазыменование: методы T можно
/// вызывать прямо на обёртке. `Cell<T>` — внутренняя изменяемость для Copy-значений:
/// счётчик меняется даже через `&self`.
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

    // Box: значение в куче, указатель на стеке. Разыменование — оператором `*`.
    let boxed = Box::new(41);
    println!("boxed + 1 = {}", *boxed + 1);

    // -(x + 2) * 3 — дерево выражения из рекурсивного enum.
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

    // Rc: клонирование увеличивает счётчик, данные не копируются.
    let shared = Rc::new(String::from("shared text"));
    let alias = Rc::clone(&shared);
    println!(
        "strong count = {}, same allocation: {}",
        Rc::strong_count(&shared),
        Rc::ptr_eq(&shared, &alias)
    );
    drop(alias);
    println!("strong count after drop = {}", Rc::strong_count(&shared));

    // RefCell: borrow() и borrow_mut() проверяются во время выполнения.
    let cell = RefCell::new(vec![1, 2, 3]);
    cell.borrow_mut().push(4);
    {
        let reader = cell.borrow();
        let writer = cell.try_borrow_mut(); // Err: уже есть читатель
        println!(
            "{reader:?}; try_borrow_mut while reading fails: {}",
            writer.is_err()
        );
    }

    // Дерево с обратными ссылками: Rc вниз, Weak вверх.
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
    drop(root); // корень уничтожен: слабая ссылка usr.parent больше не «поднимается»
    println!("{} after the root is dropped", bin.path());

    // Cow: аллокация только когда она действительно нужна.
    for input in ["plain text", "a < b && b > c"] {
        let escaped = escape_html(input);
        let kind = if matches!(escaped, Cow::Borrowed(_)) {
            "borrowed"
        } else {
            "owned"
        };
        println!("{kind}: {escaped}");
    }

    // Deref: len() и to_uppercase() — методы str, вызванные через Tracked<String>.
    let tracked = Tracked {
        value: String::from("deref"),
        reads: Cell::new(0),
    };
    let summary = format!("{} {}", tracked.len(), tracked.to_uppercase());
    println!("{summary}, value was read {} times", tracked.reads.get());
}

// =====================================================================================
//  12. МОДУЛИ, АТРИБУТЫ, ТЕСТЫ
// =====================================================================================

/// Модуль — единица инкапсуляции (C#: namespace и internal сразу). Всё приватно по
/// умолчанию, причём граница приватности — МОДУЛЬ, а не тип. В настоящем проекте
/// строка `mod geometry;` подключила бы файл geometry.rs; здесь модуль встроенный.
mod geometry {
    use std::sync::atomic::{AtomicU32, Ordering};

    /// `pub` — элемент виден снаружи модуля.
    #[derive(Debug, Clone, Copy)]
    pub struct Rect {
        pub width: f64,
        pub height: f64,
        id: u32, // приватное поле: снаружи модуля литералом `Rect { .. }` значение не создать
    }

    impl Rect {
        pub fn new(width: f64, height: f64) -> Self {
            Self {
                width,
                height,
                id: next_id(),
            }
        }

        /// «Геттер» — обычный метод: свойств (property) в языке нет.
        pub fn id(&self) -> u32 {
            self.id
        }

        pub fn area(&self) -> f64 {
            self.width * self.height
        }

        /// `pub(crate)` — виден во всём крейте, но не снаружи (C#: internal).
        pub(crate) fn scale(&mut self, factor: f64) {
            self.width *= factor;
            self.height *= factor;
        }
    }

    /// Приватная функция модуля.
    fn next_id() -> u32 {
        // static внутри функции: виден только здесь, живёт всю программу.
        static NEXT_ID: AtomicU32 = AtomicU32::new(1);
        NEXT_ID.fetch_add(1, Ordering::Relaxed)
    }

    /// Вложенный модуль. `super::` — родительский модуль, `crate::` — корень крейта.
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

// `use` умеет группировать и переименовывать. C#: `using Rectangle = Geometry.Rect;`.
use geometry::Rect as Rectangle;
use geometry::units::{self, inches_to_mm};

/// Атрибуты (C#: `[Attributes]`) — указания компилятору.
#[must_use = "a checksum is useless unless it is checked"] // предупредить, если результат отброшен
#[inline] // подсказка оптимизатору
fn checksum(data: &[u8]) -> u32 {
    data.iter()
        .fold(0_u32, |acc, &byte| acc.rotate_left(5) ^ u32::from(byte))
}

#[deprecated(since = "0.2.0", note = "use `checksum` instead")] // C#: [Obsolete]
fn old_checksum(data: &[u8]) -> u32 {
    checksum(data)
}

/// Условная компиляция (C#: `#if`). Функция существует только на подходящей платформе.
#[cfg(target_os = "windows")]
fn platform_name() -> &'static str {
    "Windows"
}

#[cfg(not(target_os = "windows"))]
fn platform_name() -> &'static str {
    "Unix-like"
}

/// Модульные тесты — часть языка и живут рядом с кодом. `#[cfg(test)]`: модуль
/// компилируется только командой `rustc --test` / `cargo test`.
/// C#: отдельный проект с xUnit или NUnit.
#[cfg(test)]
mod tests {
    use super::*; // тесты видят и приватные элементы родительского модуля

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

    let mut rect = Rectangle::new(3.0, 4.0); // geometry::Rect под псевдонимом
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

    #[allow(deprecated)] // атрибут можно повесить и на отдельный оператор
    let legacy = old_checksum(b"rust");
    println!(
        "checksum {:#010x} (legacy {legacy:#010x}), platform: {}, debug build: {}",
        checksum(b"rust"),
        platform_name(),
        cfg!(debug_assertions) // cfg! — то же условие в виде выражения
    );
    // Макросы с информацией о месте в коде. C#: [CallerFilePath], [CallerLineNumber].
    println!("{}:{} in module `{}`", file!(), line!(), module_path!());
}

// =====================================================================================
//  13. МНОГОПОТОЧНОСТЬ
// =====================================================================================
//
//  Потокобезопасность встроена в систему типов через два маркерных трейта:
//    Send — значение можно ПЕРЕДАТЬ в другой поток;
//    Sync — на значение можно ССЫЛАТЬСЯ из нескольких потоков одновременно.
//  Компилятор выводит их автоматически. `Rc<T>`, `RefCell<T>` и сырые указатели ими
//  не обладают, поэтому гонка данных в безопасном Rust — ошибка компиляции.

fn section13_concurrency() {
    header(13, "Concurrency");

    // --- Поток ОС -------------------------------------------------------------------
    // `spawn` принимает замыкание и возвращает JoinHandle<T>. C#: Task.Run / new Thread.
    // Замыкание должно быть `Send + 'static`, поэтому данные в него перемещают (`move`).
    let limit = 1000_u64;
    let handle = thread::spawn(move || (1..=limit).sum::<u64>());
    let total = handle.join().expect("worker panicked"); // Err, если поток запаниковал
    println!("sum computed in another thread: {total}");

    // --- Arc<Mutex<T>>: общее изменяемое состояние -----------------------------------
    // Мьютекс ВЛАДЕЕТ данными: добраться до них, не взяв блокировку, невозможно.
    // (В C# `lock (obj)` и защищаемые поля связаны только договорённостью.)
    // Arc — потокобезопасный Rc с атомарным счётчиком.
    let counter = Arc::new(Mutex::new(0_u64));
    let mut workers = Vec::new();
    for _ in 0..4 {
        let counter = Arc::clone(&counter); // свой экземпляр Arc для каждого потока
        workers.push(thread::spawn(move || {
            for _ in 0..1000 {
                let mut guard = counter.lock().unwrap(); // MutexGuard — RAII-блокировка
                *guard += 1;
            } // блокировка снимается при уничтожении guard
        }));
    }
    for worker in workers {
        worker.join().unwrap();
    }
    println!("counter = {}", *counter.lock().unwrap());

    // --- Scoped threads: потоки, заимствующие локальные данные ------------------------
    // `scope` гарантирует, что все потоки завершатся до выхода из блока, поэтому
    // им можно отдать обычные ссылки на стек — без Arc и без `'static`.
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

    // --- Каналы ---------------------------------------------------------------------
    // mpsc = multiple producers, single consumer. C#: System.Threading.Channels.
    let (sender, receiver) = mpsc::channel::<String>();
    for id in 0..3 {
        let sender = sender.clone();
        thread::spawn(move || {
            sender.send(format!("worker {id} done")).unwrap(); // сообщение ПЕРЕМЕЩАЕТСЯ в канал
        });
    }
    drop(sender); // канал закроется, когда исчезнут все отправители
    let mut messages: Vec<String> = receiver.iter().collect(); // до закрытия канала
    messages.sort(); // порядок прихода сообщений не определён
    println!("{messages:?}");

    // --- Атомики. C#: Interlocked ---------------------------------------------------
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

    // --- RwLock: много читателей или один писатель. C#: ReaderWriterLockSlim ---------
    let settings = RwLock::new(HashMap::from([("mode", "fast")]));
    let before = settings.read().unwrap()["mode"];
    settings.write().unwrap().insert("mode", "safe");
    println!("mode: {before} -> {}", settings.read().unwrap()["mode"]);

    // --- Ленивая глобальная инициализация. C#: Lazy<T> --------------------------------
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

    // --- Send и Sync проверяются при компиляции ---------------------------------------
    fn assert_send<T: Send>() {}
    assert_send::<Arc<Mutex<Vec<i32>>>>();
    // assert_send::<Rc<i32>>(); // E0277: `Rc<i32>` cannot be sent between threads safely
}

// =====================================================================================
//  14. МАКРОСЫ
// =====================================================================================
//
//  Имя с восклицательным знаком (println!, vec!, format!) — это макрос: код, который
//  порождает код на этапе компиляции. Макросы принимают произвольное число аргументов
//  и проверяют форматные строки при компиляции — обычная функция так не может.
//  В C# ближайший аналог — source generators, но они заметно тяжелее в написании.

/// Декларативный макрос: сопоставление с образцом по ТОКЕНАМ.
///   `$key:expr`   — фрагмент-выражение (ещё бывают ident, ty, literal, pat, tt, ...);
///   `$( ... ),*`  — повторение через запятую, ноль или более раз;
///   `$(,)?`       — необязательная запятая в конце.
/// Макросы гигиеничны: локальная `map` внутри не конфликтует с вашей переменной `map`.
macro_rules! hashmap {
    ($($key:expr => $value:expr),* $(,)?) => {{
        let mut map = ::std::collections::HashMap::new();
        $( map.insert($key, $value); )*
        map
    }};
}

/// Рекурсивный макрос с двумя ветками: `max!(a, b, c, ...)` для любого числа аргументов.
macro_rules! max {
    ($only:expr) => { $only };
    ($first:expr, $($rest:expr),+) => {{
        let (a, b) = ($first, max!($($rest),+));
        if a > b { a } else { b }
    }};
}

/// Макрос, порождающий ЭЛЕМЕНТЫ (тип и его impl-ы): так избавляются от шаблонного кода.
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

/// Частый приём: реализовать трейт сразу для списка типов.
macro_rules! impl_describe_for_numbers {
    ($($ty:ty),+) => {
        $(
            impl Describe for $ty {
                fn name(&self) -> String {
                    format!("{self}{}", stringify!($ty)) // stringify! — токены как строка
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
    // let nonsense = Kilograms(1.0) + Newtons(1.0); // E0308: типы из макроса не смешиваются

    // Встроенные макросы.
    let value = 6 * 7;
    println!("{} = {value}", stringify!(6 * 7)); // C#: [CallerArgumentExpression]
    println!("{}", concat!("glued ", "at ", "compile time"));
    assert!(value > 0, "value must be positive, got {value}"); // паника с сообщением, если ложно
    assert_eq!(value, 42);
    debug_assert!(value < 100); // проверяется только в debug-сборке. C#: Debug.Assert
    // Ещё пригодятся:
    //   todo!(), unimplemented!(), unreachable!() — заглушки: компилируются, но паникуют;
    //   dbg!(expr) — печатает в stderr файл, строку, выражение и значение, возвращает значение;
    //   include_str!("file.txt"), include_bytes!(..) — вшить файл в программу при компиляции;
    //   env!("VAR") — значение переменной окружения на момент компиляции;
    //   compile_error!("...") — остановить компиляцию с вашим сообщением.
    //
    // Процедурные макросы (`#[derive(Serialize)]`, `#[tokio::main]`, `sqlx::query!`) — это
    // обычные Rust-функции «токены -> токены». Они живут в отдельном крейте, поэтому
    // в одном файле их не показать.
}

// =====================================================================================
//  15. ВЫЧИСЛЕНИЯ НА ЭТАПЕ КОМПИЛЯЦИИ
// =====================================================================================

/// `const fn` можно вызывать при компиляции (C++: constexpr). В C# такого нет: там
/// константой может быть только выражение из литералов.
const fn factorial(n: u64) -> u64 {
    if n <= 1 { 1 } else { n * factorial(n - 1) }
}

const FACTORIAL_20: u64 = factorial(20); // вычислено компилятором, в программе — готовое число

/// Таблица CRC-32, построенная при компиляции. В const fn разрешены циклы, ветвления
/// и изменяемые локальные переменные, но пока нельзя `for`: итераторы — это трейты,
/// а вызывать методы трейтов в константных вычислениях ещё нельзя. Поэтому `while`.
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

// Проверки на этапе компиляции (C++: static_assert). `const _` — безымянная константа,
// нужная только ради вычисления её значения.
const _: () = assert!(size_of::<Vec2>() == 16, "Vec2 must stay two f64 wide");
// Эталонное значение CRC-32 для "123456789": модульный тест, который выполняет компилятор.
const _: () = assert!(crc32(b"123456789") == 0xCBF4_3926);

/// Проверка параметра обобщения: блок `const { }` вычисляется для каждого N отдельно.
fn first_element<const N: usize>(values: [i32; N]) -> i32 {
    const { assert!(N > 0, "the array must not be empty") };
    values[0]
}

fn section15_compile_time() {
    header(15, "Compile-time evaluation");

    // const fn можно вызвать и во время выполнения — это обычная функция.
    println!(
        "20! = {FACTORIAL_20}, crc32(\"hello\") = {:#010x}",
        crc32(b"hello")
    );

    // Константа, инициализированная блоком с циклом.
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
    // first_element([]); // ошибка КОМПИЛЯЦИИ: evaluation panicked: the array must not be empty

    // Результат const fn годится туда, где нужна константа, — например, в длину массива.
    let buffer = [0_u8; factorial(4) as usize]; // тип: [u8; 24]
    println!("buffer of {} bytes", buffer.len());
}

// =====================================================================================
//  16. ПРОДВИНУТАЯ СИСТЕМА ТИПОВ
// =====================================================================================

// --- Typestate: состояние объекта записано в ТИПЕ ---------------------------------------
// Недопустимые переходы не «бросают исключение», а не компилируются.

struct Disconnected; // типы-маркеры состояний
struct Connected;

struct Connection<State> {
    address: String,
    bytes_sent: usize,
    _state: PhantomData<State>, // поле нулевого размера, «использующее» параметр State
}

impl Connection<Disconnected> {
    fn new(address: &str) -> Self {
        Connection {
            address: address.to_string(),
            bytes_sent: 0,
            _state: PhantomData,
        }
    }

    /// `self` по значению: «отключённое» соединение после вызова перестаёт существовать.
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

/// Методы, общие для всех состояний.
impl<State> Connection<State> {
    fn address(&self) -> &str {
        &self.address
    }
}

// --- GAT: обобщённые ассоциированные типы ---------------------------------------------

/// Ассоциированный тип со СВОИМ параметром (здесь — временем жизни). Классический
/// пример — «одалживающий» итератор: его элемент заимствует сам итератор и живёт
/// только до следующего `next()`. Обычный `Iterator` такого выразить не может.
trait LendingIterator {
    type Item<'a>
    where
        Self: 'a;

    fn next(&mut self) -> Option<Self::Item<'_>>;
}

/// Перекрывающиеся ИЗМЕНЯЕМЫЕ окна по срезу. (Стандартный `windows()` выдаёт только
/// окна для чтения: два перекрывающихся `&mut` одновременно существовать не могут.)
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

// --- HRTB: ограничения высшего ранга ----------------------------------------------------

/// `for<'a>` читается «для ЛЮБОГО времени жизни 'a»: замыкание обязано работать со
/// строкой, живущей сколько угодно, и вернуть её же часть.
fn map_strs<'s, F>(items: &'s [String], f: F) -> Vec<&'s str>
where
    F: for<'a> Fn(&'a str) -> &'a str,
{
    items.iter().map(|item| f(item)).collect()
}

// --- Any: информация о типе во время выполнения ------------------------------------------

/// Безопасное приведение «вниз». C#: `value is int number`.
/// Это вся рефлексия, что есть в языке: списка полей или методов в рантайме не получить.
fn describe_any(value: &dyn Any) -> String {
    if let Some(number) = value.downcast_ref::<i32>() {
        format!("i32 {number}")
    } else if let Some(text) = value.downcast_ref::<String>() {
        format!("String {text:?}")
    } else {
        "something else".to_string()
    }
}

// --- impl Trait в трейтах ---------------------------------------------------------------

/// Метод трейта может возвращать `impl Trait` (Rust 1.75): каждая реализация отдаёт
/// свой тип итератора — без Box и без виртуальных вызовов.
trait Graph {
    fn neighbors(&self, node: usize) -> impl Iterator<Item = usize>;
}

/// Граф, заданный списками смежности.
struct AdjacencyList(Vec<Vec<usize>>);

impl Graph for AdjacencyList {
    fn neighbors(&self, node: usize) -> impl Iterator<Item = usize> {
        self.0[node].iter().copied()
    }
}

/// Кольцо из n вершин: соседи вычисляются на лету, память под рёбра не нужна.
struct Ring(usize);

impl Graph for Ring {
    fn neighbors(&self, node: usize) -> impl Iterator<Item = usize> {
        [(node + self.0 - 1) % self.0, (node + 1) % self.0].into_iter()
    }
}

/// Обобщённый алгоритм поверх трейта: обход в ширину.
fn breadth_first(graph: &impl Graph, start: usize) -> Vec<usize> {
    let mut seen = HashSet::from([start]);
    let mut queue = VecDeque::from([start]);
    let mut order = Vec::new();
    while let Some(node) = queue.pop_front() {
        order.push(node);
        for next in graph.neighbors(node) {
            if seen.insert(next) {
                queue.push_back(next); // insert вернул true: вершину видим впервые
            }
        }
    }
    order
}

// --- Указатели на функции, псевдонимы типов, тип `!` ------------------------------------

/// Псевдоним типа (C#: `using UnaryOp = System.Func<double, double>;`).
/// `fn(f64) -> f64` — указатель на функцию: значение размером с адрес, без состояния.
/// Ему соответствуют обычные функции и замыкания, которые ничего не захватывают.
type UnaryOp = fn(f64) -> f64;

fn apply_all(value: f64, operations: &[(&str, UnaryOp)]) -> Vec<String> {
    operations
        .iter()
        .map(|(name, op)| format!("{name}({value}) = {:.3}", op(value)))
        .collect()
}

/// `!` (never) — тип выражений, которые не возвращают управление: `panic!`, `return`,
/// `break`, бесконечный `loop`. Он приводится к ЛЮБОМУ типу, поэтому ветка с `panic!`
/// не ломает типизацию `match`. В сигнатурах `-> !` доступен давно; писать `!` в любом
/// месте (например, `Result<T, !>`) разрешено начиная с Rust 1.100 (ноябрь 2026).
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

    // GAT: сглаживание скользящим окном прямо в исходном массиве.
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

    // impl Trait в трейтах.
    let list = AdjacencyList(vec![vec![1, 2], vec![3], vec![3], vec![]]);
    println!(
        "bfs: {:?}, ring: {:?}",
        breadth_first(&list, 0),
        breadth_first(&Ring(5), 0)
    );

    // Указатели на функции: методы, функции и замыкания без захвата — в одном массиве.
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

    // `!` в действии: у веток match типы u32 и `!`, результат — u32.
    let parsed: u32 = match "42".parse() {
        Ok(number) => number,
        Err(_) => fail("not a number"),
    };
    println!("parsed {parsed}");
}

// =====================================================================================
//  17. UNSAFE И FFI
// =====================================================================================
//
//  `unsafe` НЕ отключает borrow checker и остальные проверки. Он лишь разрешает пять
//  дополнительных действий:
//    1) разыменовывать сырые указатели `*const T` / `*mut T`;
//    2) вызывать unsafe-функции (в том числе внешние, из C);
//    3) обращаться к `static mut`;
//    4) реализовывать unsafe-трейты (например, Send и Sync);
//    5) читать поля union.
//  Идея: маленькое unsafe-ядро, обёрнутое в безопасный API, за инварианты которого
//  отвечаете вы. Каждый unsafe-блок принято снабжать комментарием `// SAFETY:`.
//  C#: `unsafe { }`, указатели и `fixed` — та же роль и та же редкость применения.

// FFI: объявления функций из библиотеки C (здесь — из libc, с которой std и так
// слинкована). C#: [DllImport] / [LibraryImport]. В edition 2024 блок обязан быть
// `unsafe extern`; функцию, чей контракт нельзя нарушить, можно пометить `safe`.
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

/// Функция с соглашением о вызовах C: её можно отдать C-коду как callback.
/// C#: `[UnmanagedCallersOnly]` + указатель на функцию `delegate* unmanaged`.
extern "C" fn compare_i32(a: *const c_void, b: *const c_void) -> c_int {
    // SAFETY: qsort передаёт указатели на элементы массива i32.
    let (a, b) = unsafe { (*a.cast::<i32>(), *b.cast::<i32>()) };
    a.cmp(&b) as c_int // Ordering — это enum со значениями -1, 0, 1
}

/// `#[repr(C)]` фиксирует раскладку полей как в C (C#: `[StructLayout(Sequential)]`).
/// Без него компилятор вправе переставлять поля ради плотной упаковки.
#[repr(C)]
#[derive(Debug, Clone, Copy)]
struct Rgba {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
}

/// `union`: все поля делят одну память (C#: `[StructLayout(Explicit)]` + `[FieldOffset(0)]`).
/// Чтение поля — unsafe: компилятор не знает, какое из них было записано последним.
#[repr(C)]
union Pixel {
    rgba: Rgba,
    packed: u32,
    bytes: [u8; 4],
}

/// unsafe-функция: у неё есть предусловие, которое компилятор проверить не может.
/// Его принято описывать в разделе `# Safety` документации.
///
/// # Safety
/// `index` должен быть меньше `values.len()`.
unsafe fn element_unchecked(values: &[f64], index: usize) -> f64 {
    // С edition 2024 unsafe-операции и внутри unsafe-функции пишут в блоке `unsafe`
    // (иначе компилятор выдаёт предупреждение).
    unsafe { *values.get_unchecked(index) }
}

/// Изменяемая глобальная переменная: любое обращение — unsafe (возможна гонка данных).
/// В новом коде вместо неё берут атомики, Mutex или LazyLock (раздел 13).
static mut LEGACY_CALLS: u32 = 0;

/// Обёртка над сырым указателем по умолчанию не Send. Если МЫ гарантируем, что доступ
/// к данным синхронизирован, обещание даётся явно — через `unsafe impl`.
struct FrameBuffer(*mut u8);

unsafe impl Send for FrameBuffer {}

/// Безопасная абстракция поверх unsafe: вектор фиксированной ёмкости без кучи
/// (C#: `stackalloc` или `[InlineArray]` + ручной учёт длины).
/// ИНВАРИАНТ: элементы с индексами `0..len` инициализированы, остальные — нет.
struct ArrayVec<T, const N: usize> {
    items: [MaybeUninit<T>; N], // память под N элементов, возможно неинициализированная
    len: usize,
}

impl<T, const N: usize> ArrayVec<T, N> {
    fn new() -> Self {
        Self {
            items: [const { MaybeUninit::uninit() }; N],
            len: 0,
        }
    }

    /// При переполнении возвращает значение обратно вызывающему.
    fn push(&mut self, value: T) -> Result<(), T> {
        if self.len == N {
            return Err(value);
        }
        self.items[self.len].write(value); // запись в неинициализированную ячейку безопасна
        self.len += 1;
        Ok(())
    }

    fn pop(&mut self) -> Option<T> {
        if self.len == 0 {
            return None;
        }
        self.len -= 1;
        // SAFETY: ячейка `len` была инициализирована в push, а после уменьшения len
        // она больше не считается занятой, так что значение не будет прочитано дважды.
        Some(unsafe { self.items[self.len].assume_init_read() })
    }

    fn as_slice(&self) -> &[T] {
        // SAFETY: первые `len` элементов инициализированы (инвариант), а раскладка
        // MaybeUninit<T> совпадает с раскладкой T.
        unsafe { std::slice::from_raw_parts(self.items.as_ptr().cast::<T>(), self.len) }
    }
}

impl<T, const N: usize> Drop for ArrayVec<T, N> {
    fn drop(&mut self) {
        // MaybeUninit сам ничего не уничтожает: «живые» элементы надо уничтожить вручную.
        for slot in &mut self.items[..self.len] {
            // SAFETY: ячейки `0..len` инициализированы (инвариант).
            unsafe { slot.assume_init_drop() };
        }
    }
}

fn section17_unsafe_and_ffi() {
    header(17, "unsafe and FFI");

    // --- Сырые указатели --------------------------------------------------------------
    let mut value = 10;
    let reader: *const i32 = &raw const value; // создать сырой указатель — безопасно
    let writer: *mut i32 = &raw mut value;
    // SAFETY: оба указателя смотрят на живую локальную переменную; ссылок на неё сейчас нет.
    unsafe {
        *writer += 1;
        println!("through raw pointers: {}", *reader);
    }

    // Арифметика указателей. C: `*(p + 2)`.
    let array = [10, 20, 30, 40];
    let pointer = array.as_ptr();
    // SAFETY: смещение 2 лежит в пределах массива из четырёх элементов.
    let third = unsafe { *pointer.add(2) };
    // SAFETY: индекс 1 меньше длины среза.
    let unchecked = unsafe { element_unchecked(&[0.5, 1.5], 1) };
    println!("third = {third}, unchecked = {unchecked}");

    // Два непересекающихся `&mut` в один срез: сам borrow checker этого не докажет.
    // std реализует split_at_mut через unsafe, а наружу отдаёт безопасный API.
    let mut numbers = [1, 2, 3, 4, 5, 6];
    let (left, right) = numbers.split_at_mut(3);
    left[0] += right[0];
    std::mem::swap(&mut left[1], &mut right[1]);
    // То же для отдельных элементов (Rust 1.86): Err, если индексы совпали или вне границ.
    if let Ok([first, last]) = numbers.get_disjoint_mut([0, 5]) {
        std::mem::swap(first, last);
    }
    println!("{numbers:?}");

    // --- Переинтерпретация битов --------------------------------------------------------
    // Для чисел есть безопасные методы: to_bits / from_bits, to_le_bytes / from_le_bytes.
    let bits = 1.0_f32.to_bits();
    let float = f32::from_bits(0x4049_0FDB);
    println!("1.0f32 is {bits:#x}; 0x40490fdb is {float}");

    // transmute — крайнее средство: «считать эти байты значением другого типа».
    let color = Rgba {
        r: 0x11,
        g: 0x22,
        b: 0x33,
        a: 0xFF,
    };
    // SAFETY: Rgba — #[repr(C)]-структура из четырёх u8: её размер равен размеру u32,
    // и любой набор битов — допустимое значение u32.
    let transmuted = unsafe { std::mem::transmute::<Rgba, u32>(color) };
    let pixel = Pixel { rgba: color };
    // SAFETY: все поля Pixel — простые данные по 4 байта; читать можно любое из них.
    let (packed, bytes) = unsafe { (pixel.packed, pixel.bytes) };
    println!(
        "transmute {transmuted:#010x} == union {packed:#010x} (LE), bytes {bytes:02x?}, size {}",
        size_of::<Pixel>()
    );

    // --- Вызовы в C -------------------------------------------------------------------
    let text = c"hello from C"; // литерал C-строки: &CStr с завершающим нулём (Rust 1.77)
    // SAFETY: передаём указатель на корректную C-строку.
    let length = unsafe { strlen(text.as_ptr()) };
    let mut unsorted = [42, -7, 19, 0, 3];
    // SAFETY: указатель, число элементов и размер элемента описывают массив `unsorted`,
    // а функция сравнения читает ровно по одному i32 из каждого указателя.
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
    // SAFETY: программа в этом месте однопоточная, других обращений к LEGACY_CALLS нет.
    let calls = unsafe {
        LEGACY_CALLS += 1;
        LEGACY_CALLS
    };
    println!("legacy calls = {calls}");

    // --- Безопасная обёртка над unsafe ---------------------------------------------------
    let mut small: ArrayVec<String, 2> = ArrayVec::new();
    small.push("alpha".to_string()).unwrap();
    small.push("beta".to_string()).unwrap();
    let overflow = small.push("gamma".to_string()); // Err: места нет, строка возвращена
    println!("{:?}, overflow: {overflow:?}", small.as_slice());
    println!(
        "popped {:?}, {} bytes on the stack, no heap for the array",
        small.pop(),
        size_of_val(&small)
    );
} // здесь Drop для ArrayVec уничтожит оставшуюся строку "alpha"

// =====================================================================================
//  18. ASYNC/AWAIT ИЗНУТРИ
// =====================================================================================
//
//  `async fn` возвращает Future — конечный автомат, который САМ НИЧЕГО НЕ ДЕЛАЕТ, пока
//  его не опрашивают методом `poll`. Отличия от C#:
//    - Task в C# «горячий» (начинает выполняться сразу), Future в Rust «ленивый»;
//    - нет аллокации на каждый async-вызов: вложенные future встраиваются в один автомат;
//    - исполнитель (executor) — не часть языка, а библиотека: tokio, smol, embassy.
//  Ниже — исполнитель, написанный вручную, чтобы показать механику: трейт Future,
//  Poll, Context и Waker, закрепление Pin.

/// Future, готовый со второго опроса: уступает управление исполнителю.
/// C#: `await Task.Yield()`.
struct YieldNow {
    yielded: bool,
}

impl Future for YieldNow {
    type Output = ();

    /// `Pin<&mut Self>` гарантирует, что future не переместят в памяти между опросами:
    /// автомат может хранить ссылки на собственные поля.
    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<()> {
        if self.yielded {
            return Poll::Ready(());
        }
        self.yielded = true;
        cx.waker().wake_by_ref(); // «опросите меня ещё раз» — иначе о задаче забудут
        Poll::Pending
    }
}

fn yield_now() -> YieldNow {
    YieldNow { yielded: false }
}

/// Таймер. C#: `Task.Delay`. Для простоты заводит вспомогательный поток, который
/// разбудит задачу; настоящие рантаймы держат одну общую очередь таймеров.
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
            let waker = cx.waker().clone(); // Waker — «ручка», за которую будят задачу
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

/// Waker для `block_on`: будит припаркованный поток. Трейт `Wake` превращает `Arc<T>`
/// в Waker без ручной работы с таблицей функций.
struct ThreadWaker(thread::Thread);

impl Wake for ThreadWaker {
    fn wake(self: Arc<Self>) {
        self.0.unpark();
    }
}

/// Простейший исполнитель: опрашивает один future на текущем потоке до готовности.
/// C#: `task.GetAwaiter().GetResult()`.
fn block_on<F: Future>(future: F) -> F::Output {
    let mut future = pin!(future); // закрепить на стеке: после первого poll перемещать нельзя
    let waker = Waker::from(Arc::new(ThreadWaker(thread::current())));
    let mut cx = Context::from_waker(&waker);
    loop {
        match future.as_mut().poll(&mut cx) {
            Poll::Ready(output) => return output,
            Poll::Pending => thread::park(), // спим, пока кто-нибудь не вызовет wake()
        }
    }
}

/// Конкурентное ожидание двух future на ОДНОМ потоке. C#: `Task.WhenAll`.
async fn join2<A: Future, B: Future>(a: A, b: B) -> (A::Output, B::Output) {
    let (mut a, mut b) = (pin!(a), pin!(b));
    let (mut result_a, mut result_b) = (None, None);
    // poll_fn строит future из замыкания: удобно для ручных комбинаторов.
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

/// Обычная async-функция. Компилятор превращает её в конечный автомат (enum с вариантом
/// на каждую точку `.await`). `.await` — постфиксный: удобно в цепочках `x.await?.len()`.
async fn fetch(name: &str, delay_ms: u64) -> u64 {
    sleep(Duration::from_millis(delay_ms)).await;
    name.len() as u64 * delay_ms
}

/// Async-замыкания и трейты `AsyncFn*` (Rust 1.85). C#: `Func<uint, Task<uint>>`.
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

/// `async fn` в трейтах (Rust 1.75). C#: метод интерфейса, возвращающий `Task<T>`.
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

// --- Исполнитель с очередью задач: так устроены настоящие рантаймы (в миниатюре) --------

/// Future произвольного типа, закреплённый в куче. C#: просто `Task`.
type BoxFuture = Pin<Box<dyn Future<Output = ()> + Send>>;

struct Task {
    future: Mutex<Option<BoxFuture>>, // None — задача завершена
    ready_queue: mpsc::Sender<Arc<Task>>,
}

impl Wake for Task {
    /// Разбудить задачу = снова поставить её в очередь готовых.
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

    /// C#: `Task.Run`. Future должен быть Send + 'static: задача живёт отдельно от создателя.
    fn spawn(&self, future: impl Future<Output = ()> + Send + 'static) {
        let task = Task {
            future: Mutex::new(Some(Box::pin(future))),
            ready_queue: self.sender.clone(),
        };
        self.sender.send(Arc::new(task)).expect("the queue is open");
    }

    /// Опрашивает готовые задачи, пока они не закончатся.
    fn run(self) {
        let Executor { sender, receiver } = self;
        drop(sender); // теперь канал закроется, когда исчезнут все задачи и их Waker-ы
        while let Ok(task) = receiver.recv() {
            let mut slot = task.future.lock().unwrap();
            if let Some(mut future) = slot.take() {
                let waker = Waker::from(Arc::clone(&task));
                let mut cx = Context::from_waker(&waker);
                if future.as_mut().poll(&mut cx).is_pending() {
                    *slot = Some(future); // не готова: вернуть на место до следующего wake()
                }
            }
        }
    }
}

fn section18_async() {
    header(18, "async/await from the inside");

    // Future ленив: создание ничего не запускает.
    let future = fetch("alpha", 30);
    println!(
        "future created, nothing has run yet; its state machine takes {} bytes",
        size_of_val(&future)
    );
    println!("block_on -> {}", block_on(future));

    // Два future конкурентно на одном потоке: общее время — максимум, а не сумма.
    let started = Instant::now();
    let (beta, gamma) = block_on(join2(fetch("beta", 40), fetch("gamma", 20)));
    println!(
        "join2 -> ({beta}, {gamma}) in about {} ms (not 60)",
        started.elapsed().as_millis()
    );

    // async-блок, async-замыкание и async-метод трейта.
    let (result, attempts, average) = block_on(async {
        let attempts = RefCell::new(Vec::new());
        // Замыкание заимствует `attempts`, и future, который оно возвращает, — тоже.
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

    // Исполнитель с очередью: три независимые задачи на одном потоке.
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
//  ТОЧКА ВХОДА
// =====================================================================================

/// `main` может возвращать Result: при `Err` программа напечатает ошибку в stderr
/// и завершится с кодом 1. Поэтому внутри можно пользоваться оператором `?`.
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
