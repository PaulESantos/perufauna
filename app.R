# Aplicación Shiny interactiva de perufauna
# Ejecutar localmente con shiny::runApp() o desplegar en shinyapps.io / Posit Connect

if (dir.exists(".cran-lib")) {
  .libPaths(c(normalizePath(".cran-lib"), .libPaths()))
}

options(shiny.autoload.r = FALSE)

if (file.exists(file.path("R", "shiny-app.R")) && requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", helpers = FALSE, quiet = TRUE)
} else {
  library("perufauna")
}

perufauna::perufauna_app()
