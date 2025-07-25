# MCP (Model Context Protocol) Servers Explained

## What is MCP?

MCP (Model Context Protocol) is an open protocol that allows AI assistants like Claude to connect to external tools, databases, and services. Think of MCP servers as "plugins" that extend Claude's capabilities beyond its built-in knowledge.

## How MCP Servers Work

### Basic Architecture
```
Claude Code ←→ MCP Protocol ←→ MCP Server ←→ External Resource
                                    ↓
                              (Database, API, 
                               File System, etc.)
```

### Server Types

1. **stdio servers** (Most Common)
   - Run as local executables
   - Communicate via stdin/stdout
   - Example: Python script, Node.js app

2. **SSE servers** (Server-Sent Events)
   - Web-based servers
   - Stream data over HTTP
   - Good for remote connections

3. **HTTP servers**
   - REST API style
   - Request/response pattern

## Real-World Examples

### Example 1: Database MCP Server
```json
{
  "mcp-postgres": {
    "command": "npx",
    "args": ["@modelcontextprotocol/server-postgres"],
    "env": {
      "POSTGRES_URL": "postgresql://user:pass@localhost/mydb"
    }
  }
}
```

**What it does:**
- Connects Claude to PostgreSQL database
- Allows queries like: "Show me all users created this week"
- Can inspect schema, run queries, analyze data

### Example 2: GitHub MCP Server
```json
{
  "github": {
    "command": "node",
    "args": ["/path/to/github-mcp-server.js"],
    "env": {
      "GITHUB_TOKEN": "ghp_xxxxxxxxxxxx"
    }
  }
}
```

**What it does:**
- Access GitHub issues, PRs, repos
- Create issues, comment on PRs
- Search code across repositories

### Example 3: File System MCP Server
```json
{
  "filesystem": {
    "command": "python",
    "args": ["/home/user/mcp-filesystem.py"],
    "env": {
      "ALLOWED_PATHS": "/home/user/documents,/home/user/projects"
    }
  }
}
```

**What it does:**
- Browse specific directories
- Read/write files outside Claude's normal access
- Manage project files safely

## How to Use MCP Servers

### 1. Configuration Files
MCP servers are configured in JSON files located at:
- **User level**: `~/.config/claude/mcp-settings.json`
- **Project level**: `.claude/mcp-settings.json`
- **Local level**: `.mcp-settings.json`

### 2. Using @ Mentions
Once configured, you can reference MCP resources:
```
@postgres Can you show me the user table schema?
@github What are the open issues in my project?
@filesystem Read the config file in my home directory
```

### 3. Slash Commands
MCP servers can provide custom slash commands:
```
/db-query SELECT * FROM users WHERE created_at > '2024-01-01'
/github-create-issue Title: Bug in login, Body: Users can't...
```

## Creating Your Own MCP Server

### Simple Python Example
```python
#!/usr/bin/env python3
import json
import sys

class SimpleMCPServer:
    def __init__(self):
        self.tools = {
            "get_weather": self.get_weather,
            "calculate": self.calculate
        }
    
    def get_weather(self, location):
        # Simulate weather API call
        return f"Weather in {location}: Sunny, 72°F"
    
    def calculate(self, expression):
        try:
            result = eval(expression)  # Note: unsafe in production!
            return f"Result: {result}"
        except:
            return "Error: Invalid expression"
    
    def run(self):
        while True:
            request = json.loads(input())
            method = request.get("method")
            params = request.get("params", {})
            
            if method in self.tools:
                result = self.tools[method](**params)
                response = {
                    "id": request.get("id"),
                    "result": result
                }
            else:
                response = {
                    "id": request.get("id"),
                    "error": "Method not found"
                }
            
            print(json.dumps(response))
            sys.stdout.flush()

if __name__ == "__main__":
    server = SimpleMCPServer()
    server.run()
```

### Configuration for the above server:
```json
{
  "my-tools": {
    "command": "python3",
    "args": ["/path/to/simple_mcp_server.py"]
  }
}
```

## Security Considerations

1. **Sandboxing**: MCP servers run as separate processes
2. **Authentication**: Use environment variables for secrets
3. **Path Restrictions**: Limit file system access
4. **Network Access**: Control what APIs servers can reach
5. **Third-Party Risk**: Audit servers before trusting them

## Common Use Cases

### Development
- Connect to development databases
- Access local Docker containers
- Integrate with IDEs

### Data Analysis
- Query production databases (read-only)
- Access data warehouses
- Connect to analytics APIs

### Automation
- Trigger CI/CD pipelines
- Manage cloud resources
- Execute scheduled tasks

### Documentation
- Access internal wikis
- Search documentation
- Generate reports

## Best Practices

1. **Minimal Permissions**: Give servers only necessary access
2. **Environment Variables**: Never hardcode credentials
3. **Logging**: Track MCP server actions
4. **Version Control**: Keep server configs in git
5. **Testing**: Test servers in isolation first

## Example: Email AI Integration via MCP

```json
{
  "email-ai": {
    "command": "node",
    "args": ["/opt/mcp-email-ai/server.js"],
    "env": {
      "DOVECOT_PATH": "/etc/dovecot",
      "SIEVE_PATH": "/etc/dovecot/sieve",
      "AI_API_KEY": "${AI_API_KEY}",
      "SPAM_MODEL": "fasttext-spam-v2"
    }
  }
}
```

This MCP server could:
- Analyze email patterns
- Update sieve rules dynamically
- Train spam models
- Generate filtering statistics
- All accessible via: `@email-ai analyze spam patterns for last week`

MCP servers essentially turn Claude into a powerful integration platform, allowing it to interact with any system you can write a server for!