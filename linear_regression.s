section     .data
    X               DB      1, 2, 6, 0x64           ; end of list currently equal to 0x64 = 100

section     .text
global      _start

_start:
    PUSH    X
    CALL    get_mean
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
