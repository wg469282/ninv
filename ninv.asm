; ============================================================================
; Funkcja: ninv
;
; Oblicza odwrotność całkowitoliczbową y = floor(2^n / x) dla dużych liczb.
;
; Argumenty :
;   rdi: uint64_t *Y   - wskaźnik do tablicy na wynik (iloraz)
;   rsi: uint64_t *X   - wskaźnik do tablicy z dzielnikiem
;   edx: unsigned n    - liczba bitów (potęga dwójki w dzielnej)
;
; Autor: wg469282 (oryginał), udokumentowano przez AI
; Wersja: 1.2 - Wersja z wyczerpującą dokumentacją
; ============================================================================

default rel
global ninv: function

SECTION .text align=16 exec

ninv:
        ; --------------------------------------------------------------------
        ; Prolog funkcji: zachowanie stanu funkcji wołającej
        ; --------------------------------------------------------------------
        push    rbp                             ; Zapisz stary wskaźnik bazowy ramki stosu
        mov     rbp, rsp                        ; Ustaw nowy wskaźnik ramki stosu dla tej funkcji
        push    r15                             ; Zapisz rejestr callee-saved r15
        push    r14                             ; Zapisz rejestr callee-saved r14
        push    r13                             ; Zapisz rejestr callee-saved r13
        push    r12                             ; Zapisz rejestr callee-saved r12
        push    rbx                             ; Zapisz rejestr callee-saved rbx

        ; --------------------------------------------------------------------
        ; Inicjalizacja: przygotowanie rejestrów i parametrów
        ; --------------------------------------------------------------------
        mov     r11, rsi                        ; r11 przechowuje wskaźnik na dzielnik (X)
        mov     r10, rdi                        ; r10 przechowuje wskaźnik na wynik (Y)
        mov     r8d, edx                        ; r8d przechowuje oryginalną wartość n (liczbę bitów)
        shr     edx, 6                          ; edx = n / 64, obliczenie długości X w słowach 64-bitowych
        mov     esi, edx                        ; esi przechowuje tę długość (oznaczoną jako 'w')

        ; --------------------------------------------------------------------
        ; Alokacja i zerowanie buforów roboczych na stosie
        ; --------------------------------------------------------------------
        lea     rcx, [rsi+1]                    ; Oblicz rozmiar bufora na resztę: w+1 słów
        mov     rbx, rcx                        ; Zachowaj ten rozmiar w rbx do użycia przez `rep stosq`
        shl     rcx, 3                          ; Przelicz rozmiar bufora z słów na bajty (rozmiar * 8)
        
        sub     rsp, rcx                        ; Zarezerwuj pamięć na bufor reszty na stosie
        and     rsp, -16                        ; Wyrównaj wskaźnik stosu do granicy 16 bajtów (wymóg ABI)
        mov     r13, rsp                        ; r13 będzie stałym wskaźnikiem na bufor reszty

        xor     eax, eax                        ; Wyzeruj rejestr EAX (wartość do zapisu: 0)
        mov     rdi, r13                        ; Ustaw RDI na adres docelowy (bufor reszty)
        mov     rcx, rbx                        ; Ustaw licznik słów do wyzerowania
        rep     stosq                           ; Wypełnij cały bufor reszty zerami (odpowiednik memset)

        mov     rdi, r10                        ; Ustaw RDI na adres docelowy (bufor wyniku)
        mov     ecx, esi                        ; Ustaw licznik słów (długość 'w')
        rep     stosq                           ; Wypełnij cały bufor wyniku zerami

; ----------------------------------------------------------------------------
; Algorytm dzielenia "bit po bicie" 
; ----------------------------------------------------------------------------

find_x_length:
        ; Określenie rzeczywistej długości dzielnika X (pominięcie wiodących zer)
        test    esi, esi                        ; Sprawdź, czy długość 'w' (esi) jest zerowa
        je      cleanup_and_return              ; Jeśli tak, zakończ (dzielenie przez zero lub puste dane)
        lea     rcx, [rsi-1]                    ; Oblicz indeks ostatniego słowa (w - 1)
        cmp     qword [r11+rcx*8], 0            ; Porównaj ostatnie słowo X z zerem
        jnz     init_remainder                  ; Jeśli niezerowe, to jest to najstarsze słowo, przejdź dalej
        dec     esi                             ; Jeśli zerowe, zmniejsz efektywną długość 'w'
        jmp     find_x_length                   ; I sprawdź kolejne słowo

