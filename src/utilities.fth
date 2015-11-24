( The ANS/Forth 2012 test suite is being modified so that the test programs  )
( for the optional word sets only use standard words from the Core word set. )
( This file, which is included *after* the Core test programs, contains      )
( various definitions for use by the optional word set test programs to      )
( remove any dependencies between word sets.                                 )

DECIMAL

( First a definition to see if a word is already defined. Note that          )
( [DEFINED] [IF] [ELSE] and [THEN] are in the optional Programming Tools     )
( word set.                                                                  )

VARIABLE (\?) 0 (\?) !     ( Word already defined flag )

( [?DEF]  followed by [?IF] cannot be used again until after [THEN] )
: [?DEF]  ( "name" -- )
   BL WORD FIND SWAP DROP 0= (\?) !
;

: [?UNDEF] [?DEF] (\?) @ -1 XOR (\?) ! ;

\ Equivalents of [IF] [ELSE] [THEN], these must not be nested
: [?IF]  ( f -- )  (\?) ! ; IMMEDIATE
: [?ELSE]  ( -- )  (\?) @ -1 XOR (\?) ! ; IMMEDIATE
: [?THEN]  ( -- )  0 (\?) ! ; IMMEDIATE

( A conditional comment and \ will be defined. Note that these definitions )
( are inadequate for use in Forth blocks. If needed in the blocks test     )
( program they will need to be modified here or redefined there )

( \? is a conditional comment )
: \?  ( "..." -- )  (\?) @ IF EXIT THEN SOURCE >IN ! DROP ; IMMEDIATE

( Ensure \ is defined so that it can be used from now on )
[?DEF] \  \? : \  SOURCE >IN ! DROP ; IMMEDIATE

[?DEF] TRUE  \? -1 CONSTANT TRUE
[?DEF] FALSE \?  0 CONSTANT FALSE
[?DEF] NIP   \?  : NIP SWAP DROP ;
[?DEF] TUCK  \?  : TUCK SWAP OVER ;

[?DEF] PARSE
\? : BUMP  ( caddr u n -- caddr+n u-n )
\?    TUCK - >R CHARS + R>
\? ;

\? : PARSE  ( ch "ccc<ch>" -- caddr u )
\?    >R SOURCE >IN @ BUMP
\?    OVER R> SWAP >R >R         ( -- start u1 ) ( R: -- start ch )
\?    BEGIN
\?       DUP
\?    WHILE
\?       OVER C@ R@ = 0=
\?    WHILE
\?       1 BUMP
\?    REPEAT
\?       1-                      ( end u2 )  \ delimiter found
\?    THEN
\?    SOURCE NIP SWAP - >IN !    ( -- end )
\?    R> DROP R>                 ( -- end start )
\?    TUCK - 1 CHARS /           ( -- start u )
\? ;

[?DEF] .(  \? : .(  [CHAR] ) PARSE TYPE ; IMMEDIATE

\ STR=  to compare (case sensitive) two strings to avoid use of COMPARE from
\ the String word set

: STR=  ( caddr1 u1 caddr2 u2 -- f )   \ f = TRUE if strings are equal
   ROT OVER = 0= IF DROP 2DROP FALSE EXIT THEN
   DUP 0= IF DROP 2DROP TRUE EXIT THEN 
   0 DO
        OVER C@ OVER C@ = 0= IF 2DROP FALSE UNLOOP EXIT THEN
        CHAR+ SWAP CHAR+
     LOOP 2DROP TRUE
;

\ Buffer for strings in interpretive mode since S" only valid in compilation
\ mode when File-Access word set is defined

64 CONSTANT SBUF-SIZE
CREATE SBUF  SBUF-SIZE CHARS ALLOT
CREATE SBUF2 SBUF-SIZE CHARS ALLOT

\ ($") saves a counted string at (caddr)
: ($")  ( caddr "ccc" -- caddr' u )
   [CHAR] " PARSE ROT 2DUP C!       ( -- ca2 u2 ca)
   CHAR+ SWAP 2DUP 2>R CHARS MOVE   ( -- )  ( R: -- ca' u2 )
   2R>
;

: $"   ( "ccc" -- caddr u )  SBUF  ($") ;
: $2"  ( "ccc" -- caddr u )  SBUF2 ($") ;
: $CLEAR  ( caddr -- ) SBUF-SIZE BL FILL ;
: CLEAR-SBUFS  ( -- )  SBUF $CLEAR SBUF2 $CLEAR ;

0 INVERT                 CONSTANT MAX-UINT   \ Don't rely on Core definitions
0 INVERT 1 RSHIFT        CONSTANT MAX-INT
0 INVERT 1 RSHIFT INVERT CONSTANT MIN-INT
0 INVERT 1 RSHIFT        CONSTANT MID-UINT
0 INVERT 1 RSHIFT INVERT CONSTANT MID-UINT+1

[?DEF] 2CONSTANT \? : 2CONSTANT  CREATE , , DOES> 2@ ;

BASE @ 2 BASE ! -1 0 <# #S #> SWAP DROP CONSTANT BITS/CELL BASE !


\ ------------------------------------------------------------------------------
\ Tests

: STR1  S" abcd" ;  : STR2  S" abcde" ;
: STR3  S" abCd" ;  : STR4  S" wbcd"  ;
: S"" S" " ;

T{ STR1 2DUP STR= -> TRUE }T
T{ STR2 2DUP STR= -> TRUE }T
T{ S""  2DUP STR= -> TRUE }T
T{ STR1 STR2 STR= -> FALSE }T
T{ STR1 STR3 STR= -> FALSE }T
T{ STR1 STR4 STR= -> FALSE }T

T{ CLEAR-SBUFS -> }T
T{ $" abcdefghijklm"  SBUF  COUNT STR= -> TRUE  }T
T{ $" nopqrstuvwxyz"  SBUF2 OVER  STR= -> FALSE }T
T{ $2" abcdefghijklm" SBUF  COUNT STR= -> FALSE }T
T{ $2" nopqrstuvwxyz" SBUF  COUNT STR= -> TRUE  }T
