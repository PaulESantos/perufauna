# Uso Integrado de pf_match() y pf_status()

## 1. Introducción y Motivación

En estudios de biodiversidad, consultoría ambiental (Líneas Base para
EIA, DIA, PMA), peritajes forenses de vida silvestre y proyectos de
conservación en el Perú, los profesionales enfrentan frecuentemente la
necesidad de contrastar listados biológicos de campo frente a múltiples
fuentes oficiales independientes:

1.  **Aves:** Lista patrón de las aves del Perú de la Unión de
    Ornitólogos del Perú (`avesperu` / UNOP).
2.  **Mamíferos:** Checklist actualizado y validado de mamíferos del
    Perú (`perumammals` / Pacheco et al., 2021).
3.  **Comercio Internacional (CITES):** Apéndices I, II y III del
    Ministerio del Ambiente (`citesperu` / MINAM).
4.  **Categorización Nacional de Amenaza:** Especies amenazadas y
    protegidas legalmente según el Decreto Supremo N° 004-2014-MINAGRI y
    el Libro Rojo de SERFOR (`perufaunads004`).

Tradicionalmente, realizar esta verificación demandaba consultar cada
base de datos por separado, cruzar identificadores manualmente y
conciliar nomenclaturas discrepantes.

El metapaquete **`perufauna`** unifica este ecosistema, y provee dos
funciones principales de consulta cruzada: \*
**[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)**:
Reconciliación profunda y multidimensional con 10 variables
estructuradas por taxón. \*
**[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)**:
Resumen ejecutivo y formateado de 6 columnas, ideal para reportes
técnicos, tablas de evaluación y anexos de impacto ambiental.

------------------------------------------------------------------------

## 2. Configuración del Entorno

Al cargar `perufauna`, el metapaquete orquesta y adjunta automáticamente
los paquetes miembros del ecosistema sin conflictos:

``` r

library(perufauna)
```

