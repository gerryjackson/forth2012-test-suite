\ == Memory Walk tools ==

: @++ ( a-addr -- a-addr+4 a-addr@ )
    DUP CELL+ SWAP @ ;

: !++ ( x a-addr -- a-addr+4 )
    TUCK ! CELL+ ;

\ == Random Numbers ==
\ Based on 'Xorshift' PRNG wikipage
\ reporting on results by George Marsaglia
\ https://en.wikipedia.org/wiki/Xorshift
\ Note: THIS IS NOT CRYPTOGRAPHIC QUALITY

: PRNG
    CREATE ( "name" -- )
        4 CELLS ALLOT
    DOES> ( -- prng )
;

: PRNG-ERROR-CODE ( prng -- errcode | 0 )
    0 4 0 DO          \ prng acc
        >R @++ R> OR  \ prng acc'
    LOOP              \ prng xORyORzORw
    NIP 0= ;          \ xORyORzORw=0

: PRNG-COPY ( src-prng dst-prng -- )
    4 CELLS MOVE ;

: PRNG-SET-SEED ( prng w z y x -- )
    4 PICK                 \ prng w z y x prng
    4 0 DO !++ LOOP DROP   \ prng
    DUP PRNG-ERROR-CODE IF \ prng
        1 OVER +!          \ prng
    THEN                   \ prng
    DROP ;                 \

1 CELLS 4 = [IF]
    : PRNG-RND ( prng -- rnd )
        DUP @                            \ prng x
        DUP 11 LSHIFT XOR                \ prng t=x^(x<<11)
        DUP 8 RSHIFT XOR                 \ prng t'=t^(t>>8)
        OVER DUP CELL+ SWAP 3 CELLS MOVE \ prng t'
        OVER 3 CELLS + @                 \ prng t' w
        DUP 19 RSHIFT XOR                \ prng t' w'=w^(w>>19)
        XOR                              \ prng rnd=w'^t'
        TUCK SWAP 3 CELLS + ! ;          \ rnd
[ELSE]
1 CELLS 2 = [IF]
    .( === NOT TESTED === )
    \ From http://b2d-f9r.blogspot.co.uk/2010/08/16-bit-xorshift-rng-now-with-more.html
    : PRNG-RND ( prng -- rnd )
        DUP @                        \ prng x
        DUP 5 LSHIFT XOR             \ prng t=x^(x<<5)
        DUP 3 RSHIFT XOR             \ prng t'=t^(t>>3)
        OVER DUP CELL+ @ TUCK SWAP ! \ prng t' y
        DUP 1 RSHIFT XOR             \ prng t' y'=y^(y>>1)
        XOR                          \ prng rnd=y'^t'
        TUCK SWAP CELL+ ! ;          \ rnd
[ELSE]
.( You need to add a Psuedo Random Number Generator for your cell size )
[THEN] [THEN]

: PRNG-RANDOM ( lower upper prng -- rnd )
    >R OVER - R> PRNG-RND UM* NIP + ;
    \ T{ lower upper 2DUP 2>R prng PRNG-RANDOM 2R> WITHIN -> TRUE }T
