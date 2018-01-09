DROP PROCEDURE IF EXISTS calculate_gradient;
DROP PROCEDURE IF EXISTS calculate_new_parameters;
DROP PROCEDURE IF EXISTS calculate_logit;
DROP PROCEDURE IF EXISTS is_new_logit_better;
DROP PROCEDURE IF EXISTS logistic_regression;

DELIMITER ;;
-- this procedure calculates the gradient for the current parameter values
CREATE PROCEDURE `calculate_gradient`()
BEGIN

DECLARE alpha DECIMAL(40, 20);

SET alpha = (
  SELECT old
  FROM parameters
  WHERE variable = 'alpha'
);

-- calculate gradient for alpha
UPDATE gradient
SET value = (
  SELECT (SELECT SUM(value) FROM binary_values) - SUM(1 / (1 + exp(- T0.linear)))
  FROM (
    SELECT d.id, SUM(d.value * p.old) + alpha AS `linear`
    FROM datapoints d
    JOIN parameters p ON p.variable = d.variable
    GROUP BY d.id
  ) T0
)
WHERE variable = 'alpha';

-- calculate other gradients
UPDATE gradient
JOIN (
  SELECT d.variable, -SUM(d.value * l.old) AS `value`
  FROM datapoints d
  JOIN logits l ON l.id = d.id
  GROUP BY d.variable
) T0
ON T0.variable = gradient.variable
SET gradient.value = T0.value;

UPDATE gradient
JOIN (
  SELECT d.variable, SUM(d.value) AS `value`
  FROM datapoints d
  JOIN binary_values bv ON bv.id = d.id
  WHERE bv.value = 1
  GROUP BY d.variable
) T0
ON T0.variable = gradient.variable
SET gradient.value = gradient.value + T0.value;

END;;

-- this procedure calculates the new parameters
CREATE PROCEDURE `calculate_new_parameters`(IN step DECIMAL(40, 20))
BEGIN

UPDATE parameters
JOIN gradient ON gradient.variable = parameters.variable
SET parameters.new = parameters.old + step * gradient.value;

END;;

-- this procedure calculates the logits for current parameter values
CREATE PROCEDURE `calculate_logit`()
BEGIN

DECLARE alpha_old DECIMAL(40, 20);
DECLARE alpha_new DECIMAL(40, 20);

SET alpha_old = (
  SELECT old
  FROM parameters
  WHERE variable = 'alpha'
);

SET alpha_new = (
  SELECT new
  FROM parameters
  WHERE variable = 'alpha'
);

DELETE FROM logits;

INSERT INTO logits
  SELECT
    d.id,
    1 / (1 + exp(- SUM(d.value * p.old) - alpha_old)) AS `old`,
    1 / (1 + exp(- SUM(d.value * p.new) - alpha_new)) AS `new`
  FROM datapoints d
  JOIN parameters p ON p.variable = d.variable
  GROUP BY d.id;

END;;

-- this procedure calculates the log likelihood function for current parameter values
-- and states if the new parameters are really better
CREATE PROCEDURE `is_new_logit_better`(OUT better INT(1))
BEGIN

SET better = (
  SELECT
    SUM(LOG(bv.value * l.new + (1 - bv.value) * (1 - l.new))) >
    SUM(LOG(bv.value * l.old + (1 - bv.value) * (1 - l.old)))
  FROM logits l
  JOIN binary_values bv ON bv.id = l.id
);

END;;

-- main procedure for execution
CREATE PROCEDURE `logistic_regression`(IN number_datapoints INT(11), IN rounds INT(11))
BEGIN

DECLARE step DECIMAL(40, 20);
DECLARE min INT(11);
DECLARE max INT(11);
DECLARE transform DECIMAL(40, 20);
DECLARE better INT(1);
DECLARE counter INT(11);

-- create a temporary table for the data
DROP TEMPORARY TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
  id INT(11),
  variable VARCHAR(32),
  value DECIMAL(40, 20)
);

-- calculate min and max values for money
SET min = (SELECT MIN(money) FROM sample);
SET max = (SELECT MAX(money) FROM sample);

-- insert all linear transformed values for column 'money' into data
SET @counter = 0;
INSERT INTO datapoints
SELECT
  @counter := @counter + 1 AS `id`,
  'beta_money' AS `variable`,
  (money - min) / (max - min) AS `value`
FROM sample
LIMIT number_datapoints;

-- create temporary table for binary variable
DROP TEMPORARY TABLE IF EXISTS binary_values;
CREATE TEMPORARY TABLE binary_values (
  id INT(11),
  value INT(1)
);

-- insert all values for column 'prime' into binary_values
SET @counter = 0;
INSERT INTO binary_values
SELECT
  @counter := @counter + 1 AS `id`,
  prime AS `value`
FROM sample
LIMIT number_datapoints;

-- create temporary table for parameters
DROP TEMPORARY TABLE IF EXISTS parameters;
CREATE TEMPORARY TABLE parameters (
  variable VARCHAR(32),
  old DECIMAL(40, 20),
  new DECIMAL(40, 20)
);

-- set initial parameters
INSERT INTO parameters VALUES
  ('alpha', 0, 0),
  ('beta_money', 0, 0);

-- create temporary table for logits
DROP TEMPORARY TABLE IF EXISTS logits;
CREATE TEMPORARY TABLE logits (
  id INT(11),
  old DECIMAL(40, 20),
  new DECIMAL(40, 20)
);

-- insert initial values into logit table
CALL calculate_logit();

-- create temporary table for gradient
DROP TEMPORARY TABLE IF EXISTS gradient;
CREATE TEMPORARY TABLE gradient (
  variable VARCHAR(32),
  value DECIMAL(40, 20)
);

-- insert variables in gradient table
INSERT INTO gradient VALUES
  ('alpha', 0),
  ('beta_money', 0);

-- set initial step distance
SET step = 1;

-- loop
SET counter = 0;
WHILE counter < rounds AND step > 0.00000000000000000001 DO

  SET better = 0;
  CALL calculate_logit();
  CALL calculate_gradient();
  CALL calculate_new_parameters(step);
  CALL calculate_logit();
  CALL is_new_logit_better(better);

  WHILE better = 0 AND step > 0.00000000000000000001 DO

    SET step = step / 2;
    CALL calculate_new_parameters(step);
    CALL calculate_logit();
    CALL is_new_logit_better(better);

  END WHILE;

  UPDATE parameters
  SET parameters.old = parameters.new;

  SET counter = counter + 1;

END WHILE;

UPDATE parameters
SET old = old / (max - min)
WHERE variable = 'beta_money';

SET transform = (SELECT old FROM parameters WHERE variable = 'beta_money');

UPDATE parameters
SET old = old - transform * min
WHERE variable = 'alpha';

SELECT variable, old AS `value`
FROM parameters;

END;;
DELIMITER ;

CALL logistic_regression(10, 1000);
