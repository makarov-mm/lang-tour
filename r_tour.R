# ==================================================================================================
#  R FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
#
#  Run:   Rscript r_tour.R          (R 4.3 or newer; base R only, no packages to install)
#
#  Verified with R 4.3.3, with no warnings. Newer interpreters were not available where this
#  file was checked; what R 4.4 and 4.5 added is listed in section 12 as comments that were
#  NOT run.
#
#  How to read. Each section is a function `sectionNN_*`; the helpers a section needs are
#  defined right before it; `main()` at the end calls the sections in order. A "C#:" note
#  shows the closest C# counterpart.
#
#  R is a language for statistics and data analysis, and it shows. The main differences from
#  C# to keep in mind from the first line:
#
#   1. Everything is a vector. There are no scalars: 42 is a vector of length one, and
#      operators and most functions work on whole vectors at once, without loops.
#   2. Indexing starts at 1.
#   3. Every object is a value. Assignment and argument passing never alias ("copy on
#      modify"); a function cannot change its caller's data. Only environments are mutable.
#   4. It is a functional language: functions are values, arguments are evaluated lazily,
#      and even `+`, `[` and `if` are functions. Code itself is data (section 10).
#   5. Missing data is part of the type system: NA is a legal value of every vector type.
#   6. Object systems are libraries: S3 (ubiquitous, informal), S4 (formal), reference
#      classes. Methods belong to generic functions, not to classes.
#   7. Dynamic typing, an interpreter, one thread. Speed comes from vectorized operations
#      implemented in C and Fortran.
#
#  Contents:
#    1. Basics: vectors, types, NA, control flow        7. Strings, regular expressions, dates
#    2. Vectors and indexing                            8. Objects: S3, S4, reference classes
#    3. Lists, factors, matrices                        9. Errors and conditions
#    4. Data frames                                    10. Metaprogramming: code is data
#    5. Functions                                      11. Statistics and numerics
#    6. Functional programming and pipes               12. The newest
# ==================================================================================================

header <- function(title) cat("\n=== ", title, " ===\n", sep = "")

# Prints its arguments on one line, separated by spaces. cat() is the plain printer;
# print() shows a value the way the interactive console does.
out <- function(...) cat(..., "\n")

# ==================================================================================================
#  1. BASICS: vectors, types, NA, control flow
# ==================================================================================================