init_remainder:
        ; Inicjalizacja reszty (R) na 1 przed rozpoczęciem pętli głównej
        mov     ecx, r8d                        ; Przywróć oryginalną wartość n do ECX
        dec     ecx                             ; Główny licznik pętli będzie iterował od n-1 do 0
        mov     eax, 1                          ; Ustaw długość reszty w słowach na 1
        mov     qword [r13], 1                  ; Ustaw wartość reszty R = 1 (jako pojedyncze słowo)
        mov     r12d, 1                         ; Załaduj stałą '1' do r12d, będzie używana do ustawiania bitów

main_division_loop:
        test    ecx, ecx                        ; Sprawdź, czy licznik bitów (n-1) spadł poniżej zera
        js      cleanup_and_return              ; Jeśli tak, zakończ algorytm

        ; Przesunięcie reszty R w lewo o 1 bit (R = R * 2)
        xor     edi, edi                        ; Zeruj indeks słowa (i=0) w pętli przesunięcia
        xor     r9, r9                          ; Zeruj rejestr r9, będzie przechowywał bit przeniesienia (carry)
shift_loop:
        cmp     edi, eax                        ; Sprawdź, czy przetworzono wszystkie słowa reszty
        jnc     check_carry_extend              ; Jeśli tak, wyjdź z pętli przesunięcia
        
        mov     r14, qword [r13+rdi*8]          ; Wczytaj i-te słowo reszty
        lea     r15, [r14+r14]                  ; Przesuń je w lewo o 1 
        shr     r14, 63                         ; Wyizoluj najwyższy bit (MSB), który staje się nowym przeniesieniem
        or      r9, r15                         ; Połącz przesunięte słowo z przeniesieniem z poprzedniej iteracji
        mov     qword [r13+rdi*8], r9           ; Zapisz nowe słowo reszty
        
        inc     edi                             ; Przejdź do następnego słowa
        mov     r9, r14                         ; Zapisz nowe przeniesienie do następnej iteracji
        jmp     shift_loop                      ; Kontynuuj pętlę przesunięcia

check_carry_extend:
        ; Jeśli wystąpiło przeniesienie z najbardziej znaczącego słowa, rozszerz resztę
        test    r9, r9                          ; Sprawdź, czy ostatnie przeniesienie było niezerowe
        jz      compare_remainder_x             ; Jeśli nie, przejdź do porównania
        cmp     eax, ebx                        ; Sprawdź, czy jest miejsce w buforze reszty
        jnc     compare_remainder_x             ; Jeśli bufor pełny, pomiń rozszerzenie
        mov     qword [r13+rax*8], 1            ; Dodaj nowe słowo (o wartości 1) na końcu reszty
        inc     eax                             ; Zwiększ długość reszty w słowach

compare_remainder_x:
        ; Porównanie reszty R z dzielnikiem X (if R >= X)
        cmp     esi, eax                        ; Porównaj długość X (w) z długością R
        jc      set_bit_and_subtract            ; Jeśli R jest dłuższe, to jest na pewno większe
        jne     next_bit                        ; Jeśli X jest dłuższe, to jest na pewno większe
        
        ; Jeśli długości są równe, porównaj słowo po słowie od najstarszego
        mov     edi, esi                        ; Ustaw licznik pętli porównującej na 'w'
word_compare_loop:
        dec     rdi                             ; Dekrementuj indeks (od w-1 do 0)
        mov     r8, qword [r13+rdi*8]           ; Wczytaj słowo reszty
        cmp     r8, qword [r11+rdi*8]           ; Porównaj ze słowem z X
        jb      next_bit                        ; Jeśli R_i < X_i, to cała liczba R < X, idź do nast. bitu
        ja      set_bit_and_subtract            ; Jeśli R_i > X_i, to cała liczba R > X, ustaw bit i odejmij
        test    rdi, rdi                        ; Sprawdź, czy to było ostatnie słowo (indeks 0)
        jnz     word_compare_loop               ; Jeśli nie, kontynuuj porównywanie kolejnych słów
        ; Jeśli wszystkie słowa są równe, to R >= X, więc również ustaw bit i odejmij

