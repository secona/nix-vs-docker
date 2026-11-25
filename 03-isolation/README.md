# 03 · Isolation

Observe dependency selection and runtime file access separately, then discuss where build sandboxing applies.

## Source and configuration

`mkServer` in `flake.nix` takes an interpreter package. Each launcher references the same `server.py` and its selected interpreter. The server opens only the path supplied in `MARKER` and checks the first byte of the demo marker. The Dockerfile runs this source with the base image’s Python.

## Build

Run these commands from this directory, or skip to **Run** if you already ran `bash prepare.sh` from the repository root.

```bash
nix flake lock 'path:.'
nix build 'path:.#default'
nix build 'path:.#alternate' -o result-alternate
docker build -t fp-isolation:v1 .
```

## Run

In terminal A, keep the same Bash session for the marker and Docker commands.

```bash
marker=$(mktemp /tmp/fp-isolation.XXXXXXXX)
printf 'fp marker\n' > "$marker"
readlink -f result result-alternate
cat result/bin/fp-isolation result-alternate/bin/fp-isolation
MARKER="$marker" PORT=8301 ./result/bin/fp-isolation &
native_pid=$!
MARKER="$marker" PORT=8302 ./result-alternate/bin/fp-isolation &
alternate_pid=$!
docker run -d --name fp-isolation-web -e MARKER="$marker" \
  -p 127.0.0.1:8303:8000 fp-isolation:v1
curl -sS http://127.0.0.1:8301/
curl -sS http://127.0.0.1:8302/
curl -sS http://127.0.0.1:8303/
```

Expect Python 3.12 and 3.13 on the native ports, the host hostname and `marker_readable: true` for both. Expect the container hostname and `false` on 8303. To expose only this file and repeat the observation, run

```bash
docker run -d --name fp-isolation-mounted -e MARKER="$marker" \
  --mount "type=bind,src=$marker,dst=$marker,readonly" \
  -p 127.0.0.1:8304:8000 fp-isolation:v1
curl -sS http://127.0.0.1:8304/
```

Expect `marker_readable: true` with the mount.

### Optional build-time observation

While the marker exists, use the local Nix builder. The probe checks for files matching the demo marker pattern in its own view of `/tmp`.

```bash
nix build 'path:.#sandboxProbe' -o result-probe
nix build --rebuild 'path:.#sandboxProbe' -o result-probe
cat result-probe
```

The second command forces a fresh build even if the first used a cached result. With the usual Linux build sandbox, expect `No demo marker visible to builder`. A failure reporting a visible marker means the builder could see a matching file. Interpret the result in light of your daemon settings and keep those settings unchanged.

## Interpreting the results

Dependency isolation lets both interpreters coexist. A sandboxed Nix build restricts the builder’s view of host files, subject to daemon settings. The HTTP observations concern runtime only. Native launches inherit the user’s ordinary file permissions. Docker gives the process a container filesystem and namespaces, and a bind mount grants explicit access. This one marker is not a general security test.

## Cleanup

In the original shell run

```bash
kill "$native_pid" "$alternate_pid"
wait "$native_pid" "$alternate_pid" 2>/dev/null || true
docker rm -f fp-isolation-web
# If you ran the mount example:
# docker rm -f fp-isolation-mounted
docker image rm fp-isolation:v1
rm -f "$marker" result result-alternate result-probe
```
