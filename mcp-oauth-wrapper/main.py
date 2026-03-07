#!/usr/bin/env python3
"""
OAuth 2.0 wrapper for Docker MCP Gateway
Allows Claude.ai to connect using OAuth instead of Bearer token
"""

import secrets
import sys
from datetime import datetime, timedelta
from enum import Enum
from typing import Dict, Optional
from urllib.parse import urlencode

import httpx
from fastapi import FastAPI, Request, HTTPException, Header, status, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse, StreamingResponse, JSONResponse
from pydantic import BaseModel, Field, field_validator, ConfigDict, ValidationError
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="",
        case_sensitive=False,
        env_file=".env",
        env_file_encoding="utf-8",
    )

    mcp_gateway_url: str = "http://localhost:8082/sse"
    mcp_gateway_auth_token: str

    oauth_client_id: str = "claude-mcp-client"
    oauth_client_secret: str

    public_base_url: str


try:
    settings = Settings()
except ValidationError as exc:
    print("ERROR: Missing or invalid required environment variables:", file=sys.stderr)
    for err in exc.errors():
        field = ".".join(str(part) for part in err.get("loc", []))
        msg = err.get("msg", "invalid")
        print(f"  - {field}: {msg}", file=sys.stderr)
    print("\nRequired:", file=sys.stderr)
    print("  MCP_GATEWAY_AUTH_TOKEN, OAUTH_CLIENT_SECRET, PUBLIC_BASE_URL", file=sys.stderr)
    print("Optional:", file=sys.stderr)
    print("  MCP_GATEWAY_URL, OAUTH_CLIENT_ID", file=sys.stderr)
    sys.exit(1)

app = FastAPI()

# Add CORS middleware for Claude.ai
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://claude.ai", "https://*.claude.ai"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class GrantType(str, Enum):
    AUTHORIZATION_CODE = "authorization_code"
    REFRESH_TOKEN = "refresh_token"


class ResponseType(str, Enum):
    CODE = "code"


class TokenType(str, Enum):
    BEARER = "Bearer"


class AuthorizationCodeData(BaseModel):
    model_config = ConfigDict(frozen=True)

    client_id: str
    redirect_uri: str
    scope: Optional[str] = None
    created_at: datetime
    expires_at: datetime


class AccessTokenData(BaseModel):
    model_config = ConfigDict(frozen=True)

    client_id: str
    scope: Optional[str] = None
    created_at: datetime
    expires_at: datetime


class TokenRequest(BaseModel):
    grant_type: GrantType
    code: Optional[str] = None
    redirect_uri: Optional[str] = None
    client_id: str
    client_secret: str

    @field_validator('code')
    @classmethod
    def validate_code_for_auth_grant(cls, v: Optional[str], info) -> Optional[str]:
        if info.data.get('grant_type') == GrantType.AUTHORIZATION_CODE and not v:
            raise ValueError('code is required for authorization_code grant')
        return v

    @field_validator('redirect_uri')
    @classmethod
    def validate_redirect_uri_for_auth_grant(cls, v: Optional[str], info) -> Optional[str]:
        if info.data.get('grant_type') == GrantType.AUTHORIZATION_CODE and not v:
            raise ValueError('redirect_uri is required for authorization_code grant')
        return v


class TokenResponse(BaseModel):
    access_token: str
    token_type: TokenType = TokenType.BEARER
    expires_in: int = Field(..., gt=0)
    scope: Optional[str] = None


class OAuthMetadata(BaseModel):
    issuer: str
    authorization_endpoint: str
    token_endpoint: str
    response_types_supported: list[str]
    grant_types_supported: list[str]
    token_endpoint_auth_methods_supported: list[str]
    scopes_supported: list[str]


class ServiceInfo(BaseModel):
    service: str
    status: str
    oauth_client_id: str
    endpoints: dict[str, str]


# In-memory storage with type safety
authorization_codes: Dict[str, AuthorizationCodeData] = {}
access_tokens: Dict[str, AccessTokenData] = {}

# Cache for OpenAPI schema (generated on first request)
cached_openapi_schema: Optional[dict] = None


