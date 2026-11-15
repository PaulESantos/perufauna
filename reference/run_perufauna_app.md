# Abrir la aplicación interactiva de perufauna

Consulta nombres científicos en cinco vistas: integrada, aves,
mamíferos, CITES y categorías nacionales de amenaza. La entrada puede
pegarse o importarse desde TXT, CSV, TSV, XLS o XLSX. Las búsquedas se
ejecutan en un proceso en segundo plano (con soporte para ejecución
síncrona) y los resultados se pueden descargar en CSV o XLSX.

## Usage

``` r
run_perufauna_app(
  host = "127.0.0.1",
  port = NULL,
  launch.browser = interactive(),
  max_request_size = 20 * 1024^2,
  options = list()
)

pf_app(
  host = "127.0.0.1",
  port = NULL,
  launch.browser = interactive(),
  max_request_size = 20 * 1024^2,
  options = list()
)

perufauna_app(options = list())
```

## Arguments

- host:

  Interfaz de red para Shiny. Por defecto, solo el equipo local
  (`"127.0.0.1"`).

- port:

  Puerto. `NULL` permite que Shiny elija uno libre.

- launch.browser:

  Abrir el navegador al iniciar la aplicación.

- max_request_size:

  Tamaño máximo de carga de archivos en bytes. Por defecto, 20 MB.

- options:

  Lista de opciones pasadas a
  [`shiny::shinyApp`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

## Value

Devuelve de forma invisible el resultado de
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html). En
`perufauna_app()`, devuelve el objeto `shinyApp`.
