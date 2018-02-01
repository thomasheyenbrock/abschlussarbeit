import sys
import os.path as p
import csv
import matplotlib.pyplot as plt

def calculate_benchmarks():
  filename = p.abspath(p.join(p.dirname(p.realpath(__file__)), "benchmarks.csv"))
  csvfile = open(filename, newline="")
  csvreader = csv.reader(csvfile, delimiter=",", quotechar="|")
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
  for row in csvreader:
    if not row[0] == "language":
      count[row[1]][row[2]][row[0]]["count"] += 1
      count[row[1]][row[2]][row[0]]["time"] += float(row[3])

  for regression_type, obj1 in count.items():
    print("benchmarks for %s:\n" % regression_type)
    table = {"header": [""], "r": ["r"], "tensorflow": ["tensorflow"], "mysql": ["mysql"], "postgresql": ["postresql"]}
    for number_datapoints, obj2 in obj1.items():
      table["header"].append(str(number_datapoints))
      for language, data in obj2.items():
        if data["count"] > 0:
          table[language].append(str(data["time"] / data["count"])[:10])
        else:
          table[language].append("          ")
        # print(regression_type, number_datapoints, language, data["count"])
        if not data["count"] == 100:
          print(regression_type, number_datapoints, language, data["count"])

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
      "|" + "  %s   |  %s  |  %s  |  %s  |  %s  |  %s  " % tuple(table["postgresql"]) + "|",
      "|" + "-" * 89 + "|"
    ]
    print(str.join("\n", print_table))
    print("\n")

  return count

def plot(benchmarks, regression_type, plot_title):
  x = [10, 100, 1000, 10000, 100000]
  r = []
  t = []
  m = []
  p = []
  for i in x:
    if benchmarks[regression_type][str(i)]["r"]["count"] > 0:
      r.append(
        benchmarks[regression_type][str(i)]["r"]["time"] /
        benchmarks[regression_type][str(i)]["r"]["count"]
      )
    else:
      r.append(None)

    if benchmarks[regression_type][str(i)]["tensorflow"]["count"] > 0:
      t.append(
        benchmarks[regression_type][str(i)]["tensorflow"]["time"] /
        benchmarks[regression_type][str(i)]["tensorflow"]["count"]
      )
    else:
      t.append(None)
    if benchmarks[regression_type][str(i)]["mysql"]["count"]:
      m.append(
        benchmarks[regression_type][str(i)]["mysql"]["time"] /
        benchmarks[regression_type][str(i)]["mysql"]["count"]
      )
    else:
      m.append(None)
    if benchmarks[regression_type][str(i)]["postgresql"]["count"]:
      p.append(
        benchmarks[regression_type][str(i)]["postgresql"]["time"] /
        benchmarks[regression_type][str(i)]["postgresql"]["count"]
      )
    else:
      p.append(None)

  plt.loglog(x, r, "r-", label="R")
  plt.loglog(x, t, "y-", label="TensorFlow")
  plt.loglog(x, m, "b-", label="MySQL")
  plt.loglog(x, p, "g-", label="PostgreSQL")
  plt.title(plot_title)
  plt.legend()
  plt.show()

def main(argv):
  print_plots = True
  if len(argv) == 2:
    if argv[1] == "-":
      print_plots = False

  benchmarks = calculate_benchmarks()

  if print_plots:
    plot(benchmarks, "simple linear regression", "Einfache lineare Regression")
    plot(benchmarks, "multiple linear regression", "Multiple lineare Regression")
    plot(benchmarks, "logistic regression", "Logistische Regression")

if __name__ == "__main__":
  main(sys.argv)
