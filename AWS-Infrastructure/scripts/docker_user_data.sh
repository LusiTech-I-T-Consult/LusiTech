#!/bin/bash
set -e

# Install Docker and Git
echo "=== Installing Docker and Git ==="
yum update -y
yum install -y docker git
systemctl enable docker
systemctl start docker

# Install Docker Compose
echo "=== Installing Docker Compose ==="
mkdir -p /usr/local/lib/docker/cli-plugins
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# Install Nginx
echo "=== Installing Nginx ==="
amazon-linux-extras enable nginx1
yum clean metadata
yum install -y nginx
systemctl enable nginx
systemctl start nginx

# Configure Nginx temporary HTTP server (for Certbot challenge)
echo "=== Temporary Nginx Configuration for HTTP Challenge ==="
cat > /etc/nginx/conf.d/lusitech.conf << EOF
server {
    listen 80;
    server_name lusitechitconsult.com www.lusitechitconsult.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

systemctl restart nginx

# Create app directory and clone repository
# echo "=== Cloning application from GitHub ==="
# mkdir -p /app
# cd /app
# git clone https://github.com/LusiTech-I-T-Consult/LusiTech.git .

# Wait for Docker to be ready
echo "=== Waiting for Docker to be ready ==="
timeout 60 bash -c 'until docker info; do sleep 1; done'

# # Build and start Docker container
# echo "=== Building and starting Docker container ==="
# cd /app
# docker build -t lusitech .
# docker run -p 8000:8000 -d lusitech
#
echo "=== Pulling and starting Docker container from Docker Hub ==="
docker pull lusitech/lusitech-website:v2
docker run -d -p 8000:8000 --name lusitech lusitech/lusitech-website:v2

# Install Certbot and request SSL certificate
echo "=== Installing Certbot ==="
yum install -y epel-release
yum install -y certbot python2-certbot-nginx

echo "=== Requesting SSL Certificate ==="
certbot --nginx -n --agree-tos --redirect --hsts --staple-ocsp --email hamdanialhassangandi2020@gmail.com -d lusitechitconsult.com -d www.lusitechitconsult.com

# Set up automatic SSL certificate renewal
echo "=== Setting up automatic certificate renewal ==="
echo "0 0 * * * root certbot renew --quiet --no-self-upgrade" > /etc/cron.d/certbot-renew

# Install AWS CLI v2
# echo "=== Installing AWS CLI v2 ==="
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# yum install -y unzip
# unzip awscliv2.zip
# ./aws/install

# Set up environment variables
cat > /app/.env << EOF
DJANGO_SETTINGS_MODULE=website.settings
DEBUG=0
ALLOWED_HOSTS=*
IS_PRIMARY=${is_primary}
AWS_REGION=${aws_region}
AWS_DEFAULT_REGION=${aws_region}
PROJECT_NAME=${project_name}
ENVIRONMENT=${environment}
EOF

# Set up container health check script
cat > /app/check_containers.sh << 'EOF'
#!/bin/bash
if ! docker ps --filter "name=lusitech" --format '{{.Names}}' | grep -q .; then
    cd /app && docker compose up -d
fi
EOF

chmod +x /app/check_containers.sh

# Add health check to crontab
echo "*/5 * * * * root /app/check_containers.sh" > /etc/cron.d/check_containers

# Print container status
echo "=== Final Container Status ==="
docker ps
docker compose logs

echo "=== Instance setup complete ==="
