// =================================================================================================
//  DELPHI FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
//
//  Delphi is Object Pascal. Its first architect, Anders Hejlsberg, went on to design C#, and it
//  shows: properties, events, exceptions with try / finally, one root class for everything.
//  What differs most is the syntax and the memory model: there is no garbage collector.
//
//  Build and run:
//
//      Delphi:        dcc64 delphi_tour.dpr      (or dcc32, or open the file in the IDE: F9)
//      Free Pascal:   fpc delphi_tour.dpr && ./delphi_tour
//
//  Verified with Free Pascal 3.2.2 on Linux, which compiles this file in its Delphi mode. A
//  Delphi compiler was NOT available: the file keeps to the language that both compilers
//  share (it should need Delphi XE7 or later), and what only Delphi has — anonymous methods,
//  inline variables, attributes, the newest syntax — is shown in comments that say so.
//
//  How to read. Go from top to bottom: each section is a procedure that prints what it
//  demonstrates, with the types it needs declared just above it; the main block at the very
//  end calls the sections in order. A "C#:" note gives the closest counterpart in C#.
//
//  The main differences from C# to keep in mind from the first line:
//
//   1. Declarations are kept apart from statements: the variables of a routine are listed in
//      a var block before its begin, types in type blocks, and everything has to be declared
//      above the place where it is used.
//   2. := assigns, = compares, <> is "not equal". A block is begin ... end, a semicolon
//      SEPARATES statements, and names are case-insensitive.
//   3. There is no garbage collector. An object lives from Create until Free is called, and
//      the idiom is try ... finally Obj.Free; end. Strings, dynamic arrays and interfaces
//      are reference counted and clean up after themselves.
//   4. A string is mutable, has value semantics (copy on write), and its characters are
//      numbered from 1.
//   5. A function returns by assigning to Result; Exit leaves a routine (C#: return).
//   6. and, or, not are logical AND bitwise operators, and they bind tighter than
//      comparisons: (A > 0) and (B > 0) needs its parentheses.
//   7. / always produces a floating-point value; integers divide with div and mod.
//   8. Integer overflow and array bounds are checked only where the code asks for it with
//      {$Q+} and {$R+}.
//   9. private means "private to the unit (the file)"; strict private is C#'s private.
//
//  Contents:
//    1. Basics: variables, types, operators          9. Interfaces and reference counting
//    2. Control flow                                10. Generics and collections
//    3. Routines: procedures and functions          11. Exceptions and compiler checks
//    4. Strings                                     12. Procedural types, method pointers, events
//    5. Arrays, sets, enumerations, subranges       13. Helpers, RTTI, pointers
//    6. Records                                     14. Streams and threads
//    7. Classes and object lifetime                 15. Units, and the newest
//    8. Inheritance and class references
// =================================================================================================

program delphi_tour;

// Compiler directives are comments that start with a dollar sign. C#: #if, #pragma
{$IFDEF FPC}
  {$mode delphi}                        // Free Pascal: compile the Delphi dialect
  {$WARN 4046 OFF}                      // three messages that come from inside Free Pascal's
  {$WARN 5071 OFF}                      // own Generics.Collections unit, not from this file
  {$WARN 6058 OFF}
{$ENDIF}
{$IFDEF MSWINDOWS}
  {$APPTYPE CONSOLE}                    // a console program, not a GUI one
{$ENDIF}

// uses imports units. C#: using. Delphi spells the library units with a namespace prefix.
uses
{$IFDEF FPC}
  {$IFDEF UNIX}cthreads,{$ENDIF}        // Free Pascal on Unix: needed first for threads
  SysUtils, Classes, Math, TypInfo, SyncObjs, Generics.Collections, Generics.Defaults;
{$ELSE}
  System.SysUtils, System.Classes, System.Math, System.TypInfo, System.SyncObjs,
  System.Generics.Collections, System.Generics.Defaults;
{$ENDIF}

procedure Title(Number: Integer; const Text: string);
begin
  WriteLn;
  WriteLn('=== ', Number, '. ', Text, ' ===');
end;

// =================================================================================================
//  1. Basics: variables, types, operators
// =================================================================================================

const
  Answer = 42;                          // a constant. C#: const int Answer = 42;
  Tau: Double = 6.283185307179586;      // a constant with an explicit type

procedure Section01_Basics;
var                                     // every local variable is declared here, before begin
  Count: Integer;                       // 32 bits. C#: int
  Big: Int64;                           // C#: long
  Small: Byte;                          // also ShortInt, SmallInt, Word, Cardinal, UInt64
  Ratio: Double;                        // C#: double; Single is float
  Price: Currency;                      // fixed point with four decimals, for money
  Letter: Char;
  Done: Boolean;
  Name: string;
begin
  Title(1, 'Basics: variables, types, operators');

  Count := 5;                           // := assigns
  Big := 9000000000;
  Small := 255;
  Ratio := 2.5;
  Price := 19.99;
  Letter := 'A';                        // characters and strings both use single quotes
  Done := True;
  Name := 'World';
  // WriteLn takes any number of arguments; Value:Width:Decimals formats a number.
  WriteLn(Count, ' ', Big, ' ', Small, ' ', Ratio:0:2, ' ', Price:0:2, ' ', Letter, ' ', Done);
  WriteLn('Answer ', Answer, ', Tau ', Tau:0:3, ', $FF = ', $FF, ', Hello, ' + Name + '!');

  // Names are case-insensitive: this is the variable declared above.
  COUNT := count + 2;

  // Arithmetic. / always gives a floating-point value; integers divide with div and mod.
  WriteLn('7 / 2 = ', (Count / 2):0:1, ', 7 div 2 = ', Count div 2, ', 7 mod 3 = ', Count mod 3);
  // There is no ++ and no +=. Inc and Dec take their place.
  Inc(Count);
  Dec(Count, 3);
  WriteLn('after Inc and Dec(.., 3): ', Count);

  // = compares and <> means "not equal". and, or, xor, not work on Booleans and on the bits
  // of integers, and they bind tighter than comparisons — hence the parentheses.
  WriteLn('(Count = 5) and (Ratio > 1): ', (Count = 5) and (Ratio > 1));
  WriteLn('12 and 10 = ', 12 and 10, ', 12 or 10 = ', 12 or 10, ', 12 xor 10 = ', 12 xor 10,
    ', 1 shl 4 = ', 1 shl 4);
  // if Count = 5 and Ratio > 1 then ...
  //     does not compile: it is read as Count = (5 and Ratio) > 1
  // Boolean expressions short-circuit, as in C#.

  // Conversions. An integer becomes a float implicitly; the other way needs Trunc or Round.
  // Round goes to the EVEN neighbour when the value is exactly halfway.
  WriteLn('Trunc(2.7) = ', Trunc(2.7), ', Round(2.5) = ', Round(2.5), ', Round(3.5) = ',
    Round(3.5));
  WriteLn('IntToStr(42) + ''!'' = ', IntToStr(42) + '!', ', StrToInt(''42'') + 1 = ',
    StrToInt('42') + 1, ', Ord(''A'') = ', Ord(Letter), ', Chr(66) = ', Chr(66));

  // Double is binary floating point; Currency is exact to four decimals.
  Ratio := 0.1;
  WriteLn('0.1 + 0.2 = 0.3 as Double: ', Ratio + 0.2 = 0.3, ', SameValue: ',
    SameValue(Ratio + 0.2, 0.3), ', three times 19.99 as Currency: ', (Price * 3):0:2);
