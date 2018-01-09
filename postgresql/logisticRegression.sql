-- this procedure calculates the gradient for the current parameter values
CREATE OR REPLACE FUNCTION calculate_gradient()
RETURNS void AS $$
BEGIN

DELETE FROM gradient;

-- calculate gradient for alpha
INSERT INTO gradient
SELECT 'alpha' AS variable, SUM(bv.value - l.old) AS value
FROM logits l
JOIN binary_values bv ON bv.id = l.id;

-- calculate other gradients
INSERT INTO gradient
SELECT d.variable, SUM(d.value * (bv.value - l.old)) AS value
FROM logits l
JOIN binary_values bv ON bv.id = l.id
JOIN datapoints d ON d.id = l.id
GROUP BY d.variable;

RETURN;

END;
$$ LANGUAGE plpgsql;


-- this procedure calculates the new parameters
CREATE OR REPLACE FUNCTION calculate_new_parameters(step NUMERIC(40, 20))
RETURNS void AS $$
BEGIN

UPDATE parameters
SET new = old + step * gradient.value
FROM gradient
WHERE gradient.variable = parameters.variable;

RETURN;

END;
$$ LANGUAGE plpgsql;




-- this procedure calculates the logits for current parameter values
CREATE OR REPLACE FUNCTION calculate_logit()
RETURNS void AS $$
BEGIN

DELETE FROM logits;

WITH
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



-- this procedure calculates the log likelihood function for current parameter values
-- and states if the new parameters are really better
CREATE OR REPLACE FUNCTION is_new_logit_better()
RETURNS BOOLEAN AS $$
DECLARE
  better BOOLEAN;
BEGIN

SELECT
  SUM(LOG(bv.value * l.new + (1 - bv.value) * (1 - l.new))) >
  SUM(LOG(bv.value * l.old + (1 - bv.value) * (1 - l.old))) INTO better
FROM logits l
JOIN binary_values bv ON bv.id = l.id;

RETURN better;

END;
$$ LANGUAGE plpgsql;




-- main procedure for execution
CREATE OR REPLACE FUNCTION logistic_regression(ref refcursor, number_datapoints INTEGER, IN rounds INTEGER)
RETURNS refcursor AS $$
DECLARE
  step NUMERIC(40, 20);
  better BOOLEAN;
  counter INTEGER;
BEGIN

-- create a temporary table for the data
DROP TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
  id INTEGER,
  variable VARCHAR(32),
  value NUMERIC(40, 20)
);

-- insert all linear transformed values for column 'money' into data
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

-- create temporary table for binary variable
DROP TABLE IF EXISTS binary_values;
CREATE TEMPORARY TABLE binary_values (
  id INTEGER,
  value INTEGER
);

-- insert all values for column 'prime' into binary_values
INSERT INTO binary_values
SELECT
  row_number() OVER () AS id,
  prime AS value
FROM sample
LIMIT number_datapoints;

-- create temporary table for parameters
DROP TABLE IF EXISTS parameters;
CREATE TEMPORARY TABLE parameters (
  variable VARCHAR(32),
  old NUMERIC(40, 20),
  new NUMERIC(40, 20)
);

-- set initial parameters
INSERT INTO parameters VALUES
  ('alpha', 0, 0),
  ('beta_money', 0, 0);

-- create temporary table for logits
DROP TABLE IF EXISTS logits;
CREATE TEMPORARY TABLE logits (
  id INTEGER,
  old NUMERIC(40, 20),
  new NUMERIC(40, 20)
);

-- insert initial values into logit table
PERFORM calculate_logit();

-- create temporary table for gradient
DROP TABLE IF EXISTS gradient;
CREATE TEMPORARY TABLE gradient (
  variable VARCHAR(32),
  value DECIMAL(40, 20)
);

-- insert variables in gradient table
INSERT INTO gradient VALUES
  ('alpha', 0),
  ('beta_money', 0);

-- set initial step distance
step := 1;

-- loop
counter := 0;
WHILE counter < rounds AND step > 0.00000000000000000001 LOOP

  PERFORM calculate_logit();
  PERFORM calculate_gradient();
  PERFORM calculate_new_parameters(step);
  PERFORM calculate_logit();
  better := is_new_logit_better();

  WHILE NOT better AND step > 0.00000000000000000001 LOOP

    step := step / 2;
    PERFORM calculate_new_parameters(step);
    PERFORM calculate_logit();
    better := is_new_logit_better();

  END LOOP;

  UPDATE parameters
  SET old = new;

  counter := counter + 1;

END LOOP;

UPDATE parameters
SET old = old / ((SELECT MAX(money) FROM sample) - (SELECT MIN(money) FROM sample))
WHERE variable = 'beta_money';

UPDATE parameters
SET old = old - (SELECT old FROM parameters WHERE variable = 'beta_money') * (SELECT MIN(money) FROM sample)
WHERE variable = 'alpha';

OPEN ref FOR
SELECT variable, old AS value
FROM parameters;

RETURN ref;

END;
$$ LANGUAGE plpgsql;

SELECT logistic_regression('cursor', 10, 1000);
FETCH ALL IN "cursor";
