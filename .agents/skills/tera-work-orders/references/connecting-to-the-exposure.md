# Registering the exposure as the `tera` MCP server

Read this when the `work_order.*` verbs are not already on your surface — a
first connection, a new deployment, or a client that cannot register an HTTP
MCP server. A session that can already list the verbs needs none of it.

## The entry

Register it with your harness as an HTTP MCP server named `tera`, which is
the name every skill of this family uses for it. Each harness keeps that
registration in its own configuration, in its own spelling; what every one of
them needs is the same three things:

- **the name** `tera`;
- **the URL**, the exposure's loopback endpoint, for example
  `http://127.0.0.1:8099/mcp/work-orders/mcp`;
- **an `Authorization: Bearer <token>` header**, carrying a per-deployment
  token read from the environment rather than written into the file.

That registration is **not checked into a repository on purpose**, because it
carries a per-deployment bearer token and because turning the surface on is an
operator's decision, not a repo default.

The URL is loopback and stays loopback (PRD-016 §13). Put the harness on
the daemon's host or tunnel to it; do not rebind the listener.

## When your client cannot register an HTTP MCP server

If your client cannot register an HTTP MCP server, the escape hatch is
raw JSON-RPC over the same endpoint — `initialize`, keep the
`Mcp-Session-Id` header, then `tools/call`. Use it for verification, not
as your normal route. To file and read work rather than to verify, the
`tera workorder` command is the better fallback: it needs no MCP client at
all.
