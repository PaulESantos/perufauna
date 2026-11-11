#' Abrir la aplicación interactiva de perufauna
#'
#' Consulta nombres científicos en cinco vistas: integrada, aves, mamíferos,
#' CITES y categorías nacionales de amenaza. La entrada puede pegarse o
#' importarse desde TXT, CSV, TSV, XLS o XLSX. Las búsquedas se ejecutan en un
#' proceso separado y los resultados se pueden descargar en CSV o XLSX.
#'
#' @param host Interfaz de red para Shiny. Por defecto, solo el equipo local.
#' @param port Puerto. `NULL` permite que Shiny elija uno libre.
#' @param launch.browser Abrir el navegador al iniciar la aplicación.
#' @return Devuelve de forma invisible el resultado de `shiny::runApp()`.
#' @export
run_perufauna_app <- function(host = "127.0.0.1", port = NULL,
                             launch.browser = interactive()) {
  needed <- c("shiny", "DT", "callr", "later")
  missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Instala las dependencias de la app: ", paste(missing, collapse = ", "),
         ".", call. = FALSE)
  }
  if (!isTRUE(l10n_info()[["UTF-8"]])) {
    previous_locale <- Sys.getlocale("LC_CTYPE")
    suppressWarnings(Sys.setlocale("LC_CTYPE", ""))
    on.exit(suppressWarnings(Sys.setlocale("LC_CTYPE", previous_locale)), add = TRUE)
  }
  previous_max_size <- getOption("shiny.maxRequestSize")
  options(shiny.maxRequestSize = max(20 * 1024^2, previous_max_size %||% 0))
  on.exit(options(shiny.maxRequestSize = previous_max_size), add = TRUE)
  shiny::runApp(
    shiny::shinyApp(ui = perufauna_app_ui(), server = perufauna_app_server),
    host = host, port = port, launch.browser = launch.browser
  )
}

app_module_controls <- function(id, module) {
  ns <- shiny::NS(id)
  advanced <- function(...) shiny::tags$details(
    class = "pf-advanced", shiny::tags$summary("Opciones avanzadas"), ...
  )
  switch(module,
    integrada = shiny::tagList(
      shiny::radioButtons(ns("view"), "Resultado", inline = TRUE,
                          choices = c("Resumen" = "resumen", "Detalle" = "detalle"),
                          selected = "resumen"),
      advanced(
        shiny::numericInput(ns("bird_distance"), "Distancia para aves", 0.1,
                            min = 0, step = 0.01),
        shiny::numericInput(ns("edit_distance"), "Ediciones para CITES y D.S. 004",
                            1, min = 0, step = 1)
      )
    ),
    aves = advanced(
      shiny::numericInput(ns("distance"), "Distancia máxima", 0.1,
                          min = 0, step = 0.01),
      shiny::tags$p("Usa 0 para coincidencias exactas.")
    ),
    mamiferos = shiny::tags$p(class = "pf-hint",
      "La búsqueda utiliza las reglas de coincidencia de perumammals."),
    cites = shiny::tagList(
      shiny::selectInput(ns("taxon"), "Grupo", c("Fauna" = "fauna",
                                                  "Flora" = "flora", "Ambos" = "all")),
      advanced(
        shiny::selectInput(ns("edition"), "Edición", c("Más reciente" = "latest",
          "Todas" = "all", "2023" = "2023", "2019" = "2019", "2018" = "2018")),
        shiny::numericInput(ns("distance"), "Ediciones permitidas", 1,
                            min = 0, step = 1),
        shiny::checkboxInput(ns("synonyms"), "Aceptar sinónimos", TRUE),
        shiny::checkboxInput(ns("genus"), "Permitir coincidencia por género", FALSE)
      )
    ),
    amenaza = advanced(
      shiny::selectInput(ns("group"), "Grupo taxonómico", c("Todos" = "",
        "Aves" = "Aves", "Mamíferos" = "Mamíferos", "Anfibios" = "Anfibios",
        "Reptiles" = "Reptiles", "Invertebrados" = "Invertebrados")),
      shiny::numericInput(ns("distance"), "Ediciones permitidas", 1,
                          min = 0, step = 1),
      shiny::checkboxInput(ns("fuzzy"), "Buscar nombres aproximados", TRUE),
      shiny::checkboxInput(ns("genus"), "Permitir coincidencia por género", TRUE)
    )
  )
}

