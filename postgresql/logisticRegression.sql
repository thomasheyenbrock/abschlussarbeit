-- Erstelle (oder ersetzte falls vorhanden) eine Prozedur zur Berechnung der Werte der logistischen Funktion.
CREATE OR REPLACE FUNCTION lr_calculate_logit()
RETURNS void AS $$
BEGIN

DELETE FROM lr_logits;

WITH
  -- Bestimme den alten und neuen Wert von alpha.
  alpha_old AS (
    SELECT old
    FROM lr_parameters
    WHERE variable = 'alpha'
  ),
  alpha_new AS (
    SELECT new
    FROM lr_parameters
    WHERE variable = 'alpha'
  )
-- Berechne die Werte der logistischen Funktion für alle Datenpunkte.
INSERT INTO lr_logits
  SELECT
    d.id,
    1 / (1 + EXP(- SUM(d.value * p.old) - (SELECT old FROM alpha_old))) AS old,
    1 / (1 + EXP(- SUM(d.value * p.new) - (SELECT new FROM alpha_new))) AS new
  FROM lr_datapoints d
  JOIN lr_parameters p ON p.variable = d.variable
  GROUP BY d.id;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erstelle (oder ersetze falls vorhanden) eine Prozedur zur Berechnung des Gradienten.
CREATE OR REPLACE FUNCTION lr_calculate_gradient()
RETURNS void AS $$
BEGIN

DELETE FROM lr_gradient;

-- Berechne die partielle Ableitung nach alpha.
INSERT INTO lr_gradient
SELECT 'alpha' AS variable, SUM(bv.value - l.old) AS value
FROM lr_logits l
JOIN lr_binary_values bv ON bv.id = l.id;

-- Berechne die partielle Ableitung nach allen beta-Parametern.
INSERT INTO lr_gradient
SELECT d.variable, SUM(d.value * (bv.value - l.old)) AS value
FROM lr_logits l
JOIN lr_binary_values bv ON bv.id = l.id
JOIN lr_datapoints d ON d.id = l.id
GROUP BY d.variable;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erzeuge (oder ersetze falls vorhanden) eine Prozedur zur Berechnung der neuen Parameter abhängig von der aktuellen Schrittweite.
CREATE OR REPLACE FUNCTION lr_calculate_new_parameters(step NUMERIC(65, 30))
RETURNS void AS $$
BEGIN

UPDATE lr_parameters
SET new = old + step * lr_gradient.value
FROM lr_gradient
WHERE lr_gradient.variable = lr_parameters.variable;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erstelle die Prozedur für logistische Regression.
CREATE OR REPLACE FUNCTION logistic_regression(number_datapoints INTEGER, rounds INTEGER, step NUMERIC(65, 30))
RETURNS TABLE (
  variable VARCHAR(50),
  value NUMERIC(65, 30)
) AS $$
DECLARE
  counter INTEGER;
BEGIN

-- Erstelle eine Relation für die Werte der unabhängigen Variablen.
DROP TABLE IF EXISTS lr_datapoints;
CREATE TEMPORARY TABLE lr_datapoints (
  id INTEGER,
  variable VARCHAR(50),
  value NUMERIC(65, 30)
);

-- Füge die linear transformierten Werte der unabhängigen Variablen in die Relation datapoints ein.
INSERT INTO lr_datapoints
SELECT
  row_number() OVER () AS id,
  'beta_money' AS variable,
  (money - (
    SELECT MIN(money) FROM sample
  ))::NUMERIC(65, 30) / ((
    SELECT MAX(money) FROM sample
  ) - (
    SELECT MIN(money) FROM sample
  ))::NUMERIC(65, 30) AS value
FROM sample
LIMIT number_datapoints;

-- Erstelle eine Relation für die (binären) Werte der abhängigen Variablen.
DROP TABLE IF EXISTS lr_binary_values;
CREATE TEMPORARY TABLE lr_binary_values (
  id INTEGER,
  value INTEGER
);

-- Füge die Werte der abhängingen Variable ein.
INSERT INTO lr_binary_values
SELECT
  row_number() OVER () AS id,
  premium AS value
FROM sample
LIMIT number_datapoints;

-- Erstelle eine Relation für die alten und neuen Parameterwerte.
DROP TABLE IF EXISTS lr_parameters;
CREATE TEMPORARY TABLE lr_parameters (
  variable VARCHAR(50),
  old NUMERIC(65, 30),
  new NUMERIC(65, 30)
);

-- Füge die Initialwerte der Parameter ein.
INSERT INTO lr_parameters VALUES
  ('alpha', 0, 0),
  ('beta_money', 0, 0);

-- Erstelle eine Relation für die Werte der logistischen Funktion für alle Datenpunkte.
DROP TABLE IF EXISTS lr_logits;
CREATE TEMPORARY TABLE lr_logits (
  id INTEGER,
  old NUMERIC(65, 30),
  new NUMERIC(65, 30)
);

-- Befülle die Relation für die Werte der logistischen Funktion.
PERFORM lr_calculate_logit();

-- Erstelle eine Relation für den Gradienten.
DROP TABLE IF EXISTS lr_gradient;
CREATE TEMPORARY TABLE lr_gradient (
  variable VARCHAR(50),
  value NUMERIC(65, 30)
);

-- Iteriere über die Anzahl der gewünschten Iterationen.
counter := 0;
WHILE counter < rounds AND step > 0.000000000000000000000000000001 LOOP

  -- Berechne den Gradienten und die neuen Parameter mit der aktuellen Schrittweite.
  PERFORM lr_calculate_gradient();
  PERFORM lr_calculate_new_parameters(step);
  PERFORM lr_calculate_logit();

  -- Verringere die Schrittweite solange, bis die neuen Parameter ein besseres Ergebnis liefern als die alten.
  WHILE NOT (
    SELECT
      SUM(LOG(bv.value * l.new + (1 - bv.value) * (1 - l.new))) >
      SUM(LOG(bv.value * l.old + (1 - bv.value) * (1 - l.old)))
    FROM lr_logits l
    JOIN lr_binary_values bv ON bv.id = l.id
  ) AND step > 0.000000000000000000000000000001 LOOP

    step := step / 2;
    PERFORM lr_calculate_new_parameters(step);
    PERFORM lr_calculate_logit();

  END LOOP;

  -- Ersetze die alten Werte durch die neuen Werte.
  UPDATE lr_parameters
  SET old = new;

  UPDATE lr_logits
  SET old = new;

  counter := counter + 1;

END LOOP;

-- Transformiere die Parameter linear, um den originalen Daten zu entsprechen.
UPDATE lr_parameters
SET old = old / ((SELECT MAX(money) FROM sample) - (SELECT MIN(money) FROM sample))
WHERE lr_parameters.variable = 'beta_money';

UPDATE lr_parameters
SET old = old - (SELECT old FROM lr_parameters p2 WHERE p2.variable = 'beta_money') * (SELECT MIN(money) FROM sample)
WHERE lr_parameters.variable = 'alpha';

-- Gib eine Relation mit Parametername und zugehörigem Wert zurück.
RETURN QUERY
SELECT lr_parameters.variable::VARCHAR(50), old AS value
FROM lr_parameters;

-- Lösche die Relationen wieder.
DROP TABLE IF EXISTS lr_datapoints;
DROP TABLE IF EXISTS lr_binary_values;
DROP TABLE IF EXISTS lr_parameters;
DROP TABLE IF EXISTS lr_logits;
DROP TABLE IF EXISTS lr_gradient;

END;
$$ LANGUAGE plpgsql;
