# Code provenance and publication lock

The revised manuscript uses a publication-lock feature-selection description in which:

1. a common absolute association value of >=0.70 is used as a redundancy-review trigger;
2. 27 modeling candidates are reduced to 24 original predictors after redundancy review;
3. categorical predictors are dummy coded to a common 34-column design matrix;
4. LASSO and Boruta are both applied to this common dummy-coded matrix;
5. supported dummy-level terms are mapped to parent original predictors;
6. the reported parent-predictor counts are LASSO 17, Boruta 11, consensus 9.

The authoritative public implementation of those steps is in `analysis/python/01_redundancy_review_0p70.py` and `analysis/python/02_dummy_matrix_lasso_boruta_consensus.py`.

The exact temporary interactive Python scratch source originally used during figure construction was not retained. The synchronized Python scripts are therefore the auditable publication-lock replacement source. Historical exploratory R scripts that apply Boruta directly to original predictor columns are intentionally not presented as the final Figure 3 implementation.

The executable prediction reference is `model/AAA_locked_RF_bundle.rds`.
