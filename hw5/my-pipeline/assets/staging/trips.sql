/* @bruin
name: staging.trips

type: duckdb.sql

# Dependencies: reference upstream assets by their full name
depends:
  - ingestion.trips
  # - ingestion.payment_lookup   # Uncomment if you JOIN to enrich payment_type below

materialization:
  type: table
  strategy: time_interval           # Reprocess only the requested time window (Bruin deletes + inserts in window)
  incremental_key: tpep_pickup_datetime
  time_granularity: timestamp       # Matches TIMESTAMP type of pickup_datetime

# Output schema: document columns for lineage, metadata, and quality checks
columns:
  - name: trip_id
    type: varchar
    description: Unique trip identifier (if present; often VendorID + pickup + location combo)
    primary_key: true                 # Optional: if you define a composite/surrogate key
    nullable: false
    checks:
      - name: not_null
      - name: unique
  - name: tpep_pickup_datetime
    type: timestamp
    description: Pickup timestamp (standardized from Yellow tpep_ or Green lpep_)
    nullable: false
    checks:
      - name: not_null
  - name: tpep_dropoff_datetime
    type: timestamp
    description: Dropoff timestamp
    nullable: false
    checks:
      - name: not_null
  - name: passenger_count
    type: integer
    description: Number of passengers
    checks:
      - name: non_negative
      - name: accepted_values
        value: [0,1,2,3,4,5,6]      # Typical range
  - name: trip_distance
    type: double
    description: Trip distance in miles
    checks:
      - name: non_negative
  - name: PULocationID
    type: integer
    description: Pickup taxi zone ID
  - name: DOLocationID
    type: integer
    description: Dropoff taxi zone ID
  - name: payment_type
    type: integer
    description: Payment type ID (1=Credit card, etc.)
  - name: fare_amount
    type: double
    description: Fare amount
    checks:
      - name: non_negative
  - name: total_amount
    type: double
    description: Total amount charged
    checks:
      - name: non_negative

# Example custom check: ensure no trips with negative distance (data quality invariant)
custom_checks:
  - name: no_negative_trip_distance
    description: No rows should have negative trip_distance
    query: |
      SELECT COUNT(*) 
      FROM {{ this }} 
      WHERE trip_distance < 0
    value: 0

@bruin */

-- Staging query: clean, standardize, filter to time window
SELECT
  -- Use a surrogate trip_id if no natural PK; or VendorID + pickup + locations as composite
  CONCAT(
    CAST(VendorID AS VARCHAR),
    '_',
    REPLACE(CAST(tpep_pickup_datetime AS VARCHAR), ' ', '_'),
    '_',
    CAST(PULocationID AS VARCHAR)
  ) AS trip_id,  -- Example surrogate key

  COALESCE(tpep_pickup_datetime, lpep_pickup_datetime) AS tpep_pickup_datetime,
  COALESCE(tpep_dropoff_datetime, lpep_dropoff_datetime) AS tpep_dropoff_datetime,

  passenger_count,
  trip_distance,
  PULocationID,
  DOLocationID,
  payment_type,
  fare_amount,
  total_amount

  -- Optional enrichment: JOIN to payment lookup
  -- , pl.payment_type_name

FROM ingestion.trips

-- Optional: LEFT JOIN ingestion.payment_lookup pl ON payment_type = pl.payment_type_id

WHERE
  -- Critical for time_interval strategy: only process the run's window
  tpep_pickup_datetime >= '{{ start_datetime }}'
  AND tpep_pickup_datetime < '{{ end_datetime }}'

  -- Basic filters: remove obvious invalid rows
  AND trip_distance >= 0
  AND passenger_count >= 0
  AND tpep_pickup_datetime IS NOT NULL
  AND tpep_dropoff_datetime IS NOT NULL
  AND tpep_dropoff_datetime > tpep_pickup_datetime  -- Dropoff after pickup