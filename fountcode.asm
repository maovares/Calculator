; helper macro function num_scam
PUTC    MACRO   char
        PUSH    AX          
        MOV     AL, char
        MOV     AH, 0Eh
        INT     10h     
        POP     AX
ENDM

name "Calcularor"

ORG 100H
       
JMP main;

;messages to show
msg1 db "Inserte el primer operando:  $"
msg2 db "Inserte el segundo operando: $"
msg3 db "Digite el simbolo de la operacion(+,-,.,|):  $"  
msg4 db "El resultado es:  $"
msg5 db "Presione una tecla para terminar $"  
msg6 db "Esc -->Salir  Enter --> Continuar:  $"   
msg7 db "NO SE PUEDE TENER UN 0 EN UNA DIVISION  $"

;variables for operation
var1 DW ?;
var2 DW ?; 
operator DB ?;
result DW ?;

ten DW 10;used as multiplier/divider by SCAN_NUM & PRINT_NUM_SCAN



main: ;principal function 

;print the message  msg1
MOV DX, OFFSET msg1;
CALL PRINT_TEXT  



CALL SCAN_NUM
MOV var1,CX  ;save the fist value in the var1 variable

CALL SPACE  



;print the message  msg2
MOV DX, OFFSET msg2;
CALL PRINT_TEXT


CALL SCAN_NUM;
MOV var2,CX  ;save the fist value in the var1 variable 

CALL SPACE 


get_operator:

    CALL SPACE

    ;print the message  msg3
    MOV DX, OFFSET msg3;
    CALL PRINT_TEXT

    ;get operator sign
    MOV AH,01;
    INT 21h;
 
    CMP AL,'+'; compare the input sign with plus sign
    JE do_add; if the sign is the same, jump to "do_add" function
    
    CMP AL,'|'; compare the input sign with this sign "|"
    JE do_div; if the sign is the same, jump to "do_div" function
    
    CMP AL,'.'; compare the input sign with this sign "."
    JE do_mul;  if the sign is the same, jump to "do_mul" funtion
    
    CMP AL,'-'; compare the input sign with this sign "-"
    JE do_sub;  if the sign is the same, jump to "do_sub" funtion
    
JMP get_operator: ; if don't is any of this signs, quiestion back to the user   

do_add: ;function to add  
    MOV AX,var1;
    ADD AX, var2;
    JMP printRes;
do_mul: ;function to multiplay  

    
    MOV AX,var1  
    CMP var1,0
    JE printerror 
    CMP var2,0 
    JE printerror
    
      
    IMUL var2
    JMP printRes
do_div: ;funtion to divide
    MOV dx, 0  
    MOV AX,var1
    IDIV var2 
    JMP printRes
do_sub: ;funtion to take away 
    MOV AX,var1
    SUB AX, var2
    JMP printRes   

;print the result 
printRes:

CALL SPACE
     
PUSH AX ;the value of AX is input to the pile to protect
mov DX, offset msg4 ; print the message
CALL PRINT_TEXT 
POP AX ; take the value of the pile
CALL PRINT_NUM  ;print the result

    CALL SPACE              
    CALL SPACE
    MOV DX, OFFSET msg5  ;print the message 
    CALL PRINT_TEXT
    
    
    MOV ah, 1 ; wait for any key to exit the program
    INT 21h
RET; 

 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; these functions are copied from emu8086.inc ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; gets the multi-digit SIGNED number from the keyboard,
; and stores the result in CX register:
SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP

; this procedure prints number in AX,
; used with PRINT_NUM_UNS to print signed numbers:
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

        PUTC    '0'
        JMP     printed

not_zero:
        ; the check SIGN of AX,
        ; make absolute if it's negative:
        CMP     AX, 0
        JNS     positive
        NEG     AX

        PUTC    '-'

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP 



; this procedure prints out an unsigned
; number in AX (not just a single digit)
; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        ; flag to prevent printing zeros before number:
        MOV     CX, 1

        ; (result of "/ 10000" is always less or equal to 9).
        MOV     BX, 10000       ; 2710h - divider.

        ; AX is zero?
        CMP     AX, 0
        JZ      print_zero

begin_print:

        ; check divider (if zero go to end_print):
        CMP     BX,0
        JZ      end_print

        ; avoid printing zeros before number:
        CMP     CX, 0
        JE      calc
        ; if AX<BX then result of DIV will be zero:
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0   ; set flag.

        MOV     DX, 0
        DIV     BX      ; AX = DX:AX / BX   (DX=remainder).

        ; print last digit
        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h    ; convert to ASCII code.
        PUTC    AL


        MOV     AX, DX  ; get remainder from last div.

skip:
        ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX

        JMP     begin_print
        
print_zero:
        PUTC    '0'
        
end_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP 
;Custom Procs 


;this procedure prints what is in register DX
PRINT_TEXT PROC NEAR
    MOV AH,09h; 
    INT 21h; 
    RET    
PRINT_TEXT ENDP

;this procedure print a jump of line
SPACE PROC NEAR    
    PUTC 0Dh
    PUTC 0Ah 
    RET
SPACE ENDP   

printerror: 
MOV DX, OFFSET msg7;
CALL PRINT_TEXT 
JMP stop


stop:
        