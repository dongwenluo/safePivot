# Compute pivot result in R

Compute pivot result in R

## Usage

``` r
safe_pivot_compute(
  data,
  rows = NULL,
  cols = NULL,
  vals = NULL,
  aggregator = "Median",
  missing_label = "(Missing)",
  show_missing_category = TRUE
)
```

## Arguments

- data:

  A data frame.

- rows:

  Character vector of row variables.

- cols:

  Character vector of column variables.

- vals:

  Character vector of value variables.

- aggregator:

  Aggregator name.

- missing_label:

  Label for missing categorical values.

- show_missing_category:

  Whether missing categorical values are shown as a level.

## Value

A list with `long`, `wide`, and `config`.
