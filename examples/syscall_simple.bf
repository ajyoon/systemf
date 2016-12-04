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