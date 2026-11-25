# 04 · Updates and rollbacks

Switch between two application releases and inspect the objects that make each rollback possible.

## Source and configuration

`mkApp` in `flake.nix` takes a version string and embeds it in the launcher for `server.py`. The Dockerfile embeds the `VERSION` build argument in its runtime environment and forwards command-line arguments. Without `--version`, each package serves the version as JSON.

## Build

Run these commands from this directory, or skip to **Run** if you already ran `bash prepare.sh` from the repository root.

```bash
nix flake lock 'path:.'
nix build 'path:.#default' -o result-v1
nix build 'path:.#v2' -o result-v2
docker build --build-arg VERSION=v1 -t fp-rollback:v1 .
docker build --build-arg VERSION=v2 -t fp-rollback:v2 .
```

## Run

Use the same Bash session throughout. Point every profile operation at a new temporary path.

```bash
profile_dir=$(mktemp -d)
profile="$profile_dir/app"
nix-env -p "$profile" --set "$(readlink -f result-v1)"
"$profile/bin/fp-rollback" --version
readlink "$profile"
nix-env -p "$profile" --set "$(readlink -f result-v2)"
"$profile/bin/fp-rollback" --version
nix-env -p "$profile" --list-generations
ls -l "$profile_dir"
nix-env -p "$profile" --rollback
readlink "$profile"
"$profile/bin/fp-rollback" --version
readlink -f result-v1 result-v2
```

Expect `v1`, then `v2`, then `v1`. The profile link selects a numbered generation link. Each generation points into the store, and both versioned build links still resolve. The example uses the `nix-env` profile interface throughout.

```bash
docker run -d --name fp-rollback-web -p 127.0.0.1:8401:8000 fp-rollback:v1
curl -sS http://127.0.0.1:8401/
docker rm -f fp-rollback-web
docker run -d --name fp-rollback-web -p 127.0.0.1:8401:8000 fp-rollback:v2
curl -sS http://127.0.0.1:8401/
docker rm -f fp-rollback-web
docker run -d --name fp-rollback-web -p 127.0.0.1:8401:8000 fp-rollback:v1
curl -sS http://127.0.0.1:8401/
docker image ls fp-rollback
```

The endpoint reports the same version sequence. Both local tags remain available after container replacement.

## Interpreting the results

The profile switch atomically changes which generation a new lookup selects. To see how two release packages share dependencies, inspect their direct references and compare their launchers.

```bash
nix-store -q --references "$(readlink -f result-v1)"
nix-store -q --references "$(readlink -f result-v2)"
cat result-{v1,v2}/bin/fp-rollback
docker image inspect fp-rollback:v1 fp-rollback:v2 --format '{{.Id}} {{json .RootFS.Layers}}'
```

Both launchers refer to the same Python store path. In these Dockerfiles only the configured version changes, so the images can have different IDs and identical filesystem layers. Inspect the actual IDs on your machine. A Nix binary cache can distribute missing store paths and a registry can distribute missing layer blobs. The transfer units differ; neither observation measures network traffic.

### Move a tag while v1 is running

After the rollback above, the service on 8401 is running v1. Point a separate local tag at each release in turn.

```bash
docker tag fp-rollback:v1 fp-rollback:trial
docker run --rm fp-rollback:trial --version
docker tag fp-rollback:v2 fp-rollback:trial
docker run --rm fp-rollback:trial --version
curl -sS http://127.0.0.1:8401/
docker image rm fp-rollback:trial
```

The new launches report v1 and v2. The existing container still reports v1. A deployment pinned to a registry digest can select the same image after a tag moves.

### Try two releases side by side

```bash
docker run -d --name fp-rollback-candidate -p 127.0.0.1:8402:8000 fp-rollback:v2
for port in 8401 8401 8401 8402; do curl -fsS "http://127.0.0.1:$port/"; echo; done
docker rm -f fp-rollback-candidate
```

Here the client sends one of four requests to the candidate. A canary deployment automates that traffic split. Blue/green switches the active route between two available releases. A rolling update progressively replaces replicas. Swarm can roll back a service specification on update failure, while the earlier local commands explicitly recreate one container. Health checks, traffic switching and service rollback each handle a different part of a release.

Generations preserve a choice of immutable packages, so the next profile-based launch uses the selected version. A switch alone leaves an already running process executing its original code. Docker rollback here recreates a container from a retained tag. Neither approach automatically restores mutable application data. This stateless example does not demonstrate database rollback or zero-downtime updates.

## Cleanup

In the original shell remove only this profile’s links and named Docker artifacts.

```bash
docker rm -f fp-rollback-web
docker image rm fp-rollback:v1 fp-rollback:v2
rm -f "$profile" "$profile_dir"/app-*-link result-v1 result-v2
rmdir "$profile_dir"
```
