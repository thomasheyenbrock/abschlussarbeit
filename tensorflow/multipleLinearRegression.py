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

    return (np.array(x[:n_samples]), np.transpose([y[:n_samples]]))

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
    y = tf.placeholder(tf.float32, [None, 1])
    alpha = tf.Variable(tf.zeros([1]))
    betas = tf.Variable(tf.zeros([2, 1]))
    y_calc = tf.matmul(x, betas) + alpha

    cost = tf.reduce_mean(tf.square(y - y_calc))
    train_step = tf.train.GradientDescentOptimizer(learn_rate).minimize(cost)

    (all_xs, all_ys) = get_data(datapoint_size)

    sess = tf.Session()
    init = tf.global_variables_initializer()
    sess.run(init)

    for i in range(steps):
        feed = { x: all_xs, y: all_ys }
        sess.run(train_step, feed_dict=feed)

    (curr_alpha, curr_betas, curr_cost) = sess.run([alpha, betas, cost], feed_dict=feed)

    print("alpha:           %f" % curr_alpha)
    print("beta_purchases:  %f" % curr_betas[0])
    print("beta_age:        %f" % curr_betas[1])
    print("cost:            %f" % curr_cost)

if __name__ == "__main__":
    main(sys.argv)
