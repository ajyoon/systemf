section .text

buildJumpTable:
  ;; rdi -> address of file buffer
  ;; rsi -> address for new jump table
  push r8                       ; Save registers
  push r9
  push r10
  push r11
  push r12
  push r13

.parseBrackets:
  %define FILE_POS r8
  %define TMP_ADDR r9
  %define FILE r10
  %define JUMP_TABLE r11
  %define INITIAL_STACK_PTR r12

  mov FILE_POS, 0
  mov FILE, rdi
  mov JUMP_TABLE, rsi
  mov INITIAL_STACK_PTR, rsp    ; Save initial stack ptr for brackets error check

.parseLoop:
  cmp byte [FILE + FILE_POS], 0      ; Check for EOF
  je .finish
  cmp byte [FILE + FILE_POS], 5Bh  ; If char == '['
  je .processLeftBracket
  cmp byte [FILE + FILE_POS], 5Dh  ; If char == ']'
  je .processRightBracket
  ;; Ignore all other characters
  jmp .parseLoopTail

.processLeftBracket:
  push r8 ;FILE_POS
  jmp .parseLoopTail

.processRightBracket:
  ; Get file index of last left bracket
  pop r13
  ; Point jump_table[right_bracket_pos] to left_bracket_pos
  mov rax, 8
  mul FILE_POS
  mov TMP_ADDR, rax
  add TMP_ADDR, JUMP_TABLE
  mov [TMP_ADDR], r13
  ; Point jump_table[left_bracket_pos] to right_bracket_pos
  mov rax, 8
  mul r13
  mov TMP_ADDR, rax
  add TMP_ADDR, JUMP_TABLE
  ; Point left bracket to just past right bracket by incrementing FILE_POS
  inc FILE_POS
  mov [TMP_ADDR], FILE_POS
  ; Reset FILE_POS
  dec FILE_POS
  jmp .parseLoopTail

.parseLoopTail:
  inc FILE_POS
  jmp .parseLoop

.finish:
  ; If stack pointer has moved since start, brackets don't match!
  cmp INITIAL_STACK_PTR, rsp
  jne mismatchBracketsError

  pop r13                       ; Restore registers and return
  pop r12
  pop r11
  pop r10
  pop r9
  pop r8

  ret
