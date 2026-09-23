inform_startup <- function(msg, ...) {
  if (is.null(msg) || !nzchar(msg)) {
    return(invisible())
  }
  if (isTRUE(getOption("perufauna.quiet"))) {
    return(invisible())
  }

  rlang::inform(msg, ..., class = "packageStartupMessage")
}

#' List all core packages in perufauna
#'
#' Lists the constituent member packages of the perufauna ecosystem.
#'
#' @param include_self Include perufauna in the list? Default is \code{FALSE}.
#' @return Character vector of package names.
#' @export
#' @examples
#' perufauna_packages()
perufauna_packages <- function(include_self = FALSE) {
  core <- c("avesperu", "perumammals", "citesperu", "perufaunads004")

  if (include_self) {
    c(core, "perufauna")
  } else {
    core
  }
}

package_version_h <- function(pkg) {
  if (!rlang::is_installed(pkg)) {
    return(cli::col_red("[no instalado]"))
  }
  highlight_version(utils::packageVersion(pkg))
}

highlight_version <- function(x) {
  x <- as.character(x)

  is_dev <- function(x) {
    x <- suppressWarnings(as.numeric(x))
    !is.na(x) & x >= 9000
  }

  pieces <- strsplit(x, ".", fixed = TRUE)
  pieces <- lapply(pieces, function(x) ifelse(is_dev(x), cli::col_red(x), x))
  vapply(pieces, paste, collapse = ".", FUN.VALUE = character(1))
}

is_loading_for_tests <- function() {
  !interactive() && identical(Sys.getenv("DEVTOOLS_LOAD"), "perufauna")
}

is_attached <- function(x) {
  paste0("package:", x) %in% search()
}
