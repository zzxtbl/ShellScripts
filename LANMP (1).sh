#!/bin/sh
#date:2015-12-07
#filename:Auto_lnmp.sh
#Edit:linuxzkq
#Email:1729294227@qq.com
#version:v1.5

#install_dmidecode
yum -y install dmidecode
#date
DATE=`date +"%y-%m-%d %H:%M:%S"`
#Product Name
Product_Name=`dmidecode|grep "Product Name"|awk -F"[: ]+" '{print $3" "$4" "$5" "$6}'|tr "\n" " "`
#Cpuinfo
Cpuinfo=`grep name /proc/cpuinfo|awk -F"[ :]" '{print $6$8$9}'`
#Physical_id
Physical_id=`grep "physical id" /proc/cpuinfo|awk -F"[ :]+" '{print $3}'`
#Meminfo
Meminfo=`grep "MemTotal" /proc/meminfo|awk '{print $2$3}'`
#ip
IPADDR=`ifconfig eth0|awk -F "[ :]+" 'NR==2{print $4}'`
#hostname
HOSTNAME=`hostname -s`
#user
USER=`whoami`
#disk_check
DISK_SDA=`df -h|grep %|awk 'NR==2{print $4}'`
#cpu_average_check
cpu_uptime=`cat /proc/loadavg | cut -c1-14`

. /etc/init.d/functions

#check
check(){
 if [ $? -eq 0 ];then
  action  "Lite or install operation:" /bin/true
 else
  action  "Lite or install operation:" /bin/false
  exit 0
 fi
}

#lite_system
init_system(){
clear
echo -e "\033[32m ######## close iptables and selinux ########\033[0m"
/etc/init.d/iptables stop
chkconfig iptables off 
chkconfig ip6tables off 
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
check
echo -e "\033[32m ######## adduser and sudo ########\033[0m"
useradd linuxzkq
echo "oldboy_zkq"|passwd --stdin linuxzkq
cp /etc/sudoers /etc/sudoers.ori
echo "linuxzkq ALL=(ALL) ALL" >>/etc/sudoers
check
echo -e "\033[32m ######## update kernerl ########\033[0m"
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*
yum upgrade -y
check
echo -e "\033[32m ######## install base pkge ########\033[0m"
yum -y install pcre pcre-devel openssl openssl-devel ncurses gcc make cmake ncurses-devel libxml2-devel libtool-ltdl-devel gcc-c++ autoconf automake bison zlib-devel perl-devel sysstat lrzsz ntpdate wget
chkconfig sysstat on
check
echo -e "\033[32m ######## update yum.repo ########\033[0m"
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
yum clean all
yum makecache
check
echo -e "\033[32m ######## lite chkconfig on service ########\033[0m"
for name in `chkconfig --list|egrep -v "crond|network|sshd|rsyslog|sysstat"|awk '{print $1}'`
do
   chkconfig $name off
done
check
echo -e "\033[32m ######## update system-time ########\033[0m"
echo '*/5 * * * */usr/sbin/ntpdate pool.ntp.org >/dev/null 2>&1' >>/var/spool/cron/root
echo '*/10 * * * * /usr/sbin/ntpdate time.windows.com >/dev/null 2>&1' >>/var/spool/cron/root
check
echo -e "\033[32m ######## modify max limits ########\033[0m"
\cp /etc/security/limits.conf /etc/security/limits.conf.ori
echo "*      -      nofile      65535" >>/etc/security/limits.conf
cat >>/etc/rc.local<<EOF
#open files
ulimit -HSn 65535
#stack size
ulimit -s 65535
EOF
check
echo -e "\033[32m ######## lite ssh ########\033[0m"
cat >>/etc/ssh/sshd_config<<EOF 
Port 52668
PermitRootLogin no 
PermitEmptyPasswords no 
UseDNS no  
#GSSAPIoptions 
GSSAPIAuthentication no 
EOF
/etc/init.d/sshd reload
check
echo -e "\033[32m ######## auto clean spool ########\033[0m"
echo '*/30 * * * * find /var/spool/clientmqueue/ -type f -mtime +30|xargs rm -f >/dev/null 2>&1' >>/var/spool/cron/root
check
echo -e "\033[32m ######## clean system-version ########\033[0m"
echo ' '>/etc/redhat-release
echo ' '>/etc/issue
check
echo -e "\033[32m ######## set char ########\033[0m"
sed -i 's#LANG="en_US.UTF-8"#LANG="zh_CN.GB18030"#' /etc/sysconfig/i18n
source /etc/sysconfig/i18n
check
echo -e "\033[32m ######## lite kernerl for apache,nginx,squid...web apply ########\033[0m"
cp /etc/sysctl.conf /etc/sysctl.conf.ori
cat >>/etc/sysctl.conf<<EOF
#by for kernerl
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem= 4096 87380 16777216
net.ipv4.tcp_wmem= 4096 65536 16777216
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 1024  65535
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_max_orphans = 3276800
EOF
check
sysctl -p
check
init 6
}

