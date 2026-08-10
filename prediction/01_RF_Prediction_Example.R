# ============================================================================
# Minimal stand-alone example for the locked RF model.
# Run from the repository root.
# ============================================================================
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
if (!file.exists(file.path("app", "global.R"))) stop("Run this script from the repository root.")
setwd("app")
source("global.R", local = FALSE)
setwd(old_wd)

new_patient <- data.frame(
  Coffee_consumption = "1",  # 1=Almost none, 2=Occasional, 3=Frequent
  Sports_status = "1",       # 1=Rare, 2=Occasional, 3=Regular
  AHI = 27.1,
  MSaO2 = 92.6,
  Depressive_symptoms_total_score = 8,
  Anxiety_total_score = 12,
  Drowsiness_total_score = 12,
  Stress_total_score = 33,
  Sleep_quality_total_score = 11,
  stringsAsFactors = FALSE
)

probability <- predict_mci_probability(bundle, new_patient)
recommendation <- classify_for_prioritization(probability, bundle)
result <- data.frame(
  Predicted_MCI_probability = probability,
  Locked_threshold = bundle$threshold,
  Prioritization = recommendation,
  stringsAsFactors = FALSE
)
print(result)
write.csv(result, "RF_example_prediction_output.csv", row.names = FALSE)
