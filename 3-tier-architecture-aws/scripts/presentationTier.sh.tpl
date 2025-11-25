#!/bin/bash

#############################################
# Production-Ready Presentation Tier Setup
# Error handling, logging, and idempotency
#############################################

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Logging setup
LOGFILE="/var/log/user-data-setup.log"
exec > >(tee -a "$LOGFILE")
exec 2>&1

echo "========================================="
echo "Starting setup at $(date)"
echo "========================================="

# Define variables
NGINX_CONF="${NGINX_CONF}"
SERVER_NAME="${SERVER_NAME}"
REGION="${REGION}"
APP_TIER_ALB_URL="${APP_TIER_ALB_URL}"



# Function for error handling
error_exit() {
    echo "ERROR: $1" >&2
    exit 1
}

# Function to check if service is running
check_service() {
    if systemctl is-active --quiet "$1"; then
        echo "✓ $1 is running"
        return 0
    else
        echo "✗ $1 is not running"
        return 1
    fi
}

#############################################
# 1. System Updates
#############################################
echo "Updating system packages..."
sudo dnf update -y || error_exit "Failed to update packages"

#############################################
# 2. Nginx Installation & Configuration
#############################################
if ! command -v nginx &> /dev/null; then
    echo "Installing nginx..."
    sudo dnf install -y nginx || error_exit "Failed to install nginx"
else
    echo "Nginx already installed, skipping..."
fi

# Backup existing nginx configuration (with timestamp)
if [ -f "$NGINX_CONF" ]; then
    BACKUP_FILE="${NGINX_CONF}.backup.$(date +%Y%m%d_%H%M%S)"
    sudo cp "$NGINX_CONF" "$BACKUP_FILE"
    echo "Backed up nginx config to $BACKUP_FILE"
fi

# Write main nginx configuration
echo "Writing nginx main configuration..."
sudo tee $NGINX_CONF > /dev/null << 'EOL'
user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log warn;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Hide nginx version
    server_tokens off;

    include /etc/nginx/conf.d/*.conf;
}
EOL

# Create server configuration
echo "Writing nginx server configuration..."
sudo tee /etc/nginx/conf.d/presentation-tier.conf > /dev/null << EOL
server {
    listen 80;
    server_name $SERVER_NAME;
    root /usr/share/nginx/html;
    index index.html index.htm;

    # Health check endpoint
    location /health {
        access_log off;
        default_type text/html;
        return 200 "<!DOCTYPE html><html><body><h1>OK</h1><p>Status: Healthy</p></body></html>";
    }

    # Static content
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API proxy to application tier
    location /api/ {
        proxy_pass $APP_TIER_ALB_URL;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }

    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOL

# Test nginx configuration
echo "Testing nginx configuration..."
sudo nginx -t || error_exit "Nginx configuration test failed"

# Start and enable nginx
echo "Starting nginx..."
sudo systemctl enable nginx
sudo systemctl restart nginx || error_exit "Failed to start nginx"
check_service nginx || error_exit "Nginx service check failed"

#############################################
# 3. CloudWatch Agent Installation
#############################################
if ! command -v amazon-cloudwatch-agent-ctl &> /dev/null; then
    echo "Installing CloudWatch agent..."
    sudo dnf install -y amazon-cloudwatch-agent || error_exit "Failed to install CloudWatch agent"
else
    echo "CloudWatch agent already installed, skipping..."
fi

# Ensure log directories exist
sudo mkdir -p /var/log/nginx
sudo mkdir -p /var/log/aws/codedeploy-agent
sudo mkdir -p /opt/codedeploy-agent/deployment-root/deployment-logs

# Write CloudWatch configuration
echo "Writing CloudWatch agent configuration..."
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'EOL'
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/nginx/access.log",
                        "log_group_name": "nginx-logs-frontend",
                        "log_stream_name": "{instance_id}-nginx-access",
                        "timestamp_format": "%d/%b/%Y:%H:%M:%S %z"
                    },
                    {
                        "file_path": "/var/log/nginx/error.log",
                        "log_group_name": "nginx-logs-frontend",
                        "log_stream_name": "{instance_id}-nginx-error",
                        "timestamp_format": "%Y/%m/%d %H:%M:%S"
                    },
                    {
                        "file_path": "/var/log/user-data-setup.log",
                        "log_group_name": "user-data-logs-frontend",
                        "log_stream_name": "{instance_id}-setup"
                    },
                    {
                        "file_path": "/var/log/aws/codedeploy-agent/codedeploy-agent.log",
                        "log_group_name": "codedeploy-agent-logs-frontend",
                        "log_stream_name": "{instance_id}-agent-log"
                    },
                    {
                        "file_path": "/opt/codedeploy-agent/deployment-root/deployment-logs/codedeploy-agent-deployments.log",
                        "log_group_name": "codedeploy-agent-logs-frontend",
                        "log_stream_name": "{instance_id}-deployment-log"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "PresentationTier",
        "metrics_collected": {
            "mem": {
                "measurement": [
                    {
                        "name": "mem_used_percent",
                        "rename": "MemoryUtilization",
                        "unit": "Percent"
                    }
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    {
                        "name": "used_percent",
                        "rename": "DiskUtilization",
                        "unit": "Percent"
                    }
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "/"
                ]
            }
        }
    }
}
EOL

# Start CloudWatch agent with configuration
echo "Starting CloudWatch agent..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json || \
    error_exit "Failed to start CloudWatch agent"

check_service amazon-cloudwatch-agent || echo "Warning: CloudWatch agent may not be running properly"

#############################################
# 4. CodeDeploy Agent Installation
#############################################
if systemctl is-active --quiet codedeploy-agent; then
    echo "CodeDeploy agent already running, skipping installation..."
else
    echo "Installing CodeDeploy agent dependencies..."
    sudo dnf install -y ruby wget || error_exit "Failed to install ruby/wget"

    # Download and install CodeDeploy agent
    cd /tmp
    INSTALL_SCRIPT="codedeploy-install-$(date +%s).sh"
    
    echo "Downloading CodeDeploy agent installer..."
    wget -O "$INSTALL_SCRIPT" "https://aws-codedeploy-${REGION}.s3.${REGION}.amazonaws.com/latest/install" || \
        error_exit "Failed to download CodeDeploy installer"
    
    chmod +x "$INSTALL_SCRIPT"
    
    echo "Installing CodeDeploy agent..."
    sudo ./"$INSTALL_SCRIPT" auto || error_exit "Failed to install CodeDeploy agent"
    
    # Cleanup
    rm -f "$INSTALL_SCRIPT"
    
    # Start and enable CodeDeploy agent
    echo "Starting CodeDeploy agent..."
    sudo systemctl enable codedeploy-agent
    sudo systemctl start codedeploy-agent || error_exit "Failed to start CodeDeploy agent"
fi

check_service codedeploy-agent || error_exit "CodeDeploy agent service check failed"

#############################################
# 5. Final Verification
#############################################
echo ""
echo "========================================="
echo "Setup Complete - Service Status:"
echo "========================================="
check_service nginx
check_service amazon-cloudwatch-agent
check_service codedeploy-agent

echo ""
echo "Testing health endpoint..."
sleep 2
curl -s http://localhost/health || echo "Warning: Health check failed"

echo ""
echo "========================================="
echo "Setup completed successfully at $(date)"
echo "Log file: $LOGFILE"
echo "========================================="

exit 0