set_bit_and_subtract:
        ; Ustawienie odpowiedniego bitu w wyniku Y
        mov     edi, ecx                        ; Użyj licznika pętli (n-1..0) jako pozycji bitu
        mov     r8, r12                         ; r8 = 1 (wartość bitu do ustawienia)
        sar     edi, 6                          ; edi = indeks słowa w Y (pozycja / 64)
        shl     r8, cl                          ; r8 = maska bitowa (1 << (pozycja % 64))
        movsxd  rdi, edi                        ; Rozszerz 32-bitowy indeks do 64 bitów dla poprawnego adresowania
        or      qword [r10+rdi*8], r8           ; Ustaw bit: Y[indeks] |= maska
        
        ; Krok 3b: Odejmowanie (R = R - X) z ręczną obsługą pożyczki
        xor     r9, r9                          ; Wyzeruj rejestr r9, będzie przechowywał bit pożyczki (borrow)
        xor     r8d, r8d                        ; Wyzeruj indeks słowa (i=0) w pętli odejmowania
subtract_loop:
        cmp     r8d, eax                        ; Sprawdź, czy przetworzono wszystkie słowa reszty
        jnc     reduce_remainder_length         ; Jeśli tak, wyjdź z pętli odejmowania
        
        xor     edi, edi                        ; Domyślnie słowo z X, które odejmujemy, jest równe 0
        cmp     r8d, esi                        ; Sprawdź, czy indeks 'i' jest w zakresie długości X
        jnc     get_x_word_zero                 ; Jeśli nie, użyj domyślnego zera (X jest krótsze niż R)
        mov     rdi, qword [r11+r8*8]           ; Jeśli tak, wczytaj i-te słowo z X
get_x_word_zero:
        mov     r14, qword [r13+r8*8]           ; Wczytaj starą wartość i-tego słowa reszty
        mov     r15, r14                        ; Skopiuj ją do rejestru roboczego
        sub     r15, r9                         ; Odejmij pożyczkę z poprzedniej iteracji
        sub     r15, rdi                        ; Odejmij słowo z X
        mov     qword [r13+r8*8], r15           ; Zapisz wynik w reszcie

        ; Ręczne obliczanie nowej pożyczki
        add     rdi, r9                         ; rdi = X[i] + pożyczka_wejściowa
        jc      new_borrow_found                ; Jeśli (X[i] + borrow_in) > MAX_UINT, to potrzebna jest pożyczka
        cmp     r14, rdi                        ; Porównaj oryginalną resztę R[i] z (X[i] + borrow_in)
        jc      new_borrow_found                ; Jeśli R[i] była mniejsza, to potrzebna jest pożyczka
        xor     r9, r9                          ; W przeciwnym razie, nowa pożyczka = 0
        jmp     no_new_borrow
new_borrow_found:
        mov     r9, 1                           ; Ustaw nową pożyczkę na 1
no_new_borrow:
        inc     r8d                             ; Przejdź do następnego słowa
        jmp     subtract_loop                   ; Kontynuuj pętlę odejmowania

reduce_remainder_length:
        ; Normalizacja reszty R: usunięcie wiodących zer po odejmowaniu
reduce_loop:
        cmp     eax, 1                          ; Sprawdź, czy długość reszty jest większa niż 1
        jle     next_bit                        ; Jeśli nie, zakończ (zawsze zostaje co najmniej 1 słowo)
        lea     rdi, [rax-1]                    ; Oblicz indeks ostatniego słowa reszty
        cmp     qword [r13+rdi*8], 0            ; Sprawdź, czy to słowo jest zerem
        jnz     next_bit                        ; Jeśli nie jest, zakończ redukcję
        dec     eax                             ; Jeśli jest zerem, zmniejsz długość reszty
        jmp     reduce_loop                     ; I sprawdź kolejne słowo

next_bit:
        ; Przejście do następnej iteracji (następnego bitu)
        dec     ecx                             ; Zmniejsz główny licznik bitów
        jmp     main_division_loop              ; Wróć na początek pętli

; ----------------------------------------------------------------------------
; Epilog funkcji: przywrócenie stanu i powrót
; ----------------------------------------------------------------------------
cleanup_and_return:
        lea     rsp, [rbp-40]                   ; Zwolnij pamięć alokowaną na stosie 
        pop     rbx                             ; Odtwórz rejestr callee-saved rbx
        pop     r12                             ; Odtwórz rejestr callee-saved r12
        pop     r13                             ; Odtwórz rejestr callee-saved r13
        pop     r14                             ; Odtwórz rejestr callee-saved r14
        pop     r15                             ; Odtwórz rejestr callee-saved r15
        pop     rbp                             ; Odtwórz stary wskaźnik ramki stosu
        ret                                     ; Powrót z funkcji
