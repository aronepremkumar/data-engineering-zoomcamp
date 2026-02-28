"""@bruin
name: ingestion.trips
type: python
image: python:3.11
connection: duckdb-zoomcamp

materialization:
  type: table
  strategy: append

columns:
  - name: VendorID
    type: integer
    description: Vendor providing the data (1 = Creative Mobile, 2 = VeriFone)
  - name: tpep_pickup_datetime
    type: timestamp
    description: Pickup datetime (Yellow) or renamed from lpep_pickup_datetime (Green)
  - name: tpep_dropoff_datetime
    type: timestamp
    description: Dropoff datetime
  - name: passenger_count
    type: integer
    description: Number of passengers
  - name: trip_distance
    type: double
    description: Trip distance in miles
  - name: PULocationID
    type: integer
    description: Pickup location ID (taxi zone)
  - name: DOLocationID
    type: integer
    description: Dropoff location ID
  - name: payment_type
    type: integer
    description: Payment type ID (joins to payment_lookup)
  - name: fare_amount
    type: double
    description: Time-and-distance fare
  - name: total_amount
    type: double
    description: Total charged (fare + extras + tip + tolls + etc.)
  - name: taxi_type
    type: string
    description: Source type ('yellow' or 'green')
  - name: extracted_at
    type: timestamp
    description: When this batch was ingested (UTC)
@bruin"""

import os
import json
import pandas as pd
from datetime import datetime
from dateutil.relativedelta import relativedelta


def materialize(**kwargs):
    """
    Ingest NYC Yellow and Green taxi trip data for the run window.
    Returns empty DataFrame (with schema) if no data is available.
    """
    # Pipeline variables
    vars_json = os.environ.get("BRUIN_VARS", "{}")
    vars_dict = json.loads(vars_json)
    taxi_types = vars_dict.get("taxi_types", ["yellow", "green"])

    # Bruin date window
    start_str = os.environ.get("BRUIN_START_DATE")
    end_str   = os.environ.get("BRUIN_END_DATE")

    if not start_str or not end_str:
        raise ValueError("BRUIN_START_DATE and BRUIN_END_DATE must be set")

    start_date = datetime.strptime(start_str, "%Y-%m-%d")
    end_date   = datetime.strptime(end_str,   "%Y-%m-%d")

    print(f"Ingestion window: {start_str} → {end_str}")
    print(f"Fetching taxi types: {', '.join(taxi_types)}")

    dfs = []

    for taxi_type in taxi_types:
        current = start_date
        while current <= end_date:
            year  = current.year
            month = current.month

            url = f"https://d37ci6vzurychx.cloudfront.net/trip-data/{taxi_type}_tripdata_{year:04d}-{month:02d}.parquet"
            print(f"  → {taxi_type} {year}-{month:02d}: {url}")

            try:
                df = pd.read_parquet(url)
                print(f"      Downloaded {len(df):,} rows")

                # Standardize column names (Green → Yellow style)
                df = df.rename(columns={
                    "lpep_pickup_datetime":  "tpep_pickup_datetime",
                    "lpep_dropoff_datetime": "tpep_dropoff_datetime",
                })

                df["taxi_type"]    = taxi_type
                df["extracted_at"] = datetime.utcnow()

                dfs.append(df)

            except Exception as e:
                print(f"      Failed: {str(e)} (skipping)")

            current += relativedelta(months=1)

    if not dfs:
        print("No data fetched → returning empty DataFrame (asset succeeds)")
        return pd.DataFrame(columns=[
            "VendorID",
            "tpep_pickup_datetime",
            "tpep_dropoff_datetime",
            "passenger_count",
            "trip_distance",
            "PULocationID",
            "DOLocationID",
            "payment_type",
            "fare_amount",
            "total_amount",
            "taxi_type",
            "extracted_at"
        ])

    final_df = pd.concat(dfs, ignore_index=True)

    # Enforce expected columns
    cols = [
        "VendorID", "tpep_pickup_datetime", "tpep_dropoff_datetime",
        "passenger_count", "trip_distance", "PULocationID", "DOLocationID",
        "payment_type", "fare_amount", "total_amount",
        "taxi_type", "extracted_at"
    ]
    final_df = final_df.reindex(columns=cols)

    print(f"Prepared {len(final_df):,} rows for materialization")
    return final_df