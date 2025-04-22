#!/bin/bash
set -e

# Update and install dependencies
yum update -y
yum install -y python3-pip nginx git jq
amazon-linux-extras install nginx1

# Install and configure supervisor
curl https://pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
pip3 install supervisor

mkdir -p /etc/supervisor/conf.d
mkdir -p /var/log/supervisor

# Create supervisord.conf
cat > /etc/supervisord.conf << 'EOF'
[unix_http_server]
file=/tmp/supervisor.sock

[supervisord]
logfile=/var/log/supervisor/supervisord.log
logfile_maxbytes=50MB
logfile_backups=10
loglevel=info
pidfile=/tmp/supervisord.pid
nodaemon=false
minfds=1024
minprocs=200

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
EOF

# Create supervisor service
cat > /etc/systemd/system/supervisord.service << 'EOF'
[Unit]
Description=Supervisor process control system
Documentation=http://supervisord.org
After=network.target

[Service]
ExecStart=/usr/local/bin/supervisord -n -c /etc/supervisord.conf
ExecStop=/usr/local/bin/supervisorctl shutdown
ExecReload=/usr/local/bin/supervisorctl reload
KillMode=process
Restart=on-failure
RestartSec=50s

[Install]
WantedBy=multi-user.target
EOF

# Get database credentials from Secrets Manager
DB_SECRET=$(aws secretsmanager get-secret-value --secret-id ${db_secret_arn} --region ${aws_region} --query SecretString --output text)
DB_USERNAME=$(echo $DB_SECRET | jq -r '.username')
DB_PASSWORD=$(echo $DB_SECRET | jq -r '.password')

# Create environment file for the application
cat > /var/www/django-app.env << EOF
DB_HOST=${db_endpoint}
DB_NAME=${db_name}
DB_USER=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
S3_BUCKET=${s3_bucket}
AWS_REGION=${aws_region}
IS_PRIMARY=${is_primary}
EOF

# Export environment variables for immediate use
export DB_HOST=${db_endpoint}
export DB_NAME=${db_name}
export DB_USER=$DB_USERNAME
export DB_PASSWORD=$DB_PASSWORD
export S3_BUCKET=${s3_bucket}
export AWS_REGION=${aws_region}
export IS_PRIMARY=${is_primary}

# Create app directory and set permissions
mkdir -p /var/www/django-app
chown nginx:nginx /var/www/django-app

# Install Docker and Git
echo "=== Installing Docker and Git ==="
yum update -y
yum install -y git docker
systemctl enable docker
systemctl start docker

# Install Docker Compose
echo "=== Installing Docker Compose ==="
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create app directory and clone repository
echo "=== Cloning application from GitHub ==="
mkdir -p /app
cd /app
git clone https://github.com/LusiTech-I-T-Consult/LusiTech.git .

# Create production environment file
echo "=== Creating production environment file ==="
cat > /app/.env << EOF
DEBUG=0
DJANGO_SETTINGS_MODULE=website.settings
ALLOWED_HOSTS=*
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=$DB_HOST
DB_PORT=5432
AWS_REGION=$AWS_REGION
IS_PRIMARY=$IS_PRIMARY
EOF

# Configure AWS credentials for Docker
mkdir -p /root/.aws
cat > /root/.aws/credentials << EOF
[default]
region = ${aws_region}
aws_access_key_id = ${aws_access_key}
aws_secret_access_key = ${aws_secret_key}
EOF

# Build and start Docker containers
echo "=== Building and starting Docker containers ==="
cd /app
docker-compose -f docker-compose.yml build
docker-compose -f docker-compose.yml up -d

# Setup periodic backups to S3 if primary
S3_BUCKET="pilot-light-dr-prod-eu-west-1"
if [ "${is_primary}" = "true" ]; then
    echo "=== Setting up S3 backup for primary instance ==="
    echo "*/30 * * * * root cd /app && /usr/local/bin/docker-compose exec -T web python manage.py backup_to_s3 s3://$S3_BUCKET/app-backup/" > /etc/cron.d/app-backup
fi

# Install and configure Nginx
yum install -y nginx
systemctl enable nginx

# Configure Nginx as reverse proxy
cat > /etc/nginx/conf.d/django-app.conf << 'EOF'
server {
    listen 80;
    server_name _;

    location /static/ {
        alias /app/static/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
    }

    # Health check endpoint
    location /health/ {
        access_log off;
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

# Start Nginx
systemctl start nginx

# Wait for services to be fully started
sleep 10

# Verify services
echo "=== Checking Nginx status ==="
systemctl status nginx

echo "=== Checking Docker containers ==="
docker ps

echo "=== Checking Docker logs ==="
docker-compose -f /app/docker-compose.yml logs --tail=50

# Create a startup check script
cat > /app/check_services.sh << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet nginx; then
    systemctl restart nginx
fi

if ! docker ps | grep -q django-app; then
    cd /app && docker-compose up -d
fi
EOF

chmod +x /app/check_services.sh

# Add service check to crontab
echo "*/5 * * * * root /app/check_services.sh" > /etc/cron.d/check_services

echo "Instance setup complete"