APP_path=/application
Tools_path=/server/tools

#install_apache
httpd(){
[ ! -d ${APP_path} ] && mkdir ${APP_path}
[ ! -d ${Tools_path} ] && mkdir ${Tools_path} -p
cd ${Tools_path}
wget http://mirror.bit.edu.cn/apache/apr/apr-1.5.2.tar.gz
wget http://mirror.bit.edu.cn/apache/apr/apr-util-1.5.4.tar.gz
check
tar xf apr-1.5.2.tar.gz
cd apr-1.5.2
./configure --prefix=/usr/local/apr
make && make install
check
cd ../
tar xf apr-util-1.5.4.tar.gz
cd apr-util-1.5.4
./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
check
make && make install
check
cd ../
wget http://mirror.bit.edu.cn/apache/httpd/httpd-2.2.31.tar.gz
tar xf httpd-2.2.31.tar.gz 
cd httpd-2.2.31
./configure \
--prefix=${APP_path}/apache-2.2.31 \
--enable-deflate \
--enable-expires \
--enable-headers \
--enable-modules=most \
--enable-so \
--with-mpm=worker \
--enable-rewrite \
--with-apr=/usr/local/apr \
--with-apr-util=/usr/local/apr-util
check
make
check
make install
check
ln -s ${APP_path}/apache-2.2.31/ ${APP_path}/apache
\cp ${APP_path}/apache/bin/apachectl /etc/init.d/httpd
chmod +x /etc/init.d/httpd
cd ../
action  "Install httpd:" /bin/true
}

#install_nginx
Nginx(){
[ ! -d ${APP_path} ] && mkdir ${APP_path}
[ ! -d ${Tools_path} ] && mkdir ${Tools_path} -p
cd ${Tools_path}
wget http://nginx.org/download/nginx-1.6.3.tar.gz
check
tar xf nginx-1.6.3.tar.gz
cd nginx-1.6.3
useradd nginx -s /sbin/nologin -M
check
./configure --prefix=${APP_path}/nginx-1.6.3 --with-http_stub_status_module --with-http_ssl_module --user=nginx --group=nginx
check
make 
check
make install
cd ../
ln -s ${APP_path}/nginx-1.6.3/ ${APP_path}/nginx
action  "Install nginx:" /bin/true
}

#install_mysql
mysql(){
groupadd mysql
useradd mysql -s /sbin/nologin -M -g mysql
check
mkdir ${APP_path}/data/mysql -p
cd ${Tools_path}
tar xf mysql-5.5.32.tar.gz
check
cd mysql-5.5.32
cmake . -DCMAKE_INSTALL_PREFIX=${APP_path}/mysql-5.5.32 \
-DMYSQL_DATADIR=${APP_path}/data/mysql \
-DMYSQL_UNIX_ADDR=${APP_path}/mysql-5.5.32/tmp/mysql.sock \
-DDEFAULT_CHARSET=utf8 \
-DDEFAULT_COLLATION=utf8_general_ci \
-DEXTRA_CHARSETS=gbk,gb2312,utf8,ascii \
-DENABLED_LOCAL_INFILE=ON \
-DWITH_INNOBASE_STORAGE_ENGINE=1 \
-DWITH_FEDERATED_STORAGE_ENGINE=1 \
-DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
-DWITHOUT_EXAMPLE_STORAGE_ENGINE=1 \
-DWITHOUT_PARTITION_STORAGE_ENGINE=1 \
-DWITH_FAST_MUTEXES=1 \
-DWITH_ZLIB=bundled \
-DENABLED_LOCAL_INFILE=1 \
-DWITH_READLINE=1 \
-DWITH_EMBEDDED_SERVER=1 \
-DWITH_DEBUG=0
check
make
check
make install
check
ln -s ${APP_path}/mysql-5.5.32/ ${APP_path}/mysql
\cp support-files/my-small.cnf /etc/my.cnf
check
echo export 'PATH=${APP_path}/mysql/bin:$PATH' >>/etc/profile
source /etc/profile
echo $PATH
check
chmod -R 1777 /tmp
chown -R mysql.mysql ${APP_path}/data/mysql
check
cd ${APP_path}/mysql/scripts
check
./mysql_install_db --basedir=${APP_path}/mysql/ --datadir=${APP_path}/data/mysql --user=mysql && cd ../
check
\cp ./support-files/mysql.server /etc/init.d/mysqld
chmod +x /etc/init.d/mysqld
cd ../
ln -s ${APP_path}/mysql/lib/libmysqlclient.so /usr/lib64/
ln -s ${APP_path}/mysql/lib/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.18
action  "Install mysql:" /bin/true
}

