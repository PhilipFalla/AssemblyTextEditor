TITLE "PROYECTO 1 - EDITOR DE TEXTO"

.MODEL SMALL
.STACK 64

.DATA

; =================================================
; VARIABLES DE LA PANTALLA DE EDICION
; =================================================

; Posicion actual del cursor
CURSORX     DB 0
CURSORY     DB 2


; =================================================
; BUFFER DEL DOCUMENTO
; =================================================

; Area editable:
; 80 columnas x 23 renglones = 1840 caracteres
;
; Fila 2  -> posiciones 0 - 79
; Fila 3  -> posiciones 80 - 159
; ...
; Fila 24 -> posiciones 1760 - 1839

BUFFER_TEXTO DB 1840 DUP(' ')


; =================================================
; COLORES DEL TEXTO
; =================================================

; Guarda el atributo de cada caracter
BUFFER_COLOR DB 1840 DUP(07H)

; Color utilizado para nuevos caracteres
; 07H = blanco
COLOR_ACTUAL DB 07H

; 0 = blanco
; 1 = verde
; 2 = celeste
NUM_COLOR    DB 0


; =================================================
; COLOR DE FONDO
; =================================================

; 0 = negro
; 1 = azul
; 2 = rojo
NUM_FONDO    DB 0

; Bits altos del atributo representan el fondo
FONDO_ACTUAL DB 00H


; =================================================
; IMAGENES DEL DOCUMENTO
; =================================================

MAX_IMAGENES EQU 20

; Cantidad de imagenes insertadas
NUM_IMAGENES DB 0

; Tipo:
; 1 = corazon
; 2 = flor
IMAGEN_TIPO  DB MAX_IMAGENES DUP(0)
IMAGEN_X     DB MAX_IMAGENES DUP(0)
IMAGEN_Y     DB MAX_IMAGENES DUP(0)


; =================================================
; PANTALLA DE AYUDA
; =================================================

TITULOAYUDA DB 'ATAJOS DEL EDITOR$'

AYUDA1  DB 'ALT+C  - Centrar cursor en la linea actual$'
AYUDA2  DB 'ALT+U  - Ir al primer renglon$'
AYUDA3  DB 'ALT+D  - Ir al ultimo renglon$'
AYUDA4  DB 'ALT+M  - Cambiar color de letra$'
AYUDA5  DB 'ALT+N  - Cambiar color de fondo$'
AYUDA6  DB 'ALT+I  - Insertar imagen 1$'
AYUDA7  DB 'ALT+J  - Insertar imagen 2$'
AYUDA8  DB 'ALT+B  - Buscar y reemplazar$'
AYUDA9  DB 'ALT+H  - Mostrar esta ayuda$'
AYUDA10 DB 'ALT+Z  - Regresar al menu principal$'
AYUDA11 DB 'ALT+S  - Guardar y salir$'

VOLVERAYUDA DB 'Presiona cualquier tecla para regresar$'


; =================================================
; BUSCAR Y REEMPLAZAR
; =================================================

TITULOBUSCAR   DB 'BUSCAR Y REEMPLAZAR$'
TXT_BUSCAR     DB 'Texto a buscar: $'
TXT_REEMPLAZAR DB 'Reemplazar por: $'

; Maximo 20 caracteres
BUSCAR_TEXTO     DB 21 DUP(0)
REEMPLAZAR_TEXTO DB 21 DUP(0)

LARGO_BUSCAR     DB 0
LARGO_REEMPLAZAR DB 0


; =================================================
; TITULO DEL EDITOR
; =================================================

TITULOEDIT DB 'EDITOR DE TEXTO$'


; =================================================
; PANTALLA DE MENU PRINCIPAL
; =================================================

; 0 = Crear archivo nuevo
; 1 = Abrir archivo por nombre
; 2 = Abrir archivo por lista
; 3 = Salir
MENU_SELECCION DB 0

TITULOMENU DB 'EDITOR DE TEXTO x8086$'

; Icono decorativo (pantalla ASCII)
ICONO1 DB 201,205,205,205,205,205,187,'$'
ICONO2 DB 186,' ','E','D','T',' ',186,'$'
ICONO3 DB 200,205,205,205,205,205,188,'$'

; Marco de la pantalla de menu
BORDE_SUP DB 201,58 DUP(205),187,'$'
BORDE_INF DB 200,58 DUP(205),188,'$'

OPCION1 DB 'CREAR ARCHIVO NUEVO$'
OPCION2 DB 'ABRIR ARCHIVO POR NOMBRE$'
OPCION3 DB 'ABRIR ARCHIVO POR LISTA$'
OPCION4 DB 'SALIR$'

