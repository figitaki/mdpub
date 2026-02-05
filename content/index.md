# mdpub

A tiny, fast Markdown publisher written in Elixir. Drop your `.md` files in a directory and get a polished documentation site.

## Features

- **Simple** - No complex configuration, just Markdown files
- **Fast** - ETS caching with automatic invalidation
- **Live reload** - Edit files and see changes instantly
- **Portable** - Single binary release, runs anywhere

## Quick Start

```bash
# Clone and run
git clone https://github.com/example/mdpub
cd mdpub
mix deps.get
mix run --no-halt
```

Visit [http://localhost:4000](http://localhost:4000) to see your docs.

## Documentation

| Page | Description |
|------|-------------|
| [Getting Started](/getting-started) | Installation and configuration |
| [Routing](/docs/routing) | URL routing and file structure |
| [Mermaid](/mermaid) | Diagram examples and usage |

## How It Works

mdpub maps URLs directly to Markdown files:

- `/` renders `content/index.md`
- `/foo` renders `content/foo.md` or `content/foo/index.md`
- `/docs/api` renders `content/docs/api.md`

> **Tip:** Edit files under `content/` and refresh to see changes immediately. Hot reloading is enabled by default.

## Built With

- [Elixir](https://elixir-lang.org/) - Functional programming language
- [Bandit](https://github.com/mtrudel/bandit) - HTTP server
- [Earmark](https://github.com/pragdave/earmark) - Markdown parser
