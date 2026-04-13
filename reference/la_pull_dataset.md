# Pull a Los Angeles Open Data dataset from the Los Angeles Open Data catalog

Uses a dataset \`key\` or \`id\` from \`la_list_datasets()\` to pull
data from Los Angeles Open Data.

## Usage

``` r
la_pull_dataset(
  dataset,
  limit = 10000,
  filters = list(),
  date = NULL,
  from = NULL,
  to = NULL,
  date_field = NULL,
  where = NULL,
  order = NULL,
  timeout_sec = 30,
  clean_names = TRUE,
  coerce_types = TRUE
)
```

## Arguments

- dataset:

  A dataset key or ID from \`la_list_datasets()\`.

- limit:

  Number of rows to retrieve (default = 10,000).

- filters:

  Optional named list of filters. Supports vectors (translated to IN()).

- date:

  Optional single date (matches all times that day) using
  \`date_field\`.

- from:

  Optional start date (inclusive) using \`date_field\`.

- to:

  Optional end date (exclusive) using \`date_field\`.

- date_field:

  Optional date/datetime column to use with \`date\`, \`from\`, or
  \`to\`. Must be supplied when \`date\`, \`from\`, or \`to\` are used.

- where:

  Optional raw SoQL WHERE clause. If \`date\`, \`from\`, or \`to\` are
  provided, their conditions are AND-ed with this.

- order:

  Optional SoQL ORDER BY clause.

- timeout_sec:

  Request timeout in seconds (default = 30).

- clean_names:

  Logical; if TRUE, convert column names to snake_case (default = TRUE).

- coerce_types:

  Logical; if TRUE, attempt light type coercion (default = TRUE).

## Value

A tibble.

## Details

Dataset keys are generated from dataset titles using
\`janitor::make_clean_names()\`. Because keys are derived from live
catalog metadata, dataset IDs are the more stable option.

## Examples

``` r
if (interactive() && curl::has_internet()) {
  # Pull by key
  la_pull_dataset("current_employee_names_salaries_and_position_titles", limit = 3)

  # Pull by ID
  la_pull_dataset("xzkq-xp2w", limit = 3)

  # Filters
  la_pull_dataset("xzkq-xp2w", limit = 3, filters = list(salary_or_hourly = "HOURLY"))

}
```
