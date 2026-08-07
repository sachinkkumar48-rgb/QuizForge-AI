# Project TITAN - Production Rollback Strategy & Protocol

**Version**: 1.0.0  
**Document Owner**: Principal DevOps Engineer  
**Scope**: Project TITAN Production & Staging Environments  

---

## 1. Overview & Objective

This document defines the automated and manual rollback protocols for Project TITAN deployments across Oracle Cloud, Docker Compose, Nginx, and FastAPI backend services.

The primary objective is to maintain zero downtime and guarantee maximum platform availability during production releases.

---

## 2. Automated Rollback Triggers

An automated rollback is triggered immediately if any of the following threshold conditions are met within 10 minutes of deployment:

| Trigger Metric | Threshold Condition | Evaluation Method | Action |
| :--- | :--- | :--- | :--- |
| **Liveness Check (`/health`)** | 3 consecutive failures | Nginx Health Monitor | Immediate Container Revert |
| **Readiness Check (`/ready`)** | Timeout (> 5s) or 503 response | Docker Healthcheck Probe | Immediate Container Revert |
| **5xx Error Rate** | $> 1.0\%$ over 5-minute window | Prometheus / Nginx Logs | Automatic Traffic Shift |
| **High Latency** | P95 latency $> 500\text{ ms}$ for 5 min | OpenTelemetry Metrics | Traffic Revert |

---

## 3. Container & Nginx Rollback Procedure

### Step 1: Revert Container Image Tag
If a new release `v1.2.0` fails validation, instantly revert the backend image tag in `.env` or `docker-compose.yml` to the last known stable tag (e.g. `v1.1.9`):

```bash
# Set image version to last stable release
export TITAN_IMAGE_TAG=sha-previous_stable_hash

# Relaunch services using cached stable image
docker compose up -d --no-build backend
```

### Step 2: Nginx Proxy Reload
Reload Nginx configuration seamlessly without dropping active connections:

```bash
docker compose exec titan_nginx nginx -s reload
```

---

## 4. State & Database Migration Rollback

1. **State Preservation**: The local database engine maintains backward compatibility.
2. **Schema Rollback**: If a database schema update fails during initialization, the container health check fails startup, preventing Nginx traffic from routing to the un-migrated instance.

---

## 5. Emergency Rollback Checklist

- [ ] Confirm active error logs in Nginx `/var/log/nginx/error.log`.
- [ ] Verify previous stable Git SHA and Docker image digest.
- [ ] Execute `docker compose up -d backend` using last stable image.
- [ ] Verify `/health` returns `{"status": "ok"}`.
- [ ] Verify `/ready` returns `{"status": "ready"}`.
- [ ] Notify DevOps / CTO engineering channel of rollback completion.