@app.get("/", response_model=None)
@app.post("/", response_model=None)
async def root_handler(
    request: Request,
    authorization: Optional[str] = Header(None)
):
    """
    Root endpoint:
    - No auth: return service info (GET only)
    - With auth: proxy to MCP Gateway (GET for SSE, POST for JSON-RPC)
    """
    # If no authorization header and GET request, return service info
    if not authorization and request.method == "GET":
        return ServiceInfo(
            service="MCP OAuth Wrapper",
            status="running",
            oauth_client_id=settings.oauth_client_id,
            endpoints={
                "authorize": "/oauth/authorize",
                "token": "/oauth/token",
                "mcp_sse": "/sse"
            }
        )

    # Otherwise, validate auth and proxy to gateway
    await validate_bearer_token(authorization)

    # Build proxy headers
    headers = {
        "Authorization": f"Bearer {settings.mcp_gateway_auth_token}",
        **{
            k: v
            for k, v in request.headers.items()
            if k.lower() not in ["host", "authorization"]
        }
    }

    # Include query parameters in the proxy URL
    proxy_url = settings.mcp_gateway_url
    if request.url.query:
        query_string = request.url.query.decode() if isinstance(request.url.query, bytes) else request.url.query
        proxy_url = f"{settings.mcp_gateway_url}?{query_string}"

    # Handle SSE streaming for GET
    if request.method == "GET":
        client = httpx.AsyncClient(timeout=None)  # No timeout for SSE

        async def stream_response():
            try:
                async with client.stream("GET", proxy_url, headers=headers) as response:
                    async for chunk in response.aiter_bytes():
                        yield chunk
            finally:
                await client.aclose()

        return StreamingResponse(
            stream_response(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive"
            }
        )

    # Handle POST requests
    body = await request.body()

    async with httpx.AsyncClient() as client:
        response = await client.post(
            proxy_url,
            headers=headers,
            content=body
        )

        from fastapi.responses import Response
        return Response(
            content=response.content,
            status_code=response.status_code,
            headers=dict(response.headers)
        )


@app.get("/oauth/authorize")
async def authorize(
    response_type: ResponseType,
    client_id: str,
    redirect_uri: str,
    state: Optional[str] = None,
    scope: Optional[str] = None
) -> RedirectResponse:
    """OAuth 2.0 authorization endpoint"""

    if client_id != settings.oauth_client_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid client_id"
        )

    # Generate authorization code
    auth_code = secrets.token_urlsafe(32)
    now = datetime.now()

    authorization_codes[auth_code] = AuthorizationCodeData(
        client_id=client_id,
        redirect_uri=redirect_uri,
        scope=scope,
        created_at=now,
        expires_at=now + timedelta(minutes=10)
    )

    # Build redirect URL
    params: dict[str, str] = {"code": auth_code}
    if state:
        params["state"] = state

    redirect_url = f"{redirect_uri}?{urlencode(params)}"
    return RedirectResponse(url=redirect_url)


@app.post("/oauth/token", response_model=TokenResponse)
async def token(
    grant_type: str = Form(...),
    code: Optional[str] = Form(None),
    redirect_uri: Optional[str] = Form(None),
    client_id: str = Form(...),
    client_secret: str = Form(...)
) -> TokenResponse:
    """OAuth 2.0 token endpoint (form-encoded)"""

    # Validate client credentials
    if client_id != settings.oauth_client_id or client_secret != settings.oauth_client_secret:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid client credentials"
        )

    if grant_type == "authorization_code":
        if not code or not redirect_uri:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="code and redirect_uri required for authorization_code grant"
            )

        # Validate authorization code
        if code not in authorization_codes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid authorization code"
            )

        auth_data = authorization_codes[code]

        # Check expiration
        if datetime.now() > auth_data.expires_at:
            del authorization_codes[code]
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Authorization code expired"
            )

        # Validate redirect_uri matches
        if redirect_uri != auth_data.redirect_uri:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Redirect URI mismatch"
            )

        # Generate access token
        access_token = secrets.token_urlsafe(32)
        now = datetime.now()

        access_tokens[access_token] = AccessTokenData(
            client_id=client_id,
            scope=auth_data.scope,
            created_at=now,
            expires_at=now + timedelta(hours=24)
        )

        # Clean up authorization code (one-time use)
        del authorization_codes[code]

        return TokenResponse(
            access_token=access_token,
            token_type=TokenType.BEARER,
            expires_in=86400,  # 24 hours
            scope=auth_data.scope
        )

    raise HTTPException(
        status_code=status.HTTP_400_BAD_REQUEST,
        detail=f"Unsupported grant_type: {grant_type}"
    )


