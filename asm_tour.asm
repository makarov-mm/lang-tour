; =================================================================================================
;  x86-64 ASSEMBLY FOR C# DEVELOPERS — a language tour in a single file, from simple to advanced
;
;  Assembler: NASM, Intel syntax. The same file builds for Linux and for Windows, without any
;  library: it talks to the operating system directly.
;
;      Linux:     nasm -f elf64 asm_tour.asm -o asm_tour.o
;                 ld asm_tour.o -o asm_tour && ./asm_tour
;
;      Windows:   nasm -f win64 asm_tour.asm -o asm_tour.obj
;                 gcc -nostdlib -Wl,-e,start asm_tour.obj -lkernel32 -o asm_tour.exe
;                 (MinGW-w64; with the Microsoft tools the second line should be
;                 link /subsystem:console /entry:start /nodefaultlib asm_tour.obj kernel32.lib)
;
;  Verified with NASM 2.16.01: the Linux build with GNU ld on x86-64 Linux, the Windows build
;  linked by MinGW-w64 GCC 13 and run under Wine. The Microsoft link line was NOT tried.
;
;  How to read. The helpers that print come first (skim them and come back after section 7),
;  then one procedure per section, then the entry point, which calls the sections in order.
;  A "C#:" note gives the closest counterpart in C#, or what the JIT compiler does with it.
;
;  The main differences from C# to keep in mind from the first line:
;
;   1. There are no variables, no types and no expressions. There are 16 general-purpose
;      registers of 64 bits, memory, and instructions that each do one small thing.
;   2. An instruction is written `mnemonic destination, source`: the destination comes first.
;   3. Memory is a flat array of bytes. [address] reads or writes it, and the SIZE of the
;      access comes from the register involved or has to be written (byte, word, dword,
;      qword). Nothing checks bounds, types or null.
;   4. There are no control structures. cmp sets flags, a conditional jump reads them and
;      goes to a label; if, while and switch are patterns built from that.
;   5. Whether a number is signed is decided by the INSTRUCTION, not by the data: jl or jb,
;      imul or mul, sar or shr.
;   6. A function is a label. call and ret only push and pop the return address; where the
;      arguments go and which registers survive a call is a convention, and Windows and
;      Linux have different ones.
;   7. Writing the 32-bit part of a register clears the upper half; writing 8 or 16 bits
;      does not.
;   8. Lines that start with % are executed by the assembler: a macro language runs before
;      any instruction is encoded.
;
;  Contents:
;    1. The shape of a program                    8. Macros and the preprocessor
;    2. Registers and moving data                 9. Floating point and SIMD
;    3. Arithmetic, bits and flags               10. Bit scans, byte order, CPUID
;    4. Control flow                             11. Atomic instructions
;    5. Memory, data and addressing              12. Indirect calls and a virtual table by hand
;    6. The stack and procedures                 13. Talking to the operating system
;    7. Strings and the string instructions      14. The newest
; =================================================================================================

bits 64
default rel                         ; address data relative to rip, as 64-bit code should

; -------------------------------------------------------------------------------------------------
;  One source, two operating systems. __OUTPUT_FORMAT__ is what was given to nasm -f.
; -------------------------------------------------------------------------------------------------

%ifidn __OUTPUT_FORMAT__, win64
    %define WINDOWS 1
    %define RODATA .rdata
    %define ARG1 rcx                ; the Microsoft x64 calling convention (see section 6)
    %define ARG2 rdx
    %define ARG3 r8
    extern GetStdHandle             ; functions of kernel32.dll
    extern WriteFile
    extern GetLastError
    extern ExitProcess
    global start
%elifidn __OUTPUT_FORMAT__, elf64
    %define LINUX 1
    %define RODATA .rodata
    %define ARG1 rdi                ; the System V calling convention (see section 6)
    %define ARG2 rsi
    %define ARG3 rdx
    global _start
    section .note.GNU-stack noalloc noexec nowrite progbits     ; "the stack is not code"
%else
    %error "assemble with -f elf64 or with -f win64"
%endif

; -------------------------------------------------------------------------------------------------
;  Macros that print. They leave every general-purpose register and the flags untouched, so
;  that they can stand between any two instructions. (On Windows the xmm registers are NOT
;  preserved; section 9 takes that into account.)
;
;      PRINT "text", 10        the bytes given, as for db; 10 is a new line
;      PINT value              a signed decimal number
;      PUINT value             an unsigned decimal number
;      PHEX value, digits      that many hexadecimal digits
;      PFIX value              value / 1000 with three decimals
;      SHOW "text", value      text, signed number, new line
;
;  `value` is a 64-bit register, a constant, or a qword in memory that is not addressed
;  through rsp.
; -------------------------------------------------------------------------------------------------

%macro PRINT 1+
    [section RODATA]                ; put the text into the read-only data ...
%%text:     db %1
%%length    equ $ - %%text
    __SECT__                        ; ... and return to the section the macro was used in
    pushfq
    push r10
    push r11
    lea r10, [%%text]
    mov r11d, %%length
    call emit
    pop r11
    pop r10
    popfq
%endmacro

%macro PINT 1
    pushfq
    push rax
    mov rax, %1
    call print_int
    pop rax
    popfq
%endmacro

%macro PUINT 1
    pushfq
    push rax
    mov rax, %1
    call print_uint
    pop rax
    popfq
%endmacro

%macro PHEX 2
    pushfq
    push rax
    push rcx
    mov rax, %1
    mov ecx, %2
    call print_hex
    pop rcx
    pop rax
    popfq
%endmacro

%macro PFIX 1
    pushfq
    push rax
    mov rax, %1
    call print_fixed
    pop rax
    popfq
%endmacro

%macro SHOW 2
    PRINT %1
    PINT %2
    PRINT 10
%endmacro

%macro TITLE 2
    PRINT 10, "=== ", %1, ". ", %2, " ===", 10
%endmacro

; A call that follows the platform's convention: on Windows the caller reserves 32 bytes of
; "shadow space" for the callee.
%macro ABI_CALL 1
%ifdef WINDOWS
    sub rsp, 32
    call %1
    add rsp, 32
%else
    call %1
%endif
%endmacro

; -------------------------------------------------------------------------------------------------
;  The helpers behind the macros. They use a private convention (value in rax, text in r10
;  and r11) and preserve every register they touch.
; -------------------------------------------------------------------------------------------------

section .bss
stdout_handle:  resq 1              ; Windows: the handle of the console
argument_count: resq 1              ; Linux: argc

section .text

; emit: writes r11 bytes that start at the address r10 to standard output.
emit:
%ifdef LINUX
    push rax
    push rcx                        ; the syscall instruction overwrites rcx and r11
    push rdx
    push rsi
    push rdi
    push r11
    mov eax, 1                      ; system call 1: write(descriptor, buffer, count)
    mov edi, 1                      ; descriptor 1 is standard output
    mov rsi, r10
    mov rdx, r11
    syscall
    pop r11
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax
    ret
