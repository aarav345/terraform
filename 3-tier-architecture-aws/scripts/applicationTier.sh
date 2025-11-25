#!/bin/bash

#############################################
# Production-Ready Application Tier Setup
# Node.js + PM2 + CloudWatch + CodeDeploy
#############################################

# Exit on error, undefined variables, and pipe failures
set -euo pipefail


# Logging setup
LOGFILE="/var/log/user-data-setup.log"
exec > >(tee -a "$LOGFILE")
exec 2>&1

echo "========================================="
echo "Starting backend setup at $(date)"
echo "========================================="

# Define variables
REGION="ap-south-1"
APP_USER="ec2-user"
APP_HOME="/home/${APP_USER}"
LOG_DIR="/var/log/react-node-mysql-app/backend"
APP_DIR="${APP_HOME}/app"
NODE_VERSION="20"


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

# Function to check command exists
command_exists() {
    command -v "$1" &> /dev/null
}

#############################################
# 1. System Updates
#############################################
echo "Updating system packages..."
sudo dnf update -y || error_exit "Failed to update packages"

#############################################
# 2. Node.js Installation
#############################################
if ! command_exists node; then
    echo "Installing Node.js ${NODE_VERSION}..."
    sudo dnf install -y nodejs || error_exit "Failed to install Node.js"
else
    echo "Node.js already installed: $(node --version)"
fi

# Verify Node.js installation
node --version || error_exit "Node.js installation verification failed"
npm --version || error_exit "npm installation verification failed"

#############################################
# 3. PM2 Installation
#############################################
if ! command_exists pm2; then
    echo "Installing PM2 globally..."
    sudo npm install -g pm2 || error_exit "Failed to install PM2"
else
    echo "PM2 already installed: $(pm2 --version)"
fi

# Verify PM2 installation
pm2 --version || error_exit "PM2 installation verification failed"

#############################################
# 4. Application Directory Setup
#############################################
echo "Setting up application directories..."

# Create log directory with proper permissions
sudo mkdir -p "$LOG_DIR"
sudo chown -R ${APP_USER}:${APP_USER} "$LOG_DIR"
sudo chmod 755 "$LOG_DIR"

# Create application directory
sudo mkdir -p "$APP_DIR"
sudo chown -R ${APP_USER}:${APP_USER} "$APP_DIR"

# Create log files with proper permissions
sudo -u ${APP_USER} touch "${LOG_DIR}/combined.log"
sudo -u ${APP_USER} touch "${LOG_DIR}/error.log"

echo "✓ Application directories created"

#############################################
# 5. PM2 Configuration
#############################################
echo "Configuring PM2 for automatic startup..."

# Generate PM2 startup script
# Note: The actual app will be started by CodeDeploy, not here
STARTUP_CMD=$(sudo -u ${APP_USER} pm2 startup systemd -u ${APP_USER} --hp ${APP_HOME} | grep "sudo")

if [ -n "$STARTUP_CMD" ]; then
    echo "Executing PM2 startup command..."
    eval "$STARTUP_CMD" || error_exit "Failed to setup PM2 startup"
else
    echo "Warning: Could not generate PM2 startup command"
fi

# Create PM2 ecosystem config template
sudo -u ${APP_USER} tee "${APP_HOME}/ecosystem.config.js" > /dev/null << 'EOL'
module.exports = {
  apps: [{
    name: 'backend-app',
    script: './server.js',
    instances: 'max',
    exec_mode: 'cluster',
    autorestart: true,
    watch: false,
    max_memory_restart: '512M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/var/log/react-node-mysql-app/backend/error.log',
    out_file: '/var/log/react-node-mysql-app/backend/combined.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    merge_logs: true,
    time: true
  }]
};
EOL

sudo chown ${APP_USER}:${APP_USER} "${APP_HOME}/ecosystem.config.js"
echo "✓ PM2 ecosystem config created"

#############################################
# 6. CloudWatch Agent Installation
#############################################
if ! command_exists amazon-cloudwatch-agent-ctl; then
    echo "Installing CloudWatch agent..."
    sudo dnf install -y amazon-cloudwatch-agent || error_exit "Failed to install CloudWatch agent"
else
    echo "CloudWatch agent already installed"
fi