end;

// =================================================================================================
//  2. Control flow
// =================================================================================================

procedure Section02_ControlFlow;
const
  Samples: array[0..3] of Integer = (2, 5, 9, 42);
var
  I, N, Total: Integer;
  Line: string;
begin
  Title(2, 'Control flow');

  // if ... then ... else. There is NO semicolon before else: a semicolon separates two
  // statements, and the if is one statement. Several statements are grouped by begin ... end.
  N := 7;
  if N mod 2 = 0 then
    WriteLn('even')
  else if N > 5 then
  begin
    Write('odd and ');
    WriteLn('greater than 5');
  end
  else
    WriteLn('odd and small');

  // case works on ordinal values (integers, characters, enumerations), takes lists and
  // ranges, and has no fall-through. C#: switch
  for I := Low(Samples) to High(Samples) do
    case Samples[I] of
      1..3:
        WriteLn(Samples[I], ': from 1 to 3');
      4, 5, 6:
        WriteLn(Samples[I], ': one of 4, 5, 6');
      7..9:
        WriteLn(Samples[I], ': from 7 to 9');
    else
      WriteLn(Samples[I], ': something else');
    end;

  // for counts up with to and down with downto, in steps of 1; BOTH bounds are included.
  Total := 0;
  for I := 1 to 5 do
    Total := Total + I;
  for I := 3 downto 1 do
    Total := Total + I;
  WriteLn('total ', Total);

  // while tests first. repeat ... until tests last and runs UNTIL the condition is true.
  // Break and Continue work as in C#.
  N := 1;
  while N < 100 do
    N := N * 2;
  I := 0;
  repeat
    Inc(I);
    if I = 2 then
      Continue;
  until I >= 3;
  WriteLn('N ', N, ', I ', I);

  // for ... in walks arrays, strings, sets and every class with an enumerator. C#: foreach
  Line := '';
  for N in Samples do
    Line := Line + IntToStr(N) + ' ';
  WriteLn(Trim(Line));
end;

// =================================================================================================
//  3. Routines: procedures and functions
// =================================================================================================

// A function returns a value by assigning it to Result. C#: return a + b;
function Add(A, B: Integer): Integer;
begin
  Result := A + B;
end;

// A procedure returns nothing. C#: void. Parameters are passed by value unless marked:
// var (C#: ref), out (C#: out), const (read-only; lets the compiler avoid a copy).
procedure SwapValues(var A, B: Integer);
var
  Keep: Integer;
begin
  Keep := A;
  A := B;
  B := Keep;
end;

function TryDivide(A, B: Integer; out Quotient: Integer): Boolean;
begin
  Result := B <> 0;
  if Result then
    Quotient := A div B
  else
    Quotient := 0;
end;

// The last parameters can have default values. C#: optional parameters
function PowerOf(Base: Double; Exponent: Integer = 2): Double;
var
  I: Integer;
begin
  Result := 1;
  for I := 1 to Exponent do
    Result := Result * Base;
end;

// Overloads have to be marked with the directive overload.
function Describe(Value: Integer): string; overload;
begin
  Result := 'the integer ' + IntToStr(Value);
end;

function Describe(const Value: string): string; overload;
begin
  Result := 'the string ' + QuotedStr(Value);
end;

// An open array parameter accepts an array of any length. C#: params int[] values
function SumOf(const Values: array of Integer): Integer;
var
  Value: Integer;
begin
  Result := 0;
  for Value in Values do
    Result := Result + Value;
end;

// Exit leaves the routine, and Exit(Value) sets the result on the way. C#: return value;
function FirstNegative(const Values: array of Integer): Integer;
var
  Value: Integer;
begin
  for Value in Values do
    if Value < 0 then
      Exit(Value);
  Result := 0;
end;

// A routine has to be declared above its first use. forward announces one whose body comes
// later, which two routines that call each other need.
function IsOddNumber(N: Integer): Boolean; forward;

function IsEvenNumber(N: Integer): Boolean;
begin
  if N = 0 then
    Result := True
  else
    Result := IsOddNumber(N - 1);
end;

function IsOddNumber(N: Integer): Boolean;
begin
  if N = 0 then
    Result := False
  else
    Result := IsEvenNumber(N - 1);
end;

procedure Section03_Routines;
var
  A, B, Quotient, Calls: Integer;

  // A nested routine sees the variables of the routine around it. C#: a local function
  procedure Bump;
  begin
    Inc(Calls);
  end;

begin
  Title(3, 'Routines: procedures and functions');

  A := 1;
  B := 2;
  SwapValues(A, B);                     // nothing at the call shows the pass by reference
  WriteLn('Add: ', Add(2, 3), '; swapped: ', A, ' ', B);
  if TryDivide(7, 2, Quotient) then
    WriteLn('7 div 2 = ', Quotient);
  WriteLn('a division by zero is accepted: ', TryDivide(1, 0, Quotient));
  WriteLn(PowerOf(3):0:1, ' ', PowerOf(2, 10):0:1);
  WriteLn(Describe(5), ' | ', Describe('five'));
  WriteLn('SumOf: ', SumOf([1, 2, 3, 4]), ', first negative: ', FirstNegative([3, -7, 5]),
    ', IsEvenNumber(10): ', IsEvenNumber(10));

  Calls := 0;
  Bump;                                 // a call without arguments needs no parentheses
  Bump();
  WriteLn('calls counted by the nested procedure: ', Calls);
end;

// =================================================================================================
//  4. Strings
// =================================================================================================

procedure Section04_Strings;
var
  S, T, Part: string;
  I, Number: Integer;
  Builder: TStringBuilder;
