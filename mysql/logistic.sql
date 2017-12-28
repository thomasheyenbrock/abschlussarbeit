DROP PROCEDURE IF EXISTS Logistic_CalculateGradient;
DROP PROCEDURE IF EXISTS Logistic_CalculateNewParameters;
DROP PROCEDURE IF EXISTS Logistic_CalculateLogit;
DROP PROCEDURE IF EXISTS Logistic_IsNewLogBetter;
DROP PROCEDURE IF EXISTS Logistic_Main;

DELIMITER ;;
-- this procedure calculates the gradient for the current parameter values
CREATE PROCEDURE `Logistic_CalculateGradient`()
BEGIN

    DECLARE bias DECIMAL(40, 20);

    SET bias = (
        SELECT old
        FROM parameters
        WHERE variable = 'bias'
    );

    -- calculate gradient for the bias
    UPDATE gradient
    SET value = (
        SELECT (SELECT SUM(value) FROM binaryValues) - SUM(1 / (1 + exp(- T0.linear)))
        FROM (
            SELECT d.id, SUM(d.value * p.old) + bias AS `linear`
            FROM data d
            JOIN parameters p ON p.variable = d.variable
            GROUP BY d.id
        ) T0
    )
    WHERE variable = 'bias';

    -- calculate other gradients
    UPDATE gradient
    JOIN (
        SELECT d.variable, -SUM(d.value * l.old) AS `value`
        FROM data d
        JOIN logits l ON l.id = d.id
        GROUP BY d.variable
    ) T0
    ON T0.variable = gradient.variable
    SET gradient.value = T0.value;

    UPDATE gradient
    JOIN (
        SELECT d.variable, SUM(d.value) AS `value`
        FROM data d
        JOIN binaryValues bv ON bv.id = d.id
        WHERE bv.value = 1
        GROUP BY d.variable
    ) T0
    ON T0.variable = gradient.variable
    SET gradient.value = gradient.value + T0.value;

END;;


-- this procedure calculates the new parameters
CREATE PROCEDURE `Logistic_CalculateNewParameters`(IN step DECIMAL(40, 20))
BEGIN

    UPDATE parameters
    JOIN gradient ON gradient.variable = parameters.variable
    SET parameters.new = parameters.old + step * gradient.value;

END;;



-- this procedure calculates the logits for current parameter values
CREATE PROCEDURE `Logistic_CalculateLogit`()
BEGIN

    DECLARE biasOld DECIMAL(40, 20);
    DECLARE biasNew DECIMAL(40, 20);

    SET biasOld = (
        SELECT old
        FROM parameters
        WHERE variable = 'bias'
    );

    SET biasNew = (
        SELECT new
        FROM parameters
        WHERE variable = 'bias'
    );

    DELETE FROM logits;
    INSERT INTO logits
        SELECT
            d.id,
            1 / (1 + exp(- SUM(d.value * p.old) - biasOld)) AS `old`,
            1 / (1 + exp(- SUM(d.value * p.new) - biasNew)) AS `new`
        FROM data d
        JOIN parameters p ON p.variable = d.variable
        GROUP BY d.id;

END;;



-- this procedure calculates the log likelihood function for current parameter values
-- and states if the new parameters are really better
CREATE PROCEDURE `Logistic_IsNewLogBetter`(OUT better INT(1))
BEGIN

    SET better = (
        SELECT
            SUM(LOG(bv.value * l.new + (1 - bv.value) * (1 - l.new))) >
            SUM(LOG(bv.value * l.old + (1 - bv.value) * (1 - l.old)))
        FROM logits l
        JOIN binaryValues bv ON bv.id = l.id
    );

END;;



