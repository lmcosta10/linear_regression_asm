section     .data
    X       DB      1, 2, 6, 0x64           ; end of list currently equal to 0x64 = 100
    Y       DB      2, 4, 12, 0x64          ; end of list currently equal to 0x64 = 100

section     .text
global      _start

_start:
    PUSH    ebp
    MOV     ebp,    esp
    PUSH    X
    CALL    get_mean
    PUSH    eax                     ; X's mean
    PUSH    Y
    CALL    get_mean
    PUSH    eax                     ; Y's mean
    CALL    get_b1
    PUSH    eax                     ; b1
    POP     ebp
    MOV     eax,    1
    MOV     ebx,    0
    INT     80h

get_mean:
    ; Parameters
    ; X: list of numbers to get mean of
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

get_b1:
    ; Parameters
    ; Y mean
    ; Y
    ; X mean
    ; X
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

    CALL    get_b1_loop_num         ; sum gets stored in eax

    POP     edx
    POP     eax
    POP     ebp
    RET

get_b1_loop_num:
    ; TODO - check negative numbers

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
    JNE     get_b1_loop_num
    MOV     eax,    [ebp-4]         ; store sum in eax
    RET