begin
  Title(4, 'Strings');

  // string is a managed type: reference counted, copied on write, freed automatically. In
  // Delphi it holds UTF-16 like a C# string (Free Pascal's Delphi mode uses 8-bit strings,
  // which makes no difference for the ASCII text of this tour). Unlike in C#, a string can
  // be changed in place, and its characters are numbered from 1.
  S := 'Delphi';
  T := S;                               // no copy yet: both variables share the text
  T[1] := 'd';                          // the copy is made now
  WriteLn(S, ' ', T, ', Length ', Length(S), ', S[1] = ', S[1]);

  // A quote inside a literal is doubled; a control character is written #code.
  S := 'It''s' + #9 + 'tabbed';
  WriteLn(S);

  // The classic routines count positions from 1 ...
  S := 'Hello, World';
  WriteLn(Copy(S, 8, 5), ' ', Pos('World', S), ' ', UpperCase(S), ' ',
    StringReplace(S, 'l', 'L', [rfReplaceAll]), ' [', Trim('  x  '), ']');
  Delete(S, 1, 7);                      // changes S itself
  Insert('Big ', S, 1);
  WriteLn(S, ' ', SameText('ABC', 'abc'), ' ', CompareStr('a', 'b') < 0, ' ', S = 'Big World');

  // ... and the newer helper methods count from 0, as in C#.
  S := 'Hello, World';
  WriteLn(S.ToUpper, ' ', S.IndexOf('World'), ' ', S.Substring(7, 5), ' ', S.Contains('lo, W'),
    ' ', S.StartsWith('Hell'));
  T := '';
  for Part in 'alpha,beta,gamma'.Split([',']) do
    T := T + '[' + Part + ']';
  WriteLn(T);

  // Conversions.
  WriteLn(IntToStr(42) + '|' + IntToHex(255, 4) + '|' + FloatToStr(2.5) + '|' +
    FormatFloat('0.00', Pi) + '|' + BoolToStr(True, True));
  WriteLn(StrToInt('42') + 1, ' ', StrToIntDef('abc', -1), ' ', TryStrToInt('12x', Number), ' ',
    StrToFloat('2.5'):0:2);
  // Format is C#'s string.Format with printf-style placeholders. Its arguments go in square
  // brackets: an "array of const", which can hold values of different types.
  WriteLn(Format('%s is %d years old, %.1f%% sure, [%5d] [%-5s] %x',
    ['Ann', 31, 99.5, 42, 'ab', 255]));

  // TStringBuilder for many appends. C#: StringBuilder. It is an object: it must be freed.
  Builder := TStringBuilder.Create;
  try
    for I := 1 to 5 do
      Builder.Append(I).Append(' ');
    WriteLn(Trim(Builder.ToString), ', length ', Builder.Length);
  finally
    Builder.Free;
  end;
end;

// =================================================================================================
//  5. Arrays, sets, enumerations, subranges
// =================================================================================================

type
  // An enumeration. C#: enum
  TColor = (Red, Green, Blue);
  // A set of small ordinal values: a bit set with language support. C#: a [Flags] enum
  TColors = set of TColor;
  // A subrange: an integer type limited to a range of values.
  TPercent = 0..100;

  // With SCOPEDENUMS the values need the name of their type, as in C#.
  {$SCOPEDENUMS ON}
  TLevel = (Junior, Middle, Senior);
  {$SCOPEDENUMS OFF}

procedure Section05_Arrays;
const
  // An array indexed by an enumeration, with its values.
  ColorNames: array[TColor] of string = ('red', 'green', 'blue');
var
  Fixed: array[1..5] of Integer;        // a static array: any index range, a value type
  Grid: array[0..1, 0..2] of Integer;   // two dimensions
  Numbers, Alias, Clone: TArray<Integer>;   // dynamic arrays. C#: int[]
  Color: TColor;
  Colors: TColors;
  Level: TLevel;
  Percent: TPercent;
  I, J: Integer;
  Line: string;
begin
  Title(5, 'Arrays, sets, enumerations, subranges');

  // The bounds of a static array belong to its type; Low, High and Length report them.
  for I := Low(Fixed) to High(Fixed) do
    Fixed[I] := I * I;
  WriteLn('Fixed: ', Low(Fixed), '..', High(Fixed), ', length ', Length(Fixed), ', last ',
    Fixed[High(Fixed)]);
  for I := 0 to 1 do
    for J := 0 to 2 do
      Grid[I, J] := I * 10 + J;
  WriteLn('Grid[1, 2] = ', Grid[1, 2]);

  // A dynamic array starts at 0 and lives on the heap, reference counted.
  Numbers := [3, 1, 2];                 // an array literal
  SetLength(Numbers, 5);                // resize; the new elements are zero
  Numbers[4] := 9;
  Numbers := Numbers + [7];             // concatenation
  // Assignment SHARES a dynamic array (there is no copy on write as for strings); Copy
  // makes a new one.
  Alias := Numbers;
  Clone := Copy(Numbers);
  Alias[0] := 100;
  WriteLn('Numbers[0] = ', Numbers[0], ' (changed through Alias), Clone[0] = ', Clone[0],
    ', length ', Length(Numbers));
  Line := '';
  for I in Numbers do
    Line := Line + IntToStr(I) + ' ';
  WriteLn(Trim(Line));

  // Enumerations are ordinal types: Ord, Succ, Pred, Low and High apply, and loops run
  // over them.
  Line := '';
  for Color := Low(TColor) to High(TColor) do
    Line := Line + ColorNames[Color] + '=' + IntToStr(Ord(Color)) + ' ';
  WriteLn(Trim(Line), ', Succ(Red) = Green: ', Succ(Red) = Green);
  Level := TLevel.Senior;
  WriteLn('a scoped value: ', Ord(Level), ', its name at run time: ',
    GetEnumName(TypeInfo(TLevel), Ord(Level)));

  // Sets: literals in brackets, in, + (union), * (intersection), - (difference).
  Colors := [Red, Blue];
  Include(Colors, Green);
  Exclude(Colors, Red);
  WriteLn('Green in Colors: ', Green in Colors, ', Red in Colors: ', Red in Colors,
    ', Colors * [Red, Blue] = [Blue]: ', Colors * [Red, Blue] = [Blue]);
  WriteLn('x is a lower-case letter: ', CharInSet('x', ['a'..'z']));

  // A value outside a subrange raises ERangeError when range checking is on (section 11).
  Percent := 100;
  WriteLn('Percent ', Percent, ' of at most ', High(TPercent));
end;

// =================================================================================================
//  6. Records
// =================================================================================================

