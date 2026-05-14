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

safe_pivot_xlsx_palette <- function(palette = "blue_white_red") {
  switch(
    palette,
    "blue" = c("#F7FBFF", "#C6DBEF", "#6BAED6"),
    "yellow_orange" = c("#FFFFE5", "#FEE391", "#FDAE6B"),
    "green" = c("#F7FCF5", "#C7E9C0", "#74C476"),
    "green_red" = c("#D1FAE5", "#FFF7ED", "#F87171"),
    "blue_white_red" = c("#7777FF", "#FFFFFF", "#FF7777"),
    c("#7777FF", "#FFFFFF", "#FF7777")
  )
}

safe_pivot_xlsx_mix_col <- function(col1, col2, t) {
  t <- max(0, min(1, t))
  
  rgb1 <- grDevices::col2rgb(col1)
  rgb2 <- grDevices::col2rgb(col2)
  
  rgb <- round(rgb1 + (rgb2 - rgb1) * t)
  
  grDevices::rgb(
    red = rgb[1, 1],
    green = rgb[2, 1],
    blue = rgb[3, 1],
    maxColorValue = 255
  )
}

safe_pivot_xlsx_heat_col <- function(value, min_value, max_value, palette) {
  if (!is.finite(value) || !is.finite(min_value) || !is.finite(max_value)) {
    return(NA_character_)
  }
  
  cols <- safe_pivot_xlsx_palette(palette)
  
  if (isTRUE(all.equal(min_value, max_value))) {
    return(cols[[2]])
  }
  
  t <- (value - min_value) / (max_value - min_value)
  t <- max(0, min(1, t))
  
  if (t <= 0.5) {
    safe_pivot_xlsx_mix_col(cols[[1]], cols[[2]], t * 2)
  } else {
    safe_pivot_xlsx_mix_col(cols[[2]], cols[[3]], (t - 0.5) * 2)
  }
}

safe_pivot_xlsx_is_empty <- function(x) {
  if (length(x) == 0 || is.na(x)) {
    return(TRUE)
  }
  
  z <- trimws(as.character(x))
  
  z %in% c("", "NA", "NaN", "NULL", "null")
}

safe_pivot_xlsx_num <- function(x) {
  if (safe_pivot_xlsx_is_empty(x)) {
    return(NA_real_)
  }
  
  out <- suppressWarnings(as.numeric(x))
  
  if (length(out) == 0 || !is.finite(out)) {
    NA_real_
  } else {
    out
  }
}

safe_pivot_xlsx_style_cache <- function() {
  cache <- new.env(parent = emptyenv())
  
  get_style <- function(fill, font_colour = "#111827", bold = FALSE) {
    key <- paste(fill, font_colour, bold, sep = "|")
    
    if (!exists(key, envir = cache, inherits = FALSE)) {
      args <- list(
        fgFill = fill,
        fontColour = font_colour
      )
      
      if (isTRUE(bold)) {
        args$textDecoration <- "bold"
      }
      
      cache[[key]] <- do.call(openxlsx::createStyle, args)
    }
    
    cache[[key]]
  }
  
  get_style
}

