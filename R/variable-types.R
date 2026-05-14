safe_pivot_variable_type_one <- function(x) {
  if (inherits(x, "POSIXct") || inherits(x, "POSIXlt") || inherits(x, "POSIXt")) {
    return("time")
  }
  
  if (inherits(x, "Date")) {
    return("date")
  }
  
  if (is.ordered(x)) {
    return("ord")
  }
  
  if (is.factor(x)) {
    return("fct")
  }
  
  if (is.logical(x)) {
    return("lgl")
  }
  
  if (is.integer(x)) {
    return("int")
  }
  
  if (is.numeric(x)) {
    return("num")
  }
  
  if (is.character(x)) {
    return("chr")
  }
  
  if (is.list(x)) {
    return("list")
  }
  
  "obj"
}

safe_pivot_variable_type_label <- function(type) {
  labels <- c(
    num = "numeric",
    int = "integer",
    chr = "character",
    fct = "factor",
    ord = "ordered factor",
    date = "Date",
    time = "date-time",
    lgl = "logical",
    list = "list",
    obj = "object"
  )
  
  out <- unname(labels[type])
  out[is.na(out)] <- "object"
  
  out
}

safe_pivot_variable_types <- function(data) {
  stopifnot(is.data.frame(data))
  
  types <- vapply(
    data,
    safe_pivot_variable_type_one,
    character(1)
  )
  
  labels <- safe_pivot_variable_type_label(types)
  
  out <- Map(
    function(type, label) {
      list(
        type = type,
        label = label
      )
    },
    type = unname(types),
    label = unname(labels)
  )
  
  names(out) <- names(data)
  
  out
}
