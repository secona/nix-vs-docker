#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ ${1:-} == --check ]]; then
  for artifact in \
    01-deployment/result/bin/fp-deployment \
    02-reproducibility/result-{first,again,changed}/message.txt \
    03-isolation/{result,result-alternate}/bin/fp-isolation \
    04-rollback/result-{v1,v2}/bin/fp-rollback \
    05-scalability/result/bin/fp-scale \
    06-integration/result/bin/fp-integration 06-integration/result-image; do
    if [[ ! -r "$artifact" ]]; then
      echo "Missing prepared artifact: $artifact" >&2
      exit 1
    fi
  done
  docker image inspect alpine:3.22 fp-deployment:v1 fp-repro:{cached,fresh} \
    fp-isolation:v1 fp-rollback:{v1,v2} fp-scalability:v1 >/dev/null
  echo "Local packages, image tags and the integration archive are present."
  exit 0
fi

(
  cd 01-deployment
  nix flake lock 'path:.'
  nix build 'path:.#default'
  docker build -t fp-deployment:v1 .
)

(
  cd 02-reproducibility
  nix flake lock 'path:.'
  nix build 'path:.#default' -o result-first
  nix build 'path:.#default' -o result-again
  nix build --rebuild 'path:.#default' -o result-first
  nix build 'path:.#changed' -o result-changed
  docker pull alpine:3.22
  docker build -t fp-repro:cached .
  docker build -t fp-repro:cached .
  sleep 2
  docker build --no-cache -t fp-repro:fresh .
)

(
  cd 03-isolation
  nix flake lock 'path:.'
  nix build 'path:.#default'
  nix build 'path:.#alternate' -o result-alternate
  docker build -t fp-isolation:v1 .
)

(
  cd 04-rollback
  nix flake lock 'path:.'
  nix build 'path:.#default' -o result-v1
  nix build 'path:.#v2' -o result-v2
  docker build --build-arg VERSION=v1 -t fp-rollback:v1 .
  docker build --build-arg VERSION=v2 -t fp-rollback:v2 .
)

(
  cd 05-scalability
  nix flake lock 'path:.'
  nix build 'path:.#default'
  docker compose build web
)

(
  cd 06-integration
  nix flake lock 'path:.'
  nix build 'path:.#default'
  nix build 'path:.#image' -o result-image
)
