# OSA-MCI locked random-forest model: code and web-calculator reproducibility package

This repository supports the revised manuscript **“Interpretable machine learning for identifying mild cognitive impairment among Chinese patients with obstructive sleep apnea: a multicenter cross-sectional study.”**

## Scope

The archive provides the executable locked nine-predictor random-forest (RF) model, the Shiny calculator source, example prediction code, a variable dictionary, synthetic example input/output, software-concordance scripts, software/session information, and publication-lock code for the synchronized feature-selection steps used in the revised manuscript.

**Patient-level development and validation data are not included** because of privacy, informed-consent, and institutional-governance restrictions. Consequently, scripts that require patient-level data cannot be executed by external users unless equivalent authorized data are supplied.

## Public web calculator

The deployed calculator is available at:

https://mciriskmodel.shinyapps.io/make_web/

It estimates the probability of **concurrent clinically defined MCI** in patients with OSA and is intended only to prioritize formal cognitive assessment. It is not a stand-alone diagnosis, does not predict future cognitive decline, and should not replace standardized cognitive assessment or clinical judgment.

## Locked model

- Model: random forest
- Final predictors: 9
- Positive class: `Yes`
- Training-derived prioritization threshold: `0.3228`
- Canonical locked model file: `model/AAA_locked_RF_bundle.rds`
- Deployment copy used by Shiny: `app/AAA_locked_RF_bundle.rds`
- SHA-256: `7aac8100312e67b8929c353465e41702c14bcf1ae9d54bc5418540a6eaf6b463`

The nine required inputs are:

1. Coffee consumption
2. Physical activity
3. AHI
4. Mean oxygen saturation (MSaO2)
5. PHQ-9 total score
6. GAD-7 total score
7. ESS total score
8. CPSS-14 total score
9. PSQI total score

See `metadata/RF_variable_dictionary.csv` for coding and units.

## Repository structure

```text
model/       locked RF bundle
app/         Shiny source and local/preflight scripts
prediction/  example prediction and software-concordance checks
metadata/    variable dictionary, model specification, R session information
examples/    synthetic example input/output and concordance cases
analysis/
  python/    publication-lock feature-selection and publication-output code
  r/         supporting R analysis scripts that do not define the authoritative Figure 3 feature-selection implementation
docs/        model card, data availability, security/provenance notes
```

## Important code-provenance note

The publication-lock implementation for the revised feature-selection description is:

- `analysis/python/01_redundancy_review_0p70.py`
- `analysis/python/02_dummy_matrix_lasso_boruta_consensus.py`

These scripts implement the synchronized `>=0.70` redundancy-review trigger and the common dummy-coded matrix used by both LASSO and Boruta, with mapping back to parent predictors and the locked `24 -> 34`, `17/11`, and `9` counts.

Historical exploratory R scripts that applied Boruta directly to original predictor columns are **not included as the final Figure 3 implementation**, because doing so would conflict with the revised manuscript. The locked RF object is the executable reference for prediction.

## Reproduce an example prediction

From the repository root, run:

```r
source("prediction/01_RF_Prediction_Example.R")
```

The synthetic example in `examples/RF_example_input.csv` should return approximately:

```text
Predicted_MCI_probability = 0.556
Locked_threshold = 0.3228
Prioritization = Prioritize formal cognitive assessment
```

## Run the Shiny application locally

The deployed app uses the locked model and saved preprocessing components; it does not refit, retune, reselect predictors, recalibrate, or re-estimate the threshold at runtime.

```r
source("app/00_Install_and_Preflight_RF_Web_FIXED.R")
source("app/02_Run_RF_Web_Local.R")
```

## Data availability

No patient-level data are included in this public package. See `docs/DATA_AVAILABILITY.md`.

## Clinical-use limitation

The calculator is an implementation of the locked research model, not a prospectively validated medical device or clinical decision-support product. New-site use requires reassessment of calibration and clinical utility.

## Version

Publication-lock archive: `v1.0.0` (2026-08-10).
