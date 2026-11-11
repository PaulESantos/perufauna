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

test_that("the interface renders all five modules", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("DT")
  html <- htmltools::renderTags(perufauna_app_ui())$html
  for (id in c("integrada", "aves", "mamiferos", "cites", "amenaza")) {
    expect_true(grepl(paste0('data-value="', id, '"'), html, fixed = TRUE))
  }
})
