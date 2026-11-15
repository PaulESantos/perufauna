test_that("app records keep input order and file provenance", {
  file <- list(name = "nombres.csv", header_rows = 1L,
               data = data.frame(scientific_name = c("Panthera onca", "", NA,
                                                       "Vultur gryphus")))
  result <- app_records("Tremarctos ornatus\n\nHomo sapiens", file,
                        "scientific_name")
  expect_equal(result$submitted_name,
               c("Tremarctos ornatus", "Homo sapiens", "Panthera onca",
                 "Vultur gryphus"))
  expect_equal(result$source_row, c(1L, 3L, 2L, 5L))
  expect_error(app_records("", file, NULL), "Selecciona la columna")
})

test_that("file input supports headers and headerless tables", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  writeLines(c("scientific_name,id", "Panthera onca,1"), path)
  with_header <- app_read_file(path, "nombres.csv")
  expect_identical(app_guess_column(with_header$data), "scientific_name")
  expect_equal(app_records("", with_header, "scientific_name")$source_row, 2L)
  without_header <- app_read_file(path, "nombres.csv", header = FALSE)
  expect_equal(nrow(without_header$data), 2L)
  expect_equal(without_header$header_rows, 0L)
})

test_that("Excel imports preserve worksheet row numbers", {
  skip_if_not_installed("readxl")
  skip_if_not_installed("writexl")
  path <- tempfile(fileext = ".xlsx")
  on.exit(unlink(path), add = TRUE)
  writexl::write_xlsx(data.frame(scientific_name = c("Panthera onca",
                                                     "Vultur gryphus")), path)
  file <- app_read_file(path, "nombres.xlsx")
  expect_equal(app_records("", file, "scientific_name")$source_row, 2:3)
})

test_that("app limits oversized batches before launching a job", {
  records <- app_records("Vultur gryphus")
  expect_invisible(app_validate_records(records))
  expect_error(app_validate_records(records[FALSE, ]), "al menos un nombre")
  expect_error(app_validate_records(records[rep(1, 10001), ]), "10 000")
})

test_that("five query views return row-aligned results", {
  species <- c("Panthera onca", "Vultur gryphus")
  settings <- list(
    integrada = list(view = "resumen", bird_distance = 0.1, edit_distance = 1),
    aves = list(distance = 0.1),
    mamiferos = list(),
    cites = list(taxon = "fauna", edition = "latest", distance = 1,
                 synonyms = TRUE, genus = FALSE),
    amenaza = list(group = "", distance = 1, fuzzy = TRUE, genus = TRUE)
  )
  records <- app_records(paste(species, collapse = "\n"))
  for (module in names(settings)) {
    result <- app_query(module, species, settings[[module]])
    expect_equal(nrow(result), length(species), info = module)
    with_source <- app_result_with_source(result, records)
    expect_equal(with_source$source_row, 1:2, info = module)
  }
})

test_that("app exports mark approximate matches for review", {
  records <- app_records("Vultor gryphos")
  for (module in c("integrada", "aves", "cites", "amenaza", "mamiferos")) {
    input_records <- if (module == "mamiferos") app_records("Pantera onca") else records
    value <- app_query(module, input_records$submitted_name, list())
    exported <- app_result_with_source(value, input_records)
    expect_true(exported$review_flag[1], info = module)
    expect_false(any(c("review_reason", "cites_candidate_appendix") %in% names(exported)), info = module)
    expect_true(grepl("Necesidad de revisi", exported$review_observation[1], fixed = TRUE), info = module)
  }
  cites <- app_query("cites", records$submitted_name, list())
  expect_identical(cites$match_assessment[1], "requires_taxonomic_validation")
})

test_that("the interface renders all five modules", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  html <- htmltools::renderTags(perufauna_app_ui())$html
  for (id in c("integrada", "aves", "mamiferos", "cites", "amenaza")) {
    expect_true(grepl(paste0('data-value="', id, '"'), html, fixed = TRUE))
  }
  for (label in c("Consultar todas las fuentes", "Consultar aves",
                  "Consultar mam", "Consultar CITES",
                  "Consultar amenaza nacional")) {
    expect_true(grepl(label, html, fixed = TRUE), info = label)
  }
  expect_true(grepl('id="names_text"', html, fixed = TRUE))
  expect_false(grepl('value="Panthera onca', html, fixed = TRUE))
})

test_that("each module runs its own query", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  old_async <- getOption("perufauna.async")
  options(perufauna.async = FALSE)
  on.exit(options(perufauna.async = old_async), add = TRUE)
  called <- character()
  local_mocked_bindings(
    app_query = function(module, names, settings) {
      called <<- c(called, module)
      data.frame(submitted_name = names, queried_module = module)
    }
  )
  for (selected_module in c("integrada", "aves", "mamiferos", "cites", "amenaza")) {
    shiny::testServer(app_module_server,
      args = list(id = selected_module, module = selected_module,
                  records = shiny::reactive(app_records("Panthera onca"))), {
        session$setInputs(run = 1L)
      })
  }
  expect_identical(called, c("integrada", "aves", "mamiferos", "cites", "amenaza"))
})

test_that("app supports semicolon-delimited CSV files from Spanish Excel", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  writeLines(c("scientific_name;id", "Panthera onca;1", "Vultur gryphus;2"), path)
  parsed <- app_read_file(path, "nombres_excel.csv")
  expect_identical(app_guess_column(parsed$data), "scientific_name")
  expect_equal(nrow(parsed$data), 2L)
  expect_equal(ncol(parsed$data), 2L)
  expect_equal(parsed$data$scientific_name, c("Panthera onca", "Vultur gryphus"))
})

test_that("perufauna_app and pf_app aliases and shiny.appobj work", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  expect_identical(pf_app, run_perufauna_app)
  app <- perufauna_app()
  expect_s3_class(app, "shiny.appobj")
})

test_that("app_dt_language returns Spanish localization strings", {
  lang <- app_dt_language()
  expect_type(lang, "list")
  expect_equal(lang$search, "Buscar:")
  expect_true(grepl("registros", lang$lengthMenu))
})

test_that("app_module_summary_cards produces KPI metrics for query results", {
  skip_if_not_installed("shiny")
  df <- data.frame(
    submitted_name = c("Panthera onca", "Homo sapiens"),
    in_peru = c(TRUE, FALSE),
    is_threatened = c(TRUE, FALSE),
    cites_appendix = c("I", NA),
    is_endemic = c(FALSE, FALSE)
  )
  cards <- app_module_summary_cards(df, "integrada")
  expect_s3_class(cards, "shiny.tag")
  html <- as.character(cards)
  expect_true(grepl("Total consultados", html))
  expect_true(grepl("Encontrados en Per", html))
  expect_true(grepl("Coincidencias CITES", html))
})

test_that("app_query handles empty or NULL settings safely without length zero errors", {
  species <- c("Panthera onca", "Vultur gryphus")
  res_amenaza_null <- app_query("amenaza", species, list(group = NULL))
  expect_equal(nrow(res_amenaza_null), length(species))

  res_amenaza_char0 <- app_query("amenaza", species, list(group = character(0)))
  expect_equal(nrow(res_amenaza_char0), length(species))

  for (module in c("integrada", "aves", "mamiferos", "cites", "amenaza")) {
    res_empty <- app_query(module, species, list())
    expect_equal(nrow(res_empty), length(species), info = module)
  }
})