PIE_MENU DB 'Flechas: mover   ENTER: seleccionar   ALT+X: salir$'

TXT_PROXIMAMENTE DB 'Funcion disponible proximamente. Presiona una tecla...$'


; =================================================
; MANEJO DE ARCHIVOS
; =================================================

; Nombre base ingresado por el usuario (sin extension)
; Maximo 8 caracteres + terminador
NOMBRE_TEMP DB 9 DUP(0)

; Nombre completo en disco (con extension .SYP)
; usado por CREAR_ARCHIVO, ABRIR_ARCHIVO y GUARDAR_SALIR
ARCHIVO_ACTUAL DB 13 DUP(0)

TXT_CREAR_TITULO DB 'CREAR ARCHIVO NUEVO$'
TXT_CREAR_NOMBRE DB 'Escribe el nombre (letras/numeros, maximo 8):$'
TXT_ERROR_CREAR  DB 'No se pudo crear el archivo. Presiona una tecla para reintentar...$'


.CODE

MAIN PROC FAR

    ; Inicializar segmento de datos
    MOV AX, @DATA
    MOV DS, AX

    ; Modo texto 80x25
    MOV AX, 0003H
    INT 10H

    ; El programa inicia en el menu principal.
    ; El titulo y la posicion inicial del cursor
    ; los define REDIBUJAR_EDITOR al entrar al editor.
    JMP MOSTRAR_MENU_PRINCIPAL


; =================================================
; CICLO PRINCIPAL DEL EDITOR
; =================================================

CICLO_EDITOR:

    ; Colocar cursor
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, CURSORY
    MOV DL, CURSORX
    INT 10H

    ; Leer tecla
    ; AL = ASCII
    ; AH = scan code
    MOV AH, 00H
    INT 16H


; =================================================
; DETECTAR FLECHAS
; =================================================

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


; =================================================
; DETECTAR ATAJOS ALT
; =================================================

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
    CMP AH, 2EH
    JNE REVISAR_ALT_U

    CMP AL, 00H
    JNE REVISAR_ALT_U

    JMP CENTRAR_CURSOR


REVISAR_ALT_U:

    ; Alt + U
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
    CMP AH, 2CH
    JNE REVISAR_ALT_S

    CMP AL, 00H
    JNE REVISAR_ALT_S

    JMP REGRESAR_MENU


REVISAR_ALT_S:

    ; Alt + S
    CMP AH, 1FH
    JNE REVISAR_ESCAPE

    CMP AL, 00H
    JNE REVISAR_ESCAPE

    JMP GUARDAR_SALIR


REVISAR_ESCAPE:

    ; ESC temporal para pruebas
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
    ; puede llegar como >
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

    ; Calcular posicion dentro del buffer
    CALL CALCULAR_POSICION

    ; Guardar caracter
    MOV BUFFER_TEXTO[SI], DL

    ; Crear atributo:
    ; fondo + color de letra
    MOV BL, FONDO_ACTUAL
    OR BL, COLOR_ACTUAL

    ; Guardar atributo
    MOV BUFFER_COLOR[SI], BL

    ; Recuperar caracter
    MOV AL, DL

    ; Mostrar caracter
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 1
    INT 10H

    ; Mantener las imagenes siempre encima del texto
    CALL REDIBUJAR_IMAGENES

    ; Revisar final del renglon
    CMP CURSORX, 79
    JNE ESCRIBIR_AVANZAR_X

    ; Si estamos en columna 79,
    ; revisar si tambien estamos en la ultima fila
    CMP CURSORY, 24
    JNE ESCRIBIR_SIGUIENTE_LINEA

    JMP CICLO_EDITOR


ESCRIBIR_AVANZAR_X:

    INC CURSORX
    JMP CICLO_EDITOR


ESCRIBIR_SIGUIENTE_LINEA:

    MOV CURSORX, 0
    INC CURSORY
    JMP CICLO_EDITOR


; =================================================
; MOVIMIENTO DEL CURSOR
; =================================================

FLECHA_ARRIBA:

    CMP CURSORY, 2
    JNE ARRIBA_MOVER

    JMP CICLO_EDITOR


ARRIBA_MOVER:

    DEC CURSORY
    JMP CICLO_EDITOR


FLECHA_ABAJO:

    CMP CURSORY, 24
    JNE ABAJO_MOVER

    JMP CICLO_EDITOR


ABAJO_MOVER:

    INC CURSORY
    JMP CICLO_EDITOR


FLECHA_IZQUIERDA:

    CMP CURSORX, 0
    JE IZQUIERDA_INICIO_LINEA

    DEC CURSORX
    JMP CICLO_EDITOR


