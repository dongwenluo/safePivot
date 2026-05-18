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
  aggregator = "Count",
  renderer = "Table",
  missing_label = "(Missing)",
  show_missing_category = TRUE,
  respect_factor_order = TRUE,
  numeric_digits = 3,
  show_row_totals = TRUE,
  show_col_totals = TRUE,
  heatmap_palette = "green",
  show_type_badges = TRUE,
  conditional_format = TRUE,
  conditional_format_mode = "both",
  high_threshold = 0.85,
  low_threshold = 0.15,
  ui_font_size = 16,
  pill_font_size = 17,
  table_font_size = 18,
  badge_font_size = 12,
  plot_default_height = 620,
  plot_min_height = 520,
  plot_max_width = 1150,
  plot_font_size = 16,
  plot_title_size = 20,
  axis_title_size = 16,
  axis_tick_size = 14,
  legend_font_size = 14,
  plotly_layout = NULL,
  plotly_config = NULL,
  max_rows = 1e+05,
  width = "100%",
  height = NULL
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

  Initial aggregator name. One of `"Count"`, `"Count unique"`,
  `"List unique values"`, `"N non-missing"`, `"N missing"`,
  `"Non-missing %"`, `"Missing %"`, `"Non-missing % within Cell"`,
  `"Missing % within Cell"`, `"Non-missing % of Row"`,
  `"Non-missing % of Column"`, `"Non-missing % of Total"`,
  `"Missing % of Row"`, `"Missing % of Column"`, `"Missing % of Total"`,
  `"N zero"`, `"N non-zero"`, `"Zero % within Cell"`,
  `"Non-zero % within Cell"`, `"Zero % of Row"`, `"Zero % of Column"`,
  `"Zero % of Total"`, `"Non-zero % of Row"`, `"Non-zero % of Column"`,
  `"Non-zero % of Total"`, `"Mean"`, `"Median"`, `"Sum"`,
  `"Sum as Fraction of Total"`, `"Sum as Fraction of Rows"`,
  `"Sum as Fraction of Columns"`, `"Count as Fraction of Total"`,
  `"Count as Fraction of Rows"`, `"Count as Fraction of Columns"`,
  `"Min"`, `"Max"`, `"Range"`, `"Variance"`, `"SD"`, `"SE"`, `"CV %"`,
  `"Q1"`, `"Q3"`, or `"IQR"`.

- renderer:

  Initial renderer. One of `"Table"`, `"Heatmap"`, `"Row Heatmap"`,
  `"Col Heatmap"`, `"Bar Chart"`, `"Stacked Bar Chart"`,
  `"Horizontal Bar Chart"`, `"Horizontal Stacked Bar Chart"`,
  `"Line Chart"`, `"Area Chart"`, `"Scatter Chart"`, or
  `"Multiple Pie Chart"`.

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

- ui_font_size, pill_font_size, table_font_size, badge_font_size:

  Font sizes used by the browser UI, draggable variable pills, pivot
  table, and type badges.

- plot_default_height, plot_min_height, plot_max_width:

  Default Plotly chart sizing controls used by chart renderers.

- plot_font_size, plot_title_size, axis_title_size, axis_tick_size,
  legend_font_size:

  Font sizes used by Plotly chart renderers.

- plotly_layout:

  Optional named list of Plotly layout values merged into the default
  chart layout.

- plotly_config:

  Optional named list of Plotly config values merged into the default
  chart config.

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
