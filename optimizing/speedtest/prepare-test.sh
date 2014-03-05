#!/bin/bash

rm -f speedtest.c
cat speedtest.tmp|while read l
do
 ttt=`echo "$l"|grep "#add:"`;
 if [ -z "$ttt" ]; then
  echo "$l" >> speedtest.c
 else
 f=`echo "$l"|cut -d: -f2`
  cat "$f" >> speedtest.c
 fi
done