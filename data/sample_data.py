import sys
import random
import math

def outputCsv(data):
    output = ["%s,%s,%s" % ("purchases", "money", "prime")]

    for datapoint in data:
        output.append("%s,%s,%a" % (datapoint["purchases"], datapoint["money"], datapoint["prime"]))

    f = open("sample.csv", "w")
    f.write("\n".join(output))

    return


def main(argv):
    if len(argv) < 2:
        print('Please provide number of datapoints that shall be generated.')
        return

    data = []

    for i in range(0, int(argv[1])):
        purchases = int(max(random.normalvariate(10, 10), 1))
        money = int(max(purchases * 25 + random.normalvariate(0, (math.log(purchases) + 1) * 12), 0.01) * 100)
        if random.uniform(0, 1) > math.exp(0.2 * purchases - 2) / (1 + math.exp(0.2 * purchases - 2)):
            prime = 0
        else:
            prime = 1

        data.append({
            "purchases": purchases,
            "money": money,
            "prime": prime
        })

    outputCsv(data)
    return

if __name__ == "__main__":
    main(sys.argv)
