# Using safePivot in Shiny

## Overview

`safePivot` provides a drag-and-drop pivot-table widget for Shiny
applications. The browser-side widget is used for interaction, while R
is used for reproducible computation and export.

The recommended Shiny workflow is:

1.  display the widget with
    [`safePivotOutput()`](https://dongwenluo.github.io/safePivot/reference/safePivotOutput.md);
2.  render it with
    [`renderSafePivot()`](https://dongwenluo.github.io/safePivot/reference/renderSafePivot.md);
3.  capture the current pivot configuration through
    `input$<outputId>_config`;
4.  recompute the current pivot result in R with
    [`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md);
5.  export the R-computed result with CSV, Excel, RDS, or RData helpers.

This design avoids scraping the HTML table from the browser. Instead,
the browser sends the pivot configuration back to Shiny, and R
recomputes the exported table from the original data.

## Minimal Shiny app

``` r

library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot Shiny example"),
  safePivotOutput("pivot", height = "650px")
)

server <- function(input, output, session) {
  output$pivot <- renderSafePivot({
    safePivot(
      iris,
      rows = "Species",
      vals = "Sepal.Length",
      aggregator = "Median",
      renderer = "Table",
      show_type_badges = TRUE
    )
  })
}

shinyApp(ui, server)
```

## Heatmap and conditional formatting

`safePivot` supports table and heatmap renderers, readable heatmap
palettes, and browser-side conditional formatting.

``` r

library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot heatmap example"),
  safePivotOutput("pivot", height = "650px")
)

server <- function(input, output, session) {
  output$pivot <- renderSafePivot({
    safePivot(
      mtcars,
      rows = "cyl",
      cols = "gear",
      vals = "mpg",
      aggregator = "Mean",
      renderer = "Heatmap",
      heatmap_palette = "blue_white_red",
      conditional_format = TRUE,
      conditional_format_mode = "both",
      show_row_totals = TRUE,
      show_col_totals = TRUE
    )
  })
}

shinyApp(ui, server)
```

Available heatmap palettes include:

- `"blue"`
- `"yellow_orange"`
- `"green"`
- `"blue_white_red"`
- `"green_red"`

Available conditional formatting modes are:

| Mode             | Behaviour                                 |
|------------------|-------------------------------------------|
| `"none"`         | No extra conditional formatting           |
| `"value"`        | Highlight high and low numeric values     |
| `"data_quality"` | Highlight empty cells and zero cells      |
| `"both"`         | Combine value and data-quality formatting |

The recommended visual priority is:

``` text
empty / unavailable cells > zero cells > heatmap or high-low value styling
```

## Export the current pivot table

The key helper for Shiny export is
[`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md).

The widget sends the current drag-and-drop state to Shiny as:

``` r

input$pivot_config
```

where `pivot` is the output ID used in:

``` r

safePivotOutput("pivot")
```

[`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md)
also accepts default rows, columns, values, and aggregator settings.
These defaults are important because `input$pivot_config` may be `NULL`
before the widget sends its first configuration back to Shiny.

The following app exports the current pivot result to CSV, Excel, RDS,
and RData.

``` r

library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot export example"),

  safePivotOutput("pivot", height = "650px"),

  hr(),

  fluidRow(
    column(3, downloadButton("download_csv", "Download CSV")),
    column(3, downloadButton("download_xlsx", "Download Excel")),
    column(3, downloadButton("download_rds", "Download RDS")),
    column(3, downloadButton("download_rdata", "Download RData"))
  ),

  hr(),

  h4("Current pivot configuration"),
  verbatimTextOutput("pivot_config")
)

server <- function(input, output, session) {
  dat <- reactive({
    iris
  })

  output$pivot <- renderSafePivot({
    safePivot(
      dat(),
      rows = "Species",
      vals = "Sepal.Length",
      aggregator = "Median",
      renderer = "Table",
      show_type_badges = TRUE,
      conditional_format = TRUE,
      conditional_format_mode = "both"
    )
  })

  output$pivot_config <- renderPrint({
    input$pivot_config
  })

  current_pivot <- reactive({
    safe_pivot_compute_from_config(
      data = dat(),
      config = input$pivot_config,
      default_rows = "Species",
      default_cols = NULL,
      default_vals = "Sepal.Length",
      default_aggregator = "Median"
    )
  })

  output$download_csv <- downloadHandler(
    filename = function() {
      "safePivot_result.csv"
    },
    content = function(file) {
      safe_pivot_write_csv(
        current_pivot(),
        file,
        which = "wide"
      )
    }
  )

  output$download_xlsx <- downloadHandler(
    filename = function() {
      "safePivot_result.xlsx"
    },
    content = function(file) {
      safe_pivot_write_xlsx(
        current_pivot(),
        file,
        include_heatmap = TRUE,
        include_conditional_format = TRUE,
        conditional_format_mode = "both",
        heatmap_palette = "blue_white_red"
      )
    }
  )

  output$download_rds <- downloadHandler(
    filename = function() {
      "safePivot_result.rds"
    },
    content = function(file) {
      safe_pivot_write_rds(
        current_pivot(),
        file
      )
    }
  )

  output$download_rdata <- downloadHandler(
    filename = function() {
      "safePivot_result.RData"
    },
    content = function(file) {
      safe_pivot_write_rdata(
        current_pivot(),
        file,
        object_name = "safePivot_result"
      )
    }
  )
}