-- main procedure for execution
CREATE PROCEDURE `Logistic_Main`(IN rounds INT(11), IN use_sample INT(1))
BEGIN

    DECLARE step DECIMAL(40, 20);
    DECLARE min INT(11);
    DECLARE max INT(11);
    DECLARE better INT(1);
    DECLARE counter INT(11);

    -- create a temporary table for the data
    DROP TEMPORARY TABLE IF EXISTS data;
    CREATE TEMPORARY TABLE data(
        id INT(11),
        variable VARCHAR(32),
        value DECIMAL(40, 20)
    );

    IF use_sample = 1 THEN

        -- calculate min and max values for money
        SET min = (SELECT MIN(money) FROM regression);
        SET max = (SELECT MAX(money) FROM regression);

        -- insert all linear transformed values for column 'money' into data
        SET @counter = 0;
        INSERT INTO data
        SELECT
            @counter := @counter + 1 AS `id`,
            'money' AS `variable`,
            (money - min) / (max - min) AS `value`
        FROM regression LIMIT 10;

    ELSE

        INSERT INTO data VALUES
            (1, 'x', 1),
            (2, 'x', 2),
            (3, 'x', 3),
            (4, 'x', 4),
            (5, 'x', 5);

    END IF;

    -- create temporary table for binary variable
    DROP TEMPORARY TABLE IF EXISTS binaryValues;
    CREATE TEMPORARY TABLE binaryValues (
        id INT(11),
        value INT(1)
    );

    IF use_sample THEN

        -- insert all values for column 'prime' into binaryValues
        SET @counter = 0;
        INSERT INTO binaryValues
        SELECT
            @counter := @counter + 1 AS `id`,
            prime AS `value`
        FROM regression LIMIT 10;

    ELSE

        INSERT INTO binaryValues VALUES
            (1, 0),
            (2, 0),
            (3, 1),
            (4, 0),
            (5, 1);

    END IF;

    -- create temporary table for parameters
    DROP TEMPORARY TABLE IF EXISTS parameters;
    CREATE TEMPORARY TABLE parameters (
        variable VARCHAR(32),
        old DECIMAL(40, 20),
        new DECIMAL(40, 20)
    );

    -- set initial parameters
    IF use_sample = 1 THEN

        INSERT INTO parameters VALUES
            ('bias', 0, 0),
            ('money', 0, 0);

    ELSE

        INSERT INTO parameters VALUES
            ('bias', 0, 0),
            ('x', 0, 0);

    END IF;

    -- create temporary table for logits
    DROP TEMPORARY TABLE IF EXISTS logits;
    CREATE TEMPORARY TABLE logits (
        id INT(11),
        old DECIMAL(40, 20),
        new DECIMAL(40, 20)
    );

    -- insert initial values into logit table
    CALL Logistic_CalculateLogit();

    -- create temporary table for gradient
    DROP TEMPORARY TABLE IF EXISTS gradient;
    CREATE TEMPORARY TABLE gradient (
        variable VARCHAR(32),
        value DECIMAL(40, 20)
    );

    -- insert variables in gradient table
    IF use_sample = 1 THEN

        INSERT INTO gradient VALUES
            ('bias', 0),
            ('money', 0);

    ELSE

        INSERT INTO gradient VALUES
            ('bias', 0),
            ('x', 0);

    END IF;

    -- set initial step distance
    SET step = 1;

    -- loop
    SET counter = 0;
    WHILE counter < rounds AND step > 0.00000000000000000001 DO

        SET better = 0;
        CALL Logistic_CalculateLogit();
        CALL Logistic_CalculateGradient();
        CALL Logistic_CalculateNewParameters(step);
        CALL Logistic_CalculateLogit();
        CALL Logistic_IsNewLogBetter(better);

        WHILE better = 0 AND step > 0.00000000000000000001 DO

            SET step = step / 2;
            CALL Logistic_CalculateNewParameters(step);
            CALL Logistic_CalculateLogit();
            CALL Logistic_IsNewLogBetter(better);

        END WHILE;

        UPDATE parameters
        SET parameters.old = parameters.new;

        SET counter = counter + 1;

    END WHILE;

    SELECT variable, old AS `value`
    FROM parameters;

END;;
DELIMITER ;

CALL Logistic_Main(1000, 0);
