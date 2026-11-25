# 01 · Deployment

Follow one HTTP request to each deployment of the same source and inspect the two build artifacts.

## Source and configuration

`server.py` responds with JSON. `flake.nix` writes a launcher with absolute store paths for Python and the source file. `Dockerfile` copies the same source into a Python base image. `HOST` and `PORT` select the listening address.

## Build

Run these commands from this directory, or skip to **Run** if you already ran `bash prepare.sh` from the repository root.

```bash
nix flake lock 'path:.'
nix build 'path:.#default'
docker build -t fp-deployment:v1 .
```

## Run

Inspect the built package in terminal A.

```bash
readlink -f result
cat result/bin/fp-deployment
nix-store -q --references "$(readlink -f result)"
PORT=8101 ./result/bin/fp-deployment
```

Leave the server in the foreground. In terminal B, from this directory, run

```bash
docker image ls fp-deployment
docker run -d --name fp-deployment-web -p 127.0.0.1:8102:8000 fp-deployment:v1
curl -sS http://127.0.0.1:8101/
curl -sS http://127.0.0.1:8102/
```

Each response contains `version` (`v1`), `python` and `hostname`. Expect the host name on 8101 and a container hostname on 8102. The direct references include the selected Python and application source. The launcher also needs its shell interpreter. The local image listing shows the tagged image.

## Interpreting the results

Use the launcher to trace a runtime dependency from an executable into `/nix/store`. Docker distributes a filesystem and image configuration together. Both mechanisms reuse artifacts. These requests demonstrate packaging and execution, and provide no measurement of startup speed or image size.

## Cleanup

Stop the native server with Ctrl-C in terminal A. In terminal B run

```bash
docker rm -f fp-deployment-web
docker image rm fp-deployment:v1
rm -f result
```
