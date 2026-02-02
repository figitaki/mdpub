# Routing

mdpub uses a simple file-based routing system. URLs map directly to Markdown files in your content directory.

## Basic Rules

| URL | File Path |
|-----|-----------|
| `/` | `content/index.md` |
| `/foo` | `content/foo.md` or `content/foo/index.md` |
| `/docs/api` | `content/docs/api.md` |
| `/blog/2024/hello` | `content/blog/2024/hello.md` |

## Resolution Order

When a request comes in, mdpub checks for files in this order:

1. **Direct match**: `/foo` looks for `content/foo.md`
2. **Index fallback**: If not found, looks for `content/foo/index.md`

This allows you to organize content either as flat files or nested directories.

### Example

Both of these structures work for the URL `/guides`:

```
# Option 1: Single file
content/
  guides.md

# Option 2: Directory with index
content/
  guides/
    index.md
    advanced.md   # /guides/advanced
```

## Special Routes

### Health Check

The `/healthz` endpoint returns a 200 status for load balancer health checks:

```bash
curl http://localhost:4000/healthz
# ok
```

### Static Assets

Assets are served from `priv/static/assets/`:

```
priv/static/assets/
  style.css      # /assets/style.css
```

## Base Path

For deployments behind a reverse proxy with a path prefix, set `MDPUB_BASE_PATH`:

```bash
MDPUB_BASE_PATH=/docs mix run --no-halt
```

All generated links will include this prefix:

- Links: `/docs/getting-started`
- Assets: `/docs/assets/style.css`

## 404 Handling

Missing pages render a friendly 404 page with a link back to the home page. The 404 response includes proper HTTP status codes for SEO.

## Caching

mdpub caches rendered HTML in ETS (Erlang Term Storage) for fast responses:

- Cache is keyed by file path
- Cache is invalidated when the file's mtime changes
- File watcher triggers recompilation on changes

> **Note:** In production with `MDPUB_WATCH=false`, files are only reloaded when the server restarts.

## Security

- Path traversal attacks are blocked
- Only `.md` files in the content directory are served
- No directory listing is exposed
