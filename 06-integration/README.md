# 06 · Build with Nix, run with Docker

Use one Nix application definition both as a native package and as the entry point in a Docker-compatible image.

## Source and configuration

`flake.nix` exports `default` (a launcher that refers to Python and `server.py` by store path) and `image`. `dockerTools.buildLayeredImage` includes the application and its referenced runtime closure. The image configuration calls the launcher by absolute path and sets its listening address.

## Build

Run these commands from this directory, or skip to **Run** if you already ran `bash prepare.sh` from the repository root.

```bash
nix flake lock 'path:.'
nix build 'path:.#default'
nix build 'path:.#image' -o result-image
```

## Run

Inspect the native entry point and import the prepared image archive.

```bash
cat result/bin/fp-integration
readlink -f result-image
docker load -i result-image
docker run -d --name fp-integration-web -p 127.0.0.1:8601:8000 fp-integration:v1
curl -sS http://127.0.0.1:8601/
```

Expect a native launcher under `result/bin`, a loadable image archive behind `result-image`, a loaded image named `fp-integration:v1`, and a JSON response with `message` equal to `Hello from Nix`.

## Interpreting the results

The native package is an input to image construction. Docker starts it using the entry point recorded in the image. A CI/CD pipeline could build this archive, load and push the image to a registry, and deploy it by digest to Kubernetes or a cloud container service. The local run verifies the packaging workflow when performed. It does not exercise publication or cluster deployment.

## Cleanup

```bash
docker rm -f fp-integration-web
docker image rm fp-integration:v1
rm -f result result-image
```
