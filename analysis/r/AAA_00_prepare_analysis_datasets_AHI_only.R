# ============================================================================
# AAA_00_prepare_analysis_datasets_AHI_only.R
# Rebuild all analysis-ready datasets from the four complete source files.
# Run from the 07_R_Code folder. R version: 4.4.3.
# ============================================================================

get_script_dir <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  hit <- grep("^--file=", args, value = TRUE)
  if (length(hit) > 0L) return(dirname(normalizePath(sub("^--file=", "", hit[1]))))
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    p <- rstudioapi::getActiveDocumentContext()$path
    if (nzchar(p)) return(dirname(normalizePath(p)))
  }
  normalizePath(getwd())
}
SCRIPT_DIR <- get_script_dir()
PROJECT_ROOT <- normalizePath(file.path(SCRIPT_DIR, ".."), mustWork = TRUE)

source_dir <- file.path(PROJECT_ROOT, "00_Full_Source_Data")

source_files <- c(
  Training = file.path(source_dir, "Full_Training_With_MoCA_BJ.csv"),
  InternalValidation = file.path(source_dir, "Full_InternalValidation_With_MoCA_BJ.csv"),
  ExternalValidation = file.path(source_dir, "Full_ExternalValidation_With_MoCA_BJ.csv"),
  Original400ReferenceOnly = file.path(source_dir, "Full_Original400ReferenceOnly_With_MoCA_BJ.csv")
)

read_source <- function(path) {
  if (!file.exists(path)) stop("Missing source file: ", path)
  read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
}
data_list <- lapply(source_files, read_source)

candidate_predictors <- c(
  "Age", "Gender", "Education_level", "Marital_status", "Income_status", "BMI",
  "OSA_duration", "Smoking_status", "Alcohol_consumption", "Coffee_consumption",
  "Sports_status", "Hypertension", "Diabetes", "Heart_disease",
  "Cerebrovascular_disease", "Hyperlipidemia", "AHI", "ODI",
  "Total_sleep_time", "MSaO2", "LSaO2", "Depressive_symptoms_total_score",
  "Anxiety_total_score", "Drowsiness_total_score", "Stress_total_score",
  "Social_support_total_score", "Sleep_quality_total_score"
)
main_columns <- c("Result", candidate_predictors)
current_seven <- character(0)
no_psych <- setdiff(candidate_predictors, c(
  "Depressive_symptoms_total_score", "Anxiety_total_score", "Stress_total_score"
))
psg_clinical <- intersect(candidate_predictors, c(
  "Age", "Gender", "Education_level", "BMI", "AHI", "ODI",
  "Total_sleep_time", "MSaO2", "LSaO2", "Hypertension", "Diabetes",
  "Heart_disease", "Cerebrovascular_disease", "Hyperlipidemia"
))
no_coffee <- setdiff(candidate_predictors, "Coffee_consumption")
moca_columns <- grep("^MoCA_BJ_", names(data_list$Training), value = TRUE)

for (nm in names(data_list)) {
  dat <- data_list[[nm]]
  dat$Objective_MoCA_Outcome <- as.integer(dat$MoCA_BJ_Adjusted_Total < 26)
  dat$Objective_MoCA_Raw_Outcome <- as.integer(dat$MoCA_BJ_Raw_Total < 26)
  data_list[[nm]] <- dat
}

write_named <- function(dat, columns, relative_path) {
  out <- file.path(PROJECT_ROOT, relative_path)
  dir.create(dirname(out), recursive = TRUE, showWarnings = FALSE)
  write.csv(dat[, columns, drop = FALSE], out, row.names = FALSE, fileEncoding = "UTF-8")
}

write_named(data_list$Training, main_columns,
            "01_Feature_Selection/FeatureSelection_Training.csv")

for (nm in c("Training", "InternalValidation", "ExternalValidation")) {
  dat <- data_list[[nm]]
  write_named(dat, main_columns,
              paste0("02_Model_Development/ModelDevelopment_", nm, ".csv"))
  write_named(dat, main_columns,
              paste0("03_Performance_Comparison/Performance_", nm, ".csv"))
}
write_named(data_list$Training, main_columns, "04_SHAP/SHAP_Training.csv")
write_named(data_list$InternalValidation, main_columns, "04_SHAP/SHAP_InternalBackground.csv")
write_named(data_list$ExternalValidation, main_columns, "04_SHAP/SHAP_ExternalReference.csv")

sensA_cols <- c("Result", "Objective_MoCA_Outcome", "Objective_MoCA_Raw_Outcome",
                candidate_predictors, moca_columns)
for (nm in c("Training", "InternalValidation", "ExternalValidation")) {
  dat <- data_list[[nm]]
  write_named(dat, sensA_cols,
              paste0("06_Sensitivity_Analysis/A_Objective_MoCA_BJ/",
                     "SensitivityA_ObjectiveMoCA_", nm, ".csv"))
  write_named(dat, c("Result", no_psych),
              paste0("06_Sensitivity_Analysis/B_No_Psychological_Predictors/",
                     "SensitivityB_NoPsych_", nm, ".csv"))
  write_named(dat, c("Result", psg_clinical),
              paste0("06_Sensitivity_Analysis/C_Objective_PSG_Clinical/",
                     "SensitivityC_PSGClinical_", nm, ".csv"))
  write_named(dat, c("Result", no_coffee),
              paste0("06_Sensitivity_Analysis/D_No_Coffee/",
                     "SensitivityD_NoCoffee_", nm, ".csv"))
}

model_files <- c(
  "01_Feature_Selection/FeatureSelection_Training.csv",
  "02_Model_Development/ModelDevelopment_Training.csv",
  "02_Model_Development/ModelDevelopment_InternalValidation.csv",
  "02_Model_Development/ModelDevelopment_ExternalValidation.csv"
)
for (rf in model_files) {
  chk <- read.csv(file.path(PROJECT_ROOT, rf), check.names = FALSE)
  if ("OSA_severity" %in% names(chk)) stop("OSA_severity leakage detected in: ", rf)
  if (!"AHI" %in% names(chk)) stop("AHI missing from: ", rf)
}
message("AHI-only analysis-ready datasets regenerated under: ", PROJECT_ROOT)
