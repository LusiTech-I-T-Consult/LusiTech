#!/bin/bash
set -e

# Update and install dependencies
apt-get update
apt-get install -y python3-pip python3-venv nginx supervisor git awscli jq

# Get database credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id ${db_secret_arn} --region ${aws_region} --query SecretString --output text)
DB_USERNAME=$(echo $DB_SECRET | jq -r '.username')
DB_PASSWORD=$(echo $DB_SECRET | jq -r '.password')

# Set environment variables
echo "export DB_HOST=${db_endpoint}" >> /etc/environment
echo "export DB_NAME=${db_name}" >> /etc/environment
echo "export DB_USER=$DB_USERNAME" >> /etc/environment
echo "export DB_PASSWORD=$DB_PASSWORD" >> /etc/environment
echo "export S3_BUCKET=${s3_bucket}" >> /etc/environment
echo "export AWS_REGION=${aws_region}" >> /etc/environment
echo "export IS_PRIMARY=${is_primary}" >> /etc/environment

# Create app directory
mkdir -p /var/www/django-app

# Clone the application repository or sync from S3
cd /var/www/django-app

# If we're in DR mode, sync the application state from S3
if [ "${is_primary}" = "false" ]; then
  aws s3 sync s3://${s3_bucket}/app-backup/ /var/www/django-app/
else
  # For primary region, we might pull from a git repository instead
  # git clone https://your-repo-url.git .
  # Or sync from S3 bucket if you have pre-deployed code there
  aws s3 sync s3://${s3_bucket}/app-backup/ /var/www/django-app/
  
  # Set up a cron job to regularly backup the app to S3
  echo "*/30 * * * * root aws s3 sync /var/www/django-app/ s3://${s3_bucket}/app-backup/" > /etc/cron.d/app-backup
fi

# Set up Python virtual environment
python3 -m venv /var/www/django-app/venv
source /var/www/django-app/venv/bin/activate
pip install -r /var/www/django-app/requirements.txt

# Configure Nginx
cat > /etc/nginx/sites-available/django-app << 'EOF'
server {
    listen 80;
    server_name _;

    location /static/ {
        alias /var/www/django-app/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/django-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Configure Supervisor to run the Django application
cat > /etc/supervisor/conf.d/django-app.conf << 'EOF'
[program:django-app]
directory=/var/www/django-app
command=/var/www/django-app/venv/bin/gunicorn website.wsgi:application --bind 127.0.0.1:8000 --workers 3
autostart=true
autorestart=true
stdout_logfile=/var/log/django-app.log
stderr_logfile=/var/log/django-app-error.log
environment=PATH="/var/www/django-app/venv/bin"
user=www-data
group=www-data
EOF

# Fix permissions
chown -R www-data:www-data /var/www/django-app

# Collect static files
cd /var/www/django-app
source venv/bin/activate
python manage.py collectstatic --noinput

# Run migrations if in primary region or if DB is ready in DR
if [ "${is_primary}" = "true" ]; then
  python manage.py migrate --noinput
  
  # Create superuser if needed (you might want to use environment variables here)
  # python manage.py createsuperuser --noinput
fi

# Restart services
supervisorctl reread
supervisorctl update
service nginx restart

# Health check endpoint for load balancer
cat > /var/www/health.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
</head>
<body>
    <h1>OK</h1>
</body>
</html>
EOF

chown www-data:www-data /var/www/health.html

echo "Instance setup complete"