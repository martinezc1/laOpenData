#' List datasets available in laOpenData
#'
#' Retrieves the current Open NY catalog and returns datasets available
#' for use with `la_pull_dataset()`.
#'
#' Keys are generated from dataset names using `janitor::make_clean_names()`.
#'
#' @return A tibble of available datasets, including generated `key`, dataset
#'   `uid`, and dataset `name`.
#' @examples
#' if (interactive() && curl::has_internet()) {
#'   la_list_datasets()
#' }
#' @importFrom rlang .data
#' @export
la_list_datasets <- function() {
  .la_catalog_tbl()
}

.la_catalog_tbl <- function() {
  raw <- jsonlite::fromJSON("https://data.lacity.org/api/views/metadata/v1.json", flatten = TRUE) |>
    tibble::as_tibble()

  raw |>
    dplyr::mutate(
      key = janitor::make_clean_names(.data$name)) |>
    dplyr::filter(!is.na(.data$id), nzchar(.data$id)) |>
    dplyr::distinct(.data$id, .keep_all = TRUE) |>
    dplyr::relocate( "key", "id", "name")
}