type
  // A record is a value type. C#: struct. It can have methods, constructors, properties and
  // operators, but it cannot inherit.
  TVector = record
    X, Y: Double;
    constructor Create(AX, AY: Double);
    function Norm: Double;
    function ToText: string;
    class function Zero: TVector; static;                                 // C#: static
    class operator Add(const A, B: TVector): TVector;                     // C#: operator +
    class operator Multiply(const A: TVector; Factor: Double): TVector;
    class operator Equal(const A, B: TVector): Boolean;                   // C#: operator ==
    class operator Implicit(const V: TVector): string;                    // C#: implicit
  end;

  // A variant record lays several sets of fields over the same memory. C: a union;
  // C#: [StructLayout(LayoutKind.Explicit)]
  TOverlay = packed record
    case Boolean of
      True: (Whole: Cardinal);
      False: (Bytes: array[0..3] of Byte);
  end;

constructor TVector.Create(AX, AY: Double);
begin
  X := AX;
  Y := AY;
end;

function TVector.Norm: Double;
begin
  Result := Sqrt(X * X + Y * Y);
end;

function TVector.ToText: string;
begin
  Result := Format('(%.1f, %.1f)', [X, Y]);
end;

class function TVector.Zero: TVector;
begin
  Result := TVector.Create(0, 0);
end;

class operator TVector.Add(const A, B: TVector): TVector;
begin
  Result := TVector.Create(A.X + B.X, A.Y + B.Y);
end;

class operator TVector.Multiply(const A: TVector; Factor: Double): TVector;
begin
  Result := TVector.Create(A.X * Factor, A.Y * Factor);
end;

class operator TVector.Equal(const A, B: TVector): Boolean;
begin
  Result := (A.X = B.X) and (A.Y = B.Y);
end;

class operator TVector.Implicit(const V: TVector): string;
begin
  Result := V.ToText;
end;

procedure Section06_Records;
var
  A, B, C: TVector;
  Text: string;
  Overlay: TOverlay;
begin
  Title(6, 'Records');

  A := TVector.Create(3, 4);            // no memory is allocated: a record lives in place
  B := A;                               // a copy
  B.X := 10;
  C := A + B * 2;
  Text := C;                            // the Implicit conversion
  WriteLn('A = ', A.ToText, ', B = ', B.ToText, ', A + B * 2 = ', Text, ', Norm(A) = ',
    A.Norm:0:1);
  WriteLn('A = (3, 4): ', A = TVector.Create(3, 4), ', Zero: ', TVector.Zero.ToText);
  // A local record that is never assigned holds garbage: there is no definite-assignment
  // rule as in C#, only a compiler hint.

  Overlay.Whole := $11223344;
  WriteLn('the lowest byte of $11223344: ', IntToHex(Overlay.Bytes[0], 2), ', SizeOf = ',
    SizeOf(TOverlay));
end;

// =================================================================================================
//  7. Classes and object lifetime
// =================================================================================================

type
  EInsufficientFunds = class(Exception);

  // A class is a reference type and descends from TObject. Type names start with T, fields
  // with F and parameters often with A — conventions, not rules.
  TAccount = class
  private                               // visible to all code in this unit (file)
    FOwner: string;
    FBalance: Currency;
    FNote: string;
    class var FOpened: Integer;         // C#: a static field
    procedure SetNote(const Value: string);
  strict private                        // C#: private
    FLog: TStringList;
  public
    constructor Create(const AOwner: string; AOpening: Currency = 0);
    destructor Destroy; override;       // the destructor is always Destroy, overridden
    procedure Deposit(Amount: Currency);
    procedure Withdraw(Amount: Currency);
    function LogSize: Integer;
    function ToString: string; override;
    // A property maps to a field or to getter and setter methods. C#: a property
    property Owner: string read FOwner;
    property Balance: Currency read FBalance;
    property Note: string read FNote write SetNote;
    class property Opened: Integer read FOpened;
  end;

constructor TAccount.Create(const AOwner: string; AOpening: Currency);
begin
  inherited Create;                     // the constructor of the base class. C#: base()
  FOwner := AOwner;
  FBalance := AOpening;
  FNote := 'none';
  FLog := TStringList.Create;           // an object that this object owns ...
  Inc(FOpened);
end;

destructor TAccount.Destroy;
begin
  FLog.Free;                            // ... and therefore has to free
  inherited;                            // the destructor of the base class comes last
end;

procedure TAccount.SetNote(const Value: string);
begin
  FNote := Trim(Value);
  FLog.Add('note: ' + FNote);
end;

procedure TAccount.Deposit(Amount: Currency);
begin
  FBalance := FBalance + Amount;
  FLog.Add('deposit');
end;

procedure TAccount.Withdraw(Amount: Currency);
begin
  if Amount > FBalance then
    raise EInsufficientFunds.Create('insufficient funds');      // C#: throw new ...
  FBalance := FBalance - Amount;
  FLog.Add('withdrawal');
end;

function TAccount.LogSize: Integer;
begin
  Result := FLog.Count;
end;

function TAccount.ToString: string;
begin
  Result := Format('%s: %.2f (%s)', [FOwner, FBalance, FNote]);
end;

procedure Section07_Classes;
var
  Savings, Alias: TAccount;
begin
  Title(7, 'Classes and object lifetime');

  // Create allocates and constructs, and the variable is a reference. try ... finally makes
  // sure that Free is reached. C#: using — but here EVERY object needs it, not only those
  // that hold resources.
  Savings := TAccount.Create('Ann', 100);
  try
    Savings.Deposit(50);
    Savings.Note := '  savings  ';      // runs SetNote
    Alias := Savings;                   // a second reference to the same object, not a copy
    Alias.Deposit(1);
    WriteLn(Savings.ToString, '; log entries: ', Savings.LogSize, '; accounts opened: ',
      TAccount.Opened);
    try
      Savings.Withdraw(500);
    except
      on E: EInsufficientFunds do       // C#: catch (InsufficientFundsException e)
        WriteLn('Withdraw failed: ', E.Message);
    end;
  finally
    Savings.Free;                       // calls Destroy; Free on a nil reference is harmless
  end;

  // After Free the variables Savings and Alias still point at the freed memory. Using them
  // is an error that nothing detects. FreeAndNil(Savings) at least clears one of them.
  Savings := nil;
  WriteLn('Assigned(Savings): ', Assigned(Savings));
  // Forgotten objects are leaks. Delphi lists them at exit after
  // ReportMemoryLeaksOnShutdown := True; Free Pascal does the same with the option -gh.
end;

// =================================================================================================
//  8. Inheritance and class references
// =================================================================================================

