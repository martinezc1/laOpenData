# Internal helpers for Los Angeles Open Data requests ####
# - .la_endpoint(): constructs the Socrata endpoint URL from a dataset id
# - .la_add_filters(): adds equality filters (and IN() for multi-values) as a Socrata $where clause
# - .la_add_where(): appends a raw SoQL WHERE expression (for ranges, >=, <, etc.)
# - .la_validate_date_yyyy_mm_dd(): validates Date or "YYYY-MM-DD" inputs
# - .la_build_date_where(): constructs server-side date filters using a dataset's default_date_field
# - .la_get_json(): executes the request and returns parsed JSON (flattened)
# - .la_dataset_request(): common pattern for dataset wrapper functions + input validation (r07/r08)

test_that(".la_coerce_types handles empty, numeric, and logical-like columns", {
  coerce <- laOpenData:::.la_coerce_types

  # Empty data frame returns unchanged
  empty_df <- data.frame(a = character(0))
  res_empty <- coerce(empty_df)
  expect_s3_class(res_empty, "data.frame")
  expect_equal(nrow(res_empty), 0)

  # Non-character columns should be skipped; logical-like character columns should coerce
  df_mixed <- data.frame(
    a = c(1, 2),
    b = c("true", "false"),
    stringsAsFactors = FALSE
  )

  res <- coerce(df_mixed)

  expect_type(res$a, "double")
  expect_type(res$b, "logical")
  expect_equal(res$b, c(TRUE, FALSE))
})

test_that(".la_add_filters handles quotes, empty strings, and multi-value filters", {
  add_f <- laOpenData:::.la_add_filters

  # Single quote escaping
  q1 <- add_f(list(), list(name = "O'Reilly"))
  expect_match(q1[["$where"]], "O''Reilly")

  # Empty / whitespace-only character filters should error
  expect_error(
    add_f(list(), list(agency = " ")),
    "cannot be empty"
  )

  # Multi-value filters should generate IN (...)
  q2 <- add_f(list(), list(status = c("open", "closed")))
  expect_match(q2[["$where"]], "IN")
  expect_match(q2[["$where"]], "'open'")
  expect_match(q2[["$where"]], "'closed'")
})

test_that(".la_add_where appends correctly and ignores empty strings", {
  add_w <- laOpenData:::.la_add_where

  # Append to existing where
  q <- list("$where" = "a = 1")
  res <- add_w(q, "b = 2")
  expect_equal(res[["$where"]], "(a = 1) AND (b = 2)")

  # Empty where should leave query unchanged
  unchanged <- add_w(q, "")
  expect_equal(unchanged, q)
})

test_that(".la_build_date_where handles exact dates and partial ranges", {
  builder <- laOpenData:::.la_build_date_where

  # Exact date
  res_date <- builder("test_date", date = "2025-01-01")
  expect_match(res_date, "test_date >= '2025-01-01T00:00:00.000'")
  expect_match(res_date, "test_date < '2025-01-02T00:00:00.000'")

  # From only
  res_from <- builder("test_date", from = "2025-01-01")
  expect_match(res_from, "test_date >= '2025-01-01T00:00:00.000'")

  # To only
  res_to <- builder("test_date", to = "2025-01-01")
  expect_match(res_to, "test_date < '2025-01-01T00:00:00.000'")
})

test_that(".la_build_date_where throws errors on conflicting args and returns NULL for missing date field", {
  builder <- laOpenData:::.la_build_date_where

  expect_error(
    builder("my_date", date = "2025-01-01", from = "2025-01-01"),
    "not both"
  )

  expect_null(builder(NA_character_, date = "2025-01-01"))
  expect_null(builder(NULL, date = "2025-01-01"))
  expect_null(builder("", date = "2025-01-01"))
})

test_that(".la_validate_limit validates correctly", {
  validate_limit <- laOpenData:::.la_validate_limit

  expect_equal(validate_limit(10), 10L)

  expect_error(validate_limit(NA), "single, non-missing numeric")
  expect_error(validate_limit("10"), "single numeric")
  expect_error(validate_limit(-1), "between 0 and Inf")
  expect_error(validate_limit(1.5), "whole number")
})

test_that(".la_validate_timeout validates correctly", {
  validate_timeout <- laOpenData:::.la_validate_timeout

  expect_equal(validate_timeout(30), 30)

  expect_error(validate_timeout(NA), "single, non-missing numeric")
  expect_error(validate_timeout("30"), "single numeric")
  expect_error(validate_timeout(0), "> 0")
  expect_error(validate_timeout(-5), "> 0")
})

test_that(".la_validate_filters validates correctly", {
  validate_filters <- laOpenData:::.la_validate_filters

  expect_equal(validate_filters(NULL), list())
  expect_equal(validate_filters(list()), list())

  good <- list(status = "open", year = 2025)
  expect_equal(validate_filters(good), good)

  expect_error(validate_filters("bad"), "named list")
  expect_error(validate_filters(list("open")), "named")
  expect_error(validate_filters(list(status = character(0))), "cannot be empty")
  expect_error(validate_filters(list(status = NA)), "cannot contain NA")
})
