# ============================================================================
# ui.R
# User interface for the final locked RF OSA-MCI calculator
# ============================================================================

ui <- fluidPage(
  tags$head(
    tags$style(HTML("\n      body { font-family: Arial, sans-serif; }\n      .title-note { color: #555; font-size: 14px; margin-bottom: 14px; }\n      .warning-box { background:#fff7e6; border-left:4px solid #d97706; padding:10px 14px; margin-bottom:14px; }\n      .result-box { background:#f7f7f7; border:1px solid #ddd; border-radius:8px; padding:16px; margin-top:10px; }\n      .prob-text { font-size:28px; font-weight:700; }\n      .threshold-text { font-size:16px; font-weight:600; }\n    "))
  ),

  titlePanel("MCI prioritization calculator for patients with OSA"),

  div(
    class = "title-note",
    "Locked nine-predictor random-forest model for estimating the probability of concurrent clinically defined MCI."
  ),

  div(
    class = "warning-box",
    strong("Important: "),
    "This tool supports prioritization for formal cognitive assessment. It is not a stand-alone MCI diagnosis, does not predict future cognitive decline, and should not replace standardized cognitive assessment or clinical judgment."
  ),

  sidebarLayout(
    sidebarPanel(
      selectInput(
        "Coffee_consumption",
        "Coffee consumption",
        choices = c(
          "Almost no consumption (<1 time/week)" = "1",
          "Occasional (1-3 times/week)" = "2",
          "Frequent (>=4 times/week or daily)" = "3"
        ),
        selected = "1"
      ),

      selectInput(
        "Sports_status",
        "Physical activity",
        choices = c(
          "Rare (<1 session/week)" = "1",
          "Occasional (1-3 sessions/week)" = "2",
          "Regular (>=4 sessions/week)" = "3"
        ),
        selected = "1"
      ),

      numericInput("AHI", "AHI (events/hour)", min = 5.2, max = 129.5, step = 0.1, value = 27.1),
      numericInput("MSaO2", "Mean oxygen saturation, MSaO2 (%)", min = 32.5, max = 96.9, step = 0.1, value = 92.6),
      numericInput("Depressive_symptoms_total_score", "PHQ-9 total score", min = 1, max = 19, step = 1, value = 8),
      numericInput("Anxiety_total_score", "GAD-7 total score", min = 0, max = 21, step = 1, value = 12),
      numericInput("Drowsiness_total_score", "ESS total score", min = 0, max = 24, step = 1, value = 12),
      numericInput("Stress_total_score", "CPSS-14 total score", min = 3, max = 56, step = 1, value = 33),
      numericInput("Sleep_quality_total_score", "PSQI total score", min = 0, max = 21, step = 1, value = 11),

      actionButton("goButton", "Calculate probability", class = "btn-primary"),
      br(), br(),
      helpText("All nine inputs are required. Values are restricted to the ranges observed in the model-development training sample.")
    ),

    mainPanel(
      plotOutput("piediagram", height = "460px"),
      div(
        class = "result-box",
        div(class = "prob-text", textOutput("probability_text")),
        div(class = "threshold-text", textOutput("recommendation_text")),
        br(),
        textOutput("threshold_text")
      )
    )
  )
)
