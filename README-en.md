ninv — n-bit integer “inverse” in x86-64 NASM
This project implements a function that computes an n-bit integer y such that x·y ≤ 2ⁿ < x·(y+1) for a given n-bit integer x > 1, with numbers stored little-endian in 64-bit words; n is a multiple of 64 in [256000].

API specification

C signature: void ninv(uint64_t *y, uint64_t const *x, unsigned n);

Arguments:

x: pointer to an n-bit integer input (read-only buffer)

y: pointer to an n-bit output buffer

n: bit width, multiple of 64, 64 ≤ n ≤ 256000

Conventions:

Representation: natural binary, little-endian, 64-bit limbs (uint64_t)

ABI: System V AMD64

Contract: x must not be modified; y may contain arbitrary data on entry

Repository layout
ninv.asm — NASM implementation (to be submitted and used for linking)

ninv_example.cpp — example program using GMP to validate results

README.md — this document

Optional: LICENSE — recommended open-source license (e.g., MIT or 0BSD) depending on course policy

Requirements
OS: Linux x86-64 (as in the lab environment)

Toolchain:

NASM targeting elf64

g++ (C++20) and GMP for the example program

Linking example with non-executable stack is recommended

Build instructions
Assemble the NASM module:

nasm -f elf64 -w+all -w+error -o ninv.o ninv.asm

Build the example:

g++ -c -Wall -Wextra -std=c++20 -O2 -o ninv_example.o ninv_example.cpp

Link example with the assembly object:

g++ -z noexecstack -o ninv_example ninv_example.o ninv.o -lgmp

Running the example
Execute: ./ninv_example to generate and verify outputs satisfying x·y ≤ 2ⁿ < x·(y+1) across test instances.

Behavior and guarantees
No argument validation is performed (per assignment specification)

Input buffer x remains untouched; output buffer y is zeroed and fully written by the routine

Supports n up to 256000 bits (4000 limbs of 64 bits) with n divisible by 64

Algorithm overview
Goal: compute y = ⌊2ⁿ / x⌋ so that x·y ≤ 2ⁿ and, by definition, 2ⁿ < x·(y+1).

Bit-by-bit long division:

A remainder buffer is allocated on the stack; it starts at 1, and the loop iterates from bit n−1 down to 0

Each iteration left-shifts the remainder by 1 and compares it with x (first by length, then limb-by-limb from most significant)

If remainder ≥ x, the corresponding bit in y is set and x is subtracted from the remainder (multi-limb subtraction with explicit borrow propagation)

After subtraction, leading zero limbs are trimmed to maintain a tight remainder length

The effective length of x is determined by skipping leading zero limbs at the high end before the main loop

Implementation details (NASM, ABI)
Prologue/epilogue and callee-saved registers:

Saves and restores rbp, rbx, r12, r13, r14, r15 as required by System V AMD64 ABI

Stack pointer is 16-byte aligned; local remainder buffer is allocated on the stack

rep stosq is used to quickly zero the remainder buffer and the output buffer y

Argument mapping:

rdi → y, rsi → x, edx → n

Key working registers:

r11 = x pointer, r10 = y pointer, r8d = original n, esi = x length in limbs, eax = remainder length in limbs, r13 = remainder pointer

Remainder left-shift loop propagates carry via r9 across limbs

Comparison first on limb count, then lexicographically from most significant limb to least

Subtraction computes borrow explicitly without relying on CF/SBB to reduce long dependency chains in multi-limb loops

Memory safety:

y spans exactly n/64 limbs; remainder buffer is |x|+1 limbs, preventing overflow on left-shift extension 

x is never written; all addressing is little-endian with 8-byte strides

Complexity and performance
Time: O(n · W), where W = n/64 limbs; each bit iteration performs a remainder shift, a comparison, and optionally a multi-limb subtraction

Space: O(W) for the on-stack remainder; y is written in place after being zeroed

Micro-optimizations:

Single aligned stack allocation, rep stosq zeroing, explicit borrow computation to avoid flag hazards in long loops

Code style and formatting
NASM classic layout: labels in column 0, mnemonics aligned in a fixed column, no nested indentation

Commenting:

Block headers, register roles, loop intentions, and key instructions (bit set in y, borrow computation, length trimming) are documented inline

Assignment compliance: ABI-respecting, no writes to x, no assumptions about initial y, n in [256000] and divisible by 64

Testing
Reference check with GMP:

Compute y_ref = floor(2^n / x) and verify x*y ≤ 2^n < x*(y+1) for random and edge cases

Edge cases: n = 64 and n = 256000; x just above 1; x with only the top bit set; x near 2ⁿ−1

Memory safety checks in the example program can be done with sanitizers or valgrind to confirm no out-of-bounds accesses

Limitations and assumptions
No validation of n, buffer sizes, or x > 1 beyond the assignment contract

Targets System V AMD64 on Linux; other ABIs would require prologue/epilogue adaptation

License
Adding a LICENSE file is recommended; for coursework, keep the repository private until grading to respect course policies on code sharing

Authors and contact
The implementation is prepared for assembly labs; inline comments explain each section’s purpose and non-trivial steps

For questions, open an issue after grading and in accordance with course rules

