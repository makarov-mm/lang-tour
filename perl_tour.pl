#!/usr/bin/env perl
# ==================================================================================================
#  PERL FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
#
#  Run:   perl perl_tour.pl          (Perl 5.38 or newer; core modules only)
#
#  Verified with Perl 5.38.2, with strict and warnings enabled and no warnings printed.
#  Newer interpreters were not available where this file was checked; what 5.40 and 5.42
#  added is listed in section 10 as comments that were NOT run.
#
#  How to read. Each section is a sub `sectionNN_*`; the packages and subs a section needs
#  are declared right before it; `main()` at the end calls the sections in order. A "C#:"
#  note shows the closest C# counterpart.
#
#  The main differences from C# to keep in mind from the first line:
#
#   1. Sigils. `$x` is one value (a scalar), `@x` an array, `%x` a hash — three different
#      variables. An element is a scalar, so it is written `$x[0]` and `$x{key}`.
#   2. Context. Every expression is evaluated in list or scalar context and may mean
#      different things in each: `@x` is the elements in one and their count in the other.
#   3. No static types. A scalar holds a number, a string or a reference and converts
#      between number and string on demand; the OPERATOR says which is meant (`==` vs `eq`).
#   4. Nested data and objects are built from references; classic OOP is a convention on
#      top of packages and `bless` (section 7). A `class` syntax arrived in 5.38.
#   5. Regular expressions are part of the syntax, not a library.
#   6. "There is more than one way to do it": statement modifiers, the implicit variable
#      `$_`, optional parentheses. Modern code starts with `use v5.36` or later, which turns
#      on strict mode, warnings and signatures.
#
#  Contents:
#    1. Basics: scalars, strings, truth, control flow     6. Files, I/O and text
#    2. Arrays, hashes, context                           7. Packages and objects
#    3. References and nested data                        8. Errors
#    4. Subroutines                                       9. Idioms and metaprogramming
#    5. Regular expressions                              10. The newest
# ==================================================================================================

use v5.38;    # strict, warnings, say, signatures, postfix dereference, `isa` ...
use utf8;     # the source text is UTF-8

# Features that are still experimental in 5.38, and the warnings that announce them.
use feature qw(class try defer);
no warnings qw(experimental::class experimental::try experimental::defer
    experimental::builtin experimental::for_list);
use builtin qw(true false is_bool trim ceil floor indexed reftype blessed weaken);

# Modules. C#: using. All of these ship with Perl; everything else comes from CPAN.
use Carp        qw(croak);
use Data::Dumper ();
use Encode      qw(encode);
use File::Temp  qw(tempfile);
use List::Util  qw(sum max min first reduce any all uniq);
use POSIX       qw(strftime);
use Scalar::Util qw(looks_like_number);
use Time::Local qw(timegm);

sub title ($text) { say "\n=== $text ===" }

# Strips the " at FILE line N." that Perl appends to error messages.
sub brief ($error) { return $error =~ s/^(.*) at .+? line \d+\.\s*\z/$1/sr }

# Renders nested data on one line with sorted hash keys.
sub dump_data ($data) {
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper($data);
}

# ==================================================================================================
#  1. BASICS: scalars, strings, truth, control flow
# ==================================================================================================

