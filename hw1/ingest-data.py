import pandas as pd
from sqlalchemy import create_engine

# Engine to connect to Postgres
engine = create_engine('postgresql://postgres:postgres@localhost:5433/ny_taxi')  # Use localhost:5433 from host

# Load zones (CSV)
zones = pd.read_csv('data/taxi_zone_lookup.csv')
zones.to_sql('zones', engine, if_exists='replace', index=False)

# Load trips (Parquet) - Chunk it if large
trips = pd.read_parquet('data/green_tripdata_2025-11.parquet')
trips.to_sql('green_taxi_trips', engine, if_exists='replace', index=False, chunksize=100000)  # Chunk to avoid memory issues