IZQUIERDA_INICIO_LINEA:

    CMP CURSORY, 2
    JNE IZQUIERDA_LINEA_ANTERIOR

    JMP CICLO_EDITOR


IZQUIERDA_LINEA_ANTERIOR:

    DEC CURSORY
    MOV CURSORX, 79
    JMP CICLO_EDITOR


FLECHA_DERECHA:

    CMP CURSORX, 79
    JE DERECHA_FIN_LINEA

    INC CURSORX
    JMP CICLO_EDITOR


DERECHA_FIN_LINEA:

    CMP CURSORY, 24
    JNE DERECHA_LINEA_SIGUIENTE

    JMP CICLO_EDITOR


DERECHA_LINEA_SIGUIENTE:

    INC CURSORY
    MOV CURSORX, 0
    JMP CICLO_EDITOR


; =================================================
; CALCULAR POSICION EN EL BUFFER
;
; Formula:
; (CURSORY - 2) * 80 + CURSORX
;
; Salida:
; SI = indice dentro del buffer
; =================================================

CALCULAR_POSICION PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

    MOV AL, CURSORY
    SUB AL, 2

    XOR AH, AH

    MOV BX, 80
    MUL BX

    XOR BX, BX
    MOV BL, CURSORX
    ADD AX, BX

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

    ; Regresar a blanco
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

    ; Regresar a negro
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

    ; Centro aproximado de pantalla de 80 columnas
    MOV CURSORX, 40

    JMP CICLO_EDITOR


; =================================================
; ALT + U - PRIMER RENGLON
; =================================================

PRIMER_RENGLON:

    ; Primer renglon editable
    MOV CURSORY, 2

    JMP CICLO_EDITOR


; =================================================
; ALT + D - ULTIMO RENGLON
; =================================================

ULTIMO_RENGLON:

    ; Ultimo renglon editable
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

    JMP REDIBUJAR_EDITOR


; =================================================
; REDIBUJAR EDITOR DESDE MEMORIA
; =================================================

REDIBUJAR_EDITOR:

    ; Limpiar pantalla
    MOV AX, 0003H
    INT 10H

    ; Mostrar titulo
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 00H
    MOV DL, 32
    INT 10H

    LEA DX, TITULOEDIT
    MOV AH, 09H
    INT 21H

    ; Primera posicion del buffer
    XOR SI, SI

    MOV DH, 2
    MOV DL, 0


REDIBUJAR_SIGUIENTE:

    CMP SI, 1840
    JAE REDIBUJAR_FIN

    ; Posicionar cursor
    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    ; Caracter
    MOV AL, BUFFER_TEXTO[SI]

    ; Atributo
    MOV BL, BUFFER_COLOR[SI]

    ; Dibujar
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 1
    INT 10H

    INC SI
    INC DL

    CMP DL, 80
    JB REDIBUJAR_SIGUIENTE

    MOV DL, 0
    INC DH

    JMP REDIBUJAR_SIGUIENTE


REDIBUJAR_FIN:

    ; Las imagenes deben quedar encima del texto
    CALL REDIBUJAR_IMAGENES

    JMP CICLO_EDITOR


; =================================================
; MOSTRAR TEXTO EN UNA POSICION
;
; Entrada:
; BH = fila
; BL = columna
; DX = direccion del texto
; =================================================

MOSTRAR_TEXTO PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    MOV SI, DX

    ; Posicionar cursor
    MOV DH, BH
    MOV DL, BL
    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    ; Mostrar cadena
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

    JMP MOSTRAR_MENU_PRINCIPAL


; =================================================
; MENU PRINCIPAL
; =================================================

MOSTRAR_MENU_PRINCIPAL:

    ; Limpiar pantalla
    MOV AX, 0003H
    INT 10H

    CALL DIBUJAR_MARCO

    ; Titulo
    MOV BH, 4
    MOV BL, 29
    LEA DX, TITULOMENU
    CALL MOSTRAR_TEXTO

    ; Icono decorativo
    MOV BH, 6
    MOV BL, 36
    LEA DX, ICONO1
    CALL MOSTRAR_TEXTO

    MOV BH, 7
    MOV BL, 36
    LEA DX, ICONO2
    CALL MOSTRAR_TEXTO

    MOV BH, 8
    MOV BL, 36
    LEA DX, ICONO3
    CALL MOSTRAR_TEXTO

    ; Pie de pantalla
    MOV BH, 20
    MOV BL, 14
    LEA DX, PIE_MENU
    CALL MOSTRAR_TEXTO

    MOV MENU_SELECCION, 0


MENU_REDIBUJAR:

    CALL DIBUJAR_OPCIONES_MENU