app_module_ui <- function(id, module, title, description) {
  ns <- shiny::NS(id)
  shiny::div(class = "pf-module",
    shiny::div(class = "pf-module-heading",
      shiny::div(shiny::tags$span(class = "pf-eyebrow", "Consulta seleccionada"),
                 shiny::tags$h2(title)),
      shiny::tags$p(class = "pf-lead", description)
    ),
    if (identical(module, "integrada")) shiny::tags$p(class = "pf-hint",
      "La columna is_threatened incluye registros del D.S. 004 y del Libro Rojo; consulta la fuente antes de interpretarla como protección legal."),
    shiny::div(class = "pf-controls",
      app_module_controls(id, module),
      shiny::div(class = "pf-actions",
        shiny::actionButton(ns("run"), "Consultar nombres", class = "btn-primary"),
        shiny::uiOutput(ns("cancel_ui")),
        shiny::tags$span(class = "pf-status", shiny::textOutput(ns("status"), inline = TRUE))
      )
    ),
    shiny::div(id = ns("results"), class = "pf-results",
      shiny::uiOutput(ns("summary")),
      DT::DTOutput(ns("table")),
      shiny::uiOutput(ns("downloads")),
      shiny::uiOutput(ns("detail"))
    )
  )
}

perufauna_app_ui <- function() {
  shiny::fluidPage(
    title = "perufauna | Consulta de fauna",
    shiny::tags$head(
      shiny::tags$script(shiny::HTML("Shiny.addCustomMessageHandler('pf-reset-file', function() { var el = document.getElementById('file'); if (el) { el.value = ''; el.dispatchEvent(new Event('change', {bubbles:true})); } }); Shiny.addCustomMessageHandler('pf-scroll-results', function(id) { var el = document.getElementById(id); if (el) el.scrollIntoView({behavior:'smooth', block:'start'}); });")),
      shiny::tags$style(shiny::HTML("\
      body {background:#f3f6f4;color:#20392f;font-family:system-ui,-apple-system,'Segoe UI',sans-serif;font-size:15px}
      .container-fluid {max-width:1180px;margin:auto;padding:22px 24px 48px}
      .pf-hero {background:#173e34;color:white;padding:20px 26px;border-radius:16px;margin-bottom:16px;display:flex;align-items:center;justify-content:space-between;gap:24px}
      .pf-hero h1 {font-size:1.75rem;font-weight:750;letter-spacing:-.025em;margin:0 0 3px}
      .pf-hero p {margin:0;color:#d6e9df;font-size:.98rem}
      .pf-hero-mark {font-size:.79rem;color:#d6e9df;border:1px solid #668779;border-radius:99px;padding:7px 11px;white-space:nowrap}
      .pf-card,.pf-module {background:white;border:1px solid #dce6df;border-radius:16px;box-shadow:0 5px 20px rgba(17,53,42,.035)}
      .pf-card {padding:20px 24px;margin-bottom:16px}.pf-module {padding:24px;margin:0 0 20px}
      .pf-section-heading {display:flex;align-items:baseline;gap:12px;margin-bottom:14px}
      .pf-step {display:inline-grid;place-items:center;width:27px;height:27px;border-radius:8px;background:#dceee5;color:#205941;font-weight:700;flex:none}
      .pf-section-heading h2 {font-size:1.28rem;font-weight:720;letter-spacing:-.015em;margin:0}
      .pf-inputs {display:grid;grid-template-columns:minmax(0,1.15fr) minmax(0,1fr);gap:24px}
      .pf-inputs .form-group {margin-bottom:10px}.pf-inputs label {font-weight:650;font-size:.91rem}
      .pf-inputs textarea {border-radius:9px;min-height:126px;resize:vertical}
      .pf-inputs textarea:focus,.pf-inputs .form-control:focus {border-color:#3a8262;box-shadow:0 0 0 3px rgba(58,130,98,.13)}
      .pf-upload {border-left:1px solid #e5ece7;padding-left:24px;min-width:0}
      .pf-upload .shiny-input-container,.pf-upload .input-group {width:100%;max-width:none}
      .pf-upload .input-group .form-control {min-width:0;overflow:hidden;text-overflow:ellipsis}
      .pf-upload-help {color:#657a70;font-size:.85rem;margin:3px 0 8px}
      .pf-file-settings {background:#f7faf8;border:1px solid #e1eae3;border-radius:10px;padding:12px;margin-top:10px}
      .pf-file-settings .form-group {margin-bottom:0}.pf-file-settings .checkbox {margin-top:0}
      .pf-input-footer {border-top:1px solid #edf1ee;margin-top:14px;padding-top:12px;display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}
      .pf-count {font-weight:680;color:#285d47}.pf-link-button {border:0;background:transparent;color:#285d47;padding:5px 0;font-weight:600}
      .pf-link-button:hover {text-decoration:underline;color:#173e34}.pf-file-preview {margin-top:10px}
      .pf-file-preview summary {cursor:pointer;color:#285d47;font-weight:600}.pf-workflow {margin-top:22px}
      .pf-workflow>.pf-section-heading {margin-bottom:12px}
      .pf-workflow .nav-pills {display:flex;flex-wrap:wrap;gap:6px;margin-bottom:0;border-bottom:1px solid #dce6df;padding-bottom:9px}
      .pf-workflow .nav-pills>li {float:none;margin:0}.pf-workflow .nav-pills>li>a {border-radius:9px;color:#285d47;font-weight:630;padding:9px 14px}
      .pf-workflow .nav-pills>li.active>a,.pf-workflow .nav-pills>li.active>a:hover {background:#246a50;color:white}
      .pf-workflow .nav-pills>li:not(.active)>a:hover {background:#e8f1eb}
      .pf-module-heading {display:flex;align-items:end;justify-content:space-between;gap:24px;margin-bottom:10px}
      .pf-module-heading h2 {font-size:1.36rem;font-weight:720;margin:4px 0 0}.pf-lead {color:#526c5e;max-width:56ch;margin:0}
      .pf-eyebrow {text-transform:uppercase;letter-spacing:.08em;font-size:.72rem;font-weight:750;color:#62826e}
      .pf-controls {margin:10px 0 0}.pf-controls>.form-group {max-width:270px}
      .pf-controls .radio-inline {margin-right:12px}.pf-actions {display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-top:12px}
      .pf-actions .btn-primary {background:#246a50;border-color:#246a50;border-radius:8px;font-weight:680;padding:9px 17px}
      .pf-actions .btn-primary:hover {background:#18523c;border-color:#18523c}
      .pf-actions .btn-default {border-radius:8px}.pf-status {color:#526c5e;font-size:.88rem}
      .pf-hint {color:#60756a;font-size:.88rem;line-height:1.4;margin:8px 0}
      .pf-advanced {margin-top:8px;padding:9px 13px;border:1px solid #dce6df;border-radius:9px;max-width:640px}
      .pf-advanced summary {cursor:pointer;font-weight:620;color:#285d47}.pf-advanced[open] {padding-bottom:14px}
      .pf-advanced .form-group {margin-top:10px;max-width:280px}
      .pf-results {scroll-margin-top:18px}.pf-empty {margin-top:15px;background:#f7faf8;border:1px dashed #ccdcd1;border-radius:10px;padding:18px;color:#60756a}
      .pf-metrics {display:flex;gap:10px;flex-wrap:wrap;margin:16px 0}
      .pf-metric {background:#eaf3ee;padding:10px 14px;border-radius:9px;font-weight:650;color:#285d47}
      .pf-results .dataTables_wrapper {margin-top:8px}.pf-results .pf-card {margin-top:16px}
      .pf-results dl {display:grid;grid-template-columns:minmax(140px,1fr) 2fr;gap:7px 18px}
      .pf-results dt {color:#526c5e}.pf-results dd {margin:0;overflow-wrap:anywhere}
      @media(max-width:800px){.container-fluid{padding:12px}.pf-hero{padding:17px 18px}.pf-hero-mark{display:none}.pf-card,.pf-module{padding:17px}.pf-inputs{grid-template-columns:1fr;gap:8px}.pf-upload{border-left:0;border-top:1px solid #e5ece7;padding:14px 0 0}.pf-module-heading{display:block}.pf-lead{margin-top:8px}.pf-workflow .nav-pills{flex-wrap:nowrap;overflow-x:auto;white-space:nowrap;padding-bottom:10px}.pf-workflow .nav-pills>li>a{padding:8px 11px}}
    "))),
    shiny::div(class = "pf-hero",
      shiny::div(shiny::tags$h1("perufauna"),
        shiny::tags$p("Explora nombres científicos y su estado en fuentes de fauna del Perú.")),
      shiny::tags$span(class = "pf-hero-mark", "5 consultas · 4 fuentes")),
    shiny::div(class = "pf-card",
      shiny::div(class = "pf-section-heading", shiny::tags$span(class = "pf-step", "1"),
        shiny::tags$h2("Nombres para consultar")),
      shiny::div(class = "pf-inputs",
        shiny::div(
          shiny::textAreaInput("names_text", "Escribe o pega un nombre por línea", width = "100%",
            height = "126px", placeholder = "Panthera onca\nVultur gryphus\nTremarctos ornatus"),
          shiny::tags$p(class = "pf-hint", "Puedes combinar esta lista con un archivo.")
        ),
        shiny::div(class = "pf-upload",
          shiny::fileInput("file", "O carga un archivo",
            buttonLabel = "Seleccionar archivo", placeholder = "Ningún archivo seleccionado",
            accept = c(".txt", ".csv", ".tsv", ".xls", ".xlsx")),
          shiny::tags$p(class = "pf-upload-help", "TXT, CSV, TSV o Excel · Se omiten las filas vacías."),
          shiny::conditionalPanel("input.file && input.file.name",
            shiny::div(class = "pf-file-settings",
              shiny::checkboxInput("header", "La primera fila contiene encabezados", TRUE),
              shiny::selectInput("column", "Columna de nombres científicos", choices = NULL),
              shiny::textOutput("file_message")
            ),
            shiny::tags$details(class = "pf-file-preview",
              shiny::tags$summary("Vista previa del archivo"), DT::DTOutput("preview"))
          )
        )
      ),
      shiny::div(class = "pf-input-footer",
        shiny::tags$span(class = "pf-count", shiny::textOutput("input_count", inline = TRUE)),
        shiny::div(
          shiny::actionButton("sample", "Usar ejemplo", class = "pf-link-button"),
          shiny::actionButton("clear", "Limpiar todo", class = "pf-link-button")
        )
      )
    ),
    shiny::div(class = "pf-workflow",
      shiny::div(class = "pf-section-heading", shiny::tags$span(class = "pf-step", "2"),
        shiny::tags$h2("Elige la consulta")),
      shiny::tabsetPanel(id = "module", type = "pills",
      shiny::tabPanel("Consulta integrada", value = "integrada",
        app_module_ui("integrada", "integrada", "Consulta integrada",
          "Cruza aves, mamíferos, CITES y categorías nacionales. Empieza con un resumen o cambia a la tabla detallada.")),
      shiny::tabPanel("Aves", value = "aves",
        app_module_ui("aves", "aves", "Aves del Perú",
          "Valida nombres con la lista de avesperu y revisa coincidencias aproximadas.")),
      shiny::tabPanel("Mamíferos", value = "mamiferos",
        app_module_ui("mamiferos", "mamiferos", "Mamíferos del Perú",
          "Consulta coincidencias taxonómicas y endemismo en perumammals.")),
      shiny::tabPanel("CITES", value = "cites",
        app_module_ui("cites", "cites", "Apéndices CITES",
          "Consulta la edición y el grupo de interés. Una coincidencia CITES no confirma presencia en Perú.")),
      shiny::tabPanel("Amenaza nacional", value = "amenaza",
        app_module_ui("amenaza", "amenaza", "Categorías nacionales",
          "Revisa por separado el D.S. 004 y el Libro Rojo. El Libro Rojo no establece por sí solo protección legal."))
      )
    )
  )
}

app_module_settings <- function(input, module) {
  switch(module,
    integrada = list(view = input$view, bird_distance = input$bird_distance,
                     edit_distance = input$edit_distance),
    aves = list(distance = input$distance),
    mamiferos = list(),
    cites = list(taxon = input$taxon, edition = input$edition,
                 distance = input$distance, synonyms = isTRUE(input$synonyms),
                 genus = isTRUE(input$genus)),
    amenaza = list(group = input$group, distance = input$distance,
                   fuzzy = isTRUE(input$fuzzy), genus = isTRUE(input$genus))
  )
}

app_module_server <- function(id, module, records) {
  shiny::moduleServer(id, function(input, output, session) {
    result <- shiny::reactiveVal(NULL)
    running <- shiny::reactiveVal(FALSE)
    status <- shiny::reactiveVal("Ingresa nombres y pulsa «Consultar nombres».")
    job <- NULL
    generation <- 0L
    settings <- shiny::reactive(app_module_settings(input, module))
    cancel <- function(message) {
      generation <<- generation + 1L
      if (!is.null(job) && job$is_alive()) job$kill_tree()
      job <<- NULL
      running(FALSE)
      result(NULL)
      status(message)
    }
    shiny::observeEvent(list(records(), settings()), {
      cancel("La entrada o las opciones cambiaron. Vuelve a consultar.")
    }, ignoreInit = TRUE)
    shiny::observeEvent(input$cancel, cancel("Consulta cancelada."), ignoreInit = TRUE)
    session$onSessionEnded(function() {
      if (!is.null(job) && job$is_alive()) job$kill_tree()
    })
    shiny::observeEvent(input$run, {
      cancel("Preparando consulta…")
      input_records <- tryCatch(records(), error = function(e) e)
      if (inherits(input_records, "error")) {
        status(conditionMessage(input_records)); return(invisible(NULL))
      }
      problem <- tryCatch({ app_validate_records(input_records); NULL },
                          error = function(e) conditionMessage(e))
      if (!is.null(problem)) { status(problem); return(invisible(NULL)) }
      current_settings <- settings()
      package_path <- getNamespaceInfo(asNamespace("perufauna"), "path")
      job <<- tryCatch(callr::r_bg(
        function(path, libs, module, records, settings) {
          .libPaths(libs)
          if (file.exists(file.path(path, "R", "pf_match.R")) &&
              requireNamespace("pkgload", quietly = TRUE)) {
            pkgload::load_all(path, helpers = FALSE, quiet = TRUE)
          } else {
            library("perufauna", lib.loc = dirname(path), character.only = TRUE)
          }
          ns <- asNamespace("perufauna")
          value <- get("app_query", ns)(module, records$submitted_name, settings)
          get("app_result_with_source", ns)(value, records)
        },
        args = list(path = package_path, libs = .libPaths(), module = module,
                    records = input_records, settings = current_settings),
        supervise = TRUE
      ), error = function(e) e)
      if (inherits(job, "error")) {
        status(conditionMessage(job)); job <<- NULL; return(invisible(NULL))
      }
      token <- generation
      running(TRUE)
      status(paste("Consultando", nrow(input_records), "nombres…"))
      poll <- function() {
        if (token != generation || session$isClosed() || is.null(job)) return(invisible(NULL))
        if (job$is_alive()) {
          later::later(poll, 0.2)
        } else {
          value <- tryCatch(job$get_result(), error = function(e) e)
          job <<- NULL
          running(FALSE)
          if (inherits(value, "error")) status(conditionMessage(value)) else {
            result(value)
            status(paste("Consulta terminada:", nrow(value), "filas."))
            session$sendCustomMessage("pf-scroll-results", session$ns("results"))
          }
        }
      }
      later::later(poll, 0.2)
    })
    output$status <- shiny::renderText(status())
    output$cancel_ui <- shiny::renderUI({
      if (!running()) return(NULL)
      shiny::actionButton(session$ns("cancel"), "Cancelar consulta")
    })
    output$summary <- shiny::renderUI({
      value <- result()
      if (is.null(value)) return(shiny::div(class = "pf-empty",
        "Los resultados aparecerán aquí después de la consulta."))
      shiny::div(class = "pf-metrics",
        shiny::div(class = "pf-metric", paste(nrow(value), "nombres consultados")),
        shiny::div(class = "pf-metric", paste(ncol(value) - 2L, "campos de resultado")))
    })
    output$table <- DT::renderDT({
      value <- result(); shiny::req(value)
      DT::datatable(value, rownames = FALSE, colnames = app_field_label(base::names(value)),
        selection = "single", filter = "top",
        options = list(pageLength = 10, scrollX = TRUE, autoWidth = TRUE))
    })
    output$detail <- shiny::renderUI({
      value <- result(); selected <- input$table_rows_selected
      if (is.null(value) || !length(selected)) return(NULL)
      row <- value[selected[1], , drop = FALSE]
      shiny::div(class = "pf-card", shiny::tags$h3("Detalle de la fila"),
        shiny::tags$dl(lapply(base::names(row), function(nm) {
          shiny::tagList(shiny::tags$dt(app_field_label(nm)), shiny::tags$dd(
            if (is.na(row[[nm]][1])) "Sin dato" else as.character(row[[nm]][1])))
        })))
    })
    output$downloads <- shiny::renderUI({
      if (is.null(result())) return(NULL)
      shiny::div(class = "pf-actions",
        shiny::downloadButton(session$ns("csv"), "Descargar CSV"),
        if (requireNamespace("writexl", quietly = TRUE))
          shiny::downloadButton(session$ns("xlsx"), "Descargar XLSX") else
          shiny::tags$span(class = "pf-hint", "Instala writexl para exportar a XLSX."))
    })
    output$csv <- shiny::downloadHandler(
      filename = function() paste0("perufauna-", module, ".csv"),
      content = function(file) utils::write.csv(result(), file, row.names = FALSE,
                                                 fileEncoding = "UTF-8")
    )
    output$xlsx <- shiny::downloadHandler(
      filename = function() paste0("perufauna-", module, ".xlsx"),
      content = function(file) {
        if (!requireNamespace("writexl", quietly = TRUE)) {
          stop("Instala 'writexl' para descargar XLSX.", call. = FALSE)
        }
        writexl::write_xlsx(result(), file)
      }
    )
  })
}

perufauna_app_server <- function(input, output, session) {
  upload <- shiny::reactiveVal(NULL)
  upload_error <- shiny::reactiveVal(NULL)
  shiny::observeEvent(list(input$file, input$header), {
    upload(NULL); upload_error(NULL)
    if (is.null(input$file)) return(invisible(NULL))
    parsed <- tryCatch(app_read_file(input$file$datapath, input$file$name,
                                     header = isTRUE(input$header)),
                       error = function(e) e)
    if (inherits(parsed, "error")) {
      upload_error(conditionMessage(parsed)); return(invisible(NULL))
    }
    upload(parsed)
    shiny::updateSelectInput(session, "column",
                             choices = c("Selecciona una columna" = "", base::names(parsed$data)),
                             selected = app_guess_column(parsed$data))
  })
  shiny::observeEvent(input$sample, {
    shiny::updateTextAreaInput(session, "names_text",
      value = "Panthera onca\nVultur gryphus\nTremarctos ornatus\nHomo sapiens")
  })
  shiny::observeEvent(input$clear, {
    upload(NULL); upload_error(NULL)
    shiny::updateTextAreaInput(session, "names_text", value = "")
    shiny::updateSelectInput(session, "column", choices = character())
    session$sendCustomMessage("pf-reset-file", list())
  })
  records <- shiny::reactive({
    if (!is.null(upload_error())) return(simpleError(upload_error()))
    tryCatch(app_records(input$names_text, upload(), input$column),
             error = function(e) e)
  })
  output$file_message <- shiny::renderText({
    if (!is.null(upload_error())) return(upload_error())
    file <- upload()
    if (is.null(file)) "Puedes consultar solo con texto pegado." else
      paste(nrow(file$data), "filas cargadas de", file$name)
  })
  output$input_count <- shiny::renderText({
    value <- records()
    if (inherits(value, "error")) "Revisa el archivo y la columna seleccionada." else
      paste(nrow(value), "nombres listos para consultar. Máximo: 10 000.")
  })
  output$preview <- DT::renderDT({
    file <- upload(); if (is.null(file)) return(NULL)
    DT::datatable(utils::head(file$data, 10), rownames = FALSE,
                  options = list(dom = "t", scrollX = TRUE))
  })
  for (module in c("integrada", "aves", "mamiferos", "cites", "amenaza")) {
    app_module_server(module, module, records)
  }
}
