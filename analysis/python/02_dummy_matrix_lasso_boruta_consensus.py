from __future__ import annotations

"""Publication-lock LASSO/Boruta consensus implementation.

Both feature-selection methods are applied to the same dummy-coded training
matrix. Supported columns are subsequently mapped back to parent original
predictors before forming the final consensus.
"""

from pathlib import Path
import json
import re
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.linear_model import LogisticRegressionCV
from sklearn.pipeline import Pipeline
from sklearn.metrics import average_precision_score, make_scorer
from sklearn.ensemble import RandomForestClassifier
from boruta import BorutaPy

SEED = 2026
EXPECTED_ORIGINAL_COUNT = 24
EXPECTED_DESIGN_COUNT = 34
EXPECTED_LASSO_PARENT_COUNT = 17
EXPECTED_BORUTA_PARENT_COUNT = 11
EXPECTED_CONSENSUS_COUNT = 9

RETAINED_24 = [
    "Age", "Gender", "Education_level", "Marital_status", "Income_status", "BMI",
    "Smoking_status", "Alcohol_consumption", "Coffee_consumption", "Sports_status",
    "Hypertension", "Diabetes", "Heart_disease", "Cerebrovascular_disease",
    "Hyperlipidemia", "AHI", "Total_sleep_time", "MSaO2",
    "Depressive_symptoms_total_score", "Anxiety_total_score",
    "Drowsiness_total_score", "Stress_total_score", "Social_support_total_score",
    "Sleep_quality_total_score",
]

CONTINUOUS = [
    "Age", "AHI", "Total_sleep_time", "MSaO2",
    "Depressive_symptoms_total_score", "Anxiety_total_score",
    "Drowsiness_total_score", "Stress_total_score",
    "Social_support_total_score", "Sleep_quality_total_score",
]
CATEGORICAL = [x for x in RETAINED_24 if x not in CONTINUOUS]

FINAL_CONSENSUS_LOCK = [
    "Coffee_consumption", "Sports_status", "AHI", "MSaO2",
    "Depressive_symptoms_total_score", "Anxiety_total_score",
    "Drowsiness_total_score", "Stress_total_score", "Sleep_quality_total_score",
]


def parent_from_dummy(term: str) -> str:
    """Map a ColumnTransformer/OneHotEncoder feature name to its parent variable."""
    t = re.sub(r"^(num|cat)__", "", term)
    for parent in sorted(RETAINED_24, key=len, reverse=True):
        if t == parent or t.startswith(parent + "_"):
            return parent
    raise KeyError(f"Cannot map design-matrix term to parent predictor: {term}")


def prepare_outcome(s: pd.Series) -> np.ndarray:
    if pd.api.types.is_numeric_dtype(s):
        vals = pd.to_numeric(s, errors="coerce")
        if set(vals.dropna().unique()).issubset({0, 1}):
            return vals.astype(int).to_numpy()
    return s.astype(str).str.lower().isin(["yes", "mci", "1", "true"]).astype(int).to_numpy()


def build_design_matrix(data: pd.DataFrame):
    missing = [v for v in RETAINED_24 if v not in data.columns]
    if missing:
        raise ValueError(f"Missing retained predictors: {missing}")

    pre = ColumnTransformer(
        transformers=[
            ("num", StandardScaler(), CONTINUOUS),
            ("cat", OneHotEncoder(drop="first", handle_unknown="ignore", sparse_output=False), CATEGORICAL),
        ],
        remainder="drop",
        verbose_feature_names_out=True,
    )
    X = pre.fit_transform(data[RETAINED_24])
    feature_names = list(pre.get_feature_names_out())
    return np.asarray(X, dtype=float), feature_names, pre


def lasso_parent_selection(X: np.ndarray, y: np.ndarray, feature_names: list[str]):
    scorer = make_scorer(average_precision_score, needs_proba=True)
    # A broad logarithmic grid; model selection uses repeated CV elsewhere in the full workflow.
    model = LogisticRegressionCV(
        Cs=np.logspace(-4, 3, 100),
        cv=10,
        penalty="l1",
        solver="liblinear",
        scoring=scorer,
        max_iter=10000,
        random_state=SEED,
        refit=True,
    )
    model.fit(X, y)
    coef = model.coef_.ravel()
    selected_terms = [f for f, c in zip(feature_names, coef) if abs(c) > 1e-12]
    parents = sorted(set(parent_from_dummy(t) for t in selected_terms), key=RETAINED_24.index)
    return model, selected_terms, parents, coef


