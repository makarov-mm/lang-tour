// =====================================================================================
//  C++ ДЛЯ C#-РАЗРАБОТЧИКА — тур по языку в одном файле, от простого к сложному
// =====================================================================================
//
//  Сборка и запуск (нужен компилятор и стандартная библиотека с поддержкой C++23):
//
//      g++ -std=c++23 -O2 -Wall -Wextra -Wpedantic cpp_tour.cpp -o cpp_tour
//      clang++ -std=c++23 -stdlib=libc++ -O2 -Wall -Wextra -Wpedantic cpp_tour.cpp -o cpp_tour
//      cl /std:c++latest /utf-8 /EHsc /W4 cpp_tour.cpp
//      ./cpp_tour
//
//  Проверено: GCC 14.2 (libstdc++) и Clang 20 (libc++), в режимах -std=c++23 и -std=c++26,
//  плюс прогон под санитайзерами (address, undefined, thread). Сборка MSVC не проверялась;
//  по таблице соответствия Microsoft нужные возможности языка есть с VS 2022 17.14.
//  С флагом -std=c++26 дополнительно включаются примеры C++26 из раздела 16.
//
//  Не всё из C++23/26 уже есть в каждом компиляторе и библиотеке. Такие фрагменты
//  обёрнуты в проверки feature-test-макросов (`#ifdef __cpp_lib_generator` и т.п.):
//  где возможности нет, пример просто пропускается, а файл всё равно собирается.
//
//  Как читать. Каждый раздел — функция `sectionNN_*`; типы и функции, нужные разделу,
//  объявлены прямо перед ней; `main()` в конце файла вызывает разделы по порядку.
//  Пометка «C#:» показывает ближайший аналог в C#.
//
//  Главные отличия от C#, которые стоит держать в голове с первой строки:
//
//   1. Нет сборщика мусора. Время жизни объекта детерминировано: объект уничтожается
//      при выходе из области видимости (или когда исчезает его владелец). На этом
//      построена центральная идиома языка — RAII (раздел 4).
//   2. ЛЮБОЙ тип — значение. Переменная — это сам объект, а не ссылка на него, и `b = a`
//      копирует объект целиком. Ссылочность запрашивают явно: `T&`, `T*`, умные указатели.
//      `struct` и `class` — одно и то же (разница лишь в доступе по умолчанию).
//   3. Неопределённое поведение (undefined behavior, UB). Выход за границы массива,
//      обращение к уничтоженному объекту, знаковое переполнение, гонка данных — не
//      исключения, а «программа вправе делать что угодно». Компилятор этого не ловит.
//   4. Шаблоны — не обобщения CLR. Это генерация кода при компиляции: отдельная копия
//      на каждый набор типов, проверка тела — в момент подстановки (раздел 9).
//   5. Компиляция «сверху вниз»: имя нужно объявить до использования. Исторически код
//      делят на заголовки (.h) и единицы трансляции (.cpp); модули C++20 — раздел 16.
//   6. Наследование бывает множественным, отдельной сущности «интерфейс» нет, а про
//      виртуальный деструктор базового класса нужно помнить самому (раздел 6).
//   7. Рефлексии во время выполнения нет; многое решается при компиляции (раздел 12).
//
//  Содержание:
//    1. Основы: типы, переменные, функции          9. Шаблоны и концепты
//    2. Значения, ссылки, указатели               10. Типы-суммы: optional, variant, any
//    3. Строки, контейнеры, форматирование        11. Обработка ошибок
//    4. Классы и RAII                             12. Вычисления при компиляции
//    5. Владение памятью: умные указатели         13. Низкий уровень: память, биты, аллокаторы
//    6. Наследование и полиморфизм                14. Многопоточность
//    7. Лямбды и вызываемые объекты               15. Корутины
//    8. Алгоритмы и диапазоны (ranges)            16. C++23, C++26, модули
// =====================================================================================

// `#include` текстуально вставляет заголовочный файл — это работа препроцессора, а не
// импорт сборки. C#: using + ссылка на сборку. Стандартная библиотека разбита на
// десятки заголовков; подключают только нужные.
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
#include <version> // макросы __cpp_lib_*: какие части стандартной библиотеки реально доступны

// Условная компиляция. C#: #if. Заголовки новых возможностей подключаем, только если они есть.
#ifdef __cpp_lib_generator
#include <generator>
#endif
#ifdef __cpp_lib_mdspan
#include <mdspan>
#endif
#ifdef __cpp_lib_flat_map
#include <flat_map>
#endif

// Вносит в область видимости литеральные суффиксы: "text"s, "text"sv, 10ms.
// Целиком `using namespace std;` в серьёзном коде не пишут: слишком много имён.
using namespace std::literals;

// Печатает заголовок раздела. std::string_view — «окно» в чужую строку (раздел 3).
void header(int number, std::string_view title) {
    std::println("\n=== {:>2}. {} ===", number, title);
}

// Склеивает элементы любого диапазона в строку. `auto&&` в параметре делает функцию
// шаблоном (раздел 9): она принимает vector, array, set, ленивый view — что угодно,
// по чему можно пройти циклом и чьи элементы умеет печатать std::format.
// (Печать диапазонов «из коробки» — `std::println("{}", vec)` — есть в C++23, но пока
// не во всех библиотеках; см. раздел 16.)
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
//  1. ОСНОВЫ: типы, переменные, функции, управление потоком
// =====================================================================================

// Константа времени компиляции. C#: const. Апостроф — разделитель разрядов (C#: 100_000).
constexpr int max_points = 100'000;

// Перечисление со строгой типизацией и заданным базовым типом. C#: enum Color : byte.
// «Старый» enum (без слова class) неявно превращается в int, а имена его значений
// попадают в окружающую область видимости — в новом коде его избегают.
enum class Color : std::uint8_t { red, green, blue };

// Объявление (прототип) без тела. Компилятор читает файл сверху вниз, и имя должно
// быть объявлено ДО использования. В C# порядок членов не важен, здесь — важен.
std::string_view color_name(Color color);

// Функции. Перегрузка и параметры по умолчанию — как в C#; именованных аргументов нет.
int add(int a, int b) { return a + b; }
double add(double a, double b) { return a + b; } // перегрузка по типам параметров
int scale(int value, int factor = 2) { return value * factor; }

// `auto` вместо типа результата: тип выводится из return.
auto cube(int x) { return x * x * x; }

// «Хвостовой» тип результата — альтернативная запись; удобна в шаблонах и лямбдах.
auto half(double x) -> double { return x / 2; }

std::string_view color_name(Color color) {
    // switch: БЕЗ break выполнение «проваливается» в следующий case (в C# это запрещено).
    switch (color) {
        case Color::red:
            return "red";
        case Color::green:
            [[fallthrough]]; // атрибут: проваливание намеренное, предупреждать не нужно
        case Color::blue:
            return "cold";
    }
    std::unreachable(); // C++23: «сюда управление не попадёт». Если попадёт — UB
}

// Пространство имён. C#: namespace. Вложенность записывается через `::`.
namespace geometry::units {
constexpr double mm_per_inch = 25.4;
constexpr double to_mm(double inches) { return inches * mm_per_inch; }
} // namespace geometry::units

void section01_basics() {
    header(1, "Basics: types, variables, functions, control flow");

    // --- Переменные и инициализация ---------------------------------------------------
    int a = 42;   // инициализация «через равно»
    int b{7};     // фигурные скобки: единый синтаксис, запрещающий сужение типа
    // int bad{3.7};  // ошибка: narrowing conversion from 'double' to 'int'
    auto d = 3.5;  // double; auto — аналог var
    auto f = 2.5f; // float
    bool flag = true;
    char letter = 'A'; // ОДИН БАЙТ, а не символ UTF-16, как char в C#

    // Размеры int, long и т.д. зависят от платформы (long: 8 байт в Linux, 4 в Windows).
    // Когда разрядность важна, берут типы из <cstdint>.
    std::int64_t big = 9'000'000'000; // C#: long
    std::uint8_t byte = 0xFF;         // C#: byte
    std::size_t count = 10uz;         // беззнаковый «размер» (C#: nuint); суффикс uz — C++23
    std::println("{} {} {} {} {} {} {} {} {}", a, b, d, f, flag, letter, big, byte, count);
    std::println("sizeof: char {}, int {}, long {}, long long {}, double {}, pointer {}",
                 sizeof(char), sizeof(int), sizeof(long), sizeof(long long), sizeof(double),
                 sizeof(void*));

    // Локальная переменная без инициализатора содержит мусор, читать её нельзя: до C++26
    // это UB, в C++26 — «ошибочное поведение». (В C# — ошибка компиляции CS0165.)
    //     int garbage;
    //     std::println("{}", garbage);

    // --- const и constexpr ------------------------------------------------------------
    const int limit = a * 2;                     // нельзя изменить после инициализации
    constexpr double tau = 2 * std::numbers::pi; // значение обязано быть известно при компиляции
    std::println("limit {}, tau {:.4f}, max_points {}", limit, tau, max_points);

    // --- Преобразования: щедрые и опасные ---------------------------------------------
    // C++ неявно преобразует числа там, где C# потребовал бы явного приведения.
    double ratio = a / 5;                   // целочисленное деление: 8, и лишь потом 8 -> 8.0
    int truncated = static_cast<int>(3.99); // явное приведение: 3. Пишут static_cast, а не (int)x
    unsigned wrapped = 0u - 1u;             // беззнаковые заворачиваются по модулю 2^32
    // int overflow = std::numeric_limits<int>::max() + 1; // ЗНАКОВОЕ переполнение — UB!
    std::println("{} {} {} (int max is {})", ratio, truncated, wrapped,
                 std::numeric_limits<int>::max());

    // --- Функции ----------------------------------------------------------------------
    std::println("{} {} {} {} {} {}", add(2, 3), add(2.5, 0.5), scale(5), scale(5, 10), cube(3),
                 half(5));

    // --- Управление потоком -----------------------------------------------------------
    // if с инициализатором (C++17): переменная живёт только внутри if/else.
    if (int remainder = a % 5; remainder == 0) {
        std::println("{} is divisible by 5", a);
    } else {
        std::println("{} % 5 = {}", a, remainder);
    }
    const char* parity = (a % 2 == 0) ? "even" : "odd"; // тернарный оператор — как в C#

    int sum = 0;
    for (int i = 0; i < 5; ++i) sum += i;        // классический for
    for (int value : {10, 20, 30}) sum += value; // диапазонный for. C#: foreach
    int countdown = 3;
    while (countdown > 0) --countdown;
    do {
        ++countdown;
    } while (countdown < 2);
    std::println("{} is {}, sum = {}, countdown = {}", a, parity, sum, countdown);

    for (Color color : {Color::red, Color::green, Color::blue}) {
        // enum class превращается в число только явно; std::to_underlying — C++23.
        std::print("{}={} ", color_name(color), std::to_underlying(color));
    }
    std::println("");

    // --- Пространства имён ------------------------------------------------------------
    using geometry::units::to_mm; // внести в область видимости одно имя
    namespace gu = geometry::units; // псевдоним пространства имён
    std::println("2 in = {} mm, {} mm per inch", to_mm(2.0), gu::mm_per_inch);
}

// =====================================================================================
//  2. ЗНАЧЕНИЯ, ССЫЛКИ, УКАЗАТЕЛИ
// =====================================================================================
//
//  Самое важное отличие от C#. Там поведение задаёт сам тип: class — ссылка на объект
//  в куче, struct — значение. В C++ значение — ЛЮБОЙ тип:
//    - переменная типа T — это сам объект, а не ссылка на него;
//    - `b = a` копирует объект целиком, будь то int или вектор из миллиона элементов;
//    - «ссылочность» выбирают в месте использования: T& (ссылка) или T* (указатель).

struct Point {
    double x = 0.0; // инициализатор члена по умолчанию
    double y = 0.0;
};

// Как принять параметр, решает автор функции:
Point shifted(Point p, double dx) { // по значению: функция работает с КОПИЕЙ
    p.x += dx;
    return p;
}

void shift(Point& p, double dx) { p.x += dx; } // по ссылке: меняем оригинал. C#: ref

// По const-ссылке: без копирования и только для чтения. Так принимают всё, что
// дороже пары машинных слов. C#: in.
double norm(const Point& p) { return std::hypot(p.x, p.y); }

void shift_if_present(Point* p, double dx) { // по указателю: «объекта может не быть»
    if (p != nullptr) p->x += dx;            // `->` — доступ к члену через указатель
}

// Несколько результатов — парой, кортежем или структурой.
std::pair<int, int> div_rem(int a, int b) { return {a / b, a % b}; }

