test_that("la_list_datasets returns a catalog tibble with expected columns", {
  skip_if_not_installed("vcr")
  skip_if_not_installed("curl")
  skip_if_no_cassette("la_list_datasets_catalog")

  vcr::use_cassette("la_list_datasets_catalog", {
    cat <- la_list_datasets()

    expect_s3_class(cat, "tbl_df")
    expect_gte(nrow(cat), 1)
    expect_true(all(c("key", "id", "name") %in% names(cat)))
  })
})

test_that("la_pull_dataset returns a tibble, respects limits, supports filters + date/from/to", {
  skip_if_not_installed("vcr")
  skip_if_not_installed("curl")
  skip_if_no_cassette("la_pull_dataset_robust")

  dataset_open_dataset_id <- "29fd-3paw"

  vcr::use_cassette("la_pull_dataset_robust", {
    base <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      limit = 2,
      timeout_sec = 60
    )
    expect_s3_class(base, "tbl_df")
    expect_gte(nrow(base), 0)
    expect_lte(nrow(base), 2)
    expect_gt(ncol(base), 0)
    expect_true(all(!grepl("\\.", names(base))))

    f1 <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      limit = 2,
      filters = list(grade = "A"),
      timeout_sec = 60
    )
    expect_s3_class(f1, "tbl_df")
    expect_gte(nrow(f1), 0)
    expect_lte(nrow(f1), 2)

    f2 <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      limit = 2,
      filters = list(grade = c("A", "B")),
      timeout_sec = 60
    )
    expect_s3_class(f2, "tbl_df")
    expect_gte(nrow(f2), 0)
    expect_lte(nrow(f2), 2)

    d1 <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      date = "2020-11-20",
      date_field = "activity_date",
      limit = 2,
      timeout_sec = 60
    )
    expect_s3_class(d1, "tbl_df")
    expect_gte(nrow(d1), 0)
    expect_lte(nrow(d1), 2)

    d2 <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      from = "2020-11-20",
      to = "2020-11-21",
      date_field = "activity_date",
      limit = 2,
      timeout_sec = 60
    )
    expect_s3_class(d2, "tbl_df")
    expect_gte(nrow(d2), 0)
    expect_lte(nrow(d2), 2)

    d3 <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      from = "2020-11-20",
      date_field = "activity_date",
      limit = 2,
      timeout_sec = 60
    )
    expect_s3_class(d3, "tbl_df")
    expect_gte(nrow(d3), 0)
    expect_lte(nrow(d3), 2)

    d4 <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      to = "2020-11-20",
      date_field = "activity_date",
      limit = 2,
      timeout_sec = 60
    )
    expect_s3_class(d4, "tbl_df")
    expect_gte(nrow(d4), 0)
    expect_lte(nrow(d4), 2)
  })
})

test_that("la_pull_dataset supports lookup by generated key as well as open_dataset_id", {
  skip_if_not_installed("vcr")
  skip_if_not_installed("curl")
  skip_if_no_cassette("la_pull_dataset_key_lookup")

  vcr::use_cassette("la_pull_dataset_key_lookup", {
    cat <- la_list_datasets()

    row <- cat[cat$id == "29fd-3paw", , drop = FALSE]
    if (nrow(row) == 0) {
      skip("Known dataset not found in catalog")
    }

    dataset_key <- row$key[[1]]

    out <- la_pull_dataset(
      dataset = dataset_key,
      limit = 2,
      timeout_sec = 60
    )

    expect_s3_class(out, "tbl_df")
    expect_lte(nrow(out), 2)
  })
})

test_that("la_pull_dataset input validation errors", {
  expect_error(
    la_pull_dataset(dataset = NA_character_),
    "`dataset` must be"
  )
  expect_error(
    la_pull_dataset(dataset = ""),
    "`dataset` must be"
  )

  expect_error(
    la_pull_dataset(dataset = "not_a_real_dataset", limit = 1),
    "Unknown dataset"
  )

  expect_error(
    la_pull_dataset(
      dataset = "29fd-3paw",
      date = "2026-03-05",
      from = "2026-03-10",
      date_field = "activity_date"
    ),
    "either `date` OR `from`/`to`"
  )

  expect_error(
    la_pull_dataset(
      dataset = "29fd-3paw",
      date = "11/20/2020",
      date_field = "activity_date",
      limit = 1
    ),
    "YYYY-MM-DD"
  )

  expect_error(
    la_pull_dataset(
      dataset = "29fd-3paw",
      from = "2020-11-20",
      limit = 1
    ),
    "must also provide a single non-empty `date_field`"
  )

  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", limit = "a string"),
    "`limit` must be"
  )
  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", limit = NA),
    "`limit` must be"
  )
  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", limit = -1),
    "between 0 and Inf"
  )
  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", limit = 1.2),
    "integer"
  )

  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", filters = "not a list"),
    "`filters` must be"
  )
  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", filters = list("A")),
    "named"
  )
  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", filters = list(grade = character(0))),
    "cannot be empty"
  )
  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", filters = list(grade = NA_character_)),
    "cannot contain NA"
  )

  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", timeout_sec = 0),
    "`timeout_sec` must be > 0"
  )
  expect_error(
    la_pull_dataset(dataset = "29fd-3paw", timeout_sec = "fast"),
    "`timeout_sec` must be"
  )
})

test_that("la_pull_dataset supports clean_names/coerce_types toggles", {
  skip_if_not_installed("vcr")
  skip_if_not_installed("webmockr")
  skip_if_not_installed("curl")
  skip_if_no_cassette("la_pull_dataset_toggles")

  dataset_open_dataset_id <- "29fd-3paw"

  vcr::use_cassette("la_pull_dataset_toggles", {
    a <- la_pull_dataset(dataset = dataset_open_dataset_id, limit = 2, timeout_sec = 60)
    expect_s3_class(a, "tbl_df")
    expect_lte(nrow(a), 2)

    b <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      limit = 2,
      clean_names = FALSE,
      timeout_sec = 60
    )
    expect_s3_class(b, "tbl_df")
    expect_lte(nrow(b), 2)

    c <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      limit = 2,
      coerce_types = FALSE,
      timeout_sec = 60
    )
    expect_s3_class(c, "tbl_df")
    expect_lte(nrow(c), 2)

    d <- la_pull_dataset(
      dataset = dataset_open_dataset_id,
      limit = 2,
      clean_names = FALSE,
      coerce_types = FALSE,
      timeout_sec = 60
    )
    expect_s3_class(d, "tbl_df")
    expect_lte(nrow(d), 2)

    expect_gt(ncol(a), 0)
    expect_gt(ncol(b), 0)
    expect_gt(ncol(c), 0)
    expect_gt(ncol(d), 0)
  })
})

test_that("la_pull_dataset throws internal error if catalog is corrupted", {
  corrupted_catalog <- tibble::tibble(
    key = "some_dataset",
    dataset_title = "Some Dataset"
  )

  testthat::with_mocked_bindings(
    .la_catalog_tbl = function() corrupted_catalog,
    {
      expect_error(
        la_pull_dataset("some_dataset"),
        "Internal error: catalog missing required column"
      )
    }
  )
})

