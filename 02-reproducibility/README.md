# 02 · Reproducibility

Separate cache reuse, independent rebuild verification, and the effect of changing one declared input.

## Source and configuration

`flake.nix` calls `mkMessage` twice with different strings. Nix passes `message` to the builder as an environment variable. The builder uses the declared Coreutils input to create the output directory and writes `message.txt`. The build platform, builder, script, environment and dependency paths participate in the derivation. `Dockerfile` reads the build-time clock on top of a mutable Alpine tag.

## Build

Run these commands from this directory, or skip to **Run** if you already ran `bash prepare.sh` from the repository root.

```bash
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
```

## Run

Inspect the pin and compare the outputs from the build step.

```bash
cat flake.lock
readlink -f result-first result-again
readlink -f result-first result-changed
cat result-first/message.txt result-changed/message.txt
```

Find `nodes.nixpkgs.locked.rev` (exact Git commit) and `narHash` (hash of the fetched source tree). The first pair of links resolves to the same path. The second ordinary build can reuse the existing output. With an existing output, `--rebuild` runs the builder again and checks the result against the store copy. Expect success for this builder. The changed input yields a different path, and both files remain readable as `first` and `second`.

```bash
docker run --rm fp-repro:cached
docker run --rm fp-repro:fresh
docker image inspect alpine:3.22 --format '{{index .RepoDigests 0}}'
```

The ordinary build can reuse the timestamp layer from the first build. The uncached build executes `date` again and prints a later timestamp when run. The inspect command shows the locally pulled base’s immutable digest reference. Use that reference as the `BASE` build argument to pin the base. The timestamp will still depend on the clock.

## Interpreting the results

Inspect the image history together with the two timestamps.

```bash
docker history fp-repro:fresh
docker image inspect fp-repro:cached fp-repro:fresh --format '{{json .RootFS.Layers}}'
```

Read the layer lists from base to top. With the same local base, the lists share the base layer IDs and diverge at the timestamp layer. During a Dockerfile build, a changed input to an earlier step can invalidate downstream steps. Putting stable dependency steps before frequently edited source can improve reuse in CI. In Nix, independent derivations can reuse their existing outputs when a sibling changes. A shared binary cache extends that reuse to other builders.

A pinned base digest fixes the base filesystem. A subsequent `apt-get update` against a changing repository could still select a different package. Likewise, a flake lock pins source inputs. The dependency closure helps trace what shipped, but a full SBOM and signed build provenance require additional work.

An ordinary Nix output path identifies a build recipe and its inputs. Seeing that path twice alone gives no independent evidence of byte equality. Rebuild verification covers this output on this machine. Pinning and sandboxing reduce sources of variation, while time, randomness or nondeterministic tooling can still affect builds. The Docker timestamp is deliberate. A mutable tag *can* move, but this exercise does not observe a tag changing. Docker builds can also use pinned inputs and deterministic build steps.

## Cleanup

```bash
docker image rm fp-repro:cached fp-repro:fresh
rm -f result-first result-again result-changed
```
