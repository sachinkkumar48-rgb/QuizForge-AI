# Project TITAN - Enterprise Observability & SRE Architecture

**Version**: 1.0.0  
**Document Owner**: Principal SRE Engineer  
**Scope**: Enterprise Monitoring, Prometheus, Grafana, Loki, OpenTelemetry  

---

## 1. Overview & Architecture

Project TITAN's observability stack provides complete visibility into application performance, container resource utilization, distributed tracing, structured logging, and automated alerting.

$$\text{FastAPI / Flutter Client} \xrightarrow[\text{JSON Logs}]{\text{X-Request-ID}} \text{Loki} \quad \Big| \quad \text{FastAPI / Container} \xrightarrow{\text{Metrics}} \text{Prometheus} \xrightarrow{\text{Alerts}} \text{Alertmanager / Grafana}$$

---

## 2. Prometheus Metrics & Health Scraping

Prometheus scrapes metrics from the backend every 15 seconds (`prometheus.yml`):
- **`/metrics`**: Exposes request rates, response status counters, and execution durations.
- **`/health` & `/ready`**: Continuously monitors container liveness and dependency readiness.
- **Container Metrics**: Scrapes CPU, memory, network I/O, and disk usage.

---

## 3. Grafana Dashboard Blueprint

The Grafana monitoring stack provides 6 pre-configured operational dashboards:

1. **Application Overview Dashboard**: System uptime, HTTP status code breakdown, active request rate, P50/P95/P99 latency trends.
2. **Infrastructure Dashboard**: Container CPU utilization %, Memory quota utilization %, network I/O throughput, disk space.
3. **GARUDA AI Provider Dashboard**: Socratic turn execution latency, provider invocation success rate (Gemini/OpenAI/Claude/LocalLLM), prompt token throughput.
4. **Quiz Engine & PDF Workflow Dashboard**: PDF ingestion latency, chunking duration, question generation batch processing time.
5. **Sync Engine Dashboard**: Offline sync queue size, Cloud sync transfer duration, database mutation latency.
6. **Error & Incident Dashboard**: HTTP 5xx error distribution, top failing endpoints, exception trace counts.

---

## 4. Loki Structured Logging & Tracing Correlation

- **Structured JSON Format**: All backend logs are emitted in JSON format containing timestamp, log level, module, message, and context.
- **Request Tracing Correlation**: Every API request generates or preserves a unique `X-Request-ID` header.
- **Loki Log Aggregation**: Loki indexes logs by `app=titan_backend`, `environment`, and `log_level`, allowing instant log filtering by `X-Request-ID`.
- **Sensitive Data Sanitization**: Passwords, API keys, and JWT tokens are automatically replaced with `***REDACTED***` prior to log emission.

---

## 5. OpenTelemetry Distributed Tracing

- **Trace Context Propagation**: Outgoing requests propagate W3C `traceparent` and `X-Request-ID` headers across service boundaries.
- **Performance Spans**: Subsystem execution stages (PDF processing, vector search, Socratic reasoning) create explicit OpenTelemetry spans to trace microsecond latencies.

---

## 6. Alerting Threshold Matrix

| Alert Name | Condition | Severity | Action |
| :--- | :--- | :--- | :--- |
| **`HighErrorRate`** | HTTP 5xx rate $> 1.0\%$ over 5 min | Critical | PagerDuty / Slack Alert |
| **`HighP95Latency`** | P95 latency $> 500\text{ ms}$ over 5 min | Warning | Dev Notification |
| **`ContainerDown`** | Backend unreachable $> 1\text{ min}$ | Critical | Immediate Incident Trigger |
| **`HealthCheckFailed`** | `/health` non-200 status | Critical | Container Auto-Restart |
| **`ReadinessCheckFailed`**| `/ready` non-200 status | Warning | Traffic Shift |
| **`HighMemoryUsage`** | Memory $> 85\%$ limit | Warning | Scaled Allocation Check |
| **`HighCPUUsage`** | CPU $> 90\%$ cap | Warning | Compute Autoscaling Check |
