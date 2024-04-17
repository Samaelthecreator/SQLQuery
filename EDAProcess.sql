--Realizaremos una query general para el proceso de exploración, previo a la transformación.
--La tabla en este contexto es: marzo2024
SELECT * FROM marzo2024
							--Dimension del dataframe
SELECT 
	(SELECT COUNT(*) FROM marzo2024 m) AS num_registros, 
	(SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'marzo2024') AS num_columnas;
	
							--Metadata de los objetos:
	/* INFORMATION_SCHEMA:
	Es un esquema el cual muestra información sobre los objetos de las bases de datos (tablas, coolumnas, llaves primarias y foraneas).
	Cumple con los estandares NASI SQL (portabilidad y compatibilidad.)
	-Las vistas son los objetos a los cuales consultar, como ejemplom estan:
			TABLES , COLUMNS , CONSTRAINTS, KEY_COLUMN_USAGE etc.
	*/
SELECT * FROM INFORMATION_SCHEMA.TABLES,INFORMATION_SCHEMA.KEY_COLUMN_USAGE;
	/* pg_catalog:
	Este esquema es unicamente de PostgreSQL y almacena informacion detallada sobre objetos internos de la base de datos,
	como catálogos de sistema, estadísitcas, indices, roles, etc.
	Guarda de forma detallada la implementación de las bases dentro de Postgre, como ejemplos estan: 
		pg_indexes,pg_roles etc.
	*/	
	
SELECT * FROM  pg_indexes, pg_roles

					--Tipos de datos de cada columna

DO $$
DECLARE 
    tipo_dato VARCHAR;
    nombre_columna VARCHAR;
    columnas_cursor CURSOR FOR
        SELECT column_name, data_type 
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'marzo2024';
    columna_rec RECORD;
BEGIN
    OPEN columnas_cursor;
    LOOP
        FETCH columnas_cursor INTO columna_rec;
        EXIT WHEN NOT FOUND;
        
        nombre_columna := columna_rec.column_name;
        tipo_dato := columna_rec.data_type;
        
        RAISE NOTICE 'Columna: %, Tipo de dato: %', nombre_columna, tipo_dato;
    END LOOP;
    CLOSE columnas_cursor;
END;
$$;
					---Espacios en blanco
--para un campo
SELECT COUNT(folio), folio AS folio_null_values FROM marzo2024
WHERE folio IS NULL
GROUP BY folio;
--Todos los campos

DO $$
	DECLARE
	columna_actual VARCHAR;
	valores_nulos INTEGER;
BEGIN	
	FOR columna_actual IN 
		SELECT column_name 
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'marzo2024'
		
	LOOP 
		EXECUTE 'SELECT COUNT (*) FROM marzo2024 WHERE ' || columna_actual || ' IS NULL'
		INTO valores_nulos;
			IF valores_nulos !=0 THEN
				raise notice 'columna: % , valores nulos: %', columna_actual, valores_nulos;
			ELSE
				
			END IF;
	END LOOP;
	
END;
$$;	

				--Análisis cuántitativos & estadistica general

-- Si la columna es tipo intero, flotante o cuántitativa, calculamos las medidas de tendencia central comenzando por:
/*máximo valor, minimimo valor, media, moda y promedio
	despues calculamos: varianza, desviación estándar.
	
*/
DO $$
	DECLARE 
	n_column VARCHAR;
	column_type VARCHAR;
	cursor_var CURSOR FOR
		SELECT column_name,data_type FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'marzo2024';
	rec_var RECORD;

BEGIN
		OPEN cursor_var;
		LOOP
			FETCH cursor_var INTO rec_var;
			EXIT WHEN NOT FOUND;
			
			n_column = rec_var.column_name;
			column_type = rec_var.data_type;
			
			IF column_type = 'integer' OR column_type = 'numeric' OR column_type = 'bigint' THEN
				--raise notice 'la columna a calcular los valores centrales son; %', n_column;
				WITH ranges AS (SELECT MAX(peso) AS max_kg, MIN(peso) AS min_kg FROM marzo2024),			--rangos
	   			 average AS (SELECT AVG(peso) AS Promedio FROM marzo2024),				--promedios		
				 median AS (SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY peso) AS median FROM marzo2024),	--mediana
	  			 trend AS (SELECT peso, COUNT(peso) AS contador FROM marzo2024 
						   GROUP BY peso) 
	   			SELECT peso, max_kg,min_kg, median, MAX(contador) AS quantity FROM ranges, median, trend
					
				GROUP BY peso,max_kg, min_kg, median
				ORDER BY quantity DESC
	   			LIMIT 5;
			
			
			
			ELSE
			
			END IF;
		END LOOP;
END
$$;

--Variables centrales

SELECT( SELECT MAX(peso) AS max_kg, MIN(peso) AS min_kg FROM marzo2024 			--rangos
	   	SELECT AVG(peso) AS Promedio FROM marzo2024					--promedios		
		SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY peso) AS mediana FROM marzo2024;	--mediana
	   WITH moda AS (
	   		SELECT peso, COUNT(peso) AS contador FROM marzo2024 
			GROUP BY peso) 
	   SELECT peso, MAX(contador) AS quantity FROM moda GROUP BY peso 
	   ORDER BY quantity DESC
	   LIMIT 1;
	   
	  
	  ) 
	
	
		
	
	
				--Gráficas de los datos cuántitativos
				
				
				--análisis de variables de tiempo en caso de que existan