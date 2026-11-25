# Nix vs Docker

What changes when you package the same Python HTTP server with Nix and Docker? With Nix, you can open the generated launcher and see exactly which Python interpreter it runs. With Docker, you can start the image in a container and see which parts of the host filesystem the server can reach.

These six local examples explore how those differences affect deployment, rebuilds, updates, and running multiple instances. The final example combines both tools by building a Docker image from the same Nix package used to run the server natively.

## Examples

| Example | What to look for |
|---|---|
| [Deployment](01-deployment/README.md) | Run the same server from a Nix store path and a Docker image, then query both endpoints. |
| [Reproducibility](02-reproducibility/README.md) | Verify a Nix rebuild and observe what happens to a timestamp when Docker’s build cache is bypassed. |
| [Isolation](03-isolation/README.md) | Run two Python versions side by side. Check which processes can read a temporary host file. |
| [Updates and rollbacks](04-rollback/README.md) | Use one Nix function to produce two releases. Switch profile generations and redeploy image tags. |
| [Scaling](05-scalability/README.md) | Start three processes from one package, then scale a Compose service and query each replica. |
| [Integration](06-integration/README.md) | Build a container image with `dockerTools.buildLayeredImage`, load it into Docker, and run it. |

## Getting started

If this checkout has already been prepared, run `bash prepare.sh --check` from the repository root. It checks for the local artifacts without building or starting services. On success, go straight to **Run** in any example.

The examples target NixOS on x86_64 Linux. You’ll need Nix with `flakes` and `nix-command` enabled, access to a local Docker Engine with Compose v2, Bash, and curl. The first build needs network access to fetch dependencies. Each example supplies its own Python interpreter where needed.

To build all six examples ahead of time, run `bash prepare.sh` from the repository root. It leaves the Nix output links and Docker images in place and verifies the Nix rebuild in the reproducibility example. Each example’s **Run** section uses those artifacts. Keep them until you finish using the examples, then follow their cleanup instructions.

Pick any example and follow its README from that directory. To try the native half of the deployment example from the repository root, run

```bash
cd 01-deployment
cat result/bin/fp-deployment
PORT=8101 ./result/bin/fp-deployment
```

In another terminal, run `curl http://127.0.0.1:8101/` to see the application version, Python version, and hostname. Stop the server with Ctrl-C. The deployment walkthrough includes the Docker commands and cleanup for both builds.
