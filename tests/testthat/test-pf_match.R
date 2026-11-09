test_that("pf_match handles empty inputs", {
  res <- pf_match(character(0))
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0)
  expect_true(all(c("submitted_name", "accepted_name", "taxonomic_group", "in_peru", "cites_appendix", "ds004_category") %in% names(res)))
})

test_that("pf_match cross-references mammals, birds, and non-Peru taxa correctly", {
  sp <- c("Panthera onca", "Vultur gryphus", "Homo sapiens")
  res <- pf_match(sp)

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 3)

  # Panthera onca: mammal in Pacheco, CITES I, D.S. 004 NT
  row_jaguar <- res[res$submitted_name == "Panthera onca", ]
  expect_true(row_jaguar$in_peru)
  expect_true(row_jaguar$in_pacheco)
  expect_true(is.na(row_jaguar$in_unop))
  expect_equal(row_jaguar$taxonomic_group, "Mammalia")
  expect_equal(row_jaguar$cites_appendix, "I")
  expect_equal(row_jaguar$ds004_category, "NT")

  # Vultur gryphus: bird in UNOP, CITES I
  row_condor <- res[res$submitted_name == "Vultur gryphus", ]
  expect_true(row_condor$in_peru)
  expect_equal(row_condor$in_unop, "Residente")
  expect_false(row_condor$in_pacheco)
  expect_equal(row_condor$taxonomic_group, "Aves")
  expect_equal(row_condor$cites_appendix, "I")

  # Homo sapiens: not in checklists
  row_human <- res[res$submitted_name == "Homo sapiens", ]
  expect_false(row_human$in_peru)
  expect_true(is.na(row_human$in_unop))
})

test_that("pf_match accepts data.frame input", {
  df <- data.frame(scientific_name = c("Tremarctos ornatus", "Panthera onca"))
  res <- pf_match(df)
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 2)
  expect_true(all(res$in_peru))
})

test_that("CITES listing alone does not establish occurrence in Peru", {
  res <- pf_match("Cedrela odorata")
  expect_false(res$in_peru)
  expect_false(res$is_threatened)
  expect_false(is.na(res$cites_appendix))
  expect_true(is.na(pf_status("Cedrela odorata")$occurrence_status))
})

test_that("matching controls and name column are validated", {
  expect_error(pf_match("Vultur gryphus", max_distance = -1), "max_distance")
  expect_error(pf_match("Vultur gryphus", max_edit_distance = 0.5), "max_edit_distance")
  expect_error(pf_match(data.frame(id = 1, label = "Vultur gryphus")), "name_col")
  expect_equal(pf_match(data.frame(id = 1, label = "Vultur gryphus"),
                        name_col = "label")$taxonomic_group, "Aves")
})

test_that("CRAN perumammals works without a preloaded global dataset", {
  if (utils::packageVersion("perumammals") >= "0.1.0") {
    skip("The newer perumammals release loads its own data")
  }
  had_global <- exists("peru_mammals", envir = .GlobalEnv, inherits = FALSE)
  if (had_global) {
    previous <- get("peru_mammals", envir = .GlobalEnv, inherits = FALSE)
    rm(list = "peru_mammals", envir = .GlobalEnv)
  }
  on.exit({
    if (had_global) assign("peru_mammals", previous, envir = .GlobalEnv)
  }, add = TRUE)

  search_before <- search()
  expect_true(pf_match("Panthera onca")$in_pacheco)
  expect_false(exists("peru_mammals", envir = .GlobalEnv, inherits = FALSE))
  expect_identical(search(), search_before)
})

test_that("pf_match reports correct status for endemic and vagrant birds", {
  res <- pf_match(c("Loddigesia mirabilis", "Aptenodytes patagonicus"))
  expect_equal(res$in_unop, c("Endémico", "Divagante"))
  expect_equal(res$is_endemic, c(TRUE, FALSE))
})

