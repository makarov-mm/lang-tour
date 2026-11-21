-- =================================================================================================
--  HASKELL FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
--
--  Run:
--
--      runghc haskell_tour.hs
--
--  or compile it first:
--
--      ghc -O2 haskell_tour.hs && ./haskell_tour
--
--  Verified with GHC 9.4.7 on Linux, both ways, without warnings under -Wall. Only libraries
--  that come with the compiler are used (base, containers, mtl, stm, text). What GHC 9.6 to
--  9.14 added is listed in section 14 as comments that were NOT compiled.
--
--  How to read. Go from top to bottom: each section is an IO action that prints what it
--  demonstrates, with the definitions it needs just above it; main, at the very end, runs the
--  sections in order. A "C#:" note gives the closest counterpart in C#. A line that is
--  commented out and followed by an error does not compile, and that is the point.
--
--  The main differences from C# to keep in mind from the first line:
--
--   1. There are no statements and no variables that change. `x = 5` is a definition, an
--      equation that holds forever; a program is one big expression.
--   2. A function is applied by writing its arguments after it: `f x y`, not f(x, y).
--      Application binds tighter than any operator: `f x + 1` means (f x) + 1.
--   3. Every function takes ONE argument. `add 1 2` is `(add 1) 2`: add 1 is a function.
--      Leaving arguments out ("partial application") is everyday style.
--   4. Evaluation is lazy: an expression is computed when its value is needed, and at most
--      once. Infinite lists are fine; the order of the lines is not the order of execution.
--   5. Functions are pure: the same arguments give the same result, and nothing else
--      happens. Input and output are values of the type IO a, and the type of a function
--      says whether it can perform them.
--   6. Types are inferred, and signatures are checked documentation. There are no implicit
--      conversions at all, not even from Int to Double.
--   7. There is no null. A value that may be missing has the type Maybe a, a computation
--      that may fail has Either error a, and the compiler makes the caller look.
--   8. Data types are algebraic: a type lists its alternatives, functions take them apart
--      by pattern matching, and the compiler checks that no alternative is forgotten.
--   9. A type class is not a class. It is closer to an interface that is implemented
--      outside the type and chosen at compile time — also by the type of the RESULT.
--  10. Layout is syntax: indentation delimits blocks, as in Python.
--
--  Contents:
--    1. Basics: values, types, operators            8. Maps, sets and text
--    2. Functions                                   9. Laziness
--    3. Lists                                      10. More of the type system
--    4. Algebraic data types                       11. State without mutation
--    5. Type classes                               12. Concurrency and STM
--    6. Functor, Applicative, Monad                13. A parser from scratch
--    7. IO, mutable references, exceptions         14. The newest
-- =================================================================================================

