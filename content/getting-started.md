# Getting started

Run locally:

```bash
mix deps.get
mix run --no-halt
```

Environment variables:

- `PORT` (default `4000`)
- `MDPUB_CONTENT_DIR` (default `./content`)
- `MDPUB_WATCH` (default `true`)

Build a release:

```bash
MIX_ENV=prod mix release
_build/prod/rel/mdpub/bin/mdpub start
```