type
  TShape = class abstract               // C#: abstract class
  private
    FName: string;
  public
    constructor Create(const AName: string); virtual;     // a constructor can be virtual
    function Area: Double; virtual; abstract;             // C#: abstract
    function Describe: string; virtual;                   // C#: virtual
    property Name: string read FName;
  end;

  // A class reference type: a variable of it holds a CLASS (TCircle, TSquare ...).
  // C#: System.Type, but checked by the compiler.
  TShapeClass = class of TShape;

  TCircle = class(TShape)               // C#: class Circle : Shape
  private
    FRadius: Double;
  public
    constructor Create(const AName: string); override;
    function Area: Double; override;                      // override must be written
    property Radius: Double read FRadius write FRadius;
  end;

  TSquare = class sealed(TShape)        // C#: sealed
  private
    FSide: Double;
  public
    constructor Create(const AName: string); override;
    function Area: Double; override;
    function Describe: string; override;
  end;

constructor TShape.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

function TShape.Describe: string;
begin
  Result := Format('%s with the area %.2f', [FName, Area]);
end;

constructor TCircle.Create(const AName: string);
begin
  inherited Create(AName);
  FRadius := 1;
end;

function TCircle.Area: Double;
begin
  Result := Pi * FRadius * FRadius;
end;

constructor TSquare.Create(const AName: string);
begin
  inherited Create(AName);
  FSide := 2;
end;

function TSquare.Area: Double;
begin
  Result := FSide * FSide;
end;

function TSquare.Describe: string;
begin
  Result := 'a square: ' + inherited Describe;            // C#: base.Describe()
end;

procedure Section08_Inheritance;
var
  Shapes: TObjectList<TShape>;          // a list that owns its objects and frees them
  Shape: TShape;
  ShapeClass: TShapeClass;
  Total: Double;
begin
  Title(8, 'Inheritance and class references');

  Shapes := TObjectList<TShape>.Create(True);
  try
    Shapes.Add(TCircle.Create('disc'));
    Shapes.Add(TSquare.Create('tile'));
    // An object made from a class reference: the virtual constructor of the class that the
    // variable holds runs. C#: Activator.CreateInstance(type), without reflection here.
    ShapeClass := TCircle;
    Shapes.Add(ShapeClass.Create('made from a class reference'));

    Total := 0;
    for Shape in Shapes do
    begin
      WriteLn(Shape.Describe, ' [', Shape.ClassName, ']');
      Total := Total + Shape.Area;
      // is tests the type; as casts with a check (EInvalidCast); TCircle(Shape) casts
      // without any check.
      if Shape is TCircle then
        WriteLn('  its radius is ', (Shape as TCircle).Radius:0:1);
    end;
    WriteLn('total area: ', Total:0:2, ', TSquare inherits from TShape: ',
      TSquare.InheritsFrom(TShape));
  finally
    Shapes.Free;                        // frees the shapes as well
  end;
end;

// =================================================================================================
//  9. Interfaces and reference counting
// =================================================================================================

type
  // An interface carries a GUID, which `as` and Supports need. C#: interface
  ILogger = interface
    ['{6E1F4B32-5B0C-4C0B-9A5E-0A4B6D0C1F01}']
    procedure Log(const Text: string);
    function GetCount: Integer;
    property Count: Integer read GetCount;                // an interface can have properties
  end;

  IResettable = interface
    ['{6E1F4B32-5B0C-4C0B-9A5E-0A4B6D0C1F02}']
    procedure Reset;
  end;

  // Interface references are counted: when the last one goes away, the object is destroyed
  // at that very moment. TInterfacedObject implements the counting.
  TMemoryLogger = class(TInterfacedObject, ILogger, IResettable)
  private
    FLines: TStringList;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Log(const Text: string);
    procedure Reset;
  end;

constructor TMemoryLogger.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TMemoryLogger.Destroy;
begin
  WriteLn('  the logger is destroyed');
  FLines.Free;
  inherited;
end;

function TMemoryLogger.GetCount: Integer;
begin
  Result := FLines.Count;
end;

procedure TMemoryLogger.Log(const Text: string);
begin
  FLines.Add(Text);
end;

procedure TMemoryLogger.Reset;
begin
  FLines.Clear;
end;

procedure Section09_Interfaces;
var
  Logger, Second: ILogger;
  Resettable: IResettable;
begin
  Title(9, 'Interfaces and reference counting');

  Logger := TMemoryLogger.Create;       // owned by its references from now on: no Free
  Logger.Log('first');
  Logger.Log('second');
  Second := Logger;                     // two references
  WriteLn('lines: ', Second.Count);

  // Supports asks the object for another interface. C#: if (logger is IResettable r)
  if Supports(Logger, IResettable, Resettable) then
  begin
    Resettable.Reset;
    WriteLn('lines after Reset: ', Logger.Count);
  end;

  Resettable := nil;
  Logger := nil;
  WriteLn('one reference is left');
  Second := nil;                        // the last one: the destructor runs right here
  WriteLn('no reference is left');

  // The rule: hold an object EITHER through class references and Free it, OR through
  // interfaces; mixing the two frees it twice. Two objects that hold interfaces of each
  // other never die: Delphi has the [weak] attribute for one of the two references.
end;

// =================================================================================================
//  10. Generics and collections
// =================================================================================================

type
  // A generic class. C#: class TinyStack<T>
  TTinyStack<T> = class
  private
    FItems: TArray<T>;
    FCount: Integer;
    function GetItem(Index: Integer): T;
  public
    procedure Push(const Item: T);
    function Pop: T;
    property Count: Integer read FCount;
    // An array property marked default is an indexer: Stack[0]. C#: this[int index]
    property Items[Index: Integer]: T read GetItem; default;
  end;

  // Constraints follow a colon: class, record, constructor, a base class or an interface.
  // C#: where T : class, new()
  TFactory<T: class, constructor> = class
  public
    class function Make: T; static;
  end;

  // There are no generic standalone routines, only generic methods.
  TCompare = class
  public
    class function Max<T>(const A, B: T): T; static;
  end;

procedure TTinyStack<T>.Push(const Item: T);
begin
  if FCount = Length(FItems) then
    SetLength(FItems, FCount * 2 + 4);
  FItems[FCount] := Item;
  Inc(FCount);
end;

function TTinyStack<T>.Pop: T;
begin
  if FCount = 0 then
    raise EInvalidOpException.Create('the stack is empty');
  Dec(FCount);
  Result := FItems[FCount];
  FItems[FCount] := Default(T);         // C#: default(T)
end;

function TTinyStack<T>.GetItem(Index: Integer): T;
begin
  Result := FItems[FCount - 1 - Index];
