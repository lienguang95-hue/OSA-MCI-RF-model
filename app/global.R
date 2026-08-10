# ============================================================================
# global.R -- deployment-safe final locked RF model loader
# OSA-MCI Shiny calculator
#
# This version intentionally removes ggforce/ggplot2/scales from the runtime
# dependencies. The probability donut is drawn with base R graphics in server.R.
# ============================================================================

options(stringsAsFactors = FALSE)

required_packages <- c("shiny", "caret", "randomForest")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0L) {
  stop(
    "Missing R package(s): ", paste(missing_packages, collapse = ", "),
    ". Please install them and redeploy the app."
  )
}

suppressPackageStartupMessages({
  library(shiny)
  library(caret)
  library(randomForest)
})

MODEL_FILE <- "AAA_locked_RF_bundle.rds"
if (!file.exists(MODEL_FILE)) {
  stop("Missing locked RF model bundle: ", MODEL_FILE)
}

bundle <- readRDS(MODEL_FILE)

EXPECTED_FINAL_VARS <- c(
  "Coffee_consumption",
  "Sports_status",
  "AHI",
  "MSaO2",
  "Depressive_symptoms_total_score",
  "Anxiety_total_score",
  "Drowsiness_total_score",
  "Stress_total_score",
  "Sleep_quality_total_score"
)

required_bundle_fields <- c(
  "model", "preprocessor", "final_vars", "threshold",
  "factor_levels", "positive_class"
)
missing_bundle_fields <- setdiff(required_bundle_fields, names(bundle))
if (length(missing_bundle_fields) > 0L) {
  stop(
    "Locked RF bundle is missing field(s): ",
    paste(missing_bundle_fields, collapse = ", ")
  )
}

if (!setequal(as.character(bundle$final_vars), EXPECTED_FINAL_VARS)) {
  stop(
    "The loaded bundle does not contain the expected final nine predictors. Found: ",
    paste(bundle$final_vars, collapse = ", ")
  )
}

if (!is.finite(as.numeric(bundle$threshold)) ||
    abs(as.numeric(bundle$threshold) - 0.3228) > 1e-8) {
  stop(
    "Locked RF threshold mismatch. Expected 0.3228; found ",
    as.character(bundle$threshold)
  )
}

if (!identical(as.character(bundle$positive_class), "Yes")) {
  stop("Unexpected positive class in locked bundle: ", bundle$positive_class)
}

TRAINING_RANGE <- list(
  AHI = c(5.2, 129.5),
  MSaO2 = c(32.5, 96.9),
  Depressive_symptoms_total_score = c(1, 19),
  Anxiety_total_score = c(0, 21),
  Drowsiness_total_score = c(0, 24),
  Stress_total_score = c(3, 56),
  Sleep_quality_total_score = c(0, 21)
)

predict_dummy_locked <- function(dummy_object, newdata) {
  method <- getS3method(
    f = "predict",
    class = "dummyVars",
    envir = asNamespace("caret")
  )
  method(dummy_object, newdata = newdata)
}

predict_train_prob_locked <- function(train_object, newdata, positive_class = "Yes") {
  method <- getS3method(
    f = "predict",
    class = "train",
    envir = asNamespace("caret")
  )
  out <- method(train_object, newdata = newdata, type = "prob")
  if (!positive_class %in% colnames(out)) {
    stop("Positive-class probability column not found: ", positive_class)
  }
  as.numeric(out[, positive_class])
}

validate_raw_input <- function(newdata) {
  if (!is.data.frame(newdata) || nrow(newdata) < 1L) {
    stop("newdata must be a non-empty data.frame.")
  }

  missing_vars <- setdiff(EXPECTED_FINAL_VARS, names(newdata))
  if (length(missing_vars) > 0L) {
    stop("Missing required input(s): ", paste(missing_vars, collapse = ", "))
  }

  x <- newdata[, EXPECTED_FINAL_VARS, drop = FALSE]

  if (any(is.na(x))) {
    stop(
      "All nine model inputs are required. The locked model was developed and ",
      "validated using complete cases without an imputation strategy."
    )
  }

  for (v in c("Coffee_consumption", "Sports_status")) {
    values <- as.character(x[[v]])
    if (any(!values %in% c("1", "2", "3"))) {
      stop(v, " must be coded as 1, 2, or 3.")
    }
  }

  for (v in names(TRAINING_RANGE)) {
    values <- suppressWarnings(as.numeric(x[[v]]))
    if (any(!is.finite(values))) {
      stop(v, " must be numeric and finite.")
    }
    r <- TRAINING_RANGE[[v]]
    if (any(values < r[1] | values > r[2])) {
      stop(v, " is outside the observed training range [", r[1], ", ", r[2], "].")
    }
    x[[v]] <- values
  }

  x
}

prepare_raw_predictors <- function(object, newdata) {
  x <- validate_raw_input(newdata)
  x <- x[, object$final_vars, drop = FALSE]

  for (v in intersect(names(object$factor_levels), names(x))) {
    x[[v]] <- factor(
      as.character(x[[v]]),
      levels = object$factor_levels[[v]]
    )
    if (any(is.na(x[[v]]))) {
      stop(
        "Input level for ", v,
        " is not present in the locked training factor levels."
      )
    }
  }
  x
}

apply_locked_preprocessor <- function(object, raw_x) {
  x_design <- as.data.frame(
    predict_dummy_locked(object$preprocessor$dummy, raw_x)
  )

  missing_cols <- setdiff(object$preprocessor$keep_cols, names(x_design))
  if (length(missing_cols) > 0L) {
    for (v in missing_cols) x_design[[v]] <- 0
  }

  x_design <- x_design[, object$preprocessor$keep_cols, drop = FALSE]
  x_design
}

predict_mci_probability <- function(object = bundle, newdata) {
  raw_x <- prepare_raw_predictors(object, newdata)
  x_design <- apply_locked_preprocessor(object, raw_x)
  p <- predict_train_prob_locked(
    object$model,
    x_design,
    positive_class = object$positive_class
  )

  if (any(!is.finite(p)) || any(p < 0 | p > 1)) {
    stop("Locked RF produced an invalid probability.")
  }
  p
}

classify_for_prioritization <- function(probability, object = bundle) {
  ifelse(
    probability >= as.numeric(object$threshold),
    "Prioritize formal cognitive assessment",
    "Below the model prioritization threshold"
  )
}
