section     .data
    ; X and Y: model's X and Y.
    ; they end in 0x64 = 100 because it's what the code
    ; (currently) looks for when checking the end of the array.
    ; **Current limitation**: X mean and other intermediary results
    ; must be integers.
    X           DB      2, 5, 8, 0x64           
    Y           DB      12, 30, 48, 0x64

    ; pathname: file in which the results will get printed
    pathname    DB      "./result.txt", 0       ; linux paths must end with a null byte (0)

    ; p1 and p2: strings for printing the results.
    ; p1_len and p2_len: their lengths.
    ; Obs.: p1_len and p2_len must be right below p1 and p2
    ; respectively, since they use "$" (current position)
    p1          DB      "Y = "
    p1_len      EQU     $ - p1
    p2          DB      "X"
    p2_len      EQU     $ - p2

section     .bss
    ; section for uninitialized data
    
    ; fd_out: file descriptor. Used for result file later.
    fd_out      RESD    1

    ; buffer: for ASCII number conversion.
    buffer      RESB    10

section     .text
global      _start

_start:
    ; function prologue
    ; save the memory pointer of the previous function onto the stack
    PUSH    ebp
    MOV     ebp, esp

    ; calculate
    PUSH    X
    CALL    get_mean
    PUSH    eax                     ; X's mean
    PUSH    Y
    CALL    get_mean
    PUSH    eax                     ; Y's mean

    CALL    get_b1_num              ; get b1 numerator
    PUSH    eax                     ; b1 num
    CALL    get_b1_den              ; get b1 denominator
    MOV     ebx, eax                ; b1 den
    ; get actual b1
    POP     eax                     ; eax back to numerator
    MOV     edx, 0                  ; 0 at edx for division
    DIV     ebx
    MOV     [ebp-20], eax           ; b1 at [ebp - 20]

    ; write results
    ; create/open result.txt
    MOV     eax, 5                  ; sys_open
    ; obs.: for executing a sys call, eax must contain the sys call number before the INT 80h
    MOV     ebx, pathname
    MOV     ecx, 0101o              ; O_WRONLY | O_CREAT flags (octal)
    MOV     edx, 0666o              ; rw-rw-rw-
    INT     80h
    MOV     [fd_out], eax           ; eax keeps the file descriptor. move it to fd_out
    ; write "Y = "
    MOV     eax, 4                  ; sys_write
    MOV     ebx, [fd_out]
    MOV     ecx, p1
    MOV     edx, p1_len
    INT     80h
    ; write b1 value
    MOV     eax, [ebp-20]
    CALL    write_number
    ; write "X"
    MOV     eax, 4
    MOV     ebx, [fd_out]
    MOV     ecx, p2
    MOV     edx, p2_len
    INT     80h
    ; sys_close
    MOV     eax, 6
    MOV     ebx, [fd_out]
    INT     80h

    POP     ebp
    MOV     eax,    1
    MOV     ebx,    0
    INT     80h

write_number:
    ; eax must contain the integer to print

    PUSH    ebp
    MOV     ebp, esp

    PUSH    esi
    PUSH    edi

    MOV     edi, buffer + 9         ; start filling buffer from the end
    MOV     ecx, 10                 ; base 10 division

.convert_loop:
    MOV     edx, 0                  ; clear edx for division
    DIV     ecx                     ; eax / 10. remainder in edx
    ADD     dl, '0'                 ; convert remainder digit to ASCII
    DEC     edi                     ; move buffer pointer backward
    MOV     [edi], dl               ; store ASCII character
    TEST    eax, eax                ; loop until quotient is 0
    JNZ     .convert_loop

    ; calculate exact string length
    MOV     edx, buffer + 9
    SUB     edx, edi                ; length = end_ptr - current_ptr

    ; issue sys_write
    MOV     eax, 4                  ; sys_write
    MOV     ebx, [fd_out]           ; target file descriptor
    MOV     ecx, edi                ; address of converted text string
    INT     80h

    POP     edi
    POP     esi
    POP     ebp
    RET

get_mean:
    PUSH    ebp
    MOV     ebp,    esp

    MOV     eax,    0x0             ; sum
    MOV     ebx,    [ebp+8]         ; list addr
    MOV     ebx,    [ebx]           ; current list
    MOV     ecx,    0x0
    MOV     edx,    0x0             ; counter (will be 1 greater than actual value)
    CALL    get_mean_loop
    POP     ebp
    SUB     edx,    0x1
    MOV     ecx,    edx             ; move counter to ecx for division
    MOV     edx,    0x0             ; zero edx for division
    DIV     ecx
    RET

