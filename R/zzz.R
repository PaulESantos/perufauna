.onAttach <- function(...) {
  if (is_loading_for_tests()) {
    return(invisible())
  }

  attached <- perufauna_attach()
  inform_startup(perufauna_attach_message(attached))

  if (is_attached("conflicted")) {
    return(invisible())
  }

  conflicts <- perufauna_conflicts()
  inform_startup(perufauna_conflict_message(conflicts))
}
