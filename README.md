# data-engineering-zoomcamp


```markdown
# NYC Taxi Data PostgreSQL Database

Local PostgreSQL database setup with pgAdmin for working with NYC Taxi trip data (or any other dataset).

## What's included

- PostgreSQL 17 (alpine)  
- pgAdmin 4 web interface  
- Persistent data storage  
- Pre-created database: `ny_taxi`

## Requirements

- Docker  
- Docker Compose (v2 recommended)

## Quick Start

1. Clone this repository (or just save the files)

```bash
git clone <your-repo-url>
cd <project-folder>
```

2. Start the services

```bash
docker compose up -d
```

3. Wait ~10–30 seconds for PostgreSQL to be ready

4. Open pgAdmin in your browser:

```
http://localhost:8080
```

Login credentials:

- **Email**     : `pgadmin@pgadmin.com`  
- **Password**  : `pgadmin`

5. Connect to the database inside pgAdmin:

| Field                  | Value                  |
|------------------------|------------------------|
| Host name / Address    | `postgres`             |
| Port                   | `5432`                 |
| Maintenance database   | `ny_taxi`              |
| Username               | `postgres`             |
| Password               | `postgres`             |

## Connection Details (for applications / scripts)

| Parameter       | Value                        | Note                                 |
|-----------------|------------------------------|--------------------------------------|
| Host            | `localhost`                  | from your host machine               |
| Port            | `5433`                       | mapped from container 5432           |
| Database        | `ny_taxi`                    | pre-created                          |
| Username        | `postgres`                   | default superuser                    |
| Password        | `postgres`                   | (change in production!)              |

**Example connection strings:**

```text
# PostgreSQL URI
postgresql://postgres:postgres@localhost:5433/ny_taxi

# Python (SQLAlchemy / psycopg2)
postgresql+psycopg2://postgres:postgres@localhost:5433/ny_taxi

# Node.js (pg library)
{
  "host": "localhost",
  "port": 5433,
  "database": "ny_taxi",
  "user": "postgres",
  "password": "postgres"
}
```

## Useful Commands

```bash
# Start services in background
docker compose up -d

# See running containers
docker compose ps

# View logs
docker compose logs -f
docker compose logs -f postgres

# Quick psql access from terminal
docker exec -it postgres psql -U postgres -d ny_taxi

# Stop services (keep data)
docker compose down

# Stop and remove volumes (deletes all data!)
docker compose down -v

# Restart everything fresh
docker compose down -v && docker compose up -d
```

## Folder Structure (recommended)

```
nyc-taxi-postgres/
├── docker-compose.yml
├── README.md
├── init-scripts/           # (optional) place .sql files here to run on startup
└── data/                   # (not needed - data is stored in named volume)
```

## Security Notice

These credentials are **ONLY for local development**.

```text
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
PGADMIN_DEFAULT_PASSWORD=pgadmin
```

**Do NOT use these values in production or expose the ports publicly.**

## Optional: Initialize database with SQL scripts

Create a folder `init-scripts/` and put `.sql` files there.

Example structure:

```
init-scripts/
├── 01-create-tables.sql
└── 02-load-sample-data.sql
```

Then update `docker-compose.yml`:

```yaml
  db:
    ...
    volumes:
      - vol-pgdata:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d:ro
```

PostgreSQL will automatically run all `.sql` files in that folder when the database is created for the first time.

---

Happy querying! 🚕
```

Feel free to copy-paste this into your `README.md`.

Let me know if you'd like to add sections like:

- Loading the NYC Taxi parquet/CSV data
- Example queries
- Backup & restore instructions
- Environment variable overrides
- Healthcheck configuration

Just tell me what direction you want to extend it!