async def validate_bearer_token(authorization: Optional[str]) -> AccessTokenData:
    """Validate Bearer token and return token data"""
    if not authorization:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization header"
        )

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header format"
        )

    token = authorization.replace("Bearer ", "")

    if token not in access_tokens:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid access token"
        )

    token_data = access_tokens[token]

    if datetime.now() > token_data.expires_at:
        del access_tokens[token]
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Access token expired"
        )

    return token_data


@app.get("/sse", response_model=None)
@app.post("/sse", response_model=None)
async def proxy_sse(
    request: Request,
    authorization: Optional[str] = Header(None)
) -> StreamingResponse | JSONResponse:
    """Proxy SSE requests to MCP Gateway with authentication"""

    # Validate access token
    await validate_bearer_token(authorization)

    # Build proxy headers
    headers = {
        "Authorization": f"Bearer {settings.mcp_gateway_auth_token}",
        **{
            k: v
            for k, v in request.headers.items()
            if k.lower() not in ["host", "authorization"]
        }
    }

    # Include query parameters in the proxy URL
    proxy_url = settings.mcp_gateway_url
    if request.url.query:
        query_string = request.url.query.decode() if isinstance(request.url.query, bytes) else request.url.query
        proxy_url = f"{settings.mcp_gateway_url}?{query_string}"

    # Handle SSE streaming - keep client alive during stream
    if request.method == "GET":
        client = httpx.AsyncClient(timeout=None)  # No timeout for SSE

        async def stream_response():
            try:
                async with client.stream("GET", proxy_url, headers=headers) as response:
                    async for chunk in response.aiter_bytes():
                        yield chunk
            finally:
                await client.aclose()

        return StreamingResponse(
            stream_response(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive"
            }
        )

    # Handle POST requests
    elif request.method == "POST":
        try:
            body = await request.body()
            print(f"DEBUG: Proxying POST to {proxy_url} ({len(body)} bytes)")

            async with httpx.AsyncClient() as client:
                response = await client.post(
                    proxy_url,
                    headers=headers,
                    content=body
                )
                print(f"DEBUG: Gateway responded with {response.status_code}")

                # Return raw content, don't try to parse as JSON
                from fastapi.responses import Response
                return Response(
                    content=response.content,
                    status_code=response.status_code,
                    headers=dict(response.headers)
                )
        except Exception as e:
            print(f"ERROR in POST handler: {e}")
            raise

    raise HTTPException(
        status_code=status.HTTP_405_METHOD_NOT_ALLOWED,
        detail="Method not allowed"
    )


@app.get("/.well-known/oauth-authorization-server", response_model=OAuthMetadata)
async def oauth_metadata() -> OAuthMetadata:
    """OAuth 2.0 Authorization Server Metadata (RFC 8414)"""
    base_url = settings.public_base_url

    return OAuthMetadata(
        issuer=base_url,
        authorization_endpoint=f"{base_url}/oauth/authorize",
        token_endpoint=f"{base_url}/oauth/token",
        response_types_supported=["code"],
        grant_types_supported=["authorization_code"],
        token_endpoint_auth_methods_supported=["client_secret_post"],
        scopes_supported=["mcp"]
    )


# ============================================================================
# OpenAPI Bridge for ChatGPT Actions
# ============================================================================

def parse_sse_response(text: str) -> dict:
    """Parse SSE format response to extract JSON data"""
    import json
    for line in text.split('\n'):
        if line.startswith('data: '):
            return json.loads(line[6:])  # Skip 'data: ' prefix
    raise ValueError(f"No data found in SSE response: {text[:200]}")


