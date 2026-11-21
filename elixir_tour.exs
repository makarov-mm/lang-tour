# =================================================================================================
#  ELIXIR FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
#
#  Run:
#
#      elixir elixir_tour.exs
#
#  Verified with Elixir 1.14.0 on Erlang/OTP 25 (Linux), without warnings. What Elixir 1.15
#  to 1.20 added is listed in section 14 as comments that were NOT run; the code keeps away
#  from what those versions deprecate.
#
#  How to read. The helper modules come first, because a module has to be defined before it
#  is used. The module Tour follows: one function per section, each of which prints what it
#  demonstrates, and main/0, which calls them in order. The last line of the file starts it.
#  A "C#:" note gives the closest counterpart in C#.
#
#  The main differences from C# to keep in mind from the first line:
#
#   1. All data is immutable. A variable can be bound again (x = x + 1 makes a new binding),
#      but no value ever changes in place.
#   2. = is the match operator: the left side is a pattern that the right side has to fit.
#   3. There are no classes, objects or methods. Modules hold functions, data is plain
#      (lists, maps, tuples, structs), and it is passed in explicitly: String.upcase(text),
#      not text.upcase(). The pipe operator |> chains such calls.
#   4. Atoms such as :ok and :error are constants that are their own name. An expected
#      failure is a return value, {:ok, value} or {:error, reason}, that the caller matches.
#   5. A function is identified by its name and arity (sum/1, sum/2) and can have several
#      clauses that are chosen by pattern; recursion or the Enum module replaces loops.
#   6. Only nil and false count as false. && and || work with any value; `and` and `or`
#      demand booleans.
#   7. Concurrency means light processes that share nothing and exchange messages. Elixir
#      runs on the Erlang virtual machine, and a process that crashes is restarted by its
#      supervisor.
#   8. def, if, defmodule are macros. Code is data, and the language can be extended with
#      macros of one's own.
#   9. The typing is dynamic and strong. Since Elixir 1.20 the compiler infers types and
#      reports contradictions, without annotations.
#
#  Contents:
#    1. Basics: values, operators, strings          8. Structs, protocols, behaviours
#    2. Pattern matching                            9. Errors
#    3. Lists, tuples, keyword lists, maps         10. Processes, tasks, agents
#    4. Control flow                               11. OTP: GenServer and Supervisor
#    5. Functions and modules                      12. Metaprogramming
#    6. Enum, Stream and comprehensions            13. Erlang, the runtime, ETS
#    7. Strings, binaries, sigils                  14. The newest
# =================================================================================================

# -------------------------------------------------------------------------------------------------
#  For section 5: a module with functions
# -------------------------------------------------------------------------------------------------

# A module is a namespace for functions. C#: a static class.
defmodule Tour.Geometry do
  @moduledoc "Documentation is a part of the language: h Tour.Geometry shows this in the shell."

  # A module attribute is a compile-time constant. C#: const
  @tau 6.283185307179586

  @doc "The area of a shape that is given as a tagged tuple."
  # A function can have several clauses; the first one whose pattern fits is taken.
  # C#: a method whose body is a switch expression
  def area({:circle, radius}), do: @tau / 2 * radius * radius
  def area({:rectangle, width, height}), do: width * height
  def area({:square, side}), do: area({:rectangle, side, side})

  # A guard after `when` narrows a clause. Only a fixed set of tests is allowed in it.
  def classify(n) when not is_number(n), do: :not_a_number
  def classify(n) when n < 0, do: :negative
  def classify(0), do: :zero
  def classify(n) when rem(n, 2) == 0 and n > 100, do: :big_even
  def classify(_), do: :positive

  # A default value is written after \\. The compiler generates power/1 and power/2.
  def power(base, exponent \\ 2), do: base ** exponent

  # Recursion replaces loops. sum/1 hides sum/2, which is private (defp) and tail-recursive:
  # its last act is the call to itself, so it runs in constant stack space.
  def sum(list), do: sum(list, 0)

  defp sum([], total), do: total
  defp sum([head | tail], total), do: sum(tail, total + head)

  def fib(n), do: fib(n, 0, 1)

  defp fib(0, a, _), do: a
  defp fib(n, a, b), do: fib(n - 1, b, a + b)
end

# -------------------------------------------------------------------------------------------------
#  For section 8: structs, protocols, behaviours
# -------------------------------------------------------------------------------------------------

# A struct is a map with a fixed set of keys and the name of its module.
# C#: a record with init-only properties
defmodule Tour.Person do
  @enforce_keys [:name]                 # these keys must be given when a struct is built
  defstruct [:name, age: 0, city: "unknown"]
end

defmodule Tour.Circle do
  defstruct radius: 1
end

defmodule Tour.Rectangle do
  defstruct width: 1, height: 1
end

# A protocol is a set of functions that can be implemented for any data type — also for
# types that somebody else wrote. C#: an interface, but implemented from the outside.
defprotocol Tour.Shape do
  @doc "The area of the shape."
  def area(shape)

  @doc "A short name."
  def name(shape)
