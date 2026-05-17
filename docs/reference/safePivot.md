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
  max_rows = 50000,
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

  Initial aggregator name.

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

{"x":{"data":{"Sepal.Length":[5.1,4.9,4.7,4.6,5,5.4,4.6,5,4.4,4.9,5.4,4.8,4.8,4.3,5.8,5.7,5.4,5.1,5.7,5.1,5.4,5.1,4.6,5.1,4.8,5,5,5.2,5.2,4.7,4.8,5.4,5.2,5.5,4.9,5,5.5,4.9,4.4,5.1,5,4.5,4.4,5,5.1,4.8,5.1,4.6,5.3,5,7,6.4,6.9,5.5,6.5,5.7,6.3,4.9,6.6,5.2,5,5.9,6,6.1,5.6,6.7,5.6,5.8,6.2,5.6,5.9,6.1,6.3,6.1,6.4,6.6,6.8,6.7,6,5.7,5.5,5.5,5.8,6,5.4,6,6.7,6.3,5.6,5.5,5.5,6.1,5.8,5,5.6,5.7,5.7,6.2,5.1,5.7,6.3,5.8,7.1,6.3,6.5,7.6,4.9,7.3,6.7,7.2,6.5,6.4,6.8,5.7,5.8,6.4,6.5,7.7,7.7,6,6.9,5.6,7.7,6.3,6.7,7.2,6.2,6.1,6.4,7.2,7.4,7.9,6.4,6.3,6.1,7.7,6.3,6.4,6,6.9,6.7,6.9,5.8,6.8,6.7,6.7,6.3,6.5,6.2,5.9],"Sepal.Width":[3.5,3,3.2,3.1,3.6,3.9,3.4,3.4,2.9,3.1,3.7,3.4,3,3,4,4.4,3.9,3.5,3.8,3.8,3.4,3.7,3.6,3.3,3.4,3,3.4,3.5,3.4,3.2,3.1,3.4,4.1,4.2,3.1,3.2,3.5,3.6,3,3.4,3.5,2.3,3.2,3.5,3.8,3,3.8,3.2,3.7,3.3,3.2,3.2,3.1,2.3,2.8,2.8,3.3,2.4,2.9,2.7,2,3,2.2,2.9,2.9,3.1,3,2.7,2.2,2.5,3.2,2.8,2.5,2.8,2.9,3,2.8,3,2.9,2.6,2.4,2.4,2.7,2.7,3,3.4,3.1,2.3,3,2.5,2.6,3,2.6,2.3,2.7,3,2.9,2.9,2.5,2.8,3.3,2.7,3,2.9,3,3,2.5,2.9,2.5,3.6,3.2,2.7,3,2.5,2.8,3.2,3,3.8,2.6,2.2,3.2,2.8,2.8,2.7,3.3,3.2,2.8,3,2.8,3,2.8,3.8,2.8,2.8,2.6,3,3.4,3.1,3,3.1,3.1,3.1,2.7,3.2,3.3,3,2.5,3,3.4,3],"Petal.Length":[1.4,1.4,1.3,1.5,1.4,1.7,1.4,1.5,1.4,1.5,1.5,1.6,1.4,1.1,1.2,1.5,1.3,1.4,1.7,1.5,1.7,1.5,1,1.7,1.9,1.6,1.6,1.5,1.4,1.6,1.6,1.5,1.5,1.4,1.5,1.2,1.3,1.4,1.3,1.5,1.3,1.3,1.3,1.6,1.9,1.4,1.6,1.4,1.5,1.4,4.7,4.5,4.9,4,4.6,4.5,4.7,3.3,4.6,3.9,3.5,4.2,4,4.7,3.6,4.4,4.5,4.1,4.5,3.9,4.8,4,4.9,4.7,4.3,4.4,4.8,5,4.5,3.5,3.8,3.7,3.9,5.1,4.5,4.5,4.7,4.4,4.1,4,4.4,4.6,4,3.3,4.2,4.2,4.2,4.3,3,4.1,6,5.1,5.9,5.6,5.8,6.6,4.5,6.3,5.8,6.1,5.1,5.3,5.5,5,5.1,5.3,5.5,6.7,6.9,5,5.7,4.9,6.7,4.9,5.7,6,4.8,4.9,5.6,5.8,6.1,6.4,5.6,5.1,5.6,6.1,5.6,5.5,4.8,5.4,5.6,5.1,5.1,5.9,5.7,5.2,5,5.2,5.4,5.1],"Petal.Width":[0.2,0.2,0.2,0.2,0.2,0.4,0.3,0.2,0.2,0.1,0.2,0.2,0.1,0.1,0.2,0.4,0.4,0.3,0.3,0.3,0.2,0.4,0.2,0.5,0.2,0.2,0.4,0.2,0.2,0.2,0.2,0.4,0.1,0.2,0.2,0.2,0.2,0.1,0.2,0.2,0.3,0.3,0.2,0.6,0.4,0.3,0.2,0.2,0.2,0.2,1.4,1.5,1.5,1.3,1.5,1.3,1.6,1,1.3,1.4,1,1.5,1,1.4,1.3,1.4,1.5,1,1.5,1.1,1.8,1.3,1.5,1.2,1.3,1.4,1.4,1.7,1.5,1,1.1,1,1.2,1.6,1.5,1.6,1.5,1.3,1.3,1.3,1.2,1.4,1.2,1,1.3,1.2,1.3,1.3,1.1,1.3,2.5,1.9,2.1,1.8,2.2,2.1,1.7,1.8,1.8,2.5,2,1.9,2.1,2,2.4,2.3,1.8,2.2,2.3,1.5,2.3,2,2,1.8,2.1,1.8,1.8,1.8,2.1,1.6,1.9,2,2.2,1.5,1.4,2.3,2.4,1.8,1.8,2.1,2.4,2.3,1.9,2.3,2.5,2.3,1.9,2,2.3,1.8],"Species":["setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","setosa","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","versicolor","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica","virginica"]},"rows":"Species","cols":[],"vals":"Sepal.Length","aggregator":"Median","renderer":"Heatmap","missing_label":"(Missing)","factor_levels":{"Species":["setosa","versicolor","virginica"]},"respect_factor_order":true,"variable_types":{"Sepal.Length":{"type":"num","label":"numeric"},"Sepal.Width":{"type":"num","label":"numeric"},"Petal.Length":{"type":"num","label":"numeric"},"Petal.Width":{"type":"num","label":"numeric"},"Species":{"type":"fct","label":"factor"}},"numeric_digits":3,"show_row_totals":true,"show_col_totals":true,"heatmap_palette":"blue","show_type_badges":true,"conditional_format":true,"conditional_format_mode":"both","high_threshold":0.85,"low_threshold":0.15,"ui_font_size":16,"pill_font_size":17,"table_font_size":18,"badge_font_size":12,"plot_default_height":620,"plot_min_height":520,"plot_max_width":1150,"plot_font_size":16,"plot_title_size":20,"axis_title_size":16,"axis_tick_size":14,"legend_font_size":14,"plotly_layout":[],"plotly_config":[],"allowed_renderers":["Table","Heatmap","Row Heatmap","Col Heatmap","Bar Chart","Stacked Bar Chart","Horizontal Bar Chart","Horizontal Stacked Bar Chart","Line Chart","Area Chart","Scatter Chart","Multiple Pie Chart"],"allowed_aggregators":["Count","Count unique","List unique values","N non-missing","N missing","Non-missing %","Missing %","Non-missing % within Cell","Missing % within Cell","Non-missing % of Row","Non-missing % of Column","Non-missing % of Total","Missing % of Row","Missing % of Column","Missing % of Total","N zero","N non-zero","Zero % within Cell","Non-zero % within Cell","Zero % of Row","Zero % of Column","Zero % of Total","Non-zero % of Row","Non-zero % of Column","Non-zero % of Total","Mean","Median","Sum","Sum as Fraction of Total","Sum as Fraction of Rows","Sum as Fraction of Columns","Count as Fraction of Total","Count as Fraction of Rows","Count as Fraction of Columns","Min","Max","Range","Variance","SD","SE","CV %","Q1","Q3","IQR"]},"evals":[],"jsHooks":[]}
```