get_mean_loop:
    ADD     eax,    ecx             ; sum
    INC     edx
    MOV     ecx,    0b11111111      ; get the current list's last 2 bytes (first number)
    AND     ecx,    ebx             ; current number
    SHR     ebx,    8
    CMP     ecx,    0x64            ; check if end of list
    JNE     get_mean_loop
    RET

get_b1_num:
    PUSH    ebp
    MOV     ebp,    esp

    MOV     eax,    0x0             ; sum will be stored in [ebp-4]
    PUSH    eax

    ; Get current X list's last 2 bytes (first number) and store in eax
    MOV     ebx,    0b11111111
    MOV     eax,    [ebp+20]
    MOV     eax,    [eax]
    AND     eax,    ebx             ; current X number
    
    ; Get current Y list's last 2 bytes (first number) and store in ecx
    MOV     ecx,    0b11111111
    MOV     edx,    [ebp+12]
    MOV     edx,    [edx]
    AND     ecx,    edx             ; current Y number

    MOV     edx,    0x0
    PUSH    edx                     ; counter, times 8 (will be 8 greater than actual value in the end)

    CALL    get_b1_num_loop         ; sum gets stored in eax

    POP     edx
    POP     eax
    POP     ebp
    RET

get_b1_num_loop:
    MOV     ebx,    [ebp+16]        ; X mean
    SUB     ebx,    eax             ; first term - (X_mean - X)
    PUSH    ebx                     ; [ebp-12]

    MOV     edx,    [ebp+8]         ; Y mean
    SUB     edx,    ecx             ; second term - (Y_mean - Y)

    MOV     eax,    [ebp-16]        ; first term
    MUL     edx

    MOV     ebx,    [ebp-4]         ; get current sum
    ADD     ebx,    eax             ; new sum
    MOV     [ebp-4],ebx

    POP     ebx
    
    ; Get current X list's last 2 bytes (first number) and store in eax
    MOV     eax,    [ebp+20]
    MOV     eax,    [eax]
    ; counter
    MOV     ecx,    [ebp-8]
    ADD     ecx,    0x8
    SHR     eax,    cl              ; only works with cl
    MOV     ebx,    0b11111111
    AND     eax,    ebx             ; current X number

    ; Get current Y list's last 2 bytes (first number) and store in ecx
    MOV     edx,    [ebp+12]
    MOV     edx,    [edx]
    ; counter
    MOV     ecx,    [ebp-8]
    ADD     ecx,    0x8
    MOV     [ebp-8],ecx             ; stored counter = counter + 8
    SHR     edx,    cl              ; only works with cl
    MOV     ecx,    0b11111111
    AND     ecx,    edx             ; current Y number

    CMP     eax,    0x64            ; check if end of list
    JNE     get_b1_num_loop
    MOV     eax,    [ebp-4]         ; store sum in eax
    RET

get_b1_den:
    PUSH    ebp
    MOV     ebp,    esp

    MOV     eax,    0x0             ; sum will be stored in [ebp-4]
    PUSH    eax

    ; Get current X list's last 2 bytes (first number) and store in ebx
    MOV     ecx,    0b11111111
    MOV     ebx,    [ebp+24]
    MOV     ebx,    [ebx]
    AND     ebx,    ecx             ; current X number

    MOV     edx,    0x0
    PUSH    edx                     ; counter, times 8 (will be 8 greater than actual value in the end)

    CALL    get_b1_den_loop         ; sum gets stored in eax

    POP     edx
    POP     eax
    POP     ebp
    RET

get_b1_den_loop:
    MOV     eax,    [ebp+20]        ; X mean
    SUB     eax,    ebx             ; first term - (X_mean - X)

    MUL     eax

    MOV     ebx,    [ebp-4]         ; get current sum
    ADD     ebx,    eax             ; new sum
    MOV     [ebp-4],ebx
    
    ; Get current X list's last 2 bytes (first number) and store in ebx
    MOV     ebx,    [ebp+24]
    MOV     ebx,    [ebx]
    ; counter
    MOV     ecx,    [ebp-8]
    ADD     ecx,    0x8
    MOV     [ebp-8],ecx             ; stored counter = counter + 8
    SHR     ebx,    cl              ; only works with cl
    MOV     ecx,    0b11111111
    AND     ebx,    ecx             ; current X number

    CMP     ebx,    0x64            ; check if end of list
    JNE     get_b1_den_loop
    MOV     eax,    [ebp-4]         ; store sum in eax
    RET
