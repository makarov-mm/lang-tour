! =================================================================================================
!  FORTRAN FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
!
!  This is modern Fortran: free-form source and the features of Fortran 90 to 2018 (modules,
!  array expressions, derived types with type-bound procedures, interoperability with C). It is
!  not the fixed-form FORTRAN 77 of old textbooks, although compilers still accept that too.
!
!  Build and run:
!
!      gfortran -std=f2018 -O2 -Wall -Wextra -pedantic fortran_tour.f90 -o fortran_tour
!      ./fortran_tour
!
!  Verified with GNU Fortran (gfortran) 14.2 on Linux: no warnings, also with -fcheck=all and
!  with -fopenmp. The compiler writes a .mod file for every module (and a .smod file for the
!  submodule) into the current directory; they are the compiled interfaces and can be deleted.
!
!  How to read. The modules come first because a module must be defined before it is used;
!  the main program at the very end calls the sections in order, and every section prints
!  what it demonstrates. A "C#:" note gives the closest counterpart in C#. A line that is
!  commented out and followed by an error message does not compile, and that is the point.
!
!  The main differences from C# to keep in mind from the first line:
!
!   1. Arrays are the centre of the language. Indexes start at 1 unless declared otherwise,
!      whole arrays and sections of them take part in expressions (a = b + 2 * c), and an
!      array of several dimensions is stored column by column.
!   2. Names and keywords are case-insensitive.
!   3. Declarations come first in a scope, before the executable statements. Always write
!      `implicit none`: without it an undeclared name silently becomes a variable whose type
!      follows from its first letter.
!   4. Arguments are passed by reference. The intent attribute (in, out, inout) says what a
!      procedure may do with them.
!   5. A function is used in an expression; a subroutine (C#: a void method) is invoked with
!      the call statement.
!   6. There is no garbage collector and hardly a need for one: an allocatable variable owns
!      its memory and frees it when it goes out of scope.
!   7. A real literal is single precision unless it carries a kind suffix: 0.1 is not
!      0.1_dp. Integer division truncates: 7 / 2 is 3.
!   8. There are no exceptions. Operations that can fail report through optional status
!      arguments (stat=, iostat=); error stop ends the program.
!
!  Contents:
!    1. Basics: types, kinds, operators             8. Character strings
!    2. Control flow                                9. Input, output and files
!    3. Arrays                                     10. Procedures as values
!    4. Procedures                                 11. Numerics: kinds, IEEE, bits, random
!    5. Modules, generic names, operators          12. Errors without exceptions
!    6. Derived types and object orientation       13. Interoperability with C
!    7. Allocatable variables and pointers         14. Parallel features and the newest
! =================================================================================================

! A module is a namespace and a static class in one: it holds constants, types, variables and
! procedures. C#: a namespace plus a static class.
module tour_common
    ! iso_fortran_env is an intrinsic module that names the kinds and the units of the platform.
    use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64
    implicit none                       ! covers every procedure of the module as well
    private                             ! nothing is visible outside unless it is made public
    public :: int32, int64, real32, real64, dp, pi, title

    ! A named constant. C#: const. A "kind" is the size parameter of a type, and dp is the kind
    ! of a double-precision real: real(dp) is C#'s double.
    integer, parameter :: dp = real64
    real(dp), parameter :: pi = 3.141592653589793_dp

contains

    subroutine title(number, text)
        integer, intent(in) :: number
        character(len=*), intent(in) :: text            ! len=*: any length, taken from the caller

        print '(/, a, i0, a, a, a)', '=== ', number, '. ', text, ' ==='
    end subroutine title

end module tour_common

! =================================================================================================
!  The module for section 5: generic names and operators
! =================================================================================================

module tour_vectors
    use tour_common, only: dp
    implicit none
    private
    public :: vector, norm, swap, operator(+), operator(*), operator(.dot.)

    ! A derived type. C#: struct. Components can have default values.
    type :: vector
        real(dp) :: x = 0.0_dp
        real(dp) :: y = 0.0_dp
    end type vector

    ! A generic name collects specific procedures; the compiler picks one by the arguments.
    ! C#: overloads.
    interface swap
        module procedure swap_integers, swap_reals
    end interface swap

    ! Operators are overloaded in the same way, and new operators can be invented: .dot.
    interface operator(+)
        module procedure add_vectors
    end interface operator(+)

    interface operator(*)
        module procedure scale_vector
    end interface operator(*)

    interface operator(.dot.)
        module procedure dot_vectors
    end interface operator(.dot.)

    ! protected: everyone can read the variable, only this module can change it.
    ! C#: public get, private set.
    integer, public, protected :: swap_count = 0

contains

    pure function add_vectors(a, b) result(c)
        type(vector), intent(in) :: a, b
        type(vector) :: c

        c = vector(a%x + b%x, a%y + b%y)                ! % selects a component. C#: the dot
    end function add_vectors

    pure function scale_vector(a, factor) result(c)
        type(vector), intent(in) :: a
        real(dp), intent(in) :: factor
        type(vector) :: c

        c = vector(a%x * factor, a%y * factor)
    end function scale_vector

    pure function dot_vectors(a, b) result(d)
        type(vector), intent(in) :: a, b
        real(dp) :: d

        d = a%x * b%x + a%y * b%y
    end function dot_vectors

    pure function norm(a) result(length)
        type(vector), intent(in) :: a
        real(dp) :: length

        length = sqrt(a .dot. a)
    end function norm

    subroutine swap_integers(a, b)
        integer, intent(inout) :: a, b
        integer :: keep

        keep = a
        a = b
        b = keep
        swap_count = swap_count + 1
    end subroutine swap_integers

    subroutine swap_reals(a, b)
        real(dp), intent(inout) :: a, b
        real(dp) :: keep

        keep = a
        a = b
        b = keep
        swap_count = swap_count + 1
    end subroutine swap_reals

end module tour_vectors

! =================================================================================================
!  The module for section 6: derived types and object orientation
! =================================================================================================

module tour_shapes
    use tour_common, only: dp, pi
    implicit none
    private
    public :: shape_t, circle_t, rectangle_t, square_t, shape_box, tracker_t, show_any

    ! An abstract type with a deferred binding. C#: an abstract class with an abstract method.
    type, abstract :: shape_t
        character(len=:), allocatable :: name           ! a string of any length
    contains
        procedure(area_function), deferred :: area      ! C#: abstract
        procedure :: describe => shape_describe         ! can be overridden. C#: virtual
    end type shape_t

    ! The signature of the deferred binding. C#: the declaration of the abstract method.
    abstract interface
        pure function area_function(self) result(area)
            import :: shape_t, dp                       ! an interface body sees nothing by itself
            class(shape_t), intent(in) :: self
            real(dp) :: area
        end function area_function
    end interface

    ! extends is inheritance. C#: class Circle : Shape
    type, extends(shape_t) :: circle_t
        real(dp) :: radius = 1.0_dp
    contains
        procedure :: area => circle_area                ! C#: override
    end type circle_t

    type, extends(shape_t) :: rectangle_t
        real(dp) :: width = 1.0_dp
        real(dp) :: height = 1.0_dp
    contains
        procedure :: area => rectangle_area
    end type rectangle_t

    type, extends(rectangle_t) :: square_t
    contains
        procedure :: describe => square_describe
    end type square_t

    ! A generic name that equals the name of a type adds a constructor. C#: a constructor.
    interface square_t
        module procedure new_square
    end interface square_t

    ! All elements of an array have one type, so an array of DIFFERENT shapes is an array of
    ! boxes with a polymorphic component each. C#: Shape[] holds references anyway.
    type :: shape_box
        class(shape_t), allocatable :: item
    end type shape_box

    ! A type with a finalizer. It runs at a known moment: when the variable goes out of scope
    ! or is deallocated. C#: Dispose with `using`; C++: a destructor.
    type :: tracker_t
        character(len=:), allocatable :: label
    contains
        final :: tracker_finalize
    end type tracker_t

contains

    ! The first argument of a type-bound procedure is the object itself, and it is declared
    ! class(...): "this type or any extension of it". C#: this.
    function shape_describe(self) result(text)
        class(shape_t), intent(in) :: self
        character(len=:), allocatable :: text
        character(len=32) :: buffer

        write (buffer, '(f0.2)') self%area()            ! dispatched at run time
        text = self%name // ' with the area ' // trim(buffer)
    end function shape_describe

    pure function circle_area(self) result(area)
        class(circle_t), intent(in) :: self
        real(dp) :: area

        area = pi * self%radius ** 2
    end function circle_area

    pure function rectangle_area(self) result(area)
        class(rectangle_t), intent(in) :: self
        real(dp) :: area

        area = self%width * self%height
    end function rectangle_area

    function square_describe(self) result(text)
        class(square_t), intent(in) :: self
        character(len=:), allocatable :: text

        ! The parent is a component named after its type. C#: base.Describe()
        text = 'a square: ' // self%rectangle_t%describe()
    end function square_describe

    function new_square(side) result(square)
        real(dp), intent(in) :: side
        type(square_t) :: square

        square%name = 'square'
        square%width = side
        square%height = side
    end function new_square

    subroutine tracker_finalize(self)
        type(tracker_t), intent(inout) :: self

        if (allocated(self%label)) print '(a, a)', '  finalized: ', self%label
    end subroutine tracker_finalize

    ! class(*) accepts a value of any type. C#: object. select type is the type test and the
    ! cast in one. C#: a switch with type patterns.
    subroutine show_any(value)
        class(*), intent(in) :: value

        select type (value)
        type is (integer)
            print '(a, i0)', '  an integer: ', value
        type is (real(dp))
            print '(a, f0.2)', '  a double: ', value
        type is (character(len=*))
            print '(a, a)', '  a string: ', value
        class is (shape_t)
            print '(a, a)', '  a shape: ', value%describe()
        class default
            print '(a)', '  something else'
        end select
    end subroutine show_any

end module tour_shapes

! =================================================================================================
!  The module and the submodule for section 14
! =================================================================================================

! A module can keep only the interface of a procedure and leave the body to a submodule.
! Changing the body then does not force the users of the module to be recompiled.
! C#: an interface and its implementation; C++: a header and a source file.
module tour_geometry
    use tour_common, only: dp
    implicit none
    private
    public :: triangle_area

    interface
        pure module function triangle_area(a, b, c) result(area)
            real(dp), intent(in) :: a, b, c
            real(dp) :: area
        end function triangle_area
    end interface
end module tour_geometry

submodule (tour_geometry) tour_geometry_implementation
    implicit none
contains
    module procedure triangle_area
        real(dp) :: s

        s = (a + b + c) / 2                             ! Heron's formula
        area = sqrt(s * (s - a) * (s - b) * (s - c))
    end procedure triangle_area
end submodule tour_geometry_implementation

! =================================================================================================
!  The sections of the tour
! =================================================================================================

module tour_sections
    use, intrinsic :: iso_c_binding, only: c_int, c_double, c_char, c_size_t, c_ptr, c_funptr, &
                                           c_null_char, c_loc, c_funloc, c_f_pointer, c_sizeof
    use tour_common
    implicit none
    private
    public :: section01_basics, section02_control_flow, section03_arrays, section04_procedures, &
              section05_modules, section06_types, section07_memory, section08_strings, &
              section09_io, section10_procedure_values, section11_numerics, section12_errors, &
              section13_c_interop, section14_newest

    ! ---- for section 7: a list whose nodes own their successors ----
    type :: node_t
        integer :: value = 0
        type(node_t), allocatable :: next
    end type node_t

    ! ---- for section 10: the signature of a real function of one real argument ----
    abstract interface
        pure function real_function(x) result(y)
            import :: dp
            real(dp), intent(in) :: x
            real(dp) :: y
        end function real_function
    end interface

    type :: operation_t
        character(len=6) :: name = ''
        procedure(real_function), pointer, nopass :: apply => null()
    end type operation_t

    ! ---- for section 13: C functions and a C struct ----
    interface
        ! size_t strlen(const char *s);
        function c_strlen(s) bind(c, name='strlen') result(length)
            import :: c_char, c_size_t
            character(kind=c_char), intent(in) :: s(*)
            integer(c_size_t) :: length
        end function c_strlen

        ! void qsort(void *base, size_t count, size_t size,
        !            int (*compare)(const void *, const void *));
        subroutine c_qsort(base, count, width, compare) bind(c, name='qsort')
            import :: c_ptr, c_size_t, c_funptr
            type(c_ptr), value :: base                  ! value: passed by value, as C expects
            integer(c_size_t), value :: count, width
            type(c_funptr), value :: compare
        end subroutine c_qsort
    end interface

    ! struct { double x; double y; }. C#: [StructLayout(LayoutKind.Sequential)]
    type, bind(c) :: c_point
        real(c_double) :: x, y
    end type c_point

contains

    ! =============================================================================================
    !  1. Basics: types, kinds, operators
    ! =============================================================================================

    subroutine section01_basics()
        ! A declaration: the type, attributes, a double colon, the names. C#: int count;
        integer :: count                                ! the default integer: 32 bits
        integer(int64) :: big                           ! C#: long
        real :: rough                                   ! the default real: single. C#: float
        real(dp) :: precise                             ! C#: double
        complex(dp) :: z                                ! complex numbers are built in
        logical :: done                                 ! C#: bool; .true. and .false.
        character(len=6) :: word                        ! a string of exactly six characters
        integer, parameter :: answer = 42               ! a named constant

        call title(1, 'Basics: types, kinds, operators')

        count = 7
        big = 9000000000_int64                          ! the kind follows an underscore
        rough = 0.1
        precise = 0.1_dp                                ! without _dp it is the single 0.1
        z = (3.0_dp, 4.0_dp)
        done = .true.
        word = 'tour'                                   ! padded with blanks to six characters

        ! print '(format)', items. The format (*(g0)) writes any number of items of any
        ! type, each as short as possible.
        print '(*(g0))', 'count ', count, ', big ', big, ', answer ', answer, ', done ', done
        print '(*(g0))', 'word [', word, '], trimmed [', trim(word), '], length ', len(word)
        print '(*(g0))', 'rough ', rough, ', precise ', precise
        print '(a, es8.2)', 'the single 0.1 differs from 0.1_dp by ', real(rough, dp) - precise

        ! Names are case-insensitive: this is the variable declared above.
        COUNT = Count + 0

        ! Arithmetic: + - * / and ** for powers. Integer division truncates.
        print '(*(g0))', '7 / 2 = ', count / 2, ', mod(7, 3) = ', mod(count, 3), &
            ', 2 ** 10 = ', 2 ** 10
        print '(a, f0.2, a, f0.4)', '7 / 2.0 = ', count / 2.0, ', 2 ** 0.5 = ', 2.0_dp ** 0.5_dp

        ! Comparison: == /= < <= > >=. Logic: .and. .or. .not. .eqv. .neqv.
        ! (The FORTRAN 77 spellings .eq. .ne. .lt. .le. .gt. .ge. still work.)
        print '(*(g0))', '7 /= 6: ', count /= 6, ', 7 > 3 and not done: ', &
            count > 3 .and. .not. done

        ! Conversions are functions: real, int, nint, cmplx. int truncates, nint rounds.
        ! An assignment converts silently: count = 3.7 would store 3 (gfortran -Wall warns).
        print '(*(g0))', 'int(3.7) = ', int(3.7_dp), ', nint(3.7) = ', nint(3.7_dp), &
            ', floor(-3.7) = ', floor(-3.7_dp)
        print '(a, f0.1)', 'real(count) / 2 = ', real(count, dp) / 2

        ! Complex numbers. C#: System.Numerics.Complex
        print '(3(a, f0.1))', 'abs(z) = ', abs(z), ', real part ', z%re, &
            ', imaginary part of z * z = ', aimag(z * z)
    end subroutine section01_basics

    ! =============================================================================================
    !  2. Control flow
    ! =============================================================================================

    subroutine section02_control_flow()
        integer, parameter :: samples(5) = [2, 5, 9, 42, -1]
        integer :: i, j, n, total
        real(dp) :: x

        call title(2, 'Control flow')

        n = 7
        if (mod(n, 2) == 0) then
            print '(a)', 'even'
        else if (n > 5) then
            print '(a)', 'odd and greater than 5'
        else
            print '(a)', 'odd and small'
        end if
        if (n > 0) print '(a)', 'positive'              ! the one-line form

        ! select case takes values, lists and ranges, and there is no fall-through.
        ! C#: switch
        do i = 1, size(samples)
            select case (samples(i))
            case (1:3)
                print '(i0, a)', samples(i), ': from 1 to 3'
            case (4, 5, 6)
                print '(i0, a)', samples(i), ': one of 4, 5, 6'
            case (7:9)
                print '(i0, a)', samples(i), ': from 7 to 9'
            case (:0)
                print '(i0, a)', samples(i), ': zero or less'
            case default
                print '(i0, a)', samples(i), ': something else'
            end select
        end do

        ! do variable = first, last [, step]: BOTH bounds are included.
        total = 0
        do i = 1, 5
            total = total + i
        end do
        do i = 10, 0, -5
            total = total + i
        end do
        print '(a, i0)', 'total ', total

        ! do while, and the endless do with exit. exit is C#'s break, cycle is continue.
        n = 1
        do while (n < 100)
            n = n * 2
        end do
        j = 0
        do
            j = j + 1
            if (j >= 3) exit
        end do
        print '(a, i0, a, i0)', 'n ', n, ', j ', j

        ! A construct can have a name, and exit and cycle can name an OUTER loop.
        ! C#: goto or a flag.
        total = 0
        rows: do i = 1, 3
            do j = 1, 3
                if (j > i) cycle rows
                if (i == 3) exit rows
                total = total + 10 * i + j
            end do
        end do rows
        print '(a, i0)', '11 + 21 + 22 = ', total

        ! block opens a scope with declarations of its own.
        block
            integer :: doubled

            doubled = 2 * total
            print '(a, i0)', 'inside the block: ', doubled
        end block

        ! associate gives a name to an expression or to a variable for a few lines.
        x = 3.0_dp
        associate (hypotenuse => sqrt(x ** 2 + 4.0_dp ** 2), half => x / 2)
            print '(a, f0.1, a, f0.1)', 'hypotenuse ', hypotenuse, ', half ', half
        end associate

        ! merge(a, b, condition) chooses between two values. Unlike C#'s ?: it is an ordinary
        ! function: both values are evaluated.
        print '(a, a)', 'n is ', trim(merge('big  ', 'small', n > 100))
    end subroutine section02_control_flow

    ! =============================================================================================
    !  3. Arrays
    ! =============================================================================================

    subroutine section03_arrays()
        integer :: a(5)                                 ! five elements: a(1) ... a(5)
        integer :: shifted(-2:2)                        ! any bounds can be declared
        real(dp) :: grid(2, 3)                          ! 2 rows, 3 columns; up to 15 dimensions
        integer, allocatable :: evens(:)                ! the size is decided at run time
        integer :: i

        call title(3, 'Arrays')

        a = [3, 1, 4, 1, 5]                             ! an array constructor
        shifted = 0                                     ! a scalar goes to every element
        shifted(-2) = 7
        print '(a, *(i0, 1x))', 'a: ', a
        print '(*(g0))', 'size ', size(a), ', the bounds of shifted: ', lbound(shifted, 1), &
            ' to ', ubound(shifted, 1), ', its first element: ', shifted(-2)

        ! Sections: a(first:last:step), both ends included. A section is not a copy; it can
        ! stand on the left of an assignment. C#: Span<T> and ranges
        print '(a, *(i0, 1x))', 'a(2:4): ', a(2:4)
        print '(a, *(i0, 1x))', 'a(::2): ', a(::2)
        print '(a, *(i0, 1x))', 'reversed: ', a(5:1:-1)
        print '(a, *(i0, 1x))', 'picked by an index array: ', a([1, 5, 5])

        ! Expressions and most intrinsic functions work on whole arrays, element by element.
        print '(a, *(i0, 1x))', 'a * 2 + 1: ', a * 2 + 1
        print '(a, *(f0.2, 1x))', 'sqrt(a): ', sqrt(real(a, dp))

        ! Reductions and queries. C#: Sum, Max, Count, Any, All, Where of LINQ
        print '(*(g0))', 'sum ', sum(a), ', product ', product(a), ', maxval ', maxval(a), &
            ', position of the maximum ', maxloc(a, 1)
        print '(*(g0))', 'count(a > 2) = ', count(a > 2), ', any(a > 4) = ', any(a > 4), &
            ', all(a > 0) = ', all(a > 0), ', sum of those above 2: ', sum(a, mask=a > 2)
        print '(a, *(i0, 1x))', 'pack(a, a > 2): ', pack(a, a > 2)

        ! An implied do loop inside a constructor. Assigning to an allocatable array
        ! allocates it. C#: Enumerable.Range(1, 5).Select(i => 2 * i).ToArray()
        evens = [(2 * i, i = 1, 5)]
        print '(a, *(i0, 1x))', 'evens: ', evens
        print '(a, i0)', 'dot_product(a, evens) = ', dot_product(a, evens)

        ! where is a masked assignment.
        where (a > 3)
            a = 0
        elsewhere
            a = a * 10
        end where
        print '(a, *(i0, 1x))', 'after where: ', a

        ! Two dimensions. The elements are stored column by column, so reshape fills the first
        ! column first (C and C# go row by row).
        grid = reshape([(real(i, dp), i = 1, 6)], [2, 3])
        do i = 1, size(grid, 1)
            print '(a, i0, a, *(f4.1))', 'row ', i, ':', grid(i, :)
        end do
        print '(a, *(i0, 1x))', 'shape: ', shape(grid)
        print '(a, *(f0.1, 1x))', 'the sums of the columns: ', sum(grid, dim=1)
        print '(a, *(f0.1, 1x))', 'grid times its transpose: ', matmul(grid, transpose(grid))
    end subroutine section03_arrays

    ! =============================================================================================
    !  4. Procedures
    ! =============================================================================================

    ! A function returns its result variable. pure promises that there are no side effects,
    ! and the compiler checks it. An assumed-shape argument (:) brings its bounds along.
    ! C#: static double Mean(ReadOnlySpan<double> values)
    pure function mean(values) result(m)
        real(dp), intent(in) :: values(:)
        real(dp) :: m

        m = sum(values) / max(size(values), 1)
    end function mean

    ! A subroutine returns results through its arguments. C#: out parameters
    pure subroutine min_max(values, lowest, highest)
        real(dp), intent(in) :: values(:)
        real(dp), intent(out) :: lowest, highest

        lowest = minval(values)
        highest = maxval(values)
    end subroutine min_max

    ! An optional argument has no default value: the procedure asks present().
    pure function power(base, exponent) result(p)
        real(dp), intent(in) :: base
        integer, intent(in), optional :: exponent
        real(dp) :: p
        integer :: e

        e = 2
        if (present(exponent)) e = exponent
        p = base ** e
    end function power

    ! An elemental procedure is written for scalars and works on arrays of any shape.
    elemental function clamp(x, low, high) result(c)
        integer, intent(in) :: x, low, high
        integer :: c

        c = min(max(x, low), high)
    end function clamp

    ! recursive is the default since Fortran 2018; older standards demand the keyword.
    pure recursive function factorial(n) result(f)
        integer, intent(in) :: n
        integer(int64) :: f

        if (n <= 1) then
            f = 1
        else
            f = n * factorial(n - 1)
        end if
    end function factorial

    function next_ticket() result(ticket)
        integer :: ticket
        ! save keeps the variable alive between calls. C#: a static field.
        ! Beware: an initial value in a declaration implies save even when the word is not
        ! written. `integer :: issued = 100` is initialized once, not on every call.
        integer, save :: issued = 100

        issued = issued + 1
        ticket = issued
    end function next_ticket

    subroutine section04_procedures()
        real(dp) :: samples(5), lowest, highest
        integer :: calls, first, second

        call title(4, 'Procedures')

        samples = [2.0_dp, 8.0_dp, 4.0_dp, 6.0_dp, 5.0_dp]
        call min_max(samples, lowest, highest)          ! a subroutine is invoked with call
        print '(3(a, f0.1))', 'mean ', mean(samples), ', lowest ', lowest, ', highest ', highest
        ! A section is passed without a copy; the procedure sees an array that starts at 1.
        print '(a, f0.1)', 'the mean of every second sample: ', mean(samples(::2))

        ! Optional and keyword arguments.
        print '(3(a, f0.1))', 'power(3) = ', power(3.0_dp), ', power(2, 10) = ', &
            power(2.0_dp, 10), ', by keyword: ', power(exponent=3, base=2.0_dp)

        print '(a, i0, a, *(i0, 1x))', 'clamp(15, 0, 10) = ', clamp(15, 0, 10), &
            ', clamp of an array: ', clamp([-5, 3, 12], 0, 10)
        print '(a, i0)', 'factorial(20) = ', factorial(20)
        first = next_ticket()
        second = next_ticket()
        print '(a, i0, 1x, i0)', 'tickets: ', first, second

        ! An internal procedure, placed after `contains`, sees the variables of its host.
        ! C#: a local function
        calls = 0
        call bump()
        call bump()
        print '(a, i0)', 'calls counted by the internal procedure: ', calls

    contains

        subroutine bump()
            calls = calls + 1
        end subroutine bump

    end subroutine section04_procedures

    ! =============================================================================================
    !  5. Modules, generic names, operators     (the module tour_vectors is above)
    ! =============================================================================================

    subroutine section05_modules()
        ! use brings the public names of a module into scope; only: limits them, and
        ! local => original renames one. C#: using, and a using alias.
        use tour_vectors, only: vector, length => norm, swap, swap_count, &
                                operator(+), operator(*), operator(.dot.)
        type(vector) :: u, v, w, origin                 ! origin gets the default values
        integer :: i, j
        real(dp) :: p, q

        call title(5, 'Modules, generic names, operators')

        u = vector(1.0_dp, 2.0_dp)                      ! the structure constructor
        v = vector(y=4.0_dp, x=3.0_dp)                  ! components by keyword
        w = u + v * 2.0_dp
        print '(4(a, f0.1), a, f3.1)', 'u + v * 2 = (', w%x, ', ', w%y, '), u .dot. v = ', &
            u .dot. v, ', length of v = ', length(v), ', the default x is ', origin%x

        i = 1
        j = 2
        p = 1.5_dp
        q = 2.5_dp
        call swap(i, j)                                 ! resolved to swap_integers
        call swap(p, q)                                 ! resolved to swap_reals
        print '(2(a, i0), 2(a, f0.1), a, i0)', 'swapped: ', i, ' ', j, ' and ', p, ' ', q, &
            '; swap_count is ', swap_count
        ! swap_count = 0
        !     Error: Variable 'swap_count' is PROTECTED and cannot appear in a variable
        !     definition context (assignment)
    end subroutine section05_modules

    ! =============================================================================================
    !  6. Derived types and object orientation     (the module tour_shapes is above)
    ! =============================================================================================

    subroutine section06_types()
        use tour_shapes
        type(shape_box) :: shapes(3)
        class(shape_t), allocatable :: one              ! polymorphic. C#: a base-class reference
        type(tracker_t), allocatable :: on_heap
        real(dp) :: total
        integer :: i

        call title(6, 'Derived types and object orientation')

        ! allocate with source= gives a polymorphic variable the type and the value of an
        ! expression. The structure constructor of an extended type takes the inherited
        ! components too. (The assignment `one = circle_t(...)` means the same since Fortran
        ! 2008, but gfortran 14 leaks memory there and miscompiles it for shapes(i)%item.)
        allocate (one, source=circle_t(name='disc', radius=1.0_dp))
        print '(a)', one%describe()

        allocate (shapes(1)%item, source=circle_t(name='wheel', radius=2.0_dp))
        allocate (shapes(2)%item, source=rectangle_t(name='door', width=1.0_dp, height=2.0_dp))
        allocate (shapes(3)%item, source=square_t(3.0_dp))      ! the constructor new_square
        total = 0.0_dp
        do i = 1, size(shapes)
            print '(a)', shapes(i)%item%describe()
            total = total + shapes(i)%item%area()
            ! select type: `type is` matches one type exactly, `class is` an extension too.
            select type (item => shapes(i)%item)
            type is (circle_t)
                print '(a, f0.1)', '  a circle of radius ', item%radius
            class is (rectangle_t)
                print '(2(a, f0.1))', '  a rectangle or a square, ', item%width, ' by ', item%height
            end select
        end do
        print '(a, f0.2)', 'total area: ', total

        call show_any(42)
        call show_any(2.5_dp)
        call show_any('text')
        call show_any(one)
        call show_any(.true.)

        ! Finalization happens at the end of the scope and on deallocate.
        block
            type(tracker_t) :: local

            local%label = 'a local variable'
            print '(a)', 'inside the block'
        end block
        allocate (on_heap)
        on_heap%label = 'an allocated variable'
        deallocate (on_heap)
        print '(a)', 'after both'
    end subroutine section06_types

    ! =============================================================================================
    !  7. Allocatable variables and pointers
    ! =============================================================================================

    pure recursive function list_sum(node) result(total)
        type(node_t), intent(in) :: node
        integer :: total

        total = node%value
        if (allocated(node%next)) total = total + list_sum(node%next)
    end function list_sum

    subroutine section07_memory()
        integer, allocatable :: values(:), copy(:)
        integer, target :: storage(6)                   ! target: pointers may refer to it
        integer, pointer :: view(:)
        type(node_t), allocatable :: head, fresh
        integer :: i

        call title(7, 'Allocatable variables and pointers')

        ! An allocatable variable owns its memory. C#: an array or a List<T>, but without a
        ! garbage collector: the memory is released when the variable goes out of scope.
        allocate (values(3))
        values = [(i * i, i = 1, 3)]
        values = [values, 16, 25]                       ! assignment reallocates: an "append"
        copy = values                                   ! a deep copy: arrays are values
        copy(1) = -1
        print '(a, *(i0, 1x))', 'values: ', values
        print '(a, *(i0, 1x))', 'copy:   ', copy

        ! move_alloc hands the memory over without copying it. C++: std::move
        call move_alloc(from=values, to=copy)
        print '(a, l1, a, i0)', 'values is still allocated: ', allocated(values), &
            ', the size of copy: ', size(copy)
        deallocate (copy)                               ! allowed, but rarely necessary

        ! A pointer is an alias, and it can refer to a section of an array.
        ! `=>` makes the pointer refer to something; `=` assigns THROUGH it.
        storage = [1, 2, 3, 4, 5, 6]
        view => storage(2:6:2)
        view = view * 10
        print '(a, *(i0, 1x))', 'storage after writing through the pointer: ', storage
        print '(a, l1)', 'associated(view): ', associated(view)
        nullify (view)                                  ! C#: view = null
        print '(a, l1)', 'after nullify: ', associated(view)

        ! A linked list without pointers: a component may be an allocatable object of the
        ! type itself, so every node owns the rest of the list, and nothing can leak.
        do i = 1, 3
            allocate (fresh)
            fresh%value = i * 10
            call move_alloc(head, fresh%next)           ! the old list becomes the tail
            call move_alloc(fresh, head)                ! the new node becomes the head
        end do
        print '(a, i0, a, i0)', 'the head of the list: ', head%value, ', the sum: ', list_sum(head)
    end subroutine section07_memory

    ! =============================================================================================
    !  8. Character strings
    ! =============================================================================================

    ! There is no intrinsic that changes the case; iachar and achar convert between
    ! characters and their ASCII codes.
    pure function to_upper(text) result(upper)
        character(len=*), intent(in) :: text
        character(len=len(text)) :: upper
        integer :: i

        upper = text
        do i = 1, len(text)
            if (text(i:i) >= 'a' .and. text(i:i) <= 'z') then
                upper(i:i) = achar(iachar(text(i:i)) - 32)
            end if
        end do
    end function to_upper

    subroutine section08_strings()
        character(len=10) :: fixed                      ! exactly ten characters
        character(len=:), allocatable :: text           ! any length, set by assignment
        character(len=6), parameter :: names(3) = [character(len=6) :: 'Ann', 'Robert', 'Li']
        character(len=32) :: buffer
        integer :: number, first, comma, status, i
        real(dp) :: value

        call title(8, 'Character strings')

        fixed = 'tour'                                  ! padded with blanks
        print '(*(g0))', '[', fixed, '] len ', len(fixed), ', len_trim ', len_trim(fixed)

        text = trim(fixed) // ' of ' // 'Fortran'       ! // concatenates
        text(1:1) = 'T'                                 ! a substring is (first:last)
        print '(*(g0))', text, ': length ', len(text), ', "of" starts at ', index(text, 'of')
        print '(*(g0))', 'upper: ', to_upper(text), ', repeated: ', repeat('ab', 3), &
            ', adjustr: [', adjustr(fixed), ']'
        print '(*(g0))', 'the first vowel is at ', scan(text, 'aeiou'), &
            ', the first non-digit of 12a4 is at ', verify('12a4', '0123456789')
        ! A comparison pads the shorter string with blanks. A quote is doubled: 'it''s'.
        print '(*(g0))', '"apple" < "banana": ', 'apple' < 'banana', &
            ', "a" == "a   ": ', 'a' == 'a   ', ', ', 'it''s'

        ! Numbers and strings are converted with write and read on a character variable.
        ! C#: ToString and int.Parse
        write (buffer, '(i0, a, f0.3)') 42, ' and ', pi
        print '(a, a)', 'written: ', trim(buffer)
        buffer = '  123  4.5'
        read (buffer, *) number, value
        print '(a, i0, a, f0.1)', 'read back: ', number, ' and ', value
        buffer = 'twelve'
        read (buffer, *, iostat=status) number
        print '(a, l1)', 'reading "twelve" as an integer fails: ', status /= 0

        ! All the elements of a character array have the same length.
        print '(*(a, :, "|"))', names
        print '(*(a, :, "|"))', (trim(names(i)), i = 1, size(names))

        ! Splitting a string by hand with index.
        text = 'alpha,beta,gamma'
        first = 1
        do
            comma = index(text(first:), ',')
            if (comma == 0) then
                print '(a, a)', '  token: ', text(first:)
                exit
            end if
            print '(a, a)', '  token: ', text(first:first + comma - 2)
            first = first + comma
        end do
    end subroutine section08_strings

    ! =============================================================================================
    !  9. Input, output and files
    ! =============================================================================================

    subroutine section09_io()
        use, intrinsic :: iso_fortran_env, only: output_unit, iostat_end
        integer :: unit, status, count, n
        character(len=80) :: line, message
        character(len=8) :: word
        logical :: found

        call title(9, 'Input, output and files')

        ! An edit descriptor formats one item: i an integer, f and es a real, a characters,
        ! l a logical; x is a blank and / a new line. A width of 0 means "as short as possible".
        print '(a, i5, a, i0, a, i5.3, a)', '[', 42, '] [', 42, '] [', 42, ']'
        print '(f8.3, 1x, es10.3, 1x, f0.2, 1x, l1)', pi, 1.0e6_dp * pi, pi, .true.
        print '(3(i0, 1x), a)', 1, 2, 3, '<- a group repeated three times'
        print '(*(i0, :, ", "))', 1, 2, 3               ! the colon stops when the items run out
        ! print *, items ("list-directed") needs no format; its spacing depends on the compiler.

        ! write (unit, format): the unit * is standard output. advance='no' keeps the line open.
        write (*, '(a)', advance='no') 'no new line yet, '
        write (output_unit, '(a)') 'and now the rest'   ! error_unit is standard error

        ! Files. newunit= hands out a unit number; iostat= and iomsg= report a failure instead
        ! of stopping the program. A scratch file is a temporary file without a name.
        ! C#: FileStream, StreamWriter, StreamReader
        open (newunit=unit, status='scratch', action='readwrite', iostat=status, iomsg=message)
        if (status /= 0) error stop 'cannot open a scratch file'
        write (unit, '(a, 1x, i0)') 'alpha', 1
        write (unit, '(a, 1x, i0)') 'beta', 2
        write (unit, '(a, 1x, i0)') 'gamma', 3
        rewind (unit)
        count = 0
        do
            read (unit, '(a)', iostat=status) line
            if (status == iostat_end) exit              ! the end of the file
            count = count + 1
            read (line, *) word, n                      ! parse the line that was read
            print '(a, i0, a, a, a, i0)', '  line ', count, ': ', trim(word), ' -> ', n
        end do
        close (unit)                                    ! a scratch file is deleted here

        open (newunit=unit, file='no_such_file.txt', status='old', action='read', &
              iostat=status, iomsg=message)
        print '(a, l1)', 'opening a missing file fails: ', status /= 0
        inquire (file='no_such_file.txt', exist=found)
        print '(a, l1)', 'inquire says that it exists: ', found

        ! The command line. C#: args
        print '(a, i0)', 'command-line arguments: ', command_argument_count()
    end subroutine section09_io

    ! =============================================================================================
    !  10. Procedures as values
    ! =============================================================================================

    pure function square(x) result(y)
        real(dp), intent(in) :: x
        real(dp) :: y

        y = x * x
    end function square

    pure function cube(x) result(y)
        real(dp), intent(in) :: x
        real(dp) :: y

        y = x ** 3
    end function cube

    pure function sine(x) result(y)
        real(dp), intent(in) :: x
        real(dp) :: y

        y = sin(x)
    end function sine

    ! A procedure as an argument: the trapezoidal rule for any function with the signature
    ! real_function. C#: Func<double, double>
    pure function integrate(f, a, b, steps) result(area)
        procedure(real_function) :: f
        real(dp), intent(in) :: a, b
        integer, intent(in) :: steps
        real(dp) :: area, h
        integer :: i

        h = (b - a) / steps
        area = (f(a) + f(b)) / 2
        do i = 1, steps - 1
            area = area + f(a + i * h)
        end do
        area = area * h
    end function integrate

    subroutine section10_procedure_values()
        procedure(real_function), pointer :: f
        type(operation_t) :: table(2)
        integer :: i

        call title(10, 'Procedures as values')

        print '(a, f0.4)', 'the integral of x**2 from 0 to 3: ', &
            integrate(square, 0.0_dp, 3.0_dp, 1000)
        print '(a, f0.4)', 'the integral of sin from 0 to pi: ', &
            integrate(sine, 0.0_dp, pi, 1000)

        ! A procedure pointer is a variable that refers to a procedure. C#: a delegate
        f => square
        print '(a, f0.1)', 'f => square, f(4) = ', f(4.0_dp)
        f => cube
        print '(a, f0.1, a, l1)', 'f => cube, f(4) = ', f(4.0_dp), ', associated: ', associated(f)

        ! Procedure pointers as components: a table of named operations. nopass says that
        ! the object is not passed as the first argument.
        table(1) = operation_t('square', square)
        table(2) = operation_t('cube', cube)
        do i = 1, size(table)
            print '(a, a, a, f0.1)', '  ', table(i)%name, ' of 3: ', table(i)%apply(3.0_dp)
        end do
    end subroutine section10_procedure_values

    ! =============================================================================================
    !  11. Numerics: kinds, IEEE arithmetic, bits, random numbers
    ! =============================================================================================

    subroutine section11_numerics()
        use, intrinsic :: ieee_arithmetic, only: ieee_is_nan, ieee_is_finite
        ! A kind can be chosen by the precision that is needed instead of by a name.
        integer, parameter :: wide = selected_int_kind(18)      ! at least 18 decimal digits
        integer, parameter :: fine = selected_real_kind(15)     ! at least 15 decimal digits
        real(dp), allocatable :: samples(:)
        real(dp) :: x, zero
        integer :: bits
        integer(int64) :: start, finish, rate

        call title(11, 'Numerics: kinds, IEEE arithmetic, bits, random numbers')

        print '(*(g0))', 'selected_int_kind(18) is int64: ', wide == int64, &
            ', selected_real_kind(15) is real64: ', fine == real64
        print '(*(g0))', 'huge(int32) = ', huge(1_int32), ', huge(int64) = ', huge(1_int64)
        print '(2(a, i0), a, es8.2)', 'decimal digits: real32 ', precision(1.0_real32), &
            ', real64 ', precision(1.0_dp), '; epsilon(real64) = ', epsilon(1.0_dp)
        ! mod takes the sign of its first argument, like C#'s %; modulo that of the second.
        print '(*(g0))', 'mod(-7, 3) = ', mod(-7, 3), ', modulo(-7, 3) = ', modulo(-7, 3)

        ! IEEE arithmetic: a division by zero gives an infinity, not an error.
        zero = 0.0_dp
        x = 1.0_dp / zero
        print '(a, l1, a, l1)', '1 / 0 is finite: ', ieee_is_finite(x), &
            '; 0 / 0 is a NaN: ', ieee_is_nan(zero / zero)

        ! Bits are handled by intrinsic functions. int() accepts binary, octal and
        ! hexadecimal constants: b'1010', o'17', z'FF'.
        bits = int(b'1010')
        print '(*(g0))', 'iand(12, 10) = ', iand(12, 10), ', ior = ', ior(12, 10), &
            ', ieor = ', ieor(12, 10), ', shiftl(1, 4) = ', shiftl(1, 4), &
            ', popcnt(255) = ', popcnt(255), ', btest(10, 1) = ', btest(bits, 1)
        print '(a, b8.8, a, z4.4, a, o3.3)', '10 in binary ', bits, ', 255 in hexadecimal ', 255, &
            ', 8 in octal ', 8

        ! random_number fills a scalar or a whole array with values from [0, 1).
        ! random_init(repeatable=.true., ...) makes every run produce the same sequence.
        allocate (samples(100000))
        call random_init(repeatable=.true., image_distinct=.false.)
        call random_number(samples)
        print '(a, l1, a, f4.2)', 'all the samples are in [0, 1): ', &
            all(samples >= 0.0_dp .and. samples < 1.0_dp), ', their mean: ', mean(samples)

        ! system_clock counts the ticks of a wall clock; cpu_time measures processor time.
        call system_clock(start, rate)
        x = sum(sqrt(samples))
        call system_clock(finish)
        print '(a, l1)', 'the clock did not go backwards: ', &
            finish >= start .and. rate > 0 .and. x > 0
    end subroutine section11_numerics

    ! =============================================================================================
    !  12. Errors without exceptions
    ! =============================================================================================

    ! The convention of the built-in statements, applied to a procedure of one's own: an
    ! optional status argument. When the caller did not ask for the status, a failure ends
    ! the program.
    subroutine checked_sqrt(x, root, stat)
        real(dp), intent(in) :: x
        real(dp), intent(out) :: root
        integer, intent(out), optional :: stat

        root = 0.0_dp
        if (present(stat)) stat = 0
        if (x < 0.0_dp) then
            ! `if (present(stat) .and. stat > 0)` would be an error: .and. and .or. do not
            ! promise to skip the second operand. C#: && and || do.
            if (.not. present(stat)) error stop 'checked_sqrt: negative argument'
            stat = 1
            return
        end if
        root = sqrt(x)
    end subroutine checked_sqrt

    subroutine section12_errors()
        use, intrinsic :: ieee_exceptions, only: ieee_get_flag, ieee_set_flag, ieee_divide_by_zero
        integer, allocatable :: values(:)
        character(len=80) :: message
        ! volatile keeps the optimizer from doing the division below at compile time.
        real(dp), volatile :: zero
        real(dp) :: root, x
        integer :: status
        logical :: raised

        call title(12, 'Errors without exceptions')

        call checked_sqrt(16.0_dp, root, status)
        print '(a, f0.1, a, i0)', 'root ', root, ', status ', status
        call checked_sqrt(-1.0_dp, root, status)
        print '(a, i0)', 'a negative argument: status ', status
        ! call checked_sqrt(-1.0_dp, root)
        !     ends the program: ERROR STOP checked_sqrt: negative argument

        ! allocate and deallocate report through stat= and errmsg=; without them a failure
        ! is fatal.
        allocate (values(3))
        allocate (values(5), stat=status, errmsg=message)
        print '(a, l1, a, a)', 'allocating twice fails: ', status /= 0, ' - ', trim(message)

        ! Floating-point exceptions are flags that stay raised until they are cleared.
        zero = 0.0_dp
        call ieee_set_flag(ieee_divide_by_zero, .false.)
        x = 1.0_dp / zero
        call ieee_get_flag(ieee_divide_by_zero, raised)
        print '(a, l1, a, l1)', 'the divide-by-zero flag is raised: ', raised, &
            ', and the result is positive: ', x > 0.0_dp
        call ieee_set_flag(ieee_divide_by_zero, .false.)

        ! stop ends the program normally. error stop ends it with a message on standard error
        ! and a non-zero exit code. Array bounds are checked only on request (gfortran
        ! -fcheck=all); an index out of bounds is otherwise undefined behaviour, where C#
        ! throws IndexOutOfRangeException.
    end subroutine section12_errors

    ! =============================================================================================
    !  13. Interoperability with C
    ! =============================================================================================

    ! bind(c) gives a Fortran procedure the C calling convention, so that C can call it.
    ! C passes pointers to the two elements, and Fortran arguments are references already.
    ! C#: [UnmanagedCallersOnly]
    function compare_ints(a, b) bind(c) result(order)
        integer(c_int), intent(in) :: a, b
        integer(c_int) :: order

        if (a < b) then
            order = -1
        else if (a > b) then
            order = 1
        else
            order = 0
        end if
    end function compare_ints

    subroutine section13_c_interop()
        integer(c_int), target :: numbers(6)
        integer(c_int), pointer :: alias(:)
        type(c_point) :: point

        call title(13, 'Interoperability with C')

        ! iso_c_binding names the kinds that match the C types: c_int, c_double, c_size_t ...
        ! A Fortran string has no terminating NUL, so one is appended for C.
        ! C#: [DllImport] / [LibraryImport]
        print '(a, i0)', 'strlen("Fortran") = ', c_strlen('Fortran' // c_null_char)

        ! qsort from the C library sorts a Fortran array and calls a Fortran function back.
        numbers = [integer(c_int) :: 5, 3, 9, 1, 7, 2]
        call c_qsort(c_loc(numbers), size(numbers, kind=c_size_t), c_sizeof(numbers(1)), &
                     c_funloc(compare_ints))
        print '(a, *(i0, 1x))', 'sorted by qsort: ', numbers

        ! c_f_pointer turns a C pointer into a Fortran pointer with bounds.
        call c_f_pointer(c_loc(numbers), alias, [3])
        print '(a, *(i0, 1x))', 'the first three through a C pointer: ', alias

        ! A bind(c) type has the layout of the C struct.
        point = c_point(1.5_c_double, 2.5_c_double)
        print '(a, f0.1, a, i0, a)', 'a point with x = ', point%x, ' takes ', &
            c_sizeof(point), ' bytes'
    end subroutine section13_c_interop

    ! =============================================================================================
    !  14. Parallel features and the newest
    ! =============================================================================================

    ! Fortran 2018: an assumed-rank argument (..) accepts a scalar or an array of any rank,
    ! and select rank tells them apart.
    subroutine describe_rank(x)
        integer, intent(in) :: x(..)

        select rank (x)
        rank (0)
            print '(a, i0)', '  a scalar: ', x
        rank (1)
            print '(a, i0, a)', '  a vector of ', size(x), ' elements'
        rank default
            print '(a, i0, a, i0, a)', '  an array of rank ', rank(x), ' with ', size(x), &
                ' elements'
        end select
    end subroutine describe_rank

    subroutine section14_newest()
        use tour_geometry, only: triangle_area
        integer, parameter :: n = 8
        real(dp) :: squares(n), total
        integer :: matrix(2, 3)
        integer :: i

        call title(14, 'Parallel features and the newest')

        ! do concurrent states that the iterations do not depend on each other, so the
        ! compiler may run them in any order, vectorized or in parallel.
        do concurrent (i = 1:n)
            squares(i) = real(i, dp) ** 2
        end do

        ! OpenMP directives are comments that a compiler obeys on request (gfortran -fopenmp).
        ! Without the option the loop runs serially, with the same result.
        ! C#: Parallel.For with a thread-local sum
        total = 0.0_dp
        !$omp parallel do reduction(+:total)
        do i = 1, n
            total = total + squares(i)
        end do
        !$omp end parallel do
        print '(a, f0.1)', 'the sum of the squares of 1 to 8: ', total

        ! Coarrays put parallelism into the language itself: the program runs as several
        ! "images", and a variable declared with [*] exists once on each of them.
        !     integer :: counter[*]
        !     counter[1] = counter[1] + this_image()      ! write to the copy on image 1
        !     sync all
        ! gfortran needs -fcoarray=single or -fcoarray=lib for this: NOT compiled here.

        ! Newer than Fortran 90/95, and used in this file:
        !   2003  type extension and type-bound procedures, class, select type, procedure
        !         pointers, allocatable components and deferred-length strings,
        !         iso_c_binding, IEEE modules, associate, newunit= came in 2008
        !   2008  submodules, do concurrent, block, error stop, the g0 edit descriptor, bit
        !         intrinsics such as popcnt, recursive allocatable components, coarrays
        !   2018  assumed rank and select rank, random_init, recursion by default
        matrix = 0
        call describe_rank(5)
        call describe_rank([1, 2, 3])
        call describe_rank(matrix)
        print '(a, f0.1)', 'the area of the triangle 3-4-5 (from a submodule): ', &
            triangle_area(3.0_dp, 4.0_dp, 5.0_dp)

        ! Fortran 2023 is newer than what this file is compiled as; gfortran 14 rejects the
        ! first and the last line even with -std=f2023. NOT compiled here:
        !     label = (n > 5 ? 'big' : 'small')             ! a conditional expression
        !     enumeration type :: colour                      ! an enumeration type
        !         enumerator :: red, green, blue
        !     end enumeration type
        !     call split(text, ',', position)                 ! split and tokenize for strings
        !     simple function f(x)                            ! stricter than pure
        !     typeof(x) :: y                                  ! the type of another object
        !     x = sind(30.0)                                  ! trigonometry in degrees
        !     do concurrent (i = 1:n) reduce(+:total)         ! a reduction in do concurrent
    end subroutine section14_newest

end module tour_sections

! =================================================================================================
!  The main program. C#: Main
! =================================================================================================

program fortran_tour
    use tour_sections
    implicit none

    call section01_basics()
    call section02_control_flow()
    call section03_arrays()
    call section04_procedures()
    call section05_modules()
    call section06_types()
    call section07_memory()
    call section08_strings()
    call section09_io()
    call section10_procedure_values()
    call section11_numerics()
    call section12_errors()
    call section13_c_interop()
    call section14_newest()
end program fortran_tour
