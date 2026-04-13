# List datasets available in laOpenData

Retrieves the current Open NY catalog and returns datasets available for
use with \`la_pull_dataset()\`.

## Usage

``` r
la_list_datasets()
```

## Value

A tibble of available datasets, including generated \`key\`, dataset
\`id\`, and dataset \`name\`.

## Details

Keys are generated from dataset names using
\`janitor::make_clean_names()\`.

## Examples

``` r
if (interactive() && curl::has_internet()) {
  la_list_datasets()
}
```
