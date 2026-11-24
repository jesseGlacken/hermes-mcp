# syntax=docker/dockerfile:1
FROM python:3.12-slim AS build
COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /usr/local/bin/uv
WORKDIR /src
COPY pyproject.toml README.md LICENSE ./
COPY src ./src
RUN uv venv /opt/venv && VIRTUAL_ENV=/opt/venv uv pip install --no-cache .

FROM python:3.12-slim
ENV PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    BIND_HOST=0.0.0.0 \
    BIND_PORT=8765
COPY --from=build /opt/venv /opt/venv
RUN useradd --system --uid 10001 --no-create-home hermes
USER hermes
EXPOSE 8765
# The OAuth metadata endpoint is unauthenticated and cheap — good liveness probe.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import os,urllib.request;urllib.request.urlopen(f'http://127.0.0.1:{os.environ.get(\"BIND_PORT\",\"8765\")}/.well-known/oauth-authorization-server',timeout=4)" || exit 1
ENTRYPOINT ["hermes-mcp"]
CMD ["serve"]
