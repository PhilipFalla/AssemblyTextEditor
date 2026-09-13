TITLE "PROYECTO 1 - EDITOR DE TEXTO"

.MODEL SMALL
.STACK 64

.DATA

; -------------------------------------------------
; VARIABLES DE LA PANTALLA DE EDICION
; -------------------------------------------------

; Posicion actual del cursor
CURSORX     DB 0
CURSORY     DB 2

; Mensaje temporal para identificar la pantalla
TITULOEDIT  DB 'EDITOR DE TEXTO$'


.CODE

MAIN PROC FAR

    ; Inicializar segmento de datos
    MOV AX, @DATA
    MOV DS, AX

    ; Limpiar pantalla y entrar en modo texto 80x25
    MOV AX, 0003H
    INT 10H

    ; -------------------------------------------------
    ; MOSTRAR TITULO
    ; -------------------------------------------------

    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 00H
    MOV DL, 32
    INT 10H

    LEA DX, TITULOEDIT
    MOV AH, 09H
    INT 21H

    ; Colocar cursor al inicio del area de escritura
    MOV CURSORX, 0
    MOV CURSORY, 2


; =================================================
; CICLO PRINCIPAL DEL EDITOR
; =================================================

CICLO_EDITOR:

    ; Colocar cursor en la posicion actual
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, CURSORY
    MOV DL, CURSORX
    INT 10H

    ; Esperar una tecla
    ; AL = codigo ASCII
    ; AH = scan code
    MOV AH, 00H
    INT 16H

    ; -------------------------------------------------
    ; DETECTAR FLECHAS
    ; -------------------------------------------------

    CMP AH, 48H
    JNE REVISAR_ABAJO
    JMP FLECHA_ARRIBA

REVISAR_ABAJO:

    CMP AH, 50H
    JNE REVISAR_IZQUIERDA
    JMP FLECHA_ABAJO

REVISAR_IZQUIERDA:

    CMP AH, 4BH
    JNE REVISAR_DERECHA
    JMP FLECHA_IZQUIERDA

REVISAR_DERECHA:

    CMP AH, 4DH
    JNE REVISAR_ESCAPE
    JMP FLECHA_DERECHA


REVISAR_ESCAPE:

    ; ESC - salida temporal
    CMP AL, 1BH
    JNE VALIDAR_NUMERO
    JMP FIN_PROGRAMA


; =================================================
; VALIDAR CARACTER INGRESADO
; =================================================

VALIDAR_NUMERO:

    ; Numeros 0-9
    CMP AL, '0'
    JB VALIDAR_MAYUS

    CMP AL, '9'
    JA VALIDAR_MAYUS

    JMP ESCRIBIR


VALIDAR_MAYUS:

    ; Letras A-Z
    CMP AL, 'A'
    JB VALIDAR_MINUS

    CMP AL, 'Z'
    JA VALIDAR_MINUS

    JMP ESCRIBIR


VALIDAR_MINUS:

    ; Letras a-z
    CMP AL, 'a'
    JB VALIDAR_COMA

    CMP AL, 'z'
    JA VALIDAR_COMA

    JMP ESCRIBIR


VALIDAR_COMA:

    CMP AL, ','
    JNE VALIDAR_PUNTO

    JMP ESCRIBIR


VALIDAR_PUNTO:

    CMP AL, '.'
    JNE VALIDAR_DOSPUNTOS

    JMP ESCRIBIR


VALIDAR_DOSPUNTOS:

    CMP AL, ':'
    JNE VALIDAR_DOSPUNTOS_DOSBOX

    JMP ESCRIBIR


VALIDAR_DOSPUNTOS_DOSBOX:

    ; En este DOSBox la tecla usada para :
    ; llega como >
    CMP AL, '>'
    JNE CARACTER_INVALIDO

    MOV AL, ':'
    JMP ESCRIBIR


CARACTER_INVALIDO:

    JMP CICLO_EDITOR


; =================================================
; ESCRIBIR CARACTER
; =================================================

ESCRIBIR:

    ; Mostrar caracter en pantalla
    MOV AH, 09H
    MOV BH, 00H
    MOV BL, 07H
    MOV CX, 1
    INT 10H

    ; Revisar si estamos al final del renglon
    CMP CURSORX, 79
    JNE ESCRIBIR_AVANZAR_X

    ; Estamos en columna 79
    CMP CURSORY, 24
    JNE ESCRIBIR_SIGUIENTE_LINEA

    ; Estamos en la ultima posicion disponible
    JMP CICLO_EDITOR


ESCRIBIR_AVANZAR_X:

    INC CURSORX
    JMP CICLO_EDITOR


ESCRIBIR_SIGUIENTE_LINEA:

    MOV CURSORX, 0
    INC CURSORY
    JMP CICLO_EDITOR


; =================================================
; FLECHA ARRIBA
; =================================================

FLECHA_ARRIBA:

    CMP CURSORY, 2
    JNE ARRIBA_MOVER

    ; Ya estamos en el limite
    JMP CICLO_EDITOR


ARRIBA_MOVER:

    DEC CURSORY
    JMP CICLO_EDITOR


; =================================================
; FLECHA ABAJO
; =================================================

FLECHA_ABAJO:

    CMP CURSORY, 24
    JNE ABAJO_MOVER

    ; Ya estamos en el limite
    JMP CICLO_EDITOR


ABAJO_MOVER:

    INC CURSORY
    JMP CICLO_EDITOR


; =================================================
; FLECHA IZQUIERDA
; =================================================

FLECHA_IZQUIERDA:

    CMP CURSORX, 0
    JE IZQUIERDA_INICIO_LINEA

    ; Movimiento normal
    DEC CURSORX
    JMP CICLO_EDITOR


IZQUIERDA_INICIO_LINEA:

    ; Estamos en columna 0
    ; Revisar si tambien estamos en el primer renglon
    CMP CURSORY, 2
    JNE IZQUIERDA_LINEA_ANTERIOR

    ; No podemos movernos mas
    JMP CICLO_EDITOR


IZQUIERDA_LINEA_ANTERIOR:

    DEC CURSORY
    MOV CURSORX, 79
    JMP CICLO_EDITOR


; =================================================
; FLECHA DERECHA
; =================================================

FLECHA_DERECHA:

    CMP CURSORX, 79
    JE DERECHA_FIN_LINEA

    ; Movimiento normal
    INC CURSORX
    JMP CICLO_EDITOR


DERECHA_FIN_LINEA:

    ; Estamos en columna 79
    ; Revisar si tambien estamos en el ultimo renglon
    CMP CURSORY, 24
    JNE DERECHA_LINEA_SIGUIENTE

    ; No podemos movernos mas
    JMP CICLO_EDITOR


DERECHA_LINEA_SIGUIENTE:

    INC CURSORY
    MOV CURSORX, 0
    JMP CICLO_EDITOR


; =================================================
; FIN DEL PROGRAMA
; =================================================

FIN_PROGRAMA:

    ; Regresar a modo texto normal
    MOV AX, 0003H
    INT 10H

    ; Terminar programa
    MOV AX, 4C00H
    INT 21H


MAIN ENDP

END MAIN