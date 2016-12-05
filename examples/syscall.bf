Print to stdout using syscall write

======================Syscall code=========================
+            cell 0: 1      Syscall code for write
>
=====================Argument Count========================
+++          cell 1: 3      3 arguments
============Arg 0: File descriptor 0 for stdout============
>
(leave 0)    cell 2: 0      argv(0) is a regular argument
>
+            cell 3: 1      argv(0) cell length of 1
>
(leave 0)    cell 4: 0      file descriptor 0 for stdout
=====Arg 1: Pointer to byte buffer of string literal======
>
+            cell 5: 1      argv(1) type 1 = pointer
>
+++          cell 6: 3      argv(1) cell length of 3
>
             cell 7: 72     character 'H'
++++++++++
++++++++++
++++++++++
++++++++++
++++++++++
++++++++++
++++++++++++
>
             cell 8: 73    character 'I'
++++++++++
++++++++++
++++++++++
++++++++++
++++++++++
++++++++++
+++++++++++++
>
              cell 9: 10    character '\n'
++++++++++
============Arg 2: Byte size of buffer=======================
>
(leave 0)     cell 10:  0   argv(2) is a regular argument
>
+             cell 11: 1    argv(2) cell length of 1
>
+++           cell 12: 3    byte count of argument is 3
<<<<<<<<<<<<  Move to cell 0
%                           Execute