end

defimpl Tour.Shape, for: Tour.Circle do
  def area(%Tour.Circle{radius: radius}), do: 3.141592653589793 * radius * radius
  def name(_), do: "circle"
end

defimpl Tour.Shape, for: Tour.Rectangle do
  def area(%Tour.Rectangle{width: width, height: height}), do: width * height
  def name(_), do: "rectangle"
end

# A protocol of the standard library, implemented for our struct: String.Chars is what
# interpolation and to_string/1 use. C#: overriding ToString
defimpl String.Chars, for: Tour.Person do
  def to_string(person), do: "#{person.name} (#{person.age})"
end

# A behaviour is a list of functions that a MODULE promises to have.
# C#: an interface with static abstract members
defmodule Tour.Parser do
  @callback parse(String.t()) :: {:ok, term} | {:error, atom}
  @callback extensions() :: [String.t()]
end

defmodule Tour.IntegerParser do
  @behaviour Tour.Parser

  @impl true                            # "this function implements a callback"
  def parse(text) do
    case Integer.parse(text) do
      {number, ""} -> {:ok, number}
      _ -> {:error, :not_an_integer}
    end
  end

  @impl true
  def extensions, do: [".int"]
end

# -------------------------------------------------------------------------------------------------
#  For section 9: an exception of our own
# -------------------------------------------------------------------------------------------------

# An exception is a struct with a message. C#: class ValidationError : Exception
defmodule Tour.ValidationError do
  defexception [:field, message: "is invalid"]
end

# -------------------------------------------------------------------------------------------------
#  For section 11: a GenServer
# -------------------------------------------------------------------------------------------------

# A GenServer is a process that holds state and answers messages, with the receive loop
# supplied by the library. C#: a hosted service with a mailbox; an actor
defmodule Tour.Counter do
  use GenServer                         # brings in the behaviour and default callbacks

  # The client side: ordinary functions that hide the messages.
  def start_link(initial) do
    GenServer.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def add(n), do: GenServer.cast(__MODULE__, {:add, n})      # cast: no answer is awaited
  def get, do: GenServer.call(__MODULE__, :get)              # call: waits for the answer

  # The server side: callbacks that run inside the process, one message at a time.
  @impl true
  def init(initial), do: {:ok, initial}                      # the initial state

  @impl true
  def handle_cast({:add, n}, count), do: {:noreply, count + n}

  @impl true
  def handle_call(:get, _from, count), do: {:reply, count, count}
end

# -------------------------------------------------------------------------------------------------
#  For section 12: macros
# -------------------------------------------------------------------------------------------------

defmodule Tour.Macros do
  # A macro receives CODE (a syntax tree) and returns code. It runs while the caller is
  # compiled. C#: a source generator, but written in the language and in a few lines.
  defmacro twice(expression) do
    quote do
      unquote(expression)
      unquote(expression)
    end
  end

  # A macro that shows the source text of its argument next to the value.
  defmacro labelled(expression) do
    text = Macro.to_string(expression)

    quote do
      "#{unquote(text)} = #{inspect(unquote(expression))}"
    end
  end

  # A custom control structure: `otherwise` runs its block when the condition is false.
  defmacro otherwise(condition, do: block) do
    quote do
      if unquote(condition), do: nil, else: unquote(block)
    end
  end

  # `use Tour.Macros, greeting: "..."` calls this macro; it injects a function into the
  # module that uses it. C#: what a base class or a generator would provide
  defmacro __using__(options) do
    greeting = Keyword.get(options, :greeting, "Hello")

    quote do
      def greet(name), do: "#{unquote(greeting)}, #{name}!"
    end
  end
end

defmodule Tour.Greeter do
  use Tour.Macros, greeting: "Good day"

  # Code that runs at compile time can define functions from data.
  for {name, factor} <- [double: 2, triple: 3] do
    def unquote(name)(n), do: n * unquote(factor)
  end
end

# =================================================================================================
#  The tour
# =================================================================================================

