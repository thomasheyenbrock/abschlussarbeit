-- Erstelle (oder ersetzte falls vorhanden) eine Prozedur zur Berechnung der Werte der logistischen Funktion.
CREATE OR REPLACE FUNCTION calculate_logit()
RETURNS void AS $$
BEGIN

DELETE FROM logits;

WITH
  -- Bestimme den alten und neuen Wert von alpha.
  alpha_old AS (
    SELECT old
    FROM parameters
    WHERE variable = 'alpha'
  ),
  alpha_new AS (
    SELECT new
    FROM parameters
    WHERE variable = 'alpha'
  )
-- Berechne die Werte der logistischen Funktion für alle Datenpunkte.
INSERT INTO logits
  SELECT
    d.id,
    1 / (1 + EXP(- SUM(d.value * p.old) - (SELECT old FROM alpha_old))) AS old,
    1 / (1 + EXP(- SUM(d.value * p.new) - (SELECT new FROM alpha_new))) AS new
  FROM datapoints d
  JOIN parameters p ON p.variable = d.variable
  GROUP BY d.id;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erstelle (oder ersetze falls vorhanden) eine Prozedur zur Berechnung des Gradienten.
CREATE OR REPLACE FUNCTION calculate_gradient()
RETURNS void AS $$
BEGIN

DELETE FROM gradient;

-- Berechne die partielle Ableitung nach alpha.
INSERT INTO gradient
SELECT 'alpha' AS variable, SUM(bv.value - l.old) AS value
FROM logits l
JOIN binary_values bv ON bv.id = l.id;

-- Berechne die partielle Ableitung nach allen beta-Parametern.
INSERT INTO gradient
SELECT d.variable, SUM(d.value * (bv.value - l.old)) AS value
FROM logits l
JOIN binary_values bv ON bv.id = l.id
JOIN datapoints d ON d.id = l.id
GROUP BY d.variable;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erzeuge (oder ersetze falls vorhanden) eine Prozedur zur Berechnung der neuen Parameter abhängig von der aktuellen Schrittweite.
CREATE OR REPLACE FUNCTION calculate_new_parameters(step NUMERIC(65, 30))
RETURNS void AS $$
BEGIN

UPDATE parameters
SET new = old + step * gradient.value
FROM gradient
WHERE gradient.variable = parameters.variable;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erzeuge (oder ersetze falls vorhanden) eine Prozedur, um herauszufinden, ob die neuen Parameterwerte besser sind als die alten.
CREATE OR REPLACE FUNCTION are_new_parameters_better()
RETURNS BOOLEAN AS $$
DECLARE
  better BOOLEAN;
BEGIN

-- Berechne und vergleiche die Werte der Likelihoodfunktion für die alten und neuen Parameterwerte.
SELECT
  SUM(LOG(bv.value * l.new + (1 - bv.value) * (1 - l.new))) >
  SUM(LOG(bv.value * l.old + (1 - bv.value) * (1 - l.old))) INTO better
FROM logits l
JOIN binary_values bv ON bv.id = l.id;

RETURN better;

END;
$$ LANGUAGE plpgsql;

-- Erstelle die Prozedur für logistische Regression.
CREATE OR REPLACE FUNCTION logistic_regression(number_datapoints INTEGER, rounds INTEGER, step NUMERIC(65, 30))
RETURNS TABLE (
  variable VARCHAR(50),
  value NUMERIC(65, 30)
) AS $$
DECLARE
  better BOOLEAN;
  counter INTEGER;
BEGIN

-- Erstelle eine Relation für die Werte der unabhängigen Variablen.
DROP TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
  id INTEGER,
  variable VARCHAR(50),
  value NUMERIC(65, 30)
);

-- Füge die linear transformierten Werte der unabhängigen Variablen in die Relation datapoints ein.
INSERT INTO datapoints
SELECT
  row_number() OVER () AS id,
  'beta_money' AS variable,
  (money - (
    SELECT MIN(money) FROM sample
  ))::NUMERIC / ((
    SELECT MAX(money) FROM sample
  ) - (
    SELECT MIN(money) FROM sample
  ))::NUMERIC AS value
FROM sample
LIMIT number_datapoints;

-- Erstelle eine Relation für die (binären) Werte der abhängigen Variablen.
DROP TABLE IF EXISTS binary_values;
CREATE TEMPORARY TABLE binary_values (
  id INTEGER,
  value INTEGER
);

-- Füge die Werte der abhängingen Variable ein.
INSERT INTO binary_values
SELECT
  row_number() OVER () AS id,
  premium AS value
FROM sample
LIMIT number_datapoints;

-- Erstelle eine Relation für die alten und neuen Parameterwerte.
DROP TABLE IF EXISTS parameters;
CREATE TEMPORARY TABLE parameters (
  variable VARCHAR(50),
  old NUMERIC(65, 30),
  new NUMERIC(65, 30)
);

-- Füge die Initialwerte der Parameter ein.
INSERT INTO parameters VALUES
  ('alpha', 0, 0),
  ('beta_money', 0, 0);

-- Erstelle eine Relation für die Werte der logistischen Funktion für alle Datenpunkte.
DROP TABLE IF EXISTS logits;
CREATE TEMPORARY TABLE logits (
  id INTEGER,
  old NUMERIC(65, 30),
  new NUMERIC(65, 30)
);

-- Befülle die Relation für die Werte der logistischen Funktion.
PERFORM calculate_logit();

-- Erstelle eine Relation für den Gradienten.
DROP TABLE IF EXISTS gradient;
CREATE TEMPORARY TABLE gradient (
  variable VARCHAR(50),
  value DECIMAL(65, 30)
);

-- Iteriere über die Anzahl der gewünschten Iterationen.
counter := 0;
WHILE counter < rounds AND step > 0.000000000000000000000000000001 LOOP

  -- Berechne den Gradienten und die neuen Parameter mit der aktuellen Schrittweite.
  PERFORM calculate_gradient();
  PERFORM calculate_new_parameters(step);
  PERFORM calculate_logit();
  better := are_new_parameters_better();

  -- Verringere die Schrittweite solange, bis die neuen Parameter ein besseres Ergebnis liefern als die alten.
  WHILE NOT better AND step > 0.000000000000000000000000000001 LOOP

    step := step / 2;
    PERFORM calculate_new_parameters(step);
    PERFORM calculate_logit();
    better := are_new_parameters_better();

  END LOOP;

  -- Ersetze die alten Werte durch die neuen Werte.
  UPDATE parameters
  SET old = new;

  UPDATE logits
  SET old = new;

  counter := counter + 1;

END LOOP;

-- Transformiere die Parameter linear, um den originalen Daten zu entsprechen.
UPDATE parameters
SET old = old / ((SELECT MAX(money) FROM sample) - (SELECT MIN(money) FROM sample))
WHERE parameters.variable = 'beta_money';

UPDATE parameters
SET old = old - (SELECT old FROM parameters p2 WHERE p2.variable = 'beta_money') * (SELECT MIN(money) FROM sample)
WHERE parameters.variable = 'alpha';

-- Gib eine Relation mit Parametername und zugehörigem Wert zurück.
RETURN QUERY
SELECT parameters.variable::VARCHAR(50), old AS value
FROM parameters;

-- Lösche die Relationen wieder.
DROP TABLE IF EXISTS datapoints;
DROP TABLE IF EXISTS binary_values;
DROP TABLE IF EXISTS parameters;
DROP TABLE IF EXISTS logits;
DROP TABLE IF EXISTS gradient;

END;
$$ LANGUAGE plpgsql;
