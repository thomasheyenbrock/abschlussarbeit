args = commandArgs(trailingOnly = TRUE)

n = 100000
if (length(args) > 0) {
    n = strtoi(args[1])
}

start_time <- Sys.time()

data <- head(read.csv2("./data/sample.csv", sep = ",", header = TRUE), n)

xmin <- min(data$purchases)
xmax <- max(data$purchases)

ymin <- min(data$money)
ymax <- max(data$money)

modell <- as.formula("money ~ purchases")
slr <- lm(modell, data = data)

end_time <- Sys.time()

print(slr)
print(end_time - start_time)

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
