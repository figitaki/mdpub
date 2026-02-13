# Migration Guide: v0.1.x → v0.2.0

Version 0.2.0 introduces **Phoenix LiveView** as the web framework, replacing the minimal Plug.Router setup. This is a **breaking change** that requires configuration updates.

## What Changed

### Architecture
- **Before:** Minimal Plug.Router + string templates
- **After:** Phoenix 1.7 + LiveView + HEEx templates

### Key Benefits
- Live navigation (no full-page reloads)
- Automatic content refresh when markdown files change
- YAML-driven navigation configuration
- Phoenix ecosystem compatibility

## Migration Steps

### 1. Update Dependencies

Pull the latest code and run:

```bash
mix setup
```

This installs Phoenix dependencies and builds JavaScript assets via esbuild.

### 2. Set SECRET_KEY_BASE (Production Only)

Phoenix requires a secret key base for session signing.

**Development/Test:** Already configured with safe defaults in `config/dev.exs` and `config/test.exs`

**Production:** You **must** set the `SECRET_KEY_BASE` environment variable:

```bash
# Generate a secure secret
mix phx.gen.secret

# Set it in your deployment
export SECRET_KEY_BASE="<generated-secret>"
```

**Important:** Store this value securely and do not regenerate it unless you want to invalidate all existing sessions.

### 3. Configure Navigation (Optional)

Create `content/nav.yml` to define your site navigation:

```yaml
items:
  - label: Home
    path: /
  - label: Guides
    path: /guides
  - label: API
    path: /api
```

If this file doesn't exist, mdpub will serve content without a navigation sidebar.

### 4. Update Deployment Configs

#### Systemd Service

Update your service file to include `SECRET_KEY_BASE`:

```ini
[Service]
Environment="SECRET_KEY_BASE=your-secret-here"
Environment="PORT=4000"
Environment="PHX_HOST=yourdomain.com"
ExecStart=/path/to/mdpub/bin/mdpub start
```

#### Docker / Docker Compose

Add `SECRET_KEY_BASE` to your container environment:

```yaml
# docker-compose.yml
services:
  mdpub:
    image: ghcr.io/figitaki/mdpub:latest
    ports:
      - "4000:4000"
    environment:
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      PORT: 4000
      PHX_HOST: yourdomain.com
```

#### Kubernetes

Store `SECRET_KEY_BASE` as a Secret:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mdpub-secrets
type: Opaque
stringData:
  secret-key-base: <your-secret-here>
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mdpub
spec:
  template:
    spec:
      containers:
      - name: mdpub
        image: ghcr.io/figitaki/mdpub:latest
        env:
        - name: SECRET_KEY_BASE
          valueFrom:
            secretKeyRef:
              name: mdpub-secrets
              key: secret-key-base
        - name: PORT
          value: "4000"
```

### 5. Update Content (If Needed)

Markdown content structure remains the same. No changes needed unless you want to leverage the new nav.yml feature.

## Rollback Plan

If you need to stay on v0.1.x:

```bash
git checkout v0.1.0
mix deps.get
mix run --no-halt
```

The old Plug-based version will continue to work with your existing content.

## Troubleshooting

### Error: `environment variable SECRET_KEY_BASE is missing`

**Cause:** Running in production without setting `SECRET_KEY_BASE`

**Fix:**
```bash
export SECRET_KEY_BASE=$(mix phx.gen.secret)
```

### Assets not loading

**Cause:** Assets not built or missing NODE_PATH

**Fix:**
```bash
mix assets.setup
mix assets.build
```

### Navigation not showing

**Cause:** `content/nav.yml` missing or malformed

**Fix:** Create a valid `content/nav.yml` or check logs for YAML parsing errors

## Questions?

Open an issue at [github.com/figitaki/mdpub](https://github.com/figitaki/mdpub) if you encounter problems during migration.
