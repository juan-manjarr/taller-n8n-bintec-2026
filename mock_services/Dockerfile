# Imagen única para los tres servicios mock (Risk, Fraud, CRM).
# El servicio a ejecutar se elige con la variable SERVICE (risk | fraud | crm).
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    SERVICE=risk

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY *.py ./

RUN useradd --create-home --uid 1001 appuser
USER appuser

EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

CMD ["sh", "-c", "exec uvicorn ${SERVICE}_service:app --host 0.0.0.0 --port 8000"]
