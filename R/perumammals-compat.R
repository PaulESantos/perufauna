# perumammals 0.0.0.2 expects its dataset on the search path. Evaluate copies
# of its matcher and validator with a local data loader so the released package
# works in a clean session without changing the global environment or search().
match_peru_mammals <- function(names) {
  if (utils::packageVersion("perumammals") != "0.0.0.2") {
    return(perumammals::is_peru_mammal(names, return_details = TRUE))
  }

  data_env <- new.env(parent = emptyenv())
  utils::data("peru_mammals", package = "perumammals", envir = data_env)
  if (!exists("peru_mammals", envir = data_env, inherits = FALSE)) {
    stop("The perumammals reference dataset is unavailable.", call. = FALSE)
  }

  target <- data_env$peru_mammals
  character_columns <- vapply(target, is.character, logical(1))
  target[character_columns] <- lapply(target[character_columns], function(x) {
    gsub("[[:space:]]+", " ", trimws(x))
  })

  ns <- asNamespace("perumammals")
  local_ns <- new.env(parent = ns)
  local_ns$.load_target_peru <- function(quiet) target

  validator <- unserialize(serialize(get("validate_peru_mammals", envir = ns), NULL))
  environment(validator) <- local_ns
  local_ns$validate_peru_mammals <- validator

  matcher <- unserialize(serialize(get("is_peru_mammal", envir = ns), NULL))
  environment(matcher) <- local_ns
  matcher(names, return_details = TRUE)
}
