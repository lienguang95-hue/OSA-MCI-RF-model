from __future__ import annotations

"""Publication-lock redundancy review for the OSA-MCI model.

This script documents the synchronized redundancy-review step reported in the
revised manuscript. It is intended to be run with the authorized training data.
Patient-level source data are not distributed in the public repository.
"""

from pathlib import Path
import json
import numpy as np
import pandas as pd
from scipy.stats import chi2_contingency

SEED = 2026
THRESHOLD = 0.70

CANDIDATES_27 = [
    "Age", "Gender", "Education_level", "Marital_status", "Income_status",
    "BMI", "OSA_duration", "Smoking_status", "Alcohol_consumption",
    "Coffee_consumption", "Sports_status", "Hypertension", "Diabetes",
    "Heart_disease", "Cerebrovascular_disease", "Hyperlipidemia", "AHI",
    "ODI", "Total_sleep_time", "MSaO2", "LSaO2",
    "Depressive_symptoms_total_score", "Anxiety_total_score",
    "Drowsiness_total_score", "Stress_total_score",
    "Social_support_total_score", "Sleep_quality_total_score",
]

# Locked redundancy decisions after review of pairs meeting the common trigger.
# OSA duration, ODI and LSaO2 were removed; OSA severity is not a modeling
# candidate because it is derived directly from AHI.
LOCKED_REMOVALS = ["OSA_duration", "ODI", "LSaO2"]
RETAINED_24 = [x for x in CANDIDATES_27 if x not in LOCKED_REMOVALS]

CONTINUOUS = [
    "Age", "OSA_duration", "AHI", "ODI", "Total_sleep_time", "MSaO2",
    "LSaO2", "Depressive_symptoms_total_score", "Anxiety_total_score",
    "Drowsiness_total_score", "Stress_total_score",
    "Social_support_total_score", "Sleep_quality_total_score",
]
CATEGORICAL = [x for x in CANDIDATES_27 if x not in CONTINUOUS]


def cramer_v_bias_corrected(x: pd.Series, y: pd.Series) -> float:
    tab = pd.crosstab(x, y).to_numpy()
    if tab.size == 0 or min(tab.shape) < 2:
        return np.nan
    chi2 = chi2_contingency(tab, correction=False)[0]
    n = tab.sum()
    if n <= 1:
        return np.nan
    r, k = tab.shape
    phi2 = chi2 / n
    phi2corr = max(0.0, phi2 - ((k - 1) * (r - 1)) / (n - 1))
    rcorr = r - ((r - 1) ** 2) / (n - 1)
    kcorr = k - ((k - 1) ** 2) / (n - 1)
    denom = min(kcorr - 1, rcorr - 1)
    return float(np.sqrt(phi2corr / denom)) if denom > 0 else np.nan


def eta_squared(categories: pd.Series, values: pd.Series) -> float:
    """Correlation ratio eta^2 for categorical-continuous pairs."""
    d = pd.DataFrame({"c": categories, "x": pd.to_numeric(values, errors="coerce")}).dropna()
    if d.empty:
        return np.nan
    grand = d["x"].mean()
    ss_total = ((d["x"] - grand) ** 2).sum()
    if ss_total <= 0:
        return 0.0
    ss_between = sum(len(g) * (g["x"].mean() - grand) ** 2 for _, g in d.groupby("c"))
    return float(ss_between / ss_total)


def association(data: pd.DataFrame, a: str, b: str) -> tuple[str, float]:
    if a in CONTINUOUS and b in CONTINUOUS:
        x = pd.to_numeric(data[a], errors="coerce")
        y = pd.to_numeric(data[b], errors="coerce")
        ok = x.notna() & y.notna()
        if ok.sum() < 3:
            return "Spearman_rho", np.nan
        return "Spearman_rho", float(x[ok].corr(y[ok], method="spearman"))
    if a in CATEGORICAL and b in CATEGORICAL:
        return "Cramers_V", cramer_v_bias_corrected(data[a], data[b])
    if a in CATEGORICAL:
        return "Eta_squared", eta_squared(data[a], data[b])
    return "Eta_squared", eta_squared(data[b], data[a])


def run_redundancy_review(training_csv: str | Path, output_dir: str | Path) -> None:
    training_csv = Path(training_csv)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    data = pd.read_csv(training_csv)

    missing = [v for v in CANDIDATES_27 if v not in data.columns]
    if missing:
        raise ValueError(f"Missing required candidate predictors: {missing}")

    rows = []
    for i, a in enumerate(CANDIDATES_27):
        for b in CANDIDATES_27[i + 1:]:
            metric, value = association(data, a, b)
            rows.append({
                "Variable_1": a,
                "Variable_2": b,
                "Association_metric": metric,
                "Association": value,
                "Absolute_association": abs(value) if np.isfinite(value) else np.nan,
                "Meets_0p70_review_trigger": bool(np.isfinite(value) and abs(value) >= THRESHOLD),
            })
    assoc = pd.DataFrame(rows)
    assoc.to_csv(output_dir / "redundancy_review_all_pairs.csv", index=False)
    assoc.loc[assoc["Meets_0p70_review_trigger"]].to_csv(
        output_dir / "redundancy_review_triggered_pairs.csv", index=False
    )

    pd.DataFrame({"Removed_predictor": LOCKED_REMOVALS}).to_csv(
        output_dir / "redundancy_locked_removals.csv", index=False
    )
    pd.DataFrame({"Retained_predictor": RETAINED_24}).to_csv(
        output_dir / "redundancy_retained_24.csv", index=False
    )

    audit = {
        "seed": SEED,
        "review_trigger": THRESHOLD,
        "candidate_count": len(CANDIDATES_27),
        "removed": LOCKED_REMOVALS,
        "retained_count": len(RETAINED_24),
        "retained": RETAINED_24,
        "note": (
            "The >=0.70 value is a review trigger applied consistently across association metrics; "
            "the final removal decision also considered measurement redundancy and clinical meaning."
        ),
    }
    (output_dir / "redundancy_review_audit.json").write_text(
        json.dumps(audit, indent=2), encoding="utf-8"
    )

    if len(RETAINED_24) != 24:
        raise AssertionError(f"Expected 24 retained predictors, got {len(RETAINED_24)}")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("training_csv", help="Authorized training dataset containing the 27 candidate predictors")
    parser.add_argument("--output-dir", default="feature_selection_outputs")
    args = parser.parse_args()
    run_redundancy_review(args.training_csv, args.output_dir)
