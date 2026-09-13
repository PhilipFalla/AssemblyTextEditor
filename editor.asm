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

; -------------------------------------------------
; BUFFER DEL DOCUMENTO
; -------------------------------------------------

; Area editable:
; 80 columnas x 23 renglones = 1840 caracteres
;
; Cada posicion del buffer representa una posicion
; visible de la pantalla.
;
; Fila 2  -> posiciones 0 - 79
; Fila 3  -> posiciones 80 - 159
; ...
; Fila 24 -> posiciones 1760 - 1839

BUFFER_TEXTO DB 1840 DUP(' ')

; -------------------------------------------------
; COLORES DEL TEXTO
; -------------------------------------------------

; Guarda el color de cada caracter del documento
BUFFER_COLOR DB 1840 DUP(07H)

; Color que se utilizara para los nuevos caracteres
; 07H = blanco
COLOR_ACTUAL DB 07H

; Controla cual de los 3 colores esta seleccionado
; 0 = blanco
; 1 = verde
; 2 = celeste
NUM_COLOR    DB 0

; -------------------------------------------------
; COLOR DE FONDO
; -------------------------------------------------

; Controla cual de los 3 fondos esta seleccionado
; 0 = negro
; 1 = azul
; 2 = rojo
NUM_FONDO    DB 0

; Valor del fondo actual
; Los bits altos del atributo representan el fondo
FONDO_ACTUAL DB 00H

; -------------------------------------------------
; IMAGENES DEL DOCUMENTO
; -------------------------------------------------

; Maximo de imagenes que se pueden insertar
MAX_IMAGENES EQU 20

; Cantidad de imagenes actualmente insertadas
NUM_IMAGENES DB 0

; Informacion de cada imagen
; TIPO: 1 = corazon, 2 = flor
IMAGEN_TIPO DB MAX_IMAGENES DUP(0)
IMAGEN_X    DB MAX_IMAGENES DUP(0)
IMAGEN_Y    DB MAX_IMAGENES DUP(0)

; -------------------------------------------------
; PANTALLA DE AYUDA
; -------------------------------------------------

TITULOAYUDA DB 'ATAJOS DEL EDITOR$'

AYUDA1 DB 'ALT+C  - Centrar cursor en la linea actual$'
AYUDA2 DB 'ALT+U  - Ir al primer renglon$'
AYUDA3 DB 'ALT+D  - Ir al ultimo renglon$'
AYUDA4 DB 'ALT+M  - Cambiar color de letra$'
AYUDA5 DB 'ALT+N  - Cambiar color de fondo$'
AYUDA6 DB 'ALT+I  - Insertar imagen 1$'
AYUDA7 DB 'ALT+J  - Insertar imagen 2$'
AYUDA8 DB 'ALT+B  - Buscar y reemplazar$'
AYUDA9 DB 'ALT+H  - Mostrar esta ayuda$'
AYUDA10 DB 'ALT+Z  - Regresar al menu principal$'
AYUDA11 DB 'ALT+S  - Guardar y salir$'

VOLVERAYUDA DB 'Presiona cualquier tecla para regresar$'

; -------------------------------------------------
; BUSCAR Y REEMPLAZAR
; -------------------------------------------------

TITULOBUSCAR DB 'BUSCAR Y REEMPLAZAR$'
TXT_BUSCAR   DB 'Texto a buscar: $'
TXT_REEMPLAZAR DB 'Reemplazar por: $'
TXT_ENTER    DB 'Presiona ENTER para continuar$'

; Maximo 20 caracteres para cada entrada
BUSCAR_TEXTO     DB 21 DUP(0)
REEMPLAZAR_TEXTO DB 21 DUP(0)

LARGO_BUSCAR     DB 0
LARGO_REEMPLAZAR DB 0

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
    JNE REVISAR_ALT_M
    JMP FLECHA_DERECHA


REVISAR_ALT_M:

    ; Alt + M
    CMP AH, 32H
    JNE REVISAR_ALT_N

    CMP AL, 00H
    JNE REVISAR_ALT_N

    JMP CAMBIAR_COLOR


REVISAR_ALT_N:

    ; Alt + N
    CMP AH, 31H
    JNE REVISAR_ALT_C

    CMP AL, 00H
    JNE REVISAR_ALT_C

    JMP CAMBIAR_FONDO


