data <- read.csv2("~/Documents/abschlussarbeit/data/logistic.csv", sep = ",", header = TRUE)

xmin <- min(data$x)
xmax <- max(data$x)

modell <- as.formula("y ~ x")
logit <- glm(modell, family = binomial, data = data)

print(logit)

logitFunction <- function(x){
    b0 <- coef(logit["coefficients"])[1]
    b1 <- coef(logit["coefficients"])[2]
    c <- b0 + x * b1
    return(exp(c) / (1 + exp(c)))
}

plot(logitFunction, xlim = c(xmin - 1, xmax + 1), ylim = c(-0.2, 1.2))
lines(data$x, data$y, type="p")