sub section01_basics {
    title('1. Basics');

    # --- Scalars: `my` declares a lexical variable; a scalar holds one value of any kind ---
    my $count = 42;
    my $ratio = 3.5;
    my $name  = 'World';
    my $big   = 9_007_199_254_740_993;    # a 64-bit integer; beyond that, a double
    say join ' ', $count, $ratio, $name, $big, 7 / 2, int(7 / 2), 7 % 3, -7 % 3, 2**10, 1_000_000;

    # Numbers and strings convert into each other on demand; the operator decides.
    {
        no warnings 'numeric';    # otherwise: Argument "3 apples" isn't numeric
        say join ' ', '10' + 5, '10' . 5, '3 apples' * 2, 'abc' x 3, '-' x 10;
    }

    # Hence two sets of comparison operators: == < <=> for numbers, eq lt cmp for strings.
    say join ' ', (10 == 10.0 ? 'equal' : 'different'), ('10' eq '10.0' ? 'equal' : 'different'),
        (2 < 10 ? 'less' : 'greater'), ('2' lt '10' ? 'less' : 'greater'), 2 <=> 10, 'b' cmp 'a';

    # --- Strings and quoting ---
    my $greeting = "Hello, $name!";      # double quotes interpolate. C#: $"Hello, {name}!"
    my $literal  = 'Hello, $name!\n';    # single quotes do not
    my @list     = (1, 2, 3);
    my %ages     = (Ann => 30);
    say "$greeting | $literal | @list | $list[0] | $ages{Ann} | @{[ $count * 2 ]}";
    say join ' | ', length($greeting), uc($greeting), ucfirst('tour'), substr($greeting, 7, 5),
        index($greeting, 'World'), scalar reverse('abc'),
        sprintf('%05.1f|%-6s|%+d|%x|%b', 3.14159, 'ab', 5, 255, 5);
    my $heredoc = <<~"TEXT";             # an indented here-document
        A here-document interpolates: $name.
        The common indentation is removed.
        TEXT
    print $heredoc;
    my $accented = 'Grüße';              # characters, thanks to `use utf8`
    say length($accented), ' characters, ', length(encode('UTF-8', $accented)), ' bytes';

    # --- undef, definedness and truth ---
    my $nothing;                         # undef: "no value". C#: null
    my %config = (port => 0, host => '');
    say join ' ', (defined $nothing ? 'defined' : 'undef'), $nothing // 'default',
        $config{port} || 8080, $config{port} // 8080, (exists $config{user} ? 'exists' : 'missing');

    # False: undef, 0, '0', '' and the empty list. Everything else is true, even '0.0'.
    say join ' ', map { $_ ? 'T' : 'F' } (0, 1, '', '0', '0.0', '00', 'a', -1);

    # --- Control flow ---
    my $sum = 0;
    for my $i (0 .. 4) { $sum += $i }                 # foreach over a range
    for (my $i = 0; $i < 3; $i++) { $sum += 10 }      # the C-style form
    $sum += $_ for 10, 20, 30;        # a statement modifier; $_ is the default variable
    my $n = 3;
    $sum += 100 while $n-- > 0;
    unless ($sum % 2) { $sum += 1 }                   # unless = if not
  OUTER:
    for my $row (0 .. 2) {
        for my $col (0 .. 2) {
            next OUTER if $col > $row;    # next / last are continue / break, with labels
            $sum += 1000;
        }
    }
    my $kind = $sum % 15 == 0 ? 'fizzbuzz' : $sum % 3 == 0 ? 'fizz' : 'other';
    say "$sum $kind";
}

# ==================================================================================================
#  2. ARRAYS, HASHES, CONTEXT
# ==================================================================================================

