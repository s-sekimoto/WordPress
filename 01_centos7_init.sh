#!/bin/bash -eu
#********** Caution! **********
#Require root user
#For CentOS7
#******************************

# ****************************************
# Settings
# ****************************************
HOST_NAME=example_servername
#------ php settings ------
#post_max_size
PHP_POST_MAX=32MB
#upload_max_filesize
PHP_UPLOAD_MAX=32MB
#
# ****************************************
# Exectute
# ****************************************
echo "********** Disable SE Linux **********"
#
setenforce 0
sed -i -e "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
#
echo "********** Systemd ********** "
#
# /var/log/messeages systemd cron messeage limit.
cp /etc/systemd/system.conf /etc/systemd/system.conf.org
sed -i -e "s/#LogLevel=info/LogLevel=notice/g" /etc/systemd/system.conf
systemd-analyze set-log-level notice
# loosely limit jounald
cp /etc/systemd/journald.conf /etc/systemd/journald.conf.org
sed -i -e "s/#RateLimitInterval=30s/RateLimitInterval=10s/g" /etc/systemd/journald.conf
sed -i -e "s/#RateLimitBurst=1000/RateLimitBurst=20000/g" /etc/systemd/journald.conf
# loosely limit rsyslog
cp /etc/rsyslog.conf /etc/rsyslog.conf.org
echo '$imjournalRatelimitInterval 600' >> /etc/rsyslog.conf
echo '$imjournalRatelimitBurst 2400000' >> /etc/rsyslog.conf
#
echo "********** firewall **********"
#
cp /usr/lib/firewalld/services/ssh.xml /usr/lib/firewalld/services/ssh30022.xml
sed -i -e "s/22/30022/g" /usr/lib/firewalld/services/ssh30022.xml
sed -i -e "s/>SSH</>SSH30022</g" /usr/lib/firewalld/services/ssh30022.xml
firewall-cmd --reload
firewall-cmd --permanent --zone=public --add-service=ssh30022
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --remove-service=ssh --zone=public
firewall-cmd --reload
#
echo "********** SSH **********"
#
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.org
sed -i -e "s/#Port 22/Port 30022/g" /etc/ssh/sshd_config
sed -i -e "s/#PermitRootLogin no/PermitRootLogin no/g" /etc/ssh/sshd_config
sed -i -e "s/PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config
systemctl restart sshd
#
echo "********** Limit swich root user **********"
#
cp /etc/pam.d/su /etc/pam.d/su.org
sed -i -e "s/#auth required pam_wheel.so use_uid/auth required pam_wheel.so use_uid/g" /etc/pam.d/su
cp /etc/login.defs /etc/login.defs.org
echo "SU_WHEEL_ONLY yes" >> /etc/login.defs
#
echo "********** Host name settings **********"
#
hostnamectl set-hostname ${HOST_NAME}
sed -i -e "s/localhost localhost.localdomain/${HOST_NAME} ${HOST_NAME}.example.com localhost localhost.localdomain/g" /etc/hosts
#
echo "********** yum **********"
#
yum -y install yum-cron git screen zsh htop
yum -y install httpd httpd-devel mod_ssl openssl
yum -y install php php-mbstring php-mysql php-gd mariadb mariadb-server
yum -y install yum-priorities
yum -y install epel-release
yum -y install php-pecl-zendopcache php-pecl-apcu php-pear php-devel php-pecl-xdebug
yum clean all
yum check-update
yum -y update
cp /etc/yum/yum-cron.conf /etc/yum/yum-cron.conf.org
sed -i -e "s/apply_updates = no/apply_updates = yes/g" /etc/yum/yum-cron.conf
#
#echo "********** postfix **********"
#
#cp /etc/postfix/main.cf /etc/postfix/main.cf.org
#sed -i -e "s/#myhostname = virtual.domain.tld/myhostname = ${HOST_NAME}.example.com/g /etc/postfix/main.cf
#sed -i -e "s/#mydomain = domain.tld/mydomain = ${HOST_NAME}.example.com/g /etc/postfix/main.cf
#sed -i -e "s/#myorigin = $mydomain/myorigin = $mydomain/g /etc/postfix/main.cf
#
echo "********** php **********"
#
cp /etc/php.ini /etc/php.ini.org
sed -i -e "s/short_open_tag = Off/short_open_tag = On/g" /etc/php.ini
sed -i -e "s/expose_php = On/expose_php = Off/g" /etc/php.ini
sed -i -e "s/post_max_size = 8M/post_max_size = ${PHP_POST_MAX}/g" /etc/php.ini
sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = ${PHP_UPLOAD_MAX}/g" /etc/php.ini
sed -i -e "s/;date.timezone =/date.timezone = Asia\/Tokyo/g" /etc/php.ini
#
echo "********** apache ********** "
#
systemctl enable httpd
systemctl start httpd
#
echo "********** MariaDB ********** "
#
systemctl enable mariadb.service
systemctl start mariadb.service
sed -i -e "1a max_allowed_packet=16MB" /etc/my.cnf
sed -i -e "2a character-set-server=utf8 " /etc/my.cnf
sed -i -e "3a collation-server = utf8_general_ci " /etc/my.cnf
#
echo "********** End ********** "
#
echo "Add DNS TXT record for SPF \"v=spf1 +a:${HOST_NAME}.example.com ~all\""
echo "Please \"mysql_secure_installation\""
# ****************************************
# End
# ****************************************