void section02_values_references_pointers() {
    header(2, "Values, references, pointers");

    // --- Копирование ------------------------------------------------------------------
    std::vector<int> first{1, 2, 3};
    std::vector<int> second = first; // ПОЛНАЯ КОПИЯ (в C# скопировалась бы только ссылка)
    second.push_back(4);
    std::vector<int>& alias = first; // а это «как в C#»: второе имя ТОГО ЖЕ объекта
    alias.push_back(99);
    std::println("first [{}], second [{}]", join(first), join(second));

    // --- Ссылки и указатели -----------------------------------------------------------
    int x = 10;
    int& ref = x; // ссылка: инициализируется сразу, не бывает «пустой», не перенаправляется
    int* ptr = &x; // указатель: переменная с адресом. `&x` — взять адрес, `*ptr` — разыменовать
    ref += 1;
    *ptr += 1;
    int* nothing = nullptr;    // C#: null. Разыменовать nullptr — UB, а не NullReferenceException
    const int* read_only = &x; // указатель на const: через него значение не изменить
    std::println("x = {}, *ptr = {}, is null: {}, *read_only = {}", x, *ptr, nothing == nullptr,
                 *read_only);

    // --- Агрегаты ---------------------------------------------------------------------
    Point p1{1.0, 2.0};           // агрегатная инициализация по порядку полей
    Point p2{.x = 3.0, .y = 4.0}; // назначенные инициализаторы (C++20). C#: new Point { X = 3 }
    Point p3 = p1;                // копия всех полей
    p3.y = 20.0;
    auto [px, py] = p2; // структурные привязки (C++17). C#: var (x, y) = point
    auto [quotient, remainder] = div_rem(17, 5);
    std::println("p1.y = {}, p3.y = {}, p2 = ({}, {}), 17 / 5 = {} rem {}", p1.y, p3.y, px, py,
                 quotient, remainder);

    // --- Передача параметров ----------------------------------------------------------
    Point p{3.0, 4.0};
    Point copy = shifted(p, 10.0);  // p не изменился
    shift(p, 1.0);                  // p.x == 4
    shift_if_present(&p, 1.0);      // p.x == 5
    shift_if_present(nullptr, 1.0); // ничего не делает
    std::println("p.x = {}, copy.x = {}, norm = {:.3f}", p.x, copy.x, norm(p));

    // --- Массивы ----------------------------------------------------------------------
    int raw[4] = {1, 2, 3, 4};            // массив в стиле C: в функцию передаётся без размера
    std::array<int, 4> fixed{1, 2, 3, 4}; // массив-значение; размер — часть типа
    std::array<int, 4> duplicate = fixed; // копируется целиком (int[] в C# — ссылка)
    duplicate[0] = 100;
    std::println("raw has {} elements, fixed[0] = {}, duplicate[0] = {}", std::size(raw), fixed[0],
                 duplicate[0]);
    // fixed[10]    — выход за границы без проверки: UB.
    // fixed.at(10) — с проверкой: исключение std::out_of_range.
}

// =====================================================================================
//  3. СТРОКИ, КОНТЕЙНЕРЫ, ФОРМАТИРОВАНИЕ
// =====================================================================================

// std::span<T> — «окно» в непрерывную последовательность: массив, std::array, vector.
// C#: Span<T> / ReadOnlySpan<T>.
int sum_of_span(std::span<const int> values) {
    int total = 0;
    for (int v : values) total += v;
    return total;
}

// std::optional<T> — значение, которого может не быть. C#: T?
std::optional<int> first_even(std::span<const int> values) {
    for (int v : values) {
        if (v % 2 == 0) return v;
    }
    return std::nullopt;
}

void section03_strings_and_containers() {
    header(3, "Strings, containers, formatting");

    // --- std::string ------------------------------------------------------------------
    // Изменяемая последовательность БАЙТОВ, владеющая своим буфером; о кодировке она
    // ничего не знает. По духу ближе к StringBuilder, чем к неизменяемой string из C#.
    std::string text = "Hello";
    text += ", world";
    text.push_back('!');
    std::string copy = text; // копия буфера (в C# строки неизменяемы и потому разделяются)
    copy[0] = 'J';
    std::println("{} | {} | size {} | equal: {}", text, copy, text.size(), text == copy);

    // std::string_view — невладеющее «окно» в чужую строку. C#: ReadOnlySpan<char>.
    // Копируется дёшево (указатель + длина), но НЕ продлевает жизнь строки: вернуть из
    // функции view на локальную std::string — классическая висячая ссылка.
    std::string_view view = text;
    std::string_view word = view.substr(0, 5); // без копирования и аллокаций
    std::println("{} | starts_with: {} | contains: {} | find: {}", word,
                 view.starts_with("Hello"), view.contains("wor"), view.find("world"));

    // Литералы. Обычный "..." — массив const char[N]; суффиксы дают настоящие объекты.
    auto owned = "std::string literal"s;   // std::string
    auto viewed = "string_view literal"sv; // std::string_view
    auto raw = R"(C:\dir\file "quoted")";  // raw-строка без экранирования. C#: @"..." и """..."""
    std::println("{} | {} | {}", owned, viewed, raw);

    // Числа <-> строки.
    int parsed = std::stoi("42"); // при ошибке бросает исключение
    std::string_view digits = "1234abc";
    int fast = 0;
    // from_chars: без аллокаций, локалей и исключений; возвращает позицию остановки и код ошибки.
    auto [stop, error] = std::from_chars(digits.data(), digits.data() + digits.size(), fast);
    std::println("{} | {} ({} chars, ok: {}) | {}", parsed, fast, stop - digits.data(),
                 error == std::errc{}, std::to_string(2026) + "!");

    // size() — это байты. В UTF-8 кириллическая буква занимает два.
    std::string cyrillic = "Привет";
    std::println("'{}' takes {} bytes", cyrillic, cyrillic.size());

    // --- std::vector<T> — динамический массив. C#: List<T> ------------------------------
    std::vector<int> values{5, 3, 8};
    values.push_back(1);
    values.emplace_back(9);           // построить элемент прямо внутри вектора
    values.insert(values.begin(), 0); // позиции задают ИТЕРАТОРАМИ, а не индексами
    values.erase(values.begin() + 1); // удалить элемент с индексом 1
    std::println("[{}] size {}, front {}, back {}, at(2) {}", join(values), values.size(),
                 values.front(), values.back(), values.at(2));
    // values[100] — UB (границы не проверяются!), values.at(100) — исключение std::out_of_range.

    // span и optional в деле.
    int c_array[] = {7, 9, 4};
    std::array<int, 3> std_array{1, 3, 5};
    std::println("sums: {} {} {} | first even: {} {}", sum_of_span(values), sum_of_span(c_array),
                 sum_of_span(std::span{values}.subspan(1, 2)),
                 first_even(c_array).value_or(-1), first_even(std_array).has_value());

    // --- Словари и множества ----------------------------------------------------------
    std::map<std::string, int> ages{{"Ann", 30}, {"Bob", 25}}; // дерево. C#: SortedDictionary
    ages["Cid"] = 41;
    ages["Dan"]; // ЛОВУШКА: operator[] вставляет значение по умолчанию, если ключа нет
    // Поиск без вставки: find возвращает итератор; «не найдено» — это end().
    if (auto it = ages.find("Bob"); it != ages.end()) {
        std::println("found {} -> {}", it->first, it->second);
    }
    std::print("contains Eve: {}, size {}:", ages.contains("Eve"), ages.size());
    for (const auto& [name, age] : ages) { // структурная привязка к паре (ключ, значение)
        std::print(" {}={}", name, age);
    }
    std::println("");

    std::unordered_map<std::string, int> stock{{"bolt", 10}}; // хеш-таблица. C#: Dictionary
    stock.try_emplace("nut", 5);       // вставить, только если ключа ещё нет
    stock.insert_or_assign("bolt", 7); // вставить или заменить
    ++stock["screw"]; // а здесь автовставка нуля — ровно то, что нужно счётчику
    std::set<int> unique{3, 1, 3, 2};                // упорядоченное множество. C#: SortedSet
    std::unordered_set<std::string> seen{"a", "b"};  // C#: HashSet
    std::deque<int> queue{2, 3};                     // двусторонняя очередь
    queue.push_front(1);
    queue.push_back(4);
    std::println("stock: bolt {}, nut {}, screw {} | unique [{}] | seen a: {} | deque [{}]",
                 stock.at("bolt"), stock.at("nut"), stock.at("screw"), join(unique),
                 seen.contains("a"), join(queue));

    // --- Кортежи ----------------------------------------------------------------------
    std::tuple<int, std::string, double> record{1, "one", 1.5}; // C#: (int, string, double)
    auto [id, label, weight] = record;
    std::println("{} {} {} | get<1>: {} | get<double>: {}", id, label, weight, std::get<1>(record),
                 std::get<double>(record));

    // --- Форматирование: std::format и std::print (C++20/23) ----------------------------
    // Мини-язык почти как в C#; строка формата проверяется ПРИ КОМПИЛЯЦИИ.
    std::println("[{:>8.3f}] [{:<6}] [{:^6}] [{:08.2f}] [{:#x}] [{:#010b}] [{:e}] [{:+}]", 9.87654,
                 "ab", "mid", 2.5, 255, 5, 1234.5, 7);
    // Позиционные аргументы и ширина, взятая из аргумента.
    std::string line = std::format("{0}/{1}/{0} [{2:>{3}}]", "x", "y", 42, 6);
    std::println("{}", line);
    // До C++20 были только потоки ввода-вывода; они встречаются в любом существующем коде.
    std::cout << "iostream: " << 42 << ' ' << 3.5 << '\n';
}

// =====================================================================================
//  4. КЛАССЫ И RAII
// =====================================================================================

// Класс с инкапсуляцией. `public:` и `private:` — метки секций, а не модификаторы
// у каждого члена, как в C#.
class Vec2 {
public:
    // Конструкторы. После двоеточия — список инициализации членов: поля именно
    // ИНИЦИАЛИЗИРУЮТСЯ, а не присваиваются в теле.
    constexpr Vec2() = default; // «= default»: попросить у компилятора стандартную реализацию
    constexpr Vec2(double x, double y) : x_{x}, y_{y} {}

    // Делегирующий конструктор. explicit запрещает неявное преобразование `Vec2 v = 5.0;`
    // (конструктор с одним параметром без explicit работает как implicit operator в C#).
    constexpr explicit Vec2(double both) : Vec2{both, both} {}

    // `const` после списка параметров: метод не меняет объект, и его можно вызывать
    // через const-ссылку. C#: readonly-члены структур. [[nodiscard]] — предупреждение,
    // если результат проигнорирован.
    [[nodiscard]] constexpr double x() const { return x_; }
    [[nodiscard]] constexpr double y() const { return y_; }
    [[nodiscard]] double length() const { return std::hypot(x_, y_); }

    // Перегрузка операторов. Составное присваивание — метод, возвращающий *this.
    constexpr Vec2& operator+=(const Vec2& rhs) {
        x_ += rhs.x_;
        y_ += rhs.y_;
        return *this; // this — указатель на текущий объект, *this — сам объект
    }
    constexpr Vec2 operator-() const { return {-x_, -y_}; }

    // Бинарные операторы обычно делают свободными функциями. friend даёт им доступ
    // к приватным членам и позволяет определить их прямо внутри класса.
    friend constexpr Vec2 operator+(Vec2 lhs, const Vec2& rhs) { return lhs += rhs; }
    friend constexpr Vec2 operator*(Vec2 v, double k) { return {v.x_ * k, v.y_ * k}; }
    friend constexpr Vec2 operator*(double k, Vec2 v) { return v * k; }

    // Почленное сравнение, сгенерированное компилятором (C++20). C#: record struct.
    friend constexpr bool operator==(const Vec2&, const Vec2&) = default;

    // Статический метод — как в C#.
    static constexpr Vec2 unit_x() { return {1.0, 0.0}; }

private:
    double x_ = 0.0; // приватные поля по соглашению помечают суффиксом или префиксом
    double y_ = 0.0;
};

// Подключение своего типа к std::format / std::print — специализация шаблона
// std::formatter. C#: ToString() / IFormattable. Наследуемся от formatter<double>,
// чтобы спецификация вроде `{:.2f}` применялась к обеим координатам.
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

// Оператор <=> («космический корабль», C++20): одна строка даёт ==, !=, <, <=, >, >=
// с лексикографическим сравнением полей. C#: record + IComparable<T>, написанный руками.
struct Date {
    int year = 1970;
    int month = 1;
    int day = 1;
    auto operator<=>(const Date&) const = default;
};

