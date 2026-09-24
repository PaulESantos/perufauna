test_that("pf_status handles empty input", {
  st <- pf_status(character(0))
  expect_s3_class(st, "tbl_df")
  expect_equal(nrow(st), 0)
  expect_named(st, c("submitted_name", "accepted_name", "taxonomic_group", "occurrence_status", "cites_appendix", "ds004_category"))
})

test_that("pf_status returns atomized tibble summaries", {
  sp <- c("Panthera onca", "Homo sapiens")
  st <- pf_status(sp)
  expect_s3_class(st, "tbl_df")
  expect_equal(nrow(st), 2)
  expect_named(st, c("submitted_name", "accepted_name", "taxonomic_group", "occurrence_status", "cites_appendix", "ds004_category"))

  # Panthera onca
  expect_equal(st$taxonomic_group[1], "Mammalia")
  expect_equal(st$occurrence_status[1], "Residente")
  expect_equal(st$cites_appendix[1], "I")
  expect_equal(st$ds004_category[1], "NT")

  # Homo sapiens (not in Peru checklists)
  expect_true(is.na(st$taxonomic_group[2]))
  expect_true(is.na(st$occurrence_status[2]))
  expect_true(is.na(st$cites_appendix[2]))
  expect_true(is.na(st$ds004_category[2]))
})

test_that("pf_status reports correct occurrence_status across birds and mammals", {
  taxa <- c("Vultur gryphus", "Loddigesia mirabilis", "Lagothrix flavicauda", "Aptenodytes patagonicus")
  st <- pf_status(taxa)
  expect_s3_class(st, "tbl_df")
  expect_equal(st$occurrence_status, c("Residente", "Endémico", "Endémico", "Divagante"))
  expect_equal(st$taxonomic_group, c("Aves", "Aves", "Mammalia", "Aves"))
  expect_equal(st$cites_appendix, c("I", "II", "I", NA_character_))
  expect_equal(st$ds004_category, c("EN", "EN", "CR", NA_character_))
})

