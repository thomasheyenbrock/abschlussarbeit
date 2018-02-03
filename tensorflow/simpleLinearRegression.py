import numpy as np
import tensorflow as tf
import os.path as p
import csv
import sys
import matplotlib.pyplot as plt
from time import time

def get_data(n_samples):
  filename = p.abspath(p.join(p.dirname(p.realpath(__file__)), "..", "data", "sample.csv"))
  csvfile = open(filename, newline="")
  x = []
  x_plot = []
  y = []

  csvreader = csv.reader(csvfile, delimiter=",", quotechar="|")
  for row in csvreader:
    if not row[0] == "age":
      x.append([int(row[1])])
      x_plot.append(int(row[1]))
      y.append(int(row[2]))

  return (np.array(x[:n_samples]), x_plot[:n_samples], np.transpose([y[:n_samples]]))

def main(argv):
  datapoint_size = 1000
  plot = True
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

  start_time = time()

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

  x = tf.placeholder(tf.float32, [None, 1])
  y = tf.placeholder(tf.float32, [None, 1])
  alpha = tf.Variable(tf.zeros([1]))
  beta = tf.Variable(tf.zeros([1, 1]))
  y_calc = tf.matmul(x, beta) + alpha

  cost = tf.reduce_mean(tf.square(y - y_calc))
  train_step = tf.train.GradientDescentOptimizer(learn_rate).minimize(cost)

  (all_xs, plot_xs, all_ys) = get_data(datapoint_size)

  sess = tf.Session()
  init = tf.global_variables_initializer()
  sess.run(init)

  for i in range(steps):
    feed = { x: all_xs, y: all_ys }
    sess.run(train_step, feed_dict=feed)

  (curr_alpha, curr_beta, curr_cost) = sess.run([alpha, beta, cost], feed_dict=feed)

  end_time = time()

  print("alpha:  %f" % curr_alpha)
  print("beta:   %f" % curr_beta)
  print("cost:   %f" % curr_cost)
  print("")
  print("time elapsed:  %f sec" % (end_time - start_time))

  if plot:
    plt.plot(plot_xs, all_ys, "ro", label="Original data")
    plt.plot(plot_xs, curr_beta * all_xs + curr_alpha , label="Fitted line")
    plt.legend()
    plt.show()

if __name__ == "__main__":
  main(sys.argv)
