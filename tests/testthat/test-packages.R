test_that("perufauna_packages returns core 4 packages", {
  pkgs <- perufauna_packages()
  expect_type(pkgs, "character")
  expect_length(pkgs, 4)
  expect_true(all(c("avesperu", "perumammals", "citesperu", "perufaunads004") %in% pkgs))
})

test_that("perufauna_attach works quietly", {
  attached <- perufauna_attach()
  expect_type(attached, "character")
})

test_that("perufauna_deps returns tibble with expected columns", {
  deps <- perufauna_deps()
  expect_s3_class(deps, "tbl_df")
  expect_named(deps, c("package", "installed", "local_version"))
  expect_equal(nrow(deps), 4)
})

test_that("perufauna_sitrep prints environment information", {
  expect_output(perufauna_sitrep(), "R Environment")
  expect_output(perufauna_sitrep(), "Core Biodiversity Packages")
})

test_that("perufauna_logo prints banner", {
  lg <- perufauna_logo()
  expect_s3_class(lg, "perufauna_logo")
  expect_output(print(lg), "___")
})

test_that("perufauna_conflicts runs without error", {
  cf <- perufauna_conflicts()
  expect_s3_class(cf, "perufauna_conflicts")
})
