#' The perufauna Logo in ASCII
#'
#' Displays the stylized perufauna ASCII banner.
#'
#' @return An object of class \code{perufauna_logo}.
#' @export
#' @examples
#' perufauna_logo()
perufauna_logo <- function() {
  logo <- c(
    "  ____                 _____                         ",
    " |  _ \\ ___ _ __ _   _|  ___|_ _ _   _ _ __   __ _  ",
    " | |_) / _ \\ '__| | | | |_ / _` | | | | '_ \\ / _` | ",
    " |  __/  __/ |  | |_| |  _| (_| | |_| | | | | (_| | ",
    " |_|   \\___|_|   \\__,_|_|  \\__,_|\\__,_|_| |_|\\__,_| ",
    NULL
  )

  structure(cli::col_green(logo), class = "perufauna_logo")
}

#' @export
print.perufauna_logo <- function(x, ...) {
  cat(x, ..., sep = "\n")
  invisible(x)
}