// Класс-«трассировщик»: сообщает, когда его создают, копируют, перемещают и уничтожают.
class Tracer {
public:
    explicit Tracer(std::string name) : name_{std::move(name)} {
        ++live_;
        std::println("    ctor  {}", name_);
    }

    // Копирующий конструктор: как из существующего объекта сделать второй такой же.
    Tracer(const Tracer& other) : name_{other.name_ + "-copy"} {
        ++live_;
        std::println("    copy  {} -> {}", other.name_, name_);
    }

    // Перемещающий конструктор: как «украсть» содержимое объекта, который больше не
    // нужен. `Tracer&&` — rvalue-ссылка. В C# аналога нет: объекты классов там и так
    // не копируются, а передаются по ссылке.
    Tracer(Tracer&& other) noexcept : name_{std::move(other.name_)} {
        other.name_ = "(moved-from)";
        ++live_;
        std::println("    move  {}", name_);
    }

    Tracer& operator=(const Tracer&) = delete; // «= delete» запрещает операцию
    Tracer& operator=(Tracer&&) = delete;

    // Деструктор вызывается автоматически и детерминированно — в момент, когда
    // заканчивается время жизни объекта. C#: Dispose(), но без using и без «забыл».
    ~Tracer() {
        --live_;
        std::println("    dtor  {}", name_);
    }

    [[nodiscard]] const std::string& name() const { return name_; }
    [[nodiscard]] static int live() { return live_; }

private:
    std::string name_;
    static inline int live_ = 0; // статическое поле; inline — определение прямо в классе
};

// Возврат по значению не копирует: объект строится сразу на месте назначения
// (copy elision). Возвращать «большие» объекты по значению — нормально.
Tracer make_tracer(std::string name) { return Tracer{std::move(name)}; }

// Параметр по значению — отдельный объект; он уничтожается при выходе из функции.
void consume(Tracer tracer) { std::println("    consume({})", tracer.name()); }

// «Правило пяти». Если класс вручную управляет ресурсом, ему нужны все пять специальных
// функций: деструктор, копирующие и перемещающие конструктор и присваивание.
class Buffer {
public:
    explicit Buffer(std::size_t size) : size_{size}, data_{new double[size]{}} {}

    ~Buffer() { delete[] data_; } // освобождаем ресурс; delete[] для nullptr безопасен

    Buffer(const Buffer& other) : size_{other.size_}, data_{new double[other.size_]} {
        std::copy_n(other.data_, size_, data_); // глубокая копия
    }

    // std::exchange(a, b): записать b в a и вернуть прежнее значение a.
    Buffer(Buffer&& other) noexcept
        : size_{std::exchange(other.size_, 0)}, data_{std::exchange(other.data_, nullptr)} {}

    // Присваивание по идиоме «copy-and-swap»: параметр по значению уже содержит копию
    // (или перемещённый объект), остаётся обменяться с ним содержимым.
    Buffer& operator=(Buffer other) noexcept {
        swap(other);
        return *this;
    } // прежнее содержимое уничтожится вместе с other

    void swap(Buffer& other) noexcept {
        std::swap(size_, other.size_);
        std::swap(data_, other.data_);
    }

    // Индексатор в двух версиях: для изменяемого объекта и для const. C#: this[int index].
    double& operator[](std::size_t index) { return data_[index]; }
    const double& operator[](std::size_t index) const { return data_[index]; }

    [[nodiscard]] std::size_t size() const { return size_; }

    // Оператор преобразования; explicit — работает только в условиях: `if (buffer)`.
    explicit operator bool() const { return data_ != nullptr; }

private:
    std::size_t size_;
    double* data_;
};

// «Правило нуля»: тот же буфер из готовых RAII-кирпичиков. Копирование, перемещение
// и уничтожение компилятор сгенерирует сам — и правильно. В прикладном коде пишут
// именно так, а ручные new/delete остаются внутри библиотечных контейнеров.
struct SafeBuffer {
    std::vector<double> data;
};

// RAII вместо finally: деструктор выполнит действие при ЛЮБОМ выходе из блока —
// по return, по исключению, по break. C#: try/finally или using.
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
    // w += v; // ошибка: w объявлен const, а operator+= — не const-метод
    std::println("v = {}, w = {:.1f}, |v| = {:.3f}, equal: {}", v, w, v.length(), v == Vec2{4, 5});

    constexpr Date release{2026, 11, 17};
    static_assert(release > Date{2026, 2, 28}); // сравнение выполнено при компиляции
    std::println("dates: {} {} {}", release == Date{2026, 11, 17}, release < Date{2027, 1, 1},
                 Date{} < release);

    // --- Время жизни объектов ---------------------------------------------------------
    {
        Tracer a{"a"};               // объект живёт прямо на стеке, без new
        Tracer b = make_tracer("b"); // ни копии, ни перемещения: copy elision
        Tracer c = a;                // копирующий конструктор
        // std::move ничего не перемещает: это приведение типа, означающее «этот объект
        // мне больше не нужен, его можно ограбить». Перемещает конструктор Tracer(Tracer&&).
        Tracer d = std::move(a);
        // После перемещения `a` жив, но «пуст»: его можно только уничтожить или
        // присвоить ему новое значение.
        consume(std::move(c));
        std::println("    live objects: {}", Tracer::live());
        std::println("    end of scope");
    } // деструкторы вызываются ЗДЕСЬ, в порядке, обратном созданию: d, c, b, a

    // --- Правило пяти и правило нуля --------------------------------------------------
    Buffer original{3};
    original[0] = 1.5;
    Buffer deep_copy = original;         // копирующий конструктор: независимый буфер
    deep_copy[0] = 99.0;
    Buffer stolen = std::move(original); // перемещающий: забрали указатель, original пуст
    std::println("original alive: {}, stolen[0] = {}, deep_copy[0] = {}, sizes {} and {}",
                 static_cast<bool>(original), stolen[0], deep_copy[0], stolen.size(),
                 deep_copy.size());

    SafeBuffer safe{{1.0, 2.0, 3.0}};
    SafeBuffer safe_copy = safe;        // сгенерированное копирование
    SafeBuffer safe_moved = std::move(safe); // сгенерированное перемещение
    std::println("rule of zero: copy has {}, moved has {}", safe_copy.data.size(),
                 safe_moved.data.size());

    // --- RAII как замена finally ------------------------------------------------------
    {
        ScopeGuard guard{[] { std::println("    guard: cleanup runs on scope exit"); }};
        std::println("    guard: doing work");
    }
}

// =====================================================================================
//  5. ВЛАДЕНИЕ ПАМЯТЬЮ: УМНЫЕ УКАЗАТЕЛИ
// =====================================================================================
//
//  Локальные объекты живут на стеке и уничтожаются сами. Объект в куче создаёт `new`,
//  а освобождать его нужно вручную через `delete`:
//
//      Tracer* raw = new Tracer{"heap"};
//      delete raw;       // забыли — утечка; вызвали дважды — UB; обратились после — UB
//
//  Поэтому в современном C++ new/delete напрямую не пишут. Владение выражают типами:
//    std::unique_ptr<T> — один владелец (выбор по умолчанию, накладных расходов нет);
//    std::shared_ptr<T> — много владельцев, подсчёт ссылок;
//    std::weak_ptr<T>   — наблюдатель за shared_ptr, не продлевающий жизнь объекта;
//    T* и T&            — невладеющие «наблюдатели»: тот, кто их получил, ничего не удаляет.

// Дерево с обратными ссылками: вниз — владеющие, вверх — слабые.
struct TreeNode {
    std::string name;
    std::vector<std::shared_ptr<TreeNode>> children;
    std::weak_ptr<TreeNode> parent; // с shared_ptr здесь получился бы цикл и утечка: GC нет

    explicit TreeNode(std::string node_name) : name{std::move(node_name)} {}

    [[nodiscard]] std::string path() const {
        // lock(): weak_ptr -> shared_ptr; пустой, если объект уже уничтожен.
        if (auto owner = parent.lock()) return owner->path() + "/" + name;
        return name;
    }
};

void add_child(const std::shared_ptr<TreeNode>& parent, std::shared_ptr<TreeNode> child) {
    child->parent = parent;
    parent->children.push_back(std::move(child));
}

// Свой «удалитель»: RAII-обёртка над ресурсом из C-библиотеки. Здесь это память от
// std::malloc; точно так же оборачивают FILE*, дескрипторы ОС, объекты OpenGL и т.п.
struct FreeDeleter {
    void operator()(void* memory) const noexcept { std::free(memory); }
};
using CString = std::unique_ptr<char, FreeDeleter>; // using — псевдоним типа

CString duplicate_c_string(std::string_view text) {
    auto* memory = static_cast<char*>(std::malloc(text.size() + 1));
    if (memory == nullptr) throw std::bad_alloc{};
    std::memcpy(memory, text.data(), text.size());
    memory[text.size()] = '\0';
    return CString{memory};
}

// unique_ptr в сигнатуре документирует передачу владения.
std::unique_ptr<Tracer> make_owned(std::string name) {
    return std::make_unique<Tracer>(std::move(name)); // «фабрика»: владение уходит вызывающему
}

void take_ownership(std::unique_ptr<Tracer> owned) { // «сток»: функция забирает объект себе
    std::println("    took ownership of {}", owned->name());
} // здесь объект уничтожается

void section05_smart_pointers() {
    header(5, "Memory ownership: smart pointers");

    // --- unique_ptr -------------------------------------------------------------------
    auto owner = make_owned("unique");
    // auto copy = owner;           // ошибка компиляции: unique_ptr нельзя копировать
    Tracer* observer = owner.get(); // сырой указатель как невладеющий наблюдатель — это нормально
    std::println("    observer sees {}", observer->name());
    auto new_owner = std::move(owner); // владение передано; owner гарантированно стал nullptr
    std::println("    owner is null: {}, new owner holds {}", owner == nullptr, new_owner->name());
    take_ownership(std::move(new_owner));
    std::println("    after take_ownership");
    // observer теперь ВИСЯЧИЙ указатель: объект уничтожен. Разыменовать его — UB,
    // и компилятор об этом не предупредит.

    auto numbers = std::make_unique<int[]>(4); // массив в куче; обычно лучше std::vector
    numbers[2] = 7;
    CString c_string = duplicate_c_string("released by std::free");
    std::println("numbers[2] = {}, c string: {}", numbers[2], c_string.get());

    // --- shared_ptr и weak_ptr --------------------------------------------------------
    // Ближайший аналог обычной ссылки C#, только вместо GC — счётчик (атомарный).
    auto shared = std::make_shared<std::string>("shared text");
    auto another = shared; // копия указателя: +1 к счётчику, строка не копируется
    std::println("use_count = {}, same object: {}", shared.use_count(), shared == another);
    another.reset(); // отпустить свою долю владения
    std::println("use_count after reset = {}", shared.use_count());

    auto root = std::make_shared<TreeNode>("root");
    auto usr = std::make_shared<TreeNode>("usr");
    auto bin = std::make_shared<TreeNode>("bin");
    add_child(root, usr);
    add_child(usr, bin);
    std::println("{} | usr use_count = {}", bin->path(), usr.use_count());
    root.reset(); // корень уничтожен: слабая ссылка usr->parent «протухла»
    std::println("{} after the root is destroyed", bin->path());

    // Типичные ошибки, которые C++ НЕ ловит (всё это UB):
    //   - вернуть ссылку или string_view на локальную переменную;
    //   - держать итератор, ссылку или указатель на элемент vector после push_back
    //     (вектор мог переехать в новый буфер);
    //   - обратиться к объекту после delete / reset / выхода владельца из области видимости;
    //   - выйти за границы массива; прочитать неинициализированную переменную.
    // Инструменты: предупреждения (-Wall -Wextra), санитайзеры
    // (-fsanitize=address,undefined), статические анализаторы. И главное — RAII
    // и стандартные контейнеры вместо ручного управления памятью.
}

// =====================================================================================
//  6. НАСЛЕДОВАНИЕ И ПОЛИМОРФИЗМ
// =====================================================================================

// Абстрактный базовый класс. C#: abstract class.
class Shape {
public:
    // ВИРТУАЛЬНЫЙ ДЕСТРУКТОР обязателен, если объекты удаляют через указатель на базу:
    // иначе деструктор наследника не вызовется (UB).
    virtual ~Shape() = default;

    // «= 0» — чисто виртуальная функция. C#: abstract.
    [[nodiscard]] virtual double area() const = 0;

