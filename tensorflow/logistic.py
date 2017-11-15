import numpy as np
import tensorflow as tf
import os
import csv
import matplotlib.pyplot as plt

def get_data(n_samples):
    filename = os.path.abspath(os.path.join(os.path.dirname(os.path.realpath(__file__)), '..', 'data', 'sample.csv'))
    csvfile = open(filename, newline='')
    x = []
    y = []

    csvreader = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in csvreader:
        if not row[0] == "purchases":
            x.append(int(row[1]))
            y.append(int(row[2]))

    return (x[:n_samples], y[:n_samples])

# Step 1: read in data
(x_train, y_train) = get_data(5000)

x_train = np.asarray(x_train)
y_train = np.asarray(y_train)

min_x = min(x_train)
max_x = max(x_train)
x_train = (x_train - min_x) / (max_x - min_x)

print(x_train)
print(y_train)

# Step 2: create placeholders for input X (number of fire) and label Y (number of theft)
X = tf.placeholder(tf.float32, name="X")
Y = tf.placeholder(tf.float32, name="Y")

# Step 3: create weight and bias, initialized to 0
w = tf.Variable(0.0, name="weights")
b = tf.Variable(0.0, name="bias")

# Step 4: construct model to predict Y (number of theft) from the number of fire
Y_predicted = tf.exp(X * w + b) / (1 + tf.exp(X * w + b))

# Step 5: use the square error as the loss function
loss = tf.reduce_sum(tf.square(Y - Y_predicted, name="loss"))

# Step 6: using gradient descent with learning rate of 0.01 to minimize loss
optimizer = tf.train.GradientDescentOptimizer(learning_rate=0.01).minimize(loss)

with tf.Session() as sess:
    # Step 7: initialize the necessary variables, in this case, w and b
    sess.run(tf.global_variables_initializer())

    # Step 8: train the model
    for i in range(1000):
        p = sess.run([optimizer, w, b, loss], feed_dict={X: x_train, Y: y_train})
        if i % 100 == 0:
            print("%s: %s"%(i, p))

    # Step 9: output the values of w and b
    w_value, b_value = sess.run([w, b])

    w_value = w_value / (max_x - min_x)
    b_value = b_value - w_value * min_x

    print(w_value, b_value)

x_plot = np.arange(1000) / 1000 * (max_x - min_x) + min_x
x_train = x_train * (max_x - min_x) + min_x
plt.plot(x_train, y_train, 'ro', label='Original data')
plt.plot(x_plot, 1 / (1 + np.exp(-w_value * x_plot - b_value)), label='Fitted line')
plt.legend()
plt.show()
