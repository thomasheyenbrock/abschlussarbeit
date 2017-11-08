import sys
import tensorflow as tf
import csv
import os
import matplotlib.pyplot as plt

def get_data(n_samples):
    filename = os.path.abspath(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'data', 'sample.csv'))
    csvfile = open(filename, newline='')
    x = []
    y = []

    csvreader = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in csvreader:
        if not row[0] == "purchases":
            x.append(int(row[0]))
            y.append(int(row[1]))

    return (x[:n_samples], y[:n_samples])

def main(argv):
    if len(argv) < 2:
        n_samples = 5000
    else:
        try:
            n_samples = int(argv[1])
        except Exception:
            print("ERROR: Argument has to be a integer greater than 2.")
            return
        if n_samples < 2:
            print("ERROR: Argument has to be a integer greater than 2.")
            return

    # training data
    (x_train, y_train) = get_data(n_samples)

    # Model parameters
    W = tf.Variable([1], dtype=tf.float32)
    b = tf.Variable([0], dtype=tf.float32)
    # Model input and output
    x = tf.placeholder(tf.float32)
    linear_model = W * x + b
    y = tf.placeholder(tf.float32)

    # loss
    loss = tf.reduce_sum(tf.square(linear_model - y)) / (2 * n_samples) # sum of the squares
    # optimizer
    optimizer = tf.train.GradientDescentOptimizer(0.01)
    train = optimizer.minimize(loss)

    # training loop
    init = tf.global_variables_initializer()
    sess = tf.Session()
    sess.run(init) # reset values to wrong
    for i in range(1000):
        sess.run(train, {x: x_train, y: y_train})

    # evaluate training accuracy
    curr_W, curr_b, curr_loss = sess.run([W, b, loss], {x: x_train, y: y_train})
    print("W: %s b: %s loss: %s"%(curr_W, curr_b, curr_loss))

    # plot
    plt.plot(x_train, y_train, 'ro', label='Original data')
    plt.plot(x_train, curr_W * x_train + curr_b, label='Fitted line')
    plt.legend()
    plt.show()

if __name__ == "__main__":
    main(sys.argv)
