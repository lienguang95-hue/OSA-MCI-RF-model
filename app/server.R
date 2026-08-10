# ============================================================================
# server.R -- deployment-safe final RF calculator
#
# IMPORTANT FIX:
# The previous online deployment used ggforce::geom_arc_bar(stat = "pie") for
# the donut chart. The prediction itself worked, but the plotting output failed
# on shinyapps.io and Shiny displayed the generic red output error. This version
# uses only base R graphics for the donut chart, removing that failure point.
# ============================================================================

server <- function(input, output, session) {

  prediction <- eventReactive(input$goButton, {
    newdata <- data.frame(
      Coffee_consumption = input$Coffee_consumption,
      Sports_status = input$Sports_status,
      AHI = input$AHI,
      MSaO2 = input$MSaO2,
      Depressive_symptoms_total_score = input$Depressive_symptoms_total_score,
      Anxiety_total_score = input$Anxiety_total_score,
      Drowsiness_total_score = input$Drowsiness_total_score,
      Stress_total_score = input$Stress_total_score,
      Sleep_quality_total_score = input$Sleep_quality_total_score,
      stringsAsFactors = FALSE
    )

    tryCatch({
      p <- predict_mci_probability(bundle, newdata)
      list(
        probability = as.numeric(p[1]),
        recommendation = classify_for_prioritization(as.numeric(p[1]), bundle)
      )
    }, error = function(e) {
      message("Prediction error: ", conditionMessage(e))
      showNotification(
        paste0("Prediction could not be generated: ", conditionMessage(e)),
        type = "error",
        duration = 10
      )
      NULL
    })
  }, ignoreInit = TRUE)

  output$probability_text <- renderText({
    res <- prediction()
    req(res)
    sprintf(
      "Estimated probability of concurrent MCI: %.2f%%",
      100 * res$probability
    )
  })

  output$recommendation_text <- renderText({
    res <- prediction()
    req(res)
    res$recommendation
  })

  output$threshold_text <- renderText({
    paste0(
      "Locked training-derived prioritization threshold: ",
      sprintf("%.4f", as.numeric(bundle$threshold)),
      ". This threshold is not a diagnostic cutoff."
    )
  })

  # Deployment-safe donut chart using base R only.
  output$piediagram <- renderPlot({
    res <- prediction()
    req(res)

    p <- as.numeric(res$probability)
    validate(need(is.finite(p) && p >= 0 && p <= 1, "Invalid probability."))

    oldpar <- par(no.readonly = TRUE)
    on.exit(par(oldpar), add = TRUE)

    par(
      mar = c(1.5, 1.5, 3.5, 1.5),
      xpd = NA,
      family = "sans"
    )

    vals <- c(p, 1 - p)
    cols <- c("#ED0000", "#0099B4")
    labs <- c("Estimated MCI probability", "Remaining probability")

    pie(
      vals,
      labels = NA,
      col = cols,
      border = "#333333",
      lwd = 1,
      clockwise = TRUE,
      init.angle = 90,
      radius = 0.86
    )

    # White center to create a donut without ggforce/ggplot2.
    theta <- seq(0, 2 * pi, length.out = 500)
    polygon(
      0.48 * cos(theta),
      0.48 * sin(theta),
      col = "white",
      border = "#333333",
      lwd = 1
    )

    text(
      0, 0.12,
      labels = "Estimated MCI probability",
      font = 2,
      cex = 1.30
    )
    text(
      0, -0.10,
      labels = sprintf("%.2f%%", 100 * p),
      font = 2,
      cex = 1.65
    )

    legend(
      "top",
      legend = labs,
      fill = cols,
      border = "#333333",
      horiz = TRUE,
      bty = "n",
      cex = 1.05,
      inset = c(0, -0.08)
    )
  }, res = 110)
}
