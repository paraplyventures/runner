# runner

A GitHub Actions runner image for self-hosted runners (for example
[Actions Runner Controller](https://github.com/actions/actions-runner-controller)
scale sets) that behaves more like a GitHub-hosted runner.

It is GitHub's [`actions-runner`](https://github.com/actions/runner/pkgs/container/actions-runner)
image plus:

- build tools: `build-essential` (make, gcc), `pkg-config`, `libssl-dev`;
- common tools: git-lfs, curl, wget, jq, zip/unzip, xz, zstd, bzip2, rsync,
  file, ssh, gnupg, netcat, dig, ping, sqlite3, python3 with venv and pip;
- Docker Compose;
- the libraries Playwright's Chromium needs, fonts and xvfb;
- Rust: rustup and the current stable toolchain with rustfmt and clippy;
- Go, the current release at build time;
- `postgresql-client-18` from the PostgreSQL apt repository;
- a UTF-8 locale (`LANG=C.UTF-8`), which Erlang, Python and others expect;
- `/run/lock` (`/var/lock` points there), which only a booted system creates.
  ARC's Docker-in-Docker mode mounts a volume over `/var/run`, which hides it;
  there, start the runner with
  `bash -c "sudo install -d -m 1777 /run/lock; exec /home/runner/run.sh"`.

```
ghcr.io/paraplyventures/runner:2.338.2           # rebuilt weekly
ghcr.io/paraplyventures/runner:2.338.2-YYYYMMDD  # one build
```

Rebuilt every Monday for security updates; Dependabot bumps the runner
version. MIT licensed.
