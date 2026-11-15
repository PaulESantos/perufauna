# Entrypoint para perufauna Shiny app
# Uso: shiny::runApp(system.file("app", package = "perufauna"))
if (!requireNamespace("perufauna", quietly = TRUE)) {
  stop("El paquete 'perufauna' debe estar instalado.", call. = FALSE)
}

perufauna::perufauna_app()
