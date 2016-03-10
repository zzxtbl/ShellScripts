

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
httpd