    // Виртуальная функция с реализацией. C#: virtual.
    // ВНИМАНИЕ: без слова virtual метод НЕ виртуальный — в C# так же, а в Java иначе.
    [[nodiscard]] virtual std::string name() const { return "shape"; }

    // Невиртуальный метод, вызывающий виртуальные («шаблонный метод»).
    [[nodiscard]] std::string describe() const {
        return std::format("{} with area {:.2f}", name(), area());
    }
};

// Наследование. `public` значит «является» (is-a). final — как sealed в C#.
class Circle final : public Shape {
public:
    explicit Circle(double radius) : radius_{radius} {}

    // override: компилятор проверит, что метод действительно переопределяет виртуальный.
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

protected: // доступно самому классу и наследникам
    double width_;
    double height_;
};

class Square final : public Rectangle {
public:
    // Вызов конструктора базового класса. C#: `: base(side, side)`.
    explicit Square(double side) : Rectangle{side, side} {}

    // Обращение к реализации базового класса. C#: base.Name().
    [[nodiscard]] std::string name() const override { return "square, a " + Rectangle::name(); }
};

// Отдельной сущности «интерфейс» нет: это класс, в котором только чисто виртуальные
// функции. Множественное наследование разрешено для любых классов.
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
        return std::format("{{\"label\": \"{}\"}}", text_); // {{ и }} — экранированные скобки
    }

private:
    std::string text_;
};

// Порядок: конструкторы идут от базы к наследнику, деструкторы — в обратную сторону.
// Пока работает конструктор базы, объект ещё «является» базой: виртуальный вызов
// НЕ попадёт в наследника. (В C# попал бы — в объект, чей конструктор ещё не выполнен.)
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

    // Полиморфизм работает только через ссылку или указатель. Контейнер разнородных
    // объектов — это контейнер (умных) указателей на базовый класс.
    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.push_back(std::make_unique<Circle>(1.0));
    shapes.push_back(std::make_unique<Rectangle>(2.0, 3.0));
    shapes.push_back(std::make_unique<Square>(2.0));

    double total = 0.0;
    for (const auto& shape : shapes) {
        total += shape->area(); // виртуальный вызов через таблицу методов (vtable)
        std::println("{}", shape->describe());
        // dynamic_cast — проверяемое приведение вниз по иерархии.
        // C#: `if (shape is Circle circle)`.
        if (const auto* circle = dynamic_cast<const Circle*>(shape.get())) {
            std::println("    it is a circle of radius {}", circle->radius());
        }
    }
    std::println("total area {:.2f}", total);

    // «Срезка» (slicing): копирование наследника в переменную базового типа оставляет
    // только базовую часть. Объект sliced — честный Rectangle, а не Square.
    Square square{2.0};
    Rectangle sliced = square;
    const Shape& reference = square; // через ссылку объект остаётся собой
    std::println("sliced: {} | by reference: {}", sliced.name(), reference.name());

    // Множественное наследование: один объект виден через оба «интерфейса».
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
//  7. ЛЯМБДЫ И ВЫЗЫВАЕМЫЕ ОБЪЕКТЫ
// =====================================================================================

// Функтор — класс с operator(). Лямбда — синтаксический сахар именно для такого класса:
// компилятор создаёт безымянный тип, поля которого — захваченные переменные.
struct Multiplier {
    int factor;
    int operator()(int x) const { return x * factor; }
};

// Функция высшего порядка. Вызываемый объект принимают шаблонным параметром: тогда
// вызов разрешается при компиляции и инлайнится. std::invocable — концепт (раздел 9).
int apply_twice(std::invocable<int> auto&& f, int x) { return f(f(x)); }

// Вернуть лямбду из функции: тип результата выводится (его нельзя записать руками).
auto make_adder(int n) {
    return [n](int x) { return x + n; }; // n захвачен ПО ЗНАЧЕНИЮ: копия живёт в лямбде
    // Захват по ссылке (`[&n]`) дал бы висячую ссылку: n умрёт вместе с вызовом make_adder.
}

struct Person {
    std::string name;
    int age;
};

void section07_lambdas() {
    header(7, "Lambdas and callable objects");

    // --- Захват ----------------------------------------------------------------------
    // [захват](параметры) { тело }. В C# замыкание всегда захватывает ПЕРЕМЕННУЮ
    // (по ссылке); в C++ способ захвата выбирают явно.
    int factor = 3;
    auto by_value = [factor](int x) { return x * factor; }; // копия factor внутри лямбды
    auto by_reference = [&factor](int x) { return x * factor; }; // ссылка на factor
    factor = 10;
    std::println("by value {}, by reference {}", by_value(2), by_reference(2)); // 6 и 20
    // [=] — захватить всё используемое по значению, [&] — всё по ссылке.

    // Захват с инициализатором + mutable: у лямбды собственное изменяемое состояние.
    auto next_id = [id = 100]() mutable { return id++; };
    // Вызовы стоят в отдельных инструкциях не случайно: порядок вычисления аргументов
    // функции в C++ НЕ определён (в C# — строго слева направо), так что запись
    // `print(next_id(), next_id())` дала бы разный результат в разных компиляторах.
    int id1 = next_id();
    int id2 = next_id();
    int id3 = next_id();
    std::println("ids: {} {} {}", id1, id2, id3);

    // Захват с перемещением: единственный способ положить в лямбду unique_ptr.
    auto resource = std::make_unique<std::string>("moved into the lambda");
    auto use_resource = [owned = std::move(resource)] { return owned->size(); };
    std::println("resource moved away: {}, size {}", resource == nullptr, use_resource());

    // Обобщённая лямбда: параметры auto делают её шаблоном.
    auto smaller = [](const auto& a, const auto& b) { return a < b ? a : b; };
    std::println("{} {} {}", smaller(3, 7), smaller(2.5, 1.5), smaller("pear"s, "apple"s));

    // --- Все виды «вызываемого» -------------------------------------------------------
    Multiplier triple{3};                       // функтор
    int (*function_pointer)(int, int) = add;    // указатель на функцию (выбрана перегрузка для int)
    int (*from_lambda)(int) = [](int x) { return x + 1; }; // лямбда БЕЗ захвата -> указатель
    std::println("{} {} {} {} {}", triple(5), function_pointer(2, 3), from_lambda(41),
                 apply_twice(triple, 2), apply_twice(make_adder(10), 1));

    // std::function — «делегат»: единый тип для любого вызываемого объекта с данной
    // сигнатурой. C#: Func<double, double, double>. Цена — косвенный вызов и, возможно,
    // аллокация, поэтому там, где тип известен при компиляции, предпочитают шаблоны.
    std::map<char, std::function<double(double, double)>> operations{
        {'+', std::plus<>{}}, // готовые функторы из <functional>
        {'*', [](double a, double b) { return a * b; }},
        {'^', [](double a, double b) { return std::pow(a, b); }},
    };
    std::println("6 * 7 = {}, 2 ^ 10 = {}", operations['*'](6, 7), operations['^'](2, 10));

    // Указатели на члены класса и универсальный std::invoke.
    Vec2 v{3, 4};
    double (Vec2::*method)() const = &Vec2::length; // указатель на метод
    int Person::*field = &Person::age;              // указатель на поле
    Person ann{"Ann", 30};
    std::println("{} {} {} {}", (v.*method)(), ann.*field, std::invoke(method, v),
                 std::invoke(&Person::name, ann));

    // Частичное применение: «привязать» первые аргументы.
    auto times_two = std::bind_front(std::multiplies<>{}, 2);
    std::println("bind_front: {}", times_two(21));

    // Немедленно вызываемая лямбда: сложная инициализация const-переменной.
    const std::string banner = [&] {
        std::string result = "factor";
        if (factor > 5) result += " is big";
        return result;
    }();
    std::println("{}", banner);

    // --- Лямбды + алгоритмы + проекции ------------------------------------------------
    std::vector<Person> people{{"Cid", 35}, {"Ann", 30}, {"Bob", 25}};
    // Третий аргумент — проекция: «сравнивай по полю age». C#: OrderByDescending(p => p.Age).
    std::ranges::sort(people, std::greater<>{}, &Person::age);
    std::println("by age desc: {}", join(people | std::views::transform(&Person::name)));
    auto youngest = std::ranges::min_element(people, {}, &Person::age);
    std::println("youngest: {} ({})", youngest->name, youngest->age);
}

// =====================================================================================
//  8. АЛГОРИТМЫ И ДИАПАЗОНЫ (RANGES)
// =====================================================================================

void section08_algorithms_and_ranges() {
    header(8, "Algorithms and ranges");

    std::vector<int> numbers{5, 3, 8, 1, 9, 2, 7, 4, 6, 10};

    // --- Классические алгоритмы: пара итераторов [begin, end) ---------------------------
    // Итератор — обобщённый указатель: `*it` — элемент, `++it` — следующий, а end()
    // указывает на позицию ЗА последним элементом. C#: IEnumerator, но с арифметикой.
    auto seven = std::find(numbers.begin(), numbers.end(), 7);
    int total = std::accumulate(numbers.begin(), numbers.end(), 0); // C#: Sum / Aggregate
    std::println("7 is at index {}, total {}", seven - numbers.begin(), total);

    // --- Алгоритмы над диапазонами (C++20): контейнер целиком ---------------------------
    std::ranges::sort(numbers);
    auto [smallest, largest] = std::ranges::minmax(numbers);
    auto is_even = [](int n) { return n % 2 == 0; };
    std::println("[{}] min {} max {} | any even: {} | all positive: {} | count > 5: {}",
                 join(numbers), smallest, largest, std::ranges::any_of(numbers, is_even),
                 std::ranges::all_of(numbers, [](int n) { return n > 0; }),
                 std::ranges::count_if(numbers, [](int n) { return n > 5; }));

    // Бинарный поиск по отсортированному диапазону; contains — C++23.
    auto lower = std::ranges::lower_bound(numbers, 6);
    std::println("lower_bound(6) at index {}, contains 11: {}", lower - numbers.begin(),
                 std::ranges::contains(numbers, 11));

    // Удаление по условию. C#: RemoveAll.
    std::vector<int> odds = numbers;
    std::erase_if(odds, is_even);
    // Преобразование «на месте» и в другой контейнер.
    std::vector<int> doubled(odds.size());
    std::ranges::transform(odds, doubled.begin(), [](int n) { return n * 2; });
    std::println("odds [{}], doubled [{}]", join(odds), join(doubled));

    // --- Views: ленивые конвейеры. C#: LINQ -------------------------------------------
    // Адаптеры соединяются оператором `|`. View ничего не вычисляет и не хранит: это
    // описание обхода. Работа выполняется, когда по нему идут циклом.
    auto square = [](int n) { return n * n; };
    auto even_squares = numbers | std::views::filter(is_even)   // C#: Where
                                | std::views::transform(square); // C#: Select
    std::println("even squares: {}", join(even_squares));

    // Материализация в контейнер (C++23). C#: ToList().
    auto as_vector = even_squares | std::ranges::to<std::vector>();
    auto as_set = numbers | std::views::transform([](int n) { return n % 3; })
                          | std::ranges::to<std::set>();
    std::println("vector of {} elements, set of remainders [{}]", as_vector.size(), join(as_set));

    // iota — генератор последовательности. C#: Enumerable.Range.
    // Бесконечный диапазон + take_while: вычисляется только то, что спросили.
    auto below_60 = [](int n) { return n < 60; };
    auto squares_below_60 = std::views::iota(1) | std::views::transform(square)
                                                | std::views::take_while(below_60);
    std::println("iota(1, 6): {} | squares below 60: {}", join(std::views::iota(1, 6)),
                 join(squares_below_60));

    // take / drop / reverse. C#: Take, Skip, Reverse.
    std::println("last three reversed: {} | without first seven: {}",
                 join(numbers | std::views::reverse | std::views::take(3)),
                 join(numbers | std::views::drop(7)));

    // keys / values — проекции пар словаря.
    std::map<std::string, int> ages{{"Ann", 30}, {"Bob", 25}, {"Cid", 35}};
    std::println("keys: {} | values: {}", join(ages | std::views::keys),
                 join(ages | std::views::values));

    // split — разбить строку без копирования: каждый кусок — поддиапазон символов.
    std::vector<std::string_view> parts;
    for (auto part : "alpha,beta,gamma"sv | std::views::split(',')) {
        parts.emplace_back(part.begin(), part.end());
    }
    std::println("split: {}", join(parts, " | "));

    // join — «расплющить» вложенные диапазоны. C#: SelectMany.
    std::vector<std::vector<int>> nested{{1, 2}, {3}, {4, 5, 6}};
    std::println("flattened: {}", join(nested | std::views::join));

    // View не владеет данными: изменили источник — изменился и результат обхода.
    numbers[1] = 100;
    std::println("after numbers[1] = 100: {}", join(even_squares));
    // Адаптеры C++23 (zip, enumerate, chunk, slide, ...) — в разделе 16.
}

