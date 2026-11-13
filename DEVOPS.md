# DEVOPS.md — TaskOps Full-Stack Deployment

**Candidate:** Prajwal Ganorkar
**Stack:** Django (REST API) · React + Vite + TypeScript · Docker (multi-stage, non-root) · Docker Compose · Jenkins · GitHub Actions · Docker Hub · Terraform · AWS EC2

| Item | Link |
|---|---|
| GitHub repository | GITHUB_REPO_URL_HERE |
| Deployed application | DEPLOYED_URL_HERE |
| Screenshots / evidence (Drive) | DRIVE_URL_HERE |

---

## 1. Architecture

```
Browser ──80──▶ frontend (nginx-unprivileged :8080) ──/api/*──▶ backend (gunicorn :8000) ──▶ SQLite (named volume)
```

* Only the frontend container is published. The backend port is reachable only inside the compose network.
* nginx serves the built React bundle and reverse-proxies `/api/` to `API_URL` (default `http://backend:8000`), so the browser never needs the backend address and CORS is not an issue.

## 2. Assumptions (decisions taken without asking, as requested)

1. The registry is **Docker Hub** (public repositories `<user>/taskops-backend`, `<user>/taskops-frontend`).
2. Jenkins runs on the same machine that has Docker (self-hosted). If `DEPLOY_HOST` is set, Jenkins deploys to an EC2 server over SSH instead.
3. SQLite on a Docker named volume is sufficient for a "Hello World"-scale app (no external DB).
4. TLS/HTTPS: port 443 is opened in the firewall as required, but no certificate is installed (no domain assumed). The app is served over HTTP on port 80.
5. Backend dependency range is `Django>=5.1,<6.0`; it can be raised to Django 6 by editing `backend/requirements.txt` — nothing else changes.
6. SSH (22) is restricted to the admin's own IP (`allowed_ssh_cidr`) rather than the whole internet; 80 and 443 are open to the world.

## 3. Prerequisites

Git, Docker Engine + Compose plugin. For the cloud part: AWS account + CLI credentials, Terraform ≥ 1.5, an existing EC2 key pair. For CI/CD: Docker Hub account (+ access token), Jenkins.

```bash
git --version && docker --version && docker compose version && terraform version
```

## 4. Setup guide — local

```bash
git clone GITHUB_REPO_URL_HERE
cd taskops-prajwal-ganorkar

cp .env.example .env
# put a real random secret in .env:
python -c "import secrets; print(secrets.token_urlsafe(50))"   # paste into DJANGO_SECRET_KEY

docker compose up --build -d
docker compose ps                       # both services Up, backend (healthy)
curl http://localhost/api/health/       # {"status":"ok","service":"taskops-api","version":"1.0.0"}
```

Open <http://localhost>. Stop with `docker compose down` (add `-v` to also delete data).

**Configuration (all via environment variables, see `.env.example`):** `DEBUG`, `DJANGO_SECRET_KEY`, `ALLOWED_HOSTS`, `API_URL` (frontend → backend), `HTTP_PORT`, `DOCKERHUB_USER`, `IMAGE_TAG`. No secret is stored in git; compose refuses to start if `DJANGO_SECRET_KEY` is missing.

Run backend tests without Docker: `cd backend && DEBUG=True python manage.py test`.

## 5. Container design (Phase 1)

| | Backend | Frontend |
|---|---|---|
| Build | multi-stage: `builder` creates a venv, `runtime` copies only the venv | multi-stage: `node:20-alpine` builds, `nginx-unprivileged` serves only `dist/` |
| Base | `python:3.12-slim` | `nginxinc/nginx-unprivileged:1.27-alpine` |
| User | `app` (uid 10001, nologin) | `nginx` (uid 101) – listens on 8080 |
| `.dockerignore` | yes | yes |
| Health check | `/api/health/` | `GET /` |

Verify non-root: `docker compose exec backend id` and `docker compose exec frontend id` (neither shows `uid=0`). Compare sizes with `docker images | grep taskops`. Containers also run with `no-new-privileges`.

## 6. CI/CD (Phase 2)

### 6.1 Jenkins (primary pipeline — `Jenkinsfile`)
Stages: **Checkout → Compose validation → Build images → Backend tests → Push to Docker Hub → Deploy**. Push and Deploy run only for `main`. Triggers: GitHub webhook (`githubPush`) with a 2-minute `pollSCM` fallback.

One-time Jenkins setup:
1. Install plugins: *Pipeline*, *Git*, *GitHub*, *Credentials Binding*, *SSH Agent* (only for the EC2 deploy).
2. The Jenkins agent must be able to run `docker` and `docker compose` (Jenkins in Docker: mount `/var/run/docker.sock` and install the docker CLI + compose plugin in the image).
3. **Manage Jenkins → Credentials**: add *Username with password* with ID **`dockerhub-creds`** (Docker Hub username + access token).
4. For cloud deploy also add an *SSH Username with private key* credential with ID **`ec2-ssh-key`** and set a global/job environment variable `DEPLOY_HOST=<EC2 public IP>`. Leave `DEPLOY_HOST` empty to deploy on the Jenkins host (the "standard"/local option).
5. Create a **Pipeline** job → *Pipeline script from SCM* → Git → repo URL → branch `*/main` → script path `Jenkinsfile`. Tick *GitHub hook trigger for GITScm polling*.
6. GitHub repo → **Settings → Webhooks** → `http://<jenkins-host>:8080/github-webhook/` (content type `application/json`, push events). If Jenkins is not publicly reachable, the `pollSCM` fallback still picks up pushes.
7. Push to `main` → watch the pipeline; images appear on Docker Hub and the stack is redeployed by `scripts/deploy.sh`.