async def fetch_mcp_tools() -> dict:
    """Fetch available tools from MCP Gateway with proper session management

    With SSE transport:
    1. GET creates SSE stream and returns endpoint with sessionid
    2. POST requests return 202, actual responses come through SSE stream
    """
    import asyncio
    import json

    # Shared state
    endpoint_url = None
    endpoint_ready = asyncio.Event()
    responses = {}  # Map request ID to response
    done_event = asyncio.Event()

    async def sse_listener():
        """Keep SSE connection alive and collect responses"""
        nonlocal endpoint_url

        async with httpx.AsyncClient(timeout=None) as client:
            async with client.stream(
                "GET",
                settings.mcp_gateway_url,
                headers={"Authorization": f"Bearer {settings.mcp_gateway_auth_token}"}
            ) as sse_stream:
                buffer = ""
                async for chunk in sse_stream.aiter_text():
                    buffer += chunk
                    lines = buffer.split('\n')

                    for line in lines[:-1]:
                        if line.startswith('event: '):
                            event_type = line[7:].strip()

                        elif line.startswith('data: '):
                            data = line[6:].strip()

                            # First event: endpoint with sessionid
                            if '/sse?sessionid=' in data:
                                endpoint_url = f"{settings.mcp_gateway_url}?{data.split('?')[1]}"
                                print(f"  → Got session endpoint: {endpoint_url}")
                                endpoint_ready.set()

                            # JSON-RPC responses
                            else:
                                try:
                                    msg = json.loads(data)
                                    if 'id' in msg and msg['id'] is not None:
                                        responses[msg['id']] = msg
                                        print(f"  → Got response for request {msg['id']}")
                                except json.JSONDecodeError:
                                    pass

                        # Check if we have all responses
                        if 1 in responses and 2 in responses:
                            done_event.set()
                            return

                    buffer = lines[-1]

    async def send_requests():
        """Send MCP protocol requests"""
        # Wait for endpoint URL
        await endpoint_ready.wait()

        async with httpx.AsyncClient(timeout=10.0) as client:
            # Step 1: Initialize
            print("  → Sending initialize request...")
            await client.post(
                endpoint_url,
                headers={
                    "Authorization": f"Bearer {settings.mcp_gateway_auth_token}",
                    "Content-Type": "application/json"
                },
                json={
                    "jsonrpc": "2.0",
                    "id": 1,
                    "method": "initialize",
                    "params": {
                        "protocolVersion": "2025-11-25",
                        "capabilities": {},
                        "clientInfo": {
                            "name": "openapi-bridge",
                            "version": "1.0.0"
                        }
                    }
                }
            )

            # Wait for init response in SSE stream
            while 1 not in responses:
                await asyncio.sleep(0.1)

            print(f"  → Initialized: {responses[1].get('result', {}).get('serverInfo', {}).get('name', 'MCP Gateway')}")

            # Step 2: Send initialized notification
            await client.post(
                endpoint_url,
                headers={
                    "Authorization": f"Bearer {settings.mcp_gateway_auth_token}",
                    "Content-Type": "application/json"
                },
                json={
                    "jsonrpc": "2.0",
                    "method": "notifications/initialized"
                }
            )

            # Step 3: List tools
            print("  → Sending tools/list request...")
            await client.post(
                endpoint_url,
                headers={
                    "Authorization": f"Bearer {settings.mcp_gateway_auth_token}",
                    "Content-Type": "application/json"
                },
                json={
                    "jsonrpc": "2.0",
                    "id": 2,
                    "method": "tools/list"
                }
            )

    # Run both tasks concurrently
    print("  → Establishing SSE connection...")
    await asyncio.gather(sse_listener(), send_requests())

    # Wait for all responses
    await done_event.wait()

    if 2 not in responses:
        raise ValueError("Failed to get tools/list response")

    return responses[2]


