import numpy as np
import tensorflow as tf
import os.path as p
import csv
import sys
import matplotlib.pyplot as plt

def get_data(n_samples):
    filename = p.abspath(p.join(p.dirname(p.realpath(__file__)), '..', 'data', 'sample.csv'))
    csvfile = open(filename, newline='')
    x = []
    x_plot = []
    y = []

    csvreader = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in csvreader:
        if not row[0] == "age":
            x.append([int(row[1])])
            x_plot.append(int(row[1]))
            y.append(int(row[2]))

    return (x[:n_samples], x_plot[:n_samples], y[:n_samples])

def main(argv):
    if len(argv) < 2:
        datapoint_size = 100000
    else:
        try:
            datapoint_size = int(argv[1])
        except Exception:
            print("ERROR: Argument has to be a integer greater than 2.")
            return
        if datapoint_size < 2:
            print("ERROR: Argument has to be a integer greater than 2.")
            return

    batch_size = datapoint_size
    steps = 1000
    learn_rate = 0.0005

    x = tf.placeholder(tf.float32, [None, 1])
    W = tf.Variable(tf.zeros([1, 1]))
    b = tf.Variable(tf.zeros([1]))
    y = tf.matmul(x, W) + b
    y_ = tf.placeholder(tf.float32, [None, 1])

    cost = tf.reduce_mean(tf.square(y_ - y))
    train_step = tf.train.GradientDescentOptimizer(learn_rate).minimize(cost)

    (all_xs, plot_xs, all_ys) = get_data(datapoint_size)

    all_xs = np.array(all_xs)
    all_ys = np.transpose([all_ys])

    sess = tf.Session()
    init = tf.global_variables_initializer()
    sess.run(init)

    for i in range(steps):
        if datapoint_size == batch_size:
            batch_start_idx = 0
        elif datapoint_size < batch_size:
            raise ValueError("datapoint_size: %d, must be greater than batch_size: %d" % (datapoint_size, batch_size))
        else:
            batch_start_idx = (i * batch_size) % (datapoint_size - batch_size)
        batch_end_idx = batch_start_idx + batch_size
        batch_xs = all_xs[batch_start_idx:batch_end_idx]
        batch_ys = all_ys[batch_start_idx:batch_end_idx]
        xs = np.array(batch_xs)
        ys = np.array(batch_ys)
        feed = { x: xs, y_: ys }
        sess.run(train_step, feed_dict=feed)

    (curr_W, curr_b, curr_cost) = sess.run([W, b, cost], feed_dict=feed)

    print("W: %f" % curr_W)
    print("b: %f" % curr_b)
    print("cost: %f" % curr_cost)

    # plot
    plt.plot(plot_xs, all_ys, 'ro', label='Original data')
    plt.plot(plot_xs, curr_W * all_xs + curr_b , label='Fitted line')
    plt.legend()
    plt.show()

if __name__ == "__main__":
    main(sys.argv)
