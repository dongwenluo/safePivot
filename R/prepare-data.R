`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

safe_pivot_factor_levels <- function(data) {
  levs <- lapply(data, function(x) {
    if (is.factor(x)) levels(x) else NULL
  })
  
  levs[!vapply(levs, is.null, logical(1))]
}

safe_pivot_prepare_data <- function(
    data,
    missing_label = "(Missing)",
    show_missing_category = TRUE
) {
  stopifnot(is.data.frame(data))
  
  data[] <- lapply(data, function(x) {
    if (is.factor(x)) {
      x <- as.character(x)
      if (show_missing_category) {
        x[is.na(x) | trimws(x) == ""] <- missing_label
      }
      return(x)
    }
    
    if (is.character(x)) {
      if (show_missing_category) {
        x[is.na(x) | trimws(x) == ""] <- missing_label
      }
      return(x)
    }
    
    if (inherits(x, c("Date", "POSIXct", "POSIXlt"))) {
      x <- as.character(x)
      if (show_missing_category) {
        x[is.na(x) | trimws(x) == ""] <- missing_label
      }
      return(x)
    }
    
    # Important: keep numeric NA as NA.
    # Do not turn missing numeric values into zero.
    x
  })
  
  data
}
