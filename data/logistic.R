data <- read.csv2("~/Documents/abschlussarbeit/data/sample.csv", sep = ",", header = TRUE)

xmin <- min(data$money)
xmax <- max(data$money)

modell <- as.formula("prime ~ money")
logit <- glm(modell, family = binomial, data = data)

print(logit)

logitFunction <- function(x){
    b0 <- coef(logit["coefficients"])[1]
    b1 <- coef(logit["coefficients"])[2]
    c <- b0 + x * b1
    return(exp(c) / (1 + exp(c)))
}

plot(logitFunction, xlim = c(xmin - 1, xmax + 1), ylim = c(-0.2, 1.2))
lines(data$money, data$prime, type="p")
