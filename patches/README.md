# Patches for vendored dependencies

`vendor/` is gitignored, so local edits to vendored code are kept here as patches.

## whatsapp-mcp-outbound-throttle.patch

Applies to [lharries/whatsapp-mcp](https://github.com/lharries/whatsapp-mcp) at commit `7d6a06d`.
Adds ban-avoidance throttling to `whatsapp-bridge/main.go`: outbound sends are serialised and delayed
by a random gap (`WA_SEND_MIN_MS` / `WA_SEND_MAX_MS`, default 1500–5000 ms), plus related `go.mod`/`go.sum` changes.

Apply with:

    cd vendor/whatsapp-mcp && git checkout 7d6a06d && git apply ../../patches/whatsapp-mcp-outbound-throttle.patch
