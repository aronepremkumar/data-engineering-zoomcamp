# taxi_2021_download_and_check.py
import os
import pandas as pd
from pathlib import Path

BASE_URL_GREEN = "https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_"
BASE_URL_YELLOW = "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_"

YEARS_MONTHS = [(2021, m) for m in range(1, 8)]   # Jan–Jul

def download_and_check(taxi_type: str, year: int, month: int):
    month_str = f"{month:02d}"
    
    if taxi_type == "green":
        url = f"{BASE_URL_GREEN}{year}-{month_str}.parquet"
    else:
        url = f"{BASE_URL_YELLOW}{year}-{month_str}.parquet"
    
    filename = f"{taxi_type}_tripdata_{year}-{month_str}.parquet"
    
    print(f"\nProcessing {taxi_type.upper()} {year}-{month_str} ...")
    print(f"URL:  {url}")
    
    # Download
    if not Path(filename).exists():
        print("Downloading...")
        os.system(f"wget -O {filename} '{url}'")
        # or use curl: os.system(f"curl -L -o {filename} '{url}'")
    else:
        print("File already exists — skipping download")
    
    # Check file exists and is not empty
    if not Path(filename).exists() or Path(filename).stat().st_size == 0:
        print("❌ Download failed or file is empty")
        return
    
    # Basic inspection
    print("Reading parquet file...")
    try:
        df = pd.read_parquet(filename)
        print(f"Success! Shape: {df.shape}")
        print(f"Columns: {list(df.columns)}")
        print(f"Memory usage: ~{df.memory_usage(deep=True).sum() / 1_048_576:.1f} MB")
        print("-" * 60)
    except Exception as e:
        print(f"❌ Error reading file: {e}")

# Run for all months and both types
for year, month in YEARS_MONTHS:
    download_and_check("green", year, month)
    download_and_check("yellow", year, month)