end;

class function TFactory<T>.Make: T;
begin
  Result := T.Create;
end;

class function TCompare.Max<T>(const A, B: T): T;
begin
  // TComparer<T>.Default knows how to compare the built-in types. C#: Comparer<T>.Default
  if TComparer<T>.Default.Compare(A, B) >= 0 then
    Result := A
  else
    Result := B;
end;

procedure Section10_Generics;
var
  Stack: TTinyStack<string>;
  Made: TStringList;
  Numbers: TList<Integer>;
  Ages: TDictionary<string, Integer>;
  Names: TList<string>;
  Name, Line: string;
  Age, N: Integer;
begin
  Title(10, 'Generics and collections');

  Stack := TTinyStack<string>.Create;
  try
    Stack.Push('first');
    Stack.Push('second');
    Stack.Push('third');
    WriteLn('top: ', Stack[0], ', count: ', Stack.Count, ', popped: ', Stack.Pop);
    WriteLn('count after Pop: ', Stack.Count);
  finally
    Stack.Free;
  end;

  // The type argument of a generic method is written out here; Delphi can also infer it.
  WriteLn(TCompare.Max<Integer>(3, 9), ' ', TCompare.Max<string>('pear', 'apple'), ' ',
    TCompare.Max<Double>(1, 2.5):0:1);
  Made := TFactory<TStringList>.Make;
  try
    Made.Add('made by a generic factory');
    WriteLn(Made[0]);
  finally
    Made.Free;
  end;

  // The collections of System.Generics.Collections: TList<T>, TDictionary<K, V>,
  // TObjectList<T>, TQueue<T>, TStack<T> ... They are classes: Create and Free.
  Numbers := TList<Integer>.Create;
  try
    Numbers.AddRange([5, 3, 8, 1]);
    Numbers.Add(4);
    Numbers.Sort;
    Line := '';
    for N in Numbers do
      Line := Line + IntToStr(N) + ' ';
    WriteLn(Trim(Line), ' | count ', Numbers.Count, ', index of 8: ', Numbers.IndexOf(8),
      ', contains 7: ', Numbers.Contains(7));
  finally
    Numbers.Free;
  end;

  Ages := TDictionary<string, Integer>.Create;
  Names := TList<string>.Create;
  try
    Ages.Add('Bob', 27);
    Ages.Add('Ann', 31);
    Ages.AddOrSetValue('Cid', 40);
    Ages['Bob'] := 28;
    if Ages.TryGetValue('Ann', Age) then
      WriteLn('Ann is ', Age);
    // A dictionary has no order, so the keys are sorted for the listing.
    for Name in Ages.Keys do
      Names.Add(Name);
    Names.Sort;
    Line := '';
    for Name in Names do
      Line := Line + Format('%s=%d ', [Name, Ages[Name]]);
    WriteLn(Trim(Line), ', has Dee: ', Ages.ContainsKey('Dee'));
  finally
    Names.Free;
    Ages.Free;
  end;
end;

// =================================================================================================
//  11. Exceptions and compiler checks
// =================================================================================================

type
  // Exceptions are classes that descend from Exception; their names start with E.
  EValidation = class(Exception)
  private
    FField: string;
  public
    constructor Create(const AField, AMessage: string);
    property Field: string read FField;
  end;

constructor EValidation.Create(const AField, AMessage: string);
begin
  inherited Create(AMessage);
  FField := AField;
end;

function ParseAge(const Text: string): Integer;
begin
  if not TryStrToInt(Text, Result) then
    raise EValidation.Create('age', QuotedStr(Text) + ' is not a number');
  if (Result < 0) or (Result > 150) then
    raise EArgumentOutOfRangeException.CreateFmt('the age %d is out of range', [Result]);
end;

procedure Section11_Exceptions;
const
  Inputs: array[0..2] of string = ('42', 'abc', '999');
var
  Input: string;
  Numbers: array[1..3] of Integer;
  I, Age: Integer;
  Big: Int64;
  List: TStringList;
begin
  Title(11, 'Exceptions and compiler checks');

  // try ... except handles exceptions. C#: try / catch
  for Input in Inputs do
    try
      Age := ParseAge(Input);
      WriteLn('age ', Age);
    except
      on E: EValidation do              // C#: catch (ValidationException e)
        WriteLn('invalid ', E.Field, ': ', E.Message);
      on E: EArgumentException do       // a base class also catches its descendants
        WriteLn(E.ClassName, ': ', E.Message);
    end;

  // try ... finally cleans up. It is a statement of its own: one that both cleans up and
  // handles is written as two nested statements. C#: try / catch / finally in one.
  try
    List := TStringList.Create;
    try
      List.Add('one');
      I := StrToInt('not a number');    // raises EConvertError
      WriteLn('not reached ', I);
    finally
      List.Free;                        // runs while the exception is on its way out
      WriteLn('finally: the list is freed');
    end;
  except
    on E: Exception do                  // Exception catches everything worth catching
      WriteLn('handled ', E.ClassName);
    // a bare raise; in a handler rethrows the exception. C#: throw;
  end;

  // Integer overflow is checked only under {$Q+}. (The example uses Int64 because Free
  // Pascal computes 32-bit sums in 64 bits on a 64-bit processor; Delphi does not.)
  {$Q-}
  Big := High(Int64);
  Big := Big + 1;                       // wraps around silently
  WriteLn('High(Int64) + 1 without overflow checking: ', Big);
  {$Q+}
  Big := High(Int64);
  try
    Big := Big + 1;                     // now it raises EIntOverflow
    WriteLn('not reached ', Big);
  except
    on E: EIntOverflow do
      WriteLn('High(Int64) + 1 with overflow checking: ', E.ClassName);
  end;
  {$Q-}

  // Array bounds and subranges are checked only under {$R+}. Without it the assignment
  // below would write outside the array: undefined behaviour, where C# always throws.
  {$R+}
  I := 4;
  try
    Numbers[I] := 1;                    // index 4 of an array[1..3]
    WriteLn('not reached ', Numbers[I]);
  except
    on E: ERangeError do
      WriteLn('index 4 of array[1..3] with range checking: ', E.ClassName);
  end;
  {$R-}

  I := 0;
  try
    WriteLn(10 div I);
  except
    on E: EDivByZero do
      WriteLn('10 div 0: ', E.ClassName);
  end;

  // Assert raises EAssertionFailed where assertions are compiled in: by default in Delphi,
  // on request in Free Pascal.
  {$ASSERTIONS ON}
  try
    Assert(I > 0, 'I must be positive');
  except
    on E: EAssertionFailed do
      WriteLn('Assert(I > 0) with I = 0: ', E.ClassName);
  end;
