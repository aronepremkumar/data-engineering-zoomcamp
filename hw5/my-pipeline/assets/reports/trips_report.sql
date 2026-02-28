/* @bruin
name: reports.trips_report

type: duckdb.sql

# Depends on the cleaned staging layer
depends:
  - staging.trips

materialization:
  type: table
  strategy: time_interval           # Rebuild only the affected time window (efficient for reports)
  incremental_key: report_date      # We use the aggregated date (derived in query)
  time_granularity: date            # Report is daily → date level

# Report columns: aggregated at (pickup_date, pickup_zone) level
# Primary key = composite of date + zone for uniqueness per day/zone
columns:
  - name: report_date
    type: date
    description: The date of the trips (based on pickup datetime)
    primary_key: true
  - name: pickup_zone_id
    type: integer
    description: Taxi zone ID where the trip started (PULocationID)
    primary_key: true
  - name: trip_count
    type: bigint
    description: Number of trips that started in this zone on this date
    checks:
      - name: non_negative
  - name: avg_passengers
    type: double
    description: Average number of passengers per trip
    checks:
      - name: non_negative
  - name: total_distance_miles
    type: double
    description: Total trip distance in miles
    checks:
      - name: non_negative
  - name: total_fare_amount
    type: double
    description: Sum of fare amounts
    checks:
      - name: non_negative
  - name: total_revenue
    type: double
    description: Sum of total_amount (fare + tips + tolls + extras)
    checks:
      - name: non_negative

# Custom check example: ensure no days with zero trips in zones that had activity (sanity check)
custom_checks:
  - name: no_zero_trip_days_in_active_zones
    description: Zones with any activity should have at least one trip per day
    query: |
      SELECT COUNT(*)
      FROM {{ this }}
      WHERE trip_count = 0
    value: 0

@bruin */

-- Daily report by pickup date and pickup zone
SELECT
  DATE(tpep_pickup_datetime) AS report_date,
  PULocationID AS pickup_zone_id,

  COUNT(*) AS trip_count,
  AVG(passenger_count) AS avg_passengers,
  SUM(trip_distance) AS total_distance_miles,
  SUM(fare_amount) AS total_fare_amount,
  SUM(total_amount) AS total_revenue

FROM staging.trips

-- Filter to the current incremental window (Bruin deletes + re-inserts only this range)
WHERE tpep_pickup_datetime >= '{{ start_datetime }}'
  AND tpep_pickup_datetime < '{{ end_datetime }}'

-- Group by the aggregation keys
GROUP BY
  report_date,
  pickup_zone_id

-- Optional: having clause for quality (e.g. exclude days with too few trips)
HAVING trip_count > 0