#!/bin/sh
#auto backup mysql 
#date
#Define PATH 自定义变量
BAKDIR=/data/backup/mysql/` date +%Y-%m-%d`
MYSQLDB=zzx
MYSQLPW=root
MYSQLUSER=root
#uset use root user run scripts 必须使用root用户运行，$UID

if
   [ $UID -ne 0 ];then
   echo "This script must use the root user!!!"
   sleep 2

  exit
fi
#Defind DIR and mkdir DIR 判断目录是否存在，不存在则新建

if
   [ ! -d $BAKDIR ];then
   mkdir -p $BAKDIR
   echo "\033[32mThe $BAKDIR Create Successfully!"
else
   echo " This is $BACKDIR exists ......."
 fi
#Use mysqldump backup mysql 使用mysqldump 备份数据库
/usr/bin/mysqldump -u$MYSQLUSR -P$MYSQLPW -d $MYSQLDB >$BAKDIR/syslog_db.sql
echo "The mysql backup successfuly"
