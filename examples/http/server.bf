A slightly functional HTTP server implemented in systemf
=======================================================

socket() =======================================================================

  Create socket
  +++++++++++++++++++++++++++++++++++++++++ > code 41 = socket()
  +++ >  Arg count: 3

Arg 1: int domain
  (0) >  Normal
  +   >  Len 1
  ++  >  Content: 2 (AF_INET)

Arg 2: int type
  (0) >  Normal
  +   >  Len 1
  +   >  Content: 1 (SOCK_STREAM)

Arg 3: int protocol
  (0) >  Normal
  +   >  Len 1
  (0)    Content 0 (default protocol)

  Return to cell 0
  <<<<<<<<<<
  Execute
  %

  Cell 0 now contains the file descriptor for the socket

bind() socket =================================================================

  >>>>>>>>>> Move to cell 10
  +++++++++++++++++++++++++++++++++++++++++++++++++ > Code 49 = bind()
  +++ > Arg count: 3

Arg 1: int sockfd
  (0) > Arg type: Normal
  +     Arg len:  1
  Move socket file descriptor in cell 0 to cell 5
  <<<<<<<<<<<<<
  [>>>>>>>>>>>>>>+<<<<<<<<<<<<<<-] >>>>>>>>>>>>>> >

Arg 2: const struct sockaddr *addr
  We construct this address struct byte by byte for localhost:4000
  Begin in cell 15
  + >  Arg type: Buffer (struct)
  ++++++++++++++++ >  Arg length:

  sockaddr struct contents
  ++  > Address family
  (0) >
  +++++++++++++++ >
  ++++++++++++++++++++++++++++++++++++++++
  ++++++++++++++++++++++++++++++++++++++++
  ++++++++++++++++++++++++++++++++++++++++
  ++++++++++++++++++++++++++++++++++++++++ > 0x0f 0xa0 = port 4000
  (0) > Accept Any
  (0) >
  (0) >
  (0) >
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ++++++++++++++++ > 144
  +++++++ > 7
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ > 64
  (0) >
  (0) >
  (0) >
  (0) >
  (0) >

Arg 3: socklen_t addrlen
  Start at cell 33
  (0) > Arg type: Normal
  +   > Arg len: 1
  ++++++++++++++++ Arg content: 16 (address struct length)

Return to cell 10 and call
  <<<<<<<<<<<<<<<<<<<<<<<<<
  %

The current cell is 10
The socket file descriptor is in cell 14
The socket address struct is stored in cells 17 to 33 (16 cells long)
  and its argument settings are in cells 15 and 16
The socket address is 16 bytes long

===============================================================================
===============================================================================
MAIN SERVER LOOP ==============================================================
===============================================================================
===============================================================================

This is where the program main loop should begin

At the end of the program the memory should be restored to *exactly* the way
  it is at this point in execution and the program should loop infinitely back
  to this point

  Temporarily set cell 10 to 1 to enter loop
  +
  Enter loop
