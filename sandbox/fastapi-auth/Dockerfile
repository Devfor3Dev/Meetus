# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder
ENV PIP_NO_CACHE_DIR=1 PIP_DISABLE_PIP_VERSION_CHECK=1
WORKDIR /build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install -r requirements.txt

FROM python:3.12-slim AS runtime
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 PATH="/opt/venv/bin:$PATH"
RUN useradd --system --create-home --uid 10001 loveline
WORKDIR /srv
COPY --from=builder /opt/venv /opt/venv
COPY --chown=loveline:loveline app ./app
COPY --chown=loveline:loveline migrations ./migrations
COPY --chown=loveline:loveline alembic.ini ./
USER loveline
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health/live', timeout=3).status == 200 else 1)"
# Les migrations passent avant le démarrage. Avec plusieurs instances, lancez-les plutôt
# dans une étape de déploiement séparée pour éviter deux migrations simultanées.
CMD ["sh", "-c", "alembic upgrade head && exec uvicorn app.main:app_factory --factory --host 0.0.0.0 --port 8000 --proxy-headers"]
