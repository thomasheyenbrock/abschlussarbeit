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
modell <- as.formula("money ~ purchases")

# Führe die Regression durch.
slr <- lm(modell, data = data)

# Speichere die aktuelle Zeit zur Zeitmessung.
end_time <- Sys.time()

# Drucke die Ergebnisse der Regressionsanalyse und die Laufzeit.
print(slr)
print(end_time - start_time)

# Erstelle einen Plot.
if (plot) {
  # Bestimme die Grenzen für die unabhängige Variable.
  xmin <- min(data$purchases)
  xmax <- max(data$purchases)

  # Bestimme die Grenzen für die abhängige Variable.
  ymin <- min(data$money)
  ymax <- max(data$money)

  # Bestimme die Koeffizienten aus der Regressionsanalyse.
  b0 <- coef(slr["coefficients"])[1]
  b1 <- coef(slr["coefficients"])[2]

  # Erzeuge Vektoren zum Plot der linearen Funktion.
  xplot <- c(xmin - 1, xmax + 1)
  yplot <- c(b0 + (xmin - 1) * b1, b0 + (xmax + 1) * b1)

  # Erstelle den Plot.
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
  # Füge die Datenpunkte ein.
  lines(
    data$purchases,
    data$money,
    type="p"
  )
  # Füge die Ausgleichsgerade ein.
  lines(
    xplot,
    yplot,
    col = "red",
    lwd = 2
  )
}
