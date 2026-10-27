# Compute pivot result from a Shiny safePivot config

Rows, columns, values, aggregator, and filters are read from `config`
exactly as the browser sent them. The `default_*` arguments are only
used when `config` is `NULL` (before the widget has reported its state),
so clearing a field in the browser gives an empty field here too.

## Usage

``` r
safe_pivot_compute_from_config(
  data,
  config,
  default_rows = NULL,
  default_cols = NULL,
  default_vals = NULL,
  default_aggregator = "Median",
  default_inclusions = NULL,
  default_exclusions = NULL,
  missing_label = "(Missing)",
  show_missing_category = TRUE
)
```

## Arguments

- data:

  A data frame.

- config:

  A pivot configuration object, usually `input$<outputId>_config`.

- default_rows:

  Default row variables used when `config` is `NULL`.

- default_cols:

  Default column variables used when `config` is `NULL`.

- default_vals:

  Default value variable used when `config` is `NULL`.

- default_aggregator:

  Default aggregator used when `config` is `NULL`, or when `config` has
  no aggregator.

- default_inclusions, default_exclusions:

  Default filters used when `config` is `NULL`. Use the same values
  passed to
  [`safePivot()`](https://dongwenluo.github.io/safePivot/reference/safePivot.md).

- missing_label:

  Label for missing categorical values.

- show_missing_category:

  Whether missing categorical values are shown as a level.

## Value

A list with `long`, `wide`, and `config`. `config` also holds the
`inclusions` and `exclusions` that were applied.

## Details

Filters follow PivotTable.js: `exclusions` and `inclusions` are named
lists of values per variable. A row is dropped when its value is listed
in `exclusions`, or when its variable has `inclusions` and the value is
not listed there. Variables not present in `data` are ignored. Missing
values match `missing_label` for categorical variables and `"null"`
otherwise.

## Examples

``` r
res <- safe_pivot_compute_from_config(
  iris,
  config = NULL,
  default_rows = "Species",
  default_vals = "Sepal.Length",
  default_aggregator = "Median"
)

res <- safe_pivot_compute_from_config(
  iris,
  config = list(
    rows = list("Species"),
    vals = list("Sepal.Length"),
    aggregatorName = "Mean",
    exclusions = list(Species = list("setosa"))
  )
)
```
