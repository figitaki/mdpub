# Getting Started

Get mdpub running locally in under a minute.

## Prerequisites

You'll need Elixir 1.18+ and Erlang/OTP 27+ installed. Check your versions:

```bash
elixir --version
# Elixir 1.18.0 (compiled with Erlang/OTP 27)
```

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/example/mdpub
cd mdpub

# Install dependencies
mix deps.get

# Start the server
mix run --no-halt
```

The server starts on [http://localhost:4000](http://localhost:4000) by default.

### Using a Release

For production deployments, build and run a release:

```bash
# Build the release
MIX_ENV=prod mix release

# Run it
_build/prod/rel/mdpub/bin/mdpub start
```

## Configuration

mdpub is configured via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `4000` | HTTP port to listen on |
| `MDPUB_CONTENT_DIR` | `./content` | Directory containing Markdown files |
| `MDPUB_WATCH` | `true` | Enable file watching for hot reload |
| `MDPUB_BASE_PATH` | `` | Base path prefix for URLs |

### Example

```bash
PORT=8080 MDPUB_CONTENT_DIR=/var/docs mix run --no-halt
```

## Directory Structure

Organize your content in a simple directory structure:

```
content/
  index.md           # Home page (/)
  getting-started.md # /getting-started
  docs/
    index.md         # /docs
    api.md           # /docs/api
    routing.md       # /docs/routing
```

> **Note:** Each directory can have an `index.md` that serves as the default page for that path.

## Adding Content

Create Markdown files in your content directory. mdpub supports:

- **Headings** (h1-h6)
- **Lists** (ordered and unordered)
- **Code blocks** with syntax highlighting
- **Tables**
- **Blockquotes**
- **Links and images**
- **Inline formatting** (bold, italic, code)

### Code Blocks

Use fenced code blocks with a language identifier:

```elixir
defmodule Hello do
  def world do
    IO.puts("Hello, world!")
  end
end
```

```javascript
function greet(name) {
  console.log(`Hello, ${name}!`);
}
```

### Tables

Create tables using pipes and dashes:

```markdown
| Name | Type | Required |
|------|------|----------|
| id   | int  | Yes      |
| name | str  | No       |
```

## Next Steps

- Learn about [URL routing](/docs/routing)
- Explore the source code on GitHub