[
  [-]  Reset cell 10 to 0

listen() ======================================================================

Move to address 36
  >>>>>>>>>>>>>>>>>>>>>>>>>>
  ++++++++++++++++++++++++++++++++++++++++++++++++++ > Code 50 = listen()
  ++ > Arg count: 2

  Arg 1: int sockfd:
  (0) > Arg type:     Normal
  +   > Arg cell len: 1
  Move socket file descriptor for cell 14 to cell 40
  <<<<<<<<<<<<<<<<<<<<<<<<<<
[->>>>>>>>>>>>>>>>>>>>>>>>>>+<<<<<<<<<<<<<<<<<<<<<<<<<<]
  >>>>>>>>>>>>>>>>>>>>>>>>>> >

  Arg 2: int backlog:
  (0) > Arg type: Normal
  +   > Arg cell len: 1
  +++++++++ Arg contents: value 10
  <<<<<<<
  %

accept() ======================================================================

  Current cell is 36
  Socket file descriptor is in cell 40
  The socket address struct is stored in cells 17 to 33 (16 cells long)
  and its argument settings are in cells 15 and 16
  The socket address is 16 bytes long

  Because the signature of accept() is so similar to bind()
  we can reuse most of the relevant section of tape for this call:

  Move socket file descriptor back to cell 14

    Move to cell 40
    >>>>
    [<<<<<<<<<<<<<<<<<<<<<<<<<<+>>>>>>>>>>>>>>>>>>>>>>>>>>-]
     <<<<<<<<<<<<<<<<<<<<<<<<<<

  Cell position is now 14

  Move to cell 10
  <<<<
  +++++++++++++++++++++++++++++++++++++++++++  accept() = code 43

  Arg 1: int sockfd            :: Already present

  Arg 2: struct sockaddr *addr :: Already present

  Move to cell 33
  >>>>>>>>>>>>>>>>>>>>>>>

  Arg 3: socklen_t *addrlen
  ++ >                             Arg type: cell pointer
  (already 1 from earlier call)  > Arg len:  1
  (content cell already at 16 from earlier call)
  ++++++++++++++++++++ Content: Point to cell 36
                       (right after this cell)

  Return to cell 10
  <<<<<<<<<<<<<<<<<<<<<<<<<
  Call

  %

read() =====================================================================

  Opened connection socket file descriptor is in cell 10
  Initial connection socket file descriptor is in cell 14
  Current cell is 10

  Clean up previous leftover tape data and prep arena for read()

  Move connection socket file descriptor to cell 0
  [-<<<<<<<<<<+>>>>>>>>>>]

  Move original connection socket file descriptor in cell 14 to cell 44
  (for restoration at request handling end)
  >>>>
  [->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>+<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<]

  Zero cells 1 to 14
  [-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<

  Tape position is now 0; Socket file descriptor is in cell 0
  The recvfrom() arg "struct sockaddr *src_addr" is already in place
  from cells 15 to 32

  Move socket file descriptor from cell 0 to cell 4
  [->>>>+<<<<]

  syscall code goes in cell 0
  (0) > read() == 0
  +++ > Arg count: 3

  Arg 1: int fd
  (0) > Arg type: Number
  +   > Arg len:  1
  (File descriptor already in cell 4) >

  Arg 2: void *buf = cell pointer to cell 64: where received message is written
  ++ > Arg type: Cell pointer
  +  > Arg len : 1
  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ > Arg content: 64

  Arg 3: size_t count: number of bytes to receive = 0x05ff
  (0) > Arg type: Number
  ++   > Arg len:  1
  +++++ >  Arg Content: 0x05
  - >                              0xff

  Return to cell 0
  <<<<<<<<<<<<

  Call
  %

  Remove all but the first 32 bytes of the received message since we don't need them
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  [-] > (Mark zero at cell 97 for return place)
  [>] <
  [[-]<] <
  Return to cell 0
  [<] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

Request Header Parsing ========================================================

  To parse the request header we make several limitations and assumptions
  We assume all requests are well formed GET requests
  We assume the address component of the request is less than 28 characters long
  We assume the address contains no whitespace
  We treat the address as a file path relative to the current working directory

  To extract the address component we can assume that the address occupies the space
  between the sixth character (after the leading slash after "GET ") and the following
  whitespace character; For example in "GET /index(dot)html HTTP/1(dot)1\n"
  these restrictions will extract "index(dot)html"

  To perform this address extraction we inject a null terminator (0) at the
  first whitespace (32) after the leading address slash

  Move to cell 69 (start of address after leading slash)
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  Change the first cell from 69 that is a whitespace (ascii 32)
  to 0 (a null terminator for the file path string)

  Make value in cell 27 ahead nonzero to kick off loop
  >>>>>>>>>>>>>>>>>>>>>>>>>>>
  +
  [
    Null current cell
    [-]
    Move back to the cell in the buffer being looked at
    <<<<<<<<<<<<<<<<<<<<<<<<<<<
    Copy current value 27 characters ahead
    [->>>>>>>>>>>>>>>>>>>>>>>>>>>+>+<<<<<<<<<<<<<<<<<<<<<<<<<<<<]
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>
    [-<<<<<<<<<<<<<<<<<<<<<<<<<<<<+>>>>>>>>>>>>>>>>>>>>>>>>>>>>]
    Place comparison value in cell right ahead of copy
    ++++++++++++++++++++++++++++++++
    Set comparison_cell = (comparison_cell == cell_to_the_right)
    [-<->]+<[>-<[-]]>
    If the character was a whitespace the current cell == 1; else 0
    Invert result so that the loop breaks as soon as a whitespace is encountered
    -
  ]
  Once the first whitespace is encountered jump back to corresponding
  position in read buffer and zero that location
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<
  [-]

  The file pathname being requested is now stored in cells 69 to wherever
  the null terminator has been placed

  We can now move back to a known cell by moving back to cell 64
  <[<]>

  We are now ready to open the file


open() ========================================================================


  Current cell is 64
  Pathname argument content begins in cell 69

  We need to zero out cells 64 to 68 and everything after the pathname

  [-]>[-]>[-]>[-]>[-]>  Zero out cells 64 to 68

  Current cell is 69

  >   Move into pathname
  [>] Move to null terminator
  zero at most 27 cells to the right
  [-]>[-]>[-]>[-]>[-]>[-]>[-]>[-]>[-]>[-]>
  [-]>[-]>[-]>[-]>[-]>[-]>[-]>[-]>[-]>[-]>
  [-]>[-]>[-]>[-]>[-]>[-]>
  <<<<<<<<<<<<<<<<<<<<<<<<<<<

  [<]>  Move back to cell 69

  Next we need to know how many cells long the pathname is and we need to
  store it in cell 68

  We can do this by copying the entire pathname cells 128 and onward
  and destructively counting it from the end; placing the final count
  in cell 126:
  [
    Duplicate value first to i plus 27 and i plus 59
    [-
      >>>>>>>>>>>>>>>>>>>>>>>>>>>
      +
      >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
      +
      <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ]

    Move value at i plus 27 back to i
    >>>>>>>>>>>>>>>>>>>>>>>>>>>
    [-<<<<<<<<<<<<<<<<<<<<<<<<<<<+>>>>>>>>>>>>>>>>>>>>>>>>>>>]
    Return to place in original buffer
    <<<<<<<<<<<<<<<<<<<<<<<<<<<
    Move forward
    >
  ]

  Return to cell 69
  <[<]>

  Go to cell 128
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  Move to end of copied area and destructively count
  [>]<
  [
    Consume current cell
    [-]
    <
    Move to counting area two spaces left of pathname
    (leave an empty cell between them)
    [<]<
    Currently in cell 126
    Increment counter
    +
    Move back into path
    >>
    Move back to path end
    [>]<
  ]
  Move to cell 126: where the character count is now stored
  <
  Current cell: 126
  Move this value to cell 68
  [ -
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    +
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  ]
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  Increment the count by 1 to add an EOF 0 cell
  +

  Current cell is 68

  At this point filling out the rest of the syscall
  data is straightforward:

  <<<   Move to cell 65
  ++ >  open() == 2
  ++ >  Arg count: 2

  Arg 1: const char *pathname
  + > Arg type: pointer
  Both the arg cell count and contents are already in place
  so we can skip over them
  [>]
  Move over extra padding EOF (0)
  >

  Arg 2: int flags
  (0) >  Arg type: Normal
  +   >  Arg len:  1
  (0)    Arg content: 0 (no flags)

  Move back to cell 65
  <<<<[<]>

  Execute
  %

write() HTTP Response Header ==================================================

  Current cell is 65
  Socket file descriptor is in cell 4 (from recvmsg())

  Move to cell 48
  <<<<<<<<<<<<<<<<<
  + > sendfile() == code 1
  +++ > Arg count: 3

  Arg 1: int out_fd
  (0) > Arg type: Normal
  +   > Arg len:  1
  Arg contents are currently stored in cell 4; go fetch it
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  [
    ->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    +
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  ]
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  >

  Arg 2: const void *buf = cell pointer to 128
  ++ > Arg type: Cell pointer
  +  > Arg len:  1
  ++++++++++++++++
  ++++++++++++++++
  ++++++++++++++++
  ++++++++++++++++
  ++++++++++++++++
  ++++++++++++++++
  ++++++++++++++++
  ++++++++++++++++ > Arg content: 128

  Arg 3: size_t count = 17
  (0) > Arg type: Normal
  +   > Arg len:  1
  +++++++++++++++++

  Current cell is 58

  Move to cell 128 and write header stub
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  H  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ >
  T  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ >
  T  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ >
  P  ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ >
  /  +++++++++++++++++++++++++++++++++++++++++++++++ >
  1  +++++++++++++++++++++++++++++++++++++++++++++++++ >
  (dot) ++++++++++++++++++++++++++++++++++++++++++++++ >
  1  +++++++++++++++++++++++++++++++++++++++++++++++++ >
  (space) ++++++++++++++++++++++++++++++++ >
  2  ++++++++++++++++++++++++++++++++++++++++++++++++++ >
  0  ++++++++++++++++++++++++++++++++++++++++++++++++ >
  0  ++++++++++++++++++++++++++++++++++++++++++++++++ >
  (space) ++++++++++++++++++++++++++++++++ >
  O  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ >
  K  +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ >
  \n  ++++++++++ >
  \n  ++++++++++ >

  Current cell is 144

  Move to cell 48
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  Execute
  %

  Clean up written bytes
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  <[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]
  <[-]<[-]<[-]<[-]<[-]<[-]<[-]<
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  Return to cell 48

sendfile() ====================================================================

  Currently in cell 48
  Resource file descriptor is in cell 65
  Socket file descriptor is in cell 52 (from previous write())

  Zero out cells 48 to 62 except for 52
  [-]>[-]>[-]>[-]> (keep 52) >[-]>[-]>[-]>[-]>[-]> [-]>[-]>[-]>[-]>
  <<<<<<<<<<<<<<

  Currently in cell 48
  ++++++++++++++++++++++++++++++++++++++++ > sendfile() == code 40
  ++++ > Arg count: 4

  Arg 1: int out_fd
  (0) > Arg type: Normal
  +   > Arg len:  1
  Arg contents are currently stored in cell 4; go fetch it
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  [ -
    >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    +
    <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  ]
  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  >

  Arg 2: int in_fd
  (0) > Arg type: Normal
  +   > Arg len:  1
  Arg contents are currently stored in cell 65; go fetch it
  >>>>>>>>>>
  [ -
    <<<<<<<<<<
    +
    >>>>>>>>>>
  ]
  <<<<<<<<<<
  >

  Arg 3: off_t *offset
  (0) > Arg type: Normal
  +   > Arg len:  1
  (0) > Arg contents: NULL

  Arg 4: size_t count
  (0) > Arg type: Normal
  ++ > Arg len:  2 cells
  - > - > Arg contents:  0xfffe

  Move back to cell 48
  <<<<<<<<<<<<<<<

  Call
  %

close() =======================================================================

  Close the opened connection

  The current cell is 48
  The connection file descriptor is in cell 52

  We can call the close() from the same position we are already:

  Zero all cells 48 to 51
  [-]>[-]>[-]>[-]<<<

  +++ >  close():   3
  +   >  Arg count: 1

  Arg 1: int fd
  (0) > Arg type: 0
  +     Arg len:  1
  (Arg value is already filled in)
  <<<

  Call close()
  %

Clean up and prepare to loop back to listen() =================================

  >>>>>>>>>>>>>>>>>>[>]>>[-]<<<[[-]<]
  <<<
  [-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<
  [-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<[-]<

  Move value in cell 44 (original connection socket file descriptor) to cell 14

  Current cell position is 44

  Zero cell 14
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<[-]>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

  Move cell 44 to cell 14
  [-<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<+>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>]

  Current cell position is 44

  Reset cell 0 to value 0
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  [-]

  Reset cell 1 to value 3
  > [-]
  +++

  Reset cell 2 to 0
  > [-]

  Reset cell 3 to 1
  > [-] +

  Reset cell 4 to 2
  > [-] ++

  Reset cell 5 to 0
  > [-]

  Reset cell 6 to 1
  > [-] +

  Reset cell 7 to 1
  > [-] +

  Reset cell 8 to 0
  > [-]

  Reset cell 9 to 1
  > [-] +

  Reset cell 10 to 0
  > [-]

  Reset cell 11 to 3
  > [-] +++

  Reset cell 12 to 0
  > [-]

  Reset cell 13 to 1
  > [-] +

  Zero out cell 33
  >>>>>>>>>>>>>>>>>>>>
  [-]

  Reset cell 35 to value 16
  >>
  [-]
  ++++++++++++++++
  >

  Zero out remaining cells 36 to 43
  [-]>[-]>[-]>[-]>[-]>[-]>[-]>[-]

  Return to cell 10 for loopback
  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

  Increment to force loopback
  +
]