%else
    push rbp
    mov rbp, rsp
    push rax
    push rcx
    push rdx
    push r8
    push r9
    push r10
    push r11                        ; seven registers: the last one is at [rbp - 56]
    and rsp, -16                    ; the convention wants rsp to be a multiple of 16 ...
    sub rsp, 48                     ; ... with 32 bytes of shadow space; plus two more slots
    mov rcx, [stdout_handle]        ; WriteFile(handle, buffer, count, &written, overlapped)
    mov rdx, r10
    mov r8, r11
    lea r9, [rsp + 40]
    mov qword [rsp + 32], 0         ; the fifth argument travels on the stack
    call WriteFile
    lea rsp, [rbp - 56]
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdx
    pop rcx
    pop rax
    pop rbp
    ret
%endif

; print_uint: writes rax as an unsigned decimal number.
print_uint:
    push rbp
    mov rbp, rsp
    sub rsp, 32                     ; a local buffer for the digits
    push rax
    push rcx
    push rdx
    push r10
    push r11
    mov r10, rbp                    ; the digits are produced from the last one backwards
    mov ecx, 10
.digit:
    xor edx, edx
    div rcx                         ; rax = quotient, rdx = remainder (see section 3)
    add dl, '0'
    dec r10
    mov [r10], dl
    test rax, rax
    jnz .digit
    mov r11, rbp
    sub r11, r10                    ; the number of digits
    call emit
    pop r11
    pop r10
    pop rdx
    pop rcx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; print_int: writes rax as a signed decimal number.
print_int:
    push rax
    test rax, rax
    jns .magnitude
    PRINT "-"
    neg rax
.magnitude:
    call print_uint
    pop rax
    ret

; print_hex: writes the lowest rcx hexadecimal digits of rax.
print_hex:
    push rbp
    mov rbp, rsp
    sub rsp, 32
    push rax
    push rcx
    push rdx
    push r10
    push r11
    mov r11, rcx                    ; the length
    mov r10, rbp
.digit:
    mov edx, eax
    and edx, 15
    cmp dl, 10
    jb .decimal
    add dl, 'A' - 10 - '0'
.decimal:
    add dl, '0'
    dec r10
    mov [r10], dl
    shr rax, 4
    dec rcx
    jnz .digit
    call emit
    pop r11
    pop r10
    pop rdx
    pop rcx
    pop rax
    mov rsp, rbp
    pop rbp
    ret

; print_fixed: writes rax / 1000 with exactly three decimals.
print_fixed:
    push rax
    push rcx
    push rdx
    test rax, rax
    jns .magnitude
    PRINT "-"
    neg rax
.magnitude:
    xor edx, edx
    mov ecx, 1000
    div rcx
    call print_uint                 ; the whole part
    PRINT "."
    mov rax, rdx                    ; the three decimals, with their leading zeros
    xor edx, edx
    mov ecx, 100
    div rcx
    call print_uint
    mov rax, rdx
    xor edx, edx
    mov ecx, 10
    div rcx
    call print_uint
    mov rax, rdx
    call print_uint
    pop rdx
    pop rcx
    pop rax
    ret

; print_text: writes the zero-terminated string at r10.
print_text:
    push r11
    xor r11d, r11d
.measure:
    cmp byte [r10 + r11], 0
    je .write
    inc r11
    jmp .measure
.write:
    call emit
    pop r11
    ret

; =================================================================================================
;  1. The shape of a program
; =================================================================================================

; A source file is a list of sections:
;     .text     the instructions                          (read-only, executable)
;     .rodata   constants; Windows calls it .rdata        (read-only)
;     .data     variables with an initial value
;     .bss      variables without one: only their size is recorded, and they start as zero
;
; A line is  label: instruction operands ; comment.  A label is a name for an address and
; nothing more: `main_message` below is the address of a byte, `section01_program` the
; address of an instruction. C#: a label is at once a field name, a method name and a goto
; target.

section RODATA
main_message:   db "Hello from x86-64 assembly", 10     ; db stores bytes; 10 is a line feed
main_length     equ $ - main_message                    ; $ is "here": the length, a constant

section .text

section01_program:
    TITLE "1", "The shape of a program"

    ; The smallest useful act: hand a buffer to the operating system. (The details of emit
    ; are in section 13.)
    lea r10, [main_message]         ; r10 = the ADDRESS of the text. C#: a pointer
    mov r11, main_length            ; r11 = its length
    call emit

%ifdef WINDOWS
    PRINT "assembled for Windows: the Microsoft x64 convention, kernel32.dll", 10
%else
    PRINT "assembled for Linux: the System V convention, system calls", 10
%endif
    ret                             ; back to the entry point, which is at the end of the file

; =================================================================================================
;  2. Registers and moving data
; =================================================================================================

; The general-purpose registers: rax rbx rcx rdx rsi rdi rbp rsp and r8 ... r15. Each holds
; 64 bits; rsp is the stack pointer, and the rest are yours within the limits of the calling
; convention. rip, the instruction pointer, and rflags are changed only indirectly.

section02_registers:
    TITLE "2", "Registers and moving data"

    mov rax, 0x1122334455667788     ; a constant into a register. C#: long a = 0x11...;
    PRINT "rax                 = 0x"
    PHEX rax, 16
    PRINT 10

    ; The low parts of a register have their own names: eax (32 bits), ax (16), al (8).
    mov rcx, rax
    mov cl, 0xFF                    ; 8 bits are written, the other 56 keep their value
    PRINT "after mov cl, 0xFF  = 0x"
    PHEX rcx, 16
    PRINT 10
    mov rcx, rax
    mov cx, 0                       ; 16 bits: the rest is kept as well
    PRINT "after mov cx, 0     = 0x"
    PHEX rcx, 16
    PRINT 10
    mov rcx, rax
    mov ecx, 1                      ; 32 bits: the upper half is CLEARED — the irregular rule
    PRINT "after mov ecx, 1    = 0x"
    PHEX rcx, 16
    PRINT 10
    ; Hence the idiom for "rax = 0": xor eax, eax. It is shorter than mov rax, 0.

    ; Widening: movzx fills with zeros, movsx with copies of the sign bit.
    ; C#: (long)(byte)x and (long)(sbyte)x
    mov edx, 0x80                   ; the byte 0x80 is 128 unsigned and -128 signed
    movzx r8, dl
    movsx r9, dl
    PRINT "movzx of the byte 0x80 = "
    PINT r8
    PRINT ", movsx = "
    PINT r9
    PRINT 10

    ; lea ("load effective address") evaluates an address expression and stores the result
    ; without touching memory: a free addition and small multiplication.
    mov rcx, 10
    lea rdx, [rcx + rcx*4 + 7]      ; 10 + 40 + 7
    SHOW "lea rdx, [rcx + rcx*4 + 7] with rcx = 10: ", rdx

    ; xchg swaps two operands.
    mov rax, 1
    mov rcx, 2
    xchg rax, rcx
    PRINT "after xchg: rax = "
    PINT rax
    PRINT ", rcx = "
    PINT rcx
    PRINT 10
    ret

; =================================================================================================
;  3. Arithmetic, bits and flags
; =================================================================================================

