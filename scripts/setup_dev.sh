#!/bin/bash
# Dev Server Initialization - Development/Staging Environment
# Installs: Java 17, Apache, Tomcat, Git, Maven, MySQL client
set -euo pipefail

LOG_FILE="/var/log/hoseo-dev-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] Dev server initialization started"

# System setup
dnf update -y
dnf install -y epel-release
timedatectl set-timezone Asia/Seoul

# SSH security hardening (SER-011)
SSH_PORT=2222
sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Install development tools
dnf install -y \
  java-17-openjdk \
  java-17-openjdk-devel \
  httpd \
  mod_ssl \
  git \
  wget \
  curl \
  unzip \
  vim \
  net-tools \
  htop \
  mysql \
  mysql-devel \
  maven

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/profile.d/java.sh

# Install Tomcat (staging WAS)
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
Description=Apache Tomcat - Dev/Staging
After=network.target

[Service]
Type=forking
User=${TOMCAT_USER}
Group=${TOMCAT_USER}
Environment="JAVA_HOME=/usr/lib/jvm/java-17-openjdk"
Environment="CATALINA_HOME=${TOMCAT_DIR}"
Environment="CATALINA_OPTS=-Xms256M -Xmx1024M -server"
ExecStart=${TOMCAT_DIR}/bin/startup.sh
ExecStop=${TOMCAT_DIR}/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable tomcat

# Git configuration (SER-010)
git config --system user.email "dev@hoseo.ac.kr"
git config --system user.name "Hoseo LMS Dev"
git config --system core.autocrlf input

mkdir -p /opt/lms-source
mkdir -p /opt/scripts
mkdir -p /opt/backup/staging

# Firewall
dnf install -y firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --add-port=${SSH_PORT}/tcp
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/8" port port="8080" protocol="tcp" accept'
firewall-cmd --reload

echo "[$(date)] Dev server initialization completed"
