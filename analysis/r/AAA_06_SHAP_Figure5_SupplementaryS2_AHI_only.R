# ============================================================================
# Regenerate the corrected SHAP figures after the full model rerun
# Version: 2026-08-05 AHI-only v4
#
# Main manuscript Figure 5: A-F
#   A beeswarm; B mean |SHAP|; C-D force; E-F waterfall.
# Supplementary Figure S2: A-I
#   A-G dependence plots for the rerun final predictors;
#   H-I fixed-SHAP explanation-stability analyses.
#
# The stability analysis resamples the fixed SHAP matrix. It must be described
# as "fixed-SHAP explanation stability", never as feature-selection stability.
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
MODEL_DIR <- file.path(PROJECT_ROOT, "08_Results_AHI_only", "01_primary")
OUT_DIR <- file.path(PROJECT_ROOT, "08_Results_AHI_only", "06_SHAP_figures")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

TRAIN_FILE <- file.path(PROJECT_ROOT, "04_SHAP", "SHAP_Training.csv")
INTERNAL_FILE <- file.path(PROJECT_ROOT, "04_SHAP", "SHAP_InternalBackground.csv")
BUNDLE_FILE <- file.path(MODEL_DIR, "AAA_locked_RF_bundle.rds")

packages <- c("kernelshap", "shapviz", "ggplot2", "patchwork", "dplyr", "tidyr", "scales")
for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

if (!file.exists(BUNDLE_FILE)) stop("Run the updated full-pipeline script first.")
bundle <- readRDS(BUNDLE_FILE)
train_raw <- read.csv(TRAIN_FILE, check.names = FALSE, stringsAsFactors = FALSE)
internal_raw <- read.csv(INTERNAL_FILE, check.names = FALSE, stringsAsFactors = FALSE)

final_vars <- bundle$final_vars
if (length(final_vars) < 2L) stop("Invalid final predictor set in the RF bundle.")
if (any(grepl("^MoCA_BJ_", final_vars))) stop("Leakage: MoCA-BJ variables cannot be predictors.")

prepare_raw_predictors <- function(dat) {
  x <- dat[, final_vars, drop = FALSE]
  for (v in intersect(names(bundle$factor_levels), names(x))) {
    x[[v]] <- factor(as.character(x[[v]]), levels = bundle$factor_levels[[v]])
  }
  x
}

apply_preprocessor <- function(raw_x) {
  x <- as.data.frame(predict(bundle$preprocessor$dummy, newdata = raw_x))
  missing_cols <- setdiff(bundle$preprocessor$keep_cols, names(x))
  if (length(missing_cols) > 0L) for (v in missing_cols) x[[v]] <- 0
  x[, bundle$preprocessor$keep_cols, drop = FALSE]
}

predict_probability_raw <- function(object, newdata) {
  x <- prepare_raw_predictors(newdata)
  x_design <- apply_preprocessor(x)
  as.numeric(predict(object$model, newdata = x_design, type = "prob")[, "Yes"])
}

X_explain <- prepare_raw_predictors(train_raw)
X_background <- prepare_raw_predictors(internal_raw)

set.seed(2026)
ks <- kernelshap::kernelshap(
  object = bundle,
  X = X_explain,
  bg_X = X_background,
  pred_fun = predict_probability_raw
)
sv <- shapviz::shapviz(ks, X_pred = X_explain, interactions = FALSE)
if (!inherits(sv, "shapviz") && !is.null(sv$Yes)) sv <- sv$Yes
if (!inherits(sv, "shapviz")) stop("Could not construct a shapviz object.")

base_theme <- theme_bw(base_size = 10) +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))

# Main A-B
pA <- shapviz::sv_importance(
  sv, kind = "beeswarm", show_numbers = FALSE,
  viridis_args = list(begin = 0.25, end = 0.85, option = "B")
) + ggtitle("Random forest") + base_theme

pB <- shapviz::sv_importance(sv, kind = "bar", show_numbers = FALSE) +
  ggtitle("Random forest") + base_theme

# Main C-F: representative local explanations
row_1 <- min(76L, nrow(X_explain))
row_2 <- min(86L, nrow(X_explain))
if (row_2 == row_1) row_2 <- max(1L, nrow(X_explain))

pC <- shapviz::sv_force(sv, row_id = row_1, size = 8) +
  ggtitle(paste0("Case ", row_1)) + base_theme
pD <- shapviz::sv_force(sv, row_id = row_2, size = 8) +
  ggtitle(paste0("Case ", row_2)) + base_theme
pE <- shapviz::sv_waterfall(sv, row_id = row_1) +
  ggtitle(paste0("Case ", row_1)) + base_theme
pF <- shapviz::sv_waterfall(sv, row_id = row_2) +
  ggtitle(paste0("Case ", row_2)) + base_theme

main_plots <- list(A = pA, B = pB, C = pC, D = pD, E = pE, F = pF)
for (nm in names(main_plots)) {
  ggsave(file.path(OUT_DIR, paste0("Figure5_panel_", nm, ".pdf")),
         main_plots[[nm]], width = ifelse(nm %in% c("C", "D"), 8, 7),
         height = 5.5, device = cairo_pdf)
}

main_combined <- (pA | pB | pC) / (pD | pE | pF) +
  patchwork::plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))
ggsave(file.path(OUT_DIR, "Figure5_SHAP_A_to_F_600dpi.tiff"),
       main_combined, width = 21, height = 11, dpi = 600, compression = "lzw")

