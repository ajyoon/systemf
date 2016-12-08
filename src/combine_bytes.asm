combineBytes:
;; A function that takes a series of bytes and joins them together as
;; a big-endian integer.
;; Args:
;;   * rdi -> address of buffer start
;;   * rsi -> length of bytes to combine
  push rbp                      ; Function prologue
  push rdx
  push r10
  push r8
  push r9

  mov r9,  0                    ; r9  = Bytes combined
  mov r10, 0                    ; r10 = Combined data value

;; Load first byte
  movzx r10, byte [rdi + r9]
  inc r9

;; Skip loop if byte length is 1
  cmp r9, rsi
  jge .combineBytesFinish

.combineLoop:
  sal r10, 8                    ; Repeatedly shift left and OR to combine bytes
  or  r10b, byte [rdi + r9]
  inc r9
  cmp r9, rsi
  jne .combineLoop

.combineBytesFinish:
  mov rax, r10
  pop r9                        ; Function epilogue
  pop r8
  pop r10
  pop rdx
  pop rbp
  ret
