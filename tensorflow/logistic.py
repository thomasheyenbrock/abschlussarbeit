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

x_train = np.asarray(x_train[:10])
y_train = np.asarray(y_train[:10])

# x_train = np.asarray([1,2,3,4,5])
# y_train = np.asarray([0,0,1,0,1])

min_x = min(x_train)
max_x = max(x_train)

print(x_train)
print(y_train)

# Step 2: create placeholders for input X and label Y
X = tf.placeholder(tf.float32, name="X")
Y = tf.placeholder(tf.float32, name="Y")

# Step 3: create weight and bias, initialized to 0
w = tf.Variable(0.0, name="weights")
b = tf.Variable(0.0, name="bias")

# Step 4: construct model to predict Y from X
Y_predicted = 1 / (1 + tf.exp(- X * w - b))

# Step 5: use the negative likelihood as loss function
loss = - tf.reduce_prod(Y * Y_predicted + (1 - Y) * (1 - Y_predicted))

# Step 6: using gradient descent with learning rate of 0.1 to minimize loss
optimizer = tf.train.GradientDescentOptimizer(learning_rate=0.1).minimize(loss)

with tf.Session() as sess:
    # Step 7: initialize the necessary variables, in this case, w and b
    sess.run(tf.global_variables_initializer())

    # Step 8: train the model
    for i in range(10000):
        p = sess.run([optimizer, w, b, loss], feed_dict={X: x_train, Y: y_train})
        if i % 100 == 0:
            print("%s: %s"%(i, p))

    # Step 9: output the values of w and b
    w_value, b_value = sess.run([w, b])

    print(w_value, b_value)

x_plot = np.arange(1000) / 1000 * (max_x - min_x) + min_x
plt.plot(x_train, y_train, 'ro', label='Original data')
plt.plot(x_plot, 1 / (1 + np.exp(-w_value * x_plot - b_value)), label='Fitted line')
plt.legend()
plt.show()