// =====================================================================================
//  9. ШАБЛОНЫ И КОНЦЕПТЫ
// =====================================================================================
//
//  Обобщение в C# — один скомпилированный метод, работающий с любым T, который
//  удовлетворяет ограничениям `where`. Шаблон в C++ — РЕЦЕПТ: для каждого набора
//  аргументов компилятор генерирует отдельную функцию или класс и только тогда
//  проверяет тело. Отсюда:
//    + нулевые накладные расходы, специализации, вычисления над типами и значениями;
//    + «утиная типизация»: подойдёт любой тип, для которого тело компилируется;
//    − шаблон должен быть виден целиком в месте использования (обычно в заголовке);
//    − ошибки без концептов длинные и возникают глубоко внутри.

// --- Шаблон функции ---------------------------------------------------------------------
template <typename T>
T max_of(T a, T b) {
    return a < b ? b : a; // требование «у T есть operator<» нигде не записано: утиная типизация
}

// --- Концепты (C++20): именованные ограничения. C#: where T : ... ------------------------
template <typename T>
concept Number = std::integral<T> || std::floating_point<T>;

// requires-выражение описывает, что с типом МОЖНО сделать: «у объекта есть метод area(),
// и результат приводится к double». Наследоваться от чего-либо типу не нужно.
template <typename T>
concept HasArea = requires(const T& value) {
    { value.area() } -> std::convertible_to<double>;
};

// Ограничение на параметр шаблона и отдельное requires-условие.
template <std::ranges::input_range Range>
    requires Number<std::ranges::range_value_t<Range>>
auto sum_of(const Range& range) {
    std::ranges::range_value_t<Range> total{}; // «тип элементов этого диапазона»
    for (const auto& value : range) total += value;
    return total;
}

// --- Вариативные шаблоны и свёртки (fold expressions, C++17) ----------------------------
// `auto` в параметре — сокращённая запись шаблона; `...` — пакет параметров.
double total_area(const HasArea auto&... shapes) {
    return (0.0 + ... + shapes.area()); // развернётся в 0.0 + a.area() + b.area() + ...
}

template <typename... Args>
std::string concat(const Args&... args) {
    std::string result;
    // Свёртка по оператору «запятая»: выполнить выражение для каждого аргумента пакета.
    ((result += std::format("{}", args)), ...);
    return result;
}

// --- Шаблон класса с параметрами-ЗНАЧЕНИЯМИ ---------------------------------------------
// В C# аналога нет. Matrix<double, 2, 3> и Matrix<double, 3, 2> — разные типы,
// а размеры проверяются при компиляции.
template <Number T, std::size_t Rows, std::size_t Cols>
class Matrix {
public:
    constexpr Matrix() = default;

    constexpr Matrix(std::initializer_list<T> values) { // позволяет писать Matrix{1, 2, 3}
        std::copy_n(values.begin(), std::min(values.size(), data_.size()), data_.begin());
    }

    // Многомерный operator[] (C++23): m[row, col].
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
    std::array<T, Rows * Cols> data_{}; // размер массива вычислен из параметров шаблона
};

// Умножение определено только для согласованных размеров: (R x K) * (K x C) = (R x C).
// Несогласованные размеры — ошибка компиляции: подходящей функции просто не найдётся.
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

// --- Специализация: своя реализация шаблона для конкретных аргументов --------------------
template <typename T>
struct TypeName { // общий случай
    static constexpr std::string_view value = "something";
};

template <>
struct TypeName<int> { // полная специализация
    static constexpr std::string_view value = "int";
};

template <typename T>
struct TypeName<std::vector<T>> { // частичная: для ЛЮБОГО вектора
    static constexpr std::string_view value = "vector";
};

template <typename T>
struct TypeName<T*> { // частичная: для любого указателя
    static constexpr std::string_view value = "pointer";
};

// --- if constexpr: ветвление при компиляции (C++17) --------------------------------------
// Невыбранная ветка не инстанцируется, поэтому в ней может стоять код, который для
// данного T вообще не компилируется.
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

// --- Шаблон класса, правило вывода, шаблонный конструктор --------------------------------
template <typename T>
class Stack {
public:
    Stack() = default;

    // Конструктор-шаблон: принимает пару любых итераторов.
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

// Правило вывода (deduction guide): как получить T из аргументов конструктора.
// Благодаря ему `Stack s(v.begin(), v.end());` сам выведет Stack<int>.
template <std::input_iterator Iterator>
Stack(Iterator, Iterator) -> Stack<std::iter_value_t<Iterator>>;

// --- Идеальная передача (perfect forwarding) ---------------------------------------------
// `Args&&` при выводе типа — «универсальная» ссылка: принимает и lvalue, и rvalue.
// std::forward передаёт аргумент дальше, сохраняя эту категорию (копировать или
// перемещать — решит получатель). decltype(auto) сохраняет ссылочность результата.
template <typename Function, typename... Args>
decltype(auto) logged_call(std::string_view label, Function&& function, Args&&... args) {
    std::println("    calling {} with {} argument(s)", label, sizeof...(Args));
    return std::invoke(std::forward<Function>(function), std::forward<Args>(args)...);
}

// --- CRTP: статический полиморфизм -------------------------------------------------------
// Базовый класс параметризован наследником и вызывает его методы БЕЗ виртуальности:
// всё разрешается при компиляции. (В C++23 то же проще делается через «deducing this»,
// раздел 16.)
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

// --- SFINAE: как ограничивали шаблоны до концептов ---------------------------------------
// «Substitution failure is not an error»: если подстановка типа даёт некорректную
// сигнатуру, шаблон молча исключается из перегрузок. Встречается в любом старом коде.
template <typename T, std::enable_if_t<std::is_integral_v<T>, int> = 0>
bool is_even_legacy(T value) {
    return value % 2 == 0;
}

// То же самое с концептом.
bool is_even(std::integral auto value) { return value % 2 == 0; }

// --- Шаблоны псевдонимов и переменных ----------------------------------------------------
template <typename T>
using Grid = std::vector<std::vector<T>>;

template <typename T>
constexpr T golden_ratio = T(1.6180339887498948482L);

// Типы, пригодные для total_area: никакого общего базового класса у них нет.
struct UnitSquare {
    [[nodiscard]] double area() const { return 1.0; }
};

struct Disc {
    double radius;
    [[nodiscard]] double area() const { return std::numbers::pi * radius * radius; }
};

void section09_templates() {
    header(9, "Templates and concepts");

    // Аргументы шаблона выводятся из аргументов вызова; при необходимости задаются явно.
    std::println("{} {} {} {}", max_of(3, 7), max_of(2.5, 1.5), max_of("apple"s, "pear"s),
                 max_of<double>(3, 7.5));
    // max_of(3, 7.5); // ошибка: T не может быть int и double одновременно

    std::println("sum_of: {} {} | total_area {:.3f} | concat {}", sum_of(std::vector{1, 2, 3}),
                 sum_of(std::array{0.5, 1.5}), total_area(UnitSquare{}, Disc{1.0}, UnitSquare{}),
                 concat("x=", 42, ", pi=", 3.14));
    // sum_of(std::vector<std::string>{}); // ошибка: constraints not satisfied — коротко и по делу
    static_assert(Number<int> && !Number<std::string>); // концепт — это ещё и булева константа
    static_assert(HasArea<Disc> && !HasArea<int>);

    // Матрицы: размеры — часть типа.
    constexpr Matrix<int, 2, 3> m{1, 2, 3, 4, 5, 6};
    constexpr auto product = m * m.transposed(); // Matrix<int, 2, 2>, вычислено при компиляции
    static_assert(product[0, 0] == 14 && product[1, 1] == 77);
    // auto bad = m * m; // ошибка: нет operator* для Matrix<int, 2, 3> и Matrix<int, 2, 3>
    std::println("m * mT = [[{}, {}], [{}, {}]]", product[0, 0], product[0, 1], product[1, 0],
                 product[1, 1]);

    std::println("TypeName: {} {} {} {}", TypeName<int>::value, TypeName<double>::value,
                 TypeName<std::vector<char>>::value, TypeName<int*>::value);
    std::println("{} | {} | {} | {}", describe(42), describe("text"), describe(std::vector{1, 2}),
                 describe(Disc{2.0}));

    // Вывод аргументов шаблона КЛАССА (CTAD, C++17): <int> писать не нужно.
    std::vector source{1, 2, 3}; // std::vector<int>
    std::pair pair{1, 2.5};      // std::pair<int, double>
    Stack stack(source.begin(), source.end()); // Stack<int> — по нашему правилу вывода
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

    // Типы — тоже данные времени компиляции: decltype и type traits.
    auto lambda = [](int x) { return x * 0.5; };
    static_assert(std::same_as<decltype(lambda(1)), double>);
    static_assert(std::same_as<std::remove_cvref_t<const int&>, int>);
    static_assert(std::same_as<std::common_type_t<int, double>, double>);
}

// =====================================================================================
//  10. ТИПЫ-СУММЫ: optional, variant, any
// =====================================================================================

// Идиома «перегруженный набор лямбд» для std::visit: класс наследуется от всех
// переданных лямбд сразу и вносит все их operator() в одну область видимости.
// Три строки, которые показывают сразу вариативное наследование, using с пакетом
// и вывод аргументов шаблона для агрегата.
template <typename... Functions>
struct overloaded : Functions... {
    using Functions::operator()...;
};

// std::variant — типобезопасный union: хранит РОВНО ОДНО из перечисленных значений
// и помнит, какое именно. C#: union из C# 15 или иерархия record-ов + switch.
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
    // std::visit вызывает ту перегрузку, что соответствует текущему содержимому.
    // Забыли обработать вариант — ошибка компиляции (как исчерпывающий switch).
    return std::visit(
        overloaded{
            [](const CircleData& c) { return std::numbers::pi * c.radius * c.radius; },
            [](const RectData& r) { return r.width * r.height; },
            [](const TriangleData& t) {
                double s = (t.a + t.b + t.c) / 2; // формула Герона
                return std::sqrt(s * (s - t.a) * (s - t.b) * (s - t.c));
            },
        },
        shape);
}

// Рекурсивный тип: дерево выражения. variant не может содержать сам себя по значению
// (размер был бы бесконечным), поэтому дочерние узлы хранятся через unique_ptr.
struct Expr; // предварительное объявление: «такой тип есть, определение — ниже»
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

// Маленькие «конструкторы» узлов, чтобы дерево читалось как формула.
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
            // at() бросит std::out_of_range, если переменной нет (раздел 11).
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

    // --- std::optional<T>: значение или «ничего». C#: T? -------------------------------
    std::optional<double> root = safe_sqrt(16.0);
    if (root) { // optional приводится к bool: «есть ли значение»
        std::println("sqrt = {}", *root); // `*` достаёт значение; для пустого optional это UB
    }
    std::println("value_or: {} | has_value: {}", safe_sqrt(-1.0).value_or(0.0),
                 safe_sqrt(-1.0).has_value());
    // .value() на пустом optional бросает std::bad_optional_access — проверяемый доступ.

    // Монадические операции (C++23): цепочка без явных проверок. C#: ?. и ??
    auto described = safe_sqrt(81.0)
                         .and_then(safe_sqrt) // продолжить, если значение есть
                         .transform([](double x) { return std::format("4th root = {}", x); })
                         .or_else([] { return std::optional{"no value"s}; }); // запасной вариант
    std::println("{} | {}", *described,
                 safe_sqrt(-4.0).transform([](double x) { return x + 1; }).has_value());

    // --- std::variant -----------------------------------------------------------------
    std::vector<ShapeData> shapes{CircleData{1.0}, RectData{2.0, 3.0}, TriangleData{3, 4, 5}};
    for (const auto& shape : shapes) {
        std::print("alternative #{} area {:.3f}; ", shape.index(), area_of(shape));
    }
    std::println("");

    ShapeData shape = RectData{4.0, 5.0};
    // Три способа заглянуть внутрь без visit:
    bool is_rect = std::holds_alternative<RectData>(shape); // проверить тип
    if (const auto* rect = std::get_if<RectData>(&shape)) {  // указатель или nullptr
        std::println("rect {} x {}, is_rect {}", rect->width, rect->height, is_rect);
    }
    try {
        (void)std::get<CircleData>(shape); // исключение, если внутри лежит другой тип
    } catch (const std::bad_variant_access& error) {
        std::println("std::get of the wrong type throws: {}", error.what());
    }

    // -(x + 2) * 3
    ExprPtr formula = mul(neg(add(var("x"), num(2.0))), num(3.0));
    std::println("eval = {}", eval(*formula, {{"x", 5.0}}));

    // --- std::any: значение любого типа. C#: object + проверка типа ---------------------
    std::vector<std::any> things{42, "text"s, 3.5};
    for (const auto& thing : things) {
        if (const int* number = std::any_cast<int>(&thing)) { // указатель или nullptr
            std::print("int {}; ", *number);
        } else if (const auto* string = std::any_cast<std::string>(&thing)) {
            std::print("string '{}'; ", *string);
        } else {
            // type() возвращает std::type_info — зачаток информации о типах времени выполнения.
            std::print("something else, a double: {}; ", thing.type() == typeid(double));
        }
    }
    std::println("");
}