Para verificar las versiones instaladas y el estado de los paquetes
centrales, puedes consultar
[`perufauna_sitrep()`](https://paulesantos.github.io/perufauna/reference/perufauna_sitrep.md):

``` r

perufauna_sitrep()
#> ── R Environment ───────────────────────────────────────────────────────────────
#> • R: 4.6.1
#> • perufauna: 0.1.0.9000
#> ── Core Biodiversity Packages ──────────────────────────────────────────────────
#> • avesperu         (v0.1.1)
#> • perumammals      (v0.0.0.2)
#> • citesperu        (v0.1.0)
#> • perufaunads004   (v0.1.0)
```

------------------------------------------------------------------------

## 3. Reconciliación Exhaustiva con `pf_match()`

[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
toma un vector de nombres científicos (o un `data.frame`) y ejecuta de
forma transparente una consulta simultánea a través de los backbones de
aves, mamíferos, CITES y fauna amenazada.

### Consulta con un vector de especies representativas

Evaluemos un conjunto diverso de fauna que incluye aves, mamíferos,
especies amenazadas, endémicas y un taxón foráneo:

``` r

especies <- c(
  "Panthera onca",        # Mamífero, CITES I, D.S. 004: NT
  "Vultur gryphus",       # Ave, CITES I, D.S. 004: EN
  "Tremarctos ornatus",   # Mamífero, CITES I, D.S. 004: VU
  "Lagothrix flavicauda", # Primate endémico, CITES I, D.S. 004: CR
  "Homo sapiens"          # Especie foránea a los checklists nacionales
)

resultado_match <- pf_match(especies)
resultado_match
#> # A tibble: 5 × 10
#>   submitted_name       accepted_name  taxonomic_group in_peru in_unop in_pacheco
#>   <chr>                <chr>          <chr>           <lgl>   <chr>   <lgl>     
#> 1 Panthera onca        Panthera onca  Mammalia        TRUE    NA      TRUE      
#> 2 Vultur gryphus       Vultur gryphus Aves            TRUE    Reside… FALSE     
#> 3 Tremarctos ornatus   Tremarctos or… Mammalia        TRUE    NA      TRUE      
#> 4 Lagothrix flavicauda Lagothrix fla… Mammalia        TRUE    NA      TRUE      
#> 5 Homo sapiens         Homo sapiens   NA              FALSE   NA      FALSE     
#> # ℹ 4 more variables: cites_appendix <chr>, ds004_category <chr>,
#> #   is_threatened <lgl>, is_endemic <lgl>
```

### Estructura de las variables devueltas por `pf_match()`

La salida de
[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
es un `tibble` consistente de 10 columnas:

| Columna | Tipo | Descripción |
|:---|:---|:---|
| `submitted_name` | `character` | Nombre científico tal como fue ingresado por el usuario. |
| `accepted_name` | `character` | Nombre binomial validado y aceptado según el estándar taxonómico. |
| `taxonomic_group` | `character` | Clase o grupo biológico mayor (`"Aves"`, `"Mammalia"`, etc.). |
| `in_peru` | `logical` | `TRUE` si la especie cuenta con presencia confirmada en el Perú. |
| `in_unop` | `character` | Estatus en el checklist UNOP (`"Residente"`, `"Endémico"`, `"Migratorio"`, etc.). |
| `in_pacheco` | `logical` | `TRUE` si figura en el checklist de mamíferos de Pacheco et al. (2021). |
| `cites_appendix` | `character` | Apéndice CITES asignado (`"I"`, `"II"`, `"III"` o `NA`). |
| `ds004_category` | `character` | Categoría legal de amenaza nacional (`"CR"`, `"EN"`, `"VU"`, `"NT"` o `NA`). |
| `is_threatened` | `logical` | `TRUE` si está legalmente categorizada como amenazada. |
| `is_endemic` | `logical` | `TRUE` si la especie es endémica del territorio peruano. |

------------------------------------------------------------------------

## 4. Tolerancia a Errores Tipográficos (*Fuzzy Matching*)

Los inventarios de campo a menudo contienen erratas de digitación.
[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
incluye el argumento `max_distance` (por defecto `0.1`), permitiendo
concordancias aproximadas:

``` r

especies_con_error <- c(
  "Pantera onca",        # Falta 'h'
  "Tremarctos ornatus",  # Correcto
  "Vultur griphus"       # 'i' en vez de 'y'
)

pf_match(especies_con_error, max_distance = 0.15)
#> # A tibble: 3 × 10
#>   submitted_name     accepted_name    taxonomic_group in_peru in_unop in_pacheco
#>   <chr>              <chr>            <chr>           <lgl>   <chr>   <lgl>     
#> 1 Pantera onca       Panthera onca    Mammalia        TRUE    NA      TRUE      
#> 2 Tremarctos ornatus Tremarctos orna… Mammalia        TRUE    NA      TRUE      
#> 3 Vultur griphus     Vultur gryphus   Aves            TRUE    Reside… FALSE     
#> # ℹ 4 more variables: cites_appendix <chr>, ds004_category <chr>,
#> #   is_threatened <lgl>, is_endemic <lgl>
```

------------------------------------------------------------------------

## 5. Entrada Directa desde un `data.frame` de Inventario

En flujos de trabajo reales con datos tabulares (ej. registros en hojas
de cálculo importadas),
[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
detecta automáticamente la columna que contiene los nombres científicos
(buscando nombres estándar como `scientific_name`, `species`,
`nombre_cientifico`, `name` o `taxon`):

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
resultado_inventario <- pf_match(inventario)
resultado_inventario[, c("submitted_name", "taxonomic_group", "cites_appendix", "ds004_category")]
#> # A tibble: 4 × 4
#>   submitted_name       taxonomic_group cites_appendix ds004_category
#>   <chr>                <chr>           <chr>          <chr>         
#> 1 Panthera onca        Mammalia        I              NT            
#> 2 Vultur gryphus       Aves            I              EN            
#> 3 Tremarctos ornatus   Mammalia        I              VU            
#> 4 Lagothrix flavicauda Mammalia        I              CR
```

------------------------------------------------------------------------

## 6. Resumen Rápido para Informes con `pf_status()`

Cuando se redactan capítulos de biodiversidad, matrices de impacto
ambiental o fichas técnicas para expedientes, se suele requerir una
tabla ejecutiva y sintética que concentre el estatus de residencia,
CITES y Decreto Supremo.

La función
[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)
simplifica esto a un formato atomizado de 6 columnas:

``` r

status_resumen <- pf_status(especies)
status_resumen
#> # A tibble: 5 × 6
#>   submitted_name  accepted_name taxonomic_group occurrence_status cites_appendix
#>   <chr>           <chr>         <chr>           <chr>             <chr>         
#> 1 Panthera onca   Panthera onca Mammalia        Residente         I             
#> 2 Vultur gryphus  Vultur gryph… Aves            Residente         I             
#> 3 Tremarctos orn… Tremarctos o… Mammalia        Residente         I             
#> 4 Lagothrix flav… Lagothrix fl… Mammalia        Endémico          I             
#> 5 Homo sapiens    Homo sapiens  NA              NA                NA            
#> # ℹ 1 more variable: ds004_category <chr>
```

### Columnas generadas por `pf_status()`:

1.  `submitted_name`: Nombre original consultado.
2.  `accepted_name`: Nombre binomial aceptado.
3.  `taxonomic_group`: Grupo taxonómico (`"Mammalia"`, `"Aves"`, etc.).
4.  `occurrence_status`: Estatus de permanencia (`"Residente"`,
    `"Endémico"`, `"Divagante"`, `"Migratorio"`, etc.).
5.  `cites_appendix`: Apéndice regulatorio CITES (`"I"`, `"II"`,
    `"III"`).
6.  `ds004_category`: Categoría nacional de amenaza (`"CR"`, `"EN"`,
    `"VU"`, `"NT"`).

------------------------------------------------------------------------

## 7. Análisis y Filtrado de Prioridades de Conservación

Al estar integradas en estructuras `tibble`, las salidas de
[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)
y
[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)
se integran naturalmente con operaciones de filtrado y resumen:

``` r

# Filtrar especies amenazadas según la normativa nacional (D.S. 004-2014-MINAGRI)
amenazadas <- resultado_match[resultado_match$is_threatened, ]
amenazadas[, c("accepted_name", "taxonomic_group", "ds004_category")]
#> # A tibble: 4 × 3
#>   accepted_name        taxonomic_group ds004_category
#>   <chr>                <chr>           <chr>         
#> 1 Panthera onca        Mammalia        NT            
#> 2 Vultur gryphus       Aves            EN            
#> 3 Tremarctos ornatus   Mammalia        VU            
#> 4 Lagothrix flavicauda Mammalia        CR

# Filtrar especies incluidas en el Apéndice I de CITES (máxima restricción comercial)
cites_i <- resultado_match[!is.na(resultado_match$cites_appendix) & resultado_match$cites_appendix == "I", ]
cites_i[, c("accepted_name", "cites_appendix")]
#> # A tibble: 4 × 2
#>   accepted_name        cites_appendix
#>   <chr>                <chr>         
#> 1 Panthera onca        I             
#> 2 Vultur gryphus       I             
#> 3 Tremarctos ornatus   I             
#> 4 Lagothrix flavicauda I

# Filtrar especies endémicas del Perú
endemicas <- resultado_match[resultado_match$is_endemic, ]
endemicas[, c("accepted_name", "taxonomic_group", "is_endemic")]
#> # A tibble: 1 × 3
#>   accepted_name        taxonomic_group is_endemic
#>   <chr>                <chr>           <lgl>     
#> 1 Lagothrix flavicauda Mammalia        TRUE
```

------------------------------------------------------------------------

## 8. Resumen y Buenas Prácticas

- Utiliza
  **[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)**
  cuando necesites trazabilidad completa por base de datos (UNOP,
  Pacheco, CITES, D.S. 004) o requieras evaluar banderas booleanas
  (`in_peru`, `is_threatened`, `is_endemic`).
- Utiliza
  **[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)**
  para elaborar matrices ejecutivas, cuadros de anexos en informes
  ambientales o resúmenes rápidos para presentaciones.
- Mantén tus paquetes actualizados ejecutando
  [`perufauna_sitrep()`](https://paulesantos.github.io/perufauna/reference/perufauna_sitrep.md)
  para asegurar que las listas de especies reflejen las últimas
  adiciones normativas y taxonómicas.