# Ensure log directories exist for CodeDeploy
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
                        "file_path": "/var/log/react-node-mysql-app/backend/combined.log",
                        "log_group_name": "node-app-logs-backend",
                        "log_stream_name": "{instance_id}-combined",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S"
                    },
                    {
                        "file_path": "/var/log/react-node-mysql-app/backend/error.log",
                        "log_group_name": "node-app-logs-backend",
                        "log_stream_name": "{instance_id}-error",
                        "timestamp_format": "%Y-%m-%d %H:%M:%S"
                    },
                    {
                        "file_path": "/var/log/user-data-setup.log",
                        "log_group_name": "user-data-logs-backend",
                        "log_stream_name": "{instance_id}-setup"
                    },
                    {
                        "file_path": "/var/log/aws/codedeploy-agent/codedeploy-agent.log",
                        "log_group_name": "codedeploy-agent-logs-backend",
                        "log_stream_name": "{instance_id}-agent"
                    },
                    {
                        "file_path": "/opt/codedeploy-agent/deployment-root/deployment-logs/codedeploy-agent-deployments.log",
                        "log_group_name": "codedeploy-agent-logs-backend",
                        "log_stream_name": "{instance_id}-deployment"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "ApplicationTier",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    {
                        "name": "cpu_usage_active",
                        "rename": "CPUUtilization",
                        "unit": "Percent"
                    }
                ],
                "metrics_collection_interval": 60,
                "totalcpu": false
            },
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

sleep 3
check_service amazon-cloudwatch-agent || echo "Warning: CloudWatch agent may not be running properly"

#############################################
# 7. CodeDeploy Agent Installation
#############################################
if systemctl is-active --quiet codedeploy-agent; then
    echo "CodeDeploy agent already running, skipping installation..."
else
    echo "Installing CodeDeploy agent dependencies..."
    sudo dnf install -y ruby wget || error_exit "Failed to install ruby/wget"

    # Download and install CodeDeploy agent
    cd /tmp
    INSTALL_SCRIPT="codedeploy-install-$(date +%s).sh"
    
    echo "Downloading CodeDeploy agent installer for ${REGION}..."
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
# 8. Security Hardening
#############################################
echo "Applying security configurations..."

# Set proper file permissions
sudo chmod 755 "$APP_HOME"
sudo chmod 755 "$LOG_DIR"

# Ensure ec2-user owns their home directory
sudo chown -R ${APP_USER}:${APP_USER} "$APP_HOME"

#############################################
# 9. Health Check Script
#############################################
echo "Creating health check script..."
sudo -u ${APP_USER} tee "${APP_HOME}/health-check.sh" > /dev/null << 'EOL'
#!/bin/bash
# Simple health check for PM2 app

if ! command -v pm2 &> /dev/null; then
    echo "ERROR: PM2 not installed"
    exit 1
fi

# Check if any PM2 apps are running
APP_COUNT=$(pm2 jlist 2>/dev/null | jq '. | length' 2>/dev/null || echo "0")

if [ "$APP_COUNT" -gt 0 ]; then
    echo "OK: $APP_COUNT PM2 app(s) running"
    pm2 status
    exit 0
else
    echo "WARNING: No PM2 apps running yet (waiting for CodeDeploy)"
    exit 0
fi
EOL

sudo chmod +x "${APP_HOME}/health-check.sh"
sudo chown ${APP_USER}:${APP_USER} "${APP_HOME}/health-check.sh"

#############################################
# 10. Final Verification
#############################################
echo ""
echo "========================================="
echo "Setup Complete - Service Status:"
echo "========================================="
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"
echo "PM2 version: $(pm2 --version)"
echo ""

check_service amazon-cloudwatch-agent
check_service codedeploy-agent

echo ""
echo "Application directories:"
echo "  App dir: $APP_DIR"
echo "  Log dir: $LOG_DIR"
echo ""

# Run health check
echo "Running health check..."
sudo -u ${APP_USER} bash "${APP_HOME}/health-check.sh" || true

echo ""
echo "========================================="
echo "Setup completed successfully at $(date)"
echo "Log file: $LOGFILE"
echo ""
echo "Next steps:"
echo "1. Deploy application using CodeDeploy"
echo "2. Application will be started by CodeDeploy lifecycle hooks"
echo "3. PM2 will automatically restart app on reboot"
echo "========================================="

exit 0