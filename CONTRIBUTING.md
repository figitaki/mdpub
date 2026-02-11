# Contributing

Thanks for contributing to mdpub!

## Commit messages (Conventional Commits)

This repo enforces [Conventional Commits](https://www.conventionalcommits.org/).

Examples:

- `feat: add directory index support`
- `fix: handle empty frontmatter`
- `docs: clarify config options`
- `chore: bump dependencies`

## Manual release workflow (GitHub)

Releases are triggered by pushing a `v*` git tag. The container publish workflow will run on the tag.

1. Ensure `main` is up to date and tests pass.
2. Bump the version in `mix.exs`.
3. Commit the version bump:

   ```bash
   git commit -am "chore(release): vX.Y.Z"
   ```

4. Tag and push:

   ```bash
   git tag -a vX.Y.Z -m "vX.Y.Z"
   git push origin main --tags
   ```

5. Create the GitHub release (requires `gh`):

   ```bash
   gh release create vX.Y.Z --generate-notes
   ```

The tag push triggers the container build/publish workflow.