### 6.2 GitHub Actions (`.github/workflows/ci.yml`)
Runs backend tests + frontend build on every push/PR to `main`, then (push to `main` only) builds and pushes both images to Docker Hub.
Repo **Settings → Secrets and variables → Actions**: secrets `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`. Optional EC2 deploy job: set variable `DEPLOY_ENABLED=true` and secrets `EC2_HOST`, `EC2_SSH_KEY`.

### 6.3 Deploy script
`scripts/deploy.sh` pulls the tagged images, runs `docker compose up -d`, waits for `/api/health/` through nginx and fails loudly (with logs) if the app does not become healthy. On a fresh machine it generates a random `DJANGO_SECRET_KEY` into `.env`.

Manual run (any machine with Docker): `DOCKERHUB_USER=<you> IMAGE_TAG=latest sh scripts/deploy.sh`

## 7. Infrastructure as Code (Phase 3 — `terraform/`)

Creates: security group, Ubuntu 22.04 EC2 instance (encrypted gp3 root volume, IMDSv2 only), Elastic IP.
Security group inbound: **80** and **443** from anywhere, **22** only from `allowed_ssh_cidr`. `user_data.sh` installs Docker + Compose at first boot.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars    # set key_name and allowed_ssh_cidr (your IP/32)
terraform init
terraform validate
terraform plan
terraform apply
terraform output application_url
```

First deploy to the server (or just push to `main` and let Jenkins/Actions do it):
```bash
scp -i <key>.pem docker-compose.yml scripts/deploy.sh ubuntu@<EC2_IP>:~/taskops/
ssh -i <key>.pem ubuntu@<EC2_IP> "cd ~/taskops && DOCKERHUB_USER=<you> IMAGE_TAG=latest sh deploy.sh"
```
Open `http://<EC2_IP>` and `http://<EC2_IP>/api/health/`. Remove everything with `terraform destroy`.

## 8. Troubleshooting log (Phase 4)

| # | Problem | Cause | Fix |
|---|---|---|---|
| 1 | `docker compose ps` printed an empty table and the site did not open | Containers had not been started in that folder/terminal (compose project is per directory) | Ran `docker compose up --build -d` from the project root, then re-checked `docker compose ps` until `backend (healthy)` |
| 2 | Backend returned `400 DisallowedHost` when the app was opened via the server IP | nginx forwarded the browser's `Host` header (the EC2 IP) and Django's `ALLOWED_HOSTS` only allowed `localhost,127.0.0.1,backend` | Stopped forwarding the browser Host; nginx now sends the internal `backend` host, so `ALLOWED_HOSTS` stays strict and works locally and on EC2 |
| 3 | `sqlite3.OperationalError: unable to open database file` after switching to a non-root user | The named volume mount was owned by root, the app runs as uid 10001 | Created `/app/data` in the image and `chown`ed it to the `app` user before `USER app`, so a fresh volume inherits the right ownership |
| 4 | nginx could not bind port 80 / ran as root | Stock `nginx` image needs root to bind 80 | Switched to `nginx-unprivileged` on port 8080 and mapped `80:8080` in compose |
| 5 | `terraform validate` failed with syntax errors | Attributes were separated with `;` (not valid HCL) | Rewrote the `.tf` files in standard multi-line HCL |
| 6 | Port 80 "already allocated" when Jenkins deployed locally | An older compose project from the same files was still running | `docker compose down` on the old project (compose project is now pinned with `name: taskops`) |
| 7 | CRLF line endings broke shell scripts on Windows checkout | Git auto-converted LF → CRLF | Added `.gitattributes` forcing LF, and used inline `CMD` instead of a script file for the container entrypoint |

## 9. Evidence checklist

Save real screenshots in `screenshots/` (see `screenshots/README.txt`): dashboard, create item, `/api/health/`, `docker compose ps`, GitHub Actions run, Jenkins pipeline, Docker Hub repo, deployed URL. Run `sh scripts/capture-evidence.sh` to also save a text log (compose status, health response, `id` of each container, image sizes).

## 10. Security notes

* No secrets in git: `.env` is git-ignored, `.env.example` holds only placeholders, CI credentials live in Jenkins/GitHub secrets, Terraform state and `terraform.tfvars` are git-ignored.
* Both containers run as non-root; backend port not published; `no-new-privileges` enabled.
* Django refuses to start without `DJANGO_SECRET_KEY` unless `DEBUG=True`.
* Known limits (demo scope): SQLite, no authentication, no TLS certificate yet (add a domain + Let's Encrypt/ALB for production).