#install_lnmp_php
lnmp_php(){
yum install -y zlib libxml libjpeg freetype libpng gd curl libiconv zlib-devel libxml2-devel libjpeg-turbo-devel freetype-devel libpng-devel gd-devel curl-devel libxslt-devel openssl-devel libxslt*
check
cd ${Tools_path}
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
tar xf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local/libiconv && make
make install
check
cd ../
tar xf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure && make
make install
check
cd libltdl/ 
./configure --enable-ltdl-install 
check
make && make install
cd ../../ 
check
tar xf mhash-0.9.9.9.tar.gz
cd mhash-0.9.9.9/
./configure
check
make
make install
check
cd ../
rm -f /usr/lib64/libmcrypt.*
rm -f /usr/lib64/libmhash*
ln -s /usr/local/lib64/libmcrypt.la /usr/lib64/libmcrypt.la
ln -s /usr/local/lib64/libmcrypt.so /usr/lib64/libmcrypt.so
ln -s /usr/local/lib64/libmcrypt.so.4 /usr/lib64/libmcrypt.so.4
ln -s /usr/local/lib64/libmcrypt.so.4.4.8 /usr/lib64/libmcrypt.so.4.4.8
ln -s /usr/local/lib64/libmhash.a /usr/lib64/libmhash.a
ln -s /usr/local/lib64/libmhash.la /usr/lib64/libmhash.la
ln -s /usr/local/lib64/libmhash.so /usr/lib64/libmhash.so
ln -s /usr/local/lib64/libmhash.so.2 /usr/lib64/libmhash.so.2
ln -s /usr/local/lib64/libmhash.so.2.0.1 /usr/lib64/libmhash.so.2.0.1
ln -s /usr/local/bin/libmcrypt-config /usr/bin/libmcrypt-config
ln -s ${APP_path}/mysql/lib/libmysqlclient.so /usr/lib64/
ln -s ${APP_path}/mysql/lib/libmysqlclient.so.18 /usr/lib64/libmysqlclient.so.18
check
tar xf mcrypt-2.6.8.tar.gz
cd mcrypt-2.6.8/ && ./configure LD_LIBRARY_PATH=/usr/local/lib
check
make && make install
cd ../
check
echo "/usr/local/lib" >>/etc/ld.so.conf
ldconfig
tar xf php-5.5.30.tar.gz
cd php-5.5.30
./configure \
--prefix=/application/php-5.5.30 \
--with-mysql=/application/mysql \
--with-iconv-dir=/usr/local/libiconv \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir=/usr \
--enable-xml \
--disable-rpath \
--enable-safe-mode \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--with-curl-wrappers \
--enable-mbregex \
--enable-fpm \
--enable-mbstring \
--with-mcrypt \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--with-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \
--enable-soap \
--enable-short-tags \
--enable-zend-multibyte \
--enable-static \
--with-xsl \
--with-fpm-user=nginx \
--with-fpm-group=nginx \
--enable-ftp
ln -s /usr/local/lib/libiconv.so.2 /usr/lib64/
check
make
check
make install
check
ln -s ${APP_path}/php-5.5.30/ ${APP_path}/php &&\
\cp php.ini-production ${APP_path}/php/lib/php.ini
check
cd ${APP_path}/php/etc/ && mv php-fpm.conf.default php-fpm.conf
cd ../
action  "Install lnmp_php:" /bin/true
}

#install_lamp_php
lamp_php(){ 
yum install zlib-devel libxml2-devel libjpeg-devel freetype-devel libpng-devel gd-devel curl-devel libxslt-devel libmcrypt-devel mhash mhash-devel mcrypt openssl-devel libtool-ltdl libtool libxslt* -y
check
cd ${Tools_path}
wget http://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.14.tar.gz
check
tar zxf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local/libiconv
make
make install
cd ../
check
tar xf php-5.5.30.tar.gz
cd php-5.5.30
./configure \
--prefix=${APP_path}/php-5.5.30 \
--with-apxs2=${APP_path}/apache/bin/apxs \
--with-mysql=${APP_path}/mysql \
--with-iconv-dir=/usr/local/libiconv \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir=/usr \
--enable-xml \
--disable-rpath \
--enable-bcmath \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--enable-mbregex \
--enable-mbstring \
--with-mcrypt \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \
--enable-soap \
--enable-short-tags \
--enable-static \
--with-xsl \
--enable-ftp
check
make 
check
make install
check
ln -s ${APP_path}/php-5.5.30/ ${APP_path}/php
ls -l ${APP_path}/apache/modules/
grep libphp5.so ${APP_path}/apache/conf/httpd.conf
check
cp php.ini-production ${APP_path}/php/lib/php.ini
cd ../
action  "Install lamp_php:" /bin/true
}

