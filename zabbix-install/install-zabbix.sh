#!/bin/bash

#文件目录
INSTALL_HOME="`dirname \`readlink -f $0\``"

#定义安装包目录
#各种包的依赖版本
HTTPD_TAR_DIR="${INSTALL_HOME}/httpd"
MYSQL_TAR_DIR="${INSTALL_HOME}/mysql"
PHP_TAR_DIR="${INSTALL_HOME}/php"
ZABBIX_TAR_DIR="${INSTALL_HOME}/zabbix"

#定义安装目录
HTTPD_HOME="/usr/local/httpd"
PHP_HOME="/usr/local/php"
MYSQLD_HOME="/usr/local/mysql"
ZABBIX_HOME="/usr/local/zabbix"


#stop iptables
service iptables stop
#stop selinux
setenforce 0 
#install base and dependency
yum -y install gcc gcc-c++  make automake autoconf kernel-devel ncurses-devel \
libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel  pcre-devel \
libtool-libs freetype-devel gd zlib-devel file bison patch mlocate flex diffutils \
readline-devel glibc-devel glib2-devel bzip2-devel gettext-devel libcap-devel libmcrypt-devel
#make all dir
mkdir -p ${HTTPD_HOME} ${PHP_HOME} ${MYSQLD_HOME} ${ZABBIX_HOME}

function install_tar(){
	#参数:
	#	tar_abs_dir: tar包绝对路径
	#	tar_name: tar包名称
	#	extract_name: 解压名称
	#	parameters: 编译参数
	tar_abs_dir=$1
	tar_name=$2
	extract_name=$3
	parameters=$4
	cd ${tar_abs_dir}
	tar zxf ${tar_name}
	cd ${extract_name}
	./configure ${parameters}
	make && make install
}


#install httpd
echo "#####################Begin to install httpd########################"

#install apr apr-util pcre
#httpd有三个依赖模块,并且需要按照如下安装顺序:
#	1. apr
#	2. apr-util
#	3. pcre
cd ${HTTPD_TAR_DIR}
tar zxf apr-1.4.5.tar.gz
cd apr-1.4.5
./configure --prefix=/usr/local/httpd/apr
make && make install

cd ${HTTPD_TAR_DIR}
tar zxf apr-util-1.3.12.tar.gz
cd apr-util-1.3.12
./configure --prefix=/usr/local/httpd/apr-util \
			--with-apr=/usr/local/httpd/apr/
make && make install

cd ${HTTPD_TAR_DIR}
tar zxf pcre-8.38.tar.gz
cd pcre-8.38
./configure --prefix=/usr/local/httpd/pcre
make && make install

#install httpd
cd ${HTTPD_TAR_DIR}
tar zxf httpd-2.4.20.tar.gz
cd httpd-2.4.20
./configure --prefix=/usr/local/httpd/ \
			--enable-modules=all \
			--enable-mods-shared=all  \
			--enable-proxy \
			--enable-proxy-connect \
			--enable-proxy-ftp \
			--enable-proxy-http \
			--enable-proxy-ajp \
			--enable-proxy-balancer \
			--enable-rewrite \
			--enable-status \
			--with-apr=/usr/local/httpd/apr \
			--with-apr-util=/usr/local/httpd/apr-util/ \
			--with-pcre=/usr/local/httpd/pcre/

make && make install
#开始配置http
#创建control脚本
#	可以自定义修改下apachectl脚本:
#	case $ACMD in
#	stop|restart|graceful|graceful-stop)
#   	 $HTTPD -k $ARGV
#    	ERROR=$?
#    	;;
#	start)
#    	$HTTPD -k $ARGV
#    	if [[ $? -ne 0 ]];then
#        	echo "Start httpd failed."
#       	exit 1
#    	fi
#    	echo "Start httpd success."
#    	;;
#	启动脚本:./apachectl start|stop
#	启动失败,出现如下错误日志:
#[Mon Apr 25 18:10:38.447576 2016] [:emerg] [pid 32058:tid 140460297283328] AH00020: Configuration Failed, exiting
#[Mon Apr 25 18:14:27.270732 2016] [proxy_balancer:emerg] [pid 19908:tid 140394453731072] AH01177: 
#	Failed to lookup provider 'shm' for 'slotmem': is mod_slotmem_shm loaded??
#解决:在httpd.conf配置文件中取消LoadModule slotmem_shm_module modules/mod_slotmem_shm.so注释


echo "#####################Install httpd success.########################"
#install mysql
echo "#####################Begin to install mysql########################"
#首先安装工具,mysql5.6使用cmake安装,首先安装cmake
#注意下cmake的安装方式,和其他还是有区别的
cd ${MYSQL_TAR_DIR}
tar zxf cmake-3.5.2.tar.gz
cd cmake-3.5.2
./bootstrap 
gmake && gmake install

