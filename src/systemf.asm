%define FILE_LENGTH 100000
%define TAPE_LENGTH 30000
%define ARG_LENGTH  256

section .data
boundsErrorMsg:            db "Tape position out of bounds", 10
boundsErrorMsgLen:         equ $ - boundsErrorMsg
filePositionErrorMsg:      db "File position out of bounds", 10
filePositionErrorMsgLen:   equ $ - filePositionErrorMsg
bracketsSyntaxErrorMsg:    db "Syntax Error: Mismatched brackets", 10
bracketsSyntaxErrorMsgLen: equ $ - bracketsSyntaxErrorMsg

section .bss
;; Buffer for file being read
file:        resb FILE_LENGTH
;; Byte array for the brainfuck tape
tape:        resb TAPE_LENGTH
;; Array for recording jump indexes during parsing
index_stack: resq FILE_LENGTH
;; Array for recording jump indexes for brackets during execution.
jump_table:  resq FILE_LENGTH
;; Arrays and mode flags for syscall args
arg_zero:       resb ARG_LENGTH
arg_zero_mode:  resb 1
arg_zero_len:   resb 1
arg_one:        resb ARG_LENGTH
arg_one_mode:   resb 1
arg_one_len:    resb 1
arg_two:        resb ARG_LENGTH
arg_two_mode:   resb 1
arg_two_len:    resb 1
arg_three:      resb ARG_LENGTH
arg_three_mode: resb 1
arg_three_len:  resb 1
arg_four:       resb ARG_LENGTH
arg_four_mode:  resb 1
arg_four_len:   resb 1
arg_five:       resb ARG_LENGTH
arg_five_mode:  resb 1
arg_five_len:   resb 1


section .includes
  %include "src/combine_bytes.asm"
  %include "src/build_jump_table.asm"

section  .text

global  _start
_start:                         ; Entry point

;; Load file ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; Get file path from argv and open it
  pop rdi                       ; argc (discard)
  pop rdi                       ; argv[0] (discard)
  pop rdi                       ; argv[1] -- main argument -- keep.

  ;; TODO: If argv[1] == '-i' consume line remainder and interpret directly?

  mov rsi, 0                    ; Read-only flag
  mov rax, 2                    ; syscall - open()
  syscall

  ;; Read file contents into `file`
  mov rdi, rax                  ; Put file descriptor from open()
                                ; into fd for read()
  mov rax, 0                    ; syscall -read()
  mov rsi, file
  mov rdx, FILE_LENGTH
  syscall

;; Parse brackets to build the jump table ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

mov rdi, file
mov rsi, jump_table
call buildJumpTable

;; Main loop for script interpretation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%define PROGRAM_POS r15 ; Current position index of the program interpreter (0...n)
  ; in the read program file
%define TAPE_POINTER r13        ; Pointer in the brainfuck array

mainLoopStart:
;; Set up main loop

  mov PROGRAM_POS, 0            ; Initialize the interpreter position
  mov TAPE_POINTER, tape        ; Initialize the tape pointer to pos 0


mainLoop:

  cmp PROGRAM_POS, FILE_LENGTH  ; if PROGRAM_POS > file length, exit.
  jg filePositionError

  ;; Read symbol at PROGRAM_POS

  cmp byte [file + PROGRAM_POS], 0h   ; NULL   End of read file, exit.
  je exitSuccess

  cmp byte [file + PROGRAM_POS], 3Eh  ; >      Increment pointer
  je BF_INCR_PTR

  cmp byte [file + PROGRAM_POS], 3Ch  ; <      Decrement pointer
  je BF_DECR_PTR

  cmp byte [file + PROGRAM_POS], 2Bh  ; +      Increment cell
  je BF_INCR_CELL

  cmp byte [file + PROGRAM_POS], 2Dh  ; -      Decrement cell
  je BF_DECR_CELL

  cmp byte [file + PROGRAM_POS], 2Ch  ; ,      Get character
  je BF_GET_CHAR

  cmp byte [file + PROGRAM_POS], 2Eh  ; .      Put character
  je BF_PUT_CHAR

  cmp byte [file + PROGRAM_POS], 5Bh  ; [      Start loop
  je BF_LOOPSTART

  cmp byte [file + PROGRAM_POS], 5Dh  ; ]      End loop
  je BF_LOOPEND

  cmp byte [file + PROGRAM_POS], 25h  ; %      Syscall
  je BF_SYSTEMCALL

  cmp byte [file + PROGRAM_POS], 24h  ; $      No-op for debugging breakpoints
  je BF_DEBUGGING_BREAK

  ;; Otherwise, ignore this character (whitespace / comment)
  jmp mainLoopTailIncrementProgramPos

