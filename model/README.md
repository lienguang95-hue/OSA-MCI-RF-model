# Locked RF model object

The deployed Shiny calculator uses the locked nine-predictor random-forest object `AAA_locked_RF_bundle.rds`.

Publication-lock properties:

- model: random forest;
- final predictors: 9;
- positive class: `Yes`;
- training-derived prioritization threshold: `0.3228`;
- SHA-256 of the canonical locked RDS file: `7aac8100312e67b8929c353465e41702c14bcf1ae9d54bc5418540a6eaf6b463`.

The connected GitHub writing interface used to assemble this repository does not support direct transfer of the local binary RDS object, so the binary itself is not duplicated in this GitHub tree.

The canonical locked RF object and the deployment copy are archived in the published Zenodo software/model record:

**DOI: 10.5281/zenodo.21872475**

https://doi.org/10.5281/zenodo.21872475

Reviewers who need the binary model object should use the Zenodo archive. The public GitHub repository provides the corresponding Shiny source, prediction code, variable dictionary, synthetic examples, software environment, and synchronized publication-lock implementation materials.
