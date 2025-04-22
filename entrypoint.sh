#!/bin/bash

# Wait for RDS database to be ready
echo "Waiting for RDS database connection..."

# Attempt to connect to the RDS database, retry if it fails
until PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -c '\q' 2>/dev/null; do
  echo "RDS database is unavailable - sleeping"
  sleep 2
done

echo "RDS database connection established"

# Apply database migrations
echo "Applying migrations..."
python manage.py migrate

# Create superuser if needed (optional)
if [ "$DJANGO_SUPERUSER_USERNAME" ] && [ "$DJANGO_SUPERUSER_EMAIL" ] && [ "$DJANGO_SUPERUSER_PASSWORD" ]; then
    python manage.py createsuperuser --noinput
fi

# Start Gunicorn
echo "Starting Gunicorn..."
exec gunicorn website.wsgi:application --bind 0.0.0.0:8000