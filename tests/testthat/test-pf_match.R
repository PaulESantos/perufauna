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
  expect_false(row_jaguar$in_unop)
  expect_equal(row_jaguar$taxonomic_group, "Mammalia")
  expect_equal(row_jaguar$cites_appendix, "I")
  expect_equal(row_jaguar$ds004_category, "NT")

  # Vultur gryphus: bird in UNOP, CITES I
  row_condor <- res[res$submitted_name == "Vultur gryphus", ]
  expect_true(row_condor$in_peru)
  expect_true(row_condor$in_unop)
  expect_false(row_condor$in_pacheco)
  expect_equal(row_condor$taxonomic_group, "Aves")
  expect_equal(row_condor$cites_appendix, "I")

  # Homo sapiens: not in checklists
  row_human <- res[res$submitted_name == "Homo sapiens", ]
  expect_false(row_human$in_peru)
})

test_that("pf_match accepts data.frame input", {
  df <- data.frame(scientific_name = c("Tremarctos ornatus", "Panthera onca"))
  res <- pf_match(df)
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 2)
  expect_true(all(res$in_peru))
})
