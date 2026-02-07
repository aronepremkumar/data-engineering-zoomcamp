Here is the clean, single-block content for your `setup.md` file. I’ve refined the formatting for better readability in GitHub or VS Code while keeping all your technical configurations intact.

Simply copy the entire block below:

```markdown
# Setup Guide – Data Engineering Zoomcamp

This guide provides a complete local development environment using Docker. By the end of this setup, you will have:
* **PostgreSQL 17** – Data storage (NYC Taxi data).
* **pgAdmin 4** – Graphical interface for database management.
* **Kestra** – Workflow orchestration and ELT pipeline management.

---

## 🛠 Prerequisites
* **Docker Desktop** (or Docker Engine + Compose for Linux).
* **Resources:** Allocate at least 4GB of RAM to Docker.
* **Storage:** ~5-10GB free disk space.

---

## 🚀 Installation Steps

### 1. Create Project Directory
```bash
mkdir data-engineering-zoomcamp
cd data-engineering-zoomcamp

```

### 2. Create the Docker Compose File

Create a file named `docker-compose.yml` and paste the following configuration:

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
      - vol-pgdata:/var/lib/postgresql/data
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
      - vol-pgadmin_data:/var/lib/pgadmin
    depends_on:
      - db

  kestra:
    image: kestra/kestra:latest
    container_name: kestra
    restart: unless-stopped
    pull_policy: always
    user: "root"
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8080:8080"
    volumes:
      - kestra_storage:/app/storage
      - /var/run/docker.sock:/var/run/docker.sock
      - /tmp:/tmp
    environment:
      KESTRA_CONFIGURATION: |
        kestra:
          server:
            basic-auth:
              enabled: true
              username: admin
              password: kestra123
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
            url: jdbc:postgresql://db:5432/kestra
            driverClassName: org.postgresql.Driver
            username: postgres
            password: postgres

volumes:
  vol-pgdata:
  vol-pgadmin_data:
  kestra_storage:

```

### 3. Initialize Kestra Database

Kestra needs its own database within the Postgres instance. Run these commands to create the init script:

```bash
mkdir -p postgres-init
echo "CREATE DATABASE kestra;" > postgres-init/01-create-kestra-db.sql

```

### 4. Launch the Stack

```bash
docker compose up -d

```

*Wait a minute or two for images to download and services to initialize.*

---

## 🔗 Service Access

| Service | Access URL | Credentials |
| --- | --- | --- |
| **Kestra** | [http://localhost:8080](https://www.google.com/search?q=http://localhost:8080) | `admin` / `kestra123` |
| **pgAdmin** | [http://localhost:8081](https://www.google.com/search?q=http://localhost:8081) | `pgadmin@pgadmin.com` / `pgadmin` |

### Database Connection (Local Host)

To connect using an external tool (like DBeaver or Python):

* **Host:** `localhost`
* **Port:** `5433`
* **User/Pass:** `postgres` / `postgres`
* **DB:** `ny_taxi`

---

## 🛠 Useful Commands

| Command | Description |
| --- | --- |
| `docker compose ps` | Check if services are running |
| `docker compose logs -f` | Tail logs for all services |
| `docker compose down` | Stop services (preserves data) |
| `docker compose down -v` | Stop services and **delete all data** |
| `docker exec -it postgres psql -U postgres -d ny_taxi` | Open SQL shell in terminal |

---

## ❓ Troubleshooting

* **Port 8080/8081 in use:** Change the first number in the `ports` section of the yaml (e.g., `8082:80`).
* **Kestra login fails:** Ensure the `KESTRA_CONFIGURATION` block in the yaml is indented correctly.
* **Empty pgAdmin:** You must manually add a "New Server" in pgAdmin using the hostname `db`, port `5432`, and your postgres credentials.