defmodule Tour do
  # alias shortens a module name; import makes functions callable without it; require makes
  # the macros of a module available. C#: using, using static
  alias Tour.{Circle, Counter, Geometry, Greeter, Person, Rectangle, Shape}
  require Tour.Macros

  def main do
    section01_basics()
    section02_matching()
    section03_collections()
    section04_control_flow()
    section05_functions()
    section06_enum()
    section07_strings()
    section08_structs()
    section09_errors()
    section10_processes()
    section11_otp()
    section12_macros()
    section13_runtime()
    section14_newest()
  end

  defp title(number, text), do: IO.puts("\n=== #{number}. #{text} ===")

  # inspect turns any value into its source form. The options make the output the same on
  # every version: maps with sorted keys, lists of small integers as lists.
  defp show(value), do: inspect(value, custom_options: [sort_maps: true], charlists: :as_lists)

  defp line(values), do: values |> Enum.map_join(" ", &show/1) |> IO.puts()

  # ===============================================================================================
  #  1. Basics: values, operators, strings
  # ===============================================================================================

  defp section01_basics do
    title(1, "Basics: values, operators, strings")

    count = 5                           # no declaration and no type: a name bound to a value
    price = 19.99
    big = 123_456_789_012_345_678_901_234_567_890 * 1000    # integers have no limit
    status = :ok                        # an atom: a constant that is its own name
    done = true                         # true, false and nil are atoms as well
    nothing = nil
    line([count, price, big, status, done, nothing])

    # A variable can be bound again; the value it had is not changed.
    count = count + 1
    IO.puts("count is now #{count}")    # interpolation. C#: $"count is now {count}"

    # Arithmetic. / always gives a float; div and rem are for integers.
    line([7 / 2, div(7, 2), rem(7, 3), 2 ** 10, Integer.pow(2, 100)])

    # Comparison. == compares numbers by value, === also demands the same type.
    line([equal?(1, 1.0), identical?(1, 1.0), 1 != 2, 2 <= 3])
    # Any two values can be compared: number < atom < ... < tuple < map < list < binary.
    line([Enum.sort([:b, 2, {:x}, "s", 1.5, :a])])

    # Only nil and false are "falsy". && and || return one of their operands.
    # C#: || on booleans, ?? on null
    line(truthiness(nothing, count, done))

    # Strings are UTF-8 binaries in double quotes; <> concatenates.
    name = "World"
    greeting = "Hello, " <> name <> "!"
    line([greeting, String.length(greeting), String.upcase(name), "#{1 + 1} items"])

    # Types are tested at run time.
    line([is_integer(count), is_float(price), is_atom(status), is_binary(name), is_nil(nothing)])
    # Conversions are functions.
    line([Integer.to_string(42), String.to_integer("42") + 1, round(2.5), trunc(2.7),
          Atom.to_string(status), to_string(3.5)])
  end

  # The compiler folds expressions whose values it can see and then warns that a test always
  # gives the same result; values that arrive as arguments keep it quiet.
  defp equal?(a, b), do: a == b
  defp identical?(a, b), do: a === b
  defp truthiness(a, b, c), do: [a || "fallback", b && "has a value", !a, c and b > 3]

  # ===============================================================================================
  #  2. Pattern matching
  # ===============================================================================================

  defp section02_matching do
    title(2, "Pattern matching")

    # = matches the pattern on the left with the value on the right and binds the variables
    # of the pattern. C#: deconstruction, generalized to every data type.
    {:ok, value} = fetch(:found)
    [first, second | rest] = [1, 2, 3, 4]
    %{name: name} = %{name: "Ann", age: 31}                 # a map pattern names only what it needs
    line([value, first, second, rest, name])

    # A value that does not fit raises MatchError.
    outcome =
      try do
        {:ok, _} = fetch(:missing)
      rescue
        error in MatchError -> "MatchError: no match for #{inspect(error.term)}"
      end

    IO.puts(outcome)

    # The pin operator ^ uses the VALUE of a variable in a pattern instead of binding it again.
    expected = 42
    line([matches?(expected, 42), matches?(expected, 43)])

    # _ fits anything and binds nothing. A name that occurs twice demands two equal values.
    {_, middle, _} = {1, 2, 3}
    line([middle, same_pair?({1, 1}), same_pair?({1, 2})])

    # Strings and binaries are matched too.
    "Hello, " <> who = "Hello, World"
    <<byte, _rest::binary>> = "ABC"
    line([who, byte])
  end

  defp fetch(:found), do: {:ok, 42}
  defp fetch(_), do: {:error, :not_found}

  defp matches?(expected, candidate) do
    case candidate do
      ^expected -> true
      _ -> false
    end
  end

  defp same_pair?({same, same}), do: true
  defp same_pair?({_, _}), do: false

  # ===============================================================================================
  #  3. Lists, tuples, keyword lists, maps
  # ===============================================================================================

  defp section03_collections do
    title(3, "Lists, tuples, keyword lists, maps")

    # A list is a singly linked list. C#: an immutable linked list; NOT an array:
    # reaching element n takes n steps, and so does length/1.
    list = [1, 2, 3]
    [head | tail] = list
    longer = [0 | list]                 # adding in front is O(1) and copies nothing
    line([head, tail, longer, list ++ [4, 5], [1, 2, 3, 2] -- [2], length(list), Enum.at(list, 1)])
    line([hd(list), tl(list), 2 in list, List.last(list), Enum.reverse(list)])

    # A tuple has a fixed size and fast access by index. C#: ValueTuple
    point = {3, 4}
    line([point, elem(point, 0), tuple_size(point), put_elem(point, 1, 40)])

    # A keyword list is a list of {atom, value} pairs with a shorter spelling. It keeps its
    # order, allows duplicate keys, and is how options are passed. C#: named arguments
    options = [timeout: 5000, retries: 3]
    line([options == [{:timeout, 5000}, {:retries, 3}], options[:retries],
          Keyword.get(options, :mode, :fast)])

    # A map. C#: an immutable Dictionary
    ages = %{"ann" => 31, "bob" => 27}                      # any value can be a key
    user = %{name: "Ann", age: 31}                          # atom keys have a shorter spelling
    older = %{user | age: 32}                               # updates an EXISTING key
    extended = Map.put(older, :city, "Munich")              # adds or replaces
    line([ages["ann"], ages["nobody"], user.name, older.age, Map.get(user, :city, "unknown")])
    line([extended, map_size(extended), extended |> Map.keys() |> Enum.sort(),
          Map.has_key?(user, :age)])
    line([user])                                            # the first map is unchanged
    # %{user | city: "Rome"}            ** (KeyError) key :city not found

    # Nested data is read and rewritten through paths.
    company = %{name: "Acme", address: %{city: "Munich", zip: "80331"}}
    moved = put_in(company.address.city, "Berlin")
    prefixed = update_in(company.address.zip, &("D-" <> &1))
    line([get_in(company, [:address, :city]), moved.address.city, prefixed.address.zip])

    # A range, and a set.
    line([Enum.to_list(1..5), Enum.to_list(1..10//3), 3 in 1..5, Enum.sum(1..100)])
    set = MapSet.new([3, 1, 3, 2])
    line([MapSet.size(set), MapSet.member?(set, 2), set |> MapSet.put(9) |> Enum.sort()])
  end

  # ===============================================================================================
  #  4. Control flow
  # ===============================================================================================

  defp section04_control_flow do
    title(4, "Control flow")

    # Everything is an expression with a value: if, case, cond and with included.
    n = 7
    parity = if rem(n, 2) == 0, do: "even", else: "odd"
    # The form with do ... end is the same thing, written over several lines.
    size =
      if n > 5 do
        "big"
      else
        "small"
      end

    line([parity, size])

    # case matches a value against patterns, with optional guards. C#: switch expression
    Enum.each([{:ok, 42}, {:error, :timeout}, [], [1, 2], %{name: "Ann"}, 3.14], fn term ->
      IO.puts("  " <> describe(term))
    end)

    # cond takes the first condition that is true. C#: an if / else if chain
    line(Enum.map([-5, 0, 5, 500], &sign/1))

    # with chains matches and stops at the first value that does not fit, returning it.
    # C#: a sequence of TryParse calls with early returns
    line([add_texts("40", "2"), add_texts("40", "x"), add_texts("-1", "2")])
  end

  defp describe(term) do
    case term do
      {:ok, value} -> "success: #{value}"
      {:error, reason} when is_atom(reason) -> "failure: #{reason}"
      [] -> "an empty list"
      [first | _] -> "a list that starts with #{first}"
      %{name: name} -> "a map with the name #{name}"
      other -> "something else: #{inspect(other)}"
    end
  end

  defp sign(n) do
    cond do
      n < 0 -> :negative
      n == 0 -> :zero
      n > 100 -> :large
      true -> :positive
    end
  end

  defp add_texts(a, b) do
    with {:ok, x} <- parse_positive(a),
         {:ok, y} <- parse_positive(b) do
      {:ok, x + y}
    end
  end

  defp parse_positive(text) do
    case Integer.parse(text) do
      {number, ""} when number >= 0 -> {:ok, number}
      {_, ""} -> {:error, :negative}
      _ -> {:error, :not_a_number}
    end
  end

  # ===============================================================================================
  #  5. Functions and modules     (the module Tour.Geometry is at the top of the file)
  # ===============================================================================================

  defp section05_functions do
    title(5, "Functions and modules")

    line([Geometry.area({:circle, 1}) |> Float.round(2), Geometry.area({:rectangle, 2, 3}),
          Geometry.area({:square, 4})])
    line(Enum.map([-5, 0, 7, 200, :abc], &Geometry.classify/1))
    line([Geometry.power(3), Geometry.power(2, 10), Geometry.sum(Enum.to_list(1..100_000)),
          Geometry.fib(90)])

    # An anonymous function is called with a dot. It is a closure. C#: a lambda
    double = fn x -> x * 2 end
    add = fn a, b -> a + b end
    factor = 3
    scale = fn x -> x * factor end
    line([double.(21), add.(1, 2), scale.(5)])

    # The capture operator & is a shorthand: &1 is the first argument. It also turns a named
    # function into a value. C#: a method group
    increment = &(&1 + 1)
    upcase = &String.upcase/1
    line([increment.(41), upcase.("shout"), Enum.map([1, 2, 3], &(&1 * &1))])

    # An anonymous function can have clauses as well.
    safe_divide = fn
      _, 0 -> {:error, :division_by_zero}
      a, b -> {:ok, a / b}
    end

    line([safe_divide.(7, 2), safe_divide.(1, 0)])

    # The pipe operator passes the value on its left as the FIRST argument of the call on
    # its right. C#: a chain of extension methods
    result =
      1..10
      |> Enum.filter(&(rem(&1, 2) == 0))
      |> Enum.map(&(&1 * &1))
      |> Enum.sum()

    words = "  hello world  " |> String.trim() |> String.split() |> Enum.map(&String.capitalize/1)
    line([result, words])

    # Functions that take and return functions.
    twice = fn f, x -> f.(f.(x)) end
    compose = fn f, g -> fn x -> f.(g.(x)) end end
    line([twice.(double, 5), compose.(double, increment).(5)])

    # The module and the function of a call can be values. C#: reflection
    line([apply(Enum, :max, [[3, 9, 4]]), function_exported?(Geometry, :area, 1),
          function_exported?(Geometry, :sum, 2)])
  end

  # ===============================================================================================
  #  6. Enum, Stream and comprehensions
  # ===============================================================================================

  defp section06_enum do
    title(6, "Enum, Stream and comprehensions")

    numbers = Enum.to_list(1..10)
    # Enum works on everything enumerable: lists, maps, ranges ... C#: LINQ to Objects
    line([Enum.map(numbers, &(&1 * 2)), Enum.filter(numbers, &(&1 > 7)),
          Enum.reduce(numbers, 0, &+/2)])
    line([Enum.sum(numbers), Enum.max(numbers), Enum.take(numbers, 3),
          Enum.chunk_every(numbers, 4)])
    line([Enum.zip([1, 2, 3], [:a, :b, :c]), Enum.with_index([:a, :b]),
          Enum.find(numbers, &(&1 > 4))])
    line([Enum.any?(numbers, &(&1 > 9)), Enum.all?(numbers, &(&1 > 0)), Enum.uniq([3, 1, 3, 2, 1]),
          Enum.frequencies(~w(a b a c a))])

    people = [%{name: "Bob", age: 27, city: "Berlin"}, %{name: "Ann", age: 31, city: "Munich"},
              %{name: "Cid", age: 45, city: "Munich"}]

    line([people |> Enum.sort_by(& &1.age, :desc) |> Enum.map(& &1.name),
          people |> Enum.group_by(& &1.city, & &1.name),
          Enum.min_by(people, & &1.age).name, Enum.map_join(people, ", ", & &1.name)])

    # Enum is eager: every step builds a list. Stream is lazy: nothing happens until a
    # result is asked for, so it can describe endless sequences. C#: IEnumerable with yield
    evens = Stream.iterate(0, &(&1 + 2))
    line([evens |> Stream.map(&(&1 * &1)) |> Enum.take(5),
          Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end) |> Enum.take(10),
          1..1_000_000 |> Stream.filter(&(rem(&1, 7) == 0)) |> Stream.take(3) |> Enum.to_list()])

    # for is a comprehension, not a loop: generators, filters, and a result.
    # C#: a LINQ query expression
    squares = for n <- numbers, rem(n, 2) == 0, do: n * n
    pairs = for a <- [1, 2], b <- [:x, :y], do: {a, b}
    triples = for a <- 1..20, b <- a..20, c <- b..20, a * a + b * b == c * c, do: {a, b, c}
    # The pattern of a generator filters, and into: chooses what is built.
    values = for {:ok, value} <- [{:ok, 1}, {:error, :x}, {:ok, 3}], do: value
    doubled = for {key, value} <- %{a: 1, b: 2}, into: %{}, do: {key, value * 2}
    total = for n <- numbers, reduce: 0, do: (sum -> sum + n)
    line([squares, pairs])
    line([triples])
    line([values, doubled, total])
  end

  # ===============================================================================================
  #  7. Strings, binaries, sigils
  # ===============================================================================================

  defp section07_strings do
    title(7, "Strings, binaries, sigils")

    text = "Hello, World"
    line([String.length(text), String.upcase(text), String.slice(text, 7, 5),
          String.replace(text, "l", "L"), String.contains?(text, "World")])
    line([String.split("a,b,,c", ","), String.split("a,b,,c", ",", trim: true),
          String.trim("  x  "), String.pad_leading("7", 3, "0"), String.reverse("abc")])
    line([String.to_integer("42"), Integer.parse("12abc"), Float.parse("2.5"),
          Integer.to_string(255, 16), :erlang.float_to_binary(3.14159, decimals: 2)])

    # A string is a binary that holds UTF-8. Bytes, code points and graphemes (what a reader
    # sees as one character) are three different counts. C#: string.Length counts UTF-16 units
    german = "Gr\u00FC\u00DFe"                              # u-umlaut, sharp s
    accent = "e\u0301"                                      # e + a combining accent
    line([byte_size(german), String.length(german), String.length(accent),
          length(String.codepoints(accent))])
    # Changing the case can change the length: the sharp s becomes SS.
    line([String.length(String.upcase(german)), String.downcase("ABC")])

    # Binaries are matched and built with <<>>; each segment has a size and a type.
    # C#: BinaryPrimitives, and shifts and masks by hand
    packet = <<4::4, 5::4, 0::8, 1500::16, "payload">>
    <<version::4, header_length::4, _service::8, total_length::16, payload::binary>> = packet
    line([packet, version, header_length, total_length, payload])
    <<red, green, blue>> = <<0xFF8000::24>>
    <<first_char::utf8, _::binary>> = german
    line([red, green, blue, first_char, <<1::32-little>>])

    # Sigils are literals with a letter: ~w word lists, ~r regular expressions, ~s strings
    # with quotes inside, ~D ~T ~N ~U dates and times, ~c charlists.
    line([~w(alpha beta gamma), ~w(a b c)a, ~s(say "hi"),
          Regex.run(~r/(\d+)-(\d+)/, "tel 555-1234")])
    line([Regex.scan(~r/\d+/, "a1 b22 c333") |> List.flatten(),
          String.match?("ann@example.com", ~r/^\S+@\S+$/),
          Regex.replace(~r/(\d+)-(\d+)-(\d+)/, "2026-11-17", "\\3.\\2.\\1")])
    date = ~D[2026-11-17]
    line([date, Date.add(date, 45), Date.diff(~D[2026-12-24], date), Date.day_of_week(date),
          Calendar.strftime(~N[2026-11-17 09:30:00], "%Y-%m-%d %H:%M")])

    # A charlist is a LIST of code points: the string type of Erlang, needed when Erlang
    # functions are called. A heredoc is a string over several lines.
    line([~c"abc", to_string(~c"abc"), String.to_charlist("abc") == ~c"abc"])

    poem = """
    two lines,
    indented relative to the closing quotes
    """

    line([poem |> String.split("\n", trim: true) |> length()])

    # iodata: a nested list of strings and bytes that output functions accept as it is.
    line([IO.iodata_to_binary(["a", ?b, ["c", [?d]]]), IO.iodata_length(["ab", [?c]])])
  end

  # ===============================================================================================
  #  8. Structs, protocols, behaviours     (the definitions are at the top of the file)
  # ===============================================================================================

  defp section08_structs do
    title(8, "Structs, protocols, behaviours")

    ann = %Person{name: "Ann", age: 31}
    moved = %{ann | city: "Munich"}                         # a copy with one field changed
    %Person{name: name, city: city} = moved                 # a pattern that demands a Person
    line([ann, name, city, ann.city, is_struct(ann, Person), is_map(ann)])
    # %Person{age: 5}                   ** (ArgumentError) the following keys must also be given
    #                                      when building struct Tour.Person: [:name]
    # %Person{name: "x", email: "y"}    a compile error: key :email not found

    # The protocol dispatches on the type of the first argument. C#: a virtual call
    shapes = [%Circle{radius: 1}, %Rectangle{width: 2, height: 3}]

    Enum.each(shapes, fn shape ->
      IO.puts("  #{Shape.name(shape)} with the area #{Float.round(Shape.area(shape) * 1.0, 2)}")
    end)

    # Protocols of the standard library: String.Chars (to_string), Inspect, Enumerable.
    line(["#{ann}", to_string(ann), Enum.count(%{a: 1, b: 2}), Enum.member?(1..10, 5)])

    # A behaviour is checked when the implementing module is compiled; the module is then
    # passed around as a value. C#: a type parameter with a static abstract interface
    parser = Tour.IntegerParser
    line([parser.parse("42"), parser.parse("4x"), parser.extensions()])
  end

  # ===============================================================================================
  #  9. Errors
  # ===============================================================================================

  defp section09_errors do
    title(9, "Errors")

    # An expected failure is a value. Functions come in pairs: fetch returns a tuple, and
    # the variant with ! raises. C#: TryGetValue versus the indexer
    settings = settings()
    line([Map.fetch(settings, :port), Map.fetch(settings, :host), Map.fetch!(settings, :port)])

    # raise and rescue. C#: throw and catch. rescue matches on the exception type.
    text = String.trim(" abc ")
    line([attempt(fn -> Map.fetch!(settings, :host) end),
          attempt(fn -> String.to_integer(text) end),
          attempt(fn -> raise "something went wrong" end),
          attempt(fn -> raise Tour.ValidationError, field: :age end),
          attempt(fn -> 42 end)])

    # after always runs; else handles the value when nothing was raised.
    result =
      try do
        divide(10, 2)
      rescue
        ArithmeticError -> :infinity
      else
        value -> {:computed, value}
      after
        IO.puts("  after: runs in every case")
      end

    line([result, attempt(fn -> divide(1, 0) end)])

    # throw and catch are a non-local return, and exit ends the process; both are rare.
    line([catch_value(fn -> throw(:enough) end), catch_value(fn -> exit(:giving_up) end)])

    # The stack trace is available as __STACKTRACE__ inside rescue and catch.
    try do
      Geometry.area(:triangle)
    rescue
      error in FunctionClauseError ->
        [{module, function, _, _} | _] = __STACKTRACE__
        IO.puts("  #{inspect(error.__struct__)} raised in #{inspect(module)}.#{function}")
    end
  end

  defp settings, do: %{port: 8080}

  defp divide(a, b), do: div(a, b)

  defp attempt(action) do
    {:ok, action.()}
  rescue                                # a function body can have rescue without try
    error in KeyError -> {:key_error, error.key}
    error in Tour.ValidationError -> {:invalid, error.field, error.message}
    error in [ArgumentError, ArithmeticError] -> {:error, error.__struct__}
    error -> {:other, Exception.message(error)}
  end

  defp catch_value(action) do
    action.()
  catch
    :throw, value -> {:thrown, value}
    :exit, reason -> {:exited, reason}
  end

  # ===============================================================================================
  #  10. Processes, tasks, agents
  # ===============================================================================================

  defp section10_processes do
    title(10, "Processes, tasks, agents")

    # spawn starts a process: an isolated unit with its own memory and mailbox, scheduled by
    # the virtual machine and far lighter than a thread. send never blocks; receive takes
    # the first message that fits a pattern. C#: a Task that owns its data and reads a Channel
    parent = self()
    child = spawn(fn -> send(parent, {self(), :hello}) end)

    receive do
      {^child, greeting} -> IO.puts("received #{inspect(greeting)} from a process")
    end

    # A process keeps state by calling itself with the new state.
    counter = spawn(fn -> counter_loop(0) end)
    send(counter, {:add, 5})
    send(counter, {:add, 10})
    send(counter, {:get, self()})

    receive do
      {:count, value} -> IO.puts("the counter process holds #{value}")
    after
      1000 -> IO.puts("no answer within a second")
    end

    send(counter, :stop)

    # Task: a process that computes one value. C#: Task.Run and await
    task = Task.async(fn -> Geometry.fib(50) end)
    line([Task.await(task)])
    # Many at once, with bounded concurrency and the results in order.
    # C#: Parallel.ForEachAsync, or Task.WhenAll
    results =
      [10, 20, 30, 40]
      |> Task.async_stream(&Geometry.fib/1, max_concurrency: 4)
      |> Enum.map(fn {:ok, value} -> value end)

    line([results])

    # Agent: a process that just holds a value. C#: a field behind a lock
    {:ok, agent} = Agent.start_link(fn -> %{} end)
    Agent.update(agent, &Map.put(&1, :visits, 1))
    Agent.update(agent, &Map.update!(&1, :visits, fn n -> n + 1 end))
    line([Agent.get(agent, & &1)])
    Agent.stop(agent)

    # A monitor reports the end of another process as a message.
    {pid, reference} = spawn_monitor(fn -> exit(:out_of_luck) end)

    receive do
      {:DOWN, ^reference, :process, ^pid, reason} ->
        IO.puts("monitored: ended with #{inspect(reason)}")
    end

    # Processes are cheap: twenty thousand of them, each waiting for a message.
    sleepers = for _ <- 1..20_000, do: spawn(fn -> receive do: (:stop -> :ok) end)
    IO.puts("#{length(sleepers)} more processes were started")
    Enum.each(sleepers, &send(&1, :stop))
  end

  defp counter_loop(count) do
    receive do
      {:add, n} ->
        counter_loop(count + n)

      {:get, from} ->
        send(from, {:count, count})
        counter_loop(count)

      :stop ->
        :ok
    end
  end

  # ===============================================================================================
  #  11. OTP: GenServer and Supervisor     (Tour.Counter is at the top of the file)
  # ===============================================================================================

  defp section11_otp do
    title(11, "OTP: GenServer and Supervisor")
    # A supervisor reports every crash of a child to the logger; the tour keeps it quiet.
    level = Logger.level()
    Logger.configure(level: :none)

    # A supervisor starts its children and restarts the ones that die.
    # {Counter, 100} means: call Counter.start_link(100).
    {:ok, supervisor} = Supervisor.start_link([{Counter, 100}], strategy: :one_for_one)
    first = Process.whereis(Counter)
    Counter.add(5)
    Counter.add(10)
    IO.puts("count: #{Counter.get()}")

    # Kill the server. The supervisor starts a new one in the known initial state, and the
    # clients go on using the same name. "Let it crash": recovery is a restart, not a catch.
    Process.exit(first, :kill)
    second = wait_for_restart(Counter, first)
    IO.puts("after the crash: a new process: #{second != first}, count: #{Counter.get()}")
    line([Supervisor.count_children(supervisor)])

    Supervisor.stop(supervisor)
    IO.puts("after stopping the supervisor the server is gone: #{Process.whereis(Counter) == nil}")
    Logger.configure(level: level)
  end

  defp wait_for_restart(name, previous) do
    case Process.whereis(name) do
      pid when is_pid(pid) and pid != previous ->
        pid

      _ ->
        Process.sleep(1)
        wait_for_restart(name, previous)
    end
  end

  # ===============================================================================================
  #  12. Metaprogramming     (Tour.Macros and Tour.Greeter are at the top of the file)
  # ===============================================================================================

  defp section12_macros do
    title(12, "Metaprogramming")

    # quote turns code into data: a tree of {name, metadata, arguments} tuples.
    {operator, _metadata, arguments} = quote do: 1 + 2 * 3
    line([operator, length(arguments), Macro.to_string(quote do: 1 + 2 * 3)])

    # unquote puts a value into quoted code; Code.eval_quoted runs it.
    # C#: expression trees, and compiling them
    factor = 10
    expression = quote do: unquote(factor) * 4 + 2
    {value, _bindings} = Code.eval_quoted(expression)
    {evaluated, _} = Code.eval_string("Enum.sum(for n <- 1..3, do: n * n)")
    line([Macro.to_string(expression), value, evaluated])

    # Macros of our own, expanded while this function is compiled.
    counter = :counters.new(1, [])
    Tour.Macros.twice(:counters.add(counter, 1, 1))
    line([:counters.get(counter, 1), Tour.Macros.labelled(Enum.sum([1, 2, 3]) * 2)])

    Tour.Macros.otherwise 1 > 2 do
      IO.puts("  otherwise: the condition was false, so this block ran")
    end

    # Functions that were generated at compile time.
    line([Greeter.greet("Ann"), Greeter.double(21), Greeter.triple(14)])

    # if itself is a macro: this is what it expands to.
    expanded = Macro.expand_once(quote(do: if(x, do: 1, else: 2)), __ENV__)
    line([expanded |> Macro.to_string() |> String.starts_with?("case")])
  end

  # ===============================================================================================
  #  13. Erlang, the runtime, ETS
  # ===============================================================================================

  defp section13_runtime do
    title(13, "Erlang, the runtime, ETS")

    # An Erlang module is an atom, and its functions are called directly: the whole Erlang
    # standard library is at hand. C#: referencing another .NET language's assembly
    line([:math.sqrt(16), :lists.reverse([1, 2, 3]), :erlang.phash2("abc") >= 0,
          "abc" |> :erlang.md5() |> Base.encode16(case: :lower)])

    # The virtual machine runs one scheduler per core and gives every process a small time
    # slice; each process has a heap of its own and is garbage-collected alone.
    IO.puts("Elixir #{System.version()} on OTP #{System.otp_release()}, " <>
              "#{System.schedulers_online()} scheduler(s)")

    # ETS: a table outside the process heaps that many processes can read and write.
    # C#: ConcurrentDictionary
    table = :ets.new(:people, [:set, :public])
    :ets.insert(table, [{:ann, 31, "Munich"}, {:bob, 27, "Berlin"}, {:cid, 45, "Munich"}])
    line([:ets.lookup(table, :bob), :ets.lookup(table, :nobody), :ets.info(table, :size)])
    line([:ets.update_counter(table, :ann, {2, 1}),
          table |> :ets.match({:"$1", :_, "Munich"}) |> Enum.sort()])
    :ets.delete(table)

    # :persistent_term holds values that are read constantly and changed almost never.
    :persistent_term.put({Tour, :settings}, %{retries: 3})
    line([:persistent_term.get({Tour, :settings})])
    :persistent_term.erase({Tour, :settings})

    # Measuring: :timer.tc returns the microseconds and the result.
    {microseconds, result} = :timer.tc(fn -> Geometry.fib(1000) |> Integer.digits() |> length() end)
    line([result, microseconds >= 0])

    # Distribution works as in Erlang: nodes started with a name connect to each other, and
    # send, spawn and GenServer.call take a node as well:
    #     iex --sname a                       iex --sname b
    #     Node.connect(:"a@host")
    #     GenServer.call({Tour.Counter, :"a@host"}, :get)
    line([node(), Node.alive?()])
  end

  # ===============================================================================================
  #  14. The newest
  # ===============================================================================================

  defp section14_newest do
    title(14, "The newest")

    # Additions of the releases up to 1.14, the version this file was verified with.
    line([Enum.to_list(1..10//4),                           # 1.12: ranges with a step
          21 |> then(&(&1 * 2)),                            # 1.12: then, and tap for side effects
          2 ** 8,                                           # 1.13: the power operator
          Enum.zip_with([1, 2], [10, 20], &+/2),            # 1.12
          Enum.slide([:a, :b, :c, :d], 0, 2),               # 1.13
          Code.ensure_loaded?(PartitionSupervisor)])        # 1.14: partitioned supervisors
    # 1.14 also brought dbg/1, which prints an expression — or every step of a pipeline —
    # together with its value. It writes to standard error, so the tour does not call it:
    #     [1, 2, 3] |> Enum.map(&(&1 * 2)) |> Enum.sum() |> dbg()
    # 1.12: a script can declare its own dependencies with Mix.install([:jason]).

    # Newer than the version this file was verified with, and therefore NOT run here:
    #   1.17 (2024)   Duration and Date.shift(date, month: 1); the first warnings from the
    #                 new type system
    #   1.18 (2024)   a JSON module in the standard library: JSON.encode!(%{a: 1});
    #                 type checking of function calls
    #   1.19 (2025)   type inference of anonymous functions, type checking of protocols,
    #                 much faster compilation of large projects
    #   1.20 (2026)   "a gradually typed language": the types of all constructs are inferred
    #                 and checked across modules and dependencies, with no annotations.
    #                 A call such as String.upcase(42) is reported when the file is compiled.
    IO.puts("the newer features: see the comments in the source")
  end
end

Tour.main()