REVISAR_ALT_C:

    ; Alt + C
    ; Scan code de C = 2EH
    CMP AH, 2EH
    JNE REVISAR_ALT_U

    CMP AL, 00H
    JNE REVISAR_ALT_U

    JMP CENTRAR_CURSOR


REVISAR_ALT_U:

    ; Alt + U
    ; Scan code de U = 16H
    CMP AH, 16H
    JNE REVISAR_ALT_D

    CMP AL, 00H
    JNE REVISAR_ALT_D

    JMP PRIMER_RENGLON


REVISAR_ALT_D:

    ; Alt + D
    CMP AH, 20H
    JNE REVISAR_ALT_I

    CMP AL, 00H
    JNE REVISAR_ALT_I

    JMP ULTIMO_RENGLON


REVISAR_ALT_I:

    ; Alt + I
    CMP AH, 17H
    JNE REVISAR_ALT_J

    CMP AL, 00H
    JNE REVISAR_ALT_J

    JMP INSERTAR_CORAZON


REVISAR_ALT_J:

    ; Alt + J
    CMP AH, 24H
    JNE REVISAR_ALT_B

    CMP AL, 00H
    JNE REVISAR_ALT_B

    JMP INSERTAR_FLOR


REVISAR_ALT_B:

    ; Alt + B
    ; Scan code de B = 30H
    CMP AH, 30H
    JNE REVISAR_ALT_H

    CMP AL, 00H
    JNE REVISAR_ALT_H

    JMP PANTALLA_BUSCAR


REVISAR_ALT_H:

    ; Alt + H
    CMP AH, 23H
    JNE REVISAR_ALT_Z

    CMP AL, 00H
    JNE REVISAR_ALT_Z

    JMP MOSTRAR_AYUDA


REVISAR_ALT_Z:

    ; Alt + Z
    ; Scan code de Z = 2CH
    CMP AH, 2CH
    JNE REVISAR_ESCAPE

    CMP AL, 00H
    JNE REVISAR_ESCAPE

    JMP REGRESAR_MENU


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

    ; Guardar temporalmente el caracter
    MOV DL, AL

    ; Calcular donde corresponde dentro del buffer
    CALL CALCULAR_POSICION

    ; Guardar caracter en memoria
    MOV BUFFER_TEXTO[SI], DL

    ; -------------------------------------------------
    ; Crear atributo del caracter
    ; fondo + color de letra
    ; -------------------------------------------------

    MOV BL, FONDO_ACTUAL
    OR BL, COLOR_ACTUAL

    ; Guardar atributo completo de este caracter
    MOV BUFFER_COLOR[SI], BL

    ; Recuperar caracter
    MOV AL, DL

    ; Mostrar caracter utilizando su atributo
    MOV AH, 09H
    MOV BH, 00H
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
; CALCULAR POSICION EN EL BUFFER
; =================================================
;
; Entrada:
;   CURSORX = columna actual
;   CURSORY = renglon actual
;
; Salida:
;   SI = indice dentro de BUFFER_TEXTO
;
; Formula:
;   (CURSORY - 2) * 80 + CURSORX
; =================================================

CALCULAR_POSICION PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

    ; Obtener numero de renglon dentro del editor
    MOV AL, CURSORY
    SUB AL, 2

    ; Convertir a 16 bits
    XOR AH, AH

    ; Multiplicar renglon por 80
    MOV BX, 80
    MUL BX

    ; AX ahora contiene:
    ; (CURSORY - 2) * 80

    ; Agregar columna actual
    XOR BX, BX
    MOV BL, CURSORX
    ADD AX, BX

    ; Guardar indice en SI
    MOV SI, AX

    POP DX
    POP BX
    POP AX

    RET

CALCULAR_POSICION ENDP

; =================================================
; ALT + M - CAMBIAR COLOR DE LETRA
; =================================================

CAMBIAR_COLOR:

    CMP NUM_COLOR, 0
    JE COLOR_VERDE

    CMP NUM_COLOR, 1
    JE COLOR_CELESTE

    ; Si estaba en color 2, regresar a blanco
    MOV NUM_COLOR, 0
    MOV COLOR_ACTUAL, 07H
    JMP CICLO_EDITOR


COLOR_VERDE:

    MOV NUM_COLOR, 1
    MOV COLOR_ACTUAL, 02H
    JMP CICLO_EDITOR