// =====================================================================================
//  11. ОБРАБОТКА ОШИБОК
// =====================================================================================
//
//  В C++ уживаются два подхода:
//    - исключения — как в C#, но без finally: его роль играют деструкторы (RAII);
//    - ошибки-значения: коды ошибок, std::optional, std::expected (C++23).
//  Исключения хороши для действительно исключительных ситуаций. Там, где ошибка —
//  штатный исход (разбор ввода, поиск), всё чаще возвращают std::expected.

// Свой класс исключения. Стандартная иерархия начинается со std::exception.
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
    if (it == config.end()) throw ConfigError{"port", "is missing"}; // бросают ПО ЗНАЧЕНИЮ
    int port = 0;
    const std::string& text = it->second;
    auto [end, error] = std::from_chars(text.data(), text.data() + text.size(), port);
    if (error != std::errc{} || end != text.data() + text.size()) {
        throw ConfigError{"port", "'" + text + "' is not a number"};
    }
    if (port < 1 || port > 65535) throw std::out_of_range{"port " + text + " is out of range"};
    return port;
}

// Ошибка как значение: std::expected<T, E> хранит либо результат, либо ошибку.
// C#: в стандартной библиотеке аналога нет (есть сторонние Result<T, E>).
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
    // and_then продолжает цепочку только при успехе; ошибка «протекает» насквозь.
    return parse_int(text).and_then([](int value) -> std::expected<int, ParseError> {
        if (value < 1 || value > 65535) return std::unexpected{ParseError::out_of_range};
        return value;
    });
}

// noexcept — обещание не бросать исключений. Нарушение обещания завершает программу
// (std::terminate), зато компилятор и контейнеры могут выбирать более быстрые пути.
int clamp_percent(int value) noexcept { return std::clamp(value, 0, 100); }

// std::source_location (C++20): место вызова подставляется само.
// C#: [CallerFilePath], [CallerLineNumber], [CallerMemberName].
void log_here(std::string_view message,
              std::source_location where = std::source_location::current()) {
    std::println("    [line {} in {}] {}", where.line(), where.function_name(), message);
}

void section11_errors() {
    header(11, "Error handling");

    // --- Исключения ---------------------------------------------------------------------
    const std::vector<std::map<std::string, std::string>> configs{
        {{"port", "8080"}}, {{"host", "localhost"}}, {{"port", "80a"}}, {{"port", "70000"}}};
    for (const auto& config : configs) {
        try {
            std::println("port = {}", read_port(config));
        } catch (const ConfigError& error) { // ловят по const-ссылке; сначала более узкий тип
            std::println("config error for key '{}': {}", error.key(), error.what());
        } catch (const std::exception& error) { // базовый класс стандартных исключений
            std::println("other error: {}", error.what());
        }
        // catch (...) поймал бы вообще всё, включая не-исключения вроде `throw 42;`
    }

    // При раскрутке стека вызываются деструкторы всех локальных объектов — так работает
    // RAII: ресурсы освобождаются без finally. C#: using / try-finally.
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
    // transform меняет значение, value_or даёт запасной вариант, or_else обрабатывает ошибку.
    std::println("{} | {}", parse_port("80").transform([](int p) { return p * 2; }).value_or(0),
                 parse_port("oops").value_or(8000));

    // --- Коды ошибок ------------------------------------------------------------------
    // std::error_code — «номер ошибки + категория». Так сообщают об ошибках системные
    // и сетевые библиотеки: у std::filesystem есть перегрузки и с кодом, и с исключением.
    std::error_code code = std::make_error_code(std::errc::permission_denied);
    std::println("error_code {}: {}", code.value(), code.message());

    log_here("source_location captured the call site");
    // assert(condition) из <cassert> проверяется только в отладочной сборке (без NDEBUG);
    // static_assert — при компиляции (раздел 12).
}

// =====================================================================================
//  12. ВЫЧИСЛЕНИЯ НА ЭТАПЕ КОМПИЛЯЦИИ
// =====================================================================================
//
//  constexpr-функцию можно вызвать и во время выполнения, и при компиляции — когда
//  результат нужен как константа. В C# константой может быть только выражение из
//  литералов; здесь при компиляции исполняется почти весь язык: циклы, классы,
//  контейнеры и даже динамическая память (если она освобождена до конца вычисления).

constexpr std::uint64_t factorial(unsigned n) { return n <= 1 ? 1 : n * factorial(n - 1); }

// static_assert — проверка при компиляции. Не выполняется — программа не соберётся.
static_assert(factorial(20) == 2'432'902'008'176'640'000ULL);

// Таблица CRC-32 и сама функция — constexpr.
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

inline constexpr auto crc_table = make_crc_table(); // 1 КБ данных, посчитанных компилятором

constexpr std::uint32_t crc32(std::string_view text) {
    std::uint32_t crc = 0xFFFF'FFFFu;
    for (char ch : text) {
        crc = crc_table[(crc ^ static_cast<unsigned char>(ch)) & 0xFFu] ^ (crc >> 8);
    }
    return ~crc;
}

