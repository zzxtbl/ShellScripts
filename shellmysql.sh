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

APP_path=/application
Tools_path=/server/tools


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
######################mysql赋值的环境变量不好用要手动要改下#########################
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
mysql