import sys
import random
import math

def outputCsv(data):
  output = ["%s,%s,%s,%s" % (
    "age",
    "purchases",
    "money",
    "premium"
  )]

  for datapoint in data:
    output.append("%s,%s,%s,%a" % (
      datapoint["age"],
      datapoint["purchases"],
      datapoint["money"],
      datapoint["premium"]
    ))

  f = open("sample.csv", "w")
  f.write("\n".join(output))

  return


def outputSql(data):
  output = [
    "DROP TABLE IF EXISTS sample;",
    "",
    "CREATE TABLE sample (",
    "  age INTEGER,",
    "  purchases INTEGER,",
    "  money INTEGER,",
    "  premium INTEGER",
    ");",
    "",
    "INSERT INTO sample (%s,%s,%s,%s) VALUES" % (
      "age",
      "purchases",
      "money",
      "premium"
    )
  ]

  for datapoint in data:
    output.append("(%s,%s,%s,%s)," % (
      datapoint["age"],
      datapoint["purchases"],
      datapoint["money"],
      datapoint["premium"]
    ))

  output[-1] = output[-1][:-1] + ";"
  f = open("sample.sql", "w")
  f.write("\n".join(output))

  return


def main(argv):
  if len(argv) < 2:
    print("Please provide number of datapoints that shall be generated.")
    return

  data = []

  for i in range(0, int(argv[1])):
    age = int(max(random.normalvariate(25, 10) + 10, 18))
    purchases = int(max(random.normalvariate(10, 10), 1))
    money = int(max(purchases * 25 + random.normalvariate(0, (math.log(purchases) + 1) * 12), 0.01) * 100)
    if random.uniform(0, 1) > math.exp(0.2 * purchases - 2) / (1 + math.exp(0.2 * purchases - 2)):
      premium = 0
    else:
      premium = 1

    data.append({
      "age": age,
      "purchases": purchases,
      "money": money,
      "premium": premium
    })

  outputCsv(data)
  outputSql(data)
  return

if __name__ == "__main__":
  main(sys.argv)
