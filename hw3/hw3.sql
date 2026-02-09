


CREATE OR REPLACE EXTERNAL TABLE `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi_external`
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://de-zoomcamp-yellow-2024/yellow_tripdata_2024-*.parquet']
);



CREATE OR REPLACE TABLE `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi` AS
SELECT * FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi_external`;


-- How many rows? (should be ~20.3 million)
SELECT COUNT(*) FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi_external`;

SELECT COUNT(*) FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi`;


SELECT COUNT(DISTINCT PULocationID) AS distinct_pu_locations
FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi_external`;     



SELECT COUNT(DISTINCT PULocationID) AS distinct_pu_locations
FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi`;        


SELECT COUNT(*) AS zero_fare_trips
FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi`
WHERE fare_amount = 0;


CREATE OR REPLACE TABLE `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi_optimized`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID
AS
SELECT *
FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi`;


SELECT DISTINCT VendorID
FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi`
WHERE tpep_dropoff_datetime >= '2024-03-01'
  AND tpep_dropoff_datetime < '2024-03-16';   -- inclusive of March 15


 SELECT DISTINCT VendorID
FROM `de-zoomcamp-2026-485504.ny_taxi_2024.yellow_taxi_optimized`
WHERE tpep_dropoff_datetime >= '2024-03-01'
  AND tpep_dropoff_datetime < '2024-03-16'; 
