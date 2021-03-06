purpose: Cache driver for 823 PowerPC chip
\ See license at end of file

headerless
d# 16 constant /dcache-block
d# 16 constant /icache-block

code (823-dcache-off)  ( -- )
   \ Don't do anything if the data cache is already off
   mfspr   t1,dc-csr
   andis.  t1,t1,h#8000
   0=  if
      next
   then

   \ Disable data translations before the flush loop: we'll run
   \ in real mode to make sure there are no mapping problems.
   mfmsr   t2
   rlwinm  t1,t2,0,28,26	\ Disable translation by clearing h#10 bit
   sync isync
   mtmsr   t1
   sync isync

   \ Unlock Dcache
   set     t1,h#0a00.0000
   sync
   mtspr   dc-csr,t1

   \ Flush Dcache before turning it off
   set     t1,h#400             \ Fill Dcache with known addresses
   begin
      addic.  t1,t1,-16
      lwz     r0,0(t1)
   = until

   set     t1,h#400             \ Size of dcache
   begin
      addic.  t1,t1,-16         \ Size of cache line
      dcbf    r0,t1             \ Flush Dcache line
   = until
   sync

   isync
   mtmsr   t2			\ Restore original MSR
   set     t1,h#0400.0000
   sync
   mtspr   dc-csr,t1		\ Disable Dcache
   isync
c;
headers
: 823-dcache-off  ( -- )   lock[ (823-dcache-off) ]unlock  ;
defer dcache-off	' 823-dcache-off to dcache-off
headerless

\ Warning: it is tempting to subtract one from the length, so that it refers
\ to the last byte in the range, and then decrement the index inside the loop.
\ However, that doesn't work because some PowerPC processors (e.g 604), when
\ in little-endian mode, do not appear to perform the following cache
\ operations properly when the effective address is unaligned.  This was
\ determined empirically.

code invalidate-823-i$-range  ( adr len -- )
   mr    t2,tos			\ len in t2
   lwz   t3,0(sp)		\ adr in t3
   lwz   tos,1cell(sp)
   addi  sp,sp,2cells

   \ Don't touch the cache if it's off
   mfspr  t1,ic-csr
   andis.  t1,t1,h#8000
   0<>  if
      \ Expand the range to include all affected cache lines
      add    t0,t3,t2		\ End of range
      addi   t0,t0,15		\ Round end address up ..
      rlwinm t0,t0,0,0,27	\ .. to cache line boundary
      rlwinm t3,t3,0,0,27	\ Round start address down
      subf. t2,t0,t3		\ Negative of length of expanded range

      ahead begin   
         icbi   t0,t2
         addic. t2,t2,16
      but then  0>= until
      sync
   then
c;
defer invalidate-i$-range   ' invalidate-823-i$-range to invalidate-i$-range

code flush-823-d$-range  ( adr len -- )
   mr    t2,tos			\ len in t2
   lwz   t3,0(sp)		\ adr in t3
   lwz   tos,1cell(sp)
   addi  sp,sp,2cells

   \ Don't touch the cache if it's off
   mfspr  t1,dc-csr
   andis. t1,t1,h#8000
   0<>  if
      \ Expand the range to include all affected cache lines
      add    t0,t3,t2		\ End of range
      addi   t0,t0,15		\ Round end address up ..
      rlwinm t0,t0,0,0,27	\ .. to cache line boundary
      rlwinm t3,t3,0,0,27	\ Round start address down
      subf. t2,t0,t3		\ Negative of length of expanded range

      ahead begin   
         dcbf   t0,t2
         addic. t2,t2,16
      but then  0>= until
      sync
   then
c;
headers
defer flush-d$-range	' flush-823-d$-range to flush-d$-range
headerless

code invalidate-823-d$-range  ( adr len -- )
   mr    t2,tos			\ len in t2
   lwz   t3,0(sp)		\ adr in t3
   lwz   tos,1cell(sp)
   addi  sp,sp,2cells

   \ Don't touch the cache if it's off
   mfspr  t1,dc-csr
   andis. t1,t1,h#8000
   0<>  if
      \ Expand the range to include all affected cache lines
      add    t0,t3,t2		\ End of range
      addi   t0,t0,15		\ Round end address up ..
      rlwinm t0,t0,0,0,27	\ .. to cache line boundary
      rlwinm t3,t3,0,0,27	\ Round start address down
      subf. t2,t0,t3		\ Negative of length of expanded range

      ahead begin   
         dcbi   t0,t2
         addic. t2,t2,16
      but then  0>= until
      sync
   then
c;
defer invalidate-d$-range   ' invalidate-823-d$-range to invalidate-d$-range

code store-823-d$-range  ( adr len -- )
   mr    t2,tos			\ len in t2
   lwz   t3,0(sp)		\ adr in t3
   lwz   tos,1cell(sp)
   addi  sp,sp,2cells

   \ Don't touch the cache if it's off
   mfspr  t1,dc-csr
   andis. t1,t1,h#8000
   0<>  if
      \ Expand the range to include all affected cache lines
      add    t0,t3,t2		\ End of range
      addi   t0,t0,15		\ Round end address up ..
      rlwinm t0,t0,0,0,27	\ .. to cache line boundary
      rlwinm t3,t3,0,0,27	\ Round start address down
      subf. t2,t0,t3		\ Negative of length of expanded range

      ahead begin   
         dcbst  t0,t2
         addic. t2,t2,16
      but then  0>= until
      sync
   then
c;
defer store-d$-range	' store-823-d$-range to store-d$-range

: stand-sync-cache  ( adr len -- adr )
   2dup store-d$-range  invalidate-i$-range
;

: invalidate-823-icache  ( -- )
   h# 0a00.0000 ic-csr!		\ Unlock all
   h# 0e00.0000 ic-csr!		\ Invalidate all
;
defer invalidate-icache  ' noop to invalidate-icache

headerless
: 823-dcache-on?  ( -- flag )  dc-csr@ h# 8000.0000 and  ;
: 823-icache-on?  ( -- flag )  ic-csr@ h# 8000.0000 and  ;
defer dcache-on?	' 823-dcache-on? to dcache-on?
defer icache-on?	' 823-icache-on? to icache-on?

headers
: 823-icache-on  ( -- )
   \ Bail out if it's already on, to avoid causing inconsistencies
   \ with L2 caches during invalidation.
   823-icache-on?  if  exit  then

   invalidate-823-icache	\ Unlock and invalidate Icache
   h# 0200.0000 ic-csr!		\ Enable Icache
   ['] invalidate-823-icache to invalidate-icache
;
defer icache-on		' 823-icache-on to icache-on

: 823-icache-off  ( -- )
   h# 0400.0000 ic-csr!		\ Disable Icache
   ['] noop to invalidate-icache
;
defer icache-off	' 823-icache-off to icache-off

headers
: 823-dcache-on  ( -- )
   \ Bail out if it's already on, to avoid causing inconsistencies
   \ with L2 caches during invalidation.
   dcache-on?  if  exit  then

   h# 0a00.0000 dc-csr!		\ Unlock all
   h# 0c00.0000 dc-csr!		\ Invalidate all
   h# 0200.0000 dc-csr!		\ Enable Dcache
;
defer dcache-on		' 823-dcache-on to dcache-on

\ Do this early so that the debugger will work as early as possible
: stand-init-io   ( -- )   stand-init-io
   ['] stand-sync-cache to sync-cache
;

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
