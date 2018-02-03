args = commandArgs(trailingOnly = TRUE)

n <- 1000
plot <- TRUE
if (length(args) == 1) {
  if (substr(args[1], 1, 1) == "-") {
    plot <- FALSE
  } else {
    n = strtoi(args[1])
  }
}
if (length(args) == 2) {
  if (substr(args[1], 1, 1) == "-") {
    n = strtoi(args[2])
  } else {
    n = strtoi(args[1])
  }
  plot <- FALSE
}

start_time <- Sys.time()

data <- head(read.csv2("./data/sample.csv", sep = ",", header = TRUE), n)

modell <- as.formula("money ~ purchases")
slr <- lm(modell, data = data)

end_time <- Sys.time()

print(slr)
print(end_time - start_time)

if (plot) {
  xmin <- min(data$purchases)
  xmax <- max(data$purchases)

  ymin <- min(data$money)
  ymax <- max(data$money)

  b0 <- coef(slr["coefficients"])[1]
  b1 <- coef(slr["coefficients"])[2]

  xplot <- c(xmin - 1, xmax + 1)
  yplot <- c(b0 + (xmin - 1) * b1, b0 + (xmax + 1) * b1)

  plot(
    c(xmin - 1, xmax + 1),
    c(ymin - 1, ymax + 1),
    type = "n",
    xlab = "purchases",
    ylab = "money",
    main = "Einfache lineare Regression",
    sub = paste("money = ", b0, "+", b1, "* purchases"),
    col.sub = "darkgray"
  )
  lines(
    data$purchases,
    data$money,
    type="p"
  )
  lines(
    xplot,
    yplot,
    col = "red",
    lwd = 2
  )
}
