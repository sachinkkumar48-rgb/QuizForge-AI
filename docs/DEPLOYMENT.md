# Project TITAN - Production Infrastructure & HTTPS Deployment Foundation

## Overview

This document details the production reverse proxy architecture and HTTPS deployment foundation for Project TITAN (QuizForge AI backend).
The application is currently configured for HTTP reverse proxy operation over port 80 while containing all production security headers, ACME webroot challenge paths, and HTTPS blueprints for seamless future domain attachment and SSL migration.

---

## 1. Network Topology & Firewall Requirements

```
[ Internet ] ---> (Port 80: HTTP / Port 443: HTTPS) ---> [ Nginx Reverse Proxy Container ]
                                                                 |
                                                       (Network: titan_internal)
                                                                 |
                                                         (Port 8000: HTTP)
                                                                 v
                                                     [ FastAPI Backend Container ]
```

### Oracle Cloud Infrastructure (OCI) Security List & Firewall Rules

To enable external access for web traffic and automated ACME SSL certificate issuance, ensure the following ingress security rules are configured in the OCI Virtual Cloud Network (VCN) Security List:

| Stat | Source CIDR | IP Protocol | Source Port | Destination Port | Description |
|---|---|---|---|---|---|
| **Ingress** | `0.0.0.0/0` | TCP (6) | All | `80` | HTTP Traffic & ACME Challenge |
| **Ingress** | `0.0.0.0/0` | TCP (6) | All | `443` | Secure HTTPS Traffic |
| **Egress** | `0.0.0.0/0` | All | All | All | Outbound Traffic (Package updates, Gemini API) |

*Instance OS Firewall (iptables / ufw on Oracle Linux / Ubuntu):*
```bash
sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp
sudo firewall-cmd --reload
```

---

## 2. Production Security Headers

The Nginx reverse proxy enforces the following security headers across all responses:

- `X-Frame-Options: DENY` (Prevents clickjacking attacks)
- `X-Content-Type-Options: nosniff` (Prevents MIME-type sniffing)
- `X-XSS-Protection: 1; mode=block` (Enforces browser XSS filtering)
- `Referrer-Policy: strict-origin-when-cross-origin` (Protects referrer data)
- `Strict-Transport-Security: max-age=31536000; includeSubDomains` (Enforced once HTTPS is active)

---

## 3. Future HTTPS Migration Procedure (When Domain is Acquired)

When a domain name (e.g. `api.quizforge.ai`) is purchased and pointed to the OCI instance public IP address, follow these steps to enable HTTPS:

### Step 1: Provision SSL Certificates via Certbot ACME Webroot

Run Certbot in webroot mode targeting the shared ACME challenge directory:

```bash
docker run --rm \
  -v certbot_etc:/etc/letsencrypt \
  -v certbot_www:/var/www/certbot \
  certbot/certbot certonly --webroot \
  -w /var/www/certbot \
  -d api.quizforge.ai \
  --email admin@quizforge.ai \
  --agree-tos \
  --no-eff-email
```

### Step 2: Update `docker-compose.yml`

Uncomment port `443` and volume mappings in `docker-compose.yml`:

```yaml
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
      - certbot_etc:/etc/letsencrypt:ro
      - certbot_www:/var/www/certbot:ro
```

### Step 3: Enable HTTPS Server Block & HTTP Redirect in `nginx.conf`

1. Replace `YOUR_DOMAIN.COM` in `nginx.conf` with your actual domain (e.g. `api.quizforge.ai`).
2. Uncomment the `return 301 https://$host$request_uri;` line inside the Port 80 server block.
3. Uncomment the Port 443 HTTPS server block.

### Step 4: Restart Containers & Test Renewal

```bash
docker compose up -d --force-recreate nginx
```

Automated Certificate Renewal Cronjob:
```bash
0 3 * * * docker run --rm -v certbot_etc:/etc/letsencrypt -v certbot_www:/var/www/certbot certbot/certbot renew --quiet && docker exec titan_nginx nginx -s reload
```
