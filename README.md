# devops-lab: an orders pipeline to learn DevOps on

A small but realistic app whose real purpose is to give every DevOps tool a genuine job to do.

**Skills practised:** Linux, shell scripting, Maven, Docker, Nginx, Tomcat, Kafka + Kafka Connect,
Terraform, Ansible, Jenkins, Kubernetes, Google Cloud (GCP).

## What the app does

```
Browser ──> Nginx ──> Tomcat (Spring Boot WAR) ──> PostgreSQL   (orders table)
 (React)   :8080          │  ▲
                          │  └── consumer (same app) reads orders.created
                          ▼
                        Kafka ── orders.created ──> consumer marks the order PROCESSED
                          │
                          └────── orders.processed ──> Kafka Connect (JDBC sink) ──> orders_report table
```

1. You place an order in the React UI.
2. The API saves it (`CREATED`) and publishes `orders.created` to Kafka. It replies `202 Accepted`.
3. A Kafka consumer picks it up, marks it `PROCESSED`, and publishes `orders.processed`.
4. Kafka Connect's JDBC sink copies `orders.processed` into a `orders_report` table, with no code.
5. The UI polls and shows each order moving from _Received_ to _Processed_.

## Repo layout

| Path                 | What lives there                                         | Phase |
| -------------------- | -------------------------------------------------------- | ----- |
| `backend/`           | Spring Boot 3.5, Java 21, Maven, WAR + Tomcat Dockerfile | 1, 2  |
| `frontend/`          | React (Vite), Nginx config template, Dockerfile          | 1, 2  |
| `kafka/`             | Kafka Connect image and connector definitions            | 2     |
| `docker-compose.yml` | The whole stack locally                                  | 2     |
| `scripts/`           | Shell scripts (starts with `smoke-test.sh`)              | 3     |
| `terraform/`         | GCP infrastructure                                       | 4, 7  |
| `ansible/`           | Server configuration                                     | 5     |
| `Jenkinsfile`        | CI/CD pipeline (added in Phase 6)                        | 6, 8  |
| `k8s/`               | Helm chart / manifests for GKE                           | 7     |
| `docs/`              | One lab guide per phase, **start with `00-roadmap.md`**  | all   |

## Quick start (needs Docker with Compose, and `jq` for the smoke test)

```bash
make up        # build images and start everything (first build takes a few minutes)
make smoke     # place an order and verify it travels the whole pipeline
open http://localhost:8080
make help      # every other shortcut
```

Prefer to build up gradually? Follow [`docs/phase-1-app-and-maven.md`](docs/phase-1-app-and-maven.md) first.

## Ports

| Port  | Service                                                       |
| ----- | ------------------------------------------------------------- |
| 8080  | Nginx (the UI and `/api`)                                     |
| 8081  | Tomcat directly (debugging)                                   |
| 5432  | PostgreSQL                                                    |
| 29092 | Kafka, for tools on your laptop (containers use `kafka:9092`) |
| 8083  | Kafka Connect REST API                                        |
| 5173  | Vite dev server (Phase 1 only)                                |

## Versions used

Java 21, Spring Boot 3.5.x (Tomcat 10.1), Tomcat image `10.1-jdk21-temurin`, Kafka 3.9 (KRaft),
Confluent Connect 7.9 with JDBC connector 10.8.2, PostgreSQL 17, Node 22, Vite, React 19, Nginx 1.27.
Bump to the latest patch releases when you start; the structure does not change.