COLOR_CELESTE:

    MOV NUM_COLOR, 2
    MOV COLOR_ACTUAL, 03H
    JMP CICLO_EDITOR

; =================================================
; ALT + N - CAMBIAR COLOR DE FONDO
; =================================================

CAMBIAR_FONDO:

    CMP NUM_FONDO, 0
    JE FONDO_AZUL

    CMP NUM_FONDO, 1
    JE FONDO_ROJO

    ; Si estaba en fondo rojo, regresar a negro
    MOV NUM_FONDO, 0
    MOV FONDO_ACTUAL, 00H
    JMP CICLO_EDITOR


FONDO_AZUL:

    MOV NUM_FONDO, 1
    MOV FONDO_ACTUAL, 10H
    JMP CICLO_EDITOR


FONDO_ROJO:

    MOV NUM_FONDO, 2
    MOV FONDO_ACTUAL, 40H
    JMP CICLO_EDITOR

; =================================================
; ALT + C - CENTRAR CURSOR
; =================================================

CENTRAR_CURSOR:

    ; Pantalla de 80 columnas: 0 - 79
    ; Columna 40 = aproximadamente el centro
    MOV CURSORX, 40

    JMP CICLO_EDITOR


; =================================================
; ALT + U - PRIMER RENGLON
; =================================================

PRIMER_RENGLON:

    ; Nuestro primer renglon editable es el 2
    ; porque las filas 0 y 1 quedan para interfaz
    MOV CURSORY, 2

    JMP CICLO_EDITOR


; =================================================
; ALT + D - ULTIMO RENGLON
; =================================================

ULTIMO_RENGLON:

    ; Ultimo renglon de la pantalla 80x25
    MOV CURSORY, 24

    JMP CICLO_EDITOR

; =================================================
; ALT + H - MOSTRAR AYUDA
; =================================================

MOSTRAR_AYUDA:

    ; Limpiar pantalla
    MOV AX, 0003H
    INT 10H

    ; Titulo
    MOV BH, 1
    MOV BL, 30
    LEA DX, TITULOAYUDA
    CALL MOSTRAR_TEXTO

    ; Atajos
    MOV BH, 3
    MOV BL, 15
    LEA DX, AYUDA1
    CALL MOSTRAR_TEXTO

    MOV BH, 4
    MOV BL, 15
    LEA DX, AYUDA2
    CALL MOSTRAR_TEXTO

    MOV BH, 5
    MOV BL, 15
    LEA DX, AYUDA3
    CALL MOSTRAR_TEXTO

    MOV BH, 6
    MOV BL, 15
    LEA DX, AYUDA4
    CALL MOSTRAR_TEXTO

    MOV BH, 7
    MOV BL, 15
    LEA DX, AYUDA5
    CALL MOSTRAR_TEXTO

    MOV BH, 8
    MOV BL, 15
    LEA DX, AYUDA6
    CALL MOSTRAR_TEXTO

    MOV BH, 9
    MOV BL, 15
    LEA DX, AYUDA7
    CALL MOSTRAR_TEXTO

    MOV BH, 10
    MOV BL, 15
    LEA DX, AYUDA8
    CALL MOSTRAR_TEXTO

    MOV BH, 11
    MOV BL, 15
    LEA DX, AYUDA9
    CALL MOSTRAR_TEXTO

    MOV BH, 12
    MOV BL, 15
    LEA DX, AYUDA10
    CALL MOSTRAR_TEXTO

    MOV BH, 13
    MOV BL, 15
    LEA DX, AYUDA11
    CALL MOSTRAR_TEXTO

    MOV BH, 16
    MOV BL, 20
    LEA DX, VOLVERAYUDA
    CALL MOSTRAR_TEXTO

    ; Esperar cualquier tecla
    MOV AH, 00H
    INT 16H

    ; Regresar al editor
    JMP REDIBUJAR_EDITOR

; =================================================
; REDIBUJAR EDITOR DESDE MEMORIA
; =================================================

REDIBUJAR_EDITOR:

    ; Limpiar pantalla
    MOV AX, 0003H
    INT 10H

    ; Mostrar titulo nuevamente
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 00H
    MOV DL, 32
    INT 10H

    LEA DX, TITULOEDIT
    MOV AH, 09H
    INT 21H

    ; Comenzar desde la primera posicion
    XOR SI, SI

    MOV DH, 2
    MOV DL, 0