shinyApp(ui, server)
```

## Why use config-based export?

A browser pivot table is interactive. Users can move variables between
rows, columns, and values, and they can change the aggregator.

Instead of trying to parse the displayed HTML table, `safePivot`
captures the current configuration and recomputes the result in R.

This gives three advantages:

- exported results are generated from the original data;
- export logic is testable in R;
- Shiny apps do not need custom HTML-scraping code.

## Export consistency

The interactive browser table and the R-side export engine use the same
aggregator names. This means a user can change the pivot table in the
browser and then export the current result through
[`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md).

`safePivot` distinguishes:

``` text
empty pivot cell  = no records exist for that row-column combination
observed missing  = a record exists, but the selected value is NA
observed zero     = a record exists and the selected numeric value is 0
```

For example:

``` r

quality_dat <- data.frame(
  row = c("A", "A", "A", "B", "B", "C"),
  col = c("X", "X", "Y", "X", "Y", "X"),
  y = c(0, 1, NA, 0, 5, NA)
)

safe_pivot_compute(
  quality_dat,
  rows = "row",
  cols = "col",
  vals = "y",
  aggregator = "N missing"
)$wide
```

In this example:

``` text
A × Y has one observed missing value, so N missing = 1.
C × X has one observed missing value, so N missing = 1.
C × Y has no records, so it remains NA.
```

Zero percentages use numeric non-missing values as the denominator:

``` r

safe_pivot_compute(
  quality_dat,
  rows = "row",
  cols = "col",
  vals = "y",
  aggregator = "Zero % within Cell"
)$wide
```

So:

``` text
A × X has values 0 and 1, so Zero % within Cell = 50.
A × Y has only NA, so Zero % within Cell = NA.
C × X has only NA, so Zero % within Cell = NA.
C × Y has no records, so it remains NA.
```

## Styled Excel export

Excel export can preserve safePivot-style visual cues.

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
  file = "safePivot-export.xlsx",
  include_heatmap = TRUE,
  include_conditional_format = TRUE,
  conditional_format_mode = "both",
  heatmap_palette = "blue_white_red"
)
```

The recommended priority is:

``` text
empty / unavailable cells > zero cells > heatmap or high-low value styling
```

## Variable type badges

`safePivot` can show data-type badges beside draggable variable names.

``` r

badge_dat <- data.frame(
  id = 1:3,
  score = c(1.2, 3.4, 5.6),
  group = factor(c("A", "B", "A")),
  ordered_group = factor(
    c("low", "medium", "high"),
    levels = c("low", "medium", "high"),
    ordered = TRUE
  ),
  name = c("x", "y", "z"),
  flag = c(TRUE, FALSE, TRUE),
  harvest_date = as.Date(c("2026-01-01", "2026-01-02", "2026-01-03")),
  timestamp = as.POSIXct(c(
    "2026-01-01 08:00:00",
    "2026-01-02 08:00:00",
    "2026-01-03 08:00:00"
  ))
)

safePivot(
  badge_dat,
  rows = "ordered_group",
  cols = "flag",
  vals = "score",
  aggregator = "Mean",
  show_type_badges = TRUE
)
```

The badges help users choose suitable variables for rows, columns, and
values. For ordered factors, always set levels explicitly if the order
matters.

## Row and column totals

You can control totals from R:

``` r

safePivot(
  mtcars,
  rows = "cyl",
  cols = "gear",
  vals = "mpg",
  aggregator = "Mean",
  renderer = "Heatmap",
  show_row_totals = TRUE,
  show_col_totals = FALSE
)
```

## Common aggregators

Useful aggregators include:

``` r

c(
  "Count",
  "Count unique",
  "List unique values",
  "N non-missing",
  "N missing",
  "Missing % within Cell",
  "Missing % of Row",
  "Missing % of Column",
  "Missing % of Total",
  "N zero",
  "N non-zero",
  "Zero % within Cell",
  "Zero % of Row",
  "Zero % of Column",
  "Zero % of Total",
  "Sum",
  "Mean",
  "Median",
  "Min",
  "Max",
  "Range",
  "Q1",
  "Q3",
  "IQR",
  "Variance",
  "SD",
  "SE",
  "CV %",
  "Sum as Fraction of Total",
  "Sum as Fraction of Rows",
  "Sum as Fraction of Columns",
  "Count as Fraction of Total",
  "Count as Fraction of Rows",
  "Count as Fraction of Columns"
)
```

## Notes for larger data

`safePivot` sends data to the browser for interactive pivoting. For
large data, filter, select, or aggregate first before sending data to
[`safePivot()`](https://dongwenluo.github.io/safePivot/reference/safePivot.md).

A practical workflow is:

1.  filter data in Shiny or in the database;
2.  send the reduced data to
    [`safePivot()`](https://dongwenluo.github.io/safePivot/reference/safePivot.md);
3.  use
    [`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md)
    for export;
4.  export only the current pivot result.
