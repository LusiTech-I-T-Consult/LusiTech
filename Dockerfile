FROM python:3.10-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Make entrypoint script executable
RUN chmod +x /app/entrypoint.sh

# Collect static files
RUN mkdir -p /app/staticfiles
RUN python manage.py collectstatic --noinput

# Run entrypoint script
ENTRYPOINT ["/app/entrypoint.sh"]