REDIBUJAR_SIGUIENTE:

    ; Revisar si terminamos las 1840 posiciones
    CMP SI, 1840
    JAE REDIBUJAR_FIN

    ; Posicionar cursor
    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    ; Obtener caracter
    MOV AL, BUFFER_TEXTO[SI]

    ; Obtener atributo guardado
    MOV BL, BUFFER_COLOR[SI]

    ; Dibujar caracter
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 1
    INT 10H

    ; Siguiente posicion
    INC SI
    INC DL

    CMP DL, 80
    JB REDIBUJAR_SIGUIENTE

    ; Siguiente renglon
    MOV DL, 0
    INC DH

    JMP REDIBUJAR_SIGUIENTE


REDIBUJAR_FIN:

    ; Guardar posicion real del cursor
    MOV AL, CURSORX
    MOV AH, CURSORY

    PUSH AX

    ; Redibujar todas las imagenes encima del texto
    CALL REDIBUJAR_IMAGENES

    ; Recuperar posicion real del cursor
    POP AX

    MOV CURSORX, AL
    MOV CURSORY, AH

    JMP CICLO_EDITOR

; =================================================
; MOSTRAR TEXTO EN UNA POSICION
;
; Entrada:
;   BH = fila
;   BL = columna
;   DX = direccion del texto
; =================================================

MOSTRAR_TEXTO PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    ; Guardar direccion del texto
    MOV SI, DX

    ; Posicionar cursor
    MOV DH, BH
    MOV DL, BL
    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    ; Mostrar texto
    MOV DX, SI
    MOV AH, 09H
    INT 21H

    POP SI
    POP DX
    POP BX
    POP AX

    RET

MOSTRAR_TEXTO ENDP    

; =================================================
; ALT + Z - REGRESAR AL MENU PRINCIPAL
; =================================================

REGRESAR_MENU:

    ; Limpiar pantalla
    MOV AX, 0003H
    INT 10H

    ; -------------------------------------------------
    ; INTEGRACION CON PERSONA A
    ;
    ; Aqui se llamara al procedimiento del menu
    ; principal cuando ambos modulos se unan.
    ;
    ; Por ahora termina el programa para poder
    ; probar que ALT+Z fue detectado correctamente.
    ; -------------------------------------------------

    JMP FIN_PROGRAMA

; =================================================
; ALT + I - INSERTAR CORAZON
; =================================================

INSERTAR_CORAZON:

    ; Verificar que el corazon quepa horizontalmente
    CMP CURSORX, 73
    JBE CORAZON_REVISAR_Y

    JMP CICLO_EDITOR


CORAZON_REVISAR_Y:

    ; Verificar que el corazon quepa verticalmente
    CMP CURSORY, 20
    JBE CORAZON_REVISAR_CANTIDAD

    JMP CICLO_EDITOR


CORAZON_REVISAR_CANTIDAD:

    ; Revisar si ya llegamos al maximo
    CMP NUM_IMAGENES, MAX_IMAGENES
    JB CORAZON_GUARDAR

    JMP CICLO_EDITOR


CORAZON_GUARDAR:

    ; Obtener indice de la nueva imagen
    XOR BX, BX
    MOV BL, NUM_IMAGENES

    ; Tipo 1 = corazon
    MOV IMAGEN_TIPO[BX], 1

    ; Guardar posicion actual del cursor
    MOV AL, CURSORX
    MOV IMAGEN_X[BX], AL

    MOV AL, CURSORY
    MOV IMAGEN_Y[BX], AL

    ; Aumentar cantidad
    INC NUM_IMAGENES

    ; Dibujar el corazon
    CALL DIBUJAR_CORAZON

    JMP CICLO_EDITOR

; =================================================
; DIBUJAR CORAZON
;
; Utiliza CURSORX y CURSORY como esquina
; superior izquierda de la imagen.
; =================================================

