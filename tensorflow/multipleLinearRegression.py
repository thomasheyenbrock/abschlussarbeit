import numpy as np
import tensorflow as tf
import os.path as p
import csv
import sys

def get_data(n_samples):
    filename = p.abspath(p.join(p.dirname(p.realpath(__file__)), '..', 'data', 'sample.csv'))
    csvfile = open(filename, newline='')
    x = []
    y = []

    csvreader = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in csvreader:
        if not row[0] == "age":
            x.append([int(row[1]), int(row[0])])
            y.append(int(row[2]))

    return (x[:n_samples], y[:n_samples])

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

    x = tf.placeholder(tf.float32, [None, 2])
    W = tf.Variable(tf.zeros([2, 1]))
    b = tf.Variable(tf.zeros([1]))
    y = tf.matmul(x, W) + b
    y_ = tf.placeholder(tf.float32, [None, 1])

    cost = tf.reduce_mean(tf.square(y_ - y))
    train_step = tf.train.GradientDescentOptimizer(learn_rate).minimize(cost)

    (all_xs, all_ys) = get_data(datapoint_size)

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

    print("W: %s" % curr_W)
    print("b: %f" % curr_b)
    print("cost: %f" % curr_cost)

if __name__ == "__main__":
    main(sys.argv)