section01_basics <- function() {
  header("1. Basics")

  # --- Assignment is `<-`. A "scalar" is a vector of length one ---
  x <- 42          # numbers are doubles unless told otherwise
  n <- 42L         # the L suffix makes an integer
  name <- "World"
  flag <- TRUE
  out(x, n, name, flag, "|", typeof(x), typeof(n), typeof(name), typeof(flag), "|", length(x))

  # c() combines values into a vector; operators and functions apply to all elements.
  v <- c(5, 3, 8, 1)
  out(v * 2, "|", v + c(10, 20, 30, 40), "|", v > 4, "|", sum(v), mean(v), max(v))
  # A shorter vector is recycled to the length of the longer one.
  out(v + c(100, 200), "|", 1:6 * c(1, -1))
  out(1:5, "|", seq(0, 1, by = 0.25), "|", seq_len(3), "|", rep(c("a", "b"), times = 2), "|", 10:7)

  # --- Numbers ---
  out(7 / 2, 7 %/% 2, 7 %% 3, -7 %% 3, 2^10, 5L / 2L, class(5L / 2L), .Machine$integer.max)
  out(0.1 + 0.2 == 0.3, isTRUE(all.equal(0.1 + 0.2, 0.3)), 1 / 0, 0 / 0, round(2.5), round(3.5),
      signif(123456, 2), format(1234567.891, big.mark = ","))

  # --- Missing values: NA is "unknown" and propagates; NULL is "nothing at all" ---
  ages <- c(31, NA, 25)
  out(ages + 1, "|", mean(ages), mean(ages, na.rm = TRUE), "|", is.na(ages), "|", NA > 1,
      NA & FALSE, NA || TRUE, "|", length(NULL), is.null(NULL), length(c(1, NULL, 2)))

  # --- A vector has ONE type; mixing types converts everything to the most general one ---
  out(c(1, "a", TRUE), class(c(1, "a", TRUE)), "|", c(1, TRUE, FALSE), "|",
      sum(c(TRUE, TRUE, FALSE)), "|", as.integer("42") + 1L, as.numeric("3.5"), as.character(99))

  # --- Strings: elements of a character vector; there is no separate char type ---
  greeting <- paste0("Hello, ", name, "!")     # no interpolation: paste and sprintf build text
  out(greeting, "|", nchar(greeting), toupper(greeting), substr(greeting, 8, 12), "|",
      paste("a", "b", sep = "-"), paste(c("x", "y"), 1:2, collapse = "+"), "|",
      sprintf("%05.1f|%-6s|%+d|%x", 3.14159, "ab", 5L, 255L))
  accented <- "Gr\u00fc\u00dfe"       # escapes keep the source ASCII
  out(r"(C:\dir\file "quoted")", "|", nchar(accented), nchar(accented, type = "bytes"))

  # --- Control flow ---
  total <- 0
  for (i in 1:5) total <- total + i            # `for` walks over a vector. C#: foreach
  k <- 3
  while (k > 0) {
    total <- total + 10
    k <- k - 1
  }
  repeat {                                     # an endless loop, left with break
    total <- total + 100
    if (total > 300) break
  }
  kind <- if (total %% 2 == 0) "even" else "odd"      # `if` is an expression
  size <- switch(as.character(total %/% 100), "3" = "three hundred", "4" = "four hundred", "other")
  # if() takes ONE logical value; ifelse() is its vectorized counterpart.
  out(total, kind, size, "|", ifelse(v > 4, "big", "small"), "|", any(v > 7), all(v > 0))
}

# ==================================================================================================
#  2. VECTORS AND INDEXING
# ==================================================================================================

section02_vectors <- function() {
  header("2. Vectors and indexing")
  v <- c(10, 20, 30, 40, 50)

  # The index is itself a vector: positions, exclusions (negative), logicals or names.
  out(v[1], v[length(v)], "|", v[2:4], "|", v[c(1, 5)], "|", v[-1], "|", v[-(1:2)], "|", v[v > 25],
      "|", v[c(TRUE, FALSE)], "|", v[10], length(v[0]))    # out of range gives NA, not an error

  v[2] <- 99                 # assignment through an index ...
  v[v > 45] <- 0             # ... or through a condition
  v[7] <- 7                  # assigning past the end grows the vector; the gap becomes NA
  out(v, "|", which(is.na(v)), which.max(v), "|", head(v, 2), "|", tail(v, 2))

  # Names turn a vector into a small dictionary.
  stock <- c(bolt = 10, nut = 5, screw = 25)
  stock["nut"] <- 6
  out(stock["bolt"], "|", names(stock), "|", stock[c("screw", "nut")], "|", names(which.max(stock)),
      "|", "nut" %in% names(stock), stock["missing"])

  # The standard vocabulary. C#: LINQ over an array.
  x <- c(5, 3, 8, 1, 9, 3)
  out(sort(x), "|", order(x), "|", rev(x), "|", unique(x), "|", cumsum(x), "|", diff(x), "|",
      range(x))
  out(table(c("a", "b", "a", "c", "a")), "|", 3 %in% x, match(8, x), "|", prod(1:5), var(x), "|",
      x[order(-x)][1:3], "|", paste(x, collapse = ""))

  # Copy on modify: assignment never creates an alias.
  y <- x
  y[1] <- 100
  out(x[1], y[1])
}

# ==================================================================================================
#  3. LISTS, FACTORS, MATRICES
# ==================================================================================================