DIBUJAR_CORAZON PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Color rojo claro
    MOV BL, 0CH

    ; -----------------------------
    ; FILA 1
    ;  XX XX
    ; -----------------------------

    MOV DH, CURSORY
    MOV DL, CURSORX
    INC DL

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 2
    INT 10H

    ; Segundo bloque de la fila
    ADD DL, 3

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 2
    INT 10H

    ; -----------------------------
    ; FILA 2 - XXXXXXX
    ; -----------------------------

    MOV DH, CURSORY
    INC DH
    MOV DL, CURSORX

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 7
    INT 10H

    ; -----------------------------
    ; FILA 3 - XXXXXXX
    ; -----------------------------

    MOV DH, CURSORY
    ADD DH, 2
    MOV DL, CURSORX

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 7
    INT 10H

    ; -----------------------------
    ; FILA 4 -  XXXXX
    ; -----------------------------

    MOV DH, CURSORY
    ADD DH, 3
    MOV DL, CURSORX
    INC DL

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 5
    INT 10H

    ; -----------------------------
    ; FILA 5 -   XXX
    ; -----------------------------

    MOV DH, CURSORY
    ADD DH, 4
    MOV DL, CURSORX
    ADD DL, 2

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 3
    INT 10H

    POP DX
    POP CX
    POP BX
    POP AX

    RET

DIBUJAR_CORAZON ENDP

; =================================================
; ALT + J - INSERTAR FLOR
; =================================================

INSERTAR_FLOR:

    ; La flor mide 7 columnas
    ; No permitir que salga por la derecha
    CMP CURSORX, 73
    JBE FLOR_REVISAR_Y

    JMP CICLO_EDITOR


FLOR_REVISAR_Y:

    ; La flor mide 5 renglones
    ; No permitir que salga por abajo
    CMP CURSORY, 20
    JBE FLOR_REVISAR_CANTIDAD

    JMP CICLO_EDITOR


FLOR_REVISAR_CANTIDAD:

    ; Revisar si ya llegamos al maximo
    CMP NUM_IMAGENES, MAX_IMAGENES
    JB FLOR_GUARDAR

    JMP CICLO_EDITOR


FLOR_GUARDAR:

    XOR BX, BX
    MOV BL, NUM_IMAGENES

    ; Tipo 2 = flor
    MOV IMAGEN_TIPO[BX], 2

    ; Guardar posicion
    MOV AL, CURSORX
    MOV IMAGEN_X[BX], AL

    MOV AL, CURSORY
    MOV IMAGEN_Y[BX], AL

    INC NUM_IMAGENES

    CALL DIBUJAR_FLOR

    JMP CICLO_EDITOR

; =================================================
; DIBUJAR FLOR
; =================================================

DIBUJAR_FLOR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; -----------------------------
    ; FILA 1 -   X X
    ; -----------------------------

    ; Rosado claro
    MOV BL, 0DH

    MOV DH, CURSORY
    MOV DL, CURSORX
    ADD DL, 2

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 1
    INT 10H

    ADD DL, 2

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 1
    INT 10H


    ; -----------------------------
    ; FILA 2 -  XXXXX
    ; -----------------------------

    MOV DH, CURSORY
    INC DH
    MOV DL, CURSORX
    INC DL

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 5
    INT 10H


    ; -----------------------------
    ; FILA 3 -   XXX
    ; -----------------------------

    MOV DH, CURSORY
    ADD DH, 2
    MOV DL, CURSORX
    ADD DL, 2

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 3
    INT 10H


    ; -----------------------------
    ; FILA 4 - tallo
    ;    X
    ; -----------------------------

    ; Verde claro
    MOV BL, 0AH

    MOV DH, CURSORY
    ADD DH, 3
    MOV DL, CURSORX
    ADD DL, 3

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 1
    INT 10H


    ; -----------------------------
    ; FILA 5 - hojas
    ;   XXX
    ; -----------------------------

    MOV DH, CURSORY
    ADD DH, 4
    MOV DL, CURSORX
    ADD DL, 2

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 3
    INT 10H


    POP DX
    POP CX
    POP BX
    POP AX

    RET

DIBUJAR_FLOR ENDP

; =================================================
; REDIBUJAR TODAS LAS IMAGENES
; =================================================

REDIBUJAR_IMAGENES PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Empezar con la primera imagen
    XOR SI, SI

    ; Cantidad total de imagenes
    XOR CX, CX
    MOV CL, NUM_IMAGENES

    ; Si no hay imagenes, terminar
    CMP CX, 0
    JE REDIBUJAR_IMAGENES_FIN


REDIBUJAR_IMAGEN_LOOP:

    ; Revisar tipo de imagen