MENU_LEER_TECLA:

    MOV AH, 00H
    INT 16H

    ; Flecha arriba
    CMP AH, 48H
    JE MENU_ARRIBA

    ; Flecha abajo
    CMP AH, 50H
    JE MENU_ABAJO

    ; Enter
    CMP AL, 0DH
    JE MENU_SELECCIONAR

    ; Alt + X
    CMP AH, 2DH
    JNE MENU_LEER_TECLA

    CMP AL, 00H
    JNE MENU_LEER_TECLA

    JMP FIN_PROGRAMA


MENU_ARRIBA:

    CMP MENU_SELECCION, 0
    JE MENU_REDIBUJAR

    DEC MENU_SELECCION
    JMP MENU_REDIBUJAR


MENU_ABAJO:

    CMP MENU_SELECCION, 3
    JE MENU_REDIBUJAR

    INC MENU_SELECCION
    JMP MENU_REDIBUJAR


MENU_SELECCIONAR:

    ; JE no alcanza estos destinos (quedan lejos en el
    ; archivo), asi que se invierte la condicion y se
    ; usa JMP, que si soporta saltos largos.

    CMP MENU_SELECCION, 0
    JNE MENU_SEL_REVISAR_1
    JMP CREAR_ARCHIVO


MENU_SEL_REVISAR_1:

    CMP MENU_SELECCION, 1
    JNE MENU_SEL_REVISAR_2
    JMP ABRIR_ARCHIVO


MENU_SEL_REVISAR_2:

    CMP MENU_SELECCION, 2
    JNE MENU_SEL_SALIR
    JMP ABRIR_ARCHIVO_LISTA


MENU_SEL_SALIR:

    JMP FIN_PROGRAMA


; =================================================
; DIBUJAR MARCO DE LA PANTALLA DE MENU
; =================================================

DIBUJAR_MARCO PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Borde superior
    MOV BH, 2
    MOV BL, 10
    LEA DX, BORDE_SUP
    CALL MOSTRAR_TEXTO

    ; Borde inferior
    MOV BH, 22
    MOV BL, 10
    LEA DX, BORDE_INF
    CALL MOSTRAR_TEXTO

    ; Bordes laterales
    MOV DH, 3


MARCO_LATERAL:

    CMP DH, 22
    JAE MARCO_LATERAL_FIN

    MOV AH, 02H
    MOV BH, 00H
    MOV DL, 10
    INT 10H

    MOV AL, 186
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 1
    INT 10H

    MOV AH, 02H
    MOV BH, 00H
    MOV DL, 69
    INT 10H

    MOV AL, 186
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 1
    INT 10H

    INC DH
    JMP MARCO_LATERAL


MARCO_LATERAL_FIN:

    POP DX
    POP CX
    POP BX
    POP AX

    RET

DIBUJAR_MARCO ENDP


; =================================================
; DIBUJAR LAS 4 OPCIONES DEL MENU
;
; La opcion resaltada usa el atributo 70H
; (negro sobre blanco). Las demas usan 0BH.
; =================================================

DIBUJAR_OPCIONES_MENU PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Opcion 0 - Crear archivo nuevo
    MOV CL, 0BH
    CMP MENU_SELECCION, 0
    JNE DOM_OP0_COLOR
    MOV CL, 70H

DOM_OP0_COLOR:

    MOV BH, 12
    MOV BL, 24
    LEA DX, OPCION1
    CALL MOSTRAR_OPCION

    ; Opcion 1 - Abrir archivo por nombre
    MOV CL, 0BH
    CMP MENU_SELECCION, 1
    JNE DOM_OP1_COLOR
    MOV CL, 70H

DOM_OP1_COLOR:

    MOV BH, 14
    MOV BL, 24
    LEA DX, OPCION2
    CALL MOSTRAR_OPCION

    ; Opcion 2 - Abrir archivo por lista
    MOV CL, 0BH
    CMP MENU_SELECCION, 2
    JNE DOM_OP2_COLOR
    MOV CL, 70H

DOM_OP2_COLOR:

    MOV BH, 16
    MOV BL, 24
    LEA DX, OPCION3
    CALL MOSTRAR_OPCION

    ; Opcion 3 - Salir
    MOV CL, 0BH
    CMP MENU_SELECCION, 3
    JNE DOM_OP3_COLOR
    MOV CL, 70H

DOM_OP3_COLOR:

    MOV BH, 18
    MOV BL, 24
    LEA DX, OPCION4
    CALL MOSTRAR_OPCION

    POP DX
    POP CX
    POP BX
    POP AX

    RET

DIBUJAR_OPCIONES_MENU ENDP


; =================================================
; MOSTRAR UNA OPCION DE MENU CON COLOR
;
; Entrada:
; BH = fila
; BL = columna
; DX = direccion del texto (terminado en '$')
; CL = atributo de color
; =================================================

