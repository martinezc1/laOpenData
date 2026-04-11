# tests/testthat/test-validate.R

test_that(".la_dataset_request validates limit", {
  expect_error(.la_dataset_request("29fd-3paw", limit = "bad"), "limit.*single numeric", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", limit = NA), "limit.*non-missing", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", limit = -1), "limit.*between 0", ignore.case = TRUE)
})

test_that(".la_dataset_request validates timeout_sec", {
  expect_error(.la_dataset_request("29fd-3paw", timeout_sec = "bad"), "timeout_sec.*single numeric", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", timeout_sec = NA), "timeout_sec.*non-missing", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", timeout_sec = 0), "timeout_sec.*> 0", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", timeout_sec = -5), "timeout_sec.*> 0", ignore.case = TRUE)
})

test_that(".la_dataset_request validates filters structure", {
  expect_error(.la_dataset_request("29fd-3paw", filters = "not a list"), "filters.*named list", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", filters = list("A")), "filters.*named", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", filters = list(grade = NA)), "filters.*NA", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", filters = list(grade = character(0))), "filters.*empty", ignore.case = TRUE)
})

test_that(".la_dataset_request validates order and where", {
  expect_error(.la_dataset_request("29fd-3paw", order = 1), "order.*character", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", order = ""), "order.*non-empty", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", where = 1), "where.*character", ignore.case = TRUE)
  expect_error(.la_dataset_request("29fd-3paw", where = NA_character_), "where.*non-missing", ignore.case = TRUE)
})

test_that(".la_add_filters supports IN() for multi-value filters", {
  q <- .la_add_filters(list(), list(grade = c("A", "B")))
  expect_true(grepl("(TRIM\\(grade\\)|grade)\\s+IN\\s*\\(", q[["$where"]]))
  expect_true(grepl("'A'", q[["$where"]]))
  expect_true(grepl("'B'", q[["$where"]]))
})

test_that(".la_add_where combines clauses with AND", {
  q <- .la_add_filters(list(), list(grade = "A"))
  q2 <- .la_add_where(q, "service_code == '1'")
  expect_true(grepl("grade", q2[["$where"]]))
  expect_true(grepl("service_code", q2[["$where"]]))
  expect_true(grepl("\\) AND \\(", q2[["$where"]]))
})
