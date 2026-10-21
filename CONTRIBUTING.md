# Contributing

- Branch from `main` as `<type>/<short-description>`, one pull request per change.
- Title pull requests `<type>(<scope>): <change>`, in Conventional Commit style.
- `make check` must pass; CI's `check` job runs it and is required.
- A maintainer named in `.github/CODEOWNERS` approves every pull request.
- Pull requests are squash-merged; the pull request title is the commit subject.
