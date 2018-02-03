import numpy as np
import tensorflow as tf
import os.path as p
import csv
import sys
from time import time

# Erstelle eine Funktion zum einlesen der Daten aus der csv-Daten.
def get_data(n_samples):
  # Bestimme den Pfad der csv-Datei und öffne die Datei.
  filename = p.abspath(p.join(p.dirname(p.realpath(__file__)), "..", "data", "sample.csv"))
  csvfile = open(filename, newline="")
  csvreader = csv.reader(csvfile, delimiter=",", quotechar="|")

  # Erstelle leere Arrays für die Daten.
  x = []
  y = []

  # Iteriere über die Zeilen der csv-Datei.
  for row in csvreader:
    # Überspringe die erste Zeile.
    if not row[0] == "age":
      # Füge die Daten der Zeile zum jeweiligen Array hinzu.
      x.append([int(row[1]), int(row[0])])
      y.append(int(row[2]))

  # Gib die Arrays bis zu der gewünschten Menge an Datenpunkten zurück.
  return (np.array(x[:n_samples]), np.transpose([y[:n_samples]]))

def main(argv):
  # Bestimme default-Wert für die Anzahl der Datenpunkte.
  datapoint_size = 1000

  # Ändere den default-Wert, wenn ein entsprechendes Argument übergeben wurde.
  if len(argv) == 2:
    datapoint_size = int(argv[1])

  # Bestimme die aktuelle Zeit zur Zeitmessung.
  start_time = time()

  # Bestimme die Anzahl der Iterationen und die Schrittweite (anhängig von der Anzahl der Datenpunkte.)
  steps = 50000
  if datapoint_size <= 10:
    learn_rate = 0.00093
  elif datapoint_size <= 100:
    learn_rate = 0.00078
  elif datapoint_size <= 1000:
    learn_rate = 0.0007
  elif datapoint_size <= 10000:
    learn_rate = 0.00071
  elif datapoint_size <= 100000:
    learn_rate = 0.00071

  # Deklariere die Platzhalter und Variablen.
  x = tf.placeholder(tf.float32, [None, 2])
  y = tf.placeholder(tf.float32, [None, 1])
  alpha = tf.Variable(tf.zeros([1]))
  beta = tf.Variable(tf.zeros([2, 1]))
  y_calc = tf.matmul(x, beta) + alpha

  # Definiere die Kostenfunktion und die Minimierungsoperation.
  cost = tf.reduce_mean(tf.square(y - y_calc))
  train_step = tf.train.GradientDescentOptimizer(learn_rate).minimize(cost)

  # Importiere die Daten.
  (all_xs, all_ys) = get_data(datapoint_size)

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
  print("alpha:           %f" % curr_alpha)
  print("beta_purchases:  %f" % curr_beta[0])
  print("beta_age:        %f" % curr_beta[1])
  print("cost:            %f" % curr_cost)
  print("")
  print("time elapsed: %f sec" % (end_time - start_time))

# Führe die main-Funktion aus.
if __name__ == "__main__":
  main(sys.argv)
