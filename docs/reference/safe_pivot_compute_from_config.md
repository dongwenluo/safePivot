# Compute pivot result from a Shiny safePivot config

Compute pivot result from a Shiny safePivot config

## Usage

``` r
safe_pivot_compute_from_config(
  data,
  config,
  default_rows = NULL,
  default_cols = NULL,
  default_vals = NULL,
  default_aggregator = "Median",
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

  Default aggregator used when `config` is `NULL`.

- missing_label:

  Label for missing categorical values.

- show_missing_category:

  Whether missing categorical values are shown as a level.

## Value

A list with `long`, `wide`, and `config`.

## Examples

``` r
res <- safe_pivot_compute_from_config(
  iris,
  config = NULL,
  default_rows = "Species",
  default_vals = "Sepal.Length",
  default_aggregator = "Median"
)
```