CMP IMAGEN_TIPO[SI], 1
JE REDIBUJAR_CORAZON_IMG

CMP IMAGEN_TIPO[SI], 2
JE REDIBUJAR_FLOR_IMG

JMP REDIBUJAR_SIGUIENTE_IMAGEN


REDIBUJAR_CORAZON_IMG:

    PUSH CX
    PUSH SI

    MOV AL, IMAGEN_X[SI]
    MOV CURSORX, AL

    MOV AL, IMAGEN_Y[SI]
    MOV CURSORY, AL

    CALL DIBUJAR_CORAZON

    POP SI
    POP CX

    JMP REDIBUJAR_SIGUIENTE_IMAGEN


REDIBUJAR_FLOR_IMG:

    PUSH CX
    PUSH SI

    MOV AL, IMAGEN_X[SI]
    MOV CURSORX, AL

    MOV AL, IMAGEN_Y[SI]
    MOV CURSORY, AL

    CALL DIBUJAR_FLOR

    POP SI
    POP CX

    JMP REDIBUJAR_SIGUIENTE_IMAGEN


REDIBUJAR_SIGUIENTE_IMAGEN:

    INC SI
    LOOP REDIBUJAR_IMAGEN_LOOP


REDIBUJAR_IMAGENES_FIN:

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

REDIBUJAR_IMAGENES ENDP

; =================================================
; ALT + B - PANTALLA BUSCAR Y REEMPLAZAR
; =================================================

PANTALLA_BUSCAR:

    ; Limpiar pantalla
    MOV AX, 0003H
    INT 10H

    ; Titulo
    MOV BH, 2
    MOV BL, 29
    LEA DX, TITULOBUSCAR
    CALL MOSTRAR_TEXTO

    ; Texto a buscar
    MOV BH, 6
    MOV BL, 15
    LEA DX, TXT_BUSCAR
    CALL MOSTRAR_TEXTO

    ; Colocar cursor despues del mensaje
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 6
    MOV DL, 31
    INT 10H

    ; Limpiar longitud anterior
    MOV LARGO_BUSCAR, 0

    ; Leer texto a buscar
    LEA DI, BUSCAR_TEXTO
    CALL LEER_CADENA

    MOV AX, CX
    MOV LARGO_BUSCAR, AL

    ; Texto de reemplazo
    MOV BH, 9
    MOV BL, 15
    LEA DX, TXT_REEMPLAZAR
    CALL MOSTRAR_TEXTO

    ; Colocar cursor despues del mensaje
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 9
    MOV DL, 32
    INT 10H

    ; Limpiar longitud anterior
    MOV LARGO_REEMPLAZAR, 0

    ; Leer reemplazo
    LEA DI, REEMPLAZAR_TEXTO
    CALL LEER_CADENA

    MOV AX, CX
    MOV LARGO_REEMPLAZAR, AL

    ; Realizar busqueda y reemplazo
    CALL BUSCAR_REEMPLAZAR

    ; Redibujar documento con los cambios
    JMP REDIBUJAR_EDITOR

    ; =================================================
; LEER CADENA
;
; Entrada:
;   DI = direccion del buffer
;
; Salida:
;   CX = cantidad de caracteres ingresados
;
; ENTER termina la entrada
; Maximo 20 caracteres
; =================================================

LEER_CADENA PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    XOR CX, CX


LEER_CADENA_TECLA:

    MOV AH, 00H
    INT 16H

    ; ENTER
    CMP AL, 0DH
    JE LEER_CADENA_FIN

    ; BACKSPACE
    CMP AL, 08H
    JE LEER_CADENA_BACKSPACE

    ; Maximo 20 caracteres
    CMP CX, 20
    JAE LEER_CADENA_TECLA

    ; Solo aceptar los caracteres permitidos
    ; Letras, numeros, coma, punto y dos puntos

    CMP AL, '0'
    JB LEER_REVISAR_MAYUS

    CMP AL, '9'
    JBE LEER_GUARDAR


LEER_REVISAR_MAYUS:

    CMP AL, 'A'
    JB LEER_REVISAR_MINUS

    CMP AL, 'Z'
    JBE LEER_GUARDAR


LEER_REVISAR_MINUS:

    CMP AL, 'a'
    JB LEER_REVISAR_SIGNOS

    CMP AL, 'z'
    JBE LEER_GUARDAR


