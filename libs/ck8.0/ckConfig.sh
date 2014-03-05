# ckConfig.sh --
# 
# This shell script (for sh) is generated automatically by Ck's
# configure script.  It will create shell variables for most of
# the configuration options discovered by the configure script.
# This script is intended to be included by the configure scripts
# for Ck extensions so that they don't have to figure this all
# out for themselves.
#
# The information in this file is specific to a single platform.
#
# $Id: ckConfig.sh.in,v 1.2 1999/12/12 09:22:09 chw Exp chw $

# Ck's version number.
CK_VERSION=''
CK_MAJOR_VERSION=''
CK_MINOR_VERSION=''

# -D flags for use with the C compiler.
CK_DEFS=' -DHAVE_UNISTD_H=1 -DHAVE_LIMITS_H=1 -DSTDC_HEADERS=1 -DRETSIGTYPE=void -DHAVE_SIGACTION=1 -DTK_FILE_READ_PTR=1 '

# The name of the Ck library (may be either a .a file or a shared library):
CK_LIB_FILE=libck.a

# Additional libraries to use when linking Ck.
CK_LIBS='-lcurses -ltermcap   -lieee -lm'

# Top-level directory in which Ck's files are installed.
CK_PREFIX='/usr'

# Top-level directory in which Tcl's platform-specific files (e.g.
# executables) are installed.
CK_EXEC_PREFIX='${prefix}'

# -I switch(es) where to find curses include files
CK_CURSESINCLUDES='-I/usr/include/ncursesw -DUSE_NCURSES'

# Linker switch(es) to use when linking with curses
CK_CURSESLIBSW='-lcurses -ltermcap'
