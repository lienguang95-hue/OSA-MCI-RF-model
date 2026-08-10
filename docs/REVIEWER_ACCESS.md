# Reviewer access guide

This repository supports review of the revised OSA-MCI diagnostic-prediction manuscript.

## Quick verification paths

- **Model specification and threshold:** `metadata/RF_model_specification.txt`
- **Nine required variables and coding:** `metadata/RF_variable_dictionary.csv`
- **Shiny implementation:** `app/global.R`, `app/ui.R`, `app/server.R`
- **Example prediction code:** `prediction/01_RF_Prediction_Example.R`
- **Synthetic software-concordance check:** `prediction/05_RF_Web_Concordance_Check.R`
- **Example input/output:** `examples/`
- **Publication-lock feature selection:** `analysis/python/01_redundancy_review_0p70.py` and `analysis/python/02_dummy_matrix_lasso_boruta_consensus.py`
- **Software environment:** `metadata/R_sessionInfo.txt` and `requirements_python.txt`
- **Data-access boundary:** `docs/DATA_AVAILABILITY.md`
- **Code provenance:** `docs/CODE_PROVENANCE.md`

## Live calculator

https://mciriskmodel.shinyapps.io/make_web/

The calculator estimates the probability of **concurrent clinically defined MCI** for prioritization of formal cognitive assessment. It is not a stand-alone diagnosis and does not predict future cognitive decline.

## Locked facts

- Random forest
- 9 predictors
- threshold 0.3228
- no runtime refitting, retuning, feature reselection, recalibration, or threshold re-estimation
- no prediction when a required input is missing
- intended for trained sleep-clinic/respiratory-care professionals

## Permanent binary-model archive

The canonical RDS SHA-256 is `7aac8100312e67b8929c353465e41702c14bcf1ae9d54bc5418540a6eaf6b463`.

The versioned reproducibility package, including the canonical locked RF RDS object and the deployment copy, has been published in Zenodo:

**DOI: 10.5281/zenodo.21872475**

https://doi.org/10.5281/zenodo.21872475

The RDS binary is not duplicated in this GitHub tree; reviewers should use the Zenodo record for the archived binary model object.
