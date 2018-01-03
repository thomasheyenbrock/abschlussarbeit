data <- read.csv2("./data/sample.csv", sep = ",", header = TRUE)

modell <- as.formula("money ~ purchases + age")
mlr <- lm(modell, data = data)

print(mlr)
