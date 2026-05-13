library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot_step 2: config capture test"),
  
  safePivotOutput("pivot", height = "600px"),
  
  hr(),
  
  h4("Current pivot config from JavaScript"),
  verbatimTextOutput("pivot_config")
)

server <- function(input, output, session) {
  output$pivot <- renderSafePivot({
    safePivot(
      iris,
      rows = "Species",
      vals = "Sepal.Length",
      aggregator = "Median",
      renderer = "Table"
    )
  })
  
  output$pivot_config <- renderPrint({
    input$pivot_config
  })
}

shinyApp(ui, server)
