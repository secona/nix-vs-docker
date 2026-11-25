# 05 · Scaling running instances

Compare starting three native processes by hand with asking Compose for three local replicas.

## Source and configuration

`server.py` reads `PORT` and reports the hostname and PID. The flake supplies the native launcher. The Dockerfile runs the same source. `compose.yaml` declares one service and asks Docker to allocate a loopback host port per container.

## Build

Run these commands from this directory, or skip to **Run** if you already ran `bash prepare.sh` from the repository root.

```bash
nix flake lock 'path:.'
nix build 'path:.#default'
docker compose build web
```

## Run

Use one Bash session so the process IDs remain available for cleanup.

```bash
app="$(readlink -f result)/bin/fp-scale"
pids=()
for port in 8501 8502 8503; do
  PORT="$port" "$app" &
  pids+=("$!")
done
ps -o pid,args -p "$(IFS=,; echo "${pids[*]}")"
for port in 8501 8502 8503; do curl -sS "http://127.0.0.1:$port/"; echo; done
```

The three commands use one package. Expect the same host name, three distinct process IDs, and the same store source path in the process listing.

```bash
docker compose up --no-build --pull never -d --scale web=1
docker compose ps
docker compose up --no-build --pull never -d --scale web=3
docker compose ps
docker inspect --format '{{.Name}} {{.State.Health.Status}} {{.HostConfig.NanoCpus}} {{.HostConfig.Memory}}' $(docker compose ps -q web)
docker inspect $(docker compose ps -q web) \
  --format '{{.Name}} health={{.State.Health.Status}} memory={{.HostConfig.Memory}} nanoCPUs={{.HostConfig.NanoCpus}}'
for replica in 1 2 3; do
  address=$(docker compose port --index "$replica" web 8000)
  curl -sS "http://$address/"
  echo
done
docker compose up --no-build --pull never -d --scale web=1
docker compose ps
```

Expect one, then three, then one running container. Each replica has its own assigned localhost port and hostname. PIDs can repeat across containers because each has its own PID namespace.

## Interpreting the results

The HTTP health check runs inside each replica. Allow a few seconds for `starting` to change to `healthy`. The inspected settings request 134217728 bytes and half a CPU per replica. Linux enforces configured resource limits through cgroups. The three native processes also share one host kernel and need no additional VMs.

Compose gives these replicas a project network. The curl loop selects a replica by its published port, so it measures reachability, not load balancing. A cluster scheduler can place or replace replicas across healthy nodes. Autoscaling and scale-to-zero additionally need a policy and a source of demand signals. Nix fleet tools such as Colmena and deploy-rs apply configurations to specified hosts; placement and traffic routing require other tooling.

Build scalability concerns producing and reusing artifacts. Runtime scalability concerns running more instances. Orchestration handles their lifecycle and placement. The Nix package supplies one reusable executable, and Bash manages these processes. Compose reconciles a manually requested count on one Docker host. This exercise provides neither automatic scaling nor distributed scheduling. Kubernetes is an example of a production orchestration platform.

## Cleanup

In the shell that launched the native processes run

```bash
kill "${pids[@]}"
wait "${pids[@]}" 2>/dev/null || true
docker compose down
docker image rm fp-scalability:v1
rm -f result
```
