library(shiny)
library(safePivot)

cfg_chr <- function(x) {
  if (is.null(x)) {
    return(character())
  }
  
  if (is.list(x)) {
    x <- unlist(x, use.names = FALSE)
  }
  
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  x
}


ui <- fluidPage(
  titlePanel("safePivot_step 3: export current pivot"),
  
  safePivotOutput("pivot", height = "600px"),
  
  hr(),
  
  h4("Current pivot config from JavaScript"),
  verbatimTextOutput("pivot_config"),
  
  hr(),
  
  downloadButton("download_csv", "Download CSV"),
  downloadButton("download_xlsx", "Download Excel"),
  downloadButton("download_rds", "Download RDS"),
  downloadButton("download_rdata", "Download RData")
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
      renderer = "Table"
    )
  })
  
  output$pivot_config <- renderPrint({
    input$pivot_config
  })
 
  current_pivot_result <- reactive({
    safe_pivot_compute_from_config(
      data = dat(),
      config = input$pivot_config,
      default_rows = "Species",
      default_cols = NULL,
      default_vals = "Sepal.Length",
      default_aggregator = "Median"
    )
  })
  
  # current_pivot_result <- reactive({
  #   cfg <- input$pivot_config
  #   
  #   if (is.null(cfg)) {
  #     return(
  #       safe_pivot_compute(
  #         dat(),
  #         rows = "Species",
  #         cols = character(),
  #         vals = "Sepal.Length",
  #         aggregator = "Median"
  #       )
  #     )
  #   }
  #   
  #   rows <- cfg_chr(cfg$rows)
  #   cols <- cfg_chr(cfg$cols)
  #   vals <- cfg_chr(cfg$vals)
  #   
  #   aggregator <- cfg$aggregatorName
  #   if (is.null(aggregator) || length(aggregator) == 0 || is.na(aggregator)) {
  #     aggregator <- "Median"
  #   } else {
  #     aggregator <- as.character(aggregator)[1]
  #   }
  #   
  #   safe_pivot_compute(
  #     dat(),
  #     rows = rows,
  #     cols = cols,
  #     vals = vals,
  #     aggregator = aggregator
  #   )
  # })
  
  output$download_csv <- downloadHandler(
    filename = function() {
      "safePivot_result.csv"
    },
    content = function(file) {
      safe_pivot_write_csv(
        current_pivot_result(),
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
        current_pivot_result(),
        file
      )
    }
  )
  
  output$download_rds <- downloadHandler(
    filename = function() {
      "safePivot_result.rds"
    },
    content = function(file) {
      safe_pivot_write_rds(
        current_pivot_result(),
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
        current_pivot_result(),
        file,
        object_name = "safePivot_result"
      )
    }
  )
}

shinyApp(ui, server)

