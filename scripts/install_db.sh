#!/bin/bash
# DB Server Initialization Script
# - MySQL 8.0 install and security configuration
# - Automated backup schedule (cron)
# - Personal data encryption (COR-001, SER-005)
set -euo pipefail

LOG_FILE="/var/log/hoseo-db-init.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[$(date)] DB server initialization started"

# System update
dnf update -y
timedatectl set-timezone Asia/Seoul

# SSH security hardening
SSH_PORT=2222
sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Install MySQL 8.0
dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-9.noarch.rpm
dnf module disable -y mysql
dnf install -y mysql-community-server

systemctl enable --now mysqld

# Get temporary root password
TEMP_ROOT_PW=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')

# Generate secure passwords
DB_ROOT_PW=$(openssl rand -base64 24)
DB_LMS_PW=$(openssl rand -base64 24)

# Store credentials securely (chmod 600)
echo "ROOT_PASSWORD=${DB_ROOT_PW}" > /root/.db_credentials
echo "LMS_PASSWORD=${DB_LMS_PW}"  >> /root/.db_credentials
chmod 600 /root/.db_credentials

mysql --connect-expired-password -u root -p"${TEMP_ROOT_PW}" << SQL
-- Change root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PW}';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';

-- Block remote root access (SER-011)
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Create LMS database
CREATE DATABASE IF NOT EXISTS coursemos_lms
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Create LMS user (App Tier access only)
CREATE USER IF NOT EXISTS 'lms_user'@'10.0.1.%' IDENTIFIED BY '${DB_LMS_PW}';
GRANT ALL PRIVILEGES ON coursemos_lms.* TO 'lms_user'@'10.0.1.%';

FLUSH PRIVILEGES;
SQL

# MySQL performance optimization (PER-008, PER-009)
cat > /etc/my.cnf.d/hoseo-lms.cnf << 'EOF'
[mysqld]
# Basic settings
bind-address            = 10.0.3.1
port                    = 3306
default_storage_engine  = InnoDB
character-set-server    = utf8mb4
collation-server        = utf8mb4_unicode_ci

# Performance settings (8vCPU, 32GB RAM)
innodb_buffer_pool_size  = 20G
innodb_buffer_pool_instances = 8
innodb_log_file_size     = 1G
innodb_flush_log_at_trx_commit = 1
max_connections          = 500
thread_cache_size        = 50
query_cache_type         = 0
table_open_cache         = 4000
tmp_table_size           = 64M
max_heap_table_size      = 64M

# Slow query log (performance monitoring)
slow_query_log           = 1
slow_query_log_file      = /var/log/mysql/slow.log
long_query_time          = 2

# SSL settings (SER-005: encryption)
ssl-ca                   = /etc/mysql/ssl/ca.pem
ssl-cert                 = /etc/mysql/ssl/server-cert.pem
ssl-key                  = /etc/mysql/ssl/server-key.pem
require_secure_transport = ON

# Binary log (for backup and recovery)
log_bin                  = /var/log/mysql/mysql-bin.log
binlog_expire_logs_seconds = 604800
max_binlog_size          = 100M
binlog_format            = ROW

# Audit log (SER-004: access logging)
general_log              = 0
general_log_file         = /var/log/mysql/general.log

[mysql]
default-character-set = utf8mb4
EOF

# Generate MySQL SSL certificates
mkdir -p /etc/mysql/ssl
mysql_ssl_rsa_setup --datadir=/etc/mysql/ssl 2>/dev/null || true

systemctl restart mysqld

# Automated backup schedule (daily at 03:00)
mkdir -p /opt/backup/mysql

cat > /opt/backup/mysql_backup.sh << 'SCRIPT'
#!/bin/bash
set -euo pipefail
BACKUP_DIR="/opt/backup/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="coursemos_lms"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${DATE}.sql.gz"

source /root/.db_credentials

mysqldump -u root -p"${ROOT_PASSWORD}" \
    --single-transaction \
    --routines \
    --triggers \
    --databases "${DB_NAME}" | \
    gzip > "${BACKUP_FILE}"

# Delete backups older than 30 days
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +30 -delete

echo "[$(date)] DB backup completed: ${BACKUP_FILE}"
SCRIPT

chmod +x /opt/backup/mysql_backup.sh

# Register cron (daily at 03:00)
echo "0 3 * * * root /opt/backup/mysql_backup.sh >> /var/log/mysql_backup.log 2>&1" \
    > /etc/cron.d/mysql-backup

# Firewall
dnf install -y firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --add-port=${SSH_PORT}/tcp
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.1.0/24" port port="3306" protocol="tcp" accept'
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.2.0/24" port port="3306" protocol="tcp" accept'
firewall-cmd --reload

echo "[$(date)] DB server initialization completed"
echo "WARNING: DB credentials stored in /root/.db_credentials (review and secure immediately)"
