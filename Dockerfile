# Multi-stage: build (runs tests) -> final
FROM python:3.11-slim AS base
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

FROM base AS test
# Run tests during image build; fail build if tests fail
RUN pytest -q

FROM base AS final
EXPOSE 8000
CMD ["python", "app.py"]
