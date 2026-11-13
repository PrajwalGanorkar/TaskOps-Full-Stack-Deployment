# TaskOps — Engineering Operations Dashboard
**Author:** Prajwal Ganorkar

TaskOps is a practical full-stack engineering operations dashboard. It lets a small team create and track work items, set priorities, update delivery status, search tasks, and monitor operational metrics.

## Features
- React + TypeScript dashboard with responsive dark UI
- Django REST-style JSON API with create, list, update and delete operations
- Metrics endpoint for total, backlog, in-progress, blocked and completed work
- SQLite persistence using a Docker named volume
- Docker Compose orchestration; Nginx serves the SPA and reverse proxies `/api`
- GitHub Actions backend test + frontend build checks
- Jenkins pipeline for container build and compose validation
- Optional AWS EC2 provisioning with Terraform

## Run locally with Docker
```bash
cp .env.example .env
docker compose up --build -d
docker compose ps
```
Open http://localhost. API health: http://localhost/api/health/

## API
| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/health/` | Service health |
| GET | `/api/items/` | List/search/filter work items |
| POST | `/api/items/create/` | Create work item |
| PATCH | `/api/items/<id>/` | Update fields/status |
| DELETE | `/api/items/<id>/` | Delete work item |
| GET | `/api/metrics/` | Dashboard counters |

Example create body:
```json
{"title":"Deploy billing API","service":"Payments","description":"Release to staging","priority":"High","owner":"Prajwal Ganorkar"}
```

## Project structure
```text
backend/                 Django API and tests
frontend/                React + Vite UI
.github/workflows/       GitHub Actions CI
terraform/               Optional AWS EC2 infrastructure
docker-compose.yml       Local/host orchestration
Jenkinsfile              Jenkins build pipeline
DEVOPS.md                Full implementation and deployment guide
screenshots/             Evidence capture folder
```

## Before public deployment
Set a strong `DJANGO_SECRET_KEY`, restrict SSH CIDR, configure HTTPS with a domain and TLS certificate, and use managed database/backups for production. This assessment build is a demo deployment, not a hardened multi-user production system.
