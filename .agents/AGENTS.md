# Agent Guidance & Rules for QuizForge AI

## MCP Tool Call Protocols
1. **Avoid Prohibited MCP Tool Invocations**: Do not attempt to invoke denied or unconfigured MCP servers (e.g., `chrome_devtools`).
2. **Prioritize Native Built-in Tools**: For file operations, code search, browser tasks, and execution, always prefer native built-in tools (`view_file`, `grep_search`, `run_command`, `browser_subagent`) over lazy MCP tools.
3. **Validate MCP Schemas Before Execution**: Never call `call_mcp_tool` without first reading and validating the tool schema from `C:\Users\acer\.gemini\antigravity-ide\mcp\<serverName>\<toolName>.json`.
4. **Graceful Fallback on Tool Failure**: If any tool or MCP invocation fails, fall back immediately to standard system commands or direct tools without throwing unhandled exceptions.
