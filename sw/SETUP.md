Here is an **updated, clean, and complete `README.md`** file that you can drop directly into your project root (`data-engineering-zoomcamp/`).

It includes:
- Clear setup instructions for **PostgreSQL + pgAdmin**
- Separate instructions for **starting Kestra** (recommended as a separate compose file)
- Step-by-step guidance for both single-command and split-compose approaches
- Useful commands, connection details, and troubleshooting
- Folder structure recommendation
- Security notice

Copy-paste the content below into `README.md`:

```markdown
# Data Engineering Zoomcamp – Local Development Environment

This repository contains a complete local setup for the **Data Engineering Zoomcamp** using Docker Compose.

It includes:
- **PostgreSQL** – for storing NYC Taxi data
- **pgAdmin** – web-based database management
- **Kestra** – modern workflow orchestration (optional but highly recommended for later modules)

## Project Structure (Recommended)

```
data-engineering-zoomcamp/
├── README.md
├── docker-compose-postgres.yml     # PostgreSQL + pgAdmin
├── docker-compose-kestra.yml       # Kestra (connects to PostgreSQL)
├── postgres-init/
│   └── 01-create-kestra-db.sql     # Creates the `kestra` database
└── flows/                          # (optional) Place your Kestra YAML flows here
```

## Requirements

- Docker Desktop (or Docker + Docker Compose)
- At least 4–6 GB RAM available
- ~5–10 GB free disk space

## 1. PostgreSQL + pgAdmin Setup

### docker-compose-postgres.yml

```yaml
version: "3.8"

services:
  db:
    container_name: postgres
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: ny_taxi
    ports:
      - "5433:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./postgres-init:/docker-entrypoint-initdb.d
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  pgadmin:
    container_name: pgadmin
    image: dpage/pgadmin4:latest
    restart: unless-stopped
    environment:
      PGADMIN_DEFAULT_EMAIL: pgadmin@pgadmin.com
      PGADMIN_DEFAULT_PASSWORD: pgadmin
    ports:
      - "8081:80"
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    depends_on:
      - db

volumes:
  pgdata:
  pgadmin_data:
```

### Create the init script (required for Kestra)

```bash
mkdir -p postgres-init
```

Create file `postgres-init/01-create-kestra-db.sql`:

```sql
CREATE DATABASE kestra;
```

### Start PostgreSQL + pgAdmin

```bash
docker compose -f docker-compose-postgres.yml up -d
```

Wait 30–60 seconds, then check:

```bash
docker compose -f docker-compose-postgres.yml ps
```

Open pgAdmin:  
**http://localhost:8081**  
Email: `pgadmin@pgadmin.com`  
Password: `pgadmin`

### PostgreSQL Connection Details

From your host machine (laptop / scripts):

| Parameter       | Value                        |
|-----------------|------------------------------|
| Host            | `localhost`                  |
| Port            | `5433`                       |
| Database        | `ny_taxi`                    |
| Username        | `postgres`                   |
| Password        | `postgres`                   |

Connection string example:
```
postgresql://postgres:postgres@localhost:5433/ny_taxi
```

## 2. Kestra Setup (Recommended: Separate File)

### docker-compose-kestra.yml

```yaml
version: "3.8"

services:
  kestra:
    image: kestra/kestra:latest
    container_name: kestra
    restart: unless-stopped
    pull_policy: always
    user: "root"
    ports:
      - "8080:8080"
    volumes:
      - kestra_storage:/app/storage
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp:/tmp
    command: server standalone
    environment:
      KESTRA_CONFIGURATION: |
        kestra:
          server:
            basic-auth:
              enabled: true
              username: admin
              password: kestra123           # ← CHANGE THIS !!!
          repository:
            type: postgres
          storage:
            type: local
            local:
              basePath: "/app/storage"
          queue:
            type: postgres
          url: "http://localhost:8080/"
          tasks:
            tmpDir:
              path: "/tmp/kestra-wd"
        datasources:
          postgres:
            url: jdbc:postgresql://host.docker.internal:5432/kestra
            driverClassName: org.postgresql.Driver
            username: postgres
            password: postgres

volumes:
  kestra_storage:
```

**Note:**  
- Use `host.docker.internal` (macOS/Windows) or `172.17.0.1` (Linux) to connect to the local PostgreSQL.

### Start Kestra

First ensure PostgreSQL is running, then:

```bash
docker compose -f docker-compose-kestra.yml up -d
```

Open Kestra UI:  
**http://localhost:8080**  
Username: `admin`  
Password: `kestra123`

## Quick Commands Reference

```bash
# Start PostgreSQL + pgAdmin
docker compose -f docker-compose-postgres.yml up -d

# Start Kestra
docker compose -f docker-compose-kestra.yml up -d

# Stop everything
docker compose -f docker-compose-postgres.yml down
docker compose -f docker-compose-kestra.yml down

# Stop + delete data (careful!)
docker compose -f docker-compose-postgres.yml down -v

# View logs
docker compose -f docker-compose-postgres.yml logs -f
docker compose -f docker-compose-kestra.yml logs -f kestra

# PostgreSQL shell
docker exec -it postgres psql -U postgres -d ny_taxi

# Check databases
docker exec -it postgres psql -U postgres -c "\l"
```

## Troubleshooting

- **Kestra says "database kestra does not exist"** → Make sure `postgres-init/01-create-kestra-db.sql` exists and PostgreSQL was started **after** creating it. Or manually run `CREATE DATABASE kestra;` in psql.
- **pgAdmin / Kestra not loading** → Check port conflicts (8080, 8081, 5433)
- **Connection refused** → Wait 60–90 seconds after starting
- **Port in use** → Change ports in the compose files

## Security Notice

These credentials are **ONLY for local development**:

```
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
PGADMIN_DEFAULT_PASSWORD=pgadmin
KESTRA_ADMIN_PASSWORD=kestra123
```

**Do NOT use these in production or expose ports publicly.**

---

Happy learning with Data Engineering Zoomcamp! 🚀  
Questions? Feel free to open an issue or ask in the course Slack.
```

This version is **self-contained**, **well-organized**, and **ready to use**.

Let me know if you want:
- A **combined single compose file** version instead
- Sections for **loading NYC Taxi data** or **example Kestra flows**
- A shorter / more minimal version