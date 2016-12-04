%define FILE_LENGTH 131072
%define TAPE_LENGTH 30000
%define ARG_LENGTH  256

global  _start

section .data
boundsErrorMsg:            db "Tape position out of bounds", 10
boundsErrorMsgLen:         equ $ - boundsErrorMsg
bracketsSyntaxErrorMsg:    db "Syntax Error: Mismatched brackets", 10
bracketsSyntaxErrorMsgLen: equ $ - bracketsSyntaxErrorMsg

section .bss
;; Buffer for file being read
file:        resb FILE_LENGTH
;; Byte array for the brainfuck tape
tape:        resb TAPE_LENGTH
;; Array for recording jump indexes during parsing
index_stack: resb FILE_LENGTH
;; Array for recording jump indexes for brackets during execution.
jump_table:  resb FILE_LENGTH
;; Arrays and mode flags for syscall args
arg_zero:       resb ARG_LENGTH
arg_zero_mode:  resb 1
arg_one:        resb ARG_LENGTH
arg_one_mode:   resb 1
arg_two:        resb ARG_LENGTH
arg_two_mode:   resb 1
arg_three:      resb ARG_LENGTH
arg_three_mode: resb 1
arg_four:       resb ARG_LENGTH
arg_four_mode:  resb 1
arg_five:       resb ARG_LENGTH
arg_five_mode:  resb 1

section  .text                  ; declaring our .text segment

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

parseBrackets:
  %define STACK_POS r10         ; Position of the stack top
  %define FILE_INDEX r15        ; Position of the interpreter in the program
  %define CURRENT_CHAR r9       ; The current interpreter character
  mov STACK_POS, -1             ; Initialize stack position
  mov FILE_INDEX, 0             ; Initialize file position

parseLoop:
  movzx CURRENT_CHAR, byte [file + FILE_INDEX] ; Read character
  cmp CURRENT_CHAR, 5Bh                        ; Test if == '['
  jne checkRightBracket
parseLeftBracket:
  ;; Push the character file index onto the index stack
  inc STACK_POS
  mov [index_stack + STACK_POS], FILE_INDEX
  jmp parseLoopTail
checkRightBracket:
  cmp CURRENT_CHAR, 5Dh
  jne checkFileEnd
parseRightBracket:
  ;; If the stack position <= -1, the brackets are mismatched
  cmp STACK_POS, -1
  jle mismatchBracketsError
  ;; Pop the left bracket from the stacks and place references from each bracket
  ;; to each other in the jump_table for use in program execution

  mov r12b, byte [index_stack + STACK_POS] ; Store the '[' file index in r12
  mov [jump_table + FILE_INDEX], r12b      ; Set jump_table[right_bracket] to left_bracket
  mov r13, FILE_INDEX
  inc r13                      ; Store right bracket file index + 1 in r13
  mov [jump_table + r12], r13b ; Set jump_table[left_bracket] to right_bracket + 1
  dec STACK_POS                ; Decrement stack pointer
  jmp parseLoopTail
checkFileEnd:
  cmp CURRENT_CHAR, 0
  je parseLoopTerminate
parseLoopTail:
  inc FILE_INDEX
  jmp parseLoop
parseLoopTerminate:
  ;; If the stack position != -1, the brackets are mismatched
  cmp STACK_POS, -1
  jne mismatchBracketsError
  ;; Otherwise all is well. Begin program execution.
  jmp mainLoopStart


;; Main loop for script interpretation ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


%define BF_PROGRAM_POS r15 ; Current position index of the program interpreter (0...n)
  ; in the read program file
%define CURRENT_SYM r14         ; Symbol at the current program position
%define TAPE_POINTER r13        ; Pointer in the brainfuck array

mainLoopStart:
;; Set up main loop

  mov BF_PROGRAM_POS, 0         ; Initialize the interpreter position
  mov TAPE_POINTER, tape        ; Initialize the tape pointer to pos 0


mainLoop:

  cmp BF_PROGRAM_POS, FILE_LENGTH ; if BF_PROGRAM_POS > file length, exit.
  jg exitSuccess

  ;; Read symbol at BF_PROGRAM_POS
  movzx CURRENT_SYM, byte [file + BF_PROGRAM_POS]

  cmp CURRENT_SYM, 0h           ; NULL   End of read file, exit.
  je exitSuccess

  cmp CURRENT_SYM, 3Eh          ; >      Increment pointer
  je BF_INCR_PTR

  cmp CURRENT_SYM, 3Ch          ; <      Decrement pointer
  je BF_DECR_PTR

  cmp CURRENT_SYM, 2Bh          ; +      Increment cell
  je BF_INCR_CELL

  cmp CURRENT_SYM, 2Dh          ; -      Decrement cell
  je BF_DECR_CELL

  cmp CURRENT_SYM, 2Ch          ; ,      Get character
  je BF_GET_CHAR

  cmp CURRENT_SYM, 2Eh          ; .      Put character
  je BF_PUT_CHAR

  cmp CURRENT_SYM, 5Bh          ; [      Start loop
  je BF_LOOPSTART

  cmp CURRENT_SYM, 5Dh          ; ]      End loop
  je BF_LOOPEND

  cmp CURRENT_SYM, 25h          ; %      Syscall
  je BF_SYSTEMCALL

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
  movzx r9, byte [jump_table + BF_PROGRAM_POS] ; Set r9 to jump-to location
  mov BF_PROGRAM_POS, r9
  jmp mainLoopTailNoChangeProgramPos

