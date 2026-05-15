
<!-- README.md is generated from README.Rmd. Please edit README.Rmd. -->

# safePivot

[![R-CMD-check](https://github.com/dongwenluo/safePivot/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dongwenluo/safePivot/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/dongwenluo/safePivot/branch/main/graph/badge.svg)](https://app.codecov.io/gh/dongwenluo/safePivot?branch=main)

`safePivot` is an R htmlwidget for safer interactive drag-and-drop pivot
tables. It wraps PivotTable.js and adds R-focused safeguards for
exploratory data analysis, Shiny export, and reproducible reporting
workflows.

The main idea is simple:

1.  use the browser for interactive pivot-table exploration;
2.  capture the current pivot configuration in Shiny;
3.  recompute the same pivot result in R;
4.  export the R-computed result to CSV, Excel, RDS, or RData.

`safePivot` is especially useful when empty cells, observed missing
values, and observed zero values must stay clearly separated.

## Installation

Install the development version from GitHub:

``` r
# install.packages("remotes")
remotes::install_github("dongwenluo/safePivot")
```

Load the package:

``` r
library(safePivot)
```

## Key features

- Interactive PivotTable.js drag-and-drop UI.
- Safe R-side pivot computation with `safe_pivot_compute()`.
- Shiny config capture with `input$<outputId>_config`.
- Config-based export with `safe_pivot_compute_from_config()`.
- CSV, Excel, RDS, and RData export helpers.
- Explicit missing, non-missing, zero, and non-zero aggregators.
- Within-cell, row, column, and total percentage aggregators.
- Sum/count fraction aggregators with explicit denominators.
- R factor-level ordering.
- Data-type badges for draggable variables.
- Browser-side conditional formatting for table output.
- Heatmap renderers with selectable palettes.
- Lightweight Plotly chart renderers.

## Basic use

``` r
safePivot(
  iris,
  rows = "Species",
  vals = "Sepal.Length",
  aggregator = "Median",
  renderer = "Table"
)
```

## Heatmap renderer

``` r
safePivot(
  iris,
  rows = "Species",
  cols = "Petal.Width",
  vals = "Sepal.Length",
  aggregator = "Median",
  renderer = "Heatmap",
  heatmap_palette = "green"
)
```

Available heatmap palettes are:

``` r
"blue"
"yellow_orange"
"green"
"blue_white_red"
"green_red"
```

Available heatmap renderers are:

``` r
"Heatmap"
"Row Heatmap"
"Col Heatmap"
```

Browser-side conditional formatting is intentionally disabled for
heatmap renderers so that heatmap palettes are not overwritten by
SafePivot table-cell formatting classes.

## Lightweight Plotly charts

`safePivot` includes lightweight Plotly renderers for quick visual
summaries:

``` r
safePivot(
  iris,
  rows = "Species",
  cols = "Petal.Width",
  vals = "Sepal.Length",
  aggregator = "Mean",
  renderer = "Bar Chart",
  plot_height = 620
)
```

Supported chart renderers include:

``` r
"Horizontal Bar Chart"
"Horizontal Stacked Bar Chart"
"Bar Chart"
"Stacked Bar Chart"
"Line Chart"
"Area Chart"
"Scatter Chart"
"Multiple Pie Chart"
```

Treemap is intentionally not included in the core package because it
requires a larger Plotly bundle and extra hierarchy-specific renderer
logic.

## Data-type badges

`safePivot` can show compact badges beside draggable variables. These
badges help users decide which variables are suitable for rows, columns,
or values before they start dragging.

| Badge  | Meaning           |
|--------|-------------------|
| `num`  | numeric / double  |
| `int`  | integer           |
| `chr`  | character         |
| `fct`  | factor            |
| `ord`  | ordered factor    |
| `date` | Date              |
| `time` | POSIX date-time   |
| `lgl`  | logical           |
| `list` | list column       |
| `obj`  | other object type |

``` r
safePivot(
  iris,
  rows = "Species",
  vals = "Sepal.Length",
  aggregator = "Median",
  renderer = "Table",
  show_type_badges = TRUE
)
```

## Factor order

If a variable is an R factor, `safePivot` can respect its factor-level
order.

``` r
iris2 <- iris
iris2$Species <- factor(
  iris2$Species,
  levels = c("virginica", "versicolor", "setosa")
)

safePivot(
  iris2,
  rows = "Species",
  vals = "Sepal.Length",
  aggregator = "Median",
  renderer = "Table",
  respect_factor_order = TRUE
)
```

For ordered factors, define levels explicitly instead of relying on
alphabetical order:

``` r
ordered_dat <- data.frame(
  stage = factor(
    c("low", "medium", "high"),
    levels = c("low", "medium", "high"),
    ordered = TRUE
  ),
  value = c(1, 2, 3)
)
```

## Aggregation rules

`safePivot` uses explicit aggregation rules so that empty pivot cells,
observed missing values, and observed zero values are not confused.

| Case | Meaning | Example | safePivot behaviour |
|----|----|----|----|
| Empty pivot cell | No records exist for this row-column combination | Row `C`, column `Y` has no rows in the data | Returned as `NA` after widening; not counted as missing |
| Observed missing value | A record exists, but the selected value is `NA` | `y = NA` | Counted by `N missing` |
| Observed zero value | A record exists and the selected numeric value is `0` | `y = 0` | Counted by `N zero` |

This distinction is important because a no-data cell is not a missing
measurement, and a missing measurement is not a zero.

### Example data for missing and zero logic

``` r
quality_dat <- data.frame(
  row = c("A", "A", "A", "B", "B", "C"),
  col = c("X", "X", "Y", "X", "Y", "X"),
  y = c(0, 1, NA, 0, 5, NA)
)
```

In this data:

- `A x X` has two observed numeric values: `0` and `1`.
- `A x Y` has one observed missing value: `NA`.
- `C x X` has one observed missing value: `NA`.
- `C x Y` has no records at all, so it is an empty pivot cell.

### Count-style aggregators

| Aggregator | Definition |
|----|----|
| `Count` | Number of observed records in the pivot cell |
| `N missing` | Number of observed records where the selected value is `NA` |
| `N non-missing` | Number of observed records where the selected value is not `NA` |
| `N zero` | Number of finite numeric non-missing values equal to `0` |
| `N non-zero` | Number of finite numeric non-missing values not equal to `0` |
| `Count unique` | Number of unique non-missing, non-blank values |
| `List unique values` | Sorted list of unique non-missing, non-blank values |

### Within-cell percentages

Within-cell percentages use only records inside the current pivot cell.

| Aggregator | Numerator | Denominator |
|----|----|----|
| `Missing % within Cell` | Cell `N missing` | Cell `Count` |
| `Non-missing % within Cell` | Cell `N non-missing` | Cell `Count` |
| `Zero % within Cell` | Cell `N zero` | Cell numeric non-missing count |
| `Non-zero % within Cell` | Cell `N non-zero` | Cell numeric non-missing count |

For a cell with values:

``` r
c(0, 1, NA)
```

`safePivot` uses:

``` text
Count                 = 3
N missing             = 1
N non-missing         = 2
N zero                = 1
N non-zero            = 1
Missing % within Cell = 1 / 3 * 100 = 33.3
Zero % within Cell    = 1 / 2 * 100 = 50
```

Zero percentages use the numeric non-missing denominator, so `NA` is not
treated as zero.

### Row, column, and total percentages

Row, column, and total percentages express the current cell as a
percentage of a larger denominator.

| Aggregator | Numerator | Denominator |
|----|----|----|
| `Missing % of Row` | Cell `N missing` | Row `Count` |
| `Missing % of Column` | Cell `N missing` | Column `Count` |
| `Missing % of Total` | Cell `N missing` | Total `Count` |
| `Non-missing % of Row` | Cell `N non-missing` | Row `Count` |
| `Non-missing % of Column` | Cell `N non-missing` | Column `Count` |
| `Non-missing % of Total` | Cell `N non-missing` | Total `Count` |
| `Zero % of Row` | Cell `N zero` | Row numeric non-missing count |
| `Zero % of Column` | Cell `N zero` | Column numeric non-missing count |
| `Zero % of Total` | Cell `N zero` | Total numeric non-missing count |
| `Non-zero % of Row` | Cell `N non-zero` | Row numeric non-missing count |
| `Non-zero % of Column` | Cell `N non-zero` | Column numeric non-missing count |
| `Non-zero % of Total` | Cell `N non-zero` | Total numeric non-missing count |

### Sum and count fractions

Fraction aggregators are different from missing/zero percentage
aggregators. They use numeric sums or record counts as denominators.

| Aggregator | Meaning |
|----|----|
| `Sum as Fraction of Total` | Cell numeric sum divided by total numeric sum |
| `Sum as Fraction of Rows` | Cell numeric sum divided by row numeric sum |
| `Sum as Fraction of Columns` | Cell numeric sum divided by column numeric sum |
| `Count as Fraction of Total` | Cell record count divided by total record count |
| `Count as Fraction of Rows` | Cell record count divided by row record count |
| `Count as Fraction of Columns` | Cell record count divided by column record count |

For example:

``` r
frac_dat <- data.frame(
  grp = c("A", "A", "B", "B"),
  col = c("X", "Y", "X", "Y"),
  y = c(1, 3, 2, 4)
)

safe_pivot_compute(
  frac_dat,
  rows = "grp",
  cols = "col",
  vals = "y",
  aggregator = "Sum as Fraction of Total"
)$wide
```

The total numeric sum is `1 + 3 + 2 + 4 = 10`, so the result is:

``` text
A x X = 1 / 10 * 100 = 10
A x Y = 3 / 10 * 100 = 30
B x X = 2 / 10 * 100 = 20
B x Y = 4 / 10 * 100 = 40
```

The count-fraction case that previously failed is now covered by
regression tests:

``` r
safe_pivot_compute(
  iris,
  rows = "Species",
  vals = "Sepal.Length",
  aggregator = "Count as Fraction of Total"
)$wide
#>      Species   .value
#> 1     setosa 33.33333
#> 2 versicolor 33.33333
#> 3  virginica 33.33333
```

## Conditional formatting

`safePivot` supports browser-side conditional formatting for normal
table output.

| Mode             | Behaviour                                 |
|------------------|-------------------------------------------|
| `"none"`         | No extra conditional formatting           |
| `"value"`        | Highlight high and low numeric values     |
| `"data_quality"` | Highlight empty cells and zero cells      |
| `"both"`         | Combine value and data-quality formatting |

``` r
safePivot(
  quality_dat,
  rows = "row",
  cols = "col",
  vals = "y",
  aggregator = "Sum",
  renderer = "Table",
  conditional_format = TRUE,
  conditional_format_mode = "both"
)
```

For heatmap renderers, use `heatmap_palette` rather than
`conditional_format_mode`. This keeps the heatmap colour scale clear and
avoids overwriting heatmap colours.

## Styled Excel export

Use `safe_pivot_write_xlsx()` to export the R-computed pivot table to
Excel. Excel export requires the optional package `openxlsx`.

``` r
res <- safe_pivot_compute(
  quality_dat,
  rows = "row",
  cols = "col",
  vals = "y",
  aggregator = "Sum"
)

safe_pivot_write_xlsx(
  res,
  file = "safePivot_result.xlsx",
  include_heatmap = TRUE,
  include_conditional_format = TRUE,
  conditional_format_mode = "both",
  heatmap_palette = "blue_white_red"
)
```

The Excel export writes the pivot table values and applies static cell
styles for heatmap-style colouring, empty cells, zero cells, and
high/low value highlighting.

## Shiny export pattern

The recommended Shiny pattern is to let the browser handle interaction,
but let R handle export. This avoids scraping the displayed HTML table.

``` r
library(shiny)
library(bslib)
library(safePivot)

ui <- page_fluid(
  titlePanel("safePivot export example"),

  layout_sidebar(
    sidebar = sidebar(
      selectInput(
        "renderer",
        "Renderer",
        choices = c(
          "Table",
          "Heatmap",
          "Row Heatmap",
          "Col Heatmap",
          "Bar Chart",
          "Stacked Bar Chart",
          "Line Chart",
          "Area Chart"
        ),
        selected = "Table"
      ),
      downloadButton("download_csv", "Download CSV"),
      downloadButton("download_xlsx", "Download Excel")
    ),

    safePivotOutput("pivot", height = "750px")
  )
)

server <- function(input, output, session) {
  dat <- reactive(iris)

  output$pivot <- renderSafePivot({
    safePivot(
      dat(),
      rows = "Species",
      vals = "Sepal.Length",
      aggregator = "Median",
      renderer = input$renderer,
      heatmap_palette = "green",
      show_type_badges = TRUE,
      conditional_format_mode = "both"
    )
  })

  current_pivot <- reactive({
    safe_pivot_compute_from_config(
      data = dat(),
      config = input$pivot_config,
      default_rows = "Species",
      default_vals = "Sepal.Length",
      default_aggregator = "Median"
    )
  })

  output$download_csv <- downloadHandler(
    filename = function() "safePivot_result.csv",
    content = function(file) {
      safe_pivot_write_csv(current_pivot(), file, which = "wide")
    }
  )

  output$download_xlsx <- downloadHandler(
    filename = function() "safePivot_result.xlsx",
    content = function(file) {
      safe_pivot_write_xlsx(
        current_pivot(),
        file,
        include_heatmap = TRUE,
        include_conditional_format = TRUE,
        conditional_format_mode = "both"
      )
    }
  )
}

shinyApp(ui, server)
```

`input$pivot_config` stores the current drag-and-drop state, including
rows, columns, values, aggregator, renderer, inclusions, and exclusions.

## Aggregator summary

| Type | Examples |
|----|----|
| Count | `Count`, `Count unique`, `List unique values` |
| Missingness | `N missing`, `N non-missing`, `Missing % within Cell`, `Missing % of Total` |
| Zero checks | `N zero`, `N non-zero`, `Zero % within Cell`, `Zero % of Row` |
| Numeric summary | `Sum`, `Mean`, `Median`, `Min`, `Max`, `Range` |
| Distribution | `Q1`, `Q3`, `IQR`, `Variance`, `SD`, `SE`, `CV %` |
| Fraction | `Sum as Fraction of Total`, `Count as Fraction of Rows` |

## Notes for larger data

`safePivot` sends data to the browser for interactive pivoting. For
large data, filter, select, or summarise first before sending data to
`safePivot()`.

A practical workflow is:

1.  filter data in Shiny or in the database;
2.  send the reduced data to `safePivot()`;
3.  use `safe_pivot_compute_from_config()` for export;
4.  export only the current pivot result.

## Development checks

Before pushing changes, run:

``` r
devtools::document()
devtools::load_all(reset = TRUE)
devtools::test()
devtools::check()
```

To rebuild this README after editing `README.Rmd`, run:

``` r
devtools::build_readme()
```

## Related work and acknowledgements

`safePivot` is inspired by `rpivotTable`, an R htmlwidget that brings
PivotTable.js / pivottable.js drag-and-drop pivot tables to R.

`safePivot` keeps the drag-and-drop table workflow but adds extra
safeguards for numeric aggregation, missing values, zero values,
factor-level ordering, readable heatmaps, Shiny config capture, and
R-side CSV/Excel/RDS/RData export.

We also acknowledge PivotTable.js by Nicolas Kruchten, the underlying
JavaScript pivot-table library used for the interactive browser-side
pivot UI.

## License

MIT