MOSTRAR_OPCION PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH BP
    PUSH ES

    MOV SI, DX

    ; CALL LARGO_CADENA destruye CX (devuelve la longitud
    ; ahi), asi que el atributo se guarda antes en AH.
    MOV AH, CL

    PUSH BX

    ; Calcular longitud de la cadena
    MOV DX, SI
    CALL LARGO_CADENA

    POP BX

    MOV DH, BH
    MOV DL, BL
    MOV BH, 00H
    MOV BL, AH

    PUSH DS
    POP ES
    MOV BP, SI

    ; AH=13H, AL=01H: escribir cadena de caracteres,
    ; usar atributo en BL, mover el cursor
    MOV AX, 1301H
    INT 10H

    POP ES
    POP BP
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX

    RET

MOSTRAR_OPCION ENDP


; =================================================
; CALCULAR LONGITUD DE UNA CADENA TERMINADA EN '$'
;
; Entrada:
; DX = direccion de la cadena
;
; Salida:
; CX = longitud (sin contar el '$')
; =================================================

LARGO_CADENA PROC NEAR

    PUSH AX
    PUSH SI

    MOV SI, DX
    XOR CX, CX


LARGO_CADENA_LOOP:

    MOV AL, [SI]
    CMP AL, '$'
    JE LARGO_CADENA_FIN

    INC CX
    INC SI
    JMP LARGO_CADENA_LOOP


LARGO_CADENA_FIN:

    POP SI
    POP AX

    RET

LARGO_CADENA ENDP


; =================================================
; MOSTRAR MENSAJE TEMPORAL "PROXIMAMENTE"
;
; Usado por las opciones del menu que todavia no
; tienen su funcionalidad conectada.
; =================================================

MOSTRAR_PROXIMAMENTE PROC NEAR

    PUSH AX
    PUSH BX
    PUSH DX

    MOV AX, 0003H
    INT 10H

    MOV BH, 12
    MOV BL, 12
    LEA DX, TXT_PROXIMAMENTE
    CALL MOSTRAR_TEXTO

    MOV AH, 00H
    INT 16H

    POP DX
    POP BX
    POP AX

    RET

MOSTRAR_PROXIMAMENTE ENDP


; =================================================
; CREAR ARCHIVO NUEVO
; =================================================

CREAR_ARCHIVO_PEDIR_NOMBRE:

    ; Limpiar pantalla
    MOV AX, 0003H
    INT 10H

    MOV BH, 6
    MOV BL, 30
    LEA DX, TXT_CREAR_TITULO
    CALL MOSTRAR_TEXTO

    MOV BH, 10
    MOV BL, 15
    LEA DX, TXT_CREAR_NOMBRE
    CALL MOSTRAR_TEXTO

    ; Cursor para escribir el nombre
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 12
    MOV DL, 15
    INT 10H

    LEA DI, NOMBRE_TEMP
    CALL LEER_NOMBRE_ARCHIVO

    JC CREAR_ARCHIVO_CANCELAR

    ; No permitir nombre vacio
    CMP CX, 0
    JE CREAR_ARCHIVO_PEDIR_NOMBRE

    CALL CONSTRUIR_NOMBRE_ARCHIVO

    ; Crear archivo (CX = atributos = 0)
    LEA DX, ARCHIVO_ACTUAL
    XOR CX, CX
    MOV AH, 3CH
    INT 21H

    JC CREAR_ARCHIVO_ERROR

    ; Cerrar el archivo recien creado
    MOV BX, AX
    MOV AH, 3EH
    INT 21H

    CALL REINICIAR_DOCUMENTO

    JMP REDIBUJAR_EDITOR


CREAR_ARCHIVO_ERROR:

    MOV BH, 14
    MOV BL, 15
    LEA DX, TXT_ERROR_CREAR
    CALL MOSTRAR_TEXTO

    MOV AH, 00H
    INT 16H

    JMP CREAR_ARCHIVO_PEDIR_NOMBRE


CREAR_ARCHIVO_CANCELAR:

    JMP MOSTRAR_MENU_PRINCIPAL


CREAR_ARCHIVO:

    JMP CREAR_ARCHIVO_PEDIR_NOMBRE


; =================================================
; LEER NOMBRE DE ARCHIVO
;
; Entrada:
; DI = direccion del buffer (ASCIIZ)
;
; Salida:
; CX = cantidad de caracteres
; CF = 1 si el usuario cancelo con ALT+Z
; CF = 0 si termino con ENTER
;
; Solo acepta letras y numeros, maximo 8 caracteres.
; Las minusculas se convierten a mayusculas.
; =================================================

