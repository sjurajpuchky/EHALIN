purpose: SCSI disk package implementing a "block" device-type interface.
\ See license at end of file

hex

" block" device-type
" disk"  encode-string  " compatible" property
" usbdisk" " iconname" string-property

fload ${BP}/dev/usb2/device/storage/scsicom.fth	\ Utility routines for SCSI commands

hex

\ 0 means no timeout
: set-timeout  ( msecs -- )  " set-timeout" $call-parent  ;

0 instance value offset-low     \ Offset to start of partition
0 instance value offset-high

external
0 instance value label-package
true value report-failure
headers

\ Sets offset-low and offset-high, reflecting the starting location of the
\ partition specified by the "my-args" string.

: init-label-package  ( -- okay? )
   0 to offset-high  0 to offset-low
   my-args  " disk-label"  $open-package to label-package
   label-package dup  if
      0 0  " offset" label-package $call-method to offset-high to offset-low
   else
      report-failure  if
         ." Can't open disk label package"  cr
      then
   then
;

\ Checks to see if a device is ready

: unit-ready?  ( -- ready? )
   " "(00 00 00 00 00 00)" drop  no-data-command  0=
;

\ Ensures that the disk is spinning, but doesn't wait forever

create sstart-cmd  h# 1b c, 0 c, 0 c, 0 c, 1 c, 0 c,

: timed-spin  ( -- error? )
   0 0 true  sstart-cmd 6  -1 retry-command?  nip  ?dup  if  ( error-code )
      \ true on top of the stack indicates a hardware error.
      \ We don't treat "illegal request" as an error because some drives
      \ don't support the start command.  Everything else other than
      \ success is considered an error.
      5 <>                                       ( error? )
   else                                          ( )
      false                                      ( false )
   then                                          ( error? )

   0 set-timeout
;

create read-capacity-cmd h# 25 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 0 c, 

