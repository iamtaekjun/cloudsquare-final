#!/bin/bash
# Cache Server Initialization Script - Redis 7.x
# - Session cache, page cache
# - Password authentication (SER-004)
set -euo pipefail

echo "[$(date)] Cache server initialization started"

dnf update -y
timedatectl set-timezone Asia/Seoul

# SSH security hardening
SSH_PORT=2222
sed -i "s/^#*Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
grep -q "^Port" /etc/ssh/sshd_config || echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Install Redis
dnf install -y redis

REDIS_PW=$(openssl rand -base64 32)
echo "REDIS_PASSWORD=${REDIS_PW}" > /root/.redis_credentials
chmod 600 /root/.redis_credentials

# Redis configuration
cat > /etc/redis/redis.conf << EOF
# Bind to App Tier internal only
bind 10.0.1.1 127.0.0.1
port 6379

# Authentication (SER-004: access control)
requirepass ${REDIS_PW}

# Memory settings (50% of 8GB RAM for 2vCPU/8GB server)
maxmemory 4gb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfsync everysec

# Disable dangerous commands for security
rename-command FLUSHALL ""
rename-command FLUSHDB  ""
rename-command CONFIG   ""
rename-command DEBUG    ""
rename-command SHUTDOWN SHUTDOWN_HOSEO

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log

# Max clients
maxclients 200

# Protected mode (block direct external access)
protected-mode yes
EOF

systemctl enable --now redis

# Firewall
dnf install -y firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --add-port=${SSH_PORT}/tcp
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.1.0/24" port port="6379" protocol="tcp" accept'
firewall-cmd --reload

echo "[$(date)] Cache server initialization completed"
