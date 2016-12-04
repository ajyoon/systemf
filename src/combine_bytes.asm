  ; mov byte [testbuffer], 255
  ; mov byte [testbuffer + 1], 255

  ; mov rdi, testbuffer
  ; mov rsi, 2
  ; call combine_bytes

  ; push rax
  ; mov rax, 1
  ; pop rdi
  ; mov rdx, 300
  ; syscall

;;
combineBytes:
  ;; rdi -> address of buffer start
  ;; rsi -> length of bytes to combine
  push rbp
  push rdx                      ; Save rbp, rdx, rcx, r8 to restore later
  push rcx
  push r8
  mov rdx, rdi                  ; rdx = Current byte address
  mov rcx, 0                    ; rcx = Combined data value

combineLoop:
  sal rcx, 8
  or  rcx, [rdx]
  inc rdx
  mov r8, rdi
  add r8, rsi
  dec r8
  cmp rdx, r8
  jl combineLoop

  mov rax, rcx
  pop r8
  pop rcx
  pop rdx
  pop rbp
  ret
