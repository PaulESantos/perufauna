# perufauna

**perufauna** es un metapaquete de R que reúne herramientas para
consultar y cruzar información sobre la fauna del Perú. Permite trabajar
con nombres científicos, listas de aves y mamíferos, apéndices CITES y
categorías nacionales de amenaza desde una misma interfaz.

El paquete conserva el acceso a las funciones de sus cuatro dependencias
y ofrece dos funciones de consulta integrada:
[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
para obtener resultados detallados y
[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)
para generar un resumen con campos de revisión manual.

### Aplicación interactiva

Con **perufauna** instalado, añade las dependencias opcionales y abre la
app:

``` r

install.packages(c("shiny", "DT", "callr", "later"))
# Opcional: lectura y descarga de archivos de Excel
install.packages(c("readxl", "writexl"))

# Iniciar la aplicación interactiva (alias canónico: pf_app())
perufauna::run_perufauna_app()
# o bien:
# perufauna::pf_app()
```

También puedes ejecutar la app directamente desde el archivo `app.R` en
la raíz del repositorio, o mediante:

``` r

shiny::runApp(system.file("app", package = "perufauna"))
```

La app ofrece una consulta integrada y cuatro vistas especializadas:
aves, mamíferos, CITES y amenaza nacional. Puedes pegar nombres o subir
un archivo TXT, CSV (con detección automática de `,` o `;`), TSV, XLS o
XLSX; seleccionar la columna de nombres; revisar los resultados con
tablas interactivas en español y descargarlos. Los archivos de Excel
requieren `readxl` para importar y `writexl` para exportar. Cada
consulta admite hasta 10 000 nombres y se ejecuta en un proceso en
segundo plano (con respaldo síncrono automático si el entorno lo
requiere) que puedes cancelar.

------------------------------------------------------------------------

## Paquetes integrados

Al ejecutar
[`library(perufauna)`](https://github.com/PaulESantos/perufauna), se
adjuntan estos cuatro paquetes:

| Paquete | Prefijo | Información | Referencia |
|:---|:--:|:---|:---|
| **[avesperu](https://github.com/PaulESantos/avesperu)** | `ap_` | Aves del Perú | Lista de la Unión de Ornitólogos del Perú (UNOP) |
| **[perumammals](https://github.com/PaulESantos/perumammals)** | `pm_` | Mamíferos del Perú | Pacheco et al. (2021) |
| **[citesperu](https://github.com/PaulESantos/citesperu)** | `cites_` | Apéndices CITES | Listado CITES del MINAM |
| **[perufaunads004](https://github.com/PaulESantos/perufaunads004)** | `ds004_` | Categorías nacionales de amenaza | D.S. 004-2014-MINAGRI y Libro Rojo de SERFOR |

Las funciones de cada paquete se pueden llamar con su espacio de
nombres, por ejemplo,
[`avesperu::search_avesperu()`](https://paulesantos.github.io/avesperu/reference/search_avesperu.html).
Los prefijos de la tabla ayudan a reconocer sus funciones;
[`perufauna_conflicts()`](https://paulesantos.github.io/perufauna/reference/perufauna_conflicts.md)
permite revisar posibles conflictos entre paquetes adjuntos.

------------------------------------------------------------------------

## Instalación

Instala **perufauna** y sus dependencias desde GitHub con una de estas
opciones:

``` r

# Instalar usando pak (recomendado)
# install.packages("pak")
pak::pak("PaulESantos/perufauna")

# O alternativamente con remotes
# install.packages("remotes")
remotes::install_github("PaulESantos/perufauna")
```

------------------------------------------------------------------------

## Inicio rápido

### Cargar los paquetes

Carga los cuatro paquetes integrados con una instrucción:

``` r

library(perufauna)
```

El mensaje de inicio muestra los paquetes adjuntados y sus versiones. Su
contenido depende de las versiones instaladas y de los paquetes ya
cargados en la sesión.

------------------------------------------------------------------------

## Consultas principales

### 1. Cruzar nombres y categorías con `pf_match()`

[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
consulta las cuatro fuentes para cada nombre científico y devuelve una
fila por entrada. El resultado reúne el nombre encontrado, el grupo
taxonómico, la presencia en las listas consultadas y las categorías
CITES y nacionales disponibles:

``` r

especies <- c(
  "Panthera onca",        # Mamífero: CITES I, D.S. 004: NT
  "Vultur gryphus",       # Ave: CITES I, D.S. 004: EN
  "Tremarctos ornatus",   # Mamífero: CITES I, D.S. 004: VU
  "Lagothrix flavicauda", # Primate endémico: CITES I, D.S. 004: CR
  "Homo sapiens"          # Especie no registrada en listas de fauna peruana
)

diagnostico <- pf_match(especies)
diagnostico
#> # A tibble: 5 × 12
#>   submitted_name       accepted_name  taxonomic_group in_peru in_unop in_pacheco
#>   <chr>                <chr>          <chr>           <lgl>   <chr>   <lgl>
#> 1 Panthera onca        Panthera onca  Mammalia        TRUE    <NA>    TRUE
#> 2 Vultur gryphus       Vultur gryphus Aves            TRUE    Reside… FALSE
#> 3 Tremarctos ornatus   Tremarctos or… Mammalia        TRUE    <NA>    TRUE
#> 4 Lagothrix flavicauda Lagothrix fla… Mammalia        TRUE    <NA>    TRUE
#> 5 Homo sapiens         Homo sapiens   <NA>            FALSE   <NA>    FALSE
#> # ℹ 6 more variables: cites_appendix <chr>, ds004_category <chr>,
#> #   is_threatened <lgl>, is_endemic <lgl>, review_flag <lgl>,
#> #   review_observation <chr>
```

#### Columnas de `pf_match()`

[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
devuelve un `tibble` con doce columnas, incluidas las señales de
revisión:

1.  `submitted_name`: Nombre original ingresado por el usuario.
2.  `accepted_name`: Nombre devuelto por las fuentes consultadas. Si no
    hay coincidencia, conserva el nombre ingresado; una corrección
    aproximada requiere validación manual.
3.  `taxonomic_group`: Clase o grupo mayor asignado (`"Aves"`,
    `"Mammalia"`, etc.).
4.  `in_peru`: `TRUE` si el nombre figura en las listas de aves o
    mamíferos, o en las referencias nacionales de amenaza. Una
    coincidencia solo en CITES no activa esta columna.
5.  `in_unop`: Estatus en el checklist UNOP (`"Residente"`,
    `"Endémico"`, `"Migratorio"`, etc.).
6.  `in_pacheco`: `TRUE` si la especie está listada en el checklist de
    mamíferos de Pacheco et al. (2021).
7.  `cites_appendix`: Apéndice CITES encontrado o sugerido (`"I"`,
    `"II"`, `"III"` o `NA`). Consulta `review_observation` antes de
    interpretarlo como identificación confirmada.
8.  `ds004_category`: Categoría D.S. 004 o, si falta, categoría del
    Libro Rojo SERFOR.
9.  `is_threatened`: `TRUE` si figura en el D.S. 004 o en el Libro Rojo.
    Esta columna agrupa ambas fuentes y no distingue por sí sola la
    protección legal.
10. `is_endemic`: `TRUE` si las listas de aves o mamíferos indican
    endemismo en el Perú.
11. `review_flag`: `TRUE` si alguna coincidencia aproximada necesita
    comprobación manual.
12. `review_observation`: Indica «Necesidad de revisión manual» para
    esas filas.

------------------------------------------------------------------------

### 2. Obtener un resumen con `pf_status()`

[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)
utiliza
[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
y devuelve los datos principales de cada nombre junto con las señales de
revisión:

``` r

pf_status(especies)
#> # A tibble: 5 × 8
#>   submitted_name  accepted_name taxonomic_group occurrence_status cites_appendix
#>   <chr>           <chr>         <chr>           <chr>             <chr>
#> 1 Panthera onca   Panthera onca Mammalia        Registrado en Pe… I
#> 2 Vultur gryphus  Vultur gryph… Aves            Residente         I
#> 3 Tremarctos orn… Tremarctos o… Mammalia        Registrado en Pe… I
#> 4 Lagothrix flav… Lagothrix fl… Mammalia        Endémico          I
#> 5 Homo sapiens    Homo sapiens  <NA>            <NA>              <NA>
#> # ℹ 3 more variables: ds004_category <chr>, review_observation <chr>,
#> #   review_flag <lgl>
```

El resultado incluye `submitted_name`, `accepted_name`,
`taxonomic_group`, `occurrence_status`, `cites_appendix`,
`ds004_category`, `review_observation` y `review_flag`. Para mamíferos
registrados, `occurrence_status` indica `"Endémico"` cuando corresponde
y `"Registrado en Perú"` en los demás casos; para aves usa el estado
devuelto por la lista de referencia.

------------------------------------------------------------------------

### 3. Ajustar la coincidencia aproximada

`max_distance` controla la distancia permitida por `avesperu`: los
valores menores que 1 son relativos a la longitud del nombre (valor
predeterminado: `0.15`). `max_edit_distance` fija el número máximo de
ediciones para CITES y D.S. 004 (valor predeterminado: `2`). La búsqueda
de mamíferos utiliza las reglas de `perumammals`. Las coincidencias
aproximadas se marcan en `review_observation` y `review_flag` para
evaluación manual. La columna `cites_appendix` muestra el apéndice
sugerido, incluso cuando la fila requiere revisión:

``` r

especies_con_error <- c(
  "Pantera onca",        # Falta la 'h'
  "Tremarctos ornatus",  # Nombre correcto
  "Vultur griphus"       # 'i' en lugar de 'y'
)

pf_match(especies_con_error, max_distance = 0.15, max_edit_distance = 2)
#> # A tibble: 3 × 12
#>   submitted_name     accepted_name    taxonomic_group in_peru in_unop in_pacheco
#>   <chr>              <chr>            <chr>           <lgl>   <chr>   <lgl>
#> 1 Pantera onca       Panthera onca    Mammalia        TRUE    <NA>    TRUE
#> 2 Tremarctos ornatus Tremarctos orna… Mammalia        TRUE    <NA>    TRUE
#> 3 Vultur griphus     Vultur gryphus   Aves            TRUE    Reside… FALSE
#> # ℹ 6 more variables: cites_appendix <chr>, ds004_category <chr>,
#> #   is_threatened <lgl>, is_endemic <lgl>, review_flag <lgl>,
#> #   review_observation <chr>
```

Por ejemplo, `Vultor gryphos` puede reconciliarse con `Vultur gryphus` y
mostrar el Apéndice I como propuesta. La observación indica que el
nombre debe comprobarse en la fuente antes de usar la categoría como
dato confirmado:

``` r

pf_status(c("Vultur gryphus", "Vultor gryphos"))[
  , c("submitted_name", "accepted_name", "cites_appendix", "review_observation")
]
#> # A tibble: 2 × 4
#>   submitted_name accepted_name  cites_appendix review_observation
#>   <chr>          <chr>          <chr>          <chr>
#> 1 Vultur gryphus Vultur gryphus I              <NA>
#> 2 Vultor gryphos Vultur gryphus I              Necesidad de revisión manual
```

------------------------------------------------------------------------

### 4. Consultar una tabla de datos

[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
y
[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)
aceptan un `data.frame` o `tibble`. Reconocen columnas como
`scientific_name`, `species`, `species_name`, `nombre_cientifico`,
`name` y `taxon`, sin distinguir mayúsculas de minúsculas. Si el nombre
de la columna es otro, indícalo con `name_col`. La salida contiene las
columnas de consulta, no las demás columnas de la tabla de entrada:

``` r

inventario <- data.frame(
  id = 1:4,
  nombre_cientifico = c(
    "Panthera onca",
    "Vultur gryphus",
    "Tremarctos ornatus",
    "Lagothrix flavicauda"
  ),
  localidad = c("Tambopata", "Colca", "Chachapoyas", "Abiseo"),
  stringsAsFactors = FALSE
)

# Consulta directa pasando el dataframe
resultado <- pf_match(inventario)
resultado[, c("submitted_name", "taxonomic_group", "cites_appendix", "ds004_category")]
#> # A tibble: 4 × 4
#>   submitted_name       taxonomic_group cites_appendix ds004_category
#>   <chr>                <chr>           <chr>          <chr>
#> 1 Panthera onca        Mammalia        I              NT
#> 2 Vultur gryphus       Aves            I              EN
#> 3 Tremarctos ornatus   Mammalia        I              VU
#> 4 Lagothrix flavicauda Mammalia        I              CR
```

------------------------------------------------------------------------

### 5. Filtrar resultados

Como el resultado es un `tibble`, puedes filtrar las coincidencias por
categoría, apéndice o endemismo:

``` r

# Coincidencias sin revisión pendiente en D.S. 004 o Libro Rojo
diagnostico[diagnostico$is_threatened & !diagnostico$review_flag,
            c("accepted_name", "taxonomic_group", "ds004_category")]
#> # A tibble: 4 × 3
#>   accepted_name        taxonomic_group ds004_category
#>   <chr>                <chr>           <chr>
#> 1 Panthera onca        Mammalia        NT
#> 2 Vultur gryphus       Aves            EN
#> 3 Tremarctos ornatus   Mammalia        VU
#> 4 Lagothrix flavicauda Mammalia        CR

# Coincidencias sin revisión pendiente en el Apéndice I de CITES
diagnostico[!is.na(diagnostico$cites_appendix) & diagnostico$cites_appendix == "I" &
              !diagnostico$review_flag,
            c("accepted_name", "cites_appendix")]
#> # A tibble: 4 × 2
#>   accepted_name        cites_appendix
#>   <chr>                <chr>
#> 1 Panthera onca        I
#> 2 Vultur gryphus       I
#> 3 Tremarctos ornatus   I
#> 4 Lagothrix flavicauda I

# Especies endémicas del Perú
diagnostico[diagnostico$is_endemic, c("accepted_name", "taxonomic_group")]
#> # A tibble: 1 × 2
#>   accepted_name        taxonomic_group
#>   <chr>                <chr>
#> 1 Lagothrix flavicauda Mammalia
```

------------------------------------------------------------------------

### 6. Revisar paquetes y conflictos

Estas funciones muestran los paquetes integrados, sus versiones
instaladas y los posibles conflictos de nombres en la sesión:

``` r

# Resumen de la sesión y versiones instaladas
perufauna_sitrep()
#> ── R Environment ───────────────────────────────────────────────────────────────
#> • R: 4.6.1
#> • perufauna: 0.1.0
#> ── Core Biodiversity Packages ──────────────────────────────────────────────────
#> • avesperu         (v0.1.1)
#> • perumammals      (v0.0.0.2)
#> • citesperu        (v0.1.0)
#> • perufaunads004   (v0.1.0)

# Tabla de paquetes, instalación y versiones
perufauna_deps()
#> # A tibble: 4 × 3
#>   package        installed local_version
#>   <chr>          <lgl>     <chr>
#> 1 avesperu       TRUE      0.1.1
#> 2 perumammals    TRUE      0.0.0.2
#> 3 citesperu      TRUE      0.1.0
#> 4 perufaunads004 TRUE      0.1.0

# Conflictos entre funciones de paquetes adjuntos
perufauna_conflicts()
```

------------------------------------------------------------------------

## Cómo funciona la consulta integrada

[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
envía cada nombre a los buscadores de `avesperu`, `perumammals`,
`citesperu` y `perufaunads004`. Después combina los resultados por
posición, conservando una fila por nombre de entrada. Las coincidencias
de aves y mamíferos determinan primero el grupo taxonómico; CITES y D.S.
004 pueden completarlo cuando falta. El nombre aceptado se actualiza con
las coincidencias: la de mamíferos prevalece sobre la de aves si ambas
listas coinciden, y CITES o D.S. 004 pueden completarlo cuando aún
coincide con el nombre ingresado.

Las columnas CITES y D.S. 004 proceden de sus respectivas fuentes.
`ds004_category` usa la categoría del D.S. 004 y, si no existe, la del
Libro Rojo. Las coincidencias aproximadas requieren revisión manual
antes de interpretar una categoría como protección legal.
[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)
selecciona los campos de resumen y revisión de esta consulta y calcula
`occurrence_status`; no realiza una búsqueda independiente.

Si una búsqueda falla,
[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
informa qué paquete produjo el error. Los parámetros de distancia se
aplican a los buscadores indicados arriba y no modifican las reglas de
coincidencia de `perumammals`.

------------------------------------------------------------------------

## Citación

Para citar **perufauna**, consulta también `citation("perufauna")`. Si
utilizas datos de un paquete integrado, cita ese paquete y sus fuentes
primarias:

``` text
Santos Andrade, P. E. (2026). perufauna: Easily Load and Harmonize Peruvian Fauna
and Biodiversity Packages. R package version 0.1.0.
https://paulesantos.github.io/perufauna/
```

### Fuentes de los paquetes integrados

- **Aves del Perú:** Plenge, M. A., & Angulo, F. (2026). *Lista de las
  aves del Perú / List of the birds of Peru*. Unión de Ornitólogos del
  Perú (UNOP).
- **Mamíferos del Perú:** Pacheco, V., Graham-Angles, R., Aguilar, L.,
  et al. (2021). *Diversidad y endemismo de los mamíferos del Perú*.
  Revista Peruana de Biología, 28(especial).
- **Estatus CITES:** Ministerio del Ambiente (MINAM). *Listado Oficial
  de Especies de Fauna y Flora Silvestre en los Apéndices CITES para el
  Perú*.
- **Fauna Amenazada:** Servicio Nacional Forestal y de Fauna Silvestre
  (SERFOR) / MINAGRI. *Decreto Supremo N° 004-2014-MINAGRI y Libro Rojo
  de la Fauna Silvestre Amenazada del Perú*.

------------------------------------------------------------------------

## Documentación y enlaces

- **Documentación:** [sitio del
  paquete](https://paulesantos.github.io/perufauna/)
- **Guía de uso:** [consultas con `pf_match()` y
  `pf_status()`](https://paulesantos.github.io/perufauna/articles/uso-pf-match-pf-status.html)
- **Código y reporte de problemas:** [repositorio en
  GitHub](https://github.com/PaulESantos/perufauna)

------------------------------------------------------------------------

## Licencia

Este proyecto se distribuye bajo la licencia **MIT**. Consulta el
archivo [LICENSE](https://paulesantos.github.io/perufauna/LICENSE) para
más detalles.
