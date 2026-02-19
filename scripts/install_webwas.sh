#!/bin/bash
# WEB/WAS Server Initialization Script
# Installs: Apache, Java 17, Tomcat, fail2ban
# NOTE: Apache VirtualHost config must be applied manually after server creation
# (NCP init script API filters angle-bracket tags)
set -euo pipefail

LOG_FILE="/var/log/hoseo-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] WEB/WAS server initialization started"

# System update
dnf update -y
dnf install -y epel-release

# Install required packages
dnf install -y \
  java-17-openjdk \
  java-17-openjdk-devel \
  httpd \
  mod_ssl \
  git \
  wget \
  curl \
  unzip \
  net-tools \
  htop \
  vim \
  chrony \
  firewalld \
  fail2ban

# Time sync
systemctl enable --now chronyd
timedatectl set-timezone Asia/Seoul

# SSH security hardening (SER-011)
SSH_PORT=2222
sed -i "s/^#*Port .*/Port ${SSH_PORT}/" /etc/ssh/sshd_config
grep -q "^Port" /etc/ssh/sshd_config || echo "Port ${SSH_PORT}" >> /etc/ssh/sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# fail2ban for brute-force protection
cat > /etc/fail2ban/jail.local << 'JAILEOF'
[sshd]
enabled = true
port    = 2222
maxretry = 3
bantime  = 3600
findtime = 600
JAILEOF
systemctl enable --now fail2ban

systemctl restart sshd
semanage port -a -t ssh_port_t -p tcp ${SSH_PORT} || true

# Install Tomcat (WAS)
TOMCAT_VERSION="10.1.18"
TOMCAT_DIR="/opt/tomcat"
TOMCAT_USER="tomcat"

useradd -r -m -U -d "$TOMCAT_DIR" -s /bin/false "$TOMCAT_USER" || true

wget -q "https://archive.apache.org/dist/tomcat/tomcat-10/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz" \
     -O /tmp/tomcat.tar.gz
tar -xzf /tmp/tomcat.tar.gz -C /opt/
mv "/opt/apache-tomcat-${TOMCAT_VERSION}" "$TOMCAT_DIR"
chown -R "$TOMCAT_USER":"$TOMCAT_USER" "$TOMCAT_DIR"

cat > /etc/systemd/system/tomcat.service << SVCEOF
[Unit]
Description=Apache Tomcat WAS
After=network.target

[Service]
Type=forking
User=${TOMCAT_USER}
Group=${TOMCAT_USER}
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
Environment="CATALINA_PID=${TOMCAT_DIR}/temp/tomcat.pid"
Environment="CATALINA_HOME=${TOMCAT_DIR}"
Environment="CATALINA_BASE=${TOMCAT_DIR}"
Environment="CATALINA_OPTS=-Xms512M -Xmx2048M -server -XX:+UseParallelGC"
ExecStart=${TOMCAT_DIR}/bin/startup.sh
ExecStop=${TOMCAT_DIR}/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable --now httpd
systemctl enable tomcat

# Firewall
systemctl enable --now firewalld
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --permanent --add-port=${SSH_PORT}/tcp
firewall-cmd --permanent --remove-service=ssh
firewall-cmd --reload

# Log rotation
cat > /etc/logrotate.d/hoseo-lms << 'LOGEOF'
/var/log/httpd/lms-*.log {
    daily
    rotate 30
    compress
    missingok
    notifempty
}
LOGEOF

echo "[$(date)] WEB/WAS server initialization completed"
echo "NOTE: Configure Apache VirtualHost manually via SSH after server creation"
