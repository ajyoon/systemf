# systemf

## a brainfuck interpreter supporting Linux syscalls

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
   where 0 indicates a regular argument, 1 indicates a buffer,
   and 2 indicates a cell number pointer.
3. The following cell is considered the number of arguments
4. The following cells outline arguments in the following form:
   1. One cell indicates the cell length of the argument
   2. The following cells indicate the argument contents.
      Multi-cell arguments are interpreted as bytes
      in big-endian form.
5. The syscall is made, and its return value is dumped to the current cell.

For example, to call sys-exit, we can give the following code:

```bf
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

We can use cell pointers to tell the kernel to write side effect data
directly into our program tape. For example, system `read()` takes in
its second argument a pointer to a buffer. To implement this in systemf
we can pass a cell pointer instead and flag it as such:

```bf
Read 5 bytes from stdin into cells 28 to 32 and print them out

  (0) >  Syscall code 0 for read()
  +++ >  Arg count 3

Arg 0~file descriptor  ================================

  (0) >  Arg type:    Normal
  +   >  Cell length: 1
  (0) >  Content:     File descriptor 0 for STDIN

Arg 1~write buffer  ===================================

  ++ >   Arg type:    Cell pointer
  + >    Cell length: 1
  +++++++
  +++++++
  +++++++
  +++++++ >  Content: Target cell 28

Arg 2~read byte count ==================================

  (0) > Arg type:    Normal
  + >   Cell length: 1
  +++++ Content:     read byte count 5

Return to cell 0 and execute
  <<<<<<<<<<
  %

5 input characters are taken and stored in cells 28 to 32
Let's prove it:

Go to cell 28
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>
Print those contents out!
  .>.>.>.>.>
```

And in execution...

```sh
systemf$ ./bin/systemf examples/syscall_read.bf
12345
12345systemf$
```