end;

// =================================================================================================
//  12. Procedural types, method pointers, events
// =================================================================================================

type
  // A procedural type: a pointer to a routine with this signature. C#: a delegate type
  TMathFunction = function(X: Double): Double;

  // With "of object" it is a method pointer: the code AND the object to call it on.
  // C#: a delegate that is bound to an instance
  TChangeEvent = procedure(Sender: TObject; NewValue: Integer) of object;

  TThermometer = class
  private
    FDegrees: Integer;
    FOnChange: TChangeEvent;
    procedure SetDegrees(Value: Integer);
  public
    property Degrees: Integer read FDegrees write SetDegrees;
    // An event is a property of a method-pointer type. It holds ONE handler, assigned with
    // := (C#: a multicast event with += and -=).
    property OnChange: TChangeEvent read FOnChange write FOnChange;
  end;

  TRecorder = class
  private
    FReadings: TList<Integer>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure HandleChange(Sender: TObject; NewValue: Integer);
    property Readings: TList<Integer> read FReadings;
  end;

procedure TThermometer.SetDegrees(Value: Integer);
begin
  if Value = FDegrees then
    Exit;
  FDegrees := Value;
  if Assigned(FOnChange) then           // C#: OnChange?.Invoke(this, value)
    FOnChange(Self, Value);             // Self is C#'s this
end;

constructor TRecorder.Create;
begin
  inherited Create;
  FReadings := TList<Integer>.Create;
end;

destructor TRecorder.Destroy;
begin
  FReadings.Free;
  inherited;
end;

procedure TRecorder.HandleChange(Sender: TObject; NewValue: Integer);
begin
  FReadings.Add(NewValue);
end;

function Square(X: Double): Double;
begin
  Result := X * X;
end;

function Cube(X: Double): Double;
begin
  Result := X * X * X;
end;

// A routine as a parameter: the trapezoidal rule. C#: Func<double, double>
function Integrate(F: TMathFunction; A, B: Double; Steps: Integer): Double;
var
  I: Integer;
  H: Double;
begin
  H := (B - A) / Steps;
  Result := (F(A) + F(B)) / 2;
  for I := 1 to Steps - 1 do
    Result := Result + F(A + I * H);
  Result := Result * H;
end;

procedure Section12_ProceduralTypes;
var
  F: TMathFunction;
  Sensor: TThermometer;
  Recorder: TRecorder;
begin
  Title(12, 'Procedural types, method pointers, events');

  F := Square;
  WriteLn('F(4) = ', F(4):0:1, ', the integral of x^2 from 0 to 3: ',
    Integrate(F, 0, 3, 1000):0:4);
  F := Cube;
  WriteLn('F(4) = ', F(4):0:1, ', Assigned(F): ', Assigned(F));

  Sensor := TThermometer.Create;
  Recorder := TRecorder.Create;
  try
    Sensor.OnChange := Recorder.HandleChange;     // subscribe: a method and its object
    Sensor.Degrees := 20;
    Sensor.Degrees := 25;
    Sensor.OnChange := nil;                       // unsubscribe
    Sensor.Degrees := 30;
    WriteLn('changes recorded: ', Recorder.Readings.Count, ', the last one: ',
      Recorder.Readings.Last);
  finally
    Recorder.Free;
    Sensor.Free;
  end;

  // The third kind are anonymous methods ("reference to"): closures that capture variables.
  // Delphi has them since 2009; Free Pascal 3.2 does not, so this is NOT compiled here:
  //
  //     type
  //       TIntPredicate = reference to function(N: Integer): Boolean;
  //     var
  //       IsBig: TIntPredicate;
  //       Limit: Integer;
  //     begin
  //       Limit := 10;
  //       IsBig := function(N: Integer): Boolean
  //                begin
  //                  Result := N > Limit;            // captures the variable Limit
  //                end;
  //       WriteLn(IsBig(42));
  //
  // The library declares TProc, TFunc<T, TResult> and TPredicate<T> for them.
  // C#: lambdas with Action, Func and Predicate
end;

// =================================================================================================
//  13. Helpers, RTTI, pointers
// =================================================================================================

type
  // A helper adds methods to an existing type. C#: extension methods. Only ONE helper per
  // type is in effect: this one hides the helper for Integer that the library brings, so
  // inside this file N.ToString no longer exists for an Integer.
  TIntHelper = record helper for Integer
    function IsEven: Boolean;
    function Clamp(Lowest, Highest: Integer): Integer;
  end;

  TStringListHelper = class helper for TStringList
    function Joined(const Separator: string): string;
  end;

  // Run-time type information: published properties can be read and written by name.
  // {$M+} switches it on for a class. C#: reflection
  {$M+}
  TPerson = class
  private
    FName: string;
    FAge: Integer;
  published
    property Name: string read FName write FName;
    property Age: Integer read FAge write FAge;
  end;
  {$M-}

function TIntHelper.IsEven: Boolean;
begin
  Result := Self mod 2 = 0;
end;

function TIntHelper.Clamp(Lowest, Highest: Integer): Integer;
begin
  Result := Min(Max(Self, Lowest), Highest);
end;

