library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot export example"),
  
  safePivotOutput("pivot", height = "850px"),
  
  hr(),
  
  fluidRow(
    column(3, downloadButton("download_csv", "Download CSV")),
    column(3, downloadButton("download_xlsx", "Download Excel")),
    column(3, downloadButton("download_rds", "Download RDS")),
    column(3, downloadButton("download_rdata", "Download RData"))
  ),
  
  hr(),
  
  h4("Current pivot config"),
  verbatimTextOutput("pivot_config")
)

server <- function(input, output, session) {
  dat <- reactive({
    mtcars
  })
  
  output$pivot <- renderSafePivot({
    safePivot(
      dat(),
      rows = "gear",
      cols = "carb",
      vals = "mpg",
      aggregator = "Median",
      heatmap_palette = "blue_white_red",
      renderer = "Bar Chart",
    )
  })
  
  output$pivot_config <- renderPrint({
    input$pivot_config
  })
  
  current_pivot <- reactive({
    safe_pivot_compute_from_config(
      data = dat(),
      config = input$pivot_config,
      default_rows = "gear",
      default_vals = "mpg",
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
      safe_pivot_write_xlsx(current_pivot(), file)
    }
  )
  
  output$download_rds <- downloadHandler(
    filename = function() "safePivot_result.rds",
    content = function(file) {
      safe_pivot_write_rds(current_pivot(), file)
    }
  )
  
  output$download_rdata <- downloadHandler(
    filename = function() "safePivot_result.RData",
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
