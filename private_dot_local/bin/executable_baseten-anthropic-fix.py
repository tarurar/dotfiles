#!/usr/bin/env python3
"""
Baseten Anthropic-format proxy with auth injection.

Fixes two issues:
1. Claude Code does not send the Authorization header.
2. Claude Code sends system role messages in messages[].
"""

import json
import os
import sys
import time
from urllib.parse import urljoin

try:
    from aiohttp import ClientSession, web
except ImportError:
    print("Install dependency: pip install aiohttp", file=sys.stderr)
    sys.exit(1)

BASETEN_URL = "https://inference.baseten.co"
HOST = "127.0.0.1"
PORT = 4000
API_KEY = os.environ.get("BASETEN_API_KEY", "")

if not API_KEY:
    print("BASETEN_API_KEY is required", file=sys.stderr)
    sys.exit(1)


def log(msg: str):
    ts = time.strftime("%H:%M:%S")
    print(f"[{ts}] {msg}", file=sys.stderr, flush=True)


def rewrite_system_messages(body: dict) -> dict:
    """Extract system role messages and move them to the top-level system field."""
    messages = body.get("messages", [])
    if not messages:
        return body

    system_parts = []
    other_messages = []

    for msg in messages:
        if msg.get("role") == "system":
            content = msg.get("content", "")
            if isinstance(content, list):
                texts = [c.get("text", "") for c in content if c.get("type") == "text"]
                system_parts.append("\n".join(texts))
            elif isinstance(content, str):
                system_parts.append(content)
        else:
            other_messages.append(msg)

    if system_parts:
        body["system"] = "\n\n".join(system_parts)
        body["messages"] = other_messages
        log(f"  Rewrote {len(system_parts)} system messages to top-level system")

    return body


async def proxy_handler(request: web.Request) -> web.Response:
    path = request.path
    method = request.method

    log("=" * 60)
    log(f"REQUEST: {method} {path}")

    headers = {}
    for key, value in request.headers.items():
        if key.lower() in ("host", "content-length", "transfer-encoding"):
            continue
        headers[key] = value

    headers["Authorization"] = f"Bearer {API_KEY}"
    log("  Injected Authorization: Bearer [redacted]")

    for key, value in headers.items():
        if key.lower() == "authorization":
            continue
        suffix = "..." if 80 < len(str(value)) else ""
        log(f"  Header: {key}={value[:80]}{suffix}")

    body = None
    try:
        body = await request.json()
        log(f"  Body keys: {list(body.keys())}")
        if "model" in body:
            log(f"  Model: {body['model']}")
        if "messages" in body and isinstance(body["messages"], list):
            roles = [m.get("role", "?") for m in body["messages"]]
            log(f"  Message roles: {roles}")

        if path == "/v1/messages" and isinstance(body, dict):
            body = rewrite_system_messages(body)
    except Exception as e:
        log(f"  Body parse error: {e}")
        body_text = await request.text()
        log(f"  Raw body: {body_text[:500]}")

    target_url = urljoin(BASETEN_URL, path)
    log(f"  Forwarding to: {target_url}")

    try:
        async with ClientSession() as session:
            req_kwargs = {
                "method": method,
                "url": target_url,
                "headers": headers,
            }
            if body is not None:
                req_kwargs["json"] = body
            else:
                req_kwargs["data"] = await request.read()

            async with session.request(**req_kwargs) as resp:
                response_body = await resp.read()
                log(f"  Response: {resp.status} {resp.reason}")
                for key, value in resp.headers.items():
                    log(f"  Resp header: {key}={value}")
                if 400 <= resp.status:
                    try:
                        err_json = json.loads(response_body)
                        log(f"  Error body: {json.dumps(err_json, indent=2)[:800]}")
                    except Exception:
                        log(f"  Error body (raw): {response_body[:500]}")

                out_headers = {}
                for key, value in resp.headers.items():
                    if key.lower() not in ("transfer-encoding", "content-encoding"):
                        out_headers[key] = value

                return web.Response(
                    body=response_body,
                    status=resp.status,
                    headers=out_headers,
                )
    except Exception as e:
        log(f"  PROXY ERROR: {type(e).__name__}: {e}")
        return web.Response(
            body=json.dumps(
                {"error": {"message": str(e), "type": "proxy_error"}}
            ).encode(),
            status=502,
            content_type="application/json",
        )


async def health_handler(request: web.Request) -> web.Response:
    return web.json_response({"status": "ok", "proxy": "baseten-anthropic-fix"})


app = web.Application(client_max_size=50 * 1024 * 1024)
app.router.add_get("/health", health_handler)
app.router.add_route("*", "/{path:.*}", proxy_handler)

if __name__ == "__main__":
    log("=" * 60)
    log(f"Baseten Anthropic Proxy starting on http://{HOST}:{PORT}")
    log(f"Forwarding to: {BASETEN_URL}")
    log("Auth injection: ENABLED")
    log(f"Test: curl http://{HOST}:{PORT}/health")
    log("=" * 60)
    web.run_app(app, host=HOST, port=PORT, print=None)
