# Safe drag-and-drop pivot table htmlwidget

Create an interactive drag-and-drop pivot table using PivotTable.js,
with safer numeric aggregators, missing-value handling, factor-level
ordering, heatmap renderers, conditional formatting, and Shiny support.

## Usage

``` r
safePivot(
  data,
  rows = NULL,
  cols = NULL,
  vals = NULL,
  aggregator = "Median",
  renderer = "Table",
  missing_label = "(Missing)",
  show_missing_category = TRUE,
  respect_factor_order = TRUE,
  numeric_digits = 3,
  show_row_totals = TRUE,
  show_col_totals = TRUE,
  heatmap_palette = "blue",
  show_type_badges = TRUE,
  conditional_format = TRUE,
  conditional_format_mode = "both",
  high_threshold = 0.85,
  low_threshold = 0.15,
  max_rows = 50000,
  width = "100%",
  height = 600
)
```

## Arguments

- data:

  A data frame.

- rows:

  Character vector of initial row variables.

- cols:

  Character vector of initial column variables.

- vals:

  Character vector of initial value variable. In v0.1, use one value
  variable.

- aggregator:

  Initial aggregator name.

- renderer:

  Initial renderer name. Supported values are `"Table"`, `"Heatmap"`,
  `"Row Heatmap"`, and `"Col Heatmap"`.

- missing_label:

  Label used for missing categorical values.

- show_missing_category:

  Whether missing categorical values should be shown as a category.

- respect_factor_order:

  Whether R factor levels should control display order.

- numeric_digits:

  Number of digits used for displayed numeric values.

- show_row_totals:

  Whether to show row totals in table renderers.

- show_col_totals:

  Whether to show column totals in table renderers.

- heatmap_palette:

  Heatmap palette. One of `"blue"`, `"yellow_orange"`, `"green"`,
  `"blue_white_red"`, or `"green_red"`.

- show_type_badges:

  Whether to show small data-type badges beside draggable variable names
  in the pivot UI.

- conditional_format:

  Whether to apply browser-side conditional formatting to pivot table
  cells.

- conditional_format_mode:

  Conditional formatting mode. One of `"none"`, `"value"`,
  `"data_quality"`, or `"both"`. `"none"` applies no extra formatting.
  `"value"` highlights high and low numeric values. `"data_quality"`
  highlights empty cells and zero values. `"both"` combines value and
  data-quality formatting.

- high_threshold:

  Relative threshold for high-value cell formatting. Values are scaled
  from 0 to 1 within the displayed pivot table.

- low_threshold:

  Relative threshold for low-value cell formatting. Values are scaled
  from 0 to 1 within the displayed pivot table.

- max_rows:

  Maximum number of rows allowed for browser-side pivoting.

- width:

  Widget width.

- height:

  Widget height.

## Value

An htmlwidget object.

## Examples

``` r
if (interactive()) {
  safePivot(
    iris,
    rows = "Species",
    vals = "Sepal.Length",
    aggregator = "Median",
    renderer = "Heatmap"
  )
}
```
