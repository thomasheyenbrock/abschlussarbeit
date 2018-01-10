# Abschlussarbeit "Effizienze statistische Methoden in Datenbanksystemen"

Diese Arbeit behandelt Grundlagen der Regressionsanalyse und demonstriert die Anwendung in folgenden Programmiersprachen bzw. Software-Bibliotheken:
* [R-Projekt](https://www.r-project.org/)
* [TensorFlow](http://tensorflow.org/)
* [MySQL](https://www.mysql.com/de/)
* [PostgreSQL](https://www.postgresql.org/)

Dieses Repository umfasst sowohl die eigentliche Arbeit (zu finden im Ordner [latex](https://github.com/thomasheyenbrock/abschlussarbeit/tree/master/latex)), also auch die dafür verwendeten Skripte. Damit die Skripte funktionieren, müssen die genannten Sprachen lokal funktionsfähig sein. Für TensorFlow wird die Python-API mit Python-Version 3 verwendet. Außerdem muss die Python-Bibliothek [`numpy`](http://www.numpy.org/) installiert sein.

## Daten

Im Ordner [data](https://github.com/thomasheyenbrock/abschlussarbeit/tree/master/data) findet man drei Dateien. Die Datei [sample_data.py](https://github.com/thomasheyenbrock/abschlussarbeit/blob/master/data/sample_data.py) ist ein Python-Skript, mit der die anderen beiden Dateien erzeugt wurden.

Die anderen beiden Dateien enthalten die (identischen) Beispieldaten, mit denen die restlichen Skripte arbeiten, einmal als csv-Datei und einmal als sql-Datei. Letztere enthält eine Abfrage, die den gesamten Datensatz in eine Tabelle `sample` einfügt.

Die Skripte für R und TensorFlow lesen die csv-Datei bei Ausführung ein. Die SQL-Skripte laden die Daten aus der `sample`-Tabelle, die zuvor manuell erzeugt werden muss.

Für MySQL kann die Tabelle wiefolgt über das Terminal erzeugt werden:
```
cat data/sample.sql | mysql -u <username> -p<password> <database-name>
```
Für PostgreSQL führt man folgenden Befehl aus:
```
cat data/sample.sql | psql <database-name>
```
Dabei sind `username`, `password` und `database-name` entsprechend zu ersetzen.

# R-Projekt

Es stehen drei Sripte zur Verfügung:
* [`simpleLinearRegression.R`](https://github.com/thomasheyenbrock/abschlussarbeit/blob/master/r/simpleLinearRegression.R)
* [`multipleLinearRegression.R`](https://github.com/thomasheyenbrock/abschlussarbeit/blob/master/r/multipleLinearRegression.R)
* [`logisticRegression.R`](https://github.com/thomasheyenbrock/abschlussarbeit/blob/master/r/logisticRegression.R)

Eines dieser Skripte kann wiefolgt ausgeführt werden:
```
Rscript r/simpleLinearRegression.R <anzahl-datenpunkte>
```
Wird keine Anzahl angegeben, werden alle vorhandenen Datenpunkte verwendet. Das Ergebnis wird im Terminal gedruckt.

Bei `simpleLinearRegression.R` und `logisticRegression.R` wird zusätzlich ein Plot erstellt, welcher in einer pdf-Datei abgespeichert wird. Hängt man bei Ausführung ein `-` an, wird kein Plot erstellt.

# TensorFlow

Es stehen drei Sripte zur Verfügung:
* [`simpleLinearRegression.py`](https://github.com/thomasheyenbrock/abschlussarbeit/blob/master/tensorflow/simpleLinearRegression.py)
* [`multipleLinearRegression.py`](https://github.com/thomasheyenbrock/abschlussarbeit/blob/master/tensorflow/multipleLinearRegression.py)
* [`logisticRegression.py`](https://github.com/thomasheyenbrock/abschlussarbeit/blob/master/tensorfow/logisticRegression.py)

Eines dieser Skripte kann wiefolgt ausgeführt werden:
```
python3 tensorflow/simpleLinearRegression.py <anzahl-datenpunkte>
```
Wird keine Anzahl angegeben, werden alle vorhandenen Datenpunkte verwendet. Das Ergebnis wird im Terminal gedruckt.

Bei `simpleLinearRegression.py` und `logisticRegression.py` wird zusätzlich ein Plot erstellt und in einem separaten Fenster geöffnet. Hängt man bei Ausführung ein `-` an, wird kein Plot erstellt.

# MySQL und PostgreSQL

Es stehen jeweils drei Skripte zur Verfügung:
* `simpleLinearRegression.sql`
* `multipleLinearRegression.sql`
* `logisticRegression.sql`

Jedes Skript erzeugt eine oder mehrer Prozeduren für den jeweiligen Typ von Regression. Man fügt ein solches Skript wiefolgt für MySQL aus:
```
cat mysql/simpleLinearRegression.sql | mysql -u <username> -p<password> <database-name>
```
Für PostgreSQL lautet der Befehl:
```
cat postgresql/simpleLinearRegression.sql | psql <database-name>
```
Die erzeugten Prozeduren heißen:
* `simple_linear_regression(IN number_datapoints INTEGER)`
* `multiple_linear_regression(IN number_datapoints INTEGER)`
* `logistic_regression(IN number_datapoints INTEGER, IN rounds INTEGER)`

`number_datapoints` ist wieder der Parameter für die Anzahl der Datepunkte. Die Prozedur für logistische Regression arbeitet iterativ, deshalb muss man hier außerdem die Anzahl der Interation `rounds` spezifizieren. Eine gute Wahl liegt in der Regel zwischen `100` und `1000`, je nach gewünschter Präzision.

Eine MySQL-Prozedur führt man wiefolgt über das Terminal aus:
```
echo "CALL simple_linear_regression(1000)" | mysql -u <username> -p<password> <database-name>
```
Eine PostgreSQL-Funktion führt man so aus:
```
echo "SELECT simple_linear_regression(1000)" | psql <database-name>
```