def boruta_parent_selection(X: np.ndarray, y: np.ndarray, feature_names: list[str]):
    rf = RandomForestClassifier(
        n_estimators=1000,
        max_depth=None,
        class_weight=None,
        random_state=SEED,
        n_jobs=-1,
    )
    selector = BorutaPy(
        estimator=rf,
        n_estimators="auto",
        max_iter=500,
        perc=100,
        alpha=0.05,
        two_step=True,
        random_state=SEED,
        verbose=0,
    )
    selector.fit(X, y)
    accepted_terms = [f for f, keep in zip(feature_names, selector.support_) if keep]
    tentative_terms = [f for f, keep in zip(feature_names, selector.support_weak_) if keep]
    parents = sorted(set(parent_from_dummy(t) for t in accepted_terms), key=RETAINED_24.index)
    return selector, accepted_terms, tentative_terms, parents


def run_feature_selection(training_csv: str | Path, output_dir: str | Path) -> None:
    training_csv = Path(training_csv)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    data = pd.read_csv(training_csv)
    if "Result" not in data.columns:
        raise ValueError("Training data must contain the outcome column 'Result'.")
    y = prepare_outcome(data["Result"])
    X, feature_names, pre = build_design_matrix(data)

    pd.DataFrame({"Design_matrix_term": feature_names, "Parent_predictor": [parent_from_dummy(x) for x in feature_names]}).to_csv(
        output_dir / "dummy_design_matrix_dictionary.csv", index=False
    )

    lasso, lasso_terms, lasso_parents, coef = lasso_parent_selection(X, y, feature_names)
    boruta, boruta_terms, boruta_tentative, boruta_parents = boruta_parent_selection(X, y, feature_names)
    consensus = [v for v in RETAINED_24 if v in set(lasso_parents) & set(boruta_parents)]

    pd.DataFrame({"Design_matrix_term": feature_names, "LASSO_coefficient": coef}).to_csv(
        output_dir / "lasso_design_matrix_coefficients.csv", index=False
    )
    pd.DataFrame({"LASSO_selected_term": lasso_terms}).to_csv(output_dir / "lasso_selected_terms.csv", index=False)
    pd.DataFrame({"LASSO_parent_predictor": lasso_parents}).to_csv(output_dir / "lasso_parent_predictors.csv", index=False)
    pd.DataFrame({"Boruta_accepted_term": boruta_terms}).to_csv(output_dir / "boruta_accepted_terms.csv", index=False)
    pd.DataFrame({"Boruta_tentative_term": boruta_tentative}).to_csv(output_dir / "boruta_tentative_terms.csv", index=False)
    pd.DataFrame({"Boruta_parent_predictor": boruta_parents}).to_csv(output_dir / "boruta_parent_predictors.csv", index=False)
    pd.DataFrame({"Consensus_predictor": consensus}).to_csv(output_dir / "consensus_predictors.csv", index=False)

    audit = {
        "seed": SEED,
        "original_predictor_count": len(RETAINED_24),
        "design_matrix_column_count": len(feature_names),
        "lasso_parent_count": len(lasso_parents),
        "boruta_parent_count": len(boruta_parents),
        "consensus_count": len(consensus),
        "lasso_parents": lasso_parents,
        "boruta_parents": boruta_parents,
        "consensus": consensus,
        "locked_final_consensus": FINAL_CONSENSUS_LOCK,
    }
    (output_dir / "feature_selection_audit.json").write_text(json.dumps(audit, indent=2), encoding="utf-8")

    # Publication-lock assertions. If authorized source data or package versions differ,
    # failures should be investigated rather than silently overwritten.
    if len(RETAINED_24) != EXPECTED_ORIGINAL_COUNT:
        raise AssertionError(f"Expected {EXPECTED_ORIGINAL_COUNT} original predictors")
    if len(feature_names) != EXPECTED_DESIGN_COUNT:
        raise AssertionError(f"Expected {EXPECTED_DESIGN_COUNT} dummy-coded columns, got {len(feature_names)}")
    if len(lasso_parents) != EXPECTED_LASSO_PARENT_COUNT:
        raise AssertionError(f"Expected {EXPECTED_LASSO_PARENT_COUNT} LASSO parent predictors, got {len(lasso_parents)}")
    if len(boruta_parents) != EXPECTED_BORUTA_PARENT_COUNT:
        raise AssertionError(f"Expected {EXPECTED_BORUTA_PARENT_COUNT} Boruta parent predictors, got {len(boruta_parents)}")
    if len(consensus) != EXPECTED_CONSENSUS_COUNT:
        raise AssertionError(f"Expected {EXPECTED_CONSENSUS_COUNT} consensus predictors, got {len(consensus)}")
    if consensus != FINAL_CONSENSUS_LOCK:
        raise AssertionError(f"Consensus differs from the publication lock: {consensus}")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("training_csv", help="Authorized training dataset after redundancy review")
    parser.add_argument("--output-dir", default="feature_selection_outputs")
    args = parser.parse_args()
    run_feature_selection(args.training_csv, args.output_dir)
