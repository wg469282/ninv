# Integer Inverse Calculator - Assembly Implementation

## 🚀 Overview

A high-performance x86-64 assembly implementation of an integer inverse calculator using the formula `y = floor(2^n / x)` for arbitrary-precision arithmetic. This project demonstrates advanced low-level programming techniques, manual memory management, and bit-manipulation algorithms optimized for large number operations.

## 🎯 Key Features

- **Arbitrary Precision**: Handles large integers that exceed standard 64-bit limitations.
- **Optimized Performance**: Hand-crafted assembly code with a minimal memory footprint.
- **Bit-by-Bit Division**: A custom algorithm implementation for maximum precision.
- **Memory Efficiency**: Stack-based buffer management with automatic cleanup.
- **ABI Compliant**: Adheres to the x86-64 System V ABI conventions for seamless integration.

## 🛠 Technical Specifications

- **Architecture**: x86-64 (Intel/AMD 64-bit)
- **Assembler**: NASM (Netwide Assembler)
- **Language**: Pure Assembly (NASM syntax)
- **Platform**: Linux/Unix systems
- **Calling Convention**: System V AMD64 ABI

## 📋 Algorithm Details

The implementation uses a sophisticated bit-by-bit long division algorithm:
- Dynamic remainder management with carry propagation.
- Word-level arithmetic operations for 64-bit chunks.
- Manual borrow handling in subtraction operations.
- Automatic precision normalization.

## 🔧 Usage

// Function signature
void ninv(uint64_t *result, uint64_t *divisor, unsigned int n);

// Parameters:
// result - Output array for the quotient
// divisor - Input array containing the divisor
// n - Number of bits (power of 2 in the dividend: 2^n

## 📈 Performance Characteristics

- **Time Complexity**: O(n × w) where n is the bit count and w is the word count.
- **Space Complexity**: O(w) of additional stack space for temporary buffers.
- **Optimizations**: Register reuse, minimal memory allocations, and efficient bit operations.

## 🚀 Getting Started

### Requirements
- NASM (Netwide Assembler)
- A Linux/Unix system with an x86-64 architecture
- GCC or a compatible C compiler (for linking)

### Compilation

#Compile the assembly file
nasm -f elf64 ninv.asm -o ninv.o

#Link with C code
gcc -o program main.c ninv.o


### Example Usage

#include <stdint.h>
#include <stdio.h>

// Declaration of the assembly function
extern void ninv(uint64_t *result, uint64_t *divisor, unsigned int n);

int main() {
uint64_t divisor[] = {5}; // Divisor: 5
uint64_t result = {0}; // Buffer for the result
unsigned int n = 128; // 2^128 / 5

ninv(result, divisor, n);

printf("Result: %lu\n", result);
return 0;
}

## 📁 Project Structure

ninv-assembly-x86-64/
├── ninv.asm # Main assembly implementation
├── main.c # Example usage
├── Makefile # Compilation script
├── README.md # This file
└── tests/ # Unit tests
└── test_ninv.c


## 📚 Documentation

The code includes detailed comments in English that explain:
- Each step of the algorithm
- Register usage
- Calling conventions
- Memory management
- Edge cases

## 📄 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## 👨‍💻 Author

**Wiktor Gerałtowski** - Computer Science Student, University of Warsaw

## 🏷️ Tags

`assembly` `x86-64` `nasm` `mathematics` `algorithms` `performance-optimization` `low-level-programming` `arbitrary-precision` `university-of-warsaw` `computer-science`

---

*This project was created as part of computer science studies to demonstrate  assembly programming techniques and the implementation of mathematical algorithms at the hardware level.*
