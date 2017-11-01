data <- read.csv2("~/Documents/abschlussarbeit/data/sample.csv", sep = ",", header = TRUE)

xmin <- min(data$purchases)
xmax <- max(data$purchases)

ymin <- min(data$money)
ymax <- max(data$money)

modell <- as.formula("money ~ purchases")
logit <- lm(modell, data = data)

print(logit)

linearFunction <- function(x){
    b0 <- coef(logit["coefficients"])[1]
    b1 <- coef(logit["coefficients"])[2]
    return(b0 + x * b1)
}

plot(linearFunction, xlim = c(xmin - 1, xmax + 1), ylim = c(ymin - 1, ymax + 1))
lines(data$purchases, data$money, type="p")