section03_structures <- function() {
  header("3. Lists, factors, matrices")

  # --- A list holds elements of ANY type. C#: an anonymous object, a Dictionary<string, object> ---
  person <- list(name = "Ann", age = 31, langs = c("C#", "R"), address = list(city = "Munich"))
  person$age <- person$age + 1                 # $ accesses an element by name
  person[["email"]] <- "ann@example.com"       # [[ ]] extracts ONE element ...
  out(person$name, person[["age"]], person$langs[2], person$address$city, "|", names(person), "|",
      length(person), class(person["name"]), class(person[["name"]]))   # ... [ ] gives a sub-LIST
  person$email <- NULL                         # assigning NULL removes an element
  str(person)                                  # str() shows the structure of any object

  # --- A factor is a categorical variable: integer codes plus labels. C#: an enum made of data ---
  sizes <- factor(c("small", "large", "small", "medium"),
                  levels = c("small", "medium", "large"), ordered = TRUE)
  out(levels(sizes), "|", as.integer(sizes), "|", table(sizes), "|", nlevels(sizes),
      as.character(sizes[2]), sizes[2] > "small")

  # --- A matrix is a vector with dimensions, filled column by column ---
  m <- matrix(1:6, nrow = 2)                   # 2 rows, 3 columns
  print(m)
  out(dim(m), "|", m[2, 3], "|", m[1, ], "|", m[, 2], "|", t(m)[, 1], "|", m %*% t(m), "|", m * 10)
  rownames(m) <- c("r1", "r2")
  colnames(m) <- c("a", "b", "c")
  out(m["r2", "b"], "|", apply(m, 1, sum), "|", apply(m, 2, max), "|", rowSums(m), "|", colMeans(m),
      "|", dim(cbind(m, d = 0)), dim(rbind(m, m)))
  a <- matrix(c(2, 1, 1, 3), nrow = 2)
  out(solve(a, c(3, 5)), "|", det(a), "|", round(solve(a) %*% a, 10), "|", diag(2), "|",
      dim(array(1:24, dim = c(2, 3, 4))), "|", outer(1:3, 1:3)[3, ])
}

# ==================================================================================================
#  4. DATA FRAMES
# ==================================================================================================

section04_data_frames <- function() {
  header("4. Data frames")

  # A data frame is a table: a list of columns of equal length, each of them a vector.
  # C#: a DataTable, or a List<record> queried with LINQ.
  staff <- data.frame(
    name = c("Ann", "Bob", "Cid", "Dee", "Eve"),
    dept = c("R&D", "Sales", "R&D", "Sales", "Ops"),
    salary = c(5200, 4100, 6100, 3900, 4700),
    age = c(34L, 45L, 29L, 38L, 51L)
  )
  out(nrow(staff), ncol(staff), "|", names(staff), "|", staff$name[2], staff[2, "salary"],
      staff[["age"]][5])
  str(staff)

  staff$bonus <- staff$salary * 0.1                       # a new column, for all rows at once
  seniors <- staff[staff$age > 35, c("name", "age")]      # C#: Where + Select
  sorted <- staff[order(staff$dept, -staff$salary), ]     # C#: OrderBy(...).ThenByDescending(...)
  out(seniors$name, "|", sorted$name, "|", sum(staff$bonus), mean(staff$salary), "|",
      with(staff, name[which.max(salary)]))
  # subset() evaluates its conditions inside the data frame (see section 10 for how).
  print(subset(staff, salary > 4500, select = c(name, dept, salary)))

  # Grouping. C#: GroupBy. The formula reads "salary by dept".
  print(aggregate(salary ~ dept, data = staff, FUN = mean))
  out(tapply(staff$salary, staff$dept, max), "|", names(split(staff$name, staff$dept)), "|",
      split(staff$name, staff$dept)$Sales, "|", table(staff$dept))

  # Joining. C#: Join / GroupJoin. all.x = TRUE makes it a left join.
  floors <- data.frame(dept = c("R&D", "Sales", "HR"), floor = c(3, 1, 2))
  print(merge(staff[, c("name", "dept")], floors, by = "dept", all.x = TRUE))
  out(summary(staff$salary), "|", quantile(staff$age, 0.5), "|", sapply(staff, class))
}

