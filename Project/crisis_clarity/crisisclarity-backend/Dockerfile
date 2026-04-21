# Stage 1: Build stage
FROM python:3.10-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Production stage
FROM python:3.10-slim

WORKDIR /app

# Create a non-root user for security
RUN groupadd -r crisisuser && useradd -r -g crisisuser crisisuser

# Copy installed packages from builder
COPY --from=builder /root/.local /home/crisisuser/.local
COPY . .

# Set environment variables
ENV PATH=/home/crisisuser/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1
ENV PORT=8000

# Change ownership to non-root user
RUN chown -R crisisuser:crisisuser /app
USER crisisuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

# Expose the application port
EXPOSE 8000

# Run the FastAPI application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
