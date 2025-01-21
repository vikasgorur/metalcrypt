# DES description

These are the building blocks of DES, with corresponding references to the code.

We will focus on encrypting only 8 bytes (= `u64`) here and refer to it as `input`.

The steps of the encryption are:

1. Do the initial permutation of input.

    `initialPermutation(in: u64) u64`

2. Key reduction. This is just another permutation that drops every 8th bit
(8, 16, ..., 64, "parity bits") thus transforming the 64-bit key into a 56-bit
one. This is described by `DROP_PARITY_BITS_SPEC`.

3. Split the 64-bit permuted input into two halves, the left and the right:
`L: u32`, `R: u32`.

4. We now do 16 rounds of the encryption.

### Initial and final permutations

Implemented in `initialPermutation` and `finalPermutation`. These serve no
security purpose. Apparently they only exist to make it easier to load data
in hardware somehow.


### Test cases

The "example" test cases are derived from this illustrated
[guide](https://page.math.tu-berlin.de/~kant/teaching/hess/krypto-ws2006/des.htm)
that has the outputs after each step.
