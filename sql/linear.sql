DROP PROCEDURE IF EXISTS CalculateGradient;
DROP PROCEDURE IF EXISTS CalculateNewParameters;
DROP PROCEDURE IF EXISTS CalculateLinears;
DROP PROCEDURE IF EXISTS IsNewBetter;
DROP PROCEDURE IF EXISTS Main;

DELIMITER ;;
-- this procedure calculates the gradient for the current parameter values
CREATE PROCEDURE `CalculateGradient`()
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
        SELECT SUM(2 * (dv.value - T0.linear))
        FROM (
            SELECT d.id, SUM(d.value * p.old) + bias AS `linear`
            FROM data d
            JOIN parameters p ON p.variable = d.variable
            GROUP BY d.id
        ) T0
        JOIN dependentValues dv ON dv.id = T0.id
    )
    WHERE variable = 'bias';

    -- calculate other gradients
    -- -------------- TODO ----------------

    UPDATE gradient
    JOIN (
        SELECT d.variable, SUM(2 * (dv.value - l.old) * d.value) AS `value`
        FROM data d
        JOIN linears l ON l.id = d.id
        JOIN dependentValues dv ON dv.id = d.id
        GROUP BY d.variable
    ) T0 ON T0.variable = gradient.variable
    SET gradient.value = T0.value;

    -- -------------- END TODO ----------------

END;;


-- this procedure calculates the new parameters
CREATE PROCEDURE `CalculateNewParameters`(IN step DECIMAL(40, 20))
BEGIN

    UPDATE parameters
    JOIN gradient ON gradient.variable = parameters.variable
    SET parameters.new = parameters.old + step * gradient.value;

END;;



-- this procedure calculates the linears for current parameter values
CREATE PROCEDURE `CalculateLinears`()
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

    DELETE FROM linears;
    INSERT INTO linears
        SELECT
            d.id,
            biasOld + SUM(d.value * p.old) AS `old`,
            biasNew + SUM(d.value * p.new) AS `new`
        FROM data d
        JOIN parameters p ON p.variable = d.variable
        GROUP BY d.id;

END;;



-- this procedure calculates the least squared function for current parameter values
-- and states if the new parameters are really better
CREATE PROCEDURE `IsNewBetter`(OUT better INT(1))
BEGIN

    SET better = (
        SELECT
            SUM(POWER(dv.value - l.new, 2)) <
            SUM(POWER(dv.value - l.old, 2))
        FROM linears l
        JOIN dependentValues dv ON dv.id = l.id
    );

END;;



-- main procedure for execution
CREATE PROCEDURE `Main`(IN rounds INT(11), IN use_sample INT(1))
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

        -- insert all linear transformed values for column 'purchases' into data
        SET @counter = 0;
        INSERT INTO data
        SELECT
            @counter := @counter + 1 AS `id`,
            'purchases' AS `variable`,
            purchases AS `value`
        FROM regression;

    ELSE

        INSERT INTO data VALUES
            (1, 'x', 1),
            (2, 'x', 2),
            (3, 'x', 3),
            (4, 'x', 4),
            (5, 'x', 5);

    END IF;

    -- create temporary table for dependent variable
    DROP TEMPORARY TABLE IF EXISTS dependentValues;
    CREATE TEMPORARY TABLE dependentValues (
        id INT(11),
        value INT(1)
    );

    IF use_sample THEN

        -- insert all values for column 'prime' into dependentValues
        SET @counter = 0;
        INSERT INTO dependentValues
        SELECT
            @counter := @counter + 1 AS `id`,
            money AS `value`
        FROM regression;

    ELSE

        INSERT INTO dependentValues VALUES
            (1, 1),
            (2, 2),
            (3, 3),
            (4, 4),
            (5, 5);

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
            ('purchases', 0, 0);

    ELSE

        INSERT INTO parameters VALUES
            ('bias', 0, 0),
            ('x', 0, 0);

    END IF;

    -- create temporary table for linears
    DROP TEMPORARY TABLE IF EXISTS linears;
    CREATE TEMPORARY TABLE linears (
        id INT(11),
        old DECIMAL(40, 20),
        new DECIMAL(40, 20)
    );

    -- insert initial values into linears table
    CALL CalculateLinears();

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
            ('purchases', 0);

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
        CALL CalculateLinears();
        CALL CalculateGradient();
        CALL CalculateNewParameters(step);
        CALL CalculateLinears();
        CALL IsNewBetter(better);

        WHILE better = 0 AND step > 0.00000000000000000001 DO

            SET step = step / 2;
            CALL CalculateNewParameters(step);
            CALL CalculateLinears();
            CALL IsNewBetter(better);

        END WHILE;

        UPDATE parameters
        SET parameters.old = parameters.new;

        SET counter = counter + 1;

    END WHILE;

    SELECT variable, old AS `value`
    FROM parameters;

END;;
DELIMITER ;

CALL Main(10, 1);