section03_arithmetic:
    TITLE "3", "Arithmetic, bits and flags"

    mov rax, 20
    add rax, 22                     ; rax = rax + 22. C#: a += 22;
    sub rax, 2
    inc rax                         ; C#: a++;
    neg rax                         ; C#: a = -a;
    SHOW "20 + 22 - 2 + 1, negated: ", rax

    ; imul is the signed multiplication; with two or three operands it keeps the low 64 bits.
    mov rcx, 7
    imul rax, rcx, 6                ; rax = rcx * 6
    SHOW "7 * 6 = ", rax

    ; The one-operand mul gives the full 128-bit product of rax and its operand in rdx:rax.
    ; C#: Math.BigMul
    mov rax, -1                     ; all bits set: 2^64 - 1 as an unsigned number
    mov rcx, 16
    mul rcx
    PRINT "(2^64 - 1) * 16 = 0x"
    PHEX rdx, 16
    PRINT ":"
    PHEX rax, 16
    PRINT "  (rdx:rax)", 10

    ; div divides the 128-bit number rdx:rax by its operand: the quotient goes to rax, the
    ; remainder to rdx. rdx has to be prepared: zero for unsigned numbers, the sign of rax
    ; (cqo) for signed ones. Forgetting it is the classic bug; a quotient that does not fit
    ; raises the same fault as a division by zero.
    mov rax, 47
    xor edx, edx
    mov rcx, 5
    div rcx
    PRINT "47 / 5 = "
    PINT rax
    PRINT " remainder "
    PINT rdx
    PRINT 10
    mov rax, -47
    cqo
    idiv rcx                        ; the signed division truncates towards zero, as in C#
    PRINT "-47 / 5 = "
    PINT rax
    PRINT " remainder "
    PINT rdx
    PRINT 10

    ; Bits. C#: & | ^ ~ << >>
    mov rax, 0b1100
    mov rcx, 0b1010
    mov rdx, rax
    and rdx, rcx
    mov r8, rax
    or r8, rcx
    mov r9, rax
    xor r9, rcx
    PRINT "1100 and 1010 = "
    PINT rdx
    PRINT ", or = "
    PINT r8
    PRINT ", xor = "
    PINT r9
    PRINT 10

    mov rax, -16
    sar rax, 2                      ; arithmetic shift: copies of the sign come in. C#: >> on long
    mov rcx, -16
    shr rcx, 60                     ; logical shift: zeros come in. C#: >>> or >> on ulong
    mov rdx, 0x8000000000000001
    rol rdx, 1                      ; rotate: the bit that leaves on the left returns on the right
    PRINT "-16 sar 2 = "
    PINT rax
    PRINT ", -16 shr 60 = "
    PINT rcx
    PRINT ", 0x8000000000000001 rol 1 = "
    PINT rdx
    PRINT 10

    ; Arithmetic sets flags: ZF (the result is zero), SF (its top bit), CF (it did not fit as
    ; an unsigned number), OF (it did not fit as a signed one). setcc stores a condition as
    ; 0 or 1.
    mov al, 200
    add al, 100                     ; 300 does not fit into 8 bits
    setc cl
    movzx rax, al
    movzx rcx, cl
    PRINT "8 bits: 200 + 100 = "
    PINT rax
    PRINT " with the carry flag "
    PINT rcx
    PRINT 10
    mov al, 100
    add al, 100                     ; 200 does not fit into a SIGNED byte
    seto cl
    movsx rax, al
    movzx rcx, cl
    PRINT "8 bits: 100 + 100 = "
    PINT rax
    PRINT " as a signed number, with the overflow flag "
    PINT rcx
    PRINT 10
    ; C#: `checked` arithmetic is exactly this: an add followed by jo or jc to a throw helper.

    ; adc adds the carry of the previous addition as well: a 128-bit sum from 64-bit halves.
    ; C#: UInt128
    mov rax, -1                     ; the low half of the number 0x1_FFFFFFFFFFFFFFFF
    mov rdx, 1                      ; its high half
    add rax, 1                      ; the low halves: wraps to 0 and sets the carry
    adc rdx, 0                      ; the high halves, plus the carry
    PRINT "0x1_FFFFFFFFFFFFFFFF + 1: high half "
    PINT rdx
    PRINT ", low half "
    PINT rax
    PRINT 10

    ; cmp is a subtraction that keeps only the flags (test is such an and). cmovcc copies
    ; only if a condition holds: a choice without a jump. C#: the JIT does this for Math.Max.
    mov rax, 3
    mov rcx, 9
    cmp rax, rcx
    mov rdx, rax
    cmovl rdx, rcx                  ; if rax < rcx (signed): rdx = rcx
    SHOW "the maximum of 3 and 9 by cmp and cmovl: ", rdx
    ret

; =================================================================================================
;  4. Control flow
; =================================================================================================

section RODATA
numbers:        dq 5, 3, 9, 1, 7                ; dq stores 64-bit values. C#: long[] numbers
numbers_count   equ ($ - numbers) / 8           ; a constant that the assembler computes

section .text

section04_control_flow:
    TITLE "4", "Control flow"

    ; if / else: compare, then jump over the part that does not apply. A label that starts
    ; with a dot is local to the last ordinary label before it.
    mov rax, -1
    mov rcx, 1
    cmp rax, rcx
    jl .signed_less                 ; jl jle jg jge read the flags as a SIGNED comparison
    PRINT "signed: -1 is not less than 1", 10
    jmp .signed_done
.signed_less:
    PRINT "signed comparison (jl): -1 is less than 1", 10
.signed_done:
    cmp rax, rcx
    jb .unsigned_below              ; jb jbe ja jae read them as an UNSIGNED one
    PRINT "unsigned comparison (jb): the same bits, 2^64 - 1, are not below 1", 10
    jmp .unsigned_done
.unsigned_below:
    PRINT "unsigned: below", 10
.unsigned_done:

    ; A counted loop: the sum of 1 to 10. C#: for (long i = 10; i != 0; i--) sum += i;
    xor eax, eax
    mov ecx, 10
.sum_next:
    add rax, rcx
    dec rcx
    jnz .sum_next                   ; dec has set the zero flag when rcx reached 0
    SHOW "the sum of 1 to 10: ", rax

    ; A while loop with a test at the top: the Collatz steps of 27.
    mov rax, 27
    xor r8d, r8d                    ; the step counter
.collatz_test:
    cmp rax, 1
    je .collatz_done
    test al, 1                      ; and without storing the result: is the number odd?
    jnz .collatz_odd
    shr rax, 1                      ; even: halve
    jmp .collatz_counted
.collatz_odd:
    lea rax, [rax + rax*2 + 1]      ; odd: 3n + 1
.collatz_counted:
    inc r8
    jmp .collatz_test
.collatz_done:
    SHOW "Collatz steps from 27 down to 1: ", r8

    ; A loop over an array: the largest of `numbers`.
    lea r8, [numbers]               ; r8 = the address of the first element
    mov rax, [r8]                   ; the best so far
    mov ecx, 1                      ; the index
.max_next:
    cmp rcx, numbers_count
    jae .max_done
    mov rdx, [r8 + rcx*8]           ; numbers[rcx]: base + index * element size
    cmp rdx, rax
    cmovg rax, rdx
    inc rcx
    jmp .max_next
