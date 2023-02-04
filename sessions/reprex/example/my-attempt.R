library(shiny)

ui <- shinyUI(fluidPage(
  sidebarLayout(
    sidebarPanel(
      checkboxInput("EF", "Efficient Frontier"),
      checkboxInput("MonteCarlo", "Monte Carlo Simulation")
    ),
    mainPanel(
      column(12,
        align = "left",
        splitLayout(
          cellWidths = c("70%", "30%"),
          plotOutput("Graphw"),
          list(
            conditionalPanel(..., tableOutput("EFWeightsTable")),
            conditionalPanel(..., tableOutput("MCWeightsTable")),
            conditionalPanel(..., tableOutput("EFMCWeightsTable"))
          )
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
))

server <- function(input, output, session) {
  # dummy tables
  df <- mtcars[1:3, 1:3]
  output$tablew <- renderTable(df)
  output$EFWeightsTable <- renderTable(df)
  output$MCWeightsTable <- renderTable(df)
  output$EFMCWeightsTable <- renderTable(df)
  # dummy plots
  output$GraphEF <- renderPlot(plot(1, 1, main = "Efficient Frontier"))
  output$GraphMC <- renderPlot(plot(1, 1, main = "Monte Carlo"))
  output$GraphEFMC <- renderPlot(plot(1, 1, main = "Both"))
  output$Graphw <- renderPlot(plot(1, 1, main = "Graph W"))
}

shinyApp(ui, server)