LEER_NOMBRE_ARCHIVO PROC NEAR

    PUSH AX
    PUSH DX

    XOR CX, CX


LNA_TECLA:

    MOV AH, 00H
    INT 16H

    ; ALT + Z cancela
    CMP AH, 2CH
    JNE LNA_REVISAR_ENTER

    CMP AL, 00H
    JNE LNA_REVISAR_ENTER

    STC
    JMP LNA_FIN


LNA_REVISAR_ENTER:

    CMP AL, 0DH
    JE LNA_TERMINAR

    CMP AL, 08H
    JE LNA_BACKSPACE

    ; Maximo 8 caracteres
    CMP CX, 8
    JAE LNA_TECLA

    ; Numeros
    CMP AL, '0'
    JB LNA_REVISAR_MAYUS

    CMP AL, '9'
    JBE LNA_GUARDAR


LNA_REVISAR_MAYUS:

    CMP AL, 'A'
    JB LNA_REVISAR_MINUS

    CMP AL, 'Z'
    JBE LNA_GUARDAR


LNA_REVISAR_MINUS:

    CMP AL, 'a'
    JB LNA_TECLA

    CMP AL, 'z'
    JA LNA_TECLA

    ; Convertir a mayuscula
    SUB AL, 20H


LNA_GUARDAR:

    MOV [DI], AL
    INC DI
    INC CX

    MOV AH, 0EH
    MOV BH, 00H
    INT 10H

    JMP LNA_TECLA


LNA_BACKSPACE:

    CMP CX, 0
    JE LNA_TECLA

    DEC DI
    DEC CX

    MOV BYTE PTR [DI], 0

    MOV AH, 0EH
    MOV AL, 08H
    INT 10H

    MOV AL, ' '
    INT 10H

    MOV AL, 08H
    INT 10H

    JMP LNA_TECLA


LNA_TERMINAR:

    MOV BYTE PTR [DI], 0
    CLC


LNA_FIN:

    POP DX
    POP AX

    RET

LEER_NOMBRE_ARCHIVO ENDP


; =================================================
; CONSTRUIR NOMBRE COMPLETO DE ARCHIVO
;
; Copia NOMBRE_TEMP a ARCHIVO_ACTUAL y le agrega
; la extension .SYP
; =================================================

CONSTRUIR_NOMBRE_ARCHIVO PROC NEAR

    PUSH AX
    PUSH SI
    PUSH DI

    LEA SI, NOMBRE_TEMP
    LEA DI, ARCHIVO_ACTUAL


CNA_COPIAR:

    MOV AL, [SI]
    CMP AL, 0
    JE CNA_EXTENSION

    MOV [DI], AL
    INC SI
    INC DI
    JMP CNA_COPIAR


CNA_EXTENSION:

    MOV BYTE PTR [DI], '.'
    INC DI
    MOV BYTE PTR [DI], 'S'
    INC DI
    MOV BYTE PTR [DI], 'Y'
    INC DI
    MOV BYTE PTR [DI], 'P'
    INC DI
    MOV BYTE PTR [DI], 0

    POP DI
    POP SI
    POP AX

    RET

CONSTRUIR_NOMBRE_ARCHIVO ENDP


; =================================================
; REINICIAR DOCUMENTO EN BLANCO
;
; Deja los buffers del editor listos para un
; documento nuevo (texto, colores, imagenes y cursor).
; =================================================

REINICIAR_DOCUMENTO PROC NEAR

    PUSH AX
    PUSH CX
    PUSH DI

    ; Texto en blanco
    LEA DI, BUFFER_TEXTO
    MOV CX, 1840
    MOV AL, ' '


REINICIAR_TEXTO_LOOP:

    MOV [DI], AL
    INC DI
    LOOP REINICIAR_TEXTO_LOOP

    ; Color por defecto
    LEA DI, BUFFER_COLOR
    MOV CX, 1840
    MOV AL, 07H


REINICIAR_COLOR_LOOP:

    MOV [DI], AL
    INC DI
    LOOP REINICIAR_COLOR_LOOP

    MOV NUM_IMAGENES, 0

    MOV COLOR_ACTUAL, 07H
    MOV NUM_COLOR, 0

    MOV FONDO_ACTUAL, 00H
    MOV NUM_FONDO, 0

    MOV CURSORX, 0
    MOV CURSORY, 2

    POP DI
    POP CX
    POP AX

    RET

REINICIAR_DOCUMENTO ENDP


; =================================================
; ABRIR ARCHIVO POR NOMBRE
;
; PENDIENTE: se implementa en un commit posterior.
; =================================================

ABRIR_ARCHIVO:

    CALL MOSTRAR_PROXIMAMENTE
    JMP MOSTRAR_MENU_PRINCIPAL