.max_done:
    SHOW "the largest element: ", rax

    ; switch: a table of addresses, indexed by the value. C#: the JIT compiles a dense
    ; switch into the same thing.
    xor r8d, r8d
.switch_next:
    PRINT "switch ("
    PINT r8
    PRINT "): "
    cmp r8, 2
    ja .case_default                ; one unsigned test rejects negative values too
    lea r9, [.jump_table]
    jmp [r9 + r8*8]                 ; an indirect jump through the table
.case_0:
    PRINT "case 0", 10
    jmp .switch_end
.case_1:
    PRINT "case 1", 10
    jmp .switch_end
.case_2:
    PRINT "case 2", 10
    jmp .switch_end
.case_default:
    PRINT "default", 10
.switch_end:
    inc r8
    cmp r8, 4
    jb .switch_next
    ret

section RODATA
.jump_table:    dq .case_0, .case_1, .case_2

section .text

; =================================================================================================
;  5. Memory, data and addressing
; =================================================================================================

; struc defines the offsets of fields; it reserves nothing. C#: a struct layout
struc point
    .x:     resq 1                  ; point.x = 0
    .y:     resq 1                  ; point.y = 8
endstruc                            ; point_size = 16

section .data
counter:        dq 0                            ; a 64-bit variable. C#: static long counter;
four_bytes:     db 0x78, 0x56, 0x34, 0x12       ; four single bytes, in this order in memory
pair:           dq 111, 222
corner:                                         ; an instance of the structure
    istruc point
        at point.x, dq 30
        at point.y, dq 40
    iend

section .bss
buffer:         resb 64                         ; 64 bytes without an initial value

section .text

section05_memory:
    TITLE "5", "Memory, data and addressing"

    ; Brackets mean "the memory at this address". Without brackets a label is the address.
    ; The general form is [base + index*scale + displacement] with a scale of 1, 2, 4 or 8.
    lea r8, [numbers]
    mov rax, [r8 + 2*8]             ; the third element
    mov ecx, 3
    mov rdx, [r8 + rcx*8]           ; numbers[3]
    PRINT "numbers[2] = "
    PINT rax
    PRINT ", numbers[3] = "
    PINT rdx
    PRINT 10
    ; (An address that uses an index register cannot be rip-relative, which is why the base
    ; is loaded with lea first.)

    ; When no register tells the size of an access, it has to be written.
    mov qword [counter], 5
    add qword [counter], 2
    inc qword [counter]
    SHOW "counter after mov 5, add 2, inc: ", [counter]
    ; mov [counter], 5              error: operation size not specified

    ; x86 is little-endian: the lowest byte of a number is stored first.
    mov eax, [four_bytes]           ; reads four bytes as one 32-bit number
    PRINT "the bytes 78 56 34 12 read as a dword: 0x"
    PHEX rax, 8
    PRINT 10

    ; Fields of a structure are offsets from its address.
    lea r8, [corner]
    mov rax, [r8 + point.x]
    add rax, [r8 + point.y]
    PRINT "corner.x + corner.y = "
    PINT rax
    PRINT ", point_size = "
    PINT point_size
    PRINT 10

    ; Walking an array with a pointer. C#: for (long* p = numbers; p < end; p++) sum += *p;
    lea r8, [numbers]
    lea r9, [numbers + numbers_count*8]         ; one past the last element
    xor eax, eax
.next:
    add rax, [r8]
    add r8, 8
    cmp r8, r9
    jb .next
    SHOW "the sum of numbers, walked with a pointer: ", rax

    ; Memory in .bss starts as zero and can be written.
    lea r8, [buffer]
    mov byte [r8], 'O'
    mov byte [r8 + 1], 'K'
    mov byte [r8 + 2], 0
    PRINT "two bytes stored into the buffer: "
    mov r10, r8
    call print_text
    PRINT 10
    ret

; =================================================================================================
;  6. The stack and procedures
; =================================================================================================

; The stack grows downwards: push subtracts 8 from rsp and stores, pop loads and adds 8.
; call pushes the address of the next instruction and jumps; ret pops it and jumps back.
; Everything else about a function is a convention:
;
;                              System V (Linux, macOS)        Microsoft x64 (Windows)
;     integer arguments        rdi rsi rdx rcx r8 r9          rcx rdx r8 r9
;     floating-point ones      xmm0 ... xmm7                  xmm0 ... xmm3
;     further arguments        on the stack                   on the stack
;     result                   rax (xmm0)                     rax (xmm0)
;     the callee preserves     rbx rbp r12-r15                rbx rbp rsi rdi r12-r15 xmm6-xmm15
;     before a call            rsp is a multiple of 16        the same, plus 32 bytes of
;                                                             shadow space above the return address
;
; The functions below follow the convention of the platform through the names ARG1, ARG2
; and ARG3, so C code could call them. C#: this is what [DllImport] has to match.

; long add3(long a, long b, long c)
add3:
    mov rax, ARG1
    add rax, ARG2
    add rax, ARG3
    ret

; long factorial(long n) — recursive
factorial:
    cmp ARG1, 1
    jg .recurse
    mov eax, 1
    ret
.recurse:
    push rbx                        ; rbx belongs to the caller: save it before using it
    mov rbx, ARG1                   ; n survives the call in a preserved register
    dec ARG1
    ABI_CALL factorial              ; rax = factorial(n - 1)
    imul rax, rbx
    pop rbx
    ret

; long sum_array(const long *items, long count)
sum_array:
    xor eax, eax
    test ARG2, ARG2
    jle .done
.next:
    add rax, [ARG1]
    add ARG1, 8
    dec ARG2
    jnz .next
.done:
    ret

; void swap_values(long *a, long *b) — results through pointers. C#: ref parameters
swap_values:
    mov rax, [ARG1]
    mov r10, [ARG2]
    mov [ARG1], r10
    mov [ARG2], rax
    ret

; long polynomial(long x) = 3x^2 + 2x + 1 — with a stack frame and local variables
polynomial:
    push rbp                        ; the prologue: keep the caller's frame pointer,
    mov rbp, rsp                    ; make rbp the fixed point of this frame,
    sub rsp, 16                     ; and reserve 16 bytes of local variables
    mov [rbp - 8], ARG1             ; a local: x
    mov rax, ARG1
    imul rax, rax
    imul rax, rax, 3
    mov [rbp - 16], rax             ; a local: 3x^2
    mov rax, [rbp - 8]
    lea rax, [rax*2 + 1]
    add rax, [rbp - 16]
    mov rsp, rbp                    ; the epilogue (`leave` does these two steps)
    pop rbp
    ret

