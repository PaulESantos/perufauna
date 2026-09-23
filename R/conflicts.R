#' Conflicts between perufauna and other packages
#'
#' Lists all function name conflicts between packages in the perufauna ecosystem
#' and other loaded packages on the search path.
#'
#' @param only Optional character vector to restrict conflict checks to specific packages.
#' @return An object of class \code{perufauna_conflicts}.
#' @export
#' @examples
#' \donttest{
#' perufauna_conflicts()
#' }
perufauna_conflicts <- function(only = NULL) {
  envs <- grep("^package:", search(), value = TRUE)
  names(envs) <- envs

  if (!is.null(only)) {
    only <- union(only, perufauna_packages())
    envs <- envs[names(envs) %in% paste0("package:", only)]
  }

  objs <- invert(lapply(envs, ls_env))

  conflicts <- objs[vapply(objs, function(obj) length(obj) > 1, FUN.VALUE = logical(1))]

  pf_names <- paste0("package:", perufauna_packages())
  conflicts <- conflicts[vapply(conflicts, function(pkg) any(pkg %in% pf_names), FUN.VALUE = logical(1))]

  conflict_funs <- list()
  for (nm in names(conflicts)) {
    cf <- confirm_conflict(conflicts[[nm]], nm)
    if (!is.null(cf)) {
      conflict_funs[[nm]] <- cf
    }
  }

  class(conflict_funs) <- "perufauna_conflicts"
  conflict_funs
}

perufauna_conflict_message <- function(x) {
  if (length(x) == 0) {
    return(NULL)
  }

  header <- cli::rule(
    left = cli::style_bold("Conflicts"),
    right = "perufauna_conflicts()"
  )

  lines <- character()
  for (fn in names(x)) {
    pkgs <- gsub("^package:", "", x[[fn]])
    winner <- pkgs[1]
    others <- pkgs[-1]
    other_calls <- paste0(cli::col_blue(others), "::", fn, "()", collapse = ", ")
    winner_call <- paste0(cli::col_blue(winner), "::", cli::col_green(paste0(fn, "()")))
    lines <- c(
      lines,
      paste0(cli::col_red(cli::symbol$cross), " ", winner_call, " masks ", other_calls)
    )
  }

  hint <- paste0(
    cli::col_cyan(cli::symbol$info), " ",
    "Use full namespace syntax like ", cli::col_yellow("package::function()"),
    " to avoid ambiguity."
  )

  paste0(header, "\n", paste(lines, collapse = "\n"), "\n", hint)
}

#' @export
print.perufauna_conflicts <- function(x, ..., startup = FALSE) {
  cli::cat_line(perufauna_conflict_message(x))
  invisible(x)
}

confirm_conflict <- function(packages, name) {
  objs <- list()
  valid_pkgs <- character()

  for (pkg in packages) {
    if (exists(name, where = pkg, inherits = FALSE)) {
      obj <- get(name, pos = pkg)
      if (is.function(obj)) {
        objs <- c(objs, list(obj))
        valid_pkgs <- c(valid_pkgs, pkg)
      }
    }
  }

  if (length(objs) <= 1) {
    return(NULL)
  }

  # Remove identical functions (e.g. if one package re-exports the exact same function)
  objs <- objs[!duplicated(objs)]
  valid_pkgs <- valid_pkgs[!duplicated(valid_pkgs)]
  if (length(objs) == 1) {
    return(NULL)
  }

  valid_pkgs
}

ls_env <- function(env) {
  ls(pos = env)
}

invert <- function(x) {
  if (length(x) == 0) {
    return(list())
  }
  stacked <- utils::stack(x)
  tapply(as.character(stacked$ind), stacked$values, list)
}
