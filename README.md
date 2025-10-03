# Kalkulator Odwrotności Całkowitoliczbowej - Implementacja w Assembly

## 🚀 Przegląd

Wysokowydajnościowa implementacja w assembly x86-64 kalkulatora odwrotności całkowitoliczbowej używającego wzoru `y = floor(2^n / x)` dla arytmetyki dowolnej precyzji. Projekt demonstruje zaawansowane techniki programowania niskiego poziomu, ręczne zarządzanie pamięcią oraz algorytmy manipulacji bitów zoptymalizowane dla operacji na dużych liczbach.

## 🎯 Kluczowe Funkcjonalności

- **Dowolna Precyzja**: Obsługuje duże liczby całkowite przekraczające standardowe ograniczenia 64-bitowe
- **Zoptymalizowana Wydajność**: Ręcznie napisany kod assembly z minimalnym zużyciem pamięci
- **Dzielenie Bit po Bicie**: Niestandardowa implementacja algorytmu dla maksymalnej precyzji
- **Efektywność Pamięciowa**: Zarządzanie buforami na stosie z automatycznym czyszczeniem
- **Zgodność z ABI**: Przestrzega konwencji x86-64 System V ABI dla bezproblemowej integracji

## 🛠 Specyfikacje Techniczne

- **Architektura**: x86-64 (Intel/AMD 64-bit)
- **Asembler**: NASM (Netwide Assembler)
- **Język**: Czysty Assembly (składnia NASM)
- **Platforma**: Systemy Linux/Unix
- **Konwencja Wywołań**: System V AMD64 ABI

## 📋 Szczegóły Algorytmu

Implementacja wykorzystuje zaawansowany algorytm długiego dzielenia bit po bicie:
- Dynamiczne zarządzanie resztą z propagacją przeniesienia
- Operacje arytmetyczne na poziomie słów dla 64-bitowych bloków
- Ręczna obsługa pożyczki w operacjach odejmowania
- Automatyczna normalizacja precyzji

## 🔧 Użycie
```c
// Sygnatura funkcji
void ninv(uint64_t *result, uint64_t *divisor, unsigned int n);

// Parametry:
// result - Tablica wyjściowa dla ilorazu
// divisor - Tablica wejściowa zawierająca dzielnik
// n - Liczba bitów (potęga 2 w dzielnej: 2^n)
```
## 📈 Charakterystyki Wydajnościowe

- **Złożoność Czasowa**: O(n × w) gdzie n to liczba bitów, a w to liczba słów
- **Złożoność Pamięciowa**: O(w) dodatkowej przestrzeni na stosie dla buforów tymczasowych
- **Optymalizacje**: Ponowne użycie rejestrów, minimalne alokacje pamięci, efektywne operacje bitowe

## 🚀 Jak Zacząć

### Wymagania
- NASM (Netwide Assembler)
- System Linux/Unix z architekturą x86-64
- GCC lub kompatybilny kompilator C (do linkowania)

### KompilacjaKompilacja pliku assembly
nasm -f elf64 ninv.asm -o ninv.o

Linkowanie z kodem C
```bash
gcc -o program main.c ninv.o
```

### Przykład Użycia
```c
#include <stdint.h>
#include <stdio.h>

// Deklaracja funkcji assembly
extern void ninv(uint64_t *result, uint64_t *divisor, unsigned int n);

int main() {
uint64_t divisor[] = {5}; // Dzielnik: 5
uint64_t result = {0}; // Bufor na wynik
unsigned int n = 128; // 2^128 / 5

ninv(result, divisor, n);

printf("Wynik: %lu\n", result);
return 0;
}
```
## 📁 Struktura Projektu
```
ninv-assembly-x86-64/
├── ninv.asm # Główna implementacja w assembly
├── main.c # Przykład użycia
├── Makefile # Skrypt kompilacji
├── README.md # Ten plik
└── tests/ # Testy jednostkowe
└── test_ninv.c
```
## 📚 Dokumentacja

Kod zawiera szczegółowe komentarze w języku angielskim wyjaśniające:
- Każdy krok algorytmu
- Użycie rejestrów
- Konwencje wywołań
- Zarządzanie pamięcią
- Przypadki brzegowe

## 📄 Licencja

Ten projekt jest udostępniony na licencji MIT. Zobacz plik `LICENSE` dla szczegółów.

## 👨‍💻 Autor

**Wiktor Gerałtowski** - Student Informatyki, Uniwersytet Warszawski


---

*Ten projekt został stworzony w ramach studiów informatycznych jako demonstracja technik programowania w assembly oraz implementacji algorytmów matematycznych na poziomie sprzętowym.*