sub section02_arrays_and_hashes {
    title('2. Arrays, hashes, context');

    # --- Arrays: @ names the whole array, $ one element. C#: List<object> ---
    my @numbers = (5, 3, 8);
    push @numbers, 1, 9;       # at the end; pop removes from the end
    unshift @numbers, 7;       # at the front; shift removes from the front
    say "@numbers | $numbers[0] $numbers[-1] | last index $#numbers | count ", scalar(@numbers);
    say "slice @numbers[1 .. 3] | sorted @{[ sort { $a <=> $b } @numbers ]}";
    my @removed = splice(@numbers, 1, 2);    # remove two elements starting at index 1
    my @words   = qw(pear Fig banana kiwi);  # qw: a list of words without quotes and commas
    say "@removed | @numbers | ", join(',', sort @words), ' | ',
        join(',', sort { lc $a cmp lc $b } @words), ' | ',
        join(',', sort { length $a <=> length $b or $a cmp $b } @words);

    # sort without a block compares as STRINGS: 10 comes before 9.
    say join ' ', sort(10, 9, 100), '|', sort { $a <=> $b } (10, 9, 100);

    # map and grep are the workhorses. C#: Select and Where.
    my @squares = map  { $_ * $_ } @numbers;
    my @even    = grep { $_ % 2 == 0 } @numbers;
    say "@squares | @even | ", join('-', map { uc } @words), ' | ', scalar(grep { /i/ } @words);

    # --- Hashes: % names the whole hash, $ one value. C#: Dictionary<string, T> ---
    my %stock = (bolt => 10, nut => 5);      # `=>` is a comma that quotes the word before it
    $stock{screw} = 25;
    delete $stock{nut};
    $stock{bolt} += 5;
    say join ', ', map { "$_=$stock{$_}" } sort keys %stock;    # the key order is random: sort
    say join ' | ', (exists $stock{nut} ? 'has nut' : 'no nut'), scalar(keys %stock),
        "@stock{qw(bolt screw)}", $stock{missing} // 'undef';
    my %count;
    $count{$_}++ for split //, 'mississippi';    # missing entries spring into existence
    my @by_frequency = sort { $count{$b} <=> $count{$a} or $a cmp $b } keys %count;
    say join ' ', map { "$_:$count{$_}" } @by_frequency;
    my %inverse = reverse %stock;                # a hash in list context is a flat key/value list
    my %merged  = (%stock, nut => 1, bolt => 0); # later pairs win
    say join ' ', $inverse{25}, map { "$_=$merged{$_}" } sort keys %merged;

    # --- Context: what an expression means depends on what the surrounding code expects ---
    my @copy      = @numbers;      # list context: the elements
    my $length    = @numbers;      # scalar context: the number of elements
    my ($first)   = @numbers;      # a list assignment: the first element
    my $last_item = (4, 5, 6)[-1]; # a list can be indexed directly
    my $matches   = () = 'banana' =~ /a/g;    # the "count of" idiom: a list assigned to nothing
    say join ' ', scalar(@copy), $length, $first, $last_item, $matches,
        scalar reverse('abc', 'def'), join('', reverse('abc', 'def'));
}

# ==================================================================================================
#  3. REFERENCES AND NESTED DATA
# ==================================================================================================

sub section03_references {
    title('3. References and nested data');

    # A reference is a scalar that points to something else. C#: an object reference.
    # Arrays and hashes hold only scalars, so every nested structure is made of references.
    my @numbers   = (1, 2, 3);
    my %ages      = (Ann => 30);
    my $array_ref = \@numbers;                   # a reference to an existing array
    my $hash_ref  = \%ages;
    my $anon_list = [10, 20, 30];                # [ ] builds an anonymous array
    my $anon_hash = { name => 'tour', tags => ['perl', 'c#'] };    # { } an anonymous hash
    push @$array_ref, 4;                         # dereference with the sigil ...
    $array_ref->[0] = 100;                       # ... or with the arrow
    say "@numbers | $$array_ref[1] $array_ref->[1] | $hash_ref->{Ann} | $anon_hash->{tags}[1]";

    # Postfix dereference reads left to right: ->@* the array, ->%* the hash, ->@[...] a slice.
    say join ' ', scalar($anon_list->@*), join(',', $anon_list->@[0, 1]),
        join(',', sort keys $anon_hash->%*), ref($array_ref), ref($anon_hash), ref(\1),
        ref(sub { });

    # Nested structures: an array of hashes.
    my @people = (
        { name => 'Ann', age => 31, langs => ['C#', 'Perl'] },
        { name => 'Bob', age => 25, langs => [] },
        { name => 'Cid', age => 31, langs => ['Go'] },
    );
    my @by_age = sort { $b->{age} <=> $a->{age} or $a->{name} cmp $b->{name} } @people;
    my %groups;
    push $groups{ $_->{age} > 30 ? 'senior' : 'junior' }->@*, $_->{name} for @people;
    say join(' ', map { $_->{name} } @by_age), ' | ', dump_data(\%groups), ' | ',
        $people[0]{langs}[-1], ' | ', scalar($people[1]{langs}->@*);

    # Copies are shallow unless every level is copied.
    my @shallow = @people;                       # copies the references, not the hashes
    $shallow[0]{name} = 'Changed';
    my @deeper = map { +{ %$_ } } @people;       # new hashes, one level deep
    $deeper[1]{name} = 'Independent';
    say "$people[0]{name} $people[1]{name}";

    # Code references: a dispatch table.
    my %operations = (
        add => sub ($x, $y) { $x + $y },
        mul => sub ($x, $y) { $x * $y },
        pow => sub ($x, $y) { $x**$y },
    );
    say join ' ', map { "$_=" . $operations{$_}->(2, 5) } sort keys %operations;

    # Memory is reference-counted: data is freed the moment nothing points to it, and a
    # cycle needs a weak reference. C#: the garbage collector copes with cycles by itself.
    my $parent = { name => 'root' };
    my $child  = { name => 'leaf', parent => $parent };
    $parent->{child} = $child;
    weaken($child->{parent});
    say "$child->{parent}{name} ", (defined $child->{parent} ? 'alive' : 'gone');
}

