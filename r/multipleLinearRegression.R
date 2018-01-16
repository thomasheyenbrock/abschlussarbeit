args = commandArgs(trailingOnly = TRUE)

n = 100000
if (length(args) > 0) {
  n = strtoi(args[1])
}

start_time <- Sys.time()

data <- head(read.csv2("./data/sample.csv", sep = ",", header = TRUE), n)

modell <- as.formula("money ~ purchases + age")
mlr <- lm(modell, data = data)

end_time <- Sys.time()

print(mlr)
print(end_time - start_time)
