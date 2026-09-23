core <- c(
  "avesperu",
  "perumammals",
  "citesperu",
  "perufaunads004"
)

core_unloaded <- function() {
  search <- paste0("package:", core)
  core[!search %in% search()]
}

same_library <- function(pkg) {
  loc <- if (pkg %in% loadedNamespaces()) dirname(getNamespaceInfo(pkg, "path"))
  library(pkg, lib.loc = loc, character.only = TRUE, warn.conflicts = FALSE)
}

#' Attach Core Packages in perufauna
#'
#' Attaches all core member packages of the perufauna ecosystem
#' (\code{avesperu}, \code{perumammals}, \code{citesperu}, \code{perufaunads004})
#' that are not yet loaded onto the search path.
#'
#' @return Invisible character vector of newly attached packages.
#' @export
#' @examples
#' \donttest{
#' perufauna_attach()
#' }
perufauna_attach <- function() {
  to_load <- core_unloaded()

  # Only attempt loading installed packages
  installed <- to_load[vapply(to_load, rlang::is_installed, FUN.VALUE = logical(1))]

  suppressPackageStartupMessages(
    lapply(installed, same_library)
  )

  invisible(installed)
}

perufauna_attach_message <- function(to_load) {
  if (length(to_load) == 0) {
    return(NULL)
  }

  header <- cli::rule(
    left = cli::style_bold("Attaching core perufauna packages"),
    right = paste0("perufauna ", package_version_h("perufauna"))
  )

  to_load <- sort(to_load)
  versions <- vapply(to_load, package_version_h, character(1))

  packages <- paste0(
    cli::col_green(cli::symbol$tick),
    " ",
    cli::col_blue(format(to_load)),
    " ",
    cli::ansi_align(versions, max(cli::ansi_nchar(versions)))
  )

  if (length(packages) %% 2 == 1) {
    packages <- append(packages, "")
  }
  col1 <- seq_len(length(packages) / 2)
  info <- paste0(packages[col1], "     ", packages[-col1])

  hint <- paste0(
    cli::col_cyan(cli::symbol$info), " ",
    "Use ", cli::col_yellow("pf_match()"), " for cross-referenced multi-taxa matching."
  )

  paste0(header, "\n", paste(info, collapse = "\n"), "\n", hint)
}
