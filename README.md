# AWS Cloud Native Order Platform

A cloud-native reference application for learning and demonstrating modern Java,
DevOps, Kubernetes and AWS practices. The project evolves incrementally from local
Spring Boot services to a production-oriented AWS/EKS architecture.

## Current Status

**Week 1 / Day 1 — project and development environment initialized.**

- Four executable Spring Boot service skeletons with configured ports and health endpoints.
- Shared Maven build, Maven wrapper and Java 25 enforcement.
- Local PostgreSQL environment with separate service databases and Flyway migrations.
- Development scripts, startup tests and Git exclusions for local configuration and secrets.

During initialization, the Maven build and all four HTTP health tests passed.
All services also reported `UP` against the local environment, and all three
PostgreSQL migrations completed successfully.

Domain APIs, Kafka consumers and cloud deployments are planned. Deployment,
infrastructure and monitoring directories currently provide scaffolding.

## Quick Start

### Prerequisites

- JDK 25
- Git
- Docker with Docker Compose and a running Docker daemon
- Bash, Python 3 and curl for the development scripts
- Internet access for the first Maven and Docker downloads

Maven does not need to be installed separately: the wrapper provides Maven 3.9.16.
On macOS, the development script selects JDK 25 automatically. On other systems,
set `JAVA_HOME` to a JDK 25 installation and add its `bin` directory to `PATH`.

### Prepare and Build

Run from the repository root:

```bash
./scripts/dev.sh setup
./scripts/dev.sh doctor
./scripts/dev.sh build
./scripts/dev.sh db-up
```

`setup` creates an ignored `.env` with a random PostgreSQL password and preserves
an existing file. If port 5432 is occupied, set `POSTGRES_PORT=5433` (or another free
port) in `.env` before running `db-up`.

### Start the Services

Run each command in a separate terminal:

```bash
./scripts/dev.sh run customer-service
./scripts/dev.sh run product-service
./scripts/dev.sh run order-service
./scripts/dev.sh run notification-service
```

Customer, Product and Order require PostgreSQL. Notification can run independently.
Kafka is not required at this stage.

### Verify and Stop

With all four services running:

```bash
./scripts/dev.sh smoke
```

The smoke check expects every service's `/actuator/health` endpoint to report `UP`.
Readiness is available at `/actuator/health/readiness` on the same port.

Stop each service with Ctrl+C, then stop PostgreSQL:

```bash
./scripts/dev.sh db-down
```

The database volume is preserved.

## Services

| Service / Maven artifact | Port | Responsibility | Java package |
| --- | ---: | --- | --- |
| `customer-service` | 8081 | Customer management | `com.example.cloudnative.customer` |
| `product-service` | 8082 | Product catalog | `com.example.cloudnative.product` |
| `order-service` | 8083 | Order processing | `com.example.cloudnative.order` |
| `notification-service` | 8084 | Event-driven notifications | `com.example.cloudnative.notification` |

Each service resides in `services/<artifact>/`, uses JAR packaging and defines its
port in `src/main/resources/application.yaml`. Artifact and application names match.
Notification is intended to become the first pure event consumer and has no
JPA or PostgreSQL dependency.

### Dependencies

All services include Spring Web, Spring Boot Actuator and Lombok.

| Additional dependencies | Customer | Product | Order | Notification |
| --- | :---: | :---: | :---: | :---: |
| Spring Data JPA | ✓ | ✓ | ✓ | — |
| Validation | ✓ | ✓ | ✓ | — |
| PostgreSQL Driver | ✓ | ✓ | ✓ | — |
| Flyway Migration | ✓ | ✓ | ✓ | — |
| Spring for Apache Kafka | — | — | ✓ | ✓ |

Kafka dependencies are present in Order and Notification; broker configuration,
listeners and event processing are deferred. Customer's planned additions are
springdoc-openapi and Testcontainers.

## Technology Stack

| Area | Current setup | Planned additions |
| --- | --- | --- |
| Application | Java 25, Spring Boot 4.1.1, Maven 3.9.16 | Domain APIs, springdoc-openapi |
| Persistence | PostgreSQL 17.6, Spring Data JPA, Flyway | Domain schema migrations |
| Messaging | Spring for Apache Kafka dependencies | Apache Kafka broker, consumers, AWS MSK |
| Local development | Git, Docker, Docker Compose | Application container images |
| Testing | HTTP startup tests, test-scoped H2 | Testcontainers |
| Deployment | Directory scaffolding | Kubernetes, Helm, Terraform, AWS, EKS |
| Delivery | — | GitHub Actions, Argo CD |
| Observability | Actuator health endpoints | Prometheus, Grafana, OpenTelemetry |