# ==================================================================================================
#  5. FUNCTIONS
# ==================================================================================================

describe <- function(name, greeting = "Hello", ...) {   # a default, and `...` for "the rest"
  extras <- list(...)
  suffix <- if (length(extras) > 0) paste0(" (+", length(extras), ")") else ""
  paste0(greeting, ", ", name, suffix)     # the last value is the result; return() is optional
}

divide <- function(dividend, divisor) {
  if (divisor == 0) stop("division by zero")           # raises an error (section 9)
  list(quotient = dividend %/% divisor, remainder = dividend %% divisor)   # several results
}

make_counter <- function() {
  count <- 0
  function() {
    count <<- count + 1      # <<- assigns in the enclosing environment: a closure with state
    count
  }
}

# Arguments are evaluated lazily, only when (and if) they are used.
lazy_demo <- function(value, unused = stop("never evaluated")) {
  if (missing(value)) "no value given" else value * 2
}

`%+%` <- function(a, b) paste(a, b)        # a user-defined infix operator

`second<-` <- function(x, value) {         # a replacement function: second(v) <- 99
  x[2] <- value
  x
}

section05_functions <- function() {
  header("5. Functions")

  out(describe("Ann"), "|", describe("Bob", "Hi"), "|", describe("Cid", "Hey", 1, 2), "|",
      describe(greeting = "Yo", name = "Dee"))          # arguments can be given by name
  result <- divide(17, 5)
  v <- c(1, 2, 3)
  second(v) <- 99
  counter <- make_counter()
  counter()
  out(result$quotient, result$remainder, "|", lazy_demo(21), lazy_demo(), "|", "a" %+% "b", "|", v,
      "|", counter(), counter())

  # Functions are values. `\(x)` is shorthand for `function(x)`. C#: x => ...
  square <- function(x) x^2
  compose <- function(...) {
    fs <- list(...)
    function(x) Reduce(function(acc, f) f(acc), fs, x)
  }
  shout <- compose(trimws, toupper, \(s) paste0(s, "!"))
  out((\(x) x^2)(7), "|", shout("  hello "), "|", names(formals(describe)), "|",
      deparse(body(square)), "|", do.call(paste, list("x", "y", sep = "-")), "|",
      match.arg("med", c("mean", "median")))

  # Operators and even control flow are functions and can be called and passed as such.
  out(`+`(2, 3), `if`(TRUE, "yes", "no"), `[`(v, 2), "|", sapply(1:3, `-`), "|", Reduce(`*`, 1:5),
      "|", sapply(list(1:3, 4:6), `[`, 2))

  # on.exit registers cleanup that runs however the function is left. C#: finally.
  events <- character()
  work <- function() {
    on.exit(events <<- c(events, "cleanup"))
    events <<- c(events, "work")
    invisible(NULL)
  }
  work()
  fib <- function(n) if (n < 2) n else fib(n - 1) + fib(n - 2)
  stopifnot(is.numeric(v), length(v) == 3)               # assertions
  out(events, "|", sapply(0:10, fib), "|", Vectorize(function(a, b) max(a, b))(1:3, c(2, 2, 2)))
}

# ==================================================================================================
#  6. FUNCTIONAL PROGRAMMING AND PIPES
# ==================================================================================================

