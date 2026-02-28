import io
import os
import requests
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq
from google.cloud import storage

def upload_to_gcs(bucket_name: str, object_name: str, local_file: str):
    """Uploads a file to GCS"""
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(object_name)
    blob.upload_from_filename(local_file)
    print(f"Uploaded {local_file} → gs://{bucket_name}/{object_name}")

# === Customize here ===
bucket_name = 'de-zoomcamp-hw4'
years = [2019, 2020]
taxi_colors = ['yellow', 'green']
init_url = 'https://github.com/DataTalksClub/nyc-tlc-data/releases/download'
# === End customize ===

for color in taxi_colors:
    for year in years:
        for month in range(1, 13):
            file_name = f"{color}_tripdata_{year}-{month:02d}.csv.gz"
            parquet_file = file_name.replace('.csv.gz', '.parquet')
            url = f"{init_url}/{color}/{file_name}"
            
            print(f"\nProcessing {file_name} ...")
            
            try:
                # Download
                response = requests.get(url, timeout=60)
                response.raise_for_status()
                
                # Read gzipped CSV → Pandas
                df = pd.read_csv(io.BytesIO(response.content), compression='gzip', low_memory=False)
                print(f"  Rows: {len(df):,}")
                
                # To Parquet
                table = pa.Table.from_pandas(df, preserve_index=False)
                pq.write_table(table, parquet_file)
                
                # Upload to GCS in subfolder
                gcs_path = f"{color}/{parquet_file}"
                upload_to_gcs(bucket_name, gcs_path, parquet_file)
                
                # Cleanup local parquet file to save disk space
                os.remove(parquet_file)
                
            except requests.exceptions.RequestException as e:
                print(f"  Download failed: {e}")
            except Exception as e:
                print(f"  Error processing {file_name}: {e}")

print("\nAll done! Check your GCS bucket.")