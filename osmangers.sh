#!/bin/bash
# system optimization lilin 2014-07-02
#Check the user
if [ "`whoami`" = "root" ]
        then
        echo "Welcome to the system optimization script!"
else
        echo "please Use the root user!"
        exit 1
fi
#update system
yum update -y
yum install -y ntpdate
yum -y install zlib zlib-devel libxml libjpeg freetype libpng gd curl libiconv libxml2-devel libjpeg-devel freetype-devel libpng-devel gd-devel crul-devel gcc-c++ ncurses-devel libxslt* openssl*
#Clean up the boot from the startup service
LANG=en
for n in `chkconfig --list|grep 3:on|awk '{print $1}'`
do
 chkconfig --level 3 $n off
done
for n in crond network rsyslog sshd irqbalance
do
        chkconfig --level 3 $n on
done
#Change the SSH configuration file
#sed -i '13a Port 60222' /etc/ssh/sshd_config
#/etc/init.d/sshd restart
#add iptables rules
#sed -i '10a -A INPUT -m state --state NEW -m tcp -p tcp --dport 60222 -j ACCEPT' /etc/sysconfig/iptables
#/etc/init.d/iptables restart
#Modify SELinux
sed -i "s#`grep "^SELINUX=" /etc/sysconfig/selinux`#SELINUX=disabled#g" /etc/sysconfig/selinux
sed -i "s#`grep "^SELINUX=" /etc/selinux/config`#SELINUX=disabled#g" /etc/selinux/config
#The server time with Internet time synchronization
#echo "*/5 * * * * /usr/sbin/ntpdate cn.pool.ntp.org >/dev/null 2>&1" >> /var/spool/cron/root
#ncrease the server file descriptor
#echo -e "\n* soft nofile 65536 \n* hard nofile 65535 " >>/etc/security/limits.conf
#To optimize the kernel parameter file
echo "
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_syncookise = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_nax_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
" >> /etc/sysctl.conf
/sbin/sysctl -p
