%% =================================================================================================
%%  ERLANG FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
%%
%%  Run it as a script:
%%
%%      escript erlang_tour.erl
%%
%%  or compile it and call main/0:
%%
%%      erlc erlang_tour.erl
%%      erl -pa . -noshell -s erlang_tour main -s init stop
%%
%%  Verified with Erlang/OTP 25 on Linux, both ways, with no compiler warnings. The language
%%  additions of OTP 26 to 29 are listed in section 14 as comments that were NOT compiled.
%%
%%  How to read. Go from top to bottom: main/0 calls the sections in order, and every section
%%  prints what it demonstrates; the functions a section needs stand just above it. A "C#:"
%%  note gives the closest counterpart in C#. A line that is commented out and followed by an
%%  error shows what would happen.
%%
%%  The main differences from C# to keep in mind from the first line:
%%
%%   1. All data is immutable, and a variable is bound once: X = 1 followed by X = 2 is an
%%      error. "Changing" something means building a new value.
%%   2. = is pattern matching, not assignment: the left side is a pattern that the right side
%%      has to fit, and its unbound variables get their values from it.
%%   3. Variables start with a capital letter. A name that starts with a lower-case letter is
%%      an ATOM: a constant that stands for itself (ok, error, true).
%%   4. There are no loops and no classes. Iteration is recursion (or a library function), and
%%      state lives in the arguments of a function that calls itself.
%%   5. A function is a list of clauses that are tried in order, and name/arity identifies
%%      it: sum/1 and sum/2 are two different functions.
%%   6. Punctuation separates: a comma between expressions, a semicolon between clauses, a
%%      full stop at the end of a function.
%%   7. Concurrency means processes that share nothing and send each other messages. They are
%%      cheap enough to have one per connection, per request, per game object.
%%   8. Errors are not prevented at all costs: a process that meets the unexpected crashes,
%%      and a supervisor starts a fresh one ("let it crash").
%%   9. The typing is dynamic and strong. Type specifications exist and are checked by a
%%      separate tool, Dialyzer.
%%
%%  Contents:
%%    1. Basics: terms, variables, operators          8. Errors: error, exit, throw
%%    2. Tuples, lists, maps, records                 9. Processes and messages
%%    3. Pattern matching, guards, case and if       10. Links, monitors, "let it crash"
%%    4. Functions, funs, recursion                  11. OTP: gen_server and supervisor
%%    5. List comprehensions and the lists module    12. ETS and other shared state
%%    6. Strings, binaries and the bit syntax        13. The runtime system
%%    7. Modules, macros, types and specs            14. The newest
%% =================================================================================================

%% A file is a module, and lines that start with a hyphen are its attributes.
%% C#: a static class; the attributes are its declarations.
-module(erlang_tour).
-mode(compile).                     % for escript: compile the file instead of interpreting it

%% Only exported functions can be called from other modules. C#: public
-export([main/0, main/1]).

%% This module implements the gen_server behaviour (section 11). C#: implementing an interface.
%% Callbacks are called from the library, so they are exported as well.
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).
-export([counter_start_link/1]).

%% A macro: text replaced before compilation. C#: const, or #define without the dangers removed.
-define(TAU, 6.283185307179586).
-define(SQUARE(X), ((X) * (X))).

%% A record: a tuple with named fields, known to the compiler only. C#: a record struct
-record(person, {name, age = 0, city = "unknown"}).

%% Types and function specifications. The compiler does not enforce them; Dialyzer checks them.
-type shape() :: {circle, number()} | {rectangle, number(), number()} | {square, number()}.
-type result(Value) :: {ok, Value} | {error, term()}.

main(_Arguments) ->                 % the entry point of escript
    main().

main() ->
    section01_basics(),
    section02_data(),
    section03_matching(),
    section04_functions(),
    section05_lists(),
    section06_strings(),
    section07_modules(),
    section08_errors(),
    section09_processes(),
    section10_links(),
    section11_otp(),
    section12_ets(),
    section13_runtime(),
    section14_newest(),
    ok.

title(Number, Text) ->
    %% io:format is printf: ~p prints any term, ~s a string, ~B an integer, ~n a new line.
    io:format("~n=== ~B. ~s ===~n", [Number, Text]).

%% =================================================================================================
%%  1. Basics: terms, variables, operators
%% =================================================================================================

