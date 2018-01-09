-- procedure for transposing a matrix
CREATE OR REPLACE FUNCTION matrix_transpose(a NUMERIC(40, 20)[][])
RETURNS NUMERIC(40, 20)[][] AS $$
DECLARE
  rows_a INTEGER := array_length(a, 1);
  columns_a INTEGER := array_length(a, 2);
  i INTEGER;
  j INTEGER;
  c NUMERIC(40, 20)[][];
  new_row NUMERIC(40, 20)[];
BEGIN

i := 1;
WHILE i <= columns_a LOOP

  j := 1;
  WHILE j <= rows_a LOOP
    new_row[j] := a[j][i];
    j := j + 1;
  END LOOP;

  c := array_cat(c, array[new_row]);
  i := i + 1;
END LOOP;

RETURN c;

END;
$$ LANGUAGE plpgsql;

-- procedure for matrix multiplication
CREATE OR REPLACE FUNCTION matrix_multiplication(a NUMERIC(40, 20)[][], b NUMERIC(40, 20)[][])
RETURNS NUMERIC(40, 20)[][] AS $$
DECLARE
  rows_a INTEGER := array_length(a, 1);
  columns_a INTEGER := array_length(a, 2);
  columns_b INTEGER := array_length(b, 2);
  new_row NUMERIC(40, 20)[];
  c NUMERIC(40, 20)[][];
  counter_1 INTEGER;
  counter_2 INTEGER;
  counter_3 INTEGER;
BEGIN

counter_1 := 1;
WHILE counter_1 <= rows_a LOOP

  counter_2 := 1;
  WHILE counter_2 <= columns_b LOOP

    new_row[counter_2] := 0;
    counter_3 := 1;
    WHILE counter_3 <= columns_a LOOP
      new_row[counter_2] := new_row[counter_2] + a[counter_1][counter_3] * b[counter_3][counter_2];
      counter_3 := counter_3 + 1;
    END LOOP;

    counter_2 := counter_2 + 1;
  END LOOP;

  c := array_cat(c, array[new_row]);
  counter_1 := counter_1 + 1;
END LOOP;

RETURN c;

END;
$$ LANGUAGE plpgsql;

-- main procedure for matrix inversion
CREATE OR REPLACE FUNCTION matrix_inversion(a NUMERIC(40, 20)[][])
RETURNS NUMERIC(40, 20)[][] AS $$
DECLARE
  n INTEGER := array_length(a, 1);
  p INTEGER := 0;
  i INTEGER;
  j INTEGER;
  c NUMERIC(40, 20)[][] := a;
  o NUMERIC(40, 20)[][];
BEGIN

WHILE p < n LOOP

  p := p + 1;

  o := c;

  j := 1;
  WHILE j <= n LOOP
    IF j <> p THEN
      c[p][j] := c[p][j] / c[p][p];
    END IF;
    j := j + 1;
  END LOOP;

  i := 1;
  WHILE i <= n LOOP
    IF i <> p THEN
      c[i][p] := - c[i][p] / c[p][p];
    END IF;
    i := i + 1;
  END LOOP;

  i := 1;
  WHILE i <= n LOOP
    IF i <> p THEN
      j := 1;
      WHILE j <= n LOOP
        IF j <> p THEN
          c[i][j] := c[i][j] + o[p][j] * c[i][p];
        END IF;
        j := j + 1;
      END LOOP;
    END IF;
    i := i + 1;
  END LOOP;

  c[p][p] := 1 / c[p][p];

END LOOP;

RETURN c;

END;
$$ LANGUAGE plpgsql;

-- main procedure for regression analysis
CREATE OR REPLACE FUNCTION multiple_linear_regression(ref refcursor, number_datapoints int)
RETURNS refcursor AS $$
DECLARE
  x INTEGER[][]:= (
    SELECT ARRAY(
      SELECT ARRAY[1, purchases, age]
      FROM sample
      LIMIT number_datapoints
    )
  );
  y INTEGER[]:= (
    SELECT ARRAY(
      SELECT ARRAY[money]
      FROM sample
      LIMIT number_datapoints
    )
  );
  b NUMERIC[][];
BEGIN

b := matrix_multiplication(
  matrix_inversion(
    matrix_multiplication(
      matrix_transpose(x),
      x
    )
  ),
  matrix_multiplication(
    matrix_transpose(x),
    y
  )
);

OPEN ref FOR
SELECT 'alpha' AS variable, b[1][1] AS value
UNION
SELECT 'beta_purchases' AS variable, b[2][1] AS value
UNION
SELECT 'beta_age' AS variable, b[3][1] AS value;

RETURN ref;

END;
$$ LANGUAGE plpgsql;

-- execute main procedure
SELECT multiple_linear_regression('cursor', 100000);
FETCH ALL IN "cursor";
