 --Periodos de features, train & test (fechas)
SELECT AGE(MIN(date),MAX(date)) AS date_range, 'features' AS name_rango FROM features
UNION
SELECT AGE(MIN(date),MAX(date)) AS date_range, 'train' AS name_rango FROM train
UNION
SELECT AGE(MIN(date),MAX(date)) AS date_range, 'test' AS name_rango FROM test; 

-- El periodo de ventas es de: "-3 years -5 mons -21 days"

--¿Cuantas tiendas hay por departamento?
SELECT  dept AS train_department,s.type, COUNT(t.store) AS stores_quantity FROM train t
INNER JOIN stores s ON t.store = s.store
GROUP BY dept, type
ORDER BY dept ASC;

SELECT dept AS test_department, s.type , COUNT(te.store) AS stores_test_quantity FROM test te
INNER JOIN stores s ON te.store = s.store
GROUP BY dept, type
ORDER BY dept ASC;


--9 mejores ventas totales en dias festivos y dias no festivos por departamento:
--Dias festivos
WITH diasfestivos AS(
SELECT store, dept,SUM(weekly_sales) as holiday_total_sales FROM train 
WHERE isholiday = true
GROUP BY store, dept, isholiday
ORDER BY store DESC
LIMIT 3),
--Dias no festivos
diasnofestivos AS (
SELECT store, dept,SUM(weekly_sales) as nonholiday_total_sales FROM train 
WHERE isholiday = false
GROUP BY store, dept, isholiday
ORDER BY store DESC
LIMIT 3) SELECT holiday_total_sales, nonholiday_total_sales FROM diasfestivos df
INNER JOIN diasnofestivos dnf ON df.store = dnf.store;

--ganancias por año por tienda
WITH ventas2010 AS (
    SELECT store, SUM(weekly_sales) AS ganancias2010
    FROM train
    WHERE date BETWEEN '2010-02-05' AND '2010-12-31'
    GROUP BY store
), 
ventas2011 AS (
    SELECT store, SUM(weekly_sales) AS ganancias2011
    FROM train
    WHERE date BETWEEN '2011-01-01' AND '2011-12-31'
    GROUP BY store
), 
ventas2012 AS (
    SELECT store, SUM(weekly_sales) AS ganancias2012
    FROM train
    WHERE date BETWEEN '2012-01-01' AND '2012-12-31'
    GROUP BY store
)
SELECT x.store, ganancias2010, ganancias2011, ganancias2012
FROM ventas2010 x
INNER JOIN ventas2011 y ON x.store = y.store
INNER JOIN ventas2012 z ON y.store = z.store;

 		


--Query General
DO $$
	--DECLARE 
	--row RECORD;
BEGIN 

	WITH ventas2010 AS (
    SELECT store, SUM(weekly_sales) AS ganancias2010
    FROM train
    WHERE date BETWEEN '2010-02-05' AND '2010-12-31'
    GROUP BY store
	), 
	ventas2011 AS (
    SELECT store, SUM(weekly_sales) AS ganancias2011
    FROM train
    WHERE date BETWEEN '2011-01-01' AND '2011-12-31'
    GROUP BY store
	), 
	ventas2012 AS (
    SELECT store, SUM(weekly_sales) AS ganancias2012
    FROM train
    WHERE date BETWEEN '2012-01-01' AND '2012-12-31'
    GROUP BY store
	),	  
	   			diasfestivos AS(
				SELECT store, dept,SUM(weekly_sales) as holiday_total_sales FROM train 
				WHERE isholiday = true
				GROUP BY store, dept, isholiday
				ORDER BY store DESC
				LIMIT 3),
				--Dias no festivos
				diasnofestivos AS (
				SELECT store, dept,SUM(weekly_sales) as nonholiday_total_sales FROM train 
				WHERE isholiday = false
				GROUP BY store, dept, isholiday
				ORDER BY store DESC
				LIMIT 3)
				
		SELECT x.store, ganancias2010, ganancias2011, ganancias2012, holiday_total_sales, nonholiday_total_sales FROM diasfestivos df
		INNER JOIN diasnofestivos dnf ON df.store = dnf.store
		INNER JOIN ventas2010 x ON dnf.store = x.store
		INNER JOIN ventas2011 y ON x.store = y.store
		INNER JOIN ventas2012 z ON y.store = z.store;
		
		--RAISE NOTICE 'Resultado:';
    --FOR row IN 
        --SELECT x.store, ganancias2010, ganancias2011, ganancias2012, holiday_total_sales, nonholiday_total_sales 
        --FROM diasfestivos df
        --INNER JOIN diasnofestivos dnf ON df.store = dnf.store
        --INNER JOIN ventas2010 x ON dnf.store = x.store
        --INNER JOIN ventas2011 y ON x.store = y.store
        --INNER JOIN ventas2012 z ON y.store = z.store
    --LOOP
        --RAISE NOTICE 'Tienda: %, Ganancias 2010: %, Ganancias 2011: %, Ganancias 2012: %, Ventas dias festivos: %, Ventas dias no festivos: %', 
            --row.store, row.ganancias2010, row.ganancias2011, row.ganancias2012, row.holiday_total_sales, row.nonholiday_total_sales;
    --END LOOP;
END;
$$;
---------------------
ROLLBACK