section01_basics() ->
    title(1, "Basics: terms, variables, operators"),

    %% A variable starts with a capital letter and is bound exactly once.
    Count = 5,
    Price = 19.99,
    Big = 123456789012345678901234567890 * 1000,    % integers have no limit. C#: BigInteger
    Status = ok,                                    % an atom: a constant that is its own name
    Done = true,                                    % true and false are atoms too
    io:format("~p ~p ~p ~p ~p~n", [Count, Price, Big, Status, Done]),

    %% = matches the pattern on the left against the value on the right.
    Count = 5,                                      % fine: 5 fits 5
    %% Count = 6,                                   ** exception error: no match of right hand
    %%                                              side value 6

    %% Arithmetic. / always gives a float; div and rem are for integers.
    io:format("7 / 2 = ~p, 7 div 2 = ~p, 7 rem 3 = ~p, 1 bsl 10 = ~p, math:pow(2, 10) = ~p~n",
              [7 / 2, 7 div 2, 7 rem 3, 1 bsl 10, math:pow(2, 10)]),

    %% Comparison. == compares numbers by value, =:= also demands the same type. "Not equal"
    %% is /= or =/=, and "less or equal" is written =<.
    One = 1,
    io:format("1 == 1.0: ~p, 1 =:= 1.0: ~p, 1 /= 2: ~p, 2 =< 3: ~p~n",
              [One == 1.0, One =:= 1.0, One /= 2, 2 =< Count]),

    %% Any two terms can be compared; the types are ordered:
    %% number < atom < reference < fun < port < pid < tuple < map < list < binary.
    io:format("sorted: ~p~n", [lists:sort([b, 2, {x}, "s", 1.5, a])]),

    %% andalso and orelse short-circuit. C#: && and ||
    io:format("~p ~p ~p~n", [Done andalso Count > 3, not Done, Count > 10 orelse Status =:= ok]),

    %% Types are tested at run time, and conversions are functions.
    io:format("~p ~p ~p ~p~n", [is_integer(Count), is_float(Price), is_atom(Status),
                                is_atom(Done)]),
    io:format("~p ~p ~p ~p ~p ~p~n", [integer_to_list(42), list_to_integer("42") + 1, float(Count),
                                      round(2.5), trunc(2.7), atom_to_list(Status)]).

%% =================================================================================================
%%  2. Tuples, lists, maps, records
%% =================================================================================================