BF_LOOPEND:                     ; Bracket close, end of loop
  cmp byte [TAPE_POINTER], 0
  je mainLoopTailIncrementProgramPos
  movzx r9, byte [jump_table + BF_PROGRAM_POS] ; Set r9 to jump-to location
  mov BF_PROGRAM_POS, r9
  jmp mainLoopTailNoChangeProgramPos

BF_SYSTEMCALL:
;;
;; System calls are read from the tape from the current position
;;
;; The current cell holds the syscall code.
;; The second cell holds the number of arguments
;; The following cells repeat in blocks of arguments in the form:
;;   * 1 cell for the type of argument (0 for normal, 1 for pointer)
;;   * 1 cell for the size (in cells) of the argument.
;;   * n cells for the data of the argument.
;;
;; The resulting value is dumped directly into the tape
;; from the position of the syscall code.
;; If the return value is a pointer,
;; it is dereferenced and dumped to tape.
;;
  mov r12, TAPE_POINTER         ; r12 = syscall excursion tape pointer
  movzx r9, byte [r12]          ; r9 = syscall code
  inc r12                       ; Move excursion tape pointer to next cell
  movzx r11, byte [r12]         ; r11 = number of args
  mov rbx, 0                    ; rbx = current arg number
sysCallGetArg:
  ;; TODO: There is a lot of repeated code here that could probably
  ;;       be simplified greatly with some macros
  cmp r11, 0
  jle sysCallExecute         ; End loop once args are exhausted
  mov rcx, 0                 ; Set rcx = 0 to track buffer copy offset
  cmp rbx, 0                 ; Branch to current argument ...
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

sysCallGetArgZero:
  inc r12                        ; Increment excursion tape pointer to arg type cell
  mov r8b, byte [r12]
  mov byte [arg_zero_mode], r8b  ; Get arg type
  inc r12                        ; Increment excursion tape pointer
  movzx r10, byte [r12]          ; Get the argument length
sysCallGetArgZeroChar:           ; Read r12 tape cells into arg_zero
  cmp r10, 0
  je sysCallGetArgCharTail      ; If there are no more cells to read, this arg is fully read.
  inc r12                       ; Increment excursion tape pointer to next argument cell
  mov al, byte [r12]            ; use al as temporary holding place for current cell value
  mov byte [arg_zero + rcx], al ; Copy current cell to arg_zero buffer
                                ; position in arg_zero buffer
  inc rcx                       ; arg_zero byte buffer offset
  dec r10
  jmp sysCallGetArgZeroChar

sysCallGetArgOne:
  inc r12                       ; Increment excursion tape pointer to arg type cell
  mov r8b, byte [r12]
  mov byte [arg_one_mode], r8b  ; Get arg type
  inc r12                       ; Increment excursion tape pointer
  movzx r10, byte [r12]         ; Get the argument length
sysCallGetArgOneChar:           ; Read r12 tape cells into arg_one
  cmp r10, 0
  je sysCallGetArgCharTail      ; If there are no more cells to read, this arg is fully read.
  inc r12                       ; Increment excursion tape pointer to next argument cell
  mov al, byte [r12]            ; use al as temporary holding place for current cell value
  mov byte [arg_one + rcx], al  ; Copy current cell to arg_zero buffer
                                ; position in arg_one buffer
  inc rcx                       ; arg_one byte buffer offset
  dec r10
  jmp sysCallGetArgOneChar

sysCallGetArgTwo:
  inc r12                       ; Increment excursion tape pointer to arg type cell
  mov r8b, byte [r12]
  mov byte [arg_two_mode], r8b  ; Get arg type
  inc r12                       ; Increment excursion tape pointer
  movzx r10, byte [r12]         ; Get the argument length
sysCallGetArgTwoChar:           ; Read r12 tape cells into arg_two
  cmp r10, 0
  je sysCallGetArgCharTail      ; If there are no more cells to read, this arg is fully read.
  inc r12                       ; Increment excursion tape pointer to next argument cell
  mov al, byte [r12]            ; use al as temporary holding place for current cell value
  mov byte [arg_two + rcx], al  ; Copy current cell to arg_two buffer
  ; position in arg_zero buffer
  inc rcx                       ; arg_two byte buffer offset
  dec r10
  jmp sysCallGetArgTwoChar

