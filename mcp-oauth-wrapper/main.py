#!/usr/bin/env python3
"""
OAuth 2.0 wrapper for Docker MCP Gateway
Allows Claude.ai to connect using OAuth instead of Bearer token
"""

import os
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
from pydantic import BaseModel, Field, field_validator, ConfigDict

# Configuration - read from environment (fail fast if not set)
MCP_GATEWAY_URL = "http://localhost:8082/mcp"
MCP_GATEWAY_TOKEN = os.environ.get("MCP_GATEWAY_AUTH_TOKEN")
if not MCP_GATEWAY_TOKEN:
    print("ERROR: MCP_GATEWAY_AUTH_TOKEN environment variable not set", file=sys.stderr)
    print("Set it with: set -Ux MCP_GATEWAY_AUTH_TOKEN <your-token>", file=sys.stderr)
    sys.exit(1)

# OAuth Client Configuration
OAUTH_CLIENT_ID = "claude-mcp-client"
OAUTH_CLIENT_SECRET = "9gtEINUgZfzokiKeTq_S-GLaqacn9e6ouUM0KGAzTg8"  # Fixed secret

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
    oauth_client_secret: str
    endpoints: dict[str, str]


# In-memory storage with type safety
authorization_codes: Dict[str, AuthorizationCodeData] = {}
access_tokens: Dict[str, AccessTokenData] = {}


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
            oauth_client_id=OAUTH_CLIENT_ID,
            oauth_client_secret=OAUTH_CLIENT_SECRET,
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
        "Authorization": f"Bearer {MCP_GATEWAY_TOKEN}",
        **{
            k: v
            for k, v in request.headers.items()
            if k.lower() not in ["host", "authorization"]
        }
    }

    # Include query parameters in the proxy URL
    proxy_url = MCP_GATEWAY_URL
    if request.url.query:
        query_string = request.url.query.decode() if isinstance(request.url.query, bytes) else request.url.query
        proxy_url = f"{MCP_GATEWAY_URL}?{query_string}"

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

    if client_id != OAUTH_CLIENT_ID:
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
    if client_id != OAUTH_CLIENT_ID or client_secret != OAUTH_CLIENT_SECRET:
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
        "Authorization": f"Bearer {MCP_GATEWAY_TOKEN}",
        **{
            k: v
            for k, v in request.headers.items()
            if k.lower() not in ["host", "authorization"]
        }
    }

    # Include query parameters in the proxy URL
    proxy_url = MCP_GATEWAY_URL
    if request.url.query:
        query_string = request.url.query.decode() if isinstance(request.url.query, bytes) else request.url.query
        proxy_url = f"{MCP_GATEWAY_URL}?{query_string}"

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
    base_url = "https://4f77vjvj-8081.euw.devtunnels.ms"

    return OAuthMetadata(
        issuer=base_url,
        authorization_endpoint=f"{base_url}/oauth/authorize",
        token_endpoint=f"{base_url}/oauth/token",
        response_types_supported=["code"],
        grant_types_supported=["authorization_code"],
        token_endpoint_auth_methods_supported=["client_secret_post"],
        scopes_supported=["mcp"]
    )


if __name__ == "__main__":
    import uvicorn

    print("=" * 60)
    print("MCP OAuth Wrapper Starting...")
    print("=" * 60)
    print(f"\nOAuth Client Credentials:")
    print(f"  Client ID:     {OAUTH_CLIENT_ID}")
    print(f"  Client Secret: {OAUTH_CLIENT_SECRET}")
    print(f"\nUse these credentials in Claude.ai to connect!")
    print("=" * 60)

    uvicorn.run(app, host="0.0.0.0", port=8081, log_level="info")
