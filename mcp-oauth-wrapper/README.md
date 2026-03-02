# MCP OAuth Wrapper

OAuth 2.0 wrapper for Docker MCP Gateway, allowing Claude.ai to connect using OAuth instead of Bearer tokens.

## Setup

### 1. Set the authentication token

The wrapper and gateway share a Bearer token via the `MCP_GATEWAY_AUTH_TOKEN` environment variable.

**Fish shell (persist across sessions):**
```fish
set -Ux MCP_GATEWAY_AUTH_TOKEN "cFjyRQa9obHa/tsDQ9purp3zleV8a9DtkXcF/u7LpVgqqiE6"
```

**Or add to nix-darwin configuration:**
```nix
# In your darwin-configuration.nix
environment.variables = {
  MCP_GATEWAY_AUTH_TOKEN = "cFjyRQa9obHa/tsDQ9purp3zleV8a9DtkXcF/u7LpVgqqiE6";
};
```

### 2. Start the MCP Gateway

```bash
docker mcp gateway run --port 8082 --transport sse --verbose > /tmp/mcp-gateway.log 2>&1 &
```

The gateway will read `MCP_GATEWAY_AUTH_TOKEN` and use it for authentication.

### 3. Start the OAuth wrapper

```bash
cd mcp-oauth-wrapper
uv run main.py > /tmp/oauth-wrapper.log 2>&1 &
```

### 4. Expose via DevTunnel (persistent tunnel)

The tunnel `mcp-gateway.euw` is already configured with port 8081. Just host it:

```bash
devtunnel host mcp-gateway > /tmp/devtunnel-host.log 2>&1 &
```

This gives you a **stable URL** that never changes: `https://4f77vjvj-8081.euw.devtunnels.ms`

## Configuration

- **MCP Gateway URL**: `http://localhost:8082/sse`
- **OAuth Wrapper Port**: `8081`
- **DevTunnel (stable)**: `https://4f77vjvj-8081.euw.devtunnels.ms`
- **OAuth Client ID**: `claude-mcp-client`
- **OAuth Client Secret**: `9gtEINUgZfzokiKeTq_S-GLaqacn9e6ouUM0KGAzTg8`

## Connecting from Claude.ai

Use the stable DevTunnel URL above with the OAuth credentials. The URL never changes across restarts.

## Token Rotation

To rotate the token:
1. Generate new token: `openssl rand -base64 36 | tr -d '\n'`
2. Update env var: `set -Ux MCP_GATEWAY_AUTH_TOKEN "<new-token>"`
3. Restart both services