section06_functional <- function() {
  header("6. Functional programming and pipes")
  numbers <- c(5, 3, 8, 1, 9)
  words <- c("pear", "fig", "banana", "kiwi")

  # The apply family replaces most loops. C#: Select.
  out(sapply(numbers, \(n) n^2), "|", vapply(words, nchar, integer(1)), "|",
      unlist(lapply(1:3, \(i) i * 10)), "|", mapply(\(w, n) paste0(w, n), words[1:2], 1:2), "|",
      unlist(Map(`+`, 1:3, 4:6)))
  out(Filter(\(n) n %% 2 == 1, numbers), "|", Reduce(`+`, numbers, accumulate = TRUE), "|",
      Find(\(n) n > 5, numbers), Position(\(n) n > 5, numbers), "|",
      words[order(nchar(words), words)])

  # The native pipe passes the left side as the first argument of the call on its right;
  # `_` marks another argument. C#: a fluent chain of extension methods.
  top3 <- numbers |> sort() |> rev() |> head(3) |> paste(collapse = " > ")
  even_squares <- 1:10 |> Filter(f = \(n) n %% 2 == 0) |> sapply(FUN = \(n) n^2) |> sum()
  slope <- mtcars |> lm(mpg ~ wt, data = _) |> coef() |> _[["wt"]] |> round(2)
  out(top3, "|", even_squares, "|", slope)

  # Split, apply, combine by hand.
  by_initial <- split(words, substr(words, 1, 1))
  out(names(by_initial), "|", sapply(by_initial, length), "|",
      sapply(by_initial, paste, collapse = "+"))
  out(do.call(rbind, list(1:2, 3:4))[2, ], "|",
      Reduce(function(a, b) paste0(b, a), strsplit("abc", "")[[1]]), "|", outer(1:3, 1:3)[2, ])
}

# ==================================================================================================
#  7. STRINGS, REGULAR EXPRESSIONS, DATES
# ==================================================================================================

section07_text <- function() {
  header("7. Strings, regular expressions, dates")

  log_text <- "2026-11-17 ERROR disk full; 2026-11-18 WARN retry; 2026-11-19 ERROR timeout"
  entries <- strsplit(log_text, ";\\s*")[[1]]            # the string functions are vectorized
  is_error <- grepl("ERROR", entries)
  dates <- regmatches(log_text, gregexpr("\\d{4}-\\d{2}-\\d{2}", log_text))[[1]]
  out(length(entries), "|", dates[is_error], "|",
      sub("(\\d+)-(\\d+)-(\\d+)", "\\3.\\2.\\1", entries[1]), "|",
      gsub("[aeiou]", "", "regular expression"), "|",
      grepl("^[[:alnum:]._]+@[[:alnum:].]+$", c("ann@example.com", "nope")))
  parts <- regmatches(entries, regexec("(\\S+) (\\w+) (.*)", entries))    # capture groups
  out(sapply(parts, `[`, 3), "|", sapply(parts, `[`, 4), "|", sprintf("%s-%d", c("a", "b"), 1:2),
      "|", sprintf("%5.2f", pi), formatC(42, width = 8, flag = "0"), trimws("  x  "),
      startsWith("tour", "to"), chartr("abc", "xyz", "aabbcc"), rev(utf8ToInt("abc")))

  # Dates are numbers with a class attribute. C#: DateOnly, TimeSpan.
  start <- as.Date("2026-11-17")
  later <- start + 45
  out(format(later), format(later, "%d.%m.%Y"), as.numeric(later - start), "|",
      format(seq(start, by = "month", length.out = 3)), "|",
      as.numeric(difftime(as.Date("2026-12-24"), start, units = "days")), "|",
      format(as.POSIXct("2026-11-17 09:30", tz = "UTC") + 3 * 3600, "%H:%M"))
}

# ==================================================================================================
#  8. OBJECTS: S3, S4, REFERENCE CLASSES
# ==================================================================================================

# --- S3: an object is any value with a "class" attribute, and a generic function picks the
# method by that attribute. C#: closer to extension methods resolved at run time than to
# classes; a method belongs to the generic, not to the object. ---
new_circle <- function(radius) structure(list(radius = radius), class = c("circle", "shape"))
new_square <- function(side) structure(list(side = side), class = c("square", "shape"))

