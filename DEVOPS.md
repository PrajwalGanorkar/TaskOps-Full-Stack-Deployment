# DEVOPS.md — TaskOps Full-Stack DevOps Assessment
**Candidate:** Prajwal Ganorkar  
**Application:** TaskOps Engineering Operations Dashboard  
**Stack:** React + TypeScript, Django, Docker, Nginx, GitHub Actions, Jenkins, AWS EC2, Terraform

## 1. Architecture
Browser → TCP 80 → Nginx frontend container → `/api/*` reverse proxy → Django/Gunicorn backend container → SQLite named volume. The backend port is internal to the Docker network; only Nginx is exposed publicly.

## 2. Prerequisites
Git, Docker Engine, Docker Compose plugin. For cloud deployment: AWS account, AWS CLI credentials, Terraform >= 1.5, an existing EC2 key pair. For CI: GitHub repository; Jenkins with Docker access is optional.

Verify:
```bash
git --version
docker --version
docker compose version
terraform version
```

## 3. Local execution
```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd Prajwal-Ganorkar
cp .env.example .env
# Replace DJANGO_SECRET_KEY with a random secret before sharing/deploying.
docker compose up --build -d
docker compose ps
curl -fsS http://localhost/api/health/
```
Expected health response:
```json
{"status":"ok","service":"taskops-api","version":"1.0.0"}
```
Open `http://localhost`. Create a work item, change its status and verify that dashboard metrics update. Data persists in the `taskops_data` Docker volume.

Stop:
```bash
docker compose down
```
Remove demo data only when intended:
```bash
docker compose down -v
```

## 4. Backend tests
```bash
cd backend
DEBUG=True python manage.py test
```
Tests cover API health, create/list behavior and metrics. The GitHub Actions workflow runs the backend test job and frontend production build on pushes and pull requests to `main`.

## 5. Container design
- Backend image: Python 3.12 slim, Gunicorn, non-root application user.
- Frontend image: multi-stage Node build and Nginx static hosting.
- Nginx forwards `/api/` to the backend service over the private Compose network.
- Docker named volume persists SQLite data.
- Backend health check gates frontend startup.
- `.gitignore` excludes environment files, Terraform state, private keys and build artifacts.

Build/run:
```bash
docker compose build
docker compose up -d
docker compose logs -f
```

## 6. GitHub repository setup
Create a new **public or private** GitHub repository named `taskops-prajwal-ganorkar`. From the project root:
```bash
git init
git branch -M main
git add .
git commit -m "Initial TaskOps full-stack DevOps assessment"
git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/taskops-prajwal-ganorkar.git
git push -u origin main
```
Replace the placeholder with the actual GitHub username and repository URL. Never commit `.env`, AWS credentials, SSH keys, or Terraform state. Add GitHub Actions secrets only if a later workflow explicitly consumes them.

## 7. Jenkins pipeline
`Jenkinsfile` checks out source, builds backend and frontend Docker images, and validates the Compose configuration. Configure a Jenkins Pipeline job using “Pipeline script from SCM”, branch `main`, script path `Jenkinsfile`. The Jenkins agent must have Docker Engine and Compose plugin installed and permission to run Docker commands. This pipeline performs CI validation; it does not claim to deploy automatically.

## 8. AWS EC2 deployment (manual)
1. Create an Ubuntu 22.04 EC2 key pair and note its name.
2. Set `allowed_ssh_cidr` in `terraform/terraform.tfvars` to your own public IP `/32`.
3. Provision:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit key_name and allowed_ssh_cidr
terraform init
terraform validate
terraform plan
terraform apply
terraform output application_url
```
4. SSH to the instance:
```bash
ssh -i <key-file.pem> ubuntu@<EC2_PUBLIC_IP>
```
5. Install/run the project:
```bash
sudo apt-get update
sudo apt-get install -y git docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker ubuntu
exit
# reconnect so group membership takes effect
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd taskops-prajwal-ganorkar
cp .env.example .env
nano .env
docker compose up --build -d
```
6. Open `http://<EC2_PUBLIC_IP>` and verify `http://<EC2_PUBLIC_IP>/api/health/`.

The Terraform security group exposes HTTP 80 and SSH 22 restricted to the configured CIDR. HTTPS is not configured; add a domain and TLS reverse proxy/certificate before production use. Do not expose the Django port.

Destroy demo infrastructure when finished:
```bash
terraform destroy
```

## 9. Evidence/screenshots checklist
Save genuine screenshots under `screenshots/`:
- `01-dashboard.png` — dashboard loaded in browser with API connected.
- `02-create-work-item.png` — create-item form or newly created task.
- `03-api-health.png` — `/api/health/` JSON response.
- `04-docker-compose-ps.png` — frontend and backend containers running.
- `05-github-actions.png` — successful CI workflow run.
- `06-jenkins-pipeline.png` — Jenkins stages (if Jenkins is configured).
- `07-deployed-application.png` — actual EC2-hosted application.

Do not fabricate deployment or pipeline evidence. Capture screenshots only after those steps succeed.

## 10. Submission values
- Candidate folder: `Prajwal-Ganorkar`
- GitHub repository: `<PASTE ACTUAL REPOSITORY URL>`
- Deployed application: `<PASTE ACTUAL EC2 URL>`
- Evidence Drive folder: `<PASTE GOOGLE DRIVE FOLDER URL>`
- Documentation: `DEVOPS.md`

## 11. Troubleshooting
| Symptom | Check |
|---|---|
| Frontend opens but API fails | `docker compose ps`; `docker compose logs backend frontend` |
| Backend health check fails | Verify Django migrations and `/api/health/` |
| Port 80 already in use | Stop the conflicting service or change host port mapping |
| EC2 page times out | Check EC2 security group inbound TCP 80 and instance status |
| SSH denied | Confirm key pair and source CIDR; use `chmod 400 <key>.pem` |
| GitHub Actions fails | Review Python test and Node build logs separately |

## 12. Security and limitations
This assessment uses a demo SQLite store and does not implement user authentication, role-based authorization, backups or TLS. For production, add authentication, PostgreSQL, HTTPS, secrets management, monitoring, backups and automated rollback. Use least-privilege cloud permissions.
