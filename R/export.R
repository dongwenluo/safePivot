#' Write pivot result to CSV
#'
#' @param pivot_result A result object returned by `safe_pivot_compute()`.
#' @param file Output file path.
#' @param which Which result table to write: `"wide"` or `"long"`.
#'
#' @return Invisibly returns `file`.
#' @export
safe_pivot_write_csv <- function(pivot_result, file, which = c("wide", "long")) {
  which <- match.arg(which)
  utils::write.csv(pivot_result[[which]], file = file, row.names = FALSE)
  invisible(file)
}

#' Write pivot result to Excel
#'
#' @param pivot_result A result object returned by `safe_pivot_compute()`.
#' @param file Output `.xlsx` file path.
#'
#' @return Invisibly returns `file`.
#' @export
safe_pivot_write_xlsx <- function(pivot_result, file) {
  config_df <- data.frame(
    item = names(pivot_result$config),
    value = vapply(
      pivot_result$config,
      function(x) paste(x, collapse = ", "),
      character(1)
    )
  )
  
  openxlsx::write.xlsx(
    x = list(
      wide = pivot_result$wide,
      long = pivot_result$long,
      config = config_df
    ),
    file = file,
    asTable = TRUE,
    overwrite = TRUE
  )
  
  invisible(file)
}

#' Write pivot result to RDS
#'
#' @param pivot_result A result object returned by `safe_pivot_compute()`.
#' @param file Output `.rds` file path.
#'
#' @return Invisibly returns `file`.
#' @export
safe_pivot_write_rds <- function(pivot_result, file) {
  saveRDS(pivot_result, file = file)
  invisible(file)
}

#' Write pivot result to RData
#'
#' @param pivot_result A result object returned by `safe_pivot_compute()`.
#' @param file Output `.RData` file path.
#' @param object_name Name of the object saved inside the `.RData` file.
#'
#' @return Invisibly returns `file`.
#' @export
safe_pivot_write_rdata <- function(
    pivot_result,
    file,
    object_name = "pivot_result"
) {
  env <- new.env(parent = emptyenv())
  assign(object_name, pivot_result, envir = env)
  save(list = object_name, file = file, envir = env)
  invisible(file)
}
