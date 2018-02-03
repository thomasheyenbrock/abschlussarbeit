import numpy as np
import tensorflow as tf
import os.path as p
import csv
import sys
import matplotlib.pyplot as plt
from time import time

# Erstelle eine Funktion zum einlesen der Daten aus der csv-Daten.
def get_data(n_samples):
  # Bestimme den Pfad der csv-Datei und öffne die Datei.
  filename = p.abspath(p.join(p.dirname(p.realpath(__file__)), "..", "data", "sample.csv"))
  csvfile = open(filename, newline="")
  csvreader = csv.reader(csvfile, delimiter=",", quotechar="|")

  # Erstelle leere Arrays für die Daten.
  x = []
  x_plot = []
  y = []

  # Iteriere über die Zeilen der csv-Datei.
  for row in csvreader:
    # Überspringe die erste Zeile.
    if not row[0] == "age":
      # Füge die Daten der Zeile zum jeweiligen Array hinzu.
      x.append([int(row[1])])
      x_plot.append(int(row[1]))
      y.append(int(row[2]))

  # Gib die Arrays bis zu der gewünschten Menge an Datenpunkten zurück.
  return (np.array(x[:n_samples]), x_plot[:n_samples], np.transpose([y[:n_samples]]))

def main(argv):
  # Bestimme default-Werte für die Anzahl der Datenpunkte und ob geplottet werden soll.
  datapoint_size = 1000
  plot = True

  # Ändere die default-Werte, wenn entsprechende Argumente übergeben wurden.
  if len(argv) == 2:
    if argv[1] == "-":
      plot = False
    else:
      datapoint_size = int(argv[1])
  elif len(argv) == 3:
    plot = False
    if argv[1] == "-":
      datapoint_size = int(argv[2])
    else:
      datapoint_size = int(argv[1])

  # Bestimme die aktuelle Zeit zur Zeitmessung.
  start_time = time()

  # Bestimme die Anzahl der Iterationen und die Schrittweite (anhängig von der Anzahl der Datenpunkte.)
  steps = 2000
  if datapoint_size <= 10:
    learn_rate = 0.0076
  elif datapoint_size <= 100:
    learn_rate = 0.0064
  elif datapoint_size <= 1000:
    learn_rate = 0.0056
  elif datapoint_size <= 10000:
    learn_rate = 0.0054
  elif datapoint_size <= 100000:
    learn_rate = 0.0054

  # Deklariere die Platzhalter und Variablen.
  x = tf.placeholder(tf.float32, [None, 1])
  y = tf.placeholder(tf.float32, [None, 1])
  alpha = tf.Variable(tf.zeros([1]))
  beta = tf.Variable(tf.zeros([1, 1]))
  y_calc = tf.matmul(x, beta) + alpha

  # Definiere die Kostenfunktion und die Minimierungsoperation.
  cost = tf.reduce_mean(tf.square(y - y_calc))
  train_step = tf.train.GradientDescentOptimizer(learn_rate).minimize(cost)

  # Importiere die Daten.
  (all_xs, plot_xs, all_ys) = get_data(datapoint_size)

  # Starte eine Session in TensorFlow.
  sess = tf.Session()
  init = tf.global_variables_initializer()
  sess.run(init)

  # Iteriere und trainiere.
  for i in range(steps):
    feed = { x: all_xs, y: all_ys }
    sess.run(train_step, feed_dict=feed)

  # Bestimme die aktuellen Parameterwerte nach der Anzahl der Iterationen.
  (curr_alpha, curr_beta, curr_cost) = sess.run([alpha, beta, cost], feed_dict=feed)

  # Bestimme die aktuelle Zeit zur Zeitmessung.
  end_time = time()

  # Drucke die Ergebnisse.
  print("alpha:  %f" % curr_alpha)
  print("beta:   %f" % curr_beta)
  print("cost:   %f" % curr_cost)
  print("")
  print("time elapsed:  %f sec" % (end_time - start_time))

  # Erstelle einen Plot (falls gewünscht).
  if plot:
    plt.plot(plot_xs, all_ys, "ro", label="Original data")
    plt.plot(plot_xs, curr_beta * all_xs + curr_alpha , label="Fitted line")
    plt.legend()
    plt.show()

# Führe die main-Funktion aus.
if __name__ == "__main__":
  main(sys.argv)
