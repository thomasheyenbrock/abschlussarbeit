args = commandArgs(trailingOnly = TRUE)

n = 100000
if (length(args) > 0) {
    n = strtoi(args[1])
}

start_time <- Sys.time()

data <- head(read.csv2("./data/sample.csv", sep = ",", header = TRUE), n)

xmin <- min(data$money)
xmax <- max(data$money)

modell <- as.formula("prime ~ money")
logit <- glm(modell, family = binomial, data = data)

end_time <- Sys.time()

print(logit)
print(end_time - start_time)

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
    ylab = "prime",
    main = "Logistische Regression"
)
lines(
    data$money,
    data$prime,
    type="p"
)
lines(
    xplot,
    yplot,
    col = "red",
    lwd = 2
)