;; Instructions

BF_INCR_PTR:                    ; Increment program pointer
  inc TAPE_POINTER
  mov r12, tape
  add r12, TAPE_LENGTH
  cmp TAPE_POINTER, r12         ; Check if TAPE_POINTER is behind tape start
  jg boundsError
  jmp mainLoopTailIncrementProgramPos

BF_DECR_PTR:                    ; Decrement program pointer
  dec TAPE_POINTER
  cmp TAPE_POINTER, tape
  jl boundsError
  jmp mainLoopTailIncrementProgramPos

BF_INCR_CELL:                   ; Increment cell value
  inc byte [TAPE_POINTER]
  jmp mainLoopTailIncrementProgramPos

BF_DECR_CELL:                   ; Decrement cell value
  dec byte [TAPE_POINTER]
  jmp mainLoopTailIncrementProgramPos

BF_GET_CHAR:                    ; Read cell char from stdin
  mov rsi, TAPE_POINTER
  mov rax, 0
  mov rdi, 0
  mov rdx, 1
  syscall
  jmp mainLoopTailIncrementProgramPos

BF_PUT_CHAR:                    ; Print cell char to stdout
  mov rsi, TAPE_POINTER
  mov rax, 1
  mov rdi, 0
  mov rdx, 1
  syscall
  jmp mainLoopTailIncrementProgramPos

BF_LOOPSTART:                   ; Bracket open, start of loop
  cmp byte [TAPE_POINTER], 0
  jne mainLoopTailIncrementProgramPos
  mov rax, 8
  mul PROGRAM_POS
  mov r9, rax
  add r9, jump_table
  mov PROGRAM_POS, qword [r9]
  jmp mainLoopTailNoChangeProgramPos

BF_LOOPEND:                     ; Bracket close, end of loop
  cmp byte [TAPE_POINTER], 0
  je mainLoopTailIncrementProgramPos
  mov rax, 8
  mul PROGRAM_POS
  mov r9, rax
  add r9, jump_table
  mov PROGRAM_POS, qword [r9]
  jmp mainLoopTailNoChangeProgramPos

BF_DEBUGGING_BREAK:             ; No-op for debugging breakpoints
  nop
  jmp mainLoopTailIncrementProgramPos

BF_SYSTEMCALL:
;;
;; System calls are read from the tape from the current position
;;
;; The current cell holds the syscall code.
;; The second cell holds the number of arguments
;; The following cells repeat in blocks of arguments in the form:
;;   * 1 cell for the type of argument
;;     (0 for normal, 1 for argument contents pointer,
;;      2 for cell pointer)
;;   * 1 cell for the size (in cells) of the argument.
;;   * n cells for the data of the argument.
;;
;; The resulting value is dumped directly into the tape
;; from the position of the syscall code.
;;
  mov r12, TAPE_POINTER         ; r12 = syscall excursion tape pointer
  inc r12                       ; Move excursion tape pointer to next cell
  movzx r11, byte [r12]         ; r11 = number of args
  mov rbx, 0                    ; rbx = current arg number
sysCallGetArg:
  cmp r11, 0
  jle sysCallExecute            ; End loop once args are exhausted
  mov rcx, 0                    ; Set rcx = 0 to track buffer copy offset
  cmp rbx, 0                    ; Branch to current argument ...
  je sysCallGetArgZero
  cmp rbx, 1
  je sysCallGetArgOne
  cmp rbx, 2
  je sysCallGetArgTwo
  cmp rbx, 3
  je sysCallGetArgThree
  cmp rbx, 4
  je sysCallGetArgFour
  cmp rbx, 5
  je sysCallGetArgFive

%macro read_arg 3
  ;; Read an argument from the tape into buffers
  ;; Arg 1: Address of argument mode target byte
  ;; Arg 2: Address of argument byte buffer
  ;; Arg 3: Address of argument length buffer
  inc r12                       ; Increment excursion tape pointer to arg type cell
  mov r8b, byte [r12]
  mov byte [%1], r8b            ; Get arg type
  inc r12                       ; Increment excursion tape pointer
  movzx r10, byte [r12]         ; Get the argument length
  mov byte [%3], r10b           ; Save argument length
