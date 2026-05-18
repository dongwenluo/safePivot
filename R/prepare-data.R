# ============================================================
# prepare-data.R
# Data preparation helpers for safePivot
# ============================================================

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}


# ------------------------------------------------------------
# Extract factor levels
# ------------------------------------------------------------
safe_pivot_factor_levels <- function(data) {
  
  stopifnot(is.data.frame(data))
  
  levs <- lapply(data, function(x) {
    
    if (!is.factor(x)) {
      return(NULL)
    }
    
    levels(x)
  })
  
  levs[!vapply(levs, is.null, logical(1))]
}


# ------------------------------------------------------------
# Normalize factor columns safely
# ------------------------------------------------------------
safe_pivot_normalize_factor <- function(
    x,
    missing_label = "(Missing)",
    drop_unused_levels = FALSE
) {
  
  stopifnot(is.factor(x))
  
  # ----------------------------------------------------------
  # Optionally remove unused levels
  # ----------------------------------------------------------
  if (isTRUE(drop_unused_levels)) {
    x <- droplevels(x)
  }
  
  # ----------------------------------------------------------
  # Preserve original factor ordering
  # ----------------------------------------------------------
  old_levels <- levels(x)
  
  # Remove pathological blank-string levels
  old_levels <- old_levels[
    nzchar(trimws(old_levels))
  ]
  
  # ----------------------------------------------------------
  # Temporary character conversion for safe cleaning
  # ----------------------------------------------------------
  x_chr <- as.character(x)
  
  # Blank strings -> NA
  x_chr[!nzchar(trimws(x_chr))] <- NA_character_
  
  # Detect REAL missing observations
  has_missing <- any(is.na(x_chr))
  
  # Replace actual missing values
  x_chr[is.na(x_chr)] <- missing_label
  
  # ----------------------------------------------------------
  # Preserve original ordering
  # Missing level always LAST
  # ----------------------------------------------------------
  new_levels <- old_levels
  
  if (has_missing) {
    new_levels <- c(new_levels, missing_label)
  }
  
  new_levels <- unique(new_levels)
  
  # ----------------------------------------------------------
  # Rebuild factor preserving ordered status
  # ----------------------------------------------------------
  # factor(
  #   x_chr,
  #   levels = new_levels,
  #   ordered = is.ordered(x)
  # )
  # ----------------------------------------------------------
  # observed NON-missing values
  observed_values <- unique(
    stats::na.omit(
      x_chr[x_chr != missing_label]
    )
  )
  
  # one observed level -> character
  # avoids white-board issue in PivotTable.js/htmlwidget
  if (length(observed_values) <= 1) {
    return(x_chr)
  }
  
  # otherwise preserve factor
  factor(
    x_chr,
    levels = new_levels,
    ordered = is.ordered(x)
  )
}


# ------------------------------------------------------------
# Normalize character/date-like columns
# ------------------------------------------------------------
safe_pivot_normalize_character <- function(
    x,
    missing_label = "(Missing)"
) {
  
  x_chr <- as.character(x)
  
  x_chr[
    is.na(x_chr) |
      !nzchar(trimws(x_chr))
  ] <- missing_label
  
  x_chr
}


# ------------------------------------------------------------
# Prepare data for safePivot
# ------------------------------------------------------------
safe_pivot_prepare_data <- function(
    data,
    missing_label = "(Missing)",
    show_missing_category = TRUE,
    group_vars = NULL,
    drop_unused_levels = FALSE
) {
  
  stopifnot(is.data.frame(data))
  
  if (!isTRUE(show_missing_category)) {
    return(data)
  }
  
  missing_label <- as.character(missing_label)[[1]]
  
  # ----------------------------------------------------------
  # Determine target grouping variables
  # ----------------------------------------------------------
  if (is.null(group_vars)) {
    
    target_vars <- names(data)[vapply(
      data,
      function(x) {
        
        is.factor(x) ||
          is.character(x) ||
          inherits(
            x,
            c(
              "Date",
              "POSIXct",
              "POSIXlt",
              "POSIXt"
            )
          )
      },
      logical(1)
    )]
    
  } else {
    
    group_vars <- trimws(
      as.character(
        unlist(group_vars, use.names = FALSE)
      )
    )
    
    group_vars <- group_vars[
      !is.na(group_vars) &
        nzchar(group_vars)
    ]
    
    target_vars <- intersect(
      group_vars,
      names(data)
    )
  }
  
  if (length(target_vars) == 0) {
    return(data)
  }
  
  # ----------------------------------------------------------
  # Process grouping variables
  # ----------------------------------------------------------
  for (nm in target_vars) {
    
    x <- data[[nm]]
    
    # --------------------------------------------------------
    # Factor variables
    # --------------------------------------------------------
    if (is.factor(x)) {
      
      data[[nm]] <- safe_pivot_normalize_factor(
        x,
        missing_label = missing_label,
        drop_unused_levels = drop_unused_levels
      )
      
      next
    }
    
    # --------------------------------------------------------
    # Character / Date / Date-time
    # --------------------------------------------------------
    if (
      is.character(x) ||
      inherits(
        x,
        c(
          "Date",
          "POSIXct",
          "POSIXlt",
          "POSIXt"
        )
      )
    ) {
      
      data[[nm]] <- safe_pivot_normalize_character(
        x,
        missing_label = missing_label
      )
      
      next
    }
    
    # --------------------------------------------------------
    # Numeric/logical/list/object columns:
    # intentionally left unchanged.
    #
    # numeric NA must remain NA so
    # missing-value aggregators work properly.
    # --------------------------------------------------------
  }
  
  data
}


