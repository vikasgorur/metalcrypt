# DES description

These are the building blocks of DES, with corresponding references to the code.

We will focus on encrypting only 8 bytes (= `u64`) here and refer to it as `input`.

The steps of the encryption are:

1. Do the initial permutation of input.

    `initialPermutation(in: u64) u64`

2. Break the input into two halves of 32 bits each, call them `left` and `right`.

3. Apply the "Feistel (F) function" on left and right in 16 rounds.

4. The Feistel function consists of:

    `feistel(in: u64, key: u64) u64`

    a. 

    b. foo


### Initial and final permutations

Implemented in `initialPermutation` and `finalPermutation`. These serve no security purpose. Apparently they only exist to make it easier to load data in hardware somehow.