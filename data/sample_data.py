import sys
import random
import math

# Erzeuge Funktion, die die Daten in eine csv-Datei schreibt.
def outputCsv(data):
  # Erzeuge ein Array mit den zu schreibenden Zeilen und übergebe die Spaltennamen.
  output = ["%s,%s,%s,%s" % (
    "age",
    "purchases",
    "money",
    "premium"
  )]

  # Iteriere über alle Datenpukte.
  for datapoint in data:
    # Hänge eine Zeile an das output-Array an.
    output.append("%s,%s,%s,%a" % (
      datapoint["age"],
      datapoint["purchases"],
      datapoint["money"],
      datapoint["premium"]
    ))

  # Öffne eine csv-Datei.
  f = open("sample.csv", "w")

  # Schreibe das output-Array als mit Zeilenumbrüchen gejointen String in die Datei.
  f.write("\n".join(output))

  return

# Erzeuge Funktion, die die Daten in eine sql-Datei schreibt.
def outputSql(data):
  # Erzeuge ein Array mit den zu schreibenden Zeilen.
  # Füge SQL-Abfragen ein, die eine eventuell bestehende Tabelle löscht und neu erstellet.
  # Beginne mit der INSERT-Abfrage.
  output = [
    "DROP TABLE IF EXISTS sample;",
    "",
    "CREATE TABLE sample (",
    "  age INTEGER,",
    "  purchases INTEGER,",
    "  money INTEGER,",
    "  premium INTEGER",
    ");",
    "",
    "INSERT INTO sample (%s,%s,%s,%s) VALUES" % (
      "age",
      "purchases",
      "money",
      "premium"
    )
  ]

  # Iteriere über alle Datenpunkte.
  for datapoint in data:
    # Füge eine Zeile an die INSERT-Abfrage an.
    output.append("(%s,%s,%s,%s)," % (
      datapoint["age"],
      datapoint["purchases"],
      datapoint["money"],
      datapoint["premium"]
    ))

  # Ersetze das letzte Komma durch ein Semikolon, um die INSERT-Abfrage zu beenden.
  output[-1] = output[-1][:-1] + ";"

  # Öffne eine sql-Datei.
  f = open("sample.sql", "w")

  # Schreibe das output-Array als mit Zeilenumbrüchen gejointen String in die Datei.
  f.write("\n".join(output))

  return

def main(argv):
  # Beende die Ausführung, wenn die Anzahl der zu erzeugenden Datenpunkte nicht übergeben wurde.
  if len(argv) < 2:
    print("Please provide number of datapoints that shall be generated.")
    return

  # Erzeuge ein leeres Array für die Daten.
  data = []

  # Iteriere über die Anzahl der zu erzeugenden Datenpunkte.
  for i in range(0, int(argv[1])):
    # Bestimme pseudo-zufällige Werte für den Datenpunkt.
    age = int(max(random.normalvariate(25, 10) + 10, 18))
    purchases = int(max(random.normalvariate(10, 10), 1))
    money = int(max(purchases * 25 + random.normalvariate(0, (math.log(purchases) + 1) * 12), 0.01) * 100)
    if random.uniform(0, 1) > math.exp(0.2 * purchases - 2) / (1 + math.exp(0.2 * purchases - 2)):
      premium = 0
    else:
      premium = 1

    # Hänge den Datenpunkt an das Array an.
    data.append({
      "age": age,
      "purchases": purchases,
      "money": money,
      "premium": premium
    })

  # Schreibe die generierten Daten in eine .csv und eine .sql Datei.
  outputCsv(data)
  outputSql(data)
  return

# Führe die main-Funktion aus.
if __name__ == "__main__":
  main(sys.argv)