-- Language extensions are switched on per file. GHC2021 is the modern default set; the others
-- are explained where they are used.
{-# LANGUAGE GHC2021 #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE LinearTypes #-}
{-# LANGUAGE MultiWayIf #-}
{-# LANGUAGE OverloadedRecordDot #-}
{-# LANGUAGE TypeFamilies #-}

-- A file is a module, and a program is the module Main with a value called main.
module Main (main) where

-- Imports name what they bring in, or are qualified. C#: using, using static, using alias
import Control.Applicative (Alternative (..))
import Control.Concurrent (forkIO)
import Control.Concurrent.MVar (modifyMVar_, newEmptyMVar, newMVar, putMVar, readMVar, takeMVar)
import Control.Concurrent.STM
  (atomically, check, modifyTVar', newTVarIO, readTVar, readTVarIO, writeTVar)
import Control.Exception (ArithException, Exception, catch, evaluate, finally, throwIO, try)
import Control.Monad (forM_, replicateM_, unless, void, when)
import Control.Monad.IO.Class (liftIO)
import Control.Monad.State
  (State, StateT, evalState, evalStateT, execState, get, modify, put, runState)
import Data.Char (isDigit, isSpace, toUpper)
import Data.IORef (modifyIORef', newIORef, readIORef)
import Data.Kind (Type)
import Data.List qualified as List
import Data.Map.Strict qualified as Map
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import Data.Monoid (Sum (..))
import Data.Ord (Down (..), comparing)
import Data.Set qualified as Set
import Data.Text qualified as T
import Text.Read (readMaybe)

title :: Int -> String -> IO ()
title number text = putStrLn ("\n=== " ++ show number ++ ". " ++ text ++ " ===")

-- Prints the pieces of a line separated by blanks.
line :: [String] -> IO ()
line = putStrLn . unwords

-- =================================================================================================
--  1. Basics: values, types, operators
-- =================================================================================================

-- A top-level definition: a name, a type signature, an equation. C#: a static readonly field
answer :: Int
answer = 42

section01Basics :: IO ()
section01Basics = do
  title 1 "Basics: values, types, operators"

  -- let introduces local definitions. They are not variables: nothing is assigned later.
  let count = 5 :: Int -- a machine integer. C#: long
      big = 2 ^ (100 :: Int) :: Integer -- an integer without limit. C#: BigInteger
      price = 19.99 :: Double
      letter = 'A' -- Char
      done = True -- Bool
      greeting = "World" -- String, which is a list of Char
  -- show turns a value into text. C#: ToString
  line [show count, show big, show price, show letter, show done, greeting, show answer]

  -- Arithmetic. div and mod are for integers, / is for fractional types, ^ takes an integer
  -- power and ** a fractional one.
  line
    [ show (7 `div` 2 :: Int)
    , show (7 `mod` 3 :: Int)
    , show (7 / 2 :: Double)
    , show (2 ^ (10 :: Int) :: Int)
    , show (2 ** 0.5 :: Double)
    ]
  -- There are NO implicit conversions between numeric types.
  -- count / 2            error: No instance for (Fractional Int) arising from a use of '/'
  -- round goes to the EVEN neighbour when the value is exactly halfway.
  line
    [ show (fromIntegral count / 2 :: Double)
    , show (round (2.5 :: Double) :: Int)
    , show (round (3.5 :: Double) :: Int)
    , show (truncate (2.7 :: Double) :: Int)
    ]

  -- Comparison and logic. "Not equal" is /=. if is an expression, and else is mandatory.
  line
    [ show (count == 5)
    , show (count /= 6)
    , show (count > 3 && not done)
    , if count > 3 then "big" else "small"
    ]

  -- Strings: ++ concatenates, show and read convert.
  line
    [ "Hello, " ++ greeting ++ "!"
    , show (length greeting)
    , show (read "42" + 1 :: Int)
    , show (words "a b  c")
    , map toUpper greeting
    ]

  -- A function is applied without parentheses or commas; backticks turn a function of two
  -- arguments into an operator, and parentheses turn an operator into a function.
  line [show (max 3 (7 :: Int)), show (10 `max` (3 :: Int)), show ((+) 1 (2 :: Int))]

  -- A tuple groups a fixed number of values of any types. C#: ValueTuple
  let pair = (count, greeting)
  line [show pair, show (fst pair), snd pair]

-- =================================================================================================
--  2. Functions
-- =================================================================================================

-- The signature reads: "takes an Int and returns a function that takes an Int and returns
-- an Int". C#: Func<int, Func<int, int>>
add :: Int -> Int -> Int
add x y = x + y

-- Several equations with patterns: the first one that fits is used.
factorial :: Integer -> Integer
factorial 0 = 1
factorial n = n * factorial (n - 1)

-- Guards choose by conditions, and where adds local definitions that all of them can see.
classify :: Int -> String
classify n
  | n < 0 = "negative"
  | n == 0 = "zero"
  | even n && n > limit = "big-and-even"
  | otherwise = "positive"
  where
    limit = 100

-- A higher-order function. The lower-case `a` is a type variable: twice works for every type.
-- C#: static T Twice<T>(Func<T, T> f, T x)
twice :: (a -> a) -> a -> a
twice f x = f (f x)

section02Functions :: IO ()
section02Functions = do
  title 2 "Functions"

  line [show (add 2 3), show (factorial 25), unwords (map classify [-5, 0, 7, 200])]

  -- Partial application: fewer arguments give a function that waits for the rest.
  let increment = add 1
      double = (* 2) :: Int -> Int -- a "section": an operator with one side filled in
      halve = (/ 2) :: Double -> Double
  line [show (increment 41), show (double 21), show (halve 5)]

  -- A lambda. C#: x => x * x
  let square = \x -> x * x :: Int
  line [show (square 12), show (map (\x -> x * x + 1) [1, 2, 3 :: Int])]

  -- (.) composes two functions, right to left. ($) is application with the lowest
  -- precedence: it replaces the parentheses around everything to its right.
  let process = show . (+ 1) . (* 2) :: Int -> String
  line [process 20, show (twice (* 3) (7 :: Int)), show $ sum $ map (* 2) [1, 2, 3 :: Int]]

  -- Functions over lists. C#: Select, Where, Aggregate, Zip
  line
    [ show (map (* 2) [1, 2, 3 :: Int])
    , show (filter even [1 .. 10 :: Int])
    , show (foldr (+) 0 [1 .. 10 :: Int])
    , show (zipWith (+) [1, 2, 3] [10, 20, 30 :: Int])
    ]

  -- A definition can leave its last argument out ("point-free"): these two are the same.
  let total xs = sum (map abs xs) :: Int
      total' = sum . map abs :: [Int] -> Int
  line [show (total [-1, 2, -3]), show (total' [-1, 2, -3])]

-- =================================================================================================
--  3. Lists
-- =================================================================================================

-- A list is either empty, [], or an element in front of a list, x : rest. Functions take
-- it apart with exactly these two patterns. C#: an immutable linked list, not an array
describeList :: Show a => [a] -> String
describeList [] = "empty"
describeList [x] = "one element, " ++ show x
describeList (x : rest) = "starts with " ++ show x ++ " and has " ++ show (length rest) ++ " more"

-- Recursion over that structure replaces loops.
sumList :: [Int] -> Int
sumList [] = 0
sumList (x : rest) = x + sumList rest

section03Lists :: IO ()
section03Lists = do
  title 3 "Lists"

  let numbers = [1 .. 10] :: [Int]
  line [describeList numbers, "|", describeList "x", "|", describeList ([] :: [Int])]
  line
    [ show (0 : numbers)
    , show (numbers ++ [11, 12])
    , show (numbers !! 2)
    , show (length numbers)
    , show (sumList numbers)
    ]
  line
    [ show (take 3 numbers)
    , show (drop 7 numbers)
    , show (reverse numbers)
    , show (5 `elem` numbers)
    , show (maximum numbers)
    , show (product numbers)
    ]
  line
    [ show (zip [1, 2, 3 :: Int] "abc")
    , show (span even [2, 4, 5, 6 :: Int])
    , show (takeWhile (< 4) numbers)
    , show (concat [[1], [2, 3], [4 :: Int]])
    ]

  -- Ranges and list comprehensions. C#: LINQ query syntax
  line [show [2, 4 .. 20 :: Int], show ['a' .. 'f'], show [10, 8 .. 1 :: Int]]
  line
    [ show [x * x | x <- numbers, even x]
    , show [(x, y) | x <- [1, 2 :: Int], y <- "ab"]
    , show [(a, b, c) | c <- [1 .. 20 :: Int], b <- [1 .. c], a <- [1 .. b], a * a + b * b == c * c]
    ]

  -- Sorting and grouping live in Data.List.
  let people = [("Bob", 27), ("Ann", 31), ("Cid", 45)] :: [(String, Int)]
  line
    [ show (List.sort [3, 1, 2 :: Int])
    , show (map fst (List.sortOn snd people))
    , show (map fst (List.sortBy (comparing (Down . snd)) people))
    , show (map (\g -> (take 1 g, length g)) (List.group (List.sort "mississippi")))
    , List.intercalate ", " (map fst people)
    ]

  -- A String is a list of characters, so all of the above works on text.
  line [reverse "hello", filter (/= 'l') "hello", show (words "to be or not"), show (lines "a\nb")]

-- =================================================================================================
--  4. Algebraic data types
-- =================================================================================================

-- A type with alternatives. C#: an enum
data Color = Red | Green | Blue
  deriving (Show, Eq, Ord, Enum, Bounded) -- the compiler writes these instances

-- The alternatives can carry data. C#: an abstract record with a closed set of subtypes
data Shape
  = Circle Double
  | Rectangle Double Double
  | Triangle Double Double Double
  deriving (Show, Eq)

-- Pattern matching takes a value apart. With -Wall the compiler reports a missing case.
-- C#: a switch expression — which cannot promise to be complete
area :: Shape -> Double
area (Circle r) = pi * r * r
area (Rectangle w h) = w * h
area (Triangle a b c) = sqrt (s * (s - a) * (s - b) * (s - c))
  where
    s = (a + b + c) / 2

-- A record: one alternative with named fields. C#: record Person(string Name, int Age)
data Person = Person
  { personName :: String
  , personAge :: Int
  }
  deriving (Show, Eq)

-- newtype makes a new type out of an existing one at no run-time cost: the compiler keeps
-- Meters and Double apart, the machine does not. C#: a wrapper struct, but free
newtype Meters = Meters Double
  deriving (Show, Eq, Ord)

-- type only gives another name to a type. C#: a using alias
type Name = String

-- Maybe takes the place of null: a value is Nothing or Just x. C#: T?
safeDivide :: Int -> Int -> Maybe Int
safeDivide _ 0 = Nothing
safeDivide a b = Just (a `div` b)

-- Either carries a reason for the failure: Left error or Right value. C#: a Result type
parseAge :: String -> Either String Int
parseAge text = case readMaybe text of
  Nothing -> Left ("not a number: " ++ text)
  Just n
    | n < 0 || n > 150 -> Left ("out of range: " ++ show n)
    | otherwise -> Right n

-- A recursive type with a type parameter: a binary search tree. C#: class Tree<T>
data Tree a = Leaf | Node (Tree a) a (Tree a)
  deriving (Functor, Foldable) -- see sections 5 and 6

insert :: Ord a => a -> Tree a -> Tree a
insert x Leaf = Node Leaf x Leaf
insert x node@(Node left value right) -- node@ names the whole value as well
  | x < value = Node (insert x left) value right
  | x > value = Node left value (insert x right)
  | otherwise = node

fromList :: Ord a => [a] -> Tree a
fromList = foldr insert Leaf

toList :: Tree a -> [a]
toList Leaf = []
toList (Node left value right) = toList left ++ [value] ++ toList right

depth :: Tree a -> Int
depth Leaf = 0
depth (Node left _ right) = 1 + max (depth left) (depth right)

greet :: Name -> String
greet who = "Hello, " ++ who

section04Types :: IO ()
section04Types = do
  title 4 "Algebraic data types"

  line
    [ show [minBound .. maxBound :: Color]
    , show (succ Red)
    , show (fromEnum Blue)
    , show (Red < Blue)
    ]
  line [show (Circle 1), show (map (roundTo 2 . area) [Circle 1, Rectangle 2 3, Triangle 3 4 5])]

  -- Building, reading and "updating" a record: an update makes a new value.
  let ann = Person {personName = "Ann", personAge = 31}
      older = ann {personAge = 32}
  line [show ann, personName older, show (personAge older), show (ann == older)]
  line [greet (personName ann)]

  -- Meters 5 + 3         error: No instance for (Num Meters) arising from a use of '+'
  line [show (Meters 5), show (Meters 5 < Meters 7)]

  -- A Maybe has to be opened before its content can be used: by case, or by a helper.
  line [show (safeDivide 7 2), show (safeDivide 7 0), show (fromMaybe 0 (safeDivide 7 0))]
  line [describeQuotient (safeDivide 7 2), describeQuotient (safeDivide 7 0)]
  line [show (parseAge "42"), show (parseAge "abc"), show (parseAge "999")]
  line [either id show (parseAge "7"), either id show (parseAge "seven")]

  let tree = fromList [5, 3, 8, 1, 4, 7, 9 :: Int]
  line [show (toList tree), show (depth tree), show (toList (insert 6 tree))]
  where
    describeQuotient result = case result of
      Nothing -> "no quotient"
      Just quotient -> "the quotient is " ++ show quotient

-- Rounds to a number of decimals, for printing.
roundTo :: Int -> Double -> Double
roundTo digits x = fromIntegral (round (x * factor) :: Integer) / factor
  where
    factor = 10 ^ digits

-- =================================================================================================
--  5. Type classes
-- =================================================================================================

-- A type class declares operations, and types become instances of it — also types that
-- somebody else wrote. C#: an interface with static abstract members, implemented from outside
class Describable a where
  describe :: a -> String
  describe _ = "something" -- a default implementation
  typeName :: a -> String

instance Describable Color where
  describe color = "the color " ++ show color
  typeName _ = "Color"

instance Describable Shape where
  typeName _ = "Shape" -- describe is taken from the default

-- An instance with a condition: lists of describable things are describable.
instance Describable a => Describable [a] where
  describe items =
    show (length items) ++ " items; the first is " ++ maybe "missing" describe (listToMaybe items)
  typeName items = "list of " ++ maybe "nothing" typeName (listToMaybe items)

-- A constraint in a signature: "for every type a that can be ordered".
-- C#: where T : IComparable<T>
largest :: Ord a => [a] -> Maybe a
largest [] = Nothing
largest items = Just (maximum items)

-- An instance written by hand. Show is C#'s ToString.
instance Show a => Show (Tree a) where
  show tree = "Tree " ++ show (toList tree)

-- Semigroup and Monoid describe things that can be combined, with a neutral element.
newtype MaxOf = MaxOf Int
  deriving (Show)

instance Semigroup MaxOf where
  MaxOf a <> MaxOf b = MaxOf (max a b)

instance Monoid MaxOf where
  mempty = MaxOf minBound

section05Classes :: IO ()
section05Classes = do
  title 5 "Type classes"

  line [describe Green, "|", describe (Circle 1), "|", describe [Red, Blue]]
  line [typeName Red, "|", typeName [Circle 1]]
  line [show (largest [3, 9, 4 :: Int]), show (largest "hello"), show (largest ([] :: [Int]))]

  -- The instance can be chosen by the type of the RESULT. C# has no counterpart: there the
  -- arguments decide.
  line
    [ show (read "42" :: Int)
    , show (read "42" :: Double)
    , show (minBound :: Int)
    , show (maxBound :: Color)
    ]
  line [show (mempty :: String), show (mempty :: [Int]), show (mempty :: MaxOf)]

  -- <> combines, mconcat combines a whole list.
  line
    [ show ([1, 2] <> [3 :: Int])
    , "ab" <> "cd"
    , show (mconcat (map MaxOf [3, 9, 4]))
    , show (getSum (foldMap Sum [1 .. 10 :: Int]))
    ]

  -- Foldable: everything that can be folded offers sum, length, elem, maximum ... The tree
  -- got its instance from `deriving (Foldable)`. C#: IEnumerable<T>
  let tree = fromList [5, 3, 8, 1 :: Int]
  line [show tree, show (sum tree), show (length tree), show (maximum tree), show (8 `elem` tree)]
  line [show (sum (Just 5 :: Maybe Int)), show (length (Map.fromList [(1 :: Int, "a"), (2, "b")]))]

-- =================================================================================================
--  6. Functor, Applicative, Monad
-- =================================================================================================

section06Monads :: IO ()
section06Monads = do
  title 6 "Functor, Applicative, Monad"

  -- Functor: fmap (or <$>) applies a function INSIDE a structure and keeps the structure.
  -- C#: Select — for lists, but equally for Maybe, Either, a tree, a parser, an IO action
  line
    [ show (fmap (+ 1) (Just 41 :: Maybe Int))
    , show (fmap (+ 1) (Nothing :: Maybe Int))
    , show ((* 2) <$> [1, 2, 3 :: Int])
    , show (length <$> (Right "abc" :: Either String String))
    , show (fmap (* 10) (fromList [2, 1, 3 :: Int]))
    ]

  -- Applicative: <*> applies a function of several arguments to several structures.
  line
    [ show ((+) <$> Just 1 <*> Just (2 :: Int))
    , show ((+) <$> Just 1 <*> (Nothing :: Maybe Int))
    , show ((,) <$> [1, 2 :: Int] <*> "ab")
    , show (Person <$> Just "Ann" <*> Just 31)
    ]

  -- Monad: >>= feeds the result of one step into the next, which may depend on it.
  -- C#: SelectMany; ?. for nullable values; await for tasks
  line [show (safeDivide 100 5 >>= safeDivide 60), show (safeDivide 100 0 >>= safeDivide 60)]

  -- do-notation is the readable spelling of a chain of >>=. With Maybe it stops at the first
  -- Nothing, with Either at the first Left — and keeps the reason.
  let quotients a b c = do
        x <- safeDivide a b
        y <- safeDivide x c
        pure (x + y)
      ages a b = do
        x <- parseAge a
        y <- parseAge b
        pure (x + y)
  line [show (quotients 100 5 2), show (quotients 100 0 2), show (quotients 100 5 0)]
  line [show (ages "30" "12"), show (ages "30" "x"), show (ages "-1" "x")]

  -- With lists the same notation means "for every combination".
  let pairs = do
        x <- [1, 2, 3 :: Int]
        y <- "ab"
        pure (x, y)
  line [show pairs]

  -- traverse runs a step on every element and collects the results, failing as a whole.
  -- C#: Task.WhenAll for tasks; a loop with an early return for parsing
  line
    [ show (traverse parseAge ["1", "2", "3"])
    , show (traverse parseAge ["1", "x", "3"])
    , show (sequence [Just 1, Just 2 :: Maybe Int])
    , show (mapMaybe (safeDivide 12) [3, 0, 4])
    ]

-- =================================================================================================
--  7. IO, mutable references, exceptions
-- =================================================================================================

-- An exception type of our own. C#: class ValidationError : Exception
newtype ValidationError = ValidationError String
  deriving (Show)

instance Exception ValidationError

section07IO :: IO ()
section07IO = do
  title 7 "IO, mutable references, exceptions"

  -- An IO action is a VALUE that describes an effect. It can be stored, passed around and
  -- combined; it runs when it becomes a part of main. C#: a Func<Task>, not a statement
  let hello = putStrLn "  an action that was stored, and is run twice"
  hello
  hello
  sequence_ [putStr "  one", putStr " two", putStrLn " three"]
  mapM_ (putStrLn . ("  item " ++) . show) [1, 2 :: Int]
  forM_ (zip [1 :: Int ..] "ab") $ \(index, letter) ->
    putStrLn ("  " ++ show index ++ ": " ++ [letter])
  when (answer > 40) (putStrLn "  when: the answer is large")
  unless (answer > 40) (putStrLn "  unless: never printed")

  -- <- takes the result out of an action; let names a pure value.
  text <- pure "a result from an action"
  let size = length text
  line ["  " ++ text ++ ",", show size, "characters"]

  -- Mutable variables exist, but only inside IO. C#: a field
  counter <- newIORef (0 :: Int)
  replicateM_ 5 (modifyIORef' counter (+ 1))
  count <- readIORef counter
  line ["  the IORef holds", show count]

  -- Exceptions are thrown and caught in IO. try turns one into an Either.
  -- (evaluate forces a pure value at this point of the program.)
  quotient <- try (evaluate (1 `div` (count - 5))) :: IO (Either ArithException Int)
  line ["  try:", show quotient]
  invalid <- try (throwIO (ValidationError "age")) :: IO (Either ValidationError ())
  line ["  try:", show invalid]

  -- catch runs a handler, finally always runs. C#: try / catch / finally
  (putStrLn "  working" >> throwIO (ValidationError "name"))
    `catch` (\(ValidationError field) -> putStrLn ("  caught: invalid field " ++ field))
    `finally` putStrLn "  finally: always runs"

  -- Pure code signals failure with Maybe or Either. `error` exists, but a function that
  -- calls it is "partial" and best avoided.
  line ["  readMaybe:", show (readMaybe "12" :: Maybe Int), show (readMaybe "1x" :: Maybe Int)]

-- =================================================================================================
--  8. Maps, sets and text
-- =================================================================================================

section08Containers :: IO ()
section08Containers = do
  title 8 "Maps, sets and text"

  -- Data.Map is an immutable, ordered dictionary. C#: ImmutableSortedDictionary
  let ages = Map.fromList [("bob", 27), ("ann", 31)] :: Map.Map String Int
      more = Map.insert "cid" 45 ages
      changed = Map.adjust (+ 1) "ann" more
  line
    [ show (Map.lookup "ann" ages)
    , show (Map.lookup "dee" ages)
    , show (Map.findWithDefault 0 "dee" ages)
    ]
  line [show changed, show (Map.size changed), show (Map.keys changed)]
  line [show (Map.member "cid" changed), show (Map.member "cid" ages)]
  line [show (Map.toList (Map.filter (> 30) changed)), show (sum changed), show (fmap (* 2) ages)]

  -- Counting words: insertWith combines the new value with the one that is there.
  let wordsSeen = words "the quick the lazy the dog"
      count counts word = Map.insertWith (+) word (1 :: Int) counts
      frequencies = List.foldl' count Map.empty wordsSeen
  line [show frequencies]

  -- Data.Set. C#: ImmutableSortedSet
  let set = Set.fromList [3, 1, 3, 2 :: Int]
  line
    [ show set
    , show (Set.member 2 set)
    , show (Set.union set (Set.fromList [9, 1]))
    , show (Set.toList (Set.map (* 10) set))
    ]

  -- A String is a linked list of characters: simple, and slow for real text. Data.Text is
  -- a packed Unicode string. C#: string
  let text = T.pack "Hello, World"
  line
    [ show (T.length text)
    , show (T.toUpper text)
    , show (T.splitOn (T.pack ", ") text)
    , show (T.replace (T.pack "l") (T.pack "L") text)
    , T.unpack (T.strip (T.pack "  trimmed  "))
    , show (T.words (T.pack "a b  c"))
    ]

-- =================================================================================================
--  9. Laziness
-- =================================================================================================

-- An infinite list that is defined in terms of itself. Only the part that is asked for is
-- ever computed. C#: an iterator with yield return, but memoized
fibonacci :: [Integer]
fibonacci = 0 : 1 : zipWith (+) fibonacci (drop 1 fibonacci)

primes :: [Int]
primes = sieve [2 ..]
  where
    sieve [] = []
    sieve (p : rest) = p : sieve [x | x <- rest, x `mod` p /= 0]

-- Laziness has a price: a lazy accumulator grows into a chain of suspended additions. The
-- bangs make the arguments strict, so this loop runs in constant space.
mean :: [Double] -> Double
mean = go 0 0
  where
    go :: Double -> Int -> [Double] -> Double
    go !total !count [] = if count == 0 then 0 else total / fromIntegral count
    go !total !count (x : rest) = go (total + x) (count + 1) rest

section09Laziness :: IO ()
section09Laziness = do
  title 9 "Laziness"

  line [show (take 12 fibonacci), show (fibonacci !! 200)]
  line [show (take 10 primes), show (takeWhile (< 60) (dropWhile (< 40) primes))]
  line
    [ show (take 5 (map (* 2) [1 :: Int ..]))
    , show (takeWhile (< 100) (iterate (* 2) (1 :: Int)))
    , take 7 (cycle "abc")
    , show (zip [1 :: Int ..] "xyz")
    ]

  -- A value that is never needed is never computed — not even when it would fail.
  let failing = error "this is never evaluated" :: Int
  line
    [ show (fst (1 :: Int, failing))
    , show (length [failing, failing])
    , show (take 2 [1, 2, failing])
    ]

  -- The other side: strict folds and strict loops for accumulating.
  line [show (List.foldl' (+) 0 [1 .. 1000000 :: Int]), show (mean [1 .. 100000])]

  -- A definition is evaluated at most once: `squares` is computed on first use and shared.
  let squares = map (^ (2 :: Int)) [1 .. 5 :: Int]
  line [show (sum squares), show (maximum squares)]

-- =================================================================================================
--  10. More of the type system
-- =================================================================================================

-- A GADT: every constructor states which type of expression it builds. An ill-typed
-- expression such as Add (BoolE True) (IntE 1) is rejected by the compiler, and eval needs
-- no run-time checks. C#: no counterpart
data Expr :: Type -> Type where
  IntE :: Int -> Expr Int
  BoolE :: Bool -> Expr Bool
  Add :: Expr Int -> Expr Int -> Expr Int
  Equal :: Expr Int -> Expr Int -> Expr Bool
  If :: Expr Bool -> Expr a -> Expr a -> Expr a

eval :: Expr a -> a
eval (IntE n) = n
eval (BoolE b) = b
eval (Add a b) = eval a + eval b
eval (Equal a b) = eval a == eval b
eval (If condition yes no) = if eval condition then eval yes else eval no

-- DataKinds lifts values into types: here the length of a vector is a part of its type.
data Nat = Zero | Succ Nat

data Vec (n :: Nat) a where
  VNil :: Vec 'Zero a
  VCons :: a -> Vec n a -> Vec ('Succ n) a

-- Only a vector with at least one element is accepted, so no check for "empty" is needed.
-- vhead VNil           error: Couldn't match type 'Zero with 'Succ n
vhead :: Vec ('Succ n) a -> a
vhead (VCons x _) = x

vtoList :: Vec n a -> [a]
vtoList VNil = []
vtoList (VCons x rest) = x : vtoList rest

-- A phantom type: the parameter occurs only in the type, and keeps units apart.
newtype Distance unit = Distance Double
  deriving (Show)

data Kilometers

data Miles

addDistance :: Distance unit -> Distance unit -> Distance unit
addDistance (Distance a) (Distance b) = Distance (a + b)

toMiles :: Distance Kilometers -> Distance Miles
toMiles (Distance kilometers) = Distance (kilometers * 0.621371)

-- A type family: a function from types to types. Elem says what a container contains.
class Container f where
  type Elem f :: Type
  emptyC :: f
  insertC :: Elem f -> f -> f
  toListC :: f -> [Elem f]

instance Container [a] where
  type Elem [a] = a
  emptyC = []
  insertC = (:)
  toListC = id

instance Ord a => Container (Set.Set a) where
  type Elem (Set.Set a) = a
  emptyC = Set.empty
  insertC = Set.insert
  toListC = Set.toList

fill :: Container f => [Elem f] -> f
fill = foldr insertC emptyC

-- An existential type hides the concrete type and keeps only the class.
-- C#: a variable of an interface type
data AnyDescribable = forall a. Describable a => AnyDescribable a

-- A rank-2 type: the ARGUMENT has to be polymorphic itself. C#: no counterpart
applyToBoth :: (forall x. [x] -> Int) -> ([Int], String) -> (Int, Int)
applyToBoth f (xs, ys) = (f xs, f ys)

section10TypeSystem :: IO ()
section10TypeSystem = do
  title 10 "More of the type system"

  let expression = If (Equal (Add (IntE 1) (IntE 2)) (IntE 3)) (IntE 10) (IntE 20)
  line [show (eval expression), show (eval (Equal (IntE 1) (IntE 2)))]

  let vector = VCons 'a' (VCons 'b' (VCons 'c' VNil))
  line [show (vhead vector), vtoList vector]

  let trip = addDistance (Distance 10) (Distance 32.2) :: Distance Kilometers
  line [show trip, show (toMiles trip)]
  -- addDistance trip (toMiles trip)      error: Couldn't match type 'Miles' with 'Kilometers'

  line
    [ show (toListC (fill [3, 1, 3, 2] :: [Int]))
    , show (toListC (fill [3, 1, 3, 2] :: Set.Set Int))
    ]

  let things = [AnyDescribable Red, AnyDescribable (Circle 1), AnyDescribable [Blue]]
  line [List.intercalate "; " [describe thing | AnyDescribable thing <- things]]
  line [show (applyToBoth length ([1, 2, 3], "ab"))]

-- =================================================================================================
--  11. State without mutation
-- =================================================================================================

-- State s a is a computation that reads and replaces a state of type s on its way to a
-- result of type a. Underneath it is a pure function s -> (a, s); do-notation hides the
-- plumbing. C#: passing the state in and out by hand, or a mutable field
labelTree :: Tree a -> State Int (Tree (Int, a))
labelTree Leaf = pure Leaf
labelTree (Node left value right) = do
  left' <- labelTree left
  number <- get
  put (number + 1)
  right' <- labelTree right
  pure (Node left' (number, value) right')

-- A stack, as two operations on a state.
push :: Int -> State [Int] ()
push x = modify (x :)

pop :: State [Int] (Maybe Int)
pop = do
  stack <- get
  case stack of
    [] -> pure Nothing
    (x : rest) -> do
      put rest
      pure (Just x)

-- A monad transformer adds one effect to another monad: StateT Int IO has a state AND can
-- do input and output.
countLines :: [String] -> StateT Int IO ()
countLines items = forM_ items $ \item -> do
  modify (+ 1)
  number <- get
  liftIO (putStrLn ("  " ++ show number ++ ". " ++ item))

section11State :: IO ()
section11State = do
  title 11 "State without mutation"

  let tree = fromList "dbfaceg"
  line [show (toList (evalState (labelTree tree) 1))]

  let program = do
        push 1
        push 2
        push 3
        top <- pop
        next <- pop
        pure (top, next)
  line [show (runState program []), show (execState (mapM_ push [1, 2, 3]) [0])]

  evalStateT (countLines ["first", "second", "third"]) 0

-- =================================================================================================
--  12. Concurrency and STM
-- =================================================================================================

section12Concurrency :: IO ()
section12Concurrency = do
  title 12 "Concurrency and STM"

  -- forkIO starts a lightweight thread; thousands of them are normal. An MVar is a box that
  -- is either full or empty: a lock and a one-place channel in one.
  -- C#: Task.Run, and a Channel or a TaskCompletionSource for the result
  results <- newEmptyMVar
  forM_ [1 .. 4 :: Int] $ \worker -> forkIO $ do
    let total = sum [1 .. worker * 100000]
    putMVar results (worker, total)
  collected <- mapM (const (takeMVar results)) [1 .. 4 :: Int]
  line [show (List.sort collected)]

  -- A shared counter behind an MVar. C#: lock
  counter <- newMVar (0 :: Int)
  finished <- newEmptyMVar
  forM_ [1 .. 8 :: Int] $ \_ -> forkIO $ do
    replicateM_ 1000 (modifyMVar_ counter (pure . (+ 1)))
    putMVar finished ()
  replicateM_ 8 (takeMVar finished)
  total <- readMVar counter
  line ["8 threads, 1000 increments each:", show total]

  -- Software transactional memory: a block inside `atomically` runs as one transaction,
  -- and transactions compose. `check` waits until a condition holds, without a loop and
  -- without a lock. C#: no counterpart
  source <- newTVarIO (100 :: Int)
  target <- newTVarIO (0 :: Int)
  let transfer amount = atomically $ do
        balance <- readTVar source
        check (balance >= amount)
        writeTVar source (balance - amount)
        modifyTVar' target (+ amount)
  done <- newEmptyMVar
  forM_ [1 .. 10 :: Int] $ \_ -> forkIO (transfer 10 >> putMVar done ())
  replicateM_ 10 (takeMVar done)
  balances <- (,) <$> readTVarIO source <*> readTVarIO target
  line ["after ten transfers of 10:", show balances]

-- =================================================================================================
--  13. A parser from scratch
-- =================================================================================================

-- A parser is a function from the input to maybe a result and the rest of the input.
-- Wrapped in a newtype it becomes a Functor, an Applicative, a Monad and an Alternative,
-- and from then on small parsers combine into big ones with the operators of sections 5
-- and 6. C#: the same idea as parser-combinator libraries such as Sprache or Pidgin
newtype Parser a = Parser {runParser :: String -> Maybe (a, String)}

instance Functor Parser where
  fmap f (Parser p) = Parser $ \input -> case p input of
    Nothing -> Nothing
    Just (value, rest) -> Just (f value, rest)

instance Applicative Parser where
  pure value = Parser $ \input -> Just (value, input)
  Parser pf <*> Parser pa = Parser $ \input -> case pf input of
    Nothing -> Nothing
    Just (f, rest) -> case pa rest of
      Nothing -> Nothing
      Just (value, rest') -> Just (f value, rest')

instance Monad Parser where
  Parser p >>= f = Parser $ \input -> case p input of
    Nothing -> Nothing
    Just (value, rest) -> runParser (f value) rest

-- Alternative: `empty` fails, and <|> tries the second parser when the first one fails.
-- It also provides many (zero or more) and some (one or more).
instance Alternative Parser where
  empty = Parser (const Nothing)
  Parser p <|> Parser q = Parser $ \input -> case p input of
    Nothing -> q input
    success -> success

satisfy :: (Char -> Bool) -> Parser Char
satisfy predicate = Parser $ \case -- \case: a lambda that matches on its argument
  (c : rest) | predicate c -> Just (c, rest)
  _ -> Nothing

spaces :: Parser ()
spaces = void (many (satisfy isSpace))

symbol :: Char -> Parser Char
symbol c = satisfy (== c) <* spaces -- <* keeps the left result and skips the right one

natural :: Parser Int
natural = read <$> some (satisfy isDigit) <* spaces

-- The grammar, almost as one would write it on paper:
--     expr = term { ('+' | '-') term }
--     term = atom { ('*' | '/') atom }
--     atom = natural | '(' expr ')'
expr :: Parser Int
expr = do
  first <- term
  rest <- many ((,) <$> (symbol '+' <|> symbol '-') <*> term)
  pure (List.foldl' apply first rest)
  where
    apply total ('+', x) = total + x
    apply total (_, x) = total - x

term :: Parser Int
term = do
  first <- atom
  rest <- many ((,) <$> (symbol '*' <|> symbol '/') <*> atom)
  pure (List.foldl' apply first rest)
  where
    apply total ('*', x) = total * x
    apply total (_, x) = total `div` x

atom :: Parser Int
atom = natural <|> (symbol '(' *> expr <* symbol ')')

calculate :: String -> Maybe Int
calculate input = case runParser (spaces *> expr) input of
  Just (value, "") -> Just value
  _ -> Nothing

section13Parser :: IO ()
section13Parser = do
  title 13 "A parser from scratch"

  forM_ ["1 + 2 * 3", "(1 + 2) * 3", " 2 * (3 + 4) - 10 / 2 ", "2 * (3 + ", "7 7"] $ \input ->
    putStrLn ("  " ++ show input ++ " -> " ++ maybe "a syntax error" show (calculate input))

-- =================================================================================================
--  14. The newest
-- =================================================================================================

-- OverloadedRecordDot (GHC 9.2): fields are read with a dot, as in C#.
data Config = Config
  { host :: String
  , port :: Int
  }

-- LinearTypes (GHC 9.0): an argument behind %1 -> has to be used exactly once.
-- C#: no counterpart; ownership in Rust is the nearest idea
swapOnce :: (a, b) %1 -> (b, a)
swapOnce (x, y) = (y, x)

section14Newest :: IO ()
section14Newest = do
  title 14 "The newest"

  let config = Config {host = "localhost", port = 8080}
  line [config.host ++ ":" ++ show config.port, show (swapOnce (1 :: Int, "one"))]

  -- \cases (GHC 9.4): a lambda with several clauses and several arguments.
  let combine :: Int -> Int -> String
      combine = \cases
        0 _ -> "zero first"
        _ 0 -> "zero second"
        a b -> show (a + b)
  line [combine 0 5, "|", combine 5 0, "|", combine 2 3]

  -- From GHC2021 (GHC 9.2): type applications, digit separators, binary literals.
  line [show (read @Int "42"), show (maxBound @Int), show (1_000_000 :: Int), show (0b1010 :: Int)]

  -- MultiWayIf: guards without a function around them.
  let size = length config.host
      verdict =
        if
          | size > 20 -> "long"
          | size > 5 -> "medium"
          | otherwise -> "short"
  line [verdict]

  -- Newer than the compiler this file was verified with, and therefore NOT compiled here:
  --   9.6  (2023)   TypeData: `type data` declares types without values
  --   9.8  (2023)   ExtendedLiterals (123#Int8), TypeAbstractions
  --   9.10 (2024)   the language edition GHC2024; RequiredTypeArguments: sizeOf (type Int)
  --   9.12 (2024)   MultilineStrings, with three double quotes around the text;
  --                 OrPatterns:  case color of (Red; Green) -> "warm"; Blue -> "cold";
  --                 NamedDefaults
  --   9.14 (2025)   the first long-term-support series of the compiler; SPECIALISE pragmas
  --                 that take type applications
  putStrLn "the newer extensions: see the comments in the source"

-- =================================================================================================
--  main: the action that the runtime performs. C#: Main
-- =================================================================================================

main :: IO ()
main = do
  section01Basics
  section02Functions
  section03Lists
  section04Types
  section05Classes
  section06Monads
  section07IO
  section08Containers
  section09Laziness
  section10TypeSystem
  section11State
  section12Concurrency
  section13Parser
  section14Newest
