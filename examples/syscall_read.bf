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