.read_arg_body:                 ; Read r12 tape cells into argument byte buffer
  cmp r10, 0
  je sysCallGetArgCharTail      ; If there are no more cells to read, this arg is fully read.

  inc r12                       ; Increment excursion tape pointer to next argument cell
  mov al, byte [r12]            ; use al as temporary holding place for current cell value
  mov byte [%2 + rcx], al       ; Copy current cell to %2 buffer position in argument buffer
  inc rcx                       ; Argument byte buffer offset
  dec r10
  jmp .read_arg_body
%endmacro

sysCallGetArgZero:
  read_arg arg_zero_mode, arg_zero, arg_zero_len
sysCallGetArgOne:
  read_arg arg_one_mode, arg_one, arg_one_len
sysCallGetArgTwo:
  read_arg arg_two_mode, arg_two, arg_two_len
sysCallGetArgThree:
  read_arg arg_three_mode, arg_three, arg_three_len
sysCallGetArgFour:
  read_arg arg_four_mode, arg_four, arg_four_len
sysCallGetArgFive:
  read_arg arg_five_mode, arg_five, arg_five_len

sysCallGetArgCharTail:
  dec r11                       ; Decrement remaining arguments
  inc rbx                       ; Increment current argument number
  jmp sysCallGetArg

sysCallExecute:

%macro prepare_arg 4
;; Macro to load an argument from a buffer into the a register.
;; Arg 1: Address of the byte flag indicating the argument type
;; Arg 2: The Address of the argument data
;; Arg 3: Target register
;; Arg 4: Byte length of argument data
prepare_%2:
  cmp byte [%1], 0              ; Check argument type flag
  je prepare_%2_as_val
  cmp byte [%1], 1
  je prepare_%2_as_buf
  cmp byte [%1], 2
  je prepare_%2_as_cell_ptr
prepare_%2_as_val:              ; Treat argument as a value
  push rdi
  push rsi
  mov rdi, %2
  movzx rsi, byte [%4]
  call combineBytes
  pop rsi
  pop rdi
  mov %3, rax
  jmp continue_%2
prepare_%2_as_buf:              ; Treat argument as a buffer
  mov %3, %2
  jmp continue_%2
prepare_%2_as_cell_ptr:         ; Treat argument as a cell pointer
  push rdi
  push rsi
  mov rdi, %2
  movzx rsi, byte [%4]
  call combineBytes
  pop rsi
  pop rdi
  mov %3, rax
  add %3, tape
  jmp continue_%2
continue_%2:                    ; Continue...
  ;; (Do nothing)
%endmacro

  prepare_arg arg_zero_mode,  arg_zero,  rdi, arg_zero_len
  prepare_arg arg_one_mode,   arg_one,   rsi, arg_one_len
  prepare_arg arg_two_mode,   arg_two,   rdx, arg_two_len
  prepare_arg arg_three_mode, arg_three, r10, arg_three_len
  prepare_arg arg_four_mode,  arg_four,  r8,  arg_four_len
  prepare_arg arg_five_mode,  arg_five,  r9,  arg_five_len
  movzx rax, byte [TAPE_POINTER]        ; Get syscall code back
  syscall
  ;; Syscall return value is now in rax
  ;; Dump it into the tape from TAPE_POINTER forward
  mov [TAPE_POINTER], al
  jmp mainLoopTailIncrementProgramPos

;; Continue the main loop by incrementing the program pointer position
;; and looping back
mainLoopTailIncrementProgramPos:
  inc PROGRAM_POS
  jmp mainLoop

;; Continue the main loop by looping back without changing the
;; program pointer position
mainLoopTailNoChangeProgramPos:
  jmp mainLoop

;; Exit conditions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

boundsError:
  ;; Print error message
  mov rax, 1
  mov rdi, 0
  mov rsi, boundsErrorMsg
  mov rdx, boundsErrorMsgLen
  syscall
  ;; Exit
  mov rax, 60
  mov rdi, 2
  syscall

filePositionError:
  ;; Print error message
  mov rax, 1
  mov rdi, 0
  mov rsi, filePositionErrorMsg
  mov rdx, filePositionErrorMsgLen
  syscall
  ;; Exit
  mov rax, 60
  mov rdi, 2
  syscall

mismatchBracketsError:
  ;; Print error message
  mov rax, 1
  mov rdi, 0
  mov rsi, bracketsSyntaxErrorMsg
  mov rdx, bracketsSyntaxErrorMsgLen
  syscall
  ;; Exit
  mov rax, 60
  mov rdi, 1
  syscall

exitSuccess:
  mov rax, 60
  mov rdi, 0
  syscall
