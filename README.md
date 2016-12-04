# SystemF

## a brainfuck interpreter with the ability to make Linux syscalls

Building:

```sh
make
```

To run, call the binary on a brainfuck file:
```sh
./bin/systemf examples/hello_world.bf
Hello, World!
```

# Interpreter rules

This interpreter features a full implementation of the [brainfuck](https://esolangs.org/wiki/brainfuck) programming language. The default settings for language-unspecified rules are:

* Each cell in the program arena is a single byte with possible values 0-255
* Cell values wrap automatically between their min (0) and max (255) values
* The program arena consists of 30000 cells
* Attempting to move the cell pointer below 0 or above 29999 results in a bounds error,
  and will crash the program with exit code `2`
* Mismatched brackets will cause a crash with exit code `1`

## Syscalls

To make a syscall in brainfuck programs, this implementation introduces an
additional language character: `%`. When this character is encountered in
a program, the interpreter does the following:

1. The value at the current cell is considered the syscall code
2. The following cell is a flag for what type of argument,
   where 0 indicates a regular argument and 1 indicates a pointer
2. The following cell is considered the number of arguments
3. The following cells outline arguments in the following form:
   1. One cell indicates the cell length of the argument
   2. The following cells indicate the argument contents.
      Multi-cell arguments are interpreted as bytes
      in little-endian form.

For example, to call sys-exit, we can give the following code:

```
++++++[>++++++++++<-]>  Write code 60 (sys exit) in cell1

>                       move to cell2
+                       Write argument count of 1 to cell2

>                       move to cell3
(leave 0)               Write first arg type as normal (non-pointer)

>                       move to cell4
+                       Write first arg cell length of 1 to cell3

>                       move to cell5
+++                     Write exit code 3 in cell4

<<<<                    move back to cell1
%                       Call kernel
```

This will trigger a program exit with exit code 3:

```sh
$ ./bin/systemf examples/syscall_simple.bf
$ echo $?
3
```
