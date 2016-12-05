; Testing ;;;;;;;;;;;;;
; section .bss
; testbuffer: resb 1000

; section .text
; global _start
; _start:

;   mov byte [testbuffer], 0xff
;   mov byte [testbuffer + 1], 0xef

;   mov rdi, testbuffer
;   mov rsi, 2
;   call combineBytes

;   push rax
;   mov rax, 1
;   pop rdi
;   mov rdx, 300
;   syscall

;   mov rax, 60
;   syscall

combineBytes:
;; rdi -> address of buffer start
;; rsi -> length of bytes to combine
  push rbp
  push rdx                      ; Save some registers to restore later
  push r10
  push r8
  push r9

;;mov rdx, rdi                ; rdx = Current byte address
  mov r9,  0                    ; r9  = Bytes combined
  mov r10, 0                    ; r10 = Combined data value

;; Load first byte
  movzx r10, byte [rdi + r9]
  inc r9

;; Skip loop if byte length is 1
  cmp r9, rsi
  jge combineBytesFinish

combineLoop:
  sal r10, 8
  or  r10b, byte [rdi + r9]
  inc r9
  cmp r9, rsi
  jne combineLoop

combineBytesFinish:
  mov rax, r10

  pop r9
  pop r8
  pop r10
  pop rdx
  pop rbp
  ret
