# Project TITAN — Direct Antigravity + AgentMemory Integration

## Purpose
AgentMemory provides a persistent context layer for Project TITAN directly inside the **Antigravity IDE** environment. It eliminates repeated repository discovery and architectural re-explanation across implementation sessions by storing durable, concise lessons, decisions, and system rules.

## System Architecture

```
+-------------------------------------------------------------+
|                      Antigravity IDE                        |
|                                                             |
|   +-----------------------+     +-----------------------+   |
|   |  .gemini/config/mcp   |     |   Antigravity Skills  |   |
|   |    mcp_config.json    |     |  .agents/skills/agent |   |
|   +-----------+-----------+     +-----------+-----------+   |
+---------------|-----------------------------|---------------+
                | stdio (MCP)                 | REST HTTP (:3111)
                v                             v
+-------------------------------------------------------------+
|                     AgentMemory Daemon                      |
|                                                             |
|   +-----------------------+     +-----------------------+   |
|   |   standalone.mjs MCP  |     |  REST API Service     |   |
|   |    (Node runner)      |     |  http://127.0.0.1:3111|   |
|   +-----------+-----------+     +-----------+-----------+   |
|               |                             |               |
|               +--------------+--------------+               |
|                              |                              |
|                              v                              |
|                    iii-engine (v0.11.2)                     |
|            SQLite / JSON State Persistence                  |
|           Local Embeddings (all-MiniLM-L6-v2)               |
+-------------------------------------------------------------+
```

## Source-of-Truth Hierarchy

AgentMemory acts as a **Context Assistant**. It is NOT the authoritative source of TITAN requirements.

1. **Product Owner instructions**
2. **Approved research/design documents**
3. **Repository source code**
4. **Project specifications**
5. **Verified tests**
6. **AgentMemory**

> [!IMPORTANT]
> If AgentMemory conflicts with repository documentation, project specifications, or source code, **repository documentation and source code ALWAYS win**.

## Startup & Daemon Management

The AgentMemory daemon runs as a local service on port `3111`:

```powershell
# Start AgentMemory daemon from a neutral directory
agentmemory

# Check health & status
agentmemory status
Invoke-RestMethod -Uri "http://localhost:3111/agentmemory/health"
```

## Security Rules

> [!CAUTION]
> NEVER store secrets or sensitive credentials in AgentMemory.
>
> Prohibited content includes:
> - API keys (Gemini API, Oracle Cloud, GitHub tokens)
> - Passwords or private keys
> - `.env` file contents or secrets
> - Private database connection strings
> - Authentication tokens

## API Usage & Verification

### 1. Store Memory
```powershell
Invoke-RestMethod -Uri "http://localhost:3111/agentmemory/remember" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"content":"Concise durable memory","project":"TITAN","tags":["titan","architecture"]}'
```

### 2. Search / Recall Memory
```powershell
Invoke-RestMethod -Uri "http://localhost:3111/agentmemory/smart-search" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"query":"TITAN Clean Architecture rules"}'
```

### 3. Forget / Delete Memory
```powershell
Invoke-RestMethod -Uri "http://localhost:3111/agentmemory/forget" `
  -Method POST `
  -ContentType "application/json" `
  -Body '{"memoryId":"mem_xxx"}'
```

## Troubleshooting

- **Server Not Responding on 3111**: Run `agentmemory` from PowerShell to launch the background service.
- **Diagnostic Tool**: Run `agentmemory doctor` to diagnose configuration.
- **MCP Server Validation**: Ensure `C:\Users\acer\.gemini\config\mcp_config.json` points to direct node execution:
  `node "C:\Users\acer\AppData\Roaming\npm\node_modules\@agentmemory\agentmemory\dist\standalone.mjs"`
