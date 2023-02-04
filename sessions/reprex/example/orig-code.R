# 12 lines = libraries ----
library(shiny)
library(quantmod)
library(PerformanceAnalytics)
library(zoo)
library(xts)
library(plyr)
library(ggplot2)
library(RiskPortfolios)
library(quadprog)
library(rvest)
library(purrr)
library(dplyr)

# 68 lines = ui ----
ui <- shinyUI(navbarPage(
  "Analysis",
  tabPanel(
    "Performance",
    titlePanel("Performance"),
    br(),
    sidebarLayout(
      sidebarPanel(),
      mainPanel()
    )
  ),
  tabPanel(
    "Construction",
    titlePanel("Construction"),
    br(),
    sidebarLayout(
      # most of this can go as side bar items are not affecting problem
      sidebarPanel(
        textInput("Stockw", "Ticker (Yahoo)"),
        numericInput("Sharesw", "Number of Shares", 0, min = 0, step = 1),
        selectInput("Countryw", "Country", choices = c("Canada", "United States")),
        column(
          12,
          splitLayout(
            cellWidths = c("70%", "30%"),
            actionButton("actionw", "Add", icon("dollar-sign"),
              style = "color: #fff; background-color: #337ab7; border-color: #2e6da4"
            ),
            actionButton("resetw", "Reset", icon("trash"),
              style = "color: #fff; background-color: #337ab7; border-color: #2e6da4"
            )
          )
        ),
        br(),
        br(),
        # keep these 2
        checkboxInput("EF", "Efficient Frontier"),
        checkboxInput("MonteCarlo", "Monte Carlo Simulation"),
        fluidRow(
          align = "center",
          p("____________________________________"),
          p("Ready to launch?", style = "font-size: 14px; font-weight: bold"),
          actionButton("Gow", "Go!", style = "color: #fff; background-color: #337ab7; border-color: #2e6da4; margin: auto")
        ),
      ),
      mainPanel(
        column(12,
          tableOutput("tablew"),
          style = "height:185px; overflow-y: scroll; border: 1px solid #e3e3e3; border-radius: 8px; background-color: #f7f7f7;text-align: left; overflow-x: hidden"
        ),
        column(12,
          br(),
          align = "left",
          splitLayout(
            cellWidths = c("70%", "30%"),
            plotOutput("Graphw"),
            conditionalPanel(..., tableOutput("EFWeightsTable")),
            conditionalPanel(..., tableOutput("MCWeightsTable")),
            conditionalPanel(..., tableOutput("EFMCWeightsTable"))
          )
        ),
        column(12,
          align = "center",
          conditionalPanel(..., plotOutput("GraphEF")),
          conditionalPanel(..., plotOutput("GraphMC")),
          conditionalPanel(..., plotOutput("GraphEFMC"))
        )
      )
    )
  )
))


