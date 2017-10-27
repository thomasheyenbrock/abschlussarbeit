data <- read.csv2("~/Documents/abschlussarbeit/data/logistic.csv", sep = ",", header = TRUE)

xmin <- min(data$x)
xmax <- max(data$x)

modell <- as.formula("y ~ x")
logit <- lm(modell, data = data)

print(logit)

linearFunction <- function(x){
    b0 <- coef(logit["coefficients"])[1]
    b1 <- coef(logit["coefficients"])[2]
    return(b0 + x * b1)
}

plot(linearFunction, xlim = c(xmin - 1, xmax + 1), ylim = c(-0.2, 1.2))
lines(data$x, data$y, type="p")