cd ${MYSQL_TAR_DIR}
tar zxf mysql-5.6.30.tar.gz
cd mysql-5.6.30
#编译的时候定义了数据的存放目录DMYSQL_DATADIR和程序运行的socket文件目录DMYSQL_UNIX_ADDR
cmake . \
		-DCMAKE_INSTALL_PREFIX=/usr/local/mysql/ \
		-DMYSQL_DATADIR=/usr/local/mysql/data \
		-DMYSQL_UNIX_ADDR=/usr/local/mysql/run/mysqld.sock \
		-DSYSCONFDIR=/usr/local/mysql/conf/ \
		-DWITH_MYISAM_STORAGE_ENGINE=1 \
		-DWITH_INNOBASE_STORAGE_ENGINE=1 \
		-DWITH_MEMORY_STORAGE_ENGINE=1 \
		-DENABLED_LOCAL_INFILE=1 \
		-DMYSQL_TCP_PORT=3306 \
		-DEXTRA_CHARSETS=all \
		-DDEFAULT_CHARSET=utf8 \
		-DDEFAULT_COLLATION=utf8_general_ci \
		-DWITH_READLINE=1
make && make install
#出现报错:
#collect2: ld returned 1 exit status
#make64[2]: *** [storage/perfschema/unittest/pfs_connect_attr-t] Error 1
#make64[1]: *** [storage/perfschema/unittest/CMakeFiles/pfs_connect_attr-t.dir/all] Error 2
#make64: *** [all] Error 2
#解决:
#加上参数:-DWITH_EMBEDDED_SERVER=0 \
#去掉参数:-DWITHOUT_PARTITION_STORAGE_ENGINE=1 \
#		  -DWITH_SSL=system \
#如果make && make install 出现错误,请记得make clean
#如果出现make不通过,可以直接重新解压,重新cmake

#配置mysql
#创建启停脚本
echo "#####################Install mysql success.########################"
#install php
echo "#####################Begin to install PHP########################"
#安装依赖库
# autoconf-2.69.tar.xz  libmcrypt-2.5.8.tar.gz  php-5.6.20.tar.gz
# freetype-2.6.tar.gz   libpng-1.6.21.tar.gz    zlib-1.2.8.tar.gz
# 此版本没有安装的库:libxml2 gd jpegsrc.v8b.tar.gz jpegsrc.v8b.tar.gz

cd ${PHP_TAR_DIR}
tar zxf autoconf-2.69.tar.gz
cd autoconf-2.69
./configure --prefix=/usr/local/php/autoconf
make && make install

cd ${PHP_TAR_DIR}
tar zxf freetype-2.6.tar.gz
cd freetype-2.6
./configure --prefix=/usr/local/php/freetype
make && make install

cd ${PHP_TAR_DIR}
tar zxf libmcrypt-2.5.8.tar.gz
cd libmcrypt-2.5.8
./configure --prefix=/usr/local/php/libmcrypt
make && make install

cd ${PHP_TAR_DIR}
tar zxf libpng-1.6.21.tar.gz
cd libpng-1.6.21
./configure --prefix=/usr/local/php/libpng
make && make install

cd ${PHP_TAR_DIR}
tar zxf zlib-1.2.8.tar.gz
cd zlib-1.2.8
./configure --prefix=/usr/local/php/zlib
make && make install

cd ${PHP_TAR_DIR}
tar zxf libiconv-1.14.tar.gz
cd libiconv-1.14
./configure --prefix=/usr/local/php/libiconv
make && make install

cd ${PHP_TAR_DIR}
tar zxf php-5.6.20.tar.gz
cd php-5.6.20
./configure --prefix=/usr/local/php \
			--with-config-file-path=/usr/local/php/etc \
			--with-apxs2=/usr/local/httpd/bin/apxs \
			--with-mysql=/usr/local/mysql/ \
			--with-pdo-mysql=/usr/local/mysql/ \
			--with-png-dir=/usr/local/php/libpng/ \
			--with-freetype-dir=/usr/local/php/freetype/ \
			--with-zlib-dir=/usr/local/php/zlib/ \
			--with-mcrypt=/usr/local/php/libmcrypt/ \
			--with-mysqli=/usr/local/mysql/bin/mysql_config/ \
			--enable-soap \
			--enable-mbstring=all \
			--enable-sockets \
			--enable-fpm \
			--enable-calendar \
			--enable-dba \
			--enable-ftp \
			--enable-zip \
			--enable-bcmath \
			--enable-xml \
			--enable-pcntl \
			--enable-mbstring \
			--with-iconv-dir=/usr/local/php/libiconv 
./configure --prefix=/usr/local/php \
			--with-config-file-path=/usr/local/php/etc \
			--with-apxs2=/usr/local/httpd/bin/apxs \
			--with-mysql=/usr/local/mysql/ \
			--with-pdo-mysql=/usr/local/mysql/ \
			--with-png-dir=/usr/local/php/libpng/ \
			--with-freetype-dir=/usr/local/php/freetype/ \
			--with-zlib-dir=/usr/local/php/zlib/  \
			--with-mcrypt=/usr/local/php/libmcrypt/ \
			--with-mysqli=/usr/local/mysql/bin/mysql_config \
			--enable-soap \
			--enable-mbstring=all \
			--enable-sockets \
			--enable-fpm \
			--enable-fpm \
			--enable-dba \
			--enable-ftp \
			--enable-zip \
			--enable-bcmath \
			--enable-xml \
			--enable-pcntl \
			--enable-pcntl \
			--with-iconv-dir=/usr/local/php/libiconv
make && make install
echo "#####################Install PHP success.########################"
#install zabbix