# ==================================================================================================
#  4. SUBROUTINES
# ==================================================================================================

sub describe ($name, $greeting = 'Hello', @extras) {    # a default and a "slurpy" array
    my $suffix = @extras ? ' (+' . @extras . ')' : '';
    return "$greeting, $name$suffix";
}

sub divide ($dividend, $divisor) {                      # returns a list
    return (int($dividend / $divisor), $dividend % $divisor);
}

sub legacy_sum {                                        # the old style: arguments arrive in @_
    my $total = 0;
    $total += $_ for @_;
    return $total;
}

sub connect_to (%options) {                             # "named arguments" are a hash
    my %settings = (host => 'localhost', port => 5432, %options);
    return "$settings{host}:$settings{port}";
}

sub context_aware {                                     # wantarray: how is the result used?
    return wantarray ? 'list' : defined(wantarray) ? 'scalar' : 'void';
}

sub make_counter ($start = 0) {                         # returns a closure over $count
    my $count = $start;
    return sub { return ++$count };
}

sub next_id {
    state $id = 0;                                      # initialized once, kept between calls
    return ++$id;
}

our $level = 'global';                                  # `our`: a package (global) variable
sub current_level { return $level }

sub with_local {
    local $level = 'temporarily changed';    # saved now, restored on exit: DYNAMIC scope
    return current_level();
}

sub section04_subroutines {
    title('4. Subroutines');

    say join ' | ', describe('Ann'), describe('Bob', 'Hi'), describe('Cid', 'Hey', 'x', 'y');
    my ($quotient, $remainder) = divide(17, 5);
    my $last = (divide(17, 5))[-1];
    say join ' ', $quotient, $remainder, $last, legacy_sum(1 .. 4), connect_to(),
        connect_to(port => 8080);
    my @list   = context_aware();
    my $scalar = context_aware();
    say "$list[0] $scalar";

    my $counter = make_counter(10);
    $counter->();
    say join ' ', $counter->(), $counter->(), next_id(), next_id(), with_local(), current_level();

    # Subs are values. `__SUB__` is the sub being executed (for anonymous recursion).
    my $compose = sub (@functions) {
        return sub ($x) { $x = $_->($x) for @functions; return $x };
    };
    my $shout     = $compose->(sub ($s) { trim($s) }, sub ($s) { uc $s }, sub ($s) { "$s!" });
    my $factorial = sub ($n) { $n <= 1 ? 1 : $n * __SUB__->($n - 1) };

    # Decorate, sort, undecorate (the "Schwartzian transform"): each key is computed once.
    my @by_length =
        map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [$_, length] } qw(pear fig banana);
    say join ' ', $shout->('  hello '), $factorial->(10), @by_length;

    # The number of arguments is checked at run time.
    eval { describe() };
    say brief($@);
}