safe_pivot_xlsx_apply_styles <- function(
    wb,
    sheet,
    dat,
    value_cols,
    include_heatmap = TRUE,
    include_conditional_format = TRUE,
    conditional_format_mode = "both",
    heatmap_palette = "blue_white_red",
    high_threshold = 0.85,
    low_threshold = 0.15,
    empty_fill = "#E5E7EB",
    zero_fill = "#FEF3C7",
    high_fill = "#FFF7ED",
    low_fill = "#EFF6FF"
) {
  if (nrow(dat) == 0 || length(value_cols) == 0) {
    return(invisible(wb))
  }
  
  allowed_modes <- c("none", "value", "data_quality", "both")
  
  if (!conditional_format_mode %in% allowed_modes) {
    stop(
      "Unsupported conditional_format_mode: ",
      conditional_format_mode,
      ". Supported values are: ",
      paste(allowed_modes, collapse = ", "),
      call. = FALSE
    )
  }
  
  style <- safe_pivot_xlsx_style_cache()
  
  numeric_values <- unlist(
    lapply(value_cols, function(j) {
      suppressWarnings(as.numeric(dat[[j]]))
    }),
    use.names = FALSE
  )
  
  numeric_values <- numeric_values[is.finite(numeric_values)]
  
  has_numeric <- length(numeric_values) > 0
  min_value <- if (has_numeric) min(numeric_values) else NA_real_
  max_value <- if (has_numeric) max(numeric_values) else NA_real_
  
  data_rows <- seq_len(nrow(dat)) + 1L
  
  for (i in seq_len(nrow(dat))) {
    excel_row <- i + 1L
    
    for (j in value_cols) {
      raw_value <- dat[[j]][[i]]
      num_value <- safe_pivot_xlsx_num(raw_value)
      
      is_empty <- safe_pivot_xlsx_is_empty(raw_value)
      is_zero <- is.finite(num_value) && isTRUE(all.equal(num_value, 0))
      
      cell_style <- NULL
      
      if (isTRUE(include_heatmap) && is.finite(num_value) && has_numeric) {
        fill <- safe_pivot_xlsx_heat_col(
          value = num_value,
          min_value = min_value,
          max_value = max_value,
          palette = heatmap_palette
        )
        
        if (!is.na(fill)) {
          cell_style <- style(fill = fill)
        }
      }
      
      if (isTRUE(include_conditional_format) && conditional_format_mode != "none") {
        if (is_empty) {
          cell_style <- style(
            fill = empty_fill,
            font_colour = "#6B7280"
          )
        } else if (
          conditional_format_mode %in% c("data_quality", "both") &&
          is_zero
        ) {
          cell_style <- style(
            fill = zero_fill,
            font_colour = "#78350F",
            bold = TRUE
          )
        } else if (
          conditional_format_mode %in% c("value", "both") &&
          is.finite(num_value) &&
          has_numeric &&
          !isTRUE(all.equal(min_value, max_value))
        ) {
          t <- (num_value - min_value) / (max_value - min_value)
          
          if (t >= high_threshold) {
            cell_style <- style(
              fill = high_fill,
              font_colour = "#111827",
              bold = TRUE
            )
          } else if (t <= low_threshold) {
            cell_style <- style(
              fill = low_fill,
              font_colour = "#1E3A8A",
              bold = TRUE
            )
          }
        }
      }
      
      if (!is.null(cell_style)) {
        openxlsx::addStyle(
          wb = wb,
          sheet = sheet,
          style = cell_style,
          rows = excel_row,
          cols = j,
          gridExpand = FALSE,
          stack = TRUE
        )
      }
    }
  }
  
  invisible(wb)
}

