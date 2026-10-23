# Agent notes for tally

- This is a small Go module; `make check` is the whole gate.
- Do not add dependencies. Prefer the standard library.
- Keep commits small, and title pull requests in Conventional Commit style.

<!-- tera:begin stamp=tera@v0.8.0-rc.4/bc9cb13c6c9d38ccbcd82f83236df1c1dc30ab53bff1c04a3ea1496844977d3c -->
## tera

Work in this repository runs through tera, a work engine: a request becomes
a Work Order, which tera dispatches to a harness session, holds while it runs,
and parks when it needs a person to answer. Reach it through the `tera` MCP
server, or the `tera` CLI where that server is not configured.

tera acts on the deployment of the selected client context: `tera context show`
names it, and every tool call and command here reaches that deployment.

How work is planned, built, reviewed and landed here is the process in
`.tera/process.md`. Follow it rather than inventing one.

| When the person asks to | Use the skill |
|---|---|
| file a work order | `tera-work-orders` |
| what's parked | `tera-supervise` |
| take the next off-tera item | `off-tera-work` |
| check a train | `tera-plans` |
| start a plan | `tera-plans` |

To check this repository's tera setup, run `tera get-started`.
<!-- tera:end -->
