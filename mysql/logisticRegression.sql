DROP PROCEDURE IF EXISTS calculate_gradient;
DROP PROCEDURE IF EXISTS calculate_new_parameters;
DROP PROCEDURE IF EXISTS calculate_logit;
DROP PROCEDURE IF EXISTS are_new_parameters_better;
DROP PROCEDURE IF EXISTS logistic_regression;

DELIMITER ;;
-- this procedure calculates the logits for current parameter values
CREATE PROCEDURE `calculate_logit`()
BEGIN

DECLARE alpha_old DECIMAL(65, 30);
DECLARE alpha_new DECIMAL(65, 30);

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

-- this procedure calculates the gradient for the current parameter values
CREATE PROCEDURE `calculate_gradient`()
BEGIN

DELETE FROM gradient;

-- calculate gradient for alpha
INSERT INTO gradient
SELECT 'alpha' AS `variable`, SUM(bv.value - l.old) AS `value`
FROM logits l
JOIN binary_values bv ON bv.id = l.id;

-- calculate other gradients
INSERT INTO gradient
SELECT d.variable, SUM(d.value * (bv.value - l.old)) AS `value`
FROM logits l
JOIN binary_values bv ON bv.id = l.id
JOIN datapoints d ON d.id = l.id
GROUP BY d.variable;

END;;

-- this procedure calculates the new parameters
CREATE PROCEDURE `calculate_new_parameters`(IN step DECIMAL(65, 30))
BEGIN

UPDATE parameters
JOIN gradient ON gradient.variable = parameters.variable
SET parameters.new = parameters.old + step * gradient.value;

END;;

-- this procedure calculates the log likelihood function for current parameter values
-- and states if the new parameters are really better
CREATE PROCEDURE `are_new_parameters_better`(OUT better INT(1))
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
CREATE PROCEDURE `logistic_regression`(IN number_datapoints INT(11), IN rounds INT(11), step DECIMAL(65, 30))
BEGIN

DECLARE min INT(11);
DECLARE max INT(11);
DECLARE transform DECIMAL(65, 30);
DECLARE better INT(1);
DECLARE counter INT(11);

-- create a temporary table for the data
DROP TEMPORARY TABLE IF EXISTS datapoints;
CREATE TEMPORARY TABLE datapoints (
  id INT(11),
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (id, variable)
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
  value INT(1),
  PRIMARY KEY (id)
);

-- insert all values for column 'premium' into binary_values
SET @counter = 0;
INSERT INTO binary_values
SELECT
  @counter := @counter + 1 AS `id`,
  premium AS `value`
FROM sample
LIMIT number_datapoints;

-- create temporary table for parameters
DROP TEMPORARY TABLE IF EXISTS parameters;
CREATE TEMPORARY TABLE parameters (
  variable VARCHAR(32),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

-- set initial parameters
INSERT INTO parameters VALUES
  ('alpha', 0, 0),
  ('beta_money', 0, 0);

-- create temporary table for logits
DROP TEMPORARY TABLE IF EXISTS logits;
CREATE TEMPORARY TABLE logits (
  id INT(11),
  old DECIMAL(65, 30),
  new DECIMAL(65, 30),
  PRIMARY KEY (id)
);

-- insert initial values into logit table
CALL calculate_logit();

-- create temporary table for gradient
DROP TEMPORARY TABLE IF EXISTS gradient;
CREATE TEMPORARY TABLE gradient (
  variable VARCHAR(32),
  value DECIMAL(65, 30),
  PRIMARY KEY (variable)
);

-- insert variables in gradient table
INSERT INTO gradient VALUES
  ('alpha', 0),
  ('beta_money', 0);

-- loop
SET counter = 0;
WHILE counter < rounds AND step > 0.000000000000000000000000000001 DO

  CALL calculate_gradient();
  CALL calculate_new_parameters(step);
  CALL calculate_logit();

  WHILE (
    SELECT
      SUM(LOG(bv.value * l.new + (1 - bv.value) * (1 - l.new))) >
      SUM(LOG(bv.value * l.old + (1 - bv.value) * (1 - l.old)))
    FROM logits l
    JOIN binary_values bv ON bv.id = l.id
  ) = 0 AND step > 0.000000000000000000000000000001 DO

    SET step = step / 2;
    CALL calculate_new_parameters(step);
    CALL calculate_logit();

  END WHILE;

  UPDATE parameters
  SET parameters.old = parameters.new;

  UPDATE logits
  SET logits.old = logits.new;

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
