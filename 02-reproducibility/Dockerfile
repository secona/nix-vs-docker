ARG BASE=alpine:3.22
FROM ${BASE}
RUN date -u +%Y-%m-%dT%H:%M:%SZ > /built-at
CMD ["cat", "/built-at"]