#config_nginx
#config_nginx(){

#}

#config_mysql
config_mysql(){
cat >/etc/my.cnf<<EOF
[client]
port	= 3306
socket	= /application/mysql-5.5.32/tmp/mysql.sock

[mysql]
no-auto-rehash

[mysqld]
user	= mysql
port	= 3306
socket	= /application/mysql-5.5.32/tmp/mysql.sock
basedir	= /application/mysql-5.5.32
datadir	= /application/data/mysql
open_files_limit = 10240
back_log = 600
max_connections = 3000
max_connect_errors = 6000
table_cache = 614
external-locking = FALSE
max_allowed_packet = 32M
sort_buffer_size = 2M
join_buffer_size = 2M
thread_cache_size = 300
thread_concurrency = 8
query_cache_size = 64M
query_cache_limit = 4M
query_cache_min_res_unit = 2k
default_table_type = InnoDB
thread_stack = 192K
transaction_isolation = READ-COMMITTED
tmp_table_size = 256M
max_heap_table_size = 256M
long_query_time = 2
log_long_format
log-error = /application/data/mysql/error.log
log-slow-queries= /application/data/mysql/slow-log.log
pid-file = /application/data/mysql/mysql.pid
log-bin = /application/data/mysql/mysql-bin
relay-log = /application/data/mysql/relay-bin
relay-log-info-file = /application/data/mysql/relay-log.info
binlog_cache_size = 4M
max_binlog_cache_size = 8M
max_binlog_size = 512M
expire_logs_days = 7
key_buffer_size = 32M
read_buffer_size = 1M
read_rnd_buffer_size = 16M
bulk_insert_buffer_size = 64M
myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_max_extra_sort_file_size = 10G
myisam_repair_threads = 1
myisam_recover
lower_case_table_names = 1
skip-name-resolve
slave-skip-errors = 1032,1062
replicate-ignore-db=mysql

server-id = 1

innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size = 2048M
innodb_data_file_path = ibdata1:1024M:autoextend
innodb_file_io_threads = 4
innodb_thread_concurrency = 8
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 16M
innodb_log_file_size = 128M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 90
innodb_lock_wait_timeout = 120
innodb_file_per_table = 0
[mysqldump]
quick
max_allowed_packet = 32M
[mysqld_safe]
log-error = /application/data/mysql/mysqld_safe_mysql.err
pid-file = /application/data/mysql/mysqld.pid
EOF
/etc/init.d/mysqld start
}


#lamp
lamp(){
httpd
mysql
lamp_php

action  "Install lamp:" /bin/true
}

#lnmp
lnmp(){
Nginx
mysql
lnmp_php
action  "Install lnmp:" /bin/true
}

#main_menu
menu(){
cat << EOF
-----------------System  Information-------------------
DATE        :$DATE
Product_Name:$Product_Name
Cpuinfo     :$Cpuinfo
Physical_id :$Physical_id
Meminfo     :$Meminfo
HOSTNAME    :$HOSTNAME 
USER        :$USER                      
IP          :$IPADDR          
DISK_USED   :$DISK_SDA 
CPU_AVERAGE :$cpu_uptime
------------------------------------------------------- 
0. lite_system
1. Install Nginx Service
2. Install HTTPD Service
3. Install MySQL Service
4. Install PHP Service
5. Install LAMP
6. Install LNMP
7. Config and start Service
8. Quit
EOF
}

while true
do
clear
menu
read -p "Please Input your choice number[0-8]:" a
[ $a -ge 9 ] && {
  echo "Please input an num to you want install service,again!"
  exit 0
}

case "$a" in
   0)clear
     init_system

     ;;
   1)clear
     Nginx

     ;;
   2)clear
     httpd

     ;;
   3)clear
     mysql

     ;;
   4)clear
     read -p "Please choice you want install php huanjing[lamp input "php1"||lnmp input "php2"]:" b
     if [ "$b" == "php1" ];then
        lamp_php
     elif [ "$b" == "php2" ];then
        lnmp_php
     else
        echo "Please choice you want install php huanjing,again!"
     fi

     ;;
   5)clear
     lamp
  
     ;;
   6)clear
     lnmp

     ;;
   7)clear
     read -p "Please choice you want config services[Httpd input "httpd"|Nginx input "nginx"|MySQL input "mysql"|PHP input "php"]:" c
     if [ "$c" == "httpd" ];then
        config_httpd
     elif [ "$c" == "nginx" ];then
        config_nginx
     elif [ "$c" == "mysql" ];then
        config_mysql
     elif [ "$c" == "php" ];then
        config_php
     else
        echo "Please choice you want config services,again!"
     fi
     
     ;;
   8)exit 1

esac
done
