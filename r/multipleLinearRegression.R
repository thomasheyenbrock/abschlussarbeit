# Lese die übergebenen Argumente ein.
args = commandArgs(trailingOnly = TRUE)

# Setzte default-Wert für die Anzahl der Datenpunkte.
n = 1000

# Ändere den default-Wert, falls ein entsprechendes Argumente übergeben wurde.
if (length(args) > 0) {
  n = strtoi(args[1])
}

# Speichere die aktuelle Zeit zur Zeitmessung.
start_time <- Sys.time()

# Lies die Daten aus der csv-Datei ein.
data <- head(read.csv2("./data/sample.csv", sep = ",", header = TRUE), n)

# Definiere das Modell.
modell <- as.formula("money ~ purchases + age")

# Führe die Regression durch.
mlr <- lm(modell, data = data)

# Speichere die aktuelle Zeit zur Zeitmessung.
end_time <- Sys.time()

# Drucke die Ergebnisse der Regressionsanalyse und die Laufzeit.
print(mlr)
print(end_time - start_time)