#' Write a safePivot result to an Excel workbook
#'
#' @param x A result from `safe_pivot_compute()` / `safe_pivot_compute_from_config()`,
#'   or a data frame.
#' @param file Output `.xlsx` file path.
#' @param sheet Worksheet name.
#' @param include_heatmap Whether to export heatmap-style cell fills.
#' @param include_conditional_format Whether to export conditional formatting
#'   styles.
#' @param conditional_format_mode One of `"none"`, `"value"`,
#'   `"data_quality"`, or `"both"`.
#' @param heatmap_palette Heatmap palette. One of `"blue"`, `"yellow_orange"`,
#'   `"green"`, `"green_red"`, or `"blue_white_red"`.
#' @param high_threshold Relative high-value threshold from 0 to 1.
#' @param low_threshold Relative low-value threshold from 0 to 1.
#' @param empty_fill Fill colour for empty / unavailable cells.
#' @param zero_fill Fill colour for displayed zero cells.
#' @param high_fill Fill colour for high-value cells.
#' @param low_fill Fill colour for low-value cells.
#' @param overwrite Whether to overwrite an existing file.
#'
#' @return Invisibly returns `file`.
#'
#' @export
safe_pivot_write_xlsx <- function(
    x,
    file,
    sheet = "safePivot",
    include_heatmap = TRUE,
    include_conditional_format = TRUE,
    conditional_format_mode = "both",
    heatmap_palette = "blue_white_red",
    high_threshold = 0.85,
    low_threshold = 0.15,
    empty_fill = "#E5E7EB",
    zero_fill = "#FEF3C7",
    high_fill = "#FFF7ED",
    low_fill = "#EFF6FF",
    overwrite = TRUE
) {
  if (is.list(x) && !is.null(x$wide)) {
    dat <- x$wide
    rows <- safe_pivot_chr(x$config$rows)
  } else if (is.data.frame(x)) {
    dat <- x
    rows <- character()
  } else {
    stop(
      "`x` must be a data frame or a result from safe_pivot_compute().",
      call. = FALSE
    )
  }
  
  dat <- as.data.frame(dat, stringsAsFactors = FALSE)
  
  if (nrow(dat) == 0) {
    stop("Cannot write an empty pivot table to xlsx.", call. = FALSE)
  }
  
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop(
      "Package 'openxlsx' is required to write xlsx files.",
      call. = FALSE
    )
  }
  
  if (!is.numeric(high_threshold) || length(high_threshold) != 1 ||
      is.na(high_threshold) || high_threshold < 0 || high_threshold > 1) {
    stop("`high_threshold` must be a single number between 0 and 1.", call. = FALSE)
  }
  
  if (!is.numeric(low_threshold) || length(low_threshold) != 1 ||
      is.na(low_threshold) || low_threshold < 0 || low_threshold > 1) {
    stop("`low_threshold` must be a single number between 0 and 1.", call. = FALSE)
  }
  
  if (low_threshold >= high_threshold) {
    stop("`low_threshold` must be smaller than `high_threshold`.", call. = FALSE)
  }
  
  allowed_modes <- c("none", "value", "data_quality", "both")
  
  if (!conditional_format_mode %in% allowed_modes) {
    stop(
      "Unsupported conditional_format_mode: ",
      conditional_format_mode,
      ". Supported values are: ",
      paste(allowed_modes, collapse = ", "),
      call. = FALSE
    )
  }
  
  row_cols <- match(rows, names(dat))
  row_cols <- row_cols[!is.na(row_cols)]
  
  value_cols <- setdiff(seq_along(dat), row_cols)
  
  wb <- openxlsx::createWorkbook()
  openxlsx::addWorksheet(wb, sheet)
  
  header_style <- openxlsx::createStyle(
    fgFill = "#E8F0F0",
    fontColour = "#111827",
    textDecoration = "bold",
    halign = "center"
  )
  
  openxlsx::writeData(
    wb = wb,
    sheet = sheet,
    x = dat,
    startRow = 1,
    startCol = 1,
    headerStyle = header_style,
    keepNA = FALSE
  )
  
  openxlsx::freezePane(
    wb = wb,
    sheet = sheet,
    firstActiveRow = 2,
    firstActiveCol = max(length(row_cols), 1) + 1
  )
  
  openxlsx::setColWidths(
    wb = wb,
    sheet = sheet,
    cols = seq_along(dat),
    widths = "auto"
  )
  
  safe_pivot_xlsx_apply_styles(
    wb = wb,
    sheet = sheet,
    dat = dat,
    value_cols = value_cols,
    include_heatmap = include_heatmap,
    include_conditional_format = include_conditional_format,
    conditional_format_mode = conditional_format_mode,
    heatmap_palette = heatmap_palette,
    high_threshold = high_threshold,
    low_threshold = low_threshold,
    empty_fill = empty_fill,
    zero_fill = zero_fill,
    high_fill = high_fill,
    low_fill = low_fill
  )
  
  openxlsx::saveWorkbook(
    wb = wb,
    file = file,
    overwrite = overwrite
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