section06_stack:
    push rbp                        ; a frame also brings rsp back to a multiple of 16
    mov rbp, rsp
    TITLE "6", "The stack and procedures"

    mov r8, rsp
    push 1
    push 2
    mov r9, rsp
    sub r8, r9
    pop rax                         ; last in, first out
    pop rcx
    PRINT "two pushes moved rsp down by "
    PINT r8
    PRINT " bytes; popped "
    PINT rax
    PRINT ", then "
    PINT rcx
    PRINT 10

    mov ARG1, 10
    mov ARG2, 20
    mov ARG3, 12
    ABI_CALL add3
    SHOW "add3(10, 20, 12) = ", rax

    mov ARG1, 20
    ABI_CALL factorial
    SHOW "factorial(20) = ", rax

    lea ARG1, [numbers]
    mov ARG2, numbers_count
    ABI_CALL sum_array
    SHOW "sum_array(numbers, 5) = ", rax

    lea ARG1, [pair]
    lea ARG2, [pair + 8]
    ABI_CALL swap_values
    PRINT "the pair 111, 222 after swap_values: "
    PINT [pair]
    PRINT ", "
    PINT [pair + 8]
    PRINT 10

    mov ARG1, 5
    ABI_CALL polynomial
    SHOW "polynomial(5) = 3*25 + 2*5 + 1 = ", rax

    pop rbp
    ret

; =================================================================================================
;  7. Strings and the string instructions
; =================================================================================================

; movs, stos, scas, cmps and lods work through rsi (source) and rdi (destination) and step
; them after each element; the prefixes rep, repe and repne repeat them rcx times.
; A string is whatever the code agrees on: here, bytes that end with a zero, as in C.

; size_t string_length(const char *text)
string_length:
    push rdi                        ; rdi is the caller's on Windows
    mov rdi, ARG1
    xor eax, eax                    ; al = 0, the byte to look for
    mov rcx, -1                     ; no limit
    cld                             ; clear the direction flag: go upwards
    repne scasb                     ; while rcx-- != 0 and [rdi++] != al
    not rcx
    lea rax, [rcx - 1]              ; the bytes scanned, without the zero
    pop rdi
    ret

; void copy_bytes(char *destination, const char *source, size_t count)
; C#: Span<byte>.CopyTo, Buffer.MemoryCopy
copy_bytes:
    push rsi
    push rdi
    mov r10, ARG1
    mov r11, ARG2
    mov rcx, ARG3
    mov rdi, r10
    mov rsi, r11
    cld
    rep movsb                       ; rcx times: [rdi++] = [rsi++]
    pop rdi
    pop rsi
    ret

; void fill_bytes(char *destination, long value, size_t count). C#: Span<byte>.Fill
fill_bytes:
    push rdi
    mov r10, ARG1
    mov rax, ARG2
    mov rcx, ARG3
    mov rdi, r10
    cld
    rep stosb                       ; rcx times: [rdi++] = al
    pop rdi
    ret

; long equal_bytes(const char *a, const char *b, size_t count): 1 if the ranges are equal
; C#: Span<byte>.SequenceEqual
equal_bytes:
    push rsi
    push rdi
    mov r10, ARG1
    mov r11, ARG2
    mov rcx, ARG3
    mov rdi, r10
    mov rsi, r11
    cld
    xor eax, eax
    cmp rcx, rcx                    ; set the zero flag in case the count is 0
    repe cmpsb                      ; compare while the bytes are equal
    sete al
    pop rdi
    pop rsi
    ret

; void to_upper(char *text) — an ordinary loop over the bytes
to_upper:
    mov r10, ARG1
.next:
    mov al, [r10]
    test al, al
    jz .done
    cmp al, 'a'
    jb .keep
    cmp al, 'z'
    ja .keep
    sub al, 'a' - 'A'
    mov [r10], al
.keep:
    inc r10
    jmp .next
.done:
    ret

section RODATA
greeting:       db "Hello, assembly", 0
word_abc:       db "abc"
word_abd:       db "abd"

section .text

section07_strings:
    push rbp
    mov rbp, rsp
    push r12                        ; two preserved registers for values that must
    push r13                        ; survive the calls
    TITLE "7", "Strings and the string instructions"

    lea ARG1, [greeting]
    ABI_CALL string_length
    mov r12, rax
    SHOW 'string_length("Hello, assembly") = ', r12

    lea ARG1, [buffer]              ; copy the text into the writable buffer
    lea ARG2, [greeting]
    mov ARG3, r12
    ABI_CALL copy_bytes

    lea r13, [buffer]
    lea ARG1, [r13 + r12]           ; append three exclamation marks ...
    mov ARG2, '!'
    mov ARG3, 3
    ABI_CALL fill_bytes
    mov byte [r13 + r12 + 3], 0     ; ... and the terminating zero

    lea ARG1, [buffer]
    ABI_CALL to_upper
    PRINT "copied, filled, upper-cased: "
    mov r10, r13
    call print_text
    PRINT 10

    lea ARG1, [word_abc]
    lea ARG2, [word_abc]
    mov ARG3, 3
    ABI_CALL equal_bytes
    mov r12, rax
    lea ARG1, [word_abc]
    lea ARG2, [word_abd]
    mov ARG3, 3
    ABI_CALL equal_bytes
    PRINT 'equal_bytes("abc", "abc") = '
    PINT r12
    PRINT ', equal_bytes("abc", "abd") = '
    PINT rax
    PRINT 10

    pop r13
    pop r12
    pop rbp
    ret

; =================================================================================================
;  8. Macros and the preprocessor
; =================================================================================================

; Everything here happens while the file is assembled; the processor never sees it.
; C#: constants, #if, and source generators.

%define SQUARE(x) ((x) * (x))       ; a single-line macro with a parameter
%assign TABLE_SIZE 8                ; a numeric variable of the preprocessor

; A multi-line macro: CLAMP register, low, high. %1, %2, %3 are the parameters, and a label
; that starts with %% is unique in every expansion.
%macro CLAMP 3
    cmp %1, %2
    jge %%not_below
    mov %1, %2
%%not_below:
    cmp %1, %3
    jle %%not_above
    mov %1, %3
%%not_above:
%endmacro

section RODATA
squares:
%assign entry 0
%rep TABLE_SIZE                     ; repeat these lines while `entry` counts up
    dq SQUARE(entry)
%assign entry entry + 1
%endrep
%undef entry

nasm_version:   db __NASM_VER__, 0  ; a predefined macro: the version of the assembler

section .text

section08_macros:
    TITLE "8", "Macros and the preprocessor"

    PRINT "a table that the assembler computed:"
    lea r8, [squares]
    xor ecx, ecx
.next:
    PRINT " "
    PINT [r8 + rcx*8]
    inc rcx
    cmp rcx, TABLE_SIZE
    jb .next
    PRINT 10

    mov rax, 15
    CLAMP rax, 0, 10
    mov rcx, -3
    CLAMP rcx, 0, 10
    PRINT "CLAMP 15 and -3 to 0..10: "
    PINT rax
    PRINT " and "
    PINT rcx
    PRINT 10

    mov rax, SQUARE(12)             ; the assembler computes 144; the instruction is mov rax, 144
    SHOW "SQUARE(12), a constant: ", rax

%if TABLE_SIZE > 4                  ; conditional assembly
    PRINT "the table has more than 4 entries; assembled by NASM "
%else
    PRINT "the table is small; assembled by NASM "
%endif
    lea r10, [nasm_version]
    call print_text
    PRINT 10
    ret

; =================================================================================================
;  9. Floating point and SIMD
; =================================================================================================