The Maven group is `com.example.cloudnative`. Versions are defined in the root
[pom.xml](pom.xml), [Maven wrapper configuration](.mvn/wrapper/maven-wrapper.properties)
and [compose.yaml](compose.yaml).

## Configuration

### Local Environment

[.env.example](.env.example) documents the variables without containing credentials.
The development script loads `.env` when starting PostgreSQL or a database-backed
service.

| Variable | Default / source | Purpose |
| --- | --- | --- |
| `POSTGRES_USER` | `orderplatform` | Local database user |
| `POSTGRES_PASSWORD` | Generated by `setup` | Required database password |
| `POSTGRES_PORT` | `5432` | Host port used by Compose and service JDBC URLs |
| `DB_URL` | Service-specific JDBC URL | Optional override for an individual service |

PostgreSQL is exposed on `127.0.0.1` only. Port 9092 is reserved for future Kafka
use; no Kafka broker is started by Compose.

### Databases and Migrations

| Service | Database | Application schema |
| --- | --- | --- |
| Customer | `customer_db` | `customer` |
| Product | `product_db` | `product` |
| Order | `order_db` | `order_service` |

Compose initializes the databases when its volume is first created. Flyway applies
migrations from each service's `src/main/resources/db/migration/` directory.
The initial migration creates the application schema; domain tables will follow.
Hibernate uses `ddl-auto: validate`, and Open Session in View is disabled.

Changing `.env` does not update credentials in an existing database volume. If you
change the password after initialization, update the PostgreSQL role password too.

## Development and Verification

| Command | Purpose |
| --- | --- |
| `./scripts/dev.sh setup` | Create local configuration without overwriting it |
| `./scripts/dev.sh doctor` | Check Java, Maven, Git, Docker and Compose |
| `./scripts/dev.sh build` | Test all modules and package executable JARs |
| `./scripts/dev.sh db-up` | Start PostgreSQL and wait for its health check |
| `./scripts/dev.sh run <service>` | Start one service |
| `./scripts/dev.sh smoke` | Check all four running services |
| `./scripts/dev.sh db-down` | Stop Compose while retaining database data |

The build runs one HTTP health test per service. Database-backed tests use H2 in
PostgreSQL mode and run the initial Flyway migration. These tests do not require
Docker; PostgreSQL compatibility is checked by starting the real local environment
and running the smoke check.

### IntelliJ IDEA

Open the root `pom.xml` as a Maven project. Select JDK 25 for the project SDK and
the Maven runner/importer. Use the development script to start services, or supply
the local environment variables in your IDE run configurations, including
`POSTGRES_PORT` if you changed it.

### Common Setup Issues

| Symptom | Action |
| --- | --- |
| Maven uses another Java version | Use `dev.sh` or set `JAVA_HOME` to JDK 25; also check the IDE Maven runner |
| Docker is unavailable | Start the Docker daemon, then rerun `doctor` |
| PostgreSQL port is occupied | Set a free `POSTGRES_PORT` in `.env`, then rerun `db-up` |
| Database-backed service cannot start | Check PostgreSQL health and the credentials, port and optional `DB_URL` |
| Smoke check fails | Start all four services and inspect the failing service's logs |

## Repository Structure

```text
aws-cloud-native-order-platform/
├── services/
│   ├── customer-service/       # Each service contains pom.xml and src/
│   ├── product-service/
│   ├── order-service/
│   └── notification-service/
├── infrastructure/
│   └── terraform/
├── deployment/
│   ├── kubernetes/
│   ├── helm/
│   └── argocd/
├── monitoring/
├── docker/
│   └── postgres/
│       └── init-databases.sh
├── docs/
│   ├── architecture/
│   ├── adr/
│   ├── security/
│   └── troubleshooting/
├── scripts/
│   └── dev.sh
├── .mvn/
│   └── wrapper/
├── mvnw
├── mvnw.cmd
├── pom.xml
├── compose.yaml
├── .env.example
├── .gitignore
└── README.md
```

Empty directories are retained in Git with `.gitkeep` files.

## Secrets and Git Hygiene

**Never commit AWS credentials, database passwords, API keys, private keys or other
secrets.** Keep local credentials in the ignored `.env`; commit only credential-free
examples.

[.gitignore](.gitignore) excludes Maven build output, IDE files, OS metadata, logs,
local environment files, `application-local` configuration, Terraform state and
variable files, AWS credential directories, and `.pem` / `.key` files.

## Roadmap

Docker → Kafka → Kubernetes → Helm → Terraform → AWS → EKS → MSK → CI/CD → GitOps
→ Observability → Security
