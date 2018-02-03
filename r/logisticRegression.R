# Lese die übergebenen Argumente ein.
args = commandArgs(trailingOnly = TRUE)

# Setzte default-Werte für die Anzahl der Datenpunkte und ob geplottet werden soll.
n <- 1000
plot <- TRUE

# Ändere die default-Werte, falls entsprechende Argumente übergeben wurden.
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

# Speichere die aktuelle Zeit zur Zeitmessung.
start_time <- Sys.time()

# Lies die Daten aus der csv-Datei ein.
data <- head(read.csv2("./data/sample.csv", sep = ",", header = TRUE), n)

# Definiere das Modell.
modell <- as.formula("premium ~ money")

# Führe die Regression durch.
logit <- glm(modell, family = binomial, data = data)

# Speichere die aktuelle Zeit zur Zeitmessung.
end_time <- Sys.time()

# Drucke die Ergebnisse der Regressionsanalyse und die Laufzeit.
print(logit)
print(end_time - start_time)

# Erstelle einen Plot.
if (plot) {
  # Bestimme die Grenzen für die unabhängige Variable.
  xmin <- min(data$money)
  xmax <- max(data$money)

  # Bestimme eine Funktion, die den Wert der logistischen Funktion berechnet.
  logitFunction <- function(x){
    # Verwende die Parameter aus der Regressionsanalyse.
    b0 <- coef(logit["coefficients"])[1]
    b1 <- coef(logit["coefficients"])[2]
    c <- b0 + x * b1
    return(exp(c) / (1 + exp(c)))
  }

  # Erzeuge Vektoren zum Plot der logistischen Funktion.
  xplot <- seq(xmin - 1, xmax + 1, 1000)
  yplot <- logitFunction(xplot)

  # Erstelle den Plot.
  plot(
    c(xmin - 1, xmax + 1),
    c(-0.2, 1.2),
    type = "n",
    xlab = "money",
    ylab = "premium",
    main = "Logistische Regression"
  )
  # Füge die Datenpunkte ein.
  lines(
    data$money,
    data$premium,
    type="p"
  )
  # Füge die logistische Funktion ein.
  lines(
    xplot,
    yplot,
    col = "red",
    lwd = 2
  )
}
