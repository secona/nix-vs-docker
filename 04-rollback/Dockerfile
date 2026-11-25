FROM python:3.12-slim
WORKDIR /app
COPY server.py .
ENV HOST=0.0.0.0 PORT=8000
ARG VERSION=v1
ENV APP_VERSION=$VERSION
ENTRYPOINT ["sh", "-c", "exec python /app/server.py --app-version \"$APP_VERSION\" \"$@\"", "--"]
