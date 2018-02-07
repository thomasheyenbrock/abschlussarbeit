-- Erstelle (oder ersetzte falls vorhanden) eine Prozedur zur Berechnung der Werte der linearen Funktion.
CREATE OR REPLACE FUNCTION slr_calculate_linears()
RETURNS void AS $$
BEGIN

DELETE FROM slr_linears;

WITH
  -- Bestimme den alten und neuen Wert von alpha.
  alpha_old AS (
    SELECT old
    FROM slr_parameters
    WHERE variable = 'alpha'
  ),
  alpha_new AS (
    SELECT new
    FROM slr_parameters
    WHERE variable = 'alpha'
  )
-- Berechne die lineare Funktion für alle Datenpunkte.
INSERT INTO slr_linears
  SELECT
    d.id,
    SUM(d.value * p.old) + (SELECT old FROM alpha_old) AS old,
    SUM(d.value * p.new) + (SELECT new FROM alpha_new) AS new
  FROM slr_datapoints d
  JOIN slr_parameters p ON p.variable = d.variable
  GROUP BY d.id;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erstelle (oder ersetze falls vorhanden) eine Prozedur zur Berechnung des Gradienten.
CREATE OR REPLACE FUNCTION slr_calculate_gradient()
RETURNS void AS $$
BEGIN

DELETE FROM slr_gradient;

-- Berechne die partielle Ableitung nach alpha.
INSERT INTO slr_gradient
SELECT 'alpha' AS variable, - 2 * SUM(bv.value - l.old) AS value
FROM slr_linears l
JOIN slr_binary_values bv ON bv.id = l.id;

-- Berechne die partielle Ableitung nach allen beta-Parametern.
INSERT INTO slr_gradient
SELECT d.variable, - 2 * SUM(d.value * (bv.value - l.old)) AS value
FROM slr_linears l
JOIN slr_binary_values bv ON bv.id = l.id
JOIN slr_datapoints d ON d.id = l.id
GROUP BY d.variable;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erzeuge (oder ersetze falls vorhanden) eine Prozedur zur Berechnung der neuen Parameter abhängig von der aktuellen Schrittweite.
CREATE OR REPLACE FUNCTION slr_calculate_new_parameters(step NUMERIC(65, 30))
RETURNS void AS $$
BEGIN

UPDATE slr_parameters
SET new = old - step * slr_gradient.value
FROM slr_gradient
WHERE slr_gradient.variable = slr_parameters.variable;

RETURN;

END;
$$ LANGUAGE plpgsql;

-- Erstelle (oder ersetze falls vorhanden) die Prozedur für lineare Regression mit Verwendung des Gradientenverfahrens.
CREATE OR REPLACE FUNCTION simple_linear_regression_gradient_descent(number_datapoints INTEGER, rounds INTEGER, step NUMERIC(65, 30))
RETURNS TABLE (
  variable VARCHAR(50),
  value NUMERIC(65, 30)
) AS $$
DECLARE
  counter INTEGER;
BEGIN

-- Erstelle eine Relation für die Werte der unabhängigen Variablen.
DROP TABLE IF EXISTS slr_datapoints;
CREATE TEMPORARY TABLE slr_datapoints (
  id INTEGER,
  variable VARCHAR(50),
  value NUMERIC(65, 30)
);

-- Füge die linear transformierten Werte der unabhängigen Variablen in die Relation datapoints ein.
INSERT INTO slr_datapoints
SELECT
  row_number() OVER () AS id,
  'beta_purchases' AS variable,
  purchases AS value
FROM sample
LIMIT number_datapoints;

-- Erstelle eine Relation für die (binären) Werte der abhängigen Variablen.
DROP TABLE IF EXISTS slr_binary_values;
CREATE TEMPORARY TABLE slr_binary_values (
  id INTEGER,
  value INTEGER
);

-- Füge die Werte der abhängingen Variable ein.
INSERT INTO slr_binary_values
SELECT
  row_number() OVER () AS id,
  money AS value
FROM sample
LIMIT number_datapoints;

-- Erstelle eine Relation für die alten und neuen Parameterwerte.
DROP TABLE IF EXISTS slr_parameters;
CREATE TEMPORARY TABLE slr_parameters (
  variable VARCHAR(50),
  old NUMERIC(65, 30),
  new NUMERIC(65, 30)
);

-- Füge die Initialwerte der Parameter ein.
INSERT INTO slr_parameters VALUES
  ('alpha', 0, 0),
  ('beta_purchases', 0, 0);

-- Erstelle eine Relation für die Werte der linearen Funktion für alle Datenpunkte.
DROP TABLE IF EXISTS slr_linears;
CREATE TEMPORARY TABLE slr_linears (
  id INTEGER,
  old NUMERIC(65, 30),
  new NUMERIC(65, 30)
);

-- Befülle die Relation für die Werte der logistischen Funktion.
PERFORM slr_calculate_linears();

-- Erstelle eine Relation für den Gradienten.
DROP TABLE IF EXISTS slr_gradient;
CREATE TEMPORARY TABLE slr_gradient (
  variable VARCHAR(50),
  value NUMERIC(65, 30)
);

-- Iteriere über die Anzahl der gewünschten Iterationen.
counter := 0;
WHILE counter < rounds AND step > 0.000000000000000000000000000001 LOOP

  -- Berechne den Gradienten und die neuen Parameter mit der aktuellen Schrittweite.
  PERFORM slr_calculate_gradient();
  PERFORM slr_calculate_new_parameters(step);
  PERFORM slr_calculate_linears();

  -- Verringere die Schrittweite solange, bis die neuen Parameter ein besseres Ergebnis liefern als die alten.
  WHILE NOT (
    SELECT
      SUM(POWER(bv.value - l.new, 2)) <
      SUM(POWER(bv.value - l.old, 2))
    FROM slr_linears l
    JOIN slr_binary_values bv ON bv.id = l.id
  ) AND step > 0.000000000000000000000000000001 LOOP

    step := step / 2;
    PERFORM slr_calculate_new_parameters(step);
    PERFORM slr_calculate_linears();

  END LOOP;

  -- Ersetze die alten Werte durch die neuen Werte.
  UPDATE slr_parameters
  SET old = new;

  UPDATE slr_linears
  SET old = new;

  counter := counter + 1;

END LOOP;

-- Gib eine Relation mit Parametername und zugehörigem Wert zurück.
RETURN QUERY
SELECT slr_parameters.variable::VARCHAR(50), old AS value
FROM slr_parameters;

-- Lösche die Relationen wieder.
DROP TABLE IF EXISTS slr_datapointss;
DROP TABLE IF EXISTS slr_binary_values;
DROP TABLE IF EXISTS slr_parameters;
DROP TABLE IF EXISTS slr_linears;
DROP TABLE IF EXISTS slr_gradient;

END;
$$ LANGUAGE plpgsql;
