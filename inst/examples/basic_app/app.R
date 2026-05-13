library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot basic example"),
  
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
      heatmap_palette = "blue",
      conditional_format = TRUE,
      show_row_totals = TRUE,
      show_col_totals = TRUE
    )
  })
}

shinyApp(ui, server)