area <- function(shape, ...) UseMethod("area")          # the generic: dispatch on class(shape)
area.circle <- function(shape, ...) pi * shape$radius^2
area.square <- function(shape, ...) shape$side^2
area.default <- function(shape, ...) stop("no area for class ", class(shape)[1])

describe_shape <- function(shape, ...) UseMethod("describe_shape")
describe_shape.shape <- function(shape, ...) {
  sprintf("%s with area %.2f", class(shape)[1], area(shape))
}
describe_shape.square <- function(shape, ...) paste("a perfect", NextMethod())   # C#: base.M()

format.circle <- function(x, ...) sprintf("<circle r=%g>", x$radius)   # for an existing generic
print.circle <- function(x, ...) cat(format(x), "\n")
"+.circle" <- function(e1, e2) new_circle(e1$radius + e2$radius)        # operators are generics

# --- S4: formal classes with typed slots, validity checks and dispatch on several arguments ---
setClass("Money", representation(amount = "numeric", currency = "character"),
         validity = function(object) {
           if (object@amount < 0) "the amount must not be negative" else TRUE
         })
invisible(setGeneric("plus", function(a, b) standardGeneric("plus")))
invisible(setMethod("plus", signature("Money", "Money"), function(a, b) {
  if (a@currency != b@currency) stop("the currencies differ")
  new("Money", amount = a@amount + b@amount, currency = a@currency)
}))
invisible(setMethod("plus", signature("Money", "numeric"), function(a, b) {
  new("Money", amount = a@amount + b, currency = a@currency)
}))
invisible(setMethod("show", "Money", function(object) {     # C#: ToString()
  cat(object@amount, object@currency, "\n")
}))

# --- Reference classes: mutable objects that carry their methods. The built-in system that
# feels most like C# classes. ---
Account <- setRefClass("Account",
  fields = list(owner = "character", balance = "numeric"),
  methods = list(
    deposit = function(amount) {
      if (amount <= 0) stop("the amount must be positive")
      balance <<- balance + amount        # fields are changed with <<-
      invisible(.self)                    # returning the object allows chaining
    },
    show = function() cat("Account <", owner, ":", balance, ">\n")
  )
)
Savings <- setRefClass("Savings",
  contains = "Account",                   # inheritance
  fields = list(rate = "numeric"),
  methods = list(add_interest = function() deposit(balance * rate))
)

section08_objects <- function() {
  header("8. Objects: S3, S4, reference classes")

  shapes <- list(new_circle(1), new_square(2))
  out(sapply(shapes, describe_shape), "|", class(shapes[[2]]), "|", inherits(shapes[[1]], "shape"),
      "|", format(shapes[[1]] + new_circle(2)), "|", tryCatch(area(42), error = conditionMessage))
  print(shapes[[1]])                                    # print() is an S3 generic itself
  # An S3 object is just a list with a label: nothing is enforced.
  out(length(methods("area")), "|", class(unclass(shapes[[1]])), names(unclass(shapes[[1]])))

  four <- new("Money", amount = 4, currency = "EUR")     # new() creates an S4 object
  ten <- plus(four, new("Money", amount = 6, currency = "EUR"))
  print(ten)
  print(plus(ten, 2.5))
  invalid <- tryCatch(new("Money", amount = -1, currency = "EUR"), error = function(e) "rejected")
  out(is(ten, "Money"), ten@amount, isVirtualClass("Money"), "|", invalid)

  account <- Account$new(owner = "Ann", balance = 100)
  alias <- account                                      # a reference object is NOT copied
  alias$deposit(50)$deposit(25)
  savings <- Savings$new(owner = "Bob", balance = 1000, rate = 0.02)
  savings$add_interest()
  print(account)
  out(account$balance, savings$balance, is(savings, "Account"), class(savings)[1])

  # Environments are the mutable building block underneath: hash tables with reference
  # semantics. Reference classes (and the popular R6 package) are built on them.
  registry <- new.env()
  assign("answer", 42, envir = registry)
  registry$name <- "tour"
  modify <- function(env) env$answer <- env$answer + 1  # the caller sees the change
  modify(registry)
  out(sort(ls(registry)), "|", get("answer", envir = registry),
      exists("missing", envir = registry, inherits = FALSE))
}

