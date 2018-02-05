import sys
import os.path as p
import csv
import matplotlib.pyplot as plt

# Erzeuge Funktion, die die Benchmarks aus der csv-Datei einliest un gruppiert.
def calculate_benchmarks():
  # Bestimme den Dateipfad der benchmark-Datei und öffne diese.
  filename = p.abspath(p.join(p.dirname(p.realpath(__file__)), "benchmarks.csv"))
  csvfile = open(filename, newline="")
  csvreader = csv.reader(csvfile, delimiter=",", quotechar="|")

  # Erstelle ein dictionary, in dem die Laufzeiten aggregiert werden sollen.
  count = {
    "simple linear regression": {
      "10": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "100": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "1000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "10000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "100000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      }
    },
    "multiple linear regression": {
      "10": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "100": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "1000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "10000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "100000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      }
    },
    "logistic regression": {
      "10": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "100": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "1000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "10000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      },
      "100000": {
        "r": {"count": 0, "time": 0},
        "tensorflow": {"count": 0, "time": 0},
        "mysql": {"count": 0, "time": 0},
        "postgresql": {"count": 0, "time": 0}
      }
    }
  }

  # Iteriere über alle Zeilen der csv-Datei.
  for row in csvreader:
    # Überspringe die erste Zeile.
    if not row[0] == "language":
      # Füge die Laufzeit in das dictionary ein.
      count[row[1]][row[2]][row[0]]["count"] += 1
      count[row[1]][row[2]][row[0]]["time"] += float(row[3])

  # Durchlaufe das dictionary (Typ der Regression).
  for regression_type, obj1 in count.items():
    print("benchmarks for %s:\n" % regression_type)

    # Erzeuge ein neues dictionary, um eine Tabelle zu drucken.
    table = {"header": [""], "r": ["r"], "tensorflow": ["tensorflow"], "mysql": ["mysql"], "postgresql": ["postgresql"]}

    # Iteriere über die im ersten dictionary enthalten dictionaries (Anzahl Datenpunkte).
    for number_datapoints, obj2 in obj1.items():
      # Ergänze die Anzahl der Datenpunkte als Spaltenbeschriftung.
      table["header"].append(str(number_datapoints))

      # Iteriere über die im zweiten dictionary enthalten dictionaries (Sprache).
      for language, data in obj2.items():
        # Füge die durchschnittliche Laufzeit in die Tabelle ein (falls Lafzeiten vorhanden sind).
        if data["count"] > 0:
          table[language].append(str(data["time"] / data["count"])[:10])
        else:
          table[language].append("          ")

    # Erzeuge die zu druckende Tabelle zeilenweise.
    print_table = [
      "|" + "-" * 89 + "|",
      "|" + "  %s            |  %s          |  %s         |  %s        |  %s       |  %s      " % tuple(table["header"]) + "|",
      "|" + "-" * 89 + "|",
      "|" + "  %s           |  %s  |  %s  |  %s  |  %s  |  %s  " % tuple(table["r"]) + "|",
      "|" + "-" * 89 + "|",
      "|" + "  %s  |  %s  |  %s  |  %s  |  %s  |  %s  " % tuple(table["tensorflow"]) + "|",
      "|" + "-" * 89 + "|",
      "|" + "  %s       |  %s  |  %s  |  %s  |  %s  |  %s  " % tuple(table["mysql"]) + "|",
      "|" + "-" * 89 + "|",
      "|" + "  %s  |  %s  |  %s  |  %s  |  %s  |  %s  " % tuple(table["postgresql"]) + "|",
      "|" + "-" * 89 + "|"
    ]

    # Drucke die Tabelle und eine Leerzeile danach.
    print(str.join("\n", print_table))
    print("\n")

  # Gib das dictionary mit allen aggregierten Laufzeiten zurück.
  return count

# Erzeuge Funktion, um die Laufzeiten für eine bestimmte Art der Regression zu plotten.
def plot(benchmarks, regression_type, plot_title):
  # Definiere ein Array mit den Anzahlen der Datenpunkte für den Plot.
  x = [10, 100, 1000, 10000, 100000]

  # Erzeuge ein dictionary mit leeren Arrays für die durchschnittlichen Laufzeiten.
  values = {
    "r": [],
    "tensorflow": [],
    "mysql": [],
    "postgresql": []
  }

  # Durchlaufe alle Sprachen.
  for language in ["r", "tensorflow", "mysql", "postgresql"]:
    # Durchlaufe die Anzahl der Datenpunkte.
    for number_datapoints in x:
      # Füge die durchschnittliche Laufzeit in das Array ein (falls Laufzeiten vorhanden sind).
      if benchmarks[regression_type][str(number_datapoints)][language]["count"] > 0:
        values[language].append(
          benchmarks[regression_type][str(number_datapoints)][language]["time"] /
          benchmarks[regression_type][str(number_datapoints)][language]["count"]
        )
      else:
        values[language].append(None)

  # Erzeuge den Plot.
  plt.loglog(x, values["r"], "r-", label="R")
  plt.loglog(x, values["tensorflow"], "y-", label="TensorFlow")
  plt.loglog(x, values["mysql"], "b-", label="MySQL")
  plt.loglog(x, values["postgresql"], "g-", label="PostgreSQL")
  plt.title(plot_title)
  plt.legend()
  plt.xlabel("Anzahl der Datenpunkte")
  plt.ylabel("Laufzeit in Sekunden")
  plt.show()

def main(argv):
  # Erzeuge default-Wert, ob Plots erstellt werden sollen.
  print_plots = True

  # Überschreibe default-Wert, falls ein entsprechendes Argument übergeben wurde.
  if len(argv) == 2:
    if argv[1] == "-":
      print_plots = False

  # Berechne und drucke die Benchmarks.
  benchmarks = calculate_benchmarks()

  # Plote die Benchmarks (falls gewüscht).
  if print_plots:
    plot(benchmarks, "simple linear regression", "Einfache lineare Regression")
    plot(benchmarks, "multiple linear regression", "Multiple lineare Regression")
    plot(benchmarks, "logistic regression", "Logistische Regression")

# Führe die main-Funktion aus.
if __name__ == "__main__":
  main(sys.argv)