; Floating-point numbers live in the registers xmm0 ... xmm15, each 128 bits wide. The
; scalar instructions (ending in sd for double, ss for float) use the lowest element; the
; packed ones (pd, ps, and the integer p...) work on all the elements at once.
; C#: double; Vector128<T> and System.Runtime.Intrinsics.X86.

section RODATA
align 16
vector_a:       dd 1, 2, 3, 4                   ; four 32-bit integers
vector_b:       dd 10, 20, 30, 40
floats_a:       dd 1.5, 2.5, 3.5, 4.5           ; four floats
floats_b:       dd 2.0, 2.0, 2.0, 2.0
eight_a:        dd 1, 2, 3, 4, 5, 6, 7, 8
eight_b:        dd 100, 100, 100, 100, 100, 100, 100, 100
three:          dq 3.0                          ; a double. C#: 3.0
four:           dq 4.0
two_and_a_half: dq 2.5
thousand:       dq 1000.0

section .bss
alignb 32
vector_result:  resd 8

section .text

; long has_avx2(void): 1 if the processor and the operating system support AVX2
has_avx2:
    push rbx                        ; cpuid overwrites rbx, which belongs to the caller
    mov eax, 1
    cpuid
    xor eax, eax
    and ecx, 0x18000000             ; bit 27: the OS saves the wide registers; bit 28: AVX
    cmp ecx, 0x18000000
    jne .done
    xor ecx, ecx
    xgetbv                          ; which register states does the OS save?
    and eax, 6                      ; bits 1 and 2: xmm and ymm
    cmp eax, 6
    mov eax, 0
    jne .done
    mov eax, 7
    xor ecx, ecx
    cpuid
    shr ebx, 5                      ; leaf 7, ebx bit 5: AVX2
    and ebx, 1
    mov eax, ebx
.done:
    pop rbx
    ret

section09_floating_point:
    push rbp
    mov rbp, rsp
    TITLE "9", "Floating point and SIMD"

    ; Scalar doubles: sqrt(3*3 + 4*4). C#: Math.Sqrt(3.0 * 3.0 + 4.0 * 4.0)
    movsd xmm0, [three]
    mulsd xmm0, xmm0
    movsd xmm1, [four]
    mulsd xmm1, xmm1
    addsd xmm0, xmm1
    sqrtsd xmm0, xmm0
    mulsd xmm0, [thousand]          ; the tour prints fixed-point numbers: value * 1000
    cvttsd2si rax, xmm0             ; double -> integer, truncating. C#: (long)x
    PRINT "sqrt(3*3 + 4*4) = "
    PFIX rax
    PRINT 10

    ; Conversions between integers and doubles.
    mov eax, 7
    cvtsi2sd xmm0, rax              ; integer -> double. C#: (double)n
    mov eax, 2
    cvtsi2sd xmm1, rax
    divsd xmm0, xmm1                ; 3.5
    cvttsd2si rax, xmm0             ; truncates
    cvtsd2si rcx, xmm0              ; rounds to the nearest, a tie to the even neighbour
    cvtsd2si rdx, [two_and_a_half]
    PRINT "7 / 2 = 3.5: truncated "
    PINT rax
    PRINT ", rounded "
    PINT rcx
    PRINT "; 2.5 rounded "
    PINT rdx
    PRINT 10

    ; Comparison: ucomisd sets the flags of an UNSIGNED comparison (ja, jb, je); the parity
    ; flag means "unordered": one of the operands is a NaN.
    xorpd xmm1, xmm1                ; 0.0
    divsd xmm1, xmm1                ; 0.0 / 0.0 = NaN, and no trap by default
    ucomisd xmm1, xmm1
    setp al
    movzx rax, al
    SHOW "0.0 / 0.0 compared with itself is unordered: ", rax

    ; Packed integers: four additions in one instruction. C#: Vector128.Add(a, b)
    movdqa xmm0, [vector_a]         ; movdqa requires a 16-byte aligned address; movdqu does not
    paddd xmm0, [vector_b]
    movdqa [vector_result], xmm0
    lea r8, [vector_result]
    PRINT "(1, 2, 3, 4) + (10, 20, 30, 40) ="
    xor ecx, ecx
.int_next:
    movsxd rax, dword [r8 + rcx*4]
    PRINT " "
    PINT rax
    inc rcx
    cmp rcx, 4
    jb .int_next
    PRINT 10

    ; Packed floats: four multiplications, then four conversions to integers.
    movaps xmm0, [floats_a]
    mulps xmm0, [floats_b]
    cvttps2dq xmm0, xmm0
    movdqa [vector_result], xmm0
    PRINT "(1.5, 2.5, 3.5, 4.5) * 2 ="
    xor ecx, ecx
.float_next:
    movsxd rax, dword [r8 + rcx*4]
    PRINT " "
    PINT rax
    inc rcx
    cmp rcx, 4
    jb .float_next
    PRINT 10

    ; AVX2 doubles the width to 256 bits (ymm registers) and gives instructions a separate
    ; destination. It is an extension: test for it before using it.
    ; C#: Vector256.IsHardwareAccelerated, Avx2.IsSupported
    ABI_CALL has_avx2
    test rax, rax
    jz .no_avx2
    vmovdqu ymm0, [eight_a]
    vpaddd ymm0, ymm0, [eight_b]    ; destination, first source, second source
    vmovdqu [vector_result], ymm0
    vzeroupper                      ; leave the upper halves clean for the SSE code around
    PRINT "AVX2, eight additions at once:"
    lea r8, [vector_result]
    xor ecx, ecx
.avx_next:
    movsxd rax, dword [r8 + rcx*4]
    PRINT " "
    PINT rax
    inc rcx
    cmp rcx, 8
    jb .avx_next
    PRINT 10
    jmp .done
.no_avx2:
    PRINT "AVX2 is not available on this machine", 10
.done:
    pop rbp
    ret

; =================================================================================================
;  10. Bit scans, byte order, CPUID
; =================================================================================================

section .bss
vendor:         resb 16

section .text

section10_bits:
    push rbp
    mov rbp, rsp
    push rbx                        ; cpuid overwrites rbx
    sub rsp, 8                      ; keep rsp a multiple of 16
    TITLE "10", "Bit scans, byte order, CPUID"

    mov rax, 0b101000
    bsf rcx, rax                    ; the index of the lowest set bit
    bsr rdx, rax                    ; the index of the highest set bit
    PRINT "101000: the lowest set bit is bit "
    PINT rcx
    PRINT ", the highest is bit "
    PINT rdx
    PRINT 10
    ; C#: BitOperations.TrailingZeroCount and BitOperations.Log2

    mov rax, 0x1122334455667788
    bswap rax                       ; reverse the bytes. C#: BinaryPrimitives.ReverseEndianness
    PRINT "bswap 0x1122334455667788 = 0x"
    PHEX rax, 16
    PRINT 10

    xor eax, eax
    bts rax, 5                      ; set bit 5 (and copy its old value into the carry flag)
    bts rax, 0
    btr rax, 0                      ; reset bit 0
    bt rax, 5                       ; test bit 5: the carry flag receives it
    setc cl
    movzx rcx, cl
    PRINT "bts 5, bts 0, btr 0 gives "
    PINT rax
    PRINT "; bt 5 reports "
    PINT rcx
    PRINT 10

    ; cpuid describes the processor: eax selects a "leaf", and the answer comes in eax,
    ; ebx, ecx and edx. Leaf 0 returns the vendor name in ebx, edx, ecx.
    xor eax, eax
    cpuid
    lea r8, [vendor]
    mov [r8], ebx
    mov [r8 + 4], edx
    mov [r8 + 8], ecx
    mov byte [r8 + 12], 0
    PRINT "the vendor string from cpuid: "
    mov r10, r8
    call print_text
    PRINT 10

    ; popcnt counts the set bits. It is an extension (leaf 1, ecx bit 23).
    ; C#: BitOperations.PopCount
    mov eax, 1
    cpuid
    bt ecx, 23
    jnc .no_popcnt
    mov rax, 0x00FF00FF
    popcnt rax, rax
    SHOW "popcnt 0x00FF00FF = ", rax
    jmp .timestamp