# ==================================================================================================
#  9. ERRORS AND CONDITIONS
# ==================================================================================================

parse_port <- function(text) {
  port <- suppressWarnings(as.integer(text))
  if (is.na(port)) {
    # A custom condition: a list with a class vector. C#: a custom exception type.
    stop(structure(
      class = c("config_error", "error", "condition"),
      list(message = sprintf("config key 'port': '%s' is not a number", text), call = NULL,
           key = "port")
    ))
  }
  if (port < 1 || port > 65535) stop(sprintf("port %d is out of range", port))
  port
}

section09_errors <- function() {
  header("9. Errors and conditions")

  for (text in c("8080", "http", "99999")) {
    answer <- tryCatch(                       # C#: try / catch / finally
      paste("port", parse_port(text)),
      config_error = function(e) paste0(conditionMessage(e), " [key ", e$key, "]"),
      error = function(e) paste("error:", conditionMessage(e)),   # the general handler last
      finally = NULL
    )
    out(answer)
  }

  # Warnings and messages are conditions as well. tryCatch unwinds the stack ...
  out(tryCatch(as.integer("x"), warning = function(w) paste("caught:", conditionMessage(w))))
  # ... while withCallingHandlers handles a condition and RESUMES where it was signalled.
  seen <- character()
  value <- withCallingHandlers(
    {
      warning("first problem")
      message("a note")
      "finished anyway"
    },
    warning = function(w) {
      seen <<- c(seen, conditionMessage(w))
      invokeRestart("muffleWarning")
    },
    message = function(m) {
      seen <<- c(seen, trimws(conditionMessage(m)))
      invokeRestart("muffleMessage")
    }
  )
  out(value, "|", seen)

  failed <- try(stop("boom"), silent = TRUE)             # try() just carries on
  out(inherits(failed, "try-error"), conditionMessage(attr(failed, "condition")), "|",
      tryCatch(stopifnot("must be positive" = -1 > 0), error = conditionMessage))
  # Many "errors" of other languages are ordinary values here.
  out(1 / 0, 1L %/% 0L, c(1, 2)[5], "|",
      tryCatch(c(1, 2)[[5]], error = function(e) "subscript error"),
      tryCatch(undefined_name, error = function(e) "object not found"))
}

# ==================================================================================================
#  10. METAPROGRAMMING: CODE IS DATA
# ==================================================================================================

section10_metaprogramming <- function() {
  header("10. Metaprogramming: code is data")

  # quote() captures an expression instead of evaluating it; the result is a tree of calls.
  # C#: an expression tree (Expression<Func<...>>).
  expr <- quote(a + b * 2)
  out(class(expr), "|", deparse(expr), "|", sapply(as.list(expr), deparse), "|",
      eval(expr, list(a = 1, b = 10)), "|", all.vars(expr))
  expr[[1]] <- as.name("-")                             # the tree can be edited
  out(deparse(expr), eval(expr, list(a = 1, b = 10)), "|", deparse(bquote(x + .(1 + 2))), "|",
      eval(parse(text = "6 * 7")), "|", deparse(call("sum", 1, 2)), eval(call("sum", 1, 2)))

  # substitute() lets a function see the EXPRESSION its caller wrote ("non-standard
  # evaluation"). That is how subset(staff, salary > 4500) and model formulas work.
  describe_call <- function(x) paste0(deparse(substitute(x)), " = ", x)
  where <- function(data, condition) data[eval(substitute(condition), data, parent.frame()), ]
  people <- data.frame(name = c("Ann", "Bob", "Cid"), age = c(31, 25, 47))
  limit <- 30
  out(describe_call(2 + 3 * 4), "|", where(people, age > limit)$name)

  # A function can be taken apart and rebuilt: arguments, body, environment.
  f <- function(x, y = 2) x^y
  body(f) <- quote(x * y)
  formals(f)$y <- 10
  out(f(3), "|", deparse(args(sum))[1], "|", environmentName(environment(mean)),
      environmentName(globalenv()), environmentName(environment(f)) == "")

  # A formula is an unevaluated expression too; modelling functions interpret it.
  model <- y ~ x + log(z)
  out(class(model), all.vars(model), "|", deparse(model[[3]]))
}