section02_data() ->
    title(2, "Tuples, lists, maps, records"),

    %% A tuple has a fixed number of elements. With an atom in front it is the usual way to
    %% make a small "object". C#: a ValueTuple, or a record
    Point = {point, 3, 4},
    {point, X, Y} = Point,                          % taking it apart is matching
    io:format("~p ~p ~p ~p ~p~n", [Point, X, Y, tuple_size(Point), element(2, Point)]),

    %% A list is a singly linked list. C#: an immutable linked list; NOT an array:
    %% reaching element n takes n steps.
    List = [1, 2, 3],
    [Head | Tail] = List,                           % [H | T]: the first element and the rest
    Longer = [0 | List],                            % adding in front is O(1) and copies nothing
    io:format("~p ~p ~p ~p ~p ~p~n", [Head, Tail, Longer, List ++ [4, 5], length(List),
                                      lists:nth(2, List)]),
    io:format("~p ~p ~p~n", [[1, 2, 3, 2] -- [2], lists:reverse(List), lists:member(2, List)]),

    %% A map. C#: an immutable dictionary
    Ages = #{ann => 31, bob => 27},
    Older = Ages#{ann := 32, cid => 40},            % := changes a key that exists, => adds one
    #{ann := AnnAge} = Older,                       % matching takes values out
    io:format("~p ~p ~p ~p ~p~n", [AnnAge, maps:get(bob, Older), maps:get(dee, Older, unknown),
                                   map_size(Older), lists:sort(maps:keys(Older))]),
    io:format("the first map is unchanged: ~p~n", [maps:get(ann, Ages)]),

    %% A record is a tuple whose fields have names at compile time.
    Ann = #person{name = "Ann", age = 31},
    Moved = Ann#person{city = "Munich"},            % a copy with one field changed
    #person{name = Name, city = City} = Moved,
    io:format("~s lives in ~s; the record is the tuple ~p; age is element ~p~n",
              [Name, City, Ann, #person.age]).

%% =================================================================================================
%%  3. Pattern matching, guards, case and if
%% =================================================================================================

%% A function is a list of clauses, separated by semicolons. The first clause whose pattern
%% fits the arguments is taken. C#: a method whose body is one switch expression
-spec area(shape()) -> number().
area({circle, Radius}) -> math:pi() * Radius * Radius;
area({rectangle, Width, Height}) -> Width * Height;
area({square, Side}) -> area({rectangle, Side, Side}).

%% A guard, after `when`, adds a condition to a clause. Only a fixed set of tests without
%% side effects is allowed there. A comma in a guard means "and", a semicolon "or".
classify(N) when not is_number(N) -> not_a_number;
classify(N) when N < 0 -> negative;
classify(0) -> zero;
classify(N) when N rem 2 =:= 0, N > 100 -> big_even;
classify(_) -> positive.                            % _ fits anything and binds nothing

%% if has guards only, and no else: the last branch is usually `true`.
size_class(N) ->
    if
        N > 100 -> big;
        N > 10 -> medium;
        true -> small
    end.

section03_matching() ->
    title(3, "Pattern matching, guards, case and if"),

    io:format("~.2f ~p ~p~n", [area({circle, 1}), area({rectangle, 2, 3}), area({square, 4})]),
    io:format("~p~n", [[classify(Value) || Value <- [-5, 0, 7, 200, abc]]]),
    %% area(triangle)       ** exception error: no function clause matching area(triangle)

    %% case does the same matching inside an expression. Everything is an expression: case,
    %% if and try all have a value.
    Describe = fun(Term) ->
        case Term of
            {ok, Value} -> {"success", Value};
            {error, Reason} when is_atom(Reason) -> {"failure", Reason};
            [] -> {"an empty list", none};
            [First | _] -> {"a list that starts with", First};
            #{name := Name} -> {"a map with a name", Name};
            _ -> {"something else", Term}
        end
    end,
    lists:foreach(fun(Term) ->
                      {Text, Detail} = Describe(Term),
                      io:format("  ~s ~p~n", [Text, Detail])
                  end,
                  [{ok, 42}, {error, timeout}, [], [1, 2], #{name => "Ann"}, 3.14]),

    %% A variable that already has a value means "equal to this value" inside a pattern.
    Expected = 42,
    Check = fun(Value) ->
                case Value of
                    Expected -> same;
                    _ -> different
                end
            end,
    %% A variable that occurs twice in one pattern demands two equal values.
    Pair = fun({Same, Same}) -> equal;
              ({_, _}) -> different
           end,
    io:format("~p ~p ~p ~p~n", [Check(42), Check(43), Pair({1, 1}), Pair({1, 2})]),

    io:format("~p ~p ~p~n", [size_class(500), size_class(42), size_class(7)]).

%% =================================================================================================
%%  4. Functions, funs, recursion
%% =================================================================================================

%% Recursion takes the place of loops. This sum is NOT tail-recursive: every call waits for
%% the next one, and the stack grows with the list.
sum([]) -> 0;
sum([Head | Tail]) -> Head + sum(Tail).

%% sum/2 is another function. It carries the result along in an accumulator, so its last act
%% is the call to itself; such a tail call reuses the stack frame. C#: a while loop
sum([], Total) -> Total;
sum([Head | Tail], Total) -> sum(Tail, Total + Head).

factorial(0) -> 1;
factorial(N) when N > 0 -> N * factorial(N - 1).

fib(N) -> fib(N, 0, 1).

fib(0, A, _) -> A;
fib(N, A, B) -> fib(N - 1, B, A + B).

section04_functions() ->
    title(4, "Functions, funs, recursion"),

    io:format("~p ~p ~p ~p~n", [sum([1, 2, 3]), sum(lists:seq(1, 100000), 0), factorial(25),
                                fib(90)]),

    %% A fun is an anonymous function, and a closure. C#: a lambda
    Double = fun(X) -> X * 2 end,
    Add = fun(A, B) -> A + B end,
    Factor = 3,
    Scale = fun(X) -> X * Factor end,               % captures Factor
    io:format("~p ~p ~p~n", [Double(21), Add(1, 2), Scale(5)]),

    %% A named function as a value: fun Name/Arity or fun Module:Name/Arity.
    %% C#: a method group
    Factorial = fun factorial/1,
    Upper = fun string:uppercase/1,
    io:format("~p ~s~n", [Factorial(5), Upper("shout")]),

    %% Functions that take and return functions.
    Twice = fun(F, X) -> F(F(X)) end,
    Compose = fun(F, G) -> fun(X) -> F(G(X)) end end,
    Increment = fun(X) -> X + 1 end,
    DoubleAfterIncrement = Compose(Double, Increment),
    io:format("~p ~p~n", [Twice(Double, 5), DoubleAfterIncrement(5)]),

    %% A fun that calls itself needs a name of its own.
    Countdown = fun Loop(0) -> [liftoff];
                    Loop(N) -> [N | Loop(N - 1)]
                end,
    io:format("~p~n", [Countdown(3)]),

    %% The module and the function of a call can be values decided at run time.
    %% C#: reflection; here it is an ordinary call.
    Module = lists,
    Function = max,
    io:format("~p ~p~n", [Module:Function([3, 9, 4]), apply(erlang, max, [1, 2])]).

%% =================================================================================================
%%  5. List comprehensions and the lists module
%% =================================================================================================

section05_lists() ->
    title(5, "List comprehensions and the lists module"),

    Numbers = lists:seq(1, 10),
    %% [Expression || Pattern <- List, Filter]. C#: LINQ's from ... where ... select
    Squares = [N * N || N <- Numbers],
    Evens = [N || N <- Numbers, N rem 2 =:= 0],
    Pairs = [{A, B} || A <- [1, 2], B <- [x, y]],   % two generators: every combination
    Triples = [{A, B, C} || A <- lists:seq(1, 20), B <- lists:seq(A, 20), C <- lists:seq(B, 20),
                            A * A + B * B =:= C * C],
    %% The pattern of a generator is a filter as well: what does not fit is skipped.
    Values = [Value || {ok, Value} <- [{ok, 1}, {error, x}, {ok, 3}]],
    io:format("~p~n~p~n~p~n~p~n~p~n", [Squares, Evens, Pairs, Triples, Values]),

    %% The lists module. C#: the LINQ methods
    io:format("~p ~p ~p~n", [lists:map(fun(N) -> N * 2 end, [1, 2, 3]),
                             lists:filter(fun(N) -> N rem 3 =:= 0 end, Numbers),
                             lists:foldl(fun(N, Total) -> N + Total end, 0, Numbers)]),
    io:format("~p ~p ~p ~p~n", [lists:sum(Numbers), lists:max(Numbers), lists:sublist(Numbers, 3),
                                lists:last(Numbers)]),
    io:format("~p ~p~n", [lists:zip([1, 2, 3], [a, b, c]),
                          lists:partition(fun(N) -> N rem 2 =:= 0 end, Numbers)]),
    io:format("~p ~p ~p~n", [lists:any(fun(N) -> N > 9 end, Numbers),
                             lists:all(fun(N) -> N > 0 end, Numbers),
                             lists:usort([3, 1, 3, 2, 1])]),

    %% Lists of tuples serve as small tables; the key* functions look at one element.
    People = [{bob, 27}, {ann, 31}, {cid, 45}],
    io:format("~p ~p ~p~n", [lists:keyfind(ann, 1, People), lists:keysort(2, People),
                             lists:sort(fun({_, Age1}, {_, Age2}) -> Age1 >= Age2 end, People)]).

%% =================================================================================================
%%  6. Strings, binaries and the bit syntax
%% =================================================================================================

section06_strings() ->
    title(6, "Strings, binaries and the bit syntax"),

    %% Text in double quotes is a LIST of code points. C#: think of List<int>
    Hello = "Hello",
    io:format("~p ~p ~p ~w ~p ~p~n", [Hello, length(Hello), hd(Hello), "Hi", [72, 105] =:= "Hi",
                                      $A]),            % ~w shows the list; $A is a character code
    %% The classic surprise: ~p prints ANY list of printable character codes as text.
    io:format("~p is the list ~w~n", [[8, 9, 10], [8, 9, 10]]),

    %% A binary is a block of bytes, and the compact way to hold text. C#: a UTF-8 byte[]
    Binary = <<"Hello, World">>,
    io:format("~p ~p ~p~n", [Binary, byte_size(Binary), binary:part(Binary, 7, 5)]),

    %% The string module accepts both kinds.
    io:format("~p ~p ~p ~p~n", [string:uppercase(Hello), string:uppercase(Binary),
                                string:split("a,b,c", ",", all), string:trim("  x  ")]),
    io:format("~p ~p ~p~n", [binary:split(<<"a,b,c">>, <<",">>, [global]),
                             string:find("Hello, World", "World"), string:length(Hello)]),

    %% Conversions.
    io:format("~p ~p ~p ~p~n", [list_to_binary("abc"), binary_to_list(<<"abc">>),
                                integer_to_binary(42), binary_to_integer(<<"42">>) + 1]),
    io:format("~p ~p~n", [float_to_binary(3.14159, [{decimals, 2}]),
                          lists:flatten(io_lib:format("~p + ~p = ~p", [1, 2, 1 + 2]))]),

    %% Outside ASCII a list holds code points and a binary holds UTF-8 bytes.
    Greeting = "Gr\x{FC}\x{DF}e",                   % u-umlaut and sharp s, written as escapes
    Utf8 = unicode:characters_to_binary(Greeting),
    io:format("~p code points, ~p bytes~n", [length(Greeting), byte_size(Utf8)]),

    %% An iolist is a nested list of strings and binaries. Every output function accepts
    %% one, so text is assembled without copying. C#: writing the pieces to a Stream
    Pieces = ["a", <<"b">>, [$c, ["d"]]],
    io:format("~p ~p~n", [iolist_to_binary(Pieces), iolist_size(Pieces)]),

    %% The bit syntax builds and matches binaries field by field: Value:Size/Type.
    %% C#: BinaryPrimitives and shifts and masks by hand.
    Packet = <<4:4, 5:4, 0:8, 1500:16/big, "payload">>,
    <<Version:4, HeaderLength:4, _Service:8, TotalLength:16/big, Payload/binary>> = Packet,
    io:format("~p -> version ~p, header length ~p, total length ~p, payload ~p~n",
              [Packet, Version, HeaderLength, TotalLength, Payload]),
    <<Red:8, Green:8, Blue:8>> = <<16#FF8000:24>>,
    io:format("~p ~p ~p ~p ~w~n", [Red, Green, Blue, <<1:32/little>>, <<16#E9/utf8>>]),
    %% A comprehension over a binary uses <= and can build a binary.
    io:format("~p ~p~n", [<< <<(Byte * 2)>> || <<Byte>> <= <<1, 2, 3>> >>,
                          [Bit || <<Bit:1>> <= <<5:4>>]]).

%% =================================================================================================
%%  7. Modules, macros, types and specs
%% =================================================================================================

-spec parse_age(string()) -> result(non_neg_integer()).
parse_age(Text) ->
    case string:to_integer(Text) of
        {Age, ""} when Age >= 0, Age =< 150 -> {ok, Age};
        {Age, ""} -> {error, {out_of_range, Age}};
        _ -> {error, not_a_number}
    end.

section07_modules() ->
    title(7, "Modules, macros, types and specs"),

    %% Macros are used with a question mark; some are predefined.
    io:format("~p ~p ~p ~.3f ~p~n", [?FUNCTION_NAME, ?FUNCTION_ARITY, is_atom(?MODULE), ?TAU,
                                     ?SQUARE(1 + 2)]),

    %% A call into another module is always written Module:Function(Arguments).
    %% Every module can describe itself. C#: reflection
    Exports = ?MODULE:module_info(exports),
    io:format("main/0 is exported: ~p; sum/2 is exported: ~p~n",
              [lists:member({main, 0}, Exports), lists:member({sum, 2}, Exports)]),

    %% The -spec above parse_age/1 says that it takes a string and returns {ok, Age} or
    %% {error, Reason}. The compiler ignores a call that contradicts it; Dialyzer reports it.
    io:format("~p ~p ~p~n", [parse_age("42"), parse_age("999"), parse_age("abc")]).

%% =================================================================================================
%%  8. Errors: error, exit, throw
%% =================================================================================================

section08_errors() ->
    title(8, "Errors: error, exit, throw"),

    %% A failure that the caller should expect is an ordinary return value: {ok, Value} or
    %% {error, Reason}. C#: TryParse, or a Result type
    {ok, Age} = parse_age("42"),                    % "it must work": anything else crashes here
    io:format("~p~n", [Age]),

    %% Exceptions come in three classes: error (a bug: badmatch, badarith, function_clause),
    %% exit (a process gives up), throw (a non-local return). try ... catch matches on
    %% Class:Reason, and `after` runs in every case. C#: try / catch / finally
    Attempt = fun(Action) ->
        try Action() of
            Value -> {returned, Value}
        catch
            error:badarith -> {caught, error, badarith};
            error:{badmatch, Unmatched} -> {caught, error, {badmatch, Unmatched}};
            throw:Term -> {caught, throw, Term};
            exit:Reason -> {caught, exit, Reason};
            Class:Reason -> {caught, Class, Reason}
        after
            ok                                      % clean-up; its value is ignored
        end
    end,
    Zero = string:length(""),                       % a zero that the compiler cannot foresee
    lists:foreach(fun(Action) -> io:format("  ~p~n", [Attempt(Action)]) end,
                  [fun() -> 42 end,
                   fun() -> 1 / Zero end,
                   fun() -> {ok, _} = parse_age("abc") end,
                   fun() -> throw(enough) end,
                   fun() -> exit(giving_up) end,
                   fun() -> error({invalid, 7}) end,
                   fun() -> area(triangle) end]),

    %% A third name in the pattern receives the stack trace.
    try
        area(triangle)
    catch
        error:function_clause:Stacktrace ->
            [{_Module, Function, Arguments, _Location} | _] = Stacktrace,
            io:format("raised in ~p with the arguments ~p~n", [Function, Arguments])
    end.

%% =================================================================================================
%%  9. Processes and messages
%% =================================================================================================

%% A process that keeps state is a function that calls itself with the new state.
%% C#: an actor, or a Task that reads a Channel<T> in a loop and owns all of its data.
counter_loop(Count) ->
    receive
        {add, N} ->
            counter_loop(Count + N);
        {get, From} ->
            From ! {count, Count},
            counter_loop(Count);
        stop ->
            ok
    end.

%% A parallel map: one process per element. The unique reference pairs each answer with its
%% question, and the results are collected in the order of the input.
%% C#: Task.WhenAll(items.Select(item => Task.Run(...)))
parallel_map(Fun, List) ->
    Parent = self(),
    References = [begin
                      Reference = make_ref(),
                      spawn(fun() -> Parent ! {Reference, Fun(Item)} end),
                      Reference
                  end || Item <- List],
    [receive {Reference, Result} -> Result end || Reference <- References].

section09_processes() ->
    title(9, "Processes and messages"),

    %% spawn starts a process: an isolated unit with its own memory and its own mailbox,
    %% scheduled by the runtime, far lighter than a thread. ! sends a message and never
    %% blocks; receive takes the first message in the mailbox that fits one of its patterns.
    Parent = self(),
    Child = spawn(fun() -> Parent ! {self(), hello} end),
    receive
        {Child, Greeting} ->
            io:format("received ~p from a process: ~p~n", [Greeting, is_pid(Child)])
    end,

    Counter = spawn(fun() -> counter_loop(0) end),
    Counter ! {add, 5},
    Counter ! {add, 10},
    Counter ! {get, self()},
    receive
        {count, Value} -> io:format("the counter process holds ~p~n", [Value])
    end,
    Counter ! stop,

    %% receive ... after gives up waiting.
    receive
        never_sent -> ok
    after 50 ->
        io:format("nothing arrived within 50 milliseconds~n")
    end,

    %% A receive is selective: it can pick a later message and leave earlier ones waiting.
    self() ! {note, low, "sent first"},
    self() ! {note, high, "sent second"},
    receive {note, high, Urgent} -> io:format("taken first: ~s~n", [Urgent]) end,
    receive {note, low, Routine} -> io:format("taken second: ~s~n", [Routine]) end,

    io:format("~p~n", [parallel_map(fun fib/1, [10, 20, 30, 40])]),

    %% A process can be registered under a name. C#: a singleton service
    register(tour_echo, spawn(fun() -> receive {From, Text} -> From ! {echo, Text} end end)),
    tour_echo ! {self(), "by name"},
    receive
        {echo, Echo} ->
            io:format("echo ~s; still registered: ~p~n", [Echo, whereis(tour_echo)])
    end.

%% =================================================================================================
%%  10. Links, monitors, "let it crash"
%% =================================================================================================

%% A supervisor in a dozen lines. It starts a worker that is linked to it and, because it
%% traps exits, receives a message when the worker dies; then it starts another one.
mini_supervisor(Owner, Work, Restarts) ->
    process_flag(trap_exit, true),
    Worker = spawn_link(Work),
    receive
        {'EXIT', Worker, normal} -> Owner ! {supervised, finished, Restarts};
        {'EXIT', Worker, _Reason} -> mini_supervisor(Owner, Work, Restarts + 1)
    end.

section10_links() ->
    title(10, "Links, monitors, \"let it crash\""),

    %% A monitor reports the end of another process as a 'DOWN' message with the reason:
    %% normal, the argument of exit/1, or the error and its stack trace.
    %% C#: awaiting a Task, or a continuation
    {Process1, Monitor1} = spawn_monitor(fun() -> ok end),
    receive {'DOWN', Monitor1, process, Process1, Reason1} -> ok end,
    {Process2, Monitor2} = spawn_monitor(fun() -> exit(out_of_luck) end),
    receive {'DOWN', Monitor2, process, Process2, Reason2} -> ok end,
    io:format("monitored: one ended with ~p, one with ~p~n", [Reason1, Reason2]),

    %% A link ties two processes together: when one dies abnormally, the other one dies too.
    %% A process that traps exits receives the signal as a message instead.
    process_flag(trap_exit, true),
    Linked = spawn_link(fun() -> exit(crashed) end),
    receive
        {'EXIT', Linked, Why} ->
            io:format("linked: the exit signal ~p arrived as a message~n", [Why])
    end,
    process_flag(trap_exit, false),

    %% "Let it crash": the worker does not defend itself against the unexpected. It dies,
    %% and its supervisor starts a clean one. Here the worker fails twice.
    Attempts = counters:new(1, []),                 % a mutable counter that processes share
    Work = fun() ->
               counters:add(Attempts, 1, 1),
               case counters:get(Attempts, 1) of
                   Attempt when Attempt < 3 -> exit({failed_attempt, Attempt});
                   _ -> ok
               end
           end,
    Owner = self(),
    spawn(fun() -> mini_supervisor(Owner, Work, 0) end),
    receive
        {supervised, finished, Restarts} ->
            io:format("the worker finished after ~p restarts~n", [Restarts])
    end.

%% =================================================================================================
%%  11. OTP: gen_server and supervisor
%% =================================================================================================

%% OTP is the library of standard process patterns. A gen_server is the generic server:
%% the library owns the receive loop, and a callback module supplies what is specific.
%% C#: a hosted service with a mailbox; the callbacks are the interface it implements.

%% The client side: ordinary functions that hide the messages.
counter_start_link(Initial) ->
    gen_server:start_link({local, tour_counter}, ?MODULE, {counter, Initial}, []).

counter_add(N) -> gen_server:cast(tour_counter, {add, N}).  % cast: no answer is awaited
counter_get() -> gen_server:call(tour_counter, get).        % call: waits for the answer
counter_calls() -> gen_server:call(tour_counter, calls).

%% The callbacks; they run inside the server process, one message at a time.
init({counter, Initial}) ->
    {ok, #{count => Initial, calls => 0}};          % the initial state
%% A supervisor needs a callback module too, with an init/1 that describes the children.
%% A real project gives it a module of its own; this single file lets a second clause of
%% the same function do it.
init({supervisor, Initial}) ->
    Flags = #{strategy => one_for_one, intensity => 3, period => 10},
    Child = #{id => counter, start => {?MODULE, counter_start_link, [Initial]}},
    {ok, {Flags, [Child]}}.

handle_call(get, _From, State = #{count := Count, calls := Calls}) ->
    {reply, Count, State#{calls := Calls + 1}};     % the answer and the new state
handle_call(calls, _From, State = #{calls := Calls}) ->
    {reply, Calls, State}.

handle_cast({add, N}, State = #{count := Count}) ->
    {noreply, State#{count := Count + N}}.

handle_info(_Message, State) ->                     % any other message that arrives
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

wait_for_restart(Name, Previous) ->
    case whereis(Name) of
        Pid when is_pid(Pid), Pid =/= Previous -> Pid;
        _ -> timer:sleep(1), wait_for_restart(Name, Previous)
    end.

section11_otp() ->
    title(11, "OTP: gen_server and supervisor"),
    %% A supervisor reports every crash of a child to the logger; the tour keeps it quiet.
    logger:set_primary_config(level, none),

    %% The supervisor starts the counter server and watches over it.
    {ok, Supervisor} = supervisor:start_link(?MODULE, {supervisor, 100}),
    First = whereis(tour_counter),
    counter_add(5),
    counter_add(10),
    io:format("count: ~p, calls so far: ~p~n", [counter_get(), counter_calls()]),

    %% Kill the server. The supervisor notices and starts a new one, in the known initial
    %% state. The clients keep using the same name.
    exit(First, kill),
    Second = wait_for_restart(tour_counter, First),
    io:format("after the crash: a new process: ~p, count: ~p, calls so far: ~p~n",
              [Second =/= First, counter_get(), counter_calls()]),
    io:format("~p~n", [supervisor:count_children(Supervisor)]),

    %% Stopping the supervisor stops its children first.
    unlink(Supervisor),
    Monitor = monitor(process, Supervisor),
    exit(Supervisor, shutdown),
    receive {'DOWN', Monitor, process, Supervisor, Reason} -> ok end,
    io:format("the supervisor ended with ~p; the server is gone: ~p~n",
              [Reason, whereis(tour_counter) =:= undefined]),
    logger:set_primary_config(level, notice).

%% =================================================================================================
%%  12. ETS and other shared state
%% =================================================================================================

section12_ets() ->
    title(12, "ETS and other shared state"),

    %% An ETS table lives outside the process heaps, and many processes can read and write
    %% it. It holds tuples, and one element of each is the key. C#: ConcurrentDictionary
    Table = ets:new(people, [set, public]),         % also ordered_set, bag, duplicate_bag
    true = ets:insert(Table, {ann, 31, "Munich"}),
    true = ets:insert(Table, [{bob, 27, "Berlin"}, {cid, 45, "Munich"}]),
    io:format("~p ~p ~p~n", [ets:lookup(Table, bob), ets:lookup(Table, nobody),
                             ets:info(Table, size)]),
    io:format("~p~n", [ets:update_counter(Table, ann, {2, 1})]),     % element 2, plus 1

    %% Queries are patterns: '_' fits anything, '$1' picks a part out.
    io:format("~p~n", [lists:sort(ets:match(Table, {'$1', '_', "Munich"}))]),
    %% A match specification adds conditions: {Pattern, Guards, Result}.
    OverThirty = ets:select(Table, [{{'$1', '$2', '_'}, [{'>', '$2', 30}], ['$1']}]),
    io:format("~p~n", [lists:sort(OverThirty)]),
    true = ets:delete(Table, bob),
    io:format("~p~n", [lists:sort(ets:tab2list(Table))]),
    true = ets:delete(Table),                       % a table also disappears with its owner

    %% persistent_term: global values that are read very often and changed almost never.
    persistent_term:put({?MODULE, settings}, #{retries => 3}),
    #{retries := Retries} = persistent_term:get({?MODULE, settings}),
    persistent_term:erase({?MODULE, settings}),

    %% counters and atomics: arrays of integers that are updated in place.
    %% C#: Interlocked on a long[]
    Hits = counters:new(2, []),
    counters:add(Hits, 1, 5),
    counters:add(Hits, 2, 7),
    io:format("~p ~p ~p~n", [Retries, counters:get(Hits, 1), counters:get(Hits, 2)]).

%% =================================================================================================
%%  13. The runtime system
%% =================================================================================================

section13_runtime() ->
    title(13, "The runtime system"),

    %% The virtual machine, BEAM, runs one scheduler thread per core and switches between
    %% processes after a fixed amount of work, so that no process can hog a core. Every
    %% process has its own heap and is garbage-collected alone: there are no global pauses.
    io:format("OTP release ~s, ~p scheduler(s)~n",
              [erlang:system_info(otp_release), erlang:system_info(schedulers)]),

    %% Processes are cheap: twenty thousand of them, each waiting for a message.
    Before = erlang:system_info(process_count),
    Sleepers = [spawn(fun() -> receive stop -> ok end end) || _ <- lists:seq(1, 20000)],
    io:format("~p more processes are alive~n", [erlang:system_info(process_count) - Before]),
    lists:foreach(fun(Sleeper) -> Sleeper ! stop end, Sleepers),
    {message_queue_len, Waiting} = process_info(self(), message_queue_len),
    io:format("messages waiting in this mailbox: ~p~n", [Waiting]),

    %% Code is data: scan, parse and evaluate a string at run time.
    %% C#: the Roslyn scripting API
    {ok, Tokens, _} = erl_scan:string("lists:sum([X * X || X <- [1, 2, 3]])."),
    {ok, Expressions} = erl_parse:parse_exprs(Tokens),
    {value, Value, _} = erl_eval:exprs(Expressions, erl_eval:new_bindings()),
    io:format("evaluated from a string: ~p~n", [Value]),

    %% Hot code loading. Two versions of a module can be loaded at once; a process moves to
    %% the new one when it makes a fully qualified call such as ?MODULE:loop(State). A
    %% running system is upgraded without being stopped.
    %%
    %% Distribution. Nodes that are started with a name form a cluster, and the same
    %% primitives work across machines:
    %%     erl -sname a                      % in one terminal
    %%     erl -sname b                      % in another
    %%     net_adm:ping('a@host').           % connect
    %%     {tour_echo, 'a@host'} ! Message.  % send to a registered process on the other node
    %%     erpc:call('a@host', lists, sum, [[1, 2, 3]]).
    io:format("this node: ~p, alive as a part of a cluster: ~p~n", [node(), is_alive()]).

%% =================================================================================================
%%  14. The newest
%% =================================================================================================

section14_newest() ->
    title(14, "The newest"),

    %% Additions of the last releases that Erlang/OTP 25 already has.
    io:format("~p ~p ~p~n", [lists:enumerate([a, b, c]), lists:uniq([1, 2, 1, 3, 2]),
                             binary:encode_hex(<<255, 0, 171>>)]),
    Groups = maps:groups_from_list(fun(N) -> N rem 3 end, lists:seq(1, 10)),
    io:format("~p~n", [lists:sort(maps:to_list(Groups))]),

    %% Newer than the release this file was verified with, and therefore NOT compiled here:
    %%
    %%   the maybe expression — behind a feature flag in OTP 25 and 26, standard since 27.
    %%   It chains steps that return {ok, Value} and stops at the first that does not:
    %%       maybe
    %%           {ok, A} ?= parse_age("42"),
    %%           {ok, B} ?= parse_age("abc"),
    %%           {ok, A + B}
    %%       else
    %%           {error, Reason} -> {error, Reason}
    %%       end
    %%
    %%   26 (2023)   map comprehensions:   #{Key => Value * 2 || Key := Value <- Map}
    %%   27 (2024)   triple-quoted strings; sigils such as ~b"a binary" and ~s"a string";
    %%               -doc attributes for documentation; the json module
    %%   28 (2025)   strict generators that fail on a mismatch:  [X || {ok, X} <:- List]
    %%               zip generators:  [A + B || A <- [1, 2, 3] && B <- [4, 5, 6]]
    %%               priority messages; nominal types declared with -nominal
    %%   29 (2026)   native records (experimental): records as a data type of their own
    %%               instead of tuples in disguise
    io:format("the newer syntax: see the comments in the source~n").
