purpose: Setup and tests for suspend/resume to RAM
\ See license at end of file

stand-init:  Suspend/resume
   " resume" find-drop-in  if
      suspend-base swap move
[ifdef] save-msrs
      msr-ranges                        ( adr )
[else]
      msr-init-range                    ( adr len )
      resume-data h# 34 + !             ( adr )
[then]
      >physical  resume-data h# 30 + !  ( )
[then]
   then
;

\ Useful for debugging suspend/resume problems
\ : sum-forth  ( -- )  0  here origin  do  i c@ +  loop  .  cr  ;

code ax-call  ( ax-value dst -- )  bx pop  ax pop  bx call  c;

: lid-wakeup
   h#  400 h# c8 gpio!  \ Clear positive edge status bit
   h#  400 h# cc gpio!  \ Clear negative edge status bit
   h# 185c pl@  h# 4000.0000 or  h# 185c pl!
;

: sci-wakeup
   h#  800 h# c8 gpio!  \ Clear positive edge status bit
   h#  800 h# cc gpio!  \ Clear negative edge status bit
   h# 185c pl@  h# 8000.0000 or  h# 185c pl!
;

: s3
   \ Enable wakeup from power button, also clearing
   \ any status bits in the low half of the register.
   h# 1840 pl@  h# 100.0000 or  h# 1840 pl!

   h# ffff.ffff h# 1858 pl!  \ Clear PME status bits
   h#      ffff h# c8 gpio!  \ Clear positive edge status bits
   h#      ffff h# cc gpio!  \ Clear negative edge status bits

\  sum-forth
[ifdef] virtual-mode
   [ also dev /mmu ]  pdir-va  h# f0000 ax-call  [ previous definitions ]
[else]
   sp@ 4 -  h# f0000 ax-call  \ sp@ 4 - is a dummy pdir-va location
[then]
\  sum-forth
;
dev screen
   : gp-wait-idle  ( -- )  begin  h# 44 gp@ h# 15 and  h# 10 =  until  ;
   : wait-vsync  ( -- )  begin  6c dc@ h# 2000.0000 and  until  ;
   : wait-!vsync  ( -- )  begin  6c dc@ h# 2000.0000 and 0=  until  ;
   : wait-frames  ( n -- )  0 ?do  wait-vsync  wait-!vsync wait-vsync  loop  ;
   : dot-line  ( -- n )  6c dc@  h# 3ff and  ;
   : wait-suspend  ( -- )
      disable-interrupts
      dot-line  d# 28 <  if  wait-vsync  then
      begin  dot-line  d# 25  d# 27  between  until
   ;
dend
: kb-suspend  ( -- )
   sci-wakeup
   begin
      begin  1 ms key?  while  key  dup [char] q = abort" Quit"  emit  repeat
\      " gp-wait-idle" screen-ih $call-method
\      2 " wait-frames" screen-ih $call-method
      noop
\      " wait-vsync" screen-ih $call-method
\      " wait-suspend" screen-ih $call-method
\      d# 550 us  \ 520 is sufficient
      s3
   again   
;
: s3-suspend
  " video-save" screen-ih $call-method  \ Freeze display
  s3
   " video-restore" screen-ih $call-method  \ Unfreeze display
   " /usb@f,5" open-dev  ?dup  if  " do-resume" 2 pick $call-method  close-dev  then
;
alias s s3-suspend

\ LICENSE_BEGIN
\ Copyright (c) 2007 FirmWorks
\ 
\ Permission is hereby granted, free of charge, to any person obtaining
\ a copy of this software and associated documentation files (the
\ "Software"), to deal in the Software without restriction, including
\ without limitation the rights to use, copy, modify, merge, publish,
\ distribute, sublicense, and/or sell copies of the Software, and to
\ permit persons to whom the Software is furnished to do so, subject to
\ the following conditions:
\ 
\ The above copyright notice and this permission notice shall be
\ included in all copies or substantial portions of the Software.
\ 
\ THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
\ EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
\ MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
\ NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
\ LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
\ OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
\ WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
\
\ LICENSE_END