sysCallGetArgThree:
  inc r12                        ; Increment excursion tape pointer to arg type cell
  mov r8b, byte [r12]
  mov byte [arg_three_mode], r8b ; Get arg type
  inc r12                        ; Increment excursion tape pointer
  movzx r10, byte [r12]          ; Get the argument length
sysCallGetArgThreeChar:          ; Read r12 tape cells into arg_three
  cmp r10, 0
  je sysCallGetArgCharTail        ; If there are no more cells to read, this arg is fully read.
  inc r12                         ; Increment excursion tape pointer to next argument cell
  mov al, byte [r12]              ; use al as temporary holding place for current cell value
  mov byte [arg_three + rcx], al  ; Copy current cell to arg_three buffer
  ; position in arg_zero buffer
  inc rcx                         ; arg_three byte buffer offset
  dec r10
  jmp sysCallGetArgThreeChar

sysCallGetArgFour:
  inc r12                        ; Increment excursion tape pointer to arg type cell
  mov r8b, byte [r12]
  mov byte [arg_four_mode], r8b  ; Get arg type
  inc r12                        ; Increment excursion tape pointer
  movzx r10, byte [r12]          ; Get the argument length
sysCallGetArgFourChar:           ; Read r12 tape cells into arg_four
  cmp r10, 0
  je sysCallGetArgCharTail      ; If there are no more cells to read, this arg is fully read.
  inc r12                       ; Increment excursion tape pointer to next argument cell
  mov al, byte [r12]            ; use al as temporary holding place for current cell value
  mov byte [arg_four + rcx], al ; Copy current cell to arg_four buffer
  ; position in arg_zero buffer
  inc rcx                       ; arg_four buffer offset
  dec r10
  jmp sysCallGetArgFourChar

sysCallGetArgFive:
  inc r12                        ; Increment excursion tape pointer to arg type cell
  mov r8b, byte [r12]
  mov byte [arg_five_mode], r8b  ; Get arg type
  inc r12                        ; Increment excursion tape pointer
  movzx r10, byte [r12]          ; Get the argument length
sysCallGetArgFiveChar:           ; Read r12 tape cells into arg_five
  cmp r10, 0
  je sysCallGetArgCharTail      ; If there are no more cells to read, this arg is fully read.
  inc r12                       ; Increment excursion tape pointer to next argument cell
  mov al, byte [r12]            ; use al as temporary holding place for current cell value
  mov byte [arg_five + rcx], al ; Copy current cell to arg_five buffer
  ; position in arg_zero buffer
  inc rcx                       ; arg_five byte buffer offset
  dec r10
  jmp sysCallGetArgFiveChar

sysCallGetArgCharTail:
  dec r11                       ; Decrement remaining arguments
  inc rbx                       ; Increment current argument number
  jmp sysCallGetArg

sysCallExecute:
  mov rax, r9                   ; Get syscall code back

get_arg_zero:
  cmp byte [arg_zero_mode], 1
  je get_arg_zero_as_ptr
get_arg_zero_as_val:
  mov rdi, [arg_zero]           ; Put arg_zero in rdi
  jmp get_arg_one
get_arg_zero_as_ptr:
  mov rdi, arg_zero

get_arg_one:
  cmp byte [arg_one_mode], 1
  je get_arg_one_as_ptr
get_arg_one_as_val:
  mov rsi, [arg_one]            ; Put arg_one in rsi
  jmp get_arg_two
get_arg_one_as_ptr:
  mov rsi, arg_one

get_arg_two:
  cmp byte [arg_two_mode], 1
  je get_arg_two_as_ptr
get_arg_two_as_val:
  mov rdx, [arg_two]            ; Put arg_two in rdx
  jmp get_arg_three
get_arg_two_as_ptr:
  mov rdx, arg_two

get_arg_three:
  cmp byte [arg_three_mode], 1
  je get_arg_three_as_ptr
get_arg_three_as_val:
  mov rcx, [arg_three]          ; Put arg_three in rcx
  jmp get_arg_four
get_arg_three_as_ptr:
  mov rcx, arg_three

get_arg_four:
  cmp byte [arg_four_mode], 1
  je get_arg_four_as_ptr
get_arg_four_as_val:
  mov r8,  [arg_four]           ; Put arg_four in r8
  jmp get_arg_five
get_arg_four_as_ptr:
  mov r8,  arg_four

get_arg_five:
  cmp byte [arg_five_mode], 1
  je get_arg_five_as_ptr
get_arg_five_as_val:
  mov r9,  [arg_five]           ; Put arg_five in r9
get_arg_five_as_ptr:
  mov r9,  arg_five
  syscall
  ;; Syscall return value is now in rax
  ;; Dump it into the tape from TAPE_POINTER forward
  ;; (Currently this value is dumped literally, pointers are not dereferenced)
  mov [TAPE_POINTER], rax
  jmp mainLoopTailIncrementProgramPos

;; Continue the main loop by incrementing the program pointer position
;; and looping back
mainLoopTailIncrementProgramPos:
  inc BF_PROGRAM_POS
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
