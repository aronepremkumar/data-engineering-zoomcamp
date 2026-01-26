
-- Check for a few known columns (adjust table name if different)
SELECT 
    lpep_pickup_datetime,
    "PULocationID",
    trip_distance,
    total_amount,
    tip_amount
FROM green_taxi_trips
LIMIT 10;

SELECT COUNT(*) 
FROM green_taxi_trips
WHERE lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
  AND trip_distance <= 1;

SELECT DATE(lpep_pickup_datetime) AS pickup_date
FROM green_taxi_trips
WHERE trip_distance < 100
  AND lpep_pickup_datetime >= '2025-11-01'
  AND lpep_pickup_datetime < '2025-12-01'
ORDER BY trip_distance DESC
LIMIT 1;

SELECT z."Zone"
FROM green_taxi_trips t
JOIN zones z ON t."PULocationID" = z."LocationID"
WHERE DATE(t.lpep_pickup_datetime) = '2025-11-18'
GROUP BY z."Zone"
ORDER BY SUM(t.total_amount) DESC
LIMIT 1;

SELECT dz."Zone" AS dropoff_zone
FROM green_taxi_trips t
JOIN zones pz ON t."PULocationID" = pz."LocationID"
JOIN zones dz ON t."DOLocationID" = dz."LocationID"
WHERE pz."Zone" = 'East Harlem North'
  AND t.lpep_pickup_datetime >= '2025-11-01'
  AND t.lpep_pickup_datetime < '2025-12-01'
ORDER BY t.tip_amount DESC
LIMIT 1;