; =================================================
; ABRIR ARCHIVO POR LISTA (EXTRA)
;
; PENDIENTE: se implementa en un commit posterior.
; =================================================

ABRIR_ARCHIVO_LISTA:

    CALL MOSTRAR_PROXIMAMENTE
    JMP MOSTRAR_MENU_PRINCIPAL


; =================================================
; ALT + I - INSERTAR CORAZON
; =================================================

INSERTAR_CORAZON:

    ; Corazon de 7 x 5
    ; Verificar limite horizontal
    CMP CURSORX, 73
    JBE CORAZON_REVISAR_Y

    JMP CICLO_EDITOR


CORAZON_REVISAR_Y:

    ; Verificar limite vertical
    CMP CURSORY, 20
    JBE CORAZON_REVISAR_CANTIDAD

    JMP CICLO_EDITOR


CORAZON_REVISAR_CANTIDAD:

    CMP NUM_IMAGENES, MAX_IMAGENES
    JB CORAZON_GUARDAR

    JMP CICLO_EDITOR


CORAZON_GUARDAR:

    XOR BX, BX
    MOV BL, NUM_IMAGENES

    ; Tipo 1 = corazon
    MOV IMAGEN_TIPO[BX], 1

    ; Guardar posicion
    MOV AL, CURSORX
    MOV IMAGEN_X[BX], AL

    MOV AL, CURSORY
    MOV IMAGEN_Y[BX], AL

    INC NUM_IMAGENES

    CALL DIBUJAR_CORAZON

    JMP CICLO_EDITOR


; =================================================
; DIBUJAR CORAZON
;
; CURSORX y CURSORY representan la esquina
; superior izquierda.
; =================================================

DIBUJAR_CORAZON PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; Rojo claro
    MOV BL, 0CH

    ; FILA 1 - XX XX
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

    ADD DL, 3

    MOV AH, 02H
    MOV BH, 00H
    INT 10H

    MOV AL, 0DBH
    MOV AH, 09H
    MOV BH, 00H
    MOV CX, 2
    INT 10H

    ; FILA 2 - XXXXXXX
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

    ; FILA 3 - XXXXXXX
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

    ; FILA 4 - XXXXX
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

    ; FILA 5 - XXX
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

    ; Flor de 7 x 5
    ; Verificar limite horizontal
    CMP CURSORX, 73
    JBE FLOR_REVISAR_Y

    JMP CICLO_EDITOR


FLOR_REVISAR_Y:

    ; Verificar limite vertical
    CMP CURSORY, 20
    JBE FLOR_REVISAR_CANTIDAD

    JMP CICLO_EDITOR


FLOR_REVISAR_CANTIDAD:

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

    ; Petalos rosados
    MOV BL, 0DH

    ; FILA 1 - X X
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

    ; FILA 2 - XXXXX
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

    ; FILA 3 - XXX
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

    ; Tallo verde
    MOV BL, 0AH

    ; FILA 4
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

    ; FILA 5 - hojas
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
;
; Preserva CURSORX y CURSORY.
; De esta forma las imagenes siempre quedan
; por encima del texto sin mover el cursor real.
; =================================================

REDIBUJAR_IMAGENES PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    ; Guardar posicion real del cursor
    MOV AL, CURSORX
    MOV AH, CURSORY
    PUSH AX

    XOR SI, SI

    XOR CX, CX
    MOV CL, NUM_IMAGENES

    CMP CX, 0
    JE REDIBUJAR_IMAGENES_RESTAURAR


REDIBUJAR_IMAGEN_LOOP:

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


REDIBUJAR_SIGUIENTE_IMAGEN:

    INC SI
    LOOP REDIBUJAR_IMAGEN_LOOP


REDIBUJAR_IMAGENES_RESTAURAR:

    ; Recuperar posicion real del cursor
    POP AX

    MOV CURSORX, AL
    MOV CURSORY, AH

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

    ; Cursor para entrada
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 6
    MOV DL, 31
    INT 10H

    MOV LARGO_BUSCAR, 0

    LEA DI, BUSCAR_TEXTO
    CALL LEER_CADENA

    MOV AX, CX
    MOV LARGO_BUSCAR, AL

    ; Texto de reemplazo
    MOV BH, 9
    MOV BL, 15
    LEA DX, TXT_REEMPLAZAR
    CALL MOSTRAR_TEXTO

    ; Cursor para entrada
    MOV AH, 02H
    MOV BH, 00H
    MOV DH, 9
    MOV DL, 32
    INT 10H

    MOV LARGO_REEMPLAZAR, 0

    LEA DI, REEMPLAZAR_TEXTO
    CALL LEER_CADENA

    MOV AX, CX
    MOV LARGO_REEMPLAZAR, AL

    ; Realizar reemplazo
    CALL BUSCAR_REEMPLAZAR

    ; Regresar al documento
    JMP REDIBUJAR_EDITOR