: get-capacity  ( -- false | block-size #blocks false true )
   8  read-capacity-cmd 0a  0  short-data-command  if  ( )
      false
   else                                        ( adr len )
      8 <>  if  drop false exit  then          ( adr )
      dup 4 + 4c@  swap 4c@  1+  false true
   then
;

[ifdef] notdef
\ This is a "read for nothing", discarding the result.  It's a
\ workaround for a problem with the "Silicon Motion SMI331" controller
\ as used in the "Transcend TS2GUSD-S3" USB / MicroSD reader.  That
\ device stalls "read capacity" commands until you do the first block
\ read. The first block read stalls too, but afterwards everything works. 
: nonce-read  ( -- )
   d# 512 dma-alloc  >r
   r@ d# 512 true  " "(28 00 00 00 00 00 00 00 01 00)"  ( data$ in? cmd$ )
   0  retry-command? 2drop
   r> d# 512 dma-free
;
[then]

: read-block-extent  ( -- true | block-size #blocks false )
   \ Try "read capacity" a few times.  Support for that command is
   \ mandatory, but some devices aren't ready for it immediately.
   d# 20  0  do
      get-capacity  if  unloop exit  then  ( )
      d# 200 ms
   loop

[ifdef] notdef
   \ At least one device stalls read-capacity until the first block read
   nonce-read

   \ Retry it a few more times
   d# 18  0  do
      get-capacity  if  unloop exit  then  ( )
      d# 200 ms
   loop
[then]

   \ If it fails, we just guess.  Some devices violate the spec and
   \ fail to implement read_capacity
   d# 512  h# ffffffff  false
;

external

[ifdef] report-geometry
create mode-sense-geometry    h# 1a c, 0 c, 4 c, 0 c, d# 36 c, 0 c,

\ The sector/track value reported below is an average, because modern SCSI
\ disks often have variable geometry - fewer sectors on the inner cylinders
\ and spare sectors and tracks located at various places on the disk.
\ If you multiply the sectors/track number obtained from the format info
\ mode sense code page by the heads and cylinders obtained from the geometry
\ page, the number of blocks thus calculated usually exceeds the number of
\ logical blocks reported in the mode sense block descriptor, often by a
\ factor of about 25%.

\ Return true for error, otherwise disk geometry and false
: geometry  ( -- true | sectors/track #heads #cylinders false )
   d# 36  mode-sense-geometry  6  2  ( len cmd$ #retries )
   short-data-command  if  true exit  then   ( adr len )
   d# 36 <>  if  drop true exit  then        ( adr )
   >r                                ( r: adr )
   r@ d# 17 + c@   r@ d# 14 + 3c@    ( heads cylinders )
   2dup *  r> d# 4 + 4c@             ( heads cylinders heads*cylinders #blocks )
   swap /  -rot                      ( sectors/track heads cylinders )
   false   
;
[then]

\ This method is called by the deblocker

0 value #blocks
0 value block-size

headers

\ Read or write "#blks" blocks starting at "block#" into memory at "addr"
\ Input? is true for reading or false for writing.
\ command is  8  for reading or  h# a  for writing
\ We use the 6-byte forms of the disk read and write commands where possible.

: 2c!  ( n addr -- )  >r lbsplit 2drop  r> +c!         c!  ;
: 4c!  ( n addr -- )  >r lbsplit        r> +c! +c! +c! c!  ;

: r/w-blocks  ( addr block# #blks input? command -- actual# )
   cmdbuf /cmdbuf erase
[ifdef] use-short-form
   2over  h# 100 u>  swap h# 20.0000 u>=  or  if  ( addr block# #blks dir cmd )
[then]
      \ Use 10-byte form
      h# 20 or  0 cb!  \ 28 (read) or 2a (write)  ( addr block# #blks dir )
      -rot swap                                   ( addr dir #blks block# )
      cmdbuf 2 + 4c!                              ( addr dir #blks )
      dup cmdbuf 7 + 2c!                          ( addr dir #blks )
      d# 10                                       ( addr dir #blks cmdlen )
[ifdef] use-short-form
   else                                           ( addr block# #blks dir cmd )
      \ Use 6-byte form
      0 cb!                                       ( addr block# #blks dir )
      -rot swap                                   ( addr dir #blks block# )
      cmdbuf 1+ 3c!                               ( addr dir #blks )
      dup 4 cb!                                   ( addr dir #blks )
      6                                           ( addr dir #blks cmdlen )
   then
[then]
   swap                                           ( addr dir cmdlen #blks )
   dup >r                                         ( addr input? cmdlen #blks )
   block-size *  -rot  cmdbuf swap  -1  ( data-adr,len in? cmd-adr,len #retries )
   retry-command?  nip  if                        ( r: #blks )
      r> drop 0
   else
      r>
   then    ( actual# )
;

external

\ These three methods are called by the deblocker.

: max-transfer  ( -- n )   parent-max-transfer  ;
: read-blocks   ( addr block# #blocks -- #read )   true  d# 8  r/w-blocks  ;
: write-blocks  ( addr block# #blocks -- #written )  false d# 10 r/w-blocks  ;

\ Methods used by external clients

0 value open-count

: open  ( -- flag )
   my-unit parent-set-address

   open-count  if
      d# 2000 set-timeout
   else

      \ Set timeout to 45 sec: some large (>1GB) drives take
      \ up to 30 secs to spin up.
      d# 45 d# 1000 *  set-timeout

      unit-ready?  0=  if  false  exit  then

      \ It might be a good idea to do an inquiry here to determine the
      \ device configuration, checking the result to see if the device
      \ really is a disk.

      \ Make sure the disk is spinning

      timed-spin  if  false exit  then

      read-block-extent  if  false exit  then  ( block-size #blocks )
      to #blocks  to block-size

      d# 2000 set-timeout
      init-deblocker  0=  if  false exit  then
   then

   init-label-package  0=  if
      open-count 0=  if
         deblocker close-package
      then
      false exit
   then

   open-count 1+ to open-count

   true
;

: close  ( -- )
   open-count dup  1- 0 max to open-count  ( old-open-count )
   label-package close-package             ( old-open-count )
   1 =  if
      deblocker close-package
   then
;

: seek  ( offset.low offset.high -- okay? )
   offset-low offset-high d+  " seek"   deblocker $call-method
;

: read  ( addr len -- actual-len )  " read"  deblocker $call-method  ;
: write ( addr len -- actual-len )  " write" deblocker $call-method  ;
: load  ( addr -- size )            " load"  label-package $call-method  ;

: size  ( -- d.size )  " size" label-package $call-method  ;
headers

\ LICENSE_BEGIN
\ Copyright (c) 2006 FirmWorks
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
