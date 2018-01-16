from time import time
from subprocess import call
import os
import sys
import csv
import json

def print_progessbar(iterations, progress):
  sys.stdout.write("\033[100D")
  for i in range(progress * 50 // iterations): sys.stdout.write("#")
  for i in range(50 - (progress * 50 // iterations)): sys.stdout.write(".")
  sys.stdout.write("  ||  %i%% / 100%%" % (progress * 100 // iterations))
  sys.stdout.flush()

def benchmark(type_regression, language, command, set_number_datapoints, file, iterations):
  print("Evaluating %s in %s..." % (type_regression, language))
  for number_datapoints in set_number_datapoints:
    print("Use %s datapoints:" % (number_datapoints))
    logfile = open("logs/%s-%s-%i.txt" % (language, type_regression.replace(" ", "-"), number_datapoints), "a")
    if command.count("%") == 2:
      exec_command = command % (number_datapoints, 8 / number_datapoints)
    else:
      exec_command = command % number_datapoints
    for i in range(iterations):
      print_progessbar(iterations, i)
      start_time = time()
      call(exec_command, stdout = logfile, stderr = logfile, shell = True)
      end_time = time()
      file.write("%s,%s,%i,%s\n" % (
        language,
        type_regression,
        number_datapoints,
        (end_time - start_time)
      ))
    logfile.close()
    print_progessbar(iterations, iterations)
    print("")
  return

def main(argv):
  iterations = 100
  set_number_datapoints = [10, 100, 1000, 10000, 100000]
  run_r = False
  run_tensorflow = False
  run_mysql = False
  run_postgresql = False
  run_simple_linear_regression = False
  run_multiple_linear_regression = False
  run_logistic_regression = False

  for arg in argv:
    if "--datapoints=" in arg: set_number_datapoints = [int(arg.split("=")[1])]
    if "--iterations=" in arg: iterations = int(arg.split("=")[1])
    if arg in ["--r", "-r"]: run_r = True
    if arg in ["--tensorflow", "-t"]: run_tensorflow = True
    if arg in ["--mysql", "-m"]: run_mysql = True
    if arg in ["--postgresql", "-p"]: run_postgresql = True
    if arg in ["--simple-linear", "-slr"]: run_simple_linear_regression = True
    if arg in ["--multiple-linear", "-mlr"]: run_multiple_linear_regression = True
    if arg in ["--logistic", "-lr"]: run_logistic_regression = True

  if not ((
    run_r or
    run_tensorflow or
    run_mysql or
    run_postgresql
  ) and (
    run_simple_linear_regression or
    run_multiple_linear_regression or
    run_logistic_regression
  )):
    run_r = True
    run_tensorflow = True
    run_mysql = True
    run_postgresql = True
    run_simple_linear_regression = True
    run_multiple_linear_regression = True
    run_logistic_regression = True

  file = open("benchmarks-%i.csv" % (time()), "w")
  file.write("language,type,datapoints,time\n")

  if run_r and run_simple_linear_regression:
    benchmark(
      "simple linear regression",
      "r",
      "Rscript r/simpleLinearRegression.R %i -",
      set_number_datapoints,
      file,
      iterations
    )
  if run_r and run_multiple_linear_regression:
    benchmark(
      "multiple linear regression",
      "r",
      "Rscript r/multipleLinearRegression.R %i -",
      set_number_datapoints,
      file,
      iterations
    )
  if run_r and run_logistic_regression:
    benchmark(
      "logistic regression",
      "r",
      "Rscript r/logisticRegression.R %i -",
      set_number_datapoints,
      file,
      iterations
    )
  if run_tensorflow and run_simple_linear_regression:
    benchmark(
      "simple linear regression",
      "tensorflow",
      "python3 tensorflow/simpleLinearRegression.py %i -",
      set_number_datapoints,
      file,
      iterations
    )
  if run_tensorflow and run_multiple_linear_regression:
    benchmark(
      "multiple linear regression",
      "tensorflow",
      "python3 tensorflow/multipleLinearRegression.py %i -",
      set_number_datapoints,
      file,
      iterations
    )
  if run_tensorflow and run_logistic_regression:
    benchmark(
      "logistic regression",
      "tensorflow",
      "python3 tensorflow/logisticRegression.py %i -",
      set_number_datapoints,
      file,
      iterations
    )
  if run_mysql and run_simple_linear_regression:
    benchmark(
      "simple linear regression",
      "mysql",
      "echo \"CALL regression.simple_linear_regression(%i)\" | " + "mysql -u %s -p%s" % (
        json.loads(os.environ["MYSQL_CONFIG"])["user"],
        json.loads(os.environ["MYSQL_CONFIG"])["password"]
      ),
      set_number_datapoints,
      file,
      iterations
    )
  if run_mysql and run_multiple_linear_regression:
    benchmark(
      "multiple linear regression",
      "mysql",
      "echo \"CALL regression.multiple_linear_regression(%i)\" | " + "mysql -u %s -p%s" % (
        json.loads(os.environ["MYSQL_CONFIG"])["user"],
        json.loads(os.environ["MYSQL_CONFIG"])["password"]
      ),
      set_number_datapoints,
      file,
      iterations
    )
  if run_mysql and run_logistic_regression:
    benchmark(
      "logistic regression",
      "mysql",
      "echo \"CALL regression.logistic_regression(%i, 1000, %f)\" | " + "mysql -u %s -p%s" % (
        json.loads(os.environ["MYSQL_CONFIG"])["user"],
        json.loads(os.environ["MYSQL_CONFIG"])["password"]
      ),
      set_number_datapoints,
      file,
      iterations
    )
  if run_postgresql and run_simple_linear_regression:
    benchmark(
      "simple linear regression",
      "postgresql",
      "echo \"SELECT simple_linear_regression(%i)\" | psql regression",
      set_number_datapoints,
      file,
      iterations
    )
  if run_postgresql and run_multiple_linear_regression:
    benchmark(
      "multiple linear regression",
      "postgresql",
      "echo \"SELECT multiple_linear_regression(%i)\" | psql regression",
      set_number_datapoints,
      file,
      iterations
    )
  if run_postgresql and run_logistic_regression:
    benchmark(
      "logistic regression",
      "postgresql",
      "echo \"SELECT logistic_regression(%i, 1000, %f)\" | psql regression",
      set_number_datapoints,
      file,
      iterations
    )

  file.close()
  return

if __name__ == "__main__":
  main(sys.argv)
