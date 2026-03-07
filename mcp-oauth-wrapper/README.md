# MCP OAuth Wrapper

OAuth 2.0 wrapper for Docker MCP Gateway, allowing Claude.ai to connect using OAuth instead of Bearer tokens.

## Setup

### 1. Set required environment variables

Required:
- `MCP_GATEWAY_AUTH_TOKEN`
- `OAUTH_CLIENT_SECRET`
- `PUBLIC_BASE_URL` (the public, reachable URL for this wrapper, e.g. your tunnel URL)

Optional:
- `MCP_GATEWAY_URL` (default: `http://localhost:8082/sse`)
- `OAUTH_CLIENT_ID` (default: `claude-mcp-client`)

#### Set the authentication token

The wrapper and gateway share a Bearer token via the `MCP_GATEWAY_AUTH_TOKEN` environment variable.

**Fish shell (persist across sessions):**
```fish
set -Ux MCP_GATEWAY_AUTH_TOKEN "<generate-and-insert-token>"
```

**Or add to nix-darwin configuration:**
```nix
# In your darwin-configuration.nix
environment.variables = {
  MCP_GATEWAY_AUTH_TOKEN = "<generate-and-insert-token>";
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

This gives you a **stable URL** that never changes: `https://<your-tunnel>.euw.devtunnels.ms`

Set `PUBLIC_BASE_URL` to this value.

## Configuration

- **MCP Gateway URL**: `http://localhost:8082/sse` (or `MCP_GATEWAY_URL`)
- **OAuth Wrapper Port**: `8081`
- **DevTunnel (stable)**: `https://<your-tunnel>.euw.devtunnels.ms`
- **OAuth Client ID**: `claude-mcp-client` (or `OAUTH_CLIENT_ID`)
- **OAuth Client Secret**: `<generate-and-insert-secret>` (set `OAUTH_CLIENT_SECRET`)

## Connecting from Claude.ai

Use the stable DevTunnel URL above with the OAuth credentials. The URL never changes across restarts.

## Token Rotation

To rotate the token:
1. Generate new token: `openssl rand -base64 36 | tr -d '\n'`
2. Update env var: `set -Ux MCP_GATEWAY_AUTH_TOKEN "<new-token>"`
3. Restart both services

To rotate the OAuth client secret:
1. Generate new secret: `openssl rand -base64 36 | tr -d '\n'`
2. Update the OAuth client secret where it is stored (secret manager, env var, or config)
3. Restart the wrapper
