test_that("pf_status returns character summaries", {
  sp <- c("Panthera onca", "Homo sapiens")
  st <- pf_status(sp)
  expect_type(st, "character")
  expect_length(st, 2)
  expect_true(grepl("Mammalia", st[1]))
  expect_true(grepl("No registrado", st[2]))
})