function TStringListHelper.Joined(const Separator: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
  begin
    if I > 0 then
      Result := Result + Separator;
    Result := Result + Strings[I];
  end;
end;

procedure Section13_HelpersRttiPointers;
var
  N: Integer;
  List: TStringList;
  Person: TPerson;
  P: PInteger;                          // a typed pointer; the type is declared as ^Integer
  Numbers: array[0..2] of Integer;
  OnHeap: PDouble;
begin
  Title(13, 'Helpers, RTTI, pointers');

  N := 42;
  WriteLn('N.IsEven: ', N.IsEven, ', N.Clamp(0, 10): ', N.Clamp(0, 10));
  List := TStringList.Create;
  try
    List.Add('a');
    List.Add('b');
    List.Add('c');
    WriteLn('Joined: ', List.Joined(' + '));
  finally
    List.Free;
  end;

  Person := TPerson.Create;
  try
    SetStrProp(Person, 'Name', 'Ann');
    SetOrdProp(Person, 'Age', 31);
    WriteLn(Person.ClassName, ': ', GetStrProp(Person, 'Name'), ', ', GetOrdProp(Person, 'Age'),
      ', has a property Email: ', IsPublishedProp(Person, 'Email'));
    WriteLn('an enumeration by name: ', GetEnumName(TypeInfo(TColor), Ord(Blue)), ' <-> ',
      GetEnumValue(TypeInfo(TColor), 'Green'));
  finally
    Person.Free;
  end;
  // Delphi's unit System.Rtti (TRttiContext) goes much further: every member, calls by
  // name, and custom attributes written as [Table('people')] above a declaration.
  // NOT compiled here: Free Pascal 3.2 has no attributes.

  // Pointers: @ takes an address, ^ follows a pointer. C#: unsafe code
  N := 5;
  P := @N;
  P^ := P^ * 2;
  WriteLn('N changed through a pointer: ', N);
  Numbers[0] := 10;
  Numbers[1] := 20;
  Numbers[2] := 30;
  P := @Numbers[0];
  Inc(P);                               // moves on by one Integer
  WriteLn('the element after the first: ', P^);
  New(OnHeap);                          // typed memory from the heap ...
  OnHeap^ := 2.5;
  WriteLn('a Double on the heap: ', OnHeap^:0:1);
  Dispose(OnHeap);                      // ... which has to be given back
  // nil is the null pointer, and Pointer is the untyped pointer type (C: void*).
end;

// =================================================================================================
//  14. Streams and threads
// =================================================================================================

type
  // A thread is a class that overrides Execute. C#: Thread
  TCounterThread = class(TThread)
  private
    FLock: TCriticalSection;
    FTotal: PInteger;
    FRounds: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(ALock: TCriticalSection; ATotal: PInteger; ARounds: Integer);
  end;

constructor TCounterThread.Create(ALock: TCriticalSection; ATotal: PInteger; ARounds: Integer);
begin
  FLock := ALock;                       // set the fields first: the thread may start in
  FTotal := ATotal;                     // the inherited constructor
  FRounds := ARounds;
  inherited Create(False);              // False: do not create it suspended
end;

procedure TCounterThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FRounds do
  begin
    FLock.Acquire;                      // C#: lock (gate) { ... }
    try
      Inc(FTotal^);
    finally
      FLock.Release;
    end;
  end;
end;

procedure Section14_StreamsThreads;
var
  Stream: TMemoryStream;
  Lines: TStringList;
  Value, I, Total: Integer;
  Lock: TCriticalSection;
  Threads: array[0..3] of TCounterThread;
begin
  Title(14, 'Streams and threads');

  // TFileStream, TMemoryStream and TStringStream share the base class TStream. C#: Stream
  Stream := TMemoryStream.Create;
  Lines := TStringList.Create;
  try
    Value := 123456;
    Stream.WriteBuffer(Value, SizeOf(Value));     // raw bytes
    Lines.Add('alpha=1');
    Lines.Add('beta=2');
    Lines.SaveToStream(Stream);                   // a TStringList also saves to files
    Stream.Position := 0;
    Value := 0;
    Stream.ReadBuffer(Value, SizeOf(Value));
    Lines.Clear;
    Lines.LoadFromStream(Stream);                 // reads from the position to the end
    WriteLn('read back: ', Value, ', ', Lines.Count, ' lines, beta = ', Lines.Values['beta']);
  finally
    Lines.Free;
    Stream.Free;
  end;

  // Threads share memory, and a critical section protects it. C#: lock
  Total := 0;
  Lock := TCriticalSection.Create;
  try
    for I := Low(Threads) to High(Threads) do
      Threads[I] := TCounterThread.Create(Lock, @Total, 10000);
    for I := Low(Threads) to High(Threads) do
    begin
      Threads[I].WaitFor;                         // C#: Join
      Threads[I].Free;
    end;
    WriteLn('4 threads, 10000 increments each: ', Total);
  finally
    Lock.Free;
  end;

  // Delphi's Parallel Programming Library (the unit System.Threading) has tasks, futures
  // and parallel loops. C#: Task, Task<T>, Parallel.For. NOT compiled here: it relies on
  // anonymous methods.
  //
  //     TParallel.For(1, 1000, procedure(I: Integer) begin Process(I); end);
  //     Future := TTask.Future<Integer>(function: Integer begin Result := Compute; end);
  //
  // TThread.Synchronize and TThread.Queue run code on the main thread, which is where a
  // GUI has to be updated. C#: Dispatcher.Invoke, SynchronizationContext.Post
end;

// =================================================================================================
//  15. Units, and the newest
// =================================================================================================

procedure Section15_Newest;
begin
  Title(15, 'Units, and the newest');

  // This tour is a single program file. Real code is split into units, one per file:
  //
  //     unit Geometry;
  //
  //     interface                       // what other units may see. C#: public
  //     uses
  //       System.SysUtils;
  //     type
  //       TShape = class ... end;
  //     function TotalArea(const Shapes: array of TShape): Double;
  //
  //     implementation                  // the bodies, and all that is private to the unit
  //     ...
  //     initialization                  // runs when the program starts. C#: a static constructor
  //     ...
  //     finalization                    // runs when the program ends
  //     ...
  //     end.
  //
  // A unit is compiled on its own (to a .dcu file), which is what makes builds fast. Two
  // units cannot use each other in their interface parts.
  WriteLn('units: see the comments in the source');

  // The language over time. Everything below is newer than what Free Pascal 3.2 compiles,
  // so it is NOT compiled here:
  //
  //   2009   generics, anonymous methods, Unicode strings (used above, except the methods)
  //   2010   attributes and extended RTTI
  //   10.3   inline variables with type inference (2018):
  //              var Total := 0;
  //              for var I := 1 to 10 do Inc(Total, I);
  //   10.4   managed records: class operator Initialize, Finalize and Assign (2020)
  //   11     binary literals and digit separators: %1010, 1_000_000 (2021)
  //   12     multi-line string literals between triple quotes ''' (2023)
  //   13     a conditional operator (2025):
  //              Size := if N > 5 then 'big' else 'small';
  //          and also the operators `is not` and `not in`, the NameOf intrinsic and the
  //          noreturn directive
  WriteLn('the newest syntax: see the comments in the source');
end;

// =================================================================================================
//  The main block. C#: Main
// =================================================================================================

begin
  // Format numbers the same way on every machine: 3.5, not 3,5.
  FormatSettings.DecimalSeparator := '.';
  FormatSettings.ThousandSeparator := ',';

  Section01_Basics;
  Section02_ControlFlow;
  Section03_Routines;
  Section04_Strings;
  Section05_Arrays;
  Section06_Records;
  Section07_Classes;
  Section08_Inheritance;
  Section09_Interfaces;
  Section10_Generics;
  Section11_Exceptions;
  Section12_ProceduralTypes;
  Section13_HelpersRttiPointers;
  Section14_StreamsThreads;
  Section15_Newest;
end.