// Эталонное значение CRC-32: модульный тест, который выполняет компилятор.
static_assert(crc32("123456789") == 0xCBF4'3926u);

// constexpr-функция с std::vector внутри: память выделяется и освобождается прямо
// во время компиляции (C++20).
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

// consteval («немедленная» функция, C++20) ОБЯЗАНА вычисляться при компиляции.
// throw в константном вычислении — это ошибка компиляции с понятным местом.
consteval int checked_percent(int value) {
    if (value < 0 || value > 100) throw std::invalid_argument{"percent must be within 0..100"};
    return value;
}

constexpr int default_quality = checked_percent(85);
// constexpr int broken = checked_percent(150); // не скомпилируется

// «switch по строкам», которого в языке нет: метки — хеши, вычисленные при компиляции.
constexpr std::uint32_t fnv1a(std::string_view text) {
    std::uint32_t hash = 2'166'136'261u;
    for (char ch : text) {
        hash ^= static_cast<unsigned char>(ch);
        hash *= 16'777'619u;
    }
    return hash;
}

std::string_view command_kind(std::string_view command) {
    switch (fnv1a(command)) { // а здесь та же функция работает во время выполнения
        case fnv1a("start"):
        case fnv1a("stop"):
            return "lifecycle";
        case fnv1a("status"):
            return "query";
        default:
            return "unknown";
    }
}

// Пользовательские литералы: `1.5_km`. Суффикс — обычная функция operator"".
struct Meters {
    double value;
    constexpr auto operator<=>(const Meters&) const = default;
};
constexpr Meters operator""_m(long double value) { return {static_cast<double>(value)}; }
constexpr Meters operator""_km(long double value) { return {static_cast<double>(value) * 1000.0}; }
constexpr Meters operator+(Meters a, Meters b) { return {a.value + b.value}; }

static_assert(1.5_km + 500.0_m == 2000.0_m);

// Объект класса как параметр шаблона (C++20). FixedString позволяет передать в шаблон
// строковый литерал: Quantity<"kg"> и Quantity<"N"> — разные типы.
template <std::size_t Size>
struct FixedString {
    char chars[Size]{};

    constexpr FixedString(const char (&text)[Size]) { // неявное преобразование из литерала
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

// Вычисления над ТИПАМИ: свёртка по пакету типов.
template <typename T, typename... Candidates>
constexpr bool is_one_of = (std::same_as<T, Candidates> || ...);

static_assert(is_one_of<int, char, int, double> && !is_one_of<float, char, int>);

// Обход кортежа: std::apply разворачивает кортеж в аргументы, свёртка их обходит.
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

// constinit: гарантия, что глобальная переменная проинициализирована при компиляции
// (а не до main() в неопределённом порядке), но при этом остаётся изменяемой.
constinit int launch_count = default_quality / 85;

void section12_compile_time() {
    header(12, "Compile-time evaluation");

    std::println("20! = {}, crc32(\"hello\") = {:#010x}, quality {}", factorial(20), crc32("hello"),
                 default_quality);

    // Таблица, заполненная немедленно вызванной constexpr-лямбдой.
    constexpr auto squares = [] {
        std::array<int, 8> table{};
        for (std::size_t i = 0; i < table.size(); ++i) table[i] = static_cast<int>(i * i);
        return table;
    }();
    static_assert(squares[7] == 49);
    std::println("squares [{}], primes below 100: {}", join(squares), count_primes_below(100));

    // Результат constexpr-функции годится туда, где нужна константа: в размер массива,
    // в аргумент шаблона, в метку case.
    std::array<std::byte, factorial(4)> buffer{}; // std::array<std::byte, 24>
    std::println("buffer of {} bytes | commands: {} {} {}", buffer.size(), command_kind("stop"),
                 command_kind("status"), command_kind("dance"));

    Quantity<"kg"> mass{2.5};
    Quantity<"kg"> total = mass + Quantity<"kg">{0.5};
    Quantity<"N"> force{9.81};
    // auto nonsense = mass + force; // ошибка: operator+ для разных единиц не существует
    std::println("{} {} | {} {} | {} m", total.value, total.unit(), force.value, force.unit(),
                 (1.5_km + 250.0_m).value);

    ++launch_count;
    std::println("{} | launch_count {}", tuple_to_string(std::tuple{1, "two", 3.5}), launch_count);
}

// =====================================================================================
//  13. НИЗКИЙ УРОВЕНЬ: память, биты, аллокаторы
// =====================================================================================

// Поля лежат в памяти в порядке объявления, с выравниванием. Порядок влияет на размер.
struct Padded { // 1 + 7 (выравнивание) + 8 + 4 + 4 (выравнивание) = 24 байта
    char tag;
    double value;
    int count;
};

struct Reordered { // 8 + 4 + 1 + 3 (выравнивание) = 16 байт
    double value;
    int count;
    char tag;
};

struct alignas(64) CacheAligned { // выровнять по границе 64 байта (кеш-линия)
    int counter;
};

struct Flags { // битовые поля: несколько значений в одном машинном слове
    unsigned ready : 1;
    unsigned mode : 3;
    unsigned level : 4;
};

// union: все поля делят одну память. В C++ читать можно только то поле, в которое
// писали последним (чтение другого — UB), поэтому для переинтерпретации байтов
// используют std::bit_cast или std::memcpy, а «тип или тип» выражают через std::variant.
union IntOrFloat {
    std::int32_t as_int;
    float as_float;
};

// Вектор фиксированной ёмкости без кучи: «сырая» память + ручное управление временем
// жизни объектов. Так изнутри устроены std::vector и std::optional. (В C++26 появляется
// готовый std::inplace_vector.) C#: stackalloc / [InlineArray] + ручной учёт длины.
template <typename T, std::size_t Capacity>
class StaticVector {
public:
    StaticVector() = default;
    StaticVector(const StaticVector&) = delete; // для краткости запретим копирование
    StaticVector& operator=(const StaticVector&) = delete;

    // Деструкторы «живых» элементов приходится вызывать вручную.
    ~StaticVector() { std::destroy_n(data(), size_); }

    template <typename... Args>
    T& emplace_back(Args&&... args) {
        if (size_ == Capacity) throw std::length_error{"StaticVector is full"};
        // construct_at — «размещающий new»: создать объект в УЖЕ выделенной памяти.
        T* created = std::construct_at(data() + size_, std::forward<Args>(args)...);
        ++size_;
        return *created;
    }

    void pop_back() {
        --size_;
        std::destroy_at(data() + size_); // вызвать деструктор, память не освобождая
    }

    T& operator[](std::size_t index) { return data()[index]; }
    [[nodiscard]] std::size_t size() const { return size_; }
    T* begin() { return data(); } // begin()/end() делают класс пригодным для range-for
    T* end() { return data() + size_; }

private:
    // reinterpret_cast: «считать этот адрес адресом T». Самое опасное из приведений.
    T* data() { return reinterpret_cast<T*>(storage_); }

    alignas(T) std::byte storage_[Capacity * sizeof(T)]; // память под элементы, без объектов
    std::size_t size_ = 0;
};

void section13_low_level() {
    header(13, "Low level: memory, bits, allocators");

    // --- Размеры и выравнивание -------------------------------------------------------
    std::println("sizeof: Padded {}, Reordered {}, CacheAligned {} | alignof: double {}, {}",
                 sizeof(Padded), sizeof(Reordered), sizeof(CacheAligned), alignof(double),
                 alignof(CacheAligned));
    Flags flags{.ready = 1, .mode = 5, .level = 9};
    std::println("Flags: {} byte(s), ready {}, mode {}, level {}", sizeof(Flags),
                 static_cast<unsigned>(flags.ready), static_cast<unsigned>(flags.mode),
                 static_cast<unsigned>(flags.level));

    // --- Указатели и арифметика -------------------------------------------------------
    int data[5] = {10, 20, 30, 40, 50};
    int* pointer = data; // массив «распадается» в указатель на первый элемент
    int third = *(pointer + 2); // то же, что pointer[2] и data[2]
    std::ptrdiff_t distance = &data[4] - pointer; // разность указателей — в элементах
    std::println("third {}, distance {}, bytes between: {}", third, distance,
                 distance * static_cast<std::ptrdiff_t>(sizeof(int)));
    // pointer + 10 — указатель за пределы массива: само его вычисление уже UB.

    // --- Байты и биты -----------------------------------------------------------------
    float one = 1.0f;
    auto bits = std::bit_cast<std::uint32_t>(one); // C++20: «те же байты, другой тип»
    std::uint32_t copied = 0;
    std::memcpy(&copied, &one, sizeof one); // способ, которым это делали до C++20
    // *reinterpret_cast<std::uint32_t*>(&one) — нарушение правила strict aliasing: UB.
    IntOrFloat number{.as_int = 7};
    number.as_float = 2.5f; // теперь «активно» поле as_float; читать as_int нельзя
    std::println("1.0f = {:#x} (memcpy {:#x}), union holds {}", bits, copied, number.as_float);

    auto raw_bytes = std::as_bytes(std::span{data}); // «байтовый вид» массива
    std::println("{} bytes, first: {:#04x}, little-endian: {}", raw_bytes.size(),
                 std::to_integer<int>(raw_bytes[0]), std::endian::native == std::endian::little);

    std::uint32_t mask = 0b1011'0000u;
    std::println("popcount {}, countr_zero {}, rotl {:#x}, bit_ceil(100) {}, byteswap {:#010x}",
                 std::popcount(mask), std::countr_zero(mask), std::rotl(mask, 28),
                 std::bit_ceil(100u), std::byteswap(0x1122'3344u));
    std::bitset<8> bitset{0b0101'0011};
    bitset.flip(0).set(7);
    std::println("bitset {} has {} bits set", bitset.to_string(), bitset.count());

    // --- Ручное управление временем жизни ---------------------------------------------
    {
        StaticVector<Tracer, 3> tracers; // Tracer из раздела 4 покажет создание и уничтожение
        tracers.emplace_back("first");
        tracers.emplace_back("second");
        tracers.pop_back();
        std::println("    {} element(s) left, {} bytes, all on the stack", tracers.size(),
                     sizeof(tracers));
    } // деструктор StaticVector уничтожит "first"

    // --- Полиморфные аллокаторы (C++17) -----------------------------------------------
    // Контейнер берёт память из заданного «ресурса». Здесь это буфер на стеке: ни одного
    // обращения к куче, а вся память освобождается разом. Так делают арены в играх
    // и системах реального времени.
    std::array<std::byte, 1024> arena{};
    std::pmr::monotonic_buffer_resource resource{arena.data(), arena.size(),
                                                 std::pmr::null_memory_resource()};
    std::pmr::vector<int> fast{&resource};
    fast.reserve(100);
    for (int i = 0; i < 100; ++i) fast.push_back(i * i);
    // std::less для указателей задаёт полный порядок (сравнение `<` для указателей на
    // разные объекты не определено).
    const auto* storage = reinterpret_cast<const std::byte*>(fast.data());
    bool inside = !std::less<>{}(storage, arena.data()) &&
                  std::less<>{}(storage, arena.data() + arena.size());
    std::println("pmr vector: {} elements, last {}, storage is inside the arena: {}", fast.size(),
                 fast.back(), inside);

    // --- Взаимодействие с C -----------------------------------------------------------
    // Заголовки C подключаются напрямую (<cstdlib>, <cstring>, ...), обёртки вроде
    // P/Invoke не нужны. Лямбда без захвата превращается в обычный указатель на функцию.
    int unsorted[] = {42, -7, 19, 0, 3};
    std::qsort(unsorted, std::size(unsorted), sizeof(int), [](const void* a, const void* b) {
        int x = *static_cast<const int*>(a);
        int y = *static_cast<const int*>(b);
        return (x > y) - (x < y);
    });
    std::println("qsort: [{}], strlen: {}", join(unsorted), std::strlen("hello from C"));
}

// =====================================================================================
//  14. МНОГОПОТОЧНОСТЬ
// =====================================================================================
//
//  Потоки, мьютексы и атомики входят в стандартную библиотеку. Главное отличие от C#:
//  гонка данных (одновременная запись и чтение обычной переменной из разных потоков
//  без синхронизации) — это UB, а не «просто неверный результат». И мьютекс никак
//  не привязан к данным, которые он защищает: дисциплина целиком на программисте.

// Потокобезопасная очередь на мьютексе и условной переменной.
// C#: BlockingCollection<T> или System.Threading.Channels.
template <typename T>
class Channel {
public:
    void send(T value) {
        {
            std::scoped_lock lock{mutex_}; // RAII-блокировка. C#: lock (sync) { ... }
            queue_.push(std::move(value));
        } // мьютекс отпущен здесь, до уведомления
        ready_.notify_one();
    }

    void close() {
        {
            std::scoped_lock lock{mutex_};
            closed_ = true;
        }
        ready_.notify_all();
    }

    // Ждёт значение; std::nullopt означает «канал закрыт и пуст».
    std::optional<T> receive() {
        std::unique_lock lock{mutex_}; // unique_lock умеет временно отпускать мьютекс
        // wait отпускает мьютекс, спит до уведомления и перепроверяет условие.
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

// thread_local: у каждого потока своя копия переменной. C#: [ThreadStatic] / ThreadLocal<T>.
thread_local int calls_in_this_thread = 0;

// Статическая локальная переменная инициализируется один раз при первом вызове,
// и эта инициализация потокобезопасна. C#: Lazy<T>.
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
    // Поток ОС. В отличие от старого std::thread, сам присоединяется (join) в деструкторе
    // и несёт токен кооперативной отмены. C#: Thread + CancellationToken.
    std::atomic<int> ticks{0};
    {
        std::jthread ticker{[&ticks](std::stop_token stop) {
            while (!stop.stop_requested()) {
                ++ticks;
                std::this_thread::sleep_for(1ms); // литерал из std::chrono
            }
        }};
        std::this_thread::sleep_for(20ms);
    } // деструктор jthread: request_stop() и join()
    std::println("ticker made some ticks: {}", ticks > 0);

    // --- Мьютекс и атомик -------------------------------------------------------------
    long long counter = 0; // обычная переменная: доступ только под мьютексом
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
                    ++calls_in_this_thread; // у каждого потока свой счётчик
                }
            });
        }
    } // все потоки завершены и присоединены
    std::println("mutex counter {}, atomic counter {}, thread_local in main: {}", counter,
                 atomic_counter.load(), calls_in_this_thread);

    // --- std::async и std::future. C#: Task.Run и task.Result ---------------------------
    std::future<long long> sum = std::async(std::launch::async, [] {
        long long total = 0;
        for (int i = 1; i <= 1000; ++i) total += i;
        return total;
    });
    // get() ждёт результат (и перебрасывает исключение, если задача упала).
    std::println("async sum = {}", sum.get());

    // std::promise — «ручной» источник результата. C#: TaskCompletionSource<T>.
    std::promise<std::string> promise;
    std::future<std::string> answer = promise.get_future();
    std::jthread producer{[&promise] { promise.set_value("a value from another thread"); }};
    std::println("promise delivered: {}", answer.get());

    // --- Производители и потребитель через Channel --------------------------------------
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
        producers.clear(); // деструкторы jthread дождутся производителей
        channel.close();   // потребитель дочитает очередь и выйдет из цикла
    }
    std::ranges::sort(received); // порядок прихода сообщений не определён
    std::println("received: {}", join(received));

    // --- Примитивы C++20 --------------------------------------------------------------
    std::latch all_done{3}; // одноразовый счётчик. C#: CountdownEvent
    std::atomic<int> finished{0};
    std::vector<std::jthread> tasks;
    for (int i = 0; i < 3; ++i) {
        tasks.emplace_back([&] {
            ++finished;
            all_done.count_down();
        });
    }
    all_done.wait(); // ждать, пока счётчик не дойдёт до нуля
    std::println("latch released after {} tasks | {} primes below 50, lazily initialised",
                 finished.load(), small_primes().size());
    // Ещё есть std::shared_mutex (C#: ReaderWriterLockSlim), std::counting_semaphore,
    // std::barrier, std::call_once, а также параллельные версии алгоритмов:
    // std::sort(std::execution::par, first, last).
}

// =====================================================================================
//  15. КОРУТИНЫ (C++20)
// =====================================================================================
//
//  Корутина — функция, в теле которой есть co_yield, co_await или co_return. Компилятор
//  превращает её в объект-состояние («кадр»), способный приостанавливаться.
//  C#: `yield return` — это co_yield, `await` — это co_await.
//
//  Принципиальное отличие: язык даёт только МЕХАНИЗМ. Что такое «генератор» или
//  «задача», решает библиотека: тип результата корутины должен содержать вложенный
//  promise_type, чьи методы компилятор вызывает в ключевых точках. Ниже оба типа
//  написаны вручную, чтобы показать, из чего они состоят.

// --- Генератор: ленивая последовательность. C#: IEnumerable<T> + yield return ------------
template <typename T>
class Generator {
public:
    struct promise_type {
        const T* current = nullptr; // адрес значения, отданного через co_yield

        Generator get_return_object() { return Generator{Handle::from_promise(*this)}; }
        std::suspend_always initial_suspend() noexcept { return {}; } // не стартовать сразу
        std::suspend_always final_suspend() noexcept { return {}; }   // не уничтожать кадр самому
        std::suspend_always yield_value(const T& value) noexcept {    // вызывается на co_yield
            current = std::addressof(value);
            return {}; // приостановиться и вернуть управление вызывающему
        }
        void return_void() noexcept {}
        void unhandled_exception() { throw; } // пробросить исключение из тела корутины
    };

    using Handle = std::coroutine_handle<promise_type>; // «пульт управления» корутиной

    explicit Generator(Handle handle) : handle_{handle} {}
    Generator(Generator&& other) noexcept : handle_{std::exchange(other.handle_, {})} {}
    Generator(const Generator&) = delete;
    Generator& operator=(const Generator&) = delete;
    ~Generator() {
        if (handle_) handle_.destroy(); // кадр корутины живёт в куче; уничтожаем его вручную
    }

    // Минимальный итератор, чтобы генератор работал в диапазонном for.
    struct Sentinel {};
    struct Iterator {
        Handle handle;
        const T& operator*() const { return *handle.promise().current; }
        Iterator& operator++() {
            handle.resume(); // продолжить корутину до следующего co_yield
            return *this;
        }
        bool operator==(Sentinel) const { return handle.done(); }
    };

    Iterator begin() {
        handle_.resume(); // дойти до первого co_yield
        return Iterator{handle_};
    }
    Sentinel end() { return {}; }

private:
    Handle handle_;
};

// Сама корутина выглядит как обычная функция. Бесконечный цикл — это нормально:
// выполнение идёт только тогда, когда вызывающий просит следующее значение.
Generator<std::uint64_t> fibonacci() {
    std::uint64_t a = 0, b = 1;
    while (true) {
        co_yield a;
        a = std::exchange(b, a + b);
    }
}

Generator<std::string> tokens(std::string text) { // параметр копируется в кадр корутины
    std::size_t start = 0;
    while (start < text.size()) {
        std::size_t end = text.find(' ', start);
        if (end == std::string::npos) end = text.size();
        if (end > start) co_yield text.substr(start, end - start);
        start = end + 1;
    }
}

// --- Планировщик: очередь готовых корутин и таймеры ----------------------------------------
// Роль, которую в C# играют планировщик задач и SynchronizationContext, здесь исполняет
// класс на три десятка строк, работающий в одном потоке.
class Scheduler {
public:
    using Clock = std::chrono::steady_clock;

    // Объект, который можно co_await-ить, обязан иметь три метода (он «awaitable»).
    struct SleepAwaiter {
        Scheduler& scheduler;
        Clock::time_point wake_at;

        bool await_ready() const noexcept { return false; } // «результат ещё не готов»
        void await_suspend(std::coroutine_handle<> handle) { // куда деть приостановленную корутину
            scheduler.timers_.emplace(wake_at, handle);
        }
        void await_resume() const noexcept {} // результат выражения co_await
    };

    SleepAwaiter sleep_for(std::chrono::milliseconds delay) { // C#: Task.Delay
        return SleepAwaiter{*this, Clock::now() + delay};
    }

    // Цикл событий: возобновлять корутины по мере срабатывания таймеров.
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

// --- Job: корутина «запустил и забыл». C#: async void -------------------------------------
struct Job {
    struct promise_type {
        Job get_return_object() noexcept { return {}; }
        std::suspend_never initial_suspend() noexcept { return {}; } // стартует немедленно
        std::suspend_never final_suspend() noexcept { return {}; }   // кадр уничтожается сам
        void return_void() noexcept {}
        void unhandled_exception() { std::terminate(); }
    };
};

// --- Task<T>: ленивая задача с результатом. C#: Task<T> -----------------------------------
template <typename T>
class Task {
public:
    struct promise_type {
        std::optional<T> result;
        std::exception_ptr error;
        std::coroutine_handle<> continuation = std::noop_coroutine(); // кто ждёт эту задачу

        Task get_return_object() { return Task{Handle::from_promise(*this)}; }
        std::suspend_always initial_suspend() noexcept { return {}; } // ленивая: ждёт co_await

        // Когда задача дошла до конца, управление передаётся ожидающей корутине.
        auto final_suspend() noexcept {
            struct Awaiter {
                bool await_ready() const noexcept { return false; }
                std::coroutine_handle<> await_suspend(
                    std::coroutine_handle<promise_type> finished) const noexcept {
                    return finished.promise().continuation; // «симметричная передача»
                }
                void await_resume() const noexcept {}
            };
            return Awaiter{};
        }

        void return_value(T value) { result = std::move(value); } // вызывается на co_return
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

    // Task сам является awaitable: `co_await task` запускает задачу и ждёт её.
    bool await_ready() const noexcept { return false; }
    std::coroutine_handle<> await_suspend(std::coroutine_handle<> awaiting) noexcept {
        handle_.promise().continuation = awaiting;
        return handle_; // возобновить задачу; ожидающий остаётся приостановленным
    }
    T await_resume() {
        if (handle_.promise().error) std::rethrow_exception(handle_.promise().error);
        return std::move(*handle_.promise().result);
    }

private:
    Handle handle_;
};

// Асинхронные функции: выглядят как в C#, только async в сигнатуре нет — корутину
// выдают слова co_await / co_return в теле.
Task<int> fetch_length(Scheduler& scheduler, std::string name, int delay_ms) {
    co_await scheduler.sleep_for(std::chrono::milliseconds{delay_ms});
    co_return static_cast<int>(name.size()) * delay_ms;
}

Task<int> fetch_both(Scheduler& scheduler) {
    int first = co_await fetch_length(scheduler, "alpha", 20); // последовательно, как await в C#
    int second = co_await fetch_length(scheduler, "beta", 10);
    co_return first + second;
}

Job run_and_store(Task<int> task, int& output) { // мост между Task и синхронным кодом
    output = co_await std::move(task);
}

Job worker(Scheduler& scheduler, std::string name, int delay_ms, std::vector<std::string>& log) {
    co_await scheduler.sleep_for(std::chrono::milliseconds{delay_ms});
    log.push_back(std::move(name));
}

void section15_coroutines() {
    header(15, "Coroutines");

    // Генераторы.
    std::vector<std::uint64_t> first_fibonacci;
    for (std::uint64_t value : fibonacci()) {
        if (value > 100) break; // бесконечную последовательность обрывает потребитель
        first_fibonacci.push_back(value);
    }
    std::vector<std::string> words;
    for (const std::string& word : tokens("coroutines are  lazy state machines")) {
        words.push_back(word);
    }
    std::println("fibonacci: {} | tokens: {}", join(first_fibonacci), join(words, "|"));

#ifdef __cpp_lib_generator
    // C++23: готовый std::generator — свой Generator писать больше не нужно.
    auto squares = []() -> std::generator<int> {
        for (int i = 1;; ++i) co_yield i * i;
    };
    std::println("std::generator: {}", join(squares() | std::views::take(5)));
#else
    std::println("std::generator is not available in this standard library");
#endif

    // Три независимые корутины на одном потоке: каждая «спит», не блокируя остальных.
    Scheduler scheduler;
    std::vector<std::string> log;
    worker(scheduler, "slow", 30, log);
    worker(scheduler, "fast", 10, log);
    worker(scheduler, "medium", 20, log);
    int total = 0;
    run_and_store(fetch_both(scheduler), total);
    std::println("coroutines started, nothing finished yet: log is empty: {}", log.empty());
    scheduler.run(); // цикл событий: будит корутины, пока есть таймеры
    std::println("finished in order: {} | fetch_both -> {}", join(log), total);
}

// =====================================================================================
//  16. C++23, C++26, МОДУЛИ
// =====================================================================================
//
//  Язык обновляется каждые три года; компиляторы догоняют стандарт постепенно. Узнать,
//  что доступно, позволяют feature-test-макросы: __cpp_* для языка, __cpp_lib_* для
//  библиотеки (заголовок <version>) и __has_cpp_attribute для атрибутов.
//  C#: #if NET9_0_OR_GREATER.

// --- Deducing this (C++23): явный параметр «этот объект» ---------------------------------
// Одна шаблонная функция вместо пары перегрузок const / не-const и замена CRTP:
// тип Self выводится из того, на чём метод вызван.
struct TextBuilder {
    std::string text;

    template <typename Self>
    Self&& append(this Self&& self, std::string_view part) {
        self.text += part;
        return std::forward<Self>(self); // lvalue вернётся ссылкой, временный объект — перемещением
    }
};

// --- if consteval (C++23): разный код для компиляции и выполнения ------------------------
constexpr double fast_or_exact_sqrt(double x) {
    if consteval {
        double guess = x > 1 ? x / 2 : 1.0; // при компиляции: метод Ньютона
        for (int i = 0; i < 60; ++i) guess = (guess + x / guess) / 2;
        return guess;
    } else {
        return std::sqrt(x); // при выполнении: библиотечная функция
    }
}

// --- static operator() (C++23): функтор без состояния не передаёт скрытый this -----------
struct IsPositive {
    static constexpr bool operator()(int value) { return value > 0; }
};

// Примеры C++26 включаются, только если файл собирают с -std=c++26 (или новее)
// И компилятор уже умеет конкретную возможность.

// --- Индексация пакета параметров (C++26) -----------------------------------------------
#if __cplusplus > 202302L && defined(__cpp_pack_indexing)
template <typename... Types>
constexpr auto last_of(Types... values) {
    return values...[sizeof...(Types) - 1]; // раньше для этого требовалась рекурсия или tuple
}
#endif

// --- `= delete` с объяснением (C++26). C#: [Obsolete("...", error: true)] ----------------
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
    // Рекурсивная лямбда: раньше лямбда не могла сослаться на саму себя.
    auto fibonacci_number = [](this auto self, int n) -> int {
        return n < 2 ? n : self(n - 1) + self(n - 2);
    };
    std::println("{} | {} | fib(20) = {}", builder.text, built, fibonacci_number(20));

    constexpr double at_compile_time = fast_or_exact_sqrt(2.0);
    double at_run_time = fast_or_exact_sqrt(2.0);
    std::println("if consteval: {:.6f} vs {:.6f} | static operator(): {}", at_compile_time,
                 at_run_time, std::ranges::count_if(std::array{-1, 2, 3}, IsPositive{}));

#if __has_cpp_attribute(assume)
    // [[assume(expr)]] (C++23): обещание оптимизатору. Нарушили обещание — UB.
    int divisor = 8;
    [[assume(divisor > 0)]];
    std::println("[[assume]]: 100 / divisor = {}", 100 / divisor);
#endif

    // --- Новые адаптеры диапазонов (C++23) ----------------------------------------------
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
    for (auto window : scores | std::views::slide(2)) { // скользящее окно
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
    // fold_left — свёртка диапазона слева направо с начальным значением. C#: Aggregate.
    std::println("fold_left: {}", std::ranges::fold_left(scores, 0, std::plus<>{}));
#endif

#ifdef __cpp_lib_format_ranges
    // Диапазоны, кортежи и словари печатаются «из коробки».
    std::println("format ranges: {} {} {}", scores, std::pair{1, "one"},
                 std::map<std::string, int>{{"a", 1}});
#endif

#ifdef __cpp_lib_move_only_function
    // std::move_only_function: «делегат», способный хранить некопируемые объекты.
    auto state = std::make_unique<int>(41);
    std::move_only_function<int()> task = [state = std::move(state)] { return *state + 1; };
    std::println("move_only_function: {}", task());
#endif

#ifdef __cpp_lib_mdspan
    // std::mdspan: многомерный «вид» на плоский массив.
    // C#: Span2D<T> из CommunityToolkit.HighPerformance.
    std::array<double, 6> flat{1, 2, 3, 4, 5, 6};
    std::mdspan grid{flat.data(), 2, 3}; // 2 строки, 3 столбца, данные не копируются
    grid[1, 2] = 60.0;
    std::println("mdspan {}x{}: grid[1, 2] = {}, flat[5] = {}", grid.extent(0), grid.extent(1),
                 grid[1, 2], flat[5]);
#endif

#ifdef __cpp_lib_flat_map
    // std::flat_map: словарь на двух отсортированных векторах — плотная память, быстрый
    // поиск, медленная вставка.
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
        // `_` — имя-заглушка «значение не интересует»; в одной области его можно повторять.
        std::mutex mutex;
        auto [_, minor_version] = std::pair{26, 1};
        std::scoped_lock _{mutex};
        std::println("placeholder variables: minor = {}", minor_version);
    }
#endif
#if __cplusplus > 202302L && defined(__cpp_deleted_function)
    // legacy_draw(1); // ошибка компиляции с вашим текстом: "use Canvas::draw instead"
    std::println("= delete(\"reason\") is supported");
#endif

    // Остальное из C++26 в компиляторах только появляется, поэтому ниже — комментарии:
    // эти фрагменты здесь НЕ компилировались и приведены по тексту предложений в стандарт.
    //
    // Статическая рефлексия (P2996): `^^T` даёт значение-описание сущности, `[: r :]`
    // превращает его обратно в код. Перечисление в строку без макросов и кодогенерации:
    //
    //     template <typename E>
    //     constexpr std::string_view enum_name(E value) {
    //         template for (constexpr auto e :
    //                       std::define_static_array(std::meta::enumerators_of(^^E)))
    //             if (value == [:e:]) return std::meta::identifier_of(e);
    //         return "<unknown>";
    //     }
    //
    // Контракты (P2900): пред- и постусловия прямо в объявлении функции.
    //
    //     double checked_sqrt(double x)
    //         pre(x >= 0)
    //         post(result: result >= 0);
    //
    // В библиотеке: std::execution (отправители и получатели — модель асинхронности),
    // std::inplace_vector, std::simd, <linalg> (BLAS поверх mdspan), <hazard_pointer>, <rcu>.
    //
    // Модули (C++20) заменяют текстовый #include: интерфейс компилируется один раз,
    // макросы наружу не утекают. Сборка требует поддержки в системе сборки (CMake 3.28+),
    // поэтому в один файл пример не помещается:
    //
    //     // math.cppm                              // main.cpp
    //     export module math;                      import math;
    //     export int add(int a, int b) {           import std;   // C++23: вся библиотека
    //         return a + b;                        int main() { std::println("{}", add(2, 3)); }
    //     }
}

// =====================================================================================
//  ТОЧКА ВХОДА
// =====================================================================================

// main возвращает код завершения процесса; `return 0;` в конце main можно не писать.
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
        // Исключение, которое никто не поймал, завершает программу через std::terminate.
        std::println(stderr, "unhandled exception: {}", error.what());
        return 1;
    }
}