; =================================================
; LEER CADENA
;
; Entrada:
; DI = direccion del buffer
;
; Salida:
; CX = cantidad de caracteres
;
; ENTER termina la entrada.
; Maximo 20 caracteres.
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

    ; Numeros
    CMP AL, '0'
    JB LEER_REVISAR_MAYUS

    CMP AL, '9'
    JBE LEER_GUARDAR


LEER_REVISAR_MAYUS:

    ; Mayusculas
    CMP AL, 'A'
    JB LEER_REVISAR_MINUS

    CMP AL, 'Z'
    JBE LEER_GUARDAR


LEER_REVISAR_MINUS:

    ; Minusculas
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

    ; Compatibilidad con DOSBox usado
    CMP AL, '>'
    JNE LEER_CADENA_TECLA

    MOV AL, ':'


LEER_GUARDAR:

    ; Guardar caracter
    MOV [DI], AL
    INC DI
    INC CX

    ; Mostrar caracter
    MOV AH, 0EH
    MOV BH, 00H
    INT 10H

    JMP LEER_CADENA_TECLA


LEER_CADENA_BACKSPACE:

    CMP CX, 0
    JE LEER_CADENA_TECLA

    DEC DI
    DEC CX

    MOV BYTE PTR [DI], 0

    ; Retroceder
    MOV AH, 0EH
    MOV AL, 08H
    INT 10H

    ; Borrar caracter visualmente
    MOV AL, ' '
    INT 10H

    ; Volver a retroceder
    MOV AL, 08H
    INT 10H

    JMP LEER_CADENA_TECLA


LEER_CADENA_FIN:

    ; Terminador
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
; BUFFER_TEXTO.
;
; Las cadenas deben tener la misma longitud.
; =================================================

BUSCAR_REEMPLAZAR PROC NEAR

    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    PUSH BP

    ; No buscar una cadena vacia
    CMP LARGO_BUSCAR, 0
    JNE BR_REVISAR_LARGOS

    JMP BR_FIN


BR_REVISAR_LARGOS:

    ; Las cadenas deben tener el mismo largo
    MOV AL, LARGO_BUSCAR
    CMP AL, LARGO_REEMPLAZAR
    JE BR_INICIAR

    JMP BR_FIN


BR_INICIAR:

    XOR SI, SI


BR_SIGUIENTE_POSICION:

    ; Verificar que todavia quepa la palabra
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

    LEA DI, BUSCAR_TEXTO

    XOR CX, CX
    MOV CL, LARGO_BUSCAR


BR_COMPARAR_LOOP:

    MOV AL, BUFFER_TEXTO[SI]

    CMP AL, [DI]
    JNE BR_NO_COINCIDE

    INC SI
    INC DI

    LOOP BR_COMPARAR_LOOP

    JMP BR_REEMPLAZAR


BR_NO_COINCIDE:

    MOV SI, BP
    INC SI

    JMP BR_SIGUIENTE_POSICION


BR_REEMPLAZAR:

    ; Volver al inicio de la coincidencia
    MOV SI, BP

    LEA DI, REEMPLAZAR_TEXTO

    XOR CX, CX
    MOV CL, LARGO_REEMPLAZAR


BR_REEMPLAZAR_LOOP:

    MOV AL, [DI]
    MOV BUFFER_TEXTO[SI], AL

    INC SI
    INC DI

    LOOP BR_REEMPLAZAR_LOOP

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
; ALT + S - GUARDAR Y SALIR
; =================================================

GUARDAR_SALIR:

    ; -------------------------------------------------
    ; PENDIENTE DE INTEGRACION CON PERSONA A
    ;
    ; Informacion disponible:
    ;
    ; BUFFER_TEXTO
    ; BUFFER_COLOR
    ;
    ; NUM_IMAGENES
    ; IMAGEN_TIPO
    ; IMAGEN_X
    ; IMAGEN_Y
    ;
    ; Persona A conectara aqui el procedimiento
    ; encargado de guardar el archivo.
    ;
    ; Por ahora Alt+S termina el programa.
    ; -------------------------------------------------

    JMP FIN_PROGRAMA


; =================================================
; FIN DEL PROGRAMA
; =================================================

FIN_PROGRAMA:

    ; Regresar a modo texto
    MOV AX, 0003H
    INT 10H

    ; Terminar programa
    MOV AX, 4C00H
    INT 21H


MAIN ENDP

END MAIN