LEER_REVISAR_SIGNOS:

    CMP AL, ','
    JE LEER_GUARDAR

    CMP AL, '.'
    JE LEER_GUARDAR

    CMP AL, ':'
    JE LEER_GUARDAR

    ; En tu DOSBox : tambien puede llegar como >
    CMP AL, '>'
    JNE LEER_CADENA_TECLA

    MOV AL, ':'


LEER_GUARDAR:

    ; Guardar caracter
    MOV [DI], AL
    INC DI
    INC CX

    ; Mostrarlo en pantalla
    MOV AH, 0EH
    MOV BH, 00H
    INT 10H

    JMP LEER_CADENA_TECLA


LEER_CADENA_BACKSPACE:

    ; Si no hay nada escrito, ignorar
    CMP CX, 0
    JE LEER_CADENA_TECLA

    DEC DI
    DEC CX

    ; Borrar del buffer
    MOV BYTE PTR [DI], 0

    ; Mover cursor atras
    MOV AH, 0EH
    MOV AL, 08H
    INT 10H

    ; Escribir espacio
    MOV AL, ' '
    INT 10H

    ; Regresar otra vez
    MOV AL, 08H
    INT 10H

    JMP LEER_CADENA_TECLA


LEER_CADENA_FIN:

    ; Colocar terminador 0
    MOV BYTE PTR [DI], 0

    POP SI
    POP DX
    POP BX
    POP AX

    RET

LEER_CADENA ENDP

; =================================================
; BUSCAR Y REEMPLAZAR
;
; Busca todas las coincidencias dentro de
; BUFFER_TEXTO y las reemplaza.
;
; Por ahora, buscar y reemplazar deben tener
; exactamente la misma longitud.
; =================================================

BUSCAR_REEMPLAZAR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BP

    ; No hacer nada si el texto a buscar esta vacio
    CMP LARGO_BUSCAR, 0
    JNE BR_REVISAR_LARGOS

    JMP BR_FIN


BR_REVISAR_LARGOS:

    ; Por ahora ambos textos deben tener el mismo largo
    MOV AL, LARGO_BUSCAR
    CMP AL, LARGO_REEMPLAZAR
    JE BR_INICIAR

    JMP BR_FIN


BR_INICIAR:

    ; SI = posicion actual dentro del documento
    XOR SI, SI


BR_SIGUIENTE_POSICION:

    ; -------------------------------------------------
    ; Verificar que todavia haya suficiente espacio
    ; para comparar toda la palabra
    ; -------------------------------------------------

    MOV AX, SI

    XOR BX, BX
    MOV BL, LARGO_BUSCAR

    ADD AX, BX

    CMP AX, 1840
    JBE BR_COMPARAR

    JMP BR_FIN


BR_COMPARAR:

    ; Guardar posicion inicial
    MOV BP, SI

    ; DI apunta al texto que buscamos
    LEA DI, BUSCAR_TEXTO

    ; CX = cantidad de caracteres a comparar
    XOR CX, CX
    MOV CL, LARGO_BUSCAR


BR_COMPARAR_LOOP:

    MOV AL, BUFFER_TEXTO[SI]

    CMP AL, [DI]
    JNE BR_NO_COINCIDE

    INC SI
    INC DI

    LOOP BR_COMPARAR_LOOP

    ; Si llegamos aqui, encontramos coincidencia
    JMP BR_REEMPLAZAR


BR_NO_COINCIDE:

    ; Volver a la posicion inicial
    MOV SI, BP

    ; Probar desde el siguiente caracter
    INC SI

    JMP BR_SIGUIENTE_POSICION


BR_REEMPLAZAR:

    ; Volver al inicio de la coincidencia
    MOV SI, BP

    ; DI apunta al texto de reemplazo
    LEA DI, REEMPLAZAR_TEXTO

    XOR CX, CX
    MOV CL, LARGO_REEMPLAZAR


BR_REEMPLAZAR_LOOP:

    MOV AL, [DI]
    MOV BUFFER_TEXTO[SI], AL

    INC SI
    INC DI

    LOOP BR_REEMPLAZAR_LOOP

    ; SI ya queda despues de la palabra reemplazada
    ; Continuar buscando desde ahi
    JMP BR_SIGUIENTE_POSICION


BR_FIN:

    POP BP
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

BUSCAR_REEMPLAZAR ENDP

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