# Supplementary A-G: dependence plots. If the rerun changes the predictor set,
# the number and labels update automatically; the caption must be updated too.
dep_plots <- lapply(final_vars, function(v) {
  shapviz::sv_dependence(sv, v = v) +
    labs(title = v, x = v, y = "SHAP value") + base_theme
})
names(dep_plots) <- final_vars

for (i in seq_along(dep_plots)) {
  ggsave(file.path(OUT_DIR, paste0("Supplementary_S2_dependence_", i, "_",
                                  gsub("[^A-Za-z0-9]+", "_", names(dep_plots)[i]), ".pdf")),
         dep_plots[[i]], width = 7, height = 6, device = cairo_pdf)
}

# Supplementary stability panels: informative top-3/top-5 and rank stability
S <- sv$S
if (is.null(S)) stop("SHAP matrix not found.")
B <- 500L
set.seed(2026)
boot_imp <- matrix(NA_real_, nrow=B, ncol=ncol(S), dimnames=list(NULL,colnames(S)))
for (b in seq_len(B)) { idx<-sample(seq_len(nrow(S)),nrow(S),replace=TRUE); boot_imp[b,]<-colMeans(abs(S[idx,,drop=FALSE]),na.rm=TRUE) }
original_imp <- colMeans(abs(S),na.rm=TRUE); original_rank <- rank(-original_imp,ties.method="average")
boot_rank <- t(apply(boot_imp,1,function(x)rank(-x,ties.method="average")))
top_freq <- function(k) vapply(seq_len(ncol(boot_imp)),function(j)mean(apply(boot_imp,1,function(x)j %in% order(x,decreasing=TRUE)[seq_len(min(k,length(x)))])),numeric(1))
spearman_rho <- apply(boot_imp,1,function(x)cor(original_imp,x,method="spearman"))
stability_summary <- data.frame(Predictor=colnames(boot_imp),Top3_Frequency=top_freq(3),Top5_Frequency=top_freq(5),Mean_Absolute_SHAP=colMeans(boot_imp,na.rm=TRUE),Lower_95=apply(boot_imp,2,quantile,.025,na.rm=TRUE),Upper_95=apply(boot_imp,2,quantile,.975,na.rm=TRUE),Median_Rank=apply(boot_rank,2,median,na.rm=TRUE),Rank_Lower_95=apply(boot_rank,2,quantile,.025,na.rm=TRUE),Rank_Upper_95=apply(boot_rank,2,quantile,.975,na.rm=TRUE),stringsAsFactors=FALSE) |> dplyr::arrange(dplyr::desc(Mean_Absolute_SHAP))
write.csv(stability_summary,file.path(OUT_DIR,"Fixed_SHAP_explanation_stability_summary.csv"),row.names=FALSE)
write.csv(data.frame(Spearman_Rho=spearman_rho),file.path(OUT_DIR,"Fixed_SHAP_bootstrap_rank_Spearman.csv"),row.names=FALSE)
long_freq <- stability_summary |> dplyr::select(Predictor,Top3_Frequency,Top5_Frequency) |> tidyr::pivot_longer(-Predictor,names_to="Top_Set",values_to="Frequency")
pH <- ggplot(long_freq,aes(x=reorder(Predictor,Frequency),y=Frequency,fill=Top_Set))+geom_col(position="dodge")+coord_flip()+scale_y_continuous(labels=scales::percent)+labs(title="Fixed-SHAP explanation stability",subtitle=paste0("Median bootstrap rank correlation = ",sprintf("%.3f",median(spearman_rho,na.rm=TRUE))),x=NULL,y="Selection frequency")+base_theme
pI <- ggplot(stability_summary,aes(x=reorder(Predictor,Mean_Absolute_SHAP),y=Mean_Absolute_SHAP))+geom_point(size=2)+geom_errorbar(aes(ymin=Lower_95,ymax=Upper_95),width=.15)+coord_flip()+labs(title="Fixed-SHAP explanation stability",x=NULL,y="Bootstrap mean absolute SHAP (95% CI)")+base_theme
ggsave(file.path(OUT_DIR,"Supplementary_S2_fixed_SHAP_top3_top5_frequency.pdf"),pH,width=7,height=5.5,device=cairo_pdf)
ggsave(file.path(OUT_DIR,"Supplementary_S2_fixed_SHAP_importance_CI.pdf"),pI,width=7,height=5.5,device=cairo_pdf)

# Combine dependence plots plus H-I in a 3-column supplementary figure.
# If there are exactly 7 final predictors, this creates 9 panels A-I.
supp_plots <- c(dep_plots, list(pH, pI))
supp_combined <- patchwork::wrap_plots(supp_plots, ncol = 3) +
  patchwork::plot_annotation(tag_levels = "A") &
  theme(plot.tag = element_text(face = "bold", size = 14))
rows_needed <- ceiling(length(supp_plots) / 3)
ggsave(file.path(OUT_DIR, "Supplementary_Figure_S2_SHAP_600dpi.tiff"),
       supp_combined, width = 21, height = 6.5 * rows_needed,
       dpi = 600, compression = "lzw")

write.csv(data.frame(Final_Predictor = final_vars),
          file.path(OUT_DIR, "SHAP_final_predictor_order.csv"), row.names = FALSE)
write.csv(data.frame(Case = c("Case_1", "Case_2"), Row = c(row_1, row_2)),
          file.path(OUT_DIR, "SHAP_representative_case_rows.csv"), row.names = FALSE)

saveRDS(list(kernelshap = ks, shapviz = sv, final_vars = final_vars),
        file.path(OUT_DIR, "AAA_updated_SHAP_objects.rds"))
message("Completed SHAP figures: ", normalizePath(OUT_DIR, winslash = "/"))
