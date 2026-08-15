# Agent Guidance & Rules for QuizForge AI

## MCP Tool Call Protocols
1. **Avoid Prohibited MCP Tool Invocations**: Do not attempt to invoke denied or unconfigured MCP servers (e.g., `chrome_devtools`).
2. **Prioritize Native Built-in Tools**: For file operations, code search, browser tasks, and execution, always prefer native built-in tools (`view_file`, `grep_search`, `run_command`, `browser_subagent`) over lazy MCP tools.
3. **Validate MCP Schemas Before Execution**: Never call `call_mcp_tool` without first reading and validating the tool schema from `C:\Users\acer\.gemini\antigravity-ide\mcp\<serverName>\<toolName>.json`.
4. **Graceful Fallback on Tool Failure**: If any tool or MCP invocation fails, fall back immediately to standard system commands or direct tools without throwing unhandled exceptions.

## AgentMemory Integration & Context Retrieval
1. **Persistent Context Assistant**: AgentMemory stores durable TITAN project context across Antigravity sessions.
2. **Source-of-Truth Hierarchy**:
   1. Product Owner instructions
   2. Approved research/design documents
   3. Repository source code
   4. Project specifications
   5. Verified tests
   6. AgentMemory
   *If AgentMemory conflicts with repository documentation or source code, repository documentation and code win.*
3. **Security Boundary**: Never store secrets, API keys, passwords, `.env` file contents, or private credentials in AgentMemory.