# 458 lines = Server ----
server <- shinyServer(function(input, output) {


  # CONSTRUCTION

  # Store Initial Tickers/Number of Shares/Countries From User Inputs (In Vectors and Data Frame)
  valuesDFw <- reactiveValues() # Initialize Data Frame
  valuesDFw$dfw <- data.frame("Ticker" = numeric(0), "Shares" = numeric(0), "Country" = numeric(0))
  valuesVECw <- reactiveValues(tickersw = NULL, SharesVecw = NULL, CountryVecw = NULL) # Initialize Vectors

  observeEvent(input$actionw, {
    isolate(valuesDFw$dfw[nrow(valuesDFw$dfw) + 1, ] <- c(input$Stockw, input$Sharesw, input$Countryw)) # Store Data frame
    valuesVECw$tickersw <- c(valuesVECw$tickersw, input$Stockw) # Store Vectors
    valuesVECw$SharesVecw <- c(valuesVECw$SharesVecw, input$Sharesw)
    valuesVECw$CountryVecw <- c(valuesVECw$CountryVecw, input$Countryw)
  })

  # Reset Initial Tickers/Number of Shares/Countries From User Inputs (In Vectors and Data Frame)
  observeEvent(input$resetw, {
    valuesVECw$tickersw <- valuesVECw$tickersw[-1:-(length(valuesVECw$tickersw))] # Reset Vectors
    valuesVECw$SharesVecw <- valuesVECw$SharesVecw[-1:-(length(valuesVECw$SharesVecw))]
    valuesVECw$CountryVecw <- valuesVECw$CountryVecw[-1:-(length(valuesVECw$CountryVecw))]
    valuesDFw$dfw <- valuesDFw$dfw[0, ] # Reset Data Frame
  })

  # Call Function (Defined Bellow)
  OPw <- reactiveValues()
  observeEvent(input$Gow, {
    OPw$PC <- Run(valuesVECw$tickersw, valuesVECw$SharesVecw, valuesVECw$CountryVecw)

    if (input$EF == TRUE && input$MonteCarlo == FALSE) {
      showModal(modalDialog("Loading... Please Wait", footer = NULL)) # Creates Loading Pop-up Message
      OPw$LIST1 <- Run2(valuesVECw$tickersw, valuesVECw$SharesVecw, valuesVECw$CountryVecw)
    }
    removeModal() # Removes Loading Pop-up Message

    if (input$MonteCarlo == TRUE && input$EF == FALSE) {
      showModal(modalDialog("Loading... Please Wait", footer = NULL)) # Creates Loading Pop-up Message
      OPw$LIST2 <- Run3(valuesVECw$tickersw, valuesVECw$SharesVecw, valuesVECw$CountryVecw)
    }
    removeModal() # Removes Loading Pop-up Message

    if (input$MonteCarlo == TRUE && input$EF == TRUE) {
      showModal(modalDialog("Loading... Please Wait", footer = NULL)) # Creates Loading Pop-up Message
      OPw$LIST3 <- Run4(valuesVECw$tickersw, valuesVECw$SharesVecw, valuesVECw$CountryVecw)
    }
    removeModal() # Removes Loading Pop-up Message
  })

  # Output Variables
  output$tablew <- renderTable({
    valuesDFw$dfw
  }) # Initial Holdings Data Frame
  output$Graphw <- renderPlot(
    { # Pie Chart
      OPw$PC
    },
    height = 400,
    width = 400
  )

  output$GraphEF <- renderPlot(
    { # Graph EF
      OPw$LIST1[[1]]
    },
    height = 550,
    width = 700
  )

  output$EFWeightsTable <- renderTable(
    { # Efficient Portfolio Weights Data Frame
      OPw$LIST1[[2]]
    },
    colnames = TRUE
  )

  output$GraphMC <- renderPlot(
    { # Graph MC
      OPw$LIST2[[1]]
    },
    height = 550,
    width = 700
  )

  output$MCWeightsTable <- renderTable(
    { # Efficient Portfolio Weights Data Frame
      OPw$LIST2[[2]]
    },
    colnames = TRUE
  )

  output$GraphEFMC <- renderPlot(
    { # Graph EFMC
      OPw$LIST3[[1]]
    },
    height = 550,
    width = 700
  )

  output$EFMCWeightsTable <- renderTable(
    { # Efficient Portfolio Weights Data Frame
      OPw$LIST3[[2]]
    },
    colnames = TRUE
  )

  # Weights Function
  Run <- function(tickersw, SharesVecw, CountryVecw) {
    # *** this step pings yahoo ----
    USDtoCAD <- getQuote("CAD=X", src = "yahoo")[2] # Convert USD to CAD
    USDtoCAD <- USDtoCAD[[1]] # List to Numeric

    # Select Last Prices (From Tickers)
    PortfolioPricesw <- NULL
    tickersw <- toupper(tickersw) # CAPS
    # *** no need for these kinds of loops ----
    for (i in tickersw) {
      PortfolioPricesw <- cbind(PortfolioPricesw, getQuote(i, src = "yahoo")[, 2])
    }

    # Convert USD Denominated Assets to CAD
    for (i in 1:length(PortfolioPricesw)) {
      if (CountryVecw[i] == "United States") {
        PortfolioPricesw[i] <- USDtoCAD * PortfolioPricesw[i]
      }
    }

    # Find Weights
    MarketValuew <- SharesVecw * PortfolioPricesw
    Weightsw <- MarketValuew / sum(MarketValuew) * 100
    colnames(Weightsw) <- tickersw

    # Create Pie Chart
    tickersw <- tickersw[order(Weightsw)]
    Weightsw <- sort(Weightsw)
    Percent <- factor(paste(tickersw, scales::percent(Weightsw / 100, accuracy = 0.1)), paste(tickersw, scales::percent(Weightsw / 100, accuracy = 0.1)))

    Plot <- ggplot() +
      theme_bw() +
      geom_bar(aes(x = "", y = Weightsw, fill = Percent),
        stat = "identity", color = "white"
      ) +
      coord_polar("y", start = 0) +
      ggtitle("My Portfolio") +
      # *** theme won't affect output ----
      theme(
        axis.title = element_blank(),
        plot.title = element_text(size = 14, face = "bold.italic", hjust = 0.5),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        panel.grid = element_blank(),
        panel.border = element_blank()
      ) +
      guides(fill = guide_legend(reverse = TRUE)) +
      theme(
        legend.text = element_text(size = 12),
        legend.title = element_blank(),
        legend.key.size = unit(0.8, "cm")
      )

    # Output
    return(Plot)
  }

  # Efficient Frontier Function
  Run2 <- function(tickersw, SharesVecw, CountryVecw) {
    AdjustedPrices <- NULL
    TargetPrice <- NULL
    CurrentPrice <- NULL
    yret <- NULL
    wret <- NULL
    ReturnsVec <- NULL

    get_summary_table <- function(symbol) {
      url <- paste0("https://finance.yahoo.com/quote/", symbol)
      df <- url %>%
        read_html() %>%
        html_table(header = FALSE) %>%
        map_df(bind_cols) %>%
        as_tibble()

      names(df) <- c("name", "value")
      df["stock"] <- symbol

      df
    }
    # *** more loops ----
    for (i in tickersw) {
      AdjustedPrices <- cbind(
        AdjustedPrices,
        getSymbols.yahoo(i,
          from = "2019-01-01", to = Sys.Date(),
          periodicity = "weekly", auto.assign = F
        )[, 6]
      )
      TargetPrice <- as.numeric(gsub(",", "", unlist(get_summary_table(i)[16, 2])))
      CurrentPrice <- as.numeric(gsub(",", "", unlist(get_summary_table(i)[1, 2])))
      yret <- (TargetPrice - CurrentPrice) / CurrentPrice
      wret <- (1 + yret)^(1 / 52) - 1
      ReturnsVec <- c(ReturnsVec, wret)
    }

    Returnsw <- Return.calculate(AdjustedPrices, method = "discrete")
    Returnsw <- Returnsw[-1, ] # Removes NA

    # Minimum Variance Portfolio
    sigma <- cov(Returnsw)
    weights_mv <- optimalPortfolio(
      Sigma = sigma,
      control = list(type = "minvol", constraint = "lo")
    )

    # Efficient Frontier
    ret_min <- sum(ReturnsVec * weights_mv)
    ret_max <- max(ReturnsVec)
    ret_range <- seq(from = ret_min, to = ret_max, length.out = 30)

    vol <- rep(NA, 30)
    mu <- rep(NA, 30)
    eweights <- matrix(NA, nrow = length(tickersw), ncol = 30)

    # Min Weights
    eweights[, 1] <- weights_mv
    # *** these uncommon fns not related to problem ----
    vol[1] <- sqrt(tcrossprod(crossprod(weights_mv, sigma), weights_mv))
    mu[1] <- ret_min

    # Max Weights
    max_ret_idx <- which(ReturnsVec == ret_max)
    w_maxret <- rep(0, length(tickersw))
    w_maxret[max_ret_idx] <- 1

    eweights[, 30] <- w_maxret
    vol[30] <- apply(Returnsw, 2, sd)[max_ret_idx]
    mu[30] <- ReturnsVec[max_ret_idx]

    # Rest of Weights
    for (i in 2:29) {
      res <- solve.QP(Dmat = sigma, dvec = rep(0, length(tickersw)), Amat = cbind(matrix(rep(1, length(tickersw)), ncol = 1), diag(length(tickersw)), matrix(ReturnsVec, ncol = 1)), bvec = c(1, rep(0, length(tickersw)), ret_range[i]), meq = 1)
      w <- res$solution

      eweights[, i] <- w
      vol[i] <- sqrt(tcrossprod(crossprod(w, sigma), w))
      mu[i] <- sum(ReturnsVec * w)
    }

    # My Weights
    USDtoCAD <- getQuote("CAD=X", src = "yahoo")[2] # Convert USD to CAD
    USDtoCAD <- USDtoCAD[[1]] # List to Numeric

    # Select Last Prices (From Tickers)
    PortfolioPricesw <- NULL
    tickersw <- toupper(tickersw) # CAPS
    for (i in tickersw) {
      PortfolioPricesw <- cbind(PortfolioPricesw, getQuote(i, src = "yahoo")[, 2])
    }

    # Convert USD Denominated Assets to CAD
    for (i in 1:length(PortfolioPricesw)) {
      if (CountryVecw[i] == "United States") {
        PortfolioPricesw[i] <- USDtoCAD * PortfolioPricesw[i]
      }
    }

    # Find Weights
    MarketValuew <- SharesVecw * PortfolioPricesw
    Weightsw <- MarketValuew / sum(MarketValuew)
    Weightsw <- as.vector(Weightsw)

    MyMu <- sum(ReturnsVec * Weightsw)
    MyVol <- as.numeric(sqrt(tcrossprod(crossprod(Weightsw, sigma), Weightsw)))

    eweights <- round(eweights, 2)
    eweights <- t(eweights)
    colnames(eweights) <- gsub(".Adjusted", "", colnames(sigma))
    eweights <- abs(eweights[c(1, 5, 8, 12, 16, 19, 23, 26, 30), ])

    MYPLOT <- ggplot(as.data.frame(cbind(vol, mu)), aes(vol, mu)) +
      geom_line() +
      geom_point(aes(MyVol, MyMu, colour = "My Portfolio"),
        shape = 18,
        size = 3
      ) +
      ggtitle("Efficient Frontier") +
      xlab("Volatility (Weekly)") +
      ylab("Expected Returns (Weekly)") +
      theme(
        plot.title = element_text(size = 14, face = "bold.italic", hjust = 0.5, margin = margin(0, 0, 15, 0)),
        axis.title.x = element_text(size = 10, margin = margin(15, 0, 0, 0)),
        axis.title.y = element_text(size = 10, margin = margin(0, 15, 0, 0)),
        panel.border = element_rect(colour = "black", fill = NA, size = 1),
        legend.position = c(0.92, 0.06),
        legend.title = element_blank(),
        legend.text = element_text(size = 8),
        legend.background = element_rect(color = "black"),
        legend.key = element_blank()
      )

    return(list(MYPLOT, eweights))
  }

  # Monte Carlo Function
  Run3 <- function(tickersw, SharesVecw, CountryVecw) {
    AdjustedPrices <- NULL
    TargetPrice <- NULL
    CurrentPrice <- NULL
    yret <- NULL
    wret <- NULL
    ReturnsVec <- NULL

    get_summary_table <- function(symbol) {
      url <- paste0("https://finance.yahoo.com/quote/", symbol)
      df <- url %>%
        read_html() %>%
        html_table(header = FALSE) %>%
        map_df(bind_cols) %>%
        as_tibble()

      names(df) <- c("name", "value")
      df["stock"] <- symbol

      df
    }

    for (i in tickersw) {
      AdjustedPrices <- cbind(
        AdjustedPrices,
        getSymbols.yahoo(i,
          from = "2019-01-01", to = Sys.Date(),
          periodicity = "weekly", auto.assign = F
        )[, 6]
      )
      # *** how much of this is related? ----
      TargetPrice <- as.numeric(gsub(",", "", unlist(get_summary_table(i)[16, 2])))
      CurrentPrice <- as.numeric(gsub(",", "", unlist(get_summary_table(i)[1, 2])))
      yret <- (TargetPrice - CurrentPrice) / CurrentPrice
      wret <- (1 + yret)^(1 / 52) - 1
      ReturnsVec <- c(ReturnsVec, wret)
    }

    Returnsw <- Return.calculate(AdjustedPrices, method = "discrete")
    Returnsw <- Returnsw[-1, ] # Removes NA

    # Minimum Variance Portfolio
    sigma <- cov(Returnsw)
    # *** optimalPortfolio ----
    weights_mv <- optimalPortfolio(
      Sigma = sigma,
      control = list(type = "minvol", constraint = "lo")
    )

    # Efficient Frontier
    ret_min <- sum(ReturnsVec * weights_mv)
    ret_max <- max(ReturnsVec)
    ret_range <- seq(from = ret_min, to = ret_max, length.out = 30)

    vol <- rep(NA, 30)
    mu <- rep(NA, 30)
    eweights <- matrix(NA, nrow = length(tickersw), ncol = 30)

    # Min Weights
    eweights[, 1] <- weights_mv
    vol[1] <- sqrt(tcrossprod(crossprod(weights_mv, sigma), weights_mv))
    mu[1] <- ret_min

    # Max Weights
    max_ret_idx <- which(ReturnsVec == ret_max)
    w_maxret <- rep(0, length(tickersw))
    w_maxret[max_ret_idx] <- 1

    eweights[, 30] <- w_maxret
    vol[30] <- apply(Returnsw, 2, sd)[max_ret_idx]
    mu[30] <- ReturnsVec[max_ret_idx]

    # Rest of Weights
    for (i in 2:29) {
      res <- solve.QP(Dmat = sigma, dvec = rep(0, length(tickersw)), Amat = cbind(matrix(rep(1, length(tickersw)), ncol = 1), diag(length(tickersw)), matrix(ReturnsVec, ncol = 1)), bvec = c(1, rep(0, length(tickersw)), ret_range[i]), meq = 1)
      w <- res$solution

      eweights[, i] <- w
      vol[i] <- sqrt(tcrossprod(crossprod(w, sigma), w))
      mu[i] <- sum(ReturnsVec * w)
    }

    # Monte Carlo
    W_Vec <- matrix(NA, nrow = length(tickersw), ncol = 1000)
    VOL <- rep(NA, 1000)
    MU <- rep(NA, 1000)

    for (i in 1:1000) {
      W_Vec[, i] <- runif(length(tickersw)) # Generate 4 random numbers [0,1]
      W_Vec[, i] <- W_Vec[, i] / sum(W_Vec[, i]) # Sum of Weights = 1
      MU[i] <- sum(ReturnsVec * W_Vec[, i])
      VOL[i] <- sqrt(tcrossprod(crossprod(W_Vec[, i], sigma), W_Vec[, i]))
    }

    # My Weights
    USDtoCAD <- getQuote("CAD=X", src = "yahoo")[2] # Convert USD to CAD
    USDtoCAD <- USDtoCAD[[1]] # List to Numeric

    # Select Last Prices (From Tickers)
    PortfolioPricesw <- NULL
    tickersw <- toupper(tickersw) # CAPS
    for (i in tickersw) {
      PortfolioPricesw <- cbind(PortfolioPricesw, getQuote(i, src = "yahoo")[, 2])
    }

    # Convert USD Denominated Assets to CAD
    for (i in 1:length(PortfolioPricesw)) {
      if (CountryVecw[i] == "United States") {
        PortfolioPricesw[i] <- USDtoCAD * PortfolioPricesw[i]
      }
    }

    # Find Weights
    MarketValuew <- SharesVecw * PortfolioPricesw
    Weightsw <- MarketValuew / sum(MarketValuew)
    Weightsw <- as.vector(Weightsw)

    MyMu <- sum(ReturnsVec * Weightsw)
    MyVol <- as.numeric(sqrt(tcrossprod(crossprod(Weightsw, sigma), Weightsw)))

    eweights <- round(eweights, 2)
    eweights <- t(eweights)
    colnames(eweights) <- gsub(".Adjusted", "", colnames(sigma))
    eweights <- abs(eweights[c(1, 5, 8, 12, 16, 19, 23, 26, 30), ])

    MYPLOT <- ggplot(as.data.frame(cbind(VOL, MU)), aes(VOL, MU)) +
      geom_point(shape = 1) +
      geom_point(aes(MyVol, MyMu, colour = "My Portfolio"),
        shape = 18,
        size = 3
      ) +
      geom_line(data = data.frame(vol, mu), mapping = aes(vol, mu)) +
      ggtitle("Efficient Frontier") +
      xlab("Volatility (Weekly)") +
      ylab("Expected Returns (Weekly)") +
      theme(
        plot.title = element_text(size = 14, face = "bold.italic", hjust = 0.5, margin = margin(0, 0, 15, 0)),
        axis.title.x = element_text(size = 10, margin = margin(15, 0, 0, 0)),
        axis.title.y = element_text(size = 10, margin = margin(0, 15, 0, 0)),
        panel.border = element_rect(colour = "black", fill = NA, size = 1),
        legend.position = c(0.92, 0.06),
        legend.title = element_blank(),
        legend.text = element_text(size = 8),
        legend.background = element_rect(color = "black"),
        legend.key = element_blank()
      )

    return(list(MYPLOT, eweights))
  }

  # Monte Carlo and EF Function
  Run4 <- function(tickersw, SharesVecw, CountryVecw) {
    Run3(tickersw, SharesVecw, CountryVecw)
  }
})

shinyApp(ui = ui, server = server)

# Problems:
- ui overly packed with superfluous aesthetics - adding icons to buttons
- loops and website queries unrelated to ui problem
- many unusual libraries that dont need to be used
- lots of cbind hardcoded values, matricies, renaming columns, etc
