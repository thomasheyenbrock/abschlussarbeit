-- Erstelle (oder ersetze falls vorhanden) die Prozedur für einfache lineare Regression.
CREATE OR REPLACE FUNCTION simple_linear_regression(number_datapoints INTEGER)
RETURNS TABLE (
  variable VARCHAR(50),
  value NUMERIC(65, 30)
) AS $$
BEGIN

-- Erstelle eine Tabelle für die zu verwendenden Datenpunkte.
DROP TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
  purchases INTEGER,
  money INTEGER
);

-- Füge die gewünschte Anzahl der Datenpunkte in die temporäre Tabelle ein.
INSERT INTO datapoints
SELECT purchases, money
FROM sample
LIMIT number_datapoints;

RETURN QUERY
WITH
  -- Berechne die Mittelwerte der abhängigen und unabhängigen Variable.
  means AS (
    SELECT
      AVG(purchases) AS mean_purchases,
      AVG(money) AS mean_money
    FROM datapoints
  ),
  -- Berechne die Summen im Nenner und Zähler der Formel für beta.
  sums AS (
    SELECT
      SUM((purchases - mean_purchases) * (money - mean_money)) AS nominator,
      SUM(POWER(purchases - mean_purchases, 2)) AS denominator
    FROM datapoints, means
  ),
  -- Berechne beta.
  beta AS (
    SELECT
      'beta'::VARCHAR(50) AS variable,
      nominator / denominator AS value
    FROM sums
  ),
  -- Berechne alpha.
  alpha AS (
    SELECT
      'alpha'::VARCHAR(50) AS variable,
      mean_money - beta.value * mean_purchases AS value
    FROM means, beta
  )
-- Gib eine Tabelle mit Parametername und zugehörigem Wert zurück.
SELECT *
FROM alpha
UNION
SELECT *
FROM beta;

-- Lösche die temporäre Tabelle mit den Datenpunkten wieder.
DROP TABLE IF EXISTS datapoints;

END;
$$ LANGUAGE plpgsql;
