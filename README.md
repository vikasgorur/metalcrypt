This repo is an attempt to write a program to brute-force crack the classic
Unix password hashing algorithm, `crypt(3)` on Apple Silicon.

**References**:

1. `man 3 crypt` - we can use this as a reference implementation on a Mac. We'll use the "traditional"
mode of a 8-character password (but only 7 bits in each character used), 12 bits of salt and count
set to 25.

2. The `crypt(3)` algorithm is DES. A good description is in Bruce Schneier, _Applied Cryptography_, 2nd edition, chapter 12.

3. _Data Encryption Standard_, FIPS 46-3, [PDF](https://csrc.nist.gov/files/pubs/fips/46-3/final/docs/fips46-3.pdf).

4. Wikipedia: [DES](https://en.wikipedia.org/wiki/Data_Encryption_Standard), [DES supplementary material](https://en.wikipedia.org/wiki/DES_supplementary_material).

5. Philip Leong, _"Unix Password Encryption Considered Insecure"_ (1991) [PDF](docs/UNIX_Password_Encryption_Considered_Insecure.pdf) - describes both a hardware and software implementation, useful as a historical curiosity.

6. Claude Shannon, _A Mathematical Theory of Cryptography_ (1945) [link](https://www.iacr.org/museum/shannon45.html) - Historical interest. This paper introduces the concepts of "confusion" and "diffusion" essential to designing a good encryption function.