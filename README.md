# Proyecto 1 - Editor de Texto en Assembly x8086

## Descripción

Este proyecto consiste en un editor de texto desarrollado en lenguaje Assembly para arquitectura x8086.

El programa permite crear, abrir, editar y guardar documentos desde una interfaz desarrollada completamente en modo texto. Además de las funciones básicas de edición, incluye diferentes atajos de teclado para modificar la apariencia del documento, navegar dentro del área de edición, buscar y reemplazar texto e insertar imágenes creadas con caracteres y colores.

El proyecto fue desarrollado utilizando TASM y ejecutado en DOSBox.


## Funcionalidades

### Menú principal

El programa cuenta con un menú principal desde el cual el usuario puede:

- Crear un nuevo archivo.
- Abrir un archivo existente.
- Ingresar al editor.
- Guardar los cambios realizados.
- Salir del programa.


### Editor de texto

El área de edición utiliza una pantalla de 80 columnas y 25 filas.

Las filas 2 a 24 son utilizadas como área editable, dando un total de:

`80 x 23 = 1840 caracteres`

El editor permite ingresar:

- Letras mayúsculas.
- Letras minúsculas.
- Números.
- Coma `,`
- Punto `.`
- Dos puntos `:`

Los caracteres aparecen inmediatamente en pantalla y se almacenan internamente para poder reconstruir el documento cuando sea necesario.


### Movimiento del cursor

El usuario puede desplazarse dentro del documento utilizando las cuatro flechas del teclado:

- Flecha arriba.
- Flecha abajo.
- Flecha izquierda.
- Flecha derecha.

El movimiento está limitado al área editable para evitar que el cursor salga de los límites establecidos.


## Atajos de teclado

El editor incluye los siguientes atajos:

| Atajo | Función |
|------|---------|
| `Alt + C` | Centrar el cursor en el renglón actual |
| `Alt + U` | Ir al primer renglón |
| `Alt + D` | Ir al último renglón |
| `Alt + M` | Cambiar el color de la letra |
| `Alt + N` | Cambiar el color de fondo |
| `Alt + I` | Insertar imagen 1 - corazón |
| `Alt + J` | Insertar imagen 2 - flor |
| `Alt + B` | Buscar y reemplazar texto |
| `Alt + H` | Mostrar la pantalla de ayuda |
| `Alt + Z` | Regresar al menú principal |
| `Alt + S` | Guardar el documento y salir |


## Colores de texto

Con `Alt + M` se puede cambiar entre tres colores de texto:

1. Blanco.
2. Verde.
3. Celeste.

El cambio de color únicamente afecta a los caracteres escritos después de realizar el cambio. Los caracteres escritos anteriormente conservan su color original.


## Colores de fondo

Con `Alt + N` se puede cambiar entre tres colores de fondo:

1. Negro.
2. Azul.
3. Rojo.

Al igual que con el color del texto, el cambio únicamente afecta a los caracteres escritos posteriormente.


## Imágenes

El editor permite insertar dos imágenes utilizando caracteres en modo texto y atributos de color.

### Corazón

Se inserta utilizando:

`Alt + I`

El corazón utiliza bloques de caracteres y color rojo claro.


### Flor

Se inserta utilizando:

`Alt + J`

La flor utiliza bloques de caracteres con pétalos rosados y tallo verde.


Las imágenes almacenan su tipo y posición dentro del documento. Al redibujar la pantalla, las imágenes se vuelven a mostrar después del texto para garantizar que permanezcan visualmente encima de este.


## Buscar y reemplazar

El editor incluye una herramienta de búsqueda y reemplazo accesible mediante:

`Alt + B`

El usuario ingresa:

1. El texto que desea buscar.
2. El texto por el cual desea reemplazarlo.

El programa recorre el contenido almacenado en memoria y reemplaza las coincidencias encontradas.

Para esta implementación, el texto buscado y el texto de reemplazo deben tener la misma longitud.


## Pantalla de ayuda

Al presionar:

`Alt + H`

se muestra una pantalla con todos los atajos disponibles dentro del editor.

Al presionar cualquier tecla, el usuario regresa al documento y el contenido se reconstruye utilizando la información almacenada en memoria.


## Estructura interna del editor

El documento utiliza diferentes estructuras para conservar su contenido y formato.

### Texto

`BUFFER_TEXTO`

Almacena los 1840 caracteres correspondientes al área editable.


### Formato

`BUFFER_COLOR`

Almacena el atributo de cada posición del documento, permitiendo conservar la combinación de color de texto y color de fondo.


### Imágenes

Las imágenes utilizan:

- `NUM_IMAGENES`
- `IMAGEN_TIPO`
- `IMAGEN_X`
- `IMAGEN_Y`

Estas estructuras permiten conocer cuántas imágenes existen, qué tipo de imagen corresponde a cada una y en qué posición debe mostrarse.


## Guardado y apertura de archivos

El programa permite guardar la información necesaria para reconstruir posteriormente el documento.

Al guardar se conserva la información relacionada con:

- Contenido del texto.
- Formato de los caracteres.
- Cantidad de imágenes.
- Tipo de cada imagen.
- Posición de cada imagen.

Al abrir un documento previamente guardado, esta información es cargada nuevamente y utilizada para reconstruir el contenido dentro del editor.


## Tecnologías utilizadas

- Assembly x8086
- TASM
- TLINK
- DOSBox
- BIOS Interrupts
- DOS Interrupts


## Interrupciones utilizadas

Durante el desarrollo se utilizaron principalmente interrupciones de BIOS y DOS.

### BIOS

`INT 10H`

Utilizada para operaciones relacionadas con video, entre ellas:

- Cambiar el modo de video.
- Posicionar el cursor.
- Mostrar caracteres con atributos de color.


`INT 16H`

Utilizada para leer entradas del teclado y obtener tanto el código ASCII como el scan code de las teclas.


### DOS

`INT 21H`

Utilizada para diferentes servicios de DOS, incluyendo manejo de texto, archivos y finalización del programa.


## Organización del proyecto

El desarrollo fue dividido entre dos integrantes.

### Persona A

Responsable principalmente de:

- Menú principal.
- Creación de archivos.
- Apertura de archivos.
- Guardado de archivos.
- Formato utilizado para almacenar los documentos.
- Integración del manejo de archivos con el editor.


### Persona B

Responsable principalmente de:

- Pantalla de edición.
- Entrada de caracteres.
- Movimiento del cursor.
- Atajos de teclado.
- Colores de texto.
- Colores de fondo.
- Pantalla de ayuda.
- Buscar y reemplazar.
- Inserción de imágenes.
- Redibujado del contenido e imágenes.


### Integración

Finalmente se integraron ambos módulos para permitir el flujo completo:

`Menú -> Crear/Abrir archivo -> Editor -> Guardar -> Menú/Salir`

La integración permite conservar tanto el contenido del documento como su formato e imágenes.


## Compilación y ejecución

Para ensamblar el programa utilizando TASM:

```bash
tasm ARCHIVO.asm
```

Para generar el ejecutable:

```bash
tlink ARCHIVO.obj
```

Finalmente, para ejecutar:

```bash
ARCHIVO.exe
```

Estos comandos deben ejecutarse dentro del entorno configurado en DOSBox.


## Autores

Proyecto desarrollado para el curso de **Arquitectura y Diseño de Computadoras**.

Universidad Francisco Marroquín.