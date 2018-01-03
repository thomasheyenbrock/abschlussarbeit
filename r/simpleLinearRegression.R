data <- read.csv2("./data/sample.csv", sep = ",", header = TRUE)

xmin <- min(data$purchases)
xmax <- max(data$purchases)

ymin <- min(data$money)
ymax <- max(data$money)

modell <- as.formula("money ~ purchases")
slr <- lm(modell, data = data)

print(slr)

linearFunction <- function(x){
    b0 <- coef(slr["coefficients"])[1]
    b1 <- coef(slr["coefficients"])[2]
    return(b0 + x * b1)
}

plot(linearFunction, xlim = c(xmin - 1, xmax + 1), ylim = c(ymin - 1, ymax + 1))
lines(data$purchases, data$money, type="p")
