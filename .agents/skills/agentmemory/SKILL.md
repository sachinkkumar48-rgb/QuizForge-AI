---
name: agentmemory
description: Interface with AgentMemory persistent context server for Project TITAN to store and recall architectural decisions, lessons, and project knowledge across sessions.
---

# AgentMemory Skill for Antigravity (Workspace)

AgentMemory provides persistent context across Antigravity development sessions for Project TITAN.

## Core Rules & Source of Truth

AgentMemory is a **Context Assistant**. It is NOT the authoritative source of TITAN requirements.

### Source-of-Truth Hierarchy
1. Product Owner instructions
2. Approved research/design documents
3. Repository source code
4. Project specifications
5. Verified tests
6. **AgentMemory**

> [!IMPORTANT]
> If AgentMemory content conflicts with repository source code or project documentation, **repository documentation and source code ALWAYS win**.

## Service Architecture & Endpoints

- **Daemon Status / Health**: `http://localhost:3111/agentmemory/health`
- **CLI Commands**: `agentmemory status`, `agentmemory doctor`, `agentmemory stop`
- **MCP Server**: Registered in `mcp_config.json` via node execution of `@agentmemory/agentmemory/dist/standalone.mjs`

## Key Operations

### 1. Health Check
```powershell
Invoke-RestMethod -Uri "http://localhost:3111/agentmemory/health"
```

### 2. Recall Context (Smart Search)
```powershell
Invoke-RestMethod -Uri "http://localhost:3111/agentmemory/smart-search" -Method POST -ContentType "application/json" -Body '{"query":"TITAN Clean Architecture rules"}'
```

### 3. Store Durable Memory
```powershell
Invoke-RestMethod -Uri "http://localhost:3111/agentmemory/remember" -Method POST -ContentType "application/json" -Body '{"content":"Concise durable memory text","project":"TITAN","tags":["titan","architecture"]}'
```

### 4. Delete / Forget Memory
```powershell
Invoke-RestMethod -Uri "http://localhost:3111/agentmemory/forget" -Method POST -ContentType "application/json" -Body '{"memoryId":"mem_xxx"}'
```

## Security Constraints

> [!CAUTION]
> NEVER store secrets in AgentMemory.
> Prohibited items: API keys, tokens, passwords, `.env` file contents, private connection strings, credentials.