# ==================================================================================================
#  5. REGULAR EXPRESSIONS
# ==================================================================================================

sub section05_regular_expressions {
    title('5. Regular expressions');
    my $log = '2026-11-17 ERROR disk full; 2026-11-18 WARN retry; 2026-11-19 ERROR timeout';

    # `=~` applies a pattern to a string. Captures land in $1, $2 ... and, if named, in %+.
    if ($log =~ /(\d{4})-(\d{2})-(\d{2}) (?<level>[A-Z]+)/) {
        say "year $1, month $2, day $3, level $+{level}, match starts at $-[0]";
    }

    # In list context a match returns its captures and, with /g, every match.
    my ($date, $level) = $log =~ /(\S+) (\w+)/;
    my @dates = $log =~ /\d{4}-\d{2}-\d{2}/g;
    my @error_dates;
    while ($log =~ /(?<date>[\d-]+) (?<level>[A-Z]+) (?<text>[^;]+)/g) {    # /g in a loop
        push @error_dates, $+{date} if $+{level} eq 'ERROR';
    }
    say "$date $level | @dates | @error_dates";

    # Substitution. /r returns the result instead of changing the string; /e runs the
    # replacement as code; tr/// translates (and counts) characters.
    (my $european = $log) =~ s/(\d+)-(\d+)-(\d+)/$3.$2.$1/g;
    my $doubled  = 'a1b22'       =~ s/(\d+)/$1 * 2/ger;
    my $squeezed = 'a   b    c'  =~ s/\s+/ /gr;
    my $shouted  = 'hello world' =~ tr/a-z/A-Z/r;
    my $vowels   = ($log =~ tr/aeiou//);
    say substr($european, 0, 10), " | $doubled | $squeezed | $shouted | $vowels vowels";

    # /x allows whitespace and comments inside a pattern; qr// makes a pattern a value.
    my $email = qr/
        ^ (?<user> [\w.]+ )             # the local part
        [@]
        (?<host> [\w.-]+ [.] \w+ ) $    # the domain
    /x;
    say join ' | ', ('ann@example.com' =~ $email ? "user=$+{user} host=$+{host}" : 'no match'),
        ('not an email' =~ $email ? 'match' : 'no match');
    say join ' | ', join(',', split /\s*[,;]\s*/, 'a, b ;c,d'), join('+', split //, 'abc'),
        ('<a><b>' =~ /<(.+?)>/ ? $1 : ''), ('price: 42 EUR' =~ /(\d+)(?=\s*EUR)/ ? $1 : '');
}

# ==================================================================================================
#  6. FILES, I/O AND TEXT
# ==================================================================================================

sub section06_files_and_text {
    title('6. Files, I/O and text');

    my ($fh, $path) = tempfile('perl-tour-XXXX', TMPDIR => 1, UNLINK => 1);
    print {$fh} "first\nsecond\n";               # print to a filehandle
    close $fh or die "close failed: $!";         # `or die` is the idiom; $! is the OS error

    open(my $out, '>>', $path) or die "cannot append to $path: $!";    # mode, then the name
    say {$out} 'third';
    close $out;

    open(my $in, '<', $path) or die "cannot read $path: $!";
    my @lines;
    while (my $line = <$in>) {                   # <$fh> reads one line in scalar context
        chomp $line;                             # strip the line ending
        push @lines, "$.:$line";                 # $. is the current line number
    }
    close $in;
    my $whole = do { local $/; open my $again, '<', $path or die $!; <$again> };    # no $/: all
    my $opened = open(my $missing, '<', "$path.missing");
    say "@lines | ", length($whole), ' bytes | ', (-e $path ? 'exists' : 'missing'), ' | size ',
        -s $path, ' | ', ($opened ? 'opened' : 'open failed: ' . ($!{ENOENT} ? 'ENOENT' : 'other'));

    # A filehandle can also read from (or write to) a string.
    open(my $memory, '<', \"alpha 1\nbeta 22\ngamma 333\n") or die $!;
    my %value_of = map { chomp; split ' ' } <$memory>;    # <$fh> in list context: every line
    say join ', ', map { "$_=$value_of{$_}" } sort keys %value_of;

    # The DATA handle reads whatever follows __DATA__ at the end of this file.
    chomp(my @data = <DATA>);
    say scalar(@data), ' data lines; the longest: ', (sort { length $b <=> length $a } @data)[0];

    # sprintf, pack / unpack, time.
    my $epoch = timegm(0, 30, 9, 17, 10, 2026);  # months count from 0
    say join ' | ', sprintf('%s has %d items (%.1f%%)', 'cart', 3, 42.857),
        join(',', unpack('A3 n C', pack('A3 n C', 'abc', 258, 255))),
        join(' ', map { sprintf '%02x', $_ } unpack('C*', pack('N', 0x11223344))),
        strftime('%Y-%m-%d %H:%M %A', gmtime($epoch + 45 * 86_400 + 3 * 3600));
}

# ==================================================================================================
#  7. PACKAGES AND OBJECTS
# ==================================================================================================
#
#  Classic OOP is done by hand: a class is a package, an object is a reference marked with
#  the package name by `bless`, and a method is a sub that receives the object as its first
#  argument. `$object->method` looks the sub up in the package and its parents.

package Shape {
    use Carp qw(croak);
    my $created = 0;                             # "static" state: a lexical next to the subs

    sub new ($class, %args) {                    # a constructor is an ordinary sub
        my $self = bless { name => $args{name} // 'shape' }, $class;
        $created++;
        return $self;
    }
    sub name ($self)     { return $self->{name} }    # an accessor, written by hand
    sub area ($self)     { croak ref($self) . ' must implement area' }
    sub describe ($self) { return sprintf '%s with area %.2f', $self->name, $self->area }
    sub created ($class) { return $created }         # a class method
}

package Circle {
    use parent -norequire, 'Shape';              # inheritance. C#: class Circle : Shape

    sub new ($class, %args) {
        my $self = $class->SUPER::new(name => 'circle');    # C#: base(...)
        $self->{radius} = $args{radius};
        return $self;
    }
    sub area ($self) { return 3.141592653589793 * $self->{radius}**2 }
}

package Square {
    use parent -norequire, 'Shape';

    sub new ($class, %args) {
        my $self = $class->SUPER::new(name => 'square');
        $self->{side} = $args{side};
        return $self;
    }
    sub area ($self)     { return $self->{side}**2 }
    sub describe ($self) { return 'a perfect ' . $self->SUPER::describe() }
}

package Vec2 {
    use overload                                 # operator overloading
        '+'  => sub ($p, $q, $swapped) { Vec2->new($p->{x} + $q->{x}, $p->{y} + $q->{y}) },
        '==' => sub ($p, $q, $swapped) { $p->{x} == $q->{x} && $p->{y} == $q->{y} },
        '""' => sub ($self, @) { "($self->{x}, $self->{y})" };    # C#: ToString()

    sub new ($class, $x, $y) { return bless { x => $x, y => $y }, $class }

    our $AUTOLOAD;

    sub AUTOLOAD ($self, @arguments) {           # called for methods that do not exist
        my $method = $AUTOLOAD =~ s/.*:://r;     # C#: DynamicObject.TryInvokeMember
        return if $method eq 'DESTROY';
        die "no method $method\n" unless exists $self->{$method};
        return $self->{$method};
    }
}

# The `class` syntax (experimental since 5.38): the constructor and the object layout are
# generated; fields are private lexical variables, and `$self` is implicit in a method.
class Point {
    field $x :param = 0;                         # :param: set from the constructor arguments
    field $y :param = 0;
    field @history;

    method coords { return ($x, $y) }

    method move ($dx, $dy) {
        push @history, [$x, $y];
        $x += $dx;
        $y += $dy;
        return $self;                            # returning $self allows chaining
    }
    method moves     { return scalar @history }
    method to_string { return "Point($x, $y)" }
}

class Point3D :isa(Point) {                      # inheritance; the parent's fields stay private
    field $z :param = 0;
    ADJUST { $z += 0 }                           # runs while the object is constructed

    method to_string { return sprintf 'Point3D(%s, %d)', join(', ', $self->coords), $z }
}

package main;

sub section07_objects {
    title('7. Packages and objects');

    my @shapes = (Circle->new(radius => 1), Square->new(side => 2));
    say join '; ', map { $_->describe } @shapes;
    say join ' | ', ref($shapes[0]), ($shapes[0] isa Shape ? 'isa Shape' : 'not a Shape'),
        ($shapes[1]->can('area') ? 'can area' : 'cannot'), Shape->created, blessed($shapes[0]),
        reftype($shapes[0]);
    my $method = 'describe';                     # a method can be called by name
    eval { Shape->new->area };
    say $shapes[1]->$method(), ' | ', brief($@);

    # Encapsulation is a convention: the object is a plain hash, and $shapes[0]{radius} works.
    my $v = Vec2->new(1, 2) + Vec2->new(3, 4);
    say "$v ", ($v == Vec2->new(4, 6) ? 'equal' : 'different'), ' ', $v->x, ' ', $v->y;

    my $point = Point->new(x => 1, y => 2);
    $point->move(2, 3)->move(1, 1);
    my $point3 = Point3D->new(x => 1, z => 7);
    say join ' | ', $point->to_string, $point->moves, $point3->to_string,
        ($point3 isa Point ? 'isa Point' : 'not a Point'), ref($point3);
}

# ==================================================================================================
#  8. ERRORS
# ==================================================================================================

package ConfigError {                            # any value can be thrown, objects included
    sub new ($class, %args)   { return bless {%args}, $class }
    sub throw ($class, %args) { die $class->new(%args) }
    sub message ($self)       { return "config key '$self->{key}': $self->{reason}" }
}

sub parse_port ($text) {
    ConfigError->throw(key => 'port', reason => 'not a number') unless $text =~ /^\d+$/;
    ConfigError->throw(key => 'port', reason => "$text is out of range")
        unless $text >= 1 && $text <= 65535;
    return $text + 0;
}

sub section08_errors {
    title('8. Errors');

    # The classic mechanism: `die` raises, `eval { }` catches, the error ends up in $@.
    for my $text (qw(8080 http 99999)) {
        my $port = eval { parse_port($text) };
        if (my $error = $@) {
            say $error isa ConfigError ? $error->message : "unexpected: $error";
        }
        else {
            say "port $port";
        }
    }

    # try / catch / finally: a feature since 5.34, no longer experimental since 5.40.
    my @log;
    try {
        push @log, 'try';
        die "a text error\n";    # the trailing newline suppresses " at FILE line N."
    }
    catch ($error) {
        chomp $error;
        push @log, "catch: $error";
    }
    finally {
        push @log, 'finally';
    }
    say join ' | ', @log;

    # Many built-in failures only warn (on STDERR); a handler can collect the warnings.
    my @warnings;
    {
        local $SIG{__WARN__} = sub ($message) { push @warnings, brief($message) };
        my $word      = 'abc';
        my $number    = $word + 1;
        my @empty;
        my $undefined = $empty[5];
        my $text      = "value: $undefined";
    }
    my $zero   = 0;
    my $result = eval { 1 / $zero } // 'died: ' . brief($@);
    say join ' | ', @warnings, $result;

    # defer (experimental): a block that runs when the enclosing scope is left.
    # C#: finally, or `using` for cleanup.
    my @order;
    {
        defer { push @order, 'deferred cleanup' }
        push @order, 'work';
    }
    say join ' | ', @order;
}

# ==================================================================================================
#  9. IDIOMS AND METAPROGRAMMING
# ==================================================================================================

sub section09_idioms {
    title('9. Idioms and metaprogramming');

    # List::Util is the standard toolbox. C#: LINQ.
    my @numbers = (5, 3, 8, 1, 9, 3);
    say join ' ', sum(@numbers), max(@numbers), min(@numbers), (first { $_ > 5 } @numbers),
        (reduce { $a * $b } 1 .. 5), ((any { $_ > 8 } @numbers) ? 'any' : 'none'),
        ((all { $_ > 0 } @numbers) ? 'all' : 'not all'), join(',', uniq @numbers),
        (looks_like_number('1e3') ? 'numeric' : 'text');

    # An iterator is a closure. C#: an iterator method with yield return.
    my ($current, $next) = (0, 1);
    my $fibonacci = sub {
        my $value = $current;
        ($current, $next) = ($next, $current + $next);
        return $value;
    };
    say join ' ', map { $fibonacci->() } 1 .. 10;

    # The magic string increment, ranges over strings, the repetition operator on lists.
    my $version = 'aa9';
    $version++;
    say join ' ', $version, join('', 'a' .. 'e'), join(',', (0) x 3),
        join(',', map { ucfirst } qw(x y));

    # The symbol table is open: subs can be created, replaced and inspected at run time.
    for my $color (qw(red green)) {
        no strict 'refs';                        # permit a string as a symbol name
        *{"paint_$color"} = sub ($text) { return "<$color>$text</$color>" };
    }
    say join ' ', main->can('paint_red')->('x'), paint_green('y'),
        (defined &paint_blue ? 'has paint_blue' : 'no paint_blue'), __PACKAGE__;

    # String eval compiles code at run time. Powerful, and dangerous with untrusted input.
    my $cube = eval 'sub ($x) { $x ** 3 }' or die $@;
    my $broken = eval '2 +';
    say $cube->(3), ' ', (defined $broken ? 'compiled' : 'the syntax error is in $@');

    # Sorting on several keys, descending and ascending.
    my %salary = (Ann => 5200, Bob => 4100, Cid => 5200);
    my @by_salary = sort { $salary{$b} <=> $salary{$a} or $a cmp $b } keys %salary;
    say join ', ', map { "$_ $salary{$_}" } @by_salary;
}

# ==================================================================================================
#  10. THE NEWEST
# ==================================================================================================

sub section10_newest {
    title('10. The newest');

    # Used above: say and state (5.10), postfix dereference (5.24), signatures and `isa`
    # (stable since 5.36), try / catch / finally, defer, the builtin:: functions, and the
    # class / field / method syntax (5.38).
    my %config = (host => 'localhost', port => 5432);
    my @pairs;
    for my ($key, $value) (map { $_ => $config{$_} } sort keys %config) {    # two at a time
        push @pairs, "$key=$value";
    }
    for my ($index, $item) (indexed 'a', 'b') {  # builtin::indexed: (0, 'a', 1, 'b')
        push @pairs, "$index:$item";
    }
    say join ' ', @pairs, (is_bool(true) ? 'true is a boolean' : ''),
        (is_bool(1) ? '' : '1 is not'), ceil(2.1), floor(-2.1), '[' . trim('  x  ') . ']',
        (false ? '' : 'false is false');
    say 'running on Perl ', $^V;

    # Newer than the interpreter this file was verified with — NOT run here:
    #   5.40   `use v5.40;` imports the builtin functions and makes try / catch stable;
    #          `field $x :reader;` generates an accessor; `__CLASS__`; `^^` (logical xor)
    #   5.42   `field $x :writer;`, lexical methods (`my method`), and the experimental
    #          list operators `any { ... } @list` and `all { ... } @list`
}

# ==================================================================================================
#  ENTRY POINT
# ==================================================================================================

sub main {
    section01_basics();
    section02_arrays_and_hashes();
    section03_references();
    section04_subroutines();
    section05_regular_expressions();
    section06_files_and_text();
    section07_objects();
    section08_errors();
    section09_idioms();
    section10_newest();
    return 0;
}

# A script runs from top to bottom; calling main() at the end is just a convention.
exit main();

__DATA__
alpha
beta gamma
delta