# ==================================================================================================
#  11. STATISTICS AND NUMERICS
# ==================================================================================================

section11_statistics <- function() {
  header("11. Statistics and numerics")

  set.seed(42)                                           # a reproducible random stream
  x <- rnorm(100, mean = 50, sd = 10)
  out(round(c(mean(x), median(x), sd(x), min(x), max(x)), 2), "|",
      round(quantile(x, c(0.25, 0.75)), 2), "|", sample(1:10, 3), "|", round(runif(2), 3))
  # Distributions: d = density, p = cumulative probability, q = quantile, r = random sample.
  out(round(c(dnorm(0), pnorm(1.96), qnorm(0.975), pbinom(3, 10, 0.5), dpois(2, 3)), 4))

  # Linear regression through the formula interface: "mpg explained by weight and power".
  model <- lm(mpg ~ wt + hp, data = mtcars)              # mtcars is a built-in data set
  out(round(coef(model), 4), "|", round(summary(model)$r.squared, 4), "|",
      round(predict(model, data.frame(wt = 3, hp = 120)), 2), "|", nrow(mtcars), class(model))
  test <- t.test(mpg ~ am, data = mtcars)                # automatic against manual gearboxes
  out(round(test$statistic, 3), signif(test$p.value, 3), "|", round(cor(mtcars$mpg, mtcars$wt), 4),
      "|", round(tapply(mtcars$mpg, mtcars$cyl, mean), 2), "|",
      table(mtcars$cyl, mtcars$gear)["4", ])

  # Numerical tools.
  out(round(integrate(dnorm, -1.96, 1.96)$value, 4), "|",
      round(optimize(\(t) (t - 2)^2 + 1, c(-10, 10))$minimum, 3), "|",
      round(uniroot(\(t) t^3 - 8, c(0, 5))$root, 3), "|", crossprod(1:3), "|", cumprod(1:6), "|",
      choose(5, 2), factorial(5))
}

# ==================================================================================================
#  12. THE NEWEST
# ==================================================================================================

section12_newest <- function() {
  header("12. The newest")

  # Used above: raw strings r"(...)" (4.0), the native pipe |> and the lambda \(x) (4.1), the
  # pipe placeholder `_` (4.2) and its use in an extraction such as _[["wt"]] (4.3).
  out(R.version.string, "|", r"(a\b)", "|", 1:3 |> rev() |> paste(collapse = ""))

  # Newer than the interpreter this file was verified with — NOT run here:
  #   4.4   x %||% default          the default when x is NULL. C#: ??
  #   4.5   use("stats", "median")  attaches only the named functions of a package
  #
  # Much of everyday R lives in packages from CRAN (C#: NuGet): the "tidyverse" (dplyr,
  # ggplot2 ...) for data work, data.table for speed, R6 and S7 for objects.
}

# ==================================================================================================
#  ENTRY POINT
# ==================================================================================================

main <- function() {
  section01_basics()
  section02_vectors()
  section03_structures()
  section04_data_frames()
  section05_functions()
  section06_functional()
  section07_text()
  section08_objects()
  section09_errors()
  section10_metaprogramming()
  section11_statistics()
  section12_newest()
}

# Rscript runs a file from top to bottom; there is no required entry point.
main()
