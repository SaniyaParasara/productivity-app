# Productivity Tips (Flask + Docker + Jenkins CI/CD)

Simple Flask app that shows random productivity tips. Includes Dockerfile and Jenkinsfile.

## Run locally (Docker)
```bash
docker build -t productivity-app:local .
docker run -p 8000:8000 productivity-app:local
# open http://localhost:8000
