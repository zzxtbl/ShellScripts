#!/bin/bash
#lave的服务上
#再次运行master的服务器
#
#install mysql if 
MYSQL_SOFT="mysql mysql-server mysql-devel php-mysql"
NUM=`rpm -qa|grep -i mysql|wc -l`
CODE=$?
if [ $NUM -ne 0 ];then
     echo -e "\033[32mThis Server mysql alredy Inistall.\033[0m"
     read -p "Please ensure yum remove Mysql Server ,YES or NO": INPUT
     if [ $INPUT == "y" -o $INPUT == "yes" ];then
           yum remove $MYSQL_SOFT -y;rm -rf /var/lib/mysql /etc/my.cnf
           yum install $MYSQL_SOFT -y
     else
            exit 0
     fi
else
     rm -rf /var/lib/mysql;yum install $MYSQL_SOFT -y
     if [ $CODE -eq 0 ];then 
         echo -e "033[32mThe mysql Install Successfully.\033[0m"
     else
         echo -e "033[32mThe mysql Install Failed.\033[0m"
         exit 1
     fi    
fi
#mysql to star and config

cat >/etc/my.cnf <<EOF
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
user=mysql
symbolic-links=0
log-bin=mysql-bin
server-id = 1
auto_increment_offset=1
auto_increment_increment=2
[mysqld_safe]
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
replicate-do-db =all
EOF
/etc/init.d/mysqld restart
ps -ef | grep mysql

function MYSQL_CONFIG(){
# master config mysql
mysql -e "grant replication slave on *.* to 'tongbu'@'%' identified by '123456'"
mysql -e "show master status;"

#slave config mysql
MASTER_FILE=`mysql -e "show master status;"|tail -1|awk '{print $1}'`
MASTER_POS=`mysql -e "show master status;"|tail -1|awk '{print $2}'`
#MASTER_IPADDR=`ifconfig eth0 |grep "Bcast"|awk '{print $2}'|cut -d: -f2` 
MASTER_IPADDR=`grep "IPADDR" /etc/sysconfig/network-scripts/ifcfg-eth0|cut -d= -f 2` 

read -p "please enter the IP Addre": SLAVE_IPADDR

#slave config mysql 
ssh -l root $SLAVE_IPADDR "sed -i 's#server-id = 1#server-id =2#g' /etc/my.cnf"
ssh -l root $SLAVE_IPADDR "/etc/init.d/mysqld restart"
ssh -l root $SLAVE_IPADDR "mysql -e \"change master to  master_host='$MASTER_IPADDR',master_user='tongbu',master_password='123456',master_log_file='$MASTER_FILE',master_log_pos=$MASTER_POS;\""
ssh -l root $SLAVE_IPADDR "mysql -e \"slave start;\""
ssh -l root $LSAVE_IPADDR "mysql -e \"show slave status\G;\""
}

read -p "please ensure your server is Master?yes or no": INPUT
if [ $INPUT == "y" -o $INPUT == "yes" ];then
      MYSQL_CONFIG
else
      exit 0
fi
