#' Shiny output binding for safePivot
#'
#' @param outputId Output variable name.
#' @param width Width of the widget.
#' @param height Height of the widget.
#'
#' @return A Shiny widget output object.
#' @export
safePivotOutput <- function(outputId, width = "100%", height = "600px") {
  htmlwidgets::shinyWidgetOutput(
    outputId = outputId,
    name = "safePivot",
    width = width,
    height = height,
    package = "safePivot"
  )
}

#' Shiny render function for safePivot
#'
#' @param expr An expression that returns a safePivot widget.
#' @param env Environment in which to evaluate `expr`.
#' @param quoted Whether `expr` is already quoted.
#'
#' @return A Shiny render function.
#' @export
renderSafePivot <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  
  htmlwidgets::shinyRenderWidget(
    expr = expr,
    outputFunction = safePivotOutput,
    env = env,
    quoted = TRUE
  )
}