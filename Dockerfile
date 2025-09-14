# Build frontend inside Docker
FROM node:18-alpine AS frontend-builder
WORKDIR /frontend

# Copy frontend source
COPY ../elysia-frontend/package*.json ./
RUN npm ci

COPY ../elysia-frontend/ ./
RUN npm run build
RUN npm run export || mkdir -p out

# Build backend with frontend static files
FROM python:3.11-slim
WORKDIR /app

# Copy backend code
COPY . .

# Create static directory and copy frontend build
RUN mkdir -p elysia/api/static
COPY --from=frontend-builder /frontend/out/* ./elysia/api/static/ 2>/dev/null || true

# Install Python dependencies
RUN pip install -e .

# Create data directory
RUN mkdir -p /data/dspy_cache

RUN sed -i 's/os.getenv("WEAVIATE_IS_LOCAL", "False") == "True"/os.getenv("WEAVIATE_IS_LOCAL", "False") in ["True", "true", "1"]/g' /app/elysia/config.py


EXPOSE 8000
CMD ["uvicorn", "elysia.api.app:app", "--host", "0.0.0.0", "--port", "8000"]