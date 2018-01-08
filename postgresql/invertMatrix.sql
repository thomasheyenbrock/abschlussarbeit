-- main procedure for matrix inversion
CREATE OR REPLACE FUNCTION invert_matrix(a NUMERIC(40, 20)[][])
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
