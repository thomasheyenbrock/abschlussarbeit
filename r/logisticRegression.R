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

modell <- as.formula("premium ~ money")
logit <- glm(modell, family = binomial, data = data)

end_time <- Sys.time()

print(logit)
print(end_time - start_time)

if (plot) {
  xmin <- min(data$money)
  xmax <- max(data$money)

  logitFunction <- function(x){
    b0 <- coef(logit["coefficients"])[1]
    b1 <- coef(logit["coefficients"])[2]
    c <- b0 + x * b1
    return(exp(c) / (1 + exp(c)))
  }

  xplot <- seq(xmin - 1, xmax + 1, 1000)
  yplot <- logitFunction(xplot)

  plot(
    c(xmin - 1, xmax + 1),
    c(-0.2, 1.2),
    type = "n",
    xlab = "money",
    ylab = "premium",
    main = "Logistische Regression"
  )
  lines(
    data$money,
    data$premium,
    type="p"
  )
  lines(
    xplot,
    yplot,
    col = "red",
    lwd = 2
  )
}