def mcp_to_openapi_schema(tools_response: dict) -> dict:
    """Convert MCP tools list to OpenAPI 3.1 spec with proxy pattern"""
    base_url = settings.public_base_url

    spec = {
        "openapi": "3.1.0",
        "info": {
            "title": "MCP Gateway API",
            "description": "Dynamic access to 145+ MCP tools via proxy endpoints. Search, discover, and execute any available MCP tool.",
            "version": "1.0.0"
        },
        "servers": [{"url": base_url}],
        "paths": {
            "/api/tools/search": {
                "post": {
                    "operationId": "search_mcp_tools",
                    "summary": "Search for available MCP tools by keyword, category, or description",
                    "description": "Search across all 145+ MCP tools to find relevant capabilities. Returns tool names, descriptions, and categories.",
                    "requestBody": {
                        "required": True,
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "object",
                                    "properties": {
                                        "query": {
                                            "type": "string",
                                            "description": "Search query (matches tool names, descriptions, categories)"
                                        },
                                        "category": {
                                            "type": "string",
                                            "description": "Filter by category (azure, monday, filesystem, memory, playwright, etc.)"
                                        },
                                        "limit": {
                                            "type": "integer",
                                            "default": 10,
                                            "description": "Maximum number of results to return"
                                        }
                                    },
                                    "required": ["query"]
                                }
                            }
                        }
                    },
                    "responses": {
                        "200": {
                            "description": "List of matching tools",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "tools": {
                                                "type": "array",
                                                "items": {
                                                    "type": "object",
                                                    "properties": {
                                                        "name": {"type": "string"},
                                                        "description": {"type": "string"},
                                                        "category": {"type": "string"}
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "/api/tools/list": {
                "get": {
                    "operationId": "list_mcp_tools",
                    "summary": "List all available MCP tools",
                    "description": "Get a complete list of all 145+ available MCP tools, optionally filtered by category.",
                    "parameters": [
                        {
                            "name": "category",
                            "in": "query",
                            "required": False,
                            "schema": {"type": "string"},
                            "description": "Filter by category (azure, monday, filesystem, memory, playwright, etc.)"
                        },
                        {
                            "name": "limit",
                            "in": "query",
                            "required": False,
                            "schema": {"type": "integer", "default": 50},
                            "description": "Maximum number of tools to return"
                        }
                    ],
                    "responses": {
                        "200": {
                            "description": "List of available tools",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "tools": {
                                                "type": "array",
                                                "items": {
                                                    "type": "object",
                                                    "properties": {
                                                        "name": {"type": "string"},
                                                        "description": {"type": "string"},
                                                        "category": {"type": "string"},
                                                        "inputSchema": {"type": "object"}
                                                    }
                                                }
                                            },
                                            "total": {"type": "integer"}
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            },
            "/api/tools/execute": {
                "post": {
                    "operationId": "execute_mcp_tool",
                    "summary": "Execute any MCP tool by name",
                    "description": "Execute any of the 145+ available MCP tools by providing the tool name and arguments. Use search or list endpoints first to discover available tools.",
                    "requestBody": {
                        "required": True,
                        "content": {
                            "application/json": {
                                "schema": {
                                    "type": "object",
                                    "properties": {
                                        "tool_name": {
                                            "type": "string",
                                            "description": "Name of the MCP tool to execute (e.g., 'list_directory', 'get_board_items_page', 'acr')"
                                        },
                                        "arguments": {
                                            "type": "object",
                                            "description": "Tool-specific arguments as a JSON object"
                                        }
                                    },
                                    "required": ["tool_name", "arguments"]
                                }
                            }
                        }
                    },
                    "responses": {
                        "200": {
                            "description": "Tool execution result",
                            "content": {
                                "application/json": {
                                    "schema": {
                                        "type": "object",
                                        "properties": {
                                            "content": {
                                                "type": "array",
                                                "items": {"type": "object"}
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },
        "components": {
            "schemas": {},
            "securitySchemes": {
                "oauth2": {
                    "type": "oauth2",
                    "flows": {
                        "authorizationCode": {
                            "authorizationUrl": f"{base_url}/oauth/authorize",
                            "tokenUrl": f"{base_url}/oauth/token",
                            "scopes": {"mcp": "Access MCP tools"}
                        }
                    }
                }
            }
        },
        "security": [{"oauth2": ["mcp"]}]
    }

    return spec


@app.get("/chatgpt-schema.json")
async def get_chatgpt_schema():
    """OpenAPI spec for ChatGPT Actions - ALL MCP tools"""
    global cached_openapi_schema

    # Generate schema on first request (with caching)
    if cached_openapi_schema is None:
        print("Generating OpenAPI schema from MCP Gateway...")
        try:
            tools_response = await fetch_mcp_tools()
            cached_openapi_schema = mcp_to_openapi_schema(tools_response)
            tool_count = len(tools_response.get("result", {}).get("tools", []))
            print(f"✓ Generated schema with {tool_count} tools")
        except Exception as e:
            print(f"✗ Failed to generate schema: {e}")
            raise HTTPException(
                status_code=503,
                detail=f"Failed to fetch tools from MCP Gateway: {str(e)}"
            )

    return cached_openapi_schema


def extract_tool_category(tool_name: str) -> str:
    """Extract category from tool name (e.g., 'mcp__azure__acr' -> 'azure')"""
    if tool_name.startswith("mcp__"):
        parts = tool_name.split("__")
        if len(parts) >= 2:
            return parts[1]
    # Direct tool names from servers
    if tool_name.startswith("browser_"):
        return "playwright"
    return "other"


@app.post("/api/tools/search")
async def search_mcp_tools(
    request: Request,
    authorization: Optional[str] = Header(None)
):
    """Search for MCP tools by keyword"""
    global cached_openapi_schema

    await validate_bearer_token(authorization)

    body = await request.json()
    query = body.get("query", "").lower()
    category_filter = body.get("category", "").lower()
    limit = body.get("limit", 10)

    if cached_openapi_schema is None:
        # Fetch tools first
        tools_response = await fetch_mcp_tools()
        cached_openapi_schema = mcp_to_openapi_schema(tools_response)

    # Re-fetch tools to get the list
    tools_response = await fetch_mcp_tools()
    tools = tools_response.get("result", {}).get("tools", [])

    # Search and filter
    results = []
    for tool in tools:
        name = tool.get("name", "")
        description = tool.get("description", "")
        category = extract_tool_category(name)

        # Apply category filter
        if category_filter and category != category_filter:
            continue

        # Search in name and description
        if query in name.lower() or query in description.lower():
            results.append({
                "name": name,
                "description": description,
                "category": category
            })

            if len(results) >= limit:
                break

    return {"tools": results, "total": len(results)}


@app.get("/api/tools/list")
async def list_mcp_tools(
    category: Optional[str] = None,
    limit: int = 50,
    authorization: Optional[str] = Header(None)
):
    """List all available MCP tools"""
    await validate_bearer_token(authorization)

    # Fetch tools
    tools_response = await fetch_mcp_tools()
    tools = tools_response.get("result", {}).get("tools", [])

    # Filter and transform
    results = []
    for tool in tools:
        name = tool.get("name", "")
        description = tool.get("description", "")
        input_schema = tool.get("inputSchema", {})
        tool_category = extract_tool_category(name)

        # Apply category filter
        if category and tool_category != category.lower():
            continue

        results.append({
            "name": name,
            "description": description,
            "category": tool_category,
            "inputSchema": input_schema
        })

        if len(results) >= limit:
            break

    return {"tools": results, "total": len(tools)}


@app.post("/api/tools/execute")
async def execute_mcp_tool(
    request: Request,
    authorization: Optional[str] = Header(None)
):
    """Execute any MCP tool by name"""
    await validate_bearer_token(authorization)

    body = await request.json()
    tool_name = body.get("tool_name")
    arguments = body.get("arguments", {})

    if not tool_name:
        raise HTTPException(status_code=400, detail="tool_name is required")

    # Build MCP request
    mcp_request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": tool_name,
            "arguments": arguments
        }
    }

    # Call MCP Gateway
    async with httpx.AsyncClient() as client:
        response = await client.post(
            settings.mcp_gateway_url,
            headers={"Authorization": f"Bearer {settings.mcp_gateway_auth_token}"},
            json=mcp_request
        )

        mcp_result = response.json()

        # Return result
        if "result" in mcp_result:
            return mcp_result["result"]
        elif "error" in mcp_result:
            raise HTTPException(
                status_code=400,
                detail=mcp_result["error"]
            )
        else:
            return mcp_result


@app.on_event("startup")
async def startup_event():
    """Optional: Pre-warm OpenAPI schema cache on startup"""
    # Schema is now generated on-demand, so this is optional
    # Uncomment to pre-fetch tools during startup (adds ~5-10s to startup time):
    #
    # global cached_openapi_schema
    # try:
    #     print("Pre-warming OpenAPI schema cache...")
    #     tools_response = await fetch_mcp_tools()
    #     cached_openapi_schema = mcp_to_openapi_schema(tools_response)
    #     tool_count = len(tools_response.get("result", {}).get("tools", []))
    #     print(f"✓ Cached schema with {tool_count} tools")
    # except Exception as e:
    #     print(f"✗ Failed to pre-warm cache: {e}")

    print("OAuth wrapper ready (OpenAPI schema will be generated on first request)")


if __name__ == "__main__":
    import uvicorn

    print("=" * 60)
    print("MCP OAuth Wrapper Starting...")
    print("=" * 60)
    print(f"\nOAuth Client ID: {settings.oauth_client_id}")
    print(f"Public Base URL: {settings.public_base_url}")
    print("=" * 60)

    uvicorn.run(app, host="0.0.0.0", port=8081, log_level="info")
