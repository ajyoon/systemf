# SystemF

## a brainfuck interpreter implemented in x86-64 assembly with the ability to make Linux syscalls

Building:

```sh
nasm -f elf64 -F dwarf systemf.asm -o systemf.o && ld systemf.o -o systemf
```

Details and, you know, a working version forthcoming...