.no_popcnt:
    PRINT "popcnt is not available on this machine", 10

.timestamp:
    ; rdtsc reads the time-stamp counter into edx:eax. C#: Stopwatch.GetTimestamp
    rdtsc
    shl rdx, 32
    or rax, rdx
    mov r8, rax
    rdtsc
    shl rdx, 32
    or rax, rdx
    xor ecx, ecx
    cmp rax, r8
    seta cl
    SHOW "the time-stamp counter went forward: ", rcx

    add rsp, 8
    pop rbx
    pop rbp
    ret

; =================================================================================================
;  11. Atomic instructions
; =================================================================================================

section .data
shared:         dq 0

section .text

section11_atomics:
    TITLE "11", "Atomic instructions"

    ; `inc qword [shared]` reads, adds and writes, and another core can get in between.
    ; The lock prefix makes the whole instruction atomic. C#: Interlocked.Increment
    mov qword [shared], 10
    lock inc qword [shared]
    SHOW "lock inc: ", [shared]

    ; xadd exchanges and adds: the memory receives the sum, the register the old value.
    ; C#: Interlocked.Add (which returns the new value) is built on it.
    mov rax, 5
    lock xadd [shared], rax
    PRINT "lock xadd 5: the memory holds "
    PINT [shared]
    PRINT ", the register got the old value "
    PINT rax
    PRINT 10

    ; cmpxchg: if the memory equals rax, store the source there and set the zero flag;
    ; otherwise load the memory into rax. All lock-free code rests on it.
    ; C#: Interlocked.CompareExchange
    mov rax, 16                     ; the value we expect
    mov rcx, 100                    ; the value we want to store
    lock cmpxchg [shared], rcx
    setz dl
    movzx rdx, dl
    PRINT "cmpxchg expecting 16: success "
    PINT rdx
    PRINT ", the memory holds "
    PINT [shared]
    PRINT 10
    mov rax, 16                     ; the expectation is now wrong
    mov rcx, 200
    lock cmpxchg [shared], rcx
    setz dl
    movzx rdx, dl
    PRINT "cmpxchg expecting 16 again: success "
    PINT rdx
    PRINT ", rax received the current value "
    PINT rax
    PRINT 10

    ; xchg with memory is always atomic, even without the prefix. C#: Interlocked.Exchange
    mov rax, 7
    xchg [shared], rax
    PRINT "xchg 7: the old value was "
    PINT rax
    PRINT ", the memory holds "
    PINT [shared]
    PRINT 10

    ; A spin lock is a loop around xchg, with pause to be polite to the other thread of
    ; the core (C#: SpinLock, SpinWait):
    ;
    ;     .acquire:   mov eax, 1
    ;                 xchg [lock_word], eax       ; take the lock, see what was there
    ;                 test eax, eax
    ;                 jz .acquired                ; it was free
    ;                 pause
    ;                 jmp .acquire
    ;
    ; x86 keeps the order of memory operations strong: only a store followed by a load of
    ; another address may be seen reordered. A locked instruction or mfence is a full
    ; barrier. C#: Volatile.Read, Volatile.Write, Thread.MemoryBarrier
    ret

; =================================================================================================
;  12. Indirect calls and a virtual table by hand
; =================================================================================================

; long op_add(long a, long b) and its relatives, for a table of operations.
; C#: delegates, function pointers (delegate*)
op_add:
    lea rax, [ARG1 + ARG2]
    ret

op_sub:
    mov rax, ARG1
    sub rax, ARG2
    ret

op_mul:
    mov rax, ARG1
    imul rax, ARG2
    ret

; Two kinds of "objects". The first field of each is the address of a table of functions:
; what the CLR calls the method table. C#: a virtual method call does exactly these two loads.
VT_AREA         equ 0               ; the offsets of the entries in such a table
VT_SIDES        equ 8

; long rectangle_area(const rectangle *self)
rectangle_area:
    mov rax, [ARG1 + 8]
    imul rax, [ARG1 + 16]
    ret

; long square_area(const square *self)
square_area:
    mov rax, [ARG1 + 8]
    imul rax, rax
    ret

; long four_sides(const void *self): shared by both
four_sides:
    mov eax, 4
    ret

section RODATA
operations:         dq op_add, op_sub, op_mul           ; an array of function pointers
rectangle_vtable:   dq rectangle_area, four_sides
square_vtable:      dq square_area, four_sides

section .data
rectangle_object:   dq rectangle_vtable, 3, 4           ; table, width, height
square_object:      dq square_vtable, 5                 ; table, side
shapes:             dq rectangle_object, square_object  ; an array of references

section .text

section12_indirect:
    push rbp
    mov rbp, rsp
    push r12
    push r13
    TITLE "12", "Indirect calls and a virtual table by hand"

    ; A function address in a register. C#: a delegate, or delegate* unmanaged
    lea r12, [op_mul]
    mov ARG1, 6
    mov ARG2, 7
    ABI_CALL r12
    SHOW "a call through a register: op_mul(6, 7) = ", rax

    ; A call through a table of addresses.
    PRINT "operations[i](12, 4):"
    lea r12, [operations]
    xor r13d, r13d
.operation_next:
    mov ARG1, 12
    mov ARG2, 4
    ABI_CALL [r12 + r13*8]
    PRINT " "
    PINT rax
    inc r13
    cmp r13, 3
    jb .operation_next
    PRINT 10

    ; A virtual call: load the object's table, then call through one of its entries.
    lea r12, [shapes]
    xor r13d, r13d
.shape_next:
    mov ARG1, [r12 + r13*8]         ; the object: `this`
    mov rax, [ARG1]                 ; its table of functions
    ABI_CALL [rax + VT_AREA]        ; the virtual call
    PRINT "shape "
    PINT r13
    PRINT ": area "
    PINT rax
    mov ARG1, [r12 + r13*8]
    mov rax, [ARG1]
    ABI_CALL [rax + VT_SIDES]
    PRINT ", sides "
    PINT rax
    PRINT 10
    inc r13
    cmp r13, 2
    jb .shape_next

    pop r13
    pop r12
    pop rbp
    ret

; =================================================================================================
;  13. Talking to the operating system
; =================================================================================================

; A program can do nothing visible by itself: output, files, memory, threads and the exit
; all go through the operating system. C#: the runtime does this beneath Console, File, GC.
;
; Linux: the syscall instruction. The number of the call goes in rax, the arguments in rdi,
; rsi, rdx, r10, r8, r9; the result comes back in rax, where -1 ... -4095 is a negated
; error number. syscall itself destroys rcx and r11. (See `emit` near the top.)
;
; Windows: the system-call numbers are not a stable interface. A program calls functions of
; system DLLs such as kernel32.dll with the Microsoft convention; a failure is reported by
; the return value, and GetLastError tells the reason.

section13_system:
    push rbp
    mov rbp, rsp
    TITLE "13", "Talking to the operating system"

%ifdef LINUX
    mov eax, 1                      ; write ...
    mov edi, -1                     ; ... to a descriptor that does not exist
    lea rsi, [main_message]
    mov edx, 1
    syscall
    SHOW "write to the descriptor -1 returns (-9 is EBADF): ", rax
    ; C#: the runtime turns such a result into an IOException.

    ; At the entry point the stack holds argc, then the argv pointers, then the environment.
    SHOW "the number of command-line arguments, the program name included: ", [argument_count]
%else
    sub rsp, 64                     ; shadow space, the fifth argument, two local slots
    xor ecx, ecx                    ; a handle that does not exist
    lea rdx, [main_message]
    mov r8d, 1
    lea r9, [rsp + 40]
    mov qword [rsp + 32], 0
    call WriteFile
    mov eax, eax                    ; the result is a 32-bit BOOL: 0 means failure
    mov [rsp + 48], rax
    call GetLastError
    mov eax, eax
    mov rcx, [rsp + 48]
    add rsp, 64
    PRINT "WriteFile to the handle 0 returns "
    PINT rcx
    PRINT ", GetLastError says (6 is ERROR_INVALID_HANDLE): "
    PINT rax
    PRINT 10
    ; C#: Marshal.GetLastWin32Error, or a Win32Exception thrown by the runtime.
%endif
    pop rbp
    ret

; =================================================================================================
;  14. The newest
; =================================================================================================

section RODATA
align 64
sixteen_a:      dd 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
sixteen_b:      times 16 dd 100                 ; `times` repeats a line

section .bss
alignb 64
wide_result:    resd 16

section .text

; long has_avx512(void): 1 if the processor has AVX-512 Foundation and the operating system
; saves the zmm and the mask registers
has_avx512:
    push rbx
    mov eax, 1
    cpuid
    xor eax, eax
    bt ecx, 27                      ; may xgetbv be used at all?
    jnc .done
    xor ecx, ecx
    xgetbv
    and eax, 0xE6                   ; the states of xmm, ymm, the masks and both zmm parts
    cmp eax, 0xE6
    mov eax, 0
    jne .done
    mov eax, 7
    xor ecx, ecx
    cpuid
    shr ebx, 16                     ; leaf 7, ebx bit 16: AVX-512 Foundation
    and ebx, 1
    mov eax, ebx
.done:
    pop rbx
    ret

; cpuid leaf 7, subleaf 0: ebx bit 5 is AVX2, bit 16 is AVX-512 Foundation;
; leaf 7, subleaf 1: edx bit 21 is APX.
section14_newest:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    TITLE "14", "The newest"

    mov eax, 7
    xor ecx, ecx
    cpuid
    mov r12d, ebx
    PRINT "this processor reports: AVX2 "
    mov eax, r12d
    shr eax, 5
    and eax, 1
    PINT rax
    PRINT ", AVX-512F "
    mov eax, r12d
    shr eax, 16
    and eax, 1
    PINT rax
    mov eax, 7
    mov ecx, 1
    cpuid
    shr edx, 21
    and edx, 1
    PRINT ", APX "
    PINT rdx
    PRINT "  (1 = yes)", 10

    ; The instruction set keeps growing, and a program has to ask cpuid before it uses
    ; anything beyond the baseline of 2003 (SSE2). Compilers group the extensions into levels:
    ;     x86-64-v2   SSE4.2, popcnt                        (processors since about 2009)
    ;     x86-64-v3   AVX2, BMI1/2, FMA, lzcnt, movbe       (since about 2013)
    ;     x86-64-v4   AVX-512                               (some processors since 2017)
    ; C#: the JIT detects the features at start-up, so the same IL uses what the machine has.

    ; AVX-512 has 32 registers of 512 bits (zmm0 ... zmm31) and mask registers k0 ... k7
    ; that select the elements an instruction applies to. AVX10 repackages the same
    ; instructions. C#: Vector512<T>, Avx512F
    ABI_CALL has_avx512
    test rax, rax
    jz .no_avx512
    vmovdqu32 zmm0, [sixteen_a]
    mov eax, 0x5555                 ; the mask: every second element
    kmovw k1, eax
    vpaddd zmm0 {k1}{z}, zmm0, [sixteen_b]      ; {z}: the elements left out become 0
    vmovdqu32 [wide_result], zmm0
    vzeroupper
    PRINT "AVX-512, sixteen additions under the mask 0101...:"
    lea r8, [wide_result]
    xor ecx, ecx
.wide_next:
    movsxd rax, dword [r8 + rcx*4]
    PRINT " "
    PINT rax
    inc rcx
    cmp rcx, 16
    jb .wide_next
    PRINT 10
    jmp .apx
.no_avx512:
    PRINT "AVX-512 is not available on this machine", 10

.apx:
    ; APX, Intel's Advanced Performance Extensions, doubles the general-purpose registers
    ; (r16 ... r31) and gives the classic instructions a separate destination:
    ;     add r16, r17, r18                       ; r16 = r17 + r18
    ; NASM assembles it from version 3.00 (October 2025); processors with APX had been
    ; announced but were not on sale when this was written. NOT assembled here: NASM 2.16
    ; does not know these registers.
    PRINT "APX: see the comments in the source", 10

    pop r12
    pop rbx
    pop rbp
    ret

; =================================================================================================
;  The entry point. C#: Main — except that nothing has been set up, and nothing cleans up.
; =================================================================================================

%ifdef WINDOWS
start:
    sub rsp, 40                     ; align the stack and reserve the shadow space
    mov ecx, -11                    ; STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    add rsp, 40
%else
_start:
    mov rax, [rsp]                  ; Linux puts argc on top of the initial stack
    mov [argument_count], rax
%endif
    and rsp, -16                    ; make sure that rsp is a multiple of 16

    call section01_program
    call section02_registers
    call section03_arithmetic
    call section04_control_flow
    call section05_memory
    call section06_stack
    call section07_strings
    call section08_macros
    call section09_floating_point
    call section10_bits
    call section11_atomics
    call section12_indirect
    call section13_system
    call section14_newest

    ; Returning from the entry point is not possible on Linux (nothing called it), so the
    ; program asks the operating system to end it. C#: Environment.Exit(0)
%ifdef WINDOWS
    sub rsp, 32
    xor ecx, ecx
    call ExitProcess
%else
    mov eax, 60                     ; system call 60: exit(status)
    xor edi, edi
